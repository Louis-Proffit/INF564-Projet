	.text
	.globl	main
main:
	movq $1, %rax
	movq $0, %r10
	idivq %rax
	movq %rax, %rdi
	call putchar
	movq $0, %r10
	addq %r10, %rsp
	movq $0, %rax
	ret
	.data
