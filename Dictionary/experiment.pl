#!/usr/local/bin/perl -w
use strict;
require HTML::Parser;   

   package MyParser;


  
open(INDEX, "<dictionary20110411.txt") or die "couldn't open file dictionary20110411.txt to read from\n";
my %whash=();	#(key,value) = (word, (part of speech, frequency))

#read dictionary.txt into whash
foreach (<INDEX>)
{
	chomp;
	my @key_value=split(/\t/, $_);
	if($#key_value == 1)
	{
		$whash{$key_value[0]}=["", $key_value[1]];	
	}
	else
	{
		$whash{$key_value[0]}=[$key_value[1],$key_value[2]];
	}
}
close(INDEX);

@MyParser::ISA = qw(HTML::Parser);	#extend HTML::Parser class... error?

print "\n";

my $num_articles=10;
for my $i (1..$num_articles)
{

	print $i." of $num_articles\n";		#print progress

	#wget and open a random wikipedia article
	system("wget", "http://en.wikipedia.org/wiki/Special:Random", "-O", "wikipedia_random_article.html", "-q");
	open(INFILE, "<wikipedia_random_article.html") or die "couldn't open file wikipedia_random_article.html\n";

   my $parser = MyParser->new;				#new instance of this class

   $parser->parse_file('wikipedia_random_article.html');

   
   my $file = $parser->{TEXT};

	#read file into sentences
	$file = join("\. ", (split(/\n+/,$file)));
	my @sentences = split(/\.\"?\s+/, $file);


	foreach my $sentence (@sentences)
	{
		if($sentence eq "")
		{
			next;
		}
		my @line = split(/ /, $sentence);

		if($line[0]=~/^[A-Za-z]+[,\.\?\!]?$/)
		{
			if(exists($whash{$line[0]}) 
					&& (
							(($whash{$line[0]}->[0])=~/proper noun/i)||
							(($whash{$line[0]}->[0])=~/initialism/i)
						)
				)
			{
				#do nothing
			}
			else
			{
				my $url = "http://en.wiktionary.org/wiki/".$line[0];
				system("wget", $url, "-q", "-O", "wiktionary_lookup_file.html");

				my $keep_capitalize=0;
				#check the wiki file for parts of speech
				#if it's not a proper noun and it's at the beginning of a sentence, uncapitalize it
				open(WIKI, "<wiktionary_lookup_file.html") or die;

				foreach my $wiki_line (<WIKI>)
				{
					if(($wiki_line=~/proper noun/i)||($wiki_line=~/initialism/i))
					{
						$keep_capitalize=1;
					}
				}
				close(WIKI);
				if($keep_capitalize==0)
				{
	#				print "in here, word is $line[0]\n"; #debugging
					$line[0]=lc($line[0]);
				}
			}
		}

		foreach my $token (@line)
		{
			if($token=~/^[A-Za-z]+[,\.\?\!]?$/)
			{
				if($token=~/[,\.\?\!]/)
				{
					chop($token);
				}
				if(exists($whash{$token}))
				{
					($whash{$token}->[1])++;
				}
				else
				{
					my $url = "http://en.wiktionary.org/wiki/".$token;
					system("wget", $url, "-q", "-O", "wiktionary_lookup_file.html");

					my $keep_capitalize=0;
					#check the wiki file for parts of speech
					#if it's not a proper noun and it's at the beginning of a sentence, uncapitalize it
					open(WIKI, "<wiktionary_lookup_file.html") or die;

					($whash{$token}) = ["",1];
					my $pos = "";
					foreach my $line (<WIKI>)
					{
						#the second check on each of the following is to prevent things like apple noun noun ...
						if($line=~/proper noun/i && $pos !~ /proper noun/i)
						{
							$pos.="(proper noun)\|";
						}
						elsif($line=~/noun/i && $pos !~ /noun/i)
						{
							$pos.="(noun)\|";
						}
						#need to be careful because most files have the word plural, so we /plural form/
						if($line=~/plural form/i && $pos !~ /plural/i)
						{
							$pos.="(plural)\|";
						}
						if($line=~/verb/i && $pos !~ /verb/i)
						{
							$pos.="(verb)\|";
						}
						if($line=~/adjective/i && $pos !~ /adjective/i)
						{
							$pos.="(adjective)\|";
						}
						if($line=~/adverb/i && $pos !~ /adverb/i)
						{
							$pos.="(adverb)\|";
						}
						if($line=~/preposition/i && $pos !~ /preposition/i)
						{
							$pos.="(preposition)\|";
						}
						#seemed to give too many results.
						#if($line=~/initialism/i && $pos !~ /initialism/i)
						#{
						#	$pos.="(initialism)\|";
						#}
					}
					chop($pos);
					($whash{$token}->[0]) = $pos;
				}
			}
		}
		close(WIKI);
	}
}
system("rm", "dictionary20110411.txt");
open(OUTFILE, ">dictionary20110411.txt") or die "couldn't open file dictionary20110411.txt";
#print the dicitonary sorted alphabetically
foreach my $key ( sort(keys(%whash)) ) {
	print OUTFILE "$key\t@{$whash{$key}}[0]\t@{$whash{$key}}[1]\n";
}

sub text
 {
   my ($self,$text) = @_;

   $self->{TEXT} .= $text;
 }
