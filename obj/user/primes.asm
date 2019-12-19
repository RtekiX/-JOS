
obj/user/primes：     文件格式 elf32-i386


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
  80002c:	e8 bf 00 00 00       	call   8000f0 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <primeproc>:
	return true;
}*/

unsigned
primeproc(void)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	56                   	push   %esi
  800037:	53                   	push   %ebx
	int i, id, p;
	envid_t *envid=NULL;

	// fetch a prime from our left neighbor
top:
	p = ipc_recv(envid, 0, 0);
  800038:	83 ec 04             	sub    $0x4,%esp
  80003b:	6a 00                	push   $0x0
  80003d:	6a 00                	push   $0x0
  80003f:	6a 00                	push   $0x0
  800041:	e8 5d 10 00 00       	call   8010a3 <ipc_recv>
  800046:	89 c3                	mov    %eax,%ebx
	//cprintf("before recv,,,p:%d\n\n",p);
	cprintf("CPU %d: %d ", thisenv->env_cpunum, p);
  800048:	a1 04 20 80 00       	mov    0x802004,%eax
  80004d:	8b 40 5c             	mov    0x5c(%eax),%eax
  800050:	83 c4 0c             	add    $0xc,%esp
  800053:	53                   	push   %ebx
  800054:	50                   	push   %eax
  800055:	68 c0 14 80 00       	push   $0x8014c0
  80005a:	e8 c2 01 00 00       	call   800221 <cprintf>

	// fork a right neighbor to continue the chain
	if ((id = fork()) < 0)
  80005f:	e8 66 0e 00 00       	call   800eca <fork>
  800064:	89 c6                	mov    %eax,%esi
  800066:	83 c4 10             	add    $0x10,%esp
  800069:	85 c0                	test   %eax,%eax
  80006b:	79 12                	jns    80007f <primeproc+0x4c>
		panic("fork: %e", id);
  80006d:	50                   	push   %eax
  80006e:	68 cc 14 80 00       	push   $0x8014cc
  800073:	6a 25                	push   $0x25
  800075:	68 d5 14 80 00       	push   $0x8014d5
  80007a:	e8 c9 00 00 00       	call   800148 <_panic>
	if (id==0)
  80007f:	85 c0                	test   %eax,%eax
  800081:	74 b5                	je     800038 <primeproc+0x5>
		goto top;
	// filter out multiples of our prime
	while (1) {
		i = ipc_recv(envid, 0, 0);
  800083:	83 ec 04             	sub    $0x4,%esp
  800086:	6a 00                	push   $0x0
  800088:	6a 00                	push   $0x0
  80008a:	6a 00                	push   $0x0
  80008c:	e8 12 10 00 00       	call   8010a3 <ipc_recv>
  800091:	89 c1                	mov    %eax,%ecx
		if (i%p)
  800093:	99                   	cltd   
  800094:	f7 fb                	idiv   %ebx
  800096:	83 c4 10             	add    $0x10,%esp
  800099:	85 d2                	test   %edx,%edx
  80009b:	74 e6                	je     800083 <primeproc+0x50>
		{	//cprintf("%d:send\n",i);
			//for (i = 3; ; i++)
//cprintf("send from %08x to %08x, i %d: p %d: CPUS:%d\n",sys_getenvid(),id,i,p,thisenv->env_cpunum);
			ipc_send(id, i, 0, 0);
  80009d:	6a 00                	push   $0x0
  80009f:	6a 00                	push   $0x0
  8000a1:	51                   	push   %ecx
  8000a2:	56                   	push   %esi
  8000a3:	e8 64 10 00 00       	call   80110c <ipc_send>
  8000a8:	83 c4 10             	add    $0x10,%esp
  8000ab:	eb d6                	jmp    800083 <primeproc+0x50>

008000ad <umain>:
	}
}

void
umain(int argc, char **argv)
{
  8000ad:	55                   	push   %ebp
  8000ae:	89 e5                	mov    %esp,%ebp
  8000b0:	56                   	push   %esi
  8000b1:	53                   	push   %ebx
	int i, id;

	// fork the first prime process in the chain
	if ((id = fork()) < 0)
  8000b2:	e8 13 0e 00 00       	call   800eca <fork>
  8000b7:	89 c6                	mov    %eax,%esi
  8000b9:	85 c0                	test   %eax,%eax
  8000bb:	79 12                	jns    8000cf <umain+0x22>
		panic("fork: %e", id);
  8000bd:	50                   	push   %eax
  8000be:	68 cc 14 80 00       	push   $0x8014cc
  8000c3:	6a 3d                	push   $0x3d
  8000c5:	68 d5 14 80 00       	push   $0x8014d5
  8000ca:	e8 79 00 00 00       	call   800148 <_panic>
  8000cf:	bb 02 00 00 00       	mov    $0x2,%ebx
	if (id == 0)
  8000d4:	85 c0                	test   %eax,%eax
  8000d6:	75 05                	jne    8000dd <umain+0x30>
		primeproc();
  8000d8:	e8 56 ff ff ff       	call   800033 <primeproc>

	// feed all the integers through
	for (i = 2; ; i++)
	{
		//cprintf("send from %08x to %08x, i %d: CPUS:%d\n",thisenv->env_id,id,i,thisenv->env_cpunum);
		ipc_send(id, i, 0, 0);
  8000dd:	6a 00                	push   $0x0
  8000df:	6a 00                	push   $0x0
  8000e1:	53                   	push   %ebx
  8000e2:	56                   	push   %esi
  8000e3:	e8 24 10 00 00       	call   80110c <ipc_send>
		panic("fork: %e", id);
	if (id == 0)
		primeproc();

	// feed all the integers through
	for (i = 2; ; i++)
  8000e8:	83 c3 01             	add    $0x1,%ebx
  8000eb:	83 c4 10             	add    $0x10,%esp
  8000ee:	eb ed                	jmp    8000dd <umain+0x30>

008000f0 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  8000f0:	55                   	push   %ebp
  8000f1:	89 e5                	mov    %esp,%ebp
  8000f3:	56                   	push   %esi
  8000f4:	53                   	push   %ebx
  8000f5:	8b 5d 08             	mov    0x8(%ebp),%ebx
  8000f8:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = &envs[ENVX(sys_getenvid())];
  8000fb:	e8 ea 0a 00 00       	call   800bea <sys_getenvid>
  800100:	25 ff 03 00 00       	and    $0x3ff,%eax
  800105:	6b c0 7c             	imul   $0x7c,%eax,%eax
  800108:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  80010d:	a3 04 20 80 00       	mov    %eax,0x802004
	// save the name of the program so that panic() can use it
	if (argc > 0)
  800112:	85 db                	test   %ebx,%ebx
  800114:	7e 07                	jle    80011d <libmain+0x2d>
		binaryname = argv[0];
  800116:	8b 06                	mov    (%esi),%eax
  800118:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  80011d:	83 ec 08             	sub    $0x8,%esp
  800120:	56                   	push   %esi
  800121:	53                   	push   %ebx
  800122:	e8 86 ff ff ff       	call   8000ad <umain>

	// exit gracefully
	exit();
  800127:	e8 0a 00 00 00       	call   800136 <exit>
}
  80012c:	83 c4 10             	add    $0x10,%esp
  80012f:	8d 65 f8             	lea    -0x8(%ebp),%esp
  800132:	5b                   	pop    %ebx
  800133:	5e                   	pop    %esi
  800134:	5d                   	pop    %ebp
  800135:	c3                   	ret    

00800136 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800136:	55                   	push   %ebp
  800137:	89 e5                	mov    %esp,%ebp
  800139:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  80013c:	6a 00                	push   $0x0
  80013e:	e8 66 0a 00 00       	call   800ba9 <sys_env_destroy>
}
  800143:	83 c4 10             	add    $0x10,%esp
  800146:	c9                   	leave  
  800147:	c3                   	ret    

00800148 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800148:	55                   	push   %ebp
  800149:	89 e5                	mov    %esp,%ebp
  80014b:	56                   	push   %esi
  80014c:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  80014d:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800150:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800156:	e8 8f 0a 00 00       	call   800bea <sys_getenvid>
  80015b:	83 ec 0c             	sub    $0xc,%esp
  80015e:	ff 75 0c             	pushl  0xc(%ebp)
  800161:	ff 75 08             	pushl  0x8(%ebp)
  800164:	56                   	push   %esi
  800165:	50                   	push   %eax
  800166:	68 f0 14 80 00       	push   $0x8014f0
  80016b:	e8 b1 00 00 00       	call   800221 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800170:	83 c4 18             	add    $0x18,%esp
  800173:	53                   	push   %ebx
  800174:	ff 75 10             	pushl  0x10(%ebp)
  800177:	e8 54 00 00 00       	call   8001d0 <vcprintf>
	cprintf("\n");
  80017c:	c7 04 24 13 15 80 00 	movl   $0x801513,(%esp)
  800183:	e8 99 00 00 00       	call   800221 <cprintf>
  800188:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  80018b:	cc                   	int3   
  80018c:	eb fd                	jmp    80018b <_panic+0x43>

0080018e <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  80018e:	55                   	push   %ebp
  80018f:	89 e5                	mov    %esp,%ebp
  800191:	53                   	push   %ebx
  800192:	83 ec 04             	sub    $0x4,%esp
  800195:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  800198:	8b 13                	mov    (%ebx),%edx
  80019a:	8d 42 01             	lea    0x1(%edx),%eax
  80019d:	89 03                	mov    %eax,(%ebx)
  80019f:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8001a2:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8001a6:	3d ff 00 00 00       	cmp    $0xff,%eax
  8001ab:	75 1a                	jne    8001c7 <putch+0x39>
		sys_cputs(b->buf, b->idx);
  8001ad:	83 ec 08             	sub    $0x8,%esp
  8001b0:	68 ff 00 00 00       	push   $0xff
  8001b5:	8d 43 08             	lea    0x8(%ebx),%eax
  8001b8:	50                   	push   %eax
  8001b9:	e8 ae 09 00 00       	call   800b6c <sys_cputs>
		b->idx = 0;
  8001be:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8001c4:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8001c7:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8001cb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8001ce:	c9                   	leave  
  8001cf:	c3                   	ret    

008001d0 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8001d0:	55                   	push   %ebp
  8001d1:	89 e5                	mov    %esp,%ebp
  8001d3:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8001d9:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8001e0:	00 00 00 
	b.cnt = 0;
  8001e3:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8001ea:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8001ed:	ff 75 0c             	pushl  0xc(%ebp)
  8001f0:	ff 75 08             	pushl  0x8(%ebp)
  8001f3:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  8001f9:	50                   	push   %eax
  8001fa:	68 8e 01 80 00       	push   $0x80018e
  8001ff:	e8 1a 01 00 00       	call   80031e <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800204:	83 c4 08             	add    $0x8,%esp
  800207:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  80020d:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800213:	50                   	push   %eax
  800214:	e8 53 09 00 00       	call   800b6c <sys_cputs>

	return b.cnt;
}
  800219:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  80021f:	c9                   	leave  
  800220:	c3                   	ret    

00800221 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800221:	55                   	push   %ebp
  800222:	89 e5                	mov    %esp,%ebp
  800224:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800227:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  80022a:	50                   	push   %eax
  80022b:	ff 75 08             	pushl  0x8(%ebp)
  80022e:	e8 9d ff ff ff       	call   8001d0 <vcprintf>
	va_end(ap);

	return cnt;
}
  800233:	c9                   	leave  
  800234:	c3                   	ret    

00800235 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800235:	55                   	push   %ebp
  800236:	89 e5                	mov    %esp,%ebp
  800238:	57                   	push   %edi
  800239:	56                   	push   %esi
  80023a:	53                   	push   %ebx
  80023b:	83 ec 1c             	sub    $0x1c,%esp
  80023e:	89 c7                	mov    %eax,%edi
  800240:	89 d6                	mov    %edx,%esi
  800242:	8b 45 08             	mov    0x8(%ebp),%eax
  800245:	8b 55 0c             	mov    0xc(%ebp),%edx
  800248:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80024b:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  80024e:	8b 4d 10             	mov    0x10(%ebp),%ecx
  800251:	bb 00 00 00 00       	mov    $0x0,%ebx
  800256:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800259:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  80025c:	39 d3                	cmp    %edx,%ebx
  80025e:	72 05                	jb     800265 <printnum+0x30>
  800260:	39 45 10             	cmp    %eax,0x10(%ebp)
  800263:	77 45                	ja     8002aa <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800265:	83 ec 0c             	sub    $0xc,%esp
  800268:	ff 75 18             	pushl  0x18(%ebp)
  80026b:	8b 45 14             	mov    0x14(%ebp),%eax
  80026e:	8d 58 ff             	lea    -0x1(%eax),%ebx
  800271:	53                   	push   %ebx
  800272:	ff 75 10             	pushl  0x10(%ebp)
  800275:	83 ec 08             	sub    $0x8,%esp
  800278:	ff 75 e4             	pushl  -0x1c(%ebp)
  80027b:	ff 75 e0             	pushl  -0x20(%ebp)
  80027e:	ff 75 dc             	pushl  -0x24(%ebp)
  800281:	ff 75 d8             	pushl  -0x28(%ebp)
  800284:	e8 a7 0f 00 00       	call   801230 <__udivdi3>
  800289:	83 c4 18             	add    $0x18,%esp
  80028c:	52                   	push   %edx
  80028d:	50                   	push   %eax
  80028e:	89 f2                	mov    %esi,%edx
  800290:	89 f8                	mov    %edi,%eax
  800292:	e8 9e ff ff ff       	call   800235 <printnum>
  800297:	83 c4 20             	add    $0x20,%esp
  80029a:	eb 18                	jmp    8002b4 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  80029c:	83 ec 08             	sub    $0x8,%esp
  80029f:	56                   	push   %esi
  8002a0:	ff 75 18             	pushl  0x18(%ebp)
  8002a3:	ff d7                	call   *%edi
  8002a5:	83 c4 10             	add    $0x10,%esp
  8002a8:	eb 03                	jmp    8002ad <printnum+0x78>
  8002aa:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8002ad:	83 eb 01             	sub    $0x1,%ebx
  8002b0:	85 db                	test   %ebx,%ebx
  8002b2:	7f e8                	jg     80029c <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8002b4:	83 ec 08             	sub    $0x8,%esp
  8002b7:	56                   	push   %esi
  8002b8:	83 ec 04             	sub    $0x4,%esp
  8002bb:	ff 75 e4             	pushl  -0x1c(%ebp)
  8002be:	ff 75 e0             	pushl  -0x20(%ebp)
  8002c1:	ff 75 dc             	pushl  -0x24(%ebp)
  8002c4:	ff 75 d8             	pushl  -0x28(%ebp)
  8002c7:	e8 94 10 00 00       	call   801360 <__umoddi3>
  8002cc:	83 c4 14             	add    $0x14,%esp
  8002cf:	0f be 80 15 15 80 00 	movsbl 0x801515(%eax),%eax
  8002d6:	50                   	push   %eax
  8002d7:	ff d7                	call   *%edi
}
  8002d9:	83 c4 10             	add    $0x10,%esp
  8002dc:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8002df:	5b                   	pop    %ebx
  8002e0:	5e                   	pop    %esi
  8002e1:	5f                   	pop    %edi
  8002e2:	5d                   	pop    %ebp
  8002e3:	c3                   	ret    

