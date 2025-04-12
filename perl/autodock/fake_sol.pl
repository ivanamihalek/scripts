#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

$atom_ctr = 0;
$res_ctr = 0;
$res_seq_old = -1;
while ( <> ) {
    if ( /^ATOM/ || /^HETATM/ ) {
	chomp;
	$record = substr $_, 0, 6;  $record =~ s/\s//g;
	$serial = substr $_, 6, 5;  $serial =~ s/\s//g;
	$name = substr $_,  12, 4 ;  $name =~ s/\s//g;
	$alt_loc = substr $_,16, 1 ;  $alt_loc =~ s/\s//g;
	$res_name = substr $_,  17, 3; $res_name=~ s/\s//g;
	$chain_id = substr $_, 21, 1;  $chain_id =~ s/\s//g; 
	$res_seq  = substr $_, 22, 4;  $res_seq=~ s/\s//g;
	$i_code = substr $_, 27, 1;  $i_code=~ s/\s//g;
	$x = substr $_,30, 8;  $x=~ s/\s//g;
	$y = substr $_,38, 8;  $y=~ s/\s//g;
	$z = substr $_, 46, 8; $z=~ s/\s//g;

	$atom_ctr++;
	if ( $res_seq_old != $res_seq ) {
	    $res_seq_old = $res_seq;
	    $res_ctr ++;
	}
	if ( (length  $name) == 4 ) {
	    printf   "%-6s%5d %-4s%1s%-3s %1s%4d%1s   %8.3f%8.3f%8.3f", 
	    $record,   $serial,  $name,   $alt_loc,   $res_name,
	    $chain_id,  $res_seq ,   $i_code ,   $x,  $y,   $z;
	} else {
	    printf  "%-6s%5d  %-3s%1s%-3s %1s%4d%1s   %8.3f%8.3f%8.3f", 
	    $record,   $serial,  $name,   $alt_loc,   $res_name,
	    $chain_id,  $res_seq ,   $i_code ,   $x,  $y,   $z;
	}
    

	if (  length $_ >= 60 ) {
	    $occupancy = substr $_, 54, 6;
	    if ( $occupancy =~ /\S/)  {
		printf  "%6.2f",$occupancy
		} else {
		    printf  "%6.2f", 1.0;
		}
	} else {
	    printf  "%6.2f", 1.0;
	}
	if (  length $_ >= 66 ) {
	    $temp_factor = substr $_, 60, 6;
	    if ( $temp_factor =~ /\S/)  {
		printf  "%6.2f",$temp_factor;
	    } else {
		printf  "%6.2f", 0.0;
	    }
	} else {
	    printf  "%6.2f", 0.0;
	}

	$charge = substr $_, 66, 10 ;
	if ( $charge =~ /\S/)  {
	    printf  "%10.3f",$charge;
	} else {
	    printf  "%10.3f", 0.0;
	}
	printf  "%8.2f%8.2f\n", 0.0, 0.0;

	
    } else {
	print;
    }
}
