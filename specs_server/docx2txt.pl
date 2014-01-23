#!/usr/bin/env perl

# docx2txt, a command-line utility to convert Docx documents to text format.
# Copyright (C) 2008-2012 Sandeep Kumar
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA

#
# This script extracts text from document.xml contained inside .docx file.
# Perl v5.10.1 was used for testing this script.
#
# Author : Sandeep Kumar (shimple0 -AT- Yahoo .DOT. COM)
#

# modified by Ivana, Aug 2013

#
# The default settings below can be overridden via docx2txt.config in current
# directory/ user configuration directory/ system configuration directory.
#

use strict;

@ARGV ==3 || die "Usage: <infile.docx> <outfile.txt> <workdir>.\n";

my ($infile, $outfile, $workdir) = @ARGV;

our $unzip = '/usr/bin/unzip';	


# check input sanity:
foreach ($infile, $workdir, $unzip) {
    (-e $infile) || die "$_ not found\n";
}
stat($infile);
(-f _ && -r _) || die "Can't read docx file $infile.\n";
(-T _) && die "$infile does not seem to be a docx file!\n";

(-d $workdir) || die "$workdir does not seem to be a directory";

chdir $workdir;

open(OF, ">$outfile") ||  die "Can't create $outfile for output!\n";

#
# extract xml document content from argument docx file
#
my $content = `$unzip  -p $infile  word/document.xml 2> /dev/null`;
$content ||  die "Failed to extract required information from $infile.\n" ;

# some config stuff
our $config_newLine = "\n";		# Alternative is "\r\n".
our $config_listIndent = "  ";		# Indent nested lists by "\t", " " etc.
our $config_lineWidth = 80;		# Line width, used for short line justification.
our $config_showHyperLink = "N";	# Show hyperlink alongside linked text.
our $config_tempDir;			# Directory for temporary file creation.
our $config_exp_extra_deEscape = "N";   # Extra conversion of &...; sequences.


#
#
# ToDo: Better list handling. Currently assumed 8 level nesting.
#
my @levchar = ('*', '+', 'o', '-', '**', '++', 'oo', '--');


#
# Character conversion tables
#

# Only (amp, apos, gt, lt and quot) are the required reserved characters in HTML
# and XHTML, others are used for better text experience.
my %escChrs = (	amp => '&', apos => '\'', gt => '>', lt => '<', quot => '"',
		acute => '\'', brvbar => '|', copy => '(C)', divide => '/',
		laquo => '<<', macr => '-', nbsp => ' ', raquo => '>>',
		reg => '(R)', shy => '-', times => 'x'
);

my %splchars = (
    "\xC2" => {
	"\xA0" => ' ',		# <nbsp> non-breaking space
	"\xA2" => 'cent',	# <cent>
	"\xA3" => 'Pound',	# <pound>
	"\xA5" => 'Yen',	# <yen>
	"\xA6" => '|',		# <brvbar> broken vertical bar
#	"\xA7" => '',		# <sect> section
	"\xA9" => '(C)',	# <copy> copyright
	"\xAB" => '<<',		# <laquo> angle quotation mark (left)
	"\xAC" => '-',		# <not> negation
	"\xAE" => '(R)',	# <reg> registered trademark
	"\xB1" => '+-',		# <plusmn> plus-or-minus
	"\xB4" => '\'',		# <acute>
	"\xB5" => 'u',		# <micro>
#	"\xB6" => '',		# <para> paragraph
	"\xBB" => '>>',		# <raquo> angle quotation mark (right)
	"\xBC" => '(1/4)',	# <frac14> fraction 1/4
	"\xBD" => '(1/2)',	# <frac12> fraction 1/2
	"\xBE" => '(3/4)',	# <frac34> fraction 3/4
    },

    "\xC3" => {
	"\x97" => 'x',		# <times> multiplication
	"\xB7" => '/',		# <divide> division
    },

    "\xCF" => {
	"\x80" => 'PI',		# <pi>
    },

    "\xE2\x80" => {
	"\x82" => '  ',		# <ensp> en space
	"\x83" => '  ',		# <emsp> em space
	"\x85" => ' ',		# <qemsp>
	"\x93" => ' - ',	# <ndash> en dash
	"\x94" => ' -- ',	# <mdash> em dash
	"\x95" => '--',		# <horizontal bar>
	"\x98" => '`',		# <soq>
	"\x99" => '\'',		# <scq>
	"\x9C" => '"',		# <doq>
	"\x9D" => '"',		# <dcq>
	"\xA2" => '::',		# <diamond symbol>
	"\xA6" => '...',	# <hellip> horizontal ellipsis
	"\xB0" => '%.',		# <permil> per mille
    },

    "\xE2\x82" => {
	"\xAC" => 'Euro'	# <euro>
    },

    "\xE2\x84" => {
	"\x85" => 'c/o',	# <care/of>
	"\x97" => '(P)',	# <sound recording copyright>
	"\xA0" => '(SM)',	# <servicemark>
	"\xA2" => '(TM)',	# <trade> trademark
	"\xA6" => 'Ohm',	# <Ohm>
    },

    "\xE2\x85" => {
	"\x93" => '(1/3)',
	"\x94" => '(2/3)',
	"\x95" => '(1/5)',
	"\x96" => '(2/5)',
	"\x97" => '(3/5)',
	"\x98" => '(4/5)',
	"\x99" => '(1/6)',
	"\x9B" => '(1/8)',
	"\x9C" => '(3/8)',
	"\x9D" => '(5/8)',
	"\x9E" => '(7/8)',
	"\x9F" => '1/',
    },

    "\xE2\x86" => {
	"\x90" => '<--',	# <larr> left arrow
	"\x92" => '-->',	# <rarr> right arrow
	"\x94" => '<-->',	# <harr> left right arrow
    },

    "\xE2\x88" => {
	"\x82" => 'd',		# partial differential
	"\x9E" => 'infinity',
    },

    "\xE2\x89" => {
	"\xA0" => '!=',		# <neq>
	"\xA4" => '<=',		# <leq>
	"\xA5" => '>=',		# <geq>
    }
);


