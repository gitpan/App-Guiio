
#----------------------------------------------------------------------------------------------------------------------------

use File::Slurp ;

#----------------------------------------------------------------------------------------------------------------------------

register_import_export_handlers 
	(
	guiioe => 
		{
		IMPORT => \&import_guiioe,
		EXPORT => \&export_guiioe,
		},
	) ;

#----------------------------------------------------------------------------------------------------------------------------

sub import_guiioe
{
my ($self, $file)  = @_ ;

my $self_to_resurect= do $file  or die "import_guiioe: can't load file '$file': $! $@\n" ;
return($self_to_resurect, $file) ;
}

#----------------------------------------------------------------------------------------------------------------------------

sub export_guiioe
{
my ($self, $elements_to_save, $file, $data)  = @_ ;

if($self->{CREATE_BACKUP} && -e $file)
	{
	use File::Copy;
	copy($file,"$file.bak") or die "export_pod: Copy failed while making backup copy: $!";		
	}

write_file($file, $self->serialize_self(1) .'$VAR1 ;') ;

return $file ;
}

 
