#! /usr/bin/perl -w
 
# perl -MCPAN -e "install 'Spreadsheet::WriteExcel'"
# doc: 
# http://search.cpan.org/dist/Spreadsheet-WriteExcel/lib/Spreadsheet/WriteExcel.pm

use Spreadsheet::WriteExcel;                             # Step 0

(defined $ARGV[2]) ||
    die "Usage:  cbcvg.pl  <method [rvet|majf|entr]>  <specs score file>  <output name>  \n"; 


($method, $ranks_file, $outname) = @ARGV;

my $workbook = Spreadsheet::WriteExcel->new("$outname.xls"); # Step 1
$worksheet   = $workbook->add_worksheet();               # Step 2
$worksheet->keep_leading_zeros();

##################################################
#set the pallette:
$COLOR_RANGE = 20;
$green = $blue = $red = 0;


$N = 5;
$C1 = $COLOR_RANGE-1;

$red = 1.00;
$green =  0.83;
$blue =    0.17;
$color[0] = "[$red, $green, $blue]"; 
$color_name[0] = "c0";
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



##################################################
# input/ouput

open (RANKS_FILE, "<$ranks_file") || 
    die "cno $ranks_file\n";
    

$format_centered = $workbook->add_format();
$format_centered->set_align('center');
$format_right = $workbook->add_format();
$format_right->set_align('right');
$format_float = $workbook->add_format();
$format_float->set_num_format('0.00');

$line = 1;
$last_column = 0;
while ( <RANKS_FILE> ) {
    next if ( !/\S/ );
    if ( /\%/ ){ # find the column that the specified method is in
	@aux = split;
	shift @aux;
	for ($ctr=0; $ctr< $#aux; $ctr++) {
	    if ($aux[$ctr] eq $method ) {
		$method_column = $ctr;
		last;
	    }
	}
        ($method_column < 0 ) && die "no method?\n";
	unshift @aux, "$method";
        # header
 	$format = $workbook->add_format(); # Add a format
	$format->set_bold();
	$format->set_align('center');
	$last_column = @aux;
	$column =  chr (ord('A') + $last_column-1);
        $worksheet->set_column("$column:$column", 20);
	$worksheet->write_row(0, 0, \@aux, $format);

   } else {
        # print;
	chomp;
	@aux = split;
	$cvg =  $aux[$method_column];

        $color_index = int ($cvg*$COLOR_RANGE );

	# the first column is the color strip
	$format = $workbook->add_format(
                                        bg_color => $xl_color[$color_index],
                                        pattern  => 1,
                                        border   => 1
                                      );

 	$worksheet->write("A$line", '',  $format);

	foreach $i (0 .. $#aux) {
	    $column =  chr (ord('B') + $i);
	    if ($i==0) {
	      $worksheet->write("$column$line", $aux[$i], $format_right);    
	    } elsif ( $i==1 || $i==2) {
	      if ( $aux[$i] =~ /\d/ ) {
		$worksheet->write("$column$line", $aux[$i], $format_right);  
	      } else {  
		$worksheet->write("$column$line", $aux[$i], $format_centered);  
	      }  
	    } elsif ($i==$#aux) {
	      @unsorted = split "",  $aux[$i];
	      $sorted = join "", sort @unsorted;
	      $worksheet->write("$column$line",$sorted, $format_centered);    
	    } else {
	      $worksheet->write("$column$line", $aux[$i], $format_float);    
	    }
	}
    }
    $line++;
}


close RANKS_FILE;
