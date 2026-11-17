2048 for GFOS
=============

Alexander Grehov's 2048-in-terminal: slide the tiles on a 4 x 4 board;
two tiles of the same number join into one of their sum. Reach 2048.

The cursor keys (or h, j, k and l) slide the tiles. A turns the sliding
animation on and off, R starts a new game, Q ends the game (as does the
window's close gadget). The game in progress and the best score are kept
in 2048.save beside the program, and an update leaves it.

What it needs
-------------
GFOS (AmigaOS 3.2 with GFOpenUp) on a 68040 or 68060; the FPU is used
when there is one, and not needed. The game runs in a console window on
any screen with eight colours or more: no SDL, no ACGame, no GFOpenGPU.

How it was ported
-----------------
The game is built from upstream as it is. Its curses is GFOpenCurses
(DalsinAI/gfopencurses, the library our console ports share): windows kept in memory, and a refresh that sends the
console only the lines written since, as ANSI that console.device reads,
with colour pairs on the screen's first eight pens (SGR 30-37, 40-47)
and lines and corners in ASCII; it opens the window, puts it in raw mode
and reads the keys (the cursor keys as curses' KEY_*). The one patch, amiga/patches/0001, leaves out the Unix
signals and the terminal check, and keeps the game in PROGDIR:2048.save.

Tests: tests/host/test_2048.sh builds the game on the build machine over
a plain terminal, plays it with scripted keys and reads back the screen
(the board, the colours, slides by cursor keys and by h j k l, a new tile
after each, R, Q, the window's close), and checks the key decoder.

Credits
-------
2048-in-terminal (c) 2014 Alexander Grehov, MIT (LICENSE.txt).
Amiga port: Designed, tested and delivered by The AmiCradle Team.
Copyright (c) 2026 AmiCradle Team, MIT like 2048-in-terminal.
