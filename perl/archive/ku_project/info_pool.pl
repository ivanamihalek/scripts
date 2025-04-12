#!/usr/bin/perl

use Spreadsheet::WriteExcel;     
use Switch;

@ARGV || die "Usage: $0 <arg file>\n";



open (IF, $ARGV[0] ) ||
    die "Cno $ARGV[0]: $!\n";

=pod
$score_file      = "Ku80.score";
$query           = "HOM_SAP_XRCC5";

$posttransl      = "Human_Ku80_postransl.csv";
$mutational      = "Human_Ku80_point_muts.csv";

$dssp_file       = "1jeyB.dssp";

$dimer_footprint = "1jeyB.A.footprint";
$dna_footprint   = "1jeyB.DNA.footprint";

$tetramer_model_footprint_A = "dimerA_chainB.dimerB.footprint";
$tetramer_model_footprint_B = "dimerB_chainB.dimerA.footprint";
=cut


($score_file, $query , $posttransl, $mutational, $dssp_file, 
 $dimer_footprint, $dna_footprint, 
 $tetramer_model_footprint_A, $tetramer_model_footprint_B,
 $human_yeast_almt, $yeast_score, $yeast_query, $yeast_mut)  = ();

while (<IF>) {

    next if ( !/\S/ );
    
    chomp;
    ($kw, $val)  = split;
    
    switch ($kw) {

	case "score_file" {$score_file = $val}
	case "query"      {$query      = $val}

	case "posttransl" {$posttransl = $val}
	case "mutational" {$mutational = $val}

	case "dssp_file"  {$dssp_file  = $val}

	case "dimer_footprint" {$dimer_footprint = $val}
	case "dna_footprint"   {$dna_footprint = $val}

	case "tetramer_model_footprint_A" {$tetramer_model_footprint_A = $val}
	case "tetramer_model_footprint_B" {$tetramer_model_footprint_B = $val}

	case "human_yeast_almt" {$human_yeast_almt  = $val} 
	case "yeast_score" {$yeast_score   = $val}  
	case "yeast_query" {$yeast_query   = $val}     
	case "yeast_mut"   {$yeast_mut     = $val}      
    }

}
close IF;


foreach ($score_file, $posttransl, $mutational, $dssp_file, 
         $dimer_footprint, $dna_footprint, 
	 $tetramer_model_footprint_A, $tetramer_model_footprint_B,
	 $human_yeast_almt, $yeast_score, $yeast_mut) {

    (-e $_) || die "$_ not found.\n";

}




###############################
%letter_code = ( 'GLY', 'G', 'ALA', 'A',  'VAL', 'V', 'LEU','L', 'ILE','I',
		 'MET', 'M', 'PRO', 'P',  'TRP', 'W', 'PHE','F', 'SER','S',
		 'CYS', 'C', 'THR', 'T',  'ASN', 'N', 'GLN','Q', 'TYR','Y',
		 'LYS', 'K', 'ARG', 'R',  'HIS', 'H', 'ASP','D', 'GLU','E', 
		 'PTR', 'Y', 'MSE', 'M' ); 

###############################
# posttr modifications
$file = $posttransl;
open (IF, "<$file") 
    || die "Cno $file: $!.\n";
while ( <IF> ) {
    chomp;
    @aux = split /\",\"/;
    $aux[0] =~ s/\"//g;
    $aux[1] =~ s/\"//g;

    $posttr{$aux[0]} = $aux[1];
}
close IF;


###############################
# mutational info
$file = $mutational;
open (IF, "<$file") 
    || die "Cno $file: $!.\n";
while ( <IF> ) {
    chomp;
    @aux = split /\",\"/;
    $aux[0] =~ s/\"//g;
    $aux[1] =~ s/\"//g;

    $aux[0] =~ /(\D+)(\d+)(\D*)/;
    @pos = split "", $1;


    foreach $pos ( @pos) {
	$mut{$pos.$2} = "$aux[0], $aux[1]";
    }
}
close IF;

