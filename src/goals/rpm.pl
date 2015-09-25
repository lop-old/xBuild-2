use strict;
use warnings;



sub goal_rpm {
	print "Building rpm..\n";
	my $goal_config = shift;
	my $arch = 'noarch';
	if (exists $goal_config->{Arch}) {
		$arch = $goal_config->{Arch};
	}
	if (length($arch) == 0) {
		error ("Arch argument not set in goal_rpm() call!");
		exit 1;
	}
	# ensure tools are available
	bin_file_exists ("rpmbuild");
	# build multi-arch
	if (index($arch, ',') != -1 || index($arch, ' ') != -1) {
		ARCH_LOOP:
		for $a ( split_comma ($arch) ) {
			if (length($a) == 0) {
				next ARCH_LOOP;
			}
			goal_rpm ($goal_config, $a);
		}
		return;
	}
	goal_rpm_build ($goal_config, $arch);
}



sub goal_rpm_build {
	my $goal_config = shift;
	my $RPM_ARCH    = shift;
	my $PWD = $main::PWD;
	my $RPM_SPEC   = "${main::project_name}.spec";
	my $BUILD_ROOT = "rpmbuild-root";
	my $RPM_SOURCE = "$PWD";
	my $BUILD_NUMBER = $main::project_build_number;
	if ($BUILD_NUMBER ne 'x' || length($BUILD_NUMBER) == 0) {
		$BUILD_NUMBER = int ($main::project_build_number);
	}
	my $SOURCE_PATH = "";
	my $SOURCE_FILE = "";
	if (exists $goal_config->{Source}) {
		$SOURCE_PATH = $goal_config->{Source};
	}
	# .spec file exists
	if ( ! -f "$PWD/$RPM_SPEC" ) {
		error ("Spec file not found: $RPM_SPEC");
		exit 1;
	}
	debug ("Found spec file: $RPM_SPEC");
	# create build space
	if ( ! -d "$PWD/$BUILD_ROOT/" ) {
		debug ("Creating directory: $BUILD_ROOT/");
		mkdir "$PWD/$BUILD_ROOT/";
	}
	foreach my $dir ( 'BUILD', 'BUILDROOT', 'RPMS', 'SOURCE', 'SOURCES', 'SPECS', 'SRPMS', 'tmp' ) {
		if ( ! -d "$PWD/$BUILD_ROOT/$dir/" ) {
			debug ("Creating directory: $BUILD_ROOT/$dir/");
			mkdir "$PWD/$BUILD_ROOT/$dir/";
		}
	}
	# copy .spec file to rpmbuild-root/SPECS/
	if ($main::testing == 0) {
		copy ( "$PWD/$RPM_SPEC", "$PWD/$BUILD_ROOT/SPECS/" ) or error ("Failed to copy .spec file!");
	}
	# get source file
	if ($main::testing == 0 && length($SOURCE_PATH) > 0) {
		($SOURCE_FILE = $SOURCE_PATH) =~ s/.*\///;
		if (length($SOURCE_FILE) == 0) {
			error ("File name must be specified in source path: $SOURCE_PATH");
			exit 1;
		}
		# download source file
		if ( $SOURCE_PATH =~ m/^(http|https):\/\/.*/ ) {
			debug ("Downloading source file: $SOURCE_FILE  from: $SOURCE_PATH");
			run_command (
				"wget -O \"$PWD/$BUILD_ROOT/SOURCES/$SOURCE_FILE\" \"$SOURCE_PATH\" ".
				"|| { echo \"Failed to download source file!\"; exit 1; }"
			);
		# copy local source file
		} else {
			if ( ! -f "$PWD/$SOURCE_PATH" ) {
				error ("Source file not found: $SOURCE_PATH");
				exit 1;
			}
			debug ("Making copy of source file: $SOURCE_PATH  to: $BUILD_ROOT/SOURCES/");
			copy ("$PWD/$SOURCE_PATH", "$PWD/$BUILD_ROOT/SOURCES/") or error ("Failed to copy source file: $SOURCE_PATH");
		}
	}
	# build rpm
	{
		my $cmd = <<EOF;
rpmbuild -bb \\
	--target="$RPM_ARCH" \\
	--define="_topdir $PWD/$BUILD_ROOT/" \\
	--define="_tmppath $PWD/$BUILD_ROOT/tmp/" \\
	--define="SOURCE_ROOT $RPM_SOURCE/" \\
	--define="_rpmdir $PWD/target/" \\
	--define="BUILD_NUMBER $BUILD_NUMBER" \\
	"$PWD/$BUILD_ROOT/SPECS/$RPM_SPEC" \\
		|| exit 1
EOF
		# run rpmbuild command
		run_command ($cmd);
		print "Results: ";
		system ("ls -l $PWD/$BUILD_TARGET/");
		print "\n";
	}
}



sub parse_version_file_spec {
	my $file = shift;
	debug ("Parsing file: $file");
	open (FILE, $file) or error ("Failed to read file: $file");
	while (my $line = <FILE>) {
		$line =~ /Version\s*\:\s*(\d+\.\d+\.\d+(\.\d+)?)/g || next;
		my ($vers) = ($1);
		if (defined $vers && length($vers) > 0) {
			close (FILE);
			debug ("Parsed version: $vers");
			return $vers;
		}
	}
	close FILE;
	error ("Missing Version field in file: $file");
	exit 1;
}



1;