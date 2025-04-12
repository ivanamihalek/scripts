#! /usr/bin/perl

$mafft      = "/usr/local/bin/mafft-linsi";
$mafft_prof = "/usr/local/bin/mafft-profile";
$tax        = "/home/ivanam/perlscr/fasta_manip/sort_by_taxonomy.pl";
$afa2msf    = "/home/ivanam/perlscr/translation/afa2msf.pl";

foreach ($mafft, $mafft_prof, $tax, $afa2msf) {
    (-e $_) || die " $_ not found\n";
}


@all_clusters = split "\n", `ls -d */cluster*`;
@all_clusters || die "no cluster dir found (?) \n";



$home = `pwd`; chomp $home;



foreach $clust ( @all_clusters) {


    chdir $home;
    chdir $clust;


    @members = split "\n",  `cat members`;
    

    foreach $member (@members) {

        chdir $member;
	print "\n$member:\n";
	print `pwd`;
	@descr_files = split "\n", `ls *descr`;
	foreach $file (@descr_files ) {
	    print "\t $file \n";
	    open (IF, "<$file") || die "Cno $file: $!\n";
	    open (OF, ">tmp") || die "Cno tmp: $!\n";

	    @ux = ();
	    while ( <IF> ) {
		next if (!/\S/);
		chomp;
		$token =  $_;
		$token =~ s/\s//g;
		push @aux, $token;
		if ( $token =~ /^>/ ) {
		    $token =~ s/>//;
		    printf OF "%-20s %-20s %-20s \n", $token, @aux;
		    @aux = ();
		} 
	    }
	    close IF;
	    close OF;
	    `mv tmp $file`;
	}
	chdir "..";
    }
    
}