###############################
# surface accessibility, SSE
$file = $dssp_file;
open (IF, "<$file") 
    || die "Cno $file: $!.\n";
while ( <IF> ) {
    last if ( / RESIDUE AA STRUCTURE BP1 BP2/); 
}
while ( <IF> ) {
    $res_number =  substr $_,  5, 5; $res_number =~ s/\s//g;
    $type       =  substr $_, 13, 1; $type       =~ s/\s//g;
    $sse{$type.$res_number} =  substr $_, 16, 1;
    $acc{$type.$res_number} =  substr $_, 34, 5; 
}
close IF;


###############################
# dimer footprint
$file = $dimer_footprint;
open (IF, "<$file") 
    || die "Cno $file: $!.\n";
while ( <IF> ) {
    chomp;
    @aux = split " ";
    $res_number = $aux[0];
    $type = $letter_code{$aux[2]};
    $dimer_foot{$type.$res_number} = $aux[1];
}
close IF;


###############################
# dna footprint
$file = $dna_footprint;
open (IF, "<$file") 
    || die "Cno $file: $!.\n";
while ( <IF> ) {
    chomp;
    @aux = split " ";
    $res_number = $aux[0];
    $type = $letter_code{$aux[2]};
    $dna_foot{$type.$res_number} = $aux[1];
}
close IF;


###############################
# tetramer footprint
$file = $tetramer_model_footprint_A;
open (IF, "<$file") 
    || die "Cno $file: $!.\n";
while ( <IF> ) {
    next if (/^%/);
    chomp;
    @aux = split " ";
    $res_number = $aux[0];
    $type = $letter_code{$aux[1]};
    $tfoot_A{$type.$res_number} = $aux[4];
}
close IF;


###############################
# tetramer footprint
$file = $tetramer_model_footprint_B;
open (IF, "<$file") 
    || die "Cno $file: $!.\n";
while ( <IF> ) {
    next if (/^%/);
    chomp;
    @aux = split " ";
    $res_number = $aux[0];
    $type = $letter_code{$aux[1]};
    $tfoot_B{$type.$res_number} = $aux[4];
}
close IF;


###############################
###############################
# yeast info: 

$file = $human_yeast_almt;
open (IF, "<$file") 
    || die "Cno $file: $!.\n";
while ( <IF> ) {
    next if ( !/\S/);
    chomp;
    if (/^>\s*(.+)/ ) {
	$name = $1;
	push @names,$name;
	@{$sequence{$name}} = ();
    } else  {
	s/\./\-/g;
	s/\#/\-/g;
	s/\s//g;
	#s/x/\./gi;
	push @{$sequence{$name}}, (split "", $_);
    } 
}
close IF;

$human_found = 0;
$yeast_found = 0;
foreach $name ( keys %sequence ) {
    ( $name eq  $query)  &&  ($human_found = 1);
    ( $name eq  $yeast_query)  &&  ($yeast_found = 1);
}

$human_found || die "$query not found in $human_yeast_almt\n";
$yeast_found || die "$yeast_query not found in $human_yeast_almt\n";

$human_ctr = 0;
$yeast_ctr = 0;
@yeast2human = (-1) x scalar @{$sequence{$yeast_query}};
@human2yeast = (-1) x scalar @{$sequence{$query}};

foreach $i ( 0 .. @{$sequence{$query}}-1 ) {
    
    ($sequence{$query}[$i] ne '-' ) && ($human_ctr++);
    ($sequence{$yeast_query}[$i] ne '-' ) && ($yeast_ctr++);
    
    if ( $sequence{$query}[$i] ne '-' && $sequence{$yeast_query}[$i] ne '-') {
	$yeast2human[$yeast_ctr] = $human_ctr;
 	$human2yeast[$human_ctr] = $yeast_ctr;
	$yeast_type[$yeast_ctr]  = $sequence{$yeast_query}[$i];
    }
}

# conservation scoring in yeast
$file = $yeast_score;
open (IF, "<$file") 
    || die "Cno $file: $!.\n";
