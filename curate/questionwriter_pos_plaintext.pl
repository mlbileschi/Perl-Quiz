#!/usr/local/bin/perl
use strict;
#warnings??
use Getopt::Long;

## Written by Max Bileschi, Spring 2011
## mlbileschi@gmail.com
## creates questions, outputs to a txt doc

#TODO Months, what about ? and ! to end sentences?
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
#countries will call sub &qfile with the list of countries
#qfile will ask questions about words or phrases in a given file (see format and restrictions above)
#we then get these options from the command line input.
my $default; my $qword; my $years; my $countries; my $qfile;
GetOptions ("default"=>\$default, "qword=s" => \$qword, "years" => \$years, "countries" => \$countries, "qfile=s" => \$qfile) or die "Whups, got options we don't recognize!";
#$qword=lc($qword); #TODO


#######MAIN#######

#open dicitonary files don't use if ($years) | ($countries) ($qfile)
open(DICTIONARY, "<dictionary20110531.txt") or die "Can't open dicitonary file\n"; #case-sensitive dictionary file
my @dict = <DICTIONARY>;

#open an output file with html format
open(OUT, ">uncurated_questions.txt") or die "Can't open file to write to";

my @file = <INFILE>; #the file you are making quizes out of (different file than the rest of the file names refer to)
my %hdict=(); #TODO
my %localfreq=(); #key is the word and the value is the local freqency (number of times apearing in the document)
my @topwords=(); #list of the highest relative frequency words in the document (#TODO)
my @filelines=(); #list of a list of desired answers (things you want to ask questions about) (one to four words long) of each important-word bearing file
my @fileans=(); #list of groups of answers that are relevant to the targeted words/phrases of each important-word bearing file
my @qfile=(); #the list of files that contain words/phrases that will have questions targeted towards (important-word bearing files)
my $total=0; #TODO ?
my @line = (); #used for parsing the dictionary/determining localfreq 

#The following regex is in the form:   ( in )|( during )|... #TODO change this one to be like the others
my $timeprepregex=""; #for determining if the sentence could contain a date
#The following regex's are in the form:   word|word|... where the word is sometimes a phrase
my @fileregex=(); #list of regex's of all lines in each important-word bearing file
my @fileregex2=(); #list of regex's of two word lines in each important-word bearing file
my @fileregex3=(); #list of regex's of three word lines in each important-word bearing file
my @fileregex4=(); #list of regex's of four word lines in each important-word bearing file

my $qfile_and_text = ""; #used for qfile. intersection of words in qfile and text input file

#read each line from the dictionary file, then put into a hash
# whose key is the word, and whose value is a two-elt array
# which is (parts of speech, frequency)
foreach (@dict)
{
	$_ =~ s/\r|\n//g; #the new chomp
	my @line = split(/\t/, $_); 			#tab delimited

	my $word = $line[0];	#pop first elt off
	my $pos=$line[1];

	$hdict{$word}=[$pos, $line[2]];	#key is word, value is (part of speech, freq)#possibly add it with a really high value?
											#want to change the denominator if you care, which is no longer the number of words spotted.
#	$total+=$line[2]; #for counting the number of word occurrences in the dictionary #TODO
}
#$total=0; #the number of words in the input text file #TODO
######---------------------------------------

#read file into sentences
my $wholefile = "";
foreach (@file)
{
	$_ =~ s/\r|\n//g; #the new chomp
	$wholefile.=$_." ";
}

