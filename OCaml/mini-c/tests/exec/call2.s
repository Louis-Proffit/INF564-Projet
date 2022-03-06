	.text
	.globl	main
f:
	movq %rcx, %rdx
	movq %rdx, %rsi
	movq %rsi, %rdi
	movq %rdi, %r14
	cmpq %r14, %r14
	jne L9
	movq $0, %rax
L1:
	ret
L9:
	movq %r14, %rdi
	call putchar
	movq $0, %r10
	addq %r10, %rsp
	movq %r14, %rcx
	call f
	movq $0, %r10
	addq %r10, %rsp
	jmp L1
main:
	movq $65, %rdi
	movq $66, %rsi
	movq $67, %rdx
	movq $0, %rcx
	call f
	movq $0, %r10
	addq %r10, %rsp
	movq $10, %rdi
	call putchar
	movq $0, %r10
	addq %r10, %rsp
	movq $0, %rax
	ret
	.data
