# r-mcp-server

An MCP (Model Context Protocol) server that gives AI coding agents like
[Claude Code](https://claude.com/claude-code) a **persistent R session** via a
`run_r_code` tool.

Built on [mcptools](https://posit-dev.github.io/mcptools/) and
[ellmer](https://ellmer.tidyverse.org/): the server is itself a long-running R
process, and `run_r_code` evaluates code in that process's global environment.
Variables, loaded packages, and options persist between tool calls — so an
agent can load data once and iterate on it, the way you would in RStudio.

## Tools

- **`run_r_code`** — execute R code, get printed output back as text.
  Captures values, `cat()` output, messages, and warnings; errors are returned
  as readable text without killing the server. Output is truncated at 8,000
  characters. Plots should be saved to a file (`ggsave()`, `png()`...) and the
  path reported.
- **`list_r_sessions`** / **`select_r_session`** — mcptools' built-in tools for
  attaching to a live interactive R session that has run
  `mcptools::mcp_session()`.

## Requirements

- R (tested on 4.5.1)
- R packages: `mcptools` (>= 0.2.1), `ellmer` (>= 0.4.1)

```r
install.packages(c("mcptools", "ellmer"))
```

## Setup with Claude Code

```sh
claude mcp add --scope user r-mcptools -- Rscript /path/to/r-mcp-server.R
```

Or add to an `mcp.json`:

```json
{
  "mcpServers": {
    "r-mcptools": {
      "command": "Rscript",
      "args": ["/path/to/r-mcp-server.R"]
    }
  }
}
```

## Notes

- State lasts for the lifetime of the server process (typically one agent
  session); restarting the agent restarts the R session.
- The server inherits your `.Rprofile` / site library, so project packages
  are available.
