
#----------------------------------------------------------------------------------------------

	
#----------------------------------------------------------------------------------------------

sub change_elements_colors
{
my ($self, $is_background) = @_ ;

my ($color) = $self->get_color_from_user([0, 0, 0]) ;

$self->create_undo_snapshot() ;

for my $element($self->get_selected_elements(1))
	{
	$is_background
		? $element->set_background_color($color) 
		: $element->set_foreground_color($color) ;
		
	}
	
$self->update_display() ;
}

#----------------------------------------------------------------------------------------------

sub change_guiio_background_color
{
my ($self) = @_ ;

my ($color) = $self->get_color_from_user([0, 0, 0]) ;

$self->create_undo_snapshot() ;

$self->flush_color_cache() ;
$self->{COLORS}{background} = $color ;
	
$self->update_display() ;
}

#----------------------------------------------------------------------------------------------

sub change_grid_color
{
my ($self) = @_ ;

my ($color) = $self->get_color_from_user([0, 0, 0]) ;

$self->create_undo_snapshot() ;

$self->flush_color_cache() ;
$self->{COLORS}{grid} = $color ;
	
$self->update_display() ;
}

#----------------------------------------------------------------------------------------------
