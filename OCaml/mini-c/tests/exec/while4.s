	.text
	.globl	main
main:
	movq $10, %r10
L6:
	cmpq %r10, %r10
	jne L14
	movq $10, %rdi
	call putchar
	movq $0, %r10
	addq %r10, %rsp
	movq $0, %rax
	ret
L14:
	movq $1, %r10
	subq %r10, %r10
	movq $65, %rdi
	addq %r10, %rdi
	call putchar
	movq $0, %r8
	addq %r8, %rsp
	jmp L6
	.data
