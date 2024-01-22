;======================================================================
;	EF9345 DRIVER FOR ROMWBW
;
;	PARTS WRITTEN BY: ALAN COX
;	REVISED/ENHANCED BY LASZLO SZOLNOKI -- 01/2024
;======================================================================
; TODO:
;	- 40X24 IMPLEMENTATION
;======================================================================
; EF9345 DRIVER - CONSTANTS
;======================================================================
;
TERMENABLE		.SET	TRUE      ;TRUE		; INCLUDE TERMINAL PSEUDODEVICE DRIVER
;
EF9345_BASE	.EQU	$40
SETREG		.EQU	EF9345_BASE + 4
DATAACC		.EQU	EF9345_BASE + 5
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
;BUSY	.EQU	10000000b
;
TGSREG	 	.EQU 	1
MATREG		.EQU	2
PATREG		.EQU	3
DORREG		.EQU	4
RORREG		.EQU	7
;WRTINDIR	.EQU 10000000b
;
; CMD
;
NOP		.EQU	$91		;
IND		.EQU	$80		;
CLF		.EQU	$05		;
OCT		.EQU	$30		;
OCTAUX	.EQU	$04		; AUXILIARY POITER
KRF		.EQU	$01		; autoincrement
KRL		.EQU	$50		; no autoincrement.
INY		.EQU	$B0		; INC Y
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
FALSE		.EQU	0
TRUE		.EQU	~FALSE
BDOS		.EQU	5
;						MAT5	MAT4
; fixed complemented	  0		  0
; flash complemented	  1		  0
; fixed underlined		  0		  1
; flash underlined		  1		  1
;
EF9345_NOCU	.EQU	10111111B	; MAT6 = 0 : NO CURSOR
EF9345_BLK	.EQU	00100000B	; MAT5 = 1 : BLINK CURSOR
EF9345_NOBL	.EQU	11011111B	; MAT5 = 0 : NO BLINK
;
EF9345_BLOK	.EQU	11101111b	; MAT4 = 0 : BLOCK CURSOR
EF9345_ULIN	.EQU	00010000b	; MAT4 = 1 : UNDERLINE CURSOR
;
EF9345_CSTY	.EQU	EF9345_BLOK	; DEFAULT CURSOR STYLE
EF9345_BLNK	.EQU	EF9345_NOBL	; DEFAULT BLINK RATE
;
;
EF9345_CURENA	.EQU	TRUE			; ENABLE CURSOR
EF9345_CURREV	.EQU	TRUE			; REVERSE BLOCK CURSOR
EF9345_CURBLI	.EQU	FALSE			; BLINKING CURSOR
EF9345_CURUDL	.EQU	~EF9345_CURREV	; UNDERLINED CURSOR
;
EF9345_MARCOL	.EQU	00000000B		; MARGIN COLOR BLACK : MAT0 = R, MAT1 = G, MAT2 = B
EF9345_MARENA	.EQU	00001000B		; MARGIN INSERT : MAT3 = 1
;
EF9345_CUREN	.EQU	01000000B	; MAT6 = 1 : CURSOR ENABLED
EF9345_DISCU	.EQU	10111111B	; MAT6 = 0 : NO CURSOR
;
EF9345_FLASH	.EQU	00100000B	; MAT5 = 1 : BLINK CURSOR
EF9345_NOFLASH	.EQU	11011111B	; MAT5 = 0 : NO BLINK
;
EF9345_COMPL	.EQU	11101111b	; MAT4 = 0 : BLOCK CURSOR
EF9345_ULIN		.EQU	00010000b	; MAT4 = 1 : UNDERLINE CURSOR
;
#IF EF9345_CURENA
EF9345_CSTY	.EQU	EF9345_CUREN + EF9345_MARENA + EF9345_MARCOL
#ELSE
EF9345_CSTY	.EQU	EF9345_MARENA + EF9345_MARCOL
#ENDIF
;
#IF EF9345_CURREV
EF9345_CSTY	.EQU EF9345_CSTY & EF9345_COMPL	;  + DEFAULT CURSOR STYLE
#ENDIF
;
#IF EF9345_CURUDL
EF9345_CSTY	.EQU EF9345_CSTY | EF9345_ULIN	;  + DEFAULT CURSOR STYLE
#ENDIF
;
#IF EF9345_CURBLI
EF9345_CSTY	.EQU EF9345_CSTY | EF9345_FLASH	;  + DEFAULT CURSOR STYLE
#ELSE
EF9345_CSTY	.EQU EF9345_CSTY & EF9345_NOFLASH	;  + DEFAULT CURSOR STYLE
#ENDIF
;
FIRSTLINE	.EQU	8
;
#IF (EF9345SIZE=V80X24)			; V80X24
DLINES		.EQU	24
DROWS		.EQU	80
DSCANL		.EQU	10
; ATTRIBUTES
EF_FLASH		.EQU	01000100B
EF_NEGATIVE		.EQU	10001000B
EF_UNDERLINE	.EQU	00100010B
EF_COLORSET		.EQU	00010001B
#ENDIF
;
#IF (EF9345SIZE=V40X24)
DLINES		.EQU	24
DROWS		.EQU	40
DSCANL		.EQU	10
#ENDIF
;
; DISTRICTS
;
DIST0 	.EQU 	0
DIST1 	.EQU 	$20
DIST2 	.EQU 	$80
DIST3 	.EQU 	$A0
;
SCREENSIZE	.EQU	DROWS * DLINES
;
;EF_IDAT		.EQU	0			; NO INSTANCE DATA ASSOCIATED WITH THIS DEVICE
;
;======================================================================
; VDU DRIVER - INITIALIZATION
;======================================================================
;
EF_INIT:
;
	LD IY,EF_IDAT			; POITER TO INSTANCE DATA
