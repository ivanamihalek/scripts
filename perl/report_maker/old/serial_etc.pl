#! /usr/bin/perl -w

defined $ARGV[0] || 
    die "usage: serial_etc.pl <name_list>\n";

$etc = "/home/i/imihalek/code/etc/wetc";

open ( ERRLOG, ">errlog") ||
    die "Cno errlog:$! \n.";
 

open (NAMES, "<$ARGV[0]") ||
    die "cno $ARGV[0]: $!\n";

$home = `pwd`;
#$home = "/sycamore/ivana/projects/cow/fssp/chains/";
chomp $home;

while ( <NAMES> ) {
    next if ( !/\S/);
   
    chomp;
    @aux = split;
    $name = $aux[0];


    chdir $home || die "cn chdir $home: $!\n";

    $dir = (substr $name, 0, 4)."/".$name;
    chdir $dir || die "cn chdir $dir: $!\n";;

 
    #$epifile = "$name.epitope";
    $pdbfile = "$name.pdb";

    #$pdbname = substr $name, 0, 4;
    $com_all  = "nice $etc -x  $name $pdbfile  -c ";

    #raw
    $msffile  =  "$name.raw.msf";
    $outname = "$name.raw" ;
    
    $commandline = $com_all."  -p $msffile -o $outname ";  
    print " $commandline \n";
    system ($commandline) && exit (1);    
 
    #from raw ro prune  5
    $msffile  =  "$name.raw.msf";
    $pruning_level =  5;  
    $outname = "pr$pruning_level" ;
    $commandline = $com_all."  -p $msffile -o $outname   -prune $pruning_level";  
    system ($commandline) && exit (1);    
    if (!  -e  "$outname.pruned.msf") {
	if ( -l  $msffile ) {
	    $target = readlink $msffile;
	     `ln -s  $target $outname.pruned.msf`; 
	} else {
	    `ln -s  $msffile $outname.pruned.msf`; 
	}
    }


    #from  prune  5 to prune  16 
    $msffile  =  "pr5.pruned.msf"; 
    $pruning_level =  16;  
    $outname = "pr$pruning_level" ;
    $commandline = $com_all."  -p $msffile -o $outname  -prune $pruning_level";  
    system ($commandline) && exit (1);    
    if (!  -e  "$outname.pruned.msf") {
	if ( -l  $msffile ) {
	    $target = readlink $msffile;
	     `ln -s  $target $outname.pruned.msf`; 
	} else {
	    `ln -s  $msffile $outname.pruned.msf`; 
	}
    }
 

    #from  prune  16 to prune  64
    $msffile  =  "pr16.pruned.msf";
    $pruning_level =  64;  
    $outname = "pr$pruning_level" ;
    $commandline = $com_all."  -p $msffile -o $outname  -prune $pruning_level";  
    system ($commandline) && exit (1);    
    if (!  -e  "$outname.pruned.msf") {
	if ( -l  $msffile ) {
	    $target = readlink $msffile;
	    `ln -s  $target $outname.pruned.msf`; 
	} else {
	    `ln -s  $msffile $outname.pruned.msf`; 
	}
    }
 

 

}

close ERRLOG;



sub process_failure  {
    	print ERRLOG "\n$name: $_[0] failure.\n";
	print ERRLOG "\texit value: ", $? >> 8, "\n"; 
	print ERRLOG "\t signal no: ", $? & 127, "\n"; 
	if ( $? & 128 ) {
	    print ERRLOG "\tcore dumped.\n";
	}
}
