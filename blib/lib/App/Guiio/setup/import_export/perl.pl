
#----------------------------------------------------------------------------------------------------------------------------

use File::Slurp ;
use Data::Dumper ;
use List::Util qw(max);
use File::Basename ;

#~ use Compress::LZF ':compress';
use Compress::Bzip2 qw(:all :utilities :gzip);
use MIME::Base64 ();

my $BASE64_HEADER = (' ' x 120)  .  '#guiio' ;
my $BASE64_HEADER_SIZE = length($BASE64_HEADER) ;

#----------------------------------------------------------------------------------------------------------------------------

register_import_export_handlers 
	(
	pod => 
		{
		IMPORT => \&import_pod,
		EXPORT => \&export_pod,
		},
		
	pl => 
		{
		IMPORT => \&import_pod,
		EXPORT => \&export_pod,
		},
		
	pm => 
		{
		IMPORT => \&import_pod,
		EXPORT => \&export_pod,
		},
	) ;

#----------------------------------------------------------------------------------------------------------------------------

sub import_pod
{
my ($self, $file)  = @_ ;

my ($base_name, $path, $extension) = File::Basename::fileparse($file, ('\..*')) ;
my $file_name = $base_name . $extension ;

my ($base64_data, $header, $footer) = get_base64_data($file_name) ;

my $decoded_base64 = MIME::Base64::decode($base64_data);
my $self_to_resurect =  decompress($decoded_base64) ;

my $VAR1 ;
my $resurected_self =  eval $self_to_resurect ;
die $@ if $@ ;

return($resurected_self, $file, {HEADER => $header, FOOTER => $footer}) ;
}

sub get_base64_data
{
=pod
find all guiio sections
select one section
extract section
remove diagram and padding
regenerate base 64 string
=cut

my ($file_name) = @_ ;

my ($header, $footer) = ('', '') ;

eval "use Pod::Select ; use Pod::Text;" ;
die $@ if $@ ;

open INPUT, '<', $file_name or die "get_base64_data: Can't open '$file_name'!\n" ;
open my $out, '>', \my $all_pod or die "Can't redirect to scalar output: $!\n";

my $parser = new Pod::Select();
$parser->parse_from_filehandle(\*INPUT, $out);

$all_pod .= '=cut' ; #add the =cut taken away by above parsing

my @guiio_pods ;

while($all_pod =~ /(^=.*?(?=\n=))/smg)
	{
	my $section = $1 ;
	if($section =~ s/^=for guiio\s*//i) 
		{
		push @guiio_pods, "=for guiio $section" ;
		last ;
		}
	}

#todo: handle files without guiio section
#todo: handle files with multiple guiio sections

my $guiio_section = $guiio_pods[0] ;
my @guiio_lines = split "\n", $guiio_section ;
my $guiio_header = shift @guiio_lines ;

#~ use Data::TreeDumper ;
#~ print DumpTree \@guiio_lines, 'guiio_lines' ;

my $whole_file = read_file($file_name) ;

if($whole_file =~ /(.*)$guiio_header.*?(\n=.*)/sm)
	{
	($header, $footer) = ($1, $2) ;
	}
else
	{
	die "get_base64_data: Can't find the text we just extracted!" ;
	}
	
my ($for, $guiio, $width, $name) = split ' ', $guiio_header ;

my $base64 = '' ;

for my $guiio_line (@guiio_lines)
	{
	substr($guiio_line, 0, $width + $BASE64_HEADER_SIZE + 1, '') ; # strip to base64
	$base64 .= $guiio_line . "\n" ;
	}

return ($base64, $header, $footer) ;
}

#----------------------------------------------------------------------------------------------------------------------------

sub export_pod
{
my ($self, $elements_to_save, $file, $data)  = @_ ;

my ($base_name, $path, $extension) = File::Basename::fileparse($file, ('\..*')) ;
my $file_name = $base_name . $extension ;

my @ascii_representation = $self->transform_elements_to_ascii_array() ;
my $longest_line =  max( map{length} @ascii_representation) ;

my $compressed_self = compress($self->serialize_self() .  '$VAR1 ;') ;

my $base64 =MIME::Base64::encode($compressed_self, '') ;
my $base64_chunk_size = int((length($base64) / @ascii_representation) + 1) ;

if($self->{CREATE_BACKUP} && -e $file)
	{
	use File::Copy;
	copy($file,"$file.bak") or die "export_pod: Copy failed while making backup copy: $!";		
	}

open POD, ">:encoding(utf8)",  $file_name or die "export_pod: can't open file '$file_name'!\n";

print POD $data->{HEADER} || '' ;
print POD "=for guiio $longest_line $base_name\n\n" ;

for my $diagram_line (@ascii_representation)
	{
	my $padding = ' ' x ($longest_line - length($diagram_line)) ;
	my $base64_chunk = substr($base64, 0, $base64_chunk_size, '') || '' ;
	
	print POD ' ' ,  $diagram_line, $padding, $BASE64_HEADER, $base64_chunk, "\n"
	}

print POD $data->{FOOTER} || "\n=cut\n\n";
close POD ;

return $file ;
}

 
