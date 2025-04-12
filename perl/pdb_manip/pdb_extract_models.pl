#! /usr/bin/perl -w

(@ARGV == 1) ||
    die "Usage: $0 <pdb name (root)>.\n";

$name = $ARGV[0];
$reading = 0;

open (IF, "<$name.pdb") ||
    die "Cno $name.pdb: $!\n";

while ( <IF> ) {
    chomp;
    if ( /^MODEL/ ) {
	if ( $reading ) {
	    close FH;
	}
	$reading = 1;
	@aux = split;
	$filename = $name.".".$aux[1].".pdb";
	open (FH, ">$filename") || 
	    die "Cno $filename: $!\n";
	print FH "$_\n";
    } elsif (/^ATOM/ || /^HETATM/ ) {
	next if ( ! $reading );
	@aux = split ('', $_);;
	print FH "$_\n";
    }  elsif (/^END/ ) {
	print FH "$_\n";
    }

}

close FH;

close IF;
