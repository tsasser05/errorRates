package MetricsConfig;

use Exporter;
use strict;
use vars qw(@ISA @EXPORT $debug);
use warnings;
use diagnostics;
use Carp;
use Data::Dumper;

use base qw( Exporter );
our @EXPORT = qw(read_config display);

my $debug = 0;


######################################################################
#
# display($meta)
#
# Displays all data for debugging
#
#
######################################################################

sub display {
  my $meta = shift;
  print Dumper($meta);

} # display()


######################################################################
#
# read_config($config_file)
#
# config_file = Name of the configuration file to read
#
# Multiple values must be comma separated
# Comments start with '#'
#
#
######################################################################

sub read_config {
  my $config_file = shift;

  my $content = read_file($config_file);
  if (! $content) {
    return 0;

  } # if

  my $meta = {};

  foreach my $line (@$content) {
    next if ($line =~ m/^#.*/);
    next if ($line =~ m/^$/);
    next if ($line =~ m/^\s+/);

    my ($tag, $remainder) = split /[=]/, $line;

    if ($remainder =~ m/[,]/) {
      my @storage = split(/,/, $remainder);
      $meta->{"$tag"} = \@storage;

    } else {
      $meta->{"$tag"} = $remainder;

    } # if

  } # foreach

  return $meta;

} # read_config($meta)


######################################################################
#
# read_file()
#
# Simple wrapper for snarf().
#
# Returns reference to an array.
#
#
######################################################################

sub read_file {
  my ($file) = shift;
  my $content = snarf($file, "<");

  if ($content) {
    return $content;

  } else {
    return 0;

  } # if

} # read_file()


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
# $dat_file    Path to data file you want to snarf
#
# $mode       Mode for open() call.  Must be:
#             < > >> +> +< +>>
#             See page 749 of the Camel Book.
#
#
######################################################################

sub snarf {
  my ($dat_file, $mode) = @_;
  return 0 if ($mode !~ m/<|>|>>|\+<|\+>|\+>>/);

  if (! -e $dat_file || ! -r $dat_file) {
    return 0;

  } # if

  open(DATFILE, "$mode $dat_file")
    or confess "$0:  cannot open DATFILE $dat_file:  $?\n";

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
# Documentation
#
#
######################################################################

=pod

=head1 MetricsConfig

MetricsConfig - A module to read simple configuration files.

=head1 Version

MetricsConfig is still in development.

=head1 Synopsis

use MetricsConfig;

    my $file = "/Users/tsasser/projects/lib/test-MetricsConfig.cfg";
    my $meta = read_config($file)

    Use the hash reference, $meta, in your code.

=head1 Description

=head2 read_config($file)

This subroutine will read in the given file, $file, and return a reference to a hash that contains all lines.

You should handle an error if the function returns 0.  It means the code could not open the configuration file.  Nagios plugins should print an error message stating the file could not be opened and return 3 (NAGIOS_UNKNOWN).

=head2 display($hash_ref)

display() uses Data::Dumper to print out the hash reference.

=head1 Code Example

    use strict;
    use lib qw(/Users/tsasser/projects/lib);
    use MetricsConfig;
    use Data::Dumper;

    my $file = "/Users/tsasser/projects/lib/test-MetricsConfig.cfg";
    my $meta = read_config($file);

    # Check result of read_config() and exit appropriately for Nagios
    if (! $meta) {
      print "MetricsConfig::read_config($file) could not open its configuration file for reading.\n";
      exit 3;

    } # if

    print Dumper($meta);

    foreach my $item (sort keys %{$meta}) {
      my $value = $meta->{$item};

      if (ref $value) {
        print "$item:\n";
    
        foreach my $item (@$value) {
          print "    $item\n";

        } # foreach

        print "\n";

      } else {
        print "$item---->$value<----\n\n";

      } # if

    } # foreach

    exit 1; # for Nagios:  NAGIOS_OK

=head1 Configuration and Environment

=head2 Dependencies

This module requires Perl modules that should be installed by default.  

=head2 Location

MetricsConfig.pm should be installed in /opt/lib.  It should be controlled by puppet in the common_utils module.

=head2 Configuration

read_config requires a flat file containing the configuration information.

=head1 Configuration File Format

The configuration file has a very simple format that consists of <name>=<value> tuples.  There should be no space between the <name>, equal sign, and <value>.

Comments start with '#'.  Blank lines and lines containing only whitespace are skipped.

=head2 <name> Format

This should be a single word string.  Use underscores to indicate multiple words.

=head2 <value> Format

<value> can be either a single word, a string in quotes if it has spaces, or a comma separated list.  There should be no spaces in the list.  

=head2 Example

 one=1
 two=two
 quoted="quoted item"
 unquotedlist=one,two,three
 quotedlist="one","two","three"
 quotedmultiple="item one","item two","item three"


=cut



######################################################################

1;
