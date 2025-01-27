#' Write panels
#' @param trdf A trelliscope data frame created with [`as_trelliscope_df()`]
#' or a data frame which will be cast as such.
#' @param width Width in pixels of each panel.
#' @param height Height in pixels of each panel.
#' @param format The format of the image if it is not an htmlwidget. Can be
#'   either "png" or "svg".
#' @param force Should the panels be forced to be written? If `FALSE`, the
#'   content of the panel column along with the `width`, `height`, and
#'   `format` parameters will be used to determine if the panel content matches
#'   panels that have already been written, in which case writing the panels
#'    will be skipped.
#' @note The size of panels will vary when shown in the viewer, but here the
#'   specification of height and width help determine the plot aspect ratio
#'   as well as the initial resolution to render plot text, etc. with.
#' @importFrom cli cli_progress_bar cli_progress_update cli_progress_done
#' @importFrom rlang hash
#' @export
write_panels <- function(
  trdf, width = 500, height = 500, format = "png", force = FALSE
) {
  trdf <- check_trelliscope_df(trdf)
  check_scalar(width, "width")
  check_pos_numeric(width, "width")
  check_scalar(height, "height")
  check_pos_numeric(height, "height")

  trobj <- attr(trdf, "trelliscope")$clone()
  app_path <- trobj$path
  # TODO: look at this
  # df <- trdf
  # if (inherits(df, "facet_panels"))
  #   df <- nest_panels(df)

  panel_col <- check_and_get_panel_col(trdf)

  panel_keys <- get_panel_paths_from_keys(trdf, format)

  panel_path <- file.path(trobj$get_display_path(), "panels")

  if (!dir.exists(panel_path)) {
    res <- dir.create(panel_path, recursive = TRUE)
    assert(res == TRUE,
      "Could not create directory for panels: {panel_path}")
  }

  html_head <- NULL
  if (inherits(trdf[[panel_col]][[1]], "htmlwidget")) {
    dir.create(file.path(app_path, "libs"), showWarnings = FALSE)
    html_head <- write_htmlwidget_deps(
      trdf[[panel_col]][[1]], app_path, panel_path)
    format <- "html"
  }

  cur_hash <- rlang::hash(c(height, width, format, trdf[[panel_col]]))

  trdf[["__PANEL_KEY__"]] <- panel_keys
  class(trdf) <- unique(c("trelliscope", class(trdf)))

  if (is.null(trobj$get("keysig")))
    trobj$set("keysig", rlang::hash(sort(panel_keys)))

  trobj$set("panelformat", format)

  if (!force && file.exists(file.path(panel_path, "hash"))) {
    prev_hash <- readLines(file.path(panel_path, "hash"), warn = FALSE)[1]
    # need to grab aspect ratio from previous
    ff <- list.files(trobj$get_display_path(),
      pattern = "displayInfo\\.json", full.names = TRUE)
    if (prev_hash == cur_hash && length(ff) > 0) {
      msg("Current panel content matches panels that have already been \\
        written. Skipping panel writing. To override this, use \\
        write_panels(..., force = TRUE).")
      trobj$panels_written <- TRUE
      trobj$set("panelaspect", read_json_p(ff)$panelaspect)
      attr(trdf, "trelliscope") <- trobj
      return(trdf)
    }
  }

  cli::cli_progress_bar("Writing panels", total = length(panel_keys))

  for (ii in seq_along(panel_keys)) {
    cli::cli_progress_update()
    write_panel(
      x = trdf[[panel_col]][[ii]],
      key = panel_keys[ii],
      base_path = app_path,
      panel_path = panel_path,
      width = width,
      height = height,
      format = format,
      html_head = html_head
    )
  }
  cli::cli_progress_done()

  cat(cur_hash, file = file.path(panel_path, "hash"))

  trobj$panels_written <- TRUE
  trobj$set("panelaspect", width / height)

  # attr(trdf, "trelliscope") <- trobj
  trdf
}

get_panel_paths_from_keys <- function(trdf, format) {
  trobj <- attr(trdf, "trelliscope")
  keycols <- trobj$get("keycols")
  apply(trdf[, keycols], 1,
    function(df) sanitize(paste(df, collapse = "_")))
  # TODO: make sure that when sanitized, keys are still unique
}
