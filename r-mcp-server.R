# MCP server exposing a persistent R session via a run_r_code tool.
# Register with: claude mcp add --scope user r-mcptools -- Rscript /path/to/r-mcp-server.R
# State persists for the lifetime of the server process (one agent session).

library(mcptools)
library(ellmer)

run_r_code <- function(code) {
  MAX_OUTPUT_CHARS <- 8000
  warnings <- character()
  messages <- character()

  out <- tryCatch(
    withCallingHandlers(
      capture.output({
        res <- withVisible(eval(parse(text = code), envir = globalenv()))
        if (res$visible) print(res$value)
      }),
      warning = function(w) {
        warnings <<- c(warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      },
      message = function(m) {
        messages <<- c(messages, trimws(conditionMessage(m)))
        invokeRestart("muffleMessage")
      }
    ),
    error = function(e) paste0("Error: ", conditionMessage(e))
  )

  parts <- c(
    paste(out, collapse = "\n"),
    if (length(messages) > 0) paste0("Messages:\n", paste(messages, collapse = "\n")),
    if (length(warnings) > 0) paste0("Warnings:\n", paste(warnings, collapse = "\n"))
  )
  result <- paste(parts[nzchar(parts)], collapse = "\n\n")

  if (!nzchar(result)) {
    result <- "(ran successfully, no visible output)"
  }
  if (nchar(result) > MAX_OUTPUT_CHARS) {
    result <- paste0(
      substr(result, 1, MAX_OUTPUT_CHARS),
      "\n... [output truncated at ", MAX_OUTPUT_CHARS, " chars]"
    )
  }
  result
}

run_r_code_tool <- tool(
  run_r_code,
  paste(
    "Execute R code in a persistent R session and return the printed output.",
    "Variables, loaded packages, and options persist between calls.",
    "Output is captured as text (print/cat/messages/warnings/errors);",
    "for plots, save to a file (e.g. ggsave or png()) and report the path."
  ),
  arguments = list(
    code = type_string("R code to execute. Can be multiple lines.")
  ),
  name = "run_r_code"
)

mcp_server(tools = list(run_r_code_tool))
