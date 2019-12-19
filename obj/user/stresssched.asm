
obj/user/stresssched：     文件格式 elf32-i386


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
  80002c:	e8 d6 00 00 00       	call   800107 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

volatile int counter;

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	56                   	push   %esi
  800037:	53                   	push   %ebx
	int i, j;
	int seen;
	envid_t parent = thisenv->env_id;
  800038:	a1 08 20 80 00       	mov    0x802008,%eax
  80003d:	8b 70 48             	mov    0x48(%eax),%esi

	// Fork several environments
	for (i = 0; i < 20; i++)
  800040:	bb 00 00 00 00       	mov    $0x0,%ebx
	{
		cprintf("CPU:%d  ",thisenv->env_cpunum);
  800045:	a1 08 20 80 00       	mov    0x802008,%eax
  80004a:	8b 40 5c             	mov    0x5c(%eax),%eax
  80004d:	83 ec 08             	sub    $0x8,%esp
  800050:	50                   	push   %eax
  800051:	68 e0 13 80 00       	push   $0x8013e0
  800056:	e8 dd 01 00 00       	call   800238 <cprintf>
		if (fork() == 0)
  80005b:	e8 81 0e 00 00       	call   800ee1 <fork>
  800060:	83 c4 10             	add    $0x10,%esp
  800063:	85 c0                	test   %eax,%eax
  800065:	74 0a                	je     800071 <umain+0x3e>
	int i, j;
	int seen;
	envid_t parent = thisenv->env_id;

	// Fork several environments
	for (i = 0; i < 20; i++)
  800067:	83 c3 01             	add    $0x1,%ebx
  80006a:	83 fb 14             	cmp    $0x14,%ebx
  80006d:	75 d6                	jne    800045 <umain+0x12>
  80006f:	eb 05                	jmp    800076 <umain+0x43>
	{
		cprintf("CPU:%d  ",thisenv->env_cpunum);
		if (fork() == 0)
			break;
	}
	if (i == 20) {
  800071:	83 fb 14             	cmp    $0x14,%ebx
  800074:	75 0e                	jne    800084 <umain+0x51>
		sys_yield();
  800076:	e8 a5 0b 00 00       	call   800c20 <sys_yield>
		return;
  80007b:	e9 80 00 00 00       	jmp    800100 <umain+0xcd>
	}

	// Wait for the parent to finish forking
	while (envs[ENVX(parent)].env_status != ENV_FREE)
		asm volatile("pause");
  800080:	f3 90                	pause  
  800082:	eb 0f                	jmp    800093 <umain+0x60>
		sys_yield();
		return;
	}

	// Wait for the parent to finish forking
	while (envs[ENVX(parent)].env_status != ENV_FREE)
  800084:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
  80008a:	6b d6 7c             	imul   $0x7c,%esi,%edx
  80008d:	81 c2 00 00 c0 ee    	add    $0xeec00000,%edx
  800093:	8b 42 54             	mov    0x54(%edx),%eax
  800096:	85 c0                	test   %eax,%eax
  800098:	75 e6                	jne    800080 <umain+0x4d>
  80009a:	bb 0a 00 00 00       	mov    $0xa,%ebx
		asm volatile("pause");

	// Check that one environment doesn't run on two CPUs at once
	for (i = 0; i < 10; i++) {
		sys_yield();
  80009f:	e8 7c 0b 00 00       	call   800c20 <sys_yield>
  8000a4:	ba 10 27 00 00       	mov    $0x2710,%edx
		for (j = 0; j < 10000; j++)
			counter++;
  8000a9:	a1 04 20 80 00       	mov    0x802004,%eax
  8000ae:	83 c0 01             	add    $0x1,%eax
  8000b1:	a3 04 20 80 00       	mov    %eax,0x802004
		asm volatile("pause");

	// Check that one environment doesn't run on two CPUs at once
	for (i = 0; i < 10; i++) {
		sys_yield();
		for (j = 0; j < 10000; j++)
  8000b6:	83 ea 01             	sub    $0x1,%edx
  8000b9:	75 ee                	jne    8000a9 <umain+0x76>
	// Wait for the parent to finish forking
	while (envs[ENVX(parent)].env_status != ENV_FREE)
		asm volatile("pause");

	// Check that one environment doesn't run on two CPUs at once
	for (i = 0; i < 10; i++) {
  8000bb:	83 eb 01             	sub    $0x1,%ebx
  8000be:	75 df                	jne    80009f <umain+0x6c>
		sys_yield();
		for (j = 0; j < 10000; j++)
			counter++;
	}

	if (counter != 10*10000)
  8000c0:	a1 04 20 80 00       	mov    0x802004,%eax
  8000c5:	3d a0 86 01 00       	cmp    $0x186a0,%eax
  8000ca:	74 17                	je     8000e3 <umain+0xb0>
		panic("ran on two CPUs at once (counter is %d)", counter);
  8000cc:	a1 04 20 80 00       	mov    0x802004,%eax
  8000d1:	50                   	push   %eax
  8000d2:	68 1c 14 80 00       	push   $0x80141c
  8000d7:	6a 24                	push   $0x24
  8000d9:	68 e9 13 80 00       	push   $0x8013e9
  8000de:	e8 7c 00 00 00       	call   80015f <_panic>

	// Check that we see environments running on different CPUs
	cprintf("[%08x] stresssched on CPU %d\n", thisenv->env_id, thisenv->env_cpunum);
  8000e3:	a1 08 20 80 00       	mov    0x802008,%eax
  8000e8:	8b 50 5c             	mov    0x5c(%eax),%edx
  8000eb:	8b 40 48             	mov    0x48(%eax),%eax
  8000ee:	83 ec 04             	sub    $0x4,%esp
  8000f1:	52                   	push   %edx
  8000f2:	50                   	push   %eax
  8000f3:	68 fc 13 80 00       	push   $0x8013fc
  8000f8:	e8 3b 01 00 00       	call   800238 <cprintf>
  8000fd:	83 c4 10             	add    $0x10,%esp

}
  800100:	8d 65 f8             	lea    -0x8(%ebp),%esp
  800103:	5b                   	pop    %ebx
  800104:	5e                   	pop    %esi
  800105:	5d                   	pop    %ebp
  800106:	c3                   	ret    

00800107 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800107:	55                   	push   %ebp
  800108:	89 e5                	mov    %esp,%ebp
  80010a:	56                   	push   %esi
  80010b:	53                   	push   %ebx
  80010c:	8b 5d 08             	mov    0x8(%ebp),%ebx
  80010f:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = &envs[ENVX(sys_getenvid())];
  800112:	e8 ea 0a 00 00       	call   800c01 <sys_getenvid>
  800117:	25 ff 03 00 00       	and    $0x3ff,%eax
  80011c:	6b c0 7c             	imul   $0x7c,%eax,%eax
  80011f:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  800124:	a3 08 20 80 00       	mov    %eax,0x802008
	// save the name of the program so that panic() can use it
	if (argc > 0)
  800129:	85 db                	test   %ebx,%ebx
  80012b:	7e 07                	jle    800134 <libmain+0x2d>
		binaryname = argv[0];
  80012d:	8b 06                	mov    (%esi),%eax
  80012f:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  800134:	83 ec 08             	sub    $0x8,%esp
  800137:	56                   	push   %esi
  800138:	53                   	push   %ebx
  800139:	e8 f5 fe ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  80013e:	e8 0a 00 00 00       	call   80014d <exit>
}
  800143:	83 c4 10             	add    $0x10,%esp
  800146:	8d 65 f8             	lea    -0x8(%ebp),%esp
  800149:	5b                   	pop    %ebx
  80014a:	5e                   	pop    %esi
  80014b:	5d                   	pop    %ebp
  80014c:	c3                   	ret    

0080014d <exit>:

#include <inc/lib.h>

void
exit(void)
{
  80014d:	55                   	push   %ebp
  80014e:	89 e5                	mov    %esp,%ebp
  800150:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  800153:	6a 00                	push   $0x0
  800155:	e8 66 0a 00 00       	call   800bc0 <sys_env_destroy>
}
  80015a:	83 c4 10             	add    $0x10,%esp
  80015d:	c9                   	leave  
  80015e:	c3                   	ret    

0080015f <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  80015f:	55                   	push   %ebp
  800160:	89 e5                	mov    %esp,%ebp
  800162:	56                   	push   %esi
  800163:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800164:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800167:	8b 35 00 20 80 00    	mov    0x802000,%esi
  80016d:	e8 8f 0a 00 00       	call   800c01 <sys_getenvid>
  800172:	83 ec 0c             	sub    $0xc,%esp
  800175:	ff 75 0c             	pushl  0xc(%ebp)
  800178:	ff 75 08             	pushl  0x8(%ebp)
  80017b:	56                   	push   %esi
  80017c:	50                   	push   %eax
  80017d:	68 50 14 80 00       	push   $0x801450
  800182:	e8 b1 00 00 00       	call   800238 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800187:	83 c4 18             	add    $0x18,%esp
  80018a:	53                   	push   %ebx
  80018b:	ff 75 10             	pushl  0x10(%ebp)
  80018e:	e8 54 00 00 00       	call   8001e7 <vcprintf>
	cprintf("\n");
  800193:	c7 04 24 18 14 80 00 	movl   $0x801418,(%esp)
  80019a:	e8 99 00 00 00       	call   800238 <cprintf>
  80019f:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  8001a2:	cc                   	int3   
  8001a3:	eb fd                	jmp    8001a2 <_panic+0x43>

008001a5 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8001a5:	55                   	push   %ebp
  8001a6:	89 e5                	mov    %esp,%ebp
  8001a8:	53                   	push   %ebx
  8001a9:	83 ec 04             	sub    $0x4,%esp
  8001ac:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8001af:	8b 13                	mov    (%ebx),%edx
  8001b1:	8d 42 01             	lea    0x1(%edx),%eax
  8001b4:	89 03                	mov    %eax,(%ebx)
  8001b6:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8001b9:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8001bd:	3d ff 00 00 00       	cmp    $0xff,%eax
  8001c2:	75 1a                	jne    8001de <putch+0x39>
		sys_cputs(b->buf, b->idx);
  8001c4:	83 ec 08             	sub    $0x8,%esp
  8001c7:	68 ff 00 00 00       	push   $0xff
  8001cc:	8d 43 08             	lea    0x8(%ebx),%eax
  8001cf:	50                   	push   %eax
  8001d0:	e8 ae 09 00 00       	call   800b83 <sys_cputs>
		b->idx = 0;
  8001d5:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8001db:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8001de:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8001e2:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8001e5:	c9                   	leave  
  8001e6:	c3                   	ret    

008001e7 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8001e7:	55                   	push   %ebp
  8001e8:	89 e5                	mov    %esp,%ebp
  8001ea:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8001f0:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8001f7:	00 00 00 
	b.cnt = 0;
  8001fa:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800201:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800204:	ff 75 0c             	pushl  0xc(%ebp)
  800207:	ff 75 08             	pushl  0x8(%ebp)
  80020a:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800210:	50                   	push   %eax
  800211:	68 a5 01 80 00       	push   $0x8001a5
  800216:	e8 1a 01 00 00       	call   800335 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  80021b:	83 c4 08             	add    $0x8,%esp
  80021e:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  800224:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  80022a:	50                   	push   %eax
  80022b:	e8 53 09 00 00       	call   800b83 <sys_cputs>

	return b.cnt;
}
  800230:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800236:	c9                   	leave  
  800237:	c3                   	ret    

00800238 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800238:	55                   	push   %ebp
  800239:	89 e5                	mov    %esp,%ebp
  80023b:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  80023e:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800241:	50                   	push   %eax
  800242:	ff 75 08             	pushl  0x8(%ebp)
  800245:	e8 9d ff ff ff       	call   8001e7 <vcprintf>
	va_end(ap);

	return cnt;
}
  80024a:	c9                   	leave  
  80024b:	c3                   	ret    

0080024c <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  80024c:	55                   	push   %ebp
  80024d:	89 e5                	mov    %esp,%ebp
  80024f:	57                   	push   %edi
  800250:	56                   	push   %esi
  800251:	53                   	push   %ebx
  800252:	83 ec 1c             	sub    $0x1c,%esp
  800255:	89 c7                	mov    %eax,%edi
  800257:	89 d6                	mov    %edx,%esi
  800259:	8b 45 08             	mov    0x8(%ebp),%eax
  80025c:	8b 55 0c             	mov    0xc(%ebp),%edx
  80025f:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800262:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800265:	8b 4d 10             	mov    0x10(%ebp),%ecx
  800268:	bb 00 00 00 00       	mov    $0x0,%ebx
  80026d:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800270:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800273:	39 d3                	cmp    %edx,%ebx
  800275:	72 05                	jb     80027c <printnum+0x30>
  800277:	39 45 10             	cmp    %eax,0x10(%ebp)
  80027a:	77 45                	ja     8002c1 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  80027c:	83 ec 0c             	sub    $0xc,%esp
  80027f:	ff 75 18             	pushl  0x18(%ebp)
  800282:	8b 45 14             	mov    0x14(%ebp),%eax
  800285:	8d 58 ff             	lea    -0x1(%eax),%ebx
  800288:	53                   	push   %ebx
  800289:	ff 75 10             	pushl  0x10(%ebp)
  80028c:	83 ec 08             	sub    $0x8,%esp
  80028f:	ff 75 e4             	pushl  -0x1c(%ebp)
  800292:	ff 75 e0             	pushl  -0x20(%ebp)
  800295:	ff 75 dc             	pushl  -0x24(%ebp)
  800298:	ff 75 d8             	pushl  -0x28(%ebp)
  80029b:	e8 b0 0e 00 00       	call   801150 <__udivdi3>
  8002a0:	83 c4 18             	add    $0x18,%esp
  8002a3:	52                   	push   %edx
  8002a4:	50                   	push   %eax
  8002a5:	89 f2                	mov    %esi,%edx
  8002a7:	89 f8                	mov    %edi,%eax
  8002a9:	e8 9e ff ff ff       	call   80024c <printnum>
  8002ae:	83 c4 20             	add    $0x20,%esp
  8002b1:	eb 18                	jmp    8002cb <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8002b3:	83 ec 08             	sub    $0x8,%esp
  8002b6:	56                   	push   %esi
  8002b7:	ff 75 18             	pushl  0x18(%ebp)
  8002ba:	ff d7                	call   *%edi
  8002bc:	83 c4 10             	add    $0x10,%esp
  8002bf:	eb 03                	jmp    8002c4 <printnum+0x78>
  8002c1:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8002c4:	83 eb 01             	sub    $0x1,%ebx
  8002c7:	85 db                	test   %ebx,%ebx
  8002c9:	7f e8                	jg     8002b3 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8002cb:	83 ec 08             	sub    $0x8,%esp
  8002ce:	56                   	push   %esi
  8002cf:	83 ec 04             	sub    $0x4,%esp
  8002d2:	ff 75 e4             	pushl  -0x1c(%ebp)
  8002d5:	ff 75 e0             	pushl  -0x20(%ebp)
  8002d8:	ff 75 dc             	pushl  -0x24(%ebp)
  8002db:	ff 75 d8             	pushl  -0x28(%ebp)
  8002de:	e8 9d 0f 00 00       	call   801280 <__umoddi3>
  8002e3:	83 c4 14             	add    $0x14,%esp
  8002e6:	0f be 80 73 14 80 00 	movsbl 0x801473(%eax),%eax
  8002ed:	50                   	push   %eax
  8002ee:	ff d7                	call   *%edi
}
  8002f0:	83 c4 10             	add    $0x10,%esp
  8002f3:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8002f6:	5b                   	pop    %ebx
  8002f7:	5e                   	pop    %esi
  8002f8:	5f                   	pop    %edi
  8002f9:	5d                   	pop    %ebp
  8002fa:	c3                   	ret    

