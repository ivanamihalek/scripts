#! /usr/bin/perl -w

sub generateSub(@);

###################################################################
# since we need to display full name of a family on the browse page
# we need the original family list, `ls` results do not have full
# name information
 
#defined($ARGV[0])  ||
    #die "Usage: generate_db_anal_index.pl genelist\n";

$home = "http://epsf.bmad.bii.a-star.edu.sg/cube/db/html";
#$dir = "/home/zhangzh/www/db_analysis_v3_pdb";
#$dir = "/home/zhangzh/www/db_analysis_v5";
#$dir = "/home/zhangzh/www/testweb";
#$dir = "/var/www/dept/bmad/htdocs/projects/EPSF/www/cube/db_analysis";


#$listfile = $ARGV[0];

@family_list = ();
$dir = `pwd`; chomp $dir;
#@dirs = split "\n", `ls`;
open(FH, "<$dir/family_full_name") || die "Cno, $listfile\n";
while(<FH>){
    chomp;
    if(/^\w/){
	$family = $_;
	push(@family_list, $family);
    }
    else{
	$_ =~ s/^\t+//;
	$_ =~ s/^\s+//;
	push(@{$hash{$family}},$_);
    }
   
}
close(FH);

#@list = `ls -l $dirnm`;

$html = "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n";
$html .= "<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\" lang=\"en\"><head>\n";
$html .= "<title>Cube db</title>\n";
$html .= "<link rel=\"stylesheet\" media=\"screen\" type=\"text/css\" href=\"style.css\" />\n";
$html .= "<meta http-equiv=\"Content-type\" content=\"text/html;charset=UTF-8\" />\n";

$html .= "</head>\n";
$html .= "<body>\n";
$html .= "<div id=\"header\">\n";
$html .= "</div>\n";
$html .= "<div id=\"page\">\n";
$html .= "<div id=\"content\">\n";
$html .= "<div class=\"box\">\n";
$html .= "<div class=\"box-padding\"><p><a href=\"\#A\">A</a> <a href=\"\#B\">B</a> <a href=\"\#C\">C</a> <a href=\"\#D\">D</a> <a href=\"\#E\">E</a> <a href=\"\#F\">F</a>\n";

$html .= "<a href=\"\#G\">G</a> <a href=\"\#H\">H</a> <a href=\"\#I\">I</a> J <a href=\"\#K\">K</a> <a href=\"\#L\">L</a>\n";
$html .= "<a href=\"\#M\">M</a> <a href=\"\#N\">N</a> <a href=\"\#O\">O</a> <a href=\"\#P\">P</a> Q <a href=\"\#R\">R</a>\n";

$html .= "<a href=\"\#S\">S</a> <a href=\"\#T\">T</a> <a href=\"\#U\">U</a> <a href=\"\#V\">V</a> <a href=\"\#W\">W</a> X\n";
$html .= "<a href=\"\#Y\">Y</a> <a href=\"\#Z\">Z</a>\n";
$html .= "</p>\n";
$html .= "</div>\n";

$html .= "</div>\n";
$html .= "<p class=\"date\"></p>\n";
$html .= "<div class=\"box\">\n";
$html .= "<div class=\"box-padding\">\n";
$html .= "<table width=\"600\"  border=\"0\" style=\"table-layout:fixed\"align=\"center\" cellpadding=\"0\" cellspacing=\"0\">\n";
foreach $family(@family_list){

    @aux = split(/\s+/, $family);
    $family_short = $aux[0];
    #$family_short =~ s/\s+//g;
    #$family_short =~ s/\t+//g;
    shift(@aux); #get rid of family_short name
    $family_long = join(" ", @aux);


    if(-d "$dir/$family_short"){
	
	$html .= "<tr><td width=\"25%\"><p>\n";
	$html .= "<a href=\"$home/$family_short/index.html\"> $family_short </a> </p></td>\n";
	$html .= "<td width=\"75%\"><p>$family_long</p></td>\n";
	$html .= "</tr>\n";
	@cluster_list = `ls $dir/$family_short`;
	
	$html_subindex = generateSub(\@cluster_list, $dir,$family_short, $family_long, \@{$hash{$family}});
	open(FH, ">$dir/$family_short/index.html") || die "Cno, $dir/$family_short/index.html\n";
	print FH $html_subindex;
	close(FH);
    }
}

$html .= "</table>\n";
$html .= "</div>\n";
$html .= "</div>\n";
$html .= "</div><div id=\"right-nav\">\n";
$html .= "<div id=\"main-menu\">\n";
$html .= "<ul><li><a href=\"$home/home.html\">HOME</a></li>\n";
$html .= "<li><a href=\"$home/db_index.html\">BROWSE</a></li>\n";
$html .= "<li><a href=\"$home/doc.html\">DOC</a></li>\n";
$html .= "<li><a href=\"http://epsf.bmad.bii.a-star.edu.sg/\">ABOUT</a></li>\n";

$html .= "<li><a href=\"$home/contact.html\">CONTACT</a></li>\n";
$html .= "</ul>\n";
$html .= "</div>\n";
$html .= "<br />\n";
#$html .= "</div>\n";
$html .= "<div class=\"right-nav-divider\"></div>\n";
$html .= "<div id=\"posts\">\n";
$html .= "<form name=\"searchform\" method=\"post\" action=\"../../../cgi-bin/db_analysis/quick_search.cgi\" enctype=\"multipart/form-data\">\n";
$html .= "<p>\n";
$html .= "\t<input type=\"text\" name=\"search\" size=\"15\" id=\"gntext\" value=\"Protein Search\" onfocus=\"this.form.search.value=''\;>\n";
$html .= "\t<input type=\"submit\" name=\"submit\" value=\"\" id=\"gnsubmit\" />\n";
$html .= "</p>\n";
$html .= "</form>\n";
$html .= "</div>\n";
$html .= "</div>\n";