008002e4 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8002e4:	55                   	push   %ebp
  8002e5:	89 e5                	mov    %esp,%ebp
  8002e7:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8002ea:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8002ee:	8b 10                	mov    (%eax),%edx
  8002f0:	3b 50 04             	cmp    0x4(%eax),%edx
  8002f3:	73 0a                	jae    8002ff <sprintputch+0x1b>
		*b->buf++ = ch;
  8002f5:	8d 4a 01             	lea    0x1(%edx),%ecx
  8002f8:	89 08                	mov    %ecx,(%eax)
  8002fa:	8b 45 08             	mov    0x8(%ebp),%eax
  8002fd:	88 02                	mov    %al,(%edx)
}
  8002ff:	5d                   	pop    %ebp
  800300:	c3                   	ret    

00800301 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800301:	55                   	push   %ebp
  800302:	89 e5                	mov    %esp,%ebp
  800304:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  800307:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  80030a:	50                   	push   %eax
  80030b:	ff 75 10             	pushl  0x10(%ebp)
  80030e:	ff 75 0c             	pushl  0xc(%ebp)
  800311:	ff 75 08             	pushl  0x8(%ebp)
  800314:	e8 05 00 00 00       	call   80031e <vprintfmt>
	va_end(ap);
}
  800319:	83 c4 10             	add    $0x10,%esp
  80031c:	c9                   	leave  
  80031d:	c3                   	ret    

0080031e <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  80031e:	55                   	push   %ebp
  80031f:	89 e5                	mov    %esp,%ebp
  800321:	57                   	push   %edi
  800322:	56                   	push   %esi
  800323:	53                   	push   %ebx
  800324:	83 ec 2c             	sub    $0x2c,%esp
  800327:	8b 75 08             	mov    0x8(%ebp),%esi
  80032a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80032d:	8b 7d 10             	mov    0x10(%ebp),%edi
  800330:	eb 12                	jmp    800344 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800332:	85 c0                	test   %eax,%eax
  800334:	0f 84 42 04 00 00    	je     80077c <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
  80033a:	83 ec 08             	sub    $0x8,%esp
  80033d:	53                   	push   %ebx
  80033e:	50                   	push   %eax
  80033f:	ff d6                	call   *%esi
  800341:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800344:	83 c7 01             	add    $0x1,%edi
  800347:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  80034b:	83 f8 25             	cmp    $0x25,%eax
  80034e:	75 e2                	jne    800332 <vprintfmt+0x14>
  800350:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  800354:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  80035b:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800362:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  800369:	b9 00 00 00 00       	mov    $0x0,%ecx
  80036e:	eb 07                	jmp    800377 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800370:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  800373:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800377:	8d 47 01             	lea    0x1(%edi),%eax
  80037a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  80037d:	0f b6 07             	movzbl (%edi),%eax
  800380:	0f b6 d0             	movzbl %al,%edx
  800383:	83 e8 23             	sub    $0x23,%eax
  800386:	3c 55                	cmp    $0x55,%al
  800388:	0f 87 d3 03 00 00    	ja     800761 <vprintfmt+0x443>
  80038e:	0f b6 c0             	movzbl %al,%eax
  800391:	ff 24 85 e0 15 80 00 	jmp    *0x8015e0(,%eax,4)
  800398:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  80039b:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  80039f:	eb d6                	jmp    800377 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003a1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003a4:	b8 00 00 00 00       	mov    $0x0,%eax
  8003a9:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  8003ac:	8d 04 80             	lea    (%eax,%eax,4),%eax
  8003af:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
  8003b3:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
  8003b6:	8d 4a d0             	lea    -0x30(%edx),%ecx
  8003b9:	83 f9 09             	cmp    $0x9,%ecx
  8003bc:	77 3f                	ja     8003fd <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8003be:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8003c1:	eb e9                	jmp    8003ac <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8003c3:	8b 45 14             	mov    0x14(%ebp),%eax
  8003c6:	8b 00                	mov    (%eax),%eax
  8003c8:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8003cb:	8b 45 14             	mov    0x14(%ebp),%eax
  8003ce:	8d 40 04             	lea    0x4(%eax),%eax
  8003d1:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003d4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8003d7:	eb 2a                	jmp    800403 <vprintfmt+0xe5>
  8003d9:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8003dc:	85 c0                	test   %eax,%eax
  8003de:	ba 00 00 00 00       	mov    $0x0,%edx
  8003e3:	0f 49 d0             	cmovns %eax,%edx
  8003e6:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003e9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003ec:	eb 89                	jmp    800377 <vprintfmt+0x59>
  8003ee:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8003f1:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  8003f8:	e9 7a ff ff ff       	jmp    800377 <vprintfmt+0x59>
  8003fd:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  800400:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  800403:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800407:	0f 89 6a ff ff ff    	jns    800377 <vprintfmt+0x59>
				width = precision, precision = -1;
  80040d:	8b 45 d0             	mov    -0x30(%ebp),%eax
  800410:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800413:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  80041a:	e9 58 ff ff ff       	jmp    800377 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  80041f:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800422:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  800425:	e9 4d ff ff ff       	jmp    800377 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  80042a:	8b 45 14             	mov    0x14(%ebp),%eax
  80042d:	8d 78 04             	lea    0x4(%eax),%edi
  800430:	83 ec 08             	sub    $0x8,%esp
  800433:	53                   	push   %ebx
  800434:	ff 30                	pushl  (%eax)
  800436:	ff d6                	call   *%esi
			break;
  800438:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  80043b:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80043e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  800441:	e9 fe fe ff ff       	jmp    800344 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800446:	8b 45 14             	mov    0x14(%ebp),%eax
  800449:	8d 78 04             	lea    0x4(%eax),%edi
  80044c:	8b 00                	mov    (%eax),%eax
  80044e:	99                   	cltd   
  80044f:	31 d0                	xor    %edx,%eax
  800451:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800453:	83 f8 09             	cmp    $0x9,%eax
  800456:	7f 0b                	jg     800463 <vprintfmt+0x145>
  800458:	8b 14 85 40 17 80 00 	mov    0x801740(,%eax,4),%edx
  80045f:	85 d2                	test   %edx,%edx
  800461:	75 1b                	jne    80047e <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
  800463:	50                   	push   %eax
  800464:	68 2d 15 80 00       	push   $0x80152d
  800469:	53                   	push   %ebx
  80046a:	56                   	push   %esi
  80046b:	e8 91 fe ff ff       	call   800301 <printfmt>
  800470:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  800473:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800476:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  800479:	e9 c6 fe ff ff       	jmp    800344 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  80047e:	52                   	push   %edx
  80047f:	68 36 15 80 00       	push   $0x801536
  800484:	53                   	push   %ebx
  800485:	56                   	push   %esi
  800486:	e8 76 fe ff ff       	call   800301 <printfmt>
  80048b:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  80048e:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800491:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800494:	e9 ab fe ff ff       	jmp    800344 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800499:	8b 45 14             	mov    0x14(%ebp),%eax
  80049c:	83 c0 04             	add    $0x4,%eax
  80049f:	89 45 cc             	mov    %eax,-0x34(%ebp)
  8004a2:	8b 45 14             	mov    0x14(%ebp),%eax
  8004a5:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  8004a7:	85 ff                	test   %edi,%edi
  8004a9:	b8 26 15 80 00       	mov    $0x801526,%eax
  8004ae:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  8004b1:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8004b5:	0f 8e 94 00 00 00    	jle    80054f <vprintfmt+0x231>
  8004bb:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  8004bf:	0f 84 98 00 00 00    	je     80055d <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
  8004c5:	83 ec 08             	sub    $0x8,%esp
  8004c8:	ff 75 d0             	pushl  -0x30(%ebp)
  8004cb:	57                   	push   %edi
  8004cc:	e8 33 03 00 00       	call   800804 <strnlen>
  8004d1:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8004d4:	29 c1                	sub    %eax,%ecx
  8004d6:	89 4d c8             	mov    %ecx,-0x38(%ebp)
  8004d9:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  8004dc:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  8004e0:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8004e3:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  8004e6:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004e8:	eb 0f                	jmp    8004f9 <vprintfmt+0x1db>
					putch(padc, putdat);
  8004ea:	83 ec 08             	sub    $0x8,%esp
  8004ed:	53                   	push   %ebx
  8004ee:	ff 75 e0             	pushl  -0x20(%ebp)
  8004f1:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004f3:	83 ef 01             	sub    $0x1,%edi
  8004f6:	83 c4 10             	add    $0x10,%esp
  8004f9:	85 ff                	test   %edi,%edi
  8004fb:	7f ed                	jg     8004ea <vprintfmt+0x1cc>
  8004fd:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  800500:	8b 4d c8             	mov    -0x38(%ebp),%ecx
  800503:	85 c9                	test   %ecx,%ecx
  800505:	b8 00 00 00 00       	mov    $0x0,%eax
  80050a:	0f 49 c1             	cmovns %ecx,%eax
  80050d:	29 c1                	sub    %eax,%ecx
  80050f:	89 75 08             	mov    %esi,0x8(%ebp)
  800512:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800515:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800518:	89 cb                	mov    %ecx,%ebx
  80051a:	eb 4d                	jmp    800569 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  80051c:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800520:	74 1b                	je     80053d <vprintfmt+0x21f>
  800522:	0f be c0             	movsbl %al,%eax
  800525:	83 e8 20             	sub    $0x20,%eax
  800528:	83 f8 5e             	cmp    $0x5e,%eax
  80052b:	76 10                	jbe    80053d <vprintfmt+0x21f>
					putch('?', putdat);
  80052d:	83 ec 08             	sub    $0x8,%esp
  800530:	ff 75 0c             	pushl  0xc(%ebp)
  800533:	6a 3f                	push   $0x3f
  800535:	ff 55 08             	call   *0x8(%ebp)
  800538:	83 c4 10             	add    $0x10,%esp
  80053b:	eb 0d                	jmp    80054a <vprintfmt+0x22c>
				else
					putch(ch, putdat);
  80053d:	83 ec 08             	sub    $0x8,%esp
  800540:	ff 75 0c             	pushl  0xc(%ebp)
  800543:	52                   	push   %edx
  800544:	ff 55 08             	call   *0x8(%ebp)
  800547:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  80054a:	83 eb 01             	sub    $0x1,%ebx
  80054d:	eb 1a                	jmp    800569 <vprintfmt+0x24b>
  80054f:	89 75 08             	mov    %esi,0x8(%ebp)
  800552:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800555:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800558:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  80055b:	eb 0c                	jmp    800569 <vprintfmt+0x24b>
  80055d:	89 75 08             	mov    %esi,0x8(%ebp)
  800560:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800563:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800566:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800569:	83 c7 01             	add    $0x1,%edi
  80056c:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800570:	0f be d0             	movsbl %al,%edx
  800573:	85 d2                	test   %edx,%edx
  800575:	74 23                	je     80059a <vprintfmt+0x27c>
  800577:	85 f6                	test   %esi,%esi
  800579:	78 a1                	js     80051c <vprintfmt+0x1fe>
  80057b:	83 ee 01             	sub    $0x1,%esi
  80057e:	79 9c                	jns    80051c <vprintfmt+0x1fe>
  800580:	89 df                	mov    %ebx,%edi
  800582:	8b 75 08             	mov    0x8(%ebp),%esi
  800585:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800588:	eb 18                	jmp    8005a2 <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  80058a:	83 ec 08             	sub    $0x8,%esp
  80058d:	53                   	push   %ebx
  80058e:	6a 20                	push   $0x20
  800590:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800592:	83 ef 01             	sub    $0x1,%edi
  800595:	83 c4 10             	add    $0x10,%esp
  800598:	eb 08                	jmp    8005a2 <vprintfmt+0x284>
  80059a:	89 df                	mov    %ebx,%edi
  80059c:	8b 75 08             	mov    0x8(%ebp),%esi
  80059f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8005a2:	85 ff                	test   %edi,%edi
  8005a4:	7f e4                	jg     80058a <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8005a6:	8b 45 cc             	mov    -0x34(%ebp),%eax
  8005a9:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005ac:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8005af:	e9 90 fd ff ff       	jmp    800344 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8005b4:	83 f9 01             	cmp    $0x1,%ecx
  8005b7:	7e 19                	jle    8005d2 <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
  8005b9:	8b 45 14             	mov    0x14(%ebp),%eax
  8005bc:	8b 50 04             	mov    0x4(%eax),%edx
  8005bf:	8b 00                	mov    (%eax),%eax
  8005c1:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005c4:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8005c7:	8b 45 14             	mov    0x14(%ebp),%eax
  8005ca:	8d 40 08             	lea    0x8(%eax),%eax
  8005cd:	89 45 14             	mov    %eax,0x14(%ebp)
  8005d0:	eb 38                	jmp    80060a <vprintfmt+0x2ec>
	else if (lflag)
  8005d2:	85 c9                	test   %ecx,%ecx
  8005d4:	74 1b                	je     8005f1 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
  8005d6:	8b 45 14             	mov    0x14(%ebp),%eax
  8005d9:	8b 00                	mov    (%eax),%eax
  8005db:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005de:	89 c1                	mov    %eax,%ecx
  8005e0:	c1 f9 1f             	sar    $0x1f,%ecx
  8005e3:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8005e6:	8b 45 14             	mov    0x14(%ebp),%eax
  8005e9:	8d 40 04             	lea    0x4(%eax),%eax
  8005ec:	89 45 14             	mov    %eax,0x14(%ebp)
  8005ef:	eb 19                	jmp    80060a <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
  8005f1:	8b 45 14             	mov    0x14(%ebp),%eax
  8005f4:	8b 00                	mov    (%eax),%eax
  8005f6:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005f9:	89 c1                	mov    %eax,%ecx
  8005fb:	c1 f9 1f             	sar    $0x1f,%ecx
  8005fe:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  800601:	8b 45 14             	mov    0x14(%ebp),%eax
  800604:	8d 40 04             	lea    0x4(%eax),%eax
  800607:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  80060a:	8b 55 d8             	mov    -0x28(%ebp),%edx
  80060d:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800610:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800615:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800619:	0f 89 0e 01 00 00    	jns    80072d <vprintfmt+0x40f>
				putch('-', putdat);
  80061f:	83 ec 08             	sub    $0x8,%esp
  800622:	53                   	push   %ebx
  800623:	6a 2d                	push   $0x2d
  800625:	ff d6                	call   *%esi
				num = -(long long) num;
  800627:	8b 55 d8             	mov    -0x28(%ebp),%edx
  80062a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  80062d:	f7 da                	neg    %edx
  80062f:	83 d1 00             	adc    $0x0,%ecx
  800632:	f7 d9                	neg    %ecx
  800634:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  800637:	b8 0a 00 00 00       	mov    $0xa,%eax
  80063c:	e9 ec 00 00 00       	jmp    80072d <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800641:	83 f9 01             	cmp    $0x1,%ecx
  800644:	7e 18                	jle    80065e <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
  800646:	8b 45 14             	mov    0x14(%ebp),%eax
  800649:	8b 10                	mov    (%eax),%edx
  80064b:	8b 48 04             	mov    0x4(%eax),%ecx
  80064e:	8d 40 08             	lea    0x8(%eax),%eax
  800651:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800654:	b8 0a 00 00 00       	mov    $0xa,%eax
  800659:	e9 cf 00 00 00       	jmp    80072d <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  80065e:	85 c9                	test   %ecx,%ecx
  800660:	74 1a                	je     80067c <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
  800662:	8b 45 14             	mov    0x14(%ebp),%eax
  800665:	8b 10                	mov    (%eax),%edx
  800667:	b9 00 00 00 00       	mov    $0x0,%ecx
  80066c:	8d 40 04             	lea    0x4(%eax),%eax
  80066f:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800672:	b8 0a 00 00 00       	mov    $0xa,%eax
  800677:	e9 b1 00 00 00       	jmp    80072d <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  80067c:	8b 45 14             	mov    0x14(%ebp),%eax
  80067f:	8b 10                	mov    (%eax),%edx
  800681:	b9 00 00 00 00       	mov    $0x0,%ecx
  800686:	8d 40 04             	lea    0x4(%eax),%eax
  800689:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  80068c:	b8 0a 00 00 00       	mov    $0xa,%eax
  800691:	e9 97 00 00 00       	jmp    80072d <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
  800696:	83 ec 08             	sub    $0x8,%esp
  800699:	53                   	push   %ebx
  80069a:	6a 58                	push   $0x58
  80069c:	ff d6                	call   *%esi
			putch('X', putdat);
  80069e:	83 c4 08             	add    $0x8,%esp
  8006a1:	53                   	push   %ebx
  8006a2:	6a 58                	push   $0x58
  8006a4:	ff d6                	call   *%esi
			putch('X', putdat);
  8006a6:	83 c4 08             	add    $0x8,%esp
  8006a9:	53                   	push   %ebx
  8006aa:	6a 58                	push   $0x58
  8006ac:	ff d6                	call   *%esi
			break;
  8006ae:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8006b1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
  8006b4:	e9 8b fc ff ff       	jmp    800344 <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
  8006b9:	83 ec 08             	sub    $0x8,%esp
  8006bc:	53                   	push   %ebx
  8006bd:	6a 30                	push   $0x30
  8006bf:	ff d6                	call   *%esi
			putch('x', putdat);
  8006c1:	83 c4 08             	add    $0x8,%esp
  8006c4:	53                   	push   %ebx
  8006c5:	6a 78                	push   $0x78
  8006c7:	ff d6                	call   *%esi
			num = (unsigned long long)
  8006c9:	8b 45 14             	mov    0x14(%ebp),%eax
  8006cc:	8b 10                	mov    (%eax),%edx
  8006ce:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  8006d3:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  8006d6:	8d 40 04             	lea    0x4(%eax),%eax
  8006d9:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  8006dc:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
  8006e1:	eb 4a                	jmp    80072d <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8006e3:	83 f9 01             	cmp    $0x1,%ecx
  8006e6:	7e 15                	jle    8006fd <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
  8006e8:	8b 45 14             	mov    0x14(%ebp),%eax
  8006eb:	8b 10                	mov    (%eax),%edx
  8006ed:	8b 48 04             	mov    0x4(%eax),%ecx
  8006f0:	8d 40 08             	lea    0x8(%eax),%eax
  8006f3:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  8006f6:	b8 10 00 00 00       	mov    $0x10,%eax
  8006fb:	eb 30                	jmp    80072d <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  8006fd:	85 c9                	test   %ecx,%ecx
  8006ff:	74 17                	je     800718 <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
  800701:	8b 45 14             	mov    0x14(%ebp),%eax
  800704:	8b 10                	mov    (%eax),%edx
  800706:	b9 00 00 00 00       	mov    $0x0,%ecx
  80070b:	8d 40 04             	lea    0x4(%eax),%eax
  80070e:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800711:	b8 10 00 00 00       	mov    $0x10,%eax
  800716:	eb 15                	jmp    80072d <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
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
		number:
			printnum(putch, putdat, num, base, width, padc);
  80072d:	83 ec 0c             	sub    $0xc,%esp
  800730:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  800734:	57                   	push   %edi
  800735:	ff 75 e0             	pushl  -0x20(%ebp)
  800738:	50                   	push   %eax
  800739:	51                   	push   %ecx
  80073a:	52                   	push   %edx
  80073b:	89 da                	mov    %ebx,%edx
  80073d:	89 f0                	mov    %esi,%eax
  80073f:	e8 f1 fa ff ff       	call   800235 <printnum>
			break;
  800744:	83 c4 20             	add    $0x20,%esp
  800747:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80074a:	e9 f5 fb ff ff       	jmp    800344 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  80074f:	83 ec 08             	sub    $0x8,%esp
  800752:	53                   	push   %ebx
  800753:	52                   	push   %edx
  800754:	ff d6                	call   *%esi
			break;
  800756:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800759:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  80075c:	e9 e3 fb ff ff       	jmp    800344 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  800761:	83 ec 08             	sub    $0x8,%esp
  800764:	53                   	push   %ebx
  800765:	6a 25                	push   $0x25
  800767:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800769:	83 c4 10             	add    $0x10,%esp
  80076c:	eb 03                	jmp    800771 <vprintfmt+0x453>
  80076e:	83 ef 01             	sub    $0x1,%edi
  800771:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800775:	75 f7                	jne    80076e <vprintfmt+0x450>
  800777:	e9 c8 fb ff ff       	jmp    800344 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  80077c:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80077f:	5b                   	pop    %ebx
  800780:	5e                   	pop    %esi
  800781:	5f                   	pop    %edi
  800782:	5d                   	pop    %ebp
  800783:	c3                   	ret    

