#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

(defined   $ARGV[0]) ||
    die "Usage: tax_compare.pl <taxreport>.\n"; 
$taxreport1 =  $ARGV[0];

@aux = split '\.', $taxreport1;

$gifile1 = "$aux[0].gi";

$ginfile1 = "$aux[0].gi2name";


%gid1 = ();

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
	$full_name = $gi."_".$name;
	if ( ! defined $gid1{$full_name} ) {
	    $gid1{$full_name}  = $gi;
	    #print " $full_name $gi \n";
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


print "\n number of spec in $taxreport1: $num_spec1\n";


open (GI1, ">$gifile1" ) ||
    die "Cno $gifile1: $! \n";


open (GIN1, ">$ginfile1" ) ||
    die "Cno $ginfile1: $! \n";


$intersection = 0;

for $full_name (keys  %gid1) {

    $gi = $gid1{$full_name};

    print GI1 "$gi\n";

    print GIN1 "$gi $full_name\n";
	    
}



