open(INDEX, "<dictionary20110411.txt") or die "couldn't open file dictionary20110411.txt to read from\n";
my %whash=();	#(key,value) = (word, (part of speech, frequency))

#read dictionary.txt into whash
foreach (<INDEX>)
{
	chomp;
	my @key_value=split(/\s+/, $_);
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

print $whash{"baseball"}->[1]
