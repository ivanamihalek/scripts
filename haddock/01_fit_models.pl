#! /usr/bin/perl -w

$template_pdb = "template.pdb";
$target_dir   = "target_dir";

$pdbdir     = "$workdir/structures/water/pdbfiles";
$scoredir   = "$workdir/structures/water/scorefiles";

$struct     = "/home/ivanam/kode/03_struct/struct";




foreach ($template_pdb, $target_dir, $pdbdir, $scoredir) {
    ( -e $_) || die "$_ not found.\n";
}



@pdbfiles = split "\n", `ls $pdbdir`;


foreach $pdbfile (@pdbfiles) {

    print $pdbfile, "\n";

    #################################
    # buried surface area, energies
    $ret = `grep \'buried surface area\' $pdbdir/$pdbfile`;
    $ret =~ s/REMARK //;
    print $ret;


    ########################
    # separate into chains
    # extract ATOM field and chain A/B from the column 73
    # `awk -F \'\' \'\$1==\"A\" && \$73==\"A\"\' $pdbdir/$pdbfile   > dock_res_A.pdb`;
    # `awk -F \'\' \'\$1==\"A\" && \$73==\"B\"\' $pdbdir/$pdbfile   > dock_res_B.pdb`;

 
    $cmd = "$struct -in1 $pdbfile -in2  $template_pdb > /dev/null";
    (system $cmd) &&  die "Error running $cmd\n";

    # the output should be called  $pdbfile.to_$template_pdb.pdb
    $outfile =  "$pdbfile.to_$template_pdb.pdb";

    (-e  $outfile) || die " $outfile not found after $outfile.\n";

    # you can nove it to your target directory:
    `mv  $pdbfile.to_$template_pdb.pdb $target_dir`;
    

} 


# prototype line from *w.pdb
#12345678901234567890123456789012345678901234567890123456789012345678901234567890
#ATOM      6  HT3 GLY     1      -8.817 -12.235  -3.875  1.00 10.00      A  
