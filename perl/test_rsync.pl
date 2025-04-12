#! /usr/bin/perl

####################################################################################
#
# Copyright 2016-2017 Saphetor SA
# All rights reserved
# Confidential
#
#####################################################################################

use strict;
use warnings FATAL => 'all';
no warnings "once";
use Cwd 'abs_path';
push(@INC, "$1/../modules") if (abs_path($0) =~ /^(.*)\//);
require Common;
require Constants;
$Constants::logFile = 'log';  # [IM any reason why we are setting this here?]
$Constants::doExecute = 1;

# my $sourceDir = "/home/ivana/scratch/src";
# my $targetDir = "/homw/ivana/scratch/tgt";
my $sourceDir = "/scratch/F10653000000/clair/";
my $targetDir = "/home/mihaleki/scratch/tgt";


# opendir my $openDir, "$sourceDir" or  Common::errorExit("Cannot open \'$sourceDir\': $!");
my @unreadable = ();
# see https://stackoverflow.com/questions/30009320/recursively-find-files-that-are-not-publicly-readable
# for the explanation of what's going on with `find` here

foreach my $fullpath (split("\n", `find $sourceDir ! -readable -prune`)) {
    if (-f $fullpath && !-r $fullpath ) {
        push @unreadable, $fullpath;
    }
    elsif (-d $fullpath) { # checking if  a dir is readable is a bit more complicated
        if ( ! opendir my $tmpDirHandle, $fullpath) { # if we fail here, it is not readable
            push @unreadable, $fullpath;
        } else {
            closedir $tmpDirHandle; # close if it is
        }
    }
}
my $exclude = join(" --exclude ", @unreadable);
# there is a cleaner way to organize the excludables, see e.g. here
# https://phoenixnap.com/kb/rsync-exclude-files-and-directories
# but it involves {}, which does not play well with the system command in perl
my $rsyncCommand = "/usr/bin/rsync -vrlu --exclude $exclude '$sourceDir'/ '$targetDir'/ > '$targetDir'/rsync.log 2>&1";
print($rsyncCommand );
Common::executeOrDie($rsyncCommand);

exit(0);

