
#----------------------------------------------------------------------------------------------

register_action_handlers
	(
	'Select next element' => ['000-Tab', \&select_next_element],
	'Select previous element' => ['00S-ISO_Left_Tab', \&select_previous_element],
	
	'Select all elements' => ['C00-a', \&select_all_elements],
	'Delete selected elements' =>  ['000-Delete', \&delete_selected_elements],

	'Group selected elements' => ['C00-g', \&group_selected_elements],
	'Ungroup selected elements' => ['C00-u', \&ungroup_selected_elements],
	
	'Move selected elements to the front' => ['C00-f', \&move_selected_elements_to_front],
	'Move selected elements to the back' => ['C00-b', \&move_selected_elements_to_back],
	
	'Edit selected element' => ['000-Return', \&edit_selected_element],
	
	'Move selected elements left' => ['000-Left', \&move_selection_left],
	'Move selected elements right' => ['000-Right', \&move_selection_right],
	'Move selected elements up' => ['000-Up', \&move_selection_up],
	'Move selected elements down' => ['000-Down', \&move_selection_down],
	) ;
	
#----------------------------------------------------------------------------------------------

sub edit_selected_element
{
my ($self) = @_ ;

my @selected_elements = $self->get_selected_elements(1) ;

if(@selected_elements == 1)
	{
	$self->create_undo_snapshot() ;
	$self->edit_element($selected_elements[0]) ;
	$self->update_display();
	}
}

#----------------------------------------------------------------------------------------------

sub change_arrow_direction
{
my ($self) = @_ ;

my @elements_to_redirect =  grep {ref $_ eq 'App::Guiio::stripes::section_wirl_arrow'} $self->get_selected_elements(1) ;

if(@elements_to_redirect)
	{
	$self->create_undo_snapshot() ;
	
	for (@elements_to_redirect)
                {
                $_->change_section_direction($self->{MOUSE_X} - $_->{X}, $self->{MOUSE_Y} - $_->{Y}) ;
                }
		
	$self->update_display()  ;
	}
}

#----------------------------------------------------------------------------------------------

sub flip_arrow_ends
{
my ($self) = @_ ;

my @elements_to_flip =  
	grep 
		{
		my @connectors = $_->get_connector_points() ; 
		
		      ref $_ eq 'App::Guiio::stripes::section_wirl_arrow'
		&& $_->get_number_of_sections() == 1
		&& @connectors > 0 ;
		} $self->get_selected_elements(1) ;

if(@elements_to_flip)
	{
	$self->create_undo_snapshot() ;
	
	my %reverse_direction = 
		(
		'up', => 'down',
		'right' => 'left',
		'down' => 'up',
		'left' => 'right'
		) ;
		
	for (@elements_to_flip)
		{
                # create one with ends swapped
		my $new_direction = $_->get_section_direction(0) ;
		
                if($new_direction =~ /(.*)-(.*)/)
                        {
                        my ($start_direction, $end_direction) = ($1, $2) ;
                        $new_direction = $reverse_direction{$end_direction} . '-' . $reverse_direction{$start_direction} ;
                        }
		else
			{
			$new_direction = $reverse_direction{$new_direction} ;
			}
		
		my ($start_connector, $end_connector) = $_->get_connector_points() ;
		my $arrow = new App::Guiio::stripes::section_wirl_arrow
						({
						%{$_},
						POINTS => 
							[
								[
								- $end_connector->{X},
								- $end_connector->{Y},
								$new_direction,
								]
							],
						DIRECTION => $new_direction,
						}) ;
		
		#add new element, connects automatically
		$self->add_element_at($arrow, $_->{X} + $end_connector->{X}, $_->{Y} + $end_connector->{Y}) ;
		
               # remove element
                $self->delete_elements($_) ;

                # keep the element selected
                $self->select_elements(1, $arrow) ;
		}
		
	$self->update_display() ;
	}
}

#----------------------------------------------------------------------------------------------

sub select_next_element
{
my ($self) = @_ ;

return unless exists $self->{ELEMENTS}[0] ;

$self->create_undo_snapshot() ;

my @selected_elements = $self->get_selected_elements(1) ;

if(@selected_elements)
	{
	my $last_selected_element = $selected_elements[-1] ;
	
	my ($seen_selected, $next_element) ;
	
	for my $element (@{$self->{ELEMENTS}}) 
		{
		if(! $self->is_element_selected($element) && $seen_selected)
			{
			$next_element = $element ; last ;
			}
			
		$seen_selected =$element == $last_selected_element ;
		}
		
	$self->select_elements(0, @{$self->{ELEMENTS}}) ;
	
	if($next_element)
		{
		$self->select_elements(1, $next_element) ;
		}
	else
		{
		$self->select_elements(1, $self->{ELEMENTS}[0]);
		}
	}
else
	{
	$self->select_elements(1, $self->{ELEMENTS}[0]);
	}
	
$self->update_display() ;
}

 #----------------------------------------------------------------------------------------------

