#!/usr/bin/perl -w
use strict;

## Written by Max Bileschi, Spring 2011
## mlbileschi@gmail.com
## Generates a frequency list of words as they appear in random wikipedia articles
## Output format: word freq (space delmited)
## Requires that a file "dictionary.txt" exists, even if it's empty. If it's not empty,
## requires that "dictionary.txt" must be in the form above.
## The program will read each word and frequency from "dictionary.txt" and adds them to a hash
## then runs a loop which wgets random wikipedia articles and (tries to) parse them into plaintext


open(INDEX, "<dictionary20110411.txt") or die "couldn't open file dictionary.txt to read from\n";
my %whash=();	#(key,value) = (word, frequency)

#read dictionary.txt into whash
foreach (<INDEX>)
{
	chomp;
	my @key_value=split(/\s+/, $_);
	$whash{@key_value[0]}=@key_value[1];
}
close(INDEX);

#wget the top bound on the loop no. of random wikipedia articles
for my $i (1..1)
{
	print $i."\n";		#print progress

	#wget and open a random wikipedia article
	system("wget", "http://en.wikipedia.org/wiki/Special:Random", "-O", "wikipedia_random_article.txt", "-q");
	open(INFILE, "<wikipedia_random_article.txt") or die "couldn't open file wikipedia_random_article.txt\n";
	my @filearr = <INFILE>;
	
	foreach (@filearr)
	{
		chomp;
		@line = split(/ /, $_);

		foreach my $token (@line)
		{
			if($token =~ /^[>][A-Za-z]+[<]$/)
			{
				$token = lc($token);
				#either increment the frequency or set equal to 1
				if(exists($whash{$token}))
				{
					$whash{$token}++;
				}
				else
				{
					$whash{$token} = 1;
				}
			} 
		}
	}
}


open(OUTFILE, ">dictionary20110411.txt")or die "couldn't open file dictionary.txt";
#print the dicitonary sorted alphabetically
foreach my $key ( sort(keys(%whash))) {  
	print OUTFILE "$key $whash{$key} \n";
}

close(INFILE);
close(OUTFILE);



##### IDEAS

#for when we want to be concerned about first letter's capitalization
#	my $wholefile = "";
#	#read file into sentences
#	foreach (@filearr)
#	{
#		chomp;
#		$wholefile.=$_;
#	}
#	my @sentences = split(/\./, $wholefile);

