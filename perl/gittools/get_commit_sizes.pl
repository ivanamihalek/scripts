#!/usr/bin/perl
foreach my $rev (`git rev-list --all --pretty=oneline`) {
    chomp $rev;
    my $tot = 0;
    ($sha = $rev) =~ s/\s(.*)$//;
    print "\n\n$sha  $1  \n";
    foreach my $blob (`git diff-tree -r -c -M -C --no-commit-id $sha`) {
        $blob = (split /\s/, $blob)[3];
        next if $blob == "0000000000000000000000000000000000000000"; # Deleted
        my $size = `echo $blob | git cat-file --batch-check`;
        $size = (split /\s/, $size)[2];
        $tot += int($size);
        #print "\t $blob $size\n";
    }
    my $revn = substr($rev, 0, 40);
    #  if ($tot > 1000000) {
      my $mb = int($tot/(1024*1024));
      print "total: $mb MB  $revn " . `git show --pretty="format:" --name-only $revn | wc -l`  ;
    #  }
}
