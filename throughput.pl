#!/usr/bin/perl

# type: perl throughput.pl <packet size trace file> <inter-packet time trace file [ms]> <tick [ms]> 

# example:

# $ perl throughput.pl ip_len.txt ipt.txt 10

# this takes a single-column file of lengths and a single column file of ipt, and calculates the throughput

# the script computes the bps in the trace files

# it reads a line from each file, so the shortest file will define the number of packets read

# it generates an output with two columns:

# - tick starting time [ms]
# - throughput during the tick [bps]

# this subroutine returns a line from the file. If the file is ended, it returns 0
sub read_file_line { 
  my $fh = shift; 
 
  if ($fh and my $line = <$fh>) { 
    chomp $line; 
    return [ split(/\t/, $line) ]; 
  } 
  return 0; 
} 

$size_file = $ARGV[0];
$ipt_file = $ARGV[1];
$tick = $ARGV[2];

#we compute how many bits were transmitted during time interval specified
#by tick parameter in seconds
$sum = 0;
$tick_begin = 0;

my $acum_bytes = 0;
my $acum_packets = 0;
my $absolut_time = 0.0;

open(my $size_file_, $size_file); 
open(my $ipt_file_, $ipt_file);

my $size_line_ = read_file_line($size_file_); 
my $ipt_line_ = read_file_line($ipt_file_);

while (($end_size_file == 0) & ($end_ipt_file == 0)) {

	# if the tick has not finished:
	if ( $absolut_time <= $tick_begin + $tick )
	{
		# acumulating the data
		$acum_bytes = $acum_bytes + $size_line_->[0]; 
		$acum_packets = $acum_packets + 1;
		$absolut_time = $absolut_time + $ipt_line_->[0];

		#print STDOUT "1\t$acum_bytes\t$absolut_time\t$tick_begin\t$throughput\n";

	# a tick has finished:
	} else {

		$throughput = $acum_bytes * 8 * 1000 / $tick ;	# factor of 1000 because time is in ms
		#print STDOUT "$absolut_time\t$tick_begin\t$acum_bytes\t$throughput\n";
		print STDOUT "$tick_begin\t$throughput\t$acum_packets\n";

		# get the data of the current packet for the next tick
		$acum_bytes = $size_line_->[0]; 
		$acum_packets = 1;
		$absolut_time = $absolut_time + $ipt_line_->[0];

		$tick_begin = $tick_begin + $tick;

		# for each tick without packets, put the tick_begin time and 0
		while ( $absolut_time > $tick_begin + $tick ) {
			#the number of bytes and the throughput are null in these ticks
			#print STDOUT "$absolut_time\t$tick_begin\t0\t0\n";
			print STDOUT "$tick_begin\t0\t0\n";
			$tick_begin = $tick_begin + $tick;		
		}
	}

	# read another line
	$size_line_ = read_file_line($size_file_); 
	$ipt_line_ = read_file_line($ipt_file_);

	if (not $size_line_ ) {
		$end_size_file = 1;
	}

	if (not $ipt_line_ ) {
		$end_ipt_file = 1;
	}
}

# last tick
$throughput = $acum_bytes * 8 * 1000 / $tick ;
$tick_begin = $tick_begin + $tick;
print STDOUT "$tick_begin\t$throughput\t$acum_packets\n";

close($size_file_);
close($ipt_file_);
exit(0);
