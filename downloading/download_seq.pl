#---------------------------------
#--Execution----------------------
#---------------------------------
#Because the 'magic' line can only hold 32-characters, this script cannot self-execute.
#Instead, execute this script by typing (copy everything after the # to the end of the line):
#/usr/gnu/bin/perl -I/home/concorde/dk131363/bin -I/home/concorde/dk131363/bin/Juan /home/concorde/dk131363/bin/SelectInputToTrace.pl
#-or-
#/usr/gnu/bin/perl -I/home/protean2/LSETtools/utils -I/home/protean5/imihalek/utils/SeqManip /home/protean2/LSETtools/SelectInputToTrace.pl

#But don't forget to add the BLAST file as the command-line parameter!


use Simple;		# these 2 packages for HTML support
require "Parser.pm";	# this one is in the 'Juan' directory

#use SeqManip;		# this package for pruning support based on group deviations

use strict 'subs';	# eliminate bareword syntax
$" = '';		# set list delimiter

# by default, HSP's less than .5 (half) the length of the query sequence are removed
# (although this can be changed with the -cutoff parameter)
$cutoff = .3;

# by default, this program restricts the number of sequences selected
$max_seqs=500;

# by default, sequences with e-values less than the minimum or greater than the
# maximum will be ignored in the BLAST file.
$use_min_evalue = 1;
$min_evalue = convert_Evalues ("1e-200");
$max_evalue = convert_Evalues("0.1");

# by default, sequences with percent identities less than the minimum or greater than the
# maximum will be ignored in the BLAST file.
$min_pid = 20;
$max_pid = 99;

#---------------------------------
#---main() - Start program here---
#---------------------------------
# begin by parsing command-line
CommandLine();

# open the files - quit if that's not possible
open (BLASTFILE, "<" . $ARGV[0]) or die "Error - can't open $ARGV[0]:  $!\n";

# process query information from the blast file (name and length)
while ($line = <BLASTFILE>)
{
  last if $line =~ /^Query=/;
}
die "Error in BLAST file!  Invalid pre-header format!\n" if eof;

$line =~ /^Query=\s+([^. ]+)/;
$Query_name = $1;
if (!$Query_name || $Query_name !~ /\S/)
{
  warn "Warning - found blank query name in Blast file.  Substituting \"Query\".\n";
  $Query_name = "Query";
}

while ($line = <BLASTFILE>)
{
  last if $line =~ /letters/;
}
die "Error in BLAST file!  Invalid pre-header format!\n" if eof;

$line =~ /([\d,]+) letters/;
$Query_length = $1;
if (!$Query_length)
{
  die "Error - can't find query length from Blast file!\n";
}
# remove commas from query length to make it a valid number
$Query_length =~ s/,//g;

print "This program will save the full output returned from NCBI's Entrez Protein search query in \$sequence.seq.  The clipped protein sequence (that is, the portions of the sequence that overlap with the query) will be stored in FASTA format as \$sequence-1.fasta, \$sequence-2.fasta, \$sequence-3.fasta, etc. (one BLAST alignment, or hsp, per file).  Overlaps less than $cutoff times the length of the query sequence will not be saved as a FASTA file.  A maximum of $max_seqs sub-sequences will be generated from the BLAST file.\n";

# get a list of sequences with which to process the alignments
GetSequencesFromBlastHeader();

# get alignment information (query/subject start and end of alignment)
GetAlignmentInfoFromBlastFile();

# make a counter for the total number of sub-sequences processed.
$total = 0;

=pod
Selection procedure:  
	first tier - select if not PDB seq and has evalue in range (ie, not < minimum or > maximum)
	second tier - select if alignment has evalue and sequence identity in range and length
		is > cutoff
	
=cut

