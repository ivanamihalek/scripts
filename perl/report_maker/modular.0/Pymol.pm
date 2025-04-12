#! /usr/bin/perl

use strict;

our $home;
our %path = ();
our (%chains_in_pdb, %ligands);
our  @rgb = ("[1, 0, 0]", "[0, 0, 1]",   "[1, 1, 0]",  "[0, 1, 0]",  "[0.62, 0.12, 0.94]",  "[0, 1, 1]", 
	     "[0.25, 0.87, 0.81]",  "[0.64, 0.16, 0.16]",  "[1, 0.49, 0.31]",  "[1, 0, 1]",  "[1, 0.62, 0.47]",  
	     "[0.52, 0.8, 0.92]",  "[0.93, 0.5, 0.93]",  "[1, 0.84, 0]",  "[1, 0.89, 0.76]",  "[0.51, 0.43, 1]", 
	     "[0.07, 0.43, 0.83]",  "[0.73, 0.56, 0.56]",  "[0.4, 0.8, 0.66]",  "[0.33, 0.41, 0.18]",  "[0.39, 0.58, 0.92]",
	     "[0.54, 0.54, 0.54]",  "[0.87, 0.72, 0.52]",  "[0.19, 0.8, 0.19]",  "[0.82, 0.7, 0.54]",  "[1, 0.54, 0]", 
	     "[1, 0.07, 0.57]",  "[0.69, 0.18, 0.37]",  "[1, 0.92, 0.8]",  "[0, 0, 0]" );

our @color_word = ( "red","blue", "yellow", "green", "purple", "azure", "turquoise", "brown", "coral",
		    "magenta", "LightSalmon", "SkyBlue", "violet", "gold", "bisque", "LightSlateBlue", "orchid", 
		    "RosyBrown", "MediumAquamarine", "DarkOliveGreen", "CornflowerBlue", "grey55", "burlywood", 
		    "LimeGreen", "tan", "DarkOrange", "DeepPink", "maroon", "BlanchedAlmond", "black");
our (%color, %color_descr);
our %coordinates;
our %hetero;
our (%nucleic, %dna);
our (%chem_name, %synonym); # this is for ligands
our %chain_associated;
our %interface;
our (@attachments, %attachment_description);
our %renamed_to;
our %rotated_coordinates ;
our %interface_notes;

sub set_colors();
################################################################################
sub pdb_intro_fig ( @) {
    my $name = $_[0];
    my $pdbname = substr $name, 0, 4;;
    my $pdbfile = $path{"pdb_repository"}."/".$pdbname.".pdb";
    my ($psfile, $file, $pymol, $command, $chain_id);
    my $given_chain_id = "";
    my $chain;
    set_colors ();

    ( length $name >= 5 ) &&  ($given_chain_id = substr $name,4,1);
    chdir $home;

    $psfile = "intro_fig.eps";
    if ( ! -e "texfiles/$psfile" ||  ! -s "texfiles/$psfile" )  {
	# pymol postscript
	$pymol  = "load $pdbfile\n bg_color white\n";
	$pymol .= "hide all\n";
	if ( $given_chain_id ) {
	    $pymol .= "remove not chain $given_chain_id\n";
	    $pymol .= "color blue, chain $given_chain_id\n";
	    $pymol .= "show cartoon, chain $given_chain_id\n";
	    $pymol .= "zoom chain $given_chain_id\n";
	} else {
	    #color by chain
	    foreach $chain ( @{ $chains_in_pdb{$pdbname}} ) {
		$chain_id = "";
		((length $chain)<=4 ) || ( $chain_id = substr $chain, 4, 1);
		if ( $chain_id) {
		    #color definition
		    $pymol .= "set_color $color_descr{$chain_id} = $color{$chain_id} \n";
		    $pymol .= "color $color_descr{$chain_id}, chain $chain_id\n"; 
		    $pymol .= "show cartoon, chain $chain_id\n";
		} else {
		    $pymol .= "show cartoon\nhide nonbonded\n";
		}
	    } 
	}
	$pymol .= "ray 800, 800\n png tmp.png\n quit\n";

	$file  = "intro_fig.pml"; 
	open  (OF, ">$file") || die "Error: Cno $file.";
	print OF $pymol; 
	close OF; 
	$command = $path{"pymol"}." -cq -u  $file > /dev/null";
	(system $command ) && die "Error: Pymol failure.";  
	$command = "convert tmp.png $psfile";
	(system $command)  && die "error convert-ing";

	#`gv $psfile`; exit;
	$command = "mv $psfile $home/texfiles";  
	(system $command ) && die "Error: Failure moving intro figure to texfiles."; 
	`rm tmp.png`; 
    }

}
   

