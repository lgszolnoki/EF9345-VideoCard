;==================================================================================================
; EF9345 TEST UTILITY - ROMWBW SPECIFIC
;==================================================================================================
;
#DEFINE USEDELAY
#DEFINE DEBUG
;
BDOS	.EQU	5
;
SETREG	.EQU	$44
;DATAACC	.EQU	$46
DATAACC	.EQU	$45
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
OCT		.EQU	$34		;
KRF		.EQU	$01		; autoincrement
;
IND_TGS		.EQU	$81
IND_MAT		.EQU	$82
IND_PAT		.EQU	$83
IND_DOR		.EQU	$84
IND_ROR		.EQU	$87
RDREG	.EQU	00001000b
WRREG	.EQU    ~RDREG


logox	.EQU	38
logoy	.EQU 	8
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
#DEFINE	PRTC(C)	CALL PRTCH \ .DB C		; PRINT CHARACTER C TO CONSOLE - PRTC('X')
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
	call PRTSTRD
	.db	"EF9345 test program 40 x 24(2)5\r\n$"
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
;	TGS(7:6) = 00 : 40 char/row mode, long char code (3 bytes)
;
	ld b,R1
	ld c,00000000b				; TSG value to R1
	call writwa

	ld b,R0 + EXEC
	ld c,IND_TGS			; IND cmd to load TGS (r=1)
	call outreg
;
; MAT Register initialization
; MAT (2:0) = 100 : Margin color = blue
; MAT3 = 1 : I Signal is high during margin period
; MAT(5:4) : 00 = fixed complement cursor
; MAT6 = 1 : cusor display enabled
; MAT7 = 0 : no zoom mode
;
	ld b,R1
	ld c,01001100b		; load value into R1
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
; PAT7 = 0 : 40 char/row mode, long code
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
; DOR(3:0) = 0011 : alpha UDS slices in block 3
; DOR(6:4) = 001 : semigraphic uds slices in block 2 and 3
; DOR 7 = 0 : Quadrichrome slices from block 0
;
	ld b,R1
	ld c,00010011b		;$13
	call writwa
	ld b,R0+EXEC
	ld c,IND_DOR		; IND cmd to load DOR (r=4)
	call outreg
;
; ROR register initialization
;
; ROR(4:0) = 01000 : origin row = 8
; ROR(7:5) = 000 : displayed page memory starts from block 0
;
	ld b,R1
	ld c,00001000b		;$08			; value to R1
	call writwa
	ld b,R0+EXEC		;
	ld c,IND_ROR		; IND cmd to load ROR (r=7)
	call outreg
;
; Clear page  memory with alphanumeric spaces
; Foreground and background colors = black
;
;	LDA #$20
;	LDX #$0000
mpfill:
	call waitrdy
	ld b,R1				; space char
	ld c,' '			; store char code into R1, R2, R3
	call outreg
	ld b,R2
	ld c,0
	call outreg
	ld b,R3
	ld c,0
	call outreg

	ld b,YP
	ld c,0				; init main pointer to the beginning of the service row : R6 = R7 = 0
	call outreg
	ld b,XP
	ld c,0
	call outreg
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
; Store slices for the 4 characters of the thomson logo
; character code c bytes are $0, $1, $2, $3
;
	ld d,0			; initial code for C bytes
	ld e,3			; block number z(3:0)
	ld hl,car1
;
ET1:
	ld a,d			;
	cp 4			; slices loaded for 4 character?
	jr z,ET2
	call wrslal
	inc d
	jr ET1
ET2:
;
; write the 4 UDS char codes into page memory
; background = black, Foreground = white: A byte = $70
;
	call waitrdy
	ld b,R0
	ld c,KRF
	call outreg
;
	ld b,R7			;init main pointer to column 38 on the first
	ld c,logox
	call outreg
;
	ld b,R6			; row after service ROMWBW
	ld c,logoy
	call outreg
;
	ld b,R2
	ld c,$80		; store char code B byte into R2
	call outreg
;
	ld b,R3			; char code A byte into R3
	ld c,$70
	call outreg
;
	ld c,0			; write upper left char
	ld b,R1+EXEC
	call writwa
;
	inc c			; write upper right char
	ld b,R1+EXEC
	call writwa
;
	ld b,R7			; init main pointer for the 2 lower char
	ld c,logox
	call outreg
;
	ld b,R6
	ld c,logoy+1			; Y = 9
	call outreg
;
	ld c,2			; write lower char
	ld b,R1+EXEC
	call writwa
	inc c
	ld b,R1+EXEC
	call writwa
;
; load the 10 slices for the Quadrichrome character
;
	ld d,$4b		; initial code for C bytes
	ld e,3			; block number z(3:0)
	ld hl,quadri
	call wrslal
;
; write quadrichrome xhar code into page memory
; palette = red-green-blue-white = A byte = 10010110b
; A7 = White
; A6 = Cyan
; A5 = Magenta
; A4 = Blue
; A3 = Yellow
; A2 = Green
; A1 = Red
; A0 = Black
;
; quadrichrome set Q3, high resolution (R=0) : B byte = $D8
; C byte $4b
;
	call waitrdy
	ld b,R7
	ld c,20			; init main pointer x = 20
	call outreg
	ld b,R6
	ld c,20			; y = 20
	call outreg
;
	ld b,R0
	ld c,KRF		; load KRF command
	call outreg
;
	ld b,R1
	ld c,$4b		; load char code C byte into R1
	call outreg
;
	ld b,R2
	ld c,$D8		; load char code B byte into R2
	call outreg
;
	ld b,R3+EXEC
	ld c,10010110b		; load char code A byte into R3
	call outreg
