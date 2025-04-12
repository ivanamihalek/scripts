#! /usr/bin/perl


@files =  ("struct.c",  "struct_complement_match.c", 
             "struct_descr_out.c", 
             "struct_grid.c",  "struct_linalg.c",  "struct_map.c", 
             "struct_quaternion.c",  
             "struct_read_cmd_file.c", "struct_representation.c", 
             "struct_recursive_output.c", "struct_scoring_fn.c", 
	   "struct_table.c",  "struct_table_input.c", 
	   "struct_input.c"); #, "struct_utils.c");

#@kwds = ("emalloc", "calloc", "dmatrix", "intmatrix", "chmatrix");
@kwds = ( "dmatrix");

foreach $file (@files) {
    $path = `ls */$file`; chomp $path;
    foreach $kwd (@kwds) {
	$ret =  `grep $kwd $path `;
	if ( $ret) {

	    printf "  $file  $path\n";
	    @ret_lines = split "\n", $ret;

	    $ret_free =   `grep free $path `;
	    @free_lines = split "\n", $ret_free;


	    foreach $line (@ret_lines ) {
		next if ( $line =~ /free/ );
		print "$line\n";
		$line =~ /(\w+)\s*\=\s*$kwd/;
		if (defined $1 ) {
		    $pointer_name = $1;
		    print "\t **** $pointer_name\n";
		    foreach $free_line (@free_lines) {
			if (  $free_line =~ /$pointer_name/ ){
			    print "\t #### $free_line\n";
			}
		    }
		    print "\n";
		}
	    }
	    print "\n\n";
	}
    }
}

