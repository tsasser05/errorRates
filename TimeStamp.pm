package TimeStamp;


######################################################################
#
# TimeStamp.pm
#
# Handle various timestamp formats in logs
#
# All times are in GMT.
#
# Access Log Timestamps:  DD_Mon_YYYY_to_SSE, SSE_to_DD_Mon_YYYY
# 
# Nav Log, nav-client log:  YYYY_MM_DD_to_SSE, SSE_to_YYYY_MM_DD
#
# genSSE() and genTS() generate current SSE and timestamp.
#
# Test script: /opt/bin/
#
#
######################################################################

use Exporter;
use strict;
use vars qw(@ISA @EXPORT $debug);

use warnings;
use diagnostics;
use Carp;

use Time::Local;

use base qw( Exporter );
our @EXPORT = qw(debug DD_Mon_YYYY_to_SSE genSSE genTS SSE_to_DD_Mon_YYYY SSE_to_YYYY_MM_DD YYYY_MM_DD_to_SSE);

my $debug = 0;


######################################################################
#
# DD_Mon_YYYY_to_SSE($accessLogLineDate)
#
# Converts access log text timestamp to SSE.
#
# $accessLogLineDate = [30/Jun/2011:18:55:20 +0000] 
#
# [ and \s\+0000] are optional and accounted for
#
# [30/Jun/2011:18:55:20 +0000] 68.87.41.190 "GET /HealthCheck HTTP/1.0" 200 281 0.002
#
# CREDIT:  from check500
#
#
######################################################################

sub DD_Mon_YYYY_to_SSE {
  my $accessLogLineDate = shift;
  print "DEBUG: DD_Mon_YYYY_to_SSE($accessLogLineDate) called\n" if $debug;

  my $sse;
  my ($year,$mon,$day,$hour,$min,$sec);

  my %month = ("Jan","01",
               "Feb","02",
               "Mar","03",
               "Apr","04",
               "May","05",
               "Jun","06",
               "Jul","07",
               "Aug","08",
               "Sep","09",
               "Oct","10",
               "Nov","11",
               "Dec","12"
              );

  if ($accessLogLineDate =~ /^\[?(\d+)\/(\S+)\/(\d+)\s+(\d+):(\d+):(\d+)\s?\+?0?0?0?0?\]?$/ || 
      $accessLogLineDate =~ /(\d+)\/(\S+)\/(\d+):(\d+):(\d+):(\d+)/) {

    $year = $3 - 1900;
    $mon  = $month{$2};
    $day = $1;
    $hour = $4;
    $min  = $5;
    $sec  = $6;

    # Trim leading zeros
    $mon  =~ s/^0?//;
    $day =~ s/^0?//;
    $hour =~ s/^0?//;
    $min  =~ s/^0?//;
    $sec  =~ s/^0?//;

    $mon--;

    print "DEBUG: DD_Mon_YYYY_to_SSE($accessLogLineDate) results: day=$day, month=$mon, year=$year, hour=$hour, min=$min, sec=$sec\n" if $debug;
    $sse = timegm($sec, $min, $hour, $day, $mon, $year);
    print "DEBUG: DD_Mon_YYYY_to_SSE($accessLogLineDate):  SSE=$sse\n" if $debug;

    if ($sse) {
      return $sse;

    } else {
      return 0;

    } # if

  } # if

} # DD_Mon_YYYY_to_SSE()


######################################################################
#
# SSE_to_DD_Mon_YYYY($sse)
#
# Returns an access log timestamp:  30/Jun/2011:18:55:20
#
#
######################################################################

sub SSE_to_DD_Mon_YYYY {
  my $sse = shift;
  print "DEBUG: SSE_to_DD_Mon_YYYY($sse) called\n" if $debug;
  my ($ss, $mm, $hh, $dd, $mon, $yyyy, $wday, $yday, $isdst) = gmtime($sse);

  my %month = ("01" => "Jan",
               "02" => "Feb",
               "03" => "Mar",
               "04" => "Apr",
               "05" => "May",
               "06" => "Jun",
               "07" => "Jul",
               "08" => "Aug",
               "09" => "Sep",
               "10" => "Oct",
               "11" => "Nov",
               "12" => "Dec",
              );

  $ss  = sprintf("%02d", $ss);
  $mm  = sprintf("%02d", $mm);
  $hh  = sprintf("%02d", $hh);
  $dd  = sprintf("%02d", $dd);

  $mon += 1;
  $mon = sprintf("%02d", $mon);
  $mon = $month{$mon};

  $yyyy += 1900;

  print "DEBUG: SSE_to_DD_Mon_YYYY($sse) results: $dd/$mon/$yyyy:$hh:$mm:$ss\n" if $debug;  

  return qq{$dd/$mon/$yyyy:$hh:$mm:$ss};

} # sub SSE_to_DD_Mon_YYYY()


