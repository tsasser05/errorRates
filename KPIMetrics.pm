package KPIMetrics;


use strict;
use diagnostics;
use warnings;
use Carp;

use File::ReadBackwards;
use lib qw(/opt/lib /opt/lib);
use TimeStamp;

use Exporter;
use vars qw(@ISA @EXPORT);
use base qw(Exporter);
our @EXPORT = qw(get_errorCount get_totalCount get_type);


######################################################################
#
# Reference for /opt/data/kpimetrics.dat
#
# $sse, $host, $requestName, $minTime, $maxTime, $avg, $count, $errorsMin, $errorsMax, $errorsAvg, $errorCount, $totalCount, $totalAvg
# 1331735701:HOSTNAME:RequestTotal:0:0:24.1460947403824:38653:0:0:9.08396946564885:655:39308:23.909153353007
#
#
######################################################################

my $debug = 0;


######################################################################
#
# get_errorCount($file_type, $request_type, $interval)
#
# Self-determines the name of the file to read.  Parses latest round of stats and returns
# the value of the $request_type field.
#
# $interval = optional interval if your metrics do no poll every 300 seconds.  Default is 299.  Optional.
#
# Returns the value of errorsCount.
#
#
######################################################################

sub get_errorCount {
  my ($file_type, $request_type, $interval) = @_;

  croak "KPIMetrics::get_errorCount($file_type, $request_type, $interval) called with missing type or request_type"
    if !$file_type || !$request_type;

  # default interval since NSG checks run every 300 seconds
  $interval = 299 if (! defined $interval); 

  print "KPIMetrics::get_errorCount($interval) called\n" if $debug > 2;

  my ($year, $mon, $day) = get_year_month_day();
  print "KPIMetrics::get_errorCount($file_type, $request_type, $interval):  year=$year, month=$mon, day=$day\n" if $debug;

  my $total = 0;
  my $line = get_type($file_type, $request_type, $interval);

  if ($line) {
    my ($sse, $host, $requestName, $minTime, $maxTime, $avg, $count, $errorsMin, $errorsMax, $errorsAvg, $errorCount, $totalCount, $totalAvg) = split(/:/, $line);
    print "KPIMetrics::get_errorCount($file_type, $request_type, $interval):  pulled line from get_type()-->$line<--\n    and found errorCount=$errorCount\n" if $debug;
    return $errorCount;

  } else {
    croak "ERROR:  KPIMetrics::get_errorCount($file_type, $request_type, $interval) could not find data for request type within interval\n";
    
  } # if

} # get_errorCount()


######################################################################
#
# get_type($file_type, $request_type, $stats_interval, $seconds_back) 
#
# OLD: get_type($file_type, $request_type, $stats_interval)
#
# Gets lines in an a kpi file back to $stats_interval
#
# $file_type = base name such as kpimetrics or tomcatmetrics
# $request_type = Type to grab.  Defaults to RequestTotal
# $stats_interval = Difference in times for each collection period for stats.  Based on SPDB metric.  Default is 300 seconds.
#
# Returns a reference to an array containing each matching line between new and $stats_interval.
#
# 1331735701:HOSTNAME:RequestTotal:0:0:24.1460947403824:38653:0:0:9.08396946564885:655:39308:23.909153353007
#
# Testing:
# 
# Requires a current kpimetrics.dat file since the interval is used to determine whether or not the line is valid.
#
#
######################################################################

