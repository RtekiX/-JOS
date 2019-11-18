
obj/user/badsegment：     文件格式 elf32-i386


セクション .text の逆アセンブル:

00800020 <_start>:
// starts us running when we are initially loaded into a new environment.
.text
.globl _start
_start:
	// See if we were started with arguments on the stack
	cmpl $USTACKTOP, %esp
  800020:	81 fc 00 e0 bf ee    	cmp    $0xeebfe000,%esp
	jne args_exist
  800026:	75 04                	jne    80002c <args_exist>

	// If not, push dummy argc/argv arguments.
	// This happens when we are loaded by the kernel,
	// because the kernel does not know about passing arguments.
	pushl $0
  800028:	6a 00                	push   $0x0
	pushl $0
  80002a:	6a 00                	push   $0x0

0080002c <args_exist>:

args_exist:
	call libmain
  80002c:	e8 0d 00 00 00       	call   80003e <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
	// Try to load the kernel's TSS selector into the DS register.
	asm volatile("movw $0x28,%ax; movw %ax,%ds");
  800036:	66 b8 28 00          	mov    $0x28,%ax
  80003a:	8e d8                	mov    %eax,%ds
}
  80003c:	5d                   	pop    %ebp
  80003d:	c3                   	ret    

0080003e <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  80003e:	55                   	push   %ebp
  80003f:	89 e5                	mov    %esp,%ebp
  800041:	56                   	push   %esi
  800042:	53                   	push   %ebx
  800043:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800046:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	envid_t envid = sys_getenvid();
  800049:	e8 be 00 00 00       	call   80010c <sys_getenvid>
	thisenv = envs;
  80004e:	c7 05 04 20 80 00 00 	movl   $0xeec00000,0x802004
  800055:	00 c0 ee 
	// save the name of the program so that panic() can use it
	if (argc > 0)
  800058:	85 db                	test   %ebx,%ebx
  80005a:	7e 07                	jle    800063 <libmain+0x25>
		binaryname = argv[0];
  80005c:	8b 06                	mov    (%esi),%eax
  80005e:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  800063:	83 ec 08             	sub    $0x8,%esp
  800066:	56                   	push   %esi
  800067:	53                   	push   %ebx
  800068:	e8 c6 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  80006d:	e8 0a 00 00 00       	call   80007c <exit>
}
  800072:	83 c4 10             	add    $0x10,%esp
  800075:	8d 65 f8             	lea    -0x8(%ebp),%esp
  800078:	5b                   	pop    %ebx
  800079:	5e                   	pop    %esi
  80007a:	5d                   	pop    %ebp
  80007b:	c3                   	ret    

0080007c <exit>:

#include <inc/lib.h>

void
exit(void)
{
  80007c:	55                   	push   %ebp
  80007d:	89 e5                	mov    %esp,%ebp
  80007f:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  800082:	6a 00                	push   $0x0
  800084:	e8 42 00 00 00       	call   8000cb <sys_env_destroy>
}
  800089:	83 c4 10             	add    $0x10,%esp
  80008c:	c9                   	leave  
  80008d:	c3                   	ret    

0080008e <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  80008e:	55                   	push   %ebp
  80008f:	89 e5                	mov    %esp,%ebp
  800091:	57                   	push   %edi
  800092:	56                   	push   %esi
  800093:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800094:	b8 00 00 00 00       	mov    $0x0,%eax
  800099:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80009c:	8b 55 08             	mov    0x8(%ebp),%edx
  80009f:	89 c3                	mov    %eax,%ebx
  8000a1:	89 c7                	mov    %eax,%edi
  8000a3:	89 c6                	mov    %eax,%esi
  8000a5:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  8000a7:	5b                   	pop    %ebx
  8000a8:	5e                   	pop    %esi
  8000a9:	5f                   	pop    %edi
  8000aa:	5d                   	pop    %ebp
  8000ab:	c3                   	ret    

008000ac <sys_cgetc>:

int
sys_cgetc(void)
{
  8000ac:	55                   	push   %ebp
  8000ad:	89 e5                	mov    %esp,%ebp
  8000af:	57                   	push   %edi
  8000b0:	56                   	push   %esi
  8000b1:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000b2:	ba 00 00 00 00       	mov    $0x0,%edx
  8000b7:	b8 01 00 00 00       	mov    $0x1,%eax
  8000bc:	89 d1                	mov    %edx,%ecx
  8000be:	89 d3                	mov    %edx,%ebx
  8000c0:	89 d7                	mov    %edx,%edi
  8000c2:	89 d6                	mov    %edx,%esi
  8000c4:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  8000c6:	5b                   	pop    %ebx
  8000c7:	5e                   	pop    %esi
  8000c8:	5f                   	pop    %edi
  8000c9:	5d                   	pop    %ebp
  8000ca:	c3                   	ret    

008000cb <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  8000cb:	55                   	push   %ebp
  8000cc:	89 e5                	mov    %esp,%ebp
  8000ce:	57                   	push   %edi
  8000cf:	56                   	push   %esi
  8000d0:	53                   	push   %ebx
  8000d1:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000d4:	b9 00 00 00 00       	mov    $0x0,%ecx
  8000d9:	b8 03 00 00 00       	mov    $0x3,%eax
  8000de:	8b 55 08             	mov    0x8(%ebp),%edx
  8000e1:	89 cb                	mov    %ecx,%ebx
  8000e3:	89 cf                	mov    %ecx,%edi
  8000e5:	89 ce                	mov    %ecx,%esi
  8000e7:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  8000e9:	85 c0                	test   %eax,%eax
  8000eb:	7e 17                	jle    800104 <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  8000ed:	83 ec 0c             	sub    $0xc,%esp
  8000f0:	50                   	push   %eax
  8000f1:	6a 03                	push   $0x3
  8000f3:	68 ea 0d 80 00       	push   $0x800dea
  8000f8:	6a 23                	push   $0x23
  8000fa:	68 07 0e 80 00       	push   $0x800e07
  8000ff:	e8 27 00 00 00       	call   80012b <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800104:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800107:	5b                   	pop    %ebx
  800108:	5e                   	pop    %esi
  800109:	5f                   	pop    %edi
  80010a:	5d                   	pop    %ebp
  80010b:	c3                   	ret    

0080010c <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  80010c:	55                   	push   %ebp
  80010d:	89 e5                	mov    %esp,%ebp
  80010f:	57                   	push   %edi
  800110:	56                   	push   %esi
  800111:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800112:	ba 00 00 00 00       	mov    $0x0,%edx
  800117:	b8 02 00 00 00       	mov    $0x2,%eax
  80011c:	89 d1                	mov    %edx,%ecx
  80011e:	89 d3                	mov    %edx,%ebx
  800120:	89 d7                	mov    %edx,%edi
  800122:	89 d6                	mov    %edx,%esi
  800124:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800126:	5b                   	pop    %ebx
  800127:	5e                   	pop    %esi
  800128:	5f                   	pop    %edi
  800129:	5d                   	pop    %ebp
  80012a:	c3                   	ret    

0080012b <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  80012b:	55                   	push   %ebp
  80012c:	89 e5                	mov    %esp,%ebp
  80012e:	56                   	push   %esi
  80012f:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800130:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800133:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800139:	e8 ce ff ff ff       	call   80010c <sys_getenvid>
  80013e:	83 ec 0c             	sub    $0xc,%esp
  800141:	ff 75 0c             	pushl  0xc(%ebp)
  800144:	ff 75 08             	pushl  0x8(%ebp)
  800147:	56                   	push   %esi
  800148:	50                   	push   %eax
  800149:	68 18 0e 80 00       	push   $0x800e18
  80014e:	e8 b1 00 00 00       	call   800204 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800153:	83 c4 18             	add    $0x18,%esp
  800156:	53                   	push   %ebx
  800157:	ff 75 10             	pushl  0x10(%ebp)
  80015a:	e8 54 00 00 00       	call   8001b3 <vcprintf>
	cprintf("\n");
  80015f:	c7 04 24 3c 0e 80 00 	movl   $0x800e3c,(%esp)
  800166:	e8 99 00 00 00       	call   800204 <cprintf>
  80016b:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  80016e:	cc                   	int3   
  80016f:	eb fd                	jmp    80016e <_panic+0x43>

00800171 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800171:	55                   	push   %ebp
  800172:	89 e5                	mov    %esp,%ebp
  800174:	53                   	push   %ebx
  800175:	83 ec 04             	sub    $0x4,%esp
  800178:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  80017b:	8b 13                	mov    (%ebx),%edx
  80017d:	8d 42 01             	lea    0x1(%edx),%eax
  800180:	89 03                	mov    %eax,(%ebx)
  800182:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800185:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  800189:	3d ff 00 00 00       	cmp    $0xff,%eax
  80018e:	75 1a                	jne    8001aa <putch+0x39>
		sys_cputs(b->buf, b->idx);
  800190:	83 ec 08             	sub    $0x8,%esp
  800193:	68 ff 00 00 00       	push   $0xff
  800198:	8d 43 08             	lea    0x8(%ebx),%eax
  80019b:	50                   	push   %eax
  80019c:	e8 ed fe ff ff       	call   80008e <sys_cputs>
		b->idx = 0;
  8001a1:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8001a7:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8001aa:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8001ae:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8001b1:	c9                   	leave  
  8001b2:	c3                   	ret    

008001b3 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8001b3:	55                   	push   %ebp
  8001b4:	89 e5                	mov    %esp,%ebp
  8001b6:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8001bc:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8001c3:	00 00 00 
	b.cnt = 0;
  8001c6:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8001cd:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8001d0:	ff 75 0c             	pushl  0xc(%ebp)
  8001d3:	ff 75 08             	pushl  0x8(%ebp)
  8001d6:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  8001dc:	50                   	push   %eax
  8001dd:	68 71 01 80 00       	push   $0x800171
  8001e2:	e8 1a 01 00 00       	call   800301 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  8001e7:	83 c4 08             	add    $0x8,%esp
  8001ea:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  8001f0:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  8001f6:	50                   	push   %eax
  8001f7:	e8 92 fe ff ff       	call   80008e <sys_cputs>

	return b.cnt;
}
  8001fc:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800202:	c9                   	leave  
  800203:	c3                   	ret    

