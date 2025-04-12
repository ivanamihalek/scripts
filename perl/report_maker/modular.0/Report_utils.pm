#! /usr/bin/perl -w
use strict;

use Carp; # carping and croaking
use FileHandle;

our $EVALUE;

our %path;
our %sequence;
our %map_on_qry;
our %options;

######################################################
sub failure_handle ( @ ) {
    my $msg = $_[0];
    # for now, just print in big letters: failure, an exit
    print "\nFAILURE: $msg\n";
    exit (1); 
}

######################################################
sub prepare_mc_postprocessor ( @) {
    my ($msffile, $out_name, $query_name, $special_name, $stucture_file) = @_;
    my $ret;
    my @names;
    my ($cmd, $fh, $msf_name);
    my $command;

    print "\t\t postprocessing\n";

    $ret = `ls $out_name.*.names`;
    @names = split '\n', $ret;
    $cmd = "align  $msffile\n";
    foreach (@names) {
	$cmd .= "names  $_\n";
    } 
    $cmd .= "query $query_name\n";
    $cmd .= "special $special_name\n";
    $cmd .= "pdbf $stucture_file\n";
    $cmd .= "sink 0.3\n";
   
    $fh = outopen ("cmd");
    print $fh $cmd;
    $fh->close;

    return "cmd";
}


######################################################
sub appopen ( @) {
    my $file = $_[0];
    my $fh = new FileHandle;

    ($fh->open(">> $file")) 
	|| croak  "Error openning $file: $!.";
    return  $fh;
}

######################################################
sub outopen ( @) {
    my $file = $_[0];
    my $fh = new FileHandle;

    ($fh->open("> $file")) 
	|| croak  "Error openning $file: $!.";
    return  $fh;
}

######################################################
sub inopen ( @) {
    my $file = $_[0];
    my $fh = new FileHandle;
    ($fh->open("< $file")) 
	|| croak  "Error openning $file: $!.";
    return  $fh;
}


######################################################
sub do_blast ( @ ) {
    my ($seq, $name, $database, $blast, $output_format, $blastfile) =  @_;
    my $command;
    my $seqfile = $name.".seq";

    (  -e  $blastfile  &&  -s $blastfile)  && return;

    ( defined $seq) || croak "Error: Undefined sequence in do_blast()";
    open ( OF, ">$seqfile") || die "Error: Cno $seqfile:$!.";
    print OF "> $name\n";
    print OF formatted_sequence ($seq), "\n";
    close OF;
    
     
    $command =  "$blast -p blastp  -d $database -i $seqfile -o $blastfile   -m $output_format";
    if ( defined $options{"BLAST_EVAL"} ) {
	$command .= " -e ".$options{"BLAST_EVAL"};
    } else {
	$command .= " -e $EVALUE";
    }
    ( system $command)  && croak "Error: $command\n error running blast."; 
    
}

######################################################
sub read_sequence ( @) {

    my $ctr, 
    my $seqfile = $_[0];
    my $seq = "";
    my $fh;
    my $allowed_aas =  "ABCDEFGHIKLMNPQRSTVWXYZ.-";
    my ($line, @aux);
	
    
    $fh = inopen ($seqfile);
    while ( <$fh> ) {
	next if ( /^>/ );
	$line = uc $_;
	$line =~ s/[\s\.\-]//g;
	@aux = split "", $line;
	foreach ( @aux ) {
	    if ( $allowed_aas !~ $_ ) {
		failure_handle ("unrecognized character in the sequence input: $_");
	    }
	}
	$seq .= $line;
    }
    $fh -> close;
    
    return $seq; 
} 

######################################################
sub formatted_sequence ( @) {

    my $ctr, 
    my $sequence = $_[0];
    ( defined $sequence) || croak "Error: Undefined sequence in formatted_sequence()";
    $ctr = 50;
    while ( $ctr < length $sequence ) { 
	substr ($sequence, $ctr, 0) = "\n";
	$ctr += 51; 
    } 
    
    return $sequence; 
} 

