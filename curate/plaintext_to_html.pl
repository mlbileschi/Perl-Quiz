#!/usr/local/bin/perl
use strict;

## Written by Max Bileschi, Summer 2011
## mlbileschi@gmail.com
## converts the flat text file to interactable html


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
my $i=0;

#whether or not we are in the middle of reading the particular part of speech
#-1 means not reading, and anything more is indicating the index
my $noun=0;
my $verb=0;
my $proper=0;
my $plural=0;
my $pos = "";

while ($i < $#pt)
{

	$pt[$i] =~ s/\r|\n//g; #the new chomp

	#this line and the next 6 lines are a question
	if($pt[$i]=~/correct answer: /)
	{
		if($i>0) #then we need to end a DIV
		{
			print HTML "\n\t\t<\/DIV>\n\n"; #end HTMl DIV
			$divNum++;
		}
		
		my @tokens = split(/ /,$pt[$i]);
		$pos = pop(@tokens);	
		 
		$pt[$i]=join(" ",@tokens);
		#create an HTML DIV for each question for show/hide
		my $tempdiv = "question".$divNum;
		my $tempbox = "ckbox".$divNum;
		print HTML "\t\t<p><input type=\"checkbox\" id=\"ckbox".$divNum."\" value=\"Click here\" onClick=\"toggleShowHide('".$tempbox."','".$tempdiv."');\"></p>\n";
		print HTML "\t\t<DIV ID=\"question".$divNum."\">\n";
		print HTML "\t\t<a style=\"display:none\" id=\"pos".$divNum."\" >$pos</a>\n";
		print HTML "\t\t\t<INPUT type=\"button\" id=\"button".$divNum."\" value=\"Finalize Question\" name=\"finalizeOne\" onClick=\"finalize('question".$divNum."'); this\.disabled=1\">\n";
		print HTML "\t\t\t<br>\n";

		print HTML "\t\t\t<a>$pt[$i]<\/a>\n";
 
		print HTML "\t\t\t<ol>\n";


		#it's one of the answers
		$i++;
		$pt[$i] =~ s/\r|\n//g; #the new chomp

		print HTML "\t\t\t\t<a>$pt[$i]<\/a>\n\t\t\t\t<br>\n";

		$i++;
		for my $j (1..5)
		{
			$pt[$i]=~s/^[\d] \. //;
			$pt[$i]=~s/\r|\n//g; #the new chomp

			print HTML "\t\t\t\t<li>\n\t\t\t\t\t<a style=\"display:none\" id = \"div".$divNum."text".$j."\">  </a>\n"; #text
			print HTML "\t\t\t\t\t<input type =\"button\" name=\"prev\" onclick=\"getPrev(\'div".$divNum."textbox".$j."\', \'pos".$divNum."\');\" value = \"&laquo;\">\t\t\t\t\n";
			print HTML "\t\t\t\t\t<input type=\"text\" name=\"textbox".$j."\" id = \"div".$divNum."textbox".$j."\" value=\"".$pt[$i]."\">\n";	#text box
			print HTML "\t\t\t\t\t<input type =\"button\" name=\"next\" onclick=\"getNext(\'div".$divNum."textbox".$j."\', \'pos".$divNum."\');\"value = \"&raquo;\">\n\t\t\t\t<\/li>\n";

			if($j==5)
			{
				print HTML "\t\t\t<\/ol>\n";
			}
			else { $i++; }
		}
	}
	
	if($pt[$i]eq"")
	{
		$noun=0;
		$verb=0;
		$plural=0;
		$proper=0;
	}
	#first word type we read in, so we need to write the script
	elsif($pt[$i]eq"nouns:")
	{
		print HTML "\t<\/body>\n<\/html>\n";
		print HTML "<script type=\"text\/javascript\">\nnouns = new Array();\nverbs = new Array();\n".
						"plurals = new Array();\npropers = new Array();\n";
		print HTML"
function findIdx(arr, elt)
{
	for (var i = 0; i < arr.length; i++)
	{
		if(arr[i]==elt) { return i; }
	}
	return -1;
}

function getNext(eltId, posId)
{
	var pos = document.getElementById(posId).innerHTML;
	var elt = document.getElementById(eltId).value;
	var arr;
	if( pos.substr(\"noun\")!=-1 ) arr = nouns;
	else if( pos.substr(\"verb\")!=-1 ) arr = verbs;
	else if( pos.substr(\"plural\")!=-1 ) arr = plurals;
	else if( pos.substr(\"proper\")!=-1 ) arr = propers;
	else arr = nouns; \/\/we get here if there is no pos, or if i've made an error
	document.getElementById(eltId).value = arr[(findIdx(arr, elt)+1)%arr.length]; \/\/note: will return first element if not found in findIdx
	return false;
}

function getPrev(eltId, posId)
{
	var pos = document.getElementById(posId).innerHTML;
	var elt = document.getElementById(eltId).value;
	var arr;
	if( pos.substr(\"noun\")!=-1 ) arr = nouns;
	else if( pos.substr(\"verb\")!=-1 ) arr = verbs;
	else if( pos.substr(\"plural\")!=-1 ) arr = plurals;
	else if( pos.substr(\"proper\")!=-1 ) arr = propers;
	else arr = nouns; \/\/we get here if there is no pos, or if i've made an error
	document.getElementById(eltId).value = arr[(findIdx(arr, elt)-1+arr.length)%arr.length]; \/\/note: will return last element if not found in findIdx
	return false;
}
";
		$noun=1;
	}
	elsif($pt[$i]eq"plurals:")
	{
		$plural=1;
	}
	elsif($pt[$i]eq"proper nouns:")
	{
		$proper=1;
	}
	elsif($pt[$i]eq"verbs:")
	{
		$verb=1;
	}
	elsif($noun==1)
	{
		$pt[$i]=~s/\r|\n//g; #the new chomp
		print HTML "\tnouns.push(\"".$pt[$i]."\")\;\n";
	}
	elsif($plural==1)
	{
		$pt[$i]=~s/\r|\n//g;
		print HTML "\tplurals.push(\"".$pt[$i]."\")\;\n";
	}
	elsif($proper==1)
	{
		$pt[$i]=~s/\r|\n//g;
		print HTML "\tpropers.push(\"".$pt[$i]."\")\;\n";
	}
	elsif($verb==1)
	{
		$pt[$i]=~s/\r|\n//g;
		print HTML "\tverbs.push(\"".$pt[$i]."\")\;\n";
	}




	$i++; #simulate a for loop, kinda
}


print HTML "<\/script>";

close(PLAINTEXT);
close(HTML);
