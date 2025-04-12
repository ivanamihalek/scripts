#! /usr/bin/perl -w -I/home/i/imihalek/perlscr/SendMail-2.09

use SendMail;

$smtpserver	     = "watson.bcm.tmc.edu";
$smtpport	     = 25;
$sender		     = "report_maker <etreport\@bcm.tmc.edu>";
$subject	     = "Error running report_maker";
$recipient	     = "report_maker <etreport\@bcm.tmc.edu>";
$header		     = "X-Mailer";
$headervalue	     = "Perl SendMail Module 1.09";
$mailbodydata	     = "This is	a testing mail.";

$obj = new SendMail();
$obj = new SendMail($smtpserver);
$obj = new SendMail($smtpserver,	$smtpport);

$obj->setDebug($obj->OFF);

$obj->From($sender);

$obj->Subject($subject);

$obj->To($recipient);
 
 

$obj->setMailHeader($header, $headervalue);

$obj->setMailBody($mailbodydata);

if ($obj->sendMail() != 0) {
    print $obj->{'error'}."\n";
}

$obj->reset();

