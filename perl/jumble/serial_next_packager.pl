#! /usr/bin/perl -w
use strict;

@ARGV>=3 ||
    die "Usage:  $0  <table (tab sep)> <source path> <target path> \n";

my ($table, $source_path, $target_path) = @ARGV;

foreach ($table, $source_path, $target_path) {
    (-e $_) || die "$_ not found\n";
}

############################
# read in the table
my %other_id = ();
my %gender = ();
my %affected = ();

my @id_lines = split "\t", $table;

foreach (@id_lines) {
    die ("Check out the table format.\n");
    chomp;
    my ($boid, $oth, $gen, $aff) = split "\t";
    $other_id {$boid} = $oth;
    $gender   {$boid} = $gen;
    $affected {$boid} = $aff;
}

###########################
# which bamfiles are
# provided  in this source dir?
my %source_bam = ();
foreach my $boid (keys %other_id) {
    my $other = $other_id{$boid};
    my $cmd = "find $source_path -name $other.bam";
    my @lines = split "\n", `$cmd`;
    if (@lines > 1) {
	print "multiple bamfiles found for $other in $source_path:\n";
	foreach (@lines) {
	    print "\t", $_;
	}
	exit(1);
    } elsif  (@lines == 1) {
	$source_bam{$boid} = pop @lines;
	chomp $source_bam{$boid};
    }
}

###########################
# main loop
foreach my $boid (keys %other_id) {
    
    # if the bamfile is not on the provided device
    # (supposedly mounted on $source_path),
    # then move on
    defined  $source_bam{$boid} || next;

    # check whether we have it already, by any chance
    my $cmd = "find $target_path -name $boid";
    my @lines = split "\n", `$cmd`;

    if (@lines > 1) {
	print "multiple directories found for $boid in $target_path:\n";
	foreach (@lines) {
	    print "\t", $_;
	}
	exit(1);
    }
    my $full_path = shift @lines;
    chomp $full_path;
    #print $full_path, "\n";

    chdir $full_path;
    $full_path =~ s/^\.\///;

    my @files = split "\n", `ls *.bam`;
    # error state
    if (@files > 1) {
	print "multiple bam files found for $boid:\n";
	foreach (@files) {
	    print "\t", $_;
	}
	exit(1);
    } 
    my $bamfile;
    my $seq_center_id;
    # bamfile for this $boid already exists
    # what if it is in a wrong directory?
    # outside the scope of this script
    if (@files == 1 )  {
	$bamfile = shift @files;

	$seq_center_id = $bamfile;
	$seq_center_id  =~ s/\.bam$//;
        if ( $seq_center_id ne $other_id{$boid}) {
	    print "bam file found for $boid: ";
	    print $bamfile;
	    print ", but it does not match the expected id: ";
	    print $other_id{$boid}, "\n";
	    exit(1);
	}
	if (-z $bamfile) {
	    print "bam file found for $boid: ";
	    print $bamfile;
	    print ", but it appears to be empty - will delete.\n";
	    `rm $bamfile`;
	} else {
	    next;
	}
    }

    # no bamfile yet - copy it from the source dir
    $seq_center_id = $other_id{$boid};

    # make the directory 
    my $yr = "20". substr ($boid, 2, 2);
    my $caseno = substr ($boid, 4, 2);
    my $dir = join "/", ($target_path, $yr, $caseno, $boid);
    (-e $dir) || `mkdir -p $dir`;
    chdir $dir;

    # copy everything with the seq_center_id to the target dir
    my $root_name = $source_bam{$boid};
    $root_name =~ s/\.bam$//g;
    `cp $root_name/* .`;

    # make  md5 file if it does not wxit yet
    my $md5file = "$seq_center_id.md5";

    if (! -e $md5file ||  -z $md5file) {
	`md5sum $bamfile > $md5file`;
    }

    my $checksum =  `cut -d ' ' -f 1   $md5file`;
    chomp $checksum;

    open ( OF, ">$boid.meta.csv") || die "Error opening $boid.meta.csv: $!\n";

    print OF  "investigator_name,sample_name,subject_name,gender,affected,bam_path,bam_checksum\n";
    print OF join (",", ("Bodamer", $boid, $boid, lc $gender{$boid} eq "female" ? "F":"M")) , ",";
    print OF  join (",",  
		(lc $affected{$boid} eq "affected" ? "Y":"N", 
		 "s3://bch-nextcode/ivana-bodamer/$full_path/$bamfile", $checksum) ) , "\n";
    close OF;

    print "meta file foor $boid can be found in $full_path/$boid.meta.csv\n";
}

