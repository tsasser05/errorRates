package MetricsTools;

use Exporter;
use strict;
use vars qw(@ISA @EXPORT $debug);
use warnings;
use diagnostics;
use Net::DNS;
use Net::SSH qw( ssh_cmd ssh );
use Time::Local;
use File::Path;
use Carp;

use base qw( Exporter );
our @EXPORT = qw(convertEEGTimestampToEpoch convertEpochToEEGTimestamp genAccessTimeSearchRange genNavTimeSearchRange getDate getEEGDataCount getLogSlice getAccessLogSlice getAccessLogSliceFilter getNavLogSlice getNavLogSliceFilter getOS pullAccessColumn readFile recursiveDelDir recursiveMkDir snarf splitAccessLogTimeStamp timestamp );


######################################################################
#
# $debug passed in from .pl files
#
# debug modes
#
# 1 includes data
# 2 includes data and status
# 3 includes data, status, and function calls
#
######################################################################



######################################################################
#
# convertEEGTimestampToEpoch($type, $yyyymmdd, $hhmmssnnn)
#
# Converts a timestamp in EEG logs to epoch seconds.
# Variables must be in the correct format.  These formats
# are from the EEG logs.
#
# Timestamp type can be either local or utc.
#
# $type = 'local' or 'utc'
#
# $yyyymmdd = YYYY-MM-DD
#
# $hhmmssnnn = HH:MM:SS,nnn
#
# Returns EPOCH seconds
#
#
######################################################################

sub convertEEGTimestampToEpoch {
  my ($type, $yyyymmdd, $hhmmssnnn) = @_;

  $hhmmssnnn =~ s/,\d+//;
  $hhmmssnnn =~ tr/:-/ /;
  $yyyymmdd =~ tr/-/ /;

  my $ts = "$yyyymmdd $hhmmssnnn";
  my ($sec, $min, $hour, $day, $month, $year) = reverse (split " ", $ts);
  my $epoch;

  if ($type eq "local") {
    $epoch = timelocal($sec, $min, $hour, $day, $month-1, $year-1900);

  } elsif ($type eq "utc") {
    $epoch = timegm($sec, $min, $hour, $day, $month-1, $year-1900);

  } else {
    confess "MetricsTools::convertEEGTimestampToEpoch($type, $yyyymmdd, $hhmmssnnn):  invalid type passed\n";

  }  # if

  return $epoch;

} # convertEEGTimestampToEpoch()


######################################################################
#
# convertEpochToEEGTimestamp($type, $epoch)
#
#
######################################################################

sub convertEpochToEEGTimestamp {
  my ($type, $epoch) = @_;
  my $ts;
  my ($sec, $min, $hour, $day_of_month, $month, $year, $wday, $yday, $isdst);

  if ($type eq "local") {
    ($sec, $min, $hour, $day_of_month, $month, $year, $wday, $yday, $isdst) = localtime($epoch);

  } elsif ($type eq "utc") {
    ($sec, $min, $hour, $day_of_month, $month, $year, $wday, $yday, $isdst) = gmtime($epoch);

  } else {
    confess "MetricsTools::convertEpochToEEGTimestamp($type, $epoch):  invalid type passed\n";

  } # if

  $month += 1;
  $year += 1900;
  my $m = sprintf "%02d", $month;
  my $day = sprintf "%02d", $day_of_month;
  $ts = "$year-$m-$day $hour:$min:$sec";
  return $ts;

} # convertEpochToEEGTimestamp()


######################################################################
#
# genAccessTimeSearchRange($first, $last, $date)
#
# Generates a string suitable for use as a regular expression for
# finding hours in an access_log timestamp DD/Mon/YYYY:HH:MM:SS +ssss
#
# $first = first hour in range to pull
# $last  = last hour in range to pull
# $date  = DD/Mon/YYYY:HH:MM:SS +ssss
#
# Example access_log:
#
# 11/Aug/2010:(00|01|02|03|04|05|06|07|08|09|10|11|12|13|14|15|16|17|18|19|20|21|22|23):[0-9][0-9]:[0-9][0-9]\s\+[0-9][0-9][0-9][0-9]].*
#
#
######################################################################

