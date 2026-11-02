# Show your public IP details from ipinfo.io (or details for any IP).
export def main [
    ip?: string      # An IP to look up; empty = your own public IP
    --raw (-r)       # Dump the whole JSON record
] {
    let path = (if ($ip | is-empty) { "json" } else { $"($ip)/json" })
    let info = (do -i { http get --headers {User-Agent: "curl/8.0"} $"https://ipinfo.io/($path)" })
    if ($info == null) {
        print -e "request failed (offline or ipinfo.io unreachable?)"
        return
    }
    if $raw {
        print ($info | to json --raw)
        return
    }
    print ($info | select -o ip? -o city? -o region? -o country? -o org? -o loc? | table --index false)
}
