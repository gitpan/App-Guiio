
package App::Guiio ;

$|++ ;

use strict;
use warnings;

use Data::TreeDumper ;
use Eval::Context ;
use Carp ;
use Module::Util qw(find_installed) ;
use File::Basename ;

use Gtk2::Gdk::Keysyms ;
my %K = %Gtk2::Gdk::Keysyms ;

#------------------------------------------------------------------------------------------------------

sub setup
{
my($self, $setup_ini_file, $setup_path) = @_ ;

$setup_ini_file = 'setup.ini' unless(defined $setup_ini_file) ;

unless(defined $setup_path)
	{
	my ($basename, $path, $ext) = File::Basename::fileparse(find_installed('App::Guiio'), ('\..*')) ;
	$setup_path = $path . $basename . '/setup/' ;
	}

if(-e $setup_path)
	{
	eval "use lib qw($setup_path) ;" ;
	die "Can't use '$setup_path'\n" if $@ ;
	
	print "Using setup directory:'$setup_path'\n" ;
	}
else
	{
	croak "Can't find setup directory '$setup_path'\n" ;
	}

my $ini_files ;

if('HASH' ne ref $setup_ini_file)
	{
	my $context = new Eval::Context() ;
	$ini_files = $context->eval
				(
				PRE_CODE => "use strict;\nuse warnings;\n",
				CODE_FROM_FILE => "$setup_path/$setup_ini_file",
				) ;

	die "can't load '$setup_ini_file': $! $@\n" if $@ ;
	}
	
$self->setup_stencils($setup_path, $ini_files->{STENCILS} || []) ;
$self->setup_hooks($setup_path, $ini_files->{HOOK_FILES} || []) ;
$self->setup_action_handlers($setup_path, $ini_files->{ACTION_FILES} || []) ;
$self->setup_import_export_handlers($setup_path, $ini_files->{IMPORT_EXPORT} || []) ;
$self->setup_object_options($setup_path, $ini_files->{guiio_OBJECT_SETUP} || []) ;
}

#------------------------------------------------------------------------------------------------------

sub setup_stencils
{
my($self, $setup_path, $stencils) = @_ ;

for my $stencil (@{$stencils})
	{
	if(-e "$setup_path/$stencil")
		{
		if(-f "$setup_path/$stencil")
			{
			$self->load_elements("$setup_path/$stencil", $stencil) ;
			}
		elsif(-d "$setup_path/$stencil")
			{
			print "batch loading stencil from $setup_path/$stencil\n" ;
			
			for(glob("$setup_path/$stencil/*"))
				{
				$self->load_elements($_, $stencil) ;
				}
			}
		else
			{
			print "Unknown type '$setup_path/$stencil'!\n" ;
			}
		}
	else
		{
		print "Can't find '$setup_path/$stencil'!\n" ;
		}
	}
}

#------------------------------------------------------------------------------------------------------

my Readonly $CATEGORY = 0 ;
my Readonly $SHORTCUTS = 0 ;
my Readonly $CODE = 1 ;
my Readonly $ARGUMENTS = 2 ;
my Readonly $CONTEXT_MENUE_SUB = 3;
my Readonly $CONTEXT_MENUE_ARGUMENTS = 4 ;
my Readonly $NAME= 5 ;
my Readonly $ORIGIN= 6 ;

sub setup_hooks
{
my($self, $setup_path, $hook_files) = @_ ;

for my $hook_file (@{ $hook_files })
	{
	my $context = new Eval::Context() ;

	my @hooks ;
	
	$context->eval
		(
		REMOVE_PACKAGE_AFTER_EVAL => 0, # VERY IMPORTANT as we return code references that will cease to exist otherwise
		INSTALL_SUBS => {register_hooks => sub{@hooks = @_}},
		PRE_CODE => "use strict;\nuse warnings;\n",
		CODE_FROM_FILE => "$setup_path/$hook_file" ,
		) ;

	die "can't load hook file '$hook_file ': $! $@\n" if $@ ;
	
	for my $hook (@hooks)
		{
		$self->{HOOKS}{$hook->[$CATEGORY]} =  $hook->[$CODE] ;
		}
	}
}

#------------------------------------------------------------------------------------------------------

sub setup_action_handlers
{
my($self, $setup_path, $action_files) = @_ ;

for my $action_file (@{ $action_files })
	{
	#~ print "setup_action_handlers: loading '$action_file'\n" ;
	
	my $context = new Eval::Context() ;

	my %action_handlers;
	$context->eval
		(
		REMOVE_PACKAGE_AFTER_EVAL => 0, # VERY IMPORTANT as we return code references that will cease to exist otherwise
		INSTALL_SUBS => {register_action_handlers => sub{%action_handlers = @_}},
		PRE_CODE => "use strict;\nuse warnings;\n",
		CODE_FROM_FILE => "$setup_path/$action_file",
		) ;

	die "can't load setup file '$action_file': $! $@\n" if $@ ;

	for my $name (keys %action_handlers)
		{
		my $action_handler ;
		my $group_name ;
		
		my $shortcuts_definition ;
		if('HASH' eq ref $action_handlers{$name})
			{
			$shortcuts_definition = $action_handlers{$name}{SHORTCUTS}  ;
			$action_handlers{$name}{GROUP_NAME} = $group_name = $name ;
			$action_handlers{$name}{ORIGIN} = $action_file;
			
			$action_handler = $self->get_group_action_handler($action_handlers{$name}, $action_file) ;
			}
		elsif('ARRAY' eq ref $action_handlers{$name})
			{
			$shortcuts_definition= $action_handlers{$name}[$SHORTCUTS]  ;
			$action_handlers{$name}[$NAME] = $name ;
			$action_handlers{$name}[$ORIGIN] = $action_file ;
			
			$action_handler = $action_handlers{$name} ;
			}
		else
			{
			#~ print "ignoring '$name'\n"  ;
			next ;
			}
			
		$self->{ACTIONS_BY_NAME}{$name} = $action_handlers{$name}  ;
		
		my $shortcuts ;
		if('ARRAY' eq ref $shortcuts_definition)
			{
			$shortcuts = $shortcuts_definition  ;
			}
		else
			{
			$shortcuts = [$shortcuts_definition]  ;
			}
			
		for my $shortcut (@$shortcuts)	
			{
			if(exists $self->{ACTIONS}{$shortcut})
				{
				print "Overriding action '$shortcut' with definition from file'$action_file'!\n" ;
				}
				
			$self->{ACTIONS}{$shortcut} =  $action_handler ;
			
			if(defined $group_name)
				{
				$self->{ACTIONS}{$shortcut}{GROUP_NAME} = $group_name ;
				$self->{ACTIONS}{$shortcut}{ORIGIN} = $action_file;
				}
			}
		}
	}
}

