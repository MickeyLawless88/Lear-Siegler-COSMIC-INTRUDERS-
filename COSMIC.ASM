; =============================================================================
; ADM-31/32  COSMIC INTRUDERS  --  ROM A  ($E000-$E7FF)
; 2716 EPROM, plugin socket
; Disassembled by Mickey W. Lawless
;
; Assemble:  crasm -o cosmicintruder.bin cosmicintruder.asm
; Verify:    python3 verify.py
;
; ADM-31 Memory Map (Table 4-1):
;   $0000-$03FF  RAM  (stack $0001-$003F, XMIT $0140-$0147, RCV $0148-$03FF)
;   $7000        HALT  (write anything here; used as timing/sync delay)
;   $7800-$7803  PIA1  (keyboard / joystick)
;   $7900        SW_BNK2
;   $7A00-$7A01  ACIA1
;   $7E00        SW_BNK1  (joystick / switch register)
;   $7F00        VTAC  (video timing / address controller)
;   $8000-$88FF  CRTRAM  (screen RAM, 48 cols x 48 rows)
;   $E000-$E7FF  ROM A  (this image, plugin slot)
;   $E800-$EFFF  ROM B  (129867-67.bin)
;   $F000-$F7FF  System ROM low  (129867-66.bin)
;   $F800-$FFFF  System ROM high (129867-65.bin)
;
; System ROM subroutines:
;   VSYNC_STROBE $F0DA  toggle PIA1_CRB bit3 (frame sync)
;   BLITCPY      $F6BB  memcpy B bytes from [$B3] to [$B1]
;   WAIT_VSYNC   $F740  wait for vsync / init video mode
; ROM B subroutine:
;   XPLUS_A      $EFAD  X = X + A  (16-bit add)
;
; NOTE: BSR L_E6A4 at $E632 assembled as JSR (crasm forward-BSR limitation)
; =============================================================================

        CPU     6800

; --- Hardware ---
HALT            EQU     $7000
PIA1_DA         EQU     $7800
PIA1_CRA        EQU     $7801
PIA1_DB         EQU     $7802
PIA1_CRB        EQU     $7803
SW_BNK2         EQU     $7900
ACIA_CTRL       EQU     $7A00
ACIA_DATA       EQU     $7A01
SW_BNK1         EQU     $7E00
VTAC            EQU     $7F00
VTAC_06         EQU     $7F06
VTAC_0A         EQU     $7F0A
VTAC_0C         EQU     $7F0C
CRTRAM          EQU     $8000

; --- System ROM ---
VSYNC_STROBE    EQU     $F0DA
BLITCPY         EQU     $F6BB
WAIT_VSYNC      EQU     $F740
XPLUS_A         EQU     $EFAD
ROMB_ENTRY      EQU     $E800

; --- Zero page variables ---
ZP_BLIT_DST      EQU     $B1
ZP_BLIT_SRC      EQU     $B3
ZP_SHIP_POS      EQU     $E0
ZP_E1            EQU     $E1
ZP_BULLET_POS    EQU     $E2
ZP_E3            EQU     $E3
ZP_CURSOR_POS    EQU     $E4
ZP_E5            EQU     $E5
ZP_ALIEN_ROW     EQU     $E6
ZP_LOOPCNT       EQU     $E7
ZP_ALIEN_DIR     EQU     $E8
ZP_FIRE_TMR      EQU     $E9
ZP_ALIEN_PTR     EQU     $EA
ZP_EB            EQU     $EB
ZP_TMP_PTR       EQU     $EC
ZP_ED            EQU     $ED
ZP_TUNE_PTR      EQU     $EE
ZP_EF            EQU     $EF
ZP_F0            EQU     $F0
ZP_F1            EQU     $F1
ZP_ALIEN_COL     EQU     $F2
ZP_SHIP_PTR      EQU     $F3
ZP_F4            EQU     $F4
ZP_SHIP_ROW      EQU     $F5
ZP_ALIEN_SPD     EQU     $F6
ZP_F7            EQU     $F7
ZP_BOMB_SPD      EQU     $F8
ZP_MOVE_TMR      EQU     $F9
ZP_HIT_FLAG      EQU     $FA
ZP_SOUND_TMR     EQU     $FB
ZP_ALIEN_IDX     EQU     $FC
ZP_WAVE_DIR      EQU     $FD
ZP_SCORE_TENS    EQU     $FE
ZP_FF            EQU     $FF

; --- Extended RAM ---
RAM_SCORE_BUF    EQU     $0104
RAM_HISCORE_FLAG EQU     $0109
RAM_SHIP_LIVES   EQU     $010A
RAM_XMIT_BUF     EQU     $0140


; --- Plugin ROM identifier ($54='T', $4A='J') ---
        *= $E000
        DB      $54,$4A         ; Plugin ID "TJ" required by ROM selector


; --- write char A to screen[X]: STAA HALT / NOP / STAA 0,X / RTS ---
L_E002           STAA    HALT                 ; $E002  B7 70 00
                 NOP                          ; $E005  01
                 STAA    $00,X                ; $E006  A7 00
                 RTS                          ; $E008  39

; --- read char from screen[X] -> A: STAA HALT / NOP / LDAA 0,X / RTS ---
L_E009           STAA    HALT                 ; $E009  B7 70 00
                 NOP                          ; $E00C  01
                 LDAA    $00,X                ; $E00D  A6 00
                 RTS                          ; $E00F  39

; --- write char B to screen[X]: STAA HALT / NOP / STAB 0,X / RTS ---
L_E010           STAA    HALT                 ; $E010  B7 70 00
                 NOP                          ; $E013  01
                 STAB    $00,X                ; $E014  E7 00
                 RTS                          ; $E016  39

; --- read char B from screen[X]: STAA HALT / NOP / LDAB 0,X / RTS ---
L_E017           STAA    HALT                 ; $E017  B7 70 00

; --- Padding/sprite data after I/O stubs ---
                 DB      $01,$E6,$00,$39,$00,$00

; --- Sprite pixel data: alien row 0 ---
                 DB      $00,$FF,$FF,$FF,$FF,$FF,$FF,$FF
                 DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FB
                 DB      $FF,$FF,$FF,$FF,$FF,$FF,$BF,$FF
                 DB      $FF,$FF,$FF,$FF
                 JMP     L_E088               ; $E03C  7E E0 88

; --- attract_anim: blink ship sprite and wait for RETURN ---
L_E03F           LDX     ZP_SHIP_POS          ; $E03F  DE E0
                 LDAA    #$14                 ; $E041  86 14
                 STAA    ZP_LOOPCNT           ; $E043  97 E7
L_E045           LDAA    #$69                 ; $E045  86 69
                 JSR     L_E002               ; $E047  BD E0 02
                 BSR     L_E068               ; $E04A  8D 1C
                 LDAA    #$6C                 ; $E04C  86 6C
                 JSR     L_E002               ; $E04E  BD E0 02
                 BSR     L_E068               ; $E051  8D 15
                 JSR     VSYNC_STROBE         ; $E053  BD F0 DA
                 DEC     $00E7                ; $E056  7A 00 E7
                 BNE     L_E045               ; $E059  26 EA
                 LDAA    #$20                 ; $E05B  86 20
                 JSR     L_E002               ; $E05D  BD E0 02
                 LDX     #$0000               ; $E060  CE 00 00
                 STX     ZP_SHIP_POS          ; $E063  DF E0
                 JMP     L_E77B               ; $E065  7E E7 7B

