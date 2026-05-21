## 2024-05-21 - Bash Fork Optimization
**Learning:** Shell scripts frequently called (like deploy.sh inside loops) suffer massive performance degradation when executing subcommands like `basename` or `tr` due to process forking (fork() / exec() syscalls).
**Action:** Always prefer native bash parameter expansions (e.g., `${dir##*/}` instead of `basename "$dir"`, and `${name//[^...]/_}` instead of `tr`) when string manipulation is needed in loops.
