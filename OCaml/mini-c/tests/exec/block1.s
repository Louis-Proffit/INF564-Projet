	.text
	.globl	main
main:
	movq $65, %r14
	movq %r14, %rdi
	call putchar
	movq $0, %r10
	addq %r10, %rsp
	movq $1, %r10
	cmpq %r10, %r10
	jne L14
	movq $67, %rdi
	call putchar
	movq $0, %r10
	addq %r10, %rsp
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
L14:
	movq $66, %rdi
	call putchar
	movq $0, %r10
	addq %r10, %rsp
	jmp L6
	.data
