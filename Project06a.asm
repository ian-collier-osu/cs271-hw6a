TITLE Program Template     (template.asm)

; Author: Ian Collier
; CS271 / Assignment 6a              Date: 3/17/19
; Description: Low level I/O handling

INCLUDE Irvine32.inc

; const
BUFFER_SIZE = 9
ASCII_NUM_0 = 48
ASCII_NUM_9 = 57
INPUT_REQUIRED = 10
TRUE = 1
FALSE = 0

.data

; Strings
intro1		BYTE	"ASSIGNMENT 6A: Low level I/O procedures",0
intro2		BYTE	"Created by Ian Collier",10,0
intro3		BYTE	"Prompts for 10 unsigned integers, verifies them, then finds their sum and average.",10,0

prompt1		BYTE	"Enter an unsigned int: ",10,"Please fill the underscores.",10,"__________",0
prompt1err	BYTE	"Error: Not an unsigned integer.",0

results1	BYTE	"You entered:",0
results2	BYTE	"Sum:",0
results3	BYTE	"Avg:",0

separator	BYTE	", ",0

bye1		BYTE	"Bye.",0

fail1		BYTE	"Fail.",0
success1	BYTE	"Success.",0

;vars
inputBuf	BYTE	BUFFER_SIZE		DUP(?)
intArray	DWORD	INPUT_REQUIRED	DUP(0)
tempVal		DWORD	?
tempVal2	DWORD	?

.code

; Macro to get string input and store in buffer
; Uses edx ecx
getString MACRO prompt:REQ, buffer:REQ, bufferSize:REQ

	; Print the prompt
	mov		edx, prompt
	call	WriteString
	call	Crlf
	; Read in
	mov		ecx, bufferSize
	mov		edx, buffer
	call	ReadString

ENDM

; Macro to print a string
; Uses edx
displayString MACRO string:REQ

	mov		edx, string
	call	WriteString
	call	Crlf

ENDM

; Procedure prototypes
writeVal		PROTO
printIntro		PROTO
printExit		PROTO
printArray		PROTO, intBufP:DWORD, intBufN:DWORD
printResults	PROTO, intBufP:DWORD, intBufN:DWORD
printSumVals	PROTO, intBufP:DWORD, intBufN:DWORD
printAvgVals	PROTO, intBufP:DWORD, intBufN:DWORD
exponentUInt	PROTO, returnValP:DWORD, xVal:DWORD, sqVal:DWORD

; not working
readVal			PROTO, returnP:DWORD
verifyAsciiInt	PROTO, returnValP:DWORD, asciiChar:BYTE
convertAsciiInt	PROTO, returnValP:DWORD, asciiChar:BYTE
readValMulti	PROTO, returnIntBufP:DWORD, returnBufN:DWORD



main PROC

	invoke	printIntro

	invoke	readValMulti, ADDR intArray, INPUT_REQUIRED
	invoke	printResults, ADDR intArray, INPUT_REQUIRED

	invoke	printExit

	exit	; exit to operating system
main ENDP


; Prints the intro text
printIntro PROC USES edx

	displayString	OFFSET intro1
	displayString	OFFSET intro2
	displayString	OFFSET intro3
	ret

printIntro ENDP


; Prints the bye text
printExit PROC USES edx

	displayString	OFFSET bye1
	ret

printExit ENDP

; Prints the results
printResults PROC USES edx, intBufP:DWORD, intBufN:DWORD

	displayString	OFFSET results1
	invoke	printArray, intBufP, intBufN
	displayString	OFFSET results2
	invoke	printSumVals, intBufP, intBufN
	displayString	OFFSET results3
	invoke	printAvgVals, intBufP, intBufN
	ret

printResults ENDP


; Reads in to int buffer user input N times
readValMulti PROC USES eax ecx edi, returnIntBufP:DWORD, returnBufN:DWORD

	; Loop N times
	mov		ecx, returnBufN
	; Setup array pointer
	mov		edi, returnIntBufP

	readValMultiLoop: 
		; Read value into array
		invoke	readVal, edi
		
		; Inc array pointer and loop
		add		edi, 4
		loop	readValMultiLoop

	ret

readValMulti ENDP


