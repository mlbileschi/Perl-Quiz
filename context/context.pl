#!/usr/local/bin/perl
use strict;
#warnings??
use Getopt::Long;

## Written by Max Bileschi, Summer 2011
## mlbileschi@gmail.com
## creates context, fill-in-the-blank questions. non-multiple choice.

#TODO Months, what about ? and ! to end sentences?
#TODO make qfile and Countries non-case sensitive

die "wrong number of parameters from comand line \n
usage:  executable  [target word] <input text file> \n"
unless ($#ARGV>=0);

my $infile=$ARGV[1];
open(INFILE, "<$infile") or die "Can't open infile $infile\n";

#######MAIN#######

#open dicitonary files don't use if ($years) | ($countries) ($qfile)
open(DICTIONARY, "<./../curate/index_regex2.idx") or die "Can't open dicitonary file index_regex2.idx\n";
my @dict = <DICTIONARY>;

#open an output file with html format
open(OUT, ">context_questions.txt") or die "Can't open file to write to";

my @file = <INFILE>; #the file you are making quizes out of (different file than the rest of the file names refer to)
my %hdict=(); #TODO
my %localfreq=(); #key is the word and the value is the local freqency (number of times apearing in the document)
my @topwords=(); #list of the highest relative frequency words in the document (#TODO)
my @line = (); #used for parsing the dictionary/determining localfreq 
my $target = $ARGV[0]; #word we want to write context questions about
my %context = (); #hash of words which form a "context" around $target


#read each line from the dictionary file, then put into a hash
# whose key is the word, and whose value is a two-elt array
# which is (parts of speech, frequency)
foreach (@dict)
{
	$_ =~ s/\r|\n//g; #the new chomp
	my @line = split(/\t/, $_); #tab delmimited

	my $word = $line[0];	#pop first elt off
	my $pos=$line[1];

	$hdict{$word}=[$pos, $line[2]];	#key is word, value is (part of speech, freq)
}

foreach(@file)
{
	$_ =~ s/\r|\n//g; #the new chomp
	@line = split(/ /, $_);
	foreach my $token (@line)
	{
#TODO change the regex to accept words in quotes, bracket?, parens, both, brackets number after, and other combinations (" ," ,[3] ." ") : ; ' ? ! (> < / \)?	
#TODO allow for hyphen in the word? break it into two words?
#TODO check to see if the next word after any comb of ! . ? with an optional " is in the dict, otherwise check the lowercase of that word instead, else set freq to one of the upper case word, or ignore?
		if($token =~ /^[A-Za-z]+[\.,]?$/)
		{
			chop($token) if ($token =~ /[\.,]+$/);	#chop that punctuation right off of there
			if(exists($localfreq{$token}))			#increase frequency/add depending if seen. #TODO different casings of same word fix
			{
				$localfreq{$token}++;
			}
			else
			{	#we need to count word relevence by proximity (THAT'S FANCY!)
				$localfreq{$token} = 1;
			}
		} 
	}
}

#compute relative frequencies
foreach my $key ( keys(%localfreq) ) 
{
	if(!exists($hdict{lc($key)}))
	{
		$localfreq{$key}=0;		#possibly add it with a really high value?
	} 
	else
	{	
		$localfreq{$key} = ($localfreq{$key})/(@{$hdict{lc($key)}}[1]);  #tricky syntax because of array references in hash table
	}
}
#add each of the keys in decreasing order to @topwords
foreach my $key (sort {$localfreq{$b} <=> $localfreq{$a}} keys(%localfreq)) 
{
	print "$key, ".@{$hdict{$key}}[0].", $localfreq{$key}\n";		#TODO possibly print if --verbose
	push(@topwords, $key);
}
#foreach (@topwords) { print "topword: $_\n"; } #TODO possibly print if --verbose / for troubleshooting


#read file into sentences
my $wholefile = "";
foreach (@file)
{
	$_ =~ s/\r|\n//g; #the new chomp
	$wholefile.=$_." ";
}

my @sentences = split(/\.["]?(\[\d+\])?\s+/, $wholefile); #split into sentences

#foreach sentence we need to count word relevence by proximity (THAT'S FANCY SOUNDIN!)
foreach my $sentence (@sentences)
{
	if($sentence!~m/$target/i)
	{
		next;
	}
	else
	{
		#split sentence into an array of words
		my @words = split(/[?'"]? /,$sentence);
		#find the index of $target within words
		my $location = -1; #will need some sort of array or something for multiple occurrences
		for my $i (0..$#words)
		{
			if ($words[$i]=~m/$target/i)
			{
				$location = $i;
				last;
			}
		}
		print "there was an error in finding the index" if ($location == -1); #because we should never get here, 
																						#unless the word is part of another word
		foreach my $i (0..$#words)
		{
			next if ($i==$location);
			my $currword = $words[$i];
			if ($localfreq{$currword}>.001) #i.e. is relatively ... relevant
			{											#but i'm worried about words which aren't in hdict...
				$context{$currword} += (1/(abs($i-$location))*$localfreq{$currword});
			}
		}
	}
}


foreach my $key (sort( {$context{$b} <=> $context{$a}} keys(%context)))
{
	print OUT "word = $key | value = $context{$key}\n";
}
############################
######### END MAIN #########
############################

close(OUT);
close(INFILE);
close(DICTIONARY);