#################################################################################
sub set_colors(){

    my ($ctr, $letter);

    # assign color to each letter:
    for $ctr ( 0 .. 25 ) {
	$letter = chr(65+$ctr);
	$color{$letter}       = $rgb[$ctr];
	$color_descr{$letter} = $color_word[$ctr];
	# also for numbers
	$color{"$ctr"}        = $rgb[$ctr];
	$color_descr{"$ctr"}  = $color_word[$ctr];
   }
    # empty string
    $color{""} =  "[0,0,255]";
    $color_descr{""} =  "blue";
}


#######################################################################
sub four_side_postscript (@) {
    my $script_name = $_[0];
    my $out_name = $_[1];
    my %rotation = ( "front", "", "back", "rotate y, 180\n", 
		  "top", "rotate x, 90\n", "bottom" ,  "rotate x, -90\n");
    my ($side, $instructions, $commandline);

    foreach $side ( "front", "back", "top", "bottom" ) {
	$instructions  = $rotation{$side};
	$instructions  .= "ray 800, 800\n";
	$instructions .= "png tmp.png\n";
	$instructions  .= "quit\n";
	( -e "tmp") && `rm tmp`; 
	( copy $script_name, "tmp" ) || die "Error: Cannot copy $script_name: $!.";
	open (OF, ">>tmp" ) || die "Error: Cno tmp: $!.";
	print OF $instructions;
	close OF;
	$commandline = $path{"pymol"}." -qc -u  tmp > /dev/null ";
	( system $commandline) &&  die "Error: pymol failure.";
	$commandline= "convert tmp.png $out_name.$side.ps";
	(system $commandline) && die "error convert-ing.";
	#`gv  $out_name.$side.ps`; 
	`mv  $out_name.$side.ps $home/texfiles`;
    }
    ( -e "tmp" ) && (`rm tmp`); 
    
}




