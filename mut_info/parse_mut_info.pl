#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

@aux = ();
$title = ""; 
$change = ""; 
$structure = ""; 
$function ="";
$disease ="";
$field = 0;
$line_ctr = 0;
while ( <> ) {
    $line_ctr++;
    next if ( !/\w/ );
    chomp;
    if ( /Summary/ ){
	if ( $title ) {
	    process ();
	}
	$title = $_;

    } else {

	$keyword = substr $_, 0, 15 ;
	if ( $keyword =~ /[A-Z]+/ ) {
	    #print "**$keyword**\n";
	    if ( $keyword =~ /ENTRY/ ) {
		if ( $change ) {
		    process();
		}
		@aux = split;
		$entry_id  = $aux[1];

	    } elsif ( /CHANGE/ ) {

		@aux = split;
		$change  = join (' ', @aux[1 .. $#aux]);
		$field = 1;

	    } elsif (/STRUCTURE/ ){
		@aux = split;
		$structure  = join (' ', @aux[1 .. $#aux]);
		$field = 2;

	    } elsif (/FUNCTION/ ) {
		@aux = split;
		$function  = join (' ', @aux[1 .. $#aux]);
		$field = 3;

	    } elsif (/DISEASE/ ) {
		@aux = split;
		$disease  = join (' ', @aux[1 .. $#aux]);
		$field = 4;
	    } else {
		$field = 0;
	    }
# i should have EXPRESSION field here too
	} else {
	    if ( $field == 1 ) {
		$change .= "\n".$_;
	    } elsif ($field == 2 ) {
		$structure .= "\n".$_;
	    } elsif ($field == 3) {
		$function .= "\n".$_; 
	    } elsif ($field == 4) {
		$disease .= "\n".$_; 
	    }
	}
    }
}   


process();


print "\n\n\n";

open (ME, ">mut.seq_epitope") ||
    die "Cno mut.seq_epitope: $!. \n";
open (LIT, ">lit_entries") ||
    die "Cno lit_entries: $!. \n";
foreach $number (0 .. $#crit) {
    if ( defined $crit[$number] ) {
	print ME  "$number  $crit[$number] \n"; 
	#print "$number \n"; 
	print LIT "$number  $crit[$number]  $lit[$number]\n";
    }
}

close ME;
close LIT;




sub process () {

	if ( $change !~ "-" &&  $change !~ /insertion/ &&  
	     $change !~ /deletion/ && $change !~ /termination/ &&
	     ( $structure =~ /\[0\]/ ||  $function =~ /\[0\]/ || $disease  #)  ){
              ||$structure =~ /\[\- \-/ ||  $function =~ /\[\- \-/)  ){

	 
	    $title =~ /\"(\w+)\s(\d+)\"/; 
	    $number = $2;
	    $name = $1;

	    @lines = split '\n', $change;
	    foreach $line ( @lines) {
		$line =~ /(\w+)\s+\d+(\w+)/;
		if ( $1 =~ $name ) {
		    print "\n\nline: $line_ctr\n$number $name\n";
		    if ( ! defined $crit[$number]) {
			$crit[$number] = $name;
			$lit[$number] = $entry_id;
		    } else {
			$lit[$number] .= "  ";
			$lit[$number] .= $entry_id;
		    }
		    print "$change\n";
		    print "$entry_id\n";
		    if ( $function  ) {
			print "function:   $function\n";
		    }
		    if ( $structure  ) {
			print "structure:   $structure\n";
		    }
		    if ( $disease  ) {
			print "disease:   $disease\n";
		    }
		}
	    }
	}

	$change = ""; 
	$structure = ""; 
	$function ="";
	$disease ="";
	$number = "";
	$name = "";
	$field = 0;
	

}
