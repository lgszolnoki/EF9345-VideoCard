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
dataacc	.EQU	$45
;
act_block	.EQU	$20
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
OCT		.EQU	$34		;
KRL		.EQU	$51		; with autoincrement
KRF		.EQU	$01		; with autoincrement
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
	.db	"\n\rEF9345 test program ELO-PRAXIS\n\r$"
;
start:
	ld b,R0 + EXEC		; dummy cmd
	ld c,NOP			;0
	call writwa
;
;	TGS Register initialization
;
;	TGS0 = 0 : 625 lines (50Hz)
;	TGS1 = 0 : not interlaced
;	TGS2 = 0 : horizontal resync. disabled
;	TGS3 = 0 : vertical resync. disabled
;	TGS4 = 0 : horizontal sync. on HVS/HS pin and vertical sync on PC/VS pin
;	TGS5 = 0 : service row y = 0
;	TGS(7:6) = 00 : 40 char/row mode, long char code (3 bytes)
;
	ld b,R1				; dann dataregister belegen
	ld c,00000000b		; csync, 625 lines/ 40Z
	call writwa
	ld b,R0 + EXEC		; cmd ausgeben
	ld c,IND_TGS		; IND cmd to load TGS register
	call outreg
;
; MAT Register initialization
;
; MAT (2:0) = 011 : Margin color = yellow
; MAT3 = 1 : margin insert, I Signal is high during margin period
; MAT(5:4) : 10 = fixed underlined cursor
; MAT6 = 1 : cusor display enabled
; MAT7 = 0 : no zoom mode
;
	ld b,R1				;
	ld c,01010011b		; $48			; background gelb, cursor ein
	call writwa
	ld b,R0 + EXEC		; $28
	ld c,IND_MAT		; IND cmd to load MAT register
	call outreg
;
; PAT register initialization
;
; PAT0 = 1 : service row enabled
; PAT1 = 1 : upper bulk enabled
; PAT2 = 1 : lower buld enabled
; PAT3 = 1 : conceal enabled
; PAT(5:4) = 11 : insert mode, I signal is high during the active displayed area
; PAT6 = 1 : flashing enabled
; PAT7 = 0 : 40 char/row mode, long code
;
	ld b,R1				;
	ld c,01111111b		; $7F			; all enable
	call writwa
	ld b,R0 + EXEC		; CMD
	ld c,IND_PAT		; IND cmd to load PAT register
	call outreg
;
; DOR register initialization
;
; DOR(3:0) = 0000 : alpha UDS slices in block 0
; DOR(6:4) = 010 : semigraphic in block 2
; DOR 7 = 1 : Quadrichrome = obere Speicherhälfte
;
	ld b,R1				; Datenregister
	ld c,10100000b		; $A0			; laden
	call writwa
	ld b,R0 + EXEC		; und ausgeben
	ld c,IND_DOR
	call outreg			; IND cmd to load DOR register
;
; ROR register initialization
;
; ROR(4:0) = 01000 : origin row = 8
; ROR(7:5) = 000 : displayed page memory starts from block 0
;
	ld b,R1				; Datenregister
	ld c,00001000b		; Start  = 8, Block = 0
	call writwa			; row von 8 bis 31
	ld b,R0 + EXEC
	ld c,IND_ROR		; IND cmd to load ROR register
	call outreg
;
	ld b,YP				; y=8 erste Zeile
	ld c,8
	call writwa
	ld b,XP				; x=0
	ld c,0
	call writwa
;
;	Bildschirm löschen + Statuszeile
	call clearscreen
;
; statuszeile laden
;
	ld b,YP				; $26
	ld c,0				; y=0 Start statuszeile
	call writwa
	ld b,XP				; $27
	ld c,0				; x=0
	call writwa
	ld b,R1				; $21
	ld c,' '			; blank
	call writwa
	ld b,R2				; $22
	ld c,0				; keine Attribute
	call writwa
	ld b,R3				; $23
	ld c,00010110b		; $16			; fg=rot, bg=gruen + blau
	call writwa
