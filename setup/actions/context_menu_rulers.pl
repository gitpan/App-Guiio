
#----------------------------------------------------------------------------------------------

#----------------------------------------------------------------------------------------------

sub add_ruler
{
my ($self, $data) = @_ ;

$self->create_undo_snapshot() ;

my ($type, $column, $line) ;

$data = {TYPE => 'VERTICAL', POSITION => $self->{MOUSE_X}} unless defined $data ;
	
$self->add_ruler_lines
		({
		COLOR => $self->{COLORS}{ruler_line},
		NAME => 'from context menu',
		%{$data},
		}) ;
		
$self->update_display();
}

#----------------------------------------------------------------------------------------------

sub remove_ruler
{
my ($self, $data) = @_ ;

$data = {TYPE => 'VERTICAL', POSITION => $self->{MOUSE_X}} unless defined $data ;
	
$self->create_undo_snapshot() ;
$self->remove_ruler_lines($data) ;
$self->update_display();
}

#----------------------------------------------------------------------------------------------

sub rulers_context_menu
{
my ($self, $popup_x, $popup_y) = @_ ;
my @context_menu_entries ;

my ($x, $y) = $self->closest_character($popup_x, $popup_y) ;

my $vertical = {TYPE => 'VERTICAL', POSITION => $x} ;
my $horizontal = {TYPE => 'HORIZONTAL', POSITION => $y} ;

if($self->exists_ruler_line($vertical))
	{
	push @context_menu_entries, ["/Ruler/remove vertical ruler", \&remove_ruler,  $vertical] ;
	}
else
	{
	push @context_menu_entries, ["/Ruler/add vertical ruler", \&add_ruler,  $vertical] ;
	}
	
if($self->exists_ruler_line($horizontal))
	{
	push @context_menu_entries, ["/Ruler/remove horizontal ruler", \&remove_ruler,  $horizontal] ;
	}
else
	{
	push @context_menu_entries, ["/Ruler/add horizontal ruler", \&add_ruler,  $horizontal] ;
	}

return(@context_menu_entries) ;
}

#----------------------------------------------------------------------------------------------

