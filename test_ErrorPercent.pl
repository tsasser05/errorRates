#!/usr/bin/perl

use strict;
use diagnostics;
use warnings;

use lib qw( /opt/lib /Users/tom/projects/nagios/check_error_rate /Users/tom/projects/lib);

use TimeStamp;
use KPIMetrics;
use ErrorPercent;

use Data::Dumper;
use File::ReadBackwards;
use Getopt::Long;

# Nagios plug-in return codes
my $NAGIOS_OK = 0;
my $NAGIOS_WARNING = 1;
my $NAGIOS_CRITICAL = 2;
my $NAGIOS_UNKNOWN  = 3;

my $debug = 3;
my $deviations = 3;
my $interval = 300;
my $seconds_back = 3600;
my $xy_count_max = 3;
my $xy_counts_file = "/var/tmp/ErrorPercent_counts.dat";

my $fqdn;
my $help;
my $percentage = 0;

GetOptions(
           "debug=i"        => \$debug,
           "deviations=i"  => \$deviations,
           "fqdn=s"          => \$fqdn,
           "help|h"           => \$help,
           "interval=i"      => \$interval,
           "percentage"    => \$percentage,
           "seconds=i"     => \$seconds_back,
           "xy=i"              => \$xy_count_max,
           "xyfile=s"        => \$xy_counts_file,
);

usage() if $help;
usage() unless defined $fqdn;

print "DEBUG MODE Level = $debug\n" if $debug;


######################################################################
#
# MAIN
#
#
######################################################################

if ($debug && $fqdn) {
  $override = check_adminoverride("$fqdn");

} else {
  $override = check_adminoverride();

} # if

if ($override == 0) {
  print "Host is out of rotation\n";
  exit $NAGIOS_OK;

} elsif ($override == 2) {
  print "Host may not be out of rotation or is experiencing problems.  Check admin override and services on the host\n";
  exit $NAGIOS_WARNING;

} # if

check_process("ErrorsToSpdb.pl");

my $self = ErrorPercent->new($deviations, $interval); # put deviations in constructor

my $file_type = 'kpimetrics';
my $request_type = 'RequestTotal';
$self->load_counts($file_type, $request_type, $seconds_back);

# NOTE: exceptions in KPIMetrics and ErrorPercent are all over the place.  They need to be cleaned up.
my $exception_level = $self->get_exception();

if ($exception_level) {
  print "checking for exceptions = $exception_level\n" if $debug > 2;
  my $message = $self->get_exception_message();
  print "$message\n";
  exit $exception_level;

} # if

$self->load_xy_count($xy_error_counts_file);
$self->compare_counts(); # default to 3 xy counts
$self->write_xy_count($xy_error_counts_file);
$self->display();

my $alarm = $self->get_alarm();
my $message = $self->get_message();

if ($alarm == 0) {
  print "OK\n";
  exit 0;

} else {
  print "$message\n";
  exit $alarm;
  
} # if


######################################################################
#
# check_adminoverride($fqdn)
#
# $fqdn = hostname to check.  Defaults to localhost if not passed to function.
#
# Answers the question if a host is in rotation or not
#
# Returns 1 = in rotation or 0 = out of rotation
# Returns 2 if it cannot find the regex in the output.
#
# OUT OF ROTATION:
# $ curl http://FQDN:8080/HealthCheck
#<?xml version="1.0" encoding="UTF-8"?><NavServerResponse code="FAILURE" message="nav server is not healthy: Server taken out of rotation CM000533263" duration="1"/>
#
# IN ROTATION:
#$ curl http://FQDN:8080/HealthCheck
#<?xml version="1.0" encoding="UTF-8"?><NavServerResponse code="OK" message="nav server is healthy" duration="2"><HealthCheckResult taskName="NavDbHealthCheckTask" code="OK" duration="1"/><HealthCheckResult taskName="RiakHealthCheckTask" code="OK" duration="2"/></NavServerResponse>
#
#
######################################################################

sub check_adminoverride {
  my $fqdn = shift;
  $fqdn = 'localhost' if (! defined $fqdn);

  print "NagiosPlugins::check_adminoverride() called\n" if $debug > 2;
  my $curl = "/usr/bin/curl";
  my $query = "$curl -s http://$fqdn:8080/HealthCheck";
  my $result = `$query`;

  my $FAILURE = qr/NavServerResponse code="FAILURE"/o;
  my $SUCCESS = qr/NavServerResponse code="OK"/o;

  if ($result =~ m/.*$FAILURE.*/o) {
    return 0;

  } elsif ($result =~ m/.*$SUCCESS.*/o) {
    return 1;

  } else {
    # unknown
    return 2;

  } # if

} # check_adminoverride()


######################################################################
#
# check_process($procName)
#
# Query the OS for a running process and limit number of checks.
#
# Calls queryProcess($procName)
#
#
######################################################################

sub check_process {
  my $procName = shift;
  print "$0 : check_process($procName) called\n" if $debug > 2;

  my $stopChecking = 0;
  my $counter = 0;
  my $limit = 2;
  my $sleepTime = 10;

  do {
    print "$0 : check_process():  counter=$counter\n" if $debug;
    my $pid = queryProcess($procName);

    if ($pid == 0) {
      $stopChecking = 1;
      print "$0 : check_process():  stopChecking=$stopChecking\n" if $debug;

    } else {
      my $exists = kill 0, $pid; # true if running, false if not running
      $stopChecking = 1 unless ($exists);

      if ($counter >= $limit) {
        my $max = $sleepTime*($limit);
        print "$0 : check_process($procName) via check_error_rate:  $procName still running after $max seconds\n" if $debug;
        exit $NAGIOS_UNKNOWN;

      } # if

      $counter++;
      print "$0 : check_process($procName):  sleeping $sleepTime seconds\n" if $debug > 2;
      sleep $sleepTime;

    } # if

  } until $stopChecking == 1;

} # check_process()


######################################################################
#
# queryProcess($processName) 
#
# Called by check_process($processName)
#
# Does the actual check for a pid.
#
#
######################################################################

sub queryProcess {
  my $procName = shift;
  print "queryProcess($procName) called\n" if $debug > 2;

  my $pid = 0;

  my $os = `uname`;

  if ($os =~ m/Darwin/i) {
    $pid = `ps -f -o pid=,command= | grep $procName|grep -v grep|cut -d' ' -f2`;

  } elsif ($os =~ m/Linux/i) {
    $pid = `ps -o pid= -C $procName`;

  } else {
    print "queryProcess($procName):  Unknown OS=$os.\n";
    exit $NAGIOS_UNKNOWN;

  } # if

  if ($pid) {
    print "queryProcess($procName):  PID for $procName is $pid\n" if $debug;

  } else {
    print "queryProcess($procName):  $procName is not running\n" if $debug;
    $pid = 0;

  } # if

  print "queryProcess($procName):  exiting\n" if $debug > 2;

  return $pid;

} # queryProcess()


######################################################################
#
# usage()
#
#
######################################################################

sub usage {
  print "usage!\n";
  exit $NAGIOS_UNKNOWN;

}
