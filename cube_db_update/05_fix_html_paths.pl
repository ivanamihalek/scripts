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


=pod
    @lines = split "\n", `cat index.html`;
    open (NEW, ">tmp.html") || die "Cno tmp.html: $!.\n";
    foreach  $line (@lines) {
	if ($line =~ /stylesheet/ ) {
	    $line = 
		"<link rel=\"stylesheet\" media=\"screen\" type=\"text/css\" ".
		"href=\"http:\/\/epsf\.bmad\.bii\.a\-star\.edu\.sg\/cube\/db\/html\/style.css\" />";
	} else {

	    if ($line =~ /http:\/\/epsf\.bmad\.bii\.a\-star\.edu\.sg\/cube/ ) {
		if ( $line =~ /cluster/ ) {
		    $line =~ s/db_analysis/db\/data/ ;	  
		} else {
		    $line =~ s/db_analysis/db\/html/;
		}
	    }
	} 
	print NEW $line , "\n";
    
    }

    close NEW;
    
    `mv tmp.html index.html`;
=cut 


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

	
	@lines = split "\n", `cat display.html`;
	open (NEW, ">tmp.html") || die "Cno tmp.html: $!.\n";
	foreach  $line (@lines) {
	    if ($line =~ /stylesheet/ ) {
		$line = 
		    "<link rel=\"stylesheet\" media=\"screen\" type=\"text/css\" ".
		    "href=\"http:\/\/epsf\.bmad\.bii\.a\-star\.edu\.sg\/cube\/db\/html\/style.css\" />";

	    } elsif ($line =~ /http:\/\/epsf\.bmad\.bii\.a\-star\.edu\.sg\/cube/ ) {
		if ( $line =~ /cluster/ ) {
		    $line =~ s/db_analysis/db\/data/ ;	  
		} else {
		    $line =~ s/db_analysis/db\/html/;
		}

	    } elsif ($line =~ /cgi\-bin\/struct_server/ ) {
	       $line =~ s/cgi\-bin\/struct_server/cgi\-bin\/cube\-db/;
	       if ($line =~ /download/ ) {
		   $line =~ s/\/home\/zhangzh\/www\/testweb/\/var\/www\/dept\/bmad\/htdocs\/projects\/EPSF\/www\/cube\/db\/data/;

	       }
	   } elsif ($line =~ /colorlegend/) {
	       $line =~ s/Image/cube\/db\/html\/images/;

	   } elsif ($line =~ /jmol/) {
	       $line =~ s/struct_server\/jmol/cube\/db\/jmol/;
	       $line =~ s/scube\-db/cube\/db/;

	   }
	    print NEW $line , "\n";
	}
    
	close NEW;
    
	`mv tmp.html display.html`;
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

