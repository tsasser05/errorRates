package MetricsError;

use strict;
use warnings;
use diagnostics;


# Class Data
  my $debug = 0;
  my $stddev_multiplier = 3;

######################################################################
#
# new($name)
#
#
######################################################################

sub new {
  my ($type, $name) = @_;
  my $class = ref($type) || $type;
  my $self = {};
  bless($self, $class);
  $self->{'name'} = $name;
  $self->{'alarm'} = 0;
  $self->{'message'} = " ";
  return $self;

} # new()


######################################################################
#
# get_alarm()
#
#
######################################################################

sub get_alarm {
  my ($self) = @_;
  return $self ->{'alarm'};

} # get_alarm()


######################################################################
#
# set_alarm($alarm)
#
#
######################################################################

sub set_alarm {
  my ($self, $alarm) = @_;
  $self->{'alarm'} = $alarm;
  return $self;

} # set_alarm()


######################################################################
#
# get_average()
#
#
######################################################################

sub get_average {
  my $self = shift;
  return $self->{'average'};

} # get_average()


######################################################################
#
# set_average()
#
#
######################################################################

sub set_average {
  my ($self, $average) = @_;
  print "MetricsError::set_average() called\n" if $debug > 2;
  
  $self->{'average'} = $average;
  return $self;

} # set_average()


######################################################################
#
# get_currentSSE()
#
#
######################################################################

sub get_currentSSE {
  my $self = shift;
  return $self->{'currentSSE'};

} # get_currentSSE()


######################################################################
#
# set_currentSSE($currentSSE)
#
#
######################################################################

sub set_currentSSE {
  my ($self, $currentSSE) = @_;
  print "MetricsError::set_currentSSE($currentSSE) called\n" if $debug > 2;
  $self->{'currentSSE'} = $currentSSE;
  return $self;

} # set_currentSSE()


######################################################################
#
# get_max()
#
#
######################################################################

sub get_max {
  my ($self) = @_;
  return $self->{'max'};

} # get_max()


######################################################################
#
# set_max($self, $stddev_multiplier)
#
#
######################################################################

sub set_max {
  my ($self, $stddev_multiplier) = @_;
  # TBD .. verify that average is set
  my $average = $self->get_average(); # put error handling in get_<attr>()

  if ($average == 0) {
    $self->{'max'} = $stddev_multiplier;

  } else {
    $self->{'max'} = _roundup($average + ($stddev_multiplier*($self->get_stddev())));

  } # if

  return $self;

} # set_max()


######################################################################
#
# get_message()
#
#
######################################################################

sub get_message {
  my ($self) = @_;
  return $self->{'message'};

} # get_message()


######################################################################
#
# set_message($message)
#
#
######################################################################

sub set_message {
  my ($self, $message) = @_;
  $self->{'message'} = $message;
  return $self;

} # set_message()


######################################################################
#
# get_min()
#
#
######################################################################

sub get_min {
  my ($self) = @_;
  return $self->{'min'};

} # get_min()


######################################################################
#
# set_min()
#
# Not currently really used.  Set to 0 until needed.
#
#
######################################################################

sub set_min {
  my ($self, $min) = @_;
  $self->{'min'} = $min;
  return $self;

} # set_min()


######################################################################
#
# get_name()
#
#
######################################################################

sub get_name {
  my ($self) = @_;
  return $self->{'name'};

} # get_name()


######################################################################
#
# set_name()
#
#
######################################################################

sub set_name {
  my ($self, $name) = @_;
  $self->{'name'} = $name;
  return $self;

} # set_name()


######################################################################
#
# get_sse()  TBD should be get_count?
#
#
######################################################################

sub get_sse {
  my ($self, $sse) = @_;
  print "MetricsError::get_sse($sse) called\n" if $debug > 2;
  return $self->{'sse'}{$sse};

} # get_sse()


######################################################################
#
# set_sse()
#
#
######################################################################

sub set_sse {
  my ($self, $sse, $count) = @_;
  print "MetricsError::set_sse($sse, $count) called\n" if $debug > 2;
  $self->{'sse'}{$sse} = $count;
  return $self;

} # set_sse()


######################################################################
#
# get_xy_count()
#
# Returns the error count for an error
#
#
######################################################################

