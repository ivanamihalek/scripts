#! /usr/bin/perl -w

@ARGV ||
    die "Usage:  $0  <file name> \n";

$filename = $ARGV[0];
open (IF, "<$filename" ) 
    || die "Cno $filename: $!.\n";

($atom_id,  $atom_name, $x, $y, $z,
 $atom_type, $subst_id, $subst_name) = ();

@subst_ids = ();


while ( <IF> ) {
    last if ( /\@\<TRIPOS\>ATOM/ );
}


while ( <IF> ) {

    next if ( !/\S/);
    last if ( /TRIPOS/);
    
    chomp;
    ($atom_id,  $atom_name, $x, $y, $z,
    $atom_type, $subst_id, $subst_name) = split;
    
    if ( ! defined $seen{$subst_id} ) {
	$seen{$subst_id} = 1;
	push @subst_ids,$subst_id;
	$subst_name{$subst_id} = $subst_name;
    }

    ($atom_name eq "CA" )  && ($root{$subst_id} = $atom_id)
}

close IF;



# subst_id subst_name root_atom [subst_type [dict_type
# [chain [sub_type [inter_bonds [status
# [comment]]]]]]]

print "@<TRIPOS>SUBSTRUCTURE\n";
$ctr = 0;

foreach $subst_id (@subst_ids) {
    $ctr++;

    printf "%6d %-6s  %5d RESIDUE           4 A     %3s     ",
    $subst_id, $subst_name{$subst_id},  $root{$subst_id}, 
    substr $subst_name{$subst_id}, 0, 3;

    if ( $ctr == 1) {
	printf "1 ROOT\n";
    } else {
	printf "2\n";
    }

}

#23456 123456------2 RESIDUE           4 A     123
#     1 GLY2        2 RESIDUE           4 A     GLY     1 ROOT