# for each sequence in the list, retrieve the full sequence, then clip according to domain
for ($i=0; $i < $numseqs; $i++)
{
	# stop if we have reached our maximum number of sequences
	last if $total >= $max_seqs;

	# skip sequences from PDB because full sequence is duplicated elsewhere
	if ($databases[$i] eq "pdb")
	{
		print "\nIgnoring PDB protein $sequence_IDs[$i] (", $i+1, " of $numseqs).";
		next;
	}
	else
	{	# for all other databases, select a set of sequences to continue with

		# convert the e-value to numerical float
		$e = convert_Evalues ($evalues[$i]);

		# if conversion didn't work, quit (this means the BLAST file is corrupt or invalid)
		if ($e == -1)
		{
			die "Critical error!  Invalid e-value at sequence $sequence_IDs[$i]!\n";
		}
		else
		{
			# if the evalue is less than the minimum, go to next sequence
			if ($use_min_eval == 1 && $e < $min_evalue)
			{
				print "\nIgnoring $sequence_IDs[$i] with e-value below minimum.";
				next;
			}

			# if the evalue is greater than the maximum, then there are no more sequences
			# in the defined range, so stop
			elsif ($e > $max_evalue)
			{
				print "\nProgram stopped at $sequence_IDs[$i] with e-value above maximum.";
				last;
			}
		}

		# if the evalue is in the defined range (the first tier of the selection process),
		# continue processing this sequence:

		print "\nRequesting sequence $sequence_IDs[$i] (", $i+1, " of $numseqs)...\n";

		# retrieve full sequence and clip according to domains
		# (if full sequence cannot be found, an error message will already have been printed out)
		if (!RetrieveFullSequence($sequence_IDs[$i]))
		{
			print "\tSequence $sequence_name found.  Extracting...";

			# this subroutine is where the second tier of the selection process occurs
			ClipSequenceToDomains($i);
		}
	}
}

print "\n\n";
close BLASTFILE;
exit (0);


#-------------------------------------------
#---Usage statement for bad (or no) input---
#-------------------------------------------
sub Usage
# Pre-condition:  nothing
# Post-condition:  halts program, outputing first whatever is passed to this
#  subroutine, then a purpose and usage statement
{ # take the path out of the command name
  # (so ./perlscript or /homes/username/perlscript becomes just perlscript)
  $0 =~ m:.*/([^/]+):; # same as $0 =~ /.*\/([^\/]+)/;
die <<END;
@_
Purpose: *This program reads in a BLAST result file and creates individual
          fasta-format files for each sequence chosen from therein.
         *This program first selects sequences based on their evolutionary
          diversity (as measured by e-value), then based on the sequence
          identity of the local alignment (the BLAST HSP).
         *For each chosen sequence, this program retrieves the full sequence
          using NCBI's Entrez search capabilities and clips the sequence
          based on the BLAST alignment (HSP).
         *The entire Entrez search result (including the full sequence of
          the protein, a description, PID, Accession number, etc.) is
          stored in a file named [protein_id].seq.
         *Since there are multiple HSP's for any given sequence, each
          sub-sequence is stored in a separate file named
          [protein_id-hspnum].fasta.
         *A sub-sequence having an alignment (HSP) less than a given fraction
          of the length of the query sequence (half by default) is not saved
          in a [protein_id-hspnum].fasta file (although all of the information
          needed to create it is stored in the [protein_id].seq and the
          original BLAST file).
         *If identical sub-sequences are found, only the first one encountered
          is stored in a [protein_id-hspnum].fasta file.
         *By default, a maximum number of sub-sequences 500 by default) is
          generated from the BLAST file.

Usage:  $1 [-h] [--] [-i]
        [-cutoff=<cutoff_value>] [-maxseqs=<max_value>]
        [-minevalue=<min_e-value>] [-maxevalue=<max_e-value>]
        [-minpid=<min_pid_value>] [-maxpid=<max_pid_value>]
	[-donotusemineval]
        <blast_file_name>

     --, -h, -help:  prints this usage statement
     -i:  prompts the user for information instead of taking input
          from the command-line
     -cutoff=<cutoff_value>:  (optional) threshhold value at which to determine
                              inclusion of a given sub-sequence.  A sub-sequence
                              having a BLAST alignment (HSP) less than this
                              fraction of the length of the query sequence will
                              not be included.  [default=.50]
     -maxseqs=<max_value>:  (optional) maximum number of sub-sequences to generate
                            from the BLAST results.  [default=500]
     -minevalue=<min_e-value>:  (optional) minimum e-value a sequence may have to
                                be selected.  [default=1e-150]
     -maxevalue=<max_e-value>:  (optional) maximum e-value a sequence may have to
                                be selected.  [default=0.05]
     -minpid=<min_pid_value>:  (optional) minimum percent identity a local
                               alignment may have to be selected.  [default=40]
     -maxpid=<max_pid_value>:  (optional) maximum percent identity a local
                               alignment may have to be selected.  [default=95]
     -donotusemineval:  (optional) does not use minimum e-value cutoff
     <blast_file_name>:  only required input - the name of the BLAST file
                         containing the sequences to retrieve and clip.  Must
                         be last command-line parameter.
