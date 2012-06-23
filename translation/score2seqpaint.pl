#! /usr/bin/perl -w
use IO::Handle;         #autoflush
# FH -> autoflush(1);

($almt,  $pdb,    $aa,     $gaps,           $substitutions,     $entr,     $entr_cvg,        
$iv,     $iv_cvg,        $rv,     $rv_cvg,    $entr_s,     $cvg,      $iv_s,     $cvg,      
 $rv_s,     $cvg,     $pheno,     $pheno_cvg,    $ph_hyb,     $cvg,    $ph_nod,    $cvg) = ();
while ( <> ) {
    chomp;
   ($almt,  $pdb,    $aa,     $gaps,           $substitutions,     $entr,     $entr_cvg,        
$iv,     $iv_cvg,        $rv,     $rv_cvg,    $entr_s,     $cvg,      $iv_s,     $cvg,      
 $rv_s,     $cvg,     $pheno,     $pheno_cvg,    $ph_hyb,     $cvg,    $ph_nod,    $cvg) = split;
    next if ( $almt =~ /\%/ );

    print "  $pheno_cvg    $aa     $pdb  \n";

}
