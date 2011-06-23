#!/usr/local/bin/perl -w
use strict;

##NOTE! OUTDATED BECAUSE THIS WAS FOR WORDNET, WHICH SUCKS

## Written by Max Bileschi, Spring 2011
## mlbileschi@gmail.com


#die "wrong number of parameters from comand line \n
#usage:  executable <input biology file> \n" unless $#ARGV==0;


open(INFILE, "<defstmp.txt");
open(OUTFILE, ">pos.txt");

my $firsttime=1;
my $toprint = "";
my $word ="";
foreach my $line (<INFILE>)
{
	chomp($line);
	if($line=~/\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-/)
	{
      	    $word = $';
            if (!$firsttime)
            {
                  print OUTFILE "\n";
            }
            $firsttime=0;
	    print OUTFILE "$word"
	}
	#note case sensitive Information doesn't hit on no matches
	if( $line =~ $word  &&
	    $line =~ /Information available for / )
	{
		my @tokens = split(/ /, $');
		print OUTFILE " ".$tokens[$#tokens-1];
	}
	
}

close(INFILE);
close(OUTFILE);

