# Pretty git branch listing + merged-branch cleanup.
#
# Lists all local branches sorted by last commit date, and can prune local
# branches that are already merged into the default branch.
export def main [
    --all (-a)          # Include remote-tracking branches too
    --prune (-p)        # Delete local branches already merged into main/master
    --force (-f)        # Use git branch -D when pruning
] {
    if $prune {
        let protected = [main master develop]
        let merged = (do { git branch --merged } | complete | get stdout | lines
            | each {|b| $b | str replace -a "* " "" | str trim }
            | where {|b| $b != "" and $b not-in $protected })
        if ($merged | is-empty) {
            print "Nothing to prune - no merged branches."
            return
        }
        print "Merged branches to delete:"
        print ($merged | each {|b| $"    ($b)" } | str join "\n")
        let answer = (input "Delete these branches? [y/N] ")
        if ($answer | str downcase) == "y" {
            let flag = (if $force { "-D" } else { "-d" })
            $merged | each {|b| do { git branch $flag $b } | complete | get stdout }
        }
        return
    }

    let refs = (if $all { "refs" } else { "refs/heads" })
    let log = (do { git for-each-ref --sort=-committerdate $refs --format='%(refname:short)|%(committerdate:relative)|%(authorname)|%(upstream:short)' } | complete)
    if ($log.exit_code != 0) { print -e ($log.stderr | str trim); return }
    let rows = ($log.stdout | lines | each {|line|
        let p = ($line | split column "|" name date author upstream)
        {branch: ($p | first | get name), last_commit: ($p | first | get date), author: ($p | first | get author), upstream: ($p | first | get upstream)}
    })
    if ($rows | is-empty) { print "No branches found."; return }
    let cur = (do { git branch --show-current } | complete | get stdout | str trim)
    print ($rows | each {|r|
        if $r.branch == $cur {
            {branch: $"* ($r.branch)", last_commit: $r.last_commit, author: $r.author, upstream: $r.upstream}
        } else { $r }
    } | table --index false)
}
