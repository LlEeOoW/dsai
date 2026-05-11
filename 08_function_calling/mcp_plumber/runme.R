# From repo root (Plumber 2.x: use pr_run if $run fails):
plumber::pr_run(plumber::plumb("08_function_calling/mcp_plumber/plumber.R"), port = 8000, host = "127.0.0.1")
