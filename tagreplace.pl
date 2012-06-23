#! /usr/gnu/bin/perl

# replace id tags in ps tree with group name
# (assuming I have my html file with the data

(defined $ARGV[0] && defined $ARGV[1] ) ||
    die "usage: tagreplace.pl <ps_file> <html_file>\n";  

$ps_file = $ARGV[0];
open (PS_FILE, "<$ps_file") ||
    die "could not open $ps_file.\n";

$html_file = $ARGV[1];

@aux = split ('\.', $ps_file);
pop @aux;
$new_ps_file = join (".", @aux);
$new_ps_file .= ".tax.ps";
print $new_ps_file, "\n"; 
open (NEW_PS_FILE, ">$new_ps_file") ||
    die "could not open $new_ps_file.\n";

while ( <PS_FILE>) {
    if ( /(.*)\((.*)\)(\s+ashow\s+)/ ) {
	next if ( $2 =~ "%" );
	@aux = split ( '-', $2);  
	pop @aux;
	$tag = join ( '-', @aux);  
	open (HTML_FILE, "<$html_file") ||
	    die "could not open $html_file.\n";
	$new_tag = " not found ";
	while ( <HTML_FILE>) {
	    if ( $_ =~ $tag ) {
		$next_line = <HTML_FILE>;
		if ( $next_line =~ /Bacteria/ ) {
		    $new_tag = "Bacteria"; 
		} elsif  ( $next_line =~ /Metazoa;/ ) {
		    $new_tag = "Metazoa";
		} elsif  ( $next_line =~ /Fungi;/ ) {
		    $new_tag = "Fungi";
		} elsif  ( $next_line =~ /Viridiplantae;/ ) {
		    $new_tag = "Plantae";
		} elsif  ( $next_line =~ /Archaea/ ) {
		    $new_tag = "Archaea";
		} elsif  ( $next_line =~ /Viruses/ ) {
		    $new_tag = "Viruses";
		} elsif  ( $next_line =~ /Euglenozoa/ 
			   || $next_line =~ /Alveolata/ 
			   || $next_line =~ /Mycetozoa/  ) {
		    $new_tag = "Protoctista";
		} 
		last;
	    }
	}
	close HTML_FILE;
	$_ = $1.'('.$new_tag.')'.$3
    }
    print  NEW_PS_FILE $_;
}


close PS_FILE;
close NEW_PS_FILE; 
