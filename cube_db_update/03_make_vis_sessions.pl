#! /usr/bin/perl -w

sub RunScript;

# check my dependencies
my $pymol   = '/cluster/apps/x86_64/bin/pymol';
my $chimera = '/cluster/apps/x86_64/packages/chimera/bin/chimera';


foreach ($pymol, $chimera){
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

	# cluster level	    
	chdir "$home/$family/$cluster";
	print "\t $cluster\n";

	@members = split "\n", `cat members`;

	foreach $member ( @members ) {
	    print "\t\t $member\n";

	    chdir "$home/$family/$cluster/$member";

	    if ( -e "mammals")  {
		chdir "$home/$family/$cluster/$member/mammals";
		# find scripts
		@scripts = split "\n", `ls *.pml *.com`;
		foreach $script (@scripts) {
		    print `pwd`;
		    print "$script\n\n";
		    RunScript ($script);
		}
	    }

	    chdir "$home/$family/$cluster/$member";
	    if ( -e "all_verts")  {
		chdir "$home/$family/$cluster/$member/all_verts";
		# find scripts
		@scripts = split "\n", `ls *.pml *.com`;
		foreach $script (@scripts) {
		    RunScript ($script);
		}
	
	    }
	}
	

    }


    print "\n";


}

################################################
sub RunScript {
    my ($script) = @_;
    my $viewer;
    
    if ( $script =~ /\.pml$/ ) {
	$viewer = "pymol";
    } elsif ( $script =~ /\.com$/ ) {
	$viewer = "chimera";
    } else {
	die "Unrecognized script type: $script\n";
    }


    if ($viewer eq 'image') {
	my $cmd = "$pymol -qc -u $script > /dev/null";
	(system($cmd) == 0) or return "Error running $cmd: $?";
    }

    #### PYMOL ######
    elsif (($viewer eq 'pymol') || ($viewer eq 'pymolMulti')) {
	my $session = $script;
	(($session =~ s/\.pml$/\.pse/) == 1)
	    or return "couldn't construct session-file name";
	
	# make sure I have the save session command in the script:
	$ret = "" || `grep save $script`;
	$ret || `echo save $session >> $script`;

	my $cmd = "$pymol -qc -u $script > /dev/null";
	(system($cmd) == 0) or return "Error running $cmd: $?";

    }


    #### CHIMERA ######
    elsif (($viewer eq 'chimera') || ($viewer eq 'chimeraMulti')) {
	my $session = $script;
	(($session =~ s/\.com$/\.py/) == 1)
	    or return "couldn't construct session-file name";

	my $cmd = "$chimera --nogui $script > /dev/null";	
	(system($cmd) == 0) or return "Error running $cmd: $?";

	(-e "$script.py") && `mv $script.py $session`; # not clear why this happens

	$cmd = "sed -i \"s/\'showSilhouette\': False/\'showSilhouette\': True/g\" $session";
	(system($cmd) == 0) or return "Error running $cmd: $?";

   }
 
   else {
	return "unrecognized viewer: '$viewer'";
    }
    
    return '';
}