sub genAccessTimeSearchRange {
   my $first = shift;
   my $last = shift;
   my $date = shift;

   $first = sprintf ("%02d", $first);
   $last = sprintf ("%02d", $last);
   my $range = "$first";

   # TBD .. first+1 may be wrong!
   for (my $x=$first+1; $x<=$last; $x+=1) {
     $x = sprintf("%02d", $x);
     $range .= "|$x";

   } # for

   my $search = "\"$date:($range):[0-9][0-9]:[0-9][0-9].*\"";

   return $search;

} # genAccessTimeSearchRange()


######################################################################
#
# genNavTimeSearchRange($first, $last, $date)
#
# Generates a string suitable for use as a regular expression for
# finding hours in an access_log timestamp DD/Mon/YYYY:HH:MM:SS +ssss
#
# $first = first hour in range to pull
# $last  = last hour in range to pull
# $date  = YYYY-MM-DD
#
# Example log:
#
# 2010-08-16 20:58:44,225 [INFO ] {http-8080-2} com.nav.dao.NAVDAOImpl - TRACER:NA >> GetDBStatus returned responseCode [NA] in [4] ms.
#
#
######################################################################

sub genNavTimeSearchRange {
   my $first = shift;
   my $last = shift;
   my $date = shift;

   $first = sprintf ("%02d", $first);
   $last = sprintf ("%02d", $last);
   my $range = "$first";

   for (my $x=$first+1; $x<=$last; $x+=1) {
     $x = sprintf("%02d", $x);
     $range .= "|$x";

   } # for

   my $search = "\"$date ($range):[0-9][0-9]:[0-9][0-9],[0-9][0-9][0-9].*\"";

   return $search;

} # genNavTimeSearchRange()


######################################################################
#
# getDate()
#
# Returns a date string in "YYYY-MM-DD" format.
#
#
######################################################################

sub getDate {
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime;

  $year += 1900;
  $mon += 1;
  $mday = sprintf("%02d", $mday);
  $mon = sprintf("%02d", $mon);

  my $timestamp = "$year-$mon-$mday";

  return $timestamp;

} # getDate()


######################################################################
#
# getEEGDataCount($first, $last, $date, $file, $server, $user, $type, $action)
#
#
######################################################################

sub getEEGDataCount {
  my ($first, $last, $date, $file, $server, $user, $type, $action) = @_;

  my @data = ();
  my $search = genNavTimeSearchRange($first, $last, $date);
  my $cmd = "egrep $search $file| egrep $type | grep $action | wc -l";
  #print "cmd = $cmd\n";
  my $result = Net::SSH::ssh_cmd("$user\@$server", "$cmd") or confess "ssh:  $!\n";
  chomp($result);
  $result =~ s/^\s+//;
  return $result;

} # getEEGDataCount()


######################################################################
#
# getLogSlice($first, $last, $date, $file, $server, $user)
#
#
######################################################################

sub getLogSlice {
  my ($first, $last, $date, $file, $server, $user) = @_;

  my @data = ();
  my $search = genNavTimeSearchRange($first, $last, $date);
  my $cmd = "egrep $search $file";
  @data = split(/\n/, Net::SSH::ssh_cmd ("$user\@$server", "$cmd")) or confess "ssh:  $!\n";

  return \@data;

} # getLogSlice()


######################################################################
#
# getAccessLogSlice($first, $last, $date, $datelog, $nav, $server, $user)
#
# Pulls logs between hours $first and end of $last from the access_log
# in instance nav$nav on $server.
#
# $first = first hour in range to pull
# $last = last hour in range to pull
# $date = YYYY-MM-DD (for determining which log to look at
# $datelog = DD/Mon/YYYY (timestamp inside log file)
# $nav = 1 or 2 (for nav1 or nav2 instance)
# $server = fqdn
# $user = username
#
# Returns reference to array containing all returned lines.
#
#
######################################################################

sub getAccessLogSlice {
  my ($first, $last, $date, $datelog, $nav, $server, $user) = @_;

  my @data = ();
  my $search = genAccessTimeSearchRange($first, $last, $datelog);
  my $file;

  if ($server =~ m/*ns.*/) {
    $file = "/opt/app/navserver/logs/access_log.$date.txt";

  } else {
    $file = "/opt/tomcat/nav$nav/logs/access_log.$date.txt";

  } # if

  my $cmd = "egrep $search $file";

  #@data = split(/\n/, Net::SSH::ssh_cmd ("$user\@$server", "$cmd")) or confess "ssh:  $!\n";
  @data = split(/\n/, `$cmd`);

  return \@data;

} # getAccessLogSlice()


