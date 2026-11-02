# Serve the current directory over HTTP for quick sharing/testing.
#
# Examples:
#   serve                 # http://localhost:8000 from here
#   serve ~/dist -p 9000  # serve ~/dist on port 9000
export def main [
    dir: path = "."        # Directory to serve
    --port (-p): int = 8000
    --host (-H): string = "0.0.0.0"  # Use 127.0.0.1 to keep it local
] {
    if ($dir | path type) != "dir" {
        print -e $"Not a directory: ($dir)"
        return
    }
    let shown_host = (if $host == "0.0.0.0" { "localhost" } else { $host })
    print $"Serving ($dir) at http://($shown_host):($port)/  [Ctrl-C to stop]"
    cd $dir
    python3 -m http.server $port --bind $host
}
