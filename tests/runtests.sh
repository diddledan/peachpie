#!/bin/bash

DIR="$(dirname "$0")"
EXECUTED=0
SUCCEEDED=0
FAILED=0

echo "Running Tests..."
MSG=""

runtest() {
    FILE="$1"
    FILENAME="$(basename "$FILE")"
    RESULT="${FILE/.php/.result}"
    OUTPUT=(
        php-cli "$FILE" > "$RESULT-php" || (
            MSG="$MSG\nFailed running php test for $FILE"
            return 1
        ) && mono "$DIR/../build/Release/pchp.exe" /target:exe /out:"${FILE/.php/.exe}" "$FILE" || (
            MSG="$MSG\nFailed to compile $FILE"
            return 1
        ) && mono "${FILE/.php/.exe}" > "$RESULT-peach" || (
            MSG="$MSG\nFailed to run compiled test ${FILE/.php/.exe} ($FILENAME)"
            return 1
        ) && diff "$RESULT-php" "$RESULT-peach" || return 1
    )
    [ $? -eq 1 ] && MSG="$MSG\n$OUTPUT\n" && return 1
}

for t in "$(find "$DIR" -type f -name "*.php")"; do
    if runtest "$t"; then
        echo "."
        SUCCEEDED=$((SUCCEEDED + 1))
    else
        echo "F"
        FAILED=$((FAILED + 1))
    fi
    EXECUTED=$((EXECUTED + 1))
done

echo "Ran $EXECUTED tests. $SUCCEDED passed, $FAILED failed."

[ "$FAILED" -eq 0 ] || exit 1