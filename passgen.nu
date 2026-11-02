# Generate strong random passwords.
#
# Examples:
#   passgen                 # five 20-char passwords with symbols
#   passgen 32 -n 1         # one 32-char password
#   passgen 16 --no-symbols # alphanumerics only (safe for most web forms)
export def main [
    length: int = 20             # Password length
    --count (-n): int = 5        # How many passwords to print
    --no-symbols (-s)            # Exclude symbol characters
    --no-digits (-d)             # Exclude digits
    --no-upper (-u)              # Exclude uppercase letters
    --no-lower (-l)              # Exclude lowercase letters
    --exclude (-x): string = ""  # Individual characters to exclude (e.g. quotes, commas)
] {
    let classes = ([
        {name: lower, chars: "abcdefghijklmnopqrstuvwxyz", on: (not $no_lower)}
        {name: upper, chars: "ABCDEFGHIJKLMNOPQRSTUVWXYZ", on: (not $no_upper)}
        {name: digit, chars: "0123456789", on: (not $no_digits)}
        {name: symbol, chars: "!@#$%^&*()-_=+[]{};:,.<>?/|~", on: (not $no_symbols)}
    ] | where on)

    if ($classes | is-empty) {
        print -e "At least one character class must stay enabled."
        return
    }
    if $length < ($classes | length) {
        print -e $"Length must be at least ($classes | length) to guarantee one char per class."
        return
    }

    let excluded = ($exclude | split chars)
    let pool = ($classes | get chars | str join | split chars | where {|c| $c not-in $excluded })
    if ($pool | length) < 4 {
        print -e "Character pool is empty after exclusion."
        return
    }
    let pool_n = ($pool | length)
    let pick = {|| $pool | get (random int 0..(($pool_n) - 1)) }

    let pws = (1..$count | each {|_|
        let minimum = ($classes | each {|| do $pick } | flatten)
        let fill = (1..($length - ($minimum | length)) | each {|| do $pick })
        ($minimum ++ $fill | shuffle | str join)
    })
    for pw in $pws { print $pw }
}
