#! /usr/bin/perl -w

defined $ARGV[0] || 
    die "usage: serial_etc.pl <name_list>\n";

$etc      = "/home/i/imihalek/code/etc/wetc";

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


    chdir $home ||
	die "cn chdir $home: $!\n";
    $dir = (substr $name, 0, 4)."/".$name;
    chdir $dir ||
	die "cn chdir $dir: $!; current dir is: ".`pwd`."\n";

 
    #$epifile = "$name.epitope";
    $pdbfile = "$name.pdb";

    #$pdbname = substr $name, 0, 4;

    $com_all  = "nice $etc -x  $name $pdbfile  -c ";

    #raw
    $msffile  =  "$name.hssp.msf";
    ( -e  $msffile ) || `mv  ../../hsspfiles/$msffile .`;
    $outname = "hssp.raw" ;
    `rm -f  $outname.*`; 
    $commandline = $com_all."  -p $msffile -o $outname";   
    system ($commandline) && exit (1);    



    #from raw ro prune  5
    $msffile  =  "$name.hssp.msf";
    $pruning_level =  5;  
    $outname = "hssp.pr$pruning_level" ;
    `rm -f  $outname.*`; 
    $commandline = $com_all."  -p $msffile -o $outname -no_realign  -prune $pruning_level";  
    system ($commandline) && exit (1);    
    if ( -e "$outname.ranks_sorted" ) {
 	`ln -s $name.hssp.msf  $outname.msf`;
    } else {
 	`grep '>' $outname.pruned.input | awk -F '>' '{print \$2}' > $outname.pruned.names`;
	( -e "$outname.msf") &&  `rm -f  $outname.msf`;
	`extr_seqs_from_msf.pl $outname.pruned.names $msffile > $outname.msf`;
	#print "rerunning trace.\n";
	$commandline = $com_all."  -p $outname.msf  -o $outname";  
	system ($commandline) && exit (1);    
    }



    #from  prune  5 to prune  16
    $msffile  =  "hssp.pr5.msf"; 
    $pruning_level =  16;  
    $outname = "hssp.pr$pruning_level" ;
      `rm -f  $outname.*`; 
    $commandline = $com_all."  -p $msffile -o $outname -no_realign -prune $pruning_level";  
    system ($commandline) && exit (1);    
    if ( -e "$outname.ranks_sorted" ) {
 	`ln -s hssp.pr5.msf  $outname.msf`;
    } else {
 	`grep '>' $outname.pruned.input | awk -F '>' '{print \$2}' > $outname.pruned.names`;
	( -e "$outname.msf") &&  `rm -f  $outname.msf`;
	`extr_seqs_from_msf.pl $outname.pruned.names $msffile > $outname.msf`;
	$commandline = $com_all."  -p $outname.msf  -o $outname";  
	system ($commandline) && exit (1);    
    }


    #from  prune  16 to prune  64
    $msffile  =  "hssp.pr16.msf";
    $pruning_level =  64;  
    $outname = "hssp.pr$pruning_level" ;
     `rm -f  $outname.*`; 
    $commandline = $com_all."  -p $msffile -o $outname -no_realign -prune $pruning_level";  
    system ($commandline) && exit (1);    
    if ( -e "$outname.ranks_sorted" ) {
  	`ln -s hssp.pr16.msf  $outname.msf`;
    } else {
 	`grep '>' $outname.pruned.input | awk -F '>' '{print \$2}' > $outname.pruned.names`;
	( -e "$outname.msf") &&  `rm -f  $outname.msf`;
	`extr_seqs_from_msf.pl $outname.pruned.names $msffile > $outname.msf`;
	$commandline = $com_all."  -p $outname.msf  -o $outname";  
	system ($commandline) && exit (1);    
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
