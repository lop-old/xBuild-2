use strict;
use warnings;



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



1;