; --- delay_long: busy-wait (~50ms) ---
L_E068           LDAB    #$32                 ; $E068  C6 32
L_E06A           LDAA    #$96                 ; $E06A  86 96
L_E06C           DECA                         ; $E06C  4A
                 BNE     L_E06C               ; $E06D  26 FD
                 DECB                         ; $E06F  5A
                 BNE     L_E06A               ; $E070  26 F8
                 RTS                          ; $E072  39

; --- Sprite pixel data: alien row 1 ---
                 DB      $00,$00,$00,$BF,$FF,$FF,$FF,$FF
                 DB      $FF,$FF,$7F,$DF,$FF

; --- Unreachable padding ---
                 DB      $7F,$00,$00,$32,$32,$7E,$E8,$D0

; --- game_init: clear zero-page RAM, configure VTAC, draw attract screen ---
L_E088           LDAB    #$0A                 ; $E088  C6 0A
                 LDAA    #$30                 ; $E08A  86 30
                 LDX     #$00FF               ; $E08C  CE 00 FF
L_E08F           STAA    $00,X                ; $E08F  A7 00
                 INX                          ; $E091  08
                 DECB                         ; $E092  5A
                 BNE     L_E08F               ; $E093  26 FA

; --- video_setup: VTAC_06=$17, WAIT_VSYNC, VTAC_0C=$55, fill screen ---
L_E095           LDAA    #$17                 ; $E095  86 17
                 STAA    VTAC_06              ; $E097  B7 7F 06
                 JSR     WAIT_VSYNC           ; $E09A  BD F7 40
                 LDAA    #$55                 ; $E09D  86 55
                 STAA    VTAC_0C              ; $E09F  B7 7F 0C
                 LDAA    #$98                 ; $E0A2  86 98
                 LDX     #CRTRAM              ; $E0A4  CE 80 00
                 JSR     L_E271               ; $E0A7  BD E2 71
                 JSR     L_E29A               ; $E0AA  BD E2 9A
                 LDX     #L_E0E6              ; $E0AD  CE E0 E6
                 STX     ZP_BLIT_SRC          ; $E0B0  DF B3
                 LDX     #$81FE               ; $E0B2  CE 81 FE
                 BSR     L_E0DF               ; $E0B5  8D 28
                 LDX     #$824E               ; $E0B7  CE 82 4E
                 BSR     L_E0DF               ; $E0BA  8D 23
                 LDX     #$829E               ; $E0BC  CE 82 9E
                 BSR     L_E0DF               ; $E0BF  8D 1E
                 LDX     #$82EE               ; $E0C1  CE 82 EE
                 BSR     L_E0DF               ; $E0C4  8D 19
                 LDX     #$842E               ; $E0C6  CE 84 2E
                 STX     ZP_BLIT_DST          ; $E0C9  DF B1
                 LDX     #L_E106              ; $E0CB  CE E1 06
                 STX     ZP_BLIT_SRC          ; $E0CE  DF B3
                 LDAB    #$19                 ; $E0D0  C6 19
                 JSR     BLITCPY              ; $E0D2  BD F6 BB
                 LDAA    #$4F                 ; $E0D5  86 4F

; --- attract_loop: scan keyboard (PIA1_DA) until RETURN pressed ---
L_E0D7           JSR     L_E6A4               ; $E0D7  BD E6 A4
                 BPL     L_E0D7               ; $E0DA  2A FB
                 JMP     L_E11F               ; $E0DC  7E E1 1F

; --- blit_row: set BLIT_DST=X, LDAB #8, JMP BLITCPY ---
L_E0DF           STX     ZP_BLIT_DST          ; $E0DF  DF B1
                 LDAB    #$08                 ; $E0E1  C6 08
                 JMP     BLITCPY              ; $E0E3  7E F6 BB

; --- Score legend + attract mode string ---
L_E0E6           ASC     " `  = 10 b  = 20 d  = 30{|} = ??"
L_E106           ASC     " PRESS RETURN TO START..."
L_E11F           DB      $BD
                 STAB    $40CE                ; $E120  F7 40 CE
                 NOP                          ; $E123  01
                 DB      $04                     ; $E124
                 LDAB    #$05                 ; $E125  C6 05
                 LDAA    #$30                 ; $E127  86 30
L_E129           STAA    $00,X                ; $E129  A7 00
                 INX                          ; $E12B  08
                 DECB                         ; $E12C  5A
                 BNE     L_E129               ; $E12D  26 FA
                 LDAA    #$55                 ; $E12F  86 55
                 STAA    VTAC_0C              ; $E131  B7 7F 0C
                 LDX     #CRTRAM              ; $E134  CE 80 00
                 LDAA    #$98                 ; $E137  86 98
                 JSR     L_E271               ; $E139  BD E2 71
                 CLRA                         ; $E13C  4F
                 STAA    ZP_ALIEN_IDX         ; $E13D  97 FC
                 STAA    ZP_SHIP_POS          ; $E13F  97 E0
                 STAA    ZP_E1                ; $E141  97 E1
                 LDX     #$8007               ; $E143  CE 80 07
                 JSR     L_E271               ; $E146  BD E2 71
                 LDX     #$8047               ; $E149  CE 80 47
                 JSR     L_E271               ; $E14C  BD E2 71
                 LDX     #$8050               ; $E14F  CE 80 50
                 JSR     L_E268               ; $E152  BD E2 68
                 LDX     #$86E0               ; $E155  CE 86 E0
                 JSR     L_E268               ; $E158  BD E2 68
                 JSR     L_E29A               ; $E15B  BD E2 9A
                 LDX     #L_E3C0              ; $E15E  CE E3 C0
                 STX     ZP_BLIT_SRC          ; $E161  DF B3
                 LDX     #$8732               ; $E163  CE 87 32
                 STX     ZP_BLIT_DST          ; $E166  DF B1
                 LDAB    #$05                 ; $E168  C6 05
                 JSR     BLITCPY              ; $E16A  BD F6 BB
                 LDX     #$85AC               ; $E16D  CE 85 AC
                 BSR     L_E179               ; $E170  8D 07
                 LDX     #$85FC               ; $E172  CE 85 FC
                 BSR     L_E179               ; $E175  8D 02
                 BRA     L_E185               ; $E177  20 0C
L_E179           STX     ZP_BLIT_DST          ; $E179  DF B1
                 LDX     #L_E2D7              ; $E17B  CE E2 D7
                 STX     ZP_BLIT_SRC          ; $E17E  DF B3
                 LDAB    #$38                 ; $E180  C6 38
                 JMP     BLITCPY              ; $E182  7E F6 BB

; --- draw_alien_rows: blit all 5 alien rows to screen using sprite data ---
L_E185           LDX     #$8153               ; $E185  CE 81 53
                 BSR     L_E1C5               ; $E188  8D 3B
                 LDX     #$81F3               ; $E18A  CE 81 F3
                 BSR     L_E1C5               ; $E18D  8D 36
                 LDX     #$8293               ; $E18F  CE 82 93
                 BSR     L_E1BE               ; $E192  8D 2A
                 LDX     #$8333               ; $E194  CE 83 33
                 BSR     L_E1BE               ; $E197  8D 25
                 LDX     #$83D3               ; $E199  CE 83 D3
                 BSR     L_E1A4               ; $E19C  8D 06
                 LDAA    #$37                 ; $E19E  86 37
                 STAA    ZP_ALIEN_ROW         ; $E1A0  97 E6
                 BRA     L_E1CC               ; $E1A2  20 28

; --- blit_alien_row_41: blit 41-byte alien sprite with wave_dir offset ---
L_E1A4           STX     ZP_BLIT_DST          ; $E1A4  DF B1
                 LDX     #L_E30F              ; $E1A6  CE E3 0F
