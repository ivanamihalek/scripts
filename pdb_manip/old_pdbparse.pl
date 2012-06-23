#!/usr/bin/perl -w  
# Ivana, Dec 2001
# PURPOSE:  select only the lines  starting with "ATOM" from a pdb file;
# INPUT:    the pdb files should be provided as a list from stdin (piping it from ls will do):
#           the list is supposed to  contain the names of the pdb  files - the pdb files themselves 
#           should be in the directory specified as $PDBFILES below; 
#           for example: "ls pdbfiles | pdbparse.pl" ; 
#
# OUTPUT:   the "stripped" files  are saved into a
#           subdirectory  according to their "type":
#            
#           single_chain:    pdbfiles containing single chain of amino acids (AA)
#           multiple_chains: if the orginal PDB file has repeating chains of the
#                            same sequence, one  representative chain gets written here
#           unique_chains:   if the orginal PDB file has several different chains (sequqnces)
#                            one representative sequence for each is output
#           nmr:             NMR dtermined strucutres - get only the first model (what if there
#                            are several chains? )
#           thry:            theoretical model -- the current lore is that we do not use
#                            these so I ust make a soft link to the original file - just
#                            for bookkeeping purposes
#           unknwn:          files whose format is not recognized, for any reason
#
#DEPENDENCIES:  none
#
#ASSUMPTIONS:  1) To connect smoothly the output of this program to pipeline.pl
#               the pdb files should be named according to the following convention:
#                <pdb_name>.pdb [note that the older pdb files sometimes have the
#               names formatted according to pdv<pdb_name>.ent]
#              2) A sequence is termed "short" if it contains less than $CUTOFF_LENGTH
#                 amino acids. The idea is that these probably won't be interesting
#                 for pipelining.

$PDBFILES = "pdbfiles"; 
$PDBNAMES_FILE = "pdbnames"; 
$CHAINNAMES_FILE = "chainnames"; 


#the "types" of PDB files  I expect to see:
$SINGLE        =  0;   # single chain
$MULTIPLE      =  1;   # multiple chains 
$THRY          =  2;   # theoretical structure model (toss away)
$NMR           =  3;   # NMR - multiple models (toss away)
$UNRECOGNIZED  =  4;   # various unrecognized types

$CUTOFF_LENGTH =  50;   # chain too short to result in meaningful blast search

open (PDBNAMES,"<$PDBNAMES_FILE" ) ||
    die "Could not open $PDBNAMES_FILE\n";

open (CHAINNAMES,">$CHAINNAMES_FILE" ) ||
    die "Could not open $CHAINNAMES_FILE\n";

%letter_code = ( 'GLY', 'G', 'ALA', 'A',  'VAL', 'V', 'LEU','L', 'ILE','I',
		'MET', 'M', 'PRO', 'P',  'TRP', 'W', 'PHE','F', 'SER','S',
		'CYS', 'C', 'THR', 'T',  'ASN', 'N', 'GLN','Q', 'TYR','Y',
                'LYS', 'K', 'ARG', 'R',  'HIS', 'H', 'ASP','D', 'GLU','E');
sub printseq();

