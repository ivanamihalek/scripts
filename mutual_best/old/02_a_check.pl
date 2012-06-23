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
exit;

foreach $clust ( @all_clusters) {

    chdir $home;
    chdir $clust;
    #( -e "mutual_best") || `mv seq_for_pdb mutual_best`;
    chdir "mutual_best";
    @aux = split "\n",  `ls *.seq`;
    @members = grep { s/.seq//g } @aux;

    foreach $member (@members) {

       ( ! -e "$member.fasta")  &&  print  `pwd`,"\t $member.fasta not found\n";
       (   -z "$member.fasta")  &&  print  `pwd`,"\t $member.fasta is empty\n";

       #( ! -e "$member.other_verts.fasta")  &&  print  `pwd`,"\t $member.other_verts.fasta not found\n";
       #(   -z "$member.other_verts.fasta")  &&  print  `pwd`,"\t $member.other_verts.fasta is empty\n";

    }
}


