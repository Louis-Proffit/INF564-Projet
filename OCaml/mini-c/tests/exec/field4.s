	.text
	.globl	main
main:
	movq $16, %rdi
	call sbrk
	movq %rax, %r14
	movq $0, %r10
	addq %r10, %rsp
	movq $65, %r10
	movq %r10, 0(%r14)
	movq 0(%r14), %rdi
	call putchar
	movq $0, %r10
	addq %r10, %rsp
	movq $66, %r10
	movq %r10, 8(%r14)
	movq 8(%r14), %rdi
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
