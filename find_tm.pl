#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

$MIN_TM_CHAIN_LENGTH =   5;
$MAX_OTHER           =   3;

(defined $ARGV[0]) || die "Usage: find_tmp.pl <single seq fastafile>.\n";
$infile= $ARGV[0];

open ( IF, "<$infile" ) || die "Cno $infile: $!.\n";

sub classify (@);

$end_of_TM_part  = 0; 

# read in the sequence and get rid of the whitespaces
while ( <IF> ) {
    chomp;
    next if (/>/);
    @aux = split;
    $sequence .= join ('', @aux);
}

# turn the input seqeunce into array of letters
@residue = split ('', $sequence);


# find the end of the transmembrane part
$state = "start";
$i = -1;
$hydro = 0;
$chg   = 0;
$other = 0;
$start_pos = 0;
while ( 1 ) {

    $i++;
    if ( $i > $#residue && $state !~ /charged/ &&  $state !~ /stop/) {
	$state = "failure";
	last;
    }


    ##################################################
    if ( $state =~ /start/ ) {

	@charged     = ();
	@hydrophobic = ();
	@other       = ();

	classify ( $residue[$i] ); # hydro, chg or other is set to 1

    ##################################################
    } elsif ( $state =~ /hydrophobic/ ) {
		
	classify ( $residue[$i] ); # hydro, chg or other is set to 1

	if ( !$hydro && @hydrophobic < $MIN_TM_CHAIN_LENGTH ) {
	    $state = "start";
	    $start_pos = $i;
	} 

    ##################################################
    } elsif ($state =~ /other/) {

	classify ( $residue[$i] ); # hydro, chg or other is set to 1
	if ( @other > $MAX_OTHER ) {
	    $state = "start";
	    $start_pos = $i;
	} 

    ##################################################
    } elsif ($state =~ /charged/) {

	classify ( $residue[$i] ); # hydro, chg or other is set to 1
	if (@hydrophobic >=  $MIN_TM_CHAIN_LENGTH  ) {
	    $state = "stop";
	}
    ##################################################
    } elsif ($state =~ /stop/) {
	print "$i: end of the transmembrane part started at $start_pos:   ";
	print "@hydrophobic -- @other --  @charged \n";
	$state = "start";
	$start_pos = $i;
    }

    printf   "pos: %4d      type:%1s     state:%s\n", $i, $residue[$i], $state;
}

print "last state: $state \n";
	



################################################
sub classify (@) {
    $res = $_[0];
    $hydro = 0;
    $chg   = 0;
    $oth = 0;
    if ($res =~/[KRHED]/i ) {
	$chg = 1;
	push @charged, $res;
	$state = "charged";
    } elsif  ($res =~/[SGAVLIMFW]/i ){
	$hydro = 1;
	push @hydrophobic, $res;
	$state = "hydrophobic";
    } else {
	$oth = 1;
	push @other, $res;
	$state = "other";
    }
   
}
