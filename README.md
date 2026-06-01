# COSMIC — Cosmic Intruders (ROM A) — README

Overview
--------

This repository includes a faithful, byte-for-byte assembly listing of the original "Cosmic Intruders" plugin ROM (ROM A). The assembly listing reproduces the original ROM image layout and machine-code bytes; comments in the listing annotate the original load addresses and opcode bytes so the binary can be reconstructed exactly.

Key facts
- Origin / load address: `* = $E000` (ROM A slot)
- ROM size (image): 0x0800 bytes ($E000-$E7FF)
- Plugin ID at $E000: `$54,$4A` (ASCII "TJ") — required by the ROM selector
- This assembly is a disassembly/reconstruction of the original binary; the file contains the original opcode bytes in comments alongside mnemonics.

Memory map (as used by the image)
- RAM: $0000-$03FF (stack, XMIT/RCV buffers)
- HALT: $7000 (timing/sync location)
- PIA1 registers: $7800-$7803 (keyboard / joystick)
- ACIA: $7A00-$7A01
- VTAC: $7F00 (+ related offsets $7F06, $7F0A, $7F0C)
- CRTRAM (screen RAM): $8000-$88FF (48×48 layout used by game)
- ROM A: $E000-$E7FF (this image)
- ROM B: $E800-$EFFF (companion ROM)
- System ROM low/high: $F000-$FFFF (system routines referenced)

Hardware registers and important constants
- `HALT` = $7000
- `PIA1_DA` = $7800, `PIA1_CRA` = $7801, `PIA1_DB` = $7802,  `PIA1_CRB` = $7803
- `SW_BNK2` = $7900, `ACIA_CTRL` = $7A00, `ACIA_DATA` = $7A01
- `SW_BNK1` = $7E00
- `VTAC` = $7F00 (plus `VTAC_06`, `VTAC_0A`, `VTAC_0C` at offsets)
- `CRTRAM` = $8000

Zero page layout (addresses and symbolic names)
- `ZP_BLIT_DST` = $B1
- `ZP_BLIT_SRC` = $B3
- `ZP_SHIP_POS` = $E0
- `ZP_BULLET_POS` = $E2
- `ZP_CURSOR_POS` = $E4
- `ZP_ALIEN_ROW` = $E6
- `ZP_ALIEN_DIR` = $E8
- `ZP_FIRE_TMR` = $E9
- `ZP_ALIEN_PTR` = $EA
- `ZP_TMP_PTR` = $EC
- `ZP_TUNE_PTR` = $EE
- `ZP_ALIEN_COL` = $F2
- `ZP_SHIP_PTR` = $F3
- `ZP_SHIP_ROW` = $F5
- `ZP_ALIEN_SPD` = $F6
- `ZP_BOMB_SPD` = $F8
- `ZP_MOVE_TMR` = $F9
- `ZP_HIT_FLAG` = $FA
- `ZP_SOUND_TMR` = $FB
- `ZP_ALIEN_IDX` = $FC
- `ZP_WAVE_DIR` = $FD
- `ZP_SCORE_TENS` = $FE

Extended RAM
- `RAM_SCORE_BUF` = $0104
- `RAM_HISCORE_FLAG` = $0109
- `RAM_SHIP_LIVES` = $010A
- `RAM_XMIT_BUF` = $0140

Notable subroutines and locations (selected)
- `$E002` (L_E002): write char A to screen[X]
- `$E009` (L_E009): read char from screen[X] -> A
- `$E010` (L_E010): write char B to screen[X]
- `$E017` (L_E017): read char B from screen[X]
- `$E068` (L_E068): delay_long
- `$E088` (L_E088): game_init / clear zero-page
- `$E095` (L_E095): video_setup (VTAC init, screen fill)
- `$E0DF` (L_E0DF): blit_row (calls ROM B `BLITCPY`)
- `$E1CC` (L_E1CC): game_start
- `$E1F5` (L_E1F5): main_loop
- `$E27B` (L_E27B): scr_next_row (uses ROM B `XPLUS_A`)
- `$E2A6` (L_E29A/L_E2A6 area): draw_scores / blit title
- `$E3C5` (L_E3C5): attract_char_walk
- `$E42D` (L_E42D): aliens_scan
- `$E4F3` (L_E4F3): ship_draw
- `$E5DF` (L_E5DF): kill_aliens
- `$E6B7` (L_E6B7): score_inc
- `$E750` (L_E750): game_over / hi-score

ROM and external routine references
- System ROM references: `VSYNC_STROBE` ($F0DA), `BLITCPY` ($F6BB), `WAIT_VSYNC` ($F740)
- ROM B entry point: `ROMB_ENTRY` ($E800) and `XPLUS_A` ($EFAD)