00800204 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800204:	55                   	push   %ebp
  800205:	89 e5                	mov    %esp,%ebp
  800207:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  80020a:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  80020d:	50                   	push   %eax
  80020e:	ff 75 08             	pushl  0x8(%ebp)
  800211:	e8 9d ff ff ff       	call   8001b3 <vcprintf>
	va_end(ap);

	return cnt;
}
  800216:	c9                   	leave  
  800217:	c3                   	ret    

00800218 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800218:	55                   	push   %ebp
  800219:	89 e5                	mov    %esp,%ebp
  80021b:	57                   	push   %edi
  80021c:	56                   	push   %esi
  80021d:	53                   	push   %ebx
  80021e:	83 ec 1c             	sub    $0x1c,%esp
  800221:	89 c7                	mov    %eax,%edi
  800223:	89 d6                	mov    %edx,%esi
  800225:	8b 45 08             	mov    0x8(%ebp),%eax
  800228:	8b 55 0c             	mov    0xc(%ebp),%edx
  80022b:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80022e:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800231:	8b 4d 10             	mov    0x10(%ebp),%ecx
  800234:	bb 00 00 00 00       	mov    $0x0,%ebx
  800239:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  80023c:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  80023f:	39 d3                	cmp    %edx,%ebx
  800241:	72 05                	jb     800248 <printnum+0x30>
  800243:	39 45 10             	cmp    %eax,0x10(%ebp)
  800246:	77 45                	ja     80028d <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800248:	83 ec 0c             	sub    $0xc,%esp
  80024b:	ff 75 18             	pushl  0x18(%ebp)
  80024e:	8b 45 14             	mov    0x14(%ebp),%eax
  800251:	8d 58 ff             	lea    -0x1(%eax),%ebx
  800254:	53                   	push   %ebx
  800255:	ff 75 10             	pushl  0x10(%ebp)
  800258:	83 ec 08             	sub    $0x8,%esp
  80025b:	ff 75 e4             	pushl  -0x1c(%ebp)
  80025e:	ff 75 e0             	pushl  -0x20(%ebp)
  800261:	ff 75 dc             	pushl  -0x24(%ebp)
  800264:	ff 75 d8             	pushl  -0x28(%ebp)
  800267:	e8 e4 08 00 00       	call   800b50 <__udivdi3>
  80026c:	83 c4 18             	add    $0x18,%esp
  80026f:	52                   	push   %edx
  800270:	50                   	push   %eax
  800271:	89 f2                	mov    %esi,%edx
  800273:	89 f8                	mov    %edi,%eax
  800275:	e8 9e ff ff ff       	call   800218 <printnum>
  80027a:	83 c4 20             	add    $0x20,%esp
  80027d:	eb 18                	jmp    800297 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  80027f:	83 ec 08             	sub    $0x8,%esp
  800282:	56                   	push   %esi
  800283:	ff 75 18             	pushl  0x18(%ebp)
  800286:	ff d7                	call   *%edi
  800288:	83 c4 10             	add    $0x10,%esp
  80028b:	eb 03                	jmp    800290 <printnum+0x78>
  80028d:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800290:	83 eb 01             	sub    $0x1,%ebx
  800293:	85 db                	test   %ebx,%ebx
  800295:	7f e8                	jg     80027f <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  800297:	83 ec 08             	sub    $0x8,%esp
  80029a:	56                   	push   %esi
  80029b:	83 ec 04             	sub    $0x4,%esp
  80029e:	ff 75 e4             	pushl  -0x1c(%ebp)
  8002a1:	ff 75 e0             	pushl  -0x20(%ebp)
  8002a4:	ff 75 dc             	pushl  -0x24(%ebp)
  8002a7:	ff 75 d8             	pushl  -0x28(%ebp)
  8002aa:	e8 d1 09 00 00       	call   800c80 <__umoddi3>
  8002af:	83 c4 14             	add    $0x14,%esp
  8002b2:	0f be 80 3e 0e 80 00 	movsbl 0x800e3e(%eax),%eax
  8002b9:	50                   	push   %eax
  8002ba:	ff d7                	call   *%edi
}
  8002bc:	83 c4 10             	add    $0x10,%esp
  8002bf:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8002c2:	5b                   	pop    %ebx
  8002c3:	5e                   	pop    %esi
  8002c4:	5f                   	pop    %edi
  8002c5:	5d                   	pop    %ebp
  8002c6:	c3                   	ret    

008002c7 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8002c7:	55                   	push   %ebp
  8002c8:	89 e5                	mov    %esp,%ebp
  8002ca:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8002cd:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8002d1:	8b 10                	mov    (%eax),%edx
  8002d3:	3b 50 04             	cmp    0x4(%eax),%edx
  8002d6:	73 0a                	jae    8002e2 <sprintputch+0x1b>
		*b->buf++ = ch;
  8002d8:	8d 4a 01             	lea    0x1(%edx),%ecx
  8002db:	89 08                	mov    %ecx,(%eax)
  8002dd:	8b 45 08             	mov    0x8(%ebp),%eax
  8002e0:	88 02                	mov    %al,(%edx)
}
  8002e2:	5d                   	pop    %ebp
  8002e3:	c3                   	ret    

008002e4 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8002e4:	55                   	push   %ebp
  8002e5:	89 e5                	mov    %esp,%ebp
  8002e7:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  8002ea:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8002ed:	50                   	push   %eax
  8002ee:	ff 75 10             	pushl  0x10(%ebp)
  8002f1:	ff 75 0c             	pushl  0xc(%ebp)
  8002f4:	ff 75 08             	pushl  0x8(%ebp)
  8002f7:	e8 05 00 00 00       	call   800301 <vprintfmt>
	va_end(ap);
}
  8002fc:	83 c4 10             	add    $0x10,%esp
  8002ff:	c9                   	leave  
  800300:	c3                   	ret    

