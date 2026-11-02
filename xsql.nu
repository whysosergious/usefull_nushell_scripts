# A simple and flexible SQL Server query runner for local development.
#
# This command automatically detects whether you passed a file path or an inline 
# T-SQL query string and executes it against your local database container.
# Each result set is printed as a table, followed by its row count.
export def main [
    input?: any                             # The file path (e.g., query.sql) OR a raw T-SQL string
    --server (-s): string = "localhost"     # Server IP
    --db (-d): string = "Database"          # Target database
    --user (-u): string = "sa"              # User
    --pass (-p): string = "SqlServer!"      # Password
    --raw (-r)                              # Plain sqlcmd output instead of tables
] {
    if ($input | is-empty) {
        print "Usage: run-sql <sql-file-path> or run-sql \"<raw-query-string>\" [-d <database>] [--raw]"
        print "Try 'run-sql -h' for full details."
        return
    }

    let base = [-S $server -U $user -P $pass -C -W -I -b -d $db]
    let is_file = ($input | describe) == "string" and ($input | path exists)
    let src = if $is_file { [-i $input] } else { [-Q $input] }

    if $raw {
        sqlcmd ...$base -s "," -h -1 ...$src
    } else {
        let result = (sqlcmd ...$base -s "\t" ...$src | complete)
        render-output ($result.stdout | lines)
        if ($result.stderr | str trim) != "" { print -e $result.stderr }
    }
}


# Walks sqlcmd output: header + "----" rule starts a result set, which ends at a
# blank line or "(n rows affected)". Everything else (counts, PRINT, Msg errors) prints as-is.
def render-output [lines: list<string>] {
    let rule = '^-+(\t-+)*$'
    let count = '^\(\d+ rows? affected\)$'
    let n = $lines | length
    mut i = 0

    while $i < $n {
        let line = $lines | get $i
        let next = if $i + 1 < $n { $lines | get ($i + 1) } else { "" }

        if ($line | str trim) != "" and ($next =~ $rule) {
            mut rows = []
            mut j = $i + 2
            while $j < $n and (($lines | get $j) | str trim) != "" and not (($lines | get $j) =~ $count) {
                $rows = ($rows | append ($lines | get $j))
                $j += 1
            }
            print ([$line] | append $rows | str join "\n" | from tsv)
            $i = $j
        } else {
            if ($line | str trim) != "" { print $line }
            $i += 1
        }
    }
}
