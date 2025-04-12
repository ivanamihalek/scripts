#! /usr/bin/perl -w
use strict;
use Carp; # carping and croaking

our %copies;
our %path;
our %sequence;
our @unique_chains;
our $TOO_FEW_SEQS;
our $MAX_ID;

###################################################### 
sub run_HSSP( @) {

    my $name = $_[0];
    my $pdbname = substr $name, 0, 4;
    my $chain   = "";
    my ($command, $ret);
    my $hsspfile = $path{"hssp_repository"}."/$pdbname."."hssp";
    my $msffile;

    (length $name > 4) && ($chain = substr $name, 4, 1);

    print "\t\tchecking for the hssp file\n";

    if ( ! -e $hsspfile || ! -s $hsspfile )  {
	`echo $pdbname > tmp`;
	$command = $path{"hssp_download"}." tmp";
	$ret  = `$command`;
	`rm tmp`;
	( !$ret || $ret =~ /failure/) && return 1;
    } 

    return 0;
}

###################################################### 
sub HSSP_chain_check ( @) {

    my $name = $_[0];
    my $pdbname = substr $name, 0, 4;
    my $chain   = "";
    my ($command, $ret, @aux);
    my @chains_in_hssp;
    my $hsspfile = $path{"hssp_repository"}."/$pdbname."."hssp";
    my ($copy, $copy_id, $copy_found, $ctr);

    print "\tHSSP chain check for $name\n";

    (length $name > 4) && ($chain = substr $name, 4, 1);

    if ($chain ) {
	# check if this is the chain given in hssp
	$ret = `grep KCHAIN $hsspfile`;
	if ( $ret ) {
	    @aux = split " ", $ret;
	    @chains_in_hssp = split ",", pop @aux;
	    print "\t\tchains in the hssp: @chains_in_hssp\n";
	    # check if $name is among these
	    if ( grep /$chain/, @chains_in_hssp ) {
		print "\t\t$chain is among them\n";
	    } else {
		$copy_found = 0;
		foreach $copy ( @{$copies{$name}} ) {
		    next if ( (substr $copy, 0, 4) ne $pdbname);
		    ( length $copy >= 5) || croak "Error: copy has no chain id.";
		    $copy_id = substr $copy, 4, 1;
		    if ( grep /$copy_id/, @chains_in_hssp ) {
			print "\t\thssp has $copy_id instead of $chain\n";
			# switsh the original and the copy
			$copy_found = 1;
			for $ctr (0 .. $#unique_chains) {
			    if ( $unique_chains[$ctr] eq $name ) {
				$unique_chains[$ctr] = $copy; 
				last;
			    }
			}
			for $ctr (0 .. $#{$copies{$name}}) {
			    if ( $copies{$name}[$ctr] eq $copy ) {
				@{$copies{$copy}} = @{$copies{$name}};
				delete $copies{$name};
				undef $copies{$name};
				$copies{$copy}[$ctr] = $name;
				print"\t\tnew unique_chains = @unique_chains\n";
				print"\t\tnew copies = @{$copies{$copy}}\n";
				last;
			    }
			}
		    
			last;
		    }
		}
		if ( ! $copy_found ) {
		    print "\t\t no equivalent  of $name found in $hsspfile\n";
		    return 1;
		} 
	    }
	} else {
	    $ret = `grep NCHAIN $hsspfile`; # expect a single chain file
	    if ( $ret !~ /1 chain/ ) {
		print "\t\t error processing $hsspfile\n";
		return 1;
	    }
	    print "\t\t single chain in $hsspfile\n";
	}

    }
    return 0;
}
###################################################### 
sub HSSP2msf ( @) {
    my $name = $_[0];
    my $pdbname = substr $name, 0, 4;
    my ($hsspfile, $msffile, $command,);
    my $chain   = "";
    my $no_seqs;
    my $seq_in_hssp;

    $hsspfile = $path{"hssp_repository"}."/$pdbname."."hssp";
    if ( ! -e  $hsspfile ) {
	print "\t in HSSP2msf: $hsspfile does not exist.\n";
	return 1; 
    }
    $hsspfile = $path{"hssp_repository"}."/$pdbname."."hssp";
    if ( ! -s  $hsspfile ) {
	print "\t in HSSP2msf: $hsspfile empty.\n";
	return 1; 
    }

    $msffile = "$name.hssp.msf"; 
    (length $name > 4) && ($chain = substr $name, 4, 1);

    if ( ! -e $msffile || ! -s $msffile )  { 
	# extract chain and turn into msf 
	$command = $path{"hssp2msf"}." -i $hsspfile -l 0.75"; 
	$chain &&  ( $command .= " -c $chain "); 
	$command .= " > tmp.msf "; 
	(system $command)  && return 1; 
	$command = $path{"remove_id_from_msf"}. " tmp.msf $name $MAX_ID > $msffile";
	(system $command) &&  return 1;  
	( -s $msffile) || return 1; # whatever went wrong here, we proceeed with mc sequence selection
	( -e "tmp.msf") && `rm tmp.msf`;
    }
    $command = "grep Name $name.hssp.msf | awk \'{print \$2}\' > $name.hssp.names"; 
    (system $command)  && croak "Error: $command\nError extracting names from hssp2msf."; 
    ($no_seqs) = split " ", `wc -l $name.hssp.names`;
    ($no_seqs >= $TOO_FEW_SEQS) || return 1;

    #check whether consistent with the sequence in the pdb file:
    
    $seq_in_hssp = `grep $name  $name.hssp.msf | grep -v Name`;
    $seq_in_hssp =~ s/$name//g;
    $seq_in_hssp =~ s/\s//g;
    ($seq_in_hssp eq $sequence{$name}) &&  return 0;

    print "\tin HSSP2msf: HSSP-PDB sequence mismatch.\n";
    return 1;


} 





1;
