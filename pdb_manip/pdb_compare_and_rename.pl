#! /usr/bin/perl -w

# given 2 pdb files in 1:1 atom correspondence, rename chains
# adn residues in the 1st file, taking the names from the 2nd

defined ( $ARGV[1] ) ||
    die "Usage: pdb_compare_and_rename.pl <pdbfile_to_be renamed> <pdbfile_with_usable_names>.\n";
($pdb1, $pdb2) = @ARGV; 


open ( IF1, "<$pdb1" ) ||
    die "Cno $pd1:$!.\n";


open ( IF2, "<$pdb2" ) ||
    die "Cno $pd1:$!.\n";

 $line_ctr_1 = 0;
 $line_ctr_2 = 0; 

while ( <IF1> ) {

    $line_ctr_1 ++;

    next if ( ! /^ATOM/ && ! /^HETATM/ );
     
    $line1 = $_;
    $atom_name_1 = substr $line1,  12, 4 ; $atom_name_1 =~ s/\s//g; 
    next  if ($atom_name_1 eq "O2");
    $res_name_1  = substr $line1,  17, 3;  $res_name_1  =~ s/\s//g;
    $chain_id_1  = substr $line1, 21, 1;   $chain_id_1  =~ s/\s//g; 
    $res_seq_1   = substr $line1, 22, 4;   $res_seq_1   =~ s/\s//g;

    while ( <IF2> ) {
	$line_ctr_2 ++;
	next if ( ! /^ATOM/ && ! /^HETATM/ );
	$line2 = $_;
	$atom_name_2 = substr $line2, 12, 4;  $atom_name_2 =~ s/\s//g; 
	next  if ($atom_name_2 eq "O2");
	$res_name_2  = substr $line2, 17, 3;  $res_name_2  =~ s/\s//g;
	$chain_id_2  = substr $line2, 21, 1;  $chain_id_2  =~ s/\s//g; 
	$res_seq_2   = substr $line2, 22, 4;  $res_seq_2   =~ s/\s//g;
	last;
    }

    if( $res_name_1 ne $res_name_2 ) {
	die " residue name mismatch at $pdb1:$line_ctr_1 and $pdb2:$line_ctr_2 .\n";
    }
    (substr $line1, 21, 1) = $chain_id_2;
    $formt = sprintf "%4d",  $res_seq_2;
    (substr $line1, 22, 4) = $formt;
    print $line1;
}


close IF1;
close IF2;


