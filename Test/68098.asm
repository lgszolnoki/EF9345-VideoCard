;==================================================================================================
; EF9345 TEST UTILITY - ROMWBW SPECIFIC
;==================================================================================================
;
#DEFINE USEDELAY
#DEFINE DEBUG
;
BDOS	.EQU	5
;
setreg	.EQU	$44
;dataacc	.EQU	$46
dataacc	.EQU	$45;
district1	.EQU	$20
;
ROWS	.EQU 	24
;
R0		.EQU	$20
R1		.EQU	R0+1
R2		.EQU	R0+2
R3		.EQU	R0+3
R4		.EQU	R0+4
R5		.EQU	R0+5
R6		.EQU	R0+6
R7		.EQU	R0+7
;
XA		.EQU	R5
YA		.EQU	R4
XP		.EQU	R7
YP		.EQU	R6
;
EXEC	.EQU	00001000b
BUSY	.EQU	10000000b
;
; CMD
;
NOP		.EQU	$91		;
IND		.EQU	$81		;
CLF		.EQU	$05		;
OCT		.EQU	$34
KRL		.EQU	$51
;
IND_TGS		.EQU	$81
IND_MAT		.EQU	$82
IND_PAT		.EQU	$83
IND_DOR		.EQU	$84
IND_ROR		.EQU	$87
RDREG	.EQU	00001000b
WRREG	.EQU    ~RDREG
;
; | 1 | 0 | 0| 0| R/!W | r | r | r |   IND command
;                        0   0   1     TGS
;                        0   1   0     MAT
;                        0   1   1     PAT
;                        1   0   0     DOR
;                        1   0   1
;                        1   1   0
;                        1   1   1     ROR
;
;==================================================================================================
; HELPER MACROS AND EQUATES
;==================================================================================================
;
FALSE		.EQU	0
TRUE		.EQU	~FALSE
BDOS		.EQU	5
;
#DEFINE	PRTC(C)	CALL PRTCH \ .DB C	; PRINT CHARACTER C TO CONSOLE - PRTC('X')
#DEFINE	PRTS(S)	CALL PRTSTRD \ .TEXT S	; PRINT STRING S TO CONSOLE - PRTD("HELLO")
#DEFINE	PRTX(X) CALL PRTSTRI \ .DW X	; PRINT STRING AT ADDRESS X TO CONSOLE - PRTI(STR_HELLO)
;
;==================================================================================================
; MAIN EF9345 TEST ROUTINE
;==================================================================================================
;
	.ORG	$0100
;
	LD	(SAVSTK),SP		; SETUP LOCAL
	LD	SP,STACK		; STACK
;
	call	PRTSTRD		; WELCOME
	.db	"EF9345 video card test program 80 x 25(24)\n\r$"
;
; APP NOTE
;
	ld b,R0+EXEC
	ld c,NOP
	call outreg
;
;	TGS Register initialization
;	TGS0 = 0 : 625 lines (50Hz)
;	TGS1 = 0 : not interlaced
;	TGS2 = 0 : horizontal resync. disabled
;	TGS3 = 0 : vertical resync. disabled
;	TGS4 = 0 : horizontal sync. on HVS/HS pin and vertical sync on PC/VS pin
;	TGS5 = 0 : service row y = 0
;	TGS(7:6) = 11 : 80 char/row mode, long char code (12 bit)
;
	ld b,R1
	ld c,11000000b				; TSG value to R1  INTERLACED BECAUSE MY MONITOR OTHERWISE DO NOT SYNC
	call writwa

	ld b,R0 + EXEC
	ld c,IND_TGS			; IND cmd to load TGS (r=1)
	call outreg
;
; MAT Register initialization
; MAT (2:0) = 000 : Margin color = black, 100 : Margin color = blue
; MAT3 = 1 : I Signal is high during margin period
; MAT(5:4) : 00 = fixed complemented cursor
; MAT6 = 1 : cusor display enabled
; MAT7 = 0 : no double height
;
	ld b,R1
	ld c,01001100b			; load value into R1
	call writwa

	ld b,R0+EXEC
	ld c,IND_MAT		; IND cmd to load MAT (r=2)
	call outreg
;
; PAT register initialization
;
; PAT0 = 1 : service row enabled
; PAT1 = 1 : upper bulk enabled
; PAT2 = 1 : lower buld enabled
; PAT3 = 1 : conceal enabled
; PAT(5:4) = 11 : I signal is high during the active displayed area
; PAT6 = 1 : flashing enabled
; PAT7 = 0 : 80 char/row mode, long code
;
	ld b,R1
	ld c,01111111b		; load into R1
	call writwa

	ld b,R0+EXEC
	ld c,IND_PAT		; IND cmd to load PAT (r=3)
	call outreg
;
; DOR register initialization
;
; DOR(3:0) = 1111   : color c0 = white
; DOR(7:4) = 1000 : color c1 = black
;
	ld b,R1
	ld c,10001111b
	call writwa

	ld b,R0+EXEC
	ld c,IND_DOR		; IND cmd to load DOR (r=4)
	call outreg
;
; ROR register initialization
;
; ROR(4:0) = 01000 : origin row = 8
;
; +-Block origin-+----- YOR 8 to 31 ------+
; | Z3 | Z1 | Z2 |    |    |    |    |    |
; +--------------+------------------------+
; ROR(7:5) =   000  : displayed page memory starts from block 0
;
	ld b,R1
	ld c,00001000b + district1	; value to R1
	call writwa

	ld b,R0+EXEC		;
	ld c,IND_ROR		; IND cmd to load ROR (r=7)
	call outreg
