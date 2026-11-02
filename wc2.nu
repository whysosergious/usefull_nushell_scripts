# Count words in text, files or stdin - like wc, but with nicer output.
#
# Examples:
#   wc2 README.md
#   wc2 a.txt b.txt c.txt      # also prints totals
#   cat file | wc2             # pipe from stdin
export def main [
    ...files: path          # Files to count; empty + piped stdin counts stdin
    --words (-w)            # Show word counts (chars are always shown)
] {
    if ($files | is-empty) {
        let text = ($in | default "" | into string)
        if $text == "" {
            print "Usage: wc2 <files...>  or  cat file | wc2"
            return
        }
        print (tally $text | table --index false)
        return
    }
    let missing = ($files | where {|f| not ($f | path exists)})
    if ($missing | is-empty) == false {
        print -e $"Not found: ($missing | str join ', ')"
        return
    }
    let rows = ($files | each {|f|
        let r = (tally (open --raw $f | into string))
        {file: $f, chars: $r.chars, words: $r.words, lines: $r.lines}
    })
    if ($rows | length) > 1 {
        let totals = {
            file: "TOTAL",
            chars: ($rows | get chars | math sum),
            words: ($rows | get words | math sum),
            lines: ($rows | get lines | math sum),
        }
        print ($rows | append $totals | table --index false)
    } else {
        print ($rows | table --index false)
    }
}

def tally [text: string] {
    {
        chars: ($text | str length),
        words: ($text | split row -r '\s+' | where {|w| $w != "" } | length),
        lines: ($text | lines | length),
    }
}