Byte-for-byte fidelity and verification
- This assembly is annotated with original load addresses and opcode bytes in-line (see many lines like
  `; $E002  B7 70 00`), which preserves the original binary representation.
- To reproduce the original ROM image exactly you should assemble with the same origin (`*= $E000`) and an assembler compatible with the listing layout (the original notes used `crasm`). Example:

```sh
crasm -o cosmicintruder.s19 cint.asm
```

Converting S-Record (S19) to raw binary
--------------------------------------

`crasm` commonly emits Motorola S-Record files (S19). Two reliable ways to convert an `.s19` file to a flat binary image are shown below.

1) Using `srec_cat` (SRecord package)

```sh
# assemble to S19
crasm -o cosmicintruder.s19 cint.asm
# convert S19 -> binary
srec_cat cosmicintruder.s19 -o cosmicintruder.bin -binary
```

`srec_cat` will write the address range present in the S19 records. If you need a fixed-size ROM image or want to force a fill value for undefined ranges, add a `-fill` range, e.g. to produce a 0x800-byte ROM at $E000..$E7FF filled with 0xFF where unspecified:

```sh
srec_cat cosmicintruder.s19 -o cosmicintruder.bin -binary -fill 0xFF 0xE000 0xE7FF
```

2) Using `objcopy` (GNU binutils)

```sh
# assemble to S19
crasm -o cosmicintruder.s19 cint.asm
# convert with objcopy
objcopy -I srec -O binary cosmicintruder.s19 cosmicintruder.bin
```

Verification
- Check the produced file size (should be 0x800 = 2048 bytes for $E000-$E7FF):

```sh
wc -c cosmicintruder.bin
# expected: 2048
```

- Compare with a known-good binary (if available):

```sh
xxd -p cosmicintruder.bin > out.hex
xxd -p original.bin > orig.hex
cmp out.hex orig.hex
```

Notes
- Install `srec_cat` via the `srecord` package, and `objcopy` is included in GNU binutils.
- Use the `-fill` form with `srec_cat` only if you need to guarantee a full ROM image covering a specific address range.

Reliable method (recommended)
-----------------------------

If the previous commands produced unexpected sizes or offsets, use `srec_cat` with `-crop` to force the exact address range and `-fill` to set unspecified bytes. This produces a flat binary exactly 0x800 (2048) bytes long covering the $E000-$E7FF ROM window:

```sh
# assemble to S19
crasm -o cosmicintruder.s19 cint.asm
# extract exactly $E000..$E7FF into a 2048-byte binary (fill missing bytes with 0xFF)
srec_cat cosmicintruder.s19 -crop 0xE000 0xE7FF -fill 0xFF 0xE000 0xE7FF -o cosmicintruder.bin -binary
```

If you don't have `srec_cat`, use `objcopy` then extract the ROM window with `dd` (fallback):

```sh
objcopy -I srec -O binary cosmicintruder.s19 tmp.bin
# skip bytes up to 0xE000 and copy 2048 bytes
dd if=tmp.bin of=cosmicintruder.bin bs=1 skip=$((0xE000)) count=2048 status=none
rm tmp.bin
```

After either method `wc -c cosmicintruder.bin` should report `2048`.


- If you have a verification script (for example `verify.py` referenced in the disassembly header) you can compare the assembled binary byte-for-byte against an original dump. Typical steps:

```sh
# assemble
crasm -o cosmicintruder.bin cint.asm
# compare with original binary (if you have it)
xxd -p cosmicintruder.bin > out.hex
xxd -p original.bin > orig.hex
cmp out.hex orig.hex
```

Notes about accuracy
- The disassembly was produced with the original machine-code bytes preserved in comments; labels use the `L_Exxx` naming convention where `xxx` is the low 3 hex digits of the load address for easy cross-reference.
- Some assembler limitations are noted in the listing (for example a forward-BSR that was assembled as JSR); these are documented in the source comments.
- If you want exact reproduction, use an assembler that preserves opcode encoding and the `$E000` origin; if necessary, adjust small assembler directives to ensure identical object bytes.

How to inspect addresses quickly
- The labels in `cint.asm` include address comments for nearly every instruction. Search for `; $E` to find address-annotated lines.
- Example: `L_E27B` contains the comment `; $E27B  36` etc., indicating the original opcode bytes at that address.

Credits
- Disassembly and reconstruction by Mickey W. Lawless (embedded in the assembly header).

Want me to:
- assemble and run a byte-for-byte verification now (I can run `crasm` if available), or
- generate a shorter cheatsheet listing only the most frequently-modified addresses and tables?
