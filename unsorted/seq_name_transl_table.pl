#! /usr/gnu/bin/perl -w

# Ivana, 2002
# from a set of *.seq files extract the pairs
# (db index, taxonomy name) and print it out
# --- pipe in the list of *.seq names

while ( <> ) {
    chomp;
    next if (/pt_/);
    @aux = split;
    foreach $name ( @aux) {
	open (SEQFILE, "<$name")  ||
	    die "Cno $name: $!\n";
	while ( <SEQFILE> ) {
	    last if (/ORGANISM/);
	}
	chomp;
	@aux2 = split;
	$seqname =  substr ($aux2[1],0,6) ;
	$seqname .=  substr ($aux2[2],0,3) ; 
	if (defined $aux2[3] && $aux2[3] !~ /[\(\)]/) {
	    $seqname .= substr ($aux2[3],0,3) ;
	}
	$seqname = uc $seqname;
	if ( defined $found{$seqname}) {
	    $found{$seqname} +=1;
	} else {
	    $found{$seqname} =1;
	}
	$seqname .="-".$found{$seqname};
	($oldname, $ext) = split ('\.', $name);
	printf "%-20s %-10s \n", $oldname,  $seqname;
	close (SEQFILE);
    }
}
