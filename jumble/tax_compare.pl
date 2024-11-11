#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

(defined   $ARGV[0]) && (defined   $ARGV[1]) ||
    die "Usage: tax_compare.pl <taxreport1> <taxreport2>.\n"; 


$gifile1 = "gis1.gi";
$gifile2 = "gis2.gi";

$ginfile1 = "gis1.gi2name";
$ginfile2 = "gis2.gi2name";


%gid1 = ();
%gid2 = ();
$taxreport1 =  $ARGV[0];
$num_spec1 = 0;

open (TR1, "<$taxreport1") ||
    die "Cno $taxreport1: $!.\n"; 

while ( <TR1> ) {
    last if ( /Help/);
}
while ( <TR1> ) {
    last if ( /Organism Report/);
}
while ( <TR1> ) {
    last if ( /Taxonomy Report/);
    next if ( !/\S/);
    if ( /^ gi\|(\d+)\|.*\s+\d+\s+([\d\-e\.]+)/  ) {
	$gi = $1;
	$e = $2;
	print "\t $gi     $e\n";
	if ( ! defined $gid1{$name} ) {
	    $gid1{$name}  = $gi;
	}
	next;
    }
    next if (/\[other sequences\]/);
    next if (/Magnaporthe/);
    $num_spec1 ++;

    $aux = $_;
    $aux =~ s/str\.\s+\w+//i;
    $aux =~ s/var\.//i;
    $aux =~ s/sp\.\s+\w+//i;
    $aux =~ s/([\d\-]+)//g;
    $aux =~ /([\w\s]*)[\(\[]/;

    @spec = split ' ', $1;
    $name = "";
    for $str ( @spec) {
	$name .= uc ( substr ( $str, 0, 3));
    }
    push @specs1, $name;
    print "$name \n";
   

}
close TR1;
print "\n\n\n";

$taxreport2 =  $ARGV[1];
$num_spec2 = 0;

open (TR2, "<$taxreport2") ||
    die "Cno $taxreport2: $!.\n"; 

while ( <TR2> ) {
    last if ( /Help/);
}
while ( <TR2> ) {
    last if ( /Organism Report/);
}
while ( <TR2> ) {
    last if ( /Taxonomy Report/);
    next if ( !/\S/);
    if ( /^ gi\|(\d+)\|.*\s+\d+\s+([\d\-e\.]+)/  ) {
	$gi = $1;
	$e = $2;
	print "\t $gi     $e\n";
	if ( ! defined $gid2{$name} ) {
	    $gid2{$name}  = $gi;
	}
	next;
    }

    next if (/\[other sequences\]/);
    next if (/Magnaporthe/);
    $num_spec2 ++;

    $aux = $_;
    $aux =~ s/str\.\s+\w+//i;
    $aux =~ s/var\.//i;
    $aux =~ s/sp\.\s+\w+//i;
    $aux =~ s/([\d\-]+)//g;
    $aux =~ /([\w\s]*)[\(\[]/;

    @spec = split ' ', $1;
    $name = "";
    for $str ( @spec) {
	$name .= uc ( substr ( $str, 0, 3));
    }
    push @specs2, $name;
    print "$name \n";

}
close TR2;
print "\n\n\n";

print "\n number of spec in $taxreport1: $num_spec1\n";

print "\n number of spec in $taxreport2: $num_spec2\n";

open (GI1, ">$gifile1" ) ||
    die "Cno $gifile1: $! \n";
open (GI2, ">$gifile2" ) ||
    die "Cno $gifile2: $! \n";


open (GIN1, ">$ginfile1" ) ||
    die "Cno $ginfile1: $! \n";
open (GIN2, ">$ginfile2" ) ||
    die "Cno $ginfile2: $! \n";


$intersection = 0;

for $sp1 ( @specs1 ) {
    for $sp2 ( @specs2 ) {
	if ( $sp1 =~ $sp2 && $sp2 =~ $sp1 ) {
	    $intersection ++;
	    print "$intersection  $sp1  $gid1{$sp1} $gid2{$sp2}";
	    print GI1 "$gid1{$sp1}\n";
	    print GI2 "$gid2{$sp1}\n";

	    print GIN1 "$gid1{$sp1}  $sp1\n";
	    print GIN2 "$gid2{$sp2}  $sp2\n";

	    print "\n";
	    
	}
    }
}




print "\n intersection set size: $intersection.\n";
