#! /usr/gnu/bin/perl -w
# Ivana, Mar 2002
# for each ID in the msf file:
# 1) find gi in the corresponding blastp file
# 2) translate GenBank ID (gi) into Taxonomy ID (using table)
# 3) download tax info from the ncbi server based on taxonomy id

# needs some libs; usage : perl -I/home/protean2/LSETtools/utils  taxdownload.pl

$transl_table_path = "/home/protean5/imihalek/ppint/taxonomy/gi_taxid_prot.dmp";
$names_table_path  = "/home/protean5/imihalek/ppint/taxonomy/names.dmp";

(defined $ARGV[0] && defined $ARGV[1] ) ||
    die "usage:  perl -I/home/protean2/LSETtools/utils  ~/perlscr/taxdownload.pl <msf_file> <blastp_file>\n";  

use Simple;		#HTML support
use IO::Handle;         #autoflush

$msf_file = $ARGV[0];
@aux = split ('.', $msf_file);
pop @aux; # get rid of msf extension
$spec_html_file    = join ('.' ,( @aux,"html")); 
open ( MSF_FILE, "<$msf_file") ||
    die "could not open $msf_file\n"; 

$spec_html_file = $msf_file.".html"; 
open ( SPEC_HTML, ">$spec_html_file") ||
    die "could not open $spec_html_file\n"; 
print SPEC_HTML "<html>\n\n";

print SPEC_HTML "<title> Taxonomy info for  $ARGV[0] </title>\n";
print SPEC_HTML "<h1> Taxonomy info for  $ARGV[0] </h1>\n";

sub find_color () {
    if ( $tax_info =~ "Bacteria" ) {
	$color = "blue";
	$bacteria_ct ++;
    } elsif ( $tax_info =~ "Metazoa;" ) {
	$color = "red";
	$metazoa_ct ++;
    } elsif ( $tax_info =~ "Fungi;" ) {
	$color = "#FF9933";
	$fungi_ct ++;
    } elsif ( $tax_info =~ "Viridiplantae;" ) {
	$color = "#006600";
	$plantae_ct ++;
    } elsif ( $tax_info =~ "Archaea" ) {
	$archaea_ct ++;
	$color = "#CC6699";
    } elsif ( $tax_info =~ "Viruses" ) {
	$color = "yellow";
	$virus_ct ++;
    } elsif ( $tax_info =~ "Euglenozoa" ||  
	      $tax_info =~ "Alveolata"  ||  
	      $tax_info =~ "Mycetozoa") {
	$color = "cyan";
	$protoctista_ct ++;
    } else {
	$color = "grey";
	$other_ct ++;
    }
}

sub retrieve_tax_id () {

    $tax_id = 0;
    if ($gi > 0 ) {
	$gi0 = 0;

	# open gi --> tax id translation table & read it in
	open ( TRANSLATION_TABLE,"<$transl_table_path") ||
	    die "could not open $transl_table_path\n"; 

	while ( <TRANSLATION_TABLE> ) {
	    ($gi0, $tax_id) = split;
	    last if ($gi0 == $gi );
	}
	close TRANSLATION_TABLE;
	($gi0 == $gi) ||
	    warn "could not locate $gi in $transl_table_path\n";


    }  elsif ( $spec_name ) {
	open (NAMES_TABLE, "<$names_table_path") ||
	    die "could not open  $names_table_path.\n";
	while ( <NAMES_TABLE>) {
	    chomp;
	    @aux = split ('\|', $_);
	    if ( (lc $aux[1])  =~  (lc $spec_name) ) {
		$aux[0] =~ s/\s*(\d+)\s*/$1/g;
		$tax_id = $aux[0];
		last;
	    }
	}
	close NAMES_TABLE;

    }
}


sub download_lineage() {
    
    # ask NCBI taxonomy site for the taxonomy info
    $query_string  =  "http://www.ncbi.nlm.nih.gov/htbin-post/Taxonomy/wgetorg?mode=Info";
    $query_string .= "&id=$tax_id";
    $query_string .= "&lvl=3&keep=1&srchmode=5&unlock&lin=f";
    $tax_info = get $query_string || "";

    # extract lineage:
    if ( $tax_info ) {
	# find species name
	$tax_info =~ /<title>Taxonomy browser \((.*)\)<\/title>/;
	$ret_spec_name= $1;
	# get rid of the HTML tags
	while ( $tax_info =~ s/(.*)<(.*)>(.*)/$1$3/g ){};
	# get rid of new lines
	$tax_info =~ s/\n//g ;
	# zoom in on info that I need here
	if ($tax_info =~/Comments and References/ ) {
	    $tax_info =~ s/.*Lineage\( full \)(.*)Comments and References.*/$1/ ;
	} elsif ($tax_info =~/ICTV/)  {
	    $tax_info =~ s/.*Lineage\( full \)(.*)ICTV.*/$1/ ;
	} else {
	    $tax_info =~ s/.*Lineage\( full \)(.*)Nucleotide.*/$1/ ;
	}
	$tax_info = $ret_spec_name.": ".$tax_info;
    } else {
	print "lineage  retrieval failure.\n";
    }
    
}

