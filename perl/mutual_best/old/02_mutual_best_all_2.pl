#! /usr/bin/perl

sub write_to_readme ( @_ );

$ensembl_mut_best = "/home/ivanam/perlscr/database/ensembl_mutual_best.2.pl";

foreach ($ensembl_mut_best) {
    (-e $_) || die " $_ not found\n";
}


@all_clusters = split "\n", `ls -d */cluster*`;
@all_clusters || die "no cluster dir found (?) \n";


open (LOG, ">mutual_best.other_verts.log") ||
    die "Cno mutual_best.other_verts.log: $!\n";

$home = `pwd`; chomp $home;

foreach $clust ( @all_clusters) {

    chdir $home;
    chdir $clust;
    ( -e "mutual_best") || `mv seq_for_pdb mutual_best`;
    chdir "mutual_best";
    @aux = split "\n",  `ls *.seq`;
    @members = grep { s/.seq//g } @aux;

    %gene_name = ();

    foreach $member (@members) {

	#(  -e "$member.other_verts.fasta" && ! -z "$member.other_verts.fasta")  && next;
	# print `pwd`, " -- fixing $member.other_verts.fasta\n";

	print `pwd`;

	foreach $template_specie ( "Gallus_gallus", "Danio_rerio" ) {
	    
	    $cmd = "$ensembl_mut_best  $member.seq $template_specie ".
		" $member.other_verts.descr $member.other_verts.fasta $member";
	    print "$cmd\n";
	    $ret = system $cmd;
	    if ( ! $ret ) {
		@aux = split " ",  `grep gene ensembl_$member.2.log`;
		$gene_name{$member} = pop @aux;
		last;
	    } elsif ( $ret == 1) {
		print LOG "$cmd failed:\n  $member.seq not found in H. sapiens genome (?)\n";
		last;
	    } elsif ($ret == 2) {
		print LOG "$cmd failed:\n  no mutal best hit found in  $template_specie\n";
		next;
	    }
	}
	( $ret ) && write_to_readme "warning (non-mammalian vertebrates): no orthologue found for $member\n";

    }

    # still need to check that each memeber had a different orthologue:
    %member_per_orthologue = ();
    foreach  $member (@members) {
	(defined $member_per_orthologue{$gene_name{$member}} ) 
	    ||   ( @{ $member_per_orthologue{$gene_name{$member}} } = ());
	push @{ $member_per_orthologue{$gene_name{$member}} }, $member;
    }
    
    foreach ( keys %member_per_orthologue ) {

	( @{$member_per_orthologue{$_}} <= 1)  && next;

	write_to_readme "warning (non-mammalian vertebrates): $_ returned as mutual best hit for ".
	    "  @{$member_per_orthologue{$_}}\n";
    }

}


close LOG;

#########################################
sub write_to_readme ( @_ ) {
    my $msg = $_[0];
    (-e "README") || `touch README`;
    ( open README, ">>README" ) || return;
    print README $msg;
    close README;
    return;
}
