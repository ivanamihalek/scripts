#! /usr/bin/perl -w

@ARGV ||
    die "Usage:  $0  <file name> \n";

$filename = $ARGV[0];
open (IF, "<$filename" ) 
    || die "Cno $filename: $!.\n";

while ( <> ) {
    /^ATOM/ || next;
    $atom_name = substr $_, 12, 4; $atom_name=~ s/\s//g;
    $atom_name eq 'N' || next;
    $res_seq   = substr $_, 22, 5;  $res_seq=~ s/\s//g;
    print $res_seq, "\n";
}

close IF;