;
	CALL	NEWLINE			; FORMATTING
	PRTS("EF9345 : IO=0x$")
	LD	A,EF9345_BASE
	CALL	PRTHEXBYTE

	PRTS(" MODE=$")			; OUTPUT DISPLAY FORMAT
	LD	A,DROWS
	CALL	PRTDECB
	PRTS("X$")
	LD	A,DLINES
	CALL	PRTDECB

	CALL EF_PROBE		; CHECK FOR HW EXISTENCE
	JR	Z,EF_INIT1		; CONTINUE IF HW PRESENT
;
	PRTS(" NOT PRESENT$")
	XOR A
	OR	-8				; HARDWARE NOT PRESENT
	RET
;
EF_INIT1:
	LD A,DIST0
	LD (CON_BANKY),A		;
	LD DE,0
	LD (VDA_OFFSET),DE
	CALL 	EF_CRTINIT		; INIT EF9345 CHIP
	CALL	EF_VDARES		; SOFT RESET
;
;	LD HL,0			; NO FONT BITMAP IMPLEMENTED
;
; ADD OURSELVES TO VDA DISPATCH TABLE
	LD	BC,EF_FNTBL		; BC := FUNCTION TABLE ADDRESS
 	LD	DE,EF_IDAT		; DE := VDU INSTANCE DATA PTR
	CALL VDA_ADDENT		; ADD ENTRY, A := UNIT ASSIGNED
;
#IF TERMENABLE
	; INITIALIZE EMULATION
	LD	C,A				; ASSIGNED VIDEO UNIT IN C
	LD	DE,EF_FNTBL		; DE := FUNCTION TABLE ADDRESS
	LD	HL,EF_IDAT		; HL := VDU INSTANCE DATA PTR
	CALL TERM_ATTACH	; DO IT
#ENDIF
;
	XOR	A			; SIGNAL SUCCESS
	RET
;
EF_CRTINIT:
	LD DE,(R0+EXEC)*256 + NOP	; FORCE NOP
	CALL EF_WWRREG
