#!/usr/local/bin/perl -w 
use strict;
   
   package Example;
   
   
   require HTML::Parser;
   
   @Example::ISA = qw(HTML::Parser);
   
   my $parser = Example->new;
   
   $parser->parse_file('wikipedia_random_article.txt');
   
   print $parser->{TEXT};
   
   sub text
    {
      my ($self,$text) = @_;
   
      $self->{TEXT} .= $text;
    }
