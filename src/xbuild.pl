#!/usr/bin/perl -w
##===============================================================================
## Copyright (c) 2013-2015 PoiXson, Mattsoft
## <http://poixson.com> <http://mattsoft.net>
##
## Description: Build and deploy script for maven and rpm projects.
##
## Install to location: /usr/bin/shellscripts
##
## Download the original from:
##   http://dl.poixson.com/shellscripts/
##
## Permission to use, copy, modify, and/or distribute this software for any
## purpose with or without fee is hereby granted, provided that the above
## copyright notice and this permission notice appear in all copies.
##
## THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
## WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
## MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
## ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
## WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
## ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
## OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
##===============================================================================
# xbuild.pl

use strict;
use warnings;
use POSIX;
use File::Copy;
use JSON;
use Switch;
#use Cwd;

use Data::Dumper;



##################################################



our $project_config_file  = 'xbuild.json';
our $global_default_goals = 'clean';



##################################################



our $debug = 0;

our @goals = ();



# parse arguments
ARGS_LOOP:
while (my $arg = shift(@ARGV)) {
	if ( $arg =~ /^\-/ ) {
		switch ($arg) {
			case '-d' {
				$arg = '--debug';
			}
			case '-h' {
				$arg = '--help';
			}
			case '-v' {
				$arg = '--version';
			}
		} # /ALIAS_LOOP
		switch ($arg) {
			case '--debug' {
				$debug = 1;
			}
			case '--help' {
				print "Usage: xbuild [-hv] [GOAL]...\n";
				print "Reads a xbuild.json config file from a project and performs build goals.\n";
				print "\n";
				print "  -d, --debug    debug mode, most verbose logging\n";
				print "\n";
				print "  -h, --help     display this help and exit\n";
				print "  -v, --version  output version information and exit\n";
				print "\n";
				exit 0;
			}
			case '--version' {
				print "\nx.x.x\n\n";
				exit 0;
			}
			else {
				error ("Unknown argument: $arg");
				exit 1;
			}
		} # /FLAG_SWITCH
		next ARGS_LOOP;
	} # /IS_FLAG
	# anything else should be a goal name
	push (@goals, $arg);
} # /ARGS_LOOP



# load xbuild.json config
our $config = load_xbuild_json();

# project name
our $project_name = $config->{Name};

# gitignore append
our @project_gitignore_append = @{$config->{'GitIgnore Append'}};

# default goals
our @project_default_goals;
{
	my $default_goals = $config->{'Default Goals'};
	if (!defined $default_goals || length($default_goals) == 0) {
		$default_goals = $global_default_goals;
	}
	@project_default_goals = split / /, $default_goals;
}
if ( (0+@goals) == 0 ) {
	@goals = @project_default_goals;
}

# version files
our @project_version_files = @{$config->{'Version Files'}};
our $project_version = parse_version_from_files(@project_version_files);



##################################################



# display info
big_title ("Project: $project_name\nVersion: $project_version");
#print " Name:    $project_name\n";
#print " Version: $project_version\n";
#print "\n";
print " Default Goals:    "; print join ", ", @project_default_goals; print "\n";
print " Performing Goals: "; print join ", ", @goals; print "\n";



# perform goals
my $project_title = "$project_name $project_version";
for my $goal (@goals) {
	switch ($goal) {
		case 'clean' {
			small_title ("$project_title\nGoal: $goal");
			goal_clean ();
		}
		case 'prep' {
			small_title ("$project_title\nGoal: $goal");
			goal_prep ();
		}
		case 'maven' {
			small_title ("$project_title\nGoal: $goal");
			goal_maven ();
		}
		case 'gradle' {
			small_title ("$project_title\nGoal: $goal");
			goal_gradle ();
		}
		case 'rpm' {
			small_title ("$project_title\nGoal: $goal");
			goal_rpm ();
		}
		case 'composer' {
			small_title ("$project_title\nGoal: $goal");
			goal_composer ();
		}
		else {
			error ("Unknown goal: $goal");
		}
	} # /GOAL_SWITCH
}



print "\n\n FINISHED!\n\n";
exit 0;



##################################################



sub goal_clean {
	print "Cleaning..\n";
	my $pwd = getcwd;
	foreach my $dir ( 'target', 'rpmbuild-root', 'build', 'bin', 'out' ) {
		my $path = "$pwd/$dir/";
		if ( -d "$path" ) {
			debug ("deleting path: $path");
			system ("[ -z \"$path\" ] || rm -Rf --preserve-root \"$path\" || exit 1");
		}
	}
}



