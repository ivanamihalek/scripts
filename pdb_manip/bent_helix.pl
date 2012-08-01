#! /usr/bin/perl -w

use Math::Trig;


(@ARGV >= 3) ||
    die "Usage:  $0  <pdb trj>  <residue from>  <residue to> \n";


($pdbtrj, $res_from, $res_to) = @ARGV;


$lsf3d = "/home/ivanam/c-utils/linear_ls_fit/three_dee/lsf3";


$filename = $pdbtrj;

open (IF, "<$filename" ) 
    || die "Cno $filename: $!.\n";

while ( <IF> ) {
    if ( /^MODEL\s+(\d+)/ ) {

	$model_no = $1;
	@coords = ();

    } elsif (  /^ENDMDL/ || /^TER/  ) {

	@midpoints = ();
	foreach $coord_ctr( 0 .. $#coords-2 ) {
	    @point_m1 = split " ", $coords[$coord_ctr];
	    @point = split " ",    $coords[$coord_ctr+1];
	    @point_p1 = split " ", $coords[$coord_ctr+2];
	    for ($i=0; $i<3; $i++) {
		$avg[$i] =  ($point_p1[$i]+ $point[$i]+  $point_m1[$i])/3;
	    }
	    push @midpoints, join  " ", @avg;
	}
	#$half = int (@midpoints/2);

	# fit to n-terminal
	open (TMP, ">tmp") || die "Cno tmp: $!.\n";
	#print TMP join "\n", @midpoints[0..$half];
	print TMP join "\n", @midpoints[0..5];
	print TMP "\n";
	close TMP;

	
	$ret = `$lsf3d tmp`;
	chomp $ret;

	@line = split "\n", $ret;
	@cm_nterm = split " ", $line[0];  shift @cm;
	@p_nterm =  split " ", $line[1]; shift @p_nterm;


	# fit to c-terminal
	open (TMP, ">tmp") || die "Cno tmp: $!.\n";
	print TMP join "\n", @midpoints[$#midpoints-5 .. $#midpoints];
	print TMP "\n";
	close TMP;
	$ret = `$lsf3d tmp`;
	chomp $ret;

	@line = split "\n", $ret;
	@cm_cterm = split " ", $line[0];  shift @cm;
	@p_cterm =  split " ", $line[1]; shift @p_cterm;

	print "  @p_nterm  @cm_nterm    @p_cterm  @cm_cterm \n";
	exit;
 
	$cos = 0;
	for $i ( 0 ..2 ) {
	    $cos += $p_nterm[$i]*$p_cterm[$i];
	}


	$cos = abs ($cos); 
	printf "$model_no   %5.2f    %5.1f  \n", $cos, acos ($cos)*180/3.14;


    } elsif ( /^ATOM/ ) {

	$res_seq  = substr $_, 22, 4;  $res_seq=~ s/\s//g;
	next if ( $res_seq< $res_from ||  $res_seq> $res_to);

	$name = substr $_,  12, 4;     $name =~ s/\s//g; 
	
	#next if ( $name ne "N" && $name ne "C" && $name ne "O");
	next if ($name ne "CA");
	
	push @coords , (substr $_,30, 24);
	    
    }
}

close IF;

