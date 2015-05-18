#!/usr/bin/perl

# this script is to be used with ns2 trace files

# trace files are this kind:
# r 0.100003 0 4 tcp 40 ------- 111000 0.0 1.0 0 2

# see http://nsnam.isi.edu/nsnam/index.php/NS-2_Trace_Formats

# the second column (0.100003 in the example) is the time. it is $x[1]


# type: perl throughput.pl <trace file> <+ or r> <origin node> <destination node> <tick> <protocol>  >  output file

# if <protocol> is 'all', it is not taken into account

# if <origin node>=-1, then it does not matter the origin node
# if <destination node>=-1 then it does not matter the destination node

# $ perl throughput.pl out.tr 5 0.1 tcp > throughput_5.txt

# the result is in bps

# the script computes the bps RECEIVED by the node in the trace
# # the link to study has to be included in the trace

$infile = $ARGV[0];
$type_packet = $ARGV[1];	# can be a sending (+) or a reception (r)
$fromnode = $ARGV[2];
$tonode = $ARGV[3];
$tick = $ARGV[4];
$protocol = $ARGV[5];		#'tcp' or 'cbr'

#we compute how many bits were transmitted during time interval specified
#by tick parameter in seconds
$sum = 0;
$tick_begin = 0;

open (DATA,"<$infile")
	|| die "Can't open $infile $!";
  
while (<DATA>) {
	@x = split(' ');

	#column 1 is time 
	if ( $x[1] <= $tick_begin + $tick )
	{
		#checking if the event corresponds to a reception or sending
		if ($x[0] eq $type_packet) 
		{ 
			#checking if the origin corresponds to arg 1
			if (($x[2] eq $fromnode) || ( $fromnode eq -1))
			{ 
				#checking if the destination corresponds to arg 2
				if (($x[3] eq $tonode) || ( $tonode eq -1))
				{ 
					#checking if the packet type is the name of the corresponding protocol
					if (($x[4] eq $protocol) || ( $protocol eq 'all'))
					{
						# acumulating the data
						$sum = $sum + ( 8 * $x[5] ); #factor of 8 for passing to bits
						#print STDOUT "$x[5]\n";
					}
				}
			}
		}
	} else {
		# a tick has finished
		$throughput = $sum / $tick;
		print STDOUT "$tick_begin\t$throughput\n";

		# get the data of the current packet for the next tick
		$sum = ( 8 * $x[5] ); #factor of 8 for passing to bits
		#print STDOUT "$x[5]\n";

		$tick_begin = $tick_begin + $tick;

		# for each tick without packets, put the tick_begin time and 0
		while ( $x[1] > $tick + $tick_begin ) {
			print STDOUT "$tick_begin\t0\n";
			$tick_begin = $tick_begin + $tick;		
		}
	}
}

# last tick
$throughput = $sum / $tick;
$tick_begin = $tick_begin + $tick;
print STDOUT "$tick_begin\t$throughput\n";
$sum = 0;

close DATA;
exit(0);