;
	LD HL,EF_INIT9345			; INITIAL SETUP PARAMETERS
	CALL EF_LOAD_MODE
	LD A,(MAT)
	LD (VDA_ATTR),A
;
	CALL EF_CLEARALL
	LD DE,0						; SET CURSOR TO 0,0
	CALL EF_VDASCP
	RET
;
EF_CLEARALL:
	LD DE,0			; SET CURSOR 0,0
	CALL EF_VDASCP	; D = ROW, E = COLUMNS
	LD HL, DROWS * DLINES
;
	LD E,' '
	CALL EF_VDAFIL
	XOR A
	RET
;
#IF (EF9345SIZE=V80X24)
EF_KRL80:
	PUSH DE
	LD DE,R0*256 + KRL		; R0 KRL COMMAND
	CALL EF_WWRREG
	LD D,R3
	LD A,(VDASAT_ATTR)
	LD E,A
	CALL EF_WWRREG
	POP DE
	RET
#ENDIF
;
;----------------------------------------------------------------------
; PROBE FOR EF9345 HARDWARE
;----------------------------------------------------------------------
;
; ON RETURN, ZF SET INDICATES HARDWARE FOUND
;
EF_PROBE:
	LD DE,R1*256+'a'
	LD H,E
	CALL EF_WRREG
	CALL EF_RDREG
	CP H
	RET
;
;----------------------------------------------------------------------
; WAIT FOR VDU TO BE READY FOR A DATA READ/WRITE
;----------------------------------------------------------------------
;
EF_WAITRDY:
;	CALL EF_STAT
	LD A,R0
	OUT (SETREG),A
	IN A,(DATAACC)
	RLA
	JR C,EF_WAITRDY
	RET
;
;----------------------------------------------------------------------
; UPDATE EF9345 REGISTERS
;   EF_WRREG WRITES VALUE IN E TO EF9345 REGISTER SPECIFIED IN D
;	EF_WWRREG AFTER WAITING FOR READY WRITES VALUE IN E TO EF9345 REGISTER SPECIFIED IN D
;----------------------------------------------------------------------
;
EF_WWRREG:
	CALL EF_WAITRDY
EF_WRREG:
	LD A,D
	OUT (SETREG),A
	LD A,E
	OUT (DATAACC),A
	RET
;
;----------------------------------------------------------------------
; READ EF9345 REGISTERS
;   EF_RDREG READS EF9345 REGISTER SPECIFIED IN D AND RETURNS VALUE IN A AND E
;----------------------------------------------------------------------
EF_RDREG:
	CALL EF_WAITRDY
	LD A,D
	OUT (SETREG),A
	IN A,(DATAACC)
	LD E,A
	RET
;
;----------------------------------------------------------------------
; READ INDIRECT EF9345 REGISTERS
;   EF_READ_INDIR READS EF9345 REGISTER SPECIFIED IN D AND RETURNS VALUE IN A AND E
;----------------------------------------------------------------------
;
EF_READ_INDIR:
	LD A,IND
	OR D
	OR RDREG
	LD E,A
	LD D,R0 + EXEC
	CALL EF_WWRREG
	LD D,R1
	CALL EF_RDREG
	RET
;
;----------------------------------------------------------------------
; WRITES INDIRECT EF9345 REGISTERS
;   EF_LOAD_INDIR WRITES VALUE IN E TO INDIRECT EF9345 REGISTER SPECIFIED IN D
;----------------------------------------------------------------------
;
EF_LOAD_INDIR:			; D = TARGET REGISTER, E = VALUE TO WRITE
	PUSH DE
	LD D,R1
	CALL EF_WWRREG
	POP DE
	PUSH DE
	LD A,IND
	OR D
	LD E,A
	LD D,R0 + EXEC
	CALL EF_WWRREG
	POP DE
	RET
