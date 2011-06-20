#!/usr/local/bin/perl -w
use strict;

## Written by Max Bileschi, Summer 2011
## mlbileschi@gmail.com
## must be run from categories dir on the ubuntu machine




my @cats = <\/home\/maxwellb\/Documents\/questionwriter\/Perl-Quiz\/categories/*>;
foreach my $cat (@cats) {
	if (-f $cat)
	{
#		print "\nThis is a file: " . $file;
	}
	if (-d $cat) 
	{
		my @lists = glob("$cat\/*");
		my $new_dir_name = $cat."_stripped";
		system("mkdir ".$new_dir_name) if (!(-d $new_dir_name));
		foreach my $list (@lists)
		{
			print $list."\n";
			open(IN, "<$list") or die "could open file to read from";
			$list=~s/$cat//;
			open(OUT, ">$new_dir_name"."\/$list") or die "couldn't open file to write to";
			my @file_arr = <IN>;
			my $num_words_accepted = $#file_arr/10;
			for my $i (0..$num_words_accepted)
			{
				my $line = $file_arr[$i];
				$line=~tr/\r|\n//;
				my @arr = split("\t", $line);
				 
				print OUT $arr[0]."\n";
			}
		}
	}
} 



