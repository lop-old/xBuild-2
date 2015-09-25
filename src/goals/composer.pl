use strict;
use warnings;



sub goal_composer {
	print "Building with composer..\n";
error ("Sorry, this goal is unfinished!");
	# ensure tools are available
	bin_file_exists ("php");
	bin_file_exists ("composer");

	my $path = $main::PWD;
	if ( ! -f "$path/composer.json" ) {
		error ("composer.json file not found: $path/");
		exit 1;
	}

	# composer install
	{
		print "Composer update: $path\n";
		my $cmd = <<EOF;
pushd "$path" && \\
php `which composer` update -v --working-dir "$path/" \\
	|| { echo "Failed to run composer install command: $path/"; exit 1; }
popd
EOF
		debug ("COMMAND:\n$cmd");
		system ($cmd) and error ("Failed to run composer update!");
		# run phpunit if available
		if ( -f "$path/vendor/bin/phpunit" ) {
			my $cmd = <<EOF;
pushd "$path" && \\
php "$path/vendor/bin/phpunit" \\
	--coverage-html="$path/coverage/html/" \\
	--coverage-php="$path/coverage/coverage.php/" \\
	--coverage-text="$path/coverage/coverage.txt" \\
	--coverage-xml="$path/coverage/xml/" \\
		|| { echo "Failed to run composer install command: $path/"; exit 1; }
popd
EOF
			debug ("COMMAND:\n$cmd");
			system ($cmd) and error ("Failed to run composer install!");
		}
	}
}



1;