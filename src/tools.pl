use strict;
use warnings;



sub load_file_contents {
	my $filepath = shift;
	if (! -f $filepath) {
		debug ("File not found: $filepath");
		return "";
	}
	debug ("Loading file: $filepath");
	open (FILE, '<:encoding(UTF-8)', $filepath)
		or error ("Unable to open file: $filepath");
	my $data = "";
	while (my $line = <FILE>) {
		chomp $line;
		$data .= "$line\n";
	}
	close (FILE);
	if (length($data) == 0) {
		debug ("File is empty: $filepath");
		return "";
	}
	return $data;
}



sub bin_file_exists {
	my $filename = shift;
	system ("which $filename >/dev/null || { echo \"Composer is not available - yum install rpm-build\"; exit 1; }")
		and error ("'which' command failed!");
}



sub split_comma {
	my $data = shift;
	if (! defined $data || length($data) == 0) {
		return "";
	}
	return split (/[,\s]+/, $data);
}



1;