sub get_xy_count {
  my ($self) = @_;
  return $self->{"xy_count"};

} # get_xy_count()


######################################################################
#
# set_xy_count($xy_count)
#
# Sets the error count for an error
#
#
######################################################################

sub set_xy_count {
  my ($self, $xy_count) = @_;
  $self->{"xy_count"} = $xy_count;
  return $self;

} # set_xy_count()


######################################################################
#
# get_all_counts($currentSSE) 
#
# returns a reference to an array containing all counts for an object.
#
# $currentSSE = Optional.  If included, then this is the currentSSE and it will be skipped
#
#
######################################################################

sub get_all_counts {
  my ($self, $currentSSE) = @_;
  my @counts = ();

  foreach my $sse (sort keys %{$self->{'sse'}}) {
    if (defined $currentSSE) {
      if ($sse == $currentSSE && $debug) {
        print "MetricsError::get_all_counts($currentSSE):  skipping sse $sse since currentSSE=$currentSSE is defined\n";

      } # if

      next if ($sse == $currentSSE);

    } # if

    push(@counts, $self->{'sse'}{$sse});

  } # foreach

  return \@counts;

} # get_all_counts()


######################################################################
#
# get_all_sse()
#
# returns hash_ref containing sse=>count pairs
#
#
######################################################################

sub get_all_sse {
  my ($self) = @_;
  my %results;

  foreach my $sse (keys %{$self->{'sse'}}) {
    $results{$sse} = $self->get_sse($sse);

  } # foreach

  return \%results;

} # get_all_sse()


######################################################################
#
# get_stddev()
#
#
######################################################################

sub get_stddev {
  my ($self) = @_;
  return $self->{'stddev'};

} # get_stddev()


######################################################################
#
# set_stddev($self, $stddev)
#
#
######################################################################

sub set_stddev {
  my ($self, $stddev) = @_;
  $self->{'stddev'} = $stddev;
  return $self;

} # set_stddev()


######################################################################
#
# Class methods
#
#
######################################################################


######################################################################
#
# average()
#
#
######################################################################

sub average {
  my ($self) = @_;
  print "MetricsError::average() called\n" if $debug > 2;
  my $results = $self->get_all_sse();

  # TBD .. verify currentSSE is set
  my $currentSSE = $self->get_currentSSE();

  my $total = 0;
  my $count = 0;

  foreach my $key (sort keys %{$results}) {
    print "MetricsError::average():  sse for this iteration=$key, count=",  $results->{$key}, "\n" if $debug;

    if ($debug) {
      if ($key == $currentSSE) {
        print "MetricsError::average():  skipping currentSSE=$currentSSE\n";

      } # if

    } # if

    next if ($key == $currentSSE); # do not average in $currentSSE
    $total += $results->{$key}; 
    $count++;

  } # foreach

  print "MetricsError::average():  total=$total, count=$count\n" if $debug;

  my $average = $total / $count;
  print "MetricsError::average():  calculated average=$average\n" if $debug;
  return $average;

} # average()


######################################################################
#
# compare($xy_count_max)
#
# $xy_count_max = max xy count value
#
#
######################################################################

sub compare {
  my ($self, $xy_count_max) = @_;
  my $max = $self->get_max();
  my $current_count = $self->get_sse($self->get_currentSSE());
  my $error_name = $self->get_name();
  my $xy_count = $self->get_xy_count();

  print "MetricsError::compare(): prealarm check:  max=$max, current_count=$current_count, error_name=$error_name, xy_count=$xy_count\n" if $debug > 2;

  # if in alarm situation
  if ($current_count > $max) {
    $xy_count++;
    $self->set_message("$error_name $current_count greater than calculated average and standard deviation $max");
      
    if ($debug > 1) {
      my $test_message = $self->get_message();
      print "MetricsError::compare(): [ALARM]  xy_count incremented.  Message=$test_message\n" if $debug > 1;

    } # if

      if ($xy_count >= $xy_count_max) {
        $self->set_alarm(2);
        print "MetricsError::compare(): [ALARM] set\n" if $debug > 1;
        $self->set_xy_count(0);

      } else {
        $self->set_xy_count($xy_count);

      } # if $xy_count >= $xy_count_max

    # not in alarm situation
  } else { 
    # reset xy_count since this run is not in an alarm condition
    $self->set_xy_count(0);

  } # if $current_count > $max / in alarm situation

  if ($debug) {
    my $alarm = $self->get_alarm();
    my $message = $self->get_message();
    print "MetricsError::compare():  error name has alarm = $alarm, message = $message\n" if $debug > 1;

  } # if 

  return $self;

} # compare()



