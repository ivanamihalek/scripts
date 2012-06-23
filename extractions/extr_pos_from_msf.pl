#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

 
defined $ARGV[0] &&  defined $ARGV[1] ||
    die "Usage: extr_pos_from_msf.pl <pos_list> <msf_file> [-col].\n"; 

$list = $ARGV[0]; 
$msf =  $ARGV[1]; 
$fasta = "";
if ( defined $ARGV[2]  && ! ($ARGV[2] eq "-col")  ) {
    $fasta =  $ARGV[2] ;
} 


	$SMALL = "AVGSTC";
	$MEDIUM = "LPNQDEMIK";
	$JUMBO = "WFYHR";
	$HYDROPHOBIC = "LPAVMWFI";
	$POLAR = "GATCY";
	$NEGATIVE = "DE";
	$POSITIVE = "KHR";
	$AROMATIC = "WFYH";
	$LONG_CHAIN = "EKRQM";
	$OH = "SDETY";
	$NH2 = "NQRK";



open ( LIST, "<$list") ||
    die "Cno $list: $!\n";

$colmws_output = 0;
if ( $ARGV[$#ARGV] eq "-col" ) {
    $colmws_output = 1;
}

@names = ();
while ( <LIST>) {
    if ( /\w/ ) {
	chomp;
	@aux = split;
	 #s/\s//g; get rid of the whitespace
	push @pos, $aux[0]; 
    }
}
close LIST;
open ( MSF, "<$msf" ) ||
    die "Cno: $msf  $!\n";
	
@names = ();

while ( <MSF>) {
    if (/Name/ ) {
	@aux = split;
	push @names, $aux[1];
    }
    last if ( /\/\// );
}
while ( <MSF>) {
    next if ( ! (/\w/) );
    chomp;
    @aux = split;
    $seq_name = $aux[0];
    if ( defined $seqs{$seq_name} ){
	$seqs{$seq_name} .= join ('', @aux[1 .. $#aux]);
    } else { 
	$seqs{$seq_name}  = join ('', @aux[1 .. $#aux]);
    }
}

close MSF;

if ( $colmws_output) {

    printf "%4s ", " ";
    $ctr = 0;
    foreach $name ( @names) {
	$ctr++;
	printf "%3d" ,  $ctr;
    }
	print "   ";
    printf "%4s", "sml";
    printf "%4s",	"med";
    printf "%4s",	"jmb";
    printf "%4s",	"hyd";
    printf "%4s",	"pol";
    printf "%4s",	"neg";
    printf "%4s",	"pos";
    printf "%4s",	"aro";
    printf "%4s",	"lng";
    printf "%4s",	"oh ";
    printf "%4s",	"nh2";
    print "\n";
    foreach $i ( @pos) { 
	printf "%4d ", $i;
	$small = 0;
	$medium = 0;
	$jumbo = 0;
	$hydrophobic = 0;
	$polar = 0;
	$negative = 0;
	$positive = 0;
	$aromatic = 0;
	$long_chain = 0;
	$oh = 0;
	$nh2 = 0;
	
	foreach $name ( @names) {
	    $val =  substr $seqs{$name}, $i-1, 1;
	    process_val ();
	    printf "  %s" ,  $val;
	}
	print "   ";
	printf "%4d", $small;
	printf "%4d",$medium;
	printf "%4d",	$jumbo;
	printf "%4d",	$hydrophobic;
	printf "%4d",$polar;
	printf "%4d",$negative;
	printf "%4d",	$positive;
	printf "%4d",	$aromatic;
	printf "%4d",	$long_chain;
	printf "%4d",	$oh;
	printf "%4d",	$nh2;
	print "\n";

	print "\n";
    }
    
    print "\n\n";
    $ctr = 0;
    foreach $name ( @names) {
	$ctr++;
	printf "%3d   $name \n" ,  $ctr;
    }
    
} else {

    foreach $name ( @names) {

	$allvals = "";
	printf "%-30s ", $name;
	foreach $i ( @pos) { 
	    $val =  substr $seqs{$name}, $i-1, 1;
	    printf "  %s" ,  $val;
	    $allvals .= $val;
	}
	print "\n";
	$subset{$name} = $allvals;
	if ( defined $pop{$allvals} ) {
	    $pop{$allvals} ++;
	} else {
	    $pop{$allvals} = 1;
	}
    }
}

print "\n";
=pod
foreach $key (keys (%pop )) {
    printf "%-4s %10d \n", $key, $pop{$key};
}
=cut

 if ( $fasta ) {
     open ( FASTA, ">$fasta" ) ||
	 die "Cno $fasta:$!.\n";
     foreach $name ( @names) {
	 print FASTA "> $name\n";
	 @seq = split ('', $subset{$name});
	 $ctr = 0;
	 for $i ( 0 .. $#seq ) {
	     print FASTA  $seq[$i];
	     $ctr++;
	     if ( ! ($ctr % 100) ) {
		 print FASTA "\n";
	     }
	     
	   
	 }
	 print FASTA "\n";
    }

     close FASTA;
 
     
 }


###############################################

sub process_val () {
    if ( $SMALL  =~ $val ) {
	$small ++;
    }
    if ( $MEDIUM =~ $val ) {
	$medium ++;
    }
    if ( $JUMBO =~ $val ) {
	$jumbo ++;
    }
    if (  $HYDROPHOBIC =~ $val ) {
	$hydrophobic ++;
    }
    if ( $POLAR =~ $val ) {
	$polar ++;
    }
    if ( $NEGATIVE =~ $val ) {
	$negative ++;
    }
    if ( $POSITIVE =~ $val ) {
	$positive ++;
    }
    if ( $AROMATIC =~ $val ) {
	$aromatic ++;
    }
    if ( $LONG_CHAIN =~ $val ) {
	$long_chain ++;
    }
    if ( $OH =~ $val ) {
	$oh ++;
    }
    if ( $NH2 =~ $val ) {
	$nh2 ++;
    }

}
