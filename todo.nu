# A tiny, file-backed todo manager (todo.txt style).
#
# Examples:
#   todo add "write the readme"
#   todo              # show open items
#   todo done 2       # mark item #2 done
#   todo undo 2       # mark item #2 not-done again
#   todo rm 2         # delete item #2
#   todo list -a      # include done items
#   todo clear        # wipe completed items
# Use -f/--file (on every subcommand) to point at another todo file.
export def main [
    --file (-f): path  # Storage file (default ~/.todo.txt)
    --all (-a)      # Also show completed items
] {
    let f = (pick-file $file)
    let items = (load $f)
    if ($items | is-empty) { print "Nothing to do - add one with: todo add \"...\""; return }
    let rows = ($items | enumerate | each {|e|
        {id: ($e.index + 1), done: $e.item.done, text: $e.item.text}
    })
    let shown = (if $all { $rows } else { $rows | where done == false })
    if ($shown | is-empty) { print "All done!"; return }
    print ($shown | table --index false)
}

export def add [
    ...words: string                # The todo text
    --file (-f): path               # Storage file (default ~/.todo.txt)
] {
    if ($words | is-empty) { print -e "Give a todo: todo add \"my task\""; return }
    let f = (pick-file $file)
    let text = ($words | str join " ")
    let lines = (raw-lines $f | append $text)
    store $f $lines
    print $"added: ($text)"
}

export def done [
    id: int                         # Item number as shown by `todo`
    --file (-f): path               # Storage file (default ~/.todo.txt)
] {
    change (pick-file $file) $id {|l| $"x ($l)" }
}

export def undo [
    id: int                         # Item number as shown by `todo`
    --file (-f): path               # Storage file (default ~/.todo.txt)
] {
    change (pick-file $file) $id {|l| $l | str replace -r '^x ' '' }
}

export def rm [
    id: int                         # Item number as shown by `todo`
    --file (-f): path               # Storage file (default ~/.todo.txt)
] {
    let f = (pick-file $file)
    if (bad-id $f $id) { return }
    let remove = ($id - 1)
    let ls = (raw-lines $f)
    store $f ($ls | enumerate | where index != $remove | get item)
    print $"removed item #($id)"
}

export def clear [
    --file (-f): path               # Storage file (default ~/.todo.txt)
] {
    let f = (pick-file $file)
    let keep = (load $f | where done == false | get text)
    store $f $keep
    print $"kept ($keep | length) open item\(s\)"
}

## Print usage if called with no args; `use todo.nu; todo` lists items.
#
# ---- helpers ------------------------------------------------------------

def pick-file [given] {
    (if ($given | is-empty) { $nu.home-path | path join ".todo.txt" } else { $given })
}

def load [file: path] {
    if ($file | path exists) == false { return [] }
    raw-lines $file | each {|l|
        if ($l | str starts-with "x ") {
            {done: true, text: ($l | str replace -r '^x ' '')}
        } else {
            {done: false, text: $l}
        }
    }
}

def raw-lines [file: path] {
    if ($file | path exists) { open --raw $file | lines | where {|l| $l != "" } } else { [] }
}

def store [file: path, ls: list<string>] {
    ($ls | append "" | str join "\n") | save $file --raw --force
}

def bad-id [file: path, id: int] {
    let n = (raw-lines $file | length)
    if $id < 1 or $id > $n {
        print -e $"No item #($id) (there are ($n))."
        true
    } else { false }
}

def change [file: path, id: int, f: closure] {
    if (bad-id $file $id) { return }
    let idx = ($id - 1)
    let ls = (raw-lines $file)
    let new = ($ls | enumerate | each {|e| if $e.index == $idx { do $f $e.item } else { $e.item } })
    store $file $new
    let hit = ($new | get $idx)
    if ($hit | str starts-with "x ") { print $"completed: ($hit | str replace -r '^x ' '')" } else { print $"reopened: ($hit)" }
}