$bacteria_ct = 0;
$metazoa_ct  = 0;
$plantae_ct  = 0;
$fungi_ct  = 0;
$archaea_ct  = 0;
$virus_ct  = 0;
$protoctista_ct  = 0;
$other_ct  = 0;



$blastp_file = $ARGV[1];
$gi = 0;
$spec_name ="";
$tax_id = 0;
$tax_info = "";

while ( <MSF_FILE> ) {
    if ( /Name:\s+(.*)\s+Len/ ) {
	$some_id = $1;
	next if ($some_id =~ /pt_/);
	@aux = split ( '-', $some_id); 
	pop @aux;
	$some_id = join ( '', @aux);
	print "\n\n\n ================================================\n\n";
	print "found in msf:  $some_id ($1)\n";
	# now go to blastp and find the corresponding 
	open ( BLASTP_FILE, "<$blastp_file") ||
	    die "could not open $blastp_file\n"; 
	$spec_name = ""; 
	$gi = 0;
	while ( <BLASTP_FILE> ) {
	    if (/^>/  && $_ =~ $some_id){
		print "found in blastp: $_ ";
		chomp; 
		$aux_str = $_;
		while (  <BLASTP_FILE> ) {
		    last if (/Length/) ;
		    chomp;
		    $aux_str .=  $_;
		}
		last;
	    }
	}
	# see if some description is avaliable
	if ( $aux_str =~  /\)([^>^\]^\[]+)\[/ ) {
	    $description = $1;
	} else {
	    $description = "";
	}
        # check for  GenBank ID
	if ( $aux_str =~  /gi\|+(\d+)/ ){
	    $gi = $1;
	# else go for species name
	} elsif (  $aux_str =~ /\[(\w+\s)\s*(\w+)/ ) {
	    $spec_name = $1.$2;
	} else {
	    print "warning: could not locate name";
	    print " nor gi for $some_id in $blastp_file. \n";
	}
	close BLASTP_FILE;
	print "specie: $spec_name    gi: $gi\n";
	print "description: $description\n";
	retrieve_tax_id ();
	if ( $tax_id > 0 ) {
	    if ( exists $species_found{$tax_id} ) {
		$species_count {$tax_id} += 1;
		$tax_info = $species_found{$tax_id};
	    } else {
		$species_count {$tax_id}  = 1;
		download_lineage();
		$species_found {$tax_id}  = $tax_info; 
	    }
	    find_color ();
	    @aux = split (';', $tax_info );
	    print SPEC_HTML "<br><font color=$color> $some_id: &nbsp;&nbsp; $tax_id: &nbsp;&nbsp;   \n";
	    print SPEC_HTML " &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;";
	    print SPEC_HTML "$aux[0]; $aux[1]; $aux[2]; $aux[3]; $aux[4];    </font> \n";
	    print SPEC_HTML "<br> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;";
	    print SPEC_HTML " &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;";
	    print SPEC_HTML " &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;";
	    print SPEC_HTML  " $description \n";
	    SPEC_HTML -> autoflush(1);
	} else {
	    print "tax id retrieval failure for $spec_name ($gi).\n";
	}
    }
}

close MSF_FILE; 
print SPEC_HTML "<br><br>\n";
print SPEC_HTML "<b> Species found: </b> \n";
print SPEC_HTML "<ul>\n";
foreach $spec ( keys %species_found ) {
    print "\n  ***********  \n";
    $count  = $species_count{$spec};
    print  "$spec found  $count times.\n";
    @aux = split  (':', $species_found{$spec});
    print SPEC_HTML "<li> $aux[0] found $count times";
}
print SPEC_HTML "</ul>\n";

print SPEC_HTML "<b> Group breakdown: </b> \n";
print SPEC_HTML "<ul>\n";
print SPEC_HTML "<li> viruses:   $virus_ct \n";
print SPEC_HTML "<li> archaea:  $archaea_ct \n";
print SPEC_HTML "<li> bacteria: $bacteria_ct \n";
print SPEC_HTML "<li> metazoa: $metazoa_ct \n";
print SPEC_HTML "<li> plantae: $plantae_ct  \n";
print SPEC_HTML "<li> fungi:   $fungi_ct \n";
print SPEC_HTML "<li> protoctista:   $protoctista_ct \n";
print SPEC_HTML "<li> unparseable: $other_ct \n";
print SPEC_HTML "</ul>\n";


print SPEC_HTML "\n</html>\n";
close SPEC_HTML;
