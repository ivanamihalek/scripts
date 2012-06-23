
#!/usr/bin/perl -W
use Net::FTP;

### ZIP stuff
# name of the zip binary
$zip = "zip";
# switches for zip
$zip_switches = "-p -r";
# what we will call the file locally and on the server
$zip_file = "backup.zip";
print "Directory to ZIP: ";
# if you will always be zipping one directory and want to skip
# this prompt substitue <STDIN> below with the directory in quotes
# I always use * and zip the current directory the script is in
chomp ($zip_dir = <STDIN>);

### FTP stuff
$ftp_site = "ftp.example.com";
# path to store the file (probably relative to your home directiory)
$remote_file = "ftp/relative/path/to/store/backup/".$zip_file;
# your username
$username = "username";
print "Password: ";
# I recommend against this, but you can also skip this prompt
# by adding your password on the FTP server here in quotes
system("stty -echo");
chomp ($password = <STDIN>);
system("stty echo");

### Create the ZIP ile
if($zip_dir) {
   print "Recursively compressing [$zip_dir]... ";
   system("$zip $zip_switches $zip_file $zip_dir");
   print "[done]\n"
}

### FTP the ZIP file
if ($ftp_site && $remote_file && $zip_file && $username && $password) {
   print "FTP: Logging in [$username]... ";
   $ftp = Net::FTP->new($ftp_site, Hash => 1) or die "FTP: Could not connect: $@.";
   $ftp->login($username, $password) or die "FTP: Could not login.";
         print "[done]\n";
         print "FTP: Changing to binary mode... ";
   $ftp->binary() or die "FTP: Couldn't specify binary type.";
         print "[done]\n";
         print "FTP: Sending to file [$remote_file]: ";
   $ftp->put($zip_file, $remote_file) or die "FTP: Could not put $remote_file.";
         print "\nFTP: Tranfer complete\n";
         print "FTP: Closing connection... ";
   $ftp->quit() or die "FTP: Couldn't quit.";
         print "[done]\n";
   #delete zip file
   print "Deleting ZIP file [$zip_file]... ";
   unlink($zip_file) or die "Unable to remove $zip_file from the system.";
   print "[done]\n";
   #show that we are done
   sleep(10);
}

#Quit
exit(0);
