	.text
	.globl	main
main:
	movq $65, %r14
	movq %r14, %rdi
	call putchar
	movq $0, %r10
	addq %r10, %rsp
	cmpq %r14, %r14
	jne L40
L38:
	movq %r14, %rdi
	call putchar
	movq $0, %r10
	addq %r10, %rsp
	movq %r14, %r10
	cmpq %r10, %r10
	je L33
	movq $0, %r10
L33:
	cmpq %r10, %r10
	jne L32
L30:
	movq %r14, %rdi
	call putchar
	movq $0, %r10
	addq %r10, %rsp
	movq %r14, %r10
	cmpq %r10, %r10
	je L25
	movq $1, %r10
L25:
	cmpq %r10, %r10
	jne L24
L22:
	movq %r14, %rdi
	call putchar
	movq $0, %r10
	addq %r10, %rsp
	movq %r14, %r10
	cmpq %r10, %r10
	jne L17
	movq $0, %r10
L17:
	cmpq %r10, %r10
	jne L16
L14:
	movq %r14, %rdi
	call putchar
	movq $0, %r10
	addq %r10, %rsp
	movq %r14, %r10
	cmpq %r10, %r10
	jne L9
	movq $1, %r10
L9:
	cmpq %r10, %r10
	jne L8
L6:
	movq %r14, %rdi
	call putchar
	movq $0, %r10
	addq %r10, %rsp
	movq $10, %rdi
	call putchar
	movq $0, %r10
	addq %r10, %rsp
	movq $0, %rax
	ret
L8:
	movq $70, %r14
	jmp L6
	jmp L9
L16:
	movq $69, %r14
	jmp L14
	jmp L17
L24:
	movq $68, %r14
	jmp L22
	jmp L25
L32:
	movq $67, %r14
	jmp L30
	jmp L33
L40:
	movq $66, %r14
	jmp L38
	.data
