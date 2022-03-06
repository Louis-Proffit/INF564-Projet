	.text
	.globl	main
f:
	movq %rdi, %rax
	addq %rsi, %rax
	ret
main:
	movq $65, %rdi
	movq $0, %rsi
	call f
	movq $0, %r10
	addq %r10, %rsp
	movq %rax, %rdi
	call putchar
	movq $0, %r10
	addq %r10, %rsp
	movq $65, %rdi
	movq $1, %rsi
	call f
	movq $0, %r10
	addq %r10, %rsp
	movq %rax, %rdi
	call putchar
	movq $0, %r10
	addq %r10, %rsp
	movq $65, %rdi
	movq $2, %rsi
	call f
	movq $0, %r10
	addq %r10, %rsp
	movq %rax, %rdi
	call putchar
	movq $0, %r10
	addq %r10, %rsp
	movq $65, %rdi
	movq $3, %rsi
	call f
	movq %rax, %rdi
	movq $0, %r10
	addq %r10, %rsp
	call putchar
	movq $0, %r10
	addq %r10, %rsp
	movq $1, %r10
	addq %r10, %rdi
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