008002fb <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8002fb:	55                   	push   %ebp
  8002fc:	89 e5                	mov    %esp,%ebp
  8002fe:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  800301:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800305:	8b 10                	mov    (%eax),%edx
  800307:	3b 50 04             	cmp    0x4(%eax),%edx
  80030a:	73 0a                	jae    800316 <sprintputch+0x1b>
		*b->buf++ = ch;
  80030c:	8d 4a 01             	lea    0x1(%edx),%ecx
  80030f:	89 08                	mov    %ecx,(%eax)
  800311:	8b 45 08             	mov    0x8(%ebp),%eax
  800314:	88 02                	mov    %al,(%edx)
}
  800316:	5d                   	pop    %ebp
  800317:	c3                   	ret    

00800318 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800318:	55                   	push   %ebp
  800319:	89 e5                	mov    %esp,%ebp
  80031b:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  80031e:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  800321:	50                   	push   %eax
  800322:	ff 75 10             	pushl  0x10(%ebp)
  800325:	ff 75 0c             	pushl  0xc(%ebp)
  800328:	ff 75 08             	pushl  0x8(%ebp)
  80032b:	e8 05 00 00 00       	call   800335 <vprintfmt>
	va_end(ap);
}
  800330:	83 c4 10             	add    $0x10,%esp
  800333:	c9                   	leave  
  800334:	c3                   	ret    

00800335 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800335:	55                   	push   %ebp
  800336:	89 e5                	mov    %esp,%ebp
  800338:	57                   	push   %edi
  800339:	56                   	push   %esi
  80033a:	53                   	push   %ebx
  80033b:	83 ec 2c             	sub    $0x2c,%esp
  80033e:	8b 75 08             	mov    0x8(%ebp),%esi
  800341:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800344:	8b 7d 10             	mov    0x10(%ebp),%edi
  800347:	eb 12                	jmp    80035b <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800349:	85 c0                	test   %eax,%eax
  80034b:	0f 84 42 04 00 00    	je     800793 <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
  800351:	83 ec 08             	sub    $0x8,%esp
  800354:	53                   	push   %ebx
  800355:	50                   	push   %eax
  800356:	ff d6                	call   *%esi
  800358:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  80035b:	83 c7 01             	add    $0x1,%edi
  80035e:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800362:	83 f8 25             	cmp    $0x25,%eax
  800365:	75 e2                	jne    800349 <vprintfmt+0x14>
  800367:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  80036b:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  800372:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800379:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  800380:	b9 00 00 00 00       	mov    $0x0,%ecx
  800385:	eb 07                	jmp    80038e <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800387:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  80038a:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80038e:	8d 47 01             	lea    0x1(%edi),%eax
  800391:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800394:	0f b6 07             	movzbl (%edi),%eax
  800397:	0f b6 d0             	movzbl %al,%edx
  80039a:	83 e8 23             	sub    $0x23,%eax
  80039d:	3c 55                	cmp    $0x55,%al
  80039f:	0f 87 d3 03 00 00    	ja     800778 <vprintfmt+0x443>
  8003a5:	0f b6 c0             	movzbl %al,%eax
  8003a8:	ff 24 85 40 15 80 00 	jmp    *0x801540(,%eax,4)
  8003af:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  8003b2:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  8003b6:	eb d6                	jmp    80038e <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003b8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003bb:	b8 00 00 00 00       	mov    $0x0,%eax
  8003c0:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  8003c3:	8d 04 80             	lea    (%eax,%eax,4),%eax
  8003c6:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
  8003ca:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
  8003cd:	8d 4a d0             	lea    -0x30(%edx),%ecx
  8003d0:	83 f9 09             	cmp    $0x9,%ecx
  8003d3:	77 3f                	ja     800414 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8003d5:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8003d8:	eb e9                	jmp    8003c3 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8003da:	8b 45 14             	mov    0x14(%ebp),%eax
  8003dd:	8b 00                	mov    (%eax),%eax
  8003df:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8003e2:	8b 45 14             	mov    0x14(%ebp),%eax
  8003e5:	8d 40 04             	lea    0x4(%eax),%eax
  8003e8:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003eb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8003ee:	eb 2a                	jmp    80041a <vprintfmt+0xe5>
  8003f0:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8003f3:	85 c0                	test   %eax,%eax
  8003f5:	ba 00 00 00 00       	mov    $0x0,%edx
  8003fa:	0f 49 d0             	cmovns %eax,%edx
  8003fd:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800400:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800403:	eb 89                	jmp    80038e <vprintfmt+0x59>
  800405:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  800408:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  80040f:	e9 7a ff ff ff       	jmp    80038e <vprintfmt+0x59>
  800414:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  800417:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  80041a:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  80041e:	0f 89 6a ff ff ff    	jns    80038e <vprintfmt+0x59>
				width = precision, precision = -1;
  800424:	8b 45 d0             	mov    -0x30(%ebp),%eax
  800427:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80042a:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800431:	e9 58 ff ff ff       	jmp    80038e <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800436:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800439:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  80043c:	e9 4d ff ff ff       	jmp    80038e <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800441:	8b 45 14             	mov    0x14(%ebp),%eax
  800444:	8d 78 04             	lea    0x4(%eax),%edi
  800447:	83 ec 08             	sub    $0x8,%esp
  80044a:	53                   	push   %ebx
  80044b:	ff 30                	pushl  (%eax)
  80044d:	ff d6                	call   *%esi
			break;
  80044f:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800452:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800455:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  800458:	e9 fe fe ff ff       	jmp    80035b <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  80045d:	8b 45 14             	mov    0x14(%ebp),%eax
  800460:	8d 78 04             	lea    0x4(%eax),%edi
  800463:	8b 00                	mov    (%eax),%eax
  800465:	99                   	cltd   
  800466:	31 d0                	xor    %edx,%eax
  800468:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  80046a:	83 f8 09             	cmp    $0x9,%eax
  80046d:	7f 0b                	jg     80047a <vprintfmt+0x145>
  80046f:	8b 14 85 a0 16 80 00 	mov    0x8016a0(,%eax,4),%edx
  800476:	85 d2                	test   %edx,%edx
  800478:	75 1b                	jne    800495 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
  80047a:	50                   	push   %eax
  80047b:	68 8b 14 80 00       	push   $0x80148b
  800480:	53                   	push   %ebx
  800481:	56                   	push   %esi
  800482:	e8 91 fe ff ff       	call   800318 <printfmt>
  800487:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  80048a:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80048d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  800490:	e9 c6 fe ff ff       	jmp    80035b <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  800495:	52                   	push   %edx
  800496:	68 94 14 80 00       	push   $0x801494
  80049b:	53                   	push   %ebx
  80049c:	56                   	push   %esi
  80049d:	e8 76 fe ff ff       	call   800318 <printfmt>
  8004a2:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  8004a5:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004a8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8004ab:	e9 ab fe ff ff       	jmp    80035b <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8004b0:	8b 45 14             	mov    0x14(%ebp),%eax
  8004b3:	83 c0 04             	add    $0x4,%eax
  8004b6:	89 45 cc             	mov    %eax,-0x34(%ebp)
  8004b9:	8b 45 14             	mov    0x14(%ebp),%eax
  8004bc:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  8004be:	85 ff                	test   %edi,%edi
  8004c0:	b8 84 14 80 00       	mov    $0x801484,%eax
  8004c5:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  8004c8:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8004cc:	0f 8e 94 00 00 00    	jle    800566 <vprintfmt+0x231>
  8004d2:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  8004d6:	0f 84 98 00 00 00    	je     800574 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
  8004dc:	83 ec 08             	sub    $0x8,%esp
  8004df:	ff 75 d0             	pushl  -0x30(%ebp)
  8004e2:	57                   	push   %edi
  8004e3:	e8 33 03 00 00       	call   80081b <strnlen>
  8004e8:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8004eb:	29 c1                	sub    %eax,%ecx
  8004ed:	89 4d c8             	mov    %ecx,-0x38(%ebp)
  8004f0:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  8004f3:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  8004f7:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8004fa:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  8004fd:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004ff:	eb 0f                	jmp    800510 <vprintfmt+0x1db>
					putch(padc, putdat);
  800501:	83 ec 08             	sub    $0x8,%esp
  800504:	53                   	push   %ebx
  800505:	ff 75 e0             	pushl  -0x20(%ebp)
  800508:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  80050a:	83 ef 01             	sub    $0x1,%edi
  80050d:	83 c4 10             	add    $0x10,%esp
  800510:	85 ff                	test   %edi,%edi
  800512:	7f ed                	jg     800501 <vprintfmt+0x1cc>
  800514:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  800517:	8b 4d c8             	mov    -0x38(%ebp),%ecx
  80051a:	85 c9                	test   %ecx,%ecx
  80051c:	b8 00 00 00 00       	mov    $0x0,%eax
  800521:	0f 49 c1             	cmovns %ecx,%eax
  800524:	29 c1                	sub    %eax,%ecx
  800526:	89 75 08             	mov    %esi,0x8(%ebp)
  800529:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80052c:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80052f:	89 cb                	mov    %ecx,%ebx
  800531:	eb 4d                	jmp    800580 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800533:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800537:	74 1b                	je     800554 <vprintfmt+0x21f>
  800539:	0f be c0             	movsbl %al,%eax
  80053c:	83 e8 20             	sub    $0x20,%eax
  80053f:	83 f8 5e             	cmp    $0x5e,%eax
  800542:	76 10                	jbe    800554 <vprintfmt+0x21f>
					putch('?', putdat);
  800544:	83 ec 08             	sub    $0x8,%esp
  800547:	ff 75 0c             	pushl  0xc(%ebp)
  80054a:	6a 3f                	push   $0x3f
  80054c:	ff 55 08             	call   *0x8(%ebp)
  80054f:	83 c4 10             	add    $0x10,%esp
  800552:	eb 0d                	jmp    800561 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
  800554:	83 ec 08             	sub    $0x8,%esp
  800557:	ff 75 0c             	pushl  0xc(%ebp)
  80055a:	52                   	push   %edx
  80055b:	ff 55 08             	call   *0x8(%ebp)
  80055e:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800561:	83 eb 01             	sub    $0x1,%ebx
  800564:	eb 1a                	jmp    800580 <vprintfmt+0x24b>
  800566:	89 75 08             	mov    %esi,0x8(%ebp)
  800569:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80056c:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80056f:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800572:	eb 0c                	jmp    800580 <vprintfmt+0x24b>
  800574:	89 75 08             	mov    %esi,0x8(%ebp)
  800577:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80057a:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80057d:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800580:	83 c7 01             	add    $0x1,%edi
  800583:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800587:	0f be d0             	movsbl %al,%edx
  80058a:	85 d2                	test   %edx,%edx
  80058c:	74 23                	je     8005b1 <vprintfmt+0x27c>
  80058e:	85 f6                	test   %esi,%esi
  800590:	78 a1                	js     800533 <vprintfmt+0x1fe>
  800592:	83 ee 01             	sub    $0x1,%esi
  800595:	79 9c                	jns    800533 <vprintfmt+0x1fe>
  800597:	89 df                	mov    %ebx,%edi
  800599:	8b 75 08             	mov    0x8(%ebp),%esi
  80059c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80059f:	eb 18                	jmp    8005b9 <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  8005a1:	83 ec 08             	sub    $0x8,%esp
  8005a4:	53                   	push   %ebx
  8005a5:	6a 20                	push   $0x20
  8005a7:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8005a9:	83 ef 01             	sub    $0x1,%edi
  8005ac:	83 c4 10             	add    $0x10,%esp
  8005af:	eb 08                	jmp    8005b9 <vprintfmt+0x284>
  8005b1:	89 df                	mov    %ebx,%edi
  8005b3:	8b 75 08             	mov    0x8(%ebp),%esi
  8005b6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8005b9:	85 ff                	test   %edi,%edi
  8005bb:	7f e4                	jg     8005a1 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8005bd:	8b 45 cc             	mov    -0x34(%ebp),%eax
  8005c0:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005c3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8005c6:	e9 90 fd ff ff       	jmp    80035b <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8005cb:	83 f9 01             	cmp    $0x1,%ecx
  8005ce:	7e 19                	jle    8005e9 <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
  8005d0:	8b 45 14             	mov    0x14(%ebp),%eax
  8005d3:	8b 50 04             	mov    0x4(%eax),%edx
  8005d6:	8b 00                	mov    (%eax),%eax
  8005d8:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005db:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8005de:	8b 45 14             	mov    0x14(%ebp),%eax
  8005e1:	8d 40 08             	lea    0x8(%eax),%eax
  8005e4:	89 45 14             	mov    %eax,0x14(%ebp)
  8005e7:	eb 38                	jmp    800621 <vprintfmt+0x2ec>
	else if (lflag)
  8005e9:	85 c9                	test   %ecx,%ecx
  8005eb:	74 1b                	je     800608 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
  8005ed:	8b 45 14             	mov    0x14(%ebp),%eax
  8005f0:	8b 00                	mov    (%eax),%eax
  8005f2:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005f5:	89 c1                	mov    %eax,%ecx
  8005f7:	c1 f9 1f             	sar    $0x1f,%ecx
  8005fa:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8005fd:	8b 45 14             	mov    0x14(%ebp),%eax
  800600:	8d 40 04             	lea    0x4(%eax),%eax
  800603:	89 45 14             	mov    %eax,0x14(%ebp)
  800606:	eb 19                	jmp    800621 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
  800608:	8b 45 14             	mov    0x14(%ebp),%eax
  80060b:	8b 00                	mov    (%eax),%eax
  80060d:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800610:	89 c1                	mov    %eax,%ecx
  800612:	c1 f9 1f             	sar    $0x1f,%ecx
  800615:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  800618:	8b 45 14             	mov    0x14(%ebp),%eax
  80061b:	8d 40 04             	lea    0x4(%eax),%eax
  80061e:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800621:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800624:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800627:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  80062c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800630:	0f 89 0e 01 00 00    	jns    800744 <vprintfmt+0x40f>
				putch('-', putdat);
  800636:	83 ec 08             	sub    $0x8,%esp
  800639:	53                   	push   %ebx
  80063a:	6a 2d                	push   $0x2d
  80063c:	ff d6                	call   *%esi
				num = -(long long) num;
  80063e:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800641:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800644:	f7 da                	neg    %edx
  800646:	83 d1 00             	adc    $0x0,%ecx
  800649:	f7 d9                	neg    %ecx
  80064b:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  80064e:	b8 0a 00 00 00       	mov    $0xa,%eax
  800653:	e9 ec 00 00 00       	jmp    800744 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800658:	83 f9 01             	cmp    $0x1,%ecx
  80065b:	7e 18                	jle    800675 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
  80065d:	8b 45 14             	mov    0x14(%ebp),%eax
  800660:	8b 10                	mov    (%eax),%edx
  800662:	8b 48 04             	mov    0x4(%eax),%ecx
  800665:	8d 40 08             	lea    0x8(%eax),%eax
  800668:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  80066b:	b8 0a 00 00 00       	mov    $0xa,%eax
  800670:	e9 cf 00 00 00       	jmp    800744 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  800675:	85 c9                	test   %ecx,%ecx
  800677:	74 1a                	je     800693 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
  800679:	8b 45 14             	mov    0x14(%ebp),%eax
  80067c:	8b 10                	mov    (%eax),%edx
  80067e:	b9 00 00 00 00       	mov    $0x0,%ecx
  800683:	8d 40 04             	lea    0x4(%eax),%eax
  800686:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800689:	b8 0a 00 00 00       	mov    $0xa,%eax
  80068e:	e9 b1 00 00 00       	jmp    800744 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  800693:	8b 45 14             	mov    0x14(%ebp),%eax
  800696:	8b 10                	mov    (%eax),%edx
  800698:	b9 00 00 00 00       	mov    $0x0,%ecx
  80069d:	8d 40 04             	lea    0x4(%eax),%eax
  8006a0:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  8006a3:	b8 0a 00 00 00       	mov    $0xa,%eax
  8006a8:	e9 97 00 00 00       	jmp    800744 <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
  8006ad:	83 ec 08             	sub    $0x8,%esp
  8006b0:	53                   	push   %ebx
  8006b1:	6a 58                	push   $0x58
  8006b3:	ff d6                	call   *%esi
			putch('X', putdat);
  8006b5:	83 c4 08             	add    $0x8,%esp
  8006b8:	53                   	push   %ebx
  8006b9:	6a 58                	push   $0x58
  8006bb:	ff d6                	call   *%esi
			putch('X', putdat);
  8006bd:	83 c4 08             	add    $0x8,%esp
  8006c0:	53                   	push   %ebx
  8006c1:	6a 58                	push   $0x58
  8006c3:	ff d6                	call   *%esi
			break;
  8006c5:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8006c8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
  8006cb:	e9 8b fc ff ff       	jmp    80035b <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
  8006d0:	83 ec 08             	sub    $0x8,%esp
  8006d3:	53                   	push   %ebx
  8006d4:	6a 30                	push   $0x30
  8006d6:	ff d6                	call   *%esi
			putch('x', putdat);
  8006d8:	83 c4 08             	add    $0x8,%esp
  8006db:	53                   	push   %ebx
  8006dc:	6a 78                	push   $0x78
  8006de:	ff d6                	call   *%esi
			num = (unsigned long long)
  8006e0:	8b 45 14             	mov    0x14(%ebp),%eax
  8006e3:	8b 10                	mov    (%eax),%edx
  8006e5:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  8006ea:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  8006ed:	8d 40 04             	lea    0x4(%eax),%eax
  8006f0:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  8006f3:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
  8006f8:	eb 4a                	jmp    800744 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8006fa:	83 f9 01             	cmp    $0x1,%ecx
  8006fd:	7e 15                	jle    800714 <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
  8006ff:	8b 45 14             	mov    0x14(%ebp),%eax
  800702:	8b 10                	mov    (%eax),%edx
  800704:	8b 48 04             	mov    0x4(%eax),%ecx
  800707:	8d 40 08             	lea    0x8(%eax),%eax
  80070a:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  80070d:	b8 10 00 00 00       	mov    $0x10,%eax
  800712:	eb 30                	jmp    800744 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  800714:	85 c9                	test   %ecx,%ecx
  800716:	74 17                	je     80072f <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
  800718:	8b 45 14             	mov    0x14(%ebp),%eax
  80071b:	8b 10                	mov    (%eax),%edx
  80071d:	b9 00 00 00 00       	mov    $0x0,%ecx
  800722:	8d 40 04             	lea    0x4(%eax),%eax
  800725:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800728:	b8 10 00 00 00       	mov    $0x10,%eax
  80072d:	eb 15                	jmp    800744 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  80072f:	8b 45 14             	mov    0x14(%ebp),%eax
  800732:	8b 10                	mov    (%eax),%edx
  800734:	b9 00 00 00 00       	mov    $0x0,%ecx
  800739:	8d 40 04             	lea    0x4(%eax),%eax
  80073c:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  80073f:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
  800744:	83 ec 0c             	sub    $0xc,%esp
  800747:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  80074b:	57                   	push   %edi
  80074c:	ff 75 e0             	pushl  -0x20(%ebp)
  80074f:	50                   	push   %eax
  800750:	51                   	push   %ecx
  800751:	52                   	push   %edx
  800752:	89 da                	mov    %ebx,%edx
  800754:	89 f0                	mov    %esi,%eax
  800756:	e8 f1 fa ff ff       	call   80024c <printnum>
			break;
  80075b:	83 c4 20             	add    $0x20,%esp
  80075e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800761:	e9 f5 fb ff ff       	jmp    80035b <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  800766:	83 ec 08             	sub    $0x8,%esp
  800769:	53                   	push   %ebx
  80076a:	52                   	push   %edx
  80076b:	ff d6                	call   *%esi
			break;
  80076d:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800770:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  800773:	e9 e3 fb ff ff       	jmp    80035b <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  800778:	83 ec 08             	sub    $0x8,%esp
  80077b:	53                   	push   %ebx
  80077c:	6a 25                	push   $0x25
  80077e:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800780:	83 c4 10             	add    $0x10,%esp
  800783:	eb 03                	jmp    800788 <vprintfmt+0x453>
  800785:	83 ef 01             	sub    $0x1,%edi
  800788:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  80078c:	75 f7                	jne    800785 <vprintfmt+0x450>
  80078e:	e9 c8 fb ff ff       	jmp    80035b <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  800793:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800796:	5b                   	pop    %ebx
  800797:	5e                   	pop    %esi
  800798:	5f                   	pop    %edi
  800799:	5d                   	pop    %ebp
  80079a:	c3                   	ret    

