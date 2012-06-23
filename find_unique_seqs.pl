#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);
# input: preferred pruning

@names = ();
$cw = "/home/protean2/LSETtools/bin/linux/clustalw -output=gcg -quicktree";
$twoseq = "/home/i/imihalek/perlscr/two_seq_analysis.pl";

=pod
open ( UNIQUE, "<unique" ) || die "Cno unique: $!.\n";
while ( <UNIQUE> ) {
    next if ( /!\S/ );
    chomp;    
    $visited{$_} = 1;
}
close UNIQUE;

open ( DUPLICATES, "<duplicates" ) || die "Cno duplicates: $!.\n";
while ( <DUPLICATES> ) {
    next if ( /!\S/ );
    @aux = split;
    $visited{$aux[0]} = 1;
}
close DUPLICATES;
=cut

while ( <> ) {
    next if ( /^%/ );
    next if ( !/\S/ );
    chomp;
    @aux = split;
    $name = $aux[0];
    next if ( defined  $visited{$name} );
    push @names, $name;
    $marked{$name} = 0;
}

print "Names left: $#names \n\n";

open ( UNIQUE, ">unique" ) || die "Cno unique: $!.\n";
open ( DUPLICATES, ">duplicates" ) || die "Cno duplicates: $!.\n";

#foreach pair of names
$total_marked = 0;
TOP: foreach $ctr1 ( 0 .. $#names ) {
    $name1 = $names[$ctr1];
    print "  $ctr1     $name1      $total_marked \n";
    #$dir1 = substr $name1, 0, 4;
    $dir1 = ".";
    next if ( $marked{$name1} );
    print UNIQUE "$name1 \n";  UNIQUE -> autoflush(1);
    foreach  $ctr2 ( $ctr1+1  .. $#names ) {
	next if ( $marked{$name1} );
	$name2 = $names[$ctr2];
	#$dir2 = substr $name2, 0, 4;
	$dir2 = ".";

        #two seq almt
	$cmd = "cat $dir1/$name1/$name1.seq $dir2/$name2/$name2.seq > tmp.fasta ";
	(system $cmd) &&  die "cat failure: $!\n";
	
	$cmd = "$cw -infile= tmp.fasta -outfile= tmp.msf > /dev/null"; 
	(system $cmd) ||  die "clustalw failure: $!\n"; # cw return something on success
	
	# perc id
	$ret = `$twoseq tmp.msf `; 
	$ret =~ /.+identity\s+([\d\.]+)\s+similarity/;
	$id = $1;
        # if similar,  mark one with lower area as out	
	if ( $id > 0.25 ) {
	    $total_marked ++;
	    print "$name1 $name2 $id   \n";
	    $marked{$name2} = 1;
	    print DUPLICATES  "$name2  $name1  $id  \n";  DUPLICATES -> autoflush(1);
	    
	}

   }
}


close UNIQUE;
close DUPLICATES;
