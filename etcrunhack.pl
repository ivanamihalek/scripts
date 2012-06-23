#! /usr/bin/perl -w

defined $ARGV[0] || 
    die "usage: runetc.pl <name_list>\n";

$etc      = "/home/protean5/imihalek/trace+/etc/etc";
$etc2      = "/home/protean5/imihalek/trace+/etc/etc2";

open (NAMES, "<$ARGV[0]") ||
    die "cno $ARGV[0]: $!\n";
while ( <NAMES> ) {
   
    if ( /\w/ ) {
	$begin = time;
    
	chomp;
	@aux = split ' ';
	$name = $aux[0];
	$name =~ s/\s//g;
	$query_name =  "query_$name";
	$msffile = "manual_DkOl1.msf";
	$pdbfile = "$name.pdb";
	#$epitope = "epitopes/$name.epitope";

	chdir $name ||
	    die "cn chdir $name: $!\n";
	print "\n $name:\n"; 
	if ( ! -e $pdbfile ) {
	    print "$pdbfile does not exist. \n";
	    chdir "../";
	    next;
	}
	print "\t running trace ... \n"; 

	# prune:
	#$retval = `$etc -p $name.raw.msf -o old -x $name -prune 71`;
	#`mv old.pruned.msf $name.pruned.msf`;

	#@epidir = ("looser_epitope", "stricter_epitope", "disease_epitope");
	@epidir = (".");


	$epitope = "$name.pdb_epitope";



	if ( ! -e $msffile ) {
	    print "$msffile does not exist. \n";
	    chdir "../";
	    die;
	}

	#$retval = `$etc -p $msffile  -o old       -pss    -c -i -x  $query_name $pdbfile -epitope $epitope `;
	#$retval = `$etc -p $msffile  -o entr       -entropy -c -i -x  $query_name $pdbfile -epitope $epitope`;
	#$retval = `$etc -p $msffile  -o new       -realval   -c -i -x  $query_name $pdbfile -epitope $epitope`;
	$retval = `$etc -p $msffile  -o zoom       -zoom  -realval -c -i -x  $query_name $pdbfile -epitope $epitope`;

	print "\t                  ... done (", time-$begin, "s)\n";  

	chdir "../"; 

    }  
    
}


