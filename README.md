# sbuild-chroot-packager

## "What is this?"

This repository contains scripts used to build Debian packages containing prebuilt build chroots.

**NOTE**: Running `sbuild-createchroot` as part of `dpkg-buildpackage` is about as weird as it gets, and I couldn't figure out a way to get it working using any of the *nice* tools like `sbuild`, so the commands to build it look something like this:

```
$ make debian SUITE=bullseye ARCH=amd64 MIRROR=http://deb.debian.org/debian/
$ schroot -c XXX -u root -- make buildpackage
```

The chroot used by `schroot` must be configured to mount your working directory within the chroot.

You could also just run `make buildpackage` (as root)... but that will debootstrap the chroot on your system and leave a few files scattered around under `/etc/`, so I'd stick to using schroot for it.

The output from the `make buildpackage` command will wind up in `..`, as is the style of `dpkg-buildpackage`... ugh.

## "Why the hell would you do that?!"

Build chroots should be inherently disposable and easy to bootstrap whenever and wherever necessary... so why package them up?

My CI environment has Debian build workers built using Packer that are preinstalled with chroots for all supported versions of Debian and Ubuntu, and bootstrapping all those chroots (10 at the time of writing) as part of the provisioning process takes a while (20-30 minutes), which is really annoying when doing development on them. Doing this means I can make changes to other parts of the worker images without having to rebuild the chroots, and changes to the chroots can be rebuilt in parallel.

This pattern would also make it easier to handle chroots which can't be built with Debian's tools (e.g. Fedora), which I used to use, but have not done since migrating to scripted workers on AWS...

Why make Debian packages, specifically? Well I've already got experience at Debian packaging and maintaining infrastructure for that, and I've been toying with the idea of using Debian packages as a mechanism for deploying roles/configurations to my servers, so I might look deeper into that in the future.
