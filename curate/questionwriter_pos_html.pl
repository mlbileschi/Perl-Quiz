#!/usr/local/bin/perl
use strict;
#warnings??
use Getopt::Long;

## Written by Max Bileschi, Spring 2011
## mlbileschi@gmail.com
## creates questions, outputs to an html doc

#TODO Months, what about ? and ! to end sentences?



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


#open an output file with html format
open(HTML, ">uncurated_questions.html") or die "Can't open file to write html to";

print HTML "<html>\n";

print HTML "<head>
<script language=\"Javascript\">
function toggleShowHide\(boxName, divName\) 
\{
	if \(document\.getElementById\(boxName\)\.checked==true\)
	\{
		document\.getElementById\(divName\)\.style\.visibility = 'hidden'\;
		document\.getElementById\(divName\)\.style\.display = 'none'\;
	\}
	else
	\{
		document\.getElementById\(divName\)\.style\.visibility = 'visible'\;
		document\.getElementById\(divName\)\.style\.display = 'block'\;
	\}
\}

<\/script>
<\/head>
";

print HTML "<body>\n";

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
	#	$total+=$line[2]; #for counting the number of word occurrences in the dictionary
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
			print HTML "word $key is not in hdict\n";
		} 
		else
		{	
			$localfreq{$key} = ($localfreq{$key})/(@{$hdict{lc($key)}}[1]);  #tricky syntax because of array references in hash table
		}
	}
	print HTML "<br>\n";
	#add each of the keys in decreasing order to @topwords
	foreach my $key (sort {$localfreq{$b} <=> $localfreq{$a}} keys(%localfreq)) 
	{
	#	print "$key, ".@{$hdict{$key}}[0].", $localfreq{$key}\n";		#possibly print if --verbose
		push(@topwords, $key);
	}
#	foreach (@topwords) { print HTML "topword: $_\n"; } #possibly print if --verbose / for troubleshooting

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
	close(TIMEPREPS);
}



#read file into sentences
my $wholefile = "";
foreach (@file)
{
	chomp;
	$wholefile.=$_." ";
}
my @sentences = split(/\."?\s+/, $wholefile);

my $counter = 0;
#foreach sentence, create the requested/relevant question
#possibly change to calling each of the subs below with parameters instead
#of depending on $_ to work properly
foreach my $sentence (@sentences)
{

#	print $sentence."\n\n";

	
#	$sentence.="\."; #?
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
	$counter++; ###??
}

######### END MAIN #########
####### SUBROUTINES ########
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
	if(($sentence =~ $timeprepregex) && (@matches = $sentence=~m/[^(,\d)][\s+,\(\-](\d+)[\.\s+\-\)]?[^(,\d+)( years)]/ig))
	{
		foreach my $match (@matches)
		{
			#create an HTML DIV for each question for show/hide
			my $tempdiv = "question".$counter;
			my $tempbox = "ckbox".$counter;
			print HTML "<p><input type=\"checkbox\" id=\"ckbox".$counter."\" value=\"Click here\" onClick=\"toggleShowHide('".$tempbox."','".$tempdiv."');\"></p>\n";
			print HTML "<DIV ID=\"question".$counter."\">\n";
			$counter++;

			print HTML "correct answer: $match "; ##correct answer with AD/BC thing?
			#account for BC in years
			if($sentence =~ /$match (BC)|(B\.C\.)|(BCE)|(B\.C\.E\.)/)
			{
				print HTML "B\.C\.";
			}
			elsif($match<=100)
			{
				print HTML "A\.D\.";
			}
			print HTML "<br>\n";
			my @tokens = split(/\s+/, $sentence);
			foreach my $word (@tokens)
			{
				if($word=~/(AD)|(BC)|(A\.D\.)|(B\.C\.)|(BCE)|(B\.C\.E\.)/) { next;}
				if($word =~ $match)
				{
					print HTML " ".$` unless $` eq " "; #in case the number has brackets around it or something stupid
					print HTML "_______________";
					print HTML $'." " unless $' eq " "; #in case the number was followed by punctuation
				}
				else
				{
					print HTML $word." ";
				}
			}
			print HTML "<br>\n";

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

			my $posneg = (-1)**int(rand(2)); #plus or minus
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
				if($match!=$post[$j-1]) #print into editable text boxes
				{
					if($match>99)
					{
						print HTML "$j \. <input type=\"text\" id=\"myInput\" value=\"".$post[$j-1]."\"> <br>\n";
					}
					elsif($post[$j-1]<0) #note that the conditions are exclusive
					{ 
						print HTML "$j \. <input type=\"text\" id=\"myInput\" value=\"".$post[$j-1]."\"> B.C.<br>\n";
					}
					else
					{
						print HTML "$j \. <input type=\"text\" id=\"myInput\" value=\"".$post[$j-1]."\">  A.D.<br>\n";
					}
				}
				else	#print just the correct answer
				{
					if($match>99)
					{
						print HTML "$j \. $post[$j-1]<br>\n";
					}
					elsif($post[$j-1]<0) #note that the conditions are exclusive
					{ 
						print HTML "$j \. ".(-1)*$post[$j-1]." B\.C\.<br>\n";
					}
					else
					{
						print HTML "$j \. $post[$j-1] A\.D\.<br>\n";
					}
				}
			}
			print HTML "<\/DIV>\n"; #end HTMl DIV
		}
	}
}