######################################################################
#
# comparePercentage($xy_count_max)
#
# $xy_count_max = max xy count value
#
#
######################################################################

sub comparePercentage {
  my ($self, $xy_count_max) = @_;
  my $max = $self->get_max_percent();
  my $current_count = $self->get_sse($self->get_currentSSE());
  my $error_name = $self->get_name();
  my $xy_count = $self->get_xy_count();

  print "MetricsError::comparePercentage(): prealarm check:  max=$max, current_count=$current_count, error_name=$error_name, xy_count=$xy_count\n" if $debug > 2;

  # if in alarm situation
  if ($current_count > $max) {
    $xy_count++;
    $self->set_message("$error_name $current_count greater than calculated average and standard deviation $max");
      
    if ($debug > 1) {
      my $test_message = $self->get_message();
      print "MetricsError::comparePercentage(): [ALARM]  xy_count incremented.  Message=$test_message\n" if $debug > 1;

    } # if

      if ($xy_count >= $xy_count_max) {
        $self->set_alarm(2);
        print "MetricsError::comparePercentage(): [ALARM] set\n" if $debug > 1;
        $self->set_xy_count(0);

      } else {
        $self->set_xy_count($xy_count);

      } # if $xy_count >= $xy_count_max

    # not in alarm situation
  } else { 
    # reset xy_count since this run is not in an alarm condition
    $self->set_xy_count(0);

  } # if $current_count > $max / in alarm situation

  if ($debug) {
    my $alarm = $self->get_alarm();
    my $message = $self->get_message();
    print "MetricsError::comparePercentage():  error name has alarm = $alarm, message = $message\n" if $debug > 1;

  } # if 

  return $self;

} # comparePercentage()


######################################################################
#
# display()
#
#
######################################################################

sub display {
  my ($self) = @_;
  print "\nDisplaying object:\n";
  print "\tname = ", $self->get_name(), "\n";

  my $sse_list = $self->get_all_sse();

  foreach my $sse (sort keys %$sse_list) {
    print "\t$sse=", $sse_list->{$sse}, "\n";

  } # foreach

  print "\taverage = ", $self->get_average(), "\n";
  print "\txy_count = ", $self->get_xy_count(), "\n";
  print "\tstddev  = ", $self->get_stddev(), "\n";
  print "\tmax = ", $self->get_max(), "\n";
  print "\tmin = ", $self->get_min(), "\n";
  print "\tcurrentSSE = ", $self->get_currentSSE(), "\n";

  return $self;

} # display()


######################################################################
#
# find_currentSSE($sse_list_ref)
#
# Finds current SSE and returns it.
#
# $sse_list_ref = reference to array containing a list of SSEs
#
#
######################################################################

sub find_currentSSE {
  my ($self, $sse_list_ref) = @_;
  print "MetricsError::find_currentSSE($sse_list_ref) called\n" if $debug > 2;
  my @sorted = sort { $b <=> $a } @$sse_list_ref;
  return $sorted[0];

} # find_currentSSE


######################################################################
#
# _roundup($number)
#
# Rounds any decimal number up 
#
#
######################################################################

sub _roundup {
    my $n = shift;
    return(($n == int($n)) ? $n : int($n + 1))

} # roundup()


######################################################################
#
# standard deviation
#
#
######################################################################

sub stddev {
  my ($self) = @_;
  my $counts = $self->get_all_counts($self->get_currentSSE()); # exclude $currentSSE
  my $length = @$counts;

  if ($length == 1) {
    print "MetricsError::standardDeviation():  returning since there's only 1 item in the array\n" if $debug;
    return 0;

  } # if

  my $average = $self->average();
  my $sqtotal = 0;

  foreach my $item (@$counts) {
    $sqtotal += ($average - $item) ** 2;

  } # foreach

  my $std = ($sqtotal / (@$counts-1)) ** 0.5;
  return $std;

} # stddev()


######################################################################

1;