sub select_previous_element
{
my ($self) = @_ ;

return unless exists $self->{ELEMENTS}[0] ;

$self->create_undo_snapshot() ;

my @selected_elements = $self->get_selected_elements(1) ;
if(@selected_elements)
	{
	my $last_selected_element = $selected_elements[0]  ;

	my ($seen_selected, $next_element) ;
	for my $element (reverse @{$self->{ELEMENTS}}) 
		{
		if(! $self->is_element_selected($element) && $seen_selected)
			{
			$next_element = $element ; last ;
			}
			
		$seen_selected =$element == $last_selected_element ;
		}
		
	$self->select_elements(0, @{$self->{ELEMENTS}}) ;

	 if(defined $next_element)
		{
		$self->select_elements(1, $next_element) ;
		}
	else
		{
		$self->select_elements(1, $self->{ELEMENTS}[-1]);
		}
	}
else
	{
	$self->select_elements(1, $self->{ELEMENTS}[-1]);
	}
	
$self->update_display() ;
}

#----------------------------------------------------------------------------------------------

sub select_all_elements
{
my ($self) = @_ ;

$self->select_elements(1, @{$self->{ELEMENTS}}) ;
$self->update_display() ;
} ;	
	
#----------------------------------------------------------------------------------------------

sub delete_selected_elements
{
my ($self) = @_ ;

$self->create_undo_snapshot() ;

$self->delete_elements($self->get_selected_elements(1)) ;
$self->update_display() ;
} ;	

#----------------------------------------------------------------------------------------------

sub move_selection_left
{
my ($self, $offset) = @_ ;

$offset = 1 unless defined $offset ;

$self->create_undo_snapshot() ;

$self->move_elements(-$offset, 0, $self->get_selected_elements(1)) ;
$self->update_display() ;
} ;

#----------------------------------------------------------------------------------------------

sub move_selection_right
{
my ($self, $offset) = @_ ;

$offset = 1 unless defined $offset ;

$self->create_undo_snapshot() ;

$self->move_elements($offset, 0, $self->get_selected_elements(1)) ;
$self->update_display() ;
} ;

#----------------------------------------------------------------------------------------------

sub move_selection_up
{
my ($self, $offset) = @_ ;

$offset = 1 unless defined $offset ;

$self->create_undo_snapshot() ;

$self->move_elements(0, -$offset, $self->get_selected_elements(1)) ;
$self->update_display() ;
} ;

#----------------------------------------------------------------------------------------------

sub move_selection_down
{
my ($self, $offset) = @_ ;

$offset = 1 unless defined $offset ;

$self->create_undo_snapshot() ;

$self->move_elements(0, $offset, $self->get_selected_elements(1)) ;
$self->update_display() ;
} ;

#----------------------------------------------------------------------------------------------

sub group_selected_elements
{
my ($self) = @_ ;

my @selected_elements = $self->get_selected_elements(1)  ;

if(@selected_elements >= 2)
	{
	$self->create_undo_snapshot() ;
	
	my $group = {'GROUP_COLOR' => $self->get_group_color()} ;
	for my $element (@selected_elements)
		{
		push @{$element->{'GROUP'}}, $group  ;
		}
	}
	
$self->update_display() ;
} ;


#----------------------------------------------------------------------------------------------

sub ungroup_selected_elements
{
my ($self) = @_ ;

my @selected_elements = $self->get_selected_elements(1)  ;

for my $grouped (grep {exists $_->{GROUP} } @selected_elements)
	{
	pop @{$grouped->{GROUP}} ;
	}

$self->update_display() ;
} ;

#----------------------------------------------------------------------------------------------

sub move_selected_elements_to_front
{
my ($self) = @_ ;

my @selected_elements = $self->get_selected_elements(1)  ;

if(@selected_elements)
	{
	$self->create_undo_snapshot() ;
	$self->move_elements_to_front(@selected_elements) ;
	}
	
$self->update_display() ;
} ;

#----------------------------------------------------------------------------------------------

sub move_selected_elements_to_back
{
my ($self) = @_ ;

my @selected_elements = $self->get_selected_elements(1)  ;

if(@selected_elements)
	{
	$self->create_undo_snapshot() ;
	$self->move_elements_to_back(@selected_elements) ;
	}
	
$self->update_display() ;
} ;
