#!/usr/local/bin/perl
use strict;
#warnings??
use Getopt::Long;
use List::MoreUtils qw(uniq);

## Written by Max Bileschi, Spring 2011
## mlbileschi@gmail.com
## creates questions, outputs to an html doc

#TODO Months, what about ? and ! to end sentences?
#TODO can explicitly request default behavior
#TODO make qfile and Countries non-case sensitive

die "wrong number of parameters from comand line \n
usage:  executable   <input text file> [options] \n    OPTIONS:
--default is the default behavior that is provided if no other flags are used. 
	Is not provided when other flags are asserted unless explicitly told to do so.\n
--qword=<word you want a question about> \n
--years (will target years instead of text.)\n
--countries (will target countries in the text.)\n
--qfile=<file path of desired question words> \n
(for qfile: each desired question word or phrase needs to be separated by a new line; only considers phrases of four words or less.)\n
(for both qfile and countries, entries are case sensitive, Countries must have proper capitalization)\n"
unless ($#ARGV>=0);

my $infile=$ARGV[0];
open(INFILE, "<$infile") or die "Can't open infile $infile\n";
shift(@ARGV);	#we have to pop off the first @ARGV element because otherwise it will screw
					#with Getopt::Long::GsetOptions below.

#flags for what "mode" we will be in.
#qword will call sub &qword and will write questions only about a specific word
#years tells us whether to target numbers in the text, and to treat them as years when near a time preposition
#countries will call sub &countries and will write questions about countries
#we then get these options from the command line input.
my $default; my $qword; my $years; my $countries; my $qfile;
GetOptions ("default"=>\$default, "qword=s" => \$qword, "years" => \$years, "countries" => \$countries, "qfile=s" => \$qfile) or die "Whups, got options we don't recognize!";
#$qword=lc($qword); #TODO

#######MAIN#######

#open dicitonary files don't use if ($years) or if ($countries)
open(DICTIONARY, "<index_regex2.idx") or die "Can't open dicitonary file index_regex2.idx\n";
my @dict = <DICTIONARY>;

#open an output file with html format
open(OUT, ">uncurated_questions.txt") or die "Can't open file to write to";


#TODO print quiz button #call it something else because print is associated with printer?
#print OUT "<input type=\"button\" id=\"PrintQuiz\" value=\"Print Quiz\" name=\"PrintQuiz\" onClick=\"printQuiz(); this\.disabled=1\">\n"; 


my %hdict=(); #TODO
my %localfreq=(); #key is the word and the value is the local freqency (number of times apearing in the document)
my @topwords=(); #list of the highest relative frequency words in the document (#TODO)
my @countries=(); #list of countries (one to four words long)
my @qfilelines=(); #list of desired answers for the qfile input (one to four words long)
my %countryans=(); #group of answers that are also countries found in the document
my %qfileans=(); #group of answers that are relevant to the desired options
my @file = <INFILE>; #the file you are making quizes on
my $total=0; #TODO ?
my @line = (); #used for parsing the dictionary/determining localfreq 
#The following regex's are in the form:  ( word )|( word )|... where the word is sometimes a phrase
my $timeprepregex=""; #for determining if the sentence could contain a date
my $countriesregex=""; #regex of all lines in the country list file
my $countriesregex2=""; #regex of two word lines in the country list file
my $countriesregex3=""; #regex of three word lines in the country list file
my $countriesregex4=""; #regex of four word lines in the country list file
my $qfileregex=""; #regex of all lines in qfile
my $qfileregex2=""; #regex of two word lines in qfile
my $qfileregex3=""; #regex of three word lines in qfile
my $qfileregex4=""; #regex of four word lines in qfile

#read each line from the dictionary file, then put into a hash
# whose key is the word, and whose value is a two-elt array
# which is (parts of speech, frequency)
foreach (@dict)
{
	$_ =~ s/\r|\n//g; #the new chomp
	my @line = split(/\t/, $_); 			#to the left of the | is word(space)pos(space)....

	my $word = $line[0];	#pop first elt off
	my $pos=$line[1];

	$hdict{$word}=[$pos, $line[2]/8382231];	#key is word, value is (part of speech, freq)#possibly add it with a really high value?
											#want to change the denominator if you care, which is no longer the number of words spotted.
#	$total+=$line[2]; #for counting the number of word occurrences in the dictionary #TODO
}
#$total=0; #the number of words in the input text file #TODO

foreach(@file)
{
	$_ =~ s/\r|\n//g; #the new chomp
	@line = split(/ /, $_);
#	$total+=$#line+1; for counting the number of lines #TODO
	foreach my $token (@line)
	{
		if($token =~ /^[A-Za-z]+[\.,]?$/)
		{
			chop($token) if ($token =~ /[\.,]+$/);	#chop that punctuation right off of there
#			$token = lc($token);							#treat words as all lower case for now #TODO
			if(exists($localfreq{$token}))			#increase frequency/add depending if seen. #TODO different casings of same word fix
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
		#print "word $key is not in hdict\n"; #for cl output
	} 
	else
	{	
		$localfreq{$key} = ($localfreq{$key})/(@{$hdict{lc($key)}}[1]);  #tricky syntax because of array references in hash table
	}
}
#add each of the keys in decreasing order to @topwords
foreach my $key (sort {$localfreq{$b} <=> $localfreq{$a}} keys(%localfreq)) 
{
#	print "$key, ".@{$hdict{$key}}[0].", $localfreq{$key}\n";		#TODO possibly print if --verbose
	push(@topwords, $key);
}
#	foreach (@topwords) { print "topword: $_\n"; } #TODO possibly print if --verbose / for troubleshooting

#TODO months... declaration of $months outside the following due to a scoping issue?
my $months = "(\s?)\(Jan\)\|\(Feb\)\|\(Mar\)\|\(Apr\)\|\(May\)\|\(Jun\)\|\(Jul\)\|\(Aug\)\|\(Sep\)\|\(Oct\)\|\(Nov\)\|\(Dec\)(\s?)";
if ($years)
{
	open(TIMEPREPS, "<time_preps.txt") or die "Can't find time preposition dictionary time_preps.txt\n";

		foreach my $prep (<TIMEPREPS>)
		{
			$prep =~ s/\r|\n//g;  #the new chomp
			$timeprepregex.="( ".$prep." )\|";  	#this way they can be a regex of "or" expressions	
													#like ( in )|( during )|...
		}
	chop($timeprepregex);           				#to take last "|" off
	close(TIMEPREPS);
}

#read file into sentences
my $wholefile = "";
foreach (@file)
{
	$_ =~ s/\r|\n//g; #the new chomp
	$wholefile.=$_." ";
}

my @sentences = split(/\."?\s+/, $wholefile); #split into sentences

foreach (@sentences) {
	$_ = " ".$_." ";  #allow the first and last words in sentences to be in the regex format
}

#breaks up the list of countrys and finds relevant answers
if ($countries)
{
	#use only if $countries
	open(COUNTRIES, "<country_list.txt") or die "Can't find country dictionary country_list.txt\n";
	
	#do this only if --countries
	
	#read in list of countries
	foreach my $place (<COUNTRIES>)
	{
		$place =~ s/\r|\n//g;
		push(@countries, $place);
		$countriesregex.=" ".$place." \|";	#this way they can be a regex of "or" expressions
												#like ( Soviet Union )|( Peru )|...
		my @tokenized_country = split(/\s/, $place);
		$countriesregex2.=" ".$place." \|" if($#tokenized_country==1);
		$countriesregex3.=" ".$place." \|" if($#tokenized_country==2);
		$countriesregex4.=" ".$place." \|" if($#tokenized_country==3);
	}
	chop($countriesregex); 				#to take last "|" off
	chop($countriesregex2); 			#to take last "|" off
	chop($countriesregex3); 			#to take last "|" off
	chop($countriesregex4); 			#to take last "|" off
	close(COUNTRIES);

	#to be used for more relevant answers
	my @words;	#all the words in the file
	my @two_words;	#sequences of two words apeice, delimited by sentence
	my @three_words;	#sequences of three words apeice, delimited by sentence
	my @four_words;		#sequences of four words apeice, delimited by sentence
	#read the file into words
	foreach my $sentence (@sentences)
	{
		my @temparray=();		#words in current sentence
		@temparray = split(/\s+/, $sentence);

		for my $i (0..$#temparray) #trim all empty strings in the sentence
		{
			if($temparray[$i] eq "") 
			{
				splice(@temparray, $i, 1);
			}
		}	
		
		foreach my $i (0..$#temparray)
		{
			push(@words, " ".$temparray[$i]." ");

			#make the mulitple-word-per-index arrays
			if($i<=$#temparray-1)
			{
				push(@two_words, " ".$temparray[$i]." ".$temparray[$i+1]." ");
			}
			if($i<=$#temparray-2)
			{
				push(@three_words, " ".$temparray[$i]." ".$temparray[$i+1]." ".$temparray[$i+2]." ");
			}
			if($i<=$#temparray-3)
			{
				push(@four_words, " ".$temparray[$i]." ".$temparray[$i+1]." ".$temparray[$i+2]." ".$temparray[$i+3]." ");				
			}
		}
	}

	#for each word in the file, check if it's a country
	foreach my $word (@words)
	{
		$word =~ s/[^A-Za-z\s]//g;
		if ($word =~ /$countriesregex/i)
		{
			$countryans{$word}++;
		}
	}

	#for each two words in the file, check if it's a country
	foreach my $two_word (@two_words)
	{
		$two_word =~ s/[^A-Za-z\s]//g;
		if ($two_word =~ /$countriesregex2/i) 
		{
			$countryans{$two_word}++;
		}
	}

	#for each three words in the file, check if it's a country
	foreach my $three_word (@three_words)
	{
		$three_word =~ s/[^A-Za-z\s]//g;
		if ($three_word =~ /$countriesregex3/i) 
		{
			$countryans{$three_word}++;
		}
	}

	#for each four words in the file, check if it's a country
	foreach my $four_word (@four_words)
	{
		$four_word =~ s/[^A-Za-z\s]//g;
		if ($four_word =~ /$countriesregex4/i) 
		{
			$countryans{$four_word}++;
		}
	}
}

#breaks up the list given by qfile and finds relevant answers
if ($qfile)
{
	#use only if $qfile
	open(QFILE, "<".$qfile) or die "Can't find ".$qfile." Confirm that this is the correct path to the file.\n";
	
	#do this only if --qfile=<file>
	
	#read in list of desired question topics
	foreach my $line (<QFILE>)
	{
		$line =~ s/\r|\n//g;
		push(@qfilelines, $line);
		$qfileregex.=" ".$line." \|";	#this way they can be a regex of "or" expressions
											#like ( Soviet Union )|( Peru )|...
		my @tokenized_line = split(/\s/, $line);
		$qfileregex2.=" ".$line." \|" if($#tokenized_line==1);
		$qfileregex3.=" ".$line." \|" if($#tokenized_line==2);
		$qfileregex4.=" ".$line." \|" if($#tokenized_line==3);
	}
	chop($qfileregex); 				#to take last "|" off
	chop($qfileregex2); 			#to take last "|" off
	chop($qfileregex3); 			#to take last "|" off
	chop($qfileregex4); 			#to take last "|" off
	close(QFILE);
	
	#to be used for more relevant answers
	my @words;	#all the words in the file
	my @two_words;	#sequences of two words apeice, delimited by sentence
	my @three_words;	#sequences of three words apeice, delimited by sentence
	my @four_words;		#sequences of four words apeice, delimited by sentence
	#read the file into words
	foreach my $sentence (@sentences)
	{
		my @temparray=();		#words in current sentence
		@temparray = split(/\s+/, $sentence);
		
		for my $i (0..$#temparray) #trim all empty strings in the sentence
		{
			if($temparray[$i] eq "") 
			{
				splice(@temparray, $i, 1);
			}
		}	
		
		foreach my $i (0..$#temparray)
		{
			push(@words, " ".$temparray[$i]." ");

			#make the mulitple-word-per-index arrays
			if($i<=$#temparray-1)
			{
				push(@two_words, " ".$temparray[$i]." ".$temparray[$i+1]." ");
			}
			if($i<=$#temparray-2)
			{
				push(@three_words, " ".$temparray[$i]." ".$temparray[$i+1]." ".$temparray[$i+2]." ");
			}
			if($i<=$#temparray-3)
			{
				push(@four_words, " ".$temparray[$i]." ".$temparray[$i+1]." ".$temparray[$i+2]." ".$temparray[$i+3]." ");				
			}
		}
	}

#TODO consider punctuation? dont modity the words before checking them against the regex?	
	#for each word in the file, check if it's a one word line in qfile
	foreach my $word (@words)
	{
		$word =~ s/[^A-Za-z\s]//g;
		if ($word =~ /$qfileregex/i)
		{
			$qfileans{$word}++;
		}
	}

	#for each two words in the file, check if it's a two word line in qfile
	foreach my $two_word (@two_words)
	{
		$two_word =~ s/[^A-Za-z\s]//g;
		if ($two_word =~ /$qfileregex2/i) 
		{
			$qfileans{$two_word}++;
		}
	}

	#for each three words in the file, check if it's a three word line in qfile
	foreach my $three_word (@three_words)
	{
		$three_word =~ s/[^A-Za-z\s]//g;
		if ($three_word =~ /$qfileregex3/i) 
		{
			$qfileans{$three_word}++;
		}
	}

	#for each four words in the file, check if it's a four word line in qfile
	foreach my $four_word (@four_words)
	{
		$four_word =~ s/[^A-Za-z\s]//g;
		if ($four_word =~ /$qfileregex4/i) 
		{
			$qfileans{$four_word}++;
		}
	}
}

my $counter = 0; #for the OUT formatting/JS methods
#foreach sentence, create the requested/relevant question
#possibly change to calling each of the subs below with parameters instead
#of depending on $_ to work properly
foreach my $sentence (@sentences)
{
	#find specific questions regarding years
	if($years) 
	{
		&years($sentence);
	}
	
	#find specific questions containing countries
	if($countries)
	{
		&countries($sentence);
	}
	
	#find specific questions containing a given set of words/phrases
	if($qfile)
	{
		&qfile($sentence);
	}
	
	#find specific questions containing a given word
	if($qword)
	{
		&qword($sentence);
	}
	
	#print questions about each of the top words
	if(( !($countries) && !($qword) && !($years) && !($qfile)) || $default)
	{
		&default($sentence);
	}
}

######### END MAIN #########
####### SUBROUTINES ########
#--years command line parameter
sub years
{
	my @matches = ();
	my $sentence = $_[0]; #anon @_

	#if sentence has a time preposition
	# and if sentence has a digit in one of the predetermined formats
	#            digits
	#          (digits) 
	# (digit,digit) etc.
	#also, @matches gets each digit match per sentence.
	#TODO fix the below regex... backreferences for months?
	if(($sentence =~ $timeprepregex) && (@matches = uniq($sentence=~m/[^(,\d)]\s+,?\(?\-?(\d+),?\.?\s?\-?\)?[^(,\d+)( years)($months)]/ig)))
	{	
		foreach my $match (@matches)
		{

			print OUT "correct answer: $match "; ##correct answer with AD/BC thing?
			#account for BC in years
			if($sentence =~ /$match (BC)|(B\.C\.)|(BCE)|(B\.C\.E\.)/)
			{
				print OUT "B\.C\.";
			}
			elsif($match<=100)
			{
				print OUT "A\.D\.";
			}
			print OUT "\n";
			my @tokens = split(/\s+/, $sentence);
			foreach my $word (@tokens)
			{
				if($word=~/(AD)|(BC)|(A\.D\.)|(B\.C\.)|(BCE)|(B\.C\.E\.)/) { next; }
				if($word =~ $match)
				{
					print OUT " ".$` unless $` eq " "; #in case the number has brackets around it or something stupid
					print OUT " _______________";
					print OUT $'." " unless $' eq " "; #in case the number was followed by punctuation
				}
				else
				{
					print OUT $word." ";
				}
				#print OUT substr($sentence, -1)."\n"; #print the punctuation
			}

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
			#			check for proximity to months
			my $one=$match; my $two=$match; my $three=$match; my $four=$match;

			my $posneg=1;
			while(exists($numberchoice{$one}) || ($lessthannow && 2011<$one)) 
			{
				$posneg = (-1)**int(rand(2)); #plus or minus
				$one = $match + $posneg*(int(rand(50))+50); 
			}
			$numberchoice{$one}=0;

			while(exists($numberchoice{$two}) || ($lessthannow && 2011<$two)) 
			{
				$posneg = (-1)**int(rand(2));
				$two = $match + $posneg*(int(rand(40))+10); 
			}
			$numberchoice{$two}=0;

			while(exists($numberchoice{$three}) || ($lessthannow && 2011<$three)) 
			{
				$posneg = (-1)**int(rand(2));
				$three = $match + $posneg*int(rand(25));
			}
			$numberchoice{$three}=0;

			while(exists($numberchoice{$four}) || ($lessthannow && 2011<$four)) 
			{
				$posneg = (-1)**int(rand(2));
				$four = $match + $posneg*int(rand(10)); 
			}
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
				if($match!=$post[$j-1])
				{
					if($match>99)
					{
						print OUT "$j \. ".$post[$j-1]."\n";
					}
					elsif($post[$j-1]<0) #note that the conditions are exclusive
					{ 
						print OUT "$j \. ".$post[$j-1]." B.C.\n";
					}
					else
					{
						print OUT "$j\. ".$post[$j-1]." A.D.\n";
					}
				}
				else	#print the correct answer
				{
					if($match>99)
					{
						print OUT "$j \. ".$post[$j-1]."\n";
					}
					elsif($post[$j-1]<0) #note that the conditions are exclusive
					{ 
						print OUT "$j \. ".((-1)*$post[$j-1])." B\.C\.\n";
					}
					else
					{
						print OUT "$j \. ".$post[$j-1]." A\.D\.\n";
					}
				}
			}
			print OUT "\n"; #end HTMl DIV
		}
	}
}

#--qword=<word> command line parameter
sub qword
{
	my $sentence = $_[0]; #anon @_
	my $nt_capitalize = 0;
	#we can't write a question about a word that's not there
	if(! exists( $localfreq{$qword} ) )
	{
		print OUT "\n$qword is not in $infile. Is your case right? Caps-Lock?\n\n";
		last;
	}
	#not quite sure how to handle these cases right now
	if(! exists( $hdict{lc($qword)} ) )
	{
		print OUT "\n$qword is not in dictionary file.\n\n";
		last;
	}

	#if qword appears in the text in a logical way, then proceed
	if($sentence=~/\s+$qword[\.,\s+]?/i || $sentence=~/^$qword\s/i) #TODO why doesn't this conditional have more under it, like the correct answers, etc also this happens elsewhere?!?!?!
	{
		print OUT "correct answer: $qword\n";
		print OUT "\n";

		my @tokens = split(/\s+/, $sentence);
		for my $j (0..$#tokens)
		{
			my $word = $tokens[$j];
			if (!($word =~ /^$qword/i))
			{
				print OUT $word." ";
			}
			else
			{
				if($j==0) {$nt_capitalize=1;}
				print OUT " ___________________ ";
				print OUT $'." " unless $' eq " "; #in case the word was followed by puncutation
			}
			#print OUT substr($sentence, -1)."\n"; #print the punctuation
		}


		#find other candidate answers from @topwords
		my %numberchoice=(); #hash of randoms chosen
		my $correct = int(rand(5))+1; #which answer is the correct one


	
		my $maxtries=50;

		for my $j (1..5)
		{
			if($j==$correct)
			{
					print OUT "$j \. $qword\n";
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
				#unable to match parts of speech, indicated by print OUT *
				if($maxtries<=0 || @{$hdict{lc($qword)}}[0] eq "")
				{
					#print "Unable to match parts of speech in this question.\n";
					#print OUT "*"; 
					while ( exists($numberchoice{$random}) ||	$topwords[$random] eq lc($qword) )
					{
						$random=int(rand(20)); #how far into @topwords i want to look for candidate answers
					}						
				}
				$numberchoice{$random}=0;
				my $toprint = $topwords[$random];
				$toprint =~ s/\b(\w+)\b/ucfirst($1)/ge if $nt_capitalize; 

				print OUT "$j \. ".$toprint."\n";

			}			
		}
		print OUT "\n"; #end OUT DIV
	}
}

#--qfile=<file> command line parameter
sub qfile
{
	my @matches = ();
	my $sentence = $_[0]; #anon @_

	if(@matches = uniq($sentence =~ m/$qfileregex/g))
	{					#match global amount of times ^
		foreach my $match (@matches)
		{
			print OUT "correct answer: ".$match;
			print OUT "\n";
			
			my @tokens = split(/\s+/, $sentence);
			#word doesn't have spaces around it, but match does, because countriesregex has spaces, to prevent things like JapanESE

			my @tmp=split(/\s/, $match);
			for my $idx (0..$#tmp) #trim out any empty strings from match
			{
				if($tmp[$idx] eq "")
				{
					splice(@tmp, $idx, 1);
				}
			}

			my $length = $#tmp+1;

			my $i = 0;
			while( $i<=$#tokens)
			{
				my $word = $tokens[$i];
				my $multiword = " ";
				if($length>1)
				{	
					for my $j ($i..$i+$length-1)
					{
						$multiword.=$tokens[$j]." ";
					}
				}
				if($multiword ne " " && $multiword =~ /$match/) #then we need to not print extra spaces.
				{
						print OUT " _______________";
						$i+=($length-1);
				}
				elsif((" ".$word." ") =~ /$match/)
				{
					#print OUT " ".$` unless $` eq " "; #in case the word has brackets around it or something stupid
					print OUT " _______________";
					print OUT $' unless $' =~ " "; #in case the word was followed by punctuation
				}
				else
				{
					print OUT $word." ";
				}
				$i++;
			}
			#print OUT substr($sentence, -1)."\n"; #print the punctuation
			
			#find other candidate answers out of @qfilelines
			my %numberchoice=(); #hash of randoms chosen

			my @temp_qfileans = keys(%qfileans);

			for my $j (0..$#temp_qfileans)
			{
				$numberchoice{$temp_qfileans[$j]}=0 if ($temp_qfileans[$j] eq $match);
			}

			my $ans = $match; my $one = $match; my $two = $match; my $three = $match; my $four = $match;
			my @answers = ($one, $two, $three, $four);
			$numberchoice{$ans}=0;

			foreach my $i (0..$#answers)
			{
				my $most_tries = 50;
				while(exists($numberchoice{$answers[$i]}) && $most_tries>0)
				{
					$answers[$i] = $temp_qfileans[int(rand($#temp_qfileans+1))];
					$most_tries--;
				}
				while(exists($numberchoice{$answers[$i]}) && $most_tries==0) #shouldn't ever get less than 0...
				{
					$answers[$i] = $qfilelines[int(rand($#qfilelines+1))];
				}
				$numberchoice{$answers[$i]}=0;
			}
			push(@answers, $ans);

			@answers = &shuffle(@answers);

			#find and print all answers
			for my $i (1..5)
			{
				if( $answers[$i-1] =~ $match )
				{
					print OUT "$i \. ".$match."\n";
				}			
				else
				{
					print OUT "$i \. ".$answers[$i-1]."\n";	#text box
				}
			}
			print OUT "\n\n";
		}
	}
}

#--countries command line parameter
sub countries
{
	my @matches = ();
	my $sentence = $_[0]; #anon @_

	if(@matches = uniq($sentence =~ /$countriesregex/g))
	{					#match global amount of times ^
		foreach my $match (@matches)
		{
			print OUT "correct answer: ".$match;
			print OUT "\n";
			
			my @tokens = split(/\s+/, $sentence);
			#word doesn't have spaces around it, but match does, because countriesregex has spaces, to prevent things like JapanESE

			my @tmp=split(/\s/, $match);
			for my $idx (0..$#tmp) #trim out any empty strings from match
			{
				if($tmp[$idx] eq "")
				{
					splice(@tmp, $idx, 1);
				}
			}

			my $length = $#tmp+1;

			my $i = 0;
			while( $i<=$#tokens)
			{
				my $word = $tokens[$i];
				my $multiword = " ";
				if($length>1)
				{	
					for my $j ($i..$i+$length-1)
					{
						$multiword.=$tokens[$j]." ";
					}
				}
				if($multiword ne " " && $multiword =~ /$match/) #then we need to not print extra spaces.
				{
						print OUT " _______________";
						$i+=($length-1);
				}
				elsif((" ".$word." ") =~ /$match/)
				{
					#print OUT " ".$` unless $` eq " "; #in case the word has brackets around it or something stupid
					print OUT " _______________";
					print OUT $' unless $' =~ " "; #in case the word was followed by punctuation
				}
				else
				{
					print OUT $word." ";
				}
				$i++;
			}
			#print OUT substr($sentence, -1)."\n"; #print the punctuation
			
			#find other candidate answers out of @countries
			my %numberchoice=(); #hash of randoms chosen

			my @temp_countryans = keys(%countryans);

			for my $j (0..$#temp_countryans)
			{
				$numberchoice{$temp_countryans[$j]}=0 if ($temp_countryans[$j] eq $match);
			}

			my $ans = $match; my $one = $match; my $two = $match; my $three = $match; my $four = $match;
			my @answers = ($one, $two, $three, $four);
			$numberchoice{$ans}=0;

			foreach my $i (0..$#answers)
			{
				my $most_tries = 50;
				while(exists($numberchoice{$answers[$i]}) && $most_tries>0)
				{
					$answers[$i] = $temp_countryans[int(rand($#temp_countryans+1))];
					$most_tries--;
				}
				while(exists($numberchoice{$answers[$i]}) && $most_tries==0) #shouldn't ever get less than 0...
				{
					$answers[$i] = $countries[int(rand($#countries+1))];
				}
				$numberchoice{$answers[$i]}=0;
			}
			push(@answers, $ans);

			@answers = &shuffle(@answers);

			#find and print all answers
			for my $i (1..5)
			{
				if( $answers[$i-1] =~ $match )
				{
					print OUT "$i \. ".$match."\n";
				}			
				else
				{
					print OUT "$i \. ".$answers[$i-1]."\n";	#text box
				}
			}
			print OUT "\n\n";
			$counter++;
		}
	}
}

sub shuffle
{
	#shuffle answers
	my @pre = @_;
	my @post = ();
	for (my $i=$#_+1; $i>=1; $i--)
	{
		my $choice = int(rand($i));
		push(@post, $pre[$choice]);
		splice(@pre,$choice,1);
	}
	return @post;
}

#TODO middle of sentence capitalization of candidate answers
#default, i.e. if no command line parameters
sub default
{
	my $sentence = $_[0]; #anon @_

	#ten of top words
	for my $i (0..10)
	{
		my $nt_capitalize = 0; #whether the replacement is the first word
		#but what about if there are two replacements in the same line?

		if( !exists( $hdict{lc($topwords[$i])} ) )
		{
			#print OUT "<br>\n ".lc($topwords[$i])." is not in dictionary file.<br>\n<br>\n"; #for cl output
			next;
		}

		my $tempregex = $topwords[$i];
		if($sentence=~/(\s+$tempregex[\.,\s+]?)|(^$tempregex[\.,\s+]?)/i)
		{
			print OUT "correct answer: $topwords[$i]\n";
			my @tokens = split(/\s+/, $sentence);
			for my $j (0..$#tokens)
			{
				my $word = $tokens[$j];
				if (!($word =~ /^$topwords[$i]/i))
				{
					print OUT $word." ";
				}
				else
				{ 
					if($j==0){$nt_capitalize=1;}
					print OUT " ___________________ ";
					print OUT $'." " unless $' eq " "; #in case the word was followed by puncutation
				}
				#print OUT "substr($sentence, -1)\n"; #print the punctuation
			}
			print OUT "\n";


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
					print OUT "$j \. $topwords[$i]\n";
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
					#print "Unable to match parts of speech in this question.\n";
					#print OUT "*";
						while ( exists($numberchoice{$random} ) )
						{
							$random=int(rand(20)); #how far into @topwords i want to look for candidate answers
						}						
					}
					$numberchoice{$random}=0;
					my $toprint = $topwords[$random];
					$toprint =~ s/\b(\w+)\b/ucfirst($1)/ge if $nt_capitalize; 

					print OUT "$j \. ".$toprint."\n";	#text box
				}
			}
			print OUT "\n\n"; #end HTMl DIV
			$counter++;
		}
	}
}

print OUT "\n";
close(OUT);
close(INFILE);
close(DICTIONARY);