######################################################################
#
# getAccessLogSliceFilter ($first, $last, $date, $datelog, $nav, $server, $user, $filter)
#
# Pulls logs between hours $first and end of $last from the access_log
# in instance nav$nav on $server.  It filters the output with $filter.
#
# $first = first hour in range to pull
# $last = last hour in range to pull
# $date = YYYY-MM-DD (for determining which log to look at
# $datelog = DD/Mon/YYYY (timestamp inside log file)
# $nav = 1 or 2 (for nav1 or nav2 instance)
# $server = fqdn
# $user = username
# $filter = string you wish to find.  Useful for getting transaction types
#           such as GetRootContents.
#
# Returns reference to array containing all returned lines.
#
#
######################################################################

sub getAccessLogSliceFilter {
  my ($first, $last, $date, $datelog, $nav, $server, $user, $filter) = @_;

  my @data = ();
  my $search = genAccessTimeSearchRange($first, $last, $datelog);
  my $file;

  if ($server =~ m/*ns.*/) {
    $file = "/opt/app/server/logs/access_log.$date.txt";

  } else {
    $file = "/opt/tomcat/nav$nav/logs/access_log.$date.txt";

  } # if

  my $cmd = "egrep $search $file \| egrep \'$filter\'"; 
  #@data = split(/\n/, Net::SSH::ssh_cmd ("$user\@$server", "$cmd")) or confess "ssh:  $!\n";
  @data = split(/\n/, `$cmd`);

  return \@data;

} #  getAccessLogSliceFilter()


######################################################################
#
# getNavLogSlice($first, $last, $date, $nav, $server, $user)
#
# Pulls logs between hours $first and end of $last from the nav.log
# in instance nav$nav on $server.
#
# $first = first hour in range to pull
# $last = last hour in range to pull
# $date = YYYY-MM-DD
# $nav = 1 or 2 (for nav1 or nav2 instance)
# $server = fqdn
# $user = username
#
# Returns reference to array containing all returned lines.
#
#
######################################################################

sub getNavLogSlice {
  my ($first, $last, $date, $nav, $server, $user) = @_;

  my @data = ();
  my $search = genNavTimeSearchRange($first, $last, $date);
  my $file = "/opt/tomcat/nav$nav/logs/nav.log";
  my $cmd = "egrep $search $file";

  @data = split(/\n/, Net::SSH::ssh_cmd ("$user\@$server", "$cmd")) or confess "ssh:  $!\n";

  return \@data;

} # getNavLogSlice()


######################################################################
#
# getNavLogSliceFilter($first, $last, $date, $nav, $server, $user, $filter)
#
# Pulls logs between hours $first and end of $last from the nav.log
# in instance nav$nav on $server.
#
# $first = first hour in range to pull
# $last = last hour in range to pull
# $date = YYYY-MM-DD
# $nav = 1 or 2 (for nav1 or nav2 instance)
# $server = fqdn
# $user = username
# $filter = Search string to look for.  \ your quotes!
#           Example filter:  my $filter = "\'\\[ERROR\\]\'";
#
# Returns reference to array containing all returned lines.
#
#
######################################################################

sub getNavLogSliceFilter {
  my ($first, $last, $date, $nav, $server, $user, $filter) = @_;

  my @data = ();
  my $search = genNavTimeSearchRange($first, $last, $date);
  my $file = "/opt/tomcat/nav$nav/logs/nav.log";
  my $cmd = "egrep $search $file \| egrep $filter";

  @data = split(/\n/, Net::SSH::ssh_cmd ("$user\@$server", "$cmd")) or confess "ssh:  $!\n";

  return \@data;

} # getNavLogSliceFilter()


######################################################################
#
# getOS()
#
# Returns a string containing the operating system of
# the target host.
#
#
######################################################################

sub getOS {
  my ($user, $host) = @_;

  return Net::SSH::ssh_cmd ("$user\@$host", '/usr/bin/uname');

} # getOS()


