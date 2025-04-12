#! /usr/bin/perl -w

@ARGV>1 || die "Usage:  $0  <file name>  <chain_name> \n";

$filename = $ARGV[0];
$target_chain = $ARGV[1];

open (IF, "<$filename" )
    || die "Cno $filename: $!.\n";

while ( <IF> ) {
    /^ATOM/ || next;
    $chain_name = substr $_, 21, 1;
    $chain_name eq $target_chain || next;
    $atom_name = substr $_, 12, 4; $atom_name=~ s/\s//g;
    $atom_name eq 'N' || next;
    $res_seq   = substr $_, 22, 5;  $res_seq=~ s/\s//g;
    $res_name = substr $_, 17, 3;  $res_name=~ s/\s//g;
    print "$res_seq\t$res_name\n";
}

close IF;
