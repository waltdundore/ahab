# Future Features

Backlog of ideas not yet specified. Each entry: what, where it came from, and the
integration path it should follow. Nothing here is scheduled.

## Speedtest: build `fast` into ahab

- **What**: A quick internet speedtest for the lab/workstation, exposed as a
  Makefile target (e.g. `make speedtest`) or a docker module.
- **Source**: standalone Dockerfile at `~/git/fast/` — alpine base,
  `ca-certificates`, copies the `fast` speedtest binary, runs it as `CMD`.
- **Integration path**: ahab already deploys modules via
  `make install [modules...]` → `scripts/generate-docker-compose.py`; a
  speedtest module or a thin `make speedtest` wrapper around the `fast` image
  fits that existing mechanism.
- **Status**: not started — note only (operator request, 2026-09-17).
