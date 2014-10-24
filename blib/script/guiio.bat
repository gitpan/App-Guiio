@rem = '--*-Perl-*--
@echo off
if "%OS%" == "Windows_NT" goto WinNT
perl -x -S "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
:WinNT
perl -x -S %0 %*
if NOT "%COMSPEC%" == "%SystemRoot%\system32\cmd.exe" goto endofperl
if %errorlevel% == 9009 echo You do not have Perl in your PATH.
if errorlevel 1 goto script_failed_so_exit_with_non_zero_val 2>nul
goto endofperl
@rem ';
#!C:\camelbox\bin\perl.exe -w
#line 15

package main ;

use strict;
use warnings;

use Glib ':constants';
use Gtk2 -init;
Gtk2->init;

use App::Guiio ;

#-----------------------------------------------------------------------------

my $window = Gtk2::Window->new('toplevel');
$window->set_title("GUIIO");
$window->set_default_size(640, 480) ;
$window->signal_connect("destroy", sub { exit(0); });

my @guiios ;

my $guiio = new App::Guiio(0, 0) ;
push @guiios, $guiio ;

my $vbox = Gtk2::VBox->new (FALSE, 0);
my $hcontentbox = Gtk2::HBox->new(FALSE, 0);

$window->add($vbox);

my $hpaned = Gtk2::HPaned->new;
$vbox->pack_start($guiio->create_GUIIOMenu()->{widget},FALSE, FALSE, 0);

$hcontentbox->pack_start($guiio->display_component_palette(), FALSE, FALSE, 0);
$hcontentbox->pack_start($hpaned, TRUE, TRUE, 0);
$hcontentbox->show_all();
$vbox->pack_start($hcontentbox,TRUE,TRUE,0);
$hpaned->set_border_width (3);


$hpaned->add1($guiio->{widget});
$vbox->show_all();
$window->show();
$guiio->{widget}->grab_focus();
$guiio->{widget}->signal_connect('focus-out-event',sub { $guiio->{widget}->grab_focus();});
my ($command_line_switch_parse_ok, $command_line_parse_message, $guiio_config)
	= $guiio->ParseSwitches([@ARGV], 0) ;

die "Error: '$command_line_parse_message'!" unless $command_line_switch_parse_ok ;

$guiio->setup($guiio_config->{SETUP_INI_FILE}, $guiio_config->{SETUP_PATH}) ;

my ($character_width, $character_height) = $guiio->get_character_size() ;

if(defined $guiio_config->{TARGETS}[0])
	{
	$guiio->run_actions_by_name(['Open', $guiio_config->{TARGETS}[0]]) ;
	}
	
$guiio->set_modified_state(0) ;
$guiio->run_script($guiio_config->{SCRIPT}) ;
	
#--------------------------------------------------------------------------

$window->signal_connect (delete_event => \&delete_event, \@guiios) ;

sub delete_event
{
my ($window, $event, $guiios) = @_;
my $answer = 'yes';

my $should_save ;
for my $guiio (@{$guiios})
	{
	$should_save++ if $guiio->get_modified_state() ;
	}
	
if($should_save) 
	{
	$answer = App::Guiio::display_quit_dialog($window, 'guiio', ' ' x 25 . "Document is modified!\n\nAre you sure you want to quit and lose your changes?\n") ;
	}
	
if($answer eq 'save_and_quit')
	{
	for my $guiio (@{$guiios})
		{
		my @saved_result = $guiio->run_actions_by_name('Save') ;
		
		$answer = 'cancel' if(! defined $saved_result[0][0] || $saved_result[0][0] eq '') ;
		}
	}
	
return $answer eq 'cancel';
}

#--------------------------------------------------------------------------

Gtk2->main();

__END__
:endofperl