##########################################################################################################  
sub make_pymol_if ( @ ) {

    my ($name, $binding_partner, $ref) = @_;
    my ($psfile, $pymolfile, $orig_ligand_file, $complex, $ligand_file);
    my (@aux, $strand1, $strand2, $chain_id, $some_other_name);
    my $instructions;
    my $commandline;
    my ($x_center, $y_center, $z_center);
    my ($ligand_size, $selection);
    my ($file, $fh);

    print "\t\t interface between $name and  $binding_partner; ref: $ref\n";

    $chain_id   = substr $name, 4, 1;

    # make pymol script and ps  
    $psfile = "$name.$binding_partner.if.ps";
    $pymolfile = "$name.$binding_partner.if.pml"; 
    push @attachments, $pymolfile; # I am not checking if it is really there
    $attachment_description{$pymolfile} ="Pymol script for Figure \\ref\{$ref\}"; 

 
    (modification_time ( "$home/texfiles/$psfile" ) >= modification_time ("$name.ranks_sorted") )  &&
	return $psfile;
 
    $complex = "complex.pdb"; #this will be for local use
    if ( defined $interface_notes{$name}{$binding_partner} && 
	 $interface_notes{$name}{$binding_partner} =~ /analogy/ ) {
	$fh = outopen ("tmp0.pdb");
	print $fh $rotated_coordinates{$name}{$binding_partner};
	$fh->close;
	$ligand_file = "tmp0.pdb";
    } else {
	$ligand_file = "$home/$binding_partner.pdb"; 
    }

    if ( ! $chain_id || $chain_id ne "A" ) {
	$commandline = $path{"pdb_rename"}."   $name.pdb A > tmp1.pdb"; 
	( system $commandline) &&  die "Error: pdb_rename failure.";
	$chain_id = "A";
    } else {
	`ln -sf $name.pdb tmp1.pdb`;
    }

    $instructions  = "load $name.complex.pdb\n"; #note the name - this script will go to the outpackage
    $instructions .= "bg_color white\n";
    $instructions .= "hide all\n";

    # use cbcvg here
    if ( ! -e "$home/texfiles/$name.cbcvg" ) {
	$commandline = $path{"color_by_coverage"}."  $name.ranks_sorted   $name.complex.pdb   $name.cbcvg  $chain_id nohead";
	print "$commandline \n";
	( system $commandline) &&  die "Error: cbcvg failure";
	`cp $name.cbcvg $home/texfiles/$name.cbcvg`;
	push @attachments, "$name.cbcvg";
	$attachment_description{"$name.cbcvg"} = "used by other $name -- related pymol scripts";
    }
 
    $instructions .= "resume $name.cbcvg\n";
    $instructions .= "show spheres, chain A\nzoom chain A\n"; 

    $selection = "";
   
    #########################################################
    # handling different ligand types
    #########################################################
    if ( $nucleic{$binding_partner} ) { # nucleic

	if ( ! defined $renamed_to{$name}{$binding_partner} ) {
	    print " $name  $binding_partner \n\n"; exit;
	}
	$some_other_name = $renamed_to{$name}{$binding_partner};
	$commandline = $path{"pdb_rename"}."   $ligand_file  $some_other_name > tmp2.pdb";
	( system $commandline) &&  die "Error: pdb_rename failure.";
	$ligand_file = "tmp2.pdb";

	$some_other_name = $renamed_to{$name}{$binding_partner};
	$instructions .= "remove   (not (chain A or chain $some_other_name))\n";
	$instructions .= "set cartoon_transparency, 0.5 \ncartoon tube \ncolor green, chain $some_other_name \n";
	$instructions .= "show cartoon,  chain $some_other_name\n";

	
    }  elsif ( defined $hetero{$binding_partner} )  { # interface with a small ligand

	$selection =  $hetero{$binding_partner};
	    
	$ligand_size =  ( $coordinates{$binding_partner} =~ s/\n/\n/g );
	print "\t\t ligand size  $ligand_size \n";

	$instructions .= "remove   (not (chain A or  resn $selection))\n";
	$instructions .= "color green, resn $selection\n";
	if ( $ligand_size > 10 ) {
	    $instructions .= "show sticks, resn $selection \nhide spheres, resn $selection \n";
	} else {
	    $instructions .= "show spheres, resn $selection\n";
	}

    	    
    } else {# interface with another chain
							   
	 
	if ( ! defined $renamed_to{$name}{$binding_partner} ) { 
	    print " $name  $binding_partner \n\n"; exit; 
	}
	$some_other_name = $renamed_to{$name}{$binding_partner}; 
	$commandline = $path{"pdb_rename"}."   $ligand_file  $some_other_name > tmp2.pdb";
	( system $commandline) &&  die "Error: pdb_rename failure."; 
	$ligand_file = "tmp2.pdb";

	$instructions .= "remove   (not (chain A or chain $some_other_name))\n";
	$instructions .= "set cartoon_transparency, 0.5 \ncartoon tube \ncolor green, chain $some_other_name \n";
	$instructions .= "show cartoon,  chain $some_other_name\n";

   }


    ( $ligand_file ) || die "Error: Ligand file not determined in make_pymol_if";
    (  -e  $ligand_file && -s  $ligand_file ) || die "Error:  $ligand_file does not exist or empty";


    # write pymol file for the attachment
    open (OF, ">$pymolfile" ) || die "Error: Cno $pymolfile.";
    print OF  $instructions; 
    close OF; 


    #for local  consumption
    `cat tmp1.pdb  $ligand_file > $complex`;
    $instructions =~ s/$name\.complex\.pdb/complex\.pdb/; 
    open (OF, ">tmp2" ) || die "Error: Cno tmp2.";
    print OF  $instructions; 
    close OF; 

    # find geom center of the ligand
    $commandline = $path{"geom_center"}." $ligand_file ";  
    print "$commandline \n";
    ($x_center, $y_center, $z_center) = split " ", `$commandline`;


    # orient pdb so that we look face-on at that point 
    $commandline = $path{"pdb_point_place"}."  $complex  $x_center  $y_center  $z_center  $selection > tmp.pdb"; 
    print "$commandline \n\n";
    (system `$commandline`) || die "Error: Failure rotating $complex.";
    `mv tmp.pdb $complex`;

    # pymol produces png
    $instructions  = "ray 800,800 \npng tmp.png\n";
    $instructions .= "quit\n";
    open (OF, ">tmp3" ) || die "Error: Cno tmp3."; 
    print OF  $instructions;  
    close OF; 
    `cat tmp3 >> tmp2`; 

    # make postscript /home/pine/pymol/pymol.com -qc -u 1ceeA.1ceeB.if.pml 
    $commandline = $path{"pymol"}." -qc -u tmp2 > /dev/null"; 
    (system $commandline) &&  die "error runing pymol"; 

    $commandline = "convert tmp.png $psfile"; 
    (system $commandline)  && die "error runing $commandline";

    #`gv  $psfile `;  exit;
    `mv $psfile  $home/texfiles`;

    foreach $file ( "tmp.cbcvg", "tmp","tmp.pdb", "tmp1.pdb", "tmp2.pdb",  "complex.pdb", "tmp2", "tmp3") {
	( -e $file ) && (`rm $file`); 
    }    

    return $psfile;

}

