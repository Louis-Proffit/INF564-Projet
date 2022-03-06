	.text
	.globl	main
main:
	movq $104, %rdi
	call putchar
	movq $0, %r10
	addq %r10, %rsp
	movq $101, %rdi
	call putchar
	movq $0, %r10
	addq %r10, %rsp
	movq $108, %rdi
	call putchar
	movq $0, %r10
	addq %r10, %rsp
	movq $108, %rdi
	call putchar
	movq $0, %r10
	addq %r10, %rsp
	movq $111, %rdi
	call putchar
	movq $0, %r10
	addq %r10, %rsp
	movq $32, %rdi
	call putchar
	movq $0, %r10
	addq %r10, %rsp
	movq $119, %rdi
	call putchar
	movq $0, %r10
	addq %r10, %rsp
	movq $111, %rdi
	call putchar
	movq $0, %r10
	addq %r10, %rsp
	movq $114, %rdi
	call putchar
	movq $0, %r10
	addq %r10, %rsp
	movq $108, %rdi
	call putchar
	movq $0, %r10
	addq %r10, %rsp
	movq $100, %rdi
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
