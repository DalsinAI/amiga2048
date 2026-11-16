#!/usr/bin/env python3
"""2048's picture for its GlowIcons (art/2048.png), drawn here: upstream
has none. Four tiles in the console game's colours, with their numbers.
64 x 64, RGBA, solid or see-through.
    python3 amiga/icons/draw_art.py amiga/icons/art
Pure Python. MIT, Copyright (c) 2026 AmiCradle Team."""
import struct, sys, zlib
from pathlib import Path

W = H = 64
INK = (16, 18, 22, 255)
FONT = {  # 3 x 5
    "0": ["111", "101", "101", "101", "111"], "1": ["010", "110", "010", "010", "111"],
    "2": ["111", "001", "111", "100", "111"], "4": ["101", "101", "111", "001", "001"],
    "6": ["111", "100", "111", "101", "111"], "8": ["111", "101", "111", "101", "111"],
}


def png(px, path):
    raw = b"".join(b"\0" + bytes(v for p in row for v in p) for row in px)
    def chunk(t, d):
        return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff)
    Path(path).write_bytes(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", W, H, 8, 6, 0, 0, 0))
                           + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))


def draw():
    px = [[(0, 0, 0, 0)] * W for _ in range(H)]
    def rect(x0, y0, x1, y1, c):
        for y in range(y0, y1):
            for x in range(x0, x1):
                px[y][x] = c
    def text(s, cx, cy, scale, c):
        w = len(s) * 4 * scale - scale
        x0, y0 = cx - w // 2, cy - 5 * scale // 2
        for i, ch in enumerate(s):
            for r, row in enumerate(FONT[ch]):
                for k, bit in enumerate(row):
                    if bit == "1":
                        rect(x0 + (i * 4 + k) * scale, y0 + r * scale, x0 + (i * 4 + k + 1) * scale, y0 + (r + 1) * scale, c)
    rect(2, 2, 62, 62, INK)
    rect(4, 4, 60, 60, (40, 40, 44, 255))
    tiles = (((5, 5), (230, 210, 60, 255), "2"), ((33, 5), (70, 190, 80, 255), "4"),
             ((5, 33), (70, 110, 220, 255), "8"), ((33, 33), (220, 60, 60, 255), "16"))
    for (x, y), col, n in tiles:
        rect(x, y, x + 26, y + 26, INK)
        rect(x + 1, y + 1, x + 25, y + 25, col)
        text(n, x + 13, y + 13, 3 if len(n) == 1 else 2, INK)
    return px


if __name__ == "__main__":
    out = Path(sys.argv[1] if len(sys.argv) > 1 else "art")
    out.mkdir(parents=True, exist_ok=True)
    png(draw(), out / "2048.png")
