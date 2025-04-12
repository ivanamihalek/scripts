#! /usr/bin/perl -w


sub insert_gaps (@);
sub formatted_sequence ( @);


(@ARGV >=3 ) || die "Usage: $0 <sse almt> <aa almt1> <aa_almt2>\n";

($sse_almt, $first_aa, $other_aa) = @ARGV; 

foreach ($sse_almt, $first_aa, $other_aa) {
    (-e $_) || die "$_ not_found";
}


@lines = split "\n", `cat $sse_almt`;

foreach  (@lines ) {
    if (/^>\s*(.+)/ ) {
	$name = $1;
	$name =~ s/\s//g;
	push @names,$name;
	$sse_seq{$name} = "";
    } else  {
	s/\./-/g;
	s/\#/-/g;
	s/\s//g;
	#s/x/\./gi;
	$sse_seq{$name} .= $_;
    } 
}
$sse_seq{$name} =~ s/\s//g;
$sse_seq{$name} =~ s/\./-/g;



foreach $filename ($first_aa, $other_aa) {

    @lines = split "\n", `cat $filename`;

    foreach  (@lines ) {
	next if (!/\S/);
 
	if (/^>\s*(.+)/) {
	    $name = $1;
	    $name =~ s/\s//g;
	    ( defined $sse_seq{$name} ) ||
		die "$name not found in $sse_almt\n";
	    $aa_seq{$name}  = "";
	} else {
	    $aa_seq{$name} .= $_;
	}
    }
    $aa_seq{$name} =~ s/\s//g;

}

# insert gaps as in the SSE alnment
foreach $name (@names) {
    $aa_seq_alnd{$name} = insert_gaps ($aa_seq{$name}, $sse_seq{$name});
}



foreach $name (@names) {
    print ">$name\n";
    print formatted_sequence($aa_seq_alnd{$name}),"\n";

}


exit 0;



#############################################################
#############################################################
#############################################################
sub insert_gaps (@) {

    my ( $old_seq, $template) = @_;
    my $new_seq = "";
    my @old_array;
    my @template_array;

    my ($i_ctr, $t_ctr);

    $old_seq =~ s/\s//g;
    $template =~ s/\s//g;
    $aux = $template;
    $aux =~ s/\-//g;
    
    @old_array = grep ( /\w/, (split //, $old_seq));
    @template_array = grep ( /[\w\-]/, (split //, $template) );

    $lold   = length $old_seq;
    $ltempl = length $template;
    $laux   = length $aux;

    
    $i_ctr = 0;
    for ($t_ctr = 0; $t_ctr <=  $#template_array; $t_ctr++) {

	$template_array[$t_ctr] || next;
	
	if ( $template_array[$t_ctr] ne "-" ) {
	    (defined $old_array[$i_ctr]) || 
		die "old not defined for $i_ctr   $lold   $ltempl  $laux\n".
		" *$old_seq*\n *$template*\n *$aux*\n $t_ctr  *$template_array[$t_ctr]*\n";
	    $new_seq .= $old_array[$i_ctr];
	    $i_ctr ++;
	}  else {
	    $new_seq .= "-";
	}
    }

    return $new_seq;
    
}

#############################################################
#############################################################
#############################################################
sub formatted_sequence ( @) {

    my $ctr, 
    my $sequence = $_[0];
    ( defined $sequence) || die "Error: Undefined sequence in formatted_sequence()";
    $ctr = 50;
    while ( $ctr < length $sequence ) { 
	substr ($sequence, $ctr, 0) = "\n";
	$ctr += 51; 
    } 
    
    return $sequence; 
} 