;
EF_LOAD_MODE:			;	LOAD MODE
	LD D,TGSREG			; START INDIRECT REGISTER 1 : TGS
	LD B,INIT_CNT		; LOAD 5 INDIRECT REGISTERS
MODEREG:
	LD E,(HL)
	CALL EF_LOAD_INDIR
	INC HL
	INC D
	LD A,INIT_CNT
	CP D
	JR NZ,NOSKIP
	INC D
	INC D
	LD E,(HL)
	LD A,(CON_BANKY)
	ADD A,E
	LD E,A
	CALL EF_LOAD_INDIR
	RET
NOSKIP:
	DJNZ MODEREG
	RET
;
GETXY:				; D = ROW, E = COLUMNS
	CALL GETX
	CALL GETY
	RET
;
GETX:				; E = COLUMNS
	CALL EF_WAITRDY
	LD D,XP
	CALL EF_RDREG
	RLCA			; CORRECTION 80 ROWS MODE
	AND 00111111B
	LD E,A
	RET
;
GETY:				; D = ROW
	CALL EF_WAITRDY
	PUSH DE
	LD D,YP
	CALL EF_RDREG
	AND 00011111B
	SUB FIRSTLINE
	POP DE
	LD D,A
	RET
;
EF_LOADFONTS:
	PRTS("Not implemented$")
	CALL NEWLINE
	SYSCHKERR(ERR_NOTIMPL)	; NOT IMPLEMENTED (YET)
	LD A,-2
	OR A
	RET
;
EF_NOTIMP:
	PRTS("Not implemented$")
	CALL NEWLINE
	SYSCHKERR(ERR_NOTIMPL)	; NOT IMPLEMENTED (YET)
	XOR A
	OR -2			; FUNCTION NOT IMPLEMENTED
	RET
;
EF_CURSORON:			; CURSOR DISPLAY ENABLE
	PUSH DE
	PUSH AF
	LD D,MATREG			; LOAD CURSOR ENABLE
	CALL EF_READ_INDIR
	OR 01000000B
	LD D,MATREG			; SET CURPOS ENABLE
	LD E,A
	CALL EF_LOAD_INDIR
	POP AF
	POP DE
	RET
;
EF_CURSOROFF:
	PUSH DE
	PUSH AF
	LD D,MATREG			; LOAD CURSOR ENABLE
	CALL EF_READ_INDIR
	AND 10111111B
	LD D,MATREG			; SET CURSOR ENABLE
	LD E,A
	CALL EF_LOAD_INDIR
	POP AF
	POP DE
	RET
;
INCCURSOR:				;CURSOR POSITION, D = ROW, E = COLUMN
	PUSH DE
	PUSH HL
	LD HL,(VDA_OFFSET)
	LD DE,(VDA_POS)
	ADD HL,DE
	INC DE
	LD A,DROWS
	CP E
	JR NZ,CURS0
	LD E,0
	INC D
	LD A,DLINES
	CP D
	JR NZ,CURS0
	LD D,0
CURS0:
	LD (VDA_POS),DE
	CALL EF_VDASCP
	pop hl
	POP DE
	RET
;
;----------------------------------------------------------------------
;  DISPLAY CONTROLLER CHIP INITIALIZATION
;----------------------------------------------------------------------
;
EF_INIT9345:
#IF (EF9345SIZE=V80X24)			;E)
TGS:	.DB 11000010b		; 80 char/row, long char code (12 bits) : TGS Register interlaced
MAT:	.DB EF9345_CSTY			;01001000b		; cursor enabled, fixed complent cursor, margin color = black : MAT Register
PAT:	.DB 01111110b		; 80 char/row, long code, upper/lower bulk on, conceal on,
							; I high during active disp. area, status row disebled : PAT Register
DOR:	.DB 10001111b		; DOR(3:0) = 1111   : color c0 = white, DOR(7:4) = 1000 : color c1 = black
ROR:	.DB 00001000b		; ROR(7:5) =   000  : displayed page memory starts from block 0
							; ROR(4:0) = 01000 : origin row = 8
