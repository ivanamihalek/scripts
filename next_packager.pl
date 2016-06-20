#! /usr/bin/perl -w

@ARGV>=3 ||
    die "Usage:  $0  <Bodamer ID> <gender> <affected> \n";
($boid, $gender, $affected)  = @ARGV;
$cmd = "find . -name $boid";
@lines = split "\n", `$cmd`;

if (@lines > 1) {
    print "multiple directories found for $boid:\n";
    foreach (@lines) {
	print "\t", $_;
    }
    exit(1);
}
$full_path = shift @lines;
chomp $full_path;
#print $full_path, "\n";

chdir $full_path;
$full_path =~ s/^\.\///;

@files = split "\n", `ls *.bam`;

if (@files > 1) {
    print "multiple bam file found for $boid:\n";
    foreach (@files) {
	print "\t", $_;
    }
    exit(1);
    
} elsif (@files == 0 )  {
    print "no bam files found for $boid\n";
    exit(1);
}

$bamfile = shift @files;

$seq_center_id = $bamfile;
$seq_center_id  =~ s/\.bam$//;

#print "$bamfile\n";
#print "$seq_center_id\n";

$md5file = "$seq_center_id.md5";

if (! -e $md5file ||  -z $md5file) {
    `md5sum $bamfile > $md5file`;
}

$checksum =  `cut -d ' ' -f 1   $md5file`;
chomp $checksum;

open ( OF, ">$boid.meta") || die "Error opening $boid.meta: $!\n";

print OF  "investigator_name,sample_name,subject_name,gender,affected,bam_path,bam_checksum\n";
print OF join (",", ("Bodamer", $boid, $boid, lc $gender eq "female" ? "F":"M")) , ",";
print OF  join (",",  (lc $affected eq "affected" ? "Y":"N", "s3://bch-nextcode/ivana-bodamer/$full_path/$bamfile", $checksum) ) , "\n";
close OF;

print "meta file foor $boid can be found in $full_path/$boid.meta\n";


