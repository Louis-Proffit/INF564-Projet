	.text
	.globl	main
main:
	movq $10, %r10
L9:
	movq $1, %r8
	subq %r8, %r10
	cmpq %r10, %r10
	jne L13
	movq $10, %rdi
	call putchar
	movq $0, %r10
	addq %r10, %rsp
	movq $0, %rax
	ret
L13:
	movq $65, %rdi
	addq %r10, %rdi
	call putchar
	movq $0, %r8
	addq %r8, %rsp
	jmp L9
	.data
