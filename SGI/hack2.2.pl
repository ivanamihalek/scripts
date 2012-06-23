#!/usr/gnu/bin/perl -w 
# Ivana, Oct 2001
# PURPOSE:  select only the lines  starting with "ATOM" from a pdb file;
# INPUT:    the pdb files should be provided as a list from stdin (piping it from ls will do):
#           the list is supposed to  contain the names of the pdb  files - the pdb files themselves 
#           should be in the directory specified as $PDBFILES below; 
#           for example: "ls pdbfiles | hack2.2.pl" ; 
# OUTPUT:   the "stripped" files  are saved to $ATOMS directory and into a
#           subdirectory  according to their "type":
#            
#           single_chain:    pdbfiles containing single chain of amino acids (AA)
#           multiple_chains: if the orginal PDB file has repeating chains of the
#                            same sequence, one  representative chain gets written here
#           unique_chains:   if the orginal PDB file has several different chains (sequqnces)
#                            one representative sequence for each is output
#           thry:            theoretical model -- the current lore is that we do not use
#                            these so I ust make a soft link to the original file - just
#                            for bookkeeping purposes
#           nmr:             NMR dtermined strucutres -receive the same treatment as thry



$PDBFILES = "pdbfiles"; 

$ATOMS    = "atoms7"; # subdirectory to which the output should be directed

if ( ! -e $ATOMS ) {
    mkdir $ATOMS, 0777 ||
	die "could not make $ATOMS directory.\n";
}
#the "types" of PDB files  I expect to see:
$SINGLE   =  0;   # single chain
$MULTIPLE =  1;   # multiple chains 
$THRY     =  2;   # theoretical structure model (toss away)
$NMR      =  3;   # NMR - multiple models (toss away)


