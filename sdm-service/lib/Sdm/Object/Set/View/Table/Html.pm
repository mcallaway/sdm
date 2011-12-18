
package Sdm::Object::Set::View::Table::Html;

use strict;
use warnings;
use feature 'switch';

use Sdm;
use Data::Dumper;

class Sdm::Object::Set::View::Table::Html {
    is => 'UR::Object::View::Default::Html',
    has_constant => [
        default_aspects => {
            value => []
        }
    ]
};

sub _generate_content {
    my $self = shift;

    my $content = do { local $/; <DATA> };

    # Determine attributes of class for columns of the table
    my $class = $self->subject_class_name;
    $content =~ s/<%= class =>/$class/g;

    # Build JSON view of aaData using Json.pm peer class
    my $subject = $self->subject;
    my $jsview;
    eval {
        $jsview = $subject->create_view('perspective'=>'table','toolkit'=>'json');
    };
    unless ($jsview) {
        eval {
            $jsview = $subject->create_view(subject_class_name => 'Sdm::Object::Set', 'perspective'=>'table','toolkit'=>'json');
        };
    }
    unless ($jsview) {
        die __PACKAGE__ . " failed to create view for JSON object for $class: $@";
    }
    my $aaData = $jsview->_json->encode( $jsview->_jsobj->{aaData} );
    $content =~ s/<%= aaData =>/$aaData/;

    # Determine column headers for javascript
    my @members = $subject->members;
    my $member = $members[0];
    return $content unless ($member);

    my %args = (
            subject_class_name => $class,
            perspective => 'default',
            toolkit => 'json',
    );
    my @default_aspects = @{ $self->default_aspects };
    unless (@default_aspects and $member) {
        @default_aspects = map { $_->property_name } $member->__meta__->properties;
    }
    @default_aspects = grep {!/id/} @default_aspects;
    unshift @default_aspects,'id';
    $args{aspects} = [ @default_aspects ];
    my $view;
    eval {
        $view = $member->create_view(%args);
    };
    unless ($view) {
        eval {
            $view = $subject->create_view(subject_class_name=>'Sdm::Object::Set',perspective=>'table',toolkit=>'html');
        };
    }
    unless ($view) {
        die __PACKAGE__ . " failed to create view for JSON object for $class: $@";
    }
    my @attributes = $view->aspects;
    @attributes = map { $_->name } @attributes;

    # Here we set column attributes, like title.
    my $sTitles = qq/{ "sTitle":'id', "bVisible": false },\n/;
    foreach my $attr (@attributes) {
        next if ($attr eq 'id');
        $sTitles .= qq/{ "sTitle": "$attr" },\n/;
    }
    $content =~ s/<%= sTitles =>/$sTitles/;

    # Here we specify which columns are not editable by setting 'null' in aoColumns
    my $aoColumns;
    foreach my $attr (@attributes) {
        given ($attr) {
            when ($attr eq 'id') { next; };
            when ($attr =~ /(created|last_modified)/i) {
                $aoColumns .= qq/null,\n/;
                next;
            }
            default {
                $aoColumns .= qq/{},\n/;
            }
        }
    }
    $content =~ s/<%= aoColumns =>/$aoColumns/;

    my $idx = 0;
    my $addRecord;
    foreach my $attr (@attributes) {
        given ($attr) {
            # These are the none editable columns, hidden in the add form
            when ($attr =~ /^(id|created|last_modified)$/) {
                $addRecord .= qq{  <input type="hidden" name="$attr" id="$attr" rel="$idx" /><br />\n };
                $idx++;
                next;
            }
            default {
                $addRecord .= qq{  <label for="$attr">$attr</label><br />\n  <input type="text" name="$attr" id="$attr" class="required" rel="$idx" /><br />\n };
                $idx++;
            }
        }
    }
    $content =~ s/<%= addrecordform =>/$addRecord/;

    # Here's the HTML document we return
    return $content;
}

