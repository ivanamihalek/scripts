#!/usr/bin/perl -w
#
# testSendMail.pl -- This is a simple example of using SendMail.pm module
#		     to send a mail.
#
# Notes:
#   1) This script is run in command line only, it is not a CGI script.
#      If you are looking for CGI script, check SendMail.cgi.
#   2) If this machine, where you run this test script, does not have a
#      SMTP server run on it. You need to modify one of the line:
#		$sm = new SendMail();
#      to
#		$sm = new SendMail("you.smtp.server");
#   3) And change the email addresses when we call $sm->From() and
#      $sm->To().
#
# Simon Tneoh Chee-Boon	tneohcb@pc.jaring.my
# 
# Copyright (c) 1998-2003 Simon Tneoh Chee-Boon. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#

#
# Please refer to
# http://www.tneoh.zoneit.com/perl/SendMail/
# for more information about SendMail.pm module.
#
use SendMail 2.09;

#
# Create the object without any arguments, 
# i.e. localhost is the default SMTP server.
#
$sm = new SendMail;

#
# Set SMTP AUTH login profile.
# Uncomment the following line if you like to try SMTP AUTH.
#
#$sm->setAuth($sm->AUTHLOGIN, "username", "password");
#$sm->setAuth($sm->AUTHPLAIN, "username", "password");

#
# We set the debug mode "ON".
#
$sm->setDebug($sm->ON);

#
# We set the sender.
#
$sm->From("Your Name <yourid\@your.mail.domain>");

#
# We set the subject.
#
$sm->Subject("test");

#
# We set the recipient.
#
$sm->To("Recipient <recipientid\@recipient.mail.domain>");

#
# We set the content of the mail.
#
$sm->setMailBody("test data");

#
# Attach a testing image.
#
$sm->Attach("./welcome.gif");

#
# Check if the mail sent successfully or not.
#
if ($sm->sendMail() != 0) {
  print $sm->{'error'}."\n";
  exit -1;
}

#
# Mail sent successfully.
#
print "Done\n\n";
exit 0;