;
mpfill:
; lda #$20
; ldx #$2000
; ldb #4
;
	call waitrdy
	ld b,R1				; space char
	ld c,' '			; store char code into R1, R2, R3
	call writwa
	ld b,R2				; no attributes, std char set
	ld c,' '
	call outreg
	ld b,R3
	ld c,0				;
	call outreg
;
	ld c,0				; R6
	call set_yp
	ld b,XP				; R7
	ld c,0
	call outreg
;
	ld b,R0+EXEC
	ld c,CLF			; load and execute CLF command
	call outreg
;
	call LDELAY
;
	ld b,R0+EXEC		; execute NOP to abort CLF
	ld c,NOP
	call outreg
;
; write "ABCD..." with flash and negative attributes
; attribute bits (D,N)=01
;
	call waitrdy
	ld b,R0
	ld c,KRL
	call writwa
;
	ld b,R3
	ld c,0				; load attribute nibble (repeated into R3)
	call outreg
;
	ld c,0
	call set_yp
;
	ld b,XP
	ld c,0
	call outreg
;
	ld c,'.'
	ld d,80				; 80 character row

status:
	ld b,R1+EXEC
	call outreg
	call waitrdy
	dec d
	jr nz,status
;
#IFDEF DEBUG
	call LDELAY
#ENDIF
;
	ld c,8
	call set_yp
;
	ld b,XP
	ld c,0
	call outreg
;
	ld c,1				; first character
	ld d,80				; 80 char/row
	ld e,ROWS				; no. of rows

loop:
	ld b,R1+EXEC
	call outreg
	inc c
	call waitrdy
	dec d
	jr nz,loop
	push bc
	ld d,80
	ld b,YP
	call readreg
	inc c
	call outreg
	ld b,XP
	ld c,0
	call outreg
	dec e
	pop bc
#IFDEF DEBUG
	call LDELAY
#ENDIF
	jr nz,loop
;
	call waitrdy
	ld b,YP				; init main pointer with service row
	ld c,8 + district1				; district 0, row 8
	call outreg
;
	ld b,XP
	ld c,0
	call outreg
;
	ld d,80
	ld e,ROWS
	ld c,' '
clearscreen:
	ld b,R1+EXEC
	call outreg
	call waitrdy
	dec d
	jr nz,clearscreen
	push bc
	ld d,80
	ld b,YP
	call readreg
	inc c
	call outreg
	ld b,XP
	ld c,0
	call outreg
	dec e
	pop bc
	jr nz,clearscreen
;
#IFDEF DEBUG
	call LDELAY
#ENDIF
;
; write "KLM..." character with underlining
; (D,N) = (0,0) : background color = CM
;				  Foreground color = C0
;
	call waitrdy
	ld c,15
	call set_yp
	ld b,XP
	ld c,10
	call outreg
	ld b,R3
	ld c,$22		; attribute nibble into R3
	call outreg
;
	ld l,'0'				; first character
	ld d,20				; 80 char/row
	ld e,10				; no. of rows
;
loop1:
	ld c,l
loop2;
	ld b,R1+EXEC
	call outreg
	inc c
	call waitrdy
	dec d
	jr nz,loop2
;	push bc
	ld d,20
	ld b,YP
	call readreg
	inc c
	call outreg
	ld b,XP
	ld c,10
	call outreg
	inc l
	dec e
;	pop bc
#IFDEF DEBUG
	call LDELAY
#ENDIF
	jr nz,loop1
;
#IFDEF DEBUG
	call LDELAY
#ENDIF
;
; roll-up operation example
;
	call waitrdy
;
	ld c,IND_ROR | RDREG		; execute "IND" command to read ROR register
	ld b, R0+EXEC
	call outreg
	call waitrdy				; command executed ?
	ld b,R1
	call readreg				; read result from R1
	push bc
	ld c,IND_ROR
	ld b,R0
	call outreg
	pop bc
;
loop3:
	ld b,R1+EXEC
	call waitrdy
	call outreg
	call LDELAY					; ca. 0.5 sec
	inc c
	push bc
	ld a,c
	and $1f
	cp 31
	pop bc
	jr nz,loop3
;
;	roll-down
;
loop4:
	ld b,R1+EXEC
	call waitrdy
	call outreg
	call LDELAY					; ca. 0.5 sec
	dec c
	push bc
	ld a,c
	and $1f
	cp 8
	pop bc
	jr nz,loop4
;
	ld b,R1+EXEC
	call waitrdy
	call outreg
;
	call LDELAY
	push bc
	ld c,11				; BDOS function 11 (C_STAT) - Console status
	call BDOS
	or a
	jp nz,0
	pop bc
	jr loop3
;
ende:
;
; c to YOR
set_yp:
	push bc
	call waitrdy
;
	ld b,IND_ROR | RDREG		; execute "IND" command to read ROR register
	ld c, R0+EXEC
	call outreg
	call waitrdy				; command executed ?
	ld b,R1
	call readreg				; read result from R1
	and 11100000b
	pop bc
	add a,c
	ld c,a
	ld b,YP
	call outreg
	ret
;
outreg:					; b=register address
						; c=data for register
	ld a,b
	out (setreg),a		; reg address output -> AS Pulse
	ld a,c
	out (dataacc),a		; data output -> DS Pulse with WR
	ret
;
readreg:					; read register
	ld a,b
	out (setreg),a		; reg address output
	in a,(dataacc)		; read reg data
	ld c,a
	ret
;
waitrdy:
	ld a,R0				; read R0 BUSY bit
	out (setreg),a
	in a,(dataacc)
	rla
	jr c,waitrdy
	ret
;
writwa:					; write register with waitrdy
	call waitrdy
	jr outreg
;
.nolist
#INCLUDE "util.asm"
;
SAVSTK:		.DW	2
	.FILL	64
STACK:		.EQU	$
;
	.END
