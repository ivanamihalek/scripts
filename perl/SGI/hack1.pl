#!/usr/gnu/bin/perl -w
# 1) find pdb names from "progress" html files
# the Structural Genomics Intiative sites publish
# 2) dwonload the pdb file itself
# 3) give the output (names & links) in the html form
$searchString1 = "pdbId="; 
$searchString2 = "PDBId="; 
$htmladdr="http://www.asedb.org";
$htmlfile = "asdb.html"; 
if ( ! open ( OUTFILE, ">$htmlfile") ) {
    die "cannot open $htmlfile file\n" ;
}

$ctr = 0;
 print  OUTFILE "<html>\n";
 print OUTFILE "<table> \n <tr> <th> no</th> <th> pdb id </th><th>where from</th> <th>pdb</th> </tr>";

while (<STDIN>) {
    @files = split ;
    foreach $fileName ( @files ){

	if ( ! open ( INFILE1, "<$fileName") ) {
	    die "cannot open $fileName file\n" ;
	} else {
	    print " reading $fileName \n" ;
	}
        ($blah, $site, $blah) = split (/\./, $fileName);
	print "site = $site \n";
	$found = 0;
	while ( defined($line1 = <INFILE1>) ) {
            
	    if ($line1=~ /$searchString1/ ) {
		$found = 1;
                $searchString = $searchString1;
	    } elsif ($line1=~ /$searchString2/){
		$found = 1;
                $searchString = $searchString2;
	    }
	    if ($found>0) {
		$found = 0;
		$startpos = index ($line1,$searchString);
		$substr = substr ($line1,$startpos+6,4);
		$substr = lc ($substr);
		if ( ! exists ($found{$substr}) ) {
		    $found{$substr} = $site;
                    $upper = uc $substr; 
                    $ctr ++;
		    print OUTFILE "\n<tr><td> $ctr</td><td>";
#		    print OUTFILE "<a href = \"http://www.rcsb.org/pdb/cgi/explore.cgi?job=download;pdbId=$substr;format=PDB;page=&opt=show&format=PDB&pre=1\" >"; 
		    print OUTFILE "<a href = \"http://www.rcsb.org/pdb/cgi/export.cgi/$upper.pdb?job=download;format=PDB;pdbId=$substr;pre=1&compression=None\" >"; 
		    print OUTFILE "$substr </a> ";
		    print OUTFILE "</td>";
		    print OUTFILE "<td><a href=\"$htmladdr\"> here</a></td>";
                    $pdbfile = "pdbfiles/$upper.pdb";
		    if (-e $pdbfile) {
			print OUTFILE "<td><a href=$pdbfile>pdb</a></td>"; 
		    } else {
			print OUTFILE "<td>not found</td>"; 
		    }
		    print OUTFILE "</tr>\n";
		} else {
		    print "found $substr in $found{$substr} (now doing $site)\n";
		}
	    }
	}
	close INFILE1;
    }
}
print OUTFILE "</table> \n";

print OUTFILE "</html>"; 
