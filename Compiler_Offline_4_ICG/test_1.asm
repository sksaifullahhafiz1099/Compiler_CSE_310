;-------
;
;-------
.MODEL SMALL
.STACK 1000H
.Data
	CR EQU 0DH
	LF EQU 0AH
	number DB "00000$"
	a DW 1 DUP (0000H)
	b DW 1 DUP (0000H)
	c DW 1 DUP (0000H)
func_a PROC
	PUSH BP
	MOV BP, SP
	POP BP
	RET
func_a ENDP
foo PROC
	PUSH BP
	MOV BP, SP
	POP BP
	RET 1
foo ENDP
bar PROC
	PUSH BP
	MOV BP, SP
	POP BP
	RET 2
bar ENDP
main PROC
	MOV AX, @DATA
	MOV DS, AX
	PUSH BP
	MOV BP, SP
	SUB SP, 2
	SUB SP, 2
	SUB SP, 2
	SUB SP, 2
	ADD SP, 8
	POP BP
	MOV AX,4CH
	INT 21H
main ENDP
