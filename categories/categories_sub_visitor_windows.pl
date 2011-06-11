#!/usr/local/bin/perl -w
use strict;
require HTML::Parser;   

package MyParser;

die "correct usage: perl categories_sub_visitor.pl [category]" unless $#ARGV==0;
my %whash=();	#(key,value) = (word, (part of speech, frequency))

my %dict=();
open(INDEX, "<../curate/dictionary20110531.txt") or die "couldn't open file dictionary20110411.txt to read from";
#read dictionary.txt into %dict
foreach (<INDEX>)
{
	chomp;
	my @key_value=split(/\t/, $_);
	if($#key_value == 1)
	{
		$dict{$key_value[0]}=["", $key_value[1]];	
	}
	else
	{
		$dict{$key_value[0]}=[$key_value[1],$key_value[2]];
	}
}
close(INDEX);


#format of categories with subcategories is: <a class="CategoryTreeLabel CategoryTreeLabelNs14 CategoryTreeLabelCategory" href="/wiki/Category:Biology_awards">Biology awards</a>

#make a list of all the hrefs that we want to examine from a categories page
my @subcategories_to_visit=();
my $super_category = $ARGV[0];
system("wget2", "http://en.wikipedia.org/wiki/Category:".$super_category, "-O", "wikipedia_macro_category_article_$super_category.html");
open(INFILE, "<wikipedia_macro_category_article_$super_category.html") or die "couldn't open file ".
							"wikipedia_macro_category_article_$super_category.html\n";
foreach(<INFILE>)
{

	if($_=~m/<a +?class=\"CategoryTreeLabel.+?href=/)
	{
		my $url = "http://en.wikipedia.org".substr($',1,index($',">")-2);
		my $filename = substr(substr($',0,index($',">")),16);
		chop($filename);
		push(@subcategories_to_visit, [$url, $filename]);
	}
}

foreach(@subcategories_to_visit)
{
	print $_->[0]."| |".$_->[1]."| \n";
}
foreach my $tmp_arr (@subcategories_to_visit)
{
	my $subcategory_url=$tmp_arr->[0];
	my $subcategory_filename = $tmp_arr->[1];
	print "subcategory = $subcategory_filename\n";
	#format of links on the categories page: <a title="Society of British Neurological Surgeons" href="/wiki/Society_of_British_Neurological_Surgeons">Society of British Neurological Surgeons</a>
	#<a title="Neuron" href="/wiki/Neuron">Neuron</a>
	#make a list of all the hrefs that we want to examine from a categories page
	my @articles_to_visit=();
	system("wget2", $subcategory_url, "-O", "wikipedia_category_article_$super_category.html");
	open(INFILE, "<wikipedia_category_article_$super_category.html") or die "couldn't open file wikipedia_category_article_$super_category.html\n";
	foreach(<INFILE>)
	{
		if($_=~m/<li><a *?href=\"\/wiki\/.+?\" +?title=\".+?\">.+?<\/a><\/li>/)
		{
			push(@articles_to_visit, "http://en.wikipedia.org".substr($_,index($_, "href=")+6,
					index($_, "title")-index($_, "href=")-8));
		}
	}

	print "\n";
	@MyParser::ISA = qw(HTML::Parser);	#extend HTML::Parser class... error?

	my $i = 0;
	foreach (@articles_to_visit)
	{
		print $_."\n";
	
		print $i." of $#articles_to_visit\n";		#print progress
		$i++;

		#start wget2.bat and open a random wikipedia article
		system("wget2", $_, "-O", "wikipedia_category_article_$super_category.html");
		open(INFILE, "<wikipedia_category_article_$super_category.html") or die "couldn't open file wikipedia_category_article_$super_category.html\n";

		my $parser = MyParser->new;				#new instance of this class ##changed this
		
		$parser->parse_file("wikipedia_category_article_$super_category.html");
		
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
					system("wget2", $url, "-O", "wiktionary_lookup_file_$super_category.html");

					my $keep_capitalize=0;
					#check the wiki file for parts of speech
					#if it's not a proper noun and it's at the beginning of a sentence, uncapitalize it
					open(WIKI, "<wiktionary_lookup_$super_category_file.html") or die;

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
					#if it's in the big dictionary, then we don't need to look up the parts of speech
					elsif(exists($dict{$token}))
					{
						($whash{$token}->[0]) = ($dict{$token}->[0]);
						($whash{$token}->[1]) = 1;
					}
					else
					{
						my $url = "http://en.wiktionary.org/wiki/".$token;
						system("wget2", $url, "-O", "wiktionary_lookup_file_$super_category.html");

						my $keep_capitalize=0;
						#check the wiki file for parts of speech
						#if it's not a proper noun and it's at the beginning of a sentence, uncapitalize it
						open(WIKI, "<wiktionary_lookup_file_$super_category.html") or die;

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

	#compute relative frequencies
	foreach my $key ( keys(%whash) ) 
	{
		if(!exists($dict{$key}))
		{
			@{$whash{$key}}[1]*=1.5;		#possibly add it with a really high value?
			#print "word $key is not in hdict\n"; #for cl output
		} 
		elsif(exists($dict{$key}))
		{
			($whash{$key}->[1]) = ($whash{$key}->[1])/($dict{$key}->[1]);
		}
		else
		{
			print "wtf\n";
		}
	}	

	#system("rm", "neurons.txt");	##changed this
	system("mkdir $super_category") if (!(-d $super_category));
	open(OUTFILE, ">$super_category\\$subcategory_filename.txt") or die "couldn't open category file"; #note: different for windows system
	#print the category sorted by importance
	$i = 0; #only want top 200
	foreach my $key (sort {@{$whash{$b}}[1] <=> @{$whash{$a}}[1]} keys(%whash)) 
	{
		#last if ($i>199);
		print OUTFILE "$key\t@{$whash{$key}}[0]\t@{$whash{$key}}[1]\n";
		$i++;
	}
	close(OUTFILE);
}


sub text
{
  my ($self,$text) = @_;

  $self->{TEXT} .= $text;
}
