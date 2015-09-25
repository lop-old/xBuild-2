use strict;
use warnings;



sub goal_deploy {
	print "Deploying packages..\n";
	my $goal_config = shift;
	my $optional    = shift;
error ("Sorry, this goal is unfinished!");
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