#!/usr/bin/perl
my $rawsize = `echo \$(git merge-base HEAD origin/master)..HEAD | git pack-objects --revs --thin --stdout -q | wc -c`;
chomp $rawsize;
my $mb  = int($rawsize/(1024*1024));
print "size =  $rawsize bytes   =   $mb MB\n";
