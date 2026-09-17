##
## Shared helpers for the WebAssembly TBB stub patch.
##
## The wasm build has to make `rstan`'s wasm binary define the two Intel TBB
## runtime entry points that Stan math imports through headers (see
## tools/webr/tbb-stubs.cpp and design/howto-build-rbest-webr.md section 9):
## tools/webr/patch-rstan-tarball.R adds the stub to rstan's `src/` and rstan is
## cross-compiled from there.
##
## These helpers are the bookkeeping around it: the patch must be explicit,
## logged, and recorded in the shipped artefact, so that the wasm rstan is never
## mistaken for a stock build of the same version. They live here, one directory
## above tools/webr/docker, because the docker build context cannot reach out of
## itself -- compose.yaml passes them in through the `webrtools` build context.
##

## sha256 of a file. `tools::sha256sum()` is recent, so fall back to the system
## utility, and finally to md5 -- labelled as such, since an unlabelled digest
## of unknown algorithm is worse than no digest.
webr_checksum <- function(path) {
  if (exists("sha256sum", envir = asNamespace("tools"))) {
    return(paste0("sha256:", unname(getExportedValue("tools", "sha256sum")(path))))
  }
  for (prog in c("sha256sum", "shasum")) {
    exe <- Sys.which(prog)
    if (nzchar(exe)) {
      out <- tryCatch(
        system2(exe, c(if (prog == "shasum") "-a256", shQuote(path)), stdout = TRUE),
        error = function(e) character()
      )
      if (length(out)) {
        return(paste0("sha256:", sub("[[:space:]].*$", "", out[1])))
      }
    }
  }
  paste0("md5:", unname(tools::md5sum(path)))
}

## The single copy of the stub source. It lives in `tools/webr/`, which is
## `.Rbuildignore`'d, because it is a build-time input of the WebAssembly route
## only and must not reach the released package: both consumers inject it into
## a package's `src/` before the cross-compile, and a no-op redefinition of two
## Intel TBB runtime entry points has no business being shipped to CRAN.
##
## That is also why it cannot simply be read from the `/src` mount. `/src` is a
## full checkout in CI, but `make r-binary-webr` mounts an extracted *release
## tarball*, which carries no `tools/` at all. So the file is baked into the
## image from the `webrtools` build context alongside the helpers that use it,
## and the mount is only preferred when it does carry the file -- which is what
## makes an edit in a working tree take effect without an image rebuild.
webr_stub_image_copy <- "/usr/local/share/rbest/tbb-stubs.cpp"

webr_stub_source <- function(root = ".") {
  candidates <- c(file.path(root, "tools", "webr", "tbb-stubs.cpp"), webr_stub_image_copy)
  found <- candidates[file.exists(candidates)]
  if (!length(found)) {
    stop(
      "the TBB stub source is missing; looked for:\n  ",
      paste(candidates, collapse = "\n  ")
    )
  }
  message("TBB stub source: ", found[1])
  found[1]
}

## A human-readable record of what was patched, written next to the image and
## shipped with it. Deliberately plain text: it is meant to be read by whoever
## finds the artefact, not parsed.
##
## `entries` is a list of named character vectors, one per patched package.
webr_write_patch_manifest <- function(dir, entries, stub_file) {
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  path <- file.path(dir, "PATCHES.txt")
  lines <- c(
    "RBesT webR library image -- applied patches",
    "",
    "The packages listed below are NOT stock builds of the versions they",
    "report. They were modified during the wasm build. See",
    "design/howto-build-rbest-webr.md section 9 for the rationale.",
    "",
    "RBesT's own wasm binary carries the same two no-ops: they are injected",
    "into its src/ at build time from tools/webr/tbb-stubs.cpp, guarded by",
    "`#ifdef __EMSCRIPTEN__`. That file is a build-time input of this route",
    "and is deliberately not part of the released RBesT sources, so a native",
    "RBesT build of the same version contains no such code at all.",
    "",
    paste("generated:", format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")),
    ""
  )
  for (entry in entries) {
    lines <- c(lines, paste0(names(entry), ": ", unname(entry)), "")
  }
  lines <- c(
    lines,
    "--- tools/webr/tbb-stubs.cpp ---------------------------------------",
    readLines(stub_file, warn = FALSE)
  )
  writeLines(lines, path)
  message("== wrote ", path, " ==")
  path
}
