#!/usr/local/bin/perl -w 
#use strict;
use Getopt::Long;
 
## Written by Max Bileschi, Spring 2011
## mlbileschi@gmail.com
## creates questions

#TODO optional character after regex, like comma or period. some answers not appearing

#update Feb 25: takes one OR two CL args, to write questions about a specific thing
#update Feb 26: takes CL option --qword, --numbers
#update Feb 27: looks at every number match in a sentence, not just the first. also changed --numbers to --years


die "wrong number of parameters from comand line \n
usage:  executable   <input text file> [options] \n    OPTIONS:
--qword=<word you want a question about> (will be overriden by --years)\n
--years (will target years instead of text. Will override the qword option)\n"
unless ($#ARGV>=0);


my $infile=$ARGV[0];
open(INFILE, "<$infile") or die "Can't open infile $infile\n";
shift(@ARGV);

open(DICTIONARY, "<index.txt") or die "Can't open dicitonary file index.txt\n";
open(TIMEPREPS, "<time_preps.txt") or die "Can't find time preposition dictionary time_preps.txt\n";

my $qword; my $years;
GetOptions ("qword=s" => \$qword, "years" => \$years) or die "Whups, got options we don't recognize!";
$qword=lc($qword);

my @dict = <DICTIONARY>;
my %hdict=();

my %localfreq=();

my @file = <INFILE>;

my $total=0;
my @line = ();


foreach (@dict)
{
	chomp;
	@line = split(/ /, $_); 

	$hdict{$line[0]}=$line[1]/8382231; #key is word, value is freq
	$total+=$line[1];
}



$total=0;
foreach(@file)
{
	chomp;
	@line = split(/ /, $_);
	$total+=$#line+1;
	foreach my $token (@line)
	{
		if($token =~ /^[A-Za-z]+[\.,]?$/)
		{
			chop($token) if ($token =~ /[\.,]+$/);
			$token = lc($token);
			if(exists($localfreq{$token}))
			{
				$localfreq{$token}++;
			}
			else
			{
				$localfreq{$token} = 1;
			}
		} 
	}
}


#compute relative frequencies
foreach my $key ( keys(%localfreq) ) 
{  
	if(!exists($hdict{$key})){ print "word $key is not in hdict\n";  } #possibly add it with a really high value?
	else {	$localfreq{$key}= ($localfreq{$key}/$total)/($hdict{$key}); }
}




#now read by sentence and create questions



my $wholefile = "";
#read file into sentences
foreach (@file)
{
	chomp;
	$wholefile.=$_;
}

my @topwords=();
foreach my $key (sort {$localfreq{$b} <=> $localfreq{$a}} keys(%localfreq)) {
   

#     print "$key $localfreq{$key}\n";

     push(@topwords, $key);
}

my $timeprepregex="";
if($years) #read in time prepositions
{
	foreach(<TIMEPREPS>)
	{
		chomp;
		$timeprepregex.="(".$_.")\|";
	}
}
chop($timeprepregex); #take last "|" off


sub years
{
	my @matches = ();
	#POSSIBLE SPACE PROBLEMS HERE
	if(($_ =~ $timeprepregex) && (@matches = $_=~m/[\s+,\(\-](\d+)[\.,\s+\-\)]?/g))# || $_=~/^[0-9]+\s/)
	{
		#foreach (@matches) { print $_; }
		foreach $match (@matches)
		{
			print "correct answer: $match\n";
			my @tokens = split(/\s+/, $_);
			foreach my $word (@tokens)
			{
				if($word =~ $match)
				{
					#print " ".$` unless $` eq " "; #in case the number has brackets around it or something stupid
					print "_______________";
					print $'." " unless $' eq " "; #in case the number was followed by puncutation
				}
				else
				{
					print $word." ";
				}
			}
			print "\n";
			my %numberchoice=(); #hash of randoms chosen
			my $correct = int(rand(5));
			$numberchoice{$match}=0;
		
			#make 4 random candidate numbers
			#first
			my $one=$match; my $two=$match; my $three=$match; my $four=$match;
			my $MOST_TRIES=25;
			if( 1)#$match>10 )
			{
				my $posneg = (-1)**int(rand(2));
				while(exists($numberchoice{$one})) { $one = $match + $posneg*int(rand(sqrt($match*10))); $MOST_TRIES--; if($MOST_TRIES<=0) { $one = int(rand(100));} }
				$numberchoice{$one}=0;
				$posneg = (-1)**int(rand(2));
				while(exists($numberchoice{$two})) { $two = $match + $posneg*int(rand(sqrt($match*5))); $MOST_TRIES--; if($MOST_TRIES<=0) { $two = int(rand(100));}}
				$numberchoice{$two}=0;
				$posneg = (-1)**int(rand(2));
				while(exists($numberchoice{$three})) { $three = $match + $posneg*int(rand(sqrt($match*2))); $MOST_TRIES--; if($MOST_TRIES<=0) { $three = int(rand(100));}}
				$numberchoice{$three}=0;
				$posneg = (-1)**int(rand(2));
				while(exists($numberchoice{$four})) { $four = $match + $posneg*int(rand(sqrt($match))); $MOST_TRIES--; if($MOST_TRIES<=0) { $four = int(rand(100));}}
				$numberchoice{$four}=0;
 			}
			my @pre = ( $match, $one, $two, $three, $four );
			my @post = ();

			for (my $i=5; $i>=1; $i--)
			{
				my $choice = int(rand($i));
				push(@post, $pre[$choice]);
				splice(@pre,$choice,1);
			}




			for my $j (1..5)
			{
					print "$j \. $post[$j-1]\n"; #print answers
			}
		}
	}
}

sub qword
{
	if(! exists( $localfreq{$qword} ) )
	{
		print "\n$qword is not in $infile\n\n";
		last;
	}
	if(! exists( $hdict{$qword} ) )
	{
		print "\n$qword is not in index.txt\n\n";
		last;
	}

	#if it's the first time, we have problems if it's not preceded by a space
	if($_=~/\s+$qword[\.,\s+]?/i || $_=~/^$qword\s/i)
	{
		print "correct answer: $qword\n";
		my @tokens = split(/\s+/, $_);
		foreach my $word (@tokens)
		{
			if (!($word =~ /^$qword/i))
			{
				print $word." ";
			}
			else
			{
				print "___________________ ";
				print $'." " unless $' eq " "; #in case the word was followed by puncutation
			}
		}
		print "\n";
		my %numberchoice=(); #hash of randoms chosen
		my $correct = int(rand(5))+1;
	
		my $index_in_topwords= grep { lc($topwords[$_]) eq $qword } 0..$#topwords;

		$numberchoice{ $index_in_topwords }=0;
	
		for my $j (1..5)
		{
			if($j==$correct)
			{
				print "$j \. $qword\n";
			}
			else
			{
				my $random=$correct;
				while ( exists($numberchoice{$random}) || $topwords[$random] eq lc($qword) )
				{
					$random=int(rand(20)); #how far into @topwords i want to look for wrong answers
				}
				$numberchoice{$random}=0;
				print "$j \. $topwords[$random]\n"; #print correct output
			}
		}
	}
}


#default, i.e. if no command line parameters
sub default
{
	#ten of top words
	for my $i (0..10)
	{
		if(! exists( $hdict{$topwords[$i]} ) )
		{
			print "\n$topwords[$i] is not in index.txt\n\n";
			next;
		}
		
		if($_=~/\s+$topwords[$i]\s/i)
		{
			print "correct answer: $topwords[$i]\n";
			my @tokens = split(/\s+/, $_);
			foreach my $word (@tokens)
			{
				if (!($word =~ /^$topwords[$i]/i))
				{
					print $word." ";
				}
				else
				{
					print "___________________ ";
					print $'." " unless $' eq " "; #in case the word was followed by puncutation
				}
			}
			print "\n";
			my %numberchoice=(); #hash of randoms chosen
			my $correct = int(rand(5))+1;
		
			$numberchoice{$i}=0;
		
			for my $j (1..5)
			{
				if($j==$correct)
				{
					print "$j \. $topwords[$i]\n";
				}
				else
				{
					my $random=$correct;
					while ( exists($numberchoice{$random} ) )
					{
						$random=int(rand(20)); #how far into @topwords i want to look for wrong answers
					}
					$numberchoice{$random}=0;
					print "$j \. $topwords[$random]\n"; #print correct output
				}
			}
		}
	}
}

	
my @sentences = split(/\./, $wholefile);
foreach(@sentences)
{

	if($years)
	{
		&years
	}

	#find only specific questions
	elsif($qword)
	{
		&qword;
	}

	#print questions about each of the top words
	else
	{
		&default;
	}
}




close(INFILE);
close(DICTIONARY);
