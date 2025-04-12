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


    @cluster_dirs = split "\n", `ls -d cluster*`;
    foreach $cluster (@cluster_dirs) {

	# cluster level	    
	chdir "$home/$family/$cluster";
	print "\t $cluster\n";

	
	@lines = split "\n", `cat downloads.html`;
	open (NEW, ">tmp.html") || die "Cno tmp.html: $!.\n";

	foreach  $line (@lines) {
	    $line =~ s/\/var\/www\/dept\/bmad\/htdocs\/projects\/EPSF\/www\/cube\/db\/downloadables\///g; 
	    print NEW $line , "\n";
	}
    
	close NEW;
    
	`mv tmp.html downloads.html`;
    }

=pod

    $seq = `ls *.pdb`;
    if ($seq ) {
    }


    @members = split "\n", `cat members`;

    foreach $member ( @members ) {
	print "\t\t $member\n";

	chdir "$home/$family/$cluster/$member";

	if ( -e "mammals")  {
	    chdir "$home/$family/$cluster/$member/mammals";
	}

	chdir "$home/$family/$cluster/$member";
	if ( -e "all_verts")  {
	    chdir "$home/$family/$cluster/$member/all_verts";

	}
    }
=cut
    print "\n";


}