00800301 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800301:	55                   	push   %ebp
  800302:	89 e5                	mov    %esp,%ebp
  800304:	57                   	push   %edi
  800305:	56                   	push   %esi
  800306:	53                   	push   %ebx
  800307:	83 ec 2c             	sub    $0x2c,%esp
  80030a:	8b 75 08             	mov    0x8(%ebp),%esi
  80030d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800310:	8b 7d 10             	mov    0x10(%ebp),%edi
  800313:	eb 12                	jmp    800327 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800315:	85 c0                	test   %eax,%eax
  800317:	0f 84 42 04 00 00    	je     80075f <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
  80031d:	83 ec 08             	sub    $0x8,%esp
  800320:	53                   	push   %ebx
  800321:	50                   	push   %eax
  800322:	ff d6                	call   *%esi
  800324:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800327:	83 c7 01             	add    $0x1,%edi
  80032a:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  80032e:	83 f8 25             	cmp    $0x25,%eax
  800331:	75 e2                	jne    800315 <vprintfmt+0x14>
  800333:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  800337:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  80033e:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800345:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  80034c:	b9 00 00 00 00       	mov    $0x0,%ecx
  800351:	eb 07                	jmp    80035a <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800353:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  800356:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80035a:	8d 47 01             	lea    0x1(%edi),%eax
  80035d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800360:	0f b6 07             	movzbl (%edi),%eax
  800363:	0f b6 d0             	movzbl %al,%edx
  800366:	83 e8 23             	sub    $0x23,%eax
  800369:	3c 55                	cmp    $0x55,%al
  80036b:	0f 87 d3 03 00 00    	ja     800744 <vprintfmt+0x443>
  800371:	0f b6 c0             	movzbl %al,%eax
  800374:	ff 24 85 e0 0e 80 00 	jmp    *0x800ee0(,%eax,4)
  80037b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  80037e:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  800382:	eb d6                	jmp    80035a <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800384:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800387:	b8 00 00 00 00       	mov    $0x0,%eax
  80038c:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  80038f:	8d 04 80             	lea    (%eax,%eax,4),%eax
  800392:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
  800396:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
  800399:	8d 4a d0             	lea    -0x30(%edx),%ecx
  80039c:	83 f9 09             	cmp    $0x9,%ecx
  80039f:	77 3f                	ja     8003e0 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8003a1:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8003a4:	eb e9                	jmp    80038f <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8003a6:	8b 45 14             	mov    0x14(%ebp),%eax
  8003a9:	8b 00                	mov    (%eax),%eax
  8003ab:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8003ae:	8b 45 14             	mov    0x14(%ebp),%eax
  8003b1:	8d 40 04             	lea    0x4(%eax),%eax
  8003b4:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003b7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8003ba:	eb 2a                	jmp    8003e6 <vprintfmt+0xe5>
  8003bc:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8003bf:	85 c0                	test   %eax,%eax
  8003c1:	ba 00 00 00 00       	mov    $0x0,%edx
  8003c6:	0f 49 d0             	cmovns %eax,%edx
  8003c9:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003cc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003cf:	eb 89                	jmp    80035a <vprintfmt+0x59>
  8003d1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8003d4:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  8003db:	e9 7a ff ff ff       	jmp    80035a <vprintfmt+0x59>
  8003e0:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  8003e3:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  8003e6:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8003ea:	0f 89 6a ff ff ff    	jns    80035a <vprintfmt+0x59>
				width = precision, precision = -1;
  8003f0:	8b 45 d0             	mov    -0x30(%ebp),%eax
  8003f3:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8003f6:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8003fd:	e9 58 ff ff ff       	jmp    80035a <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800402:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800405:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  800408:	e9 4d ff ff ff       	jmp    80035a <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  80040d:	8b 45 14             	mov    0x14(%ebp),%eax
  800410:	8d 78 04             	lea    0x4(%eax),%edi
  800413:	83 ec 08             	sub    $0x8,%esp
  800416:	53                   	push   %ebx
  800417:	ff 30                	pushl  (%eax)
  800419:	ff d6                	call   *%esi
			break;
  80041b:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  80041e:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800421:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  800424:	e9 fe fe ff ff       	jmp    800327 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800429:	8b 45 14             	mov    0x14(%ebp),%eax
  80042c:	8d 78 04             	lea    0x4(%eax),%edi
  80042f:	8b 00                	mov    (%eax),%eax
  800431:	99                   	cltd   
  800432:	31 d0                	xor    %edx,%eax
  800434:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800436:	83 f8 07             	cmp    $0x7,%eax
  800439:	7f 0b                	jg     800446 <vprintfmt+0x145>
  80043b:	8b 14 85 40 10 80 00 	mov    0x801040(,%eax,4),%edx
  800442:	85 d2                	test   %edx,%edx
  800444:	75 1b                	jne    800461 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
  800446:	50                   	push   %eax
  800447:	68 56 0e 80 00       	push   $0x800e56
  80044c:	53                   	push   %ebx
  80044d:	56                   	push   %esi
  80044e:	e8 91 fe ff ff       	call   8002e4 <printfmt>
  800453:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  800456:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800459:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  80045c:	e9 c6 fe ff ff       	jmp    800327 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  800461:	52                   	push   %edx
  800462:	68 5f 0e 80 00       	push   $0x800e5f
  800467:	53                   	push   %ebx
  800468:	56                   	push   %esi
  800469:	e8 76 fe ff ff       	call   8002e4 <printfmt>
  80046e:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  800471:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800474:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800477:	e9 ab fe ff ff       	jmp    800327 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  80047c:	8b 45 14             	mov    0x14(%ebp),%eax
  80047f:	83 c0 04             	add    $0x4,%eax
  800482:	89 45 cc             	mov    %eax,-0x34(%ebp)
  800485:	8b 45 14             	mov    0x14(%ebp),%eax
  800488:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  80048a:	85 ff                	test   %edi,%edi
  80048c:	b8 4f 0e 80 00       	mov    $0x800e4f,%eax
  800491:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  800494:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800498:	0f 8e 94 00 00 00    	jle    800532 <vprintfmt+0x231>
  80049e:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  8004a2:	0f 84 98 00 00 00    	je     800540 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
  8004a8:	83 ec 08             	sub    $0x8,%esp
  8004ab:	ff 75 d0             	pushl  -0x30(%ebp)
  8004ae:	57                   	push   %edi
  8004af:	e8 33 03 00 00       	call   8007e7 <strnlen>
  8004b4:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8004b7:	29 c1                	sub    %eax,%ecx
  8004b9:	89 4d c8             	mov    %ecx,-0x38(%ebp)
  8004bc:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  8004bf:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  8004c3:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8004c6:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  8004c9:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004cb:	eb 0f                	jmp    8004dc <vprintfmt+0x1db>
					putch(padc, putdat);
  8004cd:	83 ec 08             	sub    $0x8,%esp
  8004d0:	53                   	push   %ebx
  8004d1:	ff 75 e0             	pushl  -0x20(%ebp)
  8004d4:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004d6:	83 ef 01             	sub    $0x1,%edi
  8004d9:	83 c4 10             	add    $0x10,%esp
  8004dc:	85 ff                	test   %edi,%edi
  8004de:	7f ed                	jg     8004cd <vprintfmt+0x1cc>
  8004e0:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  8004e3:	8b 4d c8             	mov    -0x38(%ebp),%ecx
  8004e6:	85 c9                	test   %ecx,%ecx
  8004e8:	b8 00 00 00 00       	mov    $0x0,%eax
  8004ed:	0f 49 c1             	cmovns %ecx,%eax
  8004f0:	29 c1                	sub    %eax,%ecx
  8004f2:	89 75 08             	mov    %esi,0x8(%ebp)
  8004f5:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8004f8:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8004fb:	89 cb                	mov    %ecx,%ebx
  8004fd:	eb 4d                	jmp    80054c <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  8004ff:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800503:	74 1b                	je     800520 <vprintfmt+0x21f>
  800505:	0f be c0             	movsbl %al,%eax
  800508:	83 e8 20             	sub    $0x20,%eax
  80050b:	83 f8 5e             	cmp    $0x5e,%eax
  80050e:	76 10                	jbe    800520 <vprintfmt+0x21f>
					putch('?', putdat);
  800510:	83 ec 08             	sub    $0x8,%esp
  800513:	ff 75 0c             	pushl  0xc(%ebp)
  800516:	6a 3f                	push   $0x3f
  800518:	ff 55 08             	call   *0x8(%ebp)
  80051b:	83 c4 10             	add    $0x10,%esp
  80051e:	eb 0d                	jmp    80052d <vprintfmt+0x22c>
				else
					putch(ch, putdat);
  800520:	83 ec 08             	sub    $0x8,%esp
  800523:	ff 75 0c             	pushl  0xc(%ebp)
  800526:	52                   	push   %edx
  800527:	ff 55 08             	call   *0x8(%ebp)
  80052a:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  80052d:	83 eb 01             	sub    $0x1,%ebx
  800530:	eb 1a                	jmp    80054c <vprintfmt+0x24b>
  800532:	89 75 08             	mov    %esi,0x8(%ebp)
  800535:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800538:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80053b:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  80053e:	eb 0c                	jmp    80054c <vprintfmt+0x24b>
  800540:	89 75 08             	mov    %esi,0x8(%ebp)
  800543:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800546:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800549:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  80054c:	83 c7 01             	add    $0x1,%edi
  80054f:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800553:	0f be d0             	movsbl %al,%edx
  800556:	85 d2                	test   %edx,%edx
  800558:	74 23                	je     80057d <vprintfmt+0x27c>
  80055a:	85 f6                	test   %esi,%esi
  80055c:	78 a1                	js     8004ff <vprintfmt+0x1fe>
  80055e:	83 ee 01             	sub    $0x1,%esi
  800561:	79 9c                	jns    8004ff <vprintfmt+0x1fe>
  800563:	89 df                	mov    %ebx,%edi
  800565:	8b 75 08             	mov    0x8(%ebp),%esi
  800568:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80056b:	eb 18                	jmp    800585 <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  80056d:	83 ec 08             	sub    $0x8,%esp
  800570:	53                   	push   %ebx
  800571:	6a 20                	push   $0x20
  800573:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800575:	83 ef 01             	sub    $0x1,%edi
  800578:	83 c4 10             	add    $0x10,%esp
  80057b:	eb 08                	jmp    800585 <vprintfmt+0x284>
  80057d:	89 df                	mov    %ebx,%edi
  80057f:	8b 75 08             	mov    0x8(%ebp),%esi
  800582:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800585:	85 ff                	test   %edi,%edi
  800587:	7f e4                	jg     80056d <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800589:	8b 45 cc             	mov    -0x34(%ebp),%eax
  80058c:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80058f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800592:	e9 90 fd ff ff       	jmp    800327 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800597:	83 f9 01             	cmp    $0x1,%ecx
  80059a:	7e 19                	jle    8005b5 <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
  80059c:	8b 45 14             	mov    0x14(%ebp),%eax
  80059f:	8b 50 04             	mov    0x4(%eax),%edx
  8005a2:	8b 00                	mov    (%eax),%eax
  8005a4:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005a7:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8005aa:	8b 45 14             	mov    0x14(%ebp),%eax
  8005ad:	8d 40 08             	lea    0x8(%eax),%eax
  8005b0:	89 45 14             	mov    %eax,0x14(%ebp)
  8005b3:	eb 38                	jmp    8005ed <vprintfmt+0x2ec>
	else if (lflag)
  8005b5:	85 c9                	test   %ecx,%ecx
  8005b7:	74 1b                	je     8005d4 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
  8005b9:	8b 45 14             	mov    0x14(%ebp),%eax
  8005bc:	8b 00                	mov    (%eax),%eax
  8005be:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005c1:	89 c1                	mov    %eax,%ecx
  8005c3:	c1 f9 1f             	sar    $0x1f,%ecx
  8005c6:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8005c9:	8b 45 14             	mov    0x14(%ebp),%eax
  8005cc:	8d 40 04             	lea    0x4(%eax),%eax
  8005cf:	89 45 14             	mov    %eax,0x14(%ebp)
  8005d2:	eb 19                	jmp    8005ed <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
  8005d4:	8b 45 14             	mov    0x14(%ebp),%eax
  8005d7:	8b 00                	mov    (%eax),%eax
  8005d9:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005dc:	89 c1                	mov    %eax,%ecx
  8005de:	c1 f9 1f             	sar    $0x1f,%ecx
  8005e1:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8005e4:	8b 45 14             	mov    0x14(%ebp),%eax
  8005e7:	8d 40 04             	lea    0x4(%eax),%eax
  8005ea:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  8005ed:	8b 55 d8             	mov    -0x28(%ebp),%edx
  8005f0:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  8005f3:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  8005f8:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  8005fc:	0f 89 0e 01 00 00    	jns    800710 <vprintfmt+0x40f>
				putch('-', putdat);
  800602:	83 ec 08             	sub    $0x8,%esp
  800605:	53                   	push   %ebx
  800606:	6a 2d                	push   $0x2d
  800608:	ff d6                	call   *%esi
				num = -(long long) num;
  80060a:	8b 55 d8             	mov    -0x28(%ebp),%edx
  80060d:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800610:	f7 da                	neg    %edx
  800612:	83 d1 00             	adc    $0x0,%ecx
  800615:	f7 d9                	neg    %ecx
  800617:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  80061a:	b8 0a 00 00 00       	mov    $0xa,%eax
  80061f:	e9 ec 00 00 00       	jmp    800710 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800624:	83 f9 01             	cmp    $0x1,%ecx
  800627:	7e 18                	jle    800641 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
  800629:	8b 45 14             	mov    0x14(%ebp),%eax
  80062c:	8b 10                	mov    (%eax),%edx
  80062e:	8b 48 04             	mov    0x4(%eax),%ecx
  800631:	8d 40 08             	lea    0x8(%eax),%eax
  800634:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800637:	b8 0a 00 00 00       	mov    $0xa,%eax
  80063c:	e9 cf 00 00 00       	jmp    800710 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  800641:	85 c9                	test   %ecx,%ecx
  800643:	74 1a                	je     80065f <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
  800645:	8b 45 14             	mov    0x14(%ebp),%eax
  800648:	8b 10                	mov    (%eax),%edx
  80064a:	b9 00 00 00 00       	mov    $0x0,%ecx
  80064f:	8d 40 04             	lea    0x4(%eax),%eax
  800652:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800655:	b8 0a 00 00 00       	mov    $0xa,%eax
  80065a:	e9 b1 00 00 00       	jmp    800710 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  80065f:	8b 45 14             	mov    0x14(%ebp),%eax
  800662:	8b 10                	mov    (%eax),%edx
  800664:	b9 00 00 00 00       	mov    $0x0,%ecx
  800669:	8d 40 04             	lea    0x4(%eax),%eax
  80066c:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  80066f:	b8 0a 00 00 00       	mov    $0xa,%eax
  800674:	e9 97 00 00 00       	jmp    800710 <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
  800679:	83 ec 08             	sub    $0x8,%esp
  80067c:	53                   	push   %ebx
  80067d:	6a 58                	push   $0x58
  80067f:	ff d6                	call   *%esi
			putch('X', putdat);
  800681:	83 c4 08             	add    $0x8,%esp
  800684:	53                   	push   %ebx
  800685:	6a 58                	push   $0x58
  800687:	ff d6                	call   *%esi
			putch('X', putdat);
  800689:	83 c4 08             	add    $0x8,%esp
  80068c:	53                   	push   %ebx
  80068d:	6a 58                	push   $0x58
  80068f:	ff d6                	call   *%esi
			break;
  800691:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800694:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
  800697:	e9 8b fc ff ff       	jmp    800327 <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
  80069c:	83 ec 08             	sub    $0x8,%esp
  80069f:	53                   	push   %ebx
  8006a0:	6a 30                	push   $0x30
  8006a2:	ff d6                	call   *%esi
			putch('x', putdat);
  8006a4:	83 c4 08             	add    $0x8,%esp
  8006a7:	53                   	push   %ebx
  8006a8:	6a 78                	push   $0x78
  8006aa:	ff d6                	call   *%esi
			num = (unsigned long long)
  8006ac:	8b 45 14             	mov    0x14(%ebp),%eax
  8006af:	8b 10                	mov    (%eax),%edx
  8006b1:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  8006b6:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  8006b9:	8d 40 04             	lea    0x4(%eax),%eax
  8006bc:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  8006bf:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
  8006c4:	eb 4a                	jmp    800710 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8006c6:	83 f9 01             	cmp    $0x1,%ecx
  8006c9:	7e 15                	jle    8006e0 <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
  8006cb:	8b 45 14             	mov    0x14(%ebp),%eax
  8006ce:	8b 10                	mov    (%eax),%edx
  8006d0:	8b 48 04             	mov    0x4(%eax),%ecx
  8006d3:	8d 40 08             	lea    0x8(%eax),%eax
  8006d6:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  8006d9:	b8 10 00 00 00       	mov    $0x10,%eax
  8006de:	eb 30                	jmp    800710 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  8006e0:	85 c9                	test   %ecx,%ecx
  8006e2:	74 17                	je     8006fb <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
  8006e4:	8b 45 14             	mov    0x14(%ebp),%eax
  8006e7:	8b 10                	mov    (%eax),%edx
  8006e9:	b9 00 00 00 00       	mov    $0x0,%ecx
  8006ee:	8d 40 04             	lea    0x4(%eax),%eax
  8006f1:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  8006f4:	b8 10 00 00 00       	mov    $0x10,%eax
  8006f9:	eb 15                	jmp    800710 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  8006fb:	8b 45 14             	mov    0x14(%ebp),%eax
  8006fe:	8b 10                	mov    (%eax),%edx
  800700:	b9 00 00 00 00       	mov    $0x0,%ecx
  800705:	8d 40 04             	lea    0x4(%eax),%eax
  800708:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  80070b:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
  800710:	83 ec 0c             	sub    $0xc,%esp
  800713:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  800717:	57                   	push   %edi
  800718:	ff 75 e0             	pushl  -0x20(%ebp)
  80071b:	50                   	push   %eax
  80071c:	51                   	push   %ecx
  80071d:	52                   	push   %edx
  80071e:	89 da                	mov    %ebx,%edx
  800720:	89 f0                	mov    %esi,%eax
  800722:	e8 f1 fa ff ff       	call   800218 <printnum>
			break;
  800727:	83 c4 20             	add    $0x20,%esp
  80072a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80072d:	e9 f5 fb ff ff       	jmp    800327 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  800732:	83 ec 08             	sub    $0x8,%esp
  800735:	53                   	push   %ebx
  800736:	52                   	push   %edx
  800737:	ff d6                	call   *%esi
			break;
  800739:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80073c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  80073f:	e9 e3 fb ff ff       	jmp    800327 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  800744:	83 ec 08             	sub    $0x8,%esp
  800747:	53                   	push   %ebx
  800748:	6a 25                	push   $0x25
  80074a:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  80074c:	83 c4 10             	add    $0x10,%esp
  80074f:	eb 03                	jmp    800754 <vprintfmt+0x453>
  800751:	83 ef 01             	sub    $0x1,%edi
  800754:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800758:	75 f7                	jne    800751 <vprintfmt+0x450>
  80075a:	e9 c8 fb ff ff       	jmp    800327 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  80075f:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800762:	5b                   	pop    %ebx
  800763:	5e                   	pop    %esi
  800764:	5f                   	pop    %edi
  800765:	5d                   	pop    %ebp
  800766:	c3                   	ret    

