#!/usr/bin/perl

# this PERL script reads two arguments:
#
# $perl calculate_ipt_for_a_throughput.pl packet_sizes.txt throughput
#
#these are the two arguments:
# file where packet lengths are (in bytes). One packet size per line
# throughput you want to achieve

# the script returns the inter-packet time (in seconds) for achieving the desired throughput when using the 
#packet sizes in the input file.

# usage example:
# $perl calculate_ipt_for_a_throughput.perl lengths.txt 10000

# 151550880 bytes	200006 packets	10000 bps
# inter-packet time: 0.606185334439967	trace duration with this throughput: 121240.704

# this subroutine returns a line from the file. If the file is ended, it returns 0
sub read_file_line { 
  my $fh = shift; 
 
  if ($fh and my $line = <$fh>) { 
    chomp $line; 
    return [ split(/\t/, $line) ]; 
  } 
  return 0; 
} 

# get the parameters
$file=$ARGV[0];
$throughput = $ARGV[1];

open(my $file_, $file); 

my $line_ = read_file_line($file_); 

my $acum_bytes = 0;
my $num_packets = 0;
my $end_file = 0;
my $pps = 0;
my $ipt = 0; #inter-packet time


# I read the file
while ($end_file == 0) {
	# I accumulate the packet size
	if ( $line_->[0] != -1) {
		$acum_bytes = $acum_bytes + $line_->[0]; 
		$acum_packets = $acum_packets + 1; 
	}

	$line_ = read_file_line($file_);

	if (not $line_ ) {
		$end_file = 1;
	}

} # the file has ended

# calculate the packets-per-second rate required for the desired throughput
$pps = ( $throughput * $acum_packets ) / ( 8 * $acum_bytes) ;
$ipt = 1 / $pps ;
$trace_duration = $acum_packets / $pps ;

# I print the results
print STDOUT "Original trace: $acum_bytes bytes\t$acum_packets packets\t\n";
print STDOUT "inter-packet time: $ipt sec\nrate: $pps pps\ntrace duration for the desired throughput: $trace_duration sec\n";

close($file_); 