#################################################################################
sub pymol_cluster (@) {
    my ($chain_id, $cluster, $color,  $color_number, $chain) = @_;
    my $ctr;
    my $line_ctr ;
    my ($pymol, $residue, $max_line_ctr);
    # color definitions

    $pymol .= "\nset_color c$color_number = $color";
    
    $ctr = 0;
    $line_ctr = 0;
    
    foreach $residue ( split "_", $cluster) {
	next if ( ! $residue);
	if ( ! ($ctr % 10 ) ) {
	    $line_ctr ++;
	    $pymol .= "\nselect sel$line_ctr, resid  $residue";
	} else {
	    $pymol .= "+$residue";
	}
	$ctr++;
    }
    $pymol .= "\n";
    $max_line_ctr = $line_ctr;
    $pymol .= "select cluster, (sel1";
    for $line_ctr ( 2 .. $max_line_ctr ) {
	$pymol .= " or sel$line_ctr";
    } 
    $pymol .= ")";
    ( $chain_id ) &&  ($pymol .= " and chain $chain_id");
    $pymol .= "\n";
    $pymol .= "color  c$color_number,  cluster\n";
    $pymol .= "show spheres,  cluster\n";

    return $pymol;

}
#######################################################################################
sub surfclust_pymol (@) {

    my ($name, $cluster, $psfile, $ref) = @_;
    my ($file, $residue, $string, $command);
    my  ($x_center, $y_center, $z_center);
    my ($pymol, $pymolfile, $chain_id);
    return  if (modification_time ("texfiles/$psfile" ) > modification_time ("$name.ranks_sorted" ));
    
    $chain_id = "";
    ( length $name >4 ) && ($chain_id = substr $name, 4, 1);

    # find geom center of the surface cluster
    $file = "tmp";
    open (OF, ">$file" ) || die "Error: Cno $file.";
    $file = "$name.pdb";
    open (IF, "<$file" ) || die "Error: Cno $file.";
    while (<IF>) {
	$residue  = substr $_, 22, 4;  $residue=~ s/\s//g;
	$string = "_$residue"."_";
	( $cluster =~ $string ) &&  print OF;
    }
    close IF;
    close OF;
    $command = $path{"geom_center"}."  tmp"; 
    ($x_center, $y_center, $z_center,) = split " ", `$command`;
    # orient pdb so that we look at that point face-on
    print "$ref center: $x_center, $y_center, $z_center\n"; 
    $command = $path{"pdb_point_place"}."  $name.pdb  $x_center  $y_center  $z_center  > tmp.pdb"; 
    (system `$command`) || die "Error: Failure rotating $name.pdb.";

    # make pymol script
    $pymolfile = "$ref.pml"; 
    $pymol = "";
    $pymol .= "load tmp.pdb, struct_name\n";
    $pymol .= "zoom complete=1\n";
    $pymol .= "bg_color white\n";
    $pymol .= "color white, struct_name\n";
    $pymol .= "hide lines, struct_name\n";
    $pymol .= "show spheres, struct_name\n"; 
    $pymol .= pymol_cluster ($chain_id, $cluster, $rgb[0], 0, "");
    # pymol produces png
    $pymol .= "ray 800,800 \npng tmp.png\n";
    $pymol .= "quit\n";

    open (OF, ">$pymolfile" ) || die "Error: Cno $pymolfile.";
    print OF  $pymol; 
    close OF; 

    #run pymol
    $command = $path{"pymol"}." -qc -u $pymolfile > /dev/null";
    (system $command) &&  die "error runing pymol";
		
    # make postscript
    $command = "convert tmp.png $psfile";
    (system $command)  && die "error runing $command";

    `mv $psfile  $home/texfiles`;
    ( -e "tmp" ) && (`rm tmp`); 
   
}

