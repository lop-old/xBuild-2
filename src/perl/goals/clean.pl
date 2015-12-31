use strict;
use warnings;



sub goal_clean {
	print "Cleaning..\n";
	my $PWD = $main::PWD;
	foreach my $dir ( 'target', 'rpmbuild-root', 'build', 'bin', 'out' ) {
		my $path = "$PWD/$dir/";
		if ( length($path) > 0 && -d "$path" ) {
			debug ("Deleting path: $path");
			run_command (
				"[ -z \"$path\" ] ".
				"|| rm -Rf --preserve-root \"$path\" ".
				"|| exit 1"
			);
		}
	}
}



1;