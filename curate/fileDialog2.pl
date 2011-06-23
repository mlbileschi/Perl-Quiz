#!/usr/local/bin/perl
use Tk;
use strict;

# Main Window
my $mw = new MainWindow;
my $lab = $mw -> Label(-text=>"Enter a file you'd like to write a quiz about:",
		-font=>"ansi 12") -> grid(-row=>1,-column=>1);
my $types = [ ['textfiles', '.txt'], #accepted filetypes
							['All Files',	 '*'],];

#Text Area
my $txt = $mw -> Text(-width=>50, -height=>1) -> grid(-row=>2,-column=>1);

my $but = $mw -> Button(-text=>"Browse...", -width=>20, 
		-command=>\&openFile)	-> grid(-row=>2,-column=>2);
my $quit = $mw->Button(-text=>"Quit", -command => \&exitTheApp)-> grid(-row=>3,-column=>2);
my $okay = $mw->Button(-text=>"OK", -command => \&acceptFile)-> grid(-row=>3,-column=>1);

MainLoop;


sub openFile {
	my $open = $mw->getOpenFile(-filetypes => $types);
	#print qq{You chose to open "$open"\n} if $open;
	$txt -> insert('end',$open);
}

sub acceptFile {
	print($txt->get("1.0", 'end'));
	exit;
}

sub exitTheApp {
		exit;
}
