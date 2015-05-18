#!/usr/bin/perl

# this PERL script reads two arguments:
#
# $perl adjust_packet_sizes.pl packet_sizes.txt min_size max_size
#
#these are the two arguments:
# file where packet lengths are (in bytes). One packet size per line
# maximum size

# the script returns a file where the packet sizes have been cut to the max size

# usage example:
# $perl adjust_packet_sizes.perl lengths.txt 1 1500



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
$min_size = $ARGV[1];
$max_size = $ARGV[2];

open(my $file_, $file); 

my $line_ = read_file_line($file_); 
my $acum_lost_bytes = 0;
my $num_packets_changed = 0;
my $end_file = 0;

# I read the file
#while ($end_file == 0) {
while ( $line_ ) {
	# I accumulate the packet size
	if ( $line_->[0] != -1) {
		if ( $line_->[0] < $min_size ) {
			print STDOUT "$min_size\n";
			$modified_packets = $modified_packets + 1 ;
		} else {
			if ( $line_->[0] > $max_size ) {
				print STDOUT "$max_size\n";
				#$modified_packets = $modified_packets + 1 ;
			} else {
				print STDOUT "$line_->[0]\n";
			}
		}
		$acum_packets = $acum_packets + 1; 
	}

	$line_ = read_file_line($file_);

	if (not $line_ ) {
		$end_file = 1;
	}

} # the file has ended

# I print the results
#print STDOUT "Num packets modified: $modified_packets. Total $acum_packets packets.\n";


close($file_); 
