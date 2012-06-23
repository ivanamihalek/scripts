#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

 
defined $ARGV[1]  ||
    die "Usage: $0  <msf_file_name> <threshold fraction>.\n"; 


$msf   =  $ARGV[0];
#$query_name =  $ARGV[1];
$threshold = $ARGV[1];


open ( MSF, "<$msf") ||
    die "Cno $msf: $!\n";

# read in the msf file:
while ( <MSF> ) {
    last if ( /\/\//);
}

@names = ();
%sequence = ();
do {
    if ( /\w/ ) {
	@aux = split;
	$name = $aux[0];
	$aux_str = join ('', @aux[1 .. $#aux] );
	if ( defined $sequence{$name} ) {
	    $sequence{$name} .= $aux_str;
	} else {
	    push @names, $name;
	    $sequence{$name}  = $aux_str;
	}
		
    } 
} while ( <MSF>);


# turn the msf into a table (first index= sequence, 2nd index= position)
$query_seq = -1;
$seq = 0;
foreach $name ( @names ) {
    @aux = split '', $sequence{$name};
    foreach $pos ( 0 .. $#aux ) {
	$array[$seq][$pos] = $aux[$pos];
    }
    if($sequence{$name} =~ /\.|X/){
        push @query_seq, $seq;
    }   
    $seq++;
    
}




foreach $query_seq(@query_seq){ 
    $no_seqs = $seq;   # number of seqs
    $max_seq = $seq-1; # max index a seq can have
    $max_pos = $#aux;  # max index a position can have
    
    # sanity check:
    $no_seqs || die "Error: no seqs found.\n"; 

    $max_id = 0;
    $max_seq = $query_seq;

    $len1 = 0;
    for $pos ( 0 .. $max_pos-1) {
        ($array[$query_seq][$pos] eq '.' || $array[$query_seq][$pos] eq 'X' ) || $len1++;
    }
    if ( ! $len1 ) {
        die "Query of length zero (?).\n";
    }

    # calculate similarity
    for $seq2 ( 0 .. $no_seqs-1) {
        next if ( $seq2 == $query_seq);
        $len2 = 0;
        for $pos ( 0 .. $max_pos-1) {
	    ($array[$seq2][$pos] eq '.' || $array[$seq2][$pos] eq 'X') || $len2++;
        }
        if ( ! $len2 ) {
	    next;
        }
	
        $common = 0;
        $common_length = 0;
        for $pos ( 0 .. $max_pos-1) {
	    if ( $array[$query_seq][$pos] !~ /[\.\-X]/ 
		 && $array[$seq2][$pos]  !~ /[\.\-X]/  ) {

		$common_length++;
	        if (  $array[$query_seq][$pos] eq $array[$seq2][$pos]) {
		    $common ++;
		}
	    }
        }
        $id =  $common/$common_length;
        #push @{$replaceidarray_hash{$names[$query_seq]}}, int(100 * $id);
        if($id >= $threshold){ 
            $replaceidarray_hash{$names[$query_seq]}{$names[$seq2]} = $id;
        }
        if ( $id > $max_id ) {
	    $max_id = $id;
	    $max_seq = $seq2;
        }
    }

}

foreach $query_name (keys %replaceidarray_hash){
    @replacementinorder = ();
    $deref = $replaceidarray_hash{$query_name};
    foreach $repName(sort {$$deref{$a}<=>$$deref{$b}}keys %$deref){
        push @replacementinorder, $repName; 
        #$print "$repName->$$deref{$repName} ";
    }
    $new_hash{$query_name}=[ @replacementinorder ];
}
$flag = 0;
foreach $query_nm (keys %new_hash){
    @replace_pos = ();
    @tmp_q = split("", $sequence{$query_nm});
    for(my $i = 0; $i <= $#tmp_q; $i++){
        if(($tmp_q[$i] eq ".") || ($tmp_q[$i] eq "X")){
           for($j=$#{$new_hash{$query_nm}}; $j>=0; $j--){
               @tmp_r = split("", $sequence{$new_hash{$query_nm}[$j]}); 
               if($tmp_r[$i] ne "." && $tmp_r[$i] ne "X"){
                   $flag = 1; 
                   last;   
               }

           }
           if($flag == 0){
               push @replace_pos, $i+1 . "replaced by $new_hash{$query_nm}[$j]:0";
           }
           else{
               $tmp_q[$i] = $tmp_r[$i];
               $flag = 1;
               $tmp_el = ($i+1) . " replaced by $new_hash{$query_nm}[$j]:" . ($i+1);
               push @replace_pos, $tmp_el;

           } 
        }
    } 
    $sequence_afterReplacement{$query_nm} = join("", @tmp_q);
#print "$query_nm=>+>\n$sequence_afterReplacement{$query_nm}\n";
    #print join(" ", @replace_pos) . "\n**************\n";
}
#    print join(" ", @{$replaceidarray_hash{$name}}) . "\n######################\n"; 
#}
#for $nm (keys %replace_hash){
#    @replace_pos = ();
#    print "$nm-> $replace_hash{$nm}\n";
#    @tmp_q = split("", $sequence{$nm});
#    @tmp_r = split("", $sequence{$replace_hash{$nm}});
#    for($i = 0; $i <= $#tmp_q; $i++){
#        if(($tmp_q[$i] eq ".") || ($tmp_q[$i] eq "X")){
#            if($tmp_r[$i] ne "." && $tmp_r[$i] ne "X"){
#                push @replace_pos, $i+1;
#            }
#            else{
#                $replacement = 0-$i;
#                push @replace_pos, $replacement;  
#            }  
#        }
#    }
#    print "replace position for $nm is from $replace_hash{$nm} at :\n";
#    print join(" ", @replace_pos) . "\n**************\n";
#}

foreach $n (keys %sequence_afterReplacement){
    $sequence{$n} = $sequence_afterReplacement{$n};
}
foreach $name(@names){
    print ">$name\n";
    print "$sequence{$name}\n";
}
#foreach $sq_name(keys %sequence){
#    print ">$sq_name\n";
#    print "$sequence{$sq_name}\n";
#}
