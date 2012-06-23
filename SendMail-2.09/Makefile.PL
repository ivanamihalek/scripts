# Check for required modules (borrowed from Net::DNS).
$| = 1;
my $missing_modules = 0;

print "Checking for MIME::Base64...";
eval {
	require MIME::Base64;
	MIME::Base64->require_version('2.11');
};
if ($@) {
	print "failed\n";
	$missing_modules++;
	print <<"AMEN";

ERROR: $@
MIME::Base64 is required but the correct version wasn't found.  You must install 
the MIME-Base64-2.11 module (or a newer version) to use SendMail.

AMEN
}
else {
    print "ok\n";
}

if ($missing_modules) {
	die <<"AMEN";
Missing modules can be obtained from the Comprehensive Perl Archive
Network (CPAN) at <URL:http://www.perl.org/CPAN/>.

*** You can't use SendMail until any missing modules are installed ***

AMEN
}

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'SendMail',
    'VERSION_FROM' => 'SendMail.pm', # finds $VERSION
);
