# Repository guidelines

## Vendored Discount sources

Directories matching `discount-*` are pristine vendored copies of upstream
Discount releases. Do not modify files in these directories directly.

When a bundled Discount release needs a local fix:

1. Add a version-specific patch under `patches/`.
2. Keep the corresponding `discount-*` directory identical to upstream.
3. Apply the patch only to the build copy under `_build/`, following the
   strict substitution mechanism in `builder/MyBuilder.pm`; do not introduce
   an external `patch` command dependency.
4. Document why the patch is required and when it can be removed in
   `patches/README.md`.
5. Re-evaluate all local patches whenever the bundled Discount version is
   updated.
