#! /usr/bin/perl -w

( @ARGV == 2 ) ||
    die "Usage: reconcile_enum.pl <pdb file> <msf file>\n";
($pdbfile, $msffile) = @ARGV;

%letter_code = ( 'GLY', 'G', 'ALA', 'A',  'VAL', 'V', 'LEU','L', 'ILE','I',
		 'MET', 'M', 'PRO', 'P',  'TRP', 'W', 'PHE','F', 'SER','S',
		 'CYS', 'C', 'THR', 'T',  'ASN', 'N', 'GLN','Q', 'TYR','Y',
		 'LYS', 'K', 'ARG', 'R',  'HIS', 'H', 'ASP','D', 'GLU','E',
		 'PTR', 'Y' ); 

$filename = $pdbfile;
open ( IF, "<$filename" ) ||
    die "Cno $filename: $!.\n";
# read in pdb
$res_ctr = 0;
$old_res_seq = -100;
$old_res_name  ="";

while ( <IF> ) {

    if ( ! /^ATOM/  ) {
	next;
    }

    $name = substr $_,  12, 4 ;  $name =~ s/\s//g; 
    $name =~ s/\*//g; 
    $alt_loc = substr $_,16, 1 ;  $alt_loc =~ s/\s//g;
    $res_seq  = substr $_, 22, 5;  $res_seq=~ s/\s//g;
    $res_name = substr $_,  17, 4; $res_name=~ s/\s//g;

    next if ( $alt_loc =~ "B" );
    $newline = $_;
    substr ($newline,16, 1 ) = " "; # alt loc

    if ( $res_seq ne $old_res_seq  ||  ! ($res_name eq $old_res_name) ){
	$old_res_seq =  $res_seq;
	$old_res_name =  $res_name;
	$res_ctr++;
	$pdb_num[$res_ctr] = $res_seq;
	$pdb_type[$res_ctr] = $letter_code{$res_name};
	
    }
}
$no_res = $res_ctr;
close IF;
 
################################
$filename = $msffile;
open ( MSF, "<$filename" ) ||
    die "Cno $filename: $!.\n";
# read in msf



while ( <MSF>) {
    last if ( /\/\// );
    last if ( /CLUSTAL FORMAT for T-COFFEE/ );
}
while ( <MSF>) {
    next if ( ! (/\w/) );
    chomp;
    @aux = split;
    $seq_name = $aux[0];
    if ( defined $seqs{$seq_name} ){
	$seqs{$seq_name} .= join ('', @aux[1 .. $#aux]);
    } else { 
	$seqs{$seq_name}  = join ('', @aux[1 .. $#aux]);
    }
}

close MSF;

$pdbname = $pdbfile;
$pdbname =~ s/\.pdb//;

(defined $seqs{$pdbname} ) || 
    die "$pdbname not found in $msffile.\n";

@seq = split '',  $seqs{$pdbname};

$res_ctr = 0;
for $ctr ( 0 .. $#seq ) {
    if ( $seq[$ctr] ne "." ) {
	$res_ctr ++;
	$msf_num [$res_ctr] = $ctr+1;
	$msf_type[$res_ctr] = $seq[$ctr];
    }
}

printf " %5s  %1s   %5s  %5s \n", "seq", "type", "msf","pdb";

for $res_ctr ( 1 .. $no_res) {
    if ( $msf_type[$res_ctr] ne $pdb_type[$res_ctr] ) {
	$errmsg =  "type mismatch for sequential $res_ctr:\n";
	$errmsg .= "\tin $msffile: $msf_num [$res_ctr] $msf_type [$res_ctr]\n";
	$errmsg .= "\tin $pdbfile: $pdb_num [$res_ctr] $pdb_type [$res_ctr]\n";
	die $errmsg;
    }
	
    printf " %5d  %1s   %5d  %5d \n", $res_ctr,
    $msf_type [$res_ctr], $msf_num [$res_ctr], $pdb_num [$res_ctr];
}
