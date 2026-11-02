# Disk usage of subdirectories (one level), sorted by size.
export def main [
    root: path = "."          # Directory to measure
    --count (-n): int = 25    # Max rows to display
    --apparent (-a)           # Show apparent size instead of disk usage
] {
    if ($root | path type) != "dir" {
        print -e $"Not a directory: ($root)"
        return
    }
    let col = (if $apparent { "apparent" } else { "physical" })
    let kids = (ls ($root | into string) | where type == dir)
    let root_row = ((du ($root | into string)) | get 0 | select -o $col | get -o $col)
    let rows = ($kids
        | each {|d|
            {dir: $d.name, size: ((du ($d.name | into string)) | get 0 | get -o $col)}
        }
        | append {dir: ($root | into string), size: $root_row}
        | sort-by -r size
        | first $count)
    print ($rows | table --index false)
}
