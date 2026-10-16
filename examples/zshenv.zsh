# ~/.zshenv (macOS). Read by every zsh, scripts included, so it stays at one line.
# Skip the system-wide /etc/zprofile and /etc/zshrc: each forks a process
# (path_helper, `locale`) for about 3 ms per shell. Put what they set up in
# your own files: PATH (the dirs from /etc/paths and /etc/paths.d),
# `setopt COMBINING_CHARS` and `bindkey -e`.
setopt no_global_rcs
