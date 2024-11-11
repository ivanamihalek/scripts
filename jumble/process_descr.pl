#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

$ctr = 0;
undef $/;
$_ = <>;
$/ = "\n";
@names_for_hypo = ( "hypothetical", "probable", "putative", "-like", "predicted", "homolog");

@lines = split '\n';
for ($ctr=0; $ctr < @lines; $ctr+=3  ) {
    $gi = $lines[$ctr];
    $name = "";
    foreach $hypo ( @names_for_hypo) {
	if ( $lines[$ctr+1] =~ /$hypo/i ) {
	    $name = "hypo";
	}
    }
=pod
    if ( !$name ) {
	if ( $lines[$ctr+1] =~ /pgp/i ||  $lines[$ctr+1] =~  /P-glycoprotein/ ) {
	    $name = "pgp";
	} elsif ( $lines[$ctr+1] =~ /multidrug/i ||  $lines[$ctr+1] =~ /mdr/i ) {
	    $name = "mdr";
	}  elsif ( $lines[$ctr+1] =~ /peptide/i ||  $lines[$ctr+1] =~ /APT/i ) {
	    $name = "apt"; 
	} elsif ( $lines[$ctr+1] =~ /lipid/i ) {
	    $name = "lip"; 
	}  elsif ( $lines[$ctr+1] =~ /bile/i ) {
	    $name = "bile"; 
	}  elsif ( $lines[$ctr+1] =~ /tap/i ) {
	    $name = "tap"; 
	}  elsif ( $lines[$ctr+1] =~ /toxin/i ) {
	    $name = "tox"; 
	}  elsif ( $lines[$ctr+1] =~ /hly/i  || $lines[$ctr+1] =~ /hemolysin/i ) {
	    $name = "tox"; 
	}  else {
	    $name = "unk";
	}
    }
=cut
    $spec = "UNK";
    if (  $lines[$ctr+2] =~ /bacteria/i ) {
	$spec = "BAC";
    }  elsif (  $lines[$ctr+2] =~ /virus/i ) {
	$spec = "VIRAL";
    }  elsif (  $lines[$ctr+2] =~ /plantae/i ) {
	$spec = "PLANT";
    }  elsif (  $lines[$ctr+2] =~ /nematoda/i ) {
	$spec = "NEMA";
    }  elsif (  $lines[$ctr+2] =~ /Vertebrata/i ) {
	$spec = "VERT";
    }  elsif (  $lines[$ctr+2] =~ /Fungi/i ) {
	$spec = "FUNGI";
    }  elsif (  $lines[$ctr+2] =~ /Archaea/i ) {
	$spec = "ARCH";
    } elsif ( $lines[$ctr+1] =~ /\[(.+)\]/ ) {
	if ( $1 ne "imported" ) {
	    @aux = split " ", $1;
	    $spec = uc substr ($aux[0], 0, 3) ."_". uc substr ($aux[1], 0, 3);
	}
    }
    #$new_name = join "_", ($gi,  $name,  $spec);
    $new_name = join "_", ($gi,  $spec);
    print "$gi   $new_name   $name  $spec $lines[$ctr+1] \n";
}
