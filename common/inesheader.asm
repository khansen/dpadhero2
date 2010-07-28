.codeseg
.ifndef PRG_BANK_COUNT
.error "Please define number of 16K PRG banks (PRG_BANK_COUNT)"
.endif
.ifndef CHR_BANK_COUNT
.error "Please define number of 8K CHR banks (CHR_BANK_COUNT)"
.endif
.db 'N','E','S',$1A
.db 16K_PRG_COUNT
.db 8K_CHR_COUNT
.db 0,0,0,0,0,0,0,0,0,0
.end
