#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

$reading = 0;
$descr   = "";
while ( <> ) {
    if ( !/\S/ ) {
	$reading = 0;
	process_entry();
    } else {
	if ( ! $reading ) {
	    $reading = 1;
	    $entry   = $_;
	} else {
	    $entry .= $_;
	}
    }
}
process_entry();




sub process_entry () {

    $entry =~ s/\n//g;
    @aux = split '\|', $entry;
    for $field (@aux) {
	($field_name, $field_value) = split '\:', $field;
	if ( $field_name =~ /Scientific name/ ) {
	    $name = $field_value;
	} elsif ( $field_name =~ /Lineage/ ) {
	    $lineage = $field_value;
	}
    }

    if ( $lineage =~ /bacil/i ) {
	$keyword = "bac";
    } else {
	$keyword = "x";
    }

    @aux = split ' ', $name;
    $short_name = uc (substr $aux[0], 0, 3);
    if ( defined $aux[1] ) {
	$short_name .= "_". uc (substr $aux[1], 0, 3);
    }
 
    print "$short_name    $keyword\n";

}
