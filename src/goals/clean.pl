use strict;
use warnings;



sub goal_clean {
	print "Cleaning..\n";
	my $pwd = getcwd;
	foreach my $dir ( 'target', 'rpmbuild-root', 'build', 'bin', 'out' ) {
		my $path = "$pwd/$dir/";
		if ( length($path) > 0 && -d "$path" ) {
			debug ("Deleting path: $path");
			my $cmd = "[ -z \"$path\" ] ".
				"|| rm -Rf --preserve-root \"$path\" ".
				"|| exit 1";
			debug ("COMMAND:\n$cmd");
			system ($cmd) and error ("Failed to delete path: $path");
		}
	}
}



1;