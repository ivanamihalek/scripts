#!/usr/gnu/bin/perl -w
# Ivana, Oct 2001
# for all the pdb files passed from
# stdin create a directory with the
# same name, copyt the pdb file and chdir to it,
#  execute EasTrace and climb back to the initial directory
while (<STDIN>) {
    @files = split ;
    foreach $fileName ( @files ){
	@aux = split ('\.', $fileName);
	pop @aux; # get rid of the pdb extension
	$nameroot = join ('.',@aux) ;
	print $nameroot, "\n"; 
        if ( -e $nameroot ) {
	} else {
	    @cmmdarray = ('mkdir', $nameroot);
	    system (@cmmdarray); 
	}
        @cmmdarray = ('cp', '-f', $fileName,  $nameroot);
	print @cmmdarray, "\n"; 
	system (@cmmdarray); 
	chdir ($nameroot ) ||
	    die "cannot chdir to $nameroot\n";
       
        @cmmdarray = ('/home/protean5/imihalek/bin/EasyT', $nameroot,  "-nomessages");
	print @cmmdarray, "\n"; 
	system (@cmmdarray); 

	chdir (".." ) ||
	    die "cannot chdir to .. \n";
	
    }
}