L_E1A9           STX     ZP_BLIT_SRC          ; $E1A9  DF B3
                 LDX     ZP_BLIT_DST          ; $E1AB  DE B1
                 LDAA    ZP_ALIEN_IDX         ; $E1AD  96 FC
L_E1AF           DECA                         ; $E1AF  4A
                 BMI     L_E1B7               ; $E1B0  2B 05
                 JSR     L_E27B               ; $E1B2  BD E2 7B
                 BRA     L_E1AF               ; $E1B5  20 F8
L_E1B7           STX     ZP_BLIT_DST          ; $E1B7  DF B1
                 LDAB    #$29                 ; $E1B9  C6 29
                 JMP     BLITCPY              ; $E1BB  7E F6 BB
L_E1BE           STX     ZP_BLIT_DST          ; $E1BE  DF B1
                 LDX     #L_E338              ; $E1C0  CE E3 38
                 BRA     L_E1A9               ; $E1C3  20 E4
L_E1C5           STX     ZP_BLIT_DST          ; $E1C5  DF B1
                 LDX     #L_E361              ; $E1C7  CE E3 61
                 BRA     L_E1A9               ; $E1CA  20 DD

; --- game_start: zero score/dir/bullet/cursor, init ship, music, speed timers ---
L_E1CC           CLRA                         ; $E1CC  4F
                 STAA    ZP_WAVE_DIR          ; $E1CD  97 FD
                 STAA    ZP_SCORE_TENS        ; $E1CF  97 FE
                 STAA    ZP_ALIEN_DIR         ; $E1D1  97 E8
                 LDX     #$0000               ; $E1D3  CE 00 00
                 STX     ZP_BULLET_POS        ; $E1D6  DF E2
                 STX     ZP_CURSOR_POS        ; $E1D8  DF E4
                 JSR     L_E414               ; $E1DA  BD E4 14
                 JSR     L_E543               ; $E1DD  BD E5 43
                 JSR     L_E77B               ; $E1E0  BD E7 7B
                 LDX     #ROMB_ENTRY          ; $E1E3  CE E8 00
                 STX     ZP_TUNE_PTR          ; $E1E6  DF EE
                 LDAA    #$1E                 ; $E1E8  86 1E
                 STAA    ZP_ALIEN_SPD         ; $E1EA  97 F6
                 STAA    ZP_BOMB_SPD          ; $E1EC  97 F8
                 STAA    ZP_MOVE_TMR          ; $E1EE  97 F9
                 STAA    ZP_SOUND_TMR         ; $E1F0  97 FB
                 STAA    RAM_SHIP_LIVES       ; $E1F2  B7 01 0A

; --- main_loop: per-frame update (alien speed, ship, bullet, input, music) ---
L_E1F5           DEC     $00F6                ; $E1F5  7A 00 F6
                 BEQ     L_E1FF               ; $E1F8  27 05
                 JSR     L_E25E               ; $E1FA  BD E2 5E
                 BRA     L_E214               ; $E1FD  20 15
L_E1FF           JSR     L_E42D               ; $E1FF  BD E4 2D
                 LDAA    ZP_ALIEN_ROW         ; $E202  96 E6
                 LSRA                         ; $E204  44
                 LSRA                         ; $E205  44
                 LSRA                         ; $E206  44
                 LSRA                         ; $E207  44
                 INCA                         ; $E208  4C
                 LDAB    SW_BNK1              ; $E209  F6 7E 00
                 BITB    #$40                 ; $E20C  C5 40
                 BNE     L_E212               ; $E20E  26 02
                 ADDA    #$02                 ; $E210  8B 02
L_E212           STAA    ZP_ALIEN_SPD         ; $E212  97 F6
L_E214           JSR     L_E4F3               ; $E214  BD E4 F3
                 DEC     $00F8                ; $E217  7A 00 F8
                 BNE     L_E22C               ; $E21A  26 10
                 JSR     L_E54D               ; $E21C  BD E5 4D
                 LDAA    #$04                 ; $E21F  86 04
                 LDAB    SW_BNK1              ; $E221  F6 7E 00
                 BITB    #$40                 ; $E224  C5 40
                 BEQ     L_E22A               ; $E226  27 02
                 LDAA    #$02                 ; $E228  86 02
L_E22A           STAA    ZP_BOMB_SPD          ; $E22A  97 F8
L_E22C           JSR     L_E609               ; $E22C  BD E6 09
                 DEC     $00F9                ; $E22F  7A 00 F9
                 BNE     L_E23B               ; $E232  26 07
                 JSR     L_E6DB               ; $E234  BD E6 DB
                 LDAA    #$28                 ; $E237  86 28
                 STAA    ZP_MOVE_TMR          ; $E239  97 F9
L_E23B           LDAA    ZP_SCORE_TENS        ; $E23B  96 FE
                 CMPA    #$32                 ; $E23D  81 32
                 BLT     L_E247               ; $E23F  2D 06
                 JSR     L_E6D3               ; $E241  BD E6 D3
                 CLR     $00FE                ; $E244  7F 00 FE
L_E247           DEC     $00FB                ; $E247  7A 00 FB
                 BNE     L_E25C               ; $E24A  26 10
                 JSR     L_E3C5               ; $E24C  BD E3 C5
                 LDAA    #$0F                 ; $E24F  86 0F
                 LDAB    SW_BNK1              ; $E251  F6 7E 00
                 BITB    #$40                 ; $E254  C5 40
                 BEQ     L_E25A               ; $E256  27 02
                 LDAB    #$06                 ; $E258  C6 06
L_E25A           STAA    ZP_SOUND_TMR         ; $E25A  97 FB
L_E25C           BRA     L_E1F5               ; $E25C  20 97

; --- delay_short: LDAA #$50, loop: STAA HALT / NOP / DECA / BNE ---
L_E25E           LDAA    #$50                 ; $E25E  86 50
L_E260           STAA    HALT                 ; $E260  B7 70 00
                 NOP                          ; $E263  01
                 DECA                         ; $E264  4A
                 BNE     L_E260               ; $E265  26 F9
                 RTS                          ; $E267  39

; --- fill_80: fill 80 bytes from X with A ---
L_E268           LDAB    #$50                 ; $E268  C6 50
L_E26A           STAA    $00,X                ; $E26A  A7 00
                 INX                          ; $E26C  08
                 DECB                         ; $E26D  5A
                 BNE     L_E26A               ; $E26E  26 FA
                 RTS                          ; $E270  39

; --- fill_row: fill one screen row (24 bytes) with A, advance row ---
L_E271           LDAB    #$18                 ; $E271  C6 18
L_E273           STAA    $00,X                ; $E273  A7 00
                 BSR     L_E27B               ; $E275  8D 04
                 DECB                         ; $E277  5A
                 BNE     L_E273               ; $E278  26 F9
                 RTS                          ; $E27A  39

; --- scr_next_row: push regs, X += $50 via XPLUS_A (ROM B), pop regs ---
L_E27B           PSHA                         ; $E27B  36
                 PSHB                         ; $E27C  37
                 LDAA    #$50                 ; $E27D  86 50
                 JSR     XPLUS_A              ; $E27F  BD EF AD
                 PULB                         ; $E282  33
                 PULA                         ; $E283  32
                 RTS                          ; $E284  39