while (<PDBNAMES>) {
    chomp;
    @files = split ;
    
    foreach $fileName ( @files ){
	# make sure I have the .pdb extension:
	@aux  = split ('\.', $fileName);
	if ( $aux [$#aux] !~ /pdb/ ) {
	    $fileName = (uc $fileName).".pdb";
	}
	$outfile = lc $fileName;
	if ( ! open ( INFILE, "<$PDBFILES/$fileName") ) {
	     $fileName = lc $fileName;
	     open ( INFILE, "<$PDBFILES/$fileName") ||
		    die "cannot open $PDBFILES/$fileName file \n" ;
	 }
	print "\n*******************************************\n" ;
	print "* reading $fileName \n" ;
	print "*******************************************\n" ;
	

	#############################################
	# classify the pdbfile type
	$type    = $UNRECOGNIZED; 
	while ( defined($line1 = <INFILE>) ) {
	    if ($line1=~ /EXPDTA/ ) {
		if ($line1=~ /THEORETICAL/) {
		    print $line1;
		    print "(dropped)\n"; 
		    $type = $THRY;
		} elsif ($line1=~ /NMR/) {
		    print $line1;
		    print "(dropped)\n"; 
		    $type = $NMR;
		}
	    } 
	}

        # if type still unrecognized: 
        if ($type == $UNRECOGNIZED ) {

            # empty containers:
	    while (($key,$value) = each %foundname) {
		delete $foundname{$key};
            }	    
            while (defined (pop @chainname)) {;}

	    $ctr = 0;
	    seek INFILE, 0, 0; # this is rewinding
	    while ( <INFILE> ) {
		if ( /SEQRES/) {
                   # format in which the sequence has a name
		   if ( /SEQRES(\s)+(\d)+(\s)+(\w)+(\s)+(\d)+(\s)+(\w{3})/ ) {
                       if ( ! exists $foundname{$4} ) {
			   $foundname{$4} = $ctr;
                           $chainname[$ctr] = $4; 
			   $ctr++; 
		       }
                   # otherwise it must be a single chain
		   } elsif (/SEQRES(\s)+(\d)+(\s)+(\d)+(\s)+(\w{3})/ ) {
		       $type = $SINGLE;
		       last; 
		   }
	       }
	    }
	    if (defined $chainname[0]) {
		if ($#chainname == 0) {
                    # single chain which is for some reason named
		    $type = $SINGLE;
		} else {
                    # the file contains several chains
		    $type = $MULTIPLE;
		}
	    }
	}

	print "type = $type \n"; 

# ***************************************************************************
# ***************************************************************************

        # sort the files and get the "ATOM" lines from the usable ones:
	if ($type == $SINGLE){
	    # check if the length of the chain is meaningful (i.e. > $CUTOFF_LENGTH) :
	    while (defined (pop @seq)) {;}

	    seek INFILE, 0, 0; # this is rewinding
	    while ( defined($line1 = <INFILE>) && $line1 !~ /ATOM(\s)+(\d)+(\s)+([\w|\s]{4})(\D){3}(\s)+/ ){ 
		# The match below excludes nucleic acids.
                # The chain  can be either named or unnamed:
		if ( $line1=~ /SEQRES(\s)+(\d)+(\s)+(\d)+(\s)+(\w{3})/ ||
		     $line1=~ /SEQRES(\s)+(\d)+(\s)+(\w)+(\s)+(\d)+(\s)+(\w{3})/ ) {
		    @aux2 = split (' ', $line1);
		    foreach ( @aux2[3..$#aux2]) { 
			if ( /\w{3}/ )  {       # some people add some junk to the end of line ...
			    if ( $_ !~ /\d/ ) { # "_" underscores and non-AA's could still get through
				push @seq, $_ ; 
			    }
			}
		    }
		}
	    }
	    $dir ="./";
	    if ( ($#seq+1) < $CUTOFF_LENGTH ) {
		print "Note: the length of the peptide chain is";
                print " is shorter (",$#seq+1,") than the currently defined cuttof (";
                print "$CUTOFF_LENGTH).\n";
            }
		
	    @ofname = split('\.', $outfile);
	    $aux = pop (@ofname);
	    # for later purposes, I want the pdbfile 
	    # in the directory with the same name
	    $dir.= join ('', @ofname);
	    if ( ! -e $dir) {
		mkdir ( $dir, 0770) ||
		    die "Cannot make $outfile2.\n";
	    }
	    # output the coordinates
	    $outfile2 = $dir.'/'.$outfile; 
	    if ( ! open (OUTFILE, ">$outfile2") ) {  
		die "cannot open $outfile2 file\n" ;
	    } else {
		print " writing pdb data to $outfile2 \n" ;
	    }
	    print CHAINNAMES join ('', @ofname),"\n";

	    @seq = ();
	    $current_aa = "";
	    do {
		if ($line1=~ /ATOM\s+(\d)+\s+([\w|\s]{4})(\w{3})\s[\s|\w]([\s|\w]{5})/ 
		    && defined $letter_code{$3}) { 
		    if ( $4 !~ $current_aa ) {
			$current_aa = $4;
			push @seq, $3;
		    }
		    print OUTFILE $line1;
		}
	    } while ( defined($line1 = <INFILE>) );
	    close OUTFILE;
	    
	    # output the sequence
	    $seqfile = $dir.'/'.join ('', @ofname).".seq"; 
	    $seqname = join ('', @ofname);
	    printseq ();

# ***************************************************************************
# ***************************************************************************
	} elsif ($type == $MULTIPLE)  {
	    # if there are multiple chains,
	    # need to decide if they are different:

            # empty containers: 
	    %chain = ();
	    @seq = ();
	    $current = -1;

            # here I assume that sequences will be listed before the indivudual atoms
	    seek INFILE, 0, 0; # this is rewinding
	    while ( defined($line1 = <INFILE>) && $line1 !~ /ATOM(\s)+(\d)+(\s)+([\w|\s]{4})(\D){3}(\s)+/ ){ 
		# the match below excludes nucleic acids:
		if ( $line1=~ /SEQRES(\s)+(\d)+(\s)+(\w)+(\s)+(\d)+(\s)+(\w{3})/ ) {
		    @aux2 = split (' ', $line1);
		    $newname = $4;
		    if ($current < 0) {
			for ($ctr=0; $ctr <= $#chainname; $ctr++) {
			    if ( $newname =~ $chainname[$ctr]){
				$current  =  $ctr;
				last;
			    }
			}
		    }
		    if ( $current <0 ) { # if current is still < zero - problem
			print join(' ', @chainname);
			die "undeclared chain  found in $fileName.\n"; 
		    }
		    # end of sequence / beginning of new sequence: 
		    if ($newname !~ $chainname[$current]) {
			if ( !( exists $chain{join('',@seq)}) ) {	
			    $chain{join('',@seq)} = $current ; 
			    print "new  $chainname[$current]\n"; 
			}  else {
			    print "found already $chainname[$current] \n"; 
			}
			    
			# empty the sequence array
			while (defined (pop @seq)) {;}
			$current = -1;
			redo; #repeat the loop without reevaluating the condition
		    }  
		    foreach ( @aux2[4..$#aux2]) { 
			if ( /\w{3}/ )  {       # some people add some junk to the end of line ...
			    if ( $_ !~ /\d/ ) { # "_" underscores and non-AA's could still get through
				push @seq, $_ ; 
			    }
			}
		    }
	    
		}
	  
	    }
            # need  to check if the last chain found - clunky
	    if ( !( exists $chain{join('',@seq)}) ) {	
		if ($current < 0) {
		    
		    for ($ctr=0; $ctr <= $#chainname; $ctr++) {
			if ( $newname =~ $chainname[$ctr]){
			    $current = $ctr;
			    last;
			}
		    }
		}
		if ($current <0 ) { # if current is still zero - problem
		    print join(' ', @chainname);
		    die "undeclared chain  found in $fileName.\n"; 
		}
		$chain{join('',@seq)} = $current ; 
		print "new  $chainname[$current]\n"; 
	    }  else {
		print "found already $chainname[$current] \n"; 
	    }
			    
	   
	
            $nochains =  keys %chain;
	    print join(' ', @chainname),"\n";
	    print " there are $nochains different AA  chains: ";
	    foreach (values  %chain ) {
		print $chainname[$_ ]," ";
	    } 
	    print "\n"; 
	    $dir= "./";

	    # construct all the filenames I need (one for each chain)
            # cleanup
	    while (defined (pop @outfile3)) {;}
	    while (($key, $value) = each %chain){
		# print STDERR "*  ", $value ,"\n"; 
		$found = 0;
		# construct the filename:
		@ofname = split('\.', $outfile);
		$aux = pop (@ofname);
		push (@ofname, $chainname[$value]);
		$outfile3[$value] = join ('', @ofname);

		$dir_chain = $dir.join ('', $outfile3[$value]);
		
		if ( ! -e $dir_chain) {
		    mkdir ( $dir_chain, 0770) ||
			die "Cannot mkdir  $dir .\n";
		}
		print CHAINNAMES "$outfile3[$value]\n";
		$cname[$value]    =  $outfile3[$value];
		$outfile3[$value] =  $dir_chain.'/'.$cname[$value].'.pdb';
		$seqfile3[$value] =  $dir_chain.'/'.$cname[$value].'.seq';
		$found[$value]    =  0; #the chains might be repeated ... skip repeats
	    }   

	    # recognize chains and print them to separate file

	    # to help me open the file only when I
	    # first see the chain, and to keep track of
	    # the current chain:
	    $current = -1;
	    $warn = 0;
	    $current_aa = "";
	    @seq = ();
	    do {{
		if ($line1=~ /ATOM\s+(\d)+\s+([\w|\s]{4})(\w{3})\s([\s|\w])([\s|\w]{5})/
		    && defined $letter_code{$3}) { 
		    # in the column 27 there might or might not 
                    # be the so called "insertion code"
		    $new_aa =  $5;
		    $chn_name = $4;
		    $aa_type = $3;
		    if ( $current < 0) { #this chain first seen 
		        foreach (values  %chain ) {
			    if ( $chn_name =~ $chainname[$_]){
				$current = $_;
				last;
			    }
			}
			next if ( $current < 0); # the chain is not what I'm looking for
			
			if (! $found[$current] ) {
			    $current_aa = "";
			    if (! open ( OUTFILE, ">$outfile3[$current]") ) {  
				die "cannot open $outfile3[$current] file\n" ;
			    } else {
				print "writing pdb data $outfile3[$current] \n" ;
			    }
			}
			
		    }
		    
		    if ( $chn_name =~ $chainname[$current] ){
			if ( ! $found[$current] ) {
			    if ( $new_aa !~ $current_aa ) {
				$current_aa = $new_aa;
				push @seq, $aa_type;
			    }
			    print OUTFILE $line1;
			}
		    } else { # new chain
			if ( ! $found[$current] ) {
			    $found[$current] = 1;
			    close OUTFILE;
			    $seqfile = $seqfile3[$current];
			    $seqname = $cname[$current];
			    printseq();
			    while (defined (pop @seq)) {;}
			}
			$current = -1;
		    }
		}
			#print $line1; 

	    }} while ( defined($line1 = <INFILE>) ) ;
	    if( defined $seq[0] ) {
		$seqfile = $seqfile3[$current];
		$seqname = $cname[$current];
		printseq();
	    }
	    if ($warn) {
		print "Warning: this file contains insertion atoms - insertion code ignored.\n";  
	    }
		
    
	        
# ***************************************************************************
# ***************************************************************************
	    
	} elsif ($type == $THRY ) {
	    if ( ! -e "thry/" ) {
		mkdir ("thry/" , 0770) ||
		    die "Cannot make thry/ .\n";
	    }
	    link "$PDBFILES/$fileName", "thry/$fileName";
	} elsif ($type == $NMR ) {
	    if ( ! -e "nmr/" ) {
		mkdir ("nmr/" , 0770) ||
		    die "Cannot make nmr/ .\n";
	    }
	    link "$PDBFILES/$fileName", "nmr/$fileName";
        } elsif ($type == $UNRECOGNIZED)  {
	    print "Warning: $fileName format not recognized.\n"; 
	    if ( ! -e "unknwn/" ) {
		mkdir ("unknwn/" , 0770) ||
		    die "Cannot make unknwn/ .\n";
	    }
	    link "$PDBFILES/$fileName", "unknwn/$fileName";
	   
	} else {
	    print "Warning: file type not assigned.\n"; 
	}

	close INFILE;
    }
}

close PDBNAMES;
close CHAINNAMES;






sub printseq() {

    if ( ! open (SEQFILE, ">$seqfile") ) {  
	die "cannot open $seqfile file\n" ;
    } else {
	print " writing sequence to $seqfile \n" ;
    }
    print SEQFILE "> $seqname\n";
    for ($i=0; $i<= $#seq; $i++) {
	print  SEQFILE $letter_code{$seq[$i]};
	if ( !(($i+1)%50) && $i != $#seq) {
	    print  SEQFILE "\n";
	}
    }
    print SEQFILE "\n";
    close SEQFILE;
}
