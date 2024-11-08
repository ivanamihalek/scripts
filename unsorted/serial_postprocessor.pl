#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

use strict;
$HOME = `echo \$HOME`;
chomp $HOME;

$home = `pwd`;
chomp $home;


$path{"mc_postprocess"}    = "$HOME/c-utils/postprocess/postp";
$path{"extract_from_msf"} = "$HOME/perlscr/extractions/extr_seqs_from_msf.pl";

foreach $program ( keys %path) {
    ( -e $path{$program} ) || die "$path{$program} not found.\n";
}

while ( <> ) {
    chomp;
    ($pdbname) = split;
    chdir $home;
    chdir $pdbname;
    # input names
    $msffile= "$pdbname.msf";
    $out_name = "mc_out";
    $query_name = $special_name = "$pdbname.mc";
    $stucture_file = "$pdbname.pdb";
    # prepare cmd file for the postprocessor
    $cmd_file = prepare_mc_postprocessor ($msffile, $out_name, $query_name, $special_name, $stucture_file);
    # run the postprocessor
    $command = $path{"mc_postprocess"}." $cmd_file ";
    $ret = `$command | grep choosing`;
    print "\t", $ret;
    @aux = split " ", $ret;
    $names_choice = $aux[3];	  
    # extract the "best" alignment
    #output name:
    $out_msf = "$pdbname.mc.msf";
    $command = $path{"extract_from_msf"}." $names_choice tmp.msf > $out_msf"; 
    (system $command) && die "Error extracting seq from msf."; 

}

######################################################
sub prepare_mc_postprocessor ( @) {
    my ($msffile, $out_name, $query_name, $special_name, $stucture_file) = @_;
    my $ret;
    my @names;
    my ($cmd, $fh, $msf_name);
    my $command;

    print "\t\t postprocessing\n";

    $ret = `ls $out_name.*.names`;
    @names = split '\n', $ret;
    $cmd = "align  $msffile\n";
    foreach (@names) {
	$cmd .= "names  $_\n";
    } 
    $cmd .= "query $query_name\n";
    $cmd .= "special $special_name\n";
    $cmd .= "pdbf $stucture_file\n";
    $cmd .= "sink 0.3\n";
   
    open (FILE, ">cmd");
    print FILE $cmd;
    close FILE;

    return "cmd";
}