#ENDIF
#IF (EF9345SIZE=V40X24)
TGS:	.DB 11000010b		; 80 char/row, long char code (12 bits) : TGS Register interlaced
MAT:	.DB EF9345_CSTY		;01001000b		; cursor enabled, fixed complent cursor, margin color = black : MAT Register
PAT:	.DB 01111110b		; 80 char/row, long code, upper/lower bulk on, conceal on,
							; I high during active disp. area, status row disebled : PAT Register
DOR:	.DB 10001111b		; DOR(3:0) = 1111   : color c0 = white, DOR(7:4) = 1000 : color c1 = black
ROR:	.DB 00001000b		; ROR(7:5) =   000  : displayed page memory starts from block 0
							; ROR(4:0) = 01000 : origin row = 8
#ENDIF

INIT_CNT:	.EQU	$ - EF_INIT9345
;
;======================================================================
; EF9345 DRIVER - VIDEO DISPLAY ADAPTER FUNCTIONS
;======================================================================
;
;VDA_FNCNT		.EQU	16
EF_FNTBL:
	.DW	EF_VDAINI
	.DW	EF_VDAQRY
	.DW	EF_VDARES
	.DW	EF_VDADEV
	.DW	EF_VDASCS
	.DW	EF_VDASCP
	.DW	EF_VDASAT
	.DW	EF_VDASCO
	.DW	EF_VDAWRC
	.DW	EF_VDAFIL
	.DW	EF_VDACPY
	.DW	EF_VDASCR
	.DW	EF_NOTIMP		;PPK_STAT
	.DW	EF_NOTIMP		;PPK_FLUSH
	.DW	EF_NOTIMP		;PPK_READ
	.DW	EF_VDARDC
#IF (($ - EF_FNTBL) != (VDA_FNCNT * 2))
	.ECHO	"*** INVALID VDU FUNCTION TABLE ***\n"
#ENDIF
;
EF_VDAINI:
; VIDEO INITIALIZE
; FULL REINITIALIZATION, CLEAR SCREEN, CURRENTLY IGNORES VIDEO MODE AND BITMAP DATA
	PUSH HL
	CALL EF_INIT1
	POP HL
	LD A,L
	OR H
	CALL NZ,EF_LOADFONTS
	XOR	A
	RET
;
EF_VDAQRY:
; VIDEO QUERY
; ENTRY: C = VIDEO UNIT, HL = FONT BITMAT
; RETURN: C = VIDEO MODE, D = ROWS, E = COLUMNS, HL = FONT BITMAT
	LD	C,$00					; MODE ZERO IS ALL WE KNOW
	LD	DE,(DLINES*256)+DROWS	; D=DLINES, E=DROWS
	LD	HL,0					; EXTRACTION OF CURRENT BITMAP DATA NOT SUPPORTED
	XOR	A						; SIGNAL SUCCESS
	RET
;
EF_VDARES:
; VIDEO RESET
; SOFT RESET, CLEAR SCREEN, HOME CURSOR, RESTORE ATTRIBUTE/COLOR DEFAULTS
;
	CALL EF_CLEARALL
	CALL EF_LOADATTR
	LD	DE,0
	LD (VDA_OFFSET),DE
	CALL EF_VDASCP
	XOR A
	RET
;
EF_VDADEV:
; VIDEO DEVICE
; ENTRY: C = VIDEO UNIT
; RETURN: D := DEVICE TYPE, E := DEVICE NUMBER, H := DEVICE UNIT MODE, L := DEVICE I/O BASE ADDRESS
	LD	DE,(VDADEV_EF9345 * 256) + 0	; D := DEVICE TYPE
										; E := PHYSICAL UNIT IS ALWAYS ZERO
	LD HL,EF9345_BASE					; H INDICATES THE VARIANT OF THE CHIP OR CIRCUIT, H = 0 : NO VARIANTS
										; L := BASE I/O ADDRESS
	XOR	A								; SIGNAL SUCCESS
	RET
