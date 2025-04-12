#! /usr/bin/perl 
use IO::Handle;         #autoflush
use FileHandle;
# FH -> autoflush(1);

defined $ARGV[0]  ||
    die "Usage: hbparse.pl <base_name>. \n";

$hbfile = "../default_dist/". uc ($ARGV[0]).".hb2";
( -e $hbfile ) ||
    die "$hbfile does not exist.\n";

open (HB, "<$hbfile") ||
    die "Cno $hbfile: $!.\n"; 



$ctr++;
while ( <HB> && $ctr <8) {
    $ctr++;
}

while ( <HB> ) {
    #chomp;
    @aux = split '';
    unshift @aux, ' ';
    # hbplus output format:
    $donor_chain_id   = join ('', @aux[1 .. 1] );
    $donor_residue_no = join ('', @aux[2 .. 5] );
    $donor_ins_code   = join ('', @aux[6 .. 6] );
    $donor_aa_code    = join ('', @aux[7 .. 9] );
    $donor_atom_type  = join ('', @aux[10 .. 13] );

    $acceptor_chain_id   = join ('', @aux[15 .. 15] );
    $acceptor_residue_no = join ('', @aux[16 .. 19] );
    $acceptor_ins_code   = join ('', @aux[20 .. 20] );
    $acceptor_aa_code    = join ('', @aux[21 .. 23] );
    $acceptor_atom_type  = join ('', @aux[24 .. 27] );

    $da_dist           = join ('', @aux[28 .. 32] );
    $donor_category    = join ('', @aux[34 .. 34] );
    $acceptor_category = join ('', @aux[35 .. 35] );
    $gap               = join ('', @aux[37 .. 39] );
    $da_dist_calpha    = join ('', @aux[41 .. 45] );
    $bond_angle        = join ('', @aux[47 .. 51] );
    $ha_dist           = join ('', @aux[53 .. 57] );
    $blah1_angle       = join ('', @aux[59 .. 63] );
    $blah2_angle       = join ('', @aux[65 .. 69] );
    $hb_count          = join ('', @aux[71 .. 75] );
    next if ( $donor_chain_id    =~ $acceptor_chain_id ) ;
    next if ( $acceptor_aa_code =~ "HOH" || $donor_aa_code =~ "HOH");
    if ( $donor_chain_id    !~ '-' ) {
	$pair_id = $donor_chain_id.".".$acceptor_chain_id;
	if ( !defined $filehandle{$pair_id} ) {
	    $new_filename = "$pair_id.hb2.pdb_epitope";
	    printf "opening new file $new_filename.\n";
	    $fh = new FileHandle($new_filename,">") 
		or die "Cno $new_filename: $! \n";
	    $filehandle{$pair_id} = $fh;
	    $filename{$pair_id} = $new_filename;
	} else {
	    $fh = $filehandle{$pair_id};
	}
	$donor_residue_no =~ /0*(\d+)/;
	print $fh " $1 \n";
    }

    if ( $acceptor_chain_id !~ '-' ) {
	$pair_id = $acceptor_chain_id.".".$donor_chain_id;
	if ( !defined $filehandle{$pair_id} ) {
	    $new_filename = "$pair_id.hb2.pdb_epitope";
	    printf "opening new file $new_filename.\n";
	    $fh = new FileHandle($new_filename,">") 
		or die "Cno $new_filename: $! \n";
	    $filehandle{$pair_id} = $fh;
	    $filename{$pair_id} = $new_filename;
	} else {
	    $fh = $filehandle{$pair_id};
	}
	$acceptor_residue_no =~ /0*(\d+)/;
	print $fh " $1 \n";
    }

  
}


foreach $pair_id ( keys %filehandle ) {
    close $filehandle{$pair_d};
    @chains = split '\.', $pair_id;
    $chaindir = "../".lc ($ARGV[0]).$chains[0];

    if ( -e $chaindir )  {
	`mv $filename{$pair_id} $chaindir`;
    } else {
	`rm $filename{$pair_id}`;
    }
}