00800767 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800767:	55                   	push   %ebp
  800768:	89 e5                	mov    %esp,%ebp
  80076a:	83 ec 18             	sub    $0x18,%esp
  80076d:	8b 45 08             	mov    0x8(%ebp),%eax
  800770:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800773:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800776:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  80077a:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  80077d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800784:	85 c0                	test   %eax,%eax
  800786:	74 26                	je     8007ae <vsnprintf+0x47>
  800788:	85 d2                	test   %edx,%edx
  80078a:	7e 22                	jle    8007ae <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  80078c:	ff 75 14             	pushl  0x14(%ebp)
  80078f:	ff 75 10             	pushl  0x10(%ebp)
  800792:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800795:	50                   	push   %eax
  800796:	68 c7 02 80 00       	push   $0x8002c7
  80079b:	e8 61 fb ff ff       	call   800301 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  8007a0:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8007a3:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  8007a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8007a9:	83 c4 10             	add    $0x10,%esp
  8007ac:	eb 05                	jmp    8007b3 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  8007ae:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  8007b3:	c9                   	leave  
  8007b4:	c3                   	ret    

008007b5 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  8007b5:	55                   	push   %ebp
  8007b6:	89 e5                	mov    %esp,%ebp
  8007b8:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  8007bb:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  8007be:	50                   	push   %eax
  8007bf:	ff 75 10             	pushl  0x10(%ebp)
  8007c2:	ff 75 0c             	pushl  0xc(%ebp)
  8007c5:	ff 75 08             	pushl  0x8(%ebp)
  8007c8:	e8 9a ff ff ff       	call   800767 <vsnprintf>
	va_end(ap);

	return rc;
}
  8007cd:	c9                   	leave  
  8007ce:	c3                   	ret    

