#!/usr/gnu/bin/perl -w
# Ivana, Oct 2001
# for all the pdb files passed from
# stdin create descend to the directory with the
# same root name and execute TracePlus6.01
while (<STDIN>) {
    @files = split ;
    foreach $fileName ( @files ){
	@aux = split ('\.', $fileName);
	pop @aux; # get rid of the pdb extension
	$nameroot = join ('.',@aux) ;
	print $nameroot, "\n"; 
	chdir ($nameroot ) ||
	    die "cannot chdir to $nameroot\n";
	$i = $nameroot;
 
	@cmmdarray = ("clustalw -align  -infile=$i.input -output=gcg -outfile=$i.msf");
	print @cmmdarray, "\n"; 
	system (@cmmdarray)
	    || die "Error execing $cmmdarray[0]"; 

        @cmmdarray = ("TracePlus6.01  -p  $i.msf  -o  ET_$i  -m  blosum62  -t  -g  +profile -rs  -x  pt_$i  pt_$i.pdb  pt_$i.access" );
	print @cmmdarray, "\n"; 
	system (@cmmdarray); 
	chdir (".." ) ||
	    die "cannot chdir to .. \n";
	
    }
}