; --- scr_prev_row: X -= $50 (back one screen row) ---
L_E285           PSHA                         ; $E285  36
                 PSHB                         ; $E286  37
                 STX     ZP_F0                ; $E287  DF F0
                 LDAB    ZP_F0                ; $E289  D6 F0
                 LDAA    ZP_F1                ; $E28B  96 F1
                 SUBA    #$50                 ; $E28D  80 50
                 SBCB    #$00                 ; $E28F  C2 00
                 STAB    ZP_F0                ; $E291  D7 F0
                 STAA    ZP_F1                ; $E293  97 F1
                 LDX     ZP_F0                ; $E295  DE F0
                 PULB                         ; $E297  33
                 PULA                         ; $E298  32
                 RTS                          ; $E299  39

; --- draw_scores: blit title bar + HI SCORE + SCORE to screen ---
L_E29A           LDX     #L_E38A              ; $E29A  CE E3 8A
                 STX     ZP_BLIT_SRC          ; $E29D  DF B3
                 LDX     #$8011               ; $E29F  CE 80 11
                 STX     ZP_BLIT_DST          ; $E2A2  DF B1
                 LDAB    #$36                 ; $E2A4  C6 36
                 JSR     BLITCPY              ; $E2A6  BD F6 BB
                 LDAA    RAM_HISCORE_FLAG     ; $E2A9  B6 01 09
                 BEQ     L_E2C3               ; $E2AC  27 15
                 LDAA    #$9A                 ; $E2AE  86 9A
                 STAA    HALT                 ; $E2B0  B7 70 00
                 NOP                          ; $E2B3  01
                 STAA    $802B                ; $E2B4  B7 80 2B
                 LDAA    #$98                 ; $E2B7  86 98
                 STAA    HALT                 ; $E2B9  B7 70 00
                 NOP                          ; $E2BC  01
                 STAA    $803A                ; $E2BD  B7 80 3A
                 CLR     RAM_HISCORE_FLAG     ; $E2C0  7F 01 09
L_E2C3           LDX     #$00FF               ; $E2C3  CE 00 FF
                 STX     ZP_BLIT_SRC          ; $E2C6  DF B3
                 LDX     #$8035               ; $E2C8  CE 80 35
                 BSR     L_E2D0               ; $E2CB  8D 03
                 LDX     #$8042               ; $E2CD  CE 80 42
L_E2D0           STX     ZP_BLIT_DST          ; $E2D0  DF B1
                 LDAB    #$05                 ; $E2D2  C6 05
                 JMP     BLITCPY              ; $E2D4  7E F6 BB

; --- Screen template: alien sprites + title bar + score + cursor chars ---
L_E2D7           DB      $5B,$5B,$5B,$5B,$5B,$5B,$5B,$5B
                 DB      $20,$20,$20,$20,$20,$20,$20,$20
                 DB      $5B,$5B,$5B,$5B,$5B,$5B,$5B,$5B
                 DB      $20,$20,$20,$20,$20,$20,$20,$20
                 DB      $5B,$5B,$5B,$5B,$5B,$5B,$5B,$5B
                 DB      $20,$20,$20,$20,$20,$20,$20,$20
                 DB      $5B,$5B,$5B,$5B,$5B,$5B,$5B,$5B
L_E30F           DB      $60,$20,$20,$20,$60,$20,$20,$20
                 DB      $60,$20,$20,$20,$60,$20,$20,$20
                 DB      $60,$20,$20,$20,$60,$20,$20,$20
                 DB      $60,$20,$20,$20,$60,$20,$20,$20
                 DB      $60,$20,$20,$20,$60,$20,$20,$20
                 DB      $60
L_E338           DB      $62,$20,$20,$20,$62,$20,$20,$20
                 DB      $62,$20,$20,$20,$62,$20,$20,$20
                 DB      $62,$20,$20,$20,$62,$20,$20,$20
                 DB      $62,$20,$20,$20,$62,$20,$20,$20
                 DB      $62,$20,$20,$20,$62,$20,$20,$20
                 DB      $62
L_E361           DB      $64,$20,$20,$20,$64,$20,$20,$20
                 DB      $64,$20,$20,$20,$64,$20,$20,$20
                 DB      $64,$20,$20,$20,$64,$20,$20,$20
                 DB      $64,$20,$20,$20,$64,$20,$20,$20
                 DB      $64,$20,$20,$20,$64,$20,$20,$20
                 DB      $64
L_E38A           DB      $41,$44,$4D,$33,$31,$2F,$33,$32
                 DB      $20,$43,$4F,$53,$4D,$49,$43,$20
                 DB      $49,$4E,$54,$52,$55,$44,$45,$52
                 DB      $53,$20,$20,$48,$49,$20,$53,$43
                 DB      $4F,$52,$45,$20,$30,$30,$30,$30
                 DB      $30,$20,$20,$53,$43,$4F,$52,$45
                 DB      $20,$30,$30,$30,$30,$30
L_E3C0           DB      $6C,$20,$6C,$20
L_E3C4           DB      $6C

; --- attract_char_walk: walk cursor thru attract screen reading chars ---
L_E3C5           LDX     ZP_CURSOR_POS        ; $E3C5  DE E4
                 BEQ     L_E407               ; $E3C7  27 3E
                 JSR     L_E009               ; $E3C9  BD E0 09
                 BSR     L_E408               ; $E3CC  8D 3A
                 BCC     L_E402               ; $E3CE  24 32
                 LDAA    #$20                 ; $E3D0  86 20
                 JSR     L_E002               ; $E3D2  BD E0 02
                 STAA    HALT                 ; $E3D5  B7 70 00
                 NOP                          ; $E3D8  01
                 STAA    $01,X                ; $E3D9  A7 01
                 STAA    HALT                 ; $E3DB  B7 70 00
                 NOP                          ; $E3DE  01
                 STAA    $02,X                ; $E3DF  A7 02
                 INX                          ; $E3E1  08
                 STAA    HALT                 ; $E3E2  B7 70 00
                 NOP                          ; $E3E5  01
                 LDAA    $03,X                ; $E3E6  A6 03
                 BEQ     L_E402               ; $E3E8  27 18
                 STX     ZP_CURSOR_POS        ; $E3EA  DF E4
L_E3EC           LDAA    #$7B                 ; $E3EC  86 7B
                 JSR     L_E002               ; $E3EE  BD E0 02
                 INCA                         ; $E3F1  4C
                 STAA    HALT                 ; $E3F2  B7 70 00
                 NOP                          ; $E3F5  01
                 STAA    $01,X                ; $E3F6  A7 01
                 INCA                         ; $E3F8  4C
                 STAA    HALT                 ; $E3F9  B7 70 00
                 NOP                          ; $E3FC  01
                 STAA    $02,X                ; $E3FD  A7 02
                 JMP     VSYNC_STROBE         ; $E3FF  7E F0 DA
L_E402           LDX     #$0000               ; $E402  CE 00 00
                 STX     ZP_CURSOR_POS        ; $E405  DF E4
L_E407           RTS                          ; $E407  39

; --- is_alien_char: SEC if A in $7B..$7D, else CLC ---
L_E408           CMPA    #$7B                 ; $E408  81 7B
                 BLT     L_E412               ; $E40A  2D 06
                 CMPA    #$7D                 ; $E40C  81 7D
                 BGT     L_E412               ; $E40E  2E 02
                 SEC                          ; $E410  0D
                 RTS                          ; $E411  39

; --- not_alien_char: CLC / RTS ---
L_E412           CLC                          ; $E412  0C
                 RTS                          ; $E413  39

