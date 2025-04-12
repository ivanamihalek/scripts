#! /usr/bin/perl


$ensembl_mut_best = "/home/ivanam/perlscr/database/ensembl_mutual_best.pl";

foreach ($ensembl_mut_best) {
    (-e $_) || die " $_ not found\n";
}


@all_clusters = split "\n", `ls -d */cluster*`;
@all_clusters || die "no cluster dir found (?) \n";


open (LOG, ">mutual_best.log") ||
    die "Cno mutual_best.log: $!\n";

$home = `pwd`; chomp $home;

foreach $clust ( @all_clusters) {

    chdir $home;
    chdir $clust;
    ( -e "mutual_best") || `mv seq_for_pdb mutual_best`;
    chdir "mutual_best";
    @aux = split "\n",  `ls *.seq`;
    @members = grep { s/.seq//g } @aux;

    print "\n";
    print `pwd`;
    foreach $member (@members) {

	(  -e "$member.fasta" && ! -z "$member.fasta")  && next;

	$cmd = "$ensembl_mut_best  $member.seq Homo_sapiens".
	    " $member.descr $member.fasta $member";
	print "$cmd\n";
	(system $cmd)  
	    && print LOG "$cmd failed for $clust, $member\n";

    }
}


close LOG;