00800784 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800784:	55                   	push   %ebp
  800785:	89 e5                	mov    %esp,%ebp
  800787:	83 ec 18             	sub    $0x18,%esp
  80078a:	8b 45 08             	mov    0x8(%ebp),%eax
  80078d:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800790:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800793:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800797:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  80079a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8007a1:	85 c0                	test   %eax,%eax
  8007a3:	74 26                	je     8007cb <vsnprintf+0x47>
  8007a5:	85 d2                	test   %edx,%edx
  8007a7:	7e 22                	jle    8007cb <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  8007a9:	ff 75 14             	pushl  0x14(%ebp)
  8007ac:	ff 75 10             	pushl  0x10(%ebp)
  8007af:	8d 45 ec             	lea    -0x14(%ebp),%eax
  8007b2:	50                   	push   %eax
  8007b3:	68 e4 02 80 00       	push   $0x8002e4
  8007b8:	e8 61 fb ff ff       	call   80031e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  8007bd:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8007c0:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  8007c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8007c6:	83 c4 10             	add    $0x10,%esp
  8007c9:	eb 05                	jmp    8007d0 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  8007cb:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  8007d0:	c9                   	leave  
  8007d1:	c3                   	ret    

008007d2 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  8007d2:	55                   	push   %ebp
  8007d3:	89 e5                	mov    %esp,%ebp
  8007d5:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  8007d8:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  8007db:	50                   	push   %eax
  8007dc:	ff 75 10             	pushl  0x10(%ebp)
  8007df:	ff 75 0c             	pushl  0xc(%ebp)
  8007e2:	ff 75 08             	pushl  0x8(%ebp)
  8007e5:	e8 9a ff ff ff       	call   800784 <vsnprintf>
	va_end(ap);

	return rc;
}
  8007ea:	c9                   	leave  
  8007eb:	c3                   	ret    

008007ec <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  8007ec:	55                   	push   %ebp
  8007ed:	89 e5                	mov    %esp,%ebp
  8007ef:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  8007f2:	b8 00 00 00 00       	mov    $0x0,%eax
  8007f7:	eb 03                	jmp    8007fc <strlen+0x10>
		n++;
  8007f9:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  8007fc:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800800:	75 f7                	jne    8007f9 <strlen+0xd>
		n++;
	return n;
}
  800802:	5d                   	pop    %ebp
  800803:	c3                   	ret    

00800804 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800804:	55                   	push   %ebp
  800805:	89 e5                	mov    %esp,%ebp
  800807:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80080a:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80080d:	ba 00 00 00 00       	mov    $0x0,%edx
  800812:	eb 03                	jmp    800817 <strnlen+0x13>
		n++;
  800814:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800817:	39 c2                	cmp    %eax,%edx
  800819:	74 08                	je     800823 <strnlen+0x1f>
  80081b:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  80081f:	75 f3                	jne    800814 <strnlen+0x10>
  800821:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  800823:	5d                   	pop    %ebp
  800824:	c3                   	ret    

00800825 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800825:	55                   	push   %ebp
  800826:	89 e5                	mov    %esp,%ebp
  800828:	53                   	push   %ebx
  800829:	8b 45 08             	mov    0x8(%ebp),%eax
  80082c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  80082f:	89 c2                	mov    %eax,%edx
  800831:	83 c2 01             	add    $0x1,%edx
  800834:	83 c1 01             	add    $0x1,%ecx
  800837:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  80083b:	88 5a ff             	mov    %bl,-0x1(%edx)
  80083e:	84 db                	test   %bl,%bl
  800840:	75 ef                	jne    800831 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800842:	5b                   	pop    %ebx
  800843:	5d                   	pop    %ebp
  800844:	c3                   	ret    

00800845 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800845:	55                   	push   %ebp
  800846:	89 e5                	mov    %esp,%ebp
  800848:	53                   	push   %ebx
  800849:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  80084c:	53                   	push   %ebx
  80084d:	e8 9a ff ff ff       	call   8007ec <strlen>
  800852:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  800855:	ff 75 0c             	pushl  0xc(%ebp)
  800858:	01 d8                	add    %ebx,%eax
  80085a:	50                   	push   %eax
  80085b:	e8 c5 ff ff ff       	call   800825 <strcpy>
	return dst;
}
  800860:	89 d8                	mov    %ebx,%eax
  800862:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800865:	c9                   	leave  
  800866:	c3                   	ret    

00800867 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800867:	55                   	push   %ebp
  800868:	89 e5                	mov    %esp,%ebp
  80086a:	56                   	push   %esi
  80086b:	53                   	push   %ebx
  80086c:	8b 75 08             	mov    0x8(%ebp),%esi
  80086f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800872:	89 f3                	mov    %esi,%ebx
  800874:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800877:	89 f2                	mov    %esi,%edx
  800879:	eb 0f                	jmp    80088a <strncpy+0x23>
		*dst++ = *src;
  80087b:	83 c2 01             	add    $0x1,%edx
  80087e:	0f b6 01             	movzbl (%ecx),%eax
  800881:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800884:	80 39 01             	cmpb   $0x1,(%ecx)
  800887:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  80088a:	39 da                	cmp    %ebx,%edx
  80088c:	75 ed                	jne    80087b <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  80088e:	89 f0                	mov    %esi,%eax
  800890:	5b                   	pop    %ebx
  800891:	5e                   	pop    %esi
  800892:	5d                   	pop    %ebp
  800893:	c3                   	ret    

00800894 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800894:	55                   	push   %ebp
  800895:	89 e5                	mov    %esp,%ebp
  800897:	56                   	push   %esi
  800898:	53                   	push   %ebx
  800899:	8b 75 08             	mov    0x8(%ebp),%esi
  80089c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80089f:	8b 55 10             	mov    0x10(%ebp),%edx
  8008a2:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  8008a4:	85 d2                	test   %edx,%edx
  8008a6:	74 21                	je     8008c9 <strlcpy+0x35>
  8008a8:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  8008ac:	89 f2                	mov    %esi,%edx
  8008ae:	eb 09                	jmp    8008b9 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  8008b0:	83 c2 01             	add    $0x1,%edx
  8008b3:	83 c1 01             	add    $0x1,%ecx
  8008b6:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  8008b9:	39 c2                	cmp    %eax,%edx
  8008bb:	74 09                	je     8008c6 <strlcpy+0x32>
  8008bd:	0f b6 19             	movzbl (%ecx),%ebx
  8008c0:	84 db                	test   %bl,%bl
  8008c2:	75 ec                	jne    8008b0 <strlcpy+0x1c>
  8008c4:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  8008c6:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  8008c9:	29 f0                	sub    %esi,%eax
}
  8008cb:	5b                   	pop    %ebx
  8008cc:	5e                   	pop    %esi
  8008cd:	5d                   	pop    %ebp
  8008ce:	c3                   	ret    

008008cf <strcmp>:

int
strcmp(const char *p, const char *q)
{
  8008cf:	55                   	push   %ebp
  8008d0:	89 e5                	mov    %esp,%ebp
  8008d2:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8008d5:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  8008d8:	eb 06                	jmp    8008e0 <strcmp+0x11>
		p++, q++;
  8008da:	83 c1 01             	add    $0x1,%ecx
  8008dd:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  8008e0:	0f b6 01             	movzbl (%ecx),%eax
  8008e3:	84 c0                	test   %al,%al
  8008e5:	74 04                	je     8008eb <strcmp+0x1c>
  8008e7:	3a 02                	cmp    (%edx),%al
  8008e9:	74 ef                	je     8008da <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  8008eb:	0f b6 c0             	movzbl %al,%eax
  8008ee:	0f b6 12             	movzbl (%edx),%edx
  8008f1:	29 d0                	sub    %edx,%eax
}
  8008f3:	5d                   	pop    %ebp
  8008f4:	c3                   	ret    

008008f5 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  8008f5:	55                   	push   %ebp
  8008f6:	89 e5                	mov    %esp,%ebp
  8008f8:	53                   	push   %ebx
  8008f9:	8b 45 08             	mov    0x8(%ebp),%eax
  8008fc:	8b 55 0c             	mov    0xc(%ebp),%edx
  8008ff:	89 c3                	mov    %eax,%ebx
  800901:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800904:	eb 06                	jmp    80090c <strncmp+0x17>
		n--, p++, q++;
  800906:	83 c0 01             	add    $0x1,%eax
  800909:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  80090c:	39 d8                	cmp    %ebx,%eax
  80090e:	74 15                	je     800925 <strncmp+0x30>
  800910:	0f b6 08             	movzbl (%eax),%ecx
  800913:	84 c9                	test   %cl,%cl
  800915:	74 04                	je     80091b <strncmp+0x26>
  800917:	3a 0a                	cmp    (%edx),%cl
  800919:	74 eb                	je     800906 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  80091b:	0f b6 00             	movzbl (%eax),%eax
  80091e:	0f b6 12             	movzbl (%edx),%edx
  800921:	29 d0                	sub    %edx,%eax
  800923:	eb 05                	jmp    80092a <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800925:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  80092a:	5b                   	pop    %ebx
  80092b:	5d                   	pop    %ebp
  80092c:	c3                   	ret    