; --- aliens_init: ZP_ALIEN_PTR=$85EF, ZP_ALIEN_COL=15-ZP_WAVE_DIR ---
L_E414           LDX     #$85EF               ; $E414  CE 85 EF
L_E417           STX     ZP_ALIEN_PTR         ; $E417  DF EA
                 LDAB    #$0F                 ; $E419  C6 0F
                 SUBB    ZP_WAVE_DIR          ; $E41B  D0 FD
                 STAB    ZP_ALIEN_COL         ; $E41D  D7 F2
                 RTS                          ; $E41F  39
L_E420           LDX     #$8140               ; $E420  CE 81 40
                 LDAA    ZP_WAVE_DIR          ; $E423  96 FD
L_E425           DECA                         ; $E425  4A
                 BMI     L_E417               ; $E426  2B EF
                 JSR     L_E27B               ; $E428  BD E2 7B
                 BRA     L_E425               ; $E42B  20 F8

; --- aliens_scan: scan alien row, move chars, check/flip direction ---
L_E42D           LDAB    #$50                 ; $E42D  C6 50
                 STAB    ZP_LOOPCNT           ; $E42F  D7 E7
                 LDX     ZP_ALIEN_PTR         ; $E431  DE EA
                 LDAA    ZP_ALIEN_DIR         ; $E433  96 E8
                 BMI     L_E43B               ; $E435  2B 04
                 BNE     L_E49E               ; $E437  26 65
                 BRA     L_E43E               ; $E439  20 03
L_E43B           JMP     L_E4C8               ; $E43B  7E E4 C8
L_E43E           JSR     L_E009               ; $E43E  BD E0 09
                 BSR     L_E492               ; $E441  8D 4F
                 BCC     L_E464               ; $E443  24 1F
                 STAA    HALT                 ; $E445  B7 70 00
                 NOP                          ; $E448  01
                 LDAB    $01,X                ; $E449  E6 01
                 BEQ     L_E489               ; $E44B  27 3C
                 JSR     L_E5F5               ; $E44D  BD E5 F5
                 BCC     L_E457               ; $E450  24 05
                 PULA                         ; $E452  32
                 PULA                         ; $E453  32
                 JMP     L_E750               ; $E454  7E E7 50
L_E457           EORA    #$01                 ; $E457  88 01
                 STAA    HALT                 ; $E459  B7 70 00
                 NOP                          ; $E45C  01
                 STAA    $01,X                ; $E45D  A7 01
                 LDAA    #$20                 ; $E45F  86 20
                 JSR     L_E002               ; $E461  BD E0 02
L_E464           DEX                          ; $E464  09
                 DEC     $00E7                ; $E465  7A 00 E7
                 BNE     L_E43E               ; $E468  26 D4
L_E46A           DEC     $00F2                ; $E46A  7A 00 F2
                 BEQ     L_E472               ; $E46D  27 03
                 STX     ZP_ALIEN_PTR         ; $E46F  DF EA
                 RTS                          ; $E471  39
L_E472           LDAA    ZP_ALIEN_DIR         ; $E472  96 E8
                 BMI     L_E47B               ; $E474  2B 05
                 BEQ     L_E486               ; $E476  27 0E
                 JMP     L_E420               ; $E478  7E E4 20
L_E47B           ANDA    #$7F                 ; $E47B  84 7F
                 EORA    #$01                 ; $E47D  88 01
                 STAA    ZP_ALIEN_DIR         ; $E47F  97 E8
                 INC     $00FD                ; $E481  7C 00 FD
                 BRA     L_E472               ; $E484  20 EC
L_E486           JMP     L_E414               ; $E486  7E E4 14
L_E489           LDAA    ZP_ALIEN_DIR         ; $E489  96 E8
                 ORAA    #$80                 ; $E48B  8A 80
                 STAA    ZP_ALIEN_DIR         ; $E48D  97 E8
                 JMP     L_E414               ; $E48F  7E E4 14

; --- is_gfx_char: SEC if A in $60..$66 (alien graphic chars), else CLC ---
L_E492           CMPA    #$60                 ; $E492  81 60
                 BLT     L_E49C               ; $E494  2D 06
                 CMPA    #$66                 ; $E496  81 66
                 BGT     L_E49C               ; $E498  2E 02
                 SEC                          ; $E49A  0D
                 RTS                          ; $E49B  39

; --- not_gfx_char: CLC / RTS ---
L_E49C           CLC                          ; $E49C  0C
                 RTS                          ; $E49D  39
L_E49E           STAA    HALT                 ; $E49E  B7 70 00
                 NOP                          ; $E4A1  01
                 LDAA    $01,X                ; $E4A2  A6 01
                 BSR     L_E492               ; $E4A4  8D EC
                 BCC     L_E4C0               ; $E4A6  24 18
                 JSR     L_E017               ; $E4A8  BD E0 17
                 BEQ     L_E489               ; $E4AB  27 DC
                 JSR     L_E5F5               ; $E4AD  BD E5 F5
                 BCC     L_E4B7               ; $E4B0  24 05
                 PULA                         ; $E4B2  32
                 PULA                         ; $E4B3  32
                 JMP     L_E750               ; $E4B4  7E E7 50
L_E4B7           EORA    #$01                 ; $E4B7  88 01
                 JSR     L_E002               ; $E4B9  BD E0 02
                 LDAA    #$20                 ; $E4BC  86 20
                 STAA    $01,X                ; $E4BE  A7 01
L_E4C0           INX                          ; $E4C0  08
                 DEC     $00E7                ; $E4C1  7A 00 E7
                 BNE     L_E49E               ; $E4C4  26 D8
                 BRA     L_E46A               ; $E4C6  20 A2
L_E4C8           JSR     L_E009               ; $E4C8  BD E0 09
                 BSR     L_E492               ; $E4CB  8D C5
                 BCC     L_E4EA               ; $E4CD  24 1B
                 LDAB    #$20                 ; $E4CF  C6 20
                 JSR     L_E010               ; $E4D1  BD E0 10
                 STX     ZP_TMP_PTR           ; $E4D4  DF EC
                 LDX     ZP_ALIEN_PTR         ; $E4D6  DE EA
                 CPX     #$85EF               ; $E4D8  8C 85 EF
                 BNE     L_E4E2               ; $E4DB  26 05
                 PULA                         ; $E4DD  32
                 PULA                         ; $E4DE  32
                 JMP     L_E750               ; $E4DF  7E E7 50
L_E4E2           LDX     ZP_TMP_PTR           ; $E4E2  DE EC
                 STAA    HALT                 ; $E4E4  B7 70 00
                 NOP                          ; $E4E7  01
                 STAA    $50,X                ; $E4E8  A7 50
L_E4EA           DEX                          ; $E4EA  09
                 DEC     $00E7                ; $E4EB  7A 00 E7
                 BNE     L_E4C8               ; $E4EE  26 D8
                 JMP     L_E46A               ; $E4F0  7E E4 6A

; --- ship_draw: draw/erase ship sprite ($6C) along current row ---
L_E4F3           LDX     ZP_SHIP_PTR          ; $E4F3  DE F3
                 LDAA    #$50                 ; $E4F5  86 50
                 STAA    ZP_LOOPCNT           ; $E4F7  97 E7
L_E4F9           JSR     L_E009               ; $E4F9  BD E0 09
                 CMPA    #$68                 ; $E4FC  81 68
                 BNE     L_E52C               ; $E4FE  26 2C
                 LDAB    #$20                 ; $E500  C6 20
                 JSR     L_E010               ; $E502  BD E0 10
                 STAA    HALT                 ; $E505  B7 70 00
                 NOP                          ; $E508  01
                 LDAB    $50,X                ; $E509  E6 50
                 CMPB    #$6C                 ; $E50B  C1 6C
                 BNE     L_E512               ; $E50D  26 03
                 JMP     L_E03F               ; $E50F  7E E0 3F
