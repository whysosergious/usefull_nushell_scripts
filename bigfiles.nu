# Find the largest files in a directory tree.
#
# Examples:
#   bigfiles ~/dev            # top 20 files in ~/dev
#   bigfiles . -n 5 -m 10mb   # top 5 files of at least 10 MB in current dir
export def main [
    root: path = "."                  # Directory to search
    --count (-n): int = 20            # How many results to show
    --min (-m): filesize = 1mb        # Minimum file size cutoff
    --sort-name (-s)                  # Sort by path instead of size
] {
    if ($root | path type) != "dir" {
        print -e $"Not a directory: ($root)"
        return
    }
    let files = (ls ($root | into string) | where type == file and size >= $min)
    if ($files | is-empty) {
        print $"No files >= ($min) found under ($root)."
        return
    }
    let sorted = if $sort_name { $files | sort-by name } else { $files | sort-by -r size }
    print ($sorted | first $count | select name size modified | table --index false)
    let sum = ($files | get size | math sum)
    print $"Total: ($files | length) files, ($sum) in ($root)"
}
