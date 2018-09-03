#!/usr/bin/perl 

use strict;
use diagnostics;
use warnings;

use KPIMetrics;

my $file_type = "kpimetrics";
my $request_type = "RequestTotal";
my $interval = 299;

print "----------------------------------------------------------------------\n";
print "Testing get_totalCount($file_type, $request_type, $interval)\n";
print "----------------------------------------------------------------------\n";

my $total = get_totalCount($file_type, $request_type, $interval);

if ($total) {
  print "total=$total\n";

} else {
  print "TEST:  get_totalCount() failed to return a total\n";

} # if


print "----------------------------------------------------------------------\n";
print "Testing get_totalCount($file_type, DeleteSavedProgram, $interval)\n";
print "----------------------------------------------------------------------\n";

$request_type = "DeleteSavedProgram";
my $delete_saved_program = get_totalCount($file_type, $request_type, $interval);

if ($total) {
  print "total=$delete_saved_program\n";

} else {
  print "TEST:  get_totalCount() failed to return a total\n";

} # if


print "----------------------------------------------------------------------\n";
print "Testing get_errorCount($file_type, RequestTotal, $interval)\n";
print "----------------------------------------------------------------------\n";

$request_type = "RequestTotal";
my $error = get_errorCount($file_type, $request_type, $interval);

if ($total) {
  print "total=$error\n";

} else {
  print "TEST:  get_errorCount() failed to return a total\n";

} # if