;
EF_VDASCS:
; VIDEO SET CURSOR STYLE
; ENTRY: C = VIDEO UNIT, D = START/END, E = STYLE : E0 = BLINK/FLASH, E1 = UNDELINE, E2 = REVERSE/COMPLEMENT
; MAT5 = 1 : FLASH, MAT4 = 0 : COMPLEMENT
; RETURN A = STATUS
	SRA E
	LD A,EF9345_FLASH	; CURSOR IS BLINKING
	JR C,VDASCS0
	XOR A
VDASCS0:
	SRA E
	JR NC,VDASCS1
	OR EF9345_ULIN		; UNDERLINED CURSOR
VDASCS1:
	SRA E
	JR NC,VDASCS2
	AND EF9345_COMPL
VDASCS2:
	LD B,A
	LD A,(VDA_ATTR)
	AND 11001111B
	OR B
	LD (VDA_ATTR),A
	CALL EF_LOADATTR
	XOR A
	RET
;
EF_VDASCP:
; SET VIDEO CURSOR POSITION
; ENTRY: C = VIDEO UNIT, D = ROW, E = COLUMN
; RETURN A = STATUS
	PUSH BC
	PUSH DE
	PUSH HL
; CHECKING THE FEASIBILITY OF THE INPUT VALUES
	LD A,DLINES-1
	CP D
	JR C,VDASCP0
	LD A,DROWS-1
	CP E
	JR C,VDASCP0
	LD (VDA_POS),DE		; D = ROW, E = COLUMNS
EF_LOADXY:
	CALL SET_XP
	CALL SET_YP
	call EF_WAITRDY
	XOR	A
	JR VDASCP1
VDASCP0:
	XOR A
	OR -6			; PARAMETERS OUT OF RANGE $FF
VDASCP1:
	POP HL
	POP DE
	POP BC
	RET
;
SET_XP:					; E = COLUMN
	PUSH DE
	RRC E				; ADJUST TO 80 COLUMN LAYOUT
	LD D,XP				; X POSITION
	CALL EF_WWRREG
	POP DE
	RET
;
SET_YP:						; D = ROW
	PUSH DE
	PUSH HL
	LD HL,(VDA_OFFSET)
	LD A,H
	POP HL
	ADD A,FIRSTLINE
	ADD A,D
	CP FIRSTLINE+DLINES
	JR C,SETYP0
	SUB DLINES
SETYP0:
	LD E,A
	LD A,(CON_BANKY)		; STAY IN DISTRICT
	OR E
	LD E,A
	LD D,YP
	CALL EF_WWRREG
	POP DE
	RET
;
EF_VDASAT:
; VIDEO SET CHARACTER ATTRIBUTE FOR SCROLL, KRL, ETC.
; ENTRY: C = VIDEO UNIT, E = ATTRIBUTE
; E = STYLE : E0 = BLINK, E1 = UNDELINE, E2 = REVERSE, E3 = COLOR SELECT
; RETURN A = STATUS
	XOR A
	SRA E				; IS BLINKING
	JR NC,VDASAT0
	OR EF_FLASH
VDASAT0:
	SRA E
	JR NC,VDASAT1
	OR EF_UNDERLINE		; UNDERLINED CURSOR
VDASAT1:
	SRA E
	JR NC,VDASAT2
	OR EF_NEGATIVE		; NEGATIVE CURSOR
VDASAT2:
	SRA E
	JR NC,VDASAT3
	OR EF_COLORSET
VDASAT3:
	LD (VDASAT_ATTR),A
	XOR A
	RET
;
EF_LOADATTR:
	LD A,(VDA_ATTR)
	LD E,A
	LD D,MATREG
	CALL EF_LOAD_INDIR
	RET
