#! /usr/bin/perl -w


%letter_code = ( 'GLY', 'G', 'ALA', 'A',  'VAL', 'V', 'LEU','L', 'ILE','I',
                 'MET', 'M', 'PRO', 'P',  'TRP', 'W', 'PHE','F', 'SER','S',
                 'CYS', 'C', 'THR', 'T',  'ASN', 'N', 'GLN','Q', 'TYR','Y',
                 'LYS', 'K', 'ARG', 'R',  'HIS', 'H', 'ASP','D', 'GLU','E', 'PTR', 'Y',
                 'MSE', 'M' ); 

$res_ctr = 0;
$old_res_seq = -100;
$old_res_name  ="";
$outstr  = "";

$tot_found = 0;

%seen = ();

while (<> ) {


    next if ( ! /^ATOM/ ) ;


    # looks like I have to format it seriously
    $record = substr $_, 0, 6;  $record =~ s/\s//g;
    $serial = substr $_, 6, 5;  $serial =~ s/\s//g;
    $name = substr $_,  12, 4 ;  $name =~ s/\s//g; 
    $name =~ s/\*//g; 
    
    $alt_loc = substr $_,16, 1 ;  $alt_loc =~ s/\s//g;
    $res_name = substr $_,  17, 3; $res_name=~ s/\s//g;
    $chain_id = substr $_, 21, 1;  $chain_id =~ s/\s//g; 
    $res_seq  = substr $_, 22, 4;  $res_seq=~ s/\s//g;
    $i_code = substr $_, 27, 1;  $i_code=~ s/\s//g;
    #replace coords with 0
    (substr $_,30, 8) =  sprintf "%8.3f", 0.0;
    (substr $_,38, 8) =  sprintf "%8.3f", 0.0;
    (substr $_,46, 8) =  sprintf "%8.3f", 0.0;
    (substr $_,53, 7) =  sprintf "%7.2f", 1.0;
    (substr $_,60, 7) =  sprintf "%6.2f ", 0.0;

    next if ( $alt_loc =~ "B" );
    next if ( $alt_loc =~ "C" );
    $alt_loc = " ";



    if ( $res_seq != $old_res_seq ||   $res_name ne $old_res_name) {
	if ($outstr && !defined $seen{$old_res_name}) {
	    $seen{$old_res_name}  = 1;
	    $letter = $letter_code{$old_res_name};

	    #print "$old_res_name  $letter\n";
	    chomp $outstr;
	    print "\$dummy_coords\{\"$letter\"\} = \n".
		"\"$outstr\";\n";
	    $tot_found ++;
	}
	$outstr = $_;
	$old_res_seq  =  $res_seq;
	$old_res_name =  $res_name;
	$res_ctr++;
    } else {
	$outstr .= $_;
    }

 
 
}


#print "res $res_ctr\n";
#print "tot $tot_found\n";
