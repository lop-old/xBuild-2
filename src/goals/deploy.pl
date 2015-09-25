use strict;
use warnings;



sub goal_deploy {
	print "Deploying packages..\n";
	my $goal_config = shift;
	my $optional    = shift;
	my $PWD = $main::PWD;
	my $paths = $main::deploy->{Paths};
	my $path_downloads   = $paths->{'Downloads'};
	my $path_yum_testing = $paths->{'Yum Testing'};
	my $path_yum_stable  = $paths->{'Yum Stable'};
	$path_downloads   = goals_deploy_replace_tags ($path_downloads);
	$path_yum_testing = goals_deploy_replace_tags ($path_yum_testing);
	$path_yum_stable  = goals_deploy_replace_tags ($path_yum_stable);
	print "\n";
	print "Downloads:   $path_downloads\n";
	print "Yum Testing: $path_yum_testing\n";
	print "Yum Stable:  $path_yum_stable\n";
	print "\n";
	if ( -d $path_downloads ) {
		debug ("Found Downloads path:   $path_downloads");
	} else {
		print "Creating Downloads directory:   $path_downloads\n";
		mkdir ($path_downloads);
	}
	if ( -d $path_yum_testing ) {
		debug ("Found Yum Testing path: $path_yum_testing");
	} else {
		print "Creating Yum Testing directory: $path_yum_testing\n";
		mkdir ($path_yum_testing);
	}
	if ( -d $path_yum_stable ) {
		debug ("Found Yum Stable path:  $path_yum_stable");
	} else {
		print "Creating Yum Stable directory:  $path_yum_stable\n";
		mkdir ($path_yum_stable);
	}

	# find files to deploy
	my @files = @{$goal_config->{Files}};
	if (0+@files == 0) {
		error ("No files configured to deploy!");
		exit 1;
	}

	# ensure expected files exist
	print "\n\n";
	print "Files:\n";
	my @files_missing = ();
	LOOP_FILES:
	for my $file (@files) {
		if (length($file) == 0) {
			next LOOP_FILES;
		}
		$file = goals_deploy_replace_tags ($file);
		if ( -f "$PWD/$file" ) {
			print "$file\n";
		} else {
			print "MISSING: $file\n";
			push (@files_missing, $file);
		}
	} # /LOOP_FILES
	print "\n\n";

	# deploy files
	LOOP_FILES:
	for my $file (@files) {
		if (length($file) == 0) {
			next LOOP_FILES;
		}
		$file = goals_deploy_replace_tags ($file);
		my $filepath = "";
		my ($filename) = ($file =~ /.*\/(.*)/);
		if (length($path_downloads) == 0 && length($path_yum_testing) == 0) {
			error ("Downloads or Yum Testing destination must be set in ${main::deploy_config_file}");
			exit 1;
		}
		# copy to downloads/
		if (length($path_downloads) > 0) {
			print "Deploying: $file  to: $path_downloads/\n";
			$filepath = "$path_downloads/$filename";
			if ($main::testing == 0) {
				copy ( "$PWD/$file", "$path_downloads/" ) or error ("Failed to copy file: $file  to: $path_downloads/");
			}
		}
		# copy to yum/testing/
		if (length($path_yum_testing) > 0) {
			if (length($filepath) == 0) {
				print "Deploying: $file  to: $path_yum_testing/\n";
				$filepath = "$path_yum_testing/$filename";
				if ($main::testing == 0) {
					copy ( "$PWD/$file", "$path_downloads/" ) or error ("Failed to copy file: $file  to: $path_downloads/");
				}
			} else {
				print "Symlink:   $filename  to: $path_yum_testing/\n";
				debug ();
				run_command(
					"ln -svf \"$filepath\" \"$path_yum_testing/\" || exit 1"
				);
			}
		}
		# something went wrong
		if (length($filepath) == 0) {
			error ("Failed to deploy file for an unknown reason! $file");
			exit 1;
		}
	} # /LOOP_FILES
	print "\n";

	# files missing
	if (0+@files_missing > 0) {
		error ("One or more files are missing; builds may have failed!");
		exit 1;
	}
}



sub goals_deploy_replace_tags {
	my $file = shift;
	if (! defined $file || length($file) == 0) {
		return "";
	}
	$file =~ s/\<PROJECT_NAME\>/${main::project_name}/g;
	$file =~ s/\<PROJECT_VERSION\>/${main::project_version}/g;
	$file =~ s/\<PROJECT_BUILD_NUMBER\>/${main::project_build_number}/g;
	return $file;
}



1;