008007cf <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  8007cf:	55                   	push   %ebp
  8007d0:	89 e5                	mov    %esp,%ebp
  8007d2:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  8007d5:	b8 00 00 00 00       	mov    $0x0,%eax
  8007da:	eb 03                	jmp    8007df <strlen+0x10>
		n++;
  8007dc:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  8007df:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  8007e3:	75 f7                	jne    8007dc <strlen+0xd>
		n++;
	return n;
}
  8007e5:	5d                   	pop    %ebp
  8007e6:	c3                   	ret    

008007e7 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  8007e7:	55                   	push   %ebp
  8007e8:	89 e5                	mov    %esp,%ebp
  8007ea:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8007ed:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8007f0:	ba 00 00 00 00       	mov    $0x0,%edx
  8007f5:	eb 03                	jmp    8007fa <strnlen+0x13>
		n++;
  8007f7:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8007fa:	39 c2                	cmp    %eax,%edx
  8007fc:	74 08                	je     800806 <strnlen+0x1f>
  8007fe:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  800802:	75 f3                	jne    8007f7 <strnlen+0x10>
  800804:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  800806:	5d                   	pop    %ebp
  800807:	c3                   	ret    

00800808 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800808:	55                   	push   %ebp
  800809:	89 e5                	mov    %esp,%ebp
  80080b:	53                   	push   %ebx
  80080c:	8b 45 08             	mov    0x8(%ebp),%eax
  80080f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800812:	89 c2                	mov    %eax,%edx
  800814:	83 c2 01             	add    $0x1,%edx
  800817:	83 c1 01             	add    $0x1,%ecx
  80081a:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  80081e:	88 5a ff             	mov    %bl,-0x1(%edx)
  800821:	84 db                	test   %bl,%bl
  800823:	75 ef                	jne    800814 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800825:	5b                   	pop    %ebx
  800826:	5d                   	pop    %ebp
  800827:	c3                   	ret    

00800828 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800828:	55                   	push   %ebp
  800829:	89 e5                	mov    %esp,%ebp
  80082b:	53                   	push   %ebx
  80082c:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  80082f:	53                   	push   %ebx
  800830:	e8 9a ff ff ff       	call   8007cf <strlen>
  800835:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  800838:	ff 75 0c             	pushl  0xc(%ebp)
  80083b:	01 d8                	add    %ebx,%eax
  80083d:	50                   	push   %eax
  80083e:	e8 c5 ff ff ff       	call   800808 <strcpy>
	return dst;
}
  800843:	89 d8                	mov    %ebx,%eax
  800845:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800848:	c9                   	leave  
  800849:	c3                   	ret    

0080084a <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  80084a:	55                   	push   %ebp
  80084b:	89 e5                	mov    %esp,%ebp
  80084d:	56                   	push   %esi
  80084e:	53                   	push   %ebx
  80084f:	8b 75 08             	mov    0x8(%ebp),%esi
  800852:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800855:	89 f3                	mov    %esi,%ebx
  800857:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  80085a:	89 f2                	mov    %esi,%edx
  80085c:	eb 0f                	jmp    80086d <strncpy+0x23>
		*dst++ = *src;
  80085e:	83 c2 01             	add    $0x1,%edx
  800861:	0f b6 01             	movzbl (%ecx),%eax
  800864:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800867:	80 39 01             	cmpb   $0x1,(%ecx)
  80086a:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  80086d:	39 da                	cmp    %ebx,%edx
  80086f:	75 ed                	jne    80085e <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800871:	89 f0                	mov    %esi,%eax
  800873:	5b                   	pop    %ebx
  800874:	5e                   	pop    %esi
  800875:	5d                   	pop    %ebp
  800876:	c3                   	ret    

00800877 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800877:	55                   	push   %ebp
  800878:	89 e5                	mov    %esp,%ebp
  80087a:	56                   	push   %esi
  80087b:	53                   	push   %ebx
  80087c:	8b 75 08             	mov    0x8(%ebp),%esi
  80087f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800882:	8b 55 10             	mov    0x10(%ebp),%edx
  800885:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800887:	85 d2                	test   %edx,%edx
  800889:	74 21                	je     8008ac <strlcpy+0x35>
  80088b:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  80088f:	89 f2                	mov    %esi,%edx
  800891:	eb 09                	jmp    80089c <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800893:	83 c2 01             	add    $0x1,%edx
  800896:	83 c1 01             	add    $0x1,%ecx
  800899:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  80089c:	39 c2                	cmp    %eax,%edx
  80089e:	74 09                	je     8008a9 <strlcpy+0x32>
  8008a0:	0f b6 19             	movzbl (%ecx),%ebx
  8008a3:	84 db                	test   %bl,%bl
  8008a5:	75 ec                	jne    800893 <strlcpy+0x1c>
  8008a7:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  8008a9:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  8008ac:	29 f0                	sub    %esi,%eax
}
  8008ae:	5b                   	pop    %ebx
  8008af:	5e                   	pop    %esi
  8008b0:	5d                   	pop    %ebp
  8008b1:	c3                   	ret    

008008b2 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  8008b2:	55                   	push   %ebp
  8008b3:	89 e5                	mov    %esp,%ebp
  8008b5:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8008b8:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  8008bb:	eb 06                	jmp    8008c3 <strcmp+0x11>
		p++, q++;
  8008bd:	83 c1 01             	add    $0x1,%ecx
  8008c0:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  8008c3:	0f b6 01             	movzbl (%ecx),%eax
  8008c6:	84 c0                	test   %al,%al
  8008c8:	74 04                	je     8008ce <strcmp+0x1c>
  8008ca:	3a 02                	cmp    (%edx),%al
  8008cc:	74 ef                	je     8008bd <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  8008ce:	0f b6 c0             	movzbl %al,%eax
  8008d1:	0f b6 12             	movzbl (%edx),%edx
  8008d4:	29 d0                	sub    %edx,%eax
}
  8008d6:	5d                   	pop    %ebp
  8008d7:	c3                   	ret    

008008d8 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  8008d8:	55                   	push   %ebp
  8008d9:	89 e5                	mov    %esp,%ebp
  8008db:	53                   	push   %ebx
  8008dc:	8b 45 08             	mov    0x8(%ebp),%eax
  8008df:	8b 55 0c             	mov    0xc(%ebp),%edx
  8008e2:	89 c3                	mov    %eax,%ebx
  8008e4:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  8008e7:	eb 06                	jmp    8008ef <strncmp+0x17>
		n--, p++, q++;
  8008e9:	83 c0 01             	add    $0x1,%eax
  8008ec:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  8008ef:	39 d8                	cmp    %ebx,%eax
  8008f1:	74 15                	je     800908 <strncmp+0x30>
  8008f3:	0f b6 08             	movzbl (%eax),%ecx
  8008f6:	84 c9                	test   %cl,%cl
  8008f8:	74 04                	je     8008fe <strncmp+0x26>
  8008fa:	3a 0a                	cmp    (%edx),%cl
  8008fc:	74 eb                	je     8008e9 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  8008fe:	0f b6 00             	movzbl (%eax),%eax
  800901:	0f b6 12             	movzbl (%edx),%edx
  800904:	29 d0                	sub    %edx,%eax
  800906:	eb 05                	jmp    80090d <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800908:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  80090d:	5b                   	pop    %ebx
  80090e:	5d                   	pop    %ebp
  80090f:	c3                   	ret    

00800910 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800910:	55                   	push   %ebp
  800911:	89 e5                	mov    %esp,%ebp
  800913:	8b 45 08             	mov    0x8(%ebp),%eax
  800916:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  80091a:	eb 07                	jmp    800923 <strchr+0x13>
		if (*s == c)
  80091c:	38 ca                	cmp    %cl,%dl
  80091e:	74 0f                	je     80092f <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800920:	83 c0 01             	add    $0x1,%eax
  800923:	0f b6 10             	movzbl (%eax),%edx
  800926:	84 d2                	test   %dl,%dl
  800928:	75 f2                	jne    80091c <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  80092a:	b8 00 00 00 00       	mov    $0x0,%eax
}
  80092f:	5d                   	pop    %ebp
  800930:	c3                   	ret    

00800931 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800931:	55                   	push   %ebp
  800932:	89 e5                	mov    %esp,%ebp
  800934:	8b 45 08             	mov    0x8(%ebp),%eax
  800937:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  80093b:	eb 03                	jmp    800940 <strfind+0xf>
  80093d:	83 c0 01             	add    $0x1,%eax
  800940:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  800943:	38 ca                	cmp    %cl,%dl
  800945:	74 04                	je     80094b <strfind+0x1a>
  800947:	84 d2                	test   %dl,%dl
  800949:	75 f2                	jne    80093d <strfind+0xc>
			break;
	return (char *) s;
}
  80094b:	5d                   	pop    %ebp
  80094c:	c3                   	ret    