;
	ld hl,hallo
;	nur noch Datenwert ändern
lpp:
	ld a,(hl)
	or a
	jr z, fina
	ld b,R1				; $21
	ld c,a
	call writwa
	ld b,R0 + EXEC		; $28
	ld c,1				; autoinc
	call writwa
	inc hl
	jr lpp
;
fina:
; Ende Statuszeileschreiben
; Datenzeilen schreiben
	ld b,YP			; $26
	ld c,8			; y=8 start Textzeile
	call writwa
	ld b,XP			; $27
	ld c,0			; x = 0
	call writwa
	ld b,R1			; $21
	ld c,' '		; Leerzeichen
	call writwa
	ld b,R2			; $22
	ld c,0			; keine Attribute, STD-Satz
	call writwa
;
	ld d,0			; Vordergrundfarbe ändern
	ld b,16			; und invers bit bei 9..16
L3:
	push bc
	push de

	ld a,d
	or 2			; Hintergrundgrün
	ld c,a
	ld b,R3
	call writwa
;
	ld hl,data
;
lpa:
	ld a,(hl)
	or a
	jr z, fina1
	ld c,a
	ld b,R1
	call writwa
	ld b,R0+EXEC
	ld c,1			; inc = 1
	call writwa
	inc hl
	jr lpa
;
fina1:
;	y-increment Befehl
	ld b,R0+EXEC
	ld c,$b0
	call writwa
	ld b,XP
	ld c,0
	call writwa		; x = auf 0 anschließend
;
	pop de
	ld a,d
	add a,$10		; Vordergrundfarbe
	ld d,a
	pop bc
	dec b
	jr nz,L3
;
; Spezialzeichen auch ausgeben
; eingebauter Zeichengenerator
;
	ld b,YP
	ld c,25
	call writwa
	ld b,XP
	ld c,0
	call writwa		; Koordinaten eingestellt
;
	ld b,R2
	ld c,' '
	call writwa
;
	ld l,0			; Startwert
	ld d,6
L4:
	ld e,40
L5:
	ld b,R1
	ld c,l			; Datencode eingeben
	call writwa
	ld a,l
	rlca
	rlca
	rlca
	and $78
	or 2			; grün als BK
	ld c,a
	ld b,R3			; Farbcode
	call writwa
	ld b,R0+EXEC
	ld c,1			; schreiben
	call writwa
	inc l
	dec e
	jr nz,L5
					; y-increment Befehl
	ld b,R0+EXEC
	ld c,$b0
	call writwa
	ld b,XP
	ld c,0
	call writwa		; x auf 0 anschließend
;
	dec d
	jr nz,L4
;
; Scroll durchführen
; immer schneller werden
;
	ld d,8			; scroll offset 8..31
L6:
	ld b,R1
	ld c,d
	call writwa
	ld b,R0+EXEC
	ld c,IND_ROR
	call writwa
	push de
	call LDELAY
	pop de
	inc d
	ld a,d
	cp 32
	jr nz,L6

; Quadrichrome test, programierbare Zeichen
; Zeichensatz Code 0..3, 32..129
; sind erlaubt pro Set
	ld b,R4				; Z2, C6-C2
	ld c,0				; LSB Zähler
	call writwa
	ld b,R5				; Z0/Z1, NT, C1/C0
	ld c,0				; lsb Zähler
	call writwa
	ld b,R6				; z3
	ld c,$40			; obere Speicherhälfte
	call writwa
;
fill:
	ld hl,chartab		; Tabelle Basisadresse
	ld e,0				; char 0..3
	ld c,charnr			; hier max. 4 Zeichen
;
L10:
	ld d,0				; slice auf 0
	ld b,10