my @sentences = split(/\."?(\[\d+\])*\s+/, $wholefile); #split into sentences. That funky thing (\[\d+\])*
																			#is in there to deal with Wikipedia citations
foreach(@sentences)
{
	my @words = split(/ /, $_);
	for my $i (0..$#words)
	{
		my $word = $words[$i];
		#check to see if the first word needs to be lowercased
		if($i==0 && @{$hdict{$word}}[0]!~m/proper/)
		{
			$word=lc(substr($word, 0, 1)) .  substr($word, 1);
		}

		#TODO change the regex to accept words in quotes, bracket?, parens, both, brackets number after, and other combinations (" ," ,[3] ." ") : ; ' ? ! (> < / \)?	
		#TODO allow for hyphen in the word? break it into two words?
		#TODO check to see if the next word after any comb of ! . ? with an optional " is in the dict, otherwise check the lowercase of that word instead, else set freq to one of the upper case word, or ignore?
		if($word =~ /^[A-Za-z]+[\.,]?$/)
		{
			chop($word) if ($word =~ /[\.,]+$/);	#chop that punctuation right off of there
			if(exists($localfreq{$word}))			#increase frequency/add depending if seen. #TODO different casings of same word fix
			{
				$localfreq{$word}++;
			}
			else
			{
				$localfreq{$word} = 1;
			}
		} 
	}
}

#compute relative frequencies
foreach my $key ( keys(%localfreq) ) 
{
	if(!exists($hdict{$key}))
	{
		$localfreq{$key}=0;		#possibly add it with a really high value?
		#print "word $key is not in hdict\n"; #for cl output
	} 
	else
	{	
		$localfreq{$key} = ($localfreq{$key})/(@{$hdict{$key}}[1]);  #tricky syntax because of array references in hash table
	}
}

#add each of the keys in decreasing order to @topwords
foreach my $key (sort {$localfreq{$b} <=> $localfreq{$a}} keys(%localfreq)) 
{
#	print "$key, ".@{$hdict{$key}}[0].", $localfreq{$key}\n";		#TODO possibly print if --verbose
	push(@topwords, $key);
}
#	foreach (@topwords) { print "topword: $_\n"; } #TODO possibly print if --verbose / for troubleshooting

#split topwords into parts of speech
#and, i'm gonna try sticking with just nouns and verbs for now
my @verbs = ();
my @nouns = ();
my @propernouns = ();
my @plurals = ();

#there's gonna be problems if the input is REALLY short.
foreach my $i (0..29)
{
	if(@{$hdict{$topwords[$i]}}[0]=~m/noun/) #gotta match those parts of speech
	{
		push(@nouns,$topwords[$i]);
	}
	if(@{$hdict{$topwords[$i]}}[0]=~m/verb/)
	{
		push(@verbs,$topwords[$i]);
	}
	if(@{$hdict{$topwords[$i]}}[0]=~m/proper/)
	{
		push(@propernouns,$topwords[$i]);
	}
	if(@{$hdict{$topwords[$i]}}[0]=~m/plural/)
	{
		push(@plurals,$topwords[$i]);
	}
}

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


#to be used for more relevant answers, only used with some command line args
my %words;			#all the words in the file; value = number of occurances
my %two_words;		#sequences of two words apiece, delimited by sentence; value = number of occurences
my %three_words;	#sequences of three words apiece, delimited by sentence; value = number of occurences
my %four_words;		#sequences of four words apiece, delimited by sentence; value = number of occurences

#compose a list of single words in the file and lists of every two, three and four word phrases (delimited by sentence)
if($countries || $qfile) 
{
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
			$words{$temparray[$i]}++;

			#make the mulitple-word-per-index arrays
			if($i<=$#temparray-1)
			{
				$two_words{$temparray[$i]." ".$temparray[$i+1]}++;
			}
			if($i<=$#temparray-2)
			{
				$three_words{$temparray[$i]." ".$temparray[$i+1]." ".$temparray[$i+2]}++;
			}
			if($i<=$#temparray-3)
			{
				$four_words{$temparray[$i]." ".$temparray[$i+1]." ".$temparray[$i+2]." ".$temparray[$i+3]}++;				
			}
		}
	}
}

#add the country_list.txt to @qfile
if ($countries)
{
	push(@qfile, "country_list.txt");	
}

#add $qfile to @qfile
if ($qfile)
{
	push(@qfile, $qfile);
}

#TODO qfile can have repeats. uniq

#breaks up the list(s) given by @qfile and finds relevant answers
foreach my $file (@qfile)
{
	#instantiate sub regex's/filelines/fileans
	my @subfilelines = ();
	my %subfileans = ();
	my $subfileregex = "";
	my $subfileregex2 = "";
	my $subfileregex3 = "";
	my $subfileregex4 = "";
	
	open(QFILE, "<".$file) or die "Can't find ".$file."\. Please confirm that this is the correct path to the file.\n";
	
	#read in list of desired question topics
	foreach my $line (<QFILE>)
	{
		$line =~ s/\r|\n//g; #trim new lines and returns
		push(@subfilelines, $line);
		$subfileregex.= "(^".$line."\$)|";	#this way they can be a regex of "or" expressions
											#like Soviet Union|Peru|...
		my @tokenized_line = split(/\s+/, $line);
		$subfileregex2.=$line."\|" if($#tokenized_line==1);
		$subfileregex3.=$line."\|" if($#tokenized_line==2);
		$subfileregex4.=$line."\|" if($#tokenized_line==3);
	}

	close(QFILE);

	chop($subfileregex); 			#to take last "|" off
	chop($subfileregex2); 			#to take last "|" off
	chop($subfileregex3); 			#to take last "|" off
	chop($subfileregex4); 			#to take last "|" off

	%subfileans = %{&parseFileIntoPhrases(\%subfileans, $subfileregex, \%words)};
	%subfileans = %{&parseFileIntoPhrases(\%subfileans, $subfileregex2, \%two_words)};
	%subfileans = %{&parseFileIntoPhrases(\%subfileans, $subfileregex3, \%three_words)};
	%subfileans = %{&parseFileIntoPhrases(\%subfileans, $subfileregex4, \%four_words)};
	
	#add all of the sub regex's/filelines/fileans to the parent lists
	push(@fileregex, $subfileregex);
	push(@fileregex2, $subfileregex2);
	push(@fileregex3, $subfileregex3);
	push(@fileregex4, $subfileregex4);
	push(@fileans, \%subfileans);
	push(@filelines, \@subfilelines);
}

foreach my $thing (@fileans)
{
	foreach my $entry (keys %{$thing})
	{
		$qfile_and_text.= $entry."|";
	}
}
chop($qfile_and_text);

#foreach sentence, create the requested/relevant question
foreach my $sentence (@sentences)
{
	my @tokens = split(/\s+/, $sentence);
	for my $i (0..$#tokens) #trim out any empty strings from @tokens
	{		
		if($tokens[$i] eq "")
		{
			splice(@tokens, $i, 1);
		}
	}

	#find specific questions regarding years
	if($years) 
	{
		&years($sentence, \@tokens);
	}
	
	#find specific questions containing a given set of words/phrases
	if(@qfile != ())
	{
		&qfile($sentence, \@tokens);
	}
	
	#find specific questions containing a given word
	if($qword)
	{
		&qword($sentence, \@tokens);
	}
	
	#print questions about each of the top words
	if(( !($countries) && !($qword) && !($years) && !($qfile)) || $default)
	{
		&default($sentence, \@tokens);
	}
}
if(!($qfile))
{
	print OUT "\nnouns:\n";
	foreach (@nouns) { print OUT $_."\n"; }
	print OUT "\nplurals:\n";
	foreach (@plurals) { print OUT $_."\n"; }
	print OUT "\npropers:\n";
	foreach (@propernouns) { print OUT $_."\n"; }
	print OUT "\nverbs:\n";
	foreach (@verbs) { print OUT $_."\n"; }
} 
else 
{ #there is a qfile
	#not quite sure which way to do this. both work.
	#for now, I'll say that we should only use the entire qfile for the forward and back js buttons is
	#when the length of the file isn't too long and when we have enough words in 
	#@qfile_and_text to make a decent use of the buttons. When it is too long, we use $qfile_and_text instead.
	open(QFILE, "<$qfile") or die "Can't find ".$qfile."\. Please confirm that this is the correct path to the file.\n";
	my @whole_file = <QFILE>;
	my @qfile_and_text_list = split(/\|/, $qfile_and_text);
	if($#whole_file <=300 && $#qfile_and_text_list<=10)
	{
		print OUT "\nnouns:\n"; #note: nouns are the default for the .js.. I can do this better later...
		print OUT $_ foreach (@whole_file);
		print OUT "\nplurals:\n";
		print OUT "\npropers:\n";
		print OUT "\nverbs:\n";
	}
	else
	{
		print OUT "\nnouns:\n";
		print OUT $_."\n"  foreach (@qfile_and_text_list);
		print OUT "\nplurals:\n";
		print OUT "\npropers:\n";
		print OUT "\nverbs:\n";
	}
	close(QFILE);
}

############################
######### END MAIN #########
############################



####### SUBROUTINES ########
#--years command line parameter
sub years
{
	my $sentence = $_[0]; #anon @_
	my @tokens = @{$_[1]};

	#if sentence has a time preposition
	# and if sentence has a digit in one of the predetermined formats
	#            digits
	#          (digits) 
	# (digit,digit) etc.
	#also, @matches gets each digit match per sentence.
	#TODO fix the below regex... backreferences for months?
	#TODO matches can not be uniq
	if(($sentence =~ $timeprepregex) && (my @matches = $sentence=~m/[^(,\d)]\s+,?\(?\-?(\d+),?\.?\s?\-?\)?[^(,\d+)( years)($months)]/g)) ##got rid of i
	{	
		foreach my $match (@matches)
		{
			printCorrectAnswer($match);
			#account for BC in years
			if($sentence =~ /$match (BC)|(B\.C\.)|(BCE)|(B\.C\.E\.)/)
			{
				print OUT "B\.C\.";
			}
			elsif($match<=100)
			{
				print OUT "A\.D\.";
			}
			
			#Print the question to OUT
			&questionLineOut(\@tokens, $match, "YEARS", 1);

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
						print OUT "$j \. ".$post[$j-1]." A.D.\n";
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
			print OUT "\n\n";
		}
	}
}

#--qword=<word> command line parameter
sub qword
{
	my $sentence = $_[0]; #anon @_
	my @tokens = @{$_[1]};
	my $nt_capitalize = 0;
	#we can't write a question about a word that's not there
	if(! exists( $localfreq{$qword} ) )
	{
		print OUT "\n$qword is not in $infile. Is your case right? Caps-Lock?\n\n";
		last;
	}
	#not quite sure how to handle these cases right now
	if(! exists( $hdict{$qword} ) )
	{
		print "\n$qword is not in dictionary file.\n\n"; #print to terminal
		last;
	}

	#if qword appears in the text in a logical way, then proceed
	if($sentence=~/\s+$qword[\.,\s+]?/i || $sentence=~/^$qword\s/i) #TODO why doesn't this conditional have more under it, like the correct answers, etc also this happens elsewhere?!?!?!
	{
		my $question;
		#Print the question to OUT and determine the correct capitalization
		($question, $nt_capitalize) = &questionLineOut(\@tokens, $qword, "DEFAULT", 1);

		if($nt_capitalize==1)
		{
			printCorrectAnswer(uc(substr($qword, 0, 1)).substr($qword, 1),$hdict{$qword}[0]);
		} else {
			printCorrectAnswer($qword, $hdict{$qword}[0]);
		}
		print OUT $question;


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
				#if pos is not empty
				if(@{$hdict{$qword}}[0] ne "")
				{
					while ( $maxtries>0		#just in case we can't match parts of speech we have a sentinel
								&& ( exists($numberchoice{$random})	#while we've already chosen this word
								|| ($topwords[$random] eq $qword) #and it's not the correct answer
								|| @{$hdict{$topwords[$random]}}[0]!~@{$hdict{$qword}}[0]   ) #and it doesn't match the part of speech
								 )
					{
						$random=int(rand(20)); #how far into @topwords i want to look for candidate answers
						$maxtries--;
					}
				}
				#unable to match parts of speech, indicated by print OUT *
				# if we're unable to pick a good topword, or we don't have a pos
				if($maxtries<=0 || @{$hdict{$qword}}[0] eq "")
				{
					#print "Unable to match parts of speech in this question.\n";
					#print OUT "*"; 
					while ( exists($numberchoice{$random}) ||	$topwords[$random] eq $qword )
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
		print OUT "\n\n";
	}
}

#--qfile=<file> or --countries command line parameter
sub qfile
{
	my $sentence = $_[0]; #anon @_
	my @tokens = @{$_[1]};	

	for my $filenum (0..$#qfile) 
	{				
		#TODO matches will be not uniq
		my $tempregex = $fileregex[$filenum];

		if(my @matches = $sentence =~ m/$qfile_and_text/g)
		{					#match global amount of times ^
			foreach my $match (@matches)
			{
				print OUT "correct answer: $match ()"; #the empty brackets will work with
																	#plaintext_to_html for the forward
																	#back arrows in javascript
				
				my @tmp = split(/\s+/, $match);
				for my $idx (0..$#tmp) #trim out any empty strings from $match
				{
					if($tmp[$idx] eq "")
					{
						splice(@tmp, $idx, 1);
					}
				}
				my $length = $#tmp+1; #used for outputting the correct words for the question
				
				#Print the question to OUT
				my @tmp_arr = &questionLineOut(\@tokens, $match, "QFILE", $length);
				print OUT $tmp_arr[0];
				
				#find other candidate answers out of @{$filelines[$filenum]}
				my %numberchoice=(); #hash of randoms chosen
				my @temp_fileans = keys(%{$fileans[$filenum]}); #contains all of the words/phrases from the important-word bearing file found in the document
				my @temp_filelines = @{$filelines[$filenum]};

				for my $j (0..$#temp_fileans)
				{
					$numberchoice{$temp_fileans[$j]}=0 if ($temp_fileans[$j] eq $match);
				}

				my $ans = $match; my $one = $match; my $two = $match; my $three = $match; my $four = $match;
				my @answers = ($one, $two, $three, $four);
				$numberchoice{$ans}=0;

				foreach my $i (0..$#answers)
				{
					my $most_tries = 50;
					while(exists($numberchoice{$answers[$i]}) && $most_tries>0)
					{
						$answers[$i] = $temp_fileans[int(rand($#temp_fileans+1))];
						$most_tries--;
					}
					while(exists($numberchoice{$answers[$i]}) && ($most_tries<=0) && ($most_tries>(-50)))
					{
						$answers[$i] = $temp_filelines[int(rand($#temp_filelines+1))];
						$most_tries--;
					}
					#REQ (@topwords >= 30)
					while(exists($numberchoice{$answers[$i]}) && ($most_tries<=(-50)))
					{
						$answers[$i] = $topwords[int(rand(31))]; #look at the top 30 words from top words
					}
					$numberchoice{$answers[$i]}=0;
				}
				push(@answers, $ans);

				@answers = &shuffle(@answers);

				#find and print all answers
				for my $i (1..5)
				{
					if($answers[$i-1] =~ $match)
					{
						print OUT "$i \. ". $match."\n";
					}			
					else
					{
						print OUT "$i \. ". $answers[$i-1]."\n";
					}
				}
				print OUT "\n\n";
			}
		}
	}
}

#TODO middle of sentence capitalization of candidate answers
#default, i.e. if no command line parameters
sub default
{
	my $sentence = $_[0]; #anon @_
	my @tokens = @{$_[1]};	

	#ten of top words
	for my $i (0..10)
	{
		my $nt_capitalize = 0; #whether the replacement is the first word
		#but what about if there are two replacements in the same line?

		if( !exists( $hdict{$topwords[$i]} ) )
		{
			#print OUT "<br>\n ".lc($topwords[$i])." is not in dictionary file.<br>\$toprint =(uc(substr($toprint, 0, 1)).substr($toprint, 1)) if $nt_capitalize; n<br>\n"; #for cl output
			next;
		}

		my $tempregex = $topwords[$i];
		if($sentence=~/(\s+$tempregex[\.,\s+]?)|(^$tempregex[\.,\s+]?)/i)
		{
			my $question;
			#Print the question to OUT and determine the correct capitalization
			($question, $nt_capitalize) = &questionLineOut(\@tokens, $topwords[$i], "DEFAULT", 1);

			if($nt_capitalize==1)
			{
				printCorrectAnswer(uc(substr($topwords[$i], 0, 1)).substr($topwords[$i], 1),$hdict{$topwords[$i]}[0]);
			} else {
				printCorrectAnswer($topwords[$i], $hdict{$topwords[$i]}[0]);
			}
			print OUT $question;

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
					my $tmp_toprint =(uc(substr($topwords[$i], 0, 1)).substr($topwords[$i], 1)) if $nt_capitalize; 
					print OUT "$j \. $topwords[$i]\n";
				}
				else
				{
					my $random=$correct;
					#goes until a new topword is chosen
					if(@{$hdict{$topwords[$i]}}[0] ne "")
					{
						while ( (exists($numberchoice{$random} ) #while we haven't already chosen it
								|| @{$hdict{$topwords[$random]}}[0]!~@{$hdict{$topwords[$i]}}[0]) #and it doesn't match the part of speech
								&& $maxtries>0)	#just in case we can't match parts of speech we have a sentinel
						{
							$random=int(rand(30)); #how far into @topwords i want to look for wrong answers
							$maxtries--;
						}
					}
					if($maxtries<=0 || @{$hdict{$topwords[$i]}}[0] eq "")
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
					$toprint =(uc(substr($toprint, 0, 1)).substr($toprint, 1)) if $nt_capitalize; 
					print OUT "$j \. ".$toprint."\n";	#text box
				}
			}
			print OUT "\n\n"; 
		}
	}
}

#Creates a string which will phrase the question
#how it will be outputted to screen (i.e. with a blank).
#Also returns whether or not the first replacement 
#is at the beginning of the sentence.
#@return: [0] = $phrased_question
#			 [1] = $need_to_captialize
sub questionLineOut #(\@tokens,$match,"SUB")
{                              #TODO attempt to reduce, make params explicit?
	my @tokens = @{$_[0]};      #list of words in the sentence
	my $match = $_[1];          #this is what we are matching to
	my $sub = $_[2];            #which sub called this sub
	my $length = $_[3];         #used when match is a phrase
	my $need_to_capitalize = 0; #for qword to return capitalization information
	my $next = 0;               #for skipping runs through the loop for phrases
	my $phrased_question="";    #string containing the question how it will be printed to screen.
										 #Note: will be returned
	$phrased_question.="\n";
	for my $i (0..$#tokens)
	{
		my $word = $tokens[$i];
		if($next>0) { $next--; next;} #skipping words since the answer is a phrase
		if($sub eq "YEARS") {if($word=~/(AD)|(BC)|(A\.D\.)|(B\.C\.)|(BCE)|(B\.C\.E\.)/) { next; } } #if years, we don't want to print any variation of AD or BC
		my $hit = ($word =~ /^$match/i);
		if($sub eq "QFILE") {$next = &phraseQuestion(\@tokens, $match, $i, $length);} #call sub to determine if it is a hit and how many skips need to be made
		if (!$hit && !$next)
		{
			if ($i == $#tokens) #we don't want a space if it's the last word in a sentence
			{
				$phrased_question.= $word;
			}
			else 
			{
				$phrased_question.= $word." ";
			}
		}
		else #we've hit a match
		{ #TODO fuck with the spacing around the blank
			if($i==0 && ($sub eq "QWORD" || $sub eq "DEFAULT")) { $need_to_capitalize=1; } #if qword or default and the first word, then return a 1 for capitalization

			#print OUT " ".$` unless $` eq " "; #in case the number has brackets around it or something stupid
			$phrased_question.= "___________________";
			$phrased_question.= $'." " unless $' eq " "; #in case the word was followed by puncutation
		}
	}	
	#print OUT "substr($sentence, -1)\n"; #print the punctuation		
	$phrased_question.=".\n";

	return($phrased_question, $need_to_capitalize); #notifies capitalization for certain calling subs
}

sub phraseQuestion #(\@tokens, $match, $i, $length)
{
	my @tokens = @{$_[0]}; #list of words in the sentence
	my $match = $_[1]; #this is what we are matching to
	my $i = $_[2]; #current index of the @tokens array
	my $length = $_[3]; #the number of words in match
	
	if (($i + $length-1) > $#tokens) {return(0);} #cant possibly be a match if you would go past the last word in the sentence
	
	my $multiword = "";
	if($length > 1)
	{	
		for my $j ($i..$i+$length-1)
		{
			$multiword.=$tokens[$j]." ";
		}
		chop($multiword); #get rid of the last space
	}
	
	if($multiword ne "" && $multiword =~ /^$match/) #then we need to skip printing words (part of the answer) and printing extra spaces.
	{												#dont anchor the end to allow for punctuation 
		return($length-1); #the number of words that need to be skipped
	} 	#implied else
	return(0); #no match
}

#creating a "bank" of all the desired answers; things we've found in the file that 
#match what the user requested
sub parseFileIntoPhrases #(%subfileans, $subfileregex, %words/phrases)
{	
#TODO consider punctuation? dont modity the words before checking them against the regex?	
	my %ans = %{$_[0]}; #important phrases we've found in the file we want to write a quiz about,
	my $regex = $_[1];
	print $regex."\n";
	my %tokens = %{$_[2]};
	#for each word/phrase in the file, check if it's a one_word, or two_word, ... line in the current qfile
	foreach my $token (keys %tokens)
	{
		$token =~ s/[^A-Za-z\s]//g; #kill off all non-letters while keeping spaces

		#why ne ""? e.g. if your qfile only has phrases of length 3 or less, four_words will be ""
		if ($token =~ m/^$regex$/i && $regex ne "") 
		{
			$ans{$token} = $tokens{$token}; #assigns the value of $token in %subfileans to be the value that was for $token in %words/phrases
			#TODO will the above put it in or no?
		}
	}
	return(\%ans);
}

#prints correct answer along with part of speech, so that the plaintext to html interpreter
#can use the part of speech to generate more answers "on the fly"
#(note: the part of speech is only viewable in the flat text file)
sub printCorrectAnswer
{
	print OUT "correct answer: $_[0] ($_[1])";
}

#shuffle answers
sub shuffle
{
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

print OUT "\n";
close(OUT);
close(INFILE);
close(DICTIONARY);
