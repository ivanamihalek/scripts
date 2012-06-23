#! /bin/csh
set  pathto = /home/i/imihalek/perlscr/mut_info

set utils = /home/i/imihalek/perlscr

$pathto/mut_http_string.pl < mut.addr_string > ! mut.addresses  && \
perl -I $utils   $pathto/dwld_mut_info.pl < mut.addresses | tee mutations && \
$pathto/parse_mut_info.pl < mutations
perl -I $utils  $pathto/lit_downld.pl