($almt, $pdb, $aa, $gaps, $rvet, $entr, $scer_type, $scer_number, $substitutions) = ();
$yeast_ctr = 0;
while ( <IF> ) {
    
    if  (/^%/) {
    } else {
	chomp;
	($almt, $pdb, $aa, $gaps, $rvet, $entr, $scer_type, $scer_number, $substitutions) = split;
	next if ($aa eq '.');
	$yeast_ctr++;
	$yeast_rvet[$yeast_ctr] = $rvet;

    }
}
close IF;

# point mutations for yeast
$file = $yeast_mut;
open (IF, "<$file") 
    || die "Cno $file: $!.\n";
while ( <IF> ) {
    chomp;
    $line = $_;
    $line =~ s/\"//g;
    @aux = split ',', $line;

    next if ( $aux[0] =~ /Mutation/ );

    $aux[1] =~ /(\D+)(\d+)(\D+)/;
    $pos = $2;
    $yeast_mut_info[$pos] = $aux[1]. "   ".join "/", @aux[2..5];

}
close IF;




#############################################################################################
#############################################################################################
#############################################################################################
#############################################################################################
# XLS  stuff
# looks like $workbook and $worksheet have to be "mine"
my $outname  = "tmp";
my $workbook = Spreadsheet::WriteExcel->new("$outname.xls"); 
my $worksheet   = $workbook->add_worksheet();                 
$worksheet->keep_leading_zeros();

###############################
# the palette

$COLOR_RANGE = 20;
$green = $blue = $red = 0;


$N = 5;
$C1 = $COLOR_RANGE-1;

$red = 1.00;
$green =  0.87;
$blue =    0.0;
$color[0] = "[$red, $green, $blue]"; 
$xl_color[0] = $workbook->set_custom_color(8, $red*255, $green*255, $blue*255 );	


$bin_size = $C1/$N;
for ( $ctr=1; $ctr <= int ($COLOR_RANGE/$N); $ctr++ ) {

    $ratio =  ( int ( 100*($bin_size- $ctr+1)/$bin_size) ) /100;
    $red   = $ratio;
    $green = $blue = 0;
		 
    $color[$ctr] = "[$red, $green, $blue]"; 
    $color_name[$ctr] = "c$ctr";

    $xl_color[$ctr] = $workbook->set_custom_color($ctr+8, $red*255, $green*255, $blue*255 );	
    #printf "  %d   %d    %d , $ctr, $xl_color[$ctr] \n",$red*255, $green*255, $blue*255;
}

for ( $ctr= int ($COLOR_RANGE/$N)+1 ; $ctr <= $COLOR_RANGE; $ctr++ ) {

    $ratio =  ( $ctr -  $COLOR_RANGE/$N)/ ($COLOR_RANGE*($N-1)/$N);
    $red = $ratio;
    $green = $blue = $red;

    $xl_color[$ctr] = $workbook->set_custom_color($ctr+8, $red*255, $green*255, $blue*255 );	
    #printf "  %d   %d    %d , $ctr, $xl_color[$ctr] \n",$red*255, $green*255, $blue*255;

  
    $color[$ctr] = "[$red, $green, $blue]"; 
    $color_name[$ctr] = "c$ctr";
}

$var_color_space_size = $ctr;


###############################
# formats
$format_centered = $workbook->add_format();
$format_centered->set_align('center');
#
$format_right = $workbook->add_format();
$format_right->set_align('right');
#
$format_left = $workbook->add_format();
$format_left->set_align('left');
#
$format_float = $workbook->add_format();
$format_float->set_num_format('0.00');
#
$format_hdr = $workbook->add_format(); # Add a format
$format_hdr->set_bold();
$format_hdr->set_border();
$format_hdr->set_align('center');


#############################################################################################
#############################################################################################
#############################################################################################
#############################################################################################