;
loop:
	ld c,11				; BDOS function 11 (C_STAT) - Console status
	call BDOS
	or a
	jr z,loop
ende:
	ld c,0
	call 5
	halt
;
; write 10 UDS slices
; entry : A = 0-0-0-0-Z3-Z2-Z1-Z0
;		: B = 0-C6-C5-C4-C3-C2-C1-C0, where C(0:6) is byte c of character code
;		: HL points to the slice buffer
; exit	: A & B destroyed
;		  HL = HL+10
;		auxiliary poiter is used : bit 2 = p of "BYTE LOAD" command = 1
wrslal:				; A = 03 : block number Z(3:0)
					; B = 00 : initial character code C byte
	push bc
	push de
	ld b,d			; initial character
	ld a,e			; block number Z(3:0)
	call axpnt
	ld b,R0			; store cmd without exec
	ld c,OCT		; byte write cmd
	call outreg
;
	ld d,10 		; loop counter for 10 slices
wrsla1:
	ld c,(hl)
	inc hl
	ld b,R1+EXEC
	call outreg
	call waitrdy
	ld b,R5
	call readreg
	add a,4
	ld c,a
	ld b,R5
	call outreg
	dec d
	jr nz,wrsla1
	pop de
	pop bc
	ret
; axpnt : auxiliary pointer set subroutine
; entry : A = 0-0-0-0-Z3-Z2-Z1-Z0
;		: B = 0-C6-C5-C4-C3-C2-C1-C0, where C(0:6) is byte c of character code
; exit  : R4 = YA = 0-0-Z2-C6-C5-C4-C3-C2
;		: R5 = XA = Z0-Z1_0-0-0-0-C1-C0
; operation : temporary storage
; 			M(0,S) = Z0-Z1-0-0-0-0-0-0
;			M(1,S) = 0-0-Z2-0-0-0-0-0
;			M(2,S) = 0-0-0-0-Z3-Z2-Z1-Z0
;			M(3,S) = 0-C6-C5-C4-C3-C2-C1-C0
;
axpnt:
	call waitrdy
	and a			; clear carry
	rra				; C = Z0, A7=0
	rra				; C = Z1, A7=Z0, A6=0
	rra				; C=Z2, A7=Z1, A6=Z0 A5=0
	rr b			; B7=Z2
	rla				; C = Z1, A7=Z0, A6=0
	rr b			; B7 = Z1, B6 = Z2
	rla				; C=Z0, A7=0
	rr b			; B7 = Z0, B6 = Z1, B5 = Z2
	ld a,b			; A7 = Z0, A6 = Z1, A5 = Z2
	and $c0
;	ld (tbuf),a		; A = Z0-Z1-0-0-0-0-0-0
	ld c,a			; C = Z0-Z1-0-0-0-0-0-0
	ld a,d			; A = 0-C6-C5-C4-C3-C2-C1-C0
	and $03			; A = 0-0-0-0-0-0-C1-C0
	or c			; A = Z0-Z1-0-0-0-0-C1-C0
	ld c,a
	ld a,b			; B7 = Z0, B6 = Z1, B5 = Z2
	and $20			; A = 0-0-Z2-0-0-0-0-0
;	ld (tbuf+1),a
	srl d
	srl d
	or d 			; A = 0-0-Z2-C6-C5-C4-C3-C2
;
	push af
	ld b,R5
	call outreg		; store into R5 = XA
	pop af
	ld c,a			; C = 0-0-Z2-C6-C5-C4-C3-C2
	ld b,R4
	call outreg		; store into R4 = YA

	ld a,e			; restore Z3-Z0 argument
	and 00001000b	; test Z3
	jr z,axpnt0
	ld b,YP			; Z3 = 1 : YP(6)=1
	call readreg
	or $40
	ld c,a
	call outreg
	ret
axpnt0:
	ld b,YP
	call readreg
	and $BF			; Z3=0 : YP(6)=0
	ld c,a
	call outreg
	ret

;
outreg:					; b=register address
						; c=data for register
	ld a,b
	out (SETREG),a		; reg address output -> AS Pulse
	ld a,c
	out (DATAACC),a		; data output -> DS Pulse with WR
	ret
;
readreg:					; read register
	ld a,b
	out (SETREG),a		; reg address output
	in a,(DATAACC)		; read reg data
	ld c,a
	ret
;
waitrdy:
	push af
waitr:
	ld a,R0				; read R0 BUSY bit
	out (SETREG),a
	in a,(DATAACC)
	rla
	jr c,waitr
	pop af
	ret
;
writwa:					; write register with waitrdy
	call waitrdy
	jr outreg
;
; Slice values for UDS characters
;
car1: .db	$20,$38,$3c,$3e,$3f,$3f,$1f,$1f,$0f,$0f
car2: .db	$04,$1c,$3c,$7c,$fc,$fc,$f8,$f8,$f0,$f0
car3: .db	$07,$c7,$e3,$f3,$f9,$fc,$fc,$f8,$e0,$80
car4: .db	$e0,$e3,$c7,$cf,$9f,$3f,$3f,$1f,$07,$01
;
; Slice valuen for Quadrichrome character
;
quadri: .db	00011011b
		.db 11100100b
		.db 10010011b
		.db 01001110b
		.db 00111001b
		.db 00111001b
		.db 10101010b
		.db 01010101b
		.db 11111111b
		.db 00000000b
;
;$9c,$5a,$a3,$6a,$a9,$be,$92,$eb,$29,$86
;
;tbuf	.db 0,0,0,0
;
.nolist
#INCLUDE "util.asm"
.list
;
SAVSTK:		.DW	2
	.FILL	64
STACK:		.EQU	$
;
	.END
