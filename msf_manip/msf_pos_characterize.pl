#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

 
defined $ARGV[0] &&  defined $ARGV[1] ||
    die "Usage: msf_pos_charcterize.pl <pos_list> <msf_file> .\n"; 

$list = $ARGV[0]; 
$msf =  $ARGV[1]; 
$fasta = "";
if ( defined $ARGV[2]  && ! ($ARGV[2] eq "-col")  ) {
    $fasta =  $ARGV[2] ;
} 
          
$ALL_AA = "ACDEFGHIKLMNPQRSTVWY";

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


    printf "%4s ", " ";
	print "   ";

    printf "%6s", "sml";
    printf "%6s",	"med";
    printf "%6s",	"jmb";
	print "   ";
    printf "%6s",	"hyd";
    printf "%6s",	"pol";
    printf "%6s",	"neg";
    printf "%6s",	"pos";
	print "   ";
    printf "%6s",	"aro";
    printf "%6s",	"lng";
    printf "%6s",	"oh ";
    printf "%6s",	"nh2";
    print "\n";
     $num_pos = $#names+1;
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
	$coutn = 0;
	foreach $name ( @names) {
	    $val =  substr $seqs{$name}, $i-1, 1;
	    process_val ();
	}
	norm_and_count();
	$alwd_replacemet = $ALL_AA;
	alwd_replacemet_size();
	print "   ";
	printf "%6.2f", $small;
	printf "%6.2f", $medium;
	printf "%6.2f",	$jumbo;
	print "   ";
	printf "%6.2f",	$hydrophobic;
	printf "%6.2f",$polar;
	printf "%6.2f",$negative;
	printf "%6.2f",	$positive;
	print "   ";
	printf "%6.2f",	$aromatic;
	printf "%6.2f",	$long_chain;
	printf "%6.2f",	$oh;
	printf "%6.2f",	$nh2;

	print "   ";
	printf "%6d", $count;
	if ( length  $complement ) {
	    printf "%20s", $complement;
	} else {
	    printf "%20s", " - ";
	}
	printf "%6d", length  $complement;
	print "\n";

   }
    
    print "\n\n";
    $ctr = 0;
    foreach $name ( @names) {
	$ctr++;
	printf "%3d   $name \n" ,  $ctr;
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

###############################################

sub norm_and_count() {
    
    
    $small/=$num_pos;
    $medium/=$num_pos;
    $jumbo/=$num_pos;
    $hydrophobic/=$num_pos;
    $polar/=$num_pos;
    $negative/=$num_pos;
    $positive/=$num_pos;
    $aromatic/=$num_pos;
    $long_chain/=$num_pos;
    $oh/=$num_pos;
    $nh2  /= $num_pos;

    $count = 0;
    ( $small < 0.1 ) && ( $count ++);
    ( $medium < 0.1 ) && ( $count ++);
    ( $jumbo < 0.1 ) && ( $count ++);
    ( $hydrophobic < 0.1 ) && ( $count ++);
    ( $polar < 0.1 ) && ( $count ++);
    ( $negative < 0.1 ) && ( $count ++);
    ( $positive < 0.1 ) && ( $count ++);
    ( $aromatic < 0.1 ) && ( $count ++);
    ( $long_chain < 0.1 ) && ( $count ++);
    ( $oh < 0.1 ) && ( $count ++);
    ( $nh2  < 0.1 ) && ( $count ++);

}



###############################################

sub alwd_replacemet_size () {
    
    $alwd_replacemet = $ALL_AA;

     ( $small < 0.1 ) && ( $alwd_replacemet =~ s/[AVGSTC]//g );
    ( $medium < 0.1 ) && ( $alwd_replacemet =~ s/[LPNQDEMIK]//g );
    ( $jumbo < 0.1 ) && ( $alwd_replacemet =~ s/[WFYHR]//g );
    ( $hydrophobic < 0.1 ) && ( $alwd_replacemet =~ s/[LPAVMWFI]//g );
    ( $polar < 0.1 ) && ( $alwd_replacemet =~ s/[GATCY]//g );
    ( $negative < 0.1 ) && ( $alwd_replacemet =~ s/[DE]//g );
    ( $positive < 0.1 ) && ( $alwd_replacemet =~ s/[KHR]//g );
    ( $aromatic < 0.1 ) && ( $alwd_replacemet =~ s/[WFYH]//g );
    ( $long_chain < 0.1 ) && ( $alwd_replacemet =~ s/[EKRQM]//g );
    ( $oh < 0.1 ) && ( $alwd_replacemet =~ s/[SDETY]//g );
    ( $nh2  < 0.1 ) && ( $alwd_replacemet =~ s/[NQRK]//g );
   
    $complement = $ALL_AA;
    $complement =~ s/[$alwd_replacemet]//g;
}
