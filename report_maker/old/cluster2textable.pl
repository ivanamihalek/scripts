#!/usr/bin/perl -w
sub wrap_up ();
# the color names should match colors used in cbc.pl, see color2word.pl
##################################################

@color_word = ("red", "blue", "yellow", "green", "purple", "azure", "turquoise", "brown", "coral",
	       "magenta", "LightSalmon", "SkyBlue", "violet", "gold", "bisque", "LightSlateBlue", "orchid", 
	       "RosyBrown", "MediumAquamarine", "DarkOliveGreen", "CornflowerBlue", "grey55", "burlywood", 
	       "LimeGreen", "tan", "DarkOrange", "DeepPink", "maroon", "BlanchedAlmond", "black");
##################################################

( defined $ARGV[1]) ||
    die "Usage:  cbc.pl <cluster_file>  <rank>   \n"; 
 
$cluster_file = $ARGV[0]; 
$rank         = $ARGV[1];

open ( CLUSTER_FILE, "<$cluster_file") || 
    die "cno $cluster_file\n";

$filename = "";
$home = `pwd`;
chomp $home;

@cluster = (());

# find the rank I need
while ( <CLUSTER_FILE> ) {
    next if ( /^\%/ );
    if ( /rank/ ) {
	/rank\:\s+(\d+)/;
	last if ( $rank == $1 );
    }
}

$filename    = "$cluster_file.rank=$rank.rs";
$cluster_ctr = 0;

while ( <CLUSTER_FILE> ) {
    next if ( /^\%/ );
    if ( /rank/ || /rho/ ) {
	last;
    } elsif (/isolated/) {
        $isolated = 1;
    } elsif (/cluster/) {
        $isolated = 0;
	$cluster_ctr++;
	if ( defined $cluster[$cluster_ctr] ) {
	     $cluster[$cluster_ctr] = ();
	}
    } else {
	@aux = split;
	if ( $chainname) {
	    for $i  (0 .. $#aux) {
		$aux[$i] .= ":$chainname";
	    }
	}
	if ( $isolated) {
	    for ($i=0; $i <= $#aux; $i++) {
		$cluster_ctr++;
		if ( defined $cluster[$cluster_ctr] ) {
		    $cluster[$cluster_ctr] = ();
		}
		$cluster[$cluster_ctr][0] = $aux[$i];
	    }
	} else {
	    push @{ $cluster[$cluster_ctr] },  @aux;
	}
	
    }

}
close CLUSTER_FILE;
wrap_up ();
exit 0;

##################################################




sub wrap_up (){

    if ( defined @cluster) {
	# sort the clusters by size
	%sizes = ();
	for ( $cluster_ctr=0; $cluster_ctr<=$#cluster; $cluster_ctr++) {
	    if ( defined $cluster[$cluster_ctr] ) {
		$sizes{$cluster_ctr} = $#{$cluster[$cluster_ctr]}+1;
	    }
	}
	@sorted = ();
	@sorted = sort { $sizes{$b} <=> $sizes{$a} } (keys(%sizes)) ;
	
	#print table header
    #	print " %\n%\n\\begin{table} \{\\small \n   \\begin\{tabular\}[h] \{l|r|l\} \n";
   	print " \{\\small \n   \\begin\{tabular\}[h] \{l|r|l\} \n";
      	print "   \{\\bf cluster color \}  &  \{\\bf size\}  &  \{\\bf member residues \}   ";
	print "\\\\  \n \\hline \\hline\\\\\n";	

        #print clusters in the order of decreasing size:
	for ( $cluster_ctr=0; $cluster_ctr<=$#cluster; $cluster_ctr++) {
	    if ( defined $sorted[$cluster_ctr] &&  defined $cluster[$sorted[$cluster_ctr]] ) {
		next if ( $sizes{$sorted[$cluster_ctr]} == 1 ); # skip isolated
		if ( $cluster_ctr >= $#color_word  ) {
		    $color_index = $#color_word;
		} else {
		    $color_index = $cluster_ctr;
		} 
		@current_cluster =  @{ $cluster[$sorted[$cluster_ctr]]};
		@lines = ();
		$line = $current_cluster[0];
		$ctr = 1;
		while ( $ctr <= $#current_cluster) {
		    if ( (length $line ) + 1 +  (length  $current_cluster[$ctr] ) <= 58) {
			$line .= ",".$current_cluster[$ctr];
		    } else {
			push@ lines, $line;
			$line = $current_cluster[$ctr];
		    }
		    $ctr++;
		}
		$line && push @lines, $line;
		print "$color_word[$color_index]  & ",  $#current_cluster+1, " &  $lines[0]\\\\\n";
		shift @lines;
		foreach $line ( @lines ) {
		    print " &  & $line \\\\\n";
		}
		print "\n \\hline\\\\\n";	

	    }
	}
    }
    #print table tail
     print "   \\end\{tabular\}\n \} \n";
    #print  " \\vspace{3mm}\n\\caption{\\label\{$reference_label\} }\n\\end{table} \n";
}

