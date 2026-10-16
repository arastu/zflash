| setup | mean | min |
|---|---:|---:|
| zsh -f (no rc files at all) | 7.2 ms ± 0.8 | 5.7 ms |
| zflash, widgets deferred | 25.1 ms ± 0.8 | 23.6 ms |
| zflash | 32.3 ms ± 0.6 | 31.3 ms |
| zgenom | 33.3 ms ± 0.8 | 31.2 ms |
| znap | 39.3 ms ± 0.9 | 37.9 ms |
| no manager (hand-written) | 44.3 ms ± 1.4 | 42.5 ms |
| antidote | 45.9 ms ± 0.6 | 45.1 ms |
| zinit, turbo mode for widgets | 50.5 ms ± 0.7 | 49.3 ms |
| sheldon | 54.3 ms ± 1.0 | 52.8 ms |
| zinit | 67.6 ms ± 0.6 | 66.4 ms |

Apple M4, macOS 27.0.1, zsh 5.9 (arm64-apple-darwin26.0), 2026-10-16. hyperfine, 10 setups, `zsh -i -c exit`.
