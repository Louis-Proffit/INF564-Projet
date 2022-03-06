	.text
	.globl	main
main:
	movq $65, %r14
	movq %r14, %rdi
	call putchar
	movq $0, %r10
	addq %r10, %rsp
	movq $1, %r10
	addq %r10, %r14
	movq %r14, %rdi
	call putchar
	movq $0, %r10
	addq %r10, %rsp
	movq %r14, %rdi
	movq $1, %r10
	addq %r10, %rdi
	movq %r14, %rdi
	call putchar
	movq $0, %r10
	addq %r10, %rsp
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
