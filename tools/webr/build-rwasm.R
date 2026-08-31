#!/usr/bin/env Rscript
##
## Cross-compile RBesT and its dependency closure to WebAssembly and pack the
## result into a mountable webR library image.
##
## Runs *inside* the webR development container, which provides the emscripten
## toolchain, a wasm R build and the `rwasm` package:
##
##   docker run --rm -v "$PWD":/github/workspace -w /github/workspace \
##     --entrypoint Rscript ghcr.io/r-wasm/webr:v0.6.0 tools/webr/build-rwasm.R
##
## Environment variables (all optional):
##   RBEST_REPO_DIR   CRAN-like wasm repository output   (default _rwasm/repo)
##   RBEST_IMAGE_DIR  VFS library image output           (default _rwasm/image)
##   RBEST_IMAGE_NAME VFS image base name                (default rbest-library.data)
##   RBEST_STRIP      comma separated dirs to strip from the library
##   RBEST_REMOTES    comma separated webR-patched package refs
##   CRAN_MIRROR      CRAN mirror                        (default cloud.r-project.org)
##
## This deliberately does *not* use `r-wasm/actions/build-rwasm`. That action
## calls `rwasm::add_pkg()` with the package defaults, and two of them are
## wrong for us -- see the comments on `dependencies` and `remotes` below.

repo_dir <- Sys.getenv("RBEST_REPO_DIR", "_rwasm/repo")
image_dir <- Sys.getenv("RBEST_IMAGE_DIR", "_rwasm/image")
image_name <- Sys.getenv("RBEST_IMAGE_NAME", "rbest-library.data")

split_env <- function(name, default) {
  value <- Sys.getenv(name, default)
  value <- strsplit(value, "[[:space:],]+")[[1]]
  value[nzchar(value)]
}

strip_dirs <- split_env(
  "RBEST_STRIP",
  ## `include` is deliberately absent: it saves ~3% of the download and
  ## rstan reads StanHeaders' installed headers on some code paths.
  "demo, doc, examples, help, html, tests, vignette"
)

## `rwasm`'s default `remotes = NA` resolves the whole `inst/webr-remotes` list
## shipped with the package -- 17 refs covering everything webR patches.
## Several of those cannot be resolved against Posit Package Manager at all
## (`Matrix`, and through it `TMB`, `rigraph` and `mmrm`) and abort pkgdepends
## with the opaque "`nrow(out)` must equal `1`", killing the resolution before
## it looks at the packages we asked for. None of them are in RBesT's closure.
## The only webR-patched package that is, is mvtnorm, so name it explicitly.
remotes <- split_env("RBEST_REMOTES", "r-wasm/mvtnorm@webr")

options(
  repos = c(CRAN = Sys.getenv("CRAN_MIRROR", "https://cloud.r-project.org")),
  timeout = 1800
)
Sys.setenv(PKG_USE_BIOCONDUCTOR = "false")
options(pkg.use_bioconductor = FALSE)

stopifnot(file.exists("DESCRIPTION"))
desc <- as.list(read.dcf("DESCRIPTION")[1, ])

## `Config/Needs/wasm` carries the refs that must override normal resolution --
## for RBesT, the rstan 2.39 source tarballs from r-universe. `rwasm` does not
## read this field itself; it has to be spliced into the package list here.
extra <- if (!is.null(desc$`Config/Needs/wasm`)) {
  refs <- strsplit(desc$`Config/Needs/wasm`, "[[:space:],]+")[[1]]
  refs[nzchar(refs)]
} else {
  character(0)
}

## All refs go into a *single* `add_pkg()` call so that pkgdepends resolves one
## graph: the explicit `url::` refs then take precedence over the CRAN `rstan`
## that RBesT's `Imports` would otherwise pull in. Resolving them separately
## would give two different rstan versions in the same repository.
##
## `dependencies = "hard"` rather than the `rwasm` default of `FALSE`, which
## would build RBesT alone and produce a library image with none of ggplot2,
## dplyr, posterior or bayesplot in it. Not `TRUE`, which additionally pulls
## the *Suggests* of every direct ref; somewhere in that much larger graph
## pkgdepends hits a malformed ref and aborts. Suggests are not wanted in a
## wasm library anyway.
packages <- c(extra, "local::.")

message("== rwasm ", as.character(packageVersion("rwasm")), " ==")
message("== ", R.version.string, " (host) ==")
message("== packages ==")
for (p in packages) message("  ", p)
message("== remotes ==")
for (r in remotes) message("  ", r)
message("== strip: ", paste(strip_dirs, collapse = ", "), " ==")

dir.create(repo_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(image_dir, recursive = TRUE, showWarnings = FALSE)

rwasm::add_pkg(
  packages,
  repo_dir = repo_dir,
  remotes = remotes,
  dependencies = "hard",
  compress = TRUE
)

message("\n== packing VFS library image ==")
rwasm::make_vfs_library(
  out_dir = image_dir,
  out_name = image_name,
  repo_dir = repo_dir,
  strip = strip_dirs,
  compress = TRUE
)

## `compress = TRUE` makes `rwasm` write `<name>.data.gz` and drop the
## uncompressed `.data` itself, so there is nothing further to clean up here.

built <- list.files(repo_dir, pattern = "\\.tgz$", recursive = TRUE)
message("\n== built ", length(built), " wasm binaries ==")
if (!any(grepl("^RBesT_", basename(built)))) {
  stop("no RBesT wasm binary was produced")
}
message("== image ==")
for (f in list.files(image_dir, full.names = TRUE)) {
  message("  ", basename(f), " (", round(file.size(f) / 1e6, 2), " MB)")
}
