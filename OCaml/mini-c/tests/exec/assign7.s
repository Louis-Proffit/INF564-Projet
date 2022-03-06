	.text
	.globl	main
main:
	movq $16, %rdi
	call sbrk
	movq %rax, %r14
	movq $0, %r10
	addq %r10, %rsp
	movq $24, %rdi
	call sbrk
	movq %rax, %r10
	movq $0, %r8
	addq %r8, %rsp
	movq $16, %rdi
	call sbrk
	movq $0, %r8
	addq %r8, %rsp
	movq %rax, 8(%r10)
	movq $65, %r8
	movq %r8, 0(%r10)
	movq $66, %r8
	movq %r8, 16(%r10)
	movq $120, %r8
	movq 8(%r10), %r9
	movq %r8, 0(%r9)
	movq $121, %r8
	movq 8(%r10), %r9
	movq %r8, 8(%r9)
	movq 0(%r10), %rdi
	call putchar
	movq $0, %r8
	addq %r8, %rsp
	movq 8(%r10), %r8
	movq 0(%r8), %rdi
	call putchar
	movq $0, %r8
	addq %r8, %rsp
	movq 8(%r10), %r8
	movq 8(%r8), %rdi
	call putchar
	movq $0, %r8
	addq %r8, %rsp
	movq 16(%r10), %rdi
	call putchar
	movq $0, %r8
	addq %r8, %rsp
	movq $10, %rdi
	call putchar
	movq $0, %r8
	addq %r8, %rsp
	movq $88, %r8
	movq %r8, 0(%r14)
	movq $89, %r8
	movq %r8, 8(%r14)
	movq 0(%r10), %rdi
	call putchar
	movq $0, %r8
	addq %r8, %rsp
	movq 8(%r10), %r8
	movq 0(%r8), %rdi
	call putchar
	movq $0, %r8
	addq %r8, %rsp
	movq 8(%r10), %r8
	movq 8(%r8), %rdi
	call putchar
	movq $0, %r8
	addq %r8, %rsp
	movq 16(%r10), %rdi
	call putchar
	movq $0, %r8
	addq %r8, %rsp
	movq $10, %rdi
	call putchar
	movq $0, %r8
	addq %r8, %rsp
	movq %r14, 8(%r10)
	movq 0(%r10), %rdi
	call putchar
	movq $0, %r8
	addq %r8, %rsp
	movq 8(%r10), %r8
	movq 0(%r8), %rdi
	call putchar
	movq $0, %r8
	addq %r8, %rsp
	movq 8(%r10), %r10
	movq 8(%r10), %rdi
	call putchar
	movq $0, %r8
	addq %r8, %rsp
	movq 16(%r10), %rdi
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
