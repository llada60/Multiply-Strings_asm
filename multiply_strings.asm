;两个大数相乘
.386
.model flat, stdcall
option casemap:none

;说明程序中用到的库、函数原型和常量
includelib msvcrt.lib
include msvcrt.inc
scanf PROTO C :dword,:vararg
printf PROTO C :ptr sbyte,:vararg

;数据区
.data
;char型，用于输入输出
A0 byte	151 dup(0)			
B0 byte	151 dup(0)
C0 byte	301 dup(0)
;int型，用于计算
A1 dword 150 dup(0)			
B1 dword 150 dup(0)
C1 dword 300 dup(0)
;字符长度
lenA dword 0
lenB dword 0
lenC dword 0
;十进制
dcn dword 10
;负数标志
flga dword 0
flgb dword 0
flg	dword 0
;正号标志
posa dword 0
posb dword 0
;转换是否跳过首位
flgpass dword 0
flgpass1 dword 0
;判断溢出的字符
tmpc byte 0


szInputNum1 byte	" %150[^ ",0ah,"]" ,0		
szInputNum2 byte	" %150[^ ", 0ah , "]" ,0	
szCharInput byte	"%c",0
szOutputMsg byte "The multiply result is: %s", 0dh, 0ah, 0
pauseInfo	byte "pause", 0
inputWrong byte "Please input number!",0ah,0ah,0
szGuide byte "Please input 2 numbers：",0ah,0
szOverflow byte "Data overflow",0ah,0

;代码区
.code

;字符转换为整型
char2int proc C X0:ptr byte, X1:ptr dword, len:dword, flgx:dword
	mov ecx,len
	mov edi,X0
	mov esi,X1
	add edi,ecx
	dec edi ;edi==X0+len-1
startC2I:
	movzx eax,byte ptr[edi]
	cmp edi,X0
	jne checkInput
	cmp flgx,1
	je trans
checkInput:
;检查输入的正确性
	cmp eax,'0'
	jl invalidInput
	cmp eax,'9'
	jg invalidInput
trans:
	sub eax,'0'
	mov dword ptr[esi],eax
	dec edi
	add esi,4
	dec ecx
	cmp ecx,0
	jg startC2I
	xor eax,eax
	ret
invalidInput:
	xor eax,eax
	mov eax,1
	ret
char2int endp

multiply proc C
	mov edi,offset C1
	mov ebx,0 ;A1 index
	;外循环
	mov edx,lenA
loop1:
	push edx
	;内循环
	mov edx,lenB
	mov ecx,0 ;B1 index
loop2:
	push edx
	mov eax,A1[ebx*4]
	mul B1[ecx*4]
	add eax,dword ptr[edi+4*ecx]
	div dcn
	mov dword ptr[edi+4*ecx],edx
	add dword ptr[edi+4*ecx+4],eax
	inc ecx
	pop edx
	dec edx
	cmp edx,0
	ja loop2 ;内循环结束
	add edi,4
	inc ebx
	pop edx
	dec edx
	cmp edx,0
	ja loop1 ;外循环结束

	xor eax,eax
	mov eax,lenA
	add eax,lenB
;检查高位0的情况
checkHigh:
	cmp dword ptr[edi+4*ecx-4],0
	jne mulRet
	dec eax
	dec ecx
	cmp eax,1
	jne checkHigh

checkIsZero:
	cmp dword ptr[edi+4*ecx-4],0
	jne mulRet
	mov flg,0
mulRet:
	mov lenC,eax
	ret
multiply endp

int2char proc C X0:ptr byte, X1:ptr dword, len:dword
	mov edi,X0
	mov esi,X1
	mov ebx,len
	dec ebx
	;检查负数的情况
	cmp flg,1
	jne startI2C
	mov byte ptr[edi],'-'
	inc edi
startI2C:
	mov eax,dword ptr[esi+4*ebx]
	add eax,'0'
	mov byte ptr[edi],al
	inc edi
	dec ebx
	cmp ebx,0
	jge startI2C
	ret
int2char endp

main:
	jmp inputNum
wrongInput:
	pop eax
wrongInput2:
	invoke printf,offset inputWrong
	mov flga,0
	mov flgb,0
	mov flg,0

inputNum:
	;输入两个大数
	invoke printf,offset szGuide
	invoke scanf, offset szInputNum1, offset A0
	invoke scanf,offset szCharInput, offset tmpc
	cmp tmpc,0ah
	je next_read
	cmp tmpc,' '
	jne overflow
next_read:
	invoke scanf, offset szInputNum2, offset B0
	invoke scanf,offset szCharInput, offset tmpc
	cmp tmpc,0ah
	je len_cal
	cmp tmpc,' '
	jne overflow
len_cal:
	invoke crt_strlen, offset A0
	mov	lenA, eax
	invoke crt_strlen, offset B0
	mov	lenB, eax
	;char转int方便计算
	;判断是否为负数
	cmp A0[0],'+' ;判断首位是否为正号
	je setPflg
	cmp	A0[0], '-'
	jne	next0
	cmp lenA,1
	je wrongInput2
	xor	flg, 1	
	mov flga,1
	jmp next0
	setPflg:
	mov posa,1
next0:
	push eax
	xor eax,eax
	mov eax,flga
	or eax,posa
	mov flgpass,eax
	invoke char2int, offset A0, offset A1, lenA	,flgpass
	cmp flgpass,1
	jne next01
	dec	lenA
next01:
	cmp eax,1
	je wrongInput
	pop eax
	
	cmp B0[0],'+' ;判断首位是否为正号
	je setPflg1
	cmp	B0[0], '-'
	jne	next1
	cmp lenB,1
	je wrongInput2
	xor	flg, 1		
	mov flgb,1
	jmp next1
	setPflg1:
	mov posb,1
next1:
	push eax
	xor eax,eax
	mov eax,flgb
	or eax,posb
	mov flgpass1,eax
	invoke char2int, offset B0, offset B1, lenB	,flgpass1
	cmp flgpass1,1
	jne next11
	dec	lenB
next11:
	cmp eax,1
	je wrongInput
	pop eax
	;做乘法
	invoke multiply
	;整型转字符
	invoke int2char, offset C0, offset C1, lenC
	;输出
	invoke crt_printf, offset szOutputMsg, offset C0
	invoke crt_system, offset pauseInfo
	ret
overflow:
	invoke printf,offset szOverflow
	invoke crt_system, offset pauseInfo
	ret
end main