0080094d <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  80094d:	55                   	push   %ebp
  80094e:	89 e5                	mov    %esp,%ebp
  800950:	57                   	push   %edi
  800951:	56                   	push   %esi
  800952:	53                   	push   %ebx
  800953:	8b 7d 08             	mov    0x8(%ebp),%edi
  800956:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800959:	85 c9                	test   %ecx,%ecx
  80095b:	74 36                	je     800993 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  80095d:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800963:	75 28                	jne    80098d <memset+0x40>
  800965:	f6 c1 03             	test   $0x3,%cl
  800968:	75 23                	jne    80098d <memset+0x40>
		c &= 0xFF;
  80096a:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  80096e:	89 d3                	mov    %edx,%ebx
  800970:	c1 e3 08             	shl    $0x8,%ebx
  800973:	89 d6                	mov    %edx,%esi
  800975:	c1 e6 18             	shl    $0x18,%esi
  800978:	89 d0                	mov    %edx,%eax
  80097a:	c1 e0 10             	shl    $0x10,%eax
  80097d:	09 f0                	or     %esi,%eax
  80097f:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  800981:	89 d8                	mov    %ebx,%eax
  800983:	09 d0                	or     %edx,%eax
  800985:	c1 e9 02             	shr    $0x2,%ecx
  800988:	fc                   	cld    
  800989:	f3 ab                	rep stos %eax,%es:(%edi)
  80098b:	eb 06                	jmp    800993 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  80098d:	8b 45 0c             	mov    0xc(%ebp),%eax
  800990:	fc                   	cld    
  800991:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800993:	89 f8                	mov    %edi,%eax
  800995:	5b                   	pop    %ebx
  800996:	5e                   	pop    %esi
  800997:	5f                   	pop    %edi
  800998:	5d                   	pop    %ebp
  800999:	c3                   	ret    

0080099a <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  80099a:	55                   	push   %ebp
  80099b:	89 e5                	mov    %esp,%ebp
  80099d:	57                   	push   %edi
  80099e:	56                   	push   %esi
  80099f:	8b 45 08             	mov    0x8(%ebp),%eax
  8009a2:	8b 75 0c             	mov    0xc(%ebp),%esi
  8009a5:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  8009a8:	39 c6                	cmp    %eax,%esi
  8009aa:	73 35                	jae    8009e1 <memmove+0x47>
  8009ac:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  8009af:	39 d0                	cmp    %edx,%eax
  8009b1:	73 2e                	jae    8009e1 <memmove+0x47>
		s += n;
		d += n;
  8009b3:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  8009b6:	89 d6                	mov    %edx,%esi
  8009b8:	09 fe                	or     %edi,%esi
  8009ba:	f7 c6 03 00 00 00    	test   $0x3,%esi
  8009c0:	75 13                	jne    8009d5 <memmove+0x3b>
  8009c2:	f6 c1 03             	test   $0x3,%cl
  8009c5:	75 0e                	jne    8009d5 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  8009c7:	83 ef 04             	sub    $0x4,%edi
  8009ca:	8d 72 fc             	lea    -0x4(%edx),%esi
  8009cd:	c1 e9 02             	shr    $0x2,%ecx
  8009d0:	fd                   	std    
  8009d1:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  8009d3:	eb 09                	jmp    8009de <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  8009d5:	83 ef 01             	sub    $0x1,%edi
  8009d8:	8d 72 ff             	lea    -0x1(%edx),%esi
  8009db:	fd                   	std    
  8009dc:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  8009de:	fc                   	cld    
  8009df:	eb 1d                	jmp    8009fe <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  8009e1:	89 f2                	mov    %esi,%edx
  8009e3:	09 c2                	or     %eax,%edx
  8009e5:	f6 c2 03             	test   $0x3,%dl
  8009e8:	75 0f                	jne    8009f9 <memmove+0x5f>
  8009ea:	f6 c1 03             	test   $0x3,%cl
  8009ed:	75 0a                	jne    8009f9 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  8009ef:	c1 e9 02             	shr    $0x2,%ecx
  8009f2:	89 c7                	mov    %eax,%edi
  8009f4:	fc                   	cld    
  8009f5:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  8009f7:	eb 05                	jmp    8009fe <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  8009f9:	89 c7                	mov    %eax,%edi
  8009fb:	fc                   	cld    
  8009fc:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  8009fe:	5e                   	pop    %esi
  8009ff:	5f                   	pop    %edi
  800a00:	5d                   	pop    %ebp
  800a01:	c3                   	ret    

00800a02 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800a02:	55                   	push   %ebp
  800a03:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  800a05:	ff 75 10             	pushl  0x10(%ebp)
  800a08:	ff 75 0c             	pushl  0xc(%ebp)
  800a0b:	ff 75 08             	pushl  0x8(%ebp)
  800a0e:	e8 87 ff ff ff       	call   80099a <memmove>
}
  800a13:	c9                   	leave  
  800a14:	c3                   	ret    

00800a15 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800a15:	55                   	push   %ebp
  800a16:	89 e5                	mov    %esp,%ebp
  800a18:	56                   	push   %esi
  800a19:	53                   	push   %ebx
  800a1a:	8b 45 08             	mov    0x8(%ebp),%eax
  800a1d:	8b 55 0c             	mov    0xc(%ebp),%edx
  800a20:	89 c6                	mov    %eax,%esi
  800a22:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a25:	eb 1a                	jmp    800a41 <memcmp+0x2c>
		if (*s1 != *s2)
  800a27:	0f b6 08             	movzbl (%eax),%ecx
  800a2a:	0f b6 1a             	movzbl (%edx),%ebx
  800a2d:	38 d9                	cmp    %bl,%cl
  800a2f:	74 0a                	je     800a3b <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800a31:	0f b6 c1             	movzbl %cl,%eax
  800a34:	0f b6 db             	movzbl %bl,%ebx
  800a37:	29 d8                	sub    %ebx,%eax
  800a39:	eb 0f                	jmp    800a4a <memcmp+0x35>
		s1++, s2++;
  800a3b:	83 c0 01             	add    $0x1,%eax
  800a3e:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a41:	39 f0                	cmp    %esi,%eax
  800a43:	75 e2                	jne    800a27 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800a45:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800a4a:	5b                   	pop    %ebx
  800a4b:	5e                   	pop    %esi
  800a4c:	5d                   	pop    %ebp
  800a4d:	c3                   	ret    

00800a4e <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800a4e:	55                   	push   %ebp
  800a4f:	89 e5                	mov    %esp,%ebp
  800a51:	53                   	push   %ebx
  800a52:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  800a55:	89 c1                	mov    %eax,%ecx
  800a57:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  800a5a:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a5e:	eb 0a                	jmp    800a6a <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  800a60:	0f b6 10             	movzbl (%eax),%edx
  800a63:	39 da                	cmp    %ebx,%edx
  800a65:	74 07                	je     800a6e <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a67:	83 c0 01             	add    $0x1,%eax
  800a6a:	39 c8                	cmp    %ecx,%eax
  800a6c:	72 f2                	jb     800a60 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800a6e:	5b                   	pop    %ebx
  800a6f:	5d                   	pop    %ebp
  800a70:	c3                   	ret    

