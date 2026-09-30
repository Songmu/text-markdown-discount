# Discount patches

The `discount-*` directories are pristine copies of upstream releases and
must not be modified locally.

`builder/MyBuilder.pm` copies the bundled Discount source into `_build/`,
applies the patches in this directory, and builds the static library from that
working copy. Building therefore requires the standard `cp` and `patch`
utilities in addition to the existing `sh` and `make` requirements.

## discount-3.0.2.0-alt-as-title.patch

Discount 3.0.2.0 includes `MKD_ALT_AS_TITLE` in the image tag's blocking flag
set. Enabling the flag consequently prevents images from rendering before it
can add the fallback title.

The patch removes the flag from the blocking set and checks the image type
directly when adding the title. Re-evaluate or remove this patch when updating
the bundled Discount release.
