# Current weather, from wttr.in.
#
# Examples:
#   weather                 # auto location based on your IP
#   weather Lisbon
#   weather Tokyo --forecast
export def main [
    location?: string            # City name or empty for auto-detect
    --format (-f): string = "3"  # One-line format string (see wttr.in/:help)
    --forecast (-F)              # Full three-day forecast page
    --metric (-m)                # Force metric units
] {
    let where_is = (if ($location | is-empty) { "" } else { $location })
    let base = $"https://wttr.in/($where_is)"
    let url = (if $forecast {
        (if $metric { $"($base)?m" } else { $base })
    } else {
        (if $metric { $"($base)?format=($format)&m" } else { $"($base)?format=($format)" })
    })
    let res = (do -i { http get --headers {User-Agent: "curl/8.0"} $url })
    if ($res == null) {
        print -e "weather request failed (offline or wttr.in unreachable?)"
    } else {
        $res
    }
}
