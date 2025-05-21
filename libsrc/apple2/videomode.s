;
; Oliver Schmidt, 07.09.2009
;
; signed char __fastcall__ videomode (unsigned mode);
;
        .export         _videomode

        .ifndef __APPLE2ENH__
        .import         machinetype
        .endif

        .import         returnFFFF

        .constructor    detect80cols

        .include        "apple2.inc"
        .include        "mli.inc"


VIDEOMODE_40x24 = $15
VIDEOMODE_80x24 = $00

        .data

card_detected:        .byte 0

        .segment        "ONCE"

IdOfsTable:                     ; Table of bytes positions, used to check four
                                ; specific bytes on the slot's firmware to make
                                ; sure this is a serial card.
        .byte   $05             ; Pascal 1.0 ID byte
        .byte   $07             ; Pascal 1.0 ID byte
        .byte   $0B             ; Pascal 1.1 generic signature byte
        .byte   $0C             ; Device signature byte

IdValTable:                     ; Table of expected values for the four checked
                                ; bytes
        .byte   $38             ; ID Byte 0 (from Pascal 1.0), fixed
        .byte   $18             ; ID Byte 1 (from Pascal 1.0), fixed
        .byte   $01             ; Generic signature for Pascal 1.1, fixed
        .byte   $88             ; Device signature byte (80 columns card)

IdTableLen      = * - IdValTable

detect80cols:
        .ifndef __APPLE2ENH__
        lda     machinetype     ; Check we're on a //e at least, otherwise we
        bpl     NoDev           ; handle no 80cols hardware (like Videx)
        .endif

        ldx     #$00
:       ldy     IdOfsTable,x    ; Check Pascal 1.1 Firmware Protocol ID bytes
        lda     IdValTable,x
        cmp     $C300,y
        bne     NoDev
        inx
        cpx     #IdTableLen
        bcc     :-

        dec     card_detected ; We have an 80-columns card! Set flag to $FF

NoDev:  rts

        .segment        "LOWCODE"

_videomode:
        bit     card_detected
        bmi     set_mode

        ; No 80 column card, return error if requested mode is 80cols
        cmp     #VIDEOMODE_40x24
        beq     out
        jmp     returnFFFF
set_mode:

        ; Get and save current videomode flag
        bit     RD80VID
        php

        ; Initializing the 80 column firmware needs the ROM switched
        ; in, otherwise it would copy the F8 ROM to the LC (@ $CEF4)
        bit     $C082

        ; Call 80 column firmware with ctrl-char code
        jsr     $C300

        ; Switch in LC bank 2 for R/O
        bit     $C080

        ; Switch in alternate charset again
        sta     SETALTCHAR

        ; Return ctrl-char code for setting previous
        ; videomode using the saved videomode flag
        lda     #VIDEOMODE_40x24
        plp
        bpl     out
        lda     #VIDEOMODE_80x24
out:    rts                     ; X was preserved all the way