$html .= "<div id=\"footer\">\n";
$html .= "<div id=\"footer-pad\">\n";
$html .= "<div class=\"line\"></div>\n";
$html .= "<p> &copy; EPSF Group 2011. All rights reserved.  Design by Harpy</a>.</p>\n";
$html .= "</div>\n";
$html .= "</div>\n";
$html .= "</div>\n";

$html .= "</body>\n";
$html .= "</html>\n";

print $html;


sub generateSub(@){
    ($list_ref, $dir_db,$short_name_family, $long_name_family, $members_ref) = @_;
    
    
    $html_cluster = "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n";
    $html_cluster .= "<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\" lang=\"en\">\n";
    $html_cluster .= "<head>\n";
    $html_cluster .= "<title>Cube db</title>\n";
    $html_cluster .= "<link rel=\"stylesheet\" media=\"screen\" type=\"text/css\" href=\"../style.css\" />\n";
    $html_cluster .= "<meta http-equiv=\"Content-type\" content=\"text/html;charset=UTF-8\" /></head>\n";

    $html_cluster .= "<body>\n";
    $html_cluster .= "<p class=\"date\"></p>\n";

    $html_cluster .= "<div id=\"header\"> </div>\n";


    $html_cluster .= "<div id=\"page\">\n";
    $html_cluster .= "<div id=\"content\">\n";

    $html_cluster .= "<div class=\"box\">\n";
    $html_cluster .= "<div class=\"box-padding\">\n";
    $html_cluster .= "<h2>$short_name_family family <p>$long_name_family</p></h2>\n";
    $html_cluster .= "</div>\n";
    $html_cluster .= "</div>\n";

    $html_cluster .= "<p class=\"date\"></p>\n";

    $html_cluster .= "<div class=\"box\">\n";
    $html_cluster .= "<div class=\"box-padding\"><table width=\"600\"  border=\"0\""; 
    $html_cluster .= "style=\"table-layout:fixed\"align=\"center\" cellpadding=\"0\" cellspacing=\"0\">\n";
    foreach $cluster(@$list_ref){
	chomp($cluster);
	
	if(-d "$dir_db/$short_name_family/$cluster"){
	    
	    @aux = grep(/\b$cluster\b/,@$members_ref);
	    if($#aux > 0){
		die"More than one clusters have the same name\n";
	    }
	    @aux_aux = split(/\s+/, $aux[0]);
	   
	    $members = $aux_aux[1];
	    $members =~ s/\(//g;
	    $members =~ s/\)//g;
	    $members =~ s/,/, /g;
	    
	    $html_cluster .= "<tr><td width=\"25%\"><p>\n";
	    $html_cluster .= "<a href=\"http://epsf.bmad.bii.a-star.edu.sg/cube/db_analysis/$short_name_family/$cluster/display.html\" > $cluster </a> </p></td>\n";
	    $html_cluster .= "<td width=\"75%\"><p>$members </p></td>\n";
	    $html_cluster .= "</tr>\n"; 

	}
	
    }
    $html_cluster .= "</table>\n";
    $html_cluster .= "</div>\n";
    $html_cluster .= "</div>\n";



    $html_cluster .= "</div>\n";


    $html_cluster .= "<div id=\"right-nav\">\n";
    $html_cluster .= "<div id=\"main-menu\">\n";
    $html_cluster .= "<ul>\n";
    $html_cluster .= "<li><a href=\"http://epsf.bmad.bii.a-star.edu.sg/cube/db_analysis/home.html\">HOME</a></li>\n";
    $html_cluster .= "<li><a href=\"http://epsf.bmad.bii.a-star.edu.sg/cube/db_analysis/db_index.html\">BROWSE</a></li>\n";

    $html_cluster .= "<li><a href=\"http://epsf.bmad.bii.a-star.edu.sg/cube/db_analysis/doc.html\">DOC</a></li>\n";
    $html_cluster .= "<li><a href=\"http://epsf.bmad.bii.a-star.edu.sg/\">ABOUT</a></li>\n";
    $html_cluster .= "<li><a href=\"http://epsf.bmad.bii.a-star.edu.sg/cube/db_analysis/contact.html\">CONTACT</a></li>\n";
    $html_cluster .= "</ul>\n";
    $html_cluster .= "</div>\n";
    $html_cluster .= "<br />\n";
    $html_cluster .= "</div>\n";



    $html_cluster .= "<div id=\"footer\">\n";
    $html_cluster .= "<div id=\"footer-pad\">\n";
    $html_cluster .= "<div class=\"line\"></div>\n";
    $html_cluster .= "<p> &copy; EPSF Group 2011. All rights reserved.  Design by Harpy</a>.</p>\n";

    $html_cluster .= "</div>\n";
    $html_cluster .= "</div>\n";
    $html_cluster .= "</div>\n";



    $html_cluster .= "</body>\n";
    $html_cluster .= "</html>\n";

    return($html_cluster);
	

}
