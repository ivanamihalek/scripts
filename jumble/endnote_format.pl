#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

$block = "";

print "*Generic\n";
print "Reference Type\tAuthor\tYear\tTitle\tSecondary Title\tVolume\tPages\n";

while ( <> ) {
    if ( /\S/ ) {
	chomp;
	$block .= $_;
    } else {
	@aux = split /\.\s/, $block;

	$names = $aux[1];
	$names =~ s/(\s\w)\,/ $1 \/\/ /g;
	$title =  $aux[2];
	($year, $journal) = split ';',  $aux[3];
	($volume, $pages)  = split ':',  $aux[4];
	$pages =~ s/\.//g;
=pod
	print "names:  $names \n";
	print "title:  $title \n";
	print "year:   $year \n";
	print "journal:   $journal \n";
	print "volume:   $volume \n";
	print "pages:   $pages \n\n\n";
=cut
        print "Journal Article\t$names \t$year \t$title \t$journal \t$volume\t$pages \n"; 
	$block = ""
    }
}
