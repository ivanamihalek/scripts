#! /usr/bin/perl -w

sub make_cmd (@);

# check my dependencies
$mafftprof = "/usr/local/bin/mafft-profile";
$restr     = "/home/ivanam/perlscr/msf_manip/restrict_msf_to_list.pl";
$afa2msf   = "/home/ivanam/perlscr/translation/afa2msf.pl";
$hc        = "/home/ivanam/kode/05_hypercube/hyper_c";

$hc2com    = "/home/ivanam/kode/05_hypercube/09_scripts/hc2chimera.pl";
$hc2pml    = "/home/ivanam/kode/05_hypercube/09_scripts/hc2pml.pl";
$hc2xls    = "/home/ivanam/kode/05_hypercube/09_scripts/hc2xls.pl";


foreach ($mafftprof, $restr, $afa2msf){
    (-e $_) || die "$_ not found\n";
}

# traverse all dirs 
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

	# cluster level	    
	chdir "$home/$family/$cluster";
	print "\t $cluster\n";

	@members = split "\n", `cat members`;

	@almts = ();
	( -e "mamm_groups") && `rm mamm_groups`;
	`touch mamm_groups`;
	foreach $member ( @members ) {
	    print "\t\t $member\n";

	    chdir "$home/$family/$cluster/$member";

	    if ( -e "mammals")  {
		chdir "$home/$family/$cluster/$member/mammals";
		# the alignment from ensembl:
		$afa_from_ens = "ensembl_search/$member.mammals.mafft.afa";
		if ( -e $afa_from_ens && ! -z $afa_from_ens ) {
		    push @almts, "$member/mammals/$afa_from_ens";
		    `echo name $member  >> $home/$family/$cluster/mamm_groups`;
		    `grep \'>\' $afa_from_ens >> $home/$family/$cluster/mamm_groups`
		}
	    }
	}
	
	$no_almts =  @almts;

	# if more than 2 almts, make the profile
	($no_almts > 1) || next;

	chdir "$home/$family/$cluster";

	$next  = shift @almts;
	`cp $next tmp.afa`;
	while ( $next  = shift @almts ) {
	    $cmd = "$mafftprof tmp.afa $next > tmp2.afa";
	    (system $cmd) && die "Error running $cmd\n";
	    `rm pre trace`;
	    `mv tmp2.afa tmp.afa`;
	}
	# add structure

	# add structure if we have one
	$seq = "" || `ls *.seq`;
	if ( $seq) {
	    chomp $seq;
	    $cmd = "$mafftprof $seq tmp.afa  > tmp2.afa";
	    (system $cmd) && die "Error running $cmd\n";
	    `rm pre trace tmp.afa`;

	    $seq =~ s/\.seq//g;

	} else {
	    `mv tmp.afa tmp2.afa`;
	}
	`echo $seq  > tmpn`;

	# to msf
	$cmd = "$afa2msf tmp2.afa > tmp.msf";
	(system $cmd) && die "Error running $cmd\n";
	`rm tmp2.afa`;


	# clean up mamm_groups
	`sed \'s/>//g\'  mamm_groups -i`;


	foreach $member ( @members ) {
	    print "\t\t $member\n";

	    chdir "$home/$family/$cluster/$member";

	    if ( -e "mammals")  {
		chdir "$home/$family/$cluster/$member/mammals";
		# the alignment from ensembl:
		$afa_from_ens = "ensembl_search/$member.mammals.mafft.afa";
		if ( -e $afa_from_ens && ! -z $afa_from_ens ) {
		    
		    `cp $home/$family/$cluster/tmpn .`;
		    `echo HOM_SAP_$member >> tmpn`;

		    # restrict to query and structure (if available)
		    $cmd = "$restr $home/$family/$cluster/tmp.msf tmpn > all_groups.msf";
		    (system $cmd) && die "Error running $cmd\n";
		    `rm tmpn `;

		    # make groups file
		    `cp $home/$family/$cluster/mamm_groups groups`;

		    # make cmd file
		    make_cmd ($seq);

		    # run hyper_c
		    $cmd = "$hc cmd";
		    (system $cmd) && die "Error running $cmd\n";

		    # run hc2xls, hc2pml and hc2chimera
		    $cmd = "$hc2xls  hc.score cons_spec.$member.xls";
		    (system $cmd) && die "Error running $cmd\n";
		    
		    if ($seq) {
			$cmd = "$hc2pml hc.score ../../$seq.pdb cons_spec.$member.pml -g $member";
			(system $cmd) && die "Error running $cmd\n";

			$cmd = "$hc2com    hc.score ../../$seq.pdb cons_det.$member -g $member ";
			(system $cmd) && die "Error running $cmd\n";
			# make pymol session

			# make chimera session
		    }

		    (-e "tmp") && `rm tmp`;
		    (-e "pre") && `rm pre`;
		    (-e "trace") && `rm trace`;

		} else {
		    #warn "\t\t\t $family/$cluster/$member/mammals/$afa_from_ens   not found.\n";

		}

	    } else {
		#warn "\t\t\t $home/$family/$cluster/$member mammals dir not found.\n";
	    }


	}
	

	# cleanup on the cluster level
	chdir "$home/$family/$cluster";
	`rm tmp.msf tmpn mamm_groups`;

    }


    print "\n";


}



sub make_cmd (@) {
    my $seq = shift @_;

    open (OF, ">cmd") || die "Cno cmd: $!\n";
    print OF "
almtname all_groups.msf

groups groups
patch_sim_cutoff  .40
patch_min_length  .40

outname hc
exchangeability
rate_matrix  /home/ivanam/kode/05_hypercube/08_data/tillier.table

";
 
    if ( $seq ) {
    print OF "
pdbname ../../$seq.pdb
struct_n $seq
";
    }

   close OF;
}
