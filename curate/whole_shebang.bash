#!/bin/bash

#quiz_file=$(perl fileDialog2.pl)
#echo $quiz_file

perl ~maxwellb/Documents/questionwriter/Perl-Quiz/curate/questionwriter_pos_plaintext.pl $1

perl ~maxwellb/Documents/questionwriter/Perl-Quiz/curate/plaintext_to_html.pl

firefox ~maxwellb/Documents/questionwriter/Perl-Quiz/curate/uncurated_questions.html
