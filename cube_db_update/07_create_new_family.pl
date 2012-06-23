#! /usr/bin/perl -w

sub make_dist_table (@);
sub get_seqs (@);
sub process_cluster (@);

(@ARGV >=2) || 
    die "Usage: $0  <family name>  <fasta file>\n";

($family, $fasta) = @ARGV;

# check my dependencies
$mafft    = "/usr/local/bin/mafft";
$afa2msf  = "/home/ivanam/perlscr/translation/afa2msf.pl";
$seqstats = "/home/ivanam/perlscr/two_seq_analysis.pl";
$clust    = "/home/ivanam/c-utils/cluster/genclust";

foreach ($mafft, $afa2msf, $seqstats, $clust, $fasta){
    (-e $_) || die "$_ not found\n";
}


$home = `pwd`; chomp $home;

###############################################
###############################################
#
# make 40% sim clusters
#
@members = ();
%sequence = ();
get_seqs ($fasta);

# this will read names and seqs from global
$distfile = "dist.table";
( -e $distfile) ||  make_dist_table ($distfile); 

#clusters?
$cmd = "$clust $distfile 0.4";
$ret = `$cmd`;
print $ret;
print "\n\n";

# make the directory tree:
# fam/clusters/members/ 
# put sequence into each member directory
@lines = split "\n", $ret; 
@clust = ();
$reading = 0;
$ctr = 0;
foreach (@lines) {
    if ( /cluster/ ) {
	if ( @clust ) {
	    $ctr ++;
	    process_cluster ($family,$ctr, @clust);
	    @clust = ();
	}
	$reading = 1;
    } elsif ( $reading ) {
	chomp;
	$name = $_; $name =~ s/\s//g;
	push @clust, $name;
    }
}
if ( @clust ) {
    $ctr ++;
    process_cluster ($family,$ctr,@clust);
}







# find structure for each cluster (member?)


# Ensembl search for each member
# (will have to do it on my machine until afs is enabled on reindeer)


exit;


###############################################
###############################################

sub process_cluster (@) {
    my $fam   = shift @_;
    my $ctr   = shift @_;
    my @clust = @_;
    my $uni;
    my $member;
    my ($fastafile, $afafile);

    chdir $home;

    (-e "families/$fam") || `mkdir families/$fam`;
    $clustdir = "cluster_$ctr";
    (-e "families/$fam/$clustdir") || `mkdir families/$fam/$clustdir`;

    $memberfile = "families/$fam/$clustdir/members";
    open (OF, ">$memberfile") || die "Cno $memberfile.\n";
    foreach $member (@clust) {
	print OF "$member\n";
	`mkdir families/$fam/$clustdir/$member`;
    }
    close OF;

    foreach $member (@clust) {
	chdir $home;
	chdir "families/$fam/$clustdir/$member"; 

	$fastafile = "$member.fasta";

	open (OF, ">$fastafile") || die "Cno $fastafile.\n";
	print OF ">$member\n";
	print OF "$sequence{$member}\n";
	close OF;
    
	`mkdir mammals all_verts`;
    }
}




###############################################
sub make_dist_table (@) {

    my $distfile = shift @_;
    my ($i, $j, $name1, $name2);
    my ($tmpf, $tmpafa, $tmpmsf, $cmd, $ret);
    my %field = ();

    open (DF, ">$distfile") || die "Cno $distfile: $!.\n";
    printf DF "%d\n", 1+$#members;

    for $i ( 0 .. $#members ) {
	$name1 = $members[$i];

	for $j ( $i+1 .. $#members ) {
		
	    $name2 = $members[$j];

	    $tmpf = "blah.fasta";
	    open (TMPOF, ">$tmpf") || die "Cno $tmpf: $!.\n";
	    print TMPOF  ">$name1\n$sequence{$name1}\n";
	    print TMPOF  ">$name2\n$sequence{$name2}\n";
	    close TMPOF;
		
	    $tmpafa = "blah.afa";
	    $cmd = "$mafft  $tmpf > $tmpafa";
	    (system $cmd) && die "Error running $cmd.\n";

	    $tmpmsf = "blah.msf";
	    $cmd = "$afa2msf $tmpafa > $tmpmsf";
	    (system $cmd) && die "Error running $cmd.\n";
		
	    $cmd = "$seqstats $tmpmsf";
	    $ret = `$cmd`;
	    chomp $ret;
	    %field = split " ",  `$cmd`;
		
	    if ($field{"frac1"} > 0.7 
		&& $field{"frac2"} > 0.7 
		&& $field{"identity"} > 0.4) {
		printf DF   "$name1   $name2   %8.3lf\n", 1-$field{"similarity"};
	    } else {
		printf DF   "$name1   $name2   %8.3lf\n", 1;
	    }


	}
    }
    close DF;

    `rm blah*`;

    
    
}
##############################################################
sub get_seqs (@) {

    my $fasta = shift @_;
    my @lines = split "\n", `cat $fasta`;
    my $name;
    %sequence = ();
    foreach (@lines) {
	next if ( !/\S/);
	chomp;
	if (/^>(\S+)/ ) {
	    $name = $1;
	    $name =~ s/_HUMAN//g;
	    push @members, $name;
	    $sequence{$name} = "";
	} else  {
	    s/\./\-/g;
	    s/\#/\-/g;
	    s/\s//g;
	    #s/x/\./gi;
	    $sequence{$name} .= $_;
	} 
    }
}
