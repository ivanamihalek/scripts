#! /usr/bin/perl -w 
use IO::Handle;         #autoflush
use File::Copy;     # copy a file (no kidding)

# FH -> autoflush(1);
defined $ARGV[1]  ||
    die "Usage: remove_short_msf.pl <msffile> <protected_sequence or list_file_name> [ <lowest id fraction>].\n"; 


$home = `pwd`;
chomp $home;
$msf_name  = $ARGV[0] ;

$name =  $ARGV[1];
@protected_names = ();
if ( -e $name ) { #it's a file
    open IF, "<$name" || die "Cno $name.\n";
    while ( <IF> ) {
	chomp; @aux = split;
	push @protected_names, $aux[0];
    }
} else {
    push @protected_names, $name
}
$query = shift @protected_names;


$lowest = 0.75;

(defined $ARGV[2] ) && ( $lowest = $ARGV[2]);

open ( MSF, "<$msf_name" ) ||
    die "Cno: $msf_name  $!\n";
	

while ( <MSF>) {
    if ( /^ Name/ ) {
	@aux = split;
	$seq_name = $aux[1];
	push @names,$seq_name;
    }
    last if ( /\/\// );
    last if ( /CLUSTAL FORMAT for T-COFFEE/ );
}

while ( <MSF>) {
    next if ( ! (/\w/) );
    chomp;
    @aux = split;
    $seq_name = $aux[0];
    if ( defined $sequence{$seq_name} ){
	$sequence{$seq_name} .= join ('', @aux[1 .. $#aux]);
    } else { 
	$sequence{$seq_name}  = join ('', @aux[1 .. $#aux]);
    }
}

close MSF;
defined  $sequence{$query} ||
    die " Sequence  $query  not found in $msf_name.\n";

   
$aux_string = $sequence{$query};
$aux_string =~ s/\.//g;
$query_length = length $aux_string;

foreach $seq_name ( @names ) {
    $aux_string = $sequence{$seq_name};
    $aux_string =~ s/\.//g;
    if ( length ( $aux_string) < $lowest *$query_length ) {
	$skip{$seq_name} = 1;
    } else {
	$skip{$seq_name} = 0;
    }
}

foreach $seq_name (@protected_names) {
    $skip{$seq_name} = 0;
}



$seqlen = length $sequence{$query};
print "PileUp\n\n";
print "            GapWeight: 30\n";
print "            GapLengthWeight: 1\n\n\n";
printf ("  MSF: %d  Type: P    Check:  9554   .. \n\n",$seqlen) ;
foreach $name ( @names  ) {
    next if ($skip{$name} );
    printf (" Name: %-20s   Len: %5d   Check: 9554   Weight: 1.00\n", $name, $seqlen);
}
printf "\n//\n\n\n\n";

for ($j=0; $j  < $seqlen; $j += 50) {
    foreach $name ( @names  ) {
	next if ($skip{$name} );
	printf "%-30s", $name;
	for ( $k = 0; $k < 5; $k++ ) {
	    if ( $j+$k*10+10 >= $seqlen ) {
		printf ("%-10s ",   substr ($sequence{$name}, $j+$k*10 ));
		last;
	    } else {
		printf ("%-10s ",   substr ($sequence{$name}, $j+$k*10, 10));
	    }
	}
	printf "\n";
    } 
    printf "\n";
}
