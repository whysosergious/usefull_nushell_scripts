# Re-run a command whenever watched files change (simple polling watcher).
#
# Examples:
#   watch "cargo build" src/main.rs Cargo.toml
#   watch "npm test" -i 2sec src/           # poll every 2 seconds
#   watch "make" --no-start Makefile        # don't run immediately at launch
# NOTE: interruption is Ctrl-C; directory watches are recursive (all files).
export def main [
    cmd: string                       # Shell command to run (passed to `nu -c`)
    ...paths: path                    # Files or directories to watch
    --interval (-i): duration = 1sec  # Poll interval
    --no-start (-n)                   # Skip the first immediate run
] {
    let missing = ($paths | where {|p| not ($p | path exists)})
    if ($missing | is-empty) == false {
        print -e $"Not found: ($missing | str join ', ')"
        return
    }
    if not $no_start {
        print "----- start -----"
        nu -c $cmd
    }
    mut prev = (latest-mtime $paths)
    loop {
        sleep $interval
        let now = (latest-mtime $paths)
        if $prev != $now {
            print $"----- changed at (date now | format date "%H:%M:%S") -----"
            nu -c $cmd
        }
        $prev = $now
    }
}

def latest-mtime [paths: list<path>] {
    let ts = ($paths | each {|p|
        if ($p | path type) == "dir" {
            glob $"($p | into string)/**/*"
                | where {|q| ($q | path type) == "file" }
                | each {|q| (((ls $q) | get 0.modified)) }
                | default []
        } else {
            [((ls $p) | get 0.modified)]
        }
    } | flatten)
    if ($ts | is-empty) { null } else { $ts | math max }
}
