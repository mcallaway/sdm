#!/usr/bin/perl

BEGIN {
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
}

use Web::Simple 'System::Service::WebApp::Main';

package System::Service::WebApp::Main;

use strict;

use File::Basename;
use Plack::Util;

our $always_memcache = $ENV{'SYSTEM_VIEW_CACHE'};

our $psgi_path;
eval {
    ## System is probably not loaded, thats okay, we can just use __FILE__
    $psgi_path = System::Service::WebApp->psgi_path;
};
unless (defined $psgi_path) {
    $psgi_path = File::Basename::dirname(__FILE__);
}

our %app = map { $_ => load_app($_) } qw/
  Rest.psgi
  Redirect.psgi
  404Handler.psgi
  Dump.psgi
  Cache.psgi
  CGI.psgi
  Site.psgi
  /;

## Utility functions
sub load_app {
    Plack::Util::load_psgi( $psgi_path . '/' . shift );
}

sub redispatch_psgi {
    my ( $psgi_app, @args ) = @_;
    __PACKAGE__->_build_dispatcher(
        {
            call => sub {
                shift;
                my ( $self, $env ) = @_;
                $psgi_app->( $env, @args );
              }
        }
    );
}

sub redirect_to {
    redispatch_psgi( $app{'Redirect.psgi'}, shift );
}

## Web::Simple dispatcher for all apps
dispatch {
      ## make 404's pretty by sending them to 404Handler.psgi
      response_filter {
          my $resp = $_[1];

          if ( ref($resp) eq 'ARRAY' && $resp->[0] == 404 ) {
              return redispatch_psgi( $app{'404Handler.psgi'}, $resp->[2] );
          } elsif ( ref($resp) eq 'ARRAY' && $resp->[0] == 500 ) {
              return redispatch_psgi( $app{'404Handler.psgi'}, $resp->[2] );
          }

          return $resp;
      },

      # Any CGI should go to this CGI handler
      # This is a special case where we want to just load Foo.pm and have
      # it return JSON data.  We use this for HTML pages using jQuery.
      sub (GET + .cgi) {
          redispatch_psgi($app{'CGI.psgi'});
      },

      # Serve "regular web pages" outside of UR views.
      sub (/site/...) {
          redispatch_psgi($app{'Site.psgi'});
      },

      sub (/res/**) {
        redispatch_to "/view/system/resource.html/$_[1]";
      },

      ## send /view without a trailing slash to /view/
      ## although thats probably a 404
      sub (/view) {
        redispatch_to "/view/";
      },

      ## In apache /viewajax maps to /cachefill
      #  because we want generate the view synchronously to the request
      #  and fill in memcached after its generated
      sub (/cachefill/...) {
        redispatch_psgi($app{'Cache.psgi'}, 2);
      },

      ## This is triggered as an ajax request from the cache-miss page
      sub (/cachetrigger/...) {
        redispatch_psgi($app{'Cache.psgi'}, 1);
      },

      ## In apache /view maps to /cache which will show the cache-miss
      #  page if necessary.
      sub (/cache/...) {
        redispatch_psgi $app{'Cache.psgi'};
      },

      ($always_memcache ? (
      sub (/viewajax/...) {
        redispatch_psgi($app{'Cache.psgi'}, 2);
      },
      sub (/view/...) {
        redispatch_psgi $app{'Cache.psgi'};
      },
      ) : (
      ## this exists so the embedded web server can run without caching
      sub (/viewajax/...) {
        redispatch_psgi $app{'Rest.psgi'};
      },

      ## this exists so the embedded web server can run without caching
      sub (/view/...) {
        redispatch_psgi $app{'Rest.psgi'};
      },
      )),

      ## dump the psgi environment, for testing
      sub (/dump/...) {
        redispatch_psgi $app{'Dump.psgi'};
      },

      ## send the browser to the finder view of System
      sub (/) {
        redirect_to "/view/system/search/status.html";
      }
};

System::Service::WebApp::Main->run_if_script;
