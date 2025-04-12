#! /usr/bin/perl -w



@start = (20, 64, 94, 121, 153, 190, 253, 288, 322, 346, 380, 415);
@end  = (57, 88, 112, 148, 180, 207, 282, 316, 341, 375, 410, 448);


while ( <> ) {
    next if ( !/\S/ );
    next if (! /^ATOM/);
    $res_seq  = substr $_, 22, 4;  $res_seq=~ s/\s//g;
    for $ctr ( 0 .. $#start ) {
	if ( $res_seq < $start[$ctr] ) {
	    last;
	} elsif ($res_seq <= $end[$ctr]) {
	    print;
	    last;
	}
    }

}