;
L11:
	ld a,d
	rlca
	rlca
	and 00111100b		; slice
	or e				; 0, 1, 2, 3, C1/C0
	inc d
	push bc
	ld b,R5
	ld c,a				; ausgeben
	call writwa			; an Pointer
	ld b,R1
	ld c,(hl)
	inc hl
	call writwa
	ld b,R0+EXEC
	ld c,$34			; aux Poiter write
	call writwa
	pop bc
	dec b
	jr nz,L11
	inc e
	dec c
	jr nz,L10
;
; jetzt Zeichen noch einschreiben
	ld b,YP
	ld c,10				; y=10 start Datenreihe
	call writwa
	ld b,XP
	ld c,19				; x=19 etwa in der Mitte
	call writwa
	ld b,R2
	ld c,11000000b		; Quadrichrome Satz 0
	call writwa
	ld b,R3
	ld c,11010010b		; Farbsatz white, cyan, blue, red
	call writwa
	ld c,0
	ld d,charnr
;
L12:
	ld b,R1				; Code ausgeben
	push bc				;0,1,2,3 ausgeben als Zeichen
	call writwa
	ld b,R0+EXEC
	ld c,1				; write Command
	call writwa			; mit autoincrement
	pop bc
	inc c
	dec d
	jr nz,L12
; Programmende zurück zu CP/M
ende:
	ld c,11				; BDOS function 11 (C_STAT) - Console status
	call BDOS
	or a
	jr z,ende
	ld c,1
	call BDOS
	cp 'q'
	jp nz,start
	ld c,0
	call BDOS
	halt
;
charnr	.EQU	4
chartab:				; Zeichen für programierbaren Generator
						; Quadrichrome Mode

	.db 00000000b
	.db 00111100b
	.db 11000011b
	.db 11000011b
	.db 11000011b
	.db 11111111b
	.db 11000011b
	.db 11000011b
	.db 00111100b
	.db 00000000b

	.DB	00000000b
	.DB	11111100b
	.DB 11111100b
	.DB 01011100b
	.DB 11111100b
	.DB 11111100b
	.DB 01011100b
	.DB 11111100b
	.DB 11111100b
	.DB 00000000b

	.DB 00000000b
	.DB 11111111b
	.DB 01010111b
	.DB 11110101b
	.DB 11110110b
	.DB 11110110b
	.DB 11110101b
	.DB 01010111b
	.DB 11111111b
	.DB 00000000b

	.DB 00001100b
	.DB 11111111b
	.DB 11111101b
	.DB 11111101b
	.DB 01010101b
	.DB 11111101b
	.DB 11111101b
	.DB 11111101b
	.DB 11111111b
	.DB 00000000b

	.DB 00000000b
	.DB 00111111b
	.DB 00111111b
	.DB 00111111b
	.DB 00110101b
	.DB 00111111b
	.DB 00111111b
	.DB 00111111b
	.DB 00111111b
	.DB 00000000b


;
hallo: .DB "Hallo Test EF9345 - Statuszeile",0
data:  .DB "der EF9345 kann 8 Farben darstellen",0
.nolist
#INCLUDE "util.asm"
.list
;
clearscreen:
	ld l,0				; alles löschen
	ld e,32				; std erst bei 0 beginnen
L1:
	ld b,YP				; c=0=Statuszeile
	ld c,l				; y=8 start row
	call outreg
	ld b,XP				; x-Position
	ld c,0				; x=0
	call outreg
	ld b,R1				; Wort 1 daten laden
	ld c,' '			; blank ASCII code
	call outreg
	ld b,R2				; wort 2
	ld c,0				; keine Attribute
	call outreg
	ld b,R3				; wort 3
	ld c,$12			; fg=rot bg=gruen
	call outreg
;
	ld d,40
L2:
	ld b,R0+EXEC		; $28
	ld c,1				; wrt 3, autoinc
	call writwa
;
	dec d
	jr nz,L2
;
	inc l
	dec e
	jr nz,L1
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
;
merker		.DW 0
SAVSTK:		.DW	2
	.FILL	64
STACK:		.EQU	$
;
	.END
;
;
;