sub get_group_action_handler
{
my ($self, $action_handler_definition, $action_file) = @_ ;

my %handler ;

for my $name (keys %{$action_handler_definition})
	{
	my $action_handler ;
	my $group_name ;
	
	my $shortcuts_definition ;
	if('SHORTCUTS' eq $name)
		{
		#~ print "Found shortcuts definition.\n" ;
		next ;
		}
	elsif('HASH' eq ref $action_handler_definition->{$name})
		{
		$shortcuts_definition= $action_handler_definition->{$name}{SHORTCUTS}  ;
		$action_handler_definition->{$name}{GROUP_NAME} = $group_name = $name ;
		$action_handler_definition->{$name}{ORIGIN} = $action_file ;
		
		$action_handler = $self->get_group_action_handler($action_handler_definition->{$name}, $action_file) ;
		}
	elsif('ARRAY' eq ref $action_handler_definition->{$name})
		{
		$shortcuts_definition= $action_handler_definition->{$name}[$SHORTCUTS]  ;
		$action_handler_definition->{$name}[$NAME] = $name ;
		$action_handler_definition->{$name}[$ORIGIN] = $action_file ;
		
		$action_handler = $action_handler_definition->{$name} ;
		}
	else
		{
		#~ print "ignoring '$name'\n"  ;
		next ;
		}
	
	my $shortcuts ;
	if('ARRAY' eq ref $shortcuts_definition)
		{
		$shortcuts = $shortcuts_definition  ;
		}
	else
		{
		$shortcuts = [$shortcuts_definition]  ;
		}
		
	for my $shortcut (@$shortcuts)	
		{
		if(exists $handler{$shortcut})
			{
			print "Overriding action group '$shortcut' with definition from file'$action_file'!\n" ;
			}
			
		$handler{$shortcut} =  $action_handler ;
		
		if(defined $group_name)
			{
			$handler{$shortcut}{GROUP_NAME} = $group_name ;
			}
		}
	}
	
return \%handler ;
}

#------------------------------------------------------------------------------------------------------

sub setup_import_export_handlers
{
my($self, $setup_path, $import_export_files) = @_ ;

for my $import_export_file (@{ $import_export_files })
	{
	my $context = new Eval::Context() ;

	my %import_export_handlers ;
	$context->eval
		(
		REMOVE_PACKAGE_AFTER_EVAL => 0, # VERY IMPORTANT as we return code references that will cease to exist otherwise
		INSTALL_SUBS => {register_import_export_handlers => sub{%import_export_handlers = @_}},
		PRE_CODE => <<EOC ,
			use strict;
			use warnings;

			use Gtk2::Gdk::Keysyms ;
			my %K = %Gtk2::Gdk::Keysyms ;
EOC
		CODE_FROM_FILE => "$setup_path/$import_export_file",
		) ;
			
	die "can't load import/export handler defintion file '$import_export_file': $! $@\n" if $@ ;

	for my $extension (keys %import_export_handlers)
		{
		if(exists $self->{IMPORT_EXPORT_HANDLERS}{$extension})
			{
			print "Overriding import/export handler for extension '$extension'!\n" ;
			}
			
		$self->{IMPORT_EXPORT_HANDLERS}{$extension} = $import_export_handlers{$extension}  ;
		}
	}
}

#------------------------------------------------------------------------------------------------------

sub setup_object_options
{
my($self, $setup_path, $options_files) = @_ ;

for my $options_file (@{ $options_files })
	{
	my $context = new Eval::Context() ;

	my %options = 
		$context->eval
			(
			PRE_CODE => "use strict;\nuse warnings;\n",
			CODE_FROM_FILE => "$setup_path/$options_file",
			) ;
	
	for my $option_name (keys %options)
		{
		$self->{$option_name} = $options{$option_name} ;
		}
		
	die "can't load setup file '$options_file': $! $@\n" if $@ ;
	}
	
$self->event_options_changed() ;
}

#------------------------------------------------------------------------------------------------------

sub run_script
{
my($self, $script) = @_ ;

if(defined $script)
	{
	my $context = new Eval::Context() ;

	$context->eval
		(
		PRE_CODE => "use strict;\nuse warnings;\n",
		CODE_FROM_FILE => $script,
		INSTALL_VARIABLES =>
			[ 
			[ '$self' => $self => $Eval::Context::SHARED ],
			] ,
		) ;
	
	die "can't load setup file '$script': $! $@\n" if $@ ;
	}
}

#------------------------------------------------------------------------------------------------------

1 ;

