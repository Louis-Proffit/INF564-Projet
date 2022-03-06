	.text
	.globl	main
main:
	movq $65, %r14
	movq %r14, %rdi
	call putchar
	movq $0, %r10
	addq %r10, %rsp
	movq $0, %r10
	cmpq %r10, %r10
	jne L18
	movq $67, %rdi
	movq $68, %rdi
	call putchar
	movq $0, %r10
	addq %r10, %rsp
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
L18:
	movq $66, %rdi
	call putchar
	movq $0, %r10
	addq %r10, %rsp
	jmp L6
	.data
