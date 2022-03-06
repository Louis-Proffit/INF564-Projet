	.text
	.globl	main
main:
	movq $65, %rdi
	call putchar
	movq $0, %r10
	addq %r10, %rsp
	movq $66, %rdi
	call putchar
	movq $0, %r10
	addq %r10, %rsp
	movq $10, %rdi
	call putchar
	movq $0, %r10
	addq %r10, %rsp
	movq $0, %rax
	ret
	.data
