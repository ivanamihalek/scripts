#! /usr/bin/perl -w

use Net::FTP;

sub process_faa ( @ );

#$filename = "spec_names";
$filename = "tmp";
open (IF, "<$filename" ) 
    || die "Cno $filename: $!.\n";

@all_species = ();
while ( <IF> ) {
    chomp;
    push @all_species, $_;

}

close IF;
    
$ftp = Net::FTP->new("ftp.ncbi.nih.gov", Debug => 0)
	or die "Cannot connect to ftp.ncbi.nih.gov: $@";

$ftp->login("anonymous",'-anonymous@')
	or die "Cannot login ", $ftp->message;

$ftp->binary;

foreach $specie (@all_species) {
    
    print "$specie\n";

    if ( -e $specie ) {
	print "\t ", $specie, " file exists\n";
    } else {
	if ( ! $ftp->cwd("/genomes/$specie/") ) {
	    print "Cannot change working directory ", $ftp->message;
	    next;
	}
	@dir_list = $ftp->dir;
	foreach $line ( @dir_list ) {
	    $is_dir = ( $line =~ /^d/ );
	    @aux = split " ", $line;
	    $file = pop @aux;

	    if ( $is_dir ) {
		# go through chromosome subdirs
		print "$line\n";
		($file =~ /^CHR/ || $file =~ /\_/  ) || next;

		if ( ($file =~ /\_/)  &&  (-e $file) ) {
		    print "\t ", $file, " file exists\n";
		    next;
		}
	
		if ( ! $ftp->cwd("/genomes/$specie/$file") ) {
		    print "Cannot change working directory ", $ftp->message;
		    next;
		}
		@subdir_list = $ftp->dir;
		foreach $subline ( @subdir_list) {
		    @aux = split " ", $subline;
		    $subfile = pop @aux;
		    if ( $file =~ /^CHR/ ) {
			process_faa ($specie, $subfile);
		    } else {
			process_faa ($file, $subfile);
		    }
		}
		
		
	    } else {
		# look for amino acid fasta files right here
		if ( $file eq "protein.fa.gz") {
		    if ( ! $ftp->get("protein.fa.gz") ) {
			print  "get failed for protein.fa.gz:", 
			$ftp->message, "\n";
			next;
		    }
	
		    system ( "gunzip protein.fa.gz" ) && 
			die "error uncompressing protein.fa.gz.\n";
	
		    `mv  protein.fa  $specie`;
		} else {
		    process_faa ($specie, $file);
		}
		
	    }

	}
	#exit;
    }
}

##################################################
sub process_faa ( @ ) {

    my ($specie, $file) = @_;

    if ( $file =~ /\.faa/) {
	print "\t downloading $file\n";
		    
	if ( ! $ftp->get($file) ) {
	    print  "get failed for $file: ", $ftp->message,"\n";
	    next;
	}
        (-e $specie) || `touch $specie`;
	`cat $file >> $specie`;
        `rm $file`;
    }

}