#
# Gather information about header, footer, hyperlinks, images, footnotes etc.
#

my $rels = `$unzip  -p $infile  word/_rels/document.xml.rels 2> /dev/null`;

my %docurels;
while ($rels =~ /<Relationship Id="(.*?)" Type=".*?\/([^\/]*?)" Target="(.*?)"( .*?)?\/>/g) {
    $docurels{"$2:$1"} = $3;
}

#
# Subroutines for center and right justification of text in a line.
#

sub justify {
    my $len = length $_[1];

    if ($_[0] eq "center" && $len < ($config_lineWidth - 1)) {
        return ' ' x (($config_lineWidth - $len) / 2) . $_[1];
    } elsif ($_[0] eq "right" && $len < $config_lineWidth) {
        return ' ' x ($config_lineWidth - $len) . $_[1];
    } else {
        return $_[1];
    }
}

#
# Subroutines for dealing with embedded links and images
#

sub hyperlink {
    my $hlrid = $_[0];
    my $hltext = $_[1];
    my $hlink = $docurels{"hyperlink:$hlrid"};

    $hltext =~ s/<[^>]*?>//og;
    $hltext .= " [HYPERLINK: $hlink]" if (lc $config_showHyperLink eq "y" && $hltext ne $hlink);

    return $hltext;
}

#
# Subroutines for processing paragraph content.
#

sub processParagraph {
    my $para = $_[0] . "$config_newLine";
    my $align = $1 if ($_[0] =~ /<w:jc w:val="([^"]*?)"\/>/);

    $para =~ s/<.*?>//og;
    return justify($align,$para) if $align;

    return $para;
}

#
# Text extraction starts.
#

my %tag2chr = (tab => "\t", noBreakHyphen => "-", softHyphen => " - ");

$content =~ s/<?xml .*?\?>(\r)?\n//;

# Remove the field instructions (instrText) and data (fldData).
$content =~ s|<w:instrText[^>]*>.*?</w:instrText>||og;
$content =~ s|<w:fldData[^>]*>[^<]*?</w:fldData>||og;

# Mark cross-reference superscripting within [...].
$content =~ s|<w:vertAlign w:val="superscript"/></w:rPr><w:t>(.*?)</w:t>|[$1]|og;

$content =~ s{<w:(tab|noBreakHyphen|softHyphen)/>}|$tag2chr{$1}|og;

my $hr = '-' x $config_lineWidth . $config_newLine;
$content =~ s|<w:pBdr>.*?</w:pBdr>|$hr|og;

$content =~ s|<w:numPr><w:ilvl w:val="([0-9]+)"/>|$config_listIndent x $1 . "$levchar[$1] "|oge;

#
# Uncomment either of below two lines and comment above line, if dealing
# with more than 8 level nested lists.
#

# $content =~ s|<w:numPr><w:ilvl w:val="([0-9]+)"/>|$config_listIndent x $1 . '* '|oge;
# $content =~ s|<w:numPr><w:ilvl w:val="([0-9]+)"/>|'*' x ($1+1) . ' '|oge;

$content =~ s{<w:caps/>.*?(<w:t>|<w:t [^>]+>)(.*?)</w:t>}/uc $2/oge;

$content =~ s{<w:hyperlink r:id="(.*?)".*?>(.*?)</w:hyperlink>}/hyperlink($1,$2)/oge;

$content =~ s/<w:p[^>]+?>(.*?)<\/w:p>/processParagraph($1)/oge;

$content =~ s{<w:p [^/>]+?/>|</w:p>|<w:br/>}|$config_newLine|og;
$content =~ s/<.*?>//og;


#
# Convert non-ASCII characters/character sequences to ASCII characters.
#

$content =~ s/(\xC2|\xC3|\xCF|\xE2.)(.)/($splchars{$1}{$2} ? $splchars{$1}{$2} : $1.$2)/oge;

#
# Convert docx specific (reserved HTML/XHTML) escape characters.
#
$content =~ s/(&)(amp|apos|gt|lt|quot)(;)/$escChrs{lc $2}/iog;

#
# Another pass for experimental text experience, after sequences like
# "&amp;laquo;" are converted to "&laquo;".
#
$content =~ s/((&)([a-z]+)(;))/($escChrs{lc $3} ? $escChrs{lc $3} : $1)/ioge if (lc $config_exp_extra_deEscape eq "y");

#
# Write the extracted and converted text contents to output.
#

print OF $content;
close OF;

exit(0);