;
EF_VDASCO:
; VIDEO SET CHARACTER COLOR
; ENTRY C = VIDEO UNIT, E = COLOR
; RETURN A = STATUS
	CALL EF_WAITRDY
	LD A,E
	AND $F8			; MASK BG COLOR
	LD B,A			; B = BG
	SRL B
	SRL B
	SRL B
	SRL B
	LD A,E
	AND $07			; MASK FG COLOR
	LD C,A			; C = FG
	LD D,DORREG		; LOAD FG COLOR FROM DOR(3..0)
	CALL EF_READ_INDIR
	AND $F8
	OR C			; SET NEW FG COLOR
	LD E,A
	LD D,DORREG		; LOAD NEW FG COLOR
	CALL EF_LOAD_INDIR
;
	LD D,MATREG		; LOAD BG COLOR
	CALL EF_READ_INDIR
	AND $F8			; MASK BG COLOR
	OR B			; SET NEW BG COLOR
	LD E,A
	LD D,MATREG		; LOAD NEW BG COLOR
	CALL EF_LOAD_INDIR
	XOR A
	RET
;
EF_VDAWRC:
; VIDEO WRITE CHARACTER,
; ENTRY C = VIDEO UNIT, E = CHARACTER
; RETURN A = STATUS
	CALL EF_KRL80
	LD D,R1+EXEC
	CALL EF_WWRREG
	CALL INCCURSOR
	XOR A
	RET
;
EF_VDAFIL:
; VIDEO FILL
; ENTRY: C = VIDEO UNIT, E = CHARACTER, HL = COUNT OF CHARACTERS
; RETURN A = STATUS
	CALL EF_CURSOROFF
VDAFIL0:
	CALL EF_VDAWRC
	DEC HL
	LD A,H
	OR L
	JR NZ,VDAFIL0
	CALL EF_CURSORON
	XOR A
	RET
;
EF_VDACPY:
; VIDEO COPY
; ENTRY C = VIDEO UNIT, D = SOURCE ROW, E =  SOURCE COLUMN, L = COUNT
; RETURN A = STATUS
	PUSH DE			; SAVE SOURCE
	CALL EF_CURSOROFF
	CALL GETXY		; GET AND SAVE CURRENT CURSOR POSITION
	LD (CURPOS),DE
; CHECK END OF SCREEN
	PUSH HL
	PUSH DE
	LD H,D			; D = CURRENT LINE
	LD E,DROWS		; CHARACTERS IN ROW
	CALL MULT8		; LINES * DROWS
	POP DE
	LD D,0
	ADD HL,DE		; ADD CHARACTERS IN CURRENT LINE := USED CHARACTERS
	EX DE,HL
	LD HL,DLINES*DROWS	; AVAILABLE CHARACTER COUNT
	XOR A
	SBC HL,DE		; REMAINING CHARACTERS = AVAILABLE - USED
	LD B,L			; SAVE REMAINING CHARACTER COUNT
	POP DE
	PUSH DE
	LD D,0
	SBC HL,DE		; COMPARE COPY COUNT WITH AVAILABLE
	POP HL
	JR NC,CPY0
	LD L,B			; ADJUST COPY COUNT
CPY0:
	POP DE
	CALL EF_VDASCP	; SET SOURCE AS CURSOR
	PUSH HL			; SAVE COUNT
	LD B,L
	LD HL,EF_BUF
CPYRD:
	PUSH BC
	CALL EF_VDARDC
	POP BC
	LD (HL),E
	INC HL
	CALL INCCURSOR
	DJNZ CPYRD
	LD DE,(CURPOS)	; RECOVER AND SET CURSOR POSITION
	CALL EF_VDASCP
	POP HL			; RECOVER COUNT
	LD B,L
	LD HL,EF_BUF
CPYWR:
	LD E,(HL)
	CALL EF_VDAWRC
	INC HL
	DJNZ CPYWR
