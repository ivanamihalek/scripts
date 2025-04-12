#! /usr/bin/perl -w 
use strict;
use warnings FATAL => 'all';
use IO::Handle; #autoflush
use File::Copy; # copy a file (no kidding)
# FH -> autoflush(1);


######################################################
sub formatted_sequence ( @) {

    my $ctr;
	my $sequence = $_[0];
    ( defined $sequence) || die "Error: Undefined sequence in formatted_sequence()";
    $ctr = 50;
    while ( $ctr < length $sequence ) {
        substr ($sequence, $ctr, 0) = "\n";
        $ctr += 51;
    }

    return $sequence;
}

######################################################


defined $ARGV[2] ||
    die "Usage: extr_region_from_msf.pl <msffile> [-q <qry_name>] <from> <to> [ <from> <to>]\n"; 


my $home = `pwd`;
chomp $home;
my $afafile = shift @ARGV ;
(-e $afafile) || die "afa file $afafile not found\n";

my $query = "";
if ( $ARGV[0] eq "-q" ) {
    shift @ARGV;
    $query = shift @ARGV;
}

my $no_regions = @ARGV/2;

my @alignment_from = ();
my @alignment_to = ();
my @query_from = ();
my @query_to = ();
for ( my $ctr=0; $ctr < $no_regions;  $ctr ++) {
    if (! defined $query || $query eq "") {
        $query_from[$ctr] =  $ARGV[2*$ctr] -1;
        $query_to[$ctr]   =  $ARGV[2*$ctr+1] - 1;
    } else {
        $alignment_from[$ctr] =  $ARGV[2*$ctr] -1;
        $alignment_to[$ctr]   =  $ARGV[2*$ctr+1] - 1;
    }
}

open (AFA, "<$afafile" ) ||
    die "Cno: $afafile  $!\n";
	

my @names = ();
my %seqs = ();

my $seq = "";
my $name = "";
while ( <AFA> ) {
    next if ( !/\S/ );
    if ( /^>(.+)/ ) {
        if ($seq ne "") {
			push @names, $name;
			$seqs{$name} = $seq;
		}
        $seq = "";
        $name = $1;
    } else {
        chomp;
        my $line = $_;
        $line =~ s/\s//g;
        $seq .= $line;
    }
}
if ($seq ne "") {
	push @names, $name;
	$seqs{$name} = $seq;
}

close AFA;

if (! defined $query || $query eq "") {
   # we defined the alignment_from and alignment_to on the command line

} else  {
    grep ( $_ eq $query, @names ) ||
	die "$query not found in $afafile.\n";
    # if the query is given, the from and to are
    # understood to refer to query
    my @sequence = split '', $seqs{$query};

    my $query_ctr = -1;
    for (my $ctr=0 ; $ctr<= $#sequence; $ctr++) {
        if ($sequence[$ctr] eq "." ) next;
        $query_ctr ++;
        for (my $region_ctr=0; $region_ctr < $no_regions; $region_ctr++) {
            if ($query_from[$region_ctr] == $query_ctr) {
                $alignemnt_from[$region_ctr] = $ctr;
            }
            if ($query_to[$region_ctr] == $query_ctr) {
                $alignemnt_to[$region_ctr] = $ctr;
            }

        }

    }
    
}
#for ($region_ctr=0; $region_ctr < $no_regions; $region_ctr++) {
#    printf " $region_ctr    $from[$region_ctr]    $to[$region_ctr]\n";
#}
		
#exit;

 while ( <MSF>) {
     last if ( /\/\// );
 }

 my @names = ();
 my %seqs = ();
 my $ctr = 0;
 while ( <MSF>) {
 	next if ( ! (/\w/) );
 	chomp;
 	my @aux = split;
 	my $seq_name = $aux[0];
 	$seq_name =~ s/\s//g;
 	if ( defined $seqs{$seq_name} ){
 		$seqs{$seq_name} .= join ('', @aux[1 .. $#aux]);
 	} else {
 		$seqs{$seq_name}  = join ('', @aux[1 .. $#aux]);
 		push @names, $seq_name;
 		$ctr ++;
 	}
 }

# output to stdout
 print "PileUp\n\n";
 print "            GapWeight: 30\n";
 print "            GapLengthWeight: 1\n\n\n";
 printf ("  MSF: %d  Type: P    Check:  9554   .. \n\n",$seqlen) ;
 for my $name (@names) {
     printf " Name: %-20s   Len: %5d   Check: 9554   Weight: 1.00\n",
 	    $name, length $seqs{$name};
 }
 printf "\n//\n\n\n\n";

 my $seqlen = length $seqs{$names[0]};

 for (my $j=0; $j  < $seqlen; $j += 50) {
 	for my $name ( @names) {
 		printf "%-30s", $name;
 		for (my $k = 0; $k < 5; $k++ ) {
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




