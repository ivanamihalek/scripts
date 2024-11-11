#!/usr/bin/perl -w

#   basicNaccess.pl 1hiaABXY 1hiaABXYIJ

#ivica Res  March 2004 
# obtained from interNaccess.pl - only the input is more elementary
# it takes a chain and a complex, and the output are the resulting interface and area

defined $ARGV[1] ||
    die "Usage: basic_naccess.pl <single_chain_pdb> <dimer_pdb>.\n"; 

open(IN,"$ARGV[0].rsa") ||                               #first chain
    die "Cno: $ARGV[0].rsa: $!.\n";
open(INPUT,"$ARGV[1].rsa") ||   #combined 2 chains   
    die "Cno: $ARGV[1].rsa: $!.\n";

open (OUT,">$ARGV[0].inter")    ||                      #output for interacting residues
    die "Cno: $ARGV[0].inter: $!.\n";
    
open (SURF,">$ARGV[0].surf")    ||                      #output for surface residues
    die "Cno: $ARGV[0].surf: $!.\n";

findInterface();                                      #interface for the first chain

close IN;
close OUT;
close SURF;


sub findInterface {

    my $line;
    my $temp;
    
    while ($line = <IN>) {
	last if $line =~ /REM                ABS/;
    }

    $temp = -1;
    while ($line = <IN>) {
	last if $line =~ /^END /;
	$s1 = substr($line,9,4);    # res number
	$s2 = uc substr($line,4,3);   # residue
	$s3 = substr($line,36,5);   # surface acc.
	$chain = uc substr($line,8,1);

	    while ($comb = <INPUT>) {
		last if $comb =~ /REM                ABS/;
	    }
	    while ($comb = <INPUT>) {
		$s1Comb = substr($comb,9,4);  
		$s3Comb = substr($comb,36,5);
		$chainId = uc substr($comb,8,1);
		last if $s1Comb eq  $s1  && $chainId eq $chain;
	    }
	    seek(INPUT,0,0);

	    if ($s1Comb != $s1) {
		print "PROBLEM\n";
		exit;
	    } 
	    if ($temp != $s1 && $s3 > 5.) {       #surface residues have relative surf. acces > 5%  	

		printf SURF "%5d  %1s  %1s\n",  $s1, $chainId, $s2;
		#next if ( ! $s3 );
		#if ( $s3Comb/$s3 <= 0.25 ) {             # interface loss of  relative surf accesibility upon complexation
		if ( $s3Comb  < 5.0  ) {             # interface loss of  relative surf accesibility upon complexation
		    #	printf OUT "%5d  %1s  %4d  %4.2f\n",  $s1, $s2, $s3, $s4;
		    printf OUT "%5d  %1s  %1s\n",  $s1, $chainId, $s2;

		}

	    }
	  	$temp = $s1;  
	
	#$temp = $s1;  # sometimes several res are given same res number
	# I choose the first one to occur
    }
}

