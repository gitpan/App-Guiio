
use strict;
use warnings;
use lib qw(lib lib/stripes) ;
use Data::TreeDumper ;

use App::Guiio ;
use App::Guiio::stripes::editable_box2 ;
use App::Guiio::stripes::process_box ;
use App::Guiio::stripes::single_stripe ;

#-----------------------------------------------------------------------------

my $guiio = new App::Guiio() ;

#-----------------------------------------------------------------------------

my ($current_x, $current_y) = (0, 0) ;

my $new_box = new App::Guiio::stripes::editable_box2
				({
				TEXT_ONLY => 'box',
				TITLE => '',
				EDITABLE => 1,
				RESIZABLE => 1,
				}) ;
$guiio->add_element_at($new_box, 0, 0) ;

my $new_process = new App::Guiio::stripes::process_box
				({
				TEXT_ONLY => 'process',
				EDITABLE => 1,
				RESIZABLE => 1,
				}) ;
$guiio->add_element_at($new_process, 25, 0) ;

my $new_stripe = new App::Guiio::stripes::single_stripe
				({
				TEXT => 'stripe',
				}) ;
$guiio->add_element_at($new_stripe, 50, 0) ;

print $guiio->transform_elements_to_ascii_buffer() ;

$new_box->set_text('title', "line 1\nline 2") ;
$new_process->set_text("line 1\nline2\nline3") ;
$new_stripe->set_text( "line 1\nline2") ;

print $guiio->transform_elements_to_ascii_buffer() ;

for ($new_box, $new_process, $new_stripe)
	{
	print "\n-------------------------------------------------------\n\n" ;
	print 'type: ',  ref($_), "\n" ;
	print 'size:', join(",", $_->get_size()) , "\n" ;
	print DumpTree([$_->get_connection_points()], 'connection points:') , "\n" ;
	print 'text : ',  join("\n", $_->get_text()) , "\n" ;
	}

