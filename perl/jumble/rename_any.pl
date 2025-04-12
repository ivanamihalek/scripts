#!/usr/gnu/bin/perl -w 
while (<STDIN>) {
    @files = split ;
    foreach $fileName ( @files ){
	if ( $fileName =~ /\bad/) {
	    @aux =  split ('\.', $fileName);
	    pop @aux;
	    $newName = join ( @aux, ".seq");
	    rename ($fileName, $newName);
	}
    }
}