; Prompts for an unsigned integer, verifies input, and stores in returnP
readVal PROC USES eax edx ecx edi esi, returnP:DWORD


	readValStart:
	; Prompt the user
	getString	OFFSET prompt1, OFFSET inputBuf, BUFFER_SIZE - 1


	; Loop to verify all characters in inputBuf
	; Init loop
	cld
	mov		esi, OFFSET inputBuf
	mov		edi, esi
	mov		ecx, BUFFER_SIZE
	xor		eax, eax

	readValCheckLoop: 
		; Call verify proc on each array item
		lodsb
		invoke	verifyAsciiInt, ADDR tempVal, al
		stosb

		; Check if verify returned FALSE
		mov		eax, tempVal
		cmp		eax, FALSE
		; If yes goto err
		je readValCheckLoopErr

		; If not keep looping
		loop readValCheckLoop

	;If loop ends normally
	jmp readValCheckLoopEnd

	; Err label
	readValCheckLoopErr:
		; Print error and start over
		displayString	OFFSET prompt1err
		jmp		readValStart

	; Normal end label
	readValCheckLoopEnd:


	; Loop to convert all characters in inputBuf
	cld
	mov		esi,OFFSET inputBuf
	mov		edi,esi
	mov		ecx, BUFFER_SIZE
	xor		ebx, ebx

	; Convert char array to a single uint
	readValConvLoop:
		xor		eax, eax
		xor		edx, edx

		; atoi
		; tempVal = int
		lodsb
		invoke	convertAsciiInt, ADDR tempVal, al
		stosb

		; Get 10^ecx
		invoke	exponentUInt, ADDR tempVal2, 10, ecx

		; Multiply converted int by 10^ecx
		mov		eax, tempVal
		mul		tempVal2

		; Add to running total
		add		ebx, eax

		loop readValConvLoop

	mov		eax, returnP
	mov		[eax], ebx

	ret

readVal ENDP


exponentUInt PROC USES eax edx ecx, returnValP:DWORD, xVal:DWORD, sqVal:DWORD
	xor		eax, eax
	mov		eax, xVal
	mov		ecx, sqVal
	; Handles exponent of 0/1
	cmp		ecx, 1
	je		exponentUIntOne
	cmp		ecx, 0
	je		exponentUIntZero
	dec		ecx

	exponentUIntLoop:
		; Mutliply by itself
		mul		xVal
		loop	exponentUIntLoop

	mov		edx, returnValP
	mov		[edx], eax
	ret

	exponentUIntZero:
	mov		eax, 1
	mov		edx, returnValP
	mov		[edx], eax
	ret

	exponentUIntOne:
	mov		eax, 10
	mov		edx, returnValP
	mov		[edx], eax
	ret

exponentUInt ENDP


; Checks if a char is a valid integer
; Returns bool
verifyAsciiInt PROC USES eax edx, returnValP:DWORD, asciiChar:BYTE

	xor		eax, eax
	mov		al, asciiChar

	; Handle null chars
	cmp		eax, 32
	jb		verifyAsciiIntSuccess

	; If char is less than ASCII 0, it's not valid
	
	cmp		eax, ASCII_NUM_0
	jb		verifyAsciiIntErr

	; If char is greater than ASCII 9, it's not valid
	cmp		eax, ASCII_NUM_9
	ja		verifyAsciiIntErr

	; No error return TRUE
	verifyAsciiIntSuccess:
		mov edx, returnValP
		mov eax, TRUE
		mov [edx], eax
		ret

	verifyAsciiIntErr:
		mov edx, returnValP
		mov eax, FALSE
		mov [edx], eax
		ret
		

verifyAsciiInt ENDP


convertAsciiInt PROC USES eax edx, returnValP:DWORD, asciiChar:BYTE

	xor		eax, eax
	mov		al, asciiChar
	; Handle the null char
	cmp		eax, 32
	jb		convertAsciiIntNull

	; Convert to number
	sub		eax, ASCII_NUM_0

	; Return value
	mov edx, returnValP
	mov [edx], eax
	ret

	; Returns 0
	convertAsciiIntNull:
		mov		eax, 0
		mov		edx, returnValP
		mov		[edx], eax
		ret
		

convertAsciiInt ENDP

; stubs
printArray PROC USES ecx esi edx eax, intBufP:DWORD, intBufN:DWORD

	; Loop thru array and print
	mov		ecx, intBufN
	mov		esi, intBufP
	printArrayLoop:
		mov		eax, [esi]
		call	WriteDec
		displayString OFFSET separator
		add		esi, 4
		loop	printArrayLoop

	call	Crlf
	ret

printArray ENDP

printSumVals PROC USES eax ecx esi, intBufP:DWORD, intBufN:DWORD
	; Loop thru array and print
	mov		ecx, intBufN
	mov		esi, intBufP
	mov		eax, 0
	printArrayLoop:
		add		eax, [esi]
		add		esi, 4
		loop	printArrayLoop

	call	WriteDec
	call	Crlf
	ret

printSumVals ENDP

printAvgVals PROC USES ecx esi eax, intBufP:DWORD, intBufN:DWORD
	; Loop thru array and print
	mov		ecx, intBufN
	mov		esi, intBufP
	xor		eax, eax
	xor		edx, edx
	printArrayLoop:
		add		eax, [esi]
		add		esi, 4
		loop	printArrayLoop

	div		intBufN
	call	WriteDec
	call	Crlf
	ret

printAvgVals ENDP

END main