0080079b <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  80079b:	55                   	push   %ebp
  80079c:	89 e5                	mov    %esp,%ebp
  80079e:	83 ec 18             	sub    $0x18,%esp
  8007a1:	8b 45 08             	mov    0x8(%ebp),%eax
  8007a4:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  8007a7:	89 45 ec             	mov    %eax,-0x14(%ebp)
  8007aa:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  8007ae:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  8007b1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8007b8:	85 c0                	test   %eax,%eax
  8007ba:	74 26                	je     8007e2 <vsnprintf+0x47>
  8007bc:	85 d2                	test   %edx,%edx
  8007be:	7e 22                	jle    8007e2 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  8007c0:	ff 75 14             	pushl  0x14(%ebp)
  8007c3:	ff 75 10             	pushl  0x10(%ebp)
  8007c6:	8d 45 ec             	lea    -0x14(%ebp),%eax
  8007c9:	50                   	push   %eax
  8007ca:	68 fb 02 80 00       	push   $0x8002fb
  8007cf:	e8 61 fb ff ff       	call   800335 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  8007d4:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8007d7:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  8007da:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8007dd:	83 c4 10             	add    $0x10,%esp
  8007e0:	eb 05                	jmp    8007e7 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  8007e2:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  8007e7:	c9                   	leave  
  8007e8:	c3                   	ret    

008007e9 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  8007e9:	55                   	push   %ebp
  8007ea:	89 e5                	mov    %esp,%ebp
  8007ec:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  8007ef:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  8007f2:	50                   	push   %eax
  8007f3:	ff 75 10             	pushl  0x10(%ebp)
  8007f6:	ff 75 0c             	pushl  0xc(%ebp)
  8007f9:	ff 75 08             	pushl  0x8(%ebp)
  8007fc:	e8 9a ff ff ff       	call   80079b <vsnprintf>
	va_end(ap);

	return rc;
}
  800801:	c9                   	leave  
  800802:	c3                   	ret    

00800803 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800803:	55                   	push   %ebp
  800804:	89 e5                	mov    %esp,%ebp
  800806:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800809:	b8 00 00 00 00       	mov    $0x0,%eax
  80080e:	eb 03                	jmp    800813 <strlen+0x10>
		n++;
  800810:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800813:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800817:	75 f7                	jne    800810 <strlen+0xd>
		n++;
	return n;
}
  800819:	5d                   	pop    %ebp
  80081a:	c3                   	ret    

0080081b <strnlen>:

int
strnlen(const char *s, size_t size)
{
  80081b:	55                   	push   %ebp
  80081c:	89 e5                	mov    %esp,%ebp
  80081e:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800821:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800824:	ba 00 00 00 00       	mov    $0x0,%edx
  800829:	eb 03                	jmp    80082e <strnlen+0x13>
		n++;
  80082b:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80082e:	39 c2                	cmp    %eax,%edx
  800830:	74 08                	je     80083a <strnlen+0x1f>
  800832:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  800836:	75 f3                	jne    80082b <strnlen+0x10>
  800838:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  80083a:	5d                   	pop    %ebp
  80083b:	c3                   	ret    

0080083c <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  80083c:	55                   	push   %ebp
  80083d:	89 e5                	mov    %esp,%ebp
  80083f:	53                   	push   %ebx
  800840:	8b 45 08             	mov    0x8(%ebp),%eax
  800843:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800846:	89 c2                	mov    %eax,%edx
  800848:	83 c2 01             	add    $0x1,%edx
  80084b:	83 c1 01             	add    $0x1,%ecx
  80084e:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  800852:	88 5a ff             	mov    %bl,-0x1(%edx)
  800855:	84 db                	test   %bl,%bl
  800857:	75 ef                	jne    800848 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800859:	5b                   	pop    %ebx
  80085a:	5d                   	pop    %ebp
  80085b:	c3                   	ret    

0080085c <strcat>:

char *
strcat(char *dst, const char *src)
{
  80085c:	55                   	push   %ebp
  80085d:	89 e5                	mov    %esp,%ebp
  80085f:	53                   	push   %ebx
  800860:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800863:	53                   	push   %ebx
  800864:	e8 9a ff ff ff       	call   800803 <strlen>
  800869:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  80086c:	ff 75 0c             	pushl  0xc(%ebp)
  80086f:	01 d8                	add    %ebx,%eax
  800871:	50                   	push   %eax
  800872:	e8 c5 ff ff ff       	call   80083c <strcpy>
	return dst;
}
  800877:	89 d8                	mov    %ebx,%eax
  800879:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  80087c:	c9                   	leave  
  80087d:	c3                   	ret    

0080087e <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  80087e:	55                   	push   %ebp
  80087f:	89 e5                	mov    %esp,%ebp
  800881:	56                   	push   %esi
  800882:	53                   	push   %ebx
  800883:	8b 75 08             	mov    0x8(%ebp),%esi
  800886:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800889:	89 f3                	mov    %esi,%ebx
  80088b:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  80088e:	89 f2                	mov    %esi,%edx
  800890:	eb 0f                	jmp    8008a1 <strncpy+0x23>
		*dst++ = *src;
  800892:	83 c2 01             	add    $0x1,%edx
  800895:	0f b6 01             	movzbl (%ecx),%eax
  800898:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  80089b:	80 39 01             	cmpb   $0x1,(%ecx)
  80089e:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8008a1:	39 da                	cmp    %ebx,%edx
  8008a3:	75 ed                	jne    800892 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  8008a5:	89 f0                	mov    %esi,%eax
  8008a7:	5b                   	pop    %ebx
  8008a8:	5e                   	pop    %esi
  8008a9:	5d                   	pop    %ebp
  8008aa:	c3                   	ret    

008008ab <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  8008ab:	55                   	push   %ebp
  8008ac:	89 e5                	mov    %esp,%ebp
  8008ae:	56                   	push   %esi
  8008af:	53                   	push   %ebx
  8008b0:	8b 75 08             	mov    0x8(%ebp),%esi
  8008b3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8008b6:	8b 55 10             	mov    0x10(%ebp),%edx
  8008b9:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  8008bb:	85 d2                	test   %edx,%edx
  8008bd:	74 21                	je     8008e0 <strlcpy+0x35>
  8008bf:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  8008c3:	89 f2                	mov    %esi,%edx
  8008c5:	eb 09                	jmp    8008d0 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  8008c7:	83 c2 01             	add    $0x1,%edx
  8008ca:	83 c1 01             	add    $0x1,%ecx
  8008cd:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  8008d0:	39 c2                	cmp    %eax,%edx
  8008d2:	74 09                	je     8008dd <strlcpy+0x32>
  8008d4:	0f b6 19             	movzbl (%ecx),%ebx
  8008d7:	84 db                	test   %bl,%bl
  8008d9:	75 ec                	jne    8008c7 <strlcpy+0x1c>
  8008db:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  8008dd:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  8008e0:	29 f0                	sub    %esi,%eax
}
  8008e2:	5b                   	pop    %ebx
  8008e3:	5e                   	pop    %esi
  8008e4:	5d                   	pop    %ebp
  8008e5:	c3                   	ret    