0080092d <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  80092d:	55                   	push   %ebp
  80092e:	89 e5                	mov    %esp,%ebp
  800930:	8b 45 08             	mov    0x8(%ebp),%eax
  800933:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800937:	eb 07                	jmp    800940 <strchr+0x13>
		if (*s == c)
  800939:	38 ca                	cmp    %cl,%dl
  80093b:	74 0f                	je     80094c <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  80093d:	83 c0 01             	add    $0x1,%eax
  800940:	0f b6 10             	movzbl (%eax),%edx
  800943:	84 d2                	test   %dl,%dl
  800945:	75 f2                	jne    800939 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800947:	b8 00 00 00 00       	mov    $0x0,%eax
}
  80094c:	5d                   	pop    %ebp
  80094d:	c3                   	ret    

0080094e <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  80094e:	55                   	push   %ebp
  80094f:	89 e5                	mov    %esp,%ebp
  800951:	8b 45 08             	mov    0x8(%ebp),%eax
  800954:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800958:	eb 03                	jmp    80095d <strfind+0xf>
  80095a:	83 c0 01             	add    $0x1,%eax
  80095d:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  800960:	38 ca                	cmp    %cl,%dl
  800962:	74 04                	je     800968 <strfind+0x1a>
  800964:	84 d2                	test   %dl,%dl
  800966:	75 f2                	jne    80095a <strfind+0xc>
			break;
	return (char *) s;
}
  800968:	5d                   	pop    %ebp
  800969:	c3                   	ret    

0080096a <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  80096a:	55                   	push   %ebp
  80096b:	89 e5                	mov    %esp,%ebp
  80096d:	57                   	push   %edi
  80096e:	56                   	push   %esi
  80096f:	53                   	push   %ebx
  800970:	8b 7d 08             	mov    0x8(%ebp),%edi
  800973:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800976:	85 c9                	test   %ecx,%ecx
  800978:	74 36                	je     8009b0 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  80097a:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800980:	75 28                	jne    8009aa <memset+0x40>
  800982:	f6 c1 03             	test   $0x3,%cl
  800985:	75 23                	jne    8009aa <memset+0x40>
		c &= 0xFF;
  800987:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  80098b:	89 d3                	mov    %edx,%ebx
  80098d:	c1 e3 08             	shl    $0x8,%ebx
  800990:	89 d6                	mov    %edx,%esi
  800992:	c1 e6 18             	shl    $0x18,%esi
  800995:	89 d0                	mov    %edx,%eax
  800997:	c1 e0 10             	shl    $0x10,%eax
  80099a:	09 f0                	or     %esi,%eax
  80099c:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  80099e:	89 d8                	mov    %ebx,%eax
  8009a0:	09 d0                	or     %edx,%eax
  8009a2:	c1 e9 02             	shr    $0x2,%ecx
  8009a5:	fc                   	cld    
  8009a6:	f3 ab                	rep stos %eax,%es:(%edi)
  8009a8:	eb 06                	jmp    8009b0 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  8009aa:	8b 45 0c             	mov    0xc(%ebp),%eax
  8009ad:	fc                   	cld    
  8009ae:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  8009b0:	89 f8                	mov    %edi,%eax
  8009b2:	5b                   	pop    %ebx
  8009b3:	5e                   	pop    %esi
  8009b4:	5f                   	pop    %edi
  8009b5:	5d                   	pop    %ebp
  8009b6:	c3                   	ret    

008009b7 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  8009b7:	55                   	push   %ebp
  8009b8:	89 e5                	mov    %esp,%ebp
  8009ba:	57                   	push   %edi
  8009bb:	56                   	push   %esi
  8009bc:	8b 45 08             	mov    0x8(%ebp),%eax
  8009bf:	8b 75 0c             	mov    0xc(%ebp),%esi
  8009c2:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  8009c5:	39 c6                	cmp    %eax,%esi
  8009c7:	73 35                	jae    8009fe <memmove+0x47>
  8009c9:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  8009cc:	39 d0                	cmp    %edx,%eax
  8009ce:	73 2e                	jae    8009fe <memmove+0x47>
		s += n;
		d += n;
  8009d0:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  8009d3:	89 d6                	mov    %edx,%esi
  8009d5:	09 fe                	or     %edi,%esi
  8009d7:	f7 c6 03 00 00 00    	test   $0x3,%esi
  8009dd:	75 13                	jne    8009f2 <memmove+0x3b>
  8009df:	f6 c1 03             	test   $0x3,%cl
  8009e2:	75 0e                	jne    8009f2 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  8009e4:	83 ef 04             	sub    $0x4,%edi
  8009e7:	8d 72 fc             	lea    -0x4(%edx),%esi
  8009ea:	c1 e9 02             	shr    $0x2,%ecx
  8009ed:	fd                   	std    
  8009ee:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  8009f0:	eb 09                	jmp    8009fb <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  8009f2:	83 ef 01             	sub    $0x1,%edi
  8009f5:	8d 72 ff             	lea    -0x1(%edx),%esi
  8009f8:	fd                   	std    
  8009f9:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  8009fb:	fc                   	cld    
  8009fc:	eb 1d                	jmp    800a1b <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  8009fe:	89 f2                	mov    %esi,%edx
  800a00:	09 c2                	or     %eax,%edx
  800a02:	f6 c2 03             	test   $0x3,%dl
  800a05:	75 0f                	jne    800a16 <memmove+0x5f>
  800a07:	f6 c1 03             	test   $0x3,%cl
  800a0a:	75 0a                	jne    800a16 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800a0c:	c1 e9 02             	shr    $0x2,%ecx
  800a0f:	89 c7                	mov    %eax,%edi
  800a11:	fc                   	cld    
  800a12:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a14:	eb 05                	jmp    800a1b <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800a16:	89 c7                	mov    %eax,%edi
  800a18:	fc                   	cld    
  800a19:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800a1b:	5e                   	pop    %esi
  800a1c:	5f                   	pop    %edi
  800a1d:	5d                   	pop    %ebp
  800a1e:	c3                   	ret    

00800a1f <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800a1f:	55                   	push   %ebp
  800a20:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  800a22:	ff 75 10             	pushl  0x10(%ebp)
  800a25:	ff 75 0c             	pushl  0xc(%ebp)
  800a28:	ff 75 08             	pushl  0x8(%ebp)
  800a2b:	e8 87 ff ff ff       	call   8009b7 <memmove>
}
  800a30:	c9                   	leave  
  800a31:	c3                   	ret    

00800a32 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800a32:	55                   	push   %ebp
  800a33:	89 e5                	mov    %esp,%ebp
  800a35:	56                   	push   %esi
  800a36:	53                   	push   %ebx
  800a37:	8b 45 08             	mov    0x8(%ebp),%eax
  800a3a:	8b 55 0c             	mov    0xc(%ebp),%edx
  800a3d:	89 c6                	mov    %eax,%esi
  800a3f:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a42:	eb 1a                	jmp    800a5e <memcmp+0x2c>
		if (*s1 != *s2)
  800a44:	0f b6 08             	movzbl (%eax),%ecx
  800a47:	0f b6 1a             	movzbl (%edx),%ebx
  800a4a:	38 d9                	cmp    %bl,%cl
  800a4c:	74 0a                	je     800a58 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800a4e:	0f b6 c1             	movzbl %cl,%eax
  800a51:	0f b6 db             	movzbl %bl,%ebx
  800a54:	29 d8                	sub    %ebx,%eax
  800a56:	eb 0f                	jmp    800a67 <memcmp+0x35>
		s1++, s2++;
  800a58:	83 c0 01             	add    $0x1,%eax
  800a5b:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a5e:	39 f0                	cmp    %esi,%eax
  800a60:	75 e2                	jne    800a44 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800a62:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800a67:	5b                   	pop    %ebx
  800a68:	5e                   	pop    %esi
  800a69:	5d                   	pop    %ebp
  800a6a:	c3                   	ret    

00800a6b <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800a6b:	55                   	push   %ebp
  800a6c:	89 e5                	mov    %esp,%ebp
  800a6e:	53                   	push   %ebx
  800a6f:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  800a72:	89 c1                	mov    %eax,%ecx
  800a74:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  800a77:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a7b:	eb 0a                	jmp    800a87 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  800a7d:	0f b6 10             	movzbl (%eax),%edx
  800a80:	39 da                	cmp    %ebx,%edx
  800a82:	74 07                	je     800a8b <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a84:	83 c0 01             	add    $0x1,%eax
  800a87:	39 c8                	cmp    %ecx,%eax
  800a89:	72 f2                	jb     800a7d <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800a8b:	5b                   	pop    %ebx
  800a8c:	5d                   	pop    %ebp
  800a8d:	c3                   	ret    

00800a8e <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800a8e:	55                   	push   %ebp
  800a8f:	89 e5                	mov    %esp,%ebp
  800a91:	57                   	push   %edi
  800a92:	56                   	push   %esi
  800a93:	53                   	push   %ebx
  800a94:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a97:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a9a:	eb 03                	jmp    800a9f <strtol+0x11>
		s++;
  800a9c:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a9f:	0f b6 01             	movzbl (%ecx),%eax
  800aa2:	3c 20                	cmp    $0x20,%al
  800aa4:	74 f6                	je     800a9c <strtol+0xe>
  800aa6:	3c 09                	cmp    $0x9,%al
  800aa8:	74 f2                	je     800a9c <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800aaa:	3c 2b                	cmp    $0x2b,%al
  800aac:	75 0a                	jne    800ab8 <strtol+0x2a>
		s++;
  800aae:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800ab1:	bf 00 00 00 00       	mov    $0x0,%edi
  800ab6:	eb 11                	jmp    800ac9 <strtol+0x3b>
  800ab8:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800abd:	3c 2d                	cmp    $0x2d,%al
  800abf:	75 08                	jne    800ac9 <strtol+0x3b>
		s++, neg = 1;
  800ac1:	83 c1 01             	add    $0x1,%ecx
  800ac4:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800ac9:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800acf:	75 15                	jne    800ae6 <strtol+0x58>
  800ad1:	80 39 30             	cmpb   $0x30,(%ecx)
  800ad4:	75 10                	jne    800ae6 <strtol+0x58>
  800ad6:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800ada:	75 7c                	jne    800b58 <strtol+0xca>
		s += 2, base = 16;
  800adc:	83 c1 02             	add    $0x2,%ecx
  800adf:	bb 10 00 00 00       	mov    $0x10,%ebx
  800ae4:	eb 16                	jmp    800afc <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800ae6:	85 db                	test   %ebx,%ebx
  800ae8:	75 12                	jne    800afc <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800aea:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800aef:	80 39 30             	cmpb   $0x30,(%ecx)
  800af2:	75 08                	jne    800afc <strtol+0x6e>
		s++, base = 8;
  800af4:	83 c1 01             	add    $0x1,%ecx
  800af7:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800afc:	b8 00 00 00 00       	mov    $0x0,%eax
  800b01:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800b04:	0f b6 11             	movzbl (%ecx),%edx
  800b07:	8d 72 d0             	lea    -0x30(%edx),%esi
  800b0a:	89 f3                	mov    %esi,%ebx
  800b0c:	80 fb 09             	cmp    $0x9,%bl
  800b0f:	77 08                	ja     800b19 <strtol+0x8b>
			dig = *s - '0';
  800b11:	0f be d2             	movsbl %dl,%edx
  800b14:	83 ea 30             	sub    $0x30,%edx
  800b17:	eb 22                	jmp    800b3b <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800b19:	8d 72 9f             	lea    -0x61(%edx),%esi
  800b1c:	89 f3                	mov    %esi,%ebx
  800b1e:	80 fb 19             	cmp    $0x19,%bl
  800b21:	77 08                	ja     800b2b <strtol+0x9d>
			dig = *s - 'a' + 10;
  800b23:	0f be d2             	movsbl %dl,%edx
  800b26:	83 ea 57             	sub    $0x57,%edx
  800b29:	eb 10                	jmp    800b3b <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800b2b:	8d 72 bf             	lea    -0x41(%edx),%esi
  800b2e:	89 f3                	mov    %esi,%ebx
  800b30:	80 fb 19             	cmp    $0x19,%bl
  800b33:	77 16                	ja     800b4b <strtol+0xbd>
			dig = *s - 'A' + 10;
  800b35:	0f be d2             	movsbl %dl,%edx
  800b38:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800b3b:	3b 55 10             	cmp    0x10(%ebp),%edx
  800b3e:	7d 0b                	jge    800b4b <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800b40:	83 c1 01             	add    $0x1,%ecx
  800b43:	0f af 45 10          	imul   0x10(%ebp),%eax
  800b47:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800b49:	eb b9                	jmp    800b04 <strtol+0x76>

	if (endptr)
  800b4b:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800b4f:	74 0d                	je     800b5e <strtol+0xd0>
		*endptr = (char *) s;
  800b51:	8b 75 0c             	mov    0xc(%ebp),%esi
  800b54:	89 0e                	mov    %ecx,(%esi)
  800b56:	eb 06                	jmp    800b5e <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800b58:	85 db                	test   %ebx,%ebx
  800b5a:	74 98                	je     800af4 <strtol+0x66>
  800b5c:	eb 9e                	jmp    800afc <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800b5e:	89 c2                	mov    %eax,%edx
  800b60:	f7 da                	neg    %edx
  800b62:	85 ff                	test   %edi,%edi
  800b64:	0f 45 c2             	cmovne %edx,%eax
}
  800b67:	5b                   	pop    %ebx
  800b68:	5e                   	pop    %esi
  800b69:	5f                   	pop    %edi
  800b6a:	5d                   	pop    %ebp
  800b6b:	c3                   	ret    

00800b6c <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800b6c:	55                   	push   %ebp
  800b6d:	89 e5                	mov    %esp,%ebp
  800b6f:	57                   	push   %edi
  800b70:	56                   	push   %esi
  800b71:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b72:	b8 00 00 00 00       	mov    $0x0,%eax
  800b77:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800b7a:	8b 55 08             	mov    0x8(%ebp),%edx
  800b7d:	89 c3                	mov    %eax,%ebx
  800b7f:	89 c7                	mov    %eax,%edi
  800b81:	89 c6                	mov    %eax,%esi
  800b83:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800b85:	5b                   	pop    %ebx
  800b86:	5e                   	pop    %esi
  800b87:	5f                   	pop    %edi
  800b88:	5d                   	pop    %ebp
  800b89:	c3                   	ret    

00800b8a <sys_cgetc>:

