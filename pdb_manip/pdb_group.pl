#! /usr/bin/perl -w

sub compare (@);

$cutoff = 20;
$fasta     = "/home/ivanam/databases/pdb_seqres/pdb_seqres"; 
$muscle    = "/home/ivanam/downloads/muscle3.6_src//muscle";
$afa_stats = "/home/ivanam/c-utils/twostat";

foreach ( $fasta, $muscle, $afa_stats) {
    (-e $_) || die "$_ not found\n";
}


$my_id = $$;


# read in  fasta
$begin = time;

@name = ();
open ( FASTA, "<$fasta") ||
    die "Cno $fasta: $!\n";


$reading = 0;
while ( <FASTA> ) {
    next if ( !/\S/);
    if (/^>(.+)/ ) {
	chomp;
	$name = $1;
	$name =~ s/_//g;
	if ( defined $sequence{$name} ) {
	    $reading = 0;
	} else {
	    $reading = 1;
	    push @name,$name;
	    $sequence{$name} = "";
	    
	}
    } elsif ( $reading)  {
	$sequence{$name} .= $_;
    } 
}
close FASTA;

print "done reading; time:", (time-$begin),  "s\n";
$begin = time;

@group_member  = ();
@group_rep = ();

$group_rep[0]     = $name[0];
@{$group_member[0]} = ($name[0]);

# for each sequence, starting from the second
for $name_ctr (1 .. $#name ) {
     ($name_ctr%10)  || 
	 printf "$name_ctr (out of $#name) groups: $#group_rep time: %4d min\n",
	  int ((time-$begin)/60); 
    # compare with all group resepresentatives - 
    $group_found = 0;
    foreach $group_id( 0 .. $#group_rep) {
	$pct_id = compare ($group_rep[$group_id], $name[$name_ctr]);

	if ( $pct_id > $cutoff/100) { # place in the group  with a given cutoff sim
	    push @{$group_member[$group_id]}, $name[$name_ctr];
	    $group_found = 1;
	    last;
	}
    }
    $group_found && next;

    # otherwise start a new group
    push @group_rep, $name[$name_ctr];
    @{$group_member[$#group_rep]} = ($name[$name_ctr]);

    
}

$file = "groups.at$cutoff"."pct";
open ( OF, ">$file") ||
    die "Cno $file: $!\n";

foreach $group_id( 0 .. $#group_rep) {
    $group_size = $#{$group_member[$group_id]}+1;
    printf OF  "%s %4d ",  $group_rep[$group_id], $group_size;
    foreach $member_ctr ( 0 .. $group_size-1 ) {
	print OF  " $group_member[$group_id][$member_ctr]";
    }
    print OF  "\n";
}
close OF;
print "done sorting; time:", int ((time-$begin)/60),  "min\n";

# fore each group - divide into groups with higher similarity
`rm tmp$my_id.fasta tmp$my_id.afa`;


#######################################################
#######################################################
#######################################################

sub compare (@) {

    my ($name1, $name2) = @_;
    my $fasta = "tmp$my_id.fasta";
    my $afa   = "tmp$my_id.afa";
    my ($blah, $pct);
    open ( OF, ">$fasta") ||
	die "Cno $fasta: $!\n";
    print OF ">$name1\n";
    print OF $sequence{$name1};
    print OF ">$name2\n";
    print OF $sequence{$name2};
    close OF;

    $cmd = "nice $muscle -in $fasta -out $afa >& /dev/null";
    system ($cmd) && die"Error running $cmd\n";	
      
    ($blah, $pct) = split " ", `nice $afa_stats $afa`;
 
    return $pct;
}