008008e6 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  8008e6:	55                   	push   %ebp
  8008e7:	89 e5                	mov    %esp,%ebp
  8008e9:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8008ec:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  8008ef:	eb 06                	jmp    8008f7 <strcmp+0x11>
		p++, q++;
  8008f1:	83 c1 01             	add    $0x1,%ecx
  8008f4:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  8008f7:	0f b6 01             	movzbl (%ecx),%eax
  8008fa:	84 c0                	test   %al,%al
  8008fc:	74 04                	je     800902 <strcmp+0x1c>
  8008fe:	3a 02                	cmp    (%edx),%al
  800900:	74 ef                	je     8008f1 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800902:	0f b6 c0             	movzbl %al,%eax
  800905:	0f b6 12             	movzbl (%edx),%edx
  800908:	29 d0                	sub    %edx,%eax
}
  80090a:	5d                   	pop    %ebp
  80090b:	c3                   	ret    

0080090c <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  80090c:	55                   	push   %ebp
  80090d:	89 e5                	mov    %esp,%ebp
  80090f:	53                   	push   %ebx
  800910:	8b 45 08             	mov    0x8(%ebp),%eax
  800913:	8b 55 0c             	mov    0xc(%ebp),%edx
  800916:	89 c3                	mov    %eax,%ebx
  800918:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  80091b:	eb 06                	jmp    800923 <strncmp+0x17>
		n--, p++, q++;
  80091d:	83 c0 01             	add    $0x1,%eax
  800920:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800923:	39 d8                	cmp    %ebx,%eax
  800925:	74 15                	je     80093c <strncmp+0x30>
  800927:	0f b6 08             	movzbl (%eax),%ecx
  80092a:	84 c9                	test   %cl,%cl
  80092c:	74 04                	je     800932 <strncmp+0x26>
  80092e:	3a 0a                	cmp    (%edx),%cl
  800930:	74 eb                	je     80091d <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800932:	0f b6 00             	movzbl (%eax),%eax
  800935:	0f b6 12             	movzbl (%edx),%edx
  800938:	29 d0                	sub    %edx,%eax
  80093a:	eb 05                	jmp    800941 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  80093c:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800941:	5b                   	pop    %ebx
  800942:	5d                   	pop    %ebp
  800943:	c3                   	ret    

00800944 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800944:	55                   	push   %ebp
  800945:	89 e5                	mov    %esp,%ebp
  800947:	8b 45 08             	mov    0x8(%ebp),%eax
  80094a:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  80094e:	eb 07                	jmp    800957 <strchr+0x13>
		if (*s == c)
  800950:	38 ca                	cmp    %cl,%dl
  800952:	74 0f                	je     800963 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800954:	83 c0 01             	add    $0x1,%eax
  800957:	0f b6 10             	movzbl (%eax),%edx
  80095a:	84 d2                	test   %dl,%dl
  80095c:	75 f2                	jne    800950 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  80095e:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800963:	5d                   	pop    %ebp
  800964:	c3                   	ret    

00800965 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800965:	55                   	push   %ebp
  800966:	89 e5                	mov    %esp,%ebp
  800968:	8b 45 08             	mov    0x8(%ebp),%eax
  80096b:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  80096f:	eb 03                	jmp    800974 <strfind+0xf>
  800971:	83 c0 01             	add    $0x1,%eax
  800974:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  800977:	38 ca                	cmp    %cl,%dl
  800979:	74 04                	je     80097f <strfind+0x1a>
  80097b:	84 d2                	test   %dl,%dl
  80097d:	75 f2                	jne    800971 <strfind+0xc>
			break;
	return (char *) s;
}
  80097f:	5d                   	pop    %ebp
  800980:	c3                   	ret    

00800981 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800981:	55                   	push   %ebp
  800982:	89 e5                	mov    %esp,%ebp
  800984:	57                   	push   %edi
  800985:	56                   	push   %esi
  800986:	53                   	push   %ebx
  800987:	8b 7d 08             	mov    0x8(%ebp),%edi
  80098a:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  80098d:	85 c9                	test   %ecx,%ecx
  80098f:	74 36                	je     8009c7 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800991:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800997:	75 28                	jne    8009c1 <memset+0x40>
  800999:	f6 c1 03             	test   $0x3,%cl
  80099c:	75 23                	jne    8009c1 <memset+0x40>
		c &= 0xFF;
  80099e:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  8009a2:	89 d3                	mov    %edx,%ebx
  8009a4:	c1 e3 08             	shl    $0x8,%ebx
  8009a7:	89 d6                	mov    %edx,%esi
  8009a9:	c1 e6 18             	shl    $0x18,%esi
  8009ac:	89 d0                	mov    %edx,%eax
  8009ae:	c1 e0 10             	shl    $0x10,%eax
  8009b1:	09 f0                	or     %esi,%eax
  8009b3:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  8009b5:	89 d8                	mov    %ebx,%eax
  8009b7:	09 d0                	or     %edx,%eax
  8009b9:	c1 e9 02             	shr    $0x2,%ecx
  8009bc:	fc                   	cld    
  8009bd:	f3 ab                	rep stos %eax,%es:(%edi)
  8009bf:	eb 06                	jmp    8009c7 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  8009c1:	8b 45 0c             	mov    0xc(%ebp),%eax
  8009c4:	fc                   	cld    
  8009c5:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  8009c7:	89 f8                	mov    %edi,%eax
  8009c9:	5b                   	pop    %ebx
  8009ca:	5e                   	pop    %esi
  8009cb:	5f                   	pop    %edi
  8009cc:	5d                   	pop    %ebp
  8009cd:	c3                   	ret    

008009ce <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  8009ce:	55                   	push   %ebp
  8009cf:	89 e5                	mov    %esp,%ebp
  8009d1:	57                   	push   %edi
  8009d2:	56                   	push   %esi
  8009d3:	8b 45 08             	mov    0x8(%ebp),%eax
  8009d6:	8b 75 0c             	mov    0xc(%ebp),%esi
  8009d9:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  8009dc:	39 c6                	cmp    %eax,%esi
  8009de:	73 35                	jae    800a15 <memmove+0x47>
  8009e0:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  8009e3:	39 d0                	cmp    %edx,%eax
  8009e5:	73 2e                	jae    800a15 <memmove+0x47>
		s += n;
		d += n;
  8009e7:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  8009ea:	89 d6                	mov    %edx,%esi
  8009ec:	09 fe                	or     %edi,%esi
  8009ee:	f7 c6 03 00 00 00    	test   $0x3,%esi
  8009f4:	75 13                	jne    800a09 <memmove+0x3b>
  8009f6:	f6 c1 03             	test   $0x3,%cl
  8009f9:	75 0e                	jne    800a09 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  8009fb:	83 ef 04             	sub    $0x4,%edi
  8009fe:	8d 72 fc             	lea    -0x4(%edx),%esi
  800a01:	c1 e9 02             	shr    $0x2,%ecx
  800a04:	fd                   	std    
  800a05:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a07:	eb 09                	jmp    800a12 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800a09:	83 ef 01             	sub    $0x1,%edi
  800a0c:	8d 72 ff             	lea    -0x1(%edx),%esi
  800a0f:	fd                   	std    
  800a10:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800a12:	fc                   	cld    
  800a13:	eb 1d                	jmp    800a32 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a15:	89 f2                	mov    %esi,%edx
  800a17:	09 c2                	or     %eax,%edx
  800a19:	f6 c2 03             	test   $0x3,%dl
  800a1c:	75 0f                	jne    800a2d <memmove+0x5f>
  800a1e:	f6 c1 03             	test   $0x3,%cl
  800a21:	75 0a                	jne    800a2d <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800a23:	c1 e9 02             	shr    $0x2,%ecx
  800a26:	89 c7                	mov    %eax,%edi
  800a28:	fc                   	cld    
  800a29:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a2b:	eb 05                	jmp    800a32 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800a2d:	89 c7                	mov    %eax,%edi
  800a2f:	fc                   	cld    
  800a30:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800a32:	5e                   	pop    %esi
  800a33:	5f                   	pop    %edi
  800a34:	5d                   	pop    %ebp
  800a35:	c3                   	ret    

00800a36 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800a36:	55                   	push   %ebp
  800a37:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  800a39:	ff 75 10             	pushl  0x10(%ebp)
  800a3c:	ff 75 0c             	pushl  0xc(%ebp)
  800a3f:	ff 75 08             	pushl  0x8(%ebp)
  800a42:	e8 87 ff ff ff       	call   8009ce <memmove>
}
  800a47:	c9                   	leave  
  800a48:	c3                   	ret    

00800a49 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800a49:	55                   	push   %ebp
  800a4a:	89 e5                	mov    %esp,%ebp
  800a4c:	56                   	push   %esi
  800a4d:	53                   	push   %ebx
  800a4e:	8b 45 08             	mov    0x8(%ebp),%eax
  800a51:	8b 55 0c             	mov    0xc(%ebp),%edx
  800a54:	89 c6                	mov    %eax,%esi
  800a56:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a59:	eb 1a                	jmp    800a75 <memcmp+0x2c>
		if (*s1 != *s2)
  800a5b:	0f b6 08             	movzbl (%eax),%ecx
  800a5e:	0f b6 1a             	movzbl (%edx),%ebx
  800a61:	38 d9                	cmp    %bl,%cl
  800a63:	74 0a                	je     800a6f <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800a65:	0f b6 c1             	movzbl %cl,%eax
  800a68:	0f b6 db             	movzbl %bl,%ebx
  800a6b:	29 d8                	sub    %ebx,%eax
  800a6d:	eb 0f                	jmp    800a7e <memcmp+0x35>
		s1++, s2++;
  800a6f:	83 c0 01             	add    $0x1,%eax
  800a72:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a75:	39 f0                	cmp    %esi,%eax
  800a77:	75 e2                	jne    800a5b <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800a79:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800a7e:	5b                   	pop    %ebx
  800a7f:	5e                   	pop    %esi
  800a80:	5d                   	pop    %ebp
  800a81:	c3                   	ret    

00800a82 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800a82:	55                   	push   %ebp
  800a83:	89 e5                	mov    %esp,%ebp
  800a85:	53                   	push   %ebx
  800a86:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  800a89:	89 c1                	mov    %eax,%ecx
  800a8b:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  800a8e:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a92:	eb 0a                	jmp    800a9e <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  800a94:	0f b6 10             	movzbl (%eax),%edx
  800a97:	39 da                	cmp    %ebx,%edx
  800a99:	74 07                	je     800aa2 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a9b:	83 c0 01             	add    $0x1,%eax
  800a9e:	39 c8                	cmp    %ecx,%eax
  800aa0:	72 f2                	jb     800a94 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800aa2:	5b                   	pop    %ebx
  800aa3:	5d                   	pop    %ebp
  800aa4:	c3                   	ret    