int
sys_cgetc(void)
{
  800b8a:	55                   	push   %ebp
  800b8b:	89 e5                	mov    %esp,%ebp
  800b8d:	57                   	push   %edi
  800b8e:	56                   	push   %esi
  800b8f:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b90:	ba 00 00 00 00       	mov    $0x0,%edx
  800b95:	b8 01 00 00 00       	mov    $0x1,%eax
  800b9a:	89 d1                	mov    %edx,%ecx
  800b9c:	89 d3                	mov    %edx,%ebx
  800b9e:	89 d7                	mov    %edx,%edi
  800ba0:	89 d6                	mov    %edx,%esi
  800ba2:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800ba4:	5b                   	pop    %ebx
  800ba5:	5e                   	pop    %esi
  800ba6:	5f                   	pop    %edi
  800ba7:	5d                   	pop    %ebp
  800ba8:	c3                   	ret    

00800ba9 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800ba9:	55                   	push   %ebp
  800baa:	89 e5                	mov    %esp,%ebp
  800bac:	57                   	push   %edi
  800bad:	56                   	push   %esi
  800bae:	53                   	push   %ebx
  800baf:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800bb2:	b9 00 00 00 00       	mov    $0x0,%ecx
  800bb7:	b8 03 00 00 00       	mov    $0x3,%eax
  800bbc:	8b 55 08             	mov    0x8(%ebp),%edx
  800bbf:	89 cb                	mov    %ecx,%ebx
  800bc1:	89 cf                	mov    %ecx,%edi
  800bc3:	89 ce                	mov    %ecx,%esi
  800bc5:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800bc7:	85 c0                	test   %eax,%eax
  800bc9:	7e 17                	jle    800be2 <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800bcb:	83 ec 0c             	sub    $0xc,%esp
  800bce:	50                   	push   %eax
  800bcf:	6a 03                	push   $0x3
  800bd1:	68 68 17 80 00       	push   $0x801768
  800bd6:	6a 23                	push   $0x23
  800bd8:	68 85 17 80 00       	push   $0x801785
  800bdd:	e8 66 f5 ff ff       	call   800148 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800be2:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800be5:	5b                   	pop    %ebx
  800be6:	5e                   	pop    %esi
  800be7:	5f                   	pop    %edi
  800be8:	5d                   	pop    %ebp
  800be9:	c3                   	ret    

00800bea <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800bea:	55                   	push   %ebp
  800beb:	89 e5                	mov    %esp,%ebp
  800bed:	57                   	push   %edi
  800bee:	56                   	push   %esi
  800bef:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800bf0:	ba 00 00 00 00       	mov    $0x0,%edx
  800bf5:	b8 02 00 00 00       	mov    $0x2,%eax
  800bfa:	89 d1                	mov    %edx,%ecx
  800bfc:	89 d3                	mov    %edx,%ebx
  800bfe:	89 d7                	mov    %edx,%edi
  800c00:	89 d6                	mov    %edx,%esi
  800c02:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800c04:	5b                   	pop    %ebx
  800c05:	5e                   	pop    %esi
  800c06:	5f                   	pop    %edi
  800c07:	5d                   	pop    %ebp
  800c08:	c3                   	ret    

00800c09 <sys_yield>:

void
sys_yield(void)
{
  800c09:	55                   	push   %ebp
  800c0a:	89 e5                	mov    %esp,%ebp
  800c0c:	57                   	push   %edi
  800c0d:	56                   	push   %esi
  800c0e:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c0f:	ba 00 00 00 00       	mov    $0x0,%edx
  800c14:	b8 0a 00 00 00       	mov    $0xa,%eax
  800c19:	89 d1                	mov    %edx,%ecx
  800c1b:	89 d3                	mov    %edx,%ebx
  800c1d:	89 d7                	mov    %edx,%edi
  800c1f:	89 d6                	mov    %edx,%esi
  800c21:	cd 30                	int    $0x30

void
sys_yield(void)
{
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
}
  800c23:	5b                   	pop    %ebx
  800c24:	5e                   	pop    %esi
  800c25:	5f                   	pop    %edi
  800c26:	5d                   	pop    %ebp
  800c27:	c3                   	ret    

00800c28 <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  800c28:	55                   	push   %ebp
  800c29:	89 e5                	mov    %esp,%ebp
  800c2b:	57                   	push   %edi
  800c2c:	56                   	push   %esi
  800c2d:	53                   	push   %ebx
  800c2e:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c31:	be 00 00 00 00       	mov    $0x0,%esi
  800c36:	b8 04 00 00 00       	mov    $0x4,%eax
  800c3b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800c3e:	8b 55 08             	mov    0x8(%ebp),%edx
  800c41:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800c44:	89 f7                	mov    %esi,%edi
  800c46:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800c48:	85 c0                	test   %eax,%eax
  800c4a:	7e 17                	jle    800c63 <sys_page_alloc+0x3b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800c4c:	83 ec 0c             	sub    $0xc,%esp
  800c4f:	50                   	push   %eax
  800c50:	6a 04                	push   $0x4
  800c52:	68 68 17 80 00       	push   $0x801768
  800c57:	6a 23                	push   $0x23
  800c59:	68 85 17 80 00       	push   $0x801785
  800c5e:	e8 e5 f4 ff ff       	call   800148 <_panic>

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
}
  800c63:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800c66:	5b                   	pop    %ebx
  800c67:	5e                   	pop    %esi
  800c68:	5f                   	pop    %edi
  800c69:	5d                   	pop    %ebp
  800c6a:	c3                   	ret    

00800c6b <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  800c6b:	55                   	push   %ebp
  800c6c:	89 e5                	mov    %esp,%ebp
  800c6e:	57                   	push   %edi
  800c6f:	56                   	push   %esi
  800c70:	53                   	push   %ebx
  800c71:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c74:	b8 05 00 00 00       	mov    $0x5,%eax
  800c79:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800c7c:	8b 55 08             	mov    0x8(%ebp),%edx
  800c7f:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800c82:	8b 7d 14             	mov    0x14(%ebp),%edi
  800c85:	8b 75 18             	mov    0x18(%ebp),%esi
  800c88:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800c8a:	85 c0                	test   %eax,%eax
  800c8c:	7e 17                	jle    800ca5 <sys_page_map+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800c8e:	83 ec 0c             	sub    $0xc,%esp
  800c91:	50                   	push   %eax
  800c92:	6a 05                	push   $0x5
  800c94:	68 68 17 80 00       	push   $0x801768
  800c99:	6a 23                	push   $0x23
  800c9b:	68 85 17 80 00       	push   $0x801785
  800ca0:	e8 a3 f4 ff ff       	call   800148 <_panic>

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
}
  800ca5:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800ca8:	5b                   	pop    %ebx
  800ca9:	5e                   	pop    %esi
  800caa:	5f                   	pop    %edi
  800cab:	5d                   	pop    %ebp
  800cac:	c3                   	ret    

00800cad <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  800cad:	55                   	push   %ebp
  800cae:	89 e5                	mov    %esp,%ebp
  800cb0:	57                   	push   %edi
  800cb1:	56                   	push   %esi
  800cb2:	53                   	push   %ebx
  800cb3:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800cb6:	bb 00 00 00 00       	mov    $0x0,%ebx
  800cbb:	b8 06 00 00 00       	mov    $0x6,%eax
  800cc0:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800cc3:	8b 55 08             	mov    0x8(%ebp),%edx
  800cc6:	89 df                	mov    %ebx,%edi
  800cc8:	89 de                	mov    %ebx,%esi
  800cca:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800ccc:	85 c0                	test   %eax,%eax
  800cce:	7e 17                	jle    800ce7 <sys_page_unmap+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800cd0:	83 ec 0c             	sub    $0xc,%esp
  800cd3:	50                   	push   %eax
  800cd4:	6a 06                	push   $0x6
  800cd6:	68 68 17 80 00       	push   $0x801768
  800cdb:	6a 23                	push   $0x23
  800cdd:	68 85 17 80 00       	push   $0x801785
  800ce2:	e8 61 f4 ff ff       	call   800148 <_panic>

int
sys_page_unmap(envid_t envid, void *va)
{
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
}
  800ce7:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800cea:	5b                   	pop    %ebx
  800ceb:	5e                   	pop    %esi
  800cec:	5f                   	pop    %edi
  800ced:	5d                   	pop    %ebp
  800cee:	c3                   	ret    

00800cef <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  800cef:	55                   	push   %ebp
  800cf0:	89 e5                	mov    %esp,%ebp
  800cf2:	57                   	push   %edi
  800cf3:	56                   	push   %esi
  800cf4:	53                   	push   %ebx
  800cf5:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800cf8:	bb 00 00 00 00       	mov    $0x0,%ebx
  800cfd:	b8 08 00 00 00       	mov    $0x8,%eax
  800d02:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800d05:	8b 55 08             	mov    0x8(%ebp),%edx
  800d08:	89 df                	mov    %ebx,%edi
  800d0a:	89 de                	mov    %ebx,%esi
  800d0c:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800d0e:	85 c0                	test   %eax,%eax
  800d10:	7e 17                	jle    800d29 <sys_env_set_status+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800d12:	83 ec 0c             	sub    $0xc,%esp
  800d15:	50                   	push   %eax
  800d16:	6a 08                	push   $0x8
  800d18:	68 68 17 80 00       	push   $0x801768
  800d1d:	6a 23                	push   $0x23
  800d1f:	68 85 17 80 00       	push   $0x801785
  800d24:	e8 1f f4 ff ff       	call   800148 <_panic>

int
sys_env_set_status(envid_t envid, int status)
{
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
}
  800d29:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800d2c:	5b                   	pop    %ebx
  800d2d:	5e                   	pop    %esi
  800d2e:	5f                   	pop    %edi
  800d2f:	5d                   	pop    %ebp
  800d30:	c3                   	ret    

00800d31 <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  800d31:	55                   	push   %ebp
  800d32:	89 e5                	mov    %esp,%ebp
  800d34:	57                   	push   %edi
  800d35:	56                   	push   %esi
  800d36:	53                   	push   %ebx
  800d37:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d3a:	bb 00 00 00 00       	mov    $0x0,%ebx
  800d3f:	b8 09 00 00 00       	mov    $0x9,%eax
  800d44:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800d47:	8b 55 08             	mov    0x8(%ebp),%edx
  800d4a:	89 df                	mov    %ebx,%edi
  800d4c:	89 de                	mov    %ebx,%esi
  800d4e:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800d50:	85 c0                	test   %eax,%eax
  800d52:	7e 17                	jle    800d6b <sys_env_set_pgfault_upcall+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800d54:	83 ec 0c             	sub    $0xc,%esp
  800d57:	50                   	push   %eax
  800d58:	6a 09                	push   $0x9
  800d5a:	68 68 17 80 00       	push   $0x801768
  800d5f:	6a 23                	push   $0x23
  800d61:	68 85 17 80 00       	push   $0x801785
  800d66:	e8 dd f3 ff ff       	call   800148 <_panic>

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
}
  800d6b:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800d6e:	5b                   	pop    %ebx
  800d6f:	5e                   	pop    %esi
  800d70:	5f                   	pop    %edi
  800d71:	5d                   	pop    %ebp
  800d72:	c3                   	ret    

00800d73 <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  800d73:	55                   	push   %ebp
  800d74:	89 e5                	mov    %esp,%ebp
  800d76:	57                   	push   %edi
  800d77:	56                   	push   %esi
  800d78:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d79:	be 00 00 00 00       	mov    $0x0,%esi
  800d7e:	b8 0b 00 00 00       	mov    $0xb,%eax
  800d83:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800d86:	8b 55 08             	mov    0x8(%ebp),%edx
  800d89:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800d8c:	8b 7d 14             	mov    0x14(%ebp),%edi
  800d8f:	cd 30                	int    $0x30

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
}
  800d91:	5b                   	pop    %ebx
  800d92:	5e                   	pop    %esi
  800d93:	5f                   	pop    %edi
  800d94:	5d                   	pop    %ebp
  800d95:	c3                   	ret    

00800d96 <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  800d96:	55                   	push   %ebp
  800d97:	89 e5                	mov    %esp,%ebp
  800d99:	57                   	push   %edi
  800d9a:	56                   	push   %esi
  800d9b:	53                   	push   %ebx
  800d9c:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d9f:	b9 00 00 00 00       	mov    $0x0,%ecx
  800da4:	b8 0c 00 00 00       	mov    $0xc,%eax
  800da9:	8b 55 08             	mov    0x8(%ebp),%edx
  800dac:	89 cb                	mov    %ecx,%ebx
  800dae:	89 cf                	mov    %ecx,%edi
  800db0:	89 ce                	mov    %ecx,%esi
  800db2:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800db4:	85 c0                	test   %eax,%eax
  800db6:	7e 17                	jle    800dcf <sys_ipc_recv+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800db8:	83 ec 0c             	sub    $0xc,%esp
  800dbb:	50                   	push   %eax
  800dbc:	6a 0c                	push   $0xc
  800dbe:	68 68 17 80 00       	push   $0x801768
  800dc3:	6a 23                	push   $0x23
  800dc5:	68 85 17 80 00       	push   $0x801785
  800dca:	e8 79 f3 ff ff       	call   800148 <_panic>

int
sys_ipc_recv(void *dstva)
{
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
}
  800dcf:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800dd2:	5b                   	pop    %ebx
  800dd3:	5e                   	pop    %esi
  800dd4:	5f                   	pop    %edi
  800dd5:	5d                   	pop    %ebp
  800dd6:	c3                   	ret    

