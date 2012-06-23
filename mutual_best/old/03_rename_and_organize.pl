#! /usr/bin/perl


=pod
foreach ($ensembl_mut_best) {
    (-e $_) || die " $_ not found\n";
}
=cut

@all_clusters = split "\n", `ls -d */cluster*`;
@all_clusters || die "no cluster dir found (?) \n";



$home = `pwd`; chomp $home;

$new_home = $home;
$new_home =~ s/_v4/_v5/;

print "$home\n";
print "$new_home\n";
#exit;


foreach $clust ( @all_clusters) {


    chdir $home;
    chdir $clust;


    chdir "mutual_best";
    ( -e "orig_seq.fasta") && `rm -rf orig_seq.fasta`;

    foreach $stupid ( "README", "tmp_blastout", "tmp.fasta", "tmp_ids" ) {
	 (-d $stupid) && `rm -rf $stupid`; 
    }

    if  ( glob("*.seq") ) {
	@aux = split "\n",  `ls *.seq`;
	@members = grep { s/.seq//g } @aux;
    } else {
	@members = split "\n",  `ls -d * | grep -v log`;
    }

    foreach $member (@members) {

 
       (-e "$member.fasta") && `mv $member.fasta $member.mammals.fasta`;
       (-e "$member" && ! -d "$member") && `rm $member`;
       (-e "$member") || `mkdir $member`;

       glob("*$member.*") && `mv *$member.* $member`;

       chdir $member;
       print "\n$member:\n";
       print `pwd`;
       if (-d "$member" ) {
	   `mv $member/* .`;
	   `rm -rf $member`;
       }

       (-e "ensembl_$member.fasta.log") && `rm ensembl_$member.fasta.log`;
       (-e "ensembl_$member.log")     && `mv ensembl_$member.log ensembl_$member.mammals.log`;
       (-e "ensembl_$member.2.log") && `mv ensembl_$member.2.log ensembl_$member.other_verts.log`;
       (-e "$member.descr")         && `mv $member.descr $member.mammals.descr`;
       (-e "$member.mafft.afa")     && `mv $member.mafft.afa $member.mammals.mafft.afa`;
       print `ls`;
       chdir "..";

 
       #( ! -e "$member.other_verts.fasta")  &&  print  `pwd`,"\t $member.other_verts.fasta not found\n";
       #(   -z "$member.other_verts.fasta")  &&  print  `pwd`,"\t $member.other_verts.fasta is empty\n";

    }

    chdir $home;
    chdir $clust;

    ( -e "$new_home/$clust") || `mkdir -p $new_home/$clust`;
    foreach $member (@members) {
	`cp -r mutual_best/$member  $new_home/$clust`;
    }
    `cp -r display.html $new_home/$clust`;
    `cp -r cmd $new_home/$clust`;

    open (MEMBERS, ">members");
    foreach $member (@members) {
	print MEMBERS "$member\n";
    }
    close MEMBERS;
   
    `cp members $new_home/$clust`;
}


