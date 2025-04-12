#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

defined ( $ARGV[1] ) ||
    die "Usage: default_blast2msf.pl <blastfile> <queryfile.\n";

$blastfile = $ARGV[0];
$queryfile = $ARGV[1];

open (  QRY, "<$queryfile" ) ||
    die "Cno $queryfile: $!.\n";

$query = "";
while ( <QRY> ) {
    if ( /^>/ ) {
	if ( $query ) {
	    printf "Warning: more than two seqs in $queryfile. Using the first one.\n";
	    last;
	} else {
	    /^>\s*(\S+)/;
	    $qry_name = $1;
	    next;
	}
    }
    next if ( ! /\S/ );
    chomp;
    $query .= $_;
}
close QRY;
$query =~ s/\s//g;

$sequence{$qry_name } = $query;


open ( DESCR, ">$qry_name.descr") ||
    die "Cno $qry_name.descr: $!.\n";

open (  BLAST, "<$blastfile" ) ||
    die "Cno $blastfile: $!.\n";


$reading_descr = 0;
$reading = 0;
$descr = "";
@name_array = ();
$linectr = 0;
while ( <BLAST> ) {
    $linectr++;
    if ( /^>/ ) {
       $reading_descr = 1;
       @aux = split;
       $descr = join ' ', @aux[1 .. $#aux];
       @aux2 = split '\|', $aux[0];
       $name = $aux2[1];
       $map{$name} = "";
       $sequence{$name} = "";
       $reading = 1;
       push @name_array, $name;
   } elsif ( /Length/ ) {
       $descr =~ s/\s\s/ /g;
       $descr =~ s/\n//g;
       $reading_descr = 0;
       print DESCR  "$name\t\t $descr\n";
   } elsif ( $reading_descr) {
       $descr .= $_;
   } elsif ( /Score/ ) {
       if  ( ! $map{$name} ) {
	   $reading = 1;
       } else {
	   $reading = 0;
       }
   } elsif ( $reading && /Query/ ) {
       chomp;
       /\:\s*(\d+)\s*([\D\S]+)\s+(\d+)/; # I cannot count on any type of formatting here
       $start = $1;
       #print "  $start  *$seq*  $end\n"; exit;
       if ( $map{$name} && $start != $end + 1 ) {
	   printf "Error: unexpected formatting at line $linectr \n";
	   printf "start: %d     end previous: $end\n", $start, $end;
	   exit;
       }
       $seq = $2;
       $end = $3;
       $offset = $start - 1;
       if ( !  $map{$name} ) {
	   substr ($map{$name}, 0, $offset)  =  substr ($query, 0, $offset);
       } 
       $seq =~ s/\s//g;
       $map{$name}.= $seq;
       
    } elsif (  $reading && /Sbjct/ ) {
       chomp;
       /\:\s*\d+\s*([\D\S]+)\s+\d+/; # I cannot count on any type of formatting here
       $seq = $1;

       if ( !  $sequence{$name} ) {
	   $ctr = 0;
	   for  $ctr ( 1 .. $offset ) {
	       $sequence{$name} .= "-";
	   }
       }
        $seq =~ s/\s//g;
      $sequence{$name}.= $seq;
       
     
   }
}

close DESCR;

close  BLAST;





# use only positions which map on  the query


$new_sequence{$qry_name} = $query;
@ref_array = split '', $query;
 
foreach $name ( @name_array ) {
    @position = split '', $sequence{$name}; 
    @map_array = split '', $map{$name};
    $ctr = 0;
    @new_array = ();
    foreach $pos_ctr (  0 .. $#position ) { 
	if ( $map_array[$pos_ctr] eq "-" ) {
	    #printf " %4d  %s     %4d %s %s \n", 
	    #0, "",  $pos_ctr, $map_array[$pos_ctr], $position[$pos_ctr]; 
	} else {
	    #printf " %4d  %s     %4d %s %s \n", 
	    #$ctr, $ref_array[$ctr], $pos_ctr, $map_array[$pos_ctr], $position[$pos_ctr]; 
	    $new_array[$ctr] = $position[$pos_ctr];
	    $ctr ++;
	} 
    } 
    $new_sequence{$name} = join '', @new_array;
    for $ctr ( $#new_array+1 .. $#ref_array ) {
	$new_sequence{$name} .=  "-";
    }
} 

open ( MSF, ">$qry_name.msf") ||
    die "Cno $qry_name.msf: $!.\n";

$seqlen = length $query;
print MSF  "PileUp\n\n";
print MSF  "            GapWeight: 30\n";
print MSF  "            GapLengthWeight: 1\n\n\n";
printf MSF ("  MSF: %d  Type: N    Check:  9554   .. \n\n",$seqlen) ;
foreach $name ( keys  %new_sequence ) {
    printf MSF (" Name: %-20s   Len: %5d   Check: 9554   Weight: 1.00\n", $name, $seqlen);
}
printf MSF "\n//\n\n\n\n";

for ($j=0; $j  < $seqlen; $j += 50) {
    foreach $name (   keys  %new_sequence ) {
	$new_sequence{$name} =~ s/\-/./g;
	printf MSF "%-40s", $name;
	for ( $k = 0; $k < 5; $k++ ) {
	    if ( $j+$k*10+10 >= $seqlen ) {
		printf MSF ("%-10s ",   substr ($new_sequence{$name}, $j+$k*10 ));
		last;
	    } else {
		printf MSF ("%-10s ",   substr ($new_sequence{$name}, $j+$k*10, 10));
	    }
	}
	printf MSF "\n";
    } 
    printf MSF "\n";
}

close MSF;
