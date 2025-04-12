#! /usr/bin/perl -w

use strict;

my $home = `pwd`; chomp $home;


sub check_date (@);

my $level = 0;
check_date ($home);

sub check_date ( @) {

    my $cwd = shift @_;
    my $file;
    my @files;
    my @directory = ();
    my $ctr;
    my @file_info = ();
    my ($month, $day, $yr);

    $level ++;

    chdir $cwd;
=pod
    for $ctr ( 1.. $level ) {
	print " ** ";
    }
    print "  $cwd********************\n";
=cut
    @files = <*> ;

    foreach $file ( @files ) {
	$file = quotemeta $file;
	if (  -d $file ) {
	    push @directory, $file; # otherwise I lose info about what is directory
	} else {
	    @file_info = split " ",  `ls -l $file`;
	    ($month, $day, $yr) = @file_info[5..7];
	    if ( $yr eq "2005" && $month eq "Jul") {
		print "@file_info[5..7] $cwd/$file_info[8]\n";
	    }
	}
    }

    foreach $file ( @directory ) {
	check_date ("$cwd/$file");
	
    }

    chdir $cwd;
    #print ">>>>>>>>>>>>>>>>>>  level $level done\n";
    $level --;
}
