compact_gmap_fixture_sample <- function(fixture_call, seed, envir = parent.frame()) {
  withr::with_seed(
    seed,
    withr::with_options(
      list(RBesT.MC.save_warmup = FALSE),
      suppressMessages(eval(fixture_call, envir = envir))
    )
  )
}
