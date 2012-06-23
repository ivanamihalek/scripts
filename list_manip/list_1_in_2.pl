#! /usr/bin/perl -w

# print out elements in list 1 that appear in list 2
# only the first string (name) is matched, but the
# whole  line from list 1 in echoed

( defined $ARGV[1] ) ||
    die "Usage: list_1_in_2.pl  <list1> <list2>.\n";

($list1, $list2) = @ARGV;

undef $/;
@list1 = ();
open ( IF,  "<$list1") || die "Cno $list1: $!.\n";
$_ = <IF>;
push @list1, split '\n';
close IF;
$/ = "\n";


%list2_names = ();
open ( IF,  "<$list2") || die "Cno $list2: $!.\n";
while (<IF>) {
    ($name) = split " ", $_;
    $list2_names{$name} = 1;
}
close IF;





foreach $element ( @list1 ) {
    ($name) = split " ", $element;
    ( defined $list2_names{$name}) && print "$element\n";
}