L_E512           JSR     L_E5F5               ; $E512  BD E5 F5
                 BCC     L_E522               ; $E515  24 0B
                 JSR     L_E601               ; $E517  BD E6 01
                 STAA    HALT                 ; $E51A  B7 70 00
                 NOP                          ; $E51D  01
                 STAB    $50,X                ; $E51E  E7 50
                 BRA     L_E535               ; $E520  20 13
L_E522           CMPB    #$20                 ; $E522  C1 20
                 BNE     L_E535               ; $E524  26 0F
                 STAA    HALT                 ; $E526  B7 70 00
                 NOP                          ; $E529  01
                 STAA    $50,X                ; $E52A  A7 50
L_E52C           CMPA    #$69                 ; $E52C  81 69
                 BNE     L_E535               ; $E52E  26 05
                 LDAA    #$20                 ; $E530  86 20
                 JSR     L_E002               ; $E532  BD E0 02
L_E535           DEX                          ; $E535  09
                 DEC     $00E7                ; $E536  7A 00 E7
                 BNE     L_E4F9               ; $E539  26 BE
                 STX     ZP_SHIP_PTR          ; $E53B  DF F3
                 DEC     $00F5                ; $E53D  7A 00 F5
                 BEQ     L_E543               ; $E540  27 01
                 RTS                          ; $E542  39

; --- ship_reset: ZP_SHIP_PTR=$86E0, ZP_SHIP_ROW=20 ---
L_E543           LDX     #$86E0               ; $E543  CE 86 E0
                 STX     ZP_SHIP_PTR          ; $E546  DF F3
                 LDAA    #$14                 ; $E548  86 14
                 STAA    ZP_SHIP_ROW          ; $E54A  97 F5
                 RTS                          ; $E54C  39

; --- bullet_move: move player bullet up one screen row ---
L_E54D           LDX     ZP_BULLET_POS        ; $E54D  DE E2
                 BNE     L_E554               ; $E54F  26 03
                 JMP     L_E5D9               ; $E551  7E E5 D9
L_E554           JSR     L_E009               ; $E554  BD E0 09
                 CMPA    #$6A                 ; $E557  81 6A
                 BEQ     L_E564               ; $E559  27 09
                 TAB                          ; $E55B  16
                 JSR     L_E492               ; $E55C  BD E4 92
                 BCS     L_E586               ; $E55F  25 25
                 JMP     L_E5D9               ; $E561  7E E5 D9
L_E564           LDAB    #$20                 ; $E564  C6 20
                 JSR     L_E010               ; $E566  BD E0 10
                 JSR     L_E285               ; $E569  BD E2 85
                 JSR     L_E017               ; $E56C  BD E0 17
                 BEQ     L_E5D9               ; $E56F  27 68
                 JSR     L_E5F5               ; $E571  BD E5 F5
                 BCC     L_E57E               ; $E574  24 08
                 JSR     L_E601               ; $E576  BD E6 01
                 JSR     L_E010               ; $E579  BD E0 10
                 BRA     L_E5D9               ; $E57C  20 5B
L_E57E           PSHA                         ; $E57E  36
                 TBA                          ; $E57F  17
                 JSR     L_E492               ; $E580  BD E4 92
                 PULA                         ; $E583  32
                 BCC     L_E5A4               ; $E584  24 1E
L_E586           LDAA    #$69                 ; $E586  86 69
                 JSR     L_E002               ; $E588  BD E0 02
                 SUBB    #$60                 ; $E58B  C0 60
                 LSRB                         ; $E58D  54
                 INCB                         ; $E58E  5C
                 JSR     L_E6B7               ; $E58F  BD E6 B7
                 DEC     $00E6                ; $E592  7A 00 E6
                 BNE     L_E5D9               ; $E595  26 42
                 LDAA    ZP_ALIEN_IDX         ; $E597  96 FC
                 INCA                         ; $E599  4C
                 CMPA    #$09                 ; $E59A  81 09
                 BNE     L_E59F               ; $E59C  26 01
                 CLRA                         ; $E59E  4F
L_E59F           STAA    ZP_ALIEN_IDX         ; $E59F  97 FC
                 JMP     L_E5DF               ; $E5A1  7E E5 DF
L_E5A4           CMPB    #$20                 ; $E5A4  C1 20
                 BNE     L_E5AE               ; $E5A6  26 06
                 JSR     L_E002               ; $E5A8  BD E0 02
                 STX     ZP_BULLET_POS        ; $E5AB  DF E2
                 RTS                          ; $E5AD  39
L_E5AE           PSHA                         ; $E5AE  36
                 TBA                          ; $E5AF  17
                 JSR     L_E408               ; $E5B0  BD E4 08
                 PULA                         ; $E5B3  32
                 BCC     L_E5D4               ; $E5B4  24 1E
                 LDAA    #$69                 ; $E5B6  86 69
                 LDX     ZP_CURSOR_POS        ; $E5B8  DE E4
                 JSR     L_E002               ; $E5BA  BD E0 02
                 INX                          ; $E5BD  08
                 JSR     L_E002               ; $E5BE  BD E0 02
                 INX                          ; $E5C1  08
                 JSR     L_E002               ; $E5C2  BD E0 02
                 LDX     ZP_TUNE_PTR          ; $E5C5  DE EE
                 LDAB    $00,X                ; $E5C7  E6 00
                 ANDB    #$1F                 ; $E5C9  C4 1F
                 INCB                         ; $E5CB  5C
                 JSR     L_E6B7               ; $E5CC  BD E6 B7
                 JSR     VSYNC_STROBE         ; $E5CF  BD F0 DA
                 BRA     L_E5D9               ; $E5D2  20 05
L_E5D4           LDAA    #$20                 ; $E5D4  86 20
                 JSR     L_E002               ; $E5D6  BD E0 02
L_E5D9           LDX     #$0000               ; $E5D9  CE 00 00
                 STX     ZP_BULLET_POS        ; $E5DC  DF E2
                 RTS                          ; $E5DE  39

; --- kill_aliens: scan $8050-$85A0, clear non-negative non-zero chars ---
L_E5DF           LDX     #$8050               ; $E5DF  CE 80 50
                 LDAA    #$20                 ; $E5E2  86 20
L_E5E4           TST     $00,X                ; $E5E4  6D 00
                 BMI     L_E5EC               ; $E5E6  2B 04
                 BEQ     L_E5EC               ; $E5E8  27 02
                 STAA    $00,X                ; $E5EA  A7 00
L_E5EC           INX                          ; $E5EC  08
                 CPX     #$85A0               ; $E5ED  8C 85 A0
                 BNE     L_E5E4               ; $E5F0  26 F2
                 JMP     L_E185               ; $E5F2  7E E1 85

; --- is_col_char: SEC if B in $5B..$5F (column marker chars), else CLC ---
L_E5F5           CMPB    #$5B                 ; $E5F5  C1 5B
                 BLT     L_E5FF               ; $E5F7  2D 06
                 CMPB    #$60                 ; $E5F9  C1 60
                 BGE     L_E5FF               ; $E5FB  2C 02
                 SEC                          ; $E5FD  0D
                 RTS                          ; $E5FE  39

; --- not_col_char: CLC / RTS ---
L_E5FF           CLC                          ; $E5FF  0C
                 RTS                          ; $E600  39

; --- next_col_char: INCB, wrap $60->$20 ---
L_E601           INCB                         ; $E601  5C
                 CMPB    #$60                 ; $E602  C1 60
                 BNE     L_E608               ; $E604  26 02
                 LDAB    #$20                 ; $E606  C6 20