######################################################
sub map_qry (@) {
    my ($to, $from, $msffile) = @_;
    my ($fh, $file, $ret, $command);
    my ($ctr, $sequential_ctr, %seq, $current);
    my ($to_seq, $from_seq);

    print "\t map $from to $to\n";

    # find mapping between query and the model structure
    if ( ! $msffile) {
	$file = "tmp.fasta";
	$fh = outopen ($file);
	print $fh "> $to\n", formatted_sequence($sequence{$to});
	print $fh "\n> $from\n", formatted_sequence($sequence{$from});
	$fh->close;

	$command = $path{"clustalw"}." -infile= $file -outfile= tmp.msf >& /dev/null"; # it would be better to keep the original blast, but oh well
	(system $command) ||  die "Error: $command\nError running clustalw."; # cw exits wit 1 on success

	$msffile = "tmp.msf";
    }

    $to_seq =  `grep $to $msffile | grep -v Name`;
    $to_seq =~ s/$to//g;
    $to_seq =~ s/[\s\n]//g;
    $from_seq =  `grep $from $msffile | grep -v Name`;
    $from_seq =~ s/$from//g;
    $from_seq =~ s/[\s\n]//g;

    @{$seq{$to}} = split "", $to_seq;
    @{$seq{$from}} = split "", $from_seq;

    ( $msffile) || `rm tmp.fasta tmp.msf`;

    $sequential_ctr = 0;
    for $ctr ( 0 .. $#{ $seq{$from}} ) {
	next if ( $seq{$from}[$ctr]  =~ /[\-\.]/ );
	$sequential_ctr ++;
	$map_on_qry{$from}[$sequential_ctr] = $seq{$to}[$ctr].($ctr+1);
	printf " $ctr    $seq{$from}[$ctr]     $sequential_ctr   $map_on_qry{$from}[$sequential_ctr] \n";
    }
    
	
}


######################################################
sub run_fastacmd (@) {
    my ($infile, $database, $outfile) = @_;
    my $command;
    $command = $path{"fastacmd"}." -i $infile -d $database  -o $outfile";
    ( system $command)  && croak "Error: $command\n error running fastacmd."; 
}

######################################################
sub seq_from_uniprot ( @) {

    my  @lines = split '\n', $_[0];
    my ($line, $reading);
    my  ($uniprot_id, $seq);;

    $line = shift @lines;
    ($uniprot_id ) = split " ", $line;

    $reading = 0;
    foreach $line ( @lines ) {
	if ( $line =~  /^SQ/ ) {
	    $reading = 1;
	} elsif ( $reading ) {
	    $seq .= $line;
	}
    }
    $seq =~ s/\s//g;
    $seq =~ s/\///g;
    
    return ($uniprot_id, $seq);
   
}

################################################################################################
sub fasta_names_simplify (@){

    my $fastafile = $_[0];
    my ($inf, $fh);

    $inf = inopen ($fastafile);
    $fh  = outopen ($fastafile."_2");

    while (<$inf>) {
	if ( />\s*gi\|(\d+)\|/ ) { # for gi names
	    print $fh "> $1\n";
	} elsif ( />\s*lcl\|([\w\d_]+)[\s\|]/ ) { # for "extended" uniprot names
	    print $fh "> $1\n";
	} elsif ( />\s*\w+\|\w+[\|\s](\w+)[\|\s]/ ) {
	    print $fh "> $1\n";
	} elsif ( />\s*\w+\|\w+[\|\s]\((\w+)\)[\|\s]/ ) {
	    print $fh "> $1\n";
	} else {
	    print $fh $_;
	}
    }
    
    $inf->close;
    $fh ->close;

    `mv $fastafile\_2  $fastafile`;
}

#######################################################################
sub modification_time (@) {
    my $filename = $_[0];
    my @aux = ();
    if ( -e $filename && -s $filename ) {
	if ( -l $filename ) { # if it's a symlink need different function
                              # otherwise I get the ststs for th file its pointing to
	    @aux = lstat $filename;
	} else {
	    @aux = stat $filename;
	}
	return $aux[9];
    } else {
	return 0;
    }
}

#######################################################################
sub percent (@) {
    my $frac = $_[0];
    my $total =  $_[1];
    if ( ! $total ) {
	return " 0";
    } elsif ( $frac==$total) {
	return " 100";
    } elsif (  $frac/$total < 0.01) {
	return " \$<\$1";
    } else {
 	return sprintf "%5d", int ( 100*$frac/$total);
   }
}
#################################################################################
sub this_and_that ( @) {
    my $last_index = $#_ ;
    my  $retstring;
    my $ctr;

    if ( $last_index == -1) {return ""};
    if ( $last_index ==  0) {return $_[0]};
    if ( $last_index ==  1) {return "$_[0] and $_[1]"};
    
    $retstring = "$_[0]";
    for $ctr ( 1 .. $last_index-1) {
	$retstring  .= ", $_[$ctr]";
    }
    $retstring  .= ", and $_[$last_index]";
    return $retstring;
	
}

#######################################################################

1;
