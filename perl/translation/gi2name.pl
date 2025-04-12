#! /usr/bin/perl -w 
# Ivana, 2002
# change all the instances of sequnece index with tax name
# the output is msf specific
defined $ARGV[0] &&  defined $ARGV[1] ||
    die "Usage: gi2name.pl <table_file_name> <translatee_name> [<old name col>  <new name col>].\n"; 
$table = $ARGV[0]; 
$translatee =  $ARGV[1]; 

$old_name_col = 0; 
$new_name_col = 1; 
if ( defined  $ARGV[3] ) {
    $old_name_col = $ARGV[2] - 1; 
    $new_name_col = $ARGV[3] - 1; 
}

$msf = 0;
@aux = split '\.', $translatee;
if ( $aux[$#aux] =~ 'msf' ) {
    $msf = 1;
}


open ( TABLE, "<$table") ||
    die "Cno $table: $!\n";

while ( <TABLE>) {
    next if ( !/\w/);
    chomp;

    @aux = split;
    $key = $aux[$old_name_col];
    if ( defined  $aux[$new_name_col] ) {
	$val = $aux[$new_name_col];
    
	#$val = join ('_', @aux[1 .. $#aux]);
	$transl_table{$key} = $val;
    }
}
close TABLE;

#slurp in the input as a single string
open ( FH, "<$translatee" ) ||
    die "Cno $translatee: $!. \n";

undef $/;
$_ = <FH>;
$/ = "\n";

close FH;

foreach $index ( keys %transl_table){
    $name =  $transl_table{$index}; 
    $index =~ s/\|//g;
    $_  =~ s/\|//g;
    if ( /(\W)($index)(\W)/ ) {
	s/(\W)($index)(\W)/$1$name$3/g ;
    }
}

if ( !($msf) ) {
    print;
    exit;
}

# ****** MSF SPECIFIC *******
@aux = split ('\n', $_);

for $line ( @aux) {
    if ($line =~ /^\w/) {
	@aux2 = split (' ', $line);
	printf ("%-31s ", $aux2[0] );
	for $i ( 1 .. $#aux2 ) {
	    printf ("%-10s ", $aux2[$i]);
	}
	print "\n";
    } else {
	print "$line\n";
    }
}

print "\n";
