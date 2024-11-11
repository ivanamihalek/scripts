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
    die "Usage: extr_region_from_afa.pl <afa file> [-q <qry_name>] <from> <to> [ <from> <to>]\n";


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
    if (defined $query && $query ne "") {
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
    for (my $alignment_ctr=0 ; $alignment_ctr<= $#sequence; $alignment_ctr++) {
        ($sequence[$alignment_ctr] eq "-" ) && next;
        $query_ctr ++;
        for (my $region_ctr=0; $region_ctr < $no_regions; $region_ctr++) {
            if ($query_from[$region_ctr] == $query_ctr) {
                $alignment_from[$region_ctr] = $alignment_ctr;
            }
            if ($query_to[$region_ctr] == $query_ctr) {
                $alignment_to[$region_ctr] = $alignment_ctr;
            }
        }
    }
}

#
#for (my $region_ctr=0; $region_ctr < $no_regions; $region_ctr++) {
#    printf " $region_ctr    $alignment_from[$region_ctr]    $alignment_to[$region_ctr]\n";
#}
#
#exit;

foreach $name ( @names ) {
    my $old_seq = $seqs{$name};
    $seqs{$name} = "";
    my $seqlen = 0;
    for (my $region_ctr=0; $region_ctr < $no_regions; $region_ctr++) {
        my $seqlen2 = $alignment_to[$region_ctr] - $alignment_from[$region_ctr] +1;
        $seqs{$name} .= substr ( $old_seq, $alignment_from[$region_ctr], $seqlen2);
        $seqlen      += $seqlen2;
   }
}

for  $name (@names) {
    print ">$name\n";
    print formatted_sequence( $seqs{$name} );
    print "\n";
}

