#! /usr/bin/perl

sub write_to_readme ( @_ );

$mafft      = "/usr/local/bin/mafft-linsi";
$mafft_prof = "/usr/local/bin/mafft-profile";
$tax        = "/home/ivanam/perlscr/fasta_manip/sort_by_taxonomy.pl";
$afa2msf    = "/home/ivanam/perlscr/translation/afa2msf.pl";

foreach ($mafft, $mafft_prof, $tax, $afa2msf) {
    (-e $_) || die " $_ not found\n";
}


@all_clusters = split "\n", `ls -d */cluster*`;
@all_clusters || die "no cluster dir found (?) \n";


#@all_clusters = ("LALB/cluster_1");


$home = `pwd`; chomp $home;



foreach $clust ( @all_clusters) {


    chdir $home;
    chdir $clust;

    @aux = split "\/", $clust;
    $prot_fam = shift @aux;
    $cluster  = shift @aux;


    @members = split "\n",  `cat members`;
    
    (-e "groups") && `rm groups`;
    `touch groups`;

    $first = 1;

    $overall_afa = "$prot_fam\_$cluster.afa";
    $overall_msf = "$prot_fam\_$cluster.msf";

    print "====  $prot_fam  $overall_afa  $overall_msf \n";

    #$need_almt =  ( ! -e $overall_msf || -z  $overall_msf);

    #$need_almt || next;

    # either all members of the cluster have clear
    # orthology relationship in non-mammalian vertebrate,
    # or we won't be using those sequences at all
    $all_members_have_other_verts = 1;
    foreach $member (@members) {
	next if (-e "$member/$member.other_verts.fasta" && 
	 ! -z "$member/$member.other_verts.fasta");
	 $all_members_have_other_verts = 0;
	write_to_readme "$member: no clear orthologues in non-mammals.\n"; 
    }


    foreach $member (@members) {

        chdir $member;
	print "\n$member:\n";
	print `pwd`;

	#if (! -e "$member.all.fasta") {

	    if ( $all_members_have_other_verts ) {
		`cat $member.mammals.fasta $member.other_verts.fasta > temp`;
	    } else {
		`cp $member.mammals.fasta temp`;
	    }
	    `$tax temp > $member.all.fasta`;
	    `rm temp`;
	#}

	
	$ret = `grep \'>\' $member.all.fasta | wc -l`;
	chomp $ret;
	print " ***  $ret *** \n";
	if ($ret <=1) {
	    chdir "..";
	    write_to_readme "$member: no orthologues found (?).\n"; 
 	    next;
	}


	$cmd = "$mafft --quiet $member.all.fasta > $member.all.afa";
	(system $cmd) &&
	    die "Error running $cmd\n";
	

	`echo name $member >> ../groups`;
	`grep \'>\' $member.all.fasta | sed \'s/>//g\' >> ../groups`;

	if ($first) {
	    $first = 0;
	    (-e "../temp_out.afa") && 'rm -rf ../temp_out.afa';
	    (-e "../temp.afa") && 'rm -rf ../temp.afa';
	    `cp $member.all.afa ../temp_out.afa`;
	} else {
	    `mv  ../temp_out.afa ../temp.afa`;
	    $cmd = "$mafft_prof ../temp.afa $member.all.afa > ../temp_out.afa";
	    (system $cmd) && die "Error running $cmd\n";
	}
	chdir "..";
    }
    
    `rm temp.afa`;
    `mv temp_out.afa $overall_afa`;
    $cmd = "$afa2msf $overall_afa > $overall_msf";
    (system $cmd) &&
	    die "Error running $cmd\n";
    

    open (CMD, ">cmd") || die "Cno cmd: $!\n";
    print CMD "almtname  $overall_msf\n";
    print CMD "groups groups \n";
    print CMD "patch_sim_cutoff  .40\n";
    print CMD "patch_min_length  .40\n";
    print CMD "outname  $prot_fam\_$clust\n";
    print CMD "exchangeability\n";
    print CMD "rate_matrix /home/ivanam/kode/05_hypercube/08_data/tillier.table\n";
    close CMD;

}


#########################################
sub write_to_readme ( @_ ) {
    my $msg = $_[0];
    (-e "README") || `touch README`;
    ( open README, ">>README" ) || return;
    print README $msg;
    close README;
    return;
}
