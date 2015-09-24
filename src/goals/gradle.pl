use strict;
use warnings;



sub goal_gradle {
print "Building with gradle..\n";
error ("Sorry, this goal is unfinished!");
	# ensure tools are available
	system 'which gradle >/dev/null || { echo "Composer is not available - yum install gradle"; exit 1; }';
}



1;