use strict;
use warnings;



sub goal_maven {
	print "Running maven..\n";
error ("Sorry, this goal is unfinished!");
	# ensure tools are available
	bin_file_exists ("mvn");
}



sub parse_version_file_pom_xml {
	my $file = shift;
	debug ("Parsing file: $file");
	open (FILE, $file) or die "Failed to read file: $file";
	while (my $line = <FILE>) {
		$line =~ /\s*\<version\>(\d+\.\d+\.\d+(\.\d+)?)\<\/version\>/g || next;
		my ($vers) = ($1);
		if (defined $vers && length($vers) > 0) {
			close (FILE);
			debug ("Parsed version: $vers");
			return $vers;
		}
	}
	close FILE;
	error ("Missing <version> tag in file: $file");
	exit 1;
}



1;