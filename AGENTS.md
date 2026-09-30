# Repository guidelines

## Vendored Discount sources

Directories matching `discount-*` are pristine vendored copies of upstream
Discount releases. Do not modify files in these directories directly.

When a bundled Discount release needs a local fix:

1. Add the complete patched file under a version-specific directory in
   `patches/`, mirroring its path in the corresponding `discount-*` directory.
2. Keep the corresponding `discount-*` directory identical to upstream.
3. Overlay patched files only on the build copy under `_build/`, following
   the mechanism in `builder/MyBuilder.pm`; do not introduce an external
   `patch` command dependency.
4. Document why the patch is required and when it can be removed in
   `patches/README.md`.
5. Re-evaluate all local patches whenever the bundled Discount version is
   updated.