L_E608           RTS                          ; $E608  39

; --- input_handler: read joystick/keyboard, move ship, fire bullet ---
L_E609           LDAA    #$4B                 ; $E609  86 4B
                 JSR     L_E6A4               ; $E60B  BD E6 A4
                 BPL     L_E62D               ; $E60E  2A 1D
                 LDX     ZP_BULLET_POS        ; $E610  DE E2
                 BNE     L_E630               ; $E612  26 1C
                 LDAA    ZP_HIT_FLAG          ; $E614  96 FA
                 BNE     L_E630               ; $E616  26 18
                 LDX     ZP_SHIP_POS          ; $E618  DE E0
                 BEQ     L_E630               ; $E61A  27 14
                 JSR     L_E285               ; $E61C  BD E2 85
                 LDAA    #$6A                 ; $E61F  86 6A
                 JSR     L_E002               ; $E621  BD E0 02
                 STX     ZP_BULLET_POS        ; $E624  DF E2
                 STAA    ZP_HIT_FLAG          ; $E626  97 FA
                 INC     $00FE                ; $E628  7C 00 FE
                 BRA     L_E630               ; $E62B  20 03
L_E62D           CLR     $00FA                ; $E62D  7F 00 FA
L_E630           LDAA    #$09                 ; $E630  86 09
                 BSR     L_E6A4               ; $E632  8D 70
                 BPL     L_E639               ; $E634  2A 03
                 JMP     ROMB_ENTRY           ; $E636  7E E8 00
L_E639           LDAA    #$54                 ; $E639  86 54
                 BSR     L_E6A4               ; $E63B  8D 67
                 BPL     L_E665               ; $E63D  2A 26
                 TST     $00E9                ; $E63F  7D 00 E9
                 BNE     L_E661               ; $E642  26 1D
                 LDX     ZP_SHIP_POS          ; $E644  DE E0
                 BEQ     L_E655               ; $E646  27 0D
                 LDAA    #$20                 ; $E648  86 20
                 JSR     L_E002               ; $E64A  BD E0 02
                 DEX                          ; $E64D  09
                 JSR     L_E009               ; $E64E  BD E0 09
                 BEQ     L_E655               ; $E651  27 02
                 STX     ZP_SHIP_POS          ; $E653  DF E0
L_E655           LDAA    RAM_SHIP_LIVES       ; $E655  B6 01 0A
                 STAA    ZP_FIRE_TMR          ; $E658  97 E9
                 BSR     L_E6AB               ; $E65A  8D 4F
                 STAA    RAM_SHIP_LIVES       ; $E65C  B7 01 0A
                 BRA     L_E69C               ; $E65F  20 3B
L_E661           DEC     $00E9                ; $E661  7A 00 E9
                 RTS                          ; $E664  39
L_E665           LDAA    #$55                 ; $E665  86 55
                 BSR     L_E6A4               ; $E667  8D 3B
                 BMI     L_E674               ; $E669  2B 09
                 CLR     $00E9                ; $E66B  7F 00 E9
                 LDAA    #$14                 ; $E66E  86 14
                 STAA    RAM_SHIP_LIVES       ; $E670  B7 01 0A
                 RTS                          ; $E673  39
L_E674           TST     $00E9                ; $E674  7D 00 E9
                 BEQ     L_E67D               ; $E677  27 04
                 DEC     $00E9                ; $E679  7A 00 E9
                 RTS                          ; $E67C  39
L_E67D           LDAA    RAM_SHIP_LIVES       ; $E67D  B6 01 0A
                 STAA    ZP_FIRE_TMR          ; $E680  97 E9
                 BSR     L_E6AB               ; $E682  8D 27
                 STAA    RAM_SHIP_LIVES       ; $E684  B7 01 0A
                 LDX     ZP_SHIP_POS          ; $E687  DE E0
                 BEQ     L_E693               ; $E689  27 08
                 STAA    HALT                 ; $E68B  B7 70 00
                 NOP                          ; $E68E  01
                 LDAA    $01,X                ; $E68F  A6 01
                 BNE     L_E694               ; $E691  26 01
L_E693           RTS                          ; $E693  39
L_E694           LDAA    #$20                 ; $E694  86 20
                 JSR     L_E002               ; $E696  BD E0 02
                 INX                          ; $E699  08
                 STX     ZP_SHIP_POS          ; $E69A  DF E0
L_E69C           LDX     ZP_SHIP_POS          ; $E69C  DE E0
                 LDAA    #$6C                 ; $E69E  86 6C
                 JSR     L_E002               ; $E6A0  BD E0 02
                 RTS                          ; $E6A3  39

; --- pia_scan: STAA PIA1_DA, LDAA PIA1_DA, RTS (keyboard scan strobe) ---
L_E6A4           STAA    PIA1_DA              ; $E6A4  B7 78 00
                 LDAA    PIA1_DA              ; $E6A7  B6 78 00
                 RTS                          ; $E6AA  39

; --- get_speed: return A=8 or A=5 based on SW_BNK1 bit6 (speed switch) ---
L_E6AB           LDAA    #$08                 ; $E6AB  86 08
                 LDAB    SW_BNK1              ; $E6AD  F6 7E 00
                 BITB    #$40                 ; $E6B0  C5 40
                 BEQ     L_E6B6               ; $E6B2  27 02
                 LDAA    #$05                 ; $E6B4  86 05
L_E6B6           RTS                          ; $E6B6  39

; --- score_inc: increment 5-digit BCD score at $8045 by B, JMP VSYNC_STROBE ---
L_E6B7           LDX     #$8045               ; $E6B7  CE 80 45
L_E6BA           JSR     L_E009               ; $E6BA  BD E0 09
                 INCA                         ; $E6BD  4C
                 CMPA    #$3A                 ; $E6BE  81 3A
                 BEQ     L_E6CB               ; $E6C0  27 09
                 JSR     L_E002               ; $E6C2  BD E0 02
                 DECB                         ; $E6C5  5A
                 BNE     L_E6B7               ; $E6C6  26 EF
                 JMP     VSYNC_STROBE         ; $E6C8  7E F0 DA
L_E6CB           LDAA    #$30                 ; $E6CB  86 30
                 JSR     L_E002               ; $E6CD  BD E0 02
                 DEX                          ; $E6D0  09
                 BRA     L_E6BA               ; $E6D1  20 E7

; --- alien_landed: set ZP_CURSOR_POS=$80AA (bottom row alien reached) ---
L_E6D3           LDX     #$80AA               ; $E6D3  CE 80 AA
                 STX     ZP_CURSOR_POS        ; $E6D6  DF E4
                 JMP     L_E3EC               ; $E6D8  7E E3 EC

; --- music_tick: advance tune ptr, extract note, output to screen region ---
L_E6DB           LDAA    ZP_SCORE_TENS        ; $E6DB  96 FE
                 ANDA    #$03                 ; $E6DD  84 03
                 BEQ     L_E720               ; $E6DF  27 3F
                 LDX     ZP_TUNE_PTR          ; $E6E1  DE EE
                 LDAA    $00,X                ; $E6E3  A6 00
                 INX                          ; $E6E5  08
                 BNE     L_E6EB               ; $E6E6  26 03
                 LDX     #ROMB_ENTRY          ; $E6E8  CE E8 00
L_E6EB           STX     ZP_TUNE_PTR          ; $E6EB  DF EE
                 ADDA    #$00                 ; $E6ED  8B 00
                 DAA                          ; $E6EF  19
                 ANDA    #$0F                 ; $E6F0  84 0F
                 INCA                         ; $E6F2  4C
                 STAA    ZP_LOOPCNT           ; $E6F3  97 E7
                 LDX     #$8640               ; $E6F5  CE 86 40
