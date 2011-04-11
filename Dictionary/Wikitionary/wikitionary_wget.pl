#!/usr/local/bin/perl -w 
use strict;

## Written by Max Bileschi, Spring 2011
## mlbileschi@gmail.com
## annotates dictionary file with parts of speech (pos)
## output format: word pos pos ... pos|frequency (those are spaces)


open(DICT, "<index.txt") or die "couldn't open file index.txt to read from";
open(DICTOUT, ">index.idx") or die "couldn't open file index.idx to write to";

my $i=1; #counts lines so will give progress vs wc -l
my $length = `wc -l index.txt`;

#annotate each item in the dictionary with parts of speech
foreach (<DICT>)
{
	my ($word, $freq) = split(/ /); #dicitonary file should have two fields delimited by spaces: word and frequency
	
	#wget entry on $word from wikitionary
	my $url = "http://en.wiktionary.org/wiki/".$word;
	#system("wget", $url, "-q", "-O", "wiktionary_lookup_file.txt");
	print "Query $i of $length  Querying Wiktionary for: $word\n"; #prints progress

	#check the wiki file for parts of speech
	open(WIKI, "<wiktionary_lookup_file.txt");
	foreach my $line (<WIKI>)
	{
		#the second check on each of the following is to prevent things like apple noun noun ...
		if($line=~/proper noun/i && $word !~ /proper noun/i)
		{
			$word.=" proper noun";
		}
		elsif($line=~/noun/i && $word !~ /noun/i)
		{
			$word.=" noun";
		}
		#need to be careful because most files have the word plural, so we /plural form/
		if($line=~/plural form/i && $word !~ /plural/i)
		{
			$word.=" plural";
		}
		if($line=~/verb/i && $word !~ /verb/i)
		{
			$word.=" verb";
		}
		if($line=~/adjective/i && $word !~ /adjective/i)
		{
			$word.=" adjective";
		}
		if($line=~/adverb/i && $word !~ /adverb/i)
		{
			$word.=" adverb";
		}
		if($line=~/preposition/i && $word !~ /preposition/i)
		{
			$word.=" preposition";
		}
	}

	print DICTOUT $word." \| ".$freq."\n";
	
	close(WIKI);	
	$i++;
}

close(DICT);
close(DICTOUT);

#### ideas


#possibly useful later when we want to search for a capitalized proper noun version of the current word:
#	my $cap_word =~ s/\b(\w+)\b/ucfirst($1)/ge; 
	#checking for proper noun
	#possibly come back when you can think of a better way......
#	$url = "http://en.wiktionary.org/wiki/".$word;
#	system("wget", $url, "-q","-O", "wiktionary_lookup_file.txt");
#	print "Query $i of $length  Querying Wiktionary for: $word\n";
#	open(WIKI, "<wiktionary_lookup_file.txt");
#	foreach my $line (<WIKI>) {}
