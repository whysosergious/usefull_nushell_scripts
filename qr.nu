# Generate a QR code in the terminal (from any text or URL).
#
# Examples:
#   qr "https://example.com"
#   qr "wifi:T:WPA;S:MyNetwork;P:password;;"
export def main [
    text: string,          # Text / URL to encode
    --ascii (-a)           # Use plain ASCII instead of UTF-8 blocks
] {
    let fmt = (if $ascii { "ANSI" } else { "UTF8" })
    let res = (do { qrencode -t $fmt $text } | complete)
    if ($res.exit_code != 0) {
        print -e $"qrencode failed: ($res.stderr | str trim)"
        print -e "Install it first, e.g. apt/dnf/brew install qrencode"
        return
    }
    print $res.stdout
}