######################################################################
#
# pullAccessColumn($columnNumber, $line)
#
# Pulls a column from an access_log line.  Counts from zero.
#
# Returns a string containing the column item.
#
# Columns:
# 0                     1      2             3     4                5         6   7    8
# [15/Aug/2010:11:54:39 +0000] 68.87.107.198 "POST /GetRootContents HTTP/1.0" 200 6316 0.046
#
# 0 timestamp
# 1 ms
# 2 IP address
# 3 type
# 4 application action
# 5 http version
# 6 http return code
# 7 bytes sent
# 8 response time
#
#
######################################################################

sub pullAccessColumn {
  my ($column, $line) = @_;

  my @line = split / /, $line;

  return $line[$column];

} # pullAccessColumn()




######################################################################
#
# readFile()
#
# Simple wrapper for snarf().
#
# Returns reference to an array.
#
#
######################################################################

sub readFile {
  my ($file) = shift;
  my $content = snarf($file, "<");
  return $content;

} # readFile()


#####################################################################################
#
# recursiveDelDir($directory)
#
#
#####################################################################################

sub recursiveDelDir {
  my $dir = shift;

  if (-d $dir) {
    eval { rmtree("$dir", 0, 0) };

    if ($@) {
      return 0;

    } # if

  } # if

  # Double check
  # print "MetricsTools::recursiveDelDir($dir) did not remove $dir\n";

  if (-d $dir) {
    return 0;

  } # if

  return 1;

} # recursiveDelDir()


######################################################################
#
# recursiveMkDir($dir)
#
#
######################################################################

sub recursiveMkDir {
  my $dir = shift;

  if (-d $dir) {
    return 1;

  } # if

  eval { mkpath($dir) };

  if ($@) {
    return 0;

  } # if

  return 1;

} # recursiveMkDir()


######################################################################
#
# splitAccessLogTimeStamp($line)
#
# Pulls HH:MM:SS from an access_log line.
#
# [15/Aug/2010:11:59:42 +0000]
#
# Returns the "HH:MM:SS".
#
#
######################################################################

sub splitAccessLogTimeStamp {
  my $line = shift;

  my $timestamp;
  $line =~ m/^\[\d\d\/\w\w\w\/\d\d\d\d:(\d\d:\d\d:\d\d)\s.*/;
  $timestamp = $1;

  return $timestamp;

} # splitAccessLogTimeStamp()


######################################################################
#
# snarf()
#
# Snorts (reads) the contents of a file into an array
# and returns a reference to it.  Calls open() with 
# the string supplied in $mode.
#
# ARGS:
#
# $datfile    Path to data file you want to snarf
#
# $mode       Mode for open() call.  Must be:
#             < > >> +> +< +>>
#             See page 749 of the Camel Book.
#
#
######################################################################

sub snarf {
  my ($datfile, $mode) = @_;
  return 0 if ($mode !~ m/<|>|>>|\+<|\+>|\+>>/);

  open(DATFILE, "$mode $datfile")
    or confess "$0:  cannot open DATFILE $datfile:  $?\n";

  flock(DATFILE, 1);

  my @content = <DATFILE>;

  foreach (@content) {
    next if /^$/;     # skip blank lines
    next if /^\s+$/;  # skip lines with only space characters
    chomp;

  } # foreach

  close DATFILE;

  return \@content;

} # snarf()


######################################################################
#
# timestamp()
#
# Strinifies a bunch of arguments into yyyy-mon-day-hourminsec
#
# Returns a string
#
#
######################################################################

sub timestamp {
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime;

  $year += 1900;
  $mon += 1;

  $mday = sprintf("%02d", $mday);
  $mon = sprintf("%02d", $mon);
  $min = sprintf("%02d", $min);
  $hour = sprintf("%02d", $hour);
  $sec = sprintf("%02d", $sec);

  my $timestamp = "$year-$mon-$mday-$hour$min$sec";

  return $timestamp;

} # timestamp()


######################################################################
#
# writeRecord($filehandle, $string)
#
# Writes a single record to an existing file handle.  Always adds
# a newline if it does not exist.
#
#
######################################################################

sub writeRecord {
  my ($FH, $string) = @_;

  if ($string =~ m/^.*\n$/) {
    print $FH "$string";

  } else {
    print $FH "$string\n";

  } # if

} # sub writeRecord()


######################################################################

1;