@column_names =  ("almt",  "rvet",  "human type", "human number","substitutions",
		  "pdb type", "pdb id", "sse", "solvent acc", "dimer footprint", 
		  "dna footprint",
		  "tetramer footprint A", "tetramer footprint B", 
		  "posttranslational modifications", "point mutations", 
		  "", "", "", "",
		  "SC type", "SC number", "SC rvet", "SC mutations");

###############################
#
$file = $score_file;
open (IF, "<$file") 
    || die "Cno $file: $!.\n";
($almt, $pdb, $aa, $gaps, $rvet, $entr, $human_type, $human_number, $substitutions) = ();
while ( <IF> ) {
    
    if  (/^%/) {

	# header
	$row = 0;
	$column = -1;
	foreach $column_name (@column_names) {
	    $column++;
	    $worksheet->write ($row, $column, $column_name, $format_hdr);
	    $column_number{$column_name} = $column;

	}


    } else {
	
	chomp;
	($almt, $pdb, $aa, $gaps, $rvet, $entr, $human_type, $human_number, $substitutions) = split;

	$row++;

	#
	$entry  = $almt;
	$column = $column_number{"almt"};
	$format = $format_right;
	$worksheet->write ($row, $column, $entry, $format);
	
	# the things a bit more complicated bcs we are coloring the cell
	$entry  = $rvet;
	$column = $column_number{"rvet"};
	$cvg =  $rvet;
	$color_index = int ($cvg*$COLOR_RANGE );
	$format = $workbook->add_format(
	    bg_color => $xl_color[$color_index],
	    pattern  => 1,
	    border   => 1
		    );
	$format ->set_num_format('0.00');
	$worksheet->write ($row, $column, $entry, $format);
	
	#
	$entry  = $human_type;
	$column = $column_number{"human type"};
	$format = $format_centered;
	$worksheet->write ($row, $column, $entry, $format);

	#
	$entry  = $human_number;
	$column = $column_number{"human number"};
	$format = $format_right;
	$worksheet->write ($row, $column, $entry, $format);

	#
	$entry  = $substitutions;
	$column = $column_number{"substitutions"};
	$format = $format_centered;
	$worksheet->write ($row, $column, $entry, $format);

	#
	$entry  = $aa;
	$column = $column_number{"pdb type"};
	$format = $format_centered;
	$worksheet->write ($row, $column, $entry, $format);

	#
	$entry  = $pdb;
	$column = $column_number{"pdb id"};
	$format = $format_right;
	$worksheet->write ($row, $column, $entry, $format);


	# 
	next if ($human_type eq ".");

	if ( defined  $sse{$human_type.$human_number}) {
            #
	    $entry  = $sse{$human_type.$human_number};
	    $column = $column_number{"sse"};
	    $format = $format_centered;
	    $worksheet->write ($row, $column, $entry, $format);
            #
	    $entry  = $acc{$human_type.$human_number};
	    $column = $column_number{"solvent acc"};
	    $format = $format_right;
	    $worksheet->write ($row, $column, $entry, $format);
	}

	if ( defined $dimer_foot{$human_type.$human_number} )  {
	    $entry  =  $dimer_foot{$human_type.$human_number};
	    $column =  $column_number{"dimer footprint"};
	    $format = $format_float;
	    $worksheet->write ($row, $column, $entry, $format);

	}

	if  ( defined $dna_foot{$human_type.$human_number} ) {
	    $entry =  $dna_foot{$human_type.$human_number};
	    $column = $column_number{"dna footprint"};
	    $format = $format_float;
	    $worksheet->write ($row, $column, $entry, $format);
	}

	if  ( defined $tfoot_A{$human_type.$human_number} ) {

	    $entry  = $tfoot_A{$human_type.$human_number};
	    $column = $column_number{"tetramer footprint A"};
	    $format = $format_float;
	    $worksheet->write ($row, $column, $entry, $format);
	}

	if  ( defined $tfoot_B{$human_type.$human_number} ) {
	    $entry  = $tfoot_B{$human_type.$human_number};
	    $column = $column_number{"tetramer footprint B"};
	    $format = $format_float;
	    $worksheet->write ($row, $column, $entry, $format);
	}

	if ( defined $posttr{$human_type.$human_number} ) {
	    $entry  = $posttr{$human_type.$human_number};
	    $column = $column_number{"posttranslational modifications"};
	    $format = $format_left;
	    $worksheet->write ($row, $column, $entry, $format);
	}

	if ( defined $mut{$human_type.$human_number} ) {
	    $entry  = $mut{$human_type.$human_number};
	    $column = $column_number{"point mutations"};
	    $format = $format_left;
	    $worksheet->write ($row, $column, $entry, $format);
	}
	if ( $human2yeast[$human_number] != -1 ) {

	    $yeast_position = $human2yeast[$human_number];

	    $entry = $yeast_type[$yeast_position];
	    $column = $column_number{"SC type"};
	    $format = $format_centered;
	    $worksheet->write ($row, $column, $entry, $format);
	    #
	    $entry  = $yeast_position;
	    $column = $column_number{"SC number"};
	    $format = $format_right;
	    $worksheet->write ($row, $column, $entry, $format);
	    #
	    $entry  = $yeast_rvet[$yeast_position];
	    $column = $column_number{"SC rvet"};
	    $cvg    = $entry;


	    $color_index = int ($cvg*$COLOR_RANGE );
	    $format = $workbook->add_format(
		bg_color => $xl_color[$color_index],
		pattern  => 1,
		border   => 1
		);
	    $format ->set_num_format('0.00');
	    $worksheet->write ($row, $column, $entry, $format);

	    if ( defined $yeast_mut_info[$yeast_position] ) {
		$entry  = $yeast_mut_info[$yeast_position];
		$column = $column_number{"SC mutations"};
		$format = $format_left;
		$worksheet->write ($row, $column, $entry, $format);
	    }
	}

    }
}

