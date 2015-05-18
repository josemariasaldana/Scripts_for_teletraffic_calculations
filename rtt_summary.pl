# type: perl rtt_summary.pl <file with rtt> <flow id> <second begin> output file

# trace files are this kind:
# now rtt_ rtt_smoothed_ rtt_variance_
# 0.010 0 0 4800
# 1.010 8 71 8
# 2.010 9 72 7
# 3.010 9 72 7

$first_file = $ARGV[0];
$flow_id = $ARGV[1];
$seconds = $ARGV[2];

#we compute how many packets were transmitted during time interval specified
#by tick parameter in seconds
$rtt_acum = 0;
$srtt_acum = 0;
$var_acum = 0;

$number_seconds = 0;

#print STDOUT "flow\tavg_rtt\tavg_srtt\tavg_var\t\n";
#print STDOUT "$first_file\t$flow_id\t$seconds\n";

open my $info1, $first_file || die "Can't open $first_file $!";

# read the first line (only text)
my $line1 = <$info1>;
@x = split(/\s+/, $line1);

# read the rest of the file
#column 0 is time 
while ( $line1 = <$info1> ) {
	@x = split(/\s+/, $line1);


	if ($x[0] > $seconds ) {
		$number_seconds = $number_seconds + 1;
		$rtt_acum = $rtt_acum + $x[1];
		$srtt_acum = $srtt_acum + $x[2];
		$var_acum = $var_acum + $x[3];
	}

}

if ($number_seconds > 0 ) {
	$rtt_avg = $rtt_acum / $number_seconds;
	$srtt_avg = $srtt_acum / $number_seconds;
	$var_avg = $var_acum / $number_seconds;
	print STDOUT "$flow_id\t$rtt_avg\t$srtt_avg\t$var_avg\n";
} else {
	print STDOUT "$flow_id\tno data\n";
}
close info1;

exit(0);