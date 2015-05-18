#!/usr/bin/perl

# this PERL script reads two arguments:
#
# $perl adapt_ipt_for_a_throughput.pl desired_throughput duration packet_size_file.txt ipt_file.txt prefix
#

# The script generates a new inter-packet time file with the duration and throughput desired when using the 
#packet sizes in the input file.
# It expands or shortens the inter-packet time for achieving the desired throughput

#these are the arguments:
# - desired_throughput: throughput obtained when using the packet size file and the output ipt file
# - duration: duration of the desired trace in seconds
# - packet size file: text file where packet lengths are (in bytes). One packet size per line
# - ipt file: file where inter-packet time (in seconds) is stored. One ipt per line

# THE OUTPUT IPTs are in MILLISECONDS

# usage example:
# $ perl adapt_ipt_for_a_throughput.pl 90000 20 ip_len_equinix_2015-adjusted.txt ipt_equinix_2015.txt adapted_
# this means:
# - 90 kbps
# - 20 seconds
# - it will read the lengths from	ip_len_equinix_2015-adjusted.txt
# - it will read the ipt from		ipt_equinix_2015.txt
# - it will add the prefix "adapted_" to the file names

#  two output files are generated:
#  - adapted_ip_len_equinix_2015-adjusted.txt
#  - adapted_ipt_equinix_2015.txt

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
$desired_throughput = $ARGV[0];
$desired_duration = $ARGV[1];
$size_file = $ARGV[2];
$ipt_file = $ARGV[3];
$prefix = $ARGV[4];

# variables
my $output_size_file = join "", $ARGV[4], $size_file;
my $output_ipt_file = join "", $ARGV[4], $ipt_file;
my $total_desired_bytes = 0;
my $acum_bytes = 0;
my $end_size_file = 0;
my $end_ipt_file = 0;
my $original_throughput = 0;
my $ipt_relationship;			#relationship between the inter-packet times
my $adapted_ipt = 0;
my $size = 0;

#1) calculate de number of bytes required for achieving the desired throughput during the desired duration

$total_desired_bytes = $desired_throughput * $desired_duration / 8;
print STDOUT "total desired bytes: $total_desired_bytes\n";

#2) go through the packet size input file until the number of desired bytes is achieved.
#   go through the ipt input file calculating the total time.
#   Obtain the original throughput

open(my $size_file_, $size_file); 
open(my $ipt_file_, $ipt_file);

my $size_line_ = read_file_line($size_file_); 
my $ipt_line_ = read_file_line($ipt_file_); 

# I read the size file
while (($end_size_file == 0) & ($end_ipt_file == 0) & ($acum_bytes < $total_desired_bytes)) {
	# I accumulate the packet size
	if ( $size_line_->[0] != -1) {
		$acum_bytes = $acum_bytes + $size_line_->[0]; 
		$acum_packets = $acum_packets + 1;
		$acum_time = $acum_time + $ipt_line_->[0];
	}

	$size_line_ = read_file_line($size_file_);
	$ipt_line_ = read_file_line($ipt_file_);

	if (not $size_line_ ) {
		$end_size_file = 1;
	}

	if (not $ipt_line_ ) {
		$end_ipt_file = 1;
	}
}
print STDOUT "total desired packets: $acum_packets\n";
print STDOUT "total time original trace: $acum_time\n";
close($size_file_);
close($ipt_file_);

# the size file has ended before getting the desired number of bytes
if ($end_size_file == 1) {
	print STDOUT "Not enough packets in the size file for the desired througput and duration\n";

}

# the ipt file has ended after getting the desired number of bytes
else {
	if ($end_ipt_file == 1) {
		print STDOUT "Not enough inter-packet times in the ipt file\n";
	}

	# the number of bytes has been correctly achieved
	else {

		#3) calculate the throughput of the original files
		$original_throughput = $acum_bytes * 8 / $acum_time ;

		print STDOUT "original throughput: $original_throughput\n";

		# calculate the relationship between the original and the desired ipt
		$ipt_relationship = $original_throughput / $desired_throughput ;

		# add a factor of 1000 to get the ipt in milliseconds
		my $ipt_relationship_ms = $ipt_relationship * 1000;



		#4) go through inter-packet time file and recalculate the inter-packet times
		#   write an output ip file as output_ipt = original_ipt * original_throughput / desired_throughput
		open($ipt_file_, $ipt_file); 
		open($size_file_, $size_file); 

		# '>', means that we are opening a file for writing
		open(my $output_size_file_, '>',  $output_size_file); 
		open(my $output_ipt_file_, '>', $output_ipt_file);

		$end_ipt_file = 0;

		$ipt_line_ = read_file_line($ipt_file_); 
		$size_line_ = read_file_line($size_file_);
		$size = sprintf ("%d", $size_line_);

		for (my $i=0; $i < $acum_packets; $i++) {
			# I calculate the new inter-packet time and write it
			if ( $ipt_line_->[0] != -1) {
				$adapted_ipt = $ipt_line_->[0] * $ipt_relationship_ms ;



				# print a value to the output ipt file
				# ipt cannot be null
				if ($adapted_ipt == 0.0 ) {
					$adapted_ipt = 0.00000000001;
				}
				printf $output_ipt_file_ ("%.12f", "$adapted_ipt");	#12 decimal digits
				printf $output_ipt_file_ ("\n");

				# print a value to the output size file
				print $output_size_file_ $size_line_->[0];
				print $output_size_file_ "\n";
			}

			$ipt_line_ = read_file_line($ipt_file_);
			$size_line_ = read_file_line($size_file_); 
			$size = sprintf ("%d", $size_line_);

			if (not $ipt_line_ ) {
				$end_ipt_file = 1;
			}

		}
		if ($end_ipt_file == 1) {
			print STDOUT "Not enough packets in the ipt file";
		}
		close($ipt_file_);
		close($size_file_);
		close($output_ipt_file_);
		close($output_size_file_);
	}
}
