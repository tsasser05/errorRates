package ErrorPercent;

use strict;
use warnings;
use diagnostics;
use Carp;

use lib qw(/opt/lib);
use KPIMetrics;
use TimeStamp;

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
  my ($type, $deviations, $interval, $debug) = @_;

  if (! defined $deviations) {
    $deviations = 3;

  } # if

  if (! defined $interval) {
    $interval = 300;

  } # if

  if (! defined $debug) {
    $debug = 0;

  } # if

  my $class = ref($type) || $type;
  my $self = {};
  bless($self, $class);

  $self->{'alarm'} = 0;
  $self->{'debug'} = $debug;
  $self->{'deviations'} = $deviations;
  $self->{'exception'} = 0;
  $self->{'exception_message'} = "";
  $self->{'interval'} = $interval;
  $self->{'message'} = "OK";
  $self->{'min'} = 0;
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
  print "ErrorPercent::set_average() called\n" if ($self->get_debug() > 2);
  
  $self->{'average'} = $average;
  return $self;

} # set_average()


######################################################################
#
# get_counts()  TBD should be get_count?
#
# Returns reference to array containing [ error_count, total_count ]
# 
#
######################################################################

sub get_counts {
  my ($self, $sse) = @_;
  print "ErrorPercent::get_counts($sse) called\n" if ($self->get_debug() > 2);
  return $self->{'sse'}{$sse};

} # get_counts()


######################################################################
#
# set_counts()
#
#
######################################################################

sub set_counts {
  my ($self, $sse, $count) = @_;
  print "ErrorPercent::set_counts($sse, $count) called\n" if ($self->get_debug() > 2);
  $self->{'sse'}{$sse} = $count;
  return $self;

} # set_counts()


######################################################################
#
# get_debug()
#
# Returns debug value
# 
#
######################################################################

sub get_debug {
  my ($self) = @_;
  return $self->{'debug'};

} # get_debug()


######################################################################
#
# set_debug($debug)
#
#
######################################################################

sub set_debug {
  my ($self, $debug) = @_;
  $self->{'debug'} = $debug;
  return $self;

} # set_debug()


######################################################################
#
# get_deviations()
#
#
######################################################################

sub get_deviations {
  my ($self) = @_;
  return $self->{'deviations'};

} # get_deviations()


######################################################################
#
# set_deviations()
#
#
######################################################################

sub set_deviations {
  my ($self, $deviations) = @_;
  $self->{'deviations'} = $deviations;
  return $self;

} # set_deviations()


######################################################################
#
# get_error_count($sse)
#
#
######################################################################

sub get_error_count {
  my ($self, $sse) = @_;
  return $self->{"error_count"}{$sse};

} # get_error_count()


######################################################################
#
# set_error_count($sse, $error_count)
#
#
######################################################################

sub set_error_count {
  my ($self, $sse, $error_count) = @_;
  $self->{"error_count"}{$sse} = $error_count;
  return $self;

} # set_error_count()


######################################################################
#
# get_exception($self)
#
# Returns numeric value.
#
#
######################################################################

sub get_exception {
  my ($self) = @_;
  return $self->{"exception"};

} # get_exception


######################################################################
#
# set_exception($self)
#
# Sets numeric value.
#
#
######################################################################

sub set_exception {
  my ($self, $exception) = @_;
  $self->{"exception"} = $exception;
  return $self;

} # set_exception


######################################################################
#
# get_exception_message($self)
#
# Returns the exception message
#
#
######################################################################

sub get_exception_message {
  my ($self) = @_;
  return $self->{"exception_message"};

} # get_exception_message


######################################################################
#
# set_exception_message($self, $exception_message)
#
# Sets the exception's message.
#
#
######################################################################

sub set_exception_message {
  my ($self, $exception_message) = @_;
  $self->{"exception_message"} = $exception_message;
  return $self;

} # set_exception_message


######################################################################
#
# get_interval()
#
#
######################################################################

sub get_interval {
  my ($self) = @_;
  return $self->{'interval'};

} # get_interval()


######################################################################
#
# set_interval($interval)
#
#
######################################################################

sub set_interval {
  my ($self, $interval) = @_;
  $self->{"interval"} = $interval;
  return $self;

} # set_interval()


######################################################################
#
# get_percentage($sse)
#
#
######################################################################

sub get_percentage {
  my ($self, $sse) = @_;
  return $self->{"percentages"}{$sse};

} # get_percentage()


######################################################################
#
# set_percentage($sse, $percentage)
#
#
######################################################################

