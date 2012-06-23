#!/usr/bin/perl -w

open ( IF, "<names" ) || die "Cno names: $!.\n";


$dir = "/home/ivanam/projects/colabs/Vivek/mirna/peedrim/illumina_tmp";
@tmp = <IF>;

@names = grep ( chomp, @tmp );

foreach $name ( @names) {
    print $name, "\n";
    $ret = `cat $name/$name.names`;

    @piece_names = split "\n", $ret;
    foreach $pn ( @piece_names ) {
	print "\t $pn\n";
	$cmd = "awk \'\$2==\"$pn\"\' $name.tmp > $dir/$pn.megablast.out";
	print $cmd, "\n";
	(system $cmd) && die "error runing $cmd\n";
    }
    
}