close IF;

# colorbar

$last_column =  @column_names;


$column =  $last_column + 2;
$row = 2;
$worksheet->write($row, $column, "conserved", $format_right);   
$row = 2+$COLOR_RANGE;
$worksheet->write($row, $column, "variable", $format_right);   



$column =  $last_column + 3;
$row = 0;

$worksheet->write($row, $column, "cons colorbar", $format_hdr);   

for ($ctr = 0; $ctr <= $COLOR_RANGE; $ctr++) {
    $format = $workbook->add_format(
	bg_color => $xl_color[$ctr],
	pattern  => 1,
	border   => 1
	);
    $row = $ctr+2;
    $worksheet->write($row, $column, '',  $format);
}




# mpoint mut info for yeast
$row += 4;
$column =  $last_column + 3;
$worksheet->write( $row, $column,"phenotype in \"SC mutations\" column:", $format_centered);   
$row++;
$worksheet->write( $row, $column,"TPE/Telo_length/End_Prot/NHEJ/DNA_bind", $format_centered);   

$row += 4;
$worksheet->write( $row, $column,"\"footprint\" is the distance to the interactant in Angstroms", $format_centered);   







# dssp template line
#  #  RESIDUE AA STRUCTURE BP1 BP2  ACC     N-H-->O    O-->H-N    N-H-->O    O-->H-N    TCO  KAPPA ALPHA  PHI   PSI    X-CA   Y-CA   Z-CA 
#12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
#   21   54 A E  S    S-     0   0   82      2,-0.3    -1,-0.2     0, 0.0    -3,-0.1  -0.904  80.5 -96.6-158.5-176.9   21.5    7.2   69.7
# res number: substr x, 5,5
# type  substr x, 13, 1
# sse   substr x, 16, 1
# surface acc: substr x, 34, 5
#Dictionary of Protein Secondary Structure : Pattern Recognition of Hydrogen-Bonded and Geometrical Features.
#WOLFGANG KABSCH and CHRISTIAN SANDER.
#Biopolymer, Vol. 22, 2577-2637(1983) 

#Turns T
#Alpha Helix H
#3/10 Helix G
# pi Helix I
# Bridge B
# beta ladder and beta sheet E 
# Bend S
