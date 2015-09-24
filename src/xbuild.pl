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



our $project_config_file  = 'xBuild.json';
our $global_default_goals = 'clean';



##################################################



our $debug = 0;
our $config;

our $project_name    = "";
our $project_version = "";
our @goals = ();
our @project_gitignore_append;
our @project_default_goals;
our @project_version_files;



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
$config = load_xbuild_json();

# project name
$project_name = $config->{Name};

# project version
$project_version = $config->{Version};

# gitignore append
@project_gitignore_append = @{$config->{'GitIgnore Append'}};

# default goals
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

{
	my $PWD = '/media/gwork/xBuild/src';
	require "$PWD/goals/clean.pl";
	require "$PWD/goals/composer.pl";
	require "$PWD/goals/deploy.pl";
	require "$PWD/goals/gradle.pl";
	require "$PWD/goals/maven.pl";
	require "$PWD/goals/prep.pl";
	require "$PWD/goals/rpm.pl";
}

# version files
@project_version_files = @{$config->{'Version Files'}};
$project_version = parse_version_from_files(@project_version_files);



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
	small_title ("$project_title\nGoal: $goal");
	if(! exists $config->{Goals}->{$goal}) {
		error ("Goal '$goal' not configured in $project_config_file project config!");
		exit 1;
	}
	my $goal_config = $config->{Goals}->{$goal};
	# find goal to run
	switch ($goal) {
		case 'clean' {
			goal_clean ($goal_config);
		}
		case 'prep' {
			goal_prep ($goal_config);
		}
		case 'gradle' {
			goal_gradle ($goal_config);
		}
		case 'maven' {
			goal_maven ($goal_config);
		}
		case 'gradle' {
			goal_gradle ($goal_config);
		}
		case 'rpm' {
			goal_rpm ($goal_config);
		}
		case 'composer' {
			goal_composer ($goal_config);
		}
		else {
			error ("Unknown goal: $goal");
		}
	} # /GOAL_SWITCH
}



small_title (" \nFINISHED!\n ");
exit 0;



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
		return &parse_version_file_spec ($file);
	}
	# pom.xml
	if ($file =~ /\/pom\.xml$/) {
		return &parse_version_file_pom_xml ($file);
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
