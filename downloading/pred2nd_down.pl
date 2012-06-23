#! /usr/bin/perl -I/home/ivanam/perlscr/

use Simple;		#HTML support

#$httpstr  ="http://users.soe.ucsc.edu/~karplus/predict-2nd/";
$httpstr  ="http://users.soe.ucsc.edu/~karplus/ultimate/";


$retfile = get $httpstr	|| "";

$retfile =~ s/\<.+?\>/ /g;
$retfile =~ s/\&gt\;/\>/g;
$retfile =~ s/\&gt\;/\>/g;
$retfile =~ s/\&nbsp\;//g;
$retfile =~ s/\&nbs//g;
$retfile =~ s/\n/@/g;
$retfile =~ s/\<.+?\>/ /g;

@lines = split '@', $retfile;
($name, $date, $time, $size) = ();
@dirs  = ();
foreach $line (@lines ) {
    next if ( $line !~ /\S/ );
    next if ( $line =~ /Index/ );
    next if ( $line =~ /modified/ );
    next if ( $line =~ /Directory/ );
    next if ( $line =~ /Apache/ );
    next if ( $line =~ /README/ );
    ($name, $date, $time, $size) = split " ", $line;
    if ( $name =~ /\/$/ ) {
	push @dirs, $name;
    } else {
	( -e "src/$name" ) && next;
	print "$name\n";
	$filehttp = $httpstr.$name;
	$retfile = ""; 
	$retfile = get $filehttp || "";
	open (OF, ">src/$name") || die "Cno src/$name: $!\n";
	print OF $retfile;
	close OF;
    }
}

$home = `pwd`;
chomp $home;

foreach $dir ( @dirs ) {

    next if ( $dir =~ /bin/);
    next if ( $dir =~ /objs/);
    next if ( $dir =~ /testing/);
    next if ( $dir =~ /CVS/);

    (-e $dir) || `mkdir $dir`;

    chdir $home;
    chdir $dir;
    $dirstr = $httpstr.$dir;

    $retfile = get $dirstr	|| "";
    
    $retfile =~ s/\<.+?\>/ /g;
    $retfile =~ s/\&gt\;/\>/g;
    $retfile =~ s/\&gt\;/\>/g;
    $retfile =~ s/\&nbsp\;//g;
    $retfile =~ s/\&nbs//g;
    $retfile =~ s/\n/@/g;
    $retfile =~ s/\<.+?\>/ /g;

    @lines = split '@', $retfile;
    ($name, $date, $time, $size) = ();
    foreach $line (@lines ) {
	next if ( $line !~ /\S/ );
	next if ( $line =~ /Index/ );
	next if ( $line =~ /modified/ );
	next if ( $line =~ /Directory/ );
	next if ( $line =~ /Apache/ );
	next if ( $line =~ /README/ );
	($name, $date, $time, $size) = split " ", $line;
	if ( $name =~ /\/$/ ) {
	    push @dirs, $name;
	} else {
	    ( -e $name ) && next;
	    print "$name\n";
	    $filehttp = $httpstr.$name;
	    $retfile = ""; 
	    $retfile = get $filehttp || "";
	    open (OF, ">$name") || die "Cno $name: $!\n";
	    print OF $retfile;
	    close OF;
	}
	
    }
    

}
