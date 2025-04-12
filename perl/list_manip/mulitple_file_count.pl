#! /usr/bin/perl -w

(@ARGV>1) || die "Usage: $0  <$column> <file1> <file2> ... \n";

$column = shift @ARGV;
$column --;

@files = @ARGV;


foreach $file (@files) {
     open (IF, "<$file") || die "Cno $file: $!\n";
    
    while ( <IF> ) {
	next if ( !/\S/);
	chomp;
	@aux = split;
	$name = $aux[$column];

	if (defined $found{$name} ) {
	    $found{$name} +=1;
	    push  @{$found_in_file{$name}},  $file;
	    #print "$name appears $found{$name} times.\n";
	    #print "$name\n";
	} else {
	    $found{$name} = 1;
	    @{$found_in_file{$name}} = ($file);
	}

    }
    close IF;
}

foreach $name( keys %found ) {
    next if ( @{$found_in_file{$name}} > 1);
    foreach  $file (  @{$found_in_file{$name}} ) {
	(defined $uniq_per_file{$file} ) || 
	    (@{$uniq_per_file{$file}} = ());
	push @{$uniq_per_file{$file}}, $name;
    }
}

foreach $name( keys %found ) {
    print "$name   $found{$name}    @{$found_in_file{$name}} \n";
}

print "\n\n";

foreach  $file ( keys %uniq_per_file ) {
    print "$file    @{$uniq_per_file{$file}}\n";
}