sub set_percentage {
  my ($self, $sse, $percentage) = @_;
  $self->{"percentages"}{$sse} = $percentage;
  return $self;

} # set_percentage()


######################################################################
#
# get_total_count($sse)
#
#
######################################################################

sub get_total_count {
  my ($self, $sse) = @_;
  return $self->{"total_count"}{$sse};

} # get_total_count()


######################################################################
#
# set_total_count($sse, $total_count)
#
#
######################################################################

sub set_total_count {
  my ($self, $sse, $total_count) = @_;
  $self->{"total_count"}{$sse} = $total_count;
  return $self;

} # set_total_count()


######################################################################
#
# get_current_sse()
#
#
######################################################################

sub get_current_sse {
  my $self = shift;
  return $self->{'current_sse'};

} # get_current_sse()


######################################################################
#
# set_current_sse($current_sse)
#
#
######################################################################

sub set_current_sse {
  my ($self, $current_sse) = @_;
  print "ErrorPercent::set_current_sse($current_sse) called\n" if ($self->get_debug() > 2);
  $self->{'current_sse'} = $current_sse;
  return $self;

} # set_current_sse()


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
# set_max($self, $max)
#
#
######################################################################

sub set_max {
  my ($self, $max) = @_;
  $self->{'max'} = $max;
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
  print "ErrorPercent::set_xy_count($xy_count) called\n" if ($self->get_debug());
  $self->{"xy_count"} = $xy_count;
  return $self;

} # set_xy_count()


######################################################################
#
# get_all_error_counts($current_sse) 
#
# Returns a reference to a hash containing all error counts for an object.
#
# $current_sse = Optional.  If included, then this is the current_sse and it will be skipped
#
#
######################################################################

sub get_all_error_counts {
  my ($self, $current_sse) = @_;

  if (defined $current_sse) {
    print "ErrorPercent::get_all_error_counts($current_sse) called\n" if ($self->get_debug() > 2);

  } else {
    print "ErrorPercent::get_all_error_counts(no arg) called\n" if ($self->get_debug() > 2);

  } # if


  # TBD FIX check for existence of keys
  # TBD .. need error class

  my %error_counts_data = %{$self->{'error_count'}};

  if (defined $current_sse && exists $error_counts_data{"$current_sse"}) {
    delete($error_counts_data{"$current_sse"});

  } # if

  return \%error_counts_data;

} # sub get_all_error_counts()


######################################################################
#
# get_all_percentages($current_sse) 
#
# Returns a reference to a hash containing all percentages for an object.
#
# $current_sse = Optional.  If included, then this is the current_sse and it will be skipped
#
#
######################################################################

sub get_all_percentages {
  my ($self, $current_sse) = @_;

  if (defined $current_sse) {
    print "ErrorPercent::get_all_percentages($current_sse) called\n" if ($self->get_debug() > 2);

  } else {
    print "ErrorPercent::get_all_percentages(no arg) called\n" if ($self->get_debug() > 2);

  } # if


  # TBD FIX check for existence of keys
  # TBD .. need error class

  my %percentage_data = %{$self->{'percentages'}};

  if (defined $current_sse && exists $percentage_data{"$current_sse"}) {
    delete($percentage_data{"$current_sse"});

  } # if

  return \%percentage_data;

} # sub get_all_percentages()


######################################################################
#
# get_all_total_counts($current_sse) 
#
# returns a reference to a hash containing all total counts for an object.
#
# $current_sse = Optional.  If included, then this is the current_sse and it will be skipped
#
#
######################################################################

sub get_all_total_counts {
  my ($self, $current_sse) = @_;

  if (defined $current_sse) {
    print "ErrorPercent::get_all_total_counts($current_sse) called\n" if ($self->get_debug() > 2);

  } else {
    print "ErrorPercent::get_all_total_counts(no arg) called\n" if ($self->get_debug() > 2);

  } # if


  # TBD FIX check for existence of keys
  # TBD .. need error class

  my %total_counts_data = %{$self->{'total_count'}};

  if (defined $current_sse && exists $total_counts_data{"$current_sse"}) {
    delete($total_counts_data{"$current_sse"});

  } # if

  return \%total_counts_data;

} # sub get_all_total_counts()



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
# Class Methods
#
#
######################################################################


######################################################################
#
# average()
#
# Returns the average of all items in $counts_array_ref unless $current_sse is specified.
# If $current_sse is specified, then that item will not be included in the average.
#
#
######################################################################

