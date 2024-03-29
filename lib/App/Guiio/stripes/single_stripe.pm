
package App::Guiio::stripes::single_stripe ;

use base App::Guiio::stripes::stripes ;

use strict;
use warnings;

sub new
{
my ($class, $element_definition) = @_ ;

my $self = bless  {}, __PACKAGE__ ;
	
$self->setup($element_definition->{TEXT}) ;

return($self) ;
}

#-----------------------------------------------------------------------------

sub setup
{
my ($self, $text) = @_ ;

my $width = 0 ;
map {$width  = $width < length($_) ? length($_)  : $width} split("\n", $text) ;

my $height = ($text =~ tr[\n][\n]) + 1 ;

$self->set
	(
	TEXT => $text,
	WIDTH =>  $width,
	HEIGHT => $height,
	) ;
}

#-----------------------------------------------------------------------------

sub get_mask_and_element_stripes
{
my ($self) = @_ ;

return {X_OFFSET => 0, Y_OFFSET => 0, WIDTH => $self->{WIDTH}, HEIGHT => $self->{HEIGHT}, TEXT => $self->{TEXT}} ;
}

#-----------------------------------------------------------------------------

sub get_size
{
my ($self) = @_ ;
return($self->{WIDTH}, $self->{HEIGHT}) ;
}

#-----------------------------------------------------------------------------

sub resize
{
my ($self, $reference_x, $reference_y, $new_x, $new_y) = @_ ;

return(0, 0, $self->{WIDTH}, $self->{HEIGHT}) ;
}

#-----------------------------------------------------------------------------

sub get_text
{
my ($self) = @_ ;
return($self->{TEXT}) ;
}

#-----------------------------------------------------------------------------

sub set_text
{
my ($self, $text) = @_ ;
$self->setup($text) ;
}

#-----------------------------------------------------------------------------


1 ;
