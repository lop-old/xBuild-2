use strict;
use warnings;



sub goal_prep {
	print "Prep workspace..\n";
	my $goal_config = shift;
	goal_prep_gen_gitignore ($goal_config);
#	goal_prep_composer      ($goal_config);
}



# generate .gitignore file
sub goal_prep_gen_gitignore {
	my $goal_config = shift;
	my $filename = '.gitignore';
	my $PWD = getcwd;
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
	if (exists $goal_config->{'GitIgnore Append'}) {
		my @project_gitignore_append = @{$goal_config->{'GitIgnore Append'}};
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
	}
	if ($main::testing == 0) {
		print "Creating file: .gitignore\n";
		open (my $FILE, '>', "$PWD/$filename") or error ("Failed to write to file: $filename");
		print $FILE "#  Auto Generated File\n";
		print $FILE "# =====================\n\n";
		print $FILE $data;
		close $FILE;
	} else {
		print "Skipping creating file: .gitignore\n";
	}
}



#sub goal_prep_composer {
#	# update composer
#	if ( -f "$PWD/composer.json" ) {
#		my $cmd = "composer self-update || { echo \"Failed to update composer!\"; exit 1; }";
#		system ($cmd) and error ("Command failed! $cmd");
#	}

#	# composer install
#	{
#		my $path = "$PWD";
#		print "Composer update: $path\n";
#		my $cmd = <<EOF;
#pushd "$path" && \\
#php `which composer` update -v --working-dir "$path/" || \\
#{ echo "Failed to run composer install command: $path/"; exit 1; }
#popd
#EOF
#		debug ("COMMAND:\n$cmd");
#		system ($cmd) and error ("Command failed! $cmd");
#	}
#}



1;