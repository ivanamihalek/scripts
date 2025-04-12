#! /usr/bin/perl -w

defined $ARGV[0] || 
    die "usage: serial_etc.pl <name_list>\n";

$etc      = "/home/i/imihalek/code/etc/wetc";
$clustalw = "/home/protean2/LSETtools/bin/linux/clustalw";
$psi_it   = 2;

open ( ERRLOG, ">errlog") ||
    die "Cno errlog:$! \n.";
 

open (NAMES, "<$ARGV[0]") ||
    die "cno $ARGV[0]: $!\n";

$home = `pwd`;
$map  = "/home/i/imihalek/perlscr/map_etc_to_struct.pl";
$etc = "/home/i/imihalek/code/etc//wetc";
chomp $home;

while ( <NAMES> ) {
    next if ( !/\S/);
   
    $begin = time;
    chomp;
    @aux = split;
    $name = $aux[0];


    print "\n $name:\n"; 
    chdir $home ||
	die "cn chdir $home: $!\n";
    chdir $name ||
	die "cn chdir $name: $!; current dir is: ".`pwd`."\n";


    for $level ( "nt", "aa") {
	# run trace w/o structure
	$msf =  "60pss.".$level.".msf";
	$commandline = "$etc -p  $msf -o 60pss.$level -readtree aa.nhx";
	print " $commandline\n";
	print `$commandline`;

	# map the ranks onto the structure
	$ranks  = "60pss.".$level.".ranks";
	$output = "60pss_".$level."_ranks";
	$commandline = "$map $level  pdbid_to_cleanaapos  $ranks > $output ";
	print " $commandline\n";
	print `$commandline`;

	# map the trace results on the structure
	$newout = "60pss.".$level.".pdb";
	$commandline = "$etc -readranks $output -x $name $name.pdb -c -epitope $name.epitope -o $newout ";
	print " $commandline\n";
	print `$commandline`;
	
    }

 
    print "\t                  ... done (", time-$begin, "s)\n";  

    
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