1;
__DATA__
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
  <head>
    <meta http-equiv="content-type" content="text/html; charset=utf-8" />
    <!-- Disable browser caching -->
    <meta http-equiv='Pragma' content='no-cache'/>
    <!-- Microsoft browsers require this additional meta tag as well -->
    <meta http-equiv='Expires' content='-1'/>
    <title><%= class =></title>
    <style type="text/css" title="currentStyle">
      @import "/css/status_page.css";
      @import "/css/status_table.css";
      @import "/js/pkg/TableTools/media/css/TableTools.css";
    </style>
    <link rel="shortcut icon" href="/images/gc_favicon.png" />
    <!-- <script type="text/javascript" language="javascript" charset="utf-8" src="/js/pkg/jQuery/jquery.min.js"></script> -->
    <script type="text/javascript" language="javascript" charset="utf-8" src="/js/pkg/jquery.js"></script>
    <script type="text/javascript" language="javascript" charset="utf-8" src="/js/pkg/DataTables/media/js/jquery.dataTables.js"></script>
    <script type="text/javascript" language="javascript" charset="utf-8" src="/js/pkg/TableTools/media/ZeroClipboard/ZeroClipboard.js"></script>
    <script type="text/javascript" language="javascript" charset="utf-8" src="/js/pkg/TableTools/media/js/TableTools.js"></script>
    <script type="text/javascript" language="javascript" charset="utf-8" src="/js/pkg/jquery-datatables-editable/jquery-ui.js"></script>
    <script type="text/javascript" language="javascript" charset="utf-8" src="/js/pkg/jquery-datatables-editable/jquery.jeditable.js"></script>
    <script type="text/javascript" language="javascript" charset="utf-8" src="/js/pkg/jquery-datatables-editable/jquery.validate.js"></script>
    <script type="text/javascript" language="javascript" charset="utf-8" src="/js/pkg/jquery-datatables-editable/jquery.dataTables.editable.js"></script>
    <script type="text/javascript" language="javascript" charset="utf-8" src="/js/app/common.js"></script>
    <script type="text/javascript" language="javascript" charset="utf-8">
        var oTable;
        function drawTable () {
            oTable = $('#datatable').dataTable( {
                    "sDom": 'T<"clear">lfrtip',
                    "bProcessing": true,
                    "bServerSide": false,
                    // This callback adds the "id" tr attribute required for sUpdateURL to work
                    "fnRowCallback": function( nRow, aaData, iDisplayIndex ) {
                        var id = aaData[0];
                        $(nRow).attr("id",id);
                        return nRow;
                    },
                    // aaData is generated automatically by Json.pm
                    "aaData":
                      <%= aaData =>
                    ,
                    // hide the id which is a UUID
                    "aoColumns": [
                        <%= sTitles =>
                    ],
                    } ).makeEditable( {
                        sUpdateURL: "/service/update?class=<%= class =>",
                        sAddURL: "/service/add?class=<%= class =>",
                        fnOnAdded: function(status) {
                          location.reload();
                        },
                        sDeleteURL: "/service/delete?class=<%= class =>",
                        // Define columns here, which can be reordered in {Html,Json}.pm
                        // Prevent users from modifying created and last_modified
                        "aoColumns": [
                          <%= aoColumns =>
                        ]
            } );
        }
    </script>
    <script type="text/javascript" language="javascript" charset="utf-8">
$(document).ready(function() {
TableToolsInit.sSwfPath = "/js/pkg/TableTools/media/swf/ZeroClipboard.swf";
drawTable();
});
    </script>
  </head>

  <body id="dt_example">
  <div id="container">
  <table cellpadding="0" cellspacing="0" border="0" class="display" id="datatable">
  </table>
  <!-- Placeholder where add and delete buttons will be generated -->
  <div class="add_delete_toolbar" />
  </div>
  <!-- Custom form for adding new records -->
  <form id="formAddNewRow" action="#" title="Add new record">
    <%= addrecordform =>
  </form>
  </body>
  <head>
    <meta http-equiv='Pragma' content='no-cache'>
  </head>
</html>