; RESTORE CURSOR
	LD DE,(CURPOS)
	CALL EF_VDASCP
	CALL EF_CURSORON
	XOR A
	RET
;
EF_VDASCR:
; VIDEO SCROLL
; ENTRY: C = VIDEO UNIT, E = LINES
; RETURN A = STATUS
	CALL EF_CURSOROFF
VDASCR0:
	LD A,E
	OR A
	JR Z,VDASCR2		; SCROLL 0, NOTHING TO DO
	PUSH DE
	RLCA
	JR C,VDASCR1
	CALL EF_SCRUP
	POP DE
	DEC E
	JR VDASCR0
VDASCR1:
	CALL EF_SCRDOWN
	POP DE
	INC E
	JP VDASCR0
VDASCR2:
	CALL EF_CURSORON
	RET
;
EF_SCRUP:
	LD HL,(VDA_OFFSET)
	LD DE,$0100 			; inc y
	ADD HL,DE
	LD A,H
	CP DLINES
	JR NZ,SCRUP0
	LD HL,0
SCRUP0:
	LD (VDA_OFFSET),HL
	LD A,(CON_BANKY)
	ADD A,H
	ADD A,FIRSTLINE
	LD E,A
	LD D,RORREG
	CALL EF_LOAD_INDIR
; fill exposed line
	LD HL,(VDA_POS)
	PUSH HL
	LD HL,(DLINES-1)*256
	EX DE,HL
SCRCLEAR:
	CALL EF_VDASCP
	LD E,' '
	LD HL,DROWS
	CALL EF_VDAFIL
;
	POP HL
	EX DE,HL
	CALL EF_VDASCP
	RET
;
EF_SCRDOWN:
	XOR A
	LD HL,(VDA_OFFSET)
	LD DE,$FF00
	ADD HL,DE
	LD A,$FF
	CP H
	JR NZ,SCRDOWN0
	LD H,DLINES-1
SCRDOWN0:
	LD (VDA_OFFSET),HL
	LD A,(CON_BANKY)
	ADD A,FIRSTLINE
	ADD A,H
	LD E,A
	LD D,RORREG
	CALL EF_LOAD_INDIR
; fill exposed line
	LD HL,(VDA_POS)
	PUSH HL
	LD DE,0
	JR SCRCLEAR
;
EF_VDARDC:
; READ CHARACTER AT CURRENT VIDEO POSITION
; ENTRY: C = VIDEO UNIT
; RETURN: A = STATUS, E = CHARACTER, B = COLOR, C = ATTRIBUTES
	LD D,R0
	LD A,KRL			; R0 KRL COMMAND NO AUTOINC
	OR RDREG
	LD E,A
	CALL EF_WWRREG
	LD D,R3 + EXEC		; READ ATTRIBUTES
	CALL EF_RDREG
	LD C,A
	CALL EF_WAITRDY
	LD D,R1+EXEC
	CALL EF_RDREG
	PUSH DE
; READ COLOR
	LD D,DORREG			; LOAD FG COLOR
	CALL EF_READ_INDIR
	AND $07
	LD B,A
	LD D,MATREG			; LOAD BG COLOR
	CALL EF_READ_INDIR
	RLCA
	RLCA
	RLCA
	RLCA
	AND $70
	OR B
	LD B,A
	POP DE
	XOR A
	RET
;
EF_IDAT:
	.DB	KBDMODE_NONE	; PS/2 8242 KEYBOARD CONTROLLER
	.DB	0
	.DB	0

VDA_POS:		.DW 0
CURPOS:			.DW 0
SCRCNT:			.DB 0
VDA_OFFSET:		.DW 0
CON_BANKY:		.DB 0
VDA_ATTR:		.DB 0
VDASAT_ATTR:	.DB 0
EF_BUF:
.nolist
	.FILL	256,0	; COPY BUFFER
.list