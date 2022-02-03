# SUITE := bullseye
# ARCH := amd64
# MIRROR := http://ftp.uk.debian.org/

PACKAGE_NAME := sbuild-chroot-$(SUITE)-$(ARCH)
PACKAGE_VERSION := $(shell date -u '+%Y.%m.%d.%H.%M.%S')
BUILD_DATE=$(shell date '+%a, %d %b %Y %H:%M:%S %z')

.PHONY: all
all:

.PHONY: debian
debian: \
	debian/changelog \
	debian/control \
	debian/rules

debian/%: debian/%.in FORCE
	sed \
		-e 's?%SUITE%?$(SUITE)?g' \
		-e 's?%ARCH%?$(ARCH)?g' \
		-e 's?%MIRROR%?$(MIRROR)?g' \
		-e 's?%PACKAGE_NAME%?$(PACKAGE_NAME)?g' \
		-e 's?%PACKAGE_VERSION%?$(PACKAGE_VERSION)?g' \
		-e 's?%BUILD_DATE%?$(BUILD_DATE)?g' \
		$< > $@

.PHONY: FORCE
FORCE:

.PHONY: install
install:
	# Check we are running in a clean environment and not about to stomp
	# over existing files on the system
	
	! test -e /srv/chroot/$(SUITE)-$(ARCH)-sbuild/
	! test -e /etc/schroot/chroot.d/$(SUITE)-$(ARCH)-*
	
	# Build the chroot
	sbuild-createchroot --arch=$(ARCH) $(SUITE) /srv/chroot/$(SUITE)-$(ARCH)-sbuild/ $(MIRROR)
	
	# Add the "universe" component to any sources that look like Ubuntu.
	sed -Ei -e 's/^(.*ubuntu.*\smain)$$/\1 universe/g' /srv/chroot/$(SUITE)-$(ARCH)-sbuild/etc/apt/sources.list
	
	# Copy the chroot into DESTDIR
	
	mkdir -p $(DESTDIR)/srv/chroot/
	cp -a /srv/chroot/$(SUITE)-$(ARCH)-sbuild $(DESTDIR)/srv/chroot/
	
	mkdir -p $(DESTDIR)/etc/schroot/chroot.d/
	cp $$(echo /etc/schroot/chroot.d/$(SUITE)-$(ARCH)-sbuild-*) $(DESTDIR)/etc/schroot/chroot.d/
	
	# Make a -buildkite variant of the chroot, which is like the -sbuild
	# variant, except /var/lib/buildkite-agent/builds/ is also bind mounted
	# so that build jobs can use make use of chroots within their checkout.
	
	sed -E \
		-e 's/^\[(.*)-sbuild\]$$/[\1-buildkite]/' \
		-e 's/^profile=sbuild$$/profile=buildkite/' \
		< $$(echo /etc/schroot/chroot.d/$(SUITE)-$(ARCH)-sbuild-*) \
		> $(DESTDIR)/$$(echo /etc/schroot/chroot.d/$(SUITE)-$(ARCH)-sbuild-* | sed -e 's/sbuild-/buildkite-/')

.PHONY: buildpackage
buildpackage:
	apt-get -y update
	apt-get -y install debhelper debootstrap sbuild schroot dpkg-dev
	
	dpkg-buildpackage --no-sign