00800aa5 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800aa5:	55                   	push   %ebp
  800aa6:	89 e5                	mov    %esp,%ebp
  800aa8:	57                   	push   %edi
  800aa9:	56                   	push   %esi
  800aaa:	53                   	push   %ebx
  800aab:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800aae:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800ab1:	eb 03                	jmp    800ab6 <strtol+0x11>
		s++;
  800ab3:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800ab6:	0f b6 01             	movzbl (%ecx),%eax
  800ab9:	3c 20                	cmp    $0x20,%al
  800abb:	74 f6                	je     800ab3 <strtol+0xe>
  800abd:	3c 09                	cmp    $0x9,%al
  800abf:	74 f2                	je     800ab3 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800ac1:	3c 2b                	cmp    $0x2b,%al
  800ac3:	75 0a                	jne    800acf <strtol+0x2a>
		s++;
  800ac5:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800ac8:	bf 00 00 00 00       	mov    $0x0,%edi
  800acd:	eb 11                	jmp    800ae0 <strtol+0x3b>
  800acf:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800ad4:	3c 2d                	cmp    $0x2d,%al
  800ad6:	75 08                	jne    800ae0 <strtol+0x3b>
		s++, neg = 1;
  800ad8:	83 c1 01             	add    $0x1,%ecx
  800adb:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800ae0:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800ae6:	75 15                	jne    800afd <strtol+0x58>
  800ae8:	80 39 30             	cmpb   $0x30,(%ecx)
  800aeb:	75 10                	jne    800afd <strtol+0x58>
  800aed:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800af1:	75 7c                	jne    800b6f <strtol+0xca>
		s += 2, base = 16;
  800af3:	83 c1 02             	add    $0x2,%ecx
  800af6:	bb 10 00 00 00       	mov    $0x10,%ebx
  800afb:	eb 16                	jmp    800b13 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800afd:	85 db                	test   %ebx,%ebx
  800aff:	75 12                	jne    800b13 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800b01:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800b06:	80 39 30             	cmpb   $0x30,(%ecx)
  800b09:	75 08                	jne    800b13 <strtol+0x6e>
		s++, base = 8;
  800b0b:	83 c1 01             	add    $0x1,%ecx
  800b0e:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800b13:	b8 00 00 00 00       	mov    $0x0,%eax
  800b18:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800b1b:	0f b6 11             	movzbl (%ecx),%edx
  800b1e:	8d 72 d0             	lea    -0x30(%edx),%esi
  800b21:	89 f3                	mov    %esi,%ebx
  800b23:	80 fb 09             	cmp    $0x9,%bl
  800b26:	77 08                	ja     800b30 <strtol+0x8b>
			dig = *s - '0';
  800b28:	0f be d2             	movsbl %dl,%edx
  800b2b:	83 ea 30             	sub    $0x30,%edx
  800b2e:	eb 22                	jmp    800b52 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800b30:	8d 72 9f             	lea    -0x61(%edx),%esi
  800b33:	89 f3                	mov    %esi,%ebx
  800b35:	80 fb 19             	cmp    $0x19,%bl
  800b38:	77 08                	ja     800b42 <strtol+0x9d>
			dig = *s - 'a' + 10;
  800b3a:	0f be d2             	movsbl %dl,%edx
  800b3d:	83 ea 57             	sub    $0x57,%edx
  800b40:	eb 10                	jmp    800b52 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800b42:	8d 72 bf             	lea    -0x41(%edx),%esi
  800b45:	89 f3                	mov    %esi,%ebx
  800b47:	80 fb 19             	cmp    $0x19,%bl
  800b4a:	77 16                	ja     800b62 <strtol+0xbd>
			dig = *s - 'A' + 10;
  800b4c:	0f be d2             	movsbl %dl,%edx
  800b4f:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800b52:	3b 55 10             	cmp    0x10(%ebp),%edx
  800b55:	7d 0b                	jge    800b62 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800b57:	83 c1 01             	add    $0x1,%ecx
  800b5a:	0f af 45 10          	imul   0x10(%ebp),%eax
  800b5e:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800b60:	eb b9                	jmp    800b1b <strtol+0x76>

	if (endptr)
  800b62:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800b66:	74 0d                	je     800b75 <strtol+0xd0>
		*endptr = (char *) s;
  800b68:	8b 75 0c             	mov    0xc(%ebp),%esi
  800b6b:	89 0e                	mov    %ecx,(%esi)
  800b6d:	eb 06                	jmp    800b75 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800b6f:	85 db                	test   %ebx,%ebx
  800b71:	74 98                	je     800b0b <strtol+0x66>
  800b73:	eb 9e                	jmp    800b13 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800b75:	89 c2                	mov    %eax,%edx
  800b77:	f7 da                	neg    %edx
  800b79:	85 ff                	test   %edi,%edi
  800b7b:	0f 45 c2             	cmovne %edx,%eax
}
  800b7e:	5b                   	pop    %ebx
  800b7f:	5e                   	pop    %esi
  800b80:	5f                   	pop    %edi
  800b81:	5d                   	pop    %ebp
  800b82:	c3                   	ret    

00800b83 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800b83:	55                   	push   %ebp
  800b84:	89 e5                	mov    %esp,%ebp
  800b86:	57                   	push   %edi
  800b87:	56                   	push   %esi
  800b88:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b89:	b8 00 00 00 00       	mov    $0x0,%eax
  800b8e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800b91:	8b 55 08             	mov    0x8(%ebp),%edx
  800b94:	89 c3                	mov    %eax,%ebx
  800b96:	89 c7                	mov    %eax,%edi
  800b98:	89 c6                	mov    %eax,%esi
  800b9a:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800b9c:	5b                   	pop    %ebx
  800b9d:	5e                   	pop    %esi
  800b9e:	5f                   	pop    %edi
  800b9f:	5d                   	pop    %ebp
  800ba0:	c3                   	ret    

00800ba1 <sys_cgetc>:

int
sys_cgetc(void)
{
  800ba1:	55                   	push   %ebp
  800ba2:	89 e5                	mov    %esp,%ebp
  800ba4:	57                   	push   %edi
  800ba5:	56                   	push   %esi
  800ba6:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800ba7:	ba 00 00 00 00       	mov    $0x0,%edx
  800bac:	b8 01 00 00 00       	mov    $0x1,%eax
  800bb1:	89 d1                	mov    %edx,%ecx
  800bb3:	89 d3                	mov    %edx,%ebx
  800bb5:	89 d7                	mov    %edx,%edi
  800bb7:	89 d6                	mov    %edx,%esi
  800bb9:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800bbb:	5b                   	pop    %ebx
  800bbc:	5e                   	pop    %esi
  800bbd:	5f                   	pop    %edi
  800bbe:	5d                   	pop    %ebp
  800bbf:	c3                   	ret    

00800bc0 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800bc0:	55                   	push   %ebp
  800bc1:	89 e5                	mov    %esp,%ebp
  800bc3:	57                   	push   %edi
  800bc4:	56                   	push   %esi
  800bc5:	53                   	push   %ebx
  800bc6:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800bc9:	b9 00 00 00 00       	mov    $0x0,%ecx
  800bce:	b8 03 00 00 00       	mov    $0x3,%eax
  800bd3:	8b 55 08             	mov    0x8(%ebp),%edx
  800bd6:	89 cb                	mov    %ecx,%ebx
  800bd8:	89 cf                	mov    %ecx,%edi
  800bda:	89 ce                	mov    %ecx,%esi
  800bdc:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800bde:	85 c0                	test   %eax,%eax
  800be0:	7e 17                	jle    800bf9 <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800be2:	83 ec 0c             	sub    $0xc,%esp
  800be5:	50                   	push   %eax
  800be6:	6a 03                	push   $0x3
  800be8:	68 c8 16 80 00       	push   $0x8016c8
  800bed:	6a 23                	push   $0x23
  800bef:	68 e5 16 80 00       	push   $0x8016e5
  800bf4:	e8 66 f5 ff ff       	call   80015f <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800bf9:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800bfc:	5b                   	pop    %ebx
  800bfd:	5e                   	pop    %esi
  800bfe:	5f                   	pop    %edi
  800bff:	5d                   	pop    %ebp
  800c00:	c3                   	ret    

00800c01 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800c01:	55                   	push   %ebp
  800c02:	89 e5                	mov    %esp,%ebp
  800c04:	57                   	push   %edi
  800c05:	56                   	push   %esi
  800c06:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c07:	ba 00 00 00 00       	mov    $0x0,%edx
  800c0c:	b8 02 00 00 00       	mov    $0x2,%eax
  800c11:	89 d1                	mov    %edx,%ecx
  800c13:	89 d3                	mov    %edx,%ebx
  800c15:	89 d7                	mov    %edx,%edi
  800c17:	89 d6                	mov    %edx,%esi
  800c19:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800c1b:	5b                   	pop    %ebx
  800c1c:	5e                   	pop    %esi
  800c1d:	5f                   	pop    %edi
  800c1e:	5d                   	pop    %ebp
  800c1f:	c3                   	ret    

00800c20 <sys_yield>:

void
sys_yield(void)
{
  800c20:	55                   	push   %ebp
  800c21:	89 e5                	mov    %esp,%ebp
  800c23:	57                   	push   %edi
  800c24:	56                   	push   %esi
  800c25:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c26:	ba 00 00 00 00       	mov    $0x0,%edx
  800c2b:	b8 0a 00 00 00       	mov    $0xa,%eax
  800c30:	89 d1                	mov    %edx,%ecx
  800c32:	89 d3                	mov    %edx,%ebx
  800c34:	89 d7                	mov    %edx,%edi
  800c36:	89 d6                	mov    %edx,%esi
  800c38:	cd 30                	int    $0x30

void
sys_yield(void)
{
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
}
  800c3a:	5b                   	pop    %ebx
  800c3b:	5e                   	pop    %esi
  800c3c:	5f                   	pop    %edi
  800c3d:	5d                   	pop    %ebp
  800c3e:	c3                   	ret    

00800c3f <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  800c3f:	55                   	push   %ebp
  800c40:	89 e5                	mov    %esp,%ebp
  800c42:	57                   	push   %edi
  800c43:	56                   	push   %esi
  800c44:	53                   	push   %ebx
  800c45:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c48:	be 00 00 00 00       	mov    $0x0,%esi
  800c4d:	b8 04 00 00 00       	mov    $0x4,%eax
  800c52:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800c55:	8b 55 08             	mov    0x8(%ebp),%edx
  800c58:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800c5b:	89 f7                	mov    %esi,%edi
  800c5d:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800c5f:	85 c0                	test   %eax,%eax
  800c61:	7e 17                	jle    800c7a <sys_page_alloc+0x3b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800c63:	83 ec 0c             	sub    $0xc,%esp
  800c66:	50                   	push   %eax
  800c67:	6a 04                	push   $0x4
  800c69:	68 c8 16 80 00       	push   $0x8016c8
  800c6e:	6a 23                	push   $0x23
  800c70:	68 e5 16 80 00       	push   $0x8016e5
  800c75:	e8 e5 f4 ff ff       	call   80015f <_panic>

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
}
  800c7a:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800c7d:	5b                   	pop    %ebx
  800c7e:	5e                   	pop    %esi
  800c7f:	5f                   	pop    %edi
  800c80:	5d                   	pop    %ebp
  800c81:	c3                   	ret    

00800c82 <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  800c82:	55                   	push   %ebp
  800c83:	89 e5                	mov    %esp,%ebp
  800c85:	57                   	push   %edi
  800c86:	56                   	push   %esi
  800c87:	53                   	push   %ebx
  800c88:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c8b:	b8 05 00 00 00       	mov    $0x5,%eax
  800c90:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800c93:	8b 55 08             	mov    0x8(%ebp),%edx
  800c96:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800c99:	8b 7d 14             	mov    0x14(%ebp),%edi
  800c9c:	8b 75 18             	mov    0x18(%ebp),%esi
  800c9f:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800ca1:	85 c0                	test   %eax,%eax
  800ca3:	7e 17                	jle    800cbc <sys_page_map+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800ca5:	83 ec 0c             	sub    $0xc,%esp
  800ca8:	50                   	push   %eax
  800ca9:	6a 05                	push   $0x5
  800cab:	68 c8 16 80 00       	push   $0x8016c8
  800cb0:	6a 23                	push   $0x23
  800cb2:	68 e5 16 80 00       	push   $0x8016e5
  800cb7:	e8 a3 f4 ff ff       	call   80015f <_panic>

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
}
  800cbc:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800cbf:	5b                   	pop    %ebx
  800cc0:	5e                   	pop    %esi
  800cc1:	5f                   	pop    %edi
  800cc2:	5d                   	pop    %ebp
  800cc3:	c3                   	ret    

00800cc4 <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  800cc4:	55                   	push   %ebp
  800cc5:	89 e5                	mov    %esp,%ebp
  800cc7:	57                   	push   %edi
  800cc8:	56                   	push   %esi
  800cc9:	53                   	push   %ebx
  800cca:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800ccd:	bb 00 00 00 00       	mov    $0x0,%ebx
  800cd2:	b8 06 00 00 00       	mov    $0x6,%eax
  800cd7:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800cda:	8b 55 08             	mov    0x8(%ebp),%edx
  800cdd:	89 df                	mov    %ebx,%edi
  800cdf:	89 de                	mov    %ebx,%esi
  800ce1:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800ce3:	85 c0                	test   %eax,%eax
  800ce5:	7e 17                	jle    800cfe <sys_page_unmap+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800ce7:	83 ec 0c             	sub    $0xc,%esp
  800cea:	50                   	push   %eax
  800ceb:	6a 06                	push   $0x6
  800ced:	68 c8 16 80 00       	push   $0x8016c8
  800cf2:	6a 23                	push   $0x23
  800cf4:	68 e5 16 80 00       	push   $0x8016e5
  800cf9:	e8 61 f4 ff ff       	call   80015f <_panic>

int
sys_page_unmap(envid_t envid, void *va)
{
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
}
  800cfe:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800d01:	5b                   	pop    %ebx
  800d02:	5e                   	pop    %esi
  800d03:	5f                   	pop    %edi
  800d04:	5d                   	pop    %ebp
  800d05:	c3                   	ret    

00800d06 <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  800d06:	55                   	push   %ebp
  800d07:	89 e5                	mov    %esp,%ebp
  800d09:	57                   	push   %edi
  800d0a:	56                   	push   %esi
  800d0b:	53                   	push   %ebx
  800d0c:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d0f:	bb 00 00 00 00       	mov    $0x0,%ebx
  800d14:	b8 08 00 00 00       	mov    $0x8,%eax
  800d19:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800d1c:	8b 55 08             	mov    0x8(%ebp),%edx
  800d1f:	89 df                	mov    %ebx,%edi
  800d21:	89 de                	mov    %ebx,%esi
  800d23:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800d25:	85 c0                	test   %eax,%eax
  800d27:	7e 17                	jle    800d40 <sys_env_set_status+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800d29:	83 ec 0c             	sub    $0xc,%esp
  800d2c:	50                   	push   %eax
  800d2d:	6a 08                	push   $0x8
  800d2f:	68 c8 16 80 00       	push   $0x8016c8
  800d34:	6a 23                	push   $0x23
  800d36:	68 e5 16 80 00       	push   $0x8016e5
  800d3b:	e8 1f f4 ff ff       	call   80015f <_panic>

int
sys_env_set_status(envid_t envid, int status)
{
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
}
  800d40:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800d43:	5b                   	pop    %ebx
  800d44:	5e                   	pop    %esi
  800d45:	5f                   	pop    %edi
  800d46:	5d                   	pop    %ebp
  800d47:	c3                   	ret    

