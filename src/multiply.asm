; from http://www.6502.org/source/integers/32muldiv.htm

.dataseg

PROD .db[8]
MULR .db[4]
MULND .db[4]

.public PROD
.public MULR
.public MULND

.codeseg

.public MULTIPLY

MULTIPLY:  lda     #$00
           sta     PROD+4   ;Clear upper half of
           sta     PROD+5   ;product
           sta     PROD+6
           sta     PROD+7
           ldx     #$20     ;Set binary count to 32
@@SHIFT_R: lsr     MULR+3   ;Shift multiplyer right
           ror     MULR+2
           ror     MULR+1
           ror     MULR
           bcc     @@ROTATE_R ;Go rotate right if c = 0
           lda     PROD+4   ;Get upper half of product
           clc              ; and add multiplicand to
           adc     MULND    ; it
           sta     PROD+4
           lda     PROD+5
           adc     MULND+1
           sta     PROD+5
           lda     PROD+6
           adc     MULND+2
           sta     PROD+6
           lda     PROD+7
           adc     MULND+3
@@ROTATE_R: ror     a        ;Rotate partial product
           sta     PROD+7   ; right
           ror     PROD+6
           ror     PROD+5
           ror     PROD+4
           ror     PROD+3
           ror     PROD+2
           ror     PROD+1
           ror     PROD
           dex              ;Decrement bit count and
           bne     @@SHIFT_R  ; loop until 32 bits are
;           clc              ; done
;           lda     MULXP1   ;Add dps and put sum in MULXP2
;           adc     MULXP2
;           sta     MULXP2
           rts

.end