L_E6F8           JSR     L_E009               ; $E6F8  BD E0 09
                 JSR     L_E492               ; $E6FB  BD E4 92
                 BCS     L_E707               ; $E6FE  25 07
                 DEX                          ; $E700  09
                 CPX     #CRTRAM              ; $E701  8C 80 00
                 BNE     L_E6F8               ; $E704  26 F2
                 RTS                          ; $E706  39
L_E707           STX     ZP_TMP_PTR           ; $E707  DF EC
L_E709           LDAB    #$50                 ; $E709  C6 50
                 LDX     ZP_TMP_PTR           ; $E70B  DE EC
L_E70D           JSR     L_E009               ; $E70D  BD E0 09
                 JSR     L_E492               ; $E710  BD E4 92
                 BCC     L_E71A               ; $E713  24 05
                 DEC     $00E7                ; $E715  7A 00 E7
                 BEQ     L_E746               ; $E718  27 2C
L_E71A           DEX                          ; $E71A  09
                 DECB                         ; $E71B  5A
                 BNE     L_E70D               ; $E71C  26 EF
                 BRA     L_E709               ; $E71E  20 E9
L_E720           LDX     ZP_SHIP_POS          ; $E720  DE E0
                 BEQ     L_E728               ; $E722  27 04
                 BSR     L_E734               ; $E724  8D 0E
                 BCC     L_E729               ; $E726  24 01
L_E728           RTS                          ; $E728  39
L_E729           LDX     ZP_SHIP_POS          ; $E729  DE E0
                 DEX                          ; $E72B  09
                 BSR     L_E734               ; $E72C  8D 06
                 BCC     L_E731               ; $E72E  24 01
                 RTS                          ; $E730  39
L_E731           LDX     ZP_SHIP_POS          ; $E731  DE E0
                 INX                          ; $E733  08
L_E734           LDAB    #$14                 ; $E734  C6 14
L_E736           JSR     L_E009               ; $E736  BD E0 09
                 JSR     L_E492               ; $E739  BD E4 92
                 BCS     L_E746               ; $E73C  25 08
                 JSR     L_E285               ; $E73E  BD E2 85
                 DECB                         ; $E741  5A
                 BNE     L_E736               ; $E742  26 F2
                 CLC                          ; $E744  0C
                 RTS                          ; $E745  39
L_E746           LDAA    #$68                 ; $E746  86 68
                 STAA    HALT                 ; $E748  B7 70 00
                 NOP                          ; $E74B  01
                 STAA    $50,X                ; $E74C  A7 50
                 SEC                          ; $E74E  0D
                 RTS                          ; $E74F  39

; --- game_over: blit "GAME OVER", long delay, hi-score check, JMP video_setup ---
L_E750           LDX     #L_E772              ; $E750  CE E7 72
                 STX     ZP_BLIT_SRC          ; $E753  DF B3
                 LDX     #$815C               ; $E755  CE 81 5C
                 STX     ZP_BLIT_DST          ; $E758  DF B1
                 LDAB    #$09                 ; $E75A  C6 09
                 JSR     BLITCPY              ; $E75C  BD F6 BB
                 LDAA    #$0A                 ; $E75F  86 0A
L_E761           LDX     #$0000               ; $E761  CE 00 00
L_E764           DEX                          ; $E764  09
                 BNE     L_E764               ; $E765  26 FD
                 DECA                         ; $E767  4A
                 BNE     L_E761               ; $E768  26 F7
                 PULA                         ; $E76A  32
                 PULA                         ; $E76B  32
                 JSR     L_E7AF               ; $E76C  BD E7 AF
                 JMP     L_E095               ; $E76F  7E E0 95

; --- "GAME OVER" string ---
L_E772           ASC     "GAME OVER"

; --- wait_start: scan $8730 area for RETURN char ($6C), then start game ---
L_E77B           LDX     ZP_SHIP_POS          ; $E77B  DE E0
                 BNE     L_E791               ; $E77D  26 12
                 LDAB    #$50                 ; $E77F  C6 50
                 LDX     #$8730               ; $E781  CE 87 30
L_E784           JSR     L_E009               ; $E784  BD E0 09
                 CMPA    #$6C                 ; $E787  81 6C
                 BEQ     L_E791               ; $E789  27 06
                 INX                          ; $E78B  08
                 DECB                         ; $E78C  5A
                 BNE     L_E784               ; $E78D  26 F5
                 BRA     L_E750               ; $E78F  20 BF
L_E791           STX     ZP_TMP_PTR           ; $E791  DF EC
                 LDX     #CRTRAM              ; $E793  CE 80 00
L_E796           STAA    HALT                 ; $E796  B7 70 00
                 NOP                          ; $E799  01
                 DEX                          ; $E79A  09
                 BNE     L_E796               ; $E79B  26 F9
                 LDX     ZP_TMP_PTR           ; $E79D  DE EC
                 LDAB    #$20                 ; $E79F  C6 20
                 JSR     L_E010               ; $E7A1  BD E0 10
                 LDX     #$869A               ; $E7A4  CE 86 9A
                 STX     ZP_SHIP_POS          ; $E7A7  DF E0
                 LDAA    #$6C                 ; $E7A9  86 6C
                 JSR     L_E002               ; $E7AB  BD E0 02
                 RTS                          ; $E7AE  39

; --- hiscore_chk: compare score at $8042 vs RAM_SCORE_BUF, copy if higher ---
L_E7AF           LDX     #$8042               ; $E7AF  CE 80 42
                 STX     ZP_BLIT_SRC          ; $E7B2  DF B3
                 LDX     #RAM_SCORE_BUF       ; $E7B4  CE 01 04
                 STX     ZP_BLIT_DST          ; $E7B7  DF B1
                 LDAB    #$05                 ; $E7B9  C6 05
                 JSR     BLITCPY              ; $E7BB  BD F6 BB
                 LDAB    #$05                 ; $E7BE  C6 05
                 STAB    ZP_LOOPCNT           ; $E7C0  D7 E7
                 LDX     #$00FF               ; $E7C2  CE 00 FF
L_E7C5           LDAA    $00,X                ; $E7C5  A6 00
                 CMPA    $05,X                ; $E7C7  A1 05
                 BGT     L_E7E5               ; $E7C9  2E 1A
                 BLT     L_E7D5               ; $E7CB  2D 08
                 INX                          ; $E7CD  08
                 DEC     $00E7                ; $E7CE  7A 00 E7
                 BNE     L_E7C5               ; $E7D1  26 F2
                 BRA     L_E7D8               ; $E7D3  20 03
L_E7D5           INC     RAM_HISCORE_FLAG     ; $E7D5  7C 01 09
L_E7D8           LDX     #$00FF               ; $E7D8  CE 00 FF
                 LDAB    #$05                 ; $E7DB  C6 05
L_E7DD           LDAA    $05,X                ; $E7DD  A6 05
                 STAA    $00,X                ; $E7DF  A7 00
                 INX                          ; $E7E1  08
                 DECB                         ; $E7E2  5A
                 BNE     L_E7DD               ; $E7E3  26 F8
L_E7E5           RTS                          ; $E7E5  39

; --- ROM tail padding ---
                 DB      $00,$00,$00,$FF,$FF,$FF,$FF,$FF
                 DB      $FF,$FB,$FF,$FF,$FF,$FF,$FF,$FF
                 DB      $BF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
                 DB      $CF,$FF