00800a71 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800a71:	55                   	push   %ebp
  800a72:	89 e5                	mov    %esp,%ebp
  800a74:	57                   	push   %edi
  800a75:	56                   	push   %esi
  800a76:	53                   	push   %ebx
  800a77:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a7a:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a7d:	eb 03                	jmp    800a82 <strtol+0x11>
		s++;
  800a7f:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a82:	0f b6 01             	movzbl (%ecx),%eax
  800a85:	3c 20                	cmp    $0x20,%al
  800a87:	74 f6                	je     800a7f <strtol+0xe>
  800a89:	3c 09                	cmp    $0x9,%al
  800a8b:	74 f2                	je     800a7f <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800a8d:	3c 2b                	cmp    $0x2b,%al
  800a8f:	75 0a                	jne    800a9b <strtol+0x2a>
		s++;
  800a91:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800a94:	bf 00 00 00 00       	mov    $0x0,%edi
  800a99:	eb 11                	jmp    800aac <strtol+0x3b>
  800a9b:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800aa0:	3c 2d                	cmp    $0x2d,%al
  800aa2:	75 08                	jne    800aac <strtol+0x3b>
		s++, neg = 1;
  800aa4:	83 c1 01             	add    $0x1,%ecx
  800aa7:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800aac:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800ab2:	75 15                	jne    800ac9 <strtol+0x58>
  800ab4:	80 39 30             	cmpb   $0x30,(%ecx)
  800ab7:	75 10                	jne    800ac9 <strtol+0x58>
  800ab9:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800abd:	75 7c                	jne    800b3b <strtol+0xca>
		s += 2, base = 16;
  800abf:	83 c1 02             	add    $0x2,%ecx
  800ac2:	bb 10 00 00 00       	mov    $0x10,%ebx
  800ac7:	eb 16                	jmp    800adf <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800ac9:	85 db                	test   %ebx,%ebx
  800acb:	75 12                	jne    800adf <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800acd:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800ad2:	80 39 30             	cmpb   $0x30,(%ecx)
  800ad5:	75 08                	jne    800adf <strtol+0x6e>
		s++, base = 8;
  800ad7:	83 c1 01             	add    $0x1,%ecx
  800ada:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800adf:	b8 00 00 00 00       	mov    $0x0,%eax
  800ae4:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800ae7:	0f b6 11             	movzbl (%ecx),%edx
  800aea:	8d 72 d0             	lea    -0x30(%edx),%esi
  800aed:	89 f3                	mov    %esi,%ebx
  800aef:	80 fb 09             	cmp    $0x9,%bl
  800af2:	77 08                	ja     800afc <strtol+0x8b>
			dig = *s - '0';
  800af4:	0f be d2             	movsbl %dl,%edx
  800af7:	83 ea 30             	sub    $0x30,%edx
  800afa:	eb 22                	jmp    800b1e <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800afc:	8d 72 9f             	lea    -0x61(%edx),%esi
  800aff:	89 f3                	mov    %esi,%ebx
  800b01:	80 fb 19             	cmp    $0x19,%bl
  800b04:	77 08                	ja     800b0e <strtol+0x9d>
			dig = *s - 'a' + 10;
  800b06:	0f be d2             	movsbl %dl,%edx
  800b09:	83 ea 57             	sub    $0x57,%edx
  800b0c:	eb 10                	jmp    800b1e <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800b0e:	8d 72 bf             	lea    -0x41(%edx),%esi
  800b11:	89 f3                	mov    %esi,%ebx
  800b13:	80 fb 19             	cmp    $0x19,%bl
  800b16:	77 16                	ja     800b2e <strtol+0xbd>
			dig = *s - 'A' + 10;
  800b18:	0f be d2             	movsbl %dl,%edx
  800b1b:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800b1e:	3b 55 10             	cmp    0x10(%ebp),%edx
  800b21:	7d 0b                	jge    800b2e <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800b23:	83 c1 01             	add    $0x1,%ecx
  800b26:	0f af 45 10          	imul   0x10(%ebp),%eax
  800b2a:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800b2c:	eb b9                	jmp    800ae7 <strtol+0x76>

	if (endptr)
  800b2e:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800b32:	74 0d                	je     800b41 <strtol+0xd0>
		*endptr = (char *) s;
  800b34:	8b 75 0c             	mov    0xc(%ebp),%esi
  800b37:	89 0e                	mov    %ecx,(%esi)
  800b39:	eb 06                	jmp    800b41 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800b3b:	85 db                	test   %ebx,%ebx
  800b3d:	74 98                	je     800ad7 <strtol+0x66>
  800b3f:	eb 9e                	jmp    800adf <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800b41:	89 c2                	mov    %eax,%edx
  800b43:	f7 da                	neg    %edx
  800b45:	85 ff                	test   %edi,%edi
  800b47:	0f 45 c2             	cmovne %edx,%eax
}
  800b4a:	5b                   	pop    %ebx
  800b4b:	5e                   	pop    %esi
  800b4c:	5f                   	pop    %edi
  800b4d:	5d                   	pop    %ebp
  800b4e:	c3                   	ret    
  800b4f:	90                   	nop

00800b50 <__udivdi3>:
  800b50:	55                   	push   %ebp
  800b51:	57                   	push   %edi
  800b52:	56                   	push   %esi
  800b53:	53                   	push   %ebx
  800b54:	83 ec 1c             	sub    $0x1c,%esp
  800b57:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  800b5b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  800b5f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  800b63:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800b67:	85 f6                	test   %esi,%esi
  800b69:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800b6d:	89 ca                	mov    %ecx,%edx
  800b6f:	89 f8                	mov    %edi,%eax
  800b71:	75 3d                	jne    800bb0 <__udivdi3+0x60>
  800b73:	39 cf                	cmp    %ecx,%edi
  800b75:	0f 87 c5 00 00 00    	ja     800c40 <__udivdi3+0xf0>
  800b7b:	85 ff                	test   %edi,%edi
  800b7d:	89 fd                	mov    %edi,%ebp
  800b7f:	75 0b                	jne    800b8c <__udivdi3+0x3c>
  800b81:	b8 01 00 00 00       	mov    $0x1,%eax
  800b86:	31 d2                	xor    %edx,%edx
  800b88:	f7 f7                	div    %edi
  800b8a:	89 c5                	mov    %eax,%ebp
  800b8c:	89 c8                	mov    %ecx,%eax
  800b8e:	31 d2                	xor    %edx,%edx
  800b90:	f7 f5                	div    %ebp
  800b92:	89 c1                	mov    %eax,%ecx
  800b94:	89 d8                	mov    %ebx,%eax
  800b96:	89 cf                	mov    %ecx,%edi
  800b98:	f7 f5                	div    %ebp
  800b9a:	89 c3                	mov    %eax,%ebx
  800b9c:	89 d8                	mov    %ebx,%eax
  800b9e:	89 fa                	mov    %edi,%edx
  800ba0:	83 c4 1c             	add    $0x1c,%esp
  800ba3:	5b                   	pop    %ebx
  800ba4:	5e                   	pop    %esi
  800ba5:	5f                   	pop    %edi
  800ba6:	5d                   	pop    %ebp
  800ba7:	c3                   	ret    
  800ba8:	90                   	nop
  800ba9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800bb0:	39 ce                	cmp    %ecx,%esi
  800bb2:	77 74                	ja     800c28 <__udivdi3+0xd8>
  800bb4:	0f bd fe             	bsr    %esi,%edi
  800bb7:	83 f7 1f             	xor    $0x1f,%edi
  800bba:	0f 84 98 00 00 00    	je     800c58 <__udivdi3+0x108>
  800bc0:	bb 20 00 00 00       	mov    $0x20,%ebx
  800bc5:	89 f9                	mov    %edi,%ecx
  800bc7:	89 c5                	mov    %eax,%ebp
  800bc9:	29 fb                	sub    %edi,%ebx
  800bcb:	d3 e6                	shl    %cl,%esi
  800bcd:	89 d9                	mov    %ebx,%ecx
  800bcf:	d3 ed                	shr    %cl,%ebp
  800bd1:	89 f9                	mov    %edi,%ecx
  800bd3:	d3 e0                	shl    %cl,%eax
  800bd5:	09 ee                	or     %ebp,%esi
  800bd7:	89 d9                	mov    %ebx,%ecx
  800bd9:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800bdd:	89 d5                	mov    %edx,%ebp
  800bdf:	8b 44 24 08          	mov    0x8(%esp),%eax
  800be3:	d3 ed                	shr    %cl,%ebp
  800be5:	89 f9                	mov    %edi,%ecx
  800be7:	d3 e2                	shl    %cl,%edx
  800be9:	89 d9                	mov    %ebx,%ecx
  800beb:	d3 e8                	shr    %cl,%eax
  800bed:	09 c2                	or     %eax,%edx
  800bef:	89 d0                	mov    %edx,%eax
  800bf1:	89 ea                	mov    %ebp,%edx
  800bf3:	f7 f6                	div    %esi
  800bf5:	89 d5                	mov    %edx,%ebp
  800bf7:	89 c3                	mov    %eax,%ebx
  800bf9:	f7 64 24 0c          	mull   0xc(%esp)
  800bfd:	39 d5                	cmp    %edx,%ebp
  800bff:	72 10                	jb     800c11 <__udivdi3+0xc1>
  800c01:	8b 74 24 08          	mov    0x8(%esp),%esi
  800c05:	89 f9                	mov    %edi,%ecx
  800c07:	d3 e6                	shl    %cl,%esi
  800c09:	39 c6                	cmp    %eax,%esi
  800c0b:	73 07                	jae    800c14 <__udivdi3+0xc4>
  800c0d:	39 d5                	cmp    %edx,%ebp
  800c0f:	75 03                	jne    800c14 <__udivdi3+0xc4>
  800c11:	83 eb 01             	sub    $0x1,%ebx
  800c14:	31 ff                	xor    %edi,%edi
  800c16:	89 d8                	mov    %ebx,%eax
  800c18:	89 fa                	mov    %edi,%edx
  800c1a:	83 c4 1c             	add    $0x1c,%esp
  800c1d:	5b                   	pop    %ebx
  800c1e:	5e                   	pop    %esi
  800c1f:	5f                   	pop    %edi
  800c20:	5d                   	pop    %ebp
  800c21:	c3                   	ret    
  800c22:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800c28:	31 ff                	xor    %edi,%edi
  800c2a:	31 db                	xor    %ebx,%ebx
  800c2c:	89 d8                	mov    %ebx,%eax
  800c2e:	89 fa                	mov    %edi,%edx
  800c30:	83 c4 1c             	add    $0x1c,%esp
  800c33:	5b                   	pop    %ebx
  800c34:	5e                   	pop    %esi
  800c35:	5f                   	pop    %edi
  800c36:	5d                   	pop    %ebp
  800c37:	c3                   	ret    
  800c38:	90                   	nop
  800c39:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800c40:	89 d8                	mov    %ebx,%eax
  800c42:	f7 f7                	div    %edi
  800c44:	31 ff                	xor    %edi,%edi
  800c46:	89 c3                	mov    %eax,%ebx
  800c48:	89 d8                	mov    %ebx,%eax
  800c4a:	89 fa                	mov    %edi,%edx
  800c4c:	83 c4 1c             	add    $0x1c,%esp
  800c4f:	5b                   	pop    %ebx
  800c50:	5e                   	pop    %esi
  800c51:	5f                   	pop    %edi
  800c52:	5d                   	pop    %ebp
  800c53:	c3                   	ret    
  800c54:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800c58:	39 ce                	cmp    %ecx,%esi
  800c5a:	72 0c                	jb     800c68 <__udivdi3+0x118>
  800c5c:	31 db                	xor    %ebx,%ebx
  800c5e:	3b 44 24 08          	cmp    0x8(%esp),%eax
  800c62:	0f 87 34 ff ff ff    	ja     800b9c <__udivdi3+0x4c>
  800c68:	bb 01 00 00 00       	mov    $0x1,%ebx
  800c6d:	e9 2a ff ff ff       	jmp    800b9c <__udivdi3+0x4c>
  800c72:	66 90                	xchg   %ax,%ax
  800c74:	66 90                	xchg   %ax,%ax
  800c76:	66 90                	xchg   %ax,%ax
  800c78:	66 90                	xchg   %ax,%ax
  800c7a:	66 90                	xchg   %ax,%ax
  800c7c:	66 90                	xchg   %ax,%ax
  800c7e:	66 90                	xchg   %ax,%ax

