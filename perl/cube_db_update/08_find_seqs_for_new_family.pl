#! /usr/bin/perl -w


# check my dependencies
my $mutual_best_mammals     = '/home/ivanam/perlscr/mutual_best/ensembl_mutual_best.pl';
my $mutual_best_other     = '/home/ivanam/perlscr/mutual_best/ensembl_mutual_best.2.pl';

foreach ($mutual_best_mammals, $mutual_best_other){
    (-e $_) || die "$_ not found\n";
}

# traverse all dirs - wnerever we find a pymol or chimera script,
# we turn it into a session
# we assume we are running this from the data dir

$home = `pwd`; chomp $home;


@dirs = split "\n", `ls`;

foreach $family (@dirs) {

    # main level

    # into family dir
    chdir "$home/$family";
    print "$family: \n";

    @cluster_dirs = split "\n", `ls -d cluster*`;
    foreach $cluster (@cluster_dirs) {
	print "\t $cluster: \n";

	chdir "$home/$family/$cluster";

	@members = split "\n", `cat members`;
	foreach $member ( @members ) {

	    ################
	    chdir "$home/$family/$cluster/$member";
	    print "\t\t $member\n";

	    print "\t\t\t mammals\n";
	    chdir "mammals";
	    $ens = "ensembl_search";
	    (-e $ens) || `mkdir $ens`;
	    chdir $ens;
	    
	    $cmd = "$mutual_best_mammals  ../../$member.fasta Homo_sapiens ".
		" $member.mammals.descr $member.mammals.fasta  $member ";
	    (system $cmd) && die "Error running $cmd\n in ".`pwd`. "\n";
	    
	    ################
	    chdir "$home/$family/$cluster/$member";
	    print "\t\t\t all_verts\n";

	    chdir "all_verts";
	    $ens = "ensembl_search";
	    (-e $ens) || `mkdir $ens`;
	    chdir $ens;
	    # need to add other species in case the first one fails
	    $cmd = "$mutual_best_other  ../../$member.fasta Danio_rerio ".
		" $member.other_verts.descr $member.other_verts.fasta  $member ";
	    (system $cmd) && die "Error running $cmd\n in ".`pwd`. "\n";
	    
	}
    }
}


########################## from here on,
########### we can go to  01_mammalian_analysis.pl &  02_all_verts.pl
########### but then I need to find PDBs before moving to  03_make_vis_sessions.pl
