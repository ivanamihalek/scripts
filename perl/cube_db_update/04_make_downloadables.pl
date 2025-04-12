#! /usr/bin/perl -w


# check my dependencies
my $zip     = '/usr/bin/zip';

foreach ($zip){
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

    $downl_dir = "$home/$family";
    $downl_dir =~ s/data/downloadables/;
    ( -e $downl_dir) || `mkdir $downl_dir`;

    @cluster_dirs = split "\n", `ls -d cluster*`;
    foreach $cluster (@cluster_dirs) {

	$cluster_downl_dir =  "$downl_dir/$cluster";
	( -e $cluster_downl_dir) || `mkdir $cluster_downl_dir`;


	# cluster level	    
	chdir "$home/$family/$cluster";
	print "\t $cluster\n";

	
	
	$oldname = "$family\_$cluster.zip";
	(-e $oldname ) && `rm $oldname`;

	$oldname = "$family\_$cluster.patchlog";
	(-e $oldname ) && `rm $oldname`;

	$oldname = "overall_almt.afa.zip";
	(-e $oldname ) && `rm $oldname`;

	$oldname = "cons_det.xls";
	(-e $oldname ) && `mv $oldname cons_spec.overall.xls`;

	$seq = `ls *.pdb`;
	if ($seq ) {
	    $oldname = "hc_cons.py.zip";
	    if ( -e $oldname ) {
		`unzip $oldname`;
		`mv  hc_cons.py cons.overall.py `;
		`rm $oldname`;
	    }
	

	    $oldname = "hc_spec.py.zip";
	    if ( -e $oldname ) {
		`unzip $oldname`;
		`mv  hc_spec.py spec.overall.py `;
		`rm $oldname`;
	    }

	    $oldname = "hc.pse.zip";
	    if ( -e $oldname ) {
		`unzip $oldname`;
		`mv  hc.pse  cons_spec.overall.pse `;
		`rm $oldname`;
	    }
	}


	#zip and move to $downl_dir
	foreach ( "overall_almt.afa",  "cons_spec.overall.xls",  "cons_spec.overall.pse", 
		  "cons.overall.py", "spec.overall.py") {
	    (-e "$cluster_downl_dir/$_.zip") && next;
	    ( ! -e $_) && next;
	    `zip -j $_.zip $_`;
	    `mv $_.zip $cluster_downl_dir`;
	}

	@members = split "\n", `cat members`;

	foreach $member ( @members ) {
	    print "\t\t $member\n";

	    chdir "$home/$family/$cluster/$member";

	    if ( -e "mammals")  {
		chdir "$home/$family/$cluster/$member/mammals";
		( -e "cons_det.$member\_cons.py" ) && 
		    `mv    cons_det.$member\_cons.py   mammals.$member.cons.py`;
		( -e "cons_det.$member\_spec.py" ) && 
		    `mv   cons_det.$member\_spec.py   mammals.$member.spec.py`;
		( -e "cons_spec.$member.pse" ) 
		    && `mv cons_spec.$member.pse mammals.$member.cons_spec.pse  `;

		( -e "cons_spec.$member.xls" ) 
		    && `mv cons_spec.$member.xls mammals.$member.cons_spec.xls  `;

		foreach ("mammals.$member.cons.py", 
			 "mammals.$member.spec.py", 
			 "mammals.$member.cons_spec.pse", 
			 "mammals.$member.cons_spec.xls") {

		    (-e "$cluster_downl_dir/$_.zip") && next;
		    ( ! -e $_) && next;
		    `zip -j $_.zip $_`;
		    `mv $_.zip $cluster_downl_dir`;
		}	

	    }

	    chdir "$home/$family/$cluster/$member";
	    if ( -e "all_verts")  {
		chdir "$home/$family/$cluster/$member/all_verts";
		( -e "cons_det.$member\_cons.py" ) && 
		    `mv    cons_det.$member\_cons.py   all_verts.$member.cons.py`;
		( -e "cons_det.$member\_spec.py" ) && 
		    `mv   cons_det.$member\_spec.py   all_verts.$member.spec.py`;
		( -e "cons_spec.$member.pse" ) 
		    && `mv cons_spec.$member.pse all_verts.$member.cons_spec.pse  `;

		( -e "cons_spec.$member.xls" ) 
		    && `mv cons_spec.$member.xls all_verts.$member.cons_spec.xls  `;


		foreach ("all_verts.$member.cons.py", 
			 "all_verts.$member.spec.py", 
			 "all_verts.$member.cons_spec.pse",
			 "all_verts.$member.cons_spec.xls") {

		    (-e "$cluster_downl_dir/$_.zip") && next;
		    ( ! -e $_) && next;
		    `zip -j $_.zip $_`;
		    `mv $_.zip $cluster_downl_dir`;
		}	


	    }
	}

	# make DIR_STRUCTURE, zip everything, and move to #downl_dir
	chdir "$home/$family/";

	$dirzip =  "$family\_$cluster.zip";
	#if (! -e "$cluster_downl_dir/$dirzip") {
	    `zip -r $dirzip $cluster`;
	    `mv $dirzip $cluster_downl_dir`;
	#}
	
    }


    print "\n";


}

