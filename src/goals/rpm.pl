use strict;
use warnings;



sub goal_rpm {
error ("Sorry, this goal is unfinished!");
	# ensure tools are available
	system 'which rpmbuild >/dev/null || { echo "Composer is not available - yum install rpm-build"; exit 1; }';
	my $pwd = getcwd;
	my $RPM_SPEC   = "$project_name.spec";
	my $BUILD_ROOT = "$pwd/rpmbuild-root";
	my $RPM_SOURCE = "$pwd";
	my $ARCH       = "noarch";
my $BUILD_NUMBER = 0;
#my $SOURCE_PATH = "$BUILD_ROOT/";
#my $SOURCE_FILE = "";
	if ( ! -f "$pwd/$RPM_SPEC" ) {
		error ("Spec file not found: $RPM_SPEC");
		exit 1;
	}
	debug ("Found spec file: $RPM_SPEC");
	# create build space
	debug ("Creating directory: rpmbuild-root/");
	mkdir "$BUILD_ROOT/" unless -d "$BUILD_ROOT/";
	foreach my $dir ( 'BUILD', 'BUILDROOT', 'RPMS', 'SOURCE', 'SOURCES', 'SPECS', 'SRPMS', 'tmp' ) {
		debug ("Creating directory: rpmbuild-root/$dir/");
		mkdir "$BUILD_ROOT/$dir/" unless -d "$BUILD_ROOT/$dir/";
	}
	copy ( "$pwd/$RPM_SPEC", "$BUILD_ROOT/SPECS/" ) or error ("Failed to copy .spec file!");
#	# copy source file
#	if ($SOURCE_PATH ne "$BUILD_ROOT/SOURCES/") {
#		copy ( "$SOURCE_PATH$SOURCE_FILE", "$BUILD_ROOT/SOURCES/" ) or error ("Failed to copy source file: $SOURCE_FILE");
#	}
#	if (length($SOURCE_PATH) == 0) {
#		$SOURCE_PATH
#	}

	# build rpm
	{
		my $cmd = <<EOF;
rpmbuild -bb \\
	--target $ARCH \\
	--define="_topdir $BUILD_ROOT" \\
	--define="_tmppath $BUILD_ROOT/tmp" \\
	--define="SOURCE_ROOT $RPM_SOURCE" \\
	--define="_rpmdir $pwd/target" \\
	--define="BUILD_NUMBER $BUILD_NUMBER" \\
	"$BUILD_ROOT/SPECS/$RPM_SPEC" \\
		|| exit 1
EOF
		debug ("COMMAND:\n$cmd");
		system $cmd;
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