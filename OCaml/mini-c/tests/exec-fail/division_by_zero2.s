	.text
	.globl	main
main:
	movq $42, %r10
	movq $0, %rax
	subq %r10, %r10
	idivq %rax
	movq %rax, %rdi
	call putchar
	movq $0, %r10
	addq %r10, %rsp
	movq $0, %rax
	ret
	.data
