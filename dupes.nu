# Find duplicate files (same content) in a directory tree.
#
# Compares sizes first, then hashes only files that share a size,
# so it is reasonably fast even on big trees.
export def main [
    root: path = "."              # Directory to search
    --min (-m): filesize = 1kb    # Ignore files smaller than this
    --delete (-d)                 # Interactively delete duplicates, keeping the first
] {
    if ($root | path type) != "dir" {
        print -e $"Not a directory: ($root)"
        return
    }
    print $"Scanning ($root) ... [this may take a moment]"
    let candidates = ((ls ($root | into string)) | where type == file and size >= $min)
    let by_size = ($candidates | group-by {|f| $f.size | into string } | items {|size, files|
        {size: ($size | into filesize), files: $files}
    } | where files >= 2)

    if ($by_size | is-empty) {
        print "No duplicate candidates found."
        return
    }

    let dupes = ($by_size | each {|g|
        let hashed = ($g.files | each {|f|
            {name: $f.name, size: $f.size, hash: (open --raw $f.name | hash md5)}
        })
        $hashed | group-by hash | items {|h, fs| if ($fs | length) >= 2 { $fs } else { [] } } | flatten
    } | flatten)

    let groups = ($dupes | group-by {|f| $f.hash } | items {|h, fs|
        {files: ($fs | get name), size: ($fs | get 0.size), wasted: ((($fs | length) - 1) * ($fs | get 0.size | into int))}
    })

    if ($groups | is-empty) {
        print "No duplicate files found."
        return
    }

    for g in $groups {
        print $"DUPLICATE \(($g.size | into string) each\), wasted ($g.wasted | into string):"
        print ($g.files | each {|f| $"    ($f)" } | str join "\n")
    }
    let total = ($groups | get wasted | math sum)
    print $"Found ($groups | length) duplicate group\(s\), ($total | into string) recoverable."

    if $delete {
        for g in $groups {
            $g.files | skip 1 | each {|f|
                let answer = (input $"Delete ($f)? [y/N] ")
                if ($answer | str downcase) == "y" {
                    rm $f
                    print $"deleted ($f)"
                }
            }
        }
    }
}
