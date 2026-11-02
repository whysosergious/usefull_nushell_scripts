# Create timestamped backups of files or directories.
#
# Examples:
#   backup notes.txt ~/docs          # -> ~/backups/backup-20261102-191102.tar.gz
#   backup project -o /mnt/hd -n     # override destination, dry-run (no writing)
export def main [
    ...targets: path                 # Files / dirs to back up (relative names are preserved)
    --out (-o): path                 # Backup destination directory (default ~/backups)
    --plain (-P)                     # Copy files instead of creating a tar.gz
    --dry-run (-n)                   # Show what would happen without writing
] {
    let dest_dir = (if ($out | is-empty) { $nu.home-path | path join "backups" } else { $out })
    if ($targets | is-empty) { print "Nothing to back up - pass at least one path."; return }
    let missing = ($targets | where {|t| not ($t | path exists)})
    if ($missing | is-empty) == false {
        print -e $"Skipping non-existent targets: ($missing | str join ', ')"
    }
    let targets = ($targets | where {|t| $t | path exists})
    if ($targets | is-empty) { return }

    let stamp = (date now | format date "%Y%m%d-%H%M%S")
    let name = $"backup-($stamp)"

    let suffix = (if $plain { "/" } else { ".tar.gz" })
    if $dry_run {
        print $"Would archive from ($targets | str join ', ') into: ($dest_dir)/($name)($suffix)"
        return
    }
    mkdir $dest_dir

    if $plain {
        let dest = ($dest_dir | path join $name)
        mkdir $dest
        for t in $targets {
            cp -r $t $dest
            print $"copied ($t) -> ($dest)"
        }
    } else {
        let dest = ($dest_dir | path join $"($name).tar.gz")
        tar -czf $dest ...($targets | each {|t| $t | into string })
        let size = (ls $dest | get 0.size)
        print $"created ($dest) [($size | into string)]"
    }
}
