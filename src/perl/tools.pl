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



sub find_file_in_parents {
	my $find = shift;
	my $path = shift;
	my $deep = shift;
	if (! defined $deep) {
		$deep = 0;
	} elsif ($deep < 0) {
		return "";
	}
	if (! defined $path || length($path) == 0 || $path eq $main::PWD) {
		$path = '.';
	}
	debug ("Checking dir: $path");
	opendir (DIR, $path) or die $!;
	FILE_LOOP:
	while (my $file = readdir(DIR)) {
		if (length($file) == 0) {
			next FILE_LOOP;
		}
		if ($file eq '.' || $file eq '..') {
			next FILE_LOOP;
		}
		if ($file eq $find) {
			debug ("Found file: $path / $file");
			closedir (DIR);
			return "$path/$file";
		}
	}
	closedir (DIR);
	return find_file_in_parents ($find, "$path/..", --$deep);
}



sub run_command {
	my $cmd = shift;
	if (length($cmd) == 0) {
		error ("No command argument provided!");
		exit 1;
	}
	if ($main::testing == 0) {
		debug ("COMMAND:\n$cmd");
		print "\n";
		system ($cmd) and error ("Failed to run command!");
		print "\n";
	} else {
		debug ("COMMAND SKIPPED:\n$cmd");
	}
}



sub split_comma {
	my $data = shift;
	if (! defined $data || length($data) == 0) {
		return "";
	}
	return split (/[,\s]+/, $data);
}



##################################################
### logging



sub title {
	big_title ( shift );
}
sub small_title {
	my $title = shift;
	my @lines = split /\n/, $title;
	my $maxlen = 0;
	LINES_LOOP:
	foreach my $line (@lines) {
		my $len = length($line);
		if ($len == 0) {
			next LINES_LOOP;
		}
		if ($len > $maxlen) {
			$maxlen = $len;
		}
	}
	if ($maxlen == 0) {
		return;
	}
	my $full  = ( '*' x ($maxlen + 8) );
	my $blank = ( ' ' x $maxlen );
	print "\n\n";
	print " $full \n";
	foreach my $line (@lines) {
		my $padding = $maxlen - length($line);
		my $padfront = ( ' ' x floor ($padding / 2) );
		my $padend   = ( ' ' x ceil  ($padding / 2) );
		print " **  $padfront$line$padend  ** \n";
	}
	print " $full \n";
	print "\n";
}
sub big_title {
	my $title = shift;
	my @lines = split /\n/, $title;
	my $maxlen = 0;
	LINES_LOOP:
	foreach my $line (@lines) {
		my $len = length($line);
		if ($len == 0) {
			next LINES_LOOP;
		}
		if ($len > $maxlen) {
			$maxlen = $len;
		}
	}
	if ($maxlen == 0) {
		return;
	}
	my $full  = ( '*' x ($maxlen + 10) );
	my $blank = ( ' ' x $maxlen );
	print "\n\n";
	print " $full \n";
	print " $full \n";
	print " ***  $blank  *** \n";
	foreach my $line (@lines) {
		my $padding = $maxlen - length($line);
		my $padfront = ( ' ' x floor ($padding / 2) );
		my $padend   = ( ' ' x ceil  ($padding / 2) );
		print " ***  $padfront$line$padend  *** \n";
	}
	print " ***  $blank  *** \n";
	print " $full \n";
	print " $full \n";
	print "\n";
}



sub debug {
	if ($main::debug == 0) {
		return;
	}
	my $msg = shift;
	if (! defined $msg || length($msg) == 0) {
		print "\n";
		return;
	}
	my @lines = split /\n/, $msg;
	LINES_LOOP:
	foreach my $line (@lines) {
		if (length($line) == 0) {
			next LINES_LOOP;
		}
		print " [debug]  $line\n";
	}
}
sub error {
	my $msg = shift;
	my $err = shift;
	if (!defined $msg || length($msg) == 0) {
		$msg = "Failed unexpectedly!";
	}
	if (!defined $err || length($err) == 0 || $err eq "0") {
		$err = 1;
	}
	print "\n\n";
	print "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n";
	print "\n [ERROR:$err]  $msg\n\n";
	print "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n";
	print "\n\n";
	exit 1;
}



1;