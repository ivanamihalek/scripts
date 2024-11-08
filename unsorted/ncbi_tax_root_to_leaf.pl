#!/usr/bin/perl -w

sub recursive_out (@_);

$names = "names.dmp";
$nodes = "nodes.dmp";


foreach ($names, $nodes) {

    (-e $_) || die "$_ not found\n";

}


# find vert id
$ret =  `grep Gnathostomata $names | grep vertebrate `;
$ret =~ s/\s//g;
($vert_id) = split '\|', $ret;
print "vert id: $vert_id\n";

open (VERT_NAMES, ">vert_names.dmp") ||
    die "Cno vert_names.dmp: $!.\n";
open (VERT_NODES, ">vert_nodes.dmp") ||
    die "Cno vert_names.dmp: $!.\n";

print VERT_NAMES $ret;
$ret = `awk -F '|' '\$1==$vert_id' $nodes`;
print VERT_NODES $ret;
recursive_out ($vert_id);


close VERT_NODES;
close VERT_NAMES;


sub recursive_out (@_) {

    my $node_id = $_[0];
    my $ret = `awk -F '|' '\$2==$node_id' $nodes`;


    my @lines = split "\n", $ret;
    foreach my $line (@lines) {
	print VERT_NODES $line."\n";
	my ( $child_id, $parent_id, $class) =  split '\|', $line;
	#print "  $child_id, $parent_id, $class \n";

	$ret = `awk -F '|' '\$1==$child_id' $names`;

	print $child_id;
	print $ret;

	$ret && print VERT_NAMES $ret;

	if ($class ne "species") {
	    recursive_out ($child_id);
	}
    }
    return
}

# if $3 eq species, awk -F '|' '$1==134991' names.dmp

