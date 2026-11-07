# Licensing

## The kit

Everything in this repository is MIT licensed unless a file says
otherwise. The kit contains build recipes and scripts, not the source code
of the software it builds. Buildroot downloads that source at build time
from upstream projects and from
[inMusic's open source release](https://github.com/inmusic-software/az0x-open-source).

## Images you build

A firmware image contains GPL and LGPL software: the Linux kernel, BusyBox,
glibc and others. **If you distribute an image**, you must also make the
corresponding source available. Buildroot helps:

```sh
make force-legal-info
```

This writes `output/force/legal-info/`, with every package's license, its
source tarball and any patches. Publish that next to your image (or a
written offer for it).

## Your application

Your app is a separate program on top of Linux. Running on a GPL kernel,
or next to GPL programs, does not put your app under the GPL. Linking
against LGPL libraries (glibc, alsa-lib) dynamically is fine for closed
source apps. If your app links GPL libraries, the GPL applies to it.

## Trademarks

"Akai Professional", "MPC", "Force" and "inMusic" are trademarks of their
owners. The kit uses those names only to say which hardware it targets.
Don't use their logos or present your firmware as official.
