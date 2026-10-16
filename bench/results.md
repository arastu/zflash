| setup | mean | min |
|---|---:|---:|
| zsh -f (no rc files at all) | 2.8 ms ± 0.1 | 2.7 ms |
| zflash, widgets deferred | 15.9 ms ± 0.4 | 15.3 ms |
| zflash | 24.5 ms ± 0.6 | 23.6 ms |
| zgenom | 28.5 ms ± 0.6 | 27.5 ms |
| znap | 33.1 ms ± 0.5 | 32.2 ms |
| no manager (hand-written) | 39.2 ms ± 0.5 | 38.2 ms |
| antidote | 40.7 ms ± 0.7 | 39.5 ms |
| zinit, turbo mode for widgets | 45.1 ms ± 0.5 | 44.3 ms |
| sheldon | 49.1 ms ± 0.7 | 47.9 ms |
| zinit | 62.0 ms ± 0.6 | 60.6 ms |

Apple M4, macOS 27.0.1, zsh 5.9 (arm64-apple-darwin26.0), 2026-10-16. hyperfine, 10 setups, `zsh -i -c exit`.
