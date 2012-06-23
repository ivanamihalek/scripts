#! /usr/bin/perl -w
# find box around set of PDB coords - for docking

use IO::Handle;         #autoflush
# FH -> autoflush(1);


(defined $ARGV[0] && defined $ARGV[1]  ) ||
    die "usage: coordbox.pl   <list_of_res> <pdbfile> \n.";

$spacing = 0.15;


$listfile = $ARGV[0];
$pdbfile = $ARGV[1];

open (LISTFILE, "<$listfile") ||
    die "could not open $listfile.\n";

@list = ();
while ( <LISTFILE>) {
    next if ( ! /\S/);
    @aux = split;
    push @list, $aux[0];
}
close LISTFILE;


open (PDBFILE, "<$pdbfile") ||
    die "could not open $pdbfile.\n";
$min = ();
$max = ();
while ( <PDBFILE> ) {
    next if ( ! /^ATOM/ );
    next if ( substr ($_, 26, 1) =~ /\S/) ;

    $res_seq  = substr $_, 22, 4;  $res_seq=~ s/\s//g;
    $c[0] = substr $_,30, 8;  $c[0]=~ s/\s//g;
    $c[1] = substr $_,38, 8;  $c[1]=~ s/\s//g;
    $c[2] = substr $_, 46, 8; $c[2]=~ s/\s//g;

    for $aa ( @list) {
        if ( $aa == $res_seq ) {
	    print;
	    last;
	}
    }

}

close PDBFILE;