######################################################################
#
# SSE_to_YYYY_MM_DD($sse)
#
# Converts SSE to YYYY-MM-DD HH:MM:SS
#
#
######################################################################

sub SSE_to_YYYY_MM_DD {
  my $sse = shift;
  print "DEBUG: SSE_to_YYYY_MM_DD($sse) called\n" if $debug;
  my ($ss, $mm, $hh, $dd, $mon, $yyyy, $wday, $yday, $isdst) = gmtime($sse);

  $ss = sprintf("%02d", $ss);
  $mm = sprintf("%02d", $mm);
  $hh = sprintf("%02d", $hh);
  $dd = sprintf("%02d", $dd);
  $mon += 1;
  $mon = sprintf("%02d", $mon);
  $yyyy += 1900;

  print "DEBUG: SSE_to_YYYY_MM_DD($sse) $yyyy-$mon-$dd $hh:$mm:$ss\n" if $debug;  
    
  return qq{$yyyy-$mon-$dd $hh:$mm:$ss};

} # sub SSE_to_YYYY_MM_DD()


######################################################################
#
# YYYY_MM_DD_to_SSE($datestring)
#
# Converts:
# 
# 2011-06-30 20:16:19,697 to SSE.
#
# ',\d\d\d' is accounted for and ignored
#
#
######################################################################

sub YYYY_MM_DD_to_SSE {
  my $datestring = shift;
  print "DEBUG: YYYY_MM_DD_to_SSE($datestring) called\n" if $debug;

  my $sse;
  my ($year,$mon,$day,$hour,$min,$sec);

 if ($datestring =~ /^(\d+)-(\d+)-(\d+)\s(\d+):(\d+):(\d+)(,\d+|)$/) {
    $year = $1 - 1900;
    $mon  = $2 - 1;
    $day  = $3;
    $hour = $4;
    $min  = $5;
    $sec  = $6;

    # Trim leading zeros
    $mon  =~ s/^0?//;
    $day =~ s/^0?//;
    $hour =~ s/^0?//;
    $min  =~ s/^0?//;
    $sec  =~ s/^0?//;

    print "DEBUG: YYYY_MM_DD_to_SSE($datestring) results: year=$year, month=$mon, day=$day, hour=$hour, min=$min, sec=$sec\n" if $debug;;
    $sse = timegm($sec, $min, $hour, $day, $mon, $year);

    if ($sse) {
      return $sse;

    } else {
      return 0;

    } # if

  } else {
    return 0;

  } # if

} # sub YYYY_MM_DD_to_SSE()


######################################################################
#
# genSSE()
#
# Returns current SSE.
#
#
######################################################################

sub genSSE {
  print "DEBUG: genSSE() called\n" if $debug;
  my $sse = timegm((gmtime(time))[0,1,2,3,4,5]);
  print "DEBUG: genSSE():  current sse = $sse\n" if $debug;
  return $sse;

} # genSSE()


######################################################################
#
# genTS()
#
# Creates a timestamp in YYYY-MM-DD hh:mm:ss format
#
#
######################################################################

sub genTS {
  print "DEBUG: gen() called\n" if $debug;
  my ($ss, $mm, $hh, $dd, $mon, $yyyy, $wday, $yday, $isdst) = gmtime(time);

  $ss = sprintf("%02d", $ss);
  $mm = sprintf("%02d", $mm);
  $hh = sprintf("%02d", $hh);
  $dd = sprintf("%02d", $dd);
  $mon += 1;
  $mon = sprintf("%02d", $mon);
  $yyyy += 1900;

  print "DEBUG: genTS() $yyyy-$mon-$dd $hh:$mm:$ss\n" if $debug;  
    
  return qq{$yyyy-$mon-$dd $hh:$mm:$ss};

} # genTS()


######################################################################

1;