sub average {
  my ($self, $counts_array_ref, $current_sse) = @_;
  print "ErrorPercent::average() called\n" if ($self->get_debug() > 2);

  my $total = 0;
  my $count = 0;

  foreach my $item (@$counts_array_ref) {
    next if (defined $current_sse && $item == $current_sse ); # do not average in $current_sse if passed to function
    $total += $item;
    $count++;

  } # foreach

  # TBD 
  # check $count to verify it's not zero
  # what to do if it's zero

  my $average = $total / $count;
  print "ErrorPercent::average():  calculated average=$average based upon total=$total, count=$count\n" if ($self->get_debug());
  return $average;

  } # average()


######################################################################
#
# calc_max($self)
#
#
######################################################################

sub calc_max {
  my ($self) = @_;
  my $average = $self->get_average(); # put error handling in get_<attr>()
  my $deviations = $self->get_deviations();

  if ($average == 0) {
    return $deviations;

  } else {
    return $average + ($deviations*($self->get_stddev()));
    
  } # if

} # calc_max()


######################################################################
#
# compare_counts($xy_count_max)
#
# $xy_count_max = max xy count value
#
#
######################################################################

sub compare_counts {
  my ($self, $xy_count_max) = @_;

  if (! defined $xy_count_max) {
    $xy_count_max = 3;

  } # if

  print "ErrorPercent::compare_counts($self, $xy_count_max) called\n" if ($self->get_debug() >2);

  my $total_counts_hash_ref = $self->get_all_total_counts();
  my $error_counts_hash_ref = $self->get_all_error_counts();

  # Double check comparison
  my $no_differences = $self->_different_keys($total_counts_hash_ref, $error_counts_hash_ref);
  print "ErrorPercent::compare_counts():  Checking for different SSE's in total and error count lists.  no_differences = $no_differences. 1=okay, 0=bad\n" if ($self->get_debug());

  my @sse_list = sort keys %{$total_counts_hash_ref};

  my %results;

  if ($no_differences) {
    foreach my $sse (@sse_list) {
      my $error = $error_counts_hash_ref->{$sse};
      my $total = $total_counts_hash_ref->{$sse};
      # TBD .. need to avoid divide by 0
      my $percent = ($error/$total)*100;
      $self->set_percentage($sse, $percent);

    } # foreach


    ######################################################################
    #
    # Need to check and eliminate all values that are zero
    # my $percent = ($error/$total)*100;
    #
    ######################################################################

    # consolidated way that does not account for values = 0
    # $self->set_stddev($self->stddev( [ sort values %{ $self->get_all_percentages($self->get_current_sse() ) } ] ));
    
    # This line does the following:
    my $current_sse = $self->get_current_sse();
    my $percentage_hash_ref = $self->get_all_percentages($current_sse); # excludes current SSE in calculation
    
    # skip any entries that are equal to 0
    foreach my $key (keys %{$percentage_hash_ref}) {
      my $val = $percentage_hash_ref->{$key};
      delete $percentage_hash_ref->{$key} if ($val <= 0);
      
    } # foreach
                     
    my @percentages = sort values %{$percentage_hash_ref};
    # make sure there are at least 1
    # return failure if not
    my $sizeof_percentages = @percentages;
    
    if ($sizeof_percentages < 1) {
      # need exception here
      $self->set_exception("3"); # NAGIOS UNKNOWN
      $self->set_exception_message("Plugin ERROR:  ErrorPercent::compare_counts():  at least one element besides current SSE has to have a value greater than 0\n");
      return $self;
      # check caller and have it first check for exceptions

    } # if

    my $stddev= $self->stddev(\@percentages);
    $self->set_stddev($stddev);

    $self->set_max($self->calc_max());

  } else { # if ($no_differences)
    $self->set_exception("3"); # NAGIOS UNKNOWN
    $self->set_exception_message("Plugin ERROR:  ErrorPercent::compare_counts():  there were different sse's in the total and error count lists\n");
    # exiting here is not correct
    # exit 1;
    return $self;

  } # if $no_differences

  # Evaluate
  my $current_percentage = $self->get_percentage($self->get_current_sse());
  my $max = $self->get_max();

  print "ErrorPercent::compare_counts()  current_percentage=$current_percentage and max=$max\n" if ($self->get_debug());

  if ($current_percentage > $max) {
    my $current_xy_count = $self->get_xy_count();
    print "ErrorPercent::compare_counts():  get_xy_count() loaded $current_xy_count\n" if ($self->get_debug());
    $current_xy_count++;
    print "ErrorPercent::compare_counts():  incremented \$current_xy_count to $current_xy_count\n" if ($self->get_debug());

    if ($current_xy_count >= $xy_count_max) {
      print "ALARM  condition met\n" if ($self->get_debug());
      $self->set_alarm(2);
      $self->set_message("Current error percentage $current_percentage is greater than calculated max = $max");
      $self->set_xy_count(0); # reset

    } else {
      $self->set_xy_count($current_xy_count);

    } # if

  } else {
    $self->set_xy_count(0); # reset

  } # if $current_percentage

  return $self;

} # compare_counts()


