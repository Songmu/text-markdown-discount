# Discount patches

The `discount-*` directories are pristine copies of upstream releases and
must not be modified locally.

`builder/MyBuilder.pm` copies the bundled Discount source into `_build/`,
overlays the version-specific patched files from this directory, and builds
the static library from that working copy. Copying and patch application use
only Perl core modules, so they do not add external `cp` or `patch` command
requirements.

Each versioned directory mirrors the path of the corresponding bundled
Discount release and contains complete replacement files.

## discount-3.0.2.0/generate.c

Discount 3.0.2.0 includes `MKD_ALT_AS_TITLE` in the image tag's blocking flag
set. Enabling the flag consequently prevents images from rendering before it
can add the fallback title.

The patched file removes the flag from the blocking set and checks the image
type directly when adding the title. Re-evaluate or remove this file when
updating the bundled Discount release.
