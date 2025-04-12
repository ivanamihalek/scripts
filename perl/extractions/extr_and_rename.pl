#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

 
(@ARGV == 2)  ||
    die "Usage: extr_and_reorder_seqs_from_msf.pl <name_list> <msf_file>.\n"; 
$list = $ARGV[0]; 
$msf =  $ARGV[1]; 
open ( LIST, "<$list") ||
    die "Cno $list: $!\n";


@names = ();
while ( <LIST>) {
    if ( /\w/ ) {
	chomp;
	($old_name, $new_name) = split;
	push @names, $old_name;
	$new{$old_name} = $new_name;
    } 
}
close LIST;


foreach $name ( @names) {
    $line{$name} = "";
}  


open ( MSF, "<$msf") ||
    die "Cno $msf: $!\n";

# header
while ( <MSF> ) {
    last if ( /Name/);
    print;
}


do {
    if ( /\w/ ) {
	@aux = split;
	if ( /Name/ ) {
	    $name0 = $aux[1];
	} else {
	    $name0 = $aux[0];
	}
	foreach $name ( @names) {
	    if ( $name0 eq  $name ) {
		$line{$name} .= $_;
		last;
	    }
	}
    } 
} while ( <MSF>);

foreach $name ( @names) {
    $line{$name} =~ s/$name/$new{$name}/g;
}

$ctr=0;
TOP: while ( 1  ) {
    foreach $name ( @names) {
	next if ( ! defined $line{$name} || !  $line{$name});
	@aux = split '\n',$line{$name};
	if ( ! defined $aux[$ctr]) {
	    last TOP;
	}
	print "$aux[$ctr]\n";
	if ($aux[$ctr]=~ "Name") {
	    $names_block = 1;
	} else {
	    $names_block = 0;
	}
    } 
    print "\n";
    if ($names_block) {
	print "//\n\n\n\n";
    }
   $ctr++;
} 