00800c80 <__umoddi3>:
  800c80:	55                   	push   %ebp
  800c81:	57                   	push   %edi
  800c82:	56                   	push   %esi
  800c83:	53                   	push   %ebx
  800c84:	83 ec 1c             	sub    $0x1c,%esp
  800c87:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  800c8b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  800c8f:	8b 74 24 34          	mov    0x34(%esp),%esi
  800c93:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800c97:	85 d2                	test   %edx,%edx
  800c99:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800c9d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800ca1:	89 f3                	mov    %esi,%ebx
  800ca3:	89 3c 24             	mov    %edi,(%esp)
  800ca6:	89 74 24 04          	mov    %esi,0x4(%esp)
  800caa:	75 1c                	jne    800cc8 <__umoddi3+0x48>
  800cac:	39 f7                	cmp    %esi,%edi
  800cae:	76 50                	jbe    800d00 <__umoddi3+0x80>
  800cb0:	89 c8                	mov    %ecx,%eax
  800cb2:	89 f2                	mov    %esi,%edx
  800cb4:	f7 f7                	div    %edi
  800cb6:	89 d0                	mov    %edx,%eax
  800cb8:	31 d2                	xor    %edx,%edx
  800cba:	83 c4 1c             	add    $0x1c,%esp
  800cbd:	5b                   	pop    %ebx
  800cbe:	5e                   	pop    %esi
  800cbf:	5f                   	pop    %edi
  800cc0:	5d                   	pop    %ebp
  800cc1:	c3                   	ret    
  800cc2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800cc8:	39 f2                	cmp    %esi,%edx
  800cca:	89 d0                	mov    %edx,%eax
  800ccc:	77 52                	ja     800d20 <__umoddi3+0xa0>
  800cce:	0f bd ea             	bsr    %edx,%ebp
  800cd1:	83 f5 1f             	xor    $0x1f,%ebp
  800cd4:	75 5a                	jne    800d30 <__umoddi3+0xb0>
  800cd6:	3b 54 24 04          	cmp    0x4(%esp),%edx
  800cda:	0f 82 e0 00 00 00    	jb     800dc0 <__umoddi3+0x140>
  800ce0:	39 0c 24             	cmp    %ecx,(%esp)
  800ce3:	0f 86 d7 00 00 00    	jbe    800dc0 <__umoddi3+0x140>
  800ce9:	8b 44 24 08          	mov    0x8(%esp),%eax
  800ced:	8b 54 24 04          	mov    0x4(%esp),%edx
  800cf1:	83 c4 1c             	add    $0x1c,%esp
  800cf4:	5b                   	pop    %ebx
  800cf5:	5e                   	pop    %esi
  800cf6:	5f                   	pop    %edi
  800cf7:	5d                   	pop    %ebp
  800cf8:	c3                   	ret    
  800cf9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800d00:	85 ff                	test   %edi,%edi
  800d02:	89 fd                	mov    %edi,%ebp
  800d04:	75 0b                	jne    800d11 <__umoddi3+0x91>
  800d06:	b8 01 00 00 00       	mov    $0x1,%eax
  800d0b:	31 d2                	xor    %edx,%edx
  800d0d:	f7 f7                	div    %edi
  800d0f:	89 c5                	mov    %eax,%ebp
  800d11:	89 f0                	mov    %esi,%eax
  800d13:	31 d2                	xor    %edx,%edx
  800d15:	f7 f5                	div    %ebp
  800d17:	89 c8                	mov    %ecx,%eax
  800d19:	f7 f5                	div    %ebp
  800d1b:	89 d0                	mov    %edx,%eax
  800d1d:	eb 99                	jmp    800cb8 <__umoddi3+0x38>
  800d1f:	90                   	nop
  800d20:	89 c8                	mov    %ecx,%eax
  800d22:	89 f2                	mov    %esi,%edx
  800d24:	83 c4 1c             	add    $0x1c,%esp
  800d27:	5b                   	pop    %ebx
  800d28:	5e                   	pop    %esi
  800d29:	5f                   	pop    %edi
  800d2a:	5d                   	pop    %ebp
  800d2b:	c3                   	ret    
  800d2c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800d30:	8b 34 24             	mov    (%esp),%esi
  800d33:	bf 20 00 00 00       	mov    $0x20,%edi
  800d38:	89 e9                	mov    %ebp,%ecx
  800d3a:	29 ef                	sub    %ebp,%edi
  800d3c:	d3 e0                	shl    %cl,%eax
  800d3e:	89 f9                	mov    %edi,%ecx
  800d40:	89 f2                	mov    %esi,%edx
  800d42:	d3 ea                	shr    %cl,%edx
  800d44:	89 e9                	mov    %ebp,%ecx
  800d46:	09 c2                	or     %eax,%edx
  800d48:	89 d8                	mov    %ebx,%eax
  800d4a:	89 14 24             	mov    %edx,(%esp)
  800d4d:	89 f2                	mov    %esi,%edx
  800d4f:	d3 e2                	shl    %cl,%edx
  800d51:	89 f9                	mov    %edi,%ecx
  800d53:	89 54 24 04          	mov    %edx,0x4(%esp)
  800d57:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800d5b:	d3 e8                	shr    %cl,%eax
  800d5d:	89 e9                	mov    %ebp,%ecx
  800d5f:	89 c6                	mov    %eax,%esi
  800d61:	d3 e3                	shl    %cl,%ebx
  800d63:	89 f9                	mov    %edi,%ecx
  800d65:	89 d0                	mov    %edx,%eax
  800d67:	d3 e8                	shr    %cl,%eax
  800d69:	89 e9                	mov    %ebp,%ecx
  800d6b:	09 d8                	or     %ebx,%eax
  800d6d:	89 d3                	mov    %edx,%ebx
  800d6f:	89 f2                	mov    %esi,%edx
  800d71:	f7 34 24             	divl   (%esp)
  800d74:	89 d6                	mov    %edx,%esi
  800d76:	d3 e3                	shl    %cl,%ebx
  800d78:	f7 64 24 04          	mull   0x4(%esp)
  800d7c:	39 d6                	cmp    %edx,%esi
  800d7e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800d82:	89 d1                	mov    %edx,%ecx
  800d84:	89 c3                	mov    %eax,%ebx
  800d86:	72 08                	jb     800d90 <__umoddi3+0x110>
  800d88:	75 11                	jne    800d9b <__umoddi3+0x11b>
  800d8a:	39 44 24 08          	cmp    %eax,0x8(%esp)
  800d8e:	73 0b                	jae    800d9b <__umoddi3+0x11b>
  800d90:	2b 44 24 04          	sub    0x4(%esp),%eax
  800d94:	1b 14 24             	sbb    (%esp),%edx
  800d97:	89 d1                	mov    %edx,%ecx
  800d99:	89 c3                	mov    %eax,%ebx
  800d9b:	8b 54 24 08          	mov    0x8(%esp),%edx
  800d9f:	29 da                	sub    %ebx,%edx
  800da1:	19 ce                	sbb    %ecx,%esi
  800da3:	89 f9                	mov    %edi,%ecx
  800da5:	89 f0                	mov    %esi,%eax
  800da7:	d3 e0                	shl    %cl,%eax
  800da9:	89 e9                	mov    %ebp,%ecx
  800dab:	d3 ea                	shr    %cl,%edx
  800dad:	89 e9                	mov    %ebp,%ecx
  800daf:	d3 ee                	shr    %cl,%esi
  800db1:	09 d0                	or     %edx,%eax
  800db3:	89 f2                	mov    %esi,%edx
  800db5:	83 c4 1c             	add    $0x1c,%esp
  800db8:	5b                   	pop    %ebx
  800db9:	5e                   	pop    %esi
  800dba:	5f                   	pop    %edi
  800dbb:	5d                   	pop    %ebp
  800dbc:	c3                   	ret    
  800dbd:	8d 76 00             	lea    0x0(%esi),%esi
  800dc0:	29 f9                	sub    %edi,%ecx
  800dc2:	19 d6                	sbb    %edx,%esi
  800dc4:	89 74 24 04          	mov    %esi,0x4(%esp)
  800dc8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800dcc:	e9 18 ff ff ff       	jmp    800ce9 <__umoddi3+0x69>
