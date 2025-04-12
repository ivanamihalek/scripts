#! /usr/gnu/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);
defined $ARGV[0]  ||
    die "Usage: multiple_profile.pl <name_list>\n"; 

open ( NAMES, "<$ARGV[0]" ) ||
    die "Cno $ARGV[0]: $!\n";

$clustalw = "/home/protean2/LSETtools/bin/linux/clustalw";
$extr = "/home/protean5/imihalek/perlscr/extr_names_from_msf.pl";
$extr_seq = "/home/protean5/imihalek/perlscr/extr_seqs_from_msf.pl";
@names = ();
while ( <NAMES> ) {
    chomp;
    @aux = split;
    push @names, $aux[0];
}
close NAMES;

$home = `pwd`;
chomp $home;
$previous = $names[0];
$next = "tmp1";
foreach $name ( @names[1..$#names] ) {
    $msfname= $name;
    print "$msfname: \n";
    @names_previous = split '\n', `$extr $previous`;
    @names_new  = split '\n', `$extr $msfname`;
    @names_uniq = ();
    $duplicates = 0;
    foreach $seq_name ( @names_new ) {
	$duplicate = 0;
	foreach $seq_name_old ( @names_previous ) {
	    if ( $seq_name =~ $seq_name_old ) {
		print "\t duplicate: $seq_name\n";
		$duplicate ++;
	    } 
	} 
	if ( ! $duplicate ) {
	    push @names_uniq, $seq_name;
	} else {
	    $duplicates++;
	}
    }
    $new = $msfname;
    if ( $duplicates ) {
	open ( TMP, ">tmp" )  || 
	    die "Cno tmp: $! \n";
	foreach $seq_name ( @names_uniq ) {
	    print TMP "$seq_name\n";
	}
	close TMP;
        $new = $msfname.".uniq"; 
	if ( -e "new" ) {
	    unlink "new";
	} 
	`$extr_seq tmp $msfname > $new`;
    }
    $cmdline = "$clustalw -profile1=$previous -profile2=$new -quicktree -outfile=$next -output=gcg ";
    #$cmdline .= "-gapopen=5.0 -gapext=0.025 ";
    print "$cmdline \n";
    $retval   = `$cmdline`;
    if ( $retval =~ /error/i ) { 
	printf "\nClustalw failure.\n\n";
	exit;
    }
    if ( -e "tmp" ) {
	unlink "tmp";
    } 
    $previous = $next;
    if ( $next =~ /1/ ) {
	$next = "tmp2";
    } else  {
	$next = "tmp1";
    }
}

printf "final: $previous \n";
