#! /usr/gnu/bin/perl -w
# find "number (number) " in input nad turn it into "number/number (percentage)"
while ( <> ) {
    $_ =~  s/(\d+)\s*\(\s*(\d+)\s*\)/sprintf("%d \/ %d ( %5.0f%% )",$1, $2, $1\/$2*100)/eg ;
   print $_; 
    
}