while (<STDIN>) {
    @files = split ;
    foreach $fileName ( @files ){
	$outfile = lc $fileName;
	if ( ! open ( INFILE, "<$PDBFILES/$fileName") ) {
	    die "cannot open $fileName file\n" ;
	} else {
	    print "\n*******************************************\n" ;
	    print "* reading $fileName \n" ;
	    print "*******************************************\n" ;
	}

	# decide output name, based on wether it is
        # a single or a multiple chain
	$chains = "";
	$nameset = 0;
	while ( defined($line1 = <INFILE>) ) {
      	    if ($line1=~ /COMPND/ ) { 
                if ($line1=~ /CHAIN:/ ) {
		    chomp $line1;
		    ($blah, $chainstring) = split (':', $line1);
		    $ind = index ($chainstring,";"); # get rid of ";  " 
                    $chainstring = substr ($chainstring, 1,$ind-1);  
		    $chains = $chains.$chainstring.', ';
		    $nameset  = 1;
		}
	        next;
	    } elsif ( $nameset ) {
		$nameset = 0;
		#should  get rid of whitespace in a better way:
		@chainname = split (', ', $chains); 
	        
		if ($#chainname>0) {
		    print " --> mulitple chains ($chains)\n";
		    $type = $MULTIPLE;

		} else {
		    print " --> single chain ($chains)\n" ;
		    $type = $SINGLE;
		}
	       
	    }
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
	    } elsif ($line1=~ /NUCLEIC ACID ATOMS/ ) {
		
		#($blah, $number) = split (':', $line1);
		#($number,$blah ) = split (' ', $number);
		if ($line1 !~ "NULL" &&  $line1 !~ /\s0\s/ ) {
		    print ("NOTE: # nucleic acid atoms != 0 \n");
		}
	    } elsif ($line1=~/SEQRES(\s)+(\d)+(\s)+(\w)+(\s)+(\d)+(\s)+(\D){3}/ 
		     ||  $line1=~ /ATOM(\s)+(\d)+(\s)+(\w)+(\s)+(\D){3}(\s)+/ ) { 
		print $line1;
		print "type = ", $type, "\n"; 
		last;
	    }

	}

        # sort the files and get the "ATOM" lines from the usable ones:
	if ($type == $SINGLE){
	    if (1) { # (or ignore it)
		if ( ! -e "$ATOMS/single_chain/" ) {
		    mkdir ("$ATOMS/single_chain/" , 0777) ||
			die "Cannot make $ATOMS/single_chain/ .\n";
		}
		$outfile2 = "$ATOMS/single_chain/". $outfile;
		if ( ! open ( OUTFILE, ">$outfile2") ) {  
		    die "cannot open $outfile2 file\n" ;
		} else {
		    print " writing to  $outfile2 \n" ;
		}

		do {
		    if ($line1=~ /ATOM(\s)+(\d)+(\s)+(\w)+(\s)+(\D){3}(\s)+/ ) { 
			print OUTFILE $line1;
		    }
		} while ( defined($line1 = <INFILE>) );
		close OUTFILE;
	    }

	} elsif ($type == $MULTIPLE)  {
	    # if there are multiple chains,
	    # need to decide if they are different:

	    while (($key,$value) = each %chain) {
                        delete $chain{$key};
            }	    
	    while (defined (pop @seq)) {;}
	    print " ** ",  $line1; 
	    #die;
	    #do {
		
		#if ($line1=~ /SEQRES(\s)+(\d)+(\s)+(\w)+(\s)+(\d)+(\s)+(\D){3}/ ) {
		    $current = -1;
		    do { 
			@aux2 = split (' ', $line1);
			if ($current < 0) {
			    for ($ctr=0; $ctr <= $#chainname; $ctr++) {
				if ( $aux2[2] =~ $chainname[$ctr]){
				    $current = $ctr;
				    last;
				}
			    }
			}
			if ($current <0 ) { # if current is still zero - problem
			    die "undeclared chain  found in $fileName.\n"; 
			}
			# end of sequence / beginning of new sequence: 
			if ($aux2[2] !~ $chainname[$current]) {
			    if ( !( exists $chain{join('',@seq)})  && $AA==1) {	
				$chain{join('',@seq)} = $current ; 
			        print "new  $chainname[$current]\n"; 
      			    }  else {
				print "found already $chainname[$current] \n"; 
			    }
			    
			    # empty the AA array
			    while (defined (pop @seq)) {;}
			    $current = -1;
		    
			}  
			if ( length ($aux2[4]) != 3 ) {# that is, if the sequence is not AA
			    $AA = 0;			   
			} else {
			    $AA = 1;
			    push @seq, @aux2[4..$#aux2];
			}
			$line1 = <INFILE>;
		       
		    } while ($line1 =~ /SEQRES(\s)+(\d)+(\s)+(\w)+(\s)+(\d)+(\s)+(\D){3}/ );
	   
	     
	   
		    if ((!exists $chain{join('',@seq)})   && $AA==1) {
			$chain{join('',@seq)} = $current ;
			print "new  $chainname[$current]\n"; 
		    } else {
			print "found already $chainname[$current] \n"; 
		    }
		    #last;
		#}
	    #} while ( defined($line1 = <INFILE>) );
	    

            $nochains =  keys %chain;
           print join(' ', @chainname),"\n";
	    print " there are $nochains different AA  chains: ";
	    foreach (values  %chain ) {
		print $chainname[$_ ]," ";
	    } 
	    print "\n"; 
	    if ( $nochains == 1 ) {
		if ( ! -e "$ATOMS/multiple_chains/" ) {
		    mkdir ("$ATOMS/multiple_chains/" , 0777) ||
			die "Cannot mkdir $ATOMS/multiple_chains/ .\n";
		}
		$dir=  "$ATOMS/multiple_chains/";
	    } else {
		if ( ! -e "$ATOMS/unique_chains/" ) {
		    mkdir ("$ATOMS/unique_chains/" , 0777) ||
			die "Cannot mkdir $ATOMS/unique_chains/ .\n";
		}
		$dir=  "$ATOMS/unique_chains/";
	    }

	    # construct all the filenames I need (one for each chain)
            # clenup
	    while (defined (pop @outfile3)) {;}
	    foreach (values  %chain ) {
		# print STDERR "*  ", $_ ,"\n"; 
		$found = 0;
		# construct the filename:
		@ofname = split('\.', $outfile);
		$aux = pop (@ofname);
		push (@ofname, $chainname[$_]);
		$outfile3 [$_] = join ('', @ofname);
		$outfile3 [$_] = $dir.$outfile3[$_].'.'.$aux;
		$found    [$_] = 0; #the chains might be repeated ... skip repeats
	    }   
	    print join(' ', @outfile3),"\n"; 

	    # recognize chains and print them to separate file

	    # to help me open the file only when I
	    # first see the chain, and to keep track of
	    # the current chain:
	    $current = -1;

	    do {
		if ($line1=~ /ATOM(\s)+(\d)+(\s)+(\w)+(\s)+(\D){3}(\s)+/ ) { 
		   
		    @aux2 = split (' ', $line1);
		    if ( $current < 0) { #this chain first seen 
		        foreach (values  %chain ) {
			    if ( $aux2[4] =~ $chainname[$_]){
				$current = $_;
				last;
			    }
			}
			if ( $current < 0) {
			    next; # maybe some DNA chain or something
			}
			if (! $found[$current] ) {
			    if (! open ( OUTFILE, ">$outfile3[$current]") ) {  
				die "cannot open $outfile3[$current] file\n" ;
			    } else {
				#print "$current : writing to  $outfile3[$current] \n" ;
			    }
			}
			
		    }
		    
		    if ( $aux2[4] =~ $chainname[$current] ){
			if ( ! $found[$current] ) {
			    print OUTFILE $line1;
			}
		    } else { # new chain
			if ( ! $found[$current] ) {
			    $found[$current] = 1;
			    close OUTFILE;
			}
			$current = -1;
		    }
		     
		}
	    } while ( defined($line1 = <INFILE>) ) ;
		
	    
	        
	    
	} elsif ($type == $THRY ) {
	    if ( ! -e "$ATOMS/thry/" ) {
		mkdir ("$ATOMS/thry/" , 0777) ||
		    die "Cannot make $ATOMS/thry/ .\n";
	    }
	    link "$PDBFILES/$fileName", "$ATOMS/thry/$fileName";
	} elsif ($type == $NMR ) {

	    if ( ! -e "$ATOMS/nmr/" ) {
		mkdir ("$ATOMS/nmr/" , 0777) ||
		    die "Cannot make $ATOMS/nmr/ .\n";
	    }
	    link "$PDBFILES/$fileName", "$ATOMS/nmr/$fileName";
        } else {
	    print "Warning: file type not assigned.\n"; 
	}



        

	close INFILE;
    }
}
