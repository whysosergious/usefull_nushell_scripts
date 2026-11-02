# Analyze an access log in Apache/nginx common or combined log format.
#
# Examples:
#   logstats /var/log/nginx/access.log
#   logstats access.log -n 20              # top 20 everywhere
#   logstats access.log --ip               # also group by client IP
export def main [
    file: path                          # Log file to analyze
    --top (-n): int = 10                # How many rows per section
    --ip (-i)                           # Also show stats per client IP
    --raw (-r)                          # Print the parsed rows instead of summaries
] {
    if ($file | path type) != "file" {
        print -e $"No such file: ($file)"
        return
    }
    # common/combined: ip ident user [time] "request" status bytes "referer" "agent"
    let re = '^(?<ip>\S+) \S+ \S+ \[(?<time>[^\]]+)\] "(?<method>\S+) (?<path>\S+)(?: \S+)?" (?<status>\d{3}) (?<bytes>\d+|-)(?: "(?<ref>[^"]*)" "(?<agent>[^"]*)")?'
    let rows = (open --raw $file | lines | parse -r $re | where ip != null | update bytes {|r| if $r.bytes == "-" { 0 } else { $r.bytes | into int } })
    if ($rows | is-empty) {
        print "No log lines matched the common/combined format."
        return
    }

    if $raw {
        print ($rows | table --index false)
        return
    }

    let total = ($rows | length)
    let bytes = ($rows | get bytes | math sum)
    let uniq = ($rows | get ip | uniq | length)
    print $"Requests: ($total)   Unique clients: ($uniq)   Bytes served: ($bytes)"

    let top_path = ($rows | group-by path | items {|p, v| {hits: ($v | length), path: $p} } | sort-by -r hits | first $top)
    print "-- Top paths -------------------------------------------------"
    print ($top_path | table --index false)

    let st = ($rows | group-by status
        | items {|s, v| {code: $s, count: ($v | length)} }
        | sort-by -r count
        | first $top)
    print "-- Status codes ----------------------------------------------"
    print ($st | table --index false)

    if $ip {
        let by_ip = ($rows | where ip != null | group-by ip | items {|a, v|
            {client: $a, hits: ($v | length), bytes: ($v | get bytes | math sum)}
        } | sort-by -r hits | first $top)
        print "-- Top clients -----------------------------------------------"
        print ($by_ip | table --index false)
    }
}