sub qword
{
	my $sentence = $_[0]; #anon @_
	my $nt_capitalize = 0;
	#we can't write a question about a word that's not there
	if(! exists( $localfreq{$qword} ) )
	{
		print HTML "<br>\n$qword is not in $infile. Is your case right? Caps-Lock?<br>\n<br>\n";
		last;
	}
	#not quite sure how to handle these cases right now
	if(! exists( $hdict{lc($qword)} ) )
	{
		print HTML "<br>\n$qword is not in dictionary file.<br>\n<br>\n";
		last;
	}

	#if qword appears in the text in a logical way, then proceed
	if($sentence=~/\s+$qword[\.,\s+]?/i || $sentence=~/^$qword\s/i)
	{
		#create an HTML DIV for each question for show/hide
		my $tempdiv = "question".$counter;
		my $tempbox = "ckbox".$counter;
		print HTML "<p><input type=\"checkbox\" id=\"ckbox".$counter."\" value=\"Click here\" onClick=\"toggleShowHide('".$tempbox."','".$tempdiv."');\"></p>\n";
		print HTML "<DIV ID=\"question".$counter."\">\n";
		$counter++;

		print HTML "correct answer: $qword<br>\n";
		my @tokens = split(/\s+/, $sentence);
		for my $j (0..$#tokens)
		{
			my $word = $tokens[$j];
			if (!($word =~ /^$qword/i))
			{
				print HTML $word." ";
			}
			else
			{
				if($j==0) {$nt_capitalize=1;}
				print HTML "___________________ ";
				print HTML $'." " unless $' eq " "; #in case the word was followed by puncutation
			}
		}
		print HTML "<br>\n";

		#find other candidate answers from @topwords
		my %numberchoice=(); #hash of randoms chosen
		my $correct = int(rand(5))+1; #which answer is the correct one


	
		my $maxtries=50;

		for my $j (1..5)
		{
			if($j==$correct)
			{
				print HTML "$j \. $qword<br>\n";
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
				#unable to match parts of speech, indicated by print HTML *
				if($maxtries<=0 || @{$hdict{lc($qword)}}[0] eq "")
				{
					#print "Unable to match parts of speech in this question.\n";
					print HTML "*"; 
					while ( exists($numberchoice{$random}) ||	$topwords[$random] eq lc($qword) )
					{
						$random=int(rand(20)); #how far into @topwords i want to look for candidate answers
					}						
				}
				$numberchoice{$random}=0;
				my $toprint = $topwords[$random];
				$toprint =~ s/\b(\w+)\b/ucfirst($1)/ge if $nt_capitalize; 
				print HTML "$j \. <input type=\"text\" id=\"myInput\" value=\"".$toprint."\"> <br>\n";
			}			
		}
		print HTML "<\/DIV>\n"; #end HTMl DIV
	}
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
			print HTML "<br>\n ".lc($topwords[$i])." is not in dictionary file.<br>\n<br>\n";
			next;
		}

		my $tempregex = $topwords[$i];
		if($sentence=~/(\s+$tempregex[\.,\s+]?)|(^$tempregex[\.,\s+]?)/i)
		{

			#create an HTML DIV for each question for show/hide
			my $tempdiv = "question".$counter;
			my $tempbox = "ckbox".$counter;
			print HTML "<p><input type=\"checkbox\" id=\"ckbox".$counter."\" value=\"Click here\" onClick=\"toggleShowHide('".$tempbox."','".$tempdiv."');\"></p>\n";
			print HTML "<DIV ID=\"question".$counter."\">\n";
			$counter++;

			my @tokens = split(/\s+/, $sentence);
			for my $j (0..$#tokens)
			{
				my $word = $tokens[$j];
				if (!($word =~ /^$topwords[$i]/i))
				{
					print HTML $word." ";
				}
				else
				{ #
					if($j==0){$nt_capitalize=1;}
					print HTML "___________________ ";
					print HTML $'." " unless $' eq " "; #in case the word was followed by puncutation
				}
			}
			print HTML "<br>\n";
			print HTML "correct answer: $topwords[$i]<br>\n";



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
					print HTML "$j \. $topwords[$i]<br>\n";
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
					print HTML "*";
						while ( exists($numberchoice{$random} ) )
						{
							$random=int(rand(20)); #how far into @topwords i want to look for wrong answers
						}						
					}
					$numberchoice{$random}=0;
					my $toprint = $topwords[$random];
					$toprint =~ s/\b(\w+)\b/ucfirst($1)/ge if $nt_capitalize; 
#					print "NTCAP = $nt_capitalize\n";

					print HTML "$j \. <input type=\"text\" id=\"myInput\" value=\"".$toprint."\"> <br>\n";

#					print HTML "$j \. $toprint<br>\n"; #print candidate answers
				}
			}
			print HTML "<\/DIV>\n"; #end HTMl DIV
		}
	}
}

print HTML "<\/html>\n<\/body>\n";
close(HTML);
close(INFILE);
close(DICTIONARY);
