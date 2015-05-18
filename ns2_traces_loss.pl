#!/usr/bin/perl

# this script is to be used with ns2 trace files

# type: perl loss.pl <trace file sent packets> <trace file loss packets> <tick> >  output file

# trace files are this kind:
# r 0.100003 0 4 tcp 40 ------- 111000 0.0 1.0 0 2		first file
# d 0.974887 4 5 ack 40 ------- 112000 0.1 1.1 6 122	second file

# see http://nsnam.isi.edu/nsnam/index.php/NS-2_Trace_Formats

# the second column (0.100003 in the example) is the time. it is $x[1]

# every tick, the script:
#	- counts the number of lines in "trace file sent packets"
#	- counts the number of lines in "trace file loss packets"
#	- writes in the output file four values: tick	total_sent_packets	loss_packets	loss_packets/total_packets

# $ perl loss.pl file1.tr file2.tr 0.1 > throughput_5.txt

$first_file = $ARGV[0];
$second_file = $ARGV[1];
$tick = $ARGV[2];

#we compute how many packets were transmitted during time interval specified
#by tick parameter in seconds
$number_sent_packets = 0;
$number_lost_packets = 0;
$acum_packet_size = 0;
$tick_begin = 0;


print STDOUT "tick_begin\tsent_pkts\tlost_pkts\tpacket_loss\tavg_size_sent_pkts\n";

open my $info1, $first_file || die "Can't open $first_file $!";

open my $info2, $second_file || die "Can't open $second_file $!";
my $line2 = <$info2>;
@y = split(/\s+/, $line2);
#print STDOUT "hola\t$y[1]\n";

while ( my $line1 = <$info1>) {
	@x = split(/\s+/, $line1);

	#column 1 is time 
	while ( ($line1) && ($x[1] <= $tick_begin + $tick )) {
		
		# increase the counter
		$number_sent_packets = $number_sent_packets + 1;

		# recalculate the acumulated packet size
		$acum_packet_size = $acum_packet_size + $x[5];
		# read another line
		$line1 = <$info1>;
		@x = split(/\s+/, $line1);
		#print STDOUT "hola\t$x[7]\t$line1";	
	}
	
	# count the number of lost packets in the second file during the same tick
	while (($line2) && ( $y[1] <= $tick_begin + $tick )) {

		# increase the counter

		# read another line from the packet loss file
		$number_lost_packets = $number_lost_packets + 1;
		$line2 = <$info2>;
		@y = split(/\s+/, $line2);
	}

	# if there are no arrived packets, I consider packet loss as null
	if ( $number_sent_packets > 0 ) {
		$packet_loss = $number_lost_packets / $number_sent_packets ;
		
		# calculate average size of sent packets
		$average_packet_size = $acum_packet_size / $number_sent_packets;

	} else {
		$packet_loss = 0;
	}


	# write the results of this tick
	print STDOUT "$tick_begin\t$number_sent_packets\t$number_lost_packets\t$packet_loss\t$average_packet_size\n";

	$number_lost_packets = 0;
	$number_sent_packets = 1;
	$acum_packet_size = $x[5];
	$tick_begin = $tick_begin + $tick;
}

	


# last tick
#$throughput = $sum / $tick;
#$tick_begin = $tick_begin + $tick;
#print STDOUT "$tick_begin\t$throughput\n";
#$sum = 0;

close info1;
close info2;
exit(0);