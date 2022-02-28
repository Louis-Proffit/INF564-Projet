	.file	"test.c"
	.text
	.globl	many
	.type	many, @function
many:
.LFB0:
	.cfi_startproc
	endbr64
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$32, %rsp
	movl	%edi, -4(%rbp)
	movl	%esi, -8(%rbp)
	movl	%edx, -12(%rbp)
	movl	%ecx, -16(%rbp)
	movl	%r8d, -20(%rbp)
	movl	%r9d, -24(%rbp)
	movl	-4(%rbp), %eax
	addl	$64, %eax
	movl	%eax, %edi
	call	putchar@PLT
	movl	-8(%rbp), %eax
	addl	$64, %eax
	movl	%eax, %edi
	call	putchar@PLT
	movl	-12(%rbp), %eax
	addl	$64, %eax
	movl	%eax, %edi
	call	putchar@PLT
	movl	-16(%rbp), %eax
	addl	$64, %eax
	movl	%eax, %edi
	call	putchar@PLT
	movl	-20(%rbp), %eax
	addl	$64, %eax
	movl	%eax, %edi
	call	putchar@PLT
	movl	-24(%rbp), %eax
	addl	$64, %eax
	movl	%eax, %edi
	call	putchar@PLT
	movl	16(%rbp), %eax
	addl	$64, %eax
	movl	%eax, %edi
	call	putchar@PLT
	movl	24(%rbp), %eax
	addl	$64, %eax
	movl	%eax, %edi
	call	putchar@PLT
	movl	32(%rbp), %eax
	addl	$64, %eax
	movl	%eax, %edi
	call	putchar@PLT
	movl	40(%rbp), %eax
	addl	$64, %eax
	movl	%eax, %edi
	call	putchar@PLT
	movl	$10, %edi
	call	putchar@PLT
	cmpl	$9, -4(%rbp)
	jg	.L2
	movl	-24(%rbp), %r8d
	movl	-20(%rbp), %ecx
	movl	-16(%rbp), %edx
	movl	-12(%rbp), %esi
	movl	-8(%rbp), %eax
	movl	-4(%rbp), %edi
	pushq	%rdi
	movl	40(%rbp), %edi
	pushq	%rdi
	movl	32(%rbp), %edi
	pushq	%rdi
	movl	24(%rbp), %edi
	pushq	%rdi
	movl	16(%rbp), %r9d
	movl	%eax, %edi
	call	many
	addq	$32, %rsp
.L2:
	movl	$0, %eax
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE0:
	.size	many, .-many
	.globl	main
	.type	main, @function
main:
.LFB1:
	.cfi_startproc
	endbr64
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	pushq	$10
	pushq	$9
	pushq	$8
	pushq	$7
	movl	$6, %r9d
	movl	$5, %r8d
	movl	$4, %ecx
	movl	$3, %edx
	movl	$2, %esi
	movl	$1, %edi
	call	many
	addq	$32, %rsp
	movl	$0, %eax
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE1:
	.size	main, .-main
	.ident	"GCC: (Ubuntu 9.3.0-17ubuntu1~20.04) 9.3.0"
	.section	.note.GNU-stack,"",@progbits
	.section	.note.gnu.property,"a"
	.align 8
	.long	 1f - 0f
	.long	 4f - 1f
	.long	 5
0:
	.string	 "GNU"
1:
	.align 8
	.long	 0xc0000002
	.long	 3f - 2f
2:
	.long	 0x3
3:
	.align 8
4:
