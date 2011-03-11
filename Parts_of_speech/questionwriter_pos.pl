#!/usr/local/bin/perl
use strict;
#warnings??
use Getopt::Long;

## Written by Max Bileschi, Spring 2011
## mlbileschi@gmail.com
## creates questions

#TODO Months
#don't need to do hdict if --years /optimization/
# what about ? and ! to end sentences?



die "wrong number of parameters from comand line \n
usage:  executable   <input text file> [options] \n    OPTIONS:
--qword=<word you want a question about> (will be overriden by --years)\n
--years (will target years instead of text. Will override the qword option)\n"
unless ($#ARGV>=0);


my $infile=$ARGV[0];
open(INFILE, "<$infile") or die "Can't open infile $infile\n";
shift(@ARGV);	#we have to pop off the first @ARGV element because otherwise it will screw
					#with Getopt::Long::GetOptions below.

#flags for what "mode" we will be in.
#qword will call sub &qword and will write questions only about a specific word
#years tells us whether to target numbers in the text, and to treat them as years when near a time preposition
#we then get these options from the command line input.
my $qword; my $years; 
GetOptions ("qword=s" => \$qword, "years" => \$years) or die "Whups, got options we don't recognize!";
#$qword=lc($qword);



#######MAIN#######



	#open dicitonary files don't use if ($years)
	open(DICTIONARY, "<index_regex2.idx") or die "Can't open dicitonary file index_regex2.idx\n";
	my @dict = <DICTIONARY>;
 

my %hdict=();
my %localfreq=();
my @topwords=();
my @file = <INFILE>;
my $total=0;
my @line = ();
my $timeprepregex="";


if(!$years)
{

	#read each line from the dictionary file, then put into a hash
	# whose key is the word, and whose value is a two-elt array
	# which is (parts of speech, frequency)
	foreach (@dict)
	{
		chomp;
		my @line = split(/\t/, $_); 			#to the left of the | is word(space)pos(space)....

		my $word = $line[0];	#pop first elt off
		my $pos=$line[1];

		$hdict{$word}=[$pos, $line[2]/8382231];	#key is word, value is (part of speech, freq)#possibly add it with a really high value?
																#want to change the denominator if you care, which is no longer the number of words spotted.
	#	$total+=$line[1]; #for counting the number of word occurrences in the dictionary
	}

	#$total=0; #the number of words in the input text file

	#for each 
	foreach(@file)
	{
		chomp;
		@line = split(/ /, $_);
	#	$total+=$#line+1; for counting the number of lines
		foreach my $token (@line)
		{
			if($token =~ /^[A-Za-z]+[\.,]?$/)
			{
				chop($token) if ($token =~ /[\.,]+$/);	#chop that punctuation right off of there
	#			$token = lc($token);							#treat words as all lower case for now
				if(exists($localfreq{$token}))			#increase frequency/add depending if seen.
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
		if(!exists($hdict{lc($key)}))
		{
			$localfreq{$key}=0;		#possibly add it with a really high value?
			print "word $key is not in hdict\n";
		} 
		else
		{	
			$localfreq{$key} = ($localfreq{$key})/(@{$hdict{lc($key)}}[1]);  #tricky syntax because of array references in hash table
		}
	}

	#add each of the keys in decreasing order to @topwords
	foreach my $key (sort {$localfreq{$b} <=> $localfreq{$a}} keys(%localfreq)) 
	{
	#	print "$key, ".@{$hdict{$key}}[0].", $localfreq{$key}\n";		#possibly print if --verbose
		push(@topwords, $key);
	}
	#foreach (@topwords) { print "topword: $_\n"; } #possibly print if --verbose / for troubleshooting

}

if ($years)
{
	#use only if $years
	open(TIMEPREPS, "<time_preps.txt") or die "Can't find time preposition dictionary time_preps.txt\n";

	#do this only if --years.

	if($years) #read in time prepositions
	{
		foreach(<TIMEPREPS>)
		{
			chomp;
			$timeprepregex.="( ".$_." )\|";	#this way they can be a regex of "or" expressions
														#like (in)|(during)|...
		}
	}
	chop($timeprepregex); 			#to take last "|" off
}



#read file into sentences
my $wholefile = "";
foreach (@file)
{
	chomp;
	$wholefile.=$_." ";
}
my @sentences = split(/\."?\s+/, $wholefile);

#foreach sentence, create the requested/relevant question
#possibly change to calling each of the subs below with parameters instead
#of depending on $_ to work properly
foreach my $sentence (@sentences)
{
	$sentence.="\.";
	if($years) 
	{
		&years($sentence);
	}

	#find only specific questions
	elsif($qword)
	{
		&qword($sentence);
	}

	#print questions about each of the top words
	else
	{
		&default($sentence);
	}
}

######### END MAIN #########
####### SUBROUTINES ########
sub years
{
	my @matches = ();
	my $sentence = $_[0];

	#if sentence has a time preposition
	# and if sentence has a digit in one of the predetermined formats
	#            digits
	#          (digits) 
	# (digit,digit) etc.
	#also, @matches gets each digit match per sentence.
	if(($sentence =~ $timeprepregex) && (@matches = $sentence=~m/[^(,\d)][\s+,\(\-](\d+)[\.\s+\-\)]?[^(,\d+)( years)]/ig))
	{
		foreach my $match (@matches)
		{
			print "correct answer: $match "; ##correct answer with AD/BC thing?
			#account for BC in years
			if($sentence =~ /$match (BC)|(B\.C\.)|(BCE)|(B\.C\.E\.)/)
			{
				print "B\.C\.";
			}
			elsif($match<=100)
			{
				print "A\.D\.";
			}
			print "\n";
			my @tokens = split(/\s+/, $sentence);
			foreach my $word (@tokens)
			{
				if($word=~/(AD)|(BC)|(A\.D\.)|(B\.C\.)|(BCE)|(B\.C\.E\.)/) { next;}
				if($word =~ $match)
				{
					print " ".$` unless $` eq " "; #in case the number has brackets around it or something stupid
					print "_______________";
					print $'." " unless $' eq " "; #in case the number was followed by punctuation
				}
				else
				{
					print $word." ";
				}
			}
			print "\n";

			if($sentence =~ /$match (BC)|(B\.C\.)|(BCE)|(B\.C\.E\.)/)
			{
				$match = (-1)*$match;
			}

			my %numberchoice=(); #hash of randoms chosen
			my $correct = int(rand(5));

			my $lessthannow = (2011>$match);
 
			$numberchoice{$match}=0;
		
			#make 4 random candidate numbers
			#first
			#fix this:
			#			better ranges
			#			none above 2011 if the number is below 2011
			#			BC/AD
			#			check for proximity to months
			my $one=$match; my $two=$match; my $three=$match; my $four=$match;

			my $posneg = (-1)**int(rand(2));
			while(exists($numberchoice{$one}) || ($lessthannow && 2011<$one)) { $one = $match + $posneg*(int(rand(50))+50); }
			$numberchoice{$one}=0;
			$posneg = (-1)**int(rand(2));
			while(exists($numberchoice{$two}) || ($lessthannow && 2011<$two)) { $two = $match + $posneg*(int(rand(40))+10); }
			$numberchoice{$two}=0;
			$posneg = (-1)**int(rand(2));
			while(exists($numberchoice{$three}) || ($lessthannow && 2011<$three)) { $three = $match + $posneg*int(rand(25)); }
			$numberchoice{$three}=0;
			$posneg = (-1)**int(rand(2));
			while(exists($numberchoice{$four}) || ($lessthannow && 2011<$four)) { $four = $match + $posneg*int(rand(10)); }
			$numberchoice{$four}=0;

			#shuffle answers
			my @pre = ( $match, $one, $two, $three, $four );
			my @post = ();
			for (my $i=5; $i>=1; $i--)
			{
				my $choice = int(rand($i));
				push(@post, $pre[$choice]);
				splice(@pre,$choice,1);
			}

			#print multiple-choice answers
			for my $j (1..5)
			{
				if($match>99)
				{
					print "$j \. $post[$j-1]\n";
				}
				elsif($post[$j-1]<0) #note that the conditions are exclusive
				{ 
					print "$j \. ".(-1)*$post[$j-1]." B.C.\n";
				}
				else
				{
					print "$j \. $post[$j-1] A.D.\n";
				}
			}
		}
	}
}

sub qword
{
	my $sentence = $_[0];
	#we can't write a question about a word that's not there
	if(! exists( $localfreq{$qword} ) )
	{
		print "\n$qword is not in $infile. Is your case right? Caps-Lock?\n\n";
		last;
	}
	#not quite sure how to handle these cases right now
	if(! exists( $hdict{lc($qword)} ) )
	{
		print "\n$qword is not in dictionary file.\n\n";
		last;
	}

	#if qword appears in the text in a logical way, then proceed
	if($sentence=~/\s+$qword[\.,\s+]?/i || $sentence=~/^$qword\s/i)
	{
		print "correct answer: $qword\n";
		my @tokens = split(/\s+/, $sentence);
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

		#find other candidate answers from @topwords
		my %numberchoice=(); #hash of randoms chosen
		my $correct = int(rand(5))+1; #which answer is the correct one


	
		my $maxtries=50;

		for my $j (1..5)
		{
			if($j==$correct)
			{
				print "$j \. $qword\n";
			}
			else
			{
				my $random=$correct;
				#goes until a new topword is chosen
				if(@{$hdict{lc($qword)}}[0] ne "")
				{
					while ( $maxtries>0		#just in case we can't match parts of speech we have a sentinel
								&& ( exists($numberchoice{$random})	#while we've already chosen this word
								|| ($topwords[$random] eq lc($qword)) #and it's not the correct answer
								|| @{$hdict{$topwords[$random]}}[0]!~@{$hdict{lc($qword)}}[0]   ) #and it doesn't match the part of speech
								 )
					{
						$random=int(rand(20)); #how far into @topwords i want to look for candidate answers
						$maxtries--;
					}
				}
				#unable to match parts of speech, indicated by print *
				if($maxtries<=0 || @{$hdict{lc($qword)}}[0] eq "")
				{
					#print "Unable to match parts of speech in this question.\n";
					print "*"; 
					while ( exists($numberchoice{$random}) ||	$topwords[$random] eq lc($qword) )
					{
						$random=int(rand(20)); #how far into @topwords i want to look for candidate answers
					}						
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
	my $sentence = $_[0];
	#ten of top words
	for my $i (0..10)
	{
		if(! exists( $hdict{lc($topwords[$i])} ) )
		{
			print "\n ".lc($topwords[$i])." is not in dictionary file.\n\n";
			next;
		}
		my $tempregex = $topwords[$i];
		if($sentence=~/\s+$tempregex[\.,\s+]?/i)
		{
			my @tokens = split(/\s+/, $sentence);
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
			print "correct answer: $topwords[$i]\n";



			#find other candidate answers out of @topwords
			my %numberchoice=(); #hash of randoms chosen
			my $correct = int(rand(5))+1; #where the correct answer will appear in the others
			$numberchoice{$i}=0; 
		
			my $maxtries=50;

			#find and print all answers
			for my $j (1..5)
			{
				if($j==$correct) #print the correct answer
				{
					print "$j \. $topwords[$i]\n";
				}
				else
				{
					my $random=$correct;
					#goes until a new topword is chosen
					if(@{$hdict{lc($topwords[$i])}}[0] ne "")
					{
						while ( (exists($numberchoice{$random} ) #while we haven't already chosen it
								|| @{$hdict{lc($topwords[$random])}}[0]!~@{$hdict{lc($topwords[$i])}}[0]) #and it doesn't match the part of speech
								&& $maxtries>0)	#just in case we can't match parts of speech we have a sentinel
						{
							$random=int(rand(30)); #how far into @topwords i want to look for wrong answers
							$maxtries--;
						}
					}
					if($maxtries<=0 || @{$hdict{lc($topwords[$i])}}[0] eq "")
					{
#					print "Unable to match parts of speech in this question.\n";
					print "*";
						while ( exists($numberchoice{$random} ) )
						{
							$random=int(rand(20)); #how far into @topwords i want to look for wrong answers
						}						
					}
					$numberchoice{$random}=0;
					print "$j \. $topwords[$random]\n"; #print correct output
				}
			}
		}
	}
}


close(INFILE);
close(DICTIONARY);
