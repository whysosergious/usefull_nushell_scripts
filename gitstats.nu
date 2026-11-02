# Git activity statistics from the commit log.
#
# Default: commits per author for the last 90 days (use --all for history).
# Use --emails to aggregate on e-mail instead of author name.
export def main [
    --since (-s): string = "90 days ago"  # Only commits newer than this (git since-format)
    --all (-a)                            # Ignore --since, use full history
    --emails (-e)                         # Group by e-mail instead of author name
    --repo (-r): path = "."               # Repository to inspect
] {
    if ($repo | path exists) == false {
        print -e $"Not a git repository: ($repo)"
        return
    }
    let key = (if $emails { "%ae" } else { "%an" })
    let args = (if $all { [] } else { [--since $since] })
    let arg = $"--pretty=format:($key)"
    let log = (do { git -C ($repo | into string) log $arg ...$args --no-merges } | complete)
    if ($log.exit_code != 0) {
        print -e ($log.stderr | str trim)
        return
    }
    let commits = ($log.stdout | lines | where {|l| $l != "" })
    if ($commits | is-empty) { print "No commits found."; return }

    let total = ($commits | length)
    let per = ($commits | group-by {|l| $l }
        | items {|who, x| {who: $who, commits: ($x | length)} }
        | each {|r|
            let pct = ($r.commits / $total * 100 | math round --precision 1)
            {who: $r.who, commits: $r.commits, pct: $"($pct)%"}
        }
        | sort-by -r commits)
    print $"Total commits: ($total)"
    print ($per | table --index false)
}
