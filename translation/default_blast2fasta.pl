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
       #$descr =~ s/\s\s/ /g;
       $reading_descr = 0;
       #print "$name\n$descr\n\n";
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
close  BLAST;


open ( FASTA, ">$qry_name.fasta" ) ||
    die "Cno :$qry_name.fasta  $!\n";
	

    foreach $seq_name ( keys %sequence ) {
	
	@seq = split ('', $sequence{$seq_name});
	print FASTA ">$seq_name \n";
	$ctr = 0;
	for $i ( 0 .. $#seq ) {
	    if ( $seq[$i] !~ '\.' ) {
		( $seq[$i] =~ '\-' ) && ( $seq[$i] = '.' );
		print FASTA  $seq[$i];
		$ctr++;
		if ( ! ($ctr % 50) ) {
		    print FASTA "\n";
		}

	    }
	}
	print FASTA "\n";
    }

close FASTA;



