	.text
	.globl	main
main:
	movq $10, %r10
L11:
	movq $1, %r8
	subq %r8, %r10
	movq %r10, %r8
	movq $1, %r9
	addq %r9, %r8
	cmpq %r8, %r8
	jne L15
	movq $10, %rdi
	call putchar
	movq $0, %r10
	addq %r10, %rsp
	movq $0, %rax
	ret
L15:
	movq $65, %rdi
	addq %r10, %rdi
	call putchar
	movq $0, %r8
	addq %r8, %rsp
	jmp L11
	.data