######################################################################
#
# display()
#
#
######################################################################

sub display {
  my ($self) = @_;
  print "\nDisplaying object:\n";

  print "\tDEBUG MODE = ", $self->get_debug(), "\n";
  print "\tcurrent_sse = ", $self->get_current_sse(), "\n";
  print "\txy_count = ", $self->get_xy_count(), "\n";

  my $total_counts_hash_ref = $self->get_all_total_counts();

  print "\tTotal Counts\n";

  foreach my $sse (sort keys %{$total_counts_hash_ref}) {
    print "\t\t$sse = ", $total_counts_hash_ref->{$sse}, "\n";

  } # foreach

  my $error_counts_hash_ref = $self->get_all_error_counts();

  print "\tError Counts\n";

  foreach my $sse (sort keys %{$error_counts_hash_ref}) {
    print "\t\t$sse = ", $error_counts_hash_ref->{$sse}, "\n";

  } # foreach

  print "\tDisplaying Percentages\n";
  my $percentage_hash_ref = $self->get_all_percentages();

  foreach my $sse (sort keys %{$percentage_hash_ref}) {
    print "\t\t$sse = ", $percentage_hash_ref->{$sse}, "\n";

  } # foreach

  print "\tstandard deviation  = ", $self->get_stddev(), "\n";
  print "\taverage = ", $self->get_average(), "\n";
  print "\tmin = ", $self->get_min(), "\n";
  print "\tmax = ", $self->get_max(), "\n";
  print "\talarm = ", $self->get_alarm(), "\n";
  print "\tmessage = ", $self->get_message(), "\n";

  
  return $self;

} # display()


######################################################################
#
# _different_keys($error_count_hash_ref, $total_count_hash_ref)
#
#
######################################################################

sub _different_keys {
  my ($self, $error_count_hash_ref, $total_count_hash_ref) = @_;

  my @different_keys = ( );

  foreach my $key (keys %{$total_count_hash_ref}) {
    push(@different_keys, $key) unless exists $error_count_hash_ref->{$key};

  } # foreach

  if ($self->get_debug()) {

    print "ErrorPercent::_different_keys():  Checking key lists\n";
    print "    Total Count SSE's:\n";

    foreach my $key (sort keys %{$total_count_hash_ref}) {
      print "        $key\n";

    } # foreach

    print "    Error Count SSE's:\n";

    foreach my $key (sort keys %{$error_count_hash_ref}) {
      print "        $key\n";

    } # foreach

    print "ErrorPercent::_different_keys():  checking different_keys array\n";

    foreach my $item (@different_keys) {
      print "$item ";

    } # foreach

    print "\n";

  } # if 

  my $length = @different_keys;
  print "ErrorPercent::_different_keys():  length of different_keys array = $length\n" if ($self->get_debug());

  if (! $length) { # if no difference, return 1
    return 1;

  } else {
    return 0;

  } # if

} # _different_keys()


######################################################################
#
# load_counts($self, $file_type, $request_type, $seconds_back)
#
# Loads error and total counts from disk
#
# $file is deprecated.
#
#
######################################################################

sub load_counts {
  my ($self, $file_type, $request_type, $seconds_back) = @_;
  
  # DATA PROCESSING using KPIMetrics::get_type()
  my @sse_list = ();

  my $interval = $self->get_interval(); # number of seconds between SPDB runs based upon SPDB metric type;  default=300
  my $kpi_line_data = get_type($file_type, $request_type, $interval, $seconds_back);
  chomp $kpi_line_data;

  if ($kpi_line_data =~ m/ERROR.*/i) {
    $self->set_exception("3");
    $self->set_exception_message("$kpi_line_data");
    return $self;

  } # if

  foreach my $line (@$kpi_line_data) {
    chomp($line);
    print "ErrorPercent::load_counts():  -->$line<--\n" if ($self->get_debug());
    my ($sse, $host, $requestName, $minTime, $maxTime, $avg, $count, $errorsMin, $errorsMax, $errorsAvg, $error_count, $total_count, $totalAvg) = split(/:/, $line);
    push @sse_list, $sse;
    $self->set_error_count($sse, $error_count);
    $self->set_total_count($sse, $total_count);

  } # foreach
  
  my @sorted = sort { $b <=> $a } @sse_list;
  $self->set_current_sse($sorted[0]);
  my $current_sse = $self->get_current_sse();
  print "ErrorPercent::load_counts():  current_sse = $current_sse\n" if ($self->get_debug());
  
  return $self;

} # sub load_counts()