sub goal_prep {
	my $pwd = getcwd;
	# generate .gitignore file
	{
		my $filename = '.gitignore';
		my $data = <<EOF;
**/.project
**/.classpath
**/.settings/
**/nbproject/

.git/
**/target/
**/rpmbuild-root/
**/build/
**/bin/
**/out/

*.zip
*.exe
*.rpm
*.jar
*.war
*.ear
*.class
*.iml
*.idea
*.lock
*.out

*.swp
.*.swp
*~
EOF
		# append custom filenames
		my $first = 1;
		APPEND_LOOP:
		foreach $filename (@project_gitignore_append) {
			if (!defined $filename || length($filename) == 0) {
				next APPEND_LOOP;
			}
			if ($first == 1) {
				$first = 0;
				$data .= "\n# Custom\n# ======\n\n";
			}
			$data .= "$filename\n";
		}
		print "Creating file: .gitignore\n";
		open (my $FILE, '>', "$pwd/$filename") or error ("Failed to write to file: $filename");
		print $FILE "#  Auto Generated File\n";
		print $FILE "# =====================\n\n";
		print $FILE $data;
		close $FILE;
	}
#	# update composer
#	if ( -f "$pwd/composer.json" ) {
#		my $cmd = "composer self-update || { echo \"Failed to update composer!\"; exit 1; }";
#		system $cmd;
#	}

	# composer install
	{
		my $path = "$pwd";
		print "Composer update: $path\n";
		my $cmd = <<EOF;
pushd "$path" && \\
php `which composer` update -v --working-dir "$path/" || \\
{ echo "Failed to run composer install command: $path/"; exit 1; }
popd
EOF
		debug ("COMMAND:\n$cmd");
		system $cmd;
	}
}
sub goal_version {
print "Updating version..\n";
error ("Sorry, this goal is unfinished!");
}



sub goal_maven {
print "Building with maven..\n";
error ("Sorry, this goal is unfinished!");
	# ensure tools are available
	system 'which mvn >/dev/null || { echo "Composer is not available - yum install maven"; exit 1; }';
}



sub goal_gradle {
print "Building with gradle..\n";
error ("Sorry, this goal is unfinished!");
	# ensure tools are available
	system 'which gradle >/dev/null || { echo "Composer is not available - yum install gradle"; exit 1; }';

}



sub goal_rpm {
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



sub goal_composer {
error ("Sorry, this goal is unfinished!");
	# ensure tools are available
	system 'which php      >/dev/null || { echo "PHP is not available - yum install php56w"; exit 1; }';
	system 'which composer >/dev/null || { echo "Composer is not available - yum install php-tools"; exit 1; }';

	my $pwd = getcwd;
	my $path = "$pwd";
	if ( ! -d "$path/" ) {
		error ("Composer workspace not found: $path/");
		exit 1;
	}
	if ( ! -f "$path/composer.json" ) {
		error ("composer.json file not found: $path/");
		exit 1;
	}

	# composer install
	{
		my $path = "$pwd";
		print "Composer update: $path\n";
		my $cmd = <<EOF;
pushd "$path" && \\
php `which composer` update -v --working-dir "$path/" || \\
{ echo "Failed to run composer install command: $path/"; exit 1; }
popd
EOF
		debug ("COMMAND:\n$cmd");
		system $cmd;
		# run phpunit if available
		if ( -f "$path/vendor/bin/phpunit" ) {
			my $cmd = <<EOF;
pushd "$path" && \\
php "$path/vendor/bin/phpunit" \\
	--coverage-html="$path/coverage/html/" \\
	--coverage-php="$path/coverage/coverage.php/" \\
	--coverage-text="$path/coverage/coverage.txt" \\
	--coverage-xml="$path/coverage/xml/" || \\
{ echo "Failed to run composer install command: $path/"; exit 1; }
popd
EOF
			debug ("COMMAND:\n$cmd");
			system $cmd;
		}
	}

}



##################################################



# load xbuild.json config
sub load_xbuild_json {
	debug ("Loading config file: $project_config_file");
	open (FILE, '<:encoding(UTF-8)', $project_config_file)
		or error ("Unable to open file: $project_config_file");
	my $data = "";
	while (my $line = <FILE>) {
		chomp $line;
		$data .= "$line\n";
	}
	if (length($data) == 0) {
		error ("Config file $project_config_file is empty!");
		exit 1;
	}
	my $json = JSON->new->utf8->decode($data);
	return $json;
}



# auto detect project version
sub parse_version_from_files {
	my @files = shift;
	my $version = "";
	if ( (0+@files) == 0 ) {
		error ("No version files specified in config file: $project_config_file");
		exit 1;
	}
	# check all files
	my $isempty = 1;
	FILES_LOOP:
	for (@files) {
		# get file name
		my $file = $_;
		if (!defined $file || length($file) == 0) {
			next FILES_LOOP;
		}
		# get file extension
		my ($ext) = $file =~ /(\.[^.]+)$/;
		if (!defined $ext || length($ext) == 0) {
			error ("File has no extension: $file");
			exit 1;
		}
		$isempty = 0;
		my $vers = parse_version_file($file, $ext);
		if (!defined $vers || length($vers) == 0) {
			error ("Failed to parse version number from file: $file");
			exit 1;
		}
		# store version number
		if (length($version) == 0) {
			$version = $vers;
		# verify version number
		} else {
			if ($version ne $vers) {
				error ("Version miss-match:  $version  !=  $vers  in  $file");
				exit 1;
			}
		}
	}
	if ($isempty == 1) {
		error ("No version files found in config: $project_config_file");
		exit 1;
	}
	if (length($version) == 0) {
		error ("Failed to detect project version!");
		exit 1;
	}
	return $version;
}
sub parse_version_file {
	my $file = shift;
	my $ext  = shift;

	# .spec
	if ($ext eq '.spec') {
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

	# pom.xml
	if ($file =~ /\/pom\.xml$/) {
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

	error ("Unknown file type: $file");
	exit 1;
}



##################################################



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
	if ($debug != 1) {
		return;
	}
	my $msg = shift;
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
