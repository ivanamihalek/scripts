
#! /usr/bin/perl -w

use strict;

use Carp; # carping and croaking

our ($id, $id_type, $main_db_entry);
our %options;
our %pid;
our ( %start, %end);

sub  process_model_alignment (@) {
    my $alignment_name = $_[0];
    my $model_name;
    my ($qry, $subject);
    my $coverage;
    my (@aux_q, @aux_s, $ctr);
    my ($qctr, $last);

    $model_name = $options{"MODEL"};
    $model_name =~ s/\.pdb$//; 
    $pid{$model_name} = 0;

    $qry =  `grep $id $alignment_name | grep -v Name`;
    $qry =~ s/$id//g;
    $qry =~ s/[\s\n]//g;
    $subject =  `grep $model_name $alignment_name | grep -v Name`;
    $subject =~ s/$model_name//g;
    $subject =~ s/[\s\n]//g;
    
    @aux_q = split "", $qry;
    @aux_s = split "", $subject;

    $coverage = 0;
    $qctr = 0;
    for $ctr ( 0 .. $#aux_q ) {
	if ( $aux_q[$ctr] ne "." ) {
	    $qctr ++;
	    if (  $aux_s[$ctr] ne "." ) {
		(defined $start{$model_name} ) || ( $start{$model_name} = $qctr);
		$last = $qctr;
		$coverage ++;
	    }
	}
    }
    $end{$model_name} = $last;
    $coverage/= ($#aux_q+1);
    printf "\t\tcoverage:  %5.2f\n", $coverage;

    return $coverage;

}



1;
