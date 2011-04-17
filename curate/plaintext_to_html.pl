#!/usr/local/bin/perl
use strict;

open(PLAINTEXT, "<uncurated_questions.txt") or die "Can't open plaintext file";
open(HTML, ">uncurated_questions.html") or die "Can't open html file to write to";
my @pt = <PLAINTEXT>;

print HTML "<html>\n";

print HTML "\t<head>
\t\t<script src=\"curator_plaintext.js\">
\t\t<\/script>
\t\t<link href =\"style.css\" rel = \"stylesheet\">
\t<\/head>
\n
\t<body>
";

#finalize all button
print HTML "<input type=\"button\" id=\"FinalizeAll\" value=\"Finalize Quiz\" name=\"FinalizeAll\" onClick=\"finalizeAll(); this\.disabled=1\">\n"; 

my $divNum = 0;
my $ansNum = 1;
for my $i (0..$#pt)
{

	$pt[$i] =~ s/\r|\n//g; #the new chomp

	#it's telling us the correct answer
	if($pt[$i]=~/correct answer: /)
	{
		if($i>0) #then we need to end a DIV
		{
			print HTML "\n\t\t<\/DIV>\n\n"; #end HTMl DIV
			$divNum++;
		}

		#create an HTML DIV for each question for show/hide
		my $tempdiv = "question".$divNum;
		my $tempbox = "ckbox".$divNum;
		print HTML "\t\t<p><input type=\"checkbox\" id=\"ckbox".$divNum."\" value=\"Click here\" onClick=\"toggleShowHide('".$tempbox."','".$tempdiv."');\"></p>\n";
		print HTML "\t\t<DIV ID=\"question".$divNum."\">\n";
		print HTML "\t\t\t<INPUT type=\"button\" id=\"button".$divNum."\" value=\"Finalize Question\" name=\"finalizeOne\" onClick=\"finalize('question".$divNum."'); this\.disabled=1\">\n";
		print HTML "\t\t\t<br>\n";

		print HTML "\t\t\t<a>$pt[$i]<\/a>\n";
 
		print HTML "\t\t\t<ol>\n";
	}

	#it's one of the answers
	elsif($pt[$i]=~m/^[\d] \. /)
	{
		if($pt[$i]=~m/^[5] \. /)
		{
			$pt[$i]=~s/^[\d] \. //;
			print HTML "\t\t\t\t<a style=\"display:none\" id = \"div".$divNum."text".$ansNum."\">  </a>\n"; #text
			print HTML "\t\t\t\t<input type=\"text\" name=\"textbox".$ansNum."\" value=\"".$pt[$i]."\">\n";	#text box
#			print HTML "\t\t\t\t\t<li>$pt[$i]</li>\n";
			print HTML "\t\t\t<\/ol>\n";
		}
		else
		{
			$pt[$i]=~s/^[\d] \. //;
			print HTML "\t\t\t\t<a style=\"display:none\" id = \"div".$divNum."text".$ansNum."\">  </a>\n"; #text
			print HTML "\t\t\t\t<input type=\"text\" name=\"textbox".$ansNum."\" value=\"".$pt[$i]."\">\n";	#text box
#			print HTML "\t\t\t\t\t<li>$pt[$i]</li>\n";
		}
		$ansNum = (($ansNum)%5)+1; #indexed 1 thru 5
	}

	#it's the actual question
	elsif($pt[$i] ne "") #note: we've chopped the linebreaks already
	{
		print HTML "\t\t\t\t<a>$pt[$i]<\/a>\n\t\t\t\t<br>\n"
	}


}

print HTML "\t<\/body>\n<\/html>\n";
close(PLAINTEXT);
close(HTML);