END
} # end sub Usage


#-------------------------------------------
#---parse command-line parameters-----------
#-------------------------------------------
sub CommandLine
# Pre-condition:  nothing
# Post-condition:  @ARGV has one element corresponding to the name of the input
#  file and has set environment variables based on other user inputs.  If no
#  user input is specified, Usage statement is printed and program halts.
{

# if no command-line parameters or if the first parameter is -h, --, or -help,
# then print usage statement and halt program
  Usage() if (!@ARGV || $ARGV[0] eq "-h" || $ARGV[0] eq "--" || $ARGV[0] eq "-help");

# if -i is present as the only command-line parameter, ask user for input
  if ($#ARGV == 0 && $ARGV[0] eq "-i")
  {
    # resize ARGV (to contain 1 element)
    $#ARGV=0;

    # get input from the user
    print "Input name of blastp result file:  ";
    chomp ($ARGV[0] = <STDIN>);
    # trip whitespace from the name (the beginning or end)
    $ARGV[0] =~ s/^\s*(.*?)\s*$/$1/;

    print "Specify cutoff threshhold determining inclusion of sub-sequences (default is 0.5):  ";
    $cutoff_value = <STDIN>;
    # check to make sure it is a valid number
    if ($cutoff_value =~ /^([01]?\.[0-9]+)\n$/)
    {
      $cutoff = $1;
    }
    else
    {
      Usage ("Error - cutoff must be a numeric fraction between 0 and 1.\n");
    }

    print "Input maximum number of sequences to return (default is 500):  ";
    $max_seqs = <STDIN>;
    # check to make sure it is a valid number <1000 and >= 10
    if ($max_seqs =~ /^([0-9]{2,3})\n$/)
    {
      $max_seqs = $1;
    }
    else
    {
      Usage ("Error - maximum number of sequences must be a numeric value between 10 and 1000.\n");
    }

    print "Specify minimum e-value determining inclusion of sub-sequences (default is 1e-150):  ";
    $min_evalue = <STDIN>;
    if ($min_evalue =~ /([0-9]?e-[0-9]{1,3}|[01]?\.[0-9]{1,3})\n$/)
    {
      $min_evalue = convert_Evalues($1);
    }
    else
    {
      Usage ("Error - invalid e-value.\n");
    }

    print "Specify maximum e-value determining inclusion of sub-sequences (default is 0.05):  ";
    $max_evalue = <STDIN>;
    if ($max_evalue =~ /([0-9]?e-[0-9]{1,3}|[01]?\.[0-9]{1,3})\n$/)
    {
      $max_evalue = convert_Evalues($1);
    }
    else
    {
      Usage ("Error - invalid e-value.\n");
    }

    print "Specify minimum percent identity determining inclusion of sub-sequences (default is 40):  ";
    $min_pid = <STDIN>;
    # check to make sure it is a valid number <= 99 and >= 0
    if ($min_pid =~ /^([0-9]{1,2})\n$/)
    {
      $min_pid = $1;
    }
    else
    {
      Usage ("Error - invalid percent identity value.  (If you want 40%, for example, input 40).\n");
    }

    print "Specify maximum percent identity determining inclusion of sub-sequences (default is 40):  ";
    $max_pid = <STDIN>;
    # check to make sure it is a valid number <= 99 and >= 0
    if ($max_pid =~ /^([0-9]{1,2})\n$/)
    {
      $max_pid = $1;
    }
    else
    {
      Usage ("Error - invalid percent identity value.  (If you want 40%, for example, input 40).\n");
    }

    # done with asking for command-line parameters
    return;
  }

#---parse command-line arguments containing switches---
  while ($_ = $ARGV[0], $_ && /^-/)
  {
    # get argument after switch
    shift @ARGV;

    # if there is no argument, output usage statement and quit
    if (!@ARGV)
    {
      Usage("Error - use of switch without corresponding value.\n");
    }

    # otherwise, check if cutoff and is a valid number
    elsif (/^-cutoff=([01]?\.[0-9]+)$/)
    {
      $cutoff = $1;
    }

    # otherwise, check if max sequences and is a valid number <1000 and >= 10
    elsif (/^-maxseqs=([0-9]{2,3})$/)
    {
      $max_seqs = $1;
    }

    # otherwise, check if min_evalue and is a valid number
    elsif (/^-minevalue=([0-9]?e-[0-9]{1,3}|[01]?\.[0-9]{1,3})/)
    {
      $min_evalue = convert_Evalues($1);
    }

    # otherwise, check if max_evalue and is a valid number
    elsif (/^-maxevalue=([0-9]?e-[0-9]{1,3}|[01]?\.[0-9]{1,3})/)
    {
      $max_evalue = convert_Evalues($1);
    }

    # otherwise, check if min percent identity and is a valid number
    elsif (/^-minpid=([0-9]{1,2}$)/)
    {
      $min_pid = $1;
    }

    # otherwise, check if max percent identity and is a valid number
    elsif (/^-maxpid=([0-9]{1,2}$)/)
    {
      $max_pid = $1;
    }

    elsif (/^-donotusemineval/)
    {
      $use_min_evalue=0;
    }

    # otherwise, output usage statement and quit
    else
    {
      Usage("Invalid command-line parameters.\n");
    }
  }
  
# if no command-line parameters after the switches:
#  Usage("Please specify the filenames.\n") if (!@ARGV);

# if an incorrect number of command-line parameters:
  Usage("Invalid command-line parameters.\n") if ($#ARGV != 0);
} # end sub Command-Line


#-------------------------------------------
#----------Parse BLAST header---------------
#-------------------------------------------
sub GetSequencesFromBlastHeader()
# Pre-condition:  BLASTFILE is open at beginning of file
# Post-condition:  BLASTFILE is positioned at end of header,
# and the list of sequences has been processed, yielding:
#   int numseqs = number of sequences in BLAST header
#   array databases = database each sequence originated from
#   array sequence_IDs = sequence ID for each sequence
{
        # position file at beginning of list of sequences
	while ($line = <BLASTFILE>)
	{
		last if $line =~ /^Sequences producing significant alignments/;
	}
	die "Error in BLAST file!  Invalid header format!\n" if eof;
        <BLASTFILE>;
	die "Error in BLAST file!  Invalid header format!\n" if eof;

        $numseqs=0;
        while ($line = <BLASTFILE>)                     # parse list of sequences
        {
                last if $line eq "\n";

                # Extract: (1) database, (2) sequence ID, (3) sequence description
                $line =~ /^([^|]*)\|([^|]*)\|(.*) +\d+\s+(\S+)\s*$/ or
			die "Can't match BLAST header!\n";

		# store the e-value of this sequence
		@evalues = (@evalues, $4);

                # store database and sequence ID info
                if ($1 ne "pir")
                {
                        @databases = (@databases, $1);
                        @sequence_IDs = (@sequence_IDs, $2);
                }
                else
                {
                        # PIR stores sequence ID in the description field
                        $3 =~ /([^ ]+) .*/;
                        @databases = (@databases, "pir");
                        @sequence_IDs = (@sequence_IDs, $1);
                }

                # increment number of sequences found
                $numseqs++;
        }
	die "Error in BLAST file!  Invalid header format!\n" if eof;
}


#-------------------------------------------
#----------Parse BLAST alignments-----------
#-------------------------------------------
sub GetAlignmentInfoFromBlastFile()
# Pre-condition:  BLASTFILE is open and positioned at beginning of alignments
#                 numseqs = number of sequences in BLASTFILE header
#                 sequence_IDs = sequence IDs of all sequences from
#   header portion of BLASTFILE
#                 Number of sequences in alignment portion of BLASTFILE =
#   number of sequences in the header portion
#                 Order of sequences in alignment portion of BLASTFILE =
#   that of sequences in the header portion
# Post-condition:  BLASTFILE is positioned at end of $numseqs alignments,
#                  and the alignment info has been processed, yielding:
#   array NUMALIGNMENT = number of alignments for the given sequence,
#     indexed by the order of the sequences in the header portion of the
#     BLASTFILE
#   2-Dimensional arrays QUERY_BEGIN, QUERY_END, SUBJECT_BEGIN, and SUBJECT_END
#     whose values represent the beginning and ending locations of the query
#     and subject sequences for each alignment in the BLASTFILE;
#     the first dimension corresponds to the order of the sequences in the
#     header portion of the BLASTFILE; the second corresponds to the
#     alignment position (with the number of alignments given by NUMALIGNMENT)
{
        # initialize variables (store them privately and locally)
        my $current_protein_index=-1;                                   # indexes proteins
        my $hspnum=-1;                                                  # indexes alignments
        my ($query_Begin, $sbjct_Begin, $query_End, $sbjct_End);        # stores alignment info

        # parse alignments
        while ($line = <BLASTFILE>)
        {
                last if $line =~ /^  Database: /;

		# start next alignment
                if ($line =~ /^>/)
                {
                        # store number of alignments of current protein
			# (unless this is the first alignment)
                        $NUMALIGNMENT[$current_protein_index]=$hspnum if $current_protein_index != -1;

                        # set variables for next protein
                        $hspnum=0;
                        $current_protein_index++;

                        if ($current_protein_index >= $numseqs)
			{
				warn "Error - After processing all the sequences in the BLAST header ($numseqs sequences), BLAST file did not end as expected.  Any remaining text will be ignored.  (Perhaps there are more sequences shown in the alignment portion of the BLAST file than the header portion?  If so, they will be ignored...)\n";
				last;
			}

                        # warn (but continue program) if sequence ID not found
                        if ($line !~ /$sequence_IDs[$current_protein_index]/)
                        {
				warn "Error? - Sequence ID $sequence_IDs[$current_protein_index] not found in the first line of its respective alignment.\n";
			}
                }

                # if alignment did not start yet, BLASTFILE does not contain valid BLAST output
                if ($hspnum < 0)
		{
			die "Error - invalid BLAST format!  Did not encounter an alignment.\n";
		}

		# first line of alignment is the Score - find it
                if ($line !~ /^ Score/)
		{
			while ($line = <BLASTFILE>)
			{
				last if $line =~ /^ Score/;
			}
			die "Error in BLAST file!  Invalid alignment format!\n" if eof;
		}

		# in the same score line, find the e-value of this alignment
		if ($line !~ /^ Score = .*Expect = ([0-9]?e-[0-9]{1,3}|[0-9]?\.[0-9]{1,3})$/)
		{
			die "Error - invalid BLAST format!  Coult not find e-value in alignment.\n";
		}

		# store the e-value of this alignment
		$EVALUES[$current_protein_index][$hspnum] = $1;

		$line = <BLASTFILE>;                     # next line is Identities
		die "Error in BLAST file!  Invalid alignment format!\n" if eof;

		# in the identity line, find the percent identity of this alignment
		if ($line !~ /^ Identities = \d+\/\d+ \((\d+)%\),/)
		{
			die "Error - invalid BLAST format!  Coult not find percent identity in alignment.\n";
		}

		# store the percent identity of this alignment
		$IDENTITIES[$current_protein_index][$hspnum] = $1;

                <BLASTFILE>;                                           # next is an empty line
		die "Error in BLAST file!  Invalid alignment format!\n" if eof;

                # if Score and Identities line found, initialize variables for start of alignment
                $query_Begin = 0;
                $sbjct_Begin = 0;

                # next line should be either a blank line (next alignment) or the query sequence
                while ($line = <BLASTFILE>)             # extract info from an individual alignment
                {
                        last if $line =~ /^$/;

                        if ($line !~ /^Query: (\d+) +.* (\d+)$/)    # extract query begin and end
                        {
				die "Error - invalid BLAST format!  Could not find Query line.\n";
			}

                        # store query begin if first time it is encountered
                        $query_Begin = $1 if $query_Begin == 0;

                        # store query end (will be successively overwritten and updated)
                        $query_End = $2;

                        # next line is a consensus - discard
                        <BLASTFILE>;
			die "Error in BLAST file!  Invalid alignment format!\n" if eof;

			# next line is Subject - extract begin and end
                        if (<BLASTFILE> !~ /^Sbjct: (\d+) *.* (\d+)$/)
                        {
				die "Error - invalid BLAST format!  Could not find Sbjct line.\n";
			}

                        # store subject begin if first time it is encountered
                        $sbjct_Begin = $1 if $sbjct_Begin == 0;

                        # store subject end (will be successively overwritten and updated)
                        $sbjct_End = $2;

                        <BLASTFILE>;    # discard empty line
                }
		die "Error in BLAST file!  Invalid alignment format!\n" if eof;

                # store query begin and end and subject begin and end in permenant, global variables
                $QUERY_BEGIN[$current_protein_index][$hspnum] = $query_Begin;
                $QUERY_END[$current_protein_index][$hspnum] = $query_End;
                $SUBJECT_BEGIN[$current_protein_index][$hspnum] = $sbjct_Begin;
                $SUBJECT_END[$current_protein_index][$hspnum] = $sbjct_End;
                $hspnum++;
        }
	die "Error in BLAST file!  Invalid alignment format!\n" if eof;

        $NUMALIGNMENT[$current_protein_index] = $hspnum;

        if ($current_protein_index+1 != $numseqs)
        {
		warn "Error - end of BLAST alignments occurred before processing all the sequences in the BLAST header (processed ", $current_protein_index+1, " of $numseqs sequences).  Perhaps there are less sequences shown in the alignment portion of the BLAST file than the header portion?\n";
		$numseqs = $current_protein_index+1;
	}
}


#-------------------------------------------
#----------Retrieve Full Sequence-----------
#-------------------------------------------
sub RetrieveFullSequence
# Pre-condition:  first argument = ID of sequence to retrieve from Entrez's Protein search engine
# Post-condition:
#   $sequence_description = full description field, a single line (FASTA requires this)
#   $sequence_name = NCBI's name for this protein (w/ no periods)
#   $sequence_full = full sequence of amino acids for this protein (one-line string)
#   $sequence_length = length of full sequence
#   $sequence_type = DNA or mRNA if sequence length is followed by 'bp' rather than 'aa'
#   All info retrieved from NCBI has been stored in the file $sequence_name.seq (including full
#       sequence, desccription, etc.)
#   Any error in NCBI output (perhaps a message indicating the database is down for the day) is stored
#	in a sequence-specific output file called Error_log_from_sequence_retrieval_of_$sequence_ID
#	and an appropriate message is output to the screen
#   Return value = error indicator:  0 indicates successful completion, while a non-zero value
#       indicates that an error in sequence retrieval or processing occurred at some point
#   Screen output:  no newlines printed to screen in error messages (to preserve formatting)
{
    # go to NCBI's Entrez Protein search batch-query URL and ask for sequence in Genpept/text format
    $htmlfile = get "http://www.ncbi.nlm.nih.gov/htbin-post/Entrez/query?db=s&form=6&Dopt=g&html=no&dispmax=1024&uid=$_[0]" || "";

    # if no response, output error message and return error code 1
    if (!$htmlfile)
    {
       print "\tCannot retrieve sequence!";
       return 1;
    }
    else
    {

      # if response is valid, check to make sure that the results do not contain multiple proteins;
      # if such an event occurs (probably due to an ambiguous sequence ID), output error message and
      # return error code 2
      if ($htmlfile =~ /\nPID\s.*\nPID/s)
      {
        print "\tAmbiguous sequence ID:  multiple Entrez reports returned.";
        return 2;
      }
      else
      {

        # if unique protein sequence found, search for sequence information from the results;
        # if not found, output error message, save NCBI's output in an error file, and return
        # error code 3
        if ($htmlfile !~ m#DEFINITION  (.*)ACCESSION   ([0-9A-Za-z_]+).*ORIGIN\s+(.*)//#s)
        {
	    print "\tError - can't find sequence $_[0] in output from sequence retreival.";
	    print "  Read Error_log_from_sequence_retrieval_of_$_[0] for details.";
	    open (ERROR_LOG, ">Error_log_from_sequence_retrieval_of_$_[0]") or
		die "Error - can't open Error_log_from_sequence_retrieval_of_$_[0] for output!\n";
	    print ERROR_LOG 
		"Attempted to read sequence $_[0] failed.  Attempt returned:\n", $htmlfile, "\n\n";
	    close ERROR_LOG;
	    return 3;
        }
        else
        {

          # if sequence information found, save the information
          $sequence_description = $1;
          $sequence_name = $2;
          $sequence_full = $3;

          # now, process the information to ensure that sequence is protein and not DNA or mRNA
          $htmlfile =~ /LOCUS *[^ ]* *([0-9]*) ([ab][ap])    (....)/ or
              warn "Error!  Can't identify sequence type!\n";
          $sequence_length = $1;
          $sequence_type = $3;
          chomp $sequence_type;

          # if sequence is not protein, output error message and return error code 4
          if ($2 ne "aa")
          {
            print "\tIgnoring $sequence_type sequence.";
            return 4;
          }
          else
          { # if sequence is protein, continue processing information

            # strip periods from the sequence name (ex: convert ABC.1 to ABC)
            $sequence_name =~ /([^.]*)/;
            $sequence_name = $1;

            # remove newlines from sequence description (to make it a single-line string)
            $sequence_description =~ s/\n */ /g;

            # convert Genpept format into raw sequence (single-line, no spaces or numbers, etc.)
            $sequence_full =~ s/^ *[0-9]+//mg;	# remove starting numbers from the sequence
            $sequence_full =~ s/ //g;		# remove spaces within the sequence
            $sequence_full =~ s/\n//g;		# convert the sequence to a single-line string

            # save NCBI's output to a sequence file (Genpept format) named $sequence_name.seq
            if (open (FILE, ">" . $sequence_name . ".seq"))
            {
              print FILE $htmlfile;
              close FILE;
            }
            else
            {
              warn "Error!  Could not open $sequence_name.seq for output!\n";
            }

            # if processing proceeded this far without an error code, indicate that the sequence was
            # found by a return error code of 0 (indicating successful completion)
            return 0;

# if you have reached this point then the following are true:
#   return value is 0
#   $sequence_description = full description field, a single line (FASTA requires this)
#   $sequence_name = NCBI's name for this protein in ABC format (w/ no periods)
#   $sequence_full = full sequence of amino acids for this protein (one-line string)
#   $sequence_length = length of full sequence
#   $sequence_type = DNA or mRNA if sequence length is followed by 'bp' rather than 'aa'
#   All info retrieved from NCBI has been stored in $sequence_name.seq (including full sequence, desccription, etc.)
          }	# sequence is DNA
        }	# correct sequence retrieval
      }		# single PID found for a given sequence ID
    }		# GET command succeeded

    return 0;	# (will never be executed)
}


#-------------------------------------------
#----------Clip Sequence to Domain----------
#-------------------------------------------
sub ClipSequenceToDomains
# Pre-condition:  RetrieveFullSequence and GetAlignmentInfoFromBlastFile have
#		  completed successfully and all of their variables are accessible.
#		  $Query_length = length of query sequence
#		  first argument = index of GetAlignmentInfoFromBlastFile arrays
#			corresponding to the protein sequence to clip
#		  $total = running total of number of sequences processed so far 
# Post-condition:  The full sequence from RetrieveFullSequence is broken down into
#		   domains and clipped accordingly using the alignment info from
#		   GetAlignmentFromBlastFile.  An appropriate message is output to
#		   the screen (with no newlines).  Each clipped domain region is
#		   saved to a file named $sequence_name-#.fasta, where # indicates
#		   the #th alignment in the BLAST file corresponding to that domain.
#		   The running total is updated.
{

	# for each alignment this sequence has, generate a subsequence/domain
	for ($j=0; $j < $NUMALIGNMENT[$_[0]]; $j++)		# j = HSP (BLAST alignment) index counter
	{
		# stop if maximum number of sequences is reached
		last if $total >= $max_seqs;

		# sequence alignment is skipped if region of homology (in the BLAST alignment)
		# is less than cutoff * query length
		if (($QUERY_END[$_[0]][$j] - $QUERY_BEGIN[$_[0]][$j]) < ($Query_length * $cutoff))
		{
			print "(Ignored - region of homology less than $cutoff * query length)";
			next;
		}

		# convert e-value of alignment to a floating-point representation
		$e = convert_Evalues ($EVALUES[$_[0]][$j]);

		# sequence is skipped if evalue of alignment is below minimum
		if ($use_min_eval == 1 && $e < $min_evalue)
		{
			print "(Ignored - alignment has e-value below minimum)";
			next;
		}

		# sequence is skipped if evalue of alignment is above maximum
		if ($e > $max_evalue)
		{
			print "(Ignored - alignment has e-value above maximum)";
			next;
		}

		# sequence is skipped if sequence identity below minimum
		if ($IDENTITIES[$_[0]][$j] < $min_pid)
		{
			print "(Ignored - alignment has sequence identity below minimum)";
			next;
		}

		# sequence is skipped if sequence identity above maximum
		if ($IDENTITIES[$_[0]][$j] > $max_pid)
		{
			print "(Ignored - alignment has sequence identity above maximum)";
			next;
		}

		# find correct beginning point of subject domain (corresponding to query position 1, if possible)
		$start = $SUBJECT_BEGIN[$_[0]][$j] - ($QUERY_BEGIN[$_[0]][$j] - 1);
		$start = 1 if $start < 1;

		# find correct ending point of subject domain (corresponding to end of query sequence, if possible)
		$end = $SUBJECT_END[$_[0]][$j] + ($Query_length - $QUERY_END[$_[0]][$j]);
		$end = $sequence_length if $end > $sequence_length;

		# clip subject sequence to its correct beginning and ending point to find domain region
		$length = $end - $start;
		$sequence_clipped = substr $sequence_full, $start-1, $length;

		# save domain information in a sequence- and domain-specific file, use FASTA format,
		# name sequence according to sequence name, ID, domain positions (beginning and ending point),
		# and the first 70 characters of the sequence description
		if (open (FILE, ">" . $sequence_name . '-' . ($j+1) . ".fasta"))
		{
			print FILE "> $sequence_name-", $j+1, " : $start->$end; ($sequence_IDs[$_[0]]) ", substr ($sequence_description, 0, 70), "\n";

			# the following loop converts a raw sequence format (single-line sequence) into FASTA format
			$index=1;
			while ($length > 50*$index)		# print sequence in FASTA format using 50 aa per line
			{
				print FILE substr $sequence_clipped, 50*($index-1), 50;
				print FILE "\n";
				$index++;
			}
			print FILE substr $sequence_clipped, 50*($index-1), 50;
			print FILE "\n";
			close FILE;
		}
		else
		{
			warn "Error!  Cannot open $sequence_name-", ($j+1), ".fasta for output!\n";
		}

		# print to screen the name of the sequence domain
		print " $sequence_name-", $j+1;

		# update the running total of sub-sequences
		$total++;
	}
}


#-------------------------------------------
#----------Select Sequences-----------------
#-------------------------------------------
sub SelectSequence
# Pre-condition:  
#		  first argument = index of GetAlignmentInfoFromBlastFile arrays
#			corresponding to the given protein sequence to
#                       select or reject
# Post-condition:  
{



}


sub convert_Evalues
{
	# if the parameter is a number of the form x.y where x=0 or 1 (0 or
	# 1 digit) and y=1 to 3 digits (from 0-9), then this is already a
	# floating-point number, so return it unchanged
	return $_[0] if $_[0] =~ /^[01]?\.[0-9]{1,3}$/;

	# otherwise, extract the base and exponent portions of the e-value
	# if it matches the form xe-y where x=0-9 (0 or 1 digit) and
	# y=1 to 3 digits (from 0-9)
	# if the parameter is not a valid e-value, return 1
	return -1 if $_[0] !~ /([0-9]?)e-([0-9]{1,3})/;

	# if the base exists, extract it, otherwise set it to 1
	# (for values of the form 'e-y')
	$base = $1;
	$base = 1 if !$1;

	# if the exponent exists (it must or the pattern wouldn't
	# match), extract it
	$exponent = $2;

	# return the floating-point representation of this e-value
	# (base * 10 ^ - exponent)
	return $base * 10 ** -$exponent;
}

__END__

=pod
(Plain-Old-Documentation)

How to use these subroutines:

query info:
print "Name:  $Query_name\nLength:  $Query_length\n";

blast parsing:
print "Found $numseqs sequences:\n";
for ($i=0; $i < $numseqs; $i++)
{ print "Sequence $sequence_IDs[$i] originating from $databases[$i] has $NUMALIGNMENT[$i] alignments:\n";
  for ($j=0; $j < $NUMALIGNMENT[$i]; $j++)
  { print "\t$sequence_IDs[$i]-", $j+1, ": Query ", $QUERY_BEGIN[$i][$j], "->", $QUERY_END[$i][$j], ", Subject ", $SUBJECT_BEGIN[$i][$j], "
->", $SUBJECT_END[$i][$j], "\n";
  }
}

sequence retrieval:
print "\nName:  $sequence_name\nLength:  $sequence_length\nType (blank for protein):  $sequence_type\nDescription:  $sequence_description\nSequence:  $sequence_full\n";

sequence clipping to domains:
output is stored in files but not in memory

=cut

#$baseURL = "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Search&db=Protein&term=";
#$URL = $baseURL . $sequence_identifiers{$key} . "&doptcmdl=GenPept";
#    $htmlfile = get $URL;
#GET /htbin-post/Entrez/query?db=s&form=6&Dopt=g&html=no&dispmax=1024&uid=
# http://ca.expasy.org/cgi-bin/get-sprot-fasta?name

