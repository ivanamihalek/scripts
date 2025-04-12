#!/usr/gnu/bin/perl -w 

%letter_code = ( 'GLY', 'G', 'ALA', 'A',  'VAL', 'V', 'LEU','L', 'ILE','I',
		'MET', 'M', 'PRO', 'P',  'TRP', 'W', 'PHE','F', 'SER','S',
		'CYS', 'C', 'THR', 'T',  'ASN', 'N', 'GLN','Q', 'TYR','Y',
                'LYS', 'K', 'ARG', 'R',  'HIS', 'H', 'ASP','D', 'GLU','E');

$current_aa = -1;
@seq = ();
@label = ();
while ( <>) {
    if (/ATOM\s+(\d)+\s+([\w|\s]{4})(\w{3})\s[\s|\w]([\s|\d]{4})/ ) { 
	if ( $4> 0 &&  $4 != $current_aa ) {
	    $current_aa = $4;
	    push @seq, $3;
	    push @label, $4;
	} 
    }
}    

for ($i=0; $i<= $#seq; $i++) {
    print  $letter_code{$seq[$i]};
    if ( !(($i+1)%50) && $i != $#seq) {
	print  "\n"; 
    }
}
print  "\n";
