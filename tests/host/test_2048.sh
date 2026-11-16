#!/bin/sh
# Host tests of the port, on this machine: amiga/curses.c and amiga/keys.c
# built with upstream's 2048 (amiga/patches applied, __amigaos__ set, so
# the Amiga's paths are the ones built) over a plain terminal
# (tests/host/console_host.c), played with scripted keys; tests/host/vt.py
# reads back the screen as the Amiga's console would show it:
#  - keys: the cursor keys come as KEY_* with keypad on, CSI sequences are
#    dropped without it, CR is NL;
#  - the board, its border, two tiles and the score panel are drawn, in the
#    pairs' colours (SGR 3x;40);
#  - the cursor keys (and h j k l) slide the tiles: the board changes and
#    the score never goes down;
#  - R starts again (score 0), Q ends the game;
#  - the window's close (the end of the input) ends it too.
# Needs a C compiler and python3; skipped without a compiler.
#   UP=/path/to/2048-in-terminal (patched) sh tests/host/test_2048.sh
# Copyright (c) 2026 AmiCradle Team. MIT, like 2048-in-terminal.
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT=$(CDPATH= cd -- "$HERE/../.." && pwd)
UP=${UP:?UP=upstream source}
CC=${HOSTCC:-cc}
command -v "$CC" >/dev/null 2>&1 || { echo "host tests: skipped (no C compiler)"; exit 0; }
T=$(mktemp -d "${TMPDIR:-/tmp}/2048-host.XXXXXX")
[ -n "${TEST_KEEP:-}" ] || trap 'rm -rf "$T"' EXIT INT TERM
cd "$ROOT"

MINE="-std=gnu99 -Wall -Werror -D_XOPEN_SOURCE=600 -D_DEFAULT_SOURCE -Iamiga/include -Iamiga"
for f in curses keys; do $CC $MINE -c -o "$T/$f.o" "amiga/$f.c"; done
$CC $MINE -c -o "$T/con.o" tests/host/console_host.c
for f in board draw main save; do
    $CC -std=gnu11 -w -D_GNU_SOURCE -D__amigaos__ -include amiga/include/amiga_prelude.h -Iamiga/include -Iamiga -c -o "$T/u_$f.o" "$UP/src/$f.c"
done
$CC -o "$T/2048" "$T"/u_*.o "$T/curses.o" "$T/keys.o" "$T/con.o"

cat > "$T/keys_test.c" <<'C'
#include <stdio.h>
#include "keys.h"
static const unsigned char *p; static int n;
static int next(void) { return n-- > 0 ? *p++ : -1; }
int main(void)
{
	static const unsigned char in[] = { 0x1b, '[', 'A', 0x9b, 'D', 0x1b, '[', 'B', 0x9b, 'C', '\r',
	                                    0x9b, 'T', 0x9b, '?', '~', 0x1b, '[', 'A', 'q' };
	int want[] = { AMIGA_KEY_UP, AMIGA_KEY_LEFT, AMIGA_KEY_DOWN, AMIGA_KEY_RIGHT, '\n',
	               AMIGA_KEY_PPAGE, AMIGA_KEY_HELP, 0, 'q', -1 }, bad = 0;
	p = in; n = sizeof in;
	for (int i = 0; i < 10; i++) {
		amiga_keys_keypad = i != 7; /* keypad off: the sequence is dropped */
		int c = amiga_key_decode(next);
		if (c != want[i]) { printf("key %d: got %d, want %d\n", i, c, want[i]); bad = 1; }
	}
	return bad;
}
C
fails=0
$CC $MINE -o "$T/keys_test" "$T/keys_test.c" "$T/keys.o"
if "$T/keys_test"; then echo "ok   keys: cursor keys as KEY_*, dropped without keypad, CR"; else echo "FAIL keys"; fails=$((fails + 1)); fi

play() {	# keys (printf format), output
    (cd "$T" && printf "$1" | timeout 20 ./2048 > "$2" 2>&1)
}
want() {	# name, output, texts...
    name=$1; out=$2; shift 2
    n=$#
    for t in "$@"; do set -- "$@" --want "$t"; done
    shift "$n"
    if python3 "$HERE/vt.py" "$out" "$@" > "$T/vt.txt"; then
        echo "ok   $name"
    else
        echo "FAIL $name"; cat "$T/vt.txt"; fails=$((fails + 1))
    fi
}
board() { python3 "$HERE/vt.py" "$1" | sed -n 2,23p | cut -c13-54; }
score() { python3 "$HERE/vt.py" "$1" | sed -n 5p | cut -c56- | tr -dc 0-9; }
tiles() { board "$1" | grep -o '[0-9][0-9]*' | wc -l; }

if play '' "$T/start.out"; then echo "ok   the window's close ends the game"; else echo "FAIL the end of the input did not end it"; fails=$((fails + 1)); fi
want "board, border, score panel" "$T/start.out" "+----------------------------------------+" "Score" "Best Score" "Animations" "Restart" "Quit"
if [ "$(tiles "$T/start.out")" -eq 2 ]; then echo "ok   two tiles to start"; else echo "FAIL tiles at the start: $(tiles "$T/start.out")"; fails=$((fails + 1)); fi
if grep -q "$(printf '\033')\[0;37;40m" "$T/start.out" && grep -q "$(printf '\033')\[0;33;40mScore" "$T/start.out"; then
    echo "ok   the pairs' colours (SGR 37/33 on 40)"
else
    echo "FAIL no colours"; fails=$((fails + 1))
fi

# the same start every run (srand(time)): compare against a run with no keys at the same second
play 'a\033[A\033[D\033[B\033[C' "$T/moves.out"
play 'a' "$T/still.out"
if [ "$(board "$T/moves.out")" != "$(board "$T/still.out")" ]; then echo "ok   the cursor keys slide the tiles"; else echo "FAIL the cursor keys moved nothing"; fails=$((fails + 1)); fi
if [ "$(tiles "$T/moves.out")" -ge 3 ]; then echo "ok   a tile comes after each slide"; else echo "FAIL no new tiles"; fails=$((fails + 1)); fi
play 'ahjklhjkl' "$T/hjkl.out"
if [ "$(board "$T/hjkl.out")" != "$(board "$T/still.out")" ]; then echo "ok   h j k l slide them too"; else echo "FAIL h j k l moved nothing"; fails=$((fails + 1)); fi
play 'a\033[A\033[D\033[B\033[C\033[A\033[Dr' "$T/restart.out"
if [ "$(score "$T/restart.out")" = 0 ] && [ "$(tiles "$T/restart.out")" -eq 2 ]; then echo "ok   R starts again"; else echo "FAIL R: score $(score "$T/restart.out")"; fails=$((fails + 1)); fi
if play 'q' "$T/quit.out" && tail -c 8 "$T/quit.out" | grep -q "$(printf '\033')\[ p"; then echo "ok   Q ends the game, the cursor shows again"; else echo "FAIL Q"; fails=$((fails + 1)); fi

if [ "$fails" -ne 0 ]; then echo "host tests: $fails failed"; exit 1; fi
echo "host tests: all passed"