#######################################################################################
sub mother_of_surfclust (@) {
    
    my ($name, $cluster, $psfile, $ref, @mother_clusters) = @_;
    my ($file, $residue, $string, $command);
    my  ($x_center, $y_center, $z_center);
    my ($pymol, $pymolfile, $vol_cluster, $chain_id, );
    return  if (  modification_time ("$home/texfiles/$psfile" ) >  modification_time ("$name.ranks_sorted" ) );

    $chain_id = "";
    ( length $name >4 ) && ($chain_id = substr $name, 4, 1);

    # find geom center of the surface cluster
    $file = "tmp";
    open (OF, ">$file" ) || die "Error: Cno $file.";
    $file = "$name.pdb";
    open (IF, "<$file" ) || die "Error: Cno $file.";
    while (<IF>) {
	$residue  = substr $_, 22, 4;  $residue=~ s/\s//g;
	$string = "_$residue"."_";
	( $cluster =~ $string ) &&  print OF;
    }
    close IF;
    close OF;
    $command = $path{"geom_center"}."  tmp"; 
    ($x_center, $y_center, $z_center,) = split " ", `$command`;

    # orient pdb so that we look at that point face-on
    print "cluster  center: $x_center, $y_center, $z_center\n"; 
    $command = $path{"pdb_point_place"}."  $name.pdb  $x_center  $y_center  $z_center  > tmp.pdb"; 
    (system `$command`) || die "Error: Failure rotating $name.pdb.";
    
    # make pymol script
    $pymolfile = "$ref.pml"; 
    $pymol = "";
    $pymol .= "load tmp.pdb, struct_name\n";
    $pymol .= "zoom complete=1\n";
    $pymol .= "bg_color white\n";
    $pymol .= "color white, struct_name\n";
    $pymol .= "hide lines, struct_name\n";
    $pymol .= "cartoon tube \nshow cartoon, struct_name\n"; 

    foreach $vol_cluster  ( @mother_clusters ) {
	$pymol .= pymol_cluster ( $chain_id,  $vol_cluster, $rgb[1], 1, "");
    }
    $pymol .= pymol_cluster ( $chain_id,  $cluster, $rgb[0], 0, "");
    
    # pymol produces png
    $pymol .= "ray 800,800 \npng tmp.png\n";
    $pymol .= "quit\n";

    open (OF, ">$pymolfile" ) || die "Error: Cno $pymolfile.";
    print OF  $pymol; 
    close OF; 
    
    #run pymol
    $command = $path{"pymol"}." -qc -u $pymolfile > /dev/null";
    (system $command) &&  die "error runing pymol";
    
    # make postscript
    $command = "convert tmp.png $psfile";
    (system $command)  && die "error runing $command";


    `mv $psfile  $home/texfiles`;
    ( -e "tmp" ) && (`rm tmp`); 
   
}

1;
