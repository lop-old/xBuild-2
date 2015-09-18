Name            : xBuild
Summary         : Build and deploy script for PoiXson projects
Version         : 1.5.0
Release         : 1
BuildArch       : noarch
Provides        : xBuild
Requires        : shellscripts >= 1.5.0
Requires        : perl
Requires        : perl-JSON
Requires        : perl-Switch
Requires        : gradle
Requires        : maven2
Prefix          : %{_bindir}/%{name}
%define _rpmfilename  %%{NAME}-%%{VERSION}-%%{RELEASE}.%%{ARCH}.rpm

Group           : Development Tools
License         : GPL-3
Packager        : PoiXson <support@poixson.com>
URL             : http://poixson.com/

%description
Build and deploy script for PoiXson projects.



# avoid centos 5/6 extras processes on contents (especially brp-java-repack-jars)
%define __os_install_post %{nil}



### Prep ###
%prep



### Build ###
%build



### Install ###
%install
echo
echo "Install.."
# delete existing rpm's
%{__rm} -fv "%{_rpmdir}/%{name}-"*.noarch.rpm
# create directories
%{__install} -d -m 0755 \
	"${RPM_BUILD_ROOT}%{prefix}/" \
	"${RPM_BUILD_ROOT}%{_sysconfdir}/profile.d/" \
		|| exit 1
# copy script files
for file in \
	xbuild.pl \
; do
	%{__install} -m 0555 \
		"%{SOURCE_ROOT}/src/${file}" \
		"${RPM_BUILD_ROOT}%{prefix}/${file}" \
			|| exit 1
done
# alias symlinks
ln -sf  "%{prefix}/xbuild.pl"  "${RPM_BUILD_ROOT}%{_bindir}/xbuild"



%check



%clean
if [ ! -z "%{_topdir}" ]; then
	%{__rm} -rf --preserve-root "%{_topdir}" \
		|| echo "Failed to delete build root!"
fi



### Files ###
%files
%defattr(-,root,root,-)
%{prefix}/xbuild.pl
%{_bindir}/xbuild
