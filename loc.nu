# Lines-of-code report grouped by file extension.
#
# Only counts "text-ish" source files; pass --ext to override the list.
export def main [
    root: path = "."              # Directory to scan
    --ext (-e): list<string> = [] # Override extension list, e.g. [-e rs -e toml]
    --sort-lines (-s)             # Sort by total lines instead of file count
] {
    let default_exts = [
        .rs .py .js .ts .tsx .jsx .go .c .h .cpp .hpp .cs .java .kt .rb
        .php .sh .bash .nu .ps1 .sql .toml .yaml .yml .json .xml .html
        .css .scss .vim .md
    ]
    let exts = (if ($ext | is-empty) {
        $default_exts
    } else {
        $ext | each {|e| if ($e | str starts-with ".") { $e } else { $".($e)" } }
    })

    let files = (glob -D $"($root | into string)/**/*"
        | where {|p|
            let e = ($p | path parse | get -o extension? | default "")
            if $e == "" { false } else { $exts | any {|x| $".($e)" == $x } }
        })

    if ($files | is-empty) {
        print "No matching source files found."
        return
    }

    print $"Counting ($files | length) files ..."
    let rows = ($files
        | each {|p|
            {ext: ($p | path parse | get -o extension?), lines: ((open --raw $p | lines | length))}
        }
        | group-by ext
        | items {|e, v| {ext: $".($e)", files: ($v | length), lines: ($v | get lines | math sum)} })

    let sorted = (if $sort_lines { $rows | sort-by -r lines } else { $rows | sort-by -r files })
    print ($sorted | table --index false)
    let t_f = ($rows | get files | math sum)
    let t_l = ($rows | get lines | math sum)
    print $"TOTAL: ($t_f) files, ($t_l) lines"
}