00800dd7 <pgfault>:
// Custom page fault handler - if faulting page is copy-on-write,
// map in our own private writable copy.
//
static void
pgfault(struct UTrapframe *utf)
{
  800dd7:	55                   	push   %ebp
  800dd8:	89 e5                	mov    %esp,%ebp
  800dda:	53                   	push   %ebx
  800ddb:	83 ec 04             	sub    $0x4,%esp
  800dde:	8b 55 08             	mov    0x8(%ebp),%edx
	void *addr = (void *) utf->utf_fault_va;
  800de1:	8b 02                	mov    (%edx),%eax
	// Hint:
	//   Use the read-only page table mappings at uvpt
	//   (see <inc/memlayout.h>).

	// LAB 4: Your code here.
	if ((err & FEC_WR) == 0||(uvpd[PDX(addr)] & PTE_P) == 0 ||
  800de3:	f6 42 04 02          	testb  $0x2,0x4(%edx)
  800de7:	74 27                	je     800e10 <pgfault+0x39>
  800de9:	89 c2                	mov    %eax,%edx
  800deb:	c1 ea 16             	shr    $0x16,%edx
  800dee:	8b 14 95 00 d0 7b ef 	mov    -0x10843000(,%edx,4),%edx
  800df5:	f6 c2 01             	test   $0x1,%dl
  800df8:	74 16                	je     800e10 <pgfault+0x39>
		(~uvpt[PGNUM(addr)] & (PTE_COW|PTE_P)) != 0)
  800dfa:	89 c2                	mov    %eax,%edx
  800dfc:	c1 ea 0c             	shr    $0xc,%edx
  800dff:	8b 14 95 00 00 40 ef 	mov    -0x10c00000(,%edx,4),%edx
	// Hint:
	//   Use the read-only page table mappings at uvpt
	//   (see <inc/memlayout.h>).

	// LAB 4: Your code here.
	if ((err & FEC_WR) == 0||(uvpd[PDX(addr)] & PTE_P) == 0 ||
  800e06:	f7 d2                	not    %edx
  800e08:	f7 c2 01 08 00 00    	test   $0x801,%edx
  800e0e:	74 14                	je     800e24 <pgfault+0x4d>
		(~uvpt[PGNUM(addr)] & (PTE_COW|PTE_P)) != 0)
	{
		panic("not copy-on-write");
  800e10:	83 ec 04             	sub    $0x4,%esp
  800e13:	68 93 17 80 00       	push   $0x801793
  800e18:	6a 1f                	push   $0x1f
  800e1a:	68 a5 17 80 00       	push   $0x8017a5
  800e1f:	e8 24 f3 ff ff       	call   800148 <_panic>
	// page to the old page's address.
	// Hint:
	//   You should make three system calls.

	// LAB 4: Your code here.
	addr = ROUNDDOWN(addr, PGSIZE);
  800e24:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  800e29:	89 c3                	mov    %eax,%ebx
	if (sys_page_alloc(0, PFTEMP, PTE_W|PTE_U|PTE_P) < 0)
  800e2b:	83 ec 04             	sub    $0x4,%esp
  800e2e:	6a 07                	push   $0x7
  800e30:	68 00 f0 7f 00       	push   $0x7ff000
  800e35:	6a 00                	push   $0x0
  800e37:	e8 ec fd ff ff       	call   800c28 <sys_page_alloc>
  800e3c:	83 c4 10             	add    $0x10,%esp
  800e3f:	85 c0                	test   %eax,%eax
  800e41:	79 14                	jns    800e57 <pgfault+0x80>
	{
		panic("sys_page_alloc failed");
  800e43:	83 ec 04             	sub    $0x4,%esp
  800e46:	68 b0 17 80 00       	push   $0x8017b0
  800e4b:	6a 2b                	push   $0x2b
  800e4d:	68 a5 17 80 00       	push   $0x8017a5
  800e52:	e8 f1 f2 ff ff       	call   800148 <_panic>
	}
	memcpy(PFTEMP, addr, PGSIZE);
  800e57:	83 ec 04             	sub    $0x4,%esp
  800e5a:	68 00 10 00 00       	push   $0x1000
  800e5f:	53                   	push   %ebx
  800e60:	68 00 f0 7f 00       	push   $0x7ff000
  800e65:	e8 b5 fb ff ff       	call   800a1f <memcpy>
	if (sys_page_map(0, PFTEMP, 0, addr, PTE_W|PTE_U|PTE_P) < 0)
  800e6a:	c7 04 24 07 00 00 00 	movl   $0x7,(%esp)
  800e71:	53                   	push   %ebx
  800e72:	6a 00                	push   $0x0
  800e74:	68 00 f0 7f 00       	push   $0x7ff000
  800e79:	6a 00                	push   $0x0
  800e7b:	e8 eb fd ff ff       	call   800c6b <sys_page_map>
  800e80:	83 c4 20             	add    $0x20,%esp
  800e83:	85 c0                	test   %eax,%eax
  800e85:	79 14                	jns    800e9b <pgfault+0xc4>
		panic("sys_page_map failed");
  800e87:	83 ec 04             	sub    $0x4,%esp
  800e8a:	68 c6 17 80 00       	push   $0x8017c6
  800e8f:	6a 2f                	push   $0x2f
  800e91:	68 a5 17 80 00       	push   $0x8017a5
  800e96:	e8 ad f2 ff ff       	call   800148 <_panic>
	if (sys_page_unmap(0, PFTEMP) < 0)
  800e9b:	83 ec 08             	sub    $0x8,%esp
  800e9e:	68 00 f0 7f 00       	push   $0x7ff000
  800ea3:	6a 00                	push   $0x0
  800ea5:	e8 03 fe ff ff       	call   800cad <sys_page_unmap>
  800eaa:	83 c4 10             	add    $0x10,%esp
  800ead:	85 c0                	test   %eax,%eax
  800eaf:	79 14                	jns    800ec5 <pgfault+0xee>
		panic("sys_page_unmap failed");
  800eb1:	83 ec 04             	sub    $0x4,%esp
  800eb4:	68 da 17 80 00       	push   $0x8017da
  800eb9:	6a 31                	push   $0x31
  800ebb:	68 a5 17 80 00       	push   $0x8017a5
  800ec0:	e8 83 f2 ff ff       	call   800148 <_panic>
	return;
	//panic("pgfault not implemented");
}
  800ec5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800ec8:	c9                   	leave  
  800ec9:	c3                   	ret    

00800eca <fork>:
//   Neither user exception stack should ever be marked copy-on-write,
//   so you must allocate a new page for the child's user exception stack.
//
envid_t
fork(void)
{
  800eca:	55                   	push   %ebp
  800ecb:	89 e5                	mov    %esp,%ebp
  800ecd:	57                   	push   %edi
  800ece:	56                   	push   %esi
  800ecf:	53                   	push   %ebx
  800ed0:	83 ec 28             	sub    $0x28,%esp
	// LAB 4: Your code here.
	set_pgfault_handler(pgfault); 
  800ed3:	68 d7 0d 80 00       	push   $0x800dd7
  800ed8:	e8 be 02 00 00       	call   80119b <set_pgfault_handler>
// This must be inlined.  Exercise for reader: why?
static __inline envid_t __attribute__((always_inline))
sys_exofork(void)
{
	envid_t ret;
	__asm __volatile("int %2"
  800edd:	b8 07 00 00 00       	mov    $0x7,%eax
  800ee2:	cd 30                	int    $0x30
  800ee4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	envid_t envid = sys_exofork(); 
	uint32_t addr;
	if(envid < 0)
  800ee7:	83 c4 10             	add    $0x10,%esp
  800eea:	85 c0                	test   %eax,%eax
  800eec:	79 14                	jns    800f02 <fork+0x38>
	{ 
		panic("sys_exofork failed");
  800eee:	83 ec 04             	sub    $0x4,%esp
  800ef1:	68 f0 17 80 00       	push   $0x8017f0
  800ef6:	6a 77                	push   $0x77
  800ef8:	68 a5 17 80 00       	push   $0x8017a5
  800efd:	e8 46 f2 ff ff       	call   800148 <_panic>
  800f02:	89 c7                	mov    %eax,%edi
  800f04:	bb 00 00 00 00       	mov    $0x0,%ebx
	}
	else if(envid == 0)
  800f09:	85 c0                	test   %eax,%eax
  800f0b:	75 1c                	jne    800f29 <fork+0x5f>
	{ 
		thisenv = &envs[ENVX(sys_getenvid())];
  800f0d:	e8 d8 fc ff ff       	call   800bea <sys_getenvid>
  800f12:	25 ff 03 00 00       	and    $0x3ff,%eax
  800f17:	6b c0 7c             	imul   $0x7c,%eax,%eax
  800f1a:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  800f1f:	a3 04 20 80 00       	mov    %eax,0x802004
		return envid;
  800f24:	e9 56 01 00 00       	jmp    80107f <fork+0x1b5>
	}
	for(addr = 0;addr < USTACKTOP;addr += PGSIZE)
	{
		if ((uvpd[PDX(addr)] & PTE_P) && (uvpt[PGNUM(addr)] & PTE_P)
  800f29:	89 d8                	mov    %ebx,%eax
  800f2b:	c1 e8 16             	shr    $0x16,%eax
  800f2e:	8b 04 85 00 d0 7b ef 	mov    -0x10843000(,%eax,4),%eax
  800f35:	a8 01                	test   $0x1,%al
  800f37:	0f 84 cb 00 00 00    	je     801008 <fork+0x13e>
  800f3d:	89 d8                	mov    %ebx,%eax
  800f3f:	c1 e8 0c             	shr    $0xc,%eax
  800f42:	8b 14 85 00 00 40 ef 	mov    -0x10c00000(,%eax,4),%edx
  800f49:	f6 c2 01             	test   $0x1,%dl
  800f4c:	0f 84 b6 00 00 00    	je     801008 <fork+0x13e>
			&& (uvpt[PGNUM(addr)] & PTE_U)) 
  800f52:	8b 14 85 00 00 40 ef 	mov    -0x10c00000(,%eax,4),%edx
  800f59:	f6 c2 04             	test   $0x4,%dl
  800f5c:	0f 84 a6 00 00 00    	je     801008 <fork+0x13e>
duppage(envid_t envid, unsigned pn)
{
	int r;

	// LAB 4: Your code here.
	void *addr = (void*)(pn * PGSIZE);
  800f62:	89 c6                	mov    %eax,%esi
  800f64:	c1 e6 0c             	shl    $0xc,%esi
	if ((uvpt[pn] & PTE_W) || (uvpt[pn] & PTE_COW)) 
  800f67:	8b 14 85 00 00 40 ef 	mov    -0x10c00000(,%eax,4),%edx
  800f6e:	f6 c2 02             	test   $0x2,%dl
  800f71:	75 0c                	jne    800f7f <fork+0xb5>
  800f73:	8b 04 85 00 00 40 ef 	mov    -0x10c00000(,%eax,4),%eax
  800f7a:	f6 c4 08             	test   $0x8,%ah
  800f7d:	74 5d                	je     800fdc <fork+0x112>
	{ 
		if (sys_page_map(0, addr, envid, addr, PTE_COW|PTE_U|PTE_P) < 0)
  800f7f:	83 ec 0c             	sub    $0xc,%esp
  800f82:	68 05 08 00 00       	push   $0x805
  800f87:	56                   	push   %esi
  800f88:	ff 75 e4             	pushl  -0x1c(%ebp)
  800f8b:	56                   	push   %esi
  800f8c:	6a 00                	push   $0x0
  800f8e:	e8 d8 fc ff ff       	call   800c6b <sys_page_map>
  800f93:	83 c4 20             	add    $0x20,%esp
  800f96:	85 c0                	test   %eax,%eax
  800f98:	79 14                	jns    800fae <fork+0xe4>
		{ 
			panic("sys_page_map envid failed");
  800f9a:	83 ec 04             	sub    $0x4,%esp
  800f9d:	68 03 18 80 00       	push   $0x801803
  800fa2:	6a 4c                	push   $0x4c
  800fa4:	68 a5 17 80 00       	push   $0x8017a5
  800fa9:	e8 9a f1 ff ff       	call   800148 <_panic>
		}
		if (sys_page_map(0, addr, 0, addr, PTE_COW|PTE_U|PTE_P) < 0)
  800fae:	83 ec 0c             	sub    $0xc,%esp
  800fb1:	68 05 08 00 00       	push   $0x805
  800fb6:	56                   	push   %esi
  800fb7:	6a 00                	push   $0x0
  800fb9:	56                   	push   %esi
  800fba:	6a 00                	push   $0x0
  800fbc:	e8 aa fc ff ff       	call   800c6b <sys_page_map>
  800fc1:	83 c4 20             	add    $0x20,%esp
  800fc4:	85 c0                	test   %eax,%eax
  800fc6:	79 40                	jns    801008 <fork+0x13e>
		{ 
			panic("sys_page_map 0 failed");
  800fc8:	83 ec 04             	sub    $0x4,%esp
  800fcb:	68 1d 18 80 00       	push   $0x80181d
  800fd0:	6a 50                	push   $0x50
  800fd2:	68 a5 17 80 00       	push   $0x8017a5
  800fd7:	e8 6c f1 ff ff       	call   800148 <_panic>
		}
	} 
	else 
	{ 
		if(sys_page_map(0, addr, envid, addr, PTE_U|PTE_P) < 0)
  800fdc:	83 ec 0c             	sub    $0xc,%esp
  800fdf:	6a 05                	push   $0x5
  800fe1:	56                   	push   %esi
  800fe2:	ff 75 e4             	pushl  -0x1c(%ebp)
  800fe5:	56                   	push   %esi
  800fe6:	6a 00                	push   $0x0
  800fe8:	e8 7e fc ff ff       	call   800c6b <sys_page_map>
  800fed:	83 c4 20             	add    $0x20,%esp
  800ff0:	85 c0                	test   %eax,%eax
  800ff2:	79 14                	jns    801008 <fork+0x13e>
		{
			panic("sys_page_map envid failed");
  800ff4:	83 ec 04             	sub    $0x4,%esp
  800ff7:	68 03 18 80 00       	push   $0x801803
  800ffc:	6a 57                	push   $0x57
  800ffe:	68 a5 17 80 00       	push   $0x8017a5
  801003:	e8 40 f1 ff ff       	call   800148 <_panic>
	else if(envid == 0)
	{ 
		thisenv = &envs[ENVX(sys_getenvid())];
		return envid;
	}
	for(addr = 0;addr < USTACKTOP;addr += PGSIZE)
  801008:	81 c3 00 10 00 00    	add    $0x1000,%ebx
  80100e:	81 fb 00 e0 bf ee    	cmp    $0xeebfe000,%ebx
  801014:	0f 85 0f ff ff ff    	jne    800f29 <fork+0x5f>
			&& (uvpt[PGNUM(addr)] & PTE_U)) 
		{
			duppage(envid, PGNUM(addr));
		}
	}
	if (sys_page_alloc(envid, (void *)(UXSTACKTOP-PGSIZE), PTE_U|PTE_W|PTE_P) < 0)
  80101a:	83 ec 04             	sub    $0x4,%esp
  80101d:	6a 07                	push   $0x7
  80101f:	68 00 f0 bf ee       	push   $0xeebff000
  801024:	57                   	push   %edi
  801025:	e8 fe fb ff ff       	call   800c28 <sys_page_alloc>
  80102a:	83 c4 10             	add    $0x10,%esp
  80102d:	85 c0                	test   %eax,%eax
  80102f:	79 17                	jns    801048 <fork+0x17e>
	{
		panic("sys_page_alloc failed");
  801031:	83 ec 04             	sub    $0x4,%esp
  801034:	68 b0 17 80 00       	push   $0x8017b0
  801039:	68 88 00 00 00       	push   $0x88
  80103e:	68 a5 17 80 00       	push   $0x8017a5
  801043:	e8 00 f1 ff ff       	call   800148 <_panic>
	}
	extern void _pgfault_upcall();
	sys_env_set_pgfault_upcall(envid, _pgfault_upcall);
  801048:	83 ec 08             	sub    $0x8,%esp
  80104b:	68 0a 12 80 00       	push   $0x80120a
  801050:	57                   	push   %edi
  801051:	e8 db fc ff ff       	call   800d31 <sys_env_set_pgfault_upcall>
	if (sys_env_set_status(envid, ENV_RUNNABLE) < 0)
  801056:	83 c4 08             	add    $0x8,%esp
  801059:	6a 02                	push   $0x2
  80105b:	57                   	push   %edi
  80105c:	e8 8e fc ff ff       	call   800cef <sys_env_set_status>
  801061:	83 c4 10             	add    $0x10,%esp
  801064:	85 c0                	test   %eax,%eax
  801066:	79 17                	jns    80107f <fork+0x1b5>
	{
		panic("sys_env_set_status failed");
  801068:	83 ec 04             	sub    $0x4,%esp
  80106b:	68 33 18 80 00       	push   $0x801833
  801070:	68 8e 00 00 00       	push   $0x8e
  801075:	68 a5 17 80 00       	push   $0x8017a5
  80107a:	e8 c9 f0 ff ff       	call   800148 <_panic>
	}
	return envid;
	//panic("fork not implemented");
}
  80107f:	89 f8                	mov    %edi,%eax
  801081:	8d 65 f4             	lea    -0xc(%ebp),%esp
  801084:	5b                   	pop    %ebx
  801085:	5e                   	pop    %esi
  801086:	5f                   	pop    %edi
  801087:	5d                   	pop    %ebp
  801088:	c3                   	ret    

00801089 <sfork>:

// Challenge!
int
sfork(void)
{
  801089:	55                   	push   %ebp
  80108a:	89 e5                	mov    %esp,%ebp
  80108c:	83 ec 0c             	sub    $0xc,%esp
	panic("sfork not implemented");
  80108f:	68 4d 18 80 00       	push   $0x80184d
  801094:	68 98 00 00 00       	push   $0x98
  801099:	68 a5 17 80 00       	push   $0x8017a5
  80109e:	e8 a5 f0 ff ff       	call   800148 <_panic>

008010a3 <ipc_recv>:
//   If 'pg' is null, pass sys_ipc_recv a value that it will understand
//   as meaning "no page".  (Zero is not the right value, since that's
//   a perfectly valid place to map a page.)
int32_t
ipc_recv(envid_t *from_env_store, void *pg, int *perm_store)
{
  8010a3:	55                   	push   %ebp
  8010a4:	89 e5                	mov    %esp,%ebp
  8010a6:	56                   	push   %esi
  8010a7:	53                   	push   %ebx
  8010a8:	8b 75 08             	mov    0x8(%ebp),%esi
  8010ab:	8b 45 0c             	mov    0xc(%ebp),%eax
  8010ae:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// LAB 4: Your code here.
	if (pg == NULL) 
  8010b1:	85 c0                	test   %eax,%eax
	{
		pg = (void*)-1;
  8010b3:	ba ff ff ff ff       	mov    $0xffffffff,%edx
  8010b8:	0f 44 c2             	cmove  %edx,%eax
	}
	int flag = sys_ipc_recv(pg);
  8010bb:	83 ec 0c             	sub    $0xc,%esp
  8010be:	50                   	push   %eax
  8010bf:	e8 d2 fc ff ff       	call   800d96 <sys_ipc_recv>
	if (flag < 0)
  8010c4:	83 c4 10             	add    $0x10,%esp
  8010c7:	85 c0                	test   %eax,%eax
  8010c9:	79 16                	jns    8010e1 <ipc_recv+0x3e>
	{
		if (from_env_store != NULL) 
  8010cb:	85 f6                	test   %esi,%esi
  8010cd:	74 06                	je     8010d5 <ipc_recv+0x32>
		{
			*from_env_store = 0;
  8010cf:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
		}
		if (perm_store != NULL)
  8010d5:	85 db                	test   %ebx,%ebx
  8010d7:	74 2c                	je     801105 <ipc_recv+0x62>
		{
			*perm_store = 0;
  8010d9:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8010df:	eb 24                	jmp    801105 <ipc_recv+0x62>
		}
		return flag;
	}
	if (from_env_store != NULL)
  8010e1:	85 f6                	test   %esi,%esi
  8010e3:	74 0a                	je     8010ef <ipc_recv+0x4c>
	{
		//cprintf("sender:%08x\n",thisenv->env_ipc_from);
		*from_env_store = thisenv->env_ipc_from;
  8010e5:	a1 04 20 80 00       	mov    0x802004,%eax
  8010ea:	8b 40 74             	mov    0x74(%eax),%eax
  8010ed:	89 06                	mov    %eax,(%esi)
	}
	if (perm_store != NULL) 
  8010ef:	85 db                	test   %ebx,%ebx
  8010f1:	74 0a                	je     8010fd <ipc_recv+0x5a>
	{
		*perm_store = thisenv->env_ipc_perm;
  8010f3:	a1 04 20 80 00       	mov    0x802004,%eax
  8010f8:	8b 40 78             	mov    0x78(%eax),%eax
  8010fb:	89 03                	mov    %eax,(%ebx)
	}
	return thisenv->env_ipc_value;
  8010fd:	a1 04 20 80 00       	mov    0x802004,%eax
  801102:	8b 40 70             	mov    0x70(%eax),%eax
	//panic("ipc_recv not implemented");
}
  801105:	8d 65 f8             	lea    -0x8(%ebp),%esp
  801108:	5b                   	pop    %ebx
  801109:	5e                   	pop    %esi
  80110a:	5d                   	pop    %ebp
  80110b:	c3                   	ret    

0080110c <ipc_send>:
//   Use sys_yield() to be CPU-friendly.
//   If 'pg' is null, pass sys_ipc_try_send a value that it will understand
//   as meaning "no page".  (Zero is not the right value.)
void
ipc_send(envid_t to_env, uint32_t val, void *pg, int perm)
{
  80110c:	55                   	push   %ebp
  80110d:	89 e5                	mov    %esp,%ebp
  80110f:	57                   	push   %edi
  801110:	56                   	push   %esi
  801111:	53                   	push   %ebx
  801112:	83 ec 0c             	sub    $0xc,%esp
  801115:	8b 7d 08             	mov    0x8(%ebp),%edi
  801118:	8b 75 0c             	mov    0xc(%ebp),%esi
  80111b:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// LAB 4: Your code here.
	if(pg == NULL)
  80111e:	85 db                	test   %ebx,%ebx
	{
		pg = (void*)-1; 
  801120:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  801125:	0f 44 d8             	cmove  %eax,%ebx
	}
	int flag;
	while (true) 
	{ //cprintf("%x\n\n\n", -E_IPC_NOT_RECV);
		flag = sys_ipc_try_send(to_env, val, pg, perm);
  801128:	ff 75 14             	pushl  0x14(%ebp)
  80112b:	53                   	push   %ebx
  80112c:	56                   	push   %esi
  80112d:	57                   	push   %edi
  80112e:	e8 40 fc ff ff       	call   800d73 <sys_ipc_try_send>
		if (flag == 0) 
  801133:	83 c4 10             	add    $0x10,%esp
  801136:	85 c0                	test   %eax,%eax
  801138:	74 20                	je     80115a <ipc_send+0x4e>
		{ 
			//cprintf("%08x send %d to %08x\n",thisenv->env_id,val,to_env);
			break;
		}
		if (flag != -E_IPC_NOT_RECV)
  80113a:	83 f8 f8             	cmp    $0xfffffff8,%eax
  80113d:	74 14                	je     801153 <ipc_send+0x47>
		{
			panic("ipc_send failed");
  80113f:	83 ec 04             	sub    $0x4,%esp
  801142:	68 63 18 80 00       	push   $0x801863
  801147:	6a 53                	push   $0x53
  801149:	68 73 18 80 00       	push   $0x801873
  80114e:	e8 f5 ef ff ff       	call   800148 <_panic>
		}
		sys_yield();
  801153:	e8 b1 fa ff ff       	call   800c09 <sys_yield>
	}
  801158:	eb ce                	jmp    801128 <ipc_send+0x1c>
	//panic("ipc_send not implemented");
}
  80115a:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80115d:	5b                   	pop    %ebx
  80115e:	5e                   	pop    %esi
  80115f:	5f                   	pop    %edi
  801160:	5d                   	pop    %ebp
  801161:	c3                   	ret    

00801162 <ipc_find_env>:
// Find the first environment of the given type.  We'll use this to
// find special environments.
// Returns 0 if no such environment exists.
envid_t
ipc_find_env(enum EnvType type)
{
  801162:	55                   	push   %ebp
  801163:	89 e5                	mov    %esp,%ebp
  801165:	8b 4d 08             	mov    0x8(%ebp),%ecx
	int i;
	for (i = 0; i < NENV; i++)
  801168:	b8 00 00 00 00       	mov    $0x0,%eax
		if (envs[i].env_type == type)
  80116d:	6b d0 7c             	imul   $0x7c,%eax,%edx
  801170:	81 c2 00 00 c0 ee    	add    $0xeec00000,%edx
  801176:	8b 52 50             	mov    0x50(%edx),%edx
  801179:	39 ca                	cmp    %ecx,%edx
  80117b:	75 0d                	jne    80118a <ipc_find_env+0x28>
			return envs[i].env_id;
  80117d:	6b c0 7c             	imul   $0x7c,%eax,%eax
  801180:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  801185:	8b 40 48             	mov    0x48(%eax),%eax
  801188:	eb 0f                	jmp    801199 <ipc_find_env+0x37>
// Returns 0 if no such environment exists.
envid_t
ipc_find_env(enum EnvType type)
{
	int i;
	for (i = 0; i < NENV; i++)
  80118a:	83 c0 01             	add    $0x1,%eax
  80118d:	3d 00 04 00 00       	cmp    $0x400,%eax
  801192:	75 d9                	jne    80116d <ipc_find_env+0xb>
		if (envs[i].env_type == type)
			return envs[i].env_id;
	return 0;
  801194:	b8 00 00 00 00       	mov    $0x0,%eax
}
  801199:	5d                   	pop    %ebp
  80119a:	c3                   	ret    

0080119b <set_pgfault_handler>:
// at UXSTACKTOP), and tell the kernel to call the assembly-language
// _pgfault_upcall routine when a page fault occurs.
//
void
set_pgfault_handler(void (*handler)(struct UTrapframe *utf))
{
  80119b:	55                   	push   %ebp
  80119c:	89 e5                	mov    %esp,%ebp
  80119e:	83 ec 08             	sub    $0x8,%esp
	int r;

	if (_pgfault_handler == 0) {
  8011a1:	83 3d 08 20 80 00 00 	cmpl   $0x0,0x802008
  8011a8:	75 56                	jne    801200 <set_pgfault_handler+0x65>
		// First time through!
		// LAB 4: Your code here.
		r = sys_page_alloc(0, (void*)UXSTACKTOP-PGSIZE, PTE_U|PTE_W|PTE_P);
  8011aa:	83 ec 04             	sub    $0x4,%esp
  8011ad:	6a 07                	push   $0x7
  8011af:	68 00 f0 bf ee       	push   $0xeebff000
  8011b4:	6a 00                	push   $0x0
  8011b6:	e8 6d fa ff ff       	call   800c28 <sys_page_alloc>
		//cprintf("%x", r);
		if(r != 0)
  8011bb:	83 c4 10             	add    $0x10,%esp
  8011be:	85 c0                	test   %eax,%eax
  8011c0:	74 14                	je     8011d6 <set_pgfault_handler+0x3b>
		{
			panic("sys_page_alloc failed");
  8011c2:	83 ec 04             	sub    $0x4,%esp
  8011c5:	68 b0 17 80 00       	push   $0x8017b0
  8011ca:	6a 24                	push   $0x24
  8011cc:	68 7d 18 80 00       	push   $0x80187d
  8011d1:	e8 72 ef ff ff       	call   800148 <_panic>
		}
		r = sys_env_set_pgfault_upcall(0, (void*)_pgfault_upcall); 
  8011d6:	83 ec 08             	sub    $0x8,%esp
  8011d9:	68 0a 12 80 00       	push   $0x80120a
  8011de:	6a 00                	push   $0x0
  8011e0:	e8 4c fb ff ff       	call   800d31 <sys_env_set_pgfault_upcall>
		//cprintf("%x\n", _pgfault_upcall);//fixed bug:_pgfault_upcall-->_pgfault_handler
		if(r != 0)
  8011e5:	83 c4 10             	add    $0x10,%esp
  8011e8:	85 c0                	test   %eax,%eax
  8011ea:	74 14                	je     801200 <set_pgfault_handler+0x65>
		{
			panic("sys_env_set_pgfault_upcall failed");
  8011ec:	83 ec 04             	sub    $0x4,%esp
  8011ef:	68 8c 18 80 00       	push   $0x80188c
  8011f4:	6a 2a                	push   $0x2a
  8011f6:	68 7d 18 80 00       	push   $0x80187d
  8011fb:	e8 48 ef ff ff       	call   800148 <_panic>
		}
		//panic("set_pgfault_handler not implemented");
	}

	// Save handler pointer for assembly to call.
	_pgfault_handler = handler;
  801200:	8b 45 08             	mov    0x8(%ebp),%eax
  801203:	a3 08 20 80 00       	mov    %eax,0x802008
}
  801208:	c9                   	leave  
  801209:	c3                   	ret    

0080120a <_pgfault_upcall>:

.text
.globl _pgfault_upcall
_pgfault_upcall:
	// Call the C page fault handler.
	pushl %esp			// function argument: pointer to UTF
  80120a:	54                   	push   %esp
	movl _pgfault_handler, %eax
  80120b:	a1 08 20 80 00       	mov    0x802008,%eax
	call *%eax
  801210:	ff d0                	call   *%eax
	addl $4, %esp			// pop function argument
  801212:	83 c4 04             	add    $0x4,%esp
	// registers are available for intermediate calculations.  You
	// may find that you have to rearrange your code in non-obvious
	// ways as registers become unavailable as scratch space.
	//
	// LAB 4: Your code here.
	movl 0x28(%esp), %eax
  801215:	8b 44 24 28          	mov    0x28(%esp),%eax
    	subl $0x4, 0x30(%esp)
  801219:	83 6c 24 30 04       	subl   $0x4,0x30(%esp)
   	movl 0x30(%esp), %ebp
  80121e:	8b 6c 24 30          	mov    0x30(%esp),%ebp
    	movl %eax, (%ebp)
  801222:	89 45 00             	mov    %eax,0x0(%ebp)
    	// pop fault_va, err
    	popl %eax
  801225:	58                   	pop    %eax
    	popl %eax
  801226:	58                   	pop    %eax
	// Restore the trap-time registers.  After you do this, you
	// can no longer modify any general-purpose registers.
	// LAB 4: Your code here.
	popal
  801227:	61                   	popa   
	// Restore eflags from the stack.  After you do this, you can
	// no longer use arithmetic operations or anything else that
	// modifies eflags.
	// LAB 4: Your code here.
	addl $0x4, %esp
  801228:	83 c4 04             	add    $0x4,%esp
	popfl
  80122b:	9d                   	popf   
	// Switch back to the adjusted trap-time stack.
	// LAB 4: Your code here.
	popl %esp
  80122c:	5c                   	pop    %esp
	// Return to re-execute the instruction that faulted.
	// LAB 4: Your code here.
	ret
  80122d:	c3                   	ret    
  80122e:	66 90                	xchg   %ax,%ax

00801230 <__udivdi3>:
  801230:	55                   	push   %ebp
  801231:	57                   	push   %edi
  801232:	56                   	push   %esi
  801233:	53                   	push   %ebx
  801234:	83 ec 1c             	sub    $0x1c,%esp
  801237:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  80123b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  80123f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  801243:	8b 7c 24 38          	mov    0x38(%esp),%edi
  801247:	85 f6                	test   %esi,%esi
  801249:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  80124d:	89 ca                	mov    %ecx,%edx
  80124f:	89 f8                	mov    %edi,%eax
  801251:	75 3d                	jne    801290 <__udivdi3+0x60>
  801253:	39 cf                	cmp    %ecx,%edi
  801255:	0f 87 c5 00 00 00    	ja     801320 <__udivdi3+0xf0>
  80125b:	85 ff                	test   %edi,%edi
  80125d:	89 fd                	mov    %edi,%ebp
  80125f:	75 0b                	jne    80126c <__udivdi3+0x3c>
  801261:	b8 01 00 00 00       	mov    $0x1,%eax
  801266:	31 d2                	xor    %edx,%edx
  801268:	f7 f7                	div    %edi
  80126a:	89 c5                	mov    %eax,%ebp
  80126c:	89 c8                	mov    %ecx,%eax
  80126e:	31 d2                	xor    %edx,%edx
  801270:	f7 f5                	div    %ebp
  801272:	89 c1                	mov    %eax,%ecx
  801274:	89 d8                	mov    %ebx,%eax
  801276:	89 cf                	mov    %ecx,%edi
  801278:	f7 f5                	div    %ebp
  80127a:	89 c3                	mov    %eax,%ebx
  80127c:	89 d8                	mov    %ebx,%eax
  80127e:	89 fa                	mov    %edi,%edx
  801280:	83 c4 1c             	add    $0x1c,%esp
  801283:	5b                   	pop    %ebx
  801284:	5e                   	pop    %esi
  801285:	5f                   	pop    %edi
  801286:	5d                   	pop    %ebp
  801287:	c3                   	ret    
  801288:	90                   	nop
  801289:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  801290:	39 ce                	cmp    %ecx,%esi
  801292:	77 74                	ja     801308 <__udivdi3+0xd8>
  801294:	0f bd fe             	bsr    %esi,%edi
  801297:	83 f7 1f             	xor    $0x1f,%edi
  80129a:	0f 84 98 00 00 00    	je     801338 <__udivdi3+0x108>
  8012a0:	bb 20 00 00 00       	mov    $0x20,%ebx
  8012a5:	89 f9                	mov    %edi,%ecx
  8012a7:	89 c5                	mov    %eax,%ebp
  8012a9:	29 fb                	sub    %edi,%ebx
  8012ab:	d3 e6                	shl    %cl,%esi
  8012ad:	89 d9                	mov    %ebx,%ecx
  8012af:	d3 ed                	shr    %cl,%ebp
  8012b1:	89 f9                	mov    %edi,%ecx
  8012b3:	d3 e0                	shl    %cl,%eax
  8012b5:	09 ee                	or     %ebp,%esi
  8012b7:	89 d9                	mov    %ebx,%ecx
  8012b9:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8012bd:	89 d5                	mov    %edx,%ebp
  8012bf:	8b 44 24 08          	mov    0x8(%esp),%eax
  8012c3:	d3 ed                	shr    %cl,%ebp
  8012c5:	89 f9                	mov    %edi,%ecx
  8012c7:	d3 e2                	shl    %cl,%edx
  8012c9:	89 d9                	mov    %ebx,%ecx
  8012cb:	d3 e8                	shr    %cl,%eax
  8012cd:	09 c2                	or     %eax,%edx
  8012cf:	89 d0                	mov    %edx,%eax
  8012d1:	89 ea                	mov    %ebp,%edx
  8012d3:	f7 f6                	div    %esi
  8012d5:	89 d5                	mov    %edx,%ebp
  8012d7:	89 c3                	mov    %eax,%ebx
  8012d9:	f7 64 24 0c          	mull   0xc(%esp)
  8012dd:	39 d5                	cmp    %edx,%ebp
  8012df:	72 10                	jb     8012f1 <__udivdi3+0xc1>
  8012e1:	8b 74 24 08          	mov    0x8(%esp),%esi
  8012e5:	89 f9                	mov    %edi,%ecx
  8012e7:	d3 e6                	shl    %cl,%esi
  8012e9:	39 c6                	cmp    %eax,%esi
  8012eb:	73 07                	jae    8012f4 <__udivdi3+0xc4>
  8012ed:	39 d5                	cmp    %edx,%ebp
  8012ef:	75 03                	jne    8012f4 <__udivdi3+0xc4>
  8012f1:	83 eb 01             	sub    $0x1,%ebx
  8012f4:	31 ff                	xor    %edi,%edi
  8012f6:	89 d8                	mov    %ebx,%eax
  8012f8:	89 fa                	mov    %edi,%edx
  8012fa:	83 c4 1c             	add    $0x1c,%esp
  8012fd:	5b                   	pop    %ebx
  8012fe:	5e                   	pop    %esi
  8012ff:	5f                   	pop    %edi
  801300:	5d                   	pop    %ebp
  801301:	c3                   	ret    
  801302:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  801308:	31 ff                	xor    %edi,%edi
  80130a:	31 db                	xor    %ebx,%ebx
  80130c:	89 d8                	mov    %ebx,%eax
  80130e:	89 fa                	mov    %edi,%edx
  801310:	83 c4 1c             	add    $0x1c,%esp
  801313:	5b                   	pop    %ebx
  801314:	5e                   	pop    %esi
  801315:	5f                   	pop    %edi
  801316:	5d                   	pop    %ebp
  801317:	c3                   	ret    
  801318:	90                   	nop
  801319:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  801320:	89 d8                	mov    %ebx,%eax
  801322:	f7 f7                	div    %edi
  801324:	31 ff                	xor    %edi,%edi
  801326:	89 c3                	mov    %eax,%ebx
  801328:	89 d8                	mov    %ebx,%eax
  80132a:	89 fa                	mov    %edi,%edx
  80132c:	83 c4 1c             	add    $0x1c,%esp
  80132f:	5b                   	pop    %ebx
  801330:	5e                   	pop    %esi
  801331:	5f                   	pop    %edi
  801332:	5d                   	pop    %ebp
  801333:	c3                   	ret    
  801334:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801338:	39 ce                	cmp    %ecx,%esi
  80133a:	72 0c                	jb     801348 <__udivdi3+0x118>
  80133c:	31 db                	xor    %ebx,%ebx
  80133e:	3b 44 24 08          	cmp    0x8(%esp),%eax
  801342:	0f 87 34 ff ff ff    	ja     80127c <__udivdi3+0x4c>
  801348:	bb 01 00 00 00       	mov    $0x1,%ebx
  80134d:	e9 2a ff ff ff       	jmp    80127c <__udivdi3+0x4c>
  801352:	66 90                	xchg   %ax,%ax
  801354:	66 90                	xchg   %ax,%ax
  801356:	66 90                	xchg   %ax,%ax
  801358:	66 90                	xchg   %ax,%ax
  80135a:	66 90                	xchg   %ax,%ax
  80135c:	66 90                	xchg   %ax,%ax
  80135e:	66 90                	xchg   %ax,%ax

00801360 <__umoddi3>:
  801360:	55                   	push   %ebp
  801361:	57                   	push   %edi
  801362:	56                   	push   %esi
  801363:	53                   	push   %ebx
  801364:	83 ec 1c             	sub    $0x1c,%esp
  801367:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  80136b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  80136f:	8b 74 24 34          	mov    0x34(%esp),%esi
  801373:	8b 7c 24 38          	mov    0x38(%esp),%edi
  801377:	85 d2                	test   %edx,%edx
  801379:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  80137d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  801381:	89 f3                	mov    %esi,%ebx
  801383:	89 3c 24             	mov    %edi,(%esp)
  801386:	89 74 24 04          	mov    %esi,0x4(%esp)
  80138a:	75 1c                	jne    8013a8 <__umoddi3+0x48>
  80138c:	39 f7                	cmp    %esi,%edi
  80138e:	76 50                	jbe    8013e0 <__umoddi3+0x80>
  801390:	89 c8                	mov    %ecx,%eax
  801392:	89 f2                	mov    %esi,%edx
  801394:	f7 f7                	div    %edi
  801396:	89 d0                	mov    %edx,%eax
  801398:	31 d2                	xor    %edx,%edx
  80139a:	83 c4 1c             	add    $0x1c,%esp
  80139d:	5b                   	pop    %ebx
  80139e:	5e                   	pop    %esi
  80139f:	5f                   	pop    %edi
  8013a0:	5d                   	pop    %ebp
  8013a1:	c3                   	ret    
  8013a2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  8013a8:	39 f2                	cmp    %esi,%edx
  8013aa:	89 d0                	mov    %edx,%eax
  8013ac:	77 52                	ja     801400 <__umoddi3+0xa0>
  8013ae:	0f bd ea             	bsr    %edx,%ebp
  8013b1:	83 f5 1f             	xor    $0x1f,%ebp
  8013b4:	75 5a                	jne    801410 <__umoddi3+0xb0>
  8013b6:	3b 54 24 04          	cmp    0x4(%esp),%edx
  8013ba:	0f 82 e0 00 00 00    	jb     8014a0 <__umoddi3+0x140>
  8013c0:	39 0c 24             	cmp    %ecx,(%esp)
  8013c3:	0f 86 d7 00 00 00    	jbe    8014a0 <__umoddi3+0x140>
  8013c9:	8b 44 24 08          	mov    0x8(%esp),%eax
  8013cd:	8b 54 24 04          	mov    0x4(%esp),%edx
  8013d1:	83 c4 1c             	add    $0x1c,%esp
  8013d4:	5b                   	pop    %ebx
  8013d5:	5e                   	pop    %esi
  8013d6:	5f                   	pop    %edi
  8013d7:	5d                   	pop    %ebp
  8013d8:	c3                   	ret    
  8013d9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  8013e0:	85 ff                	test   %edi,%edi
  8013e2:	89 fd                	mov    %edi,%ebp
  8013e4:	75 0b                	jne    8013f1 <__umoddi3+0x91>
  8013e6:	b8 01 00 00 00       	mov    $0x1,%eax
  8013eb:	31 d2                	xor    %edx,%edx
  8013ed:	f7 f7                	div    %edi
  8013ef:	89 c5                	mov    %eax,%ebp
  8013f1:	89 f0                	mov    %esi,%eax
  8013f3:	31 d2                	xor    %edx,%edx
  8013f5:	f7 f5                	div    %ebp
  8013f7:	89 c8                	mov    %ecx,%eax
  8013f9:	f7 f5                	div    %ebp
  8013fb:	89 d0                	mov    %edx,%eax
  8013fd:	eb 99                	jmp    801398 <__umoddi3+0x38>
  8013ff:	90                   	nop
  801400:	89 c8                	mov    %ecx,%eax
  801402:	89 f2                	mov    %esi,%edx
  801404:	83 c4 1c             	add    $0x1c,%esp
  801407:	5b                   	pop    %ebx
  801408:	5e                   	pop    %esi
  801409:	5f                   	pop    %edi
  80140a:	5d                   	pop    %ebp
  80140b:	c3                   	ret    
  80140c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801410:	8b 34 24             	mov    (%esp),%esi
  801413:	bf 20 00 00 00       	mov    $0x20,%edi
  801418:	89 e9                	mov    %ebp,%ecx
  80141a:	29 ef                	sub    %ebp,%edi
  80141c:	d3 e0                	shl    %cl,%eax
  80141e:	89 f9                	mov    %edi,%ecx
  801420:	89 f2                	mov    %esi,%edx
  801422:	d3 ea                	shr    %cl,%edx
  801424:	89 e9                	mov    %ebp,%ecx
  801426:	09 c2                	or     %eax,%edx
  801428:	89 d8                	mov    %ebx,%eax
  80142a:	89 14 24             	mov    %edx,(%esp)
  80142d:	89 f2                	mov    %esi,%edx
  80142f:	d3 e2                	shl    %cl,%edx
  801431:	89 f9                	mov    %edi,%ecx
  801433:	89 54 24 04          	mov    %edx,0x4(%esp)
  801437:	8b 54 24 0c          	mov    0xc(%esp),%edx
  80143b:	d3 e8                	shr    %cl,%eax
  80143d:	89 e9                	mov    %ebp,%ecx
  80143f:	89 c6                	mov    %eax,%esi
  801441:	d3 e3                	shl    %cl,%ebx
  801443:	89 f9                	mov    %edi,%ecx
  801445:	89 d0                	mov    %edx,%eax
  801447:	d3 e8                	shr    %cl,%eax
  801449:	89 e9                	mov    %ebp,%ecx
  80144b:	09 d8                	or     %ebx,%eax
  80144d:	89 d3                	mov    %edx,%ebx
  80144f:	89 f2                	mov    %esi,%edx
  801451:	f7 34 24             	divl   (%esp)
  801454:	89 d6                	mov    %edx,%esi
  801456:	d3 e3                	shl    %cl,%ebx
  801458:	f7 64 24 04          	mull   0x4(%esp)
  80145c:	39 d6                	cmp    %edx,%esi
  80145e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  801462:	89 d1                	mov    %edx,%ecx
  801464:	89 c3                	mov    %eax,%ebx
  801466:	72 08                	jb     801470 <__umoddi3+0x110>
  801468:	75 11                	jne    80147b <__umoddi3+0x11b>
  80146a:	39 44 24 08          	cmp    %eax,0x8(%esp)
  80146e:	73 0b                	jae    80147b <__umoddi3+0x11b>
  801470:	2b 44 24 04          	sub    0x4(%esp),%eax
  801474:	1b 14 24             	sbb    (%esp),%edx
  801477:	89 d1                	mov    %edx,%ecx
  801479:	89 c3                	mov    %eax,%ebx
  80147b:	8b 54 24 08          	mov    0x8(%esp),%edx
  80147f:	29 da                	sub    %ebx,%edx
  801481:	19 ce                	sbb    %ecx,%esi
  801483:	89 f9                	mov    %edi,%ecx
  801485:	89 f0                	mov    %esi,%eax
  801487:	d3 e0                	shl    %cl,%eax
  801489:	89 e9                	mov    %ebp,%ecx
  80148b:	d3 ea                	shr    %cl,%edx
  80148d:	89 e9                	mov    %ebp,%ecx
  80148f:	d3 ee                	shr    %cl,%esi
  801491:	09 d0                	or     %edx,%eax
  801493:	89 f2                	mov    %esi,%edx
  801495:	83 c4 1c             	add    $0x1c,%esp
  801498:	5b                   	pop    %ebx
  801499:	5e                   	pop    %esi
  80149a:	5f                   	pop    %edi
  80149b:	5d                   	pop    %ebp
  80149c:	c3                   	ret    
  80149d:	8d 76 00             	lea    0x0(%esi),%esi
  8014a0:	29 f9                	sub    %edi,%ecx
  8014a2:	19 d6                	sbb    %edx,%esi
  8014a4:	89 74 24 04          	mov    %esi,0x4(%esp)
  8014a8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8014ac:	e9 18 ff ff ff       	jmp    8013c9 <__umoddi3+0x69>
