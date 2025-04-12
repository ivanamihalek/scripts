#! /usr/bin/perl -w

@ARGV ||
    die "Usage:  $0  <target file> <from> <to>  <source file> <from> <to>\n".
    "(replace coords in the target file with coords from the source file). \n".
    "Note: this assumes the exact correspondence in length.\n";

($target, $from, $to, $src, $src_from, $src_to) = @ARGV;


$filename = $src;
open (SRC, "<$filename" ) 
    || die "Cno $filename: $!.\n";


$ctr = -1;
$res_seq_old = -700;
while ( <SRC> ) {

    next if ( ! /^ATOM/ && ! /^HETATM/ ) ;

    $res_seq  = substr $_, 22, 4;  $res_seq=~ s/\s//g;
    next if ($res_seq< $src_from  || $res_seq>$src_to);
    ( $res_seq != $res_seq_old) && ($ctr++);
    
    $atom_name = substr $_,  12, 4 ;  $atom_name =~ s/\s//g; 
    $res_name  = substr $_,  17, 3; $res_name=~ s/\s//g;
    $x = substr $_,30, 8; 
    $y = substr $_,38, 8; 
    $z = substr $_, 46, 8; 

    (defined $replacement_type[$ctr]) || ($replacement_type[$ctr] = $res_name);
    $replacement_x[$ctr]{$atom_name} = $x;
    $replacement_y[$ctr]{$atom_name} = $y;
    $replacement_z[$ctr]{$atom_name} = $z;
    
    $res_seq_old = $res_seq;
}

close SRC;




$filename = $target;
open (IF, "<$filename" ) 
    || die "Cno $filename: $!.\n";

$ctr = -1;
$res_seq_old = -700;
while ( <IF> ) {

    if (  ! /^ATOM/ && ! /^HETATM/ ) {
	print;
	next;
    }

    $res_seq  = substr $_, 22, 4;  $res_seq=~ s/\s//g;

    if ($res_seq< $from  || $res_seq>$to) {
	print;
	next;
    }

    ( $res_seq != $res_seq_old) && ($ctr++);
    
    $atom_name = substr $_,  12, 4 ;  $atom_name =~ s/\s//g; 
    $res_name  = substr $_,  17, 3; $res_name=~ s/\s//g;

    $line = $_;
    if ( defined $replacement_x[$ctr]{$atom_name} ) {
	substr ($line, 30, 8) = $replacement_x[$ctr]{$atom_name};
	substr ($line, 38, 8) = $replacement_y[$ctr]{$atom_name};
        substr ($line, 46, 8) = $replacement_z[$ctr]{$atom_name};
	print $line;
    } 

    $res_seq_old = $res_seq;
}


close IF;
