#!/usr/local/bin/perl
use strict;
require HTML::Parser;   

package MyParser;

@MyParser::ISA = qw(HTML::Parser);	#extend HTML::Parser class... error?



my %globalhash = ();
my %globalfreqs = ();

my $num_articles = 1000;
for my $i (1..$num_articles)
{
	print "$i of $num_articles\n";

	my %localhash = ();

	system("wget", "http://en.wikipedia.org/wiki/Special:Random", "-O", "wikipedia_random_article.html", "-q");
	open(INFILE, "<wikipedia_random_article.html") or die "couldn't open file wikipedia_random_article.html";

	my $parser = MyParser->new;				#new instance of this class

	$parser->parse_file('wikipedia_random_article.html');
	  
	my $file = $parser->{TEXT};

	my @tokens = split(/ /, $file);

	foreach my $token (@tokens)
	{
		$token = lc($token);	#yes?
		if($token=~/^[A-Za-z]+[,\.\?\!]?$/)
		{
			if($token=~/[,\.\?\!]/)
			{
				chop($token);
			}
			$localhash{$token} = 1;	#default is nonexistent/zero
			$globalfreqs{$token}++;
		}
	}
	
	foreach my $key (keys(%localhash))
	{
		$globalhash{$key}++;
	}

	close(INFILE);
	
}


open (OUTFILE, ">common_wikipedia_words.txt") or die "couldn't open file";
foreach ( sort {$globalhash{$b} <=> $globalhash{$a}}  keys(%globalhash))
{
	print OUTFILE "$_\t$globalhash{$_}\t$globalfreqs{$_}\n";
}

sub text
 {
   my ($self,$text) = @_;

   $self->{TEXT} .= $text;
 }
