

@color = { ...};


# %sizes =  (
#  " 251 451 234"      => 3,
#  " 45 3  56 "     => 3
# )

$ctr = 0;

foreach $key (sort HashByValue  (keys(%sizes))) {
    print $color[$ctr];
    print "$key";
    $ctr++;

}


sub  HashByValue {
    $sizes{$a} <=> $sizes{$b};
}
