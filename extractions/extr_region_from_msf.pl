#! /usr/bin/perl -w 
use IO::Handle;         #autoflush
use File::Copy;     # copy a file (no kidding)
# FH -> autoflush(1);
defined $ARGV[2] ||
    die "Usage: extr_region_from_msf.pl <msffile> [-q <qry_name>] <from> <to> [ <from> <to>]\n"; 


$home = `pwd`;
chomp $home;
$msffile = shift @ARGV ;

$query = "";
if ( $ARGV[0] eq "-q" ) {
    shift @ARGV;
    $query = shift @ARGV;
}

$no_regions = @ARGV/2;

for ( $ctr=0; $ctr < $no_regions;  $ctr ++) {
    $from[$ctr] =  $ARGV[2*$ctr] -1;
    $to[$ctr]   =  $ARGV[2*$ctr+1] - 1;
}

open ( MSF, "<$msffile" ) ||
    die "Cno: $msffile  $!\n";
	

while ( <MSF>) {
    last if ( /\/\// );
}

@names = ();
while ( <MSF>) {
    next if ( ! (/\w/) );
    chomp;
    @aux = split;
    $seq_name = $aux[0];
    $seq_name =~ s/\s//g; 
    if ( defined $seqs{$seq_name} ){
	$seqs{$seq_name} .= join ('', @aux[1 .. $#aux]);
    } else { 
	$seqs{$seq_name}  = join ('', @aux[1 .. $#aux]);
	push @names, $seq_name;
	$ctr ++;
    }
}

close MSF;

#for ($region_ctr=0; $region_ctr < $no_regions; $region_ctr++) {
#    printf " $region_ctr    $from[$region_ctr]    $to[$region_ctr]\n";
#}

if ( $query ) {
    grep ( $_ eq $query, @names ) ||
	die "$query not found in $msffile.\n";
    # if the query is given, the from and to are
    # understood to refer to query
    @sequence = split '', $seqs{$query};
    $ctr = 0;
    $query_ctr = -1;
    for ($region_ctr=0; $region_ctr < $no_regions; $region_ctr++) {
	$from_set = 0;
	for ( ; $ctr<= $#sequence; $ctr++) {
	    if ( $sequence[$ctr] ne "." ) {
		$query_ctr ++;
		if ( !$from_set && $from[$region_ctr] == $query_ctr ) {
		    $from[$region_ctr] = $ctr;
		    $from_set = 1;
		} elsif ( $to[$region_ctr] == $query_ctr ) {
		    $to[$region_ctr] = $ctr;
		    last;
		}
	    }
	}
    }
    
}
#for ($region_ctr=0; $region_ctr < $no_regions; $region_ctr++) {
#    printf " $region_ctr    $from[$region_ctr]    $to[$region_ctr]\n";
#}
		
#exit;

foreach $name ( @names ) {
    $old_seq = $seqs{$name};
    $seqs{$name} = "";
    $seqlen = 0;
    for ($region_ctr=0; $region_ctr < $no_regions; $region_ctr++) {
	$seqlen2 = $to[$region_ctr] - $from[$region_ctr] +1;
	$seqs{$name} .= substr ( $old_seq, $from[$region_ctr], $seqlen2);
	$seqlen      += $seqlen2;
   }
}


print "PileUp\n\n";
print "            GapWeight: 30\n";
print "            GapLengthWeight: 1\n\n\n";
printf ("  MSF: %d  Type: P    Check:  9554   .. \n\n",$seqlen) ;
for $name (@names) {
    printf " Name: %-20s   Len: %5d   Check: 9554   Weight: 1.00\n", 
	    $name, length $seqs{$name};
}
printf "\n//\n\n\n\n";

$seqlen = length $seqs{$names[0]};

for ($j=0; $j  < $seqlen; $j += 50) {
    for $name ( @names) {
	printf "%-30s", $name;
	for ( $k = 0; $k < 5; $k++ ) {
	    if ( $j+$k*10+10 >= $seqlen ) {
		printf ("%-10s ",   substr ($seqs{$name}, $j+$k*10 ));
		last;
	    } else {
		printf ("%-10s ",   substr ($seqs{$name}, $j+$k*10, 10));
	    }
	}
	printf "\n";
    } 
    printf "\n";
}
