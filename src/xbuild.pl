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
## Required packages: perl-JSON perl-Switch
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
our $deploy_config_file   = 'xDeploy.json';
my  $SCRIPT_PATH      = "/usr/bin/xBuild";
my  $GOAL_SCRIPT_PATH = "$SCRIPT_PATH/goals";

our $DEPLOY_SEARCH_DEEP = 2;



##################################################



our $debug   = 0;
our $testing = 0;

our $config;
our $deploy;

our $project_name    = "";
our $project_version = "";
our $project_build_number = 'x';

our @goals_main  = ();
our @goals_build = ();
our @project_version_files;

our $USER = $ENV{USER};

our $PWD = getcwd;
if (length($PWD) == 0) {
	print "Failed to get current working directory!";
	exit 1;
}

require "$SCRIPT_PATH/tools.pl";



# parse arguments
ARGS_LOOP:
while (my $arg = shift(@ARGV)) {
	if ( $arg =~ /^\-/ ) {
		switch ($arg) {
			case '-n' {
				$arg = '--build-number';
			}
			case '-d' {
				$arg = '--debug';
			}
			case '-t' {
				$arg = '--test';
			}
			case '-h' {
				$arg = '--help';
			}
			case '-v' {
				$arg = '--version';
			}
		} # /ALIAS_LOOP
		switch ($arg) {
			case '--build-number' {
				$project_build_number = shift(@ARGV);
			}
			case '--debug' {
				$debug = 1;
			}
			case '--test' {
				$testing = 1;
			}
			case '--help' {
				print "Usage: xbuild [-hv] [GOAL]...\n";
				print "Reads a xbuild.json config file from a project and performs build goals.\n";
				print "\n";
				print "  -n, --build-number  set the build number\n";
				print "\n";
				print "  -t, --test     read only mode for testing\n";
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
	push (@goals_main, $arg);
} # /ARGS_LOOP
if ($debug   != 0) {
	debug ("Debug mode enabled");
}
if ($testing != 0) {
	debug ("Testing mode enabled");
}
debug ();
if ($PWD =~ m/^\/(usr|bin)\/.*/ ) {
	error ("Sorry, you cannot run this command from within /usr or /bin");
	exit 1;
}



##################################################
### load config files



# load xBuild.json
{
	my $data = load_file_contents ($project_config_file);
	if (! defined $data || length($data) == 0) {
		error ("File not found or failed to load: $project_config_file");
		exit 1;
	}
	$config = JSON->new->utf8->decode($data);
	debug ();
}
# load xDeploy.json
{
	debug ("Looking for deploy config: ${main::deploy_config_file}");
	my $found = find_file_in_parents (
		$main::deploy_config_file,
		'',
		$DEPLOY_SEARCH_DEEP
	);
	if (length($found) == 0) {
		debug ("File not found: ${main::deploy_config_file}");
	} else {
		debug ("Loading file: $found");
		my $data = load_file_contents ("$PWD/$found");
		if (defined $data && length($data) > 0) {
			$deploy = JSON->new->utf8->decode($data);
		}
	}
	debug ();
}



# project name
$project_name = $config->{Name};

# project version
$project_version = $config->{Version};



##################################################
### default goals



### main goals
# from xDeploy.json
if ( (0+@goals_main) == 0 ) {
	if (defined $deploy && exists $deploy->{'Default Goals'}) {
		my $data = $deploy->{'Default Goals'};
		@goals_main = split_comma ($data);
	}
}
# last resort defaults
if ( (0+@goals_main) == 0 ) {
	@goals_main = split_comma ("build");
}
if ( (0+@goals_main) == 0 ) {
	error ("Failed to find main goals to perform!");
	exit 1;
}



### build goals
# from xBuild.json
if ( (0+@goals_build) == 0 ) {
	if (exists $config->{'Build Goals'}) {
		my $data = $config->{'Build Goals'};
		@goals_build = split_comma ($data);
	}
}
# last resort defaults
if ( (0+@goals_build) == 0 ) {
	@goals_build = split_comma ("clean");
}
if ( (0+@goals_build) == 0 ) {
	error ("Failed to find build goals to perform!");
	exit 1;
}



##################################################
### perform goals



require "$GOAL_SCRIPT_PATH/clean.pl";
require "$GOAL_SCRIPT_PATH/composer.pl";
require "$GOAL_SCRIPT_PATH/deploy.pl";
require "$GOAL_SCRIPT_PATH/gradle.pl";
require "$GOAL_SCRIPT_PATH/maven.pl";
require "$GOAL_SCRIPT_PATH/prep.pl";
require "$GOAL_SCRIPT_PATH/rpm.pl";



# version files
@project_version_files = @{$config->{'Version Files'}};
$project_version = parse_version_from_files(@project_version_files);



# display info
big_title ("Project: $project_name\nVersion: $project_version $project_build_number");
print " Goals: "; print join ", ", @goals_main; print "\n";
print " Build: "; print join ", ", @goals_build; print "\n";



print " User: $USER\n";
my $project_title = "$project_name $project_version $project_build_number";
if (0+@goals_main == 0) {
	error ("No main goals to perform..\n");
	exit 1;
}
for my $goal (@goals_main) {
	perform_goal ($goal);
}



our $last_goal = "";
sub perform_goal {
	my $goal = shift;
#	small_title ("$project_title\nGoal: $goal");
	small_title ("Goal: $goal");
	# goal already ran
	if (defined $last_goal && length($last_goal) > 0) {
		if ($goal eq $last_goal) {
			print "\nSkipping goal '$goal' has just run..\n";
			return;
		}
	}
	my $goal_config;
	if(exists $config->{Goals}->{$goal}) {
		$goal_config = $config->{Goals}->{$goal};
	}
	# find goal to run
	GOAL_SWITCH:
	switch ($goal) {
		case 'build' {
			if (0+@goals_build == 0) {
				error ("No build goals to perform..\n");
				exit 1;
			}
			print " Build Goals: "; print join ", ", @goals_build; print "\n";
			for my $goal (@goals_build) {
				perform_goal ($goal);
			}
			return;
		}
		case 'clean' {
			goal_clean ($goal_config);
		}
		case 'composer' {
			goal_composer ($goal_config);
		}
		case 'deploy' {
			goal_deploy ($goal_config, 0);
		}
		case '[deploy]' {
			goal_deploy ($goal_config, 1);
		}
		case 'gradle' {
			goal_gradle ($goal_config);
		}
		case 'maven' {
			goal_maven ($goal_config);
		}
		case 'prep' {
			goal_prep ($goal_config);
		}
		case 'rpm' {
			goal_rpm ($goal_config);
		}
		case 'version' {
			goal_version ($goal_config);
		}
		else {
			error ("Unknown goal: $goal");
		}
	} # /GOAL_SWITCH
	$last_goal = $goal;
}



small_title (" \nFINISHED!\n ");
exit 0;



##################################################



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



1;