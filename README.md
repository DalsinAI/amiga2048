# 2048 for GFOS

The AmiCradle Team's port of Alexander Grehov's 2048-in-terminal, the
sliding-tile number game, to GFOS: AmigaOS 3.2 with GFOpenUp,
68040/68060. It runs in its own 80 x 24 console window, in colour: no SDL,
no ACGame and no GFOpenGPU. It ships as a release archive with an
Installer and as the GFOpenUp part Parts/2048.

Upstream is fetched at build time (package/2048.lock) and patched
(amiga/patches); this repository holds only the Amiga port. See
[AMIGA_PORT.md](AMIGA_PORT.md).

MIT, like 2048-in-terminal. Copyright (c) 2026 AmiCradle Team.
