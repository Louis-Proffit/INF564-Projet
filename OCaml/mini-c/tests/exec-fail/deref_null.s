	.text
	.globl	main
main:
	movq $0, %r10
	movq 0(%r10), %rdi
	call putchar
	movq $0, %r10
	addq %r10, %rsp
	movq $0, %rax
	ret
	.data