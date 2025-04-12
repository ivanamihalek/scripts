#! /usr/gnu/bin/perl -w

$ctr =0;
while ( <> ) {
    chomp;
    @aux  = split ':';
    $aux0 =  $aux[0];
    @aux  = split ('\.' , $aux0);
    pop @aux;
    $to_be_skipped[$ctr] = join ('\.', @aux);
    $ctr++;
}

@aux = split (' ', `ls`);
OUTER: foreach $file_name  (@aux) {
    foreach $skip ( @to_be_skipped) {
	if ( $file_name =~ $skip) {
	    rename $file_name, "$file_name.bad";
	    next OUTER;
	}
    }
   
}


