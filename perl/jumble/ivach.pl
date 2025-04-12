#!/usr/bin/perl -w


use Mail::Sendmail;

undef $/;
$msg_txt = <>;
$/ = "\n";


%mail = (
    To      => '<ivica.res@gmail.com>',
    From    => 'Buggy The Pest <ivana.mihalek@gmail.com>',
    # Cc will appear in the header. (Bcc will not)
    #Cc      => 'Yet someone else <xz@whatever.com>',
    Subject => 'tup tup',
    'X-Mailer' => "Mail::Sendmail version $Mail::Sendmail::VERSION",
    );




$mail{Smtp} = 'smtp.bii.a-star.edu.sg';
$mail{'X-custom'}   = 'My custom additionnal header';
$mail{'mESSaGE : '} = $msg_txt;
# cheat on the date:
$mail{Date} = Mail::Sendmail::time_to_date( time() - 86400 );

if (sendmail %mail) { 
    print "Mail to $mail{To} sent OK.\n" 

} else { 
    print "Error sending mail: $Mail::Sendmail::error \n"; 
    print "\n\$Mail::Sendmail::log says:\n", $Mail::Sendmail::log;

}
