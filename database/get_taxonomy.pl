#!/usr/bin/perl -I/usr/local/lib/perl5/site_perl/5.8.0/sun4-solaris/DBI/
use DBI;

sub generic_query (@);
sub oneliner (@);

(@ARGV ) ||
    die "Usage: get_taxonomy.pl <stable_id_file>\n";

($infile) = @ARGV;

$db_info = "DBI:mysql:database=ensembl:host=localhost";
$db_usr = "";
$db_pswd = "";
$dbh = DBI->connect($db_info, $db_use, $db_pswd, 
		    {RaiseError=>1,PrintError=>1});

open (IF, "<$infile") ||
    die "Cno $infile: $!.\n";

while ( <IF> ) {
    
    next if ( ! /\S/  );
    @aux = split;
    $stable_id = $aux[0];

    $done = 0;

    $query  =  "SELECT taxon_id ";
    $query .=  " FROM  member WHERE stable_id = '$stable_id' ";
    ($taxon_id) = oneliner ($query);

    $query  =  "SELECT name ";
    $query .=  " FROM  ncbi_taxa_name WHERE taxon_id = '$taxon_id' ";
    # use only the first name
    ($ret_ptr) = generic_query($query);
    $name = shift @{$ret_ptr};
    print "$stable_id\t$name\t";

    @taxonomy = ();
    while ( !$done) {

	$query  =  "SELECT parent_id ";
	$query .=  " FROM  ncbi_taxa_node WHERE taxon_id = '$taxon_id' ";
	($parent_id) = oneliner ($query);
	if ( defined $parent_id ) {
	    $query  =  "SELECT name ";
	    $query .=  " FROM  ncbi_taxa_name WHERE taxon_id = '$parent_id' ";
	    # use only the first name
	    ($ret_ptr) = generic_query($query);
	    $name = shift @{$ret_ptr};
	    if ( $name eq "biota" ) {
		$done = 1;
	    } else {
		#print "\t $parent_id $name \n";
		push @taxonomy, $name;
		$taxon_id = $parent_id;
	    }
	} else {
	    $done = 1;
	}
    }

    while ( $name = pop @taxonomy ) {
	print "$name; ";
    }
    print "\n";


}

close IF;

#########################################

sub generic_query (@) {

    my $query = $_[0];
    my $sqlQuery;
    my $rv;
    my $ctr;
    my @ret_array;
    my @ret;

    $sqlQuery = $dbh->prepare($query) or 
	die "Can’t prepare $query: $dbh->errstrn";
    $rv = $sqlQuery->execute or 
	die "can’t execute the query: $sqlQuery->errstr";
    $ctr = 0;

    while( @ret = $sqlQuery->fetchrow_array()){
	@{$ret_array[$ctr]} = @ret;
	$ctr ++;
    }

    return @ret_array;

}

######

sub oneliner (@) {
    my $query = $_[0];
    my $sqlQuery;
    my $rv;
    my $ctr;
    my @ret_array;
    my @ret;

    $sqlQuery = $dbh->prepare($query) or 
	die "Can’t prepare $query: $dbh->errstrn";
    $rv = $sqlQuery->execute or 
	die "can’t execute the query: $sqlQuery->errstr";
    $ctr = 0;

    while( @ret = $sqlQuery->fetchrow_array()){
	$ctr ++;
	( $ctr > 1 ) && 
	    die "Error: unexpectedly\n$query\nreturns multiple lines\n";
	@ret_array = @ret;
    }

    return @ret_array;

}