######################################################################
#
# load_xy_count($self, $file)
#
# Loads the data for the error_name in /var/tmp/Error-counts.dat file
#
# Returns a hash reference containing the counts
#
#
######################################################################

sub load_xy_count {
  my ($self, $file) = @_;

  if (! defined $file) {
    $self->set_exception_message("ErrorPercent::load_xy_count() could not load $file.  Exiting 3 (Nagios unknown)\n");
    $self->set_exception("3"); # NAGIOS UNKNOWN 

  } # if

  print "ErrorPercent::load_xy_count($self, $file) called\n" if ($self->get_debug() > 2);

  my %count_data = ();
  my $xy_count = 0;

  if (! -e $file) {
      $self->set_xy_count($xy_count);
      return;

  } # if

  if (-e $file && -r $file) {
    open XYCOUNTSFILE, '<', $file 
      or croak "UNKNOWN:  cannot open ErrorPercent XY counts file:  $file\n";

    my @xy_counts_file_contents = <XYCOUNTSFILE>;
    close(XYCOUNTSFILE);

    my $size_of = @xy_counts_file_contents;
    
    if ($size_of != 1) {
      $self->set_exception("3"); # NAGIOS UNKNOWN
      $self->set_exception_message("ErrorPercent::load_xy_count($file):  more than one line in xy_counts file\n");

    } else { 
      $xy_count = 0 if ($xy_count < 0);
      my $xy_count = $xy_counts_file_contents[0];
      chomp($xy_count);
      $self->set_xy_count($xy_count);   

    } # if

    if ($self->get_debug()) {
      my $test_xy_count = $self->get_xy_count();
      print "ErrorPercent::load_xy_count():  \$test_xy_count = $test_xy_count\n" if ($self->get_debug());
      
    } # if

  } # if -e $file && -r $file

  return $self;

} # load_xy_count()


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
# TBD FIX
#
######################################################################

sub stddev {
  my ($self, $counts_array_ref) = @_;
  my $length = @$counts_array_ref;

  if ($length == 1) {
    print "ErrorPercent::standardDeviation():  returning since there's only 1 item in the array\n" if ($self->get_debug());
    return 0;

  } # if

  my $average = $self->average($counts_array_ref);
  $self->set_average($average);
  my $sqtotal = 0;

  foreach my $item (@$counts_array_ref) {
    $sqtotal += ($average - $item) ** 2;

  } # foreach

  my $std_dev = ($sqtotal / $length) ** 0.5;
  return $std_dev;

} # stddev()


######################################################################
#
# write_xy_count($file)
#
# Writes the count for the object out to /var/tmp/Error-count.dat
#
# $file = file to write out to.  This should be /var/tmp/Error-count.dat
#
#
######################################################################

sub write_xy_count {
  my ($self, $file) = @_;
  print "ErrorPercent::write_xy_count($file) called\n" if ($self->get_debug() >2);

  my $error_condition = 0;

  if (! -e $file) {
    my $system_result = system("touch", "$file");
    print "ErrorPercent:write_xy_count():  result=$system_result\n" if ($self->get_debug());

    if ($system_result > 0) {
      $self->set_exception("3");
      $self->set_exception_message("ErrorPercent::write_xy_count():  Error in write_xy_count():  could not write to $file since file creation had exit status = $system_result\n");

    } # if

  } # if

  if (-w $file) {
    open(XYCOUNTFILE, ">", $file) or $error_condition = 1;

    if ($error_condition) {
      print "WARNING:  error_condition for write_xy_count() could not open count file $file for writing:  $!\n";
      exit 3; # exit NAGIOS UNKNOWN

    } # if

    my $xy_count = $self->get_xy_count();
    print "ErrorPercent::write_XYCount():  writing out-->$xy_count<-- to $file\n" if ($self->get_debug());
    print XYCOUNTFILE "$xy_count\n";
    close(XYCOUNTFILE);

  } else {
    print "WARNING:  cannot open count file $file for writing\n";
    exit 3; # exit NAGIOS_UNKNOWN

  } # if

  return $self;

} # write_xy_count()


######################################################################

1;