sub get_type {
  my ($file_type, $request_type, $stats_interval, $seconds_back) = @_;

  croak "ERROR in KPIMetrics::get_type($file_type, $request_type, $stats_interval, $seconds_back) called with missing type or request_type"
    if !$file_type || !$request_type || ! $stats_interval || ! $seconds_back;

  print "KPIMetrics::get_type($file_type, $request_type, $stats_interval, $seconds_back):  called\n" if $debug > 2;

  my $file;
  my $file_path = "/opt/data";
  $file_path = "/tmp/lib" if $debug;
  my ($year, $mon, $day) = get_year_month_day();
  $file = "$file_path/$file_type-$year-$mon-$day.dat";

  # TBD file path and existence checking

  print "KPIMetrics::get_type($file_type, $request_type, $stats_interval, $seconds_back):  constructed file name-->$file<--\n" if $debug;

  open(FH, "<", $file) 
    or return "KPIMetrics::get_type($file_type, $request_type, $stats_interval, $seconds_back):  Could not open file $file for reading:  $!";

  my @line_data = ();

  my $bw = File::ReadBackwards->new($file);

  if (! $bw) {
    return "ERROR KPIMetrics::get_type($file_type, $request_type, $stats_interval, $seconds_back):  Could not create File::ReadBackwards object because the file $file could not be read:  $!\n";

  } # if

  my $first_run = 1;
  my $current_sse;
  my $min_sse;

  while (defined(my $line=$bw->readline)) {
    chomp($line);
    my ($sse, $host, $requestName, $minTime, $maxTime, $avg, $count, $errorsMin, $errorsMax, $errorsAvg, $errorCount, $totalCount, $totalAvg) = split(/:/, $line);

    if ($first_run) {
      $current_sse = $sse;      
      print "KPIMetrics::get_type():  current_sse=$current_sse\n" if $debug;
      $min_sse = $current_sse - $seconds_back;
      $first_run = 0;
      
      if ($debug) {
        print "KPIMetrics::get_type($file_type, $request_type, $stats_interval, $seconds_back): min_sse=$min_sse, current_sse=$current_sse\n" if $debug;  
        my $min = `date -j -f "%s" "$min_sse" "%a %b %d %T %Z %Y"`;
        my $cur = `date -j -f "%s" "$current_sse" "%a %b %d %T %Z %Y"`;
        chomp($min, $cur);
        print "KPIMetrics::get_type($file_type, $request_type, $stats_interval, $seconds_back):  Checking SSE timestamps:\n";
        print "    current time: $cur\n";
        print "    minimum time: $min\n";
        
      } # if

    } # if

    # if ($sse > $min_sse && $sse <= $current_sse) { # This is the one second off bug here 
    if ($sse > $min_sse) {
      next if ($requestName !~ m/$request_type/i);
      
      if ($requestName =~ m/$request_type/i) {
        push @line_data, $line;
        print "KPIMetrics::get_type($file_type, $request_type, $stats_interval, $seconds_back)-->$line<--\n" if $debug;

      } # if

    } # if

  } # while

  close(FH)
    or return "KPIMetrics::get_type($file_type, $request_type, $stats_interval, $seconds_back):  Could not close file=$file: $!";

  my $line_data_size = @line_data;

  # error handling
  if (! $line_data_size) {
    return "ERROR:  KPIMetrics::get_type() Could not find valid line in $file for $request_type within interval\n";

  } # if

  return \@line_data;

} # sub get_type()


######################################################################
#
# get_field($file_type, $request_type, $field, $interval)
#
# This will be a generic version of get_totalCount() that just pulls the field you tell it
#
#
######################################################################



######################################################################
#
# get_totalCount($file_type, $request_type, $interval)
#
# Self-determines the name of the file to read.  Parses latest round of stats and returns
# the value of the $request_type field.
#
# $interval = optional interval if your metrics do no poll every 300 seconds.  Default is 299.  Optional.
#
# Returns the value of totalCount.
#
#
######################################################################

sub get_totalCount {
  my ($file_type, $request_type, $interval) = @_;

  croak "KPIMetrics::get_totalCount($file_type, $request_type, $interval) called with missing type or request_type"
    if !$file_type || !$request_type;

  # default interval since NSG checks run every 300 seconds
  $interval = 299 if (! defined $interval); 

  print "KPIMetrics::get_totalCount($interval) called\n" if $debug > 2;

  my ($year, $mon, $day) = get_year_month_day();
  print "KPIMetrics::get_totalCount($file_type, $request_type, $interval):  year=$year, month=$mon, day=$day\n" if $debug;

  my $total = 0;
  my $line = get_type($file_type, $request_type, $interval);

  if ($line) {
    my ($sse, $host, $requestName, $minTime, $maxTime, $avg, $count, $errorsMin, $errorsMax, $errorsAvg, $errorCount, $totalCount, $totalAvg) = split(/:/, $line);
    print "KPIMetrics::get_totalCount($file_type, $request_type, $interval):  pulled line from get_type()-->$line<--\n    and found totalCount=$totalCount\n" if $debug;
    return $totalCount;

  } else {
    croak "ERROR:  KPIMetrics::get_totalCount($file_type, $request_type, $interval) could not find data for request type within interval\n";
    
  } # if

} # get_totalCount()


######################################################################
#
# get_year_month_day()
#
#
######################################################################

sub get_year_month_day {
  my $current_ts = genTS();
  # $yyyy-$mon-$dd $hh:$mm:$ss
  my ($first, $last) = split(/ /, $current_ts);
  my ($year, $mon, $day) = split(/-/, $first);

  return ($year, $mon, $day);

} # sub get_year_month_day()



######################################################################

1;
