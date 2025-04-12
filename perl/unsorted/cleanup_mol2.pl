#! /usr/bin/perl -w

# arrange mol2 the way Dock program likes it (this
# is apparently SYBYL version of the original Tripos format

@ARGV ||
    die "Usage:  $0  <file name> \n";

$filename = $ARGV[0];
open (IF, "<$filename" ) 
    || die "Cno $filename: $!.\n";

($atom_id,  $atom_name, $x, $y, $z,
 $atom_type, $subst_id, $subst_name, $crap) = ();

while ( <IF> ) {
    last if ( /\@\<TRIPOS\>MOLECULE/ );    
}

@mol_info = ();
while ( <IF> ) {
    
    last if ( /\@\<TRIPOS\>ATOM/ );
    push @mol_info, $_;
}

################################################
#  read in atoms
$subst_id = 0;
@atoms = ();
@subst_ids = ();
while ( <IF> ) {

    next if ( !/\S/);
    last if ( /TRIPOS/);
    
    chomp;
    ($atom_id,  $atom_name, $x, $y, $z,
    $atom_type, $old_subst_id, $subst_name, $crap) = split;
    
    if ( ! defined $seen{$old_subst_id} ) {
	$seen{$old_subst_id} = 1;
	$subst_id++;
	push @subst_ids,$subst_id;
	$subst_name{$subst_id} = $subst_name;
    }

    ($atom_name eq "CA" )  && ($root{$subst_id} = $atom_id);

#12345678901|345678901234567890123456789012345678901234567890123|567890123456789
#     3 C          19.9620   27.8960   54.5040 C.2       1 GLY2        0.5973
    $line = sprintf "  %5d %-5s    %9.4f %9.4f %9.4f %-5s %5d %-5s    %9.4f\n",
	$atom_id, $atom_name, $x, $y, $z, $atom_type, $subst_id, $subst_name, $crap;
    push @atoms, $line;

}

################################################
# read in bonds
@bonds = ();
while ( <IF> ) {
    next if ( !/\S/);
    last if ( /TRIPOS/);
    push @bonds, $_;
}

close IF;

################################################
# create substructure fields
# subst_id subst_name root_atom [subst_type [dict_type
# [chain [sub_type [inter_bonds [status
# [comment]]]]]]]

$ctr = 0;
@substr = ();
foreach $subst_id (@subst_ids) {
    $ctr++;

    $line = sprintf  "%6d %-6s  %5d RESIDUE           4 A     %3s     ",
    $subst_id, $subst_name{$subst_id},  $root{$subst_id}, 
    substr $subst_name{$subst_id}, 0, 3;

    if ( $ctr == 1) {
	$line .=  "1 ROOT\n";
    } else {
	$line .=  "2\n";
    }
    push @substr, $line;
    
}


print "@<TRIPOS>MOLECULE\n";
$line_ctr = 0;
foreach (@mol_info) {
    $line_ctr++;
    if ( $line_ctr == 2) {
	printf "%6d  %6d  %6d  0  0\n", scalar @atoms, scalar @bonds, scalar  @substr;
    } else {
	print;
    }
}

while ($line_ctr < 6 ) {
     $line_ctr++;
     print "\n";
   
}


print "@<TRIPOS>ATOM\n";
print @atoms;

print "@<TRIPOS>BOND\n";
print @bonds;

print "@<TRIPOS>SUBSTRUCTURE\n";
print @substr;



#23456 123456------2 RESIDUE           4 A     123
#     1 GLY2        2 RESIDUE           4 A     GLY     1 ROOT