00800d48 <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  800d48:	55                   	push   %ebp
  800d49:	89 e5                	mov    %esp,%ebp
  800d4b:	57                   	push   %edi
  800d4c:	56                   	push   %esi
  800d4d:	53                   	push   %ebx
  800d4e:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d51:	bb 00 00 00 00       	mov    $0x0,%ebx
  800d56:	b8 09 00 00 00       	mov    $0x9,%eax
  800d5b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800d5e:	8b 55 08             	mov    0x8(%ebp),%edx
  800d61:	89 df                	mov    %ebx,%edi
  800d63:	89 de                	mov    %ebx,%esi
  800d65:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800d67:	85 c0                	test   %eax,%eax
  800d69:	7e 17                	jle    800d82 <sys_env_set_pgfault_upcall+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800d6b:	83 ec 0c             	sub    $0xc,%esp
  800d6e:	50                   	push   %eax
  800d6f:	6a 09                	push   $0x9
  800d71:	68 c8 16 80 00       	push   $0x8016c8
  800d76:	6a 23                	push   $0x23
  800d78:	68 e5 16 80 00       	push   $0x8016e5
  800d7d:	e8 dd f3 ff ff       	call   80015f <_panic>

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
}
  800d82:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800d85:	5b                   	pop    %ebx
  800d86:	5e                   	pop    %esi
  800d87:	5f                   	pop    %edi
  800d88:	5d                   	pop    %ebp
  800d89:	c3                   	ret    

00800d8a <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  800d8a:	55                   	push   %ebp
  800d8b:	89 e5                	mov    %esp,%ebp
  800d8d:	57                   	push   %edi
  800d8e:	56                   	push   %esi
  800d8f:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d90:	be 00 00 00 00       	mov    $0x0,%esi
  800d95:	b8 0b 00 00 00       	mov    $0xb,%eax
  800d9a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800d9d:	8b 55 08             	mov    0x8(%ebp),%edx
  800da0:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800da3:	8b 7d 14             	mov    0x14(%ebp),%edi
  800da6:	cd 30                	int    $0x30

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
}
  800da8:	5b                   	pop    %ebx
  800da9:	5e                   	pop    %esi
  800daa:	5f                   	pop    %edi
  800dab:	5d                   	pop    %ebp
  800dac:	c3                   	ret    

00800dad <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  800dad:	55                   	push   %ebp
  800dae:	89 e5                	mov    %esp,%ebp
  800db0:	57                   	push   %edi
  800db1:	56                   	push   %esi
  800db2:	53                   	push   %ebx
  800db3:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800db6:	b9 00 00 00 00       	mov    $0x0,%ecx
  800dbb:	b8 0c 00 00 00       	mov    $0xc,%eax
  800dc0:	8b 55 08             	mov    0x8(%ebp),%edx
  800dc3:	89 cb                	mov    %ecx,%ebx
  800dc5:	89 cf                	mov    %ecx,%edi
  800dc7:	89 ce                	mov    %ecx,%esi
  800dc9:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800dcb:	85 c0                	test   %eax,%eax
  800dcd:	7e 17                	jle    800de6 <sys_ipc_recv+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800dcf:	83 ec 0c             	sub    $0xc,%esp
  800dd2:	50                   	push   %eax
  800dd3:	6a 0c                	push   $0xc
  800dd5:	68 c8 16 80 00       	push   $0x8016c8
  800dda:	6a 23                	push   $0x23
  800ddc:	68 e5 16 80 00       	push   $0x8016e5
  800de1:	e8 79 f3 ff ff       	call   80015f <_panic>

int
sys_ipc_recv(void *dstva)
{
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
}
  800de6:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800de9:	5b                   	pop    %ebx
  800dea:	5e                   	pop    %esi
  800deb:	5f                   	pop    %edi
  800dec:	5d                   	pop    %ebp
  800ded:	c3                   	ret    

