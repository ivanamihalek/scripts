#! /usr/bin/perl -w

# this is geared toward the way the ensembl dump is organized

@ARGV ||
    die "Usage:  $0  <file name> \n";

$filename = $ARGV[0];
open (IF, "<$filename" ) 
    || die "Cno $filename: $!.\n";

$home = `pwd`; chomp $home;
while ( <IF> ) {
    chomp;
    ($dbname) = split;
    print "$dbname\n";
    chdir $home;
    chdir $dbname;

    $cmd = "mysqladmin -u root create $dbname";
    (system $cmd) && die "error running $cmd\n";

    $cmd = "mysql -u root $dbname < $dbname.sql";
    (system $cmd) && die "error running $cmd\n";

    $cmd = "mysqlimport -u root --fields_escaped_by=\\\\ $dbname -L *.txt";
    (system $cmd) && die "error running $cmd\n";

}

close IF;
