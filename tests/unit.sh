#!/usr/bin/env sh
# Unit tests for the octokit.sh script.

abs_path=$(dirname $0)
SCRIPT="${abs_path}/../octokit.sh"
JQ="${OCTOKIT_SH_JQ_BIN:-jq}"
JQ_V="$(jq --version 2>&1 | awk '{ print $3 }')"

_main() {
    local cmd ret

    cmd="$1" && shift
    "$cmd" "$@"
    ret=$?

    [ $ret -eq 0 ] || printf 'Fail: %s\n' "$cmd" 1>&2
    exit $ret
}

test_format_json() {
    # Test output without filtering through jq.

    local output expected_out

    $SCRIPT -j _format_json foo=Foo bar=123 baz=true qux=Qux=Qux quux='Multi-line
string' | {
        read -r output

        expected_out='{"baz": true, "quux": "Multi-line\nstring", "foo": "Foo", "qux": "Qux=Qux", "bar": 123}'

        if [ "$expected_out" = "$output" ] ; then
            return 0
        else
            printf 'Expected output does not match output: `%s` != `%s`\n' \
                "$expected_out" "$output"
            return 1
        fi
    }
}

test_format_json_jq() {
    # Test output after filtering through jq.

    local output raw_out expected_out

    $SCRIPT _format_json foo=Foo bar=123 baz=true qux=Qux=Qux quux='Multi-line
string' | {
        read -r output

        raw_out='{"baz": true, "quux": "Multi-line\nstring", "foo": "Foo", "qux": "Qux=Qux", "bar": 123}'

        # jq 1.4 does not sort keys by default.
        case "$JQ_V" in
            1.4) expected_out="$(printf '%s\n' "$raw_out" | jq -S -c .)" ;;
            *) expected_out="$(printf '%s\n' "$raw_out" | jq -c .)" ;;
        esac

        if [ "$expected_out" = "$output" ] ; then
            return 0
        else
            printf 'Expected output does not match output: `%s` != `%s`\n' \
                "$expected_out" "$output"
            return 1
        fi
    }
}

_main "$@"