00800dee <pgfault>:
// Custom page fault handler - if faulting page is copy-on-write,
// map in our own private writable copy.
//
static void
pgfault(struct UTrapframe *utf)
{
  800dee:	55                   	push   %ebp
  800def:	89 e5                	mov    %esp,%ebp
  800df1:	53                   	push   %ebx
  800df2:	83 ec 04             	sub    $0x4,%esp
  800df5:	8b 55 08             	mov    0x8(%ebp),%edx
	void *addr = (void *) utf->utf_fault_va;
  800df8:	8b 02                	mov    (%edx),%eax
	// Hint:
	//   Use the read-only page table mappings at uvpt
	//   (see <inc/memlayout.h>).

	// LAB 4: Your code here.
	if ((err & FEC_WR) == 0||(uvpd[PDX(addr)] & PTE_P) == 0 ||
  800dfa:	f6 42 04 02          	testb  $0x2,0x4(%edx)
  800dfe:	74 27                	je     800e27 <pgfault+0x39>
  800e00:	89 c2                	mov    %eax,%edx
  800e02:	c1 ea 16             	shr    $0x16,%edx
  800e05:	8b 14 95 00 d0 7b ef 	mov    -0x10843000(,%edx,4),%edx
  800e0c:	f6 c2 01             	test   $0x1,%dl
  800e0f:	74 16                	je     800e27 <pgfault+0x39>
		(~uvpt[PGNUM(addr)] & (PTE_COW|PTE_P)) != 0)
  800e11:	89 c2                	mov    %eax,%edx
  800e13:	c1 ea 0c             	shr    $0xc,%edx
  800e16:	8b 14 95 00 00 40 ef 	mov    -0x10c00000(,%edx,4),%edx
	// Hint:
	//   Use the read-only page table mappings at uvpt
	//   (see <inc/memlayout.h>).

	// LAB 4: Your code here.
	if ((err & FEC_WR) == 0||(uvpd[PDX(addr)] & PTE_P) == 0 ||
  800e1d:	f7 d2                	not    %edx
  800e1f:	f7 c2 01 08 00 00    	test   $0x801,%edx
  800e25:	74 14                	je     800e3b <pgfault+0x4d>
		(~uvpt[PGNUM(addr)] & (PTE_COW|PTE_P)) != 0)
	{
		panic("not copy-on-write");
  800e27:	83 ec 04             	sub    $0x4,%esp
  800e2a:	68 f3 16 80 00       	push   $0x8016f3
  800e2f:	6a 1f                	push   $0x1f
  800e31:	68 05 17 80 00       	push   $0x801705
  800e36:	e8 24 f3 ff ff       	call   80015f <_panic>
	// page to the old page's address.
	// Hint:
	//   You should make three system calls.

	// LAB 4: Your code here.
	addr = ROUNDDOWN(addr, PGSIZE);
  800e3b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  800e40:	89 c3                	mov    %eax,%ebx
	if (sys_page_alloc(0, PFTEMP, PTE_W|PTE_U|PTE_P) < 0)
  800e42:	83 ec 04             	sub    $0x4,%esp
  800e45:	6a 07                	push   $0x7
  800e47:	68 00 f0 7f 00       	push   $0x7ff000
  800e4c:	6a 00                	push   $0x0
  800e4e:	e8 ec fd ff ff       	call   800c3f <sys_page_alloc>
  800e53:	83 c4 10             	add    $0x10,%esp
  800e56:	85 c0                	test   %eax,%eax
  800e58:	79 14                	jns    800e6e <pgfault+0x80>
	{
		panic("sys_page_alloc failed");
  800e5a:	83 ec 04             	sub    $0x4,%esp
  800e5d:	68 10 17 80 00       	push   $0x801710
  800e62:	6a 2b                	push   $0x2b
  800e64:	68 05 17 80 00       	push   $0x801705
  800e69:	e8 f1 f2 ff ff       	call   80015f <_panic>
	}
	memcpy(PFTEMP, addr, PGSIZE);
  800e6e:	83 ec 04             	sub    $0x4,%esp
  800e71:	68 00 10 00 00       	push   $0x1000
  800e76:	53                   	push   %ebx
  800e77:	68 00 f0 7f 00       	push   $0x7ff000
  800e7c:	e8 b5 fb ff ff       	call   800a36 <memcpy>
	if (sys_page_map(0, PFTEMP, 0, addr, PTE_W|PTE_U|PTE_P) < 0)
  800e81:	c7 04 24 07 00 00 00 	movl   $0x7,(%esp)
  800e88:	53                   	push   %ebx
  800e89:	6a 00                	push   $0x0
  800e8b:	68 00 f0 7f 00       	push   $0x7ff000
  800e90:	6a 00                	push   $0x0
  800e92:	e8 eb fd ff ff       	call   800c82 <sys_page_map>
  800e97:	83 c4 20             	add    $0x20,%esp
  800e9a:	85 c0                	test   %eax,%eax
  800e9c:	79 14                	jns    800eb2 <pgfault+0xc4>
		panic("sys_page_map failed");
  800e9e:	83 ec 04             	sub    $0x4,%esp
  800ea1:	68 26 17 80 00       	push   $0x801726
  800ea6:	6a 2f                	push   $0x2f
  800ea8:	68 05 17 80 00       	push   $0x801705
  800ead:	e8 ad f2 ff ff       	call   80015f <_panic>
	if (sys_page_unmap(0, PFTEMP) < 0)
  800eb2:	83 ec 08             	sub    $0x8,%esp
  800eb5:	68 00 f0 7f 00       	push   $0x7ff000
  800eba:	6a 00                	push   $0x0
  800ebc:	e8 03 fe ff ff       	call   800cc4 <sys_page_unmap>
  800ec1:	83 c4 10             	add    $0x10,%esp
  800ec4:	85 c0                	test   %eax,%eax
  800ec6:	79 14                	jns    800edc <pgfault+0xee>
		panic("sys_page_unmap failed");
  800ec8:	83 ec 04             	sub    $0x4,%esp
  800ecb:	68 3a 17 80 00       	push   $0x80173a
  800ed0:	6a 31                	push   $0x31
  800ed2:	68 05 17 80 00       	push   $0x801705
  800ed7:	e8 83 f2 ff ff       	call   80015f <_panic>
	return;
	//panic("pgfault not implemented");
}
  800edc:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800edf:	c9                   	leave  
  800ee0:	c3                   	ret    

00800ee1 <fork>:
//   Neither user exception stack should ever be marked copy-on-write,
//   so you must allocate a new page for the child's user exception stack.
//
envid_t
fork(void)
{
  800ee1:	55                   	push   %ebp
  800ee2:	89 e5                	mov    %esp,%ebp
  800ee4:	57                   	push   %edi
  800ee5:	56                   	push   %esi
  800ee6:	53                   	push   %ebx
  800ee7:	83 ec 28             	sub    $0x28,%esp
	// LAB 4: Your code here.
	set_pgfault_handler(pgfault); 
  800eea:	68 ee 0d 80 00       	push   $0x800dee
  800eef:	e8 c6 01 00 00       	call   8010ba <set_pgfault_handler>
// This must be inlined.  Exercise for reader: why?
static __inline envid_t __attribute__((always_inline))
sys_exofork(void)
{
	envid_t ret;
	__asm __volatile("int %2"
  800ef4:	b8 07 00 00 00       	mov    $0x7,%eax
  800ef9:	cd 30                	int    $0x30
  800efb:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	envid_t envid = sys_exofork(); 
	uint32_t addr;
	if(envid < 0)
  800efe:	83 c4 10             	add    $0x10,%esp
  800f01:	85 c0                	test   %eax,%eax
  800f03:	79 14                	jns    800f19 <fork+0x38>
	{ 
		panic("sys_exofork failed");
  800f05:	83 ec 04             	sub    $0x4,%esp
  800f08:	68 50 17 80 00       	push   $0x801750
  800f0d:	6a 77                	push   $0x77
  800f0f:	68 05 17 80 00       	push   $0x801705
  800f14:	e8 46 f2 ff ff       	call   80015f <_panic>
  800f19:	89 c7                	mov    %eax,%edi
  800f1b:	bb 00 00 00 00       	mov    $0x0,%ebx
	}
	else if(envid == 0)
  800f20:	85 c0                	test   %eax,%eax
  800f22:	75 1c                	jne    800f40 <fork+0x5f>
	{ 
		thisenv = &envs[ENVX(sys_getenvid())];
  800f24:	e8 d8 fc ff ff       	call   800c01 <sys_getenvid>
  800f29:	25 ff 03 00 00       	and    $0x3ff,%eax
  800f2e:	6b c0 7c             	imul   $0x7c,%eax,%eax
  800f31:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  800f36:	a3 08 20 80 00       	mov    %eax,0x802008
		return envid;
  800f3b:	e9 56 01 00 00       	jmp    801096 <fork+0x1b5>
	}
	for(addr = 0;addr < USTACKTOP;addr += PGSIZE)
	{
		if ((uvpd[PDX(addr)] & PTE_P) && (uvpt[PGNUM(addr)] & PTE_P)
  800f40:	89 d8                	mov    %ebx,%eax
  800f42:	c1 e8 16             	shr    $0x16,%eax
  800f45:	8b 04 85 00 d0 7b ef 	mov    -0x10843000(,%eax,4),%eax
  800f4c:	a8 01                	test   $0x1,%al
  800f4e:	0f 84 cb 00 00 00    	je     80101f <fork+0x13e>
  800f54:	89 d8                	mov    %ebx,%eax
  800f56:	c1 e8 0c             	shr    $0xc,%eax
  800f59:	8b 14 85 00 00 40 ef 	mov    -0x10c00000(,%eax,4),%edx
  800f60:	f6 c2 01             	test   $0x1,%dl
  800f63:	0f 84 b6 00 00 00    	je     80101f <fork+0x13e>
			&& (uvpt[PGNUM(addr)] & PTE_U)) 
  800f69:	8b 14 85 00 00 40 ef 	mov    -0x10c00000(,%eax,4),%edx
  800f70:	f6 c2 04             	test   $0x4,%dl
  800f73:	0f 84 a6 00 00 00    	je     80101f <fork+0x13e>
duppage(envid_t envid, unsigned pn)
{
	int r;

	// LAB 4: Your code here.
	void *addr = (void*)(pn * PGSIZE);
  800f79:	89 c6                	mov    %eax,%esi
  800f7b:	c1 e6 0c             	shl    $0xc,%esi
	if ((uvpt[pn] & PTE_W) || (uvpt[pn] & PTE_COW)) 
  800f7e:	8b 14 85 00 00 40 ef 	mov    -0x10c00000(,%eax,4),%edx
  800f85:	f6 c2 02             	test   $0x2,%dl
  800f88:	75 0c                	jne    800f96 <fork+0xb5>
  800f8a:	8b 04 85 00 00 40 ef 	mov    -0x10c00000(,%eax,4),%eax
  800f91:	f6 c4 08             	test   $0x8,%ah
  800f94:	74 5d                	je     800ff3 <fork+0x112>
	{ 
		if (sys_page_map(0, addr, envid, addr, PTE_COW|PTE_U|PTE_P) < 0)
  800f96:	83 ec 0c             	sub    $0xc,%esp
  800f99:	68 05 08 00 00       	push   $0x805
  800f9e:	56                   	push   %esi
  800f9f:	ff 75 e4             	pushl  -0x1c(%ebp)
  800fa2:	56                   	push   %esi
  800fa3:	6a 00                	push   $0x0
  800fa5:	e8 d8 fc ff ff       	call   800c82 <sys_page_map>
  800faa:	83 c4 20             	add    $0x20,%esp
  800fad:	85 c0                	test   %eax,%eax
  800faf:	79 14                	jns    800fc5 <fork+0xe4>
		{ 
			panic("sys_page_map envid failed");
  800fb1:	83 ec 04             	sub    $0x4,%esp
  800fb4:	68 63 17 80 00       	push   $0x801763
  800fb9:	6a 4c                	push   $0x4c
  800fbb:	68 05 17 80 00       	push   $0x801705
  800fc0:	e8 9a f1 ff ff       	call   80015f <_panic>
		}
		if (sys_page_map(0, addr, 0, addr, PTE_COW|PTE_U|PTE_P) < 0)
  800fc5:	83 ec 0c             	sub    $0xc,%esp
  800fc8:	68 05 08 00 00       	push   $0x805
  800fcd:	56                   	push   %esi
  800fce:	6a 00                	push   $0x0
  800fd0:	56                   	push   %esi
  800fd1:	6a 00                	push   $0x0
  800fd3:	e8 aa fc ff ff       	call   800c82 <sys_page_map>
  800fd8:	83 c4 20             	add    $0x20,%esp
  800fdb:	85 c0                	test   %eax,%eax
  800fdd:	79 40                	jns    80101f <fork+0x13e>
		{ 
			panic("sys_page_map 0 failed");
  800fdf:	83 ec 04             	sub    $0x4,%esp
  800fe2:	68 7d 17 80 00       	push   $0x80177d
  800fe7:	6a 50                	push   $0x50
  800fe9:	68 05 17 80 00       	push   $0x801705
  800fee:	e8 6c f1 ff ff       	call   80015f <_panic>
		}
	} 
	else 
	{ 
		if(sys_page_map(0, addr, envid, addr, PTE_U|PTE_P) < 0)
  800ff3:	83 ec 0c             	sub    $0xc,%esp
  800ff6:	6a 05                	push   $0x5
  800ff8:	56                   	push   %esi
  800ff9:	ff 75 e4             	pushl  -0x1c(%ebp)
  800ffc:	56                   	push   %esi
  800ffd:	6a 00                	push   $0x0
  800fff:	e8 7e fc ff ff       	call   800c82 <sys_page_map>
  801004:	83 c4 20             	add    $0x20,%esp
  801007:	85 c0                	test   %eax,%eax
  801009:	79 14                	jns    80101f <fork+0x13e>
		{
			panic("sys_page_map envid failed");
  80100b:	83 ec 04             	sub    $0x4,%esp
  80100e:	68 63 17 80 00       	push   $0x801763
  801013:	6a 57                	push   $0x57
  801015:	68 05 17 80 00       	push   $0x801705
  80101a:	e8 40 f1 ff ff       	call   80015f <_panic>
	else if(envid == 0)
	{ 
		thisenv = &envs[ENVX(sys_getenvid())];
		return envid;
	}
	for(addr = 0;addr < USTACKTOP;addr += PGSIZE)
  80101f:	81 c3 00 10 00 00    	add    $0x1000,%ebx
  801025:	81 fb 00 e0 bf ee    	cmp    $0xeebfe000,%ebx
  80102b:	0f 85 0f ff ff ff    	jne    800f40 <fork+0x5f>
			&& (uvpt[PGNUM(addr)] & PTE_U)) 
		{
			duppage(envid, PGNUM(addr));
		}
	}
	if (sys_page_alloc(envid, (void *)(UXSTACKTOP-PGSIZE), PTE_U|PTE_W|PTE_P) < 0)
  801031:	83 ec 04             	sub    $0x4,%esp
  801034:	6a 07                	push   $0x7
  801036:	68 00 f0 bf ee       	push   $0xeebff000
  80103b:	57                   	push   %edi
  80103c:	e8 fe fb ff ff       	call   800c3f <sys_page_alloc>
  801041:	83 c4 10             	add    $0x10,%esp
  801044:	85 c0                	test   %eax,%eax
  801046:	79 17                	jns    80105f <fork+0x17e>
	{
		panic("sys_page_alloc failed");
  801048:	83 ec 04             	sub    $0x4,%esp
  80104b:	68 10 17 80 00       	push   $0x801710
  801050:	68 88 00 00 00       	push   $0x88
  801055:	68 05 17 80 00       	push   $0x801705
  80105a:	e8 00 f1 ff ff       	call   80015f <_panic>
	}
	extern void _pgfault_upcall();
	sys_env_set_pgfault_upcall(envid, _pgfault_upcall);
  80105f:	83 ec 08             	sub    $0x8,%esp
  801062:	68 29 11 80 00       	push   $0x801129
  801067:	57                   	push   %edi
  801068:	e8 db fc ff ff       	call   800d48 <sys_env_set_pgfault_upcall>
	if (sys_env_set_status(envid, ENV_RUNNABLE) < 0)
  80106d:	83 c4 08             	add    $0x8,%esp
  801070:	6a 02                	push   $0x2
  801072:	57                   	push   %edi
  801073:	e8 8e fc ff ff       	call   800d06 <sys_env_set_status>
  801078:	83 c4 10             	add    $0x10,%esp
  80107b:	85 c0                	test   %eax,%eax
  80107d:	79 17                	jns    801096 <fork+0x1b5>
	{
		panic("sys_env_set_status failed");
  80107f:	83 ec 04             	sub    $0x4,%esp
  801082:	68 93 17 80 00       	push   $0x801793
  801087:	68 8e 00 00 00       	push   $0x8e
  80108c:	68 05 17 80 00       	push   $0x801705
  801091:	e8 c9 f0 ff ff       	call   80015f <_panic>
	}
	return envid;
	//panic("fork not implemented");
}
  801096:	89 f8                	mov    %edi,%eax
  801098:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80109b:	5b                   	pop    %ebx
  80109c:	5e                   	pop    %esi
  80109d:	5f                   	pop    %edi
  80109e:	5d                   	pop    %ebp
  80109f:	c3                   	ret    

008010a0 <sfork>:

// Challenge!
int
sfork(void)
{
  8010a0:	55                   	push   %ebp
  8010a1:	89 e5                	mov    %esp,%ebp
  8010a3:	83 ec 0c             	sub    $0xc,%esp
	panic("sfork not implemented");
  8010a6:	68 ad 17 80 00       	push   $0x8017ad
  8010ab:	68 98 00 00 00       	push   $0x98
  8010b0:	68 05 17 80 00       	push   $0x801705
  8010b5:	e8 a5 f0 ff ff       	call   80015f <_panic>

008010ba <set_pgfault_handler>:
// at UXSTACKTOP), and tell the kernel to call the assembly-language
// _pgfault_upcall routine when a page fault occurs.
//
void
set_pgfault_handler(void (*handler)(struct UTrapframe *utf))
{
  8010ba:	55                   	push   %ebp
  8010bb:	89 e5                	mov    %esp,%ebp
  8010bd:	83 ec 08             	sub    $0x8,%esp
	int r;

	if (_pgfault_handler == 0) {
  8010c0:	83 3d 0c 20 80 00 00 	cmpl   $0x0,0x80200c
  8010c7:	75 56                	jne    80111f <set_pgfault_handler+0x65>
		// First time through!
		// LAB 4: Your code here.
		r = sys_page_alloc(0, (void*)UXSTACKTOP-PGSIZE, PTE_U|PTE_W|PTE_P);
  8010c9:	83 ec 04             	sub    $0x4,%esp
  8010cc:	6a 07                	push   $0x7
  8010ce:	68 00 f0 bf ee       	push   $0xeebff000
  8010d3:	6a 00                	push   $0x0
  8010d5:	e8 65 fb ff ff       	call   800c3f <sys_page_alloc>
		//cprintf("%x", r);
		if(r != 0)
  8010da:	83 c4 10             	add    $0x10,%esp
  8010dd:	85 c0                	test   %eax,%eax
  8010df:	74 14                	je     8010f5 <set_pgfault_handler+0x3b>
		{
			panic("sys_page_alloc failed");
  8010e1:	83 ec 04             	sub    $0x4,%esp
  8010e4:	68 10 17 80 00       	push   $0x801710
  8010e9:	6a 24                	push   $0x24
  8010eb:	68 c3 17 80 00       	push   $0x8017c3
  8010f0:	e8 6a f0 ff ff       	call   80015f <_panic>
		}
		r = sys_env_set_pgfault_upcall(0, (void*)_pgfault_upcall); 
  8010f5:	83 ec 08             	sub    $0x8,%esp
  8010f8:	68 29 11 80 00       	push   $0x801129
  8010fd:	6a 00                	push   $0x0
  8010ff:	e8 44 fc ff ff       	call   800d48 <sys_env_set_pgfault_upcall>
		//cprintf("%x\n", _pgfault_upcall);//fixed bug:_pgfault_upcall-->_pgfault_handler
		if(r != 0)
  801104:	83 c4 10             	add    $0x10,%esp
  801107:	85 c0                	test   %eax,%eax
  801109:	74 14                	je     80111f <set_pgfault_handler+0x65>
		{
			panic("sys_env_set_pgfault_upcall failed");
  80110b:	83 ec 04             	sub    $0x4,%esp
  80110e:	68 d4 17 80 00       	push   $0x8017d4
  801113:	6a 2a                	push   $0x2a
  801115:	68 c3 17 80 00       	push   $0x8017c3
  80111a:	e8 40 f0 ff ff       	call   80015f <_panic>
		}
		//panic("set_pgfault_handler not implemented");
	}

	// Save handler pointer for assembly to call.
	_pgfault_handler = handler;
  80111f:	8b 45 08             	mov    0x8(%ebp),%eax
  801122:	a3 0c 20 80 00       	mov    %eax,0x80200c
}
  801127:	c9                   	leave  
  801128:	c3                   	ret    

00801129 <_pgfault_upcall>:

.text
.globl _pgfault_upcall
_pgfault_upcall:
	// Call the C page fault handler.
	pushl %esp			// function argument: pointer to UTF
  801129:	54                   	push   %esp
	movl _pgfault_handler, %eax
  80112a:	a1 0c 20 80 00       	mov    0x80200c,%eax
	call *%eax
  80112f:	ff d0                	call   *%eax
	addl $4, %esp			// pop function argument
  801131:	83 c4 04             	add    $0x4,%esp
	// registers are available for intermediate calculations.  You
	// may find that you have to rearrange your code in non-obvious
	// ways as registers become unavailable as scratch space.
	//
	// LAB 4: Your code here.
	movl 0x28(%esp), %eax
  801134:	8b 44 24 28          	mov    0x28(%esp),%eax
    	subl $0x4, 0x30(%esp)
  801138:	83 6c 24 30 04       	subl   $0x4,0x30(%esp)
   	movl 0x30(%esp), %ebp
  80113d:	8b 6c 24 30          	mov    0x30(%esp),%ebp
    	movl %eax, (%ebp)
  801141:	89 45 00             	mov    %eax,0x0(%ebp)
    	// pop fault_va, err
    	popl %eax
  801144:	58                   	pop    %eax
    	popl %eax
  801145:	58                   	pop    %eax
	// Restore the trap-time registers.  After you do this, you
	// can no longer modify any general-purpose registers.
	// LAB 4: Your code here.
	popal
  801146:	61                   	popa   
	// Restore eflags from the stack.  After you do this, you can
	// no longer use arithmetic operations or anything else that
	// modifies eflags.
	// LAB 4: Your code here.
	addl $0x4, %esp
  801147:	83 c4 04             	add    $0x4,%esp
	popfl
  80114a:	9d                   	popf   
	// Switch back to the adjusted trap-time stack.
	// LAB 4: Your code here.
	popl %esp
  80114b:	5c                   	pop    %esp
	// Return to re-execute the instruction that faulted.
	// LAB 4: Your code here.
	ret
  80114c:	c3                   	ret    
  80114d:	66 90                	xchg   %ax,%ax
  80114f:	90                   	nop

00801150 <__udivdi3>:
  801150:	55                   	push   %ebp
  801151:	57                   	push   %edi
  801152:	56                   	push   %esi
  801153:	53                   	push   %ebx
  801154:	83 ec 1c             	sub    $0x1c,%esp
  801157:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  80115b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  80115f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  801163:	8b 7c 24 38          	mov    0x38(%esp),%edi
  801167:	85 f6                	test   %esi,%esi
  801169:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  80116d:	89 ca                	mov    %ecx,%edx
  80116f:	89 f8                	mov    %edi,%eax
  801171:	75 3d                	jne    8011b0 <__udivdi3+0x60>
  801173:	39 cf                	cmp    %ecx,%edi
  801175:	0f 87 c5 00 00 00    	ja     801240 <__udivdi3+0xf0>
  80117b:	85 ff                	test   %edi,%edi
  80117d:	89 fd                	mov    %edi,%ebp
  80117f:	75 0b                	jne    80118c <__udivdi3+0x3c>
  801181:	b8 01 00 00 00       	mov    $0x1,%eax
  801186:	31 d2                	xor    %edx,%edx
  801188:	f7 f7                	div    %edi
  80118a:	89 c5                	mov    %eax,%ebp
  80118c:	89 c8                	mov    %ecx,%eax
  80118e:	31 d2                	xor    %edx,%edx
  801190:	f7 f5                	div    %ebp
  801192:	89 c1                	mov    %eax,%ecx
  801194:	89 d8                	mov    %ebx,%eax
  801196:	89 cf                	mov    %ecx,%edi
  801198:	f7 f5                	div    %ebp
  80119a:	89 c3                	mov    %eax,%ebx
  80119c:	89 d8                	mov    %ebx,%eax
  80119e:	89 fa                	mov    %edi,%edx
  8011a0:	83 c4 1c             	add    $0x1c,%esp
  8011a3:	5b                   	pop    %ebx
  8011a4:	5e                   	pop    %esi
  8011a5:	5f                   	pop    %edi
  8011a6:	5d                   	pop    %ebp
  8011a7:	c3                   	ret    
  8011a8:	90                   	nop
  8011a9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  8011b0:	39 ce                	cmp    %ecx,%esi
  8011b2:	77 74                	ja     801228 <__udivdi3+0xd8>
  8011b4:	0f bd fe             	bsr    %esi,%edi
  8011b7:	83 f7 1f             	xor    $0x1f,%edi
  8011ba:	0f 84 98 00 00 00    	je     801258 <__udivdi3+0x108>
  8011c0:	bb 20 00 00 00       	mov    $0x20,%ebx
  8011c5:	89 f9                	mov    %edi,%ecx
  8011c7:	89 c5                	mov    %eax,%ebp
  8011c9:	29 fb                	sub    %edi,%ebx
  8011cb:	d3 e6                	shl    %cl,%esi
  8011cd:	89 d9                	mov    %ebx,%ecx
  8011cf:	d3 ed                	shr    %cl,%ebp
  8011d1:	89 f9                	mov    %edi,%ecx
  8011d3:	d3 e0                	shl    %cl,%eax
  8011d5:	09 ee                	or     %ebp,%esi
  8011d7:	89 d9                	mov    %ebx,%ecx
  8011d9:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8011dd:	89 d5                	mov    %edx,%ebp
  8011df:	8b 44 24 08          	mov    0x8(%esp),%eax
  8011e3:	d3 ed                	shr    %cl,%ebp
  8011e5:	89 f9                	mov    %edi,%ecx
  8011e7:	d3 e2                	shl    %cl,%edx
  8011e9:	89 d9                	mov    %ebx,%ecx
  8011eb:	d3 e8                	shr    %cl,%eax
  8011ed:	09 c2                	or     %eax,%edx
  8011ef:	89 d0                	mov    %edx,%eax
  8011f1:	89 ea                	mov    %ebp,%edx
  8011f3:	f7 f6                	div    %esi
  8011f5:	89 d5                	mov    %edx,%ebp
  8011f7:	89 c3                	mov    %eax,%ebx
  8011f9:	f7 64 24 0c          	mull   0xc(%esp)
  8011fd:	39 d5                	cmp    %edx,%ebp
  8011ff:	72 10                	jb     801211 <__udivdi3+0xc1>
  801201:	8b 74 24 08          	mov    0x8(%esp),%esi
  801205:	89 f9                	mov    %edi,%ecx
  801207:	d3 e6                	shl    %cl,%esi
  801209:	39 c6                	cmp    %eax,%esi
  80120b:	73 07                	jae    801214 <__udivdi3+0xc4>
  80120d:	39 d5                	cmp    %edx,%ebp
  80120f:	75 03                	jne    801214 <__udivdi3+0xc4>
  801211:	83 eb 01             	sub    $0x1,%ebx
  801214:	31 ff                	xor    %edi,%edi
  801216:	89 d8                	mov    %ebx,%eax
  801218:	89 fa                	mov    %edi,%edx
  80121a:	83 c4 1c             	add    $0x1c,%esp
  80121d:	5b                   	pop    %ebx
  80121e:	5e                   	pop    %esi
  80121f:	5f                   	pop    %edi
  801220:	5d                   	pop    %ebp
  801221:	c3                   	ret    
  801222:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  801228:	31 ff                	xor    %edi,%edi
  80122a:	31 db                	xor    %ebx,%ebx
  80122c:	89 d8                	mov    %ebx,%eax
  80122e:	89 fa                	mov    %edi,%edx
  801230:	83 c4 1c             	add    $0x1c,%esp
  801233:	5b                   	pop    %ebx
  801234:	5e                   	pop    %esi
  801235:	5f                   	pop    %edi
  801236:	5d                   	pop    %ebp
  801237:	c3                   	ret    
  801238:	90                   	nop
  801239:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  801240:	89 d8                	mov    %ebx,%eax
  801242:	f7 f7                	div    %edi
  801244:	31 ff                	xor    %edi,%edi
  801246:	89 c3                	mov    %eax,%ebx
  801248:	89 d8                	mov    %ebx,%eax
  80124a:	89 fa                	mov    %edi,%edx
  80124c:	83 c4 1c             	add    $0x1c,%esp
  80124f:	5b                   	pop    %ebx
  801250:	5e                   	pop    %esi
  801251:	5f                   	pop    %edi
  801252:	5d                   	pop    %ebp
  801253:	c3                   	ret    
  801254:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801258:	39 ce                	cmp    %ecx,%esi
  80125a:	72 0c                	jb     801268 <__udivdi3+0x118>
  80125c:	31 db                	xor    %ebx,%ebx
  80125e:	3b 44 24 08          	cmp    0x8(%esp),%eax
  801262:	0f 87 34 ff ff ff    	ja     80119c <__udivdi3+0x4c>
  801268:	bb 01 00 00 00       	mov    $0x1,%ebx
  80126d:	e9 2a ff ff ff       	jmp    80119c <__udivdi3+0x4c>
  801272:	66 90                	xchg   %ax,%ax
  801274:	66 90                	xchg   %ax,%ax
  801276:	66 90                	xchg   %ax,%ax
  801278:	66 90                	xchg   %ax,%ax
  80127a:	66 90                	xchg   %ax,%ax
  80127c:	66 90                	xchg   %ax,%ax
  80127e:	66 90                	xchg   %ax,%ax

00801280 <__umoddi3>:
  801280:	55                   	push   %ebp
  801281:	57                   	push   %edi
  801282:	56                   	push   %esi
  801283:	53                   	push   %ebx
  801284:	83 ec 1c             	sub    $0x1c,%esp
  801287:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  80128b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  80128f:	8b 74 24 34          	mov    0x34(%esp),%esi
  801293:	8b 7c 24 38          	mov    0x38(%esp),%edi
  801297:	85 d2                	test   %edx,%edx
  801299:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  80129d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8012a1:	89 f3                	mov    %esi,%ebx
  8012a3:	89 3c 24             	mov    %edi,(%esp)
  8012a6:	89 74 24 04          	mov    %esi,0x4(%esp)
  8012aa:	75 1c                	jne    8012c8 <__umoddi3+0x48>
  8012ac:	39 f7                	cmp    %esi,%edi
  8012ae:	76 50                	jbe    801300 <__umoddi3+0x80>
  8012b0:	89 c8                	mov    %ecx,%eax
  8012b2:	89 f2                	mov    %esi,%edx
  8012b4:	f7 f7                	div    %edi
  8012b6:	89 d0                	mov    %edx,%eax
  8012b8:	31 d2                	xor    %edx,%edx
  8012ba:	83 c4 1c             	add    $0x1c,%esp
  8012bd:	5b                   	pop    %ebx
  8012be:	5e                   	pop    %esi
  8012bf:	5f                   	pop    %edi
  8012c0:	5d                   	pop    %ebp
  8012c1:	c3                   	ret    
  8012c2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  8012c8:	39 f2                	cmp    %esi,%edx
  8012ca:	89 d0                	mov    %edx,%eax
  8012cc:	77 52                	ja     801320 <__umoddi3+0xa0>
  8012ce:	0f bd ea             	bsr    %edx,%ebp
  8012d1:	83 f5 1f             	xor    $0x1f,%ebp
  8012d4:	75 5a                	jne    801330 <__umoddi3+0xb0>
  8012d6:	3b 54 24 04          	cmp    0x4(%esp),%edx
  8012da:	0f 82 e0 00 00 00    	jb     8013c0 <__umoddi3+0x140>
  8012e0:	39 0c 24             	cmp    %ecx,(%esp)
  8012e3:	0f 86 d7 00 00 00    	jbe    8013c0 <__umoddi3+0x140>
  8012e9:	8b 44 24 08          	mov    0x8(%esp),%eax
  8012ed:	8b 54 24 04          	mov    0x4(%esp),%edx
  8012f1:	83 c4 1c             	add    $0x1c,%esp
  8012f4:	5b                   	pop    %ebx
  8012f5:	5e                   	pop    %esi
  8012f6:	5f                   	pop    %edi
  8012f7:	5d                   	pop    %ebp
  8012f8:	c3                   	ret    
  8012f9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  801300:	85 ff                	test   %edi,%edi
  801302:	89 fd                	mov    %edi,%ebp
  801304:	75 0b                	jne    801311 <__umoddi3+0x91>
  801306:	b8 01 00 00 00       	mov    $0x1,%eax
  80130b:	31 d2                	xor    %edx,%edx
  80130d:	f7 f7                	div    %edi
  80130f:	89 c5                	mov    %eax,%ebp
  801311:	89 f0                	mov    %esi,%eax
  801313:	31 d2                	xor    %edx,%edx
  801315:	f7 f5                	div    %ebp
  801317:	89 c8                	mov    %ecx,%eax
  801319:	f7 f5                	div    %ebp
  80131b:	89 d0                	mov    %edx,%eax
  80131d:	eb 99                	jmp    8012b8 <__umoddi3+0x38>
  80131f:	90                   	nop
  801320:	89 c8                	mov    %ecx,%eax
  801322:	89 f2                	mov    %esi,%edx
  801324:	83 c4 1c             	add    $0x1c,%esp
  801327:	5b                   	pop    %ebx
  801328:	5e                   	pop    %esi
  801329:	5f                   	pop    %edi
  80132a:	5d                   	pop    %ebp
  80132b:	c3                   	ret    
  80132c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801330:	8b 34 24             	mov    (%esp),%esi
  801333:	bf 20 00 00 00       	mov    $0x20,%edi
  801338:	89 e9                	mov    %ebp,%ecx
  80133a:	29 ef                	sub    %ebp,%edi
  80133c:	d3 e0                	shl    %cl,%eax
  80133e:	89 f9                	mov    %edi,%ecx
  801340:	89 f2                	mov    %esi,%edx
  801342:	d3 ea                	shr    %cl,%edx
  801344:	89 e9                	mov    %ebp,%ecx
  801346:	09 c2                	or     %eax,%edx
  801348:	89 d8                	mov    %ebx,%eax
  80134a:	89 14 24             	mov    %edx,(%esp)
  80134d:	89 f2                	mov    %esi,%edx
  80134f:	d3 e2                	shl    %cl,%edx
  801351:	89 f9                	mov    %edi,%ecx
  801353:	89 54 24 04          	mov    %edx,0x4(%esp)
  801357:	8b 54 24 0c          	mov    0xc(%esp),%edx
  80135b:	d3 e8                	shr    %cl,%eax
  80135d:	89 e9                	mov    %ebp,%ecx
  80135f:	89 c6                	mov    %eax,%esi
  801361:	d3 e3                	shl    %cl,%ebx
  801363:	89 f9                	mov    %edi,%ecx
  801365:	89 d0                	mov    %edx,%eax
  801367:	d3 e8                	shr    %cl,%eax
  801369:	89 e9                	mov    %ebp,%ecx
  80136b:	09 d8                	or     %ebx,%eax
  80136d:	89 d3                	mov    %edx,%ebx
  80136f:	89 f2                	mov    %esi,%edx
  801371:	f7 34 24             	divl   (%esp)
  801374:	89 d6                	mov    %edx,%esi
  801376:	d3 e3                	shl    %cl,%ebx
  801378:	f7 64 24 04          	mull   0x4(%esp)
  80137c:	39 d6                	cmp    %edx,%esi
  80137e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  801382:	89 d1                	mov    %edx,%ecx
  801384:	89 c3                	mov    %eax,%ebx
  801386:	72 08                	jb     801390 <__umoddi3+0x110>
  801388:	75 11                	jne    80139b <__umoddi3+0x11b>
  80138a:	39 44 24 08          	cmp    %eax,0x8(%esp)
  80138e:	73 0b                	jae    80139b <__umoddi3+0x11b>
  801390:	2b 44 24 04          	sub    0x4(%esp),%eax
  801394:	1b 14 24             	sbb    (%esp),%edx
  801397:	89 d1                	mov    %edx,%ecx
  801399:	89 c3                	mov    %eax,%ebx
  80139b:	8b 54 24 08          	mov    0x8(%esp),%edx
  80139f:	29 da                	sub    %ebx,%edx
  8013a1:	19 ce                	sbb    %ecx,%esi
  8013a3:	89 f9                	mov    %edi,%ecx
  8013a5:	89 f0                	mov    %esi,%eax
  8013a7:	d3 e0                	shl    %cl,%eax
  8013a9:	89 e9                	mov    %ebp,%ecx
  8013ab:	d3 ea                	shr    %cl,%edx
  8013ad:	89 e9                	mov    %ebp,%ecx
  8013af:	d3 ee                	shr    %cl,%esi
  8013b1:	09 d0                	or     %edx,%eax
  8013b3:	89 f2                	mov    %esi,%edx
  8013b5:	83 c4 1c             	add    $0x1c,%esp
  8013b8:	5b                   	pop    %ebx
  8013b9:	5e                   	pop    %esi
  8013ba:	5f                   	pop    %edi
  8013bb:	5d                   	pop    %ebp
  8013bc:	c3                   	ret    
  8013bd:	8d 76 00             	lea    0x0(%esi),%esi
  8013c0:	29 f9                	sub    %edi,%ecx
  8013c2:	19 d6                	sbb    %edx,%esi
  8013c4:	89 74 24 04          	mov    %esi,0x4(%esp)
  8013c8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8013cc:	e9 18 ff ff ff       	jmp    8012e9 <__umoddi3+0x69>
