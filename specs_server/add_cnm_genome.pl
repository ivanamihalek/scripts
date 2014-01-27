#! /usr/bin/perl -w
defined($ARGV[1])  ||
    die "Usage: find_common_nm.pl dictionaryfile genomefile\n";
#$species_name_file = "/home/zhangzh/speciesName";
$dictionaryfile = $ARGV[0];
$genomefile = $ARGV[1];

open(IF, "<$dictionaryfile") || die "Cno $dictionaryfile $!\n";
while(<IF>){
    chomp;
    next if(/^$/);
    @tmp=split;
    $common_name{$tmp[0]} = "$tmp[1]\t$tmp[3]";     
}
close(IF);
#foreach $k(keys%common_name){
    #print "$k,$common_name{$k}\n";
#}
@new_content=();
open(IF, "<$genomefile") || die "Cno $genomefile $!\n";
while(<IF>){
    chomp;
    next if(/^$/);
    @tmp = split(/\t/,$_);
    @aux = split(/\s/,$tmp[2]);
    $tmp_N = join("_",@aux);
    $scientificN = uc(substr($tmp_N,0,1)) . lc(substr($tmp_N,1));
    if(defined($common_name{$scientificN})){
	#print "$scientificN->$common_name{$scientificN}\n";
	$line = "$_\t$common_name{$scientificN}\n";
	push(@new_content,$line);
    }
    else{
	$line = "$_\n";
	push(@new_content,$line);
    }
    
}
close(IF);
$new_genomefile = substr($genomefile,0,-4) . ".new.txt";
#print "newfile=$new_genomefile\n";

open(IF,">$new_genomefile")||die "Cno:$new_genomefile,$!\n";
print IF @new_content;
close(IF);
#foreach $qu(@query){
#    if(defined($common_name{$qu})){
#        print "$qu\t$common_name{$qu}\n";
#    } 
#    else{
#        print "$qu(not find)\n";
#    }
#}

