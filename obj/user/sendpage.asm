
obj/user/sendpage：     文件格式 elf32-i386


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
  80002c:	e8 68 01 00 00       	call   800199 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:
#define TEMP_ADDR	((char*)0xa00000)
#define TEMP_ADDR_CHILD	((char*)0xb00000)

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 18             	sub    $0x18,%esp
	envid_t who;

	if ((who = fork()) == 0) {
  800039:	e8 ef 0e 00 00       	call   800f2d <fork>
  80003e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  800041:	85 c0                	test   %eax,%eax
  800043:	0f 85 9f 00 00 00    	jne    8000e8 <umain+0xb5>
		// Child
		ipc_recv(&who, TEMP_ADDR_CHILD, 0);
  800049:	83 ec 04             	sub    $0x4,%esp
  80004c:	6a 00                	push   $0x0
  80004e:	68 00 00 b0 00       	push   $0xb00000
  800053:	8d 45 f4             	lea    -0xc(%ebp),%eax
  800056:	50                   	push   %eax
  800057:	e8 aa 10 00 00       	call   801106 <ipc_recv>
		cprintf("%x got message: %s\n", who, TEMP_ADDR_CHILD);
  80005c:	83 c4 0c             	add    $0xc,%esp
  80005f:	68 00 00 b0 00       	push   $0xb00000
  800064:	ff 75 f4             	pushl  -0xc(%ebp)
  800067:	68 80 15 80 00       	push   $0x801580
  80006c:	e8 13 02 00 00       	call   800284 <cprintf>
		if (strncmp(TEMP_ADDR_CHILD, str1, strlen(str1)) == 0)
  800071:	83 c4 04             	add    $0x4,%esp
  800074:	ff 35 04 20 80 00    	pushl  0x802004
  80007a:	e8 d0 07 00 00       	call   80084f <strlen>
  80007f:	83 c4 0c             	add    $0xc,%esp
  800082:	50                   	push   %eax
  800083:	ff 35 04 20 80 00    	pushl  0x802004
  800089:	68 00 00 b0 00       	push   $0xb00000
  80008e:	e8 c5 08 00 00       	call   800958 <strncmp>
  800093:	83 c4 10             	add    $0x10,%esp
  800096:	85 c0                	test   %eax,%eax
  800098:	75 10                	jne    8000aa <umain+0x77>
			cprintf("child received correct message\n");
  80009a:	83 ec 0c             	sub    $0xc,%esp
  80009d:	68 94 15 80 00       	push   $0x801594
  8000a2:	e8 dd 01 00 00       	call   800284 <cprintf>
  8000a7:	83 c4 10             	add    $0x10,%esp

		memcpy(TEMP_ADDR_CHILD, str2, strlen(str2) + 1);
  8000aa:	83 ec 0c             	sub    $0xc,%esp
  8000ad:	ff 35 00 20 80 00    	pushl  0x802000
  8000b3:	e8 97 07 00 00       	call   80084f <strlen>
  8000b8:	83 c4 0c             	add    $0xc,%esp
  8000bb:	83 c0 01             	add    $0x1,%eax
  8000be:	50                   	push   %eax
  8000bf:	ff 35 00 20 80 00    	pushl  0x802000
  8000c5:	68 00 00 b0 00       	push   $0xb00000
  8000ca:	e8 b3 09 00 00       	call   800a82 <memcpy>
		ipc_send(who, 0, TEMP_ADDR_CHILD, PTE_P | PTE_W | PTE_U);
  8000cf:	6a 07                	push   $0x7
  8000d1:	68 00 00 b0 00       	push   $0xb00000
  8000d6:	6a 00                	push   $0x0
  8000d8:	ff 75 f4             	pushl  -0xc(%ebp)
  8000db:	e8 8f 10 00 00       	call   80116f <ipc_send>
		return;
  8000e0:	83 c4 20             	add    $0x20,%esp
  8000e3:	e9 af 00 00 00       	jmp    800197 <umain+0x164>
	}

	// Parent
	sys_page_alloc(thisenv->env_id, TEMP_ADDR, PTE_P | PTE_W | PTE_U);
  8000e8:	a1 0c 20 80 00       	mov    0x80200c,%eax
  8000ed:	8b 40 48             	mov    0x48(%eax),%eax
  8000f0:	83 ec 04             	sub    $0x4,%esp
  8000f3:	6a 07                	push   $0x7
  8000f5:	68 00 00 a0 00       	push   $0xa00000
  8000fa:	50                   	push   %eax
  8000fb:	e8 8b 0b 00 00       	call   800c8b <sys_page_alloc>
	memcpy(TEMP_ADDR, str1, strlen(str1) + 1);
  800100:	83 c4 04             	add    $0x4,%esp
  800103:	ff 35 04 20 80 00    	pushl  0x802004
  800109:	e8 41 07 00 00       	call   80084f <strlen>
  80010e:	83 c4 0c             	add    $0xc,%esp
  800111:	83 c0 01             	add    $0x1,%eax
  800114:	50                   	push   %eax
  800115:	ff 35 04 20 80 00    	pushl  0x802004
  80011b:	68 00 00 a0 00       	push   $0xa00000
  800120:	e8 5d 09 00 00       	call   800a82 <memcpy>
	ipc_send(who, 0, TEMP_ADDR, PTE_P | PTE_W | PTE_U);
  800125:	6a 07                	push   $0x7
  800127:	68 00 00 a0 00       	push   $0xa00000
  80012c:	6a 00                	push   $0x0
  80012e:	ff 75 f4             	pushl  -0xc(%ebp)
  800131:	e8 39 10 00 00       	call   80116f <ipc_send>

	ipc_recv(&who, TEMP_ADDR, 0);
  800136:	83 c4 1c             	add    $0x1c,%esp
  800139:	6a 00                	push   $0x0
  80013b:	68 00 00 a0 00       	push   $0xa00000
  800140:	8d 45 f4             	lea    -0xc(%ebp),%eax
  800143:	50                   	push   %eax
  800144:	e8 bd 0f 00 00       	call   801106 <ipc_recv>
	cprintf("%x got message: %s\n", who, TEMP_ADDR);
  800149:	83 c4 0c             	add    $0xc,%esp
  80014c:	68 00 00 a0 00       	push   $0xa00000
  800151:	ff 75 f4             	pushl  -0xc(%ebp)
  800154:	68 80 15 80 00       	push   $0x801580
  800159:	e8 26 01 00 00       	call   800284 <cprintf>
	if (strncmp(TEMP_ADDR, str2, strlen(str2)) == 0)
  80015e:	83 c4 04             	add    $0x4,%esp
  800161:	ff 35 00 20 80 00    	pushl  0x802000
  800167:	e8 e3 06 00 00       	call   80084f <strlen>
  80016c:	83 c4 0c             	add    $0xc,%esp
  80016f:	50                   	push   %eax
  800170:	ff 35 00 20 80 00    	pushl  0x802000
  800176:	68 00 00 a0 00       	push   $0xa00000
  80017b:	e8 d8 07 00 00       	call   800958 <strncmp>
  800180:	83 c4 10             	add    $0x10,%esp
  800183:	85 c0                	test   %eax,%eax
  800185:	75 10                	jne    800197 <umain+0x164>
		cprintf("parent received correct message\n");
  800187:	83 ec 0c             	sub    $0xc,%esp
  80018a:	68 b4 15 80 00       	push   $0x8015b4
  80018f:	e8 f0 00 00 00       	call   800284 <cprintf>
  800194:	83 c4 10             	add    $0x10,%esp
	return;
}
  800197:	c9                   	leave  
  800198:	c3                   	ret    

00800199 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800199:	55                   	push   %ebp
  80019a:	89 e5                	mov    %esp,%ebp
  80019c:	56                   	push   %esi
  80019d:	53                   	push   %ebx
  80019e:	8b 5d 08             	mov    0x8(%ebp),%ebx
  8001a1:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = &envs[ENVX(sys_getenvid())];
  8001a4:	e8 a4 0a 00 00       	call   800c4d <sys_getenvid>
  8001a9:	25 ff 03 00 00       	and    $0x3ff,%eax
  8001ae:	6b c0 7c             	imul   $0x7c,%eax,%eax
  8001b1:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  8001b6:	a3 0c 20 80 00       	mov    %eax,0x80200c
	// save the name of the program so that panic() can use it
	if (argc > 0)
  8001bb:	85 db                	test   %ebx,%ebx
  8001bd:	7e 07                	jle    8001c6 <libmain+0x2d>
		binaryname = argv[0];
  8001bf:	8b 06                	mov    (%esi),%eax
  8001c1:	a3 08 20 80 00       	mov    %eax,0x802008

	// call user main routine
	umain(argc, argv);
  8001c6:	83 ec 08             	sub    $0x8,%esp
  8001c9:	56                   	push   %esi
  8001ca:	53                   	push   %ebx
  8001cb:	e8 63 fe ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  8001d0:	e8 0a 00 00 00       	call   8001df <exit>
}
  8001d5:	83 c4 10             	add    $0x10,%esp
  8001d8:	8d 65 f8             	lea    -0x8(%ebp),%esp
  8001db:	5b                   	pop    %ebx
  8001dc:	5e                   	pop    %esi
  8001dd:	5d                   	pop    %ebp
  8001de:	c3                   	ret    

008001df <exit>:

#include <inc/lib.h>

void
exit(void)
{
  8001df:	55                   	push   %ebp
  8001e0:	89 e5                	mov    %esp,%ebp
  8001e2:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  8001e5:	6a 00                	push   $0x0
  8001e7:	e8 20 0a 00 00       	call   800c0c <sys_env_destroy>
}
  8001ec:	83 c4 10             	add    $0x10,%esp
  8001ef:	c9                   	leave  
  8001f0:	c3                   	ret    

008001f1 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8001f1:	55                   	push   %ebp
  8001f2:	89 e5                	mov    %esp,%ebp
  8001f4:	53                   	push   %ebx
  8001f5:	83 ec 04             	sub    $0x4,%esp
  8001f8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8001fb:	8b 13                	mov    (%ebx),%edx
  8001fd:	8d 42 01             	lea    0x1(%edx),%eax
  800200:	89 03                	mov    %eax,(%ebx)
  800202:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800205:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  800209:	3d ff 00 00 00       	cmp    $0xff,%eax
  80020e:	75 1a                	jne    80022a <putch+0x39>
		sys_cputs(b->buf, b->idx);
  800210:	83 ec 08             	sub    $0x8,%esp
  800213:	68 ff 00 00 00       	push   $0xff
  800218:	8d 43 08             	lea    0x8(%ebx),%eax
  80021b:	50                   	push   %eax
  80021c:	e8 ae 09 00 00       	call   800bcf <sys_cputs>
		b->idx = 0;
  800221:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  800227:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  80022a:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  80022e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800231:	c9                   	leave  
  800232:	c3                   	ret    

00800233 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  800233:	55                   	push   %ebp
  800234:	89 e5                	mov    %esp,%ebp
  800236:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  80023c:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  800243:	00 00 00 
	b.cnt = 0;
  800246:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  80024d:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800250:	ff 75 0c             	pushl  0xc(%ebp)
  800253:	ff 75 08             	pushl  0x8(%ebp)
  800256:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  80025c:	50                   	push   %eax
  80025d:	68 f1 01 80 00       	push   $0x8001f1
  800262:	e8 1a 01 00 00       	call   800381 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800267:	83 c4 08             	add    $0x8,%esp
  80026a:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  800270:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800276:	50                   	push   %eax
  800277:	e8 53 09 00 00       	call   800bcf <sys_cputs>

	return b.cnt;
}
  80027c:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800282:	c9                   	leave  
  800283:	c3                   	ret    

00800284 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800284:	55                   	push   %ebp
  800285:	89 e5                	mov    %esp,%ebp
  800287:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  80028a:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  80028d:	50                   	push   %eax
  80028e:	ff 75 08             	pushl  0x8(%ebp)
  800291:	e8 9d ff ff ff       	call   800233 <vcprintf>
	va_end(ap);

	return cnt;
}
  800296:	c9                   	leave  
  800297:	c3                   	ret    

00800298 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800298:	55                   	push   %ebp
  800299:	89 e5                	mov    %esp,%ebp
  80029b:	57                   	push   %edi
  80029c:	56                   	push   %esi
  80029d:	53                   	push   %ebx
  80029e:	83 ec 1c             	sub    $0x1c,%esp
  8002a1:	89 c7                	mov    %eax,%edi
  8002a3:	89 d6                	mov    %edx,%esi
  8002a5:	8b 45 08             	mov    0x8(%ebp),%eax
  8002a8:	8b 55 0c             	mov    0xc(%ebp),%edx
  8002ab:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8002ae:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  8002b1:	8b 4d 10             	mov    0x10(%ebp),%ecx
  8002b4:	bb 00 00 00 00       	mov    $0x0,%ebx
  8002b9:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  8002bc:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  8002bf:	39 d3                	cmp    %edx,%ebx
  8002c1:	72 05                	jb     8002c8 <printnum+0x30>
  8002c3:	39 45 10             	cmp    %eax,0x10(%ebp)
  8002c6:	77 45                	ja     80030d <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8002c8:	83 ec 0c             	sub    $0xc,%esp
  8002cb:	ff 75 18             	pushl  0x18(%ebp)
  8002ce:	8b 45 14             	mov    0x14(%ebp),%eax
  8002d1:	8d 58 ff             	lea    -0x1(%eax),%ebx
  8002d4:	53                   	push   %ebx
  8002d5:	ff 75 10             	pushl  0x10(%ebp)
  8002d8:	83 ec 08             	sub    $0x8,%esp
  8002db:	ff 75 e4             	pushl  -0x1c(%ebp)
  8002de:	ff 75 e0             	pushl  -0x20(%ebp)
  8002e1:	ff 75 dc             	pushl  -0x24(%ebp)
  8002e4:	ff 75 d8             	pushl  -0x28(%ebp)
  8002e7:	e8 f4 0f 00 00       	call   8012e0 <__udivdi3>
  8002ec:	83 c4 18             	add    $0x18,%esp
  8002ef:	52                   	push   %edx
  8002f0:	50                   	push   %eax
  8002f1:	89 f2                	mov    %esi,%edx
  8002f3:	89 f8                	mov    %edi,%eax
  8002f5:	e8 9e ff ff ff       	call   800298 <printnum>
  8002fa:	83 c4 20             	add    $0x20,%esp
  8002fd:	eb 18                	jmp    800317 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8002ff:	83 ec 08             	sub    $0x8,%esp
  800302:	56                   	push   %esi
  800303:	ff 75 18             	pushl  0x18(%ebp)
  800306:	ff d7                	call   *%edi
  800308:	83 c4 10             	add    $0x10,%esp
  80030b:	eb 03                	jmp    800310 <printnum+0x78>
  80030d:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800310:	83 eb 01             	sub    $0x1,%ebx
  800313:	85 db                	test   %ebx,%ebx
  800315:	7f e8                	jg     8002ff <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  800317:	83 ec 08             	sub    $0x8,%esp
  80031a:	56                   	push   %esi
  80031b:	83 ec 04             	sub    $0x4,%esp
  80031e:	ff 75 e4             	pushl  -0x1c(%ebp)
  800321:	ff 75 e0             	pushl  -0x20(%ebp)
  800324:	ff 75 dc             	pushl  -0x24(%ebp)
  800327:	ff 75 d8             	pushl  -0x28(%ebp)
  80032a:	e8 e1 10 00 00       	call   801410 <__umoddi3>
  80032f:	83 c4 14             	add    $0x14,%esp
  800332:	0f be 80 2c 16 80 00 	movsbl 0x80162c(%eax),%eax
  800339:	50                   	push   %eax
  80033a:	ff d7                	call   *%edi
}
  80033c:	83 c4 10             	add    $0x10,%esp
  80033f:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800342:	5b                   	pop    %ebx
  800343:	5e                   	pop    %esi
  800344:	5f                   	pop    %edi
  800345:	5d                   	pop    %ebp
  800346:	c3                   	ret    

00800347 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  800347:	55                   	push   %ebp
  800348:	89 e5                	mov    %esp,%ebp
  80034a:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  80034d:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800351:	8b 10                	mov    (%eax),%edx
  800353:	3b 50 04             	cmp    0x4(%eax),%edx
  800356:	73 0a                	jae    800362 <sprintputch+0x1b>
		*b->buf++ = ch;
  800358:	8d 4a 01             	lea    0x1(%edx),%ecx
  80035b:	89 08                	mov    %ecx,(%eax)
  80035d:	8b 45 08             	mov    0x8(%ebp),%eax
  800360:	88 02                	mov    %al,(%edx)
}
  800362:	5d                   	pop    %ebp
  800363:	c3                   	ret    

00800364 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800364:	55                   	push   %ebp
  800365:	89 e5                	mov    %esp,%ebp
  800367:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  80036a:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  80036d:	50                   	push   %eax
  80036e:	ff 75 10             	pushl  0x10(%ebp)
  800371:	ff 75 0c             	pushl  0xc(%ebp)
  800374:	ff 75 08             	pushl  0x8(%ebp)
  800377:	e8 05 00 00 00       	call   800381 <vprintfmt>
	va_end(ap);
}
  80037c:	83 c4 10             	add    $0x10,%esp
  80037f:	c9                   	leave  
  800380:	c3                   	ret    

00800381 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800381:	55                   	push   %ebp
  800382:	89 e5                	mov    %esp,%ebp
  800384:	57                   	push   %edi
  800385:	56                   	push   %esi
  800386:	53                   	push   %ebx
  800387:	83 ec 2c             	sub    $0x2c,%esp
  80038a:	8b 75 08             	mov    0x8(%ebp),%esi
  80038d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800390:	8b 7d 10             	mov    0x10(%ebp),%edi
  800393:	eb 12                	jmp    8003a7 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800395:	85 c0                	test   %eax,%eax
  800397:	0f 84 42 04 00 00    	je     8007df <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
  80039d:	83 ec 08             	sub    $0x8,%esp
  8003a0:	53                   	push   %ebx
  8003a1:	50                   	push   %eax
  8003a2:	ff d6                	call   *%esi
  8003a4:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  8003a7:	83 c7 01             	add    $0x1,%edi
  8003aa:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8003ae:	83 f8 25             	cmp    $0x25,%eax
  8003b1:	75 e2                	jne    800395 <vprintfmt+0x14>
  8003b3:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  8003b7:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  8003be:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8003c5:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  8003cc:	b9 00 00 00 00       	mov    $0x0,%ecx
  8003d1:	eb 07                	jmp    8003da <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003d3:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  8003d6:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003da:	8d 47 01             	lea    0x1(%edi),%eax
  8003dd:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8003e0:	0f b6 07             	movzbl (%edi),%eax
  8003e3:	0f b6 d0             	movzbl %al,%edx
  8003e6:	83 e8 23             	sub    $0x23,%eax
  8003e9:	3c 55                	cmp    $0x55,%al
  8003eb:	0f 87 d3 03 00 00    	ja     8007c4 <vprintfmt+0x443>
  8003f1:	0f b6 c0             	movzbl %al,%eax
  8003f4:	ff 24 85 00 17 80 00 	jmp    *0x801700(,%eax,4)
  8003fb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  8003fe:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  800402:	eb d6                	jmp    8003da <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800404:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800407:	b8 00 00 00 00       	mov    $0x0,%eax
  80040c:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  80040f:	8d 04 80             	lea    (%eax,%eax,4),%eax
  800412:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
  800416:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
  800419:	8d 4a d0             	lea    -0x30(%edx),%ecx
  80041c:	83 f9 09             	cmp    $0x9,%ecx
  80041f:	77 3f                	ja     800460 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800421:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  800424:	eb e9                	jmp    80040f <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  800426:	8b 45 14             	mov    0x14(%ebp),%eax
  800429:	8b 00                	mov    (%eax),%eax
  80042b:	89 45 d0             	mov    %eax,-0x30(%ebp)
  80042e:	8b 45 14             	mov    0x14(%ebp),%eax
  800431:	8d 40 04             	lea    0x4(%eax),%eax
  800434:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800437:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  80043a:	eb 2a                	jmp    800466 <vprintfmt+0xe5>
  80043c:	8b 45 e0             	mov    -0x20(%ebp),%eax
  80043f:	85 c0                	test   %eax,%eax
  800441:	ba 00 00 00 00       	mov    $0x0,%edx
  800446:	0f 49 d0             	cmovns %eax,%edx
  800449:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80044c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80044f:	eb 89                	jmp    8003da <vprintfmt+0x59>
  800451:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  800454:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  80045b:	e9 7a ff ff ff       	jmp    8003da <vprintfmt+0x59>
  800460:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  800463:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  800466:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  80046a:	0f 89 6a ff ff ff    	jns    8003da <vprintfmt+0x59>
				width = precision, precision = -1;
  800470:	8b 45 d0             	mov    -0x30(%ebp),%eax
  800473:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800476:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  80047d:	e9 58 ff ff ff       	jmp    8003da <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800482:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800485:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  800488:	e9 4d ff ff ff       	jmp    8003da <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  80048d:	8b 45 14             	mov    0x14(%ebp),%eax
  800490:	8d 78 04             	lea    0x4(%eax),%edi
  800493:	83 ec 08             	sub    $0x8,%esp
  800496:	53                   	push   %ebx
  800497:	ff 30                	pushl  (%eax)
  800499:	ff d6                	call   *%esi
			break;
  80049b:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  80049e:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004a1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  8004a4:	e9 fe fe ff ff       	jmp    8003a7 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  8004a9:	8b 45 14             	mov    0x14(%ebp),%eax
  8004ac:	8d 78 04             	lea    0x4(%eax),%edi
  8004af:	8b 00                	mov    (%eax),%eax
  8004b1:	99                   	cltd   
  8004b2:	31 d0                	xor    %edx,%eax
  8004b4:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  8004b6:	83 f8 09             	cmp    $0x9,%eax
  8004b9:	7f 0b                	jg     8004c6 <vprintfmt+0x145>
  8004bb:	8b 14 85 60 18 80 00 	mov    0x801860(,%eax,4),%edx
  8004c2:	85 d2                	test   %edx,%edx
  8004c4:	75 1b                	jne    8004e1 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
  8004c6:	50                   	push   %eax
  8004c7:	68 44 16 80 00       	push   $0x801644
  8004cc:	53                   	push   %ebx
  8004cd:	56                   	push   %esi
  8004ce:	e8 91 fe ff ff       	call   800364 <printfmt>
  8004d3:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  8004d6:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004d9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  8004dc:	e9 c6 fe ff ff       	jmp    8003a7 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  8004e1:	52                   	push   %edx
  8004e2:	68 4d 16 80 00       	push   $0x80164d
  8004e7:	53                   	push   %ebx
  8004e8:	56                   	push   %esi
  8004e9:	e8 76 fe ff ff       	call   800364 <printfmt>
  8004ee:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  8004f1:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004f4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8004f7:	e9 ab fe ff ff       	jmp    8003a7 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8004fc:	8b 45 14             	mov    0x14(%ebp),%eax
  8004ff:	83 c0 04             	add    $0x4,%eax
  800502:	89 45 cc             	mov    %eax,-0x34(%ebp)
  800505:	8b 45 14             	mov    0x14(%ebp),%eax
  800508:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  80050a:	85 ff                	test   %edi,%edi
  80050c:	b8 3d 16 80 00       	mov    $0x80163d,%eax
  800511:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  800514:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800518:	0f 8e 94 00 00 00    	jle    8005b2 <vprintfmt+0x231>
  80051e:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  800522:	0f 84 98 00 00 00    	je     8005c0 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
  800528:	83 ec 08             	sub    $0x8,%esp
  80052b:	ff 75 d0             	pushl  -0x30(%ebp)
  80052e:	57                   	push   %edi
  80052f:	e8 33 03 00 00       	call   800867 <strnlen>
  800534:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  800537:	29 c1                	sub    %eax,%ecx
  800539:	89 4d c8             	mov    %ecx,-0x38(%ebp)
  80053c:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  80053f:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  800543:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800546:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  800549:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  80054b:	eb 0f                	jmp    80055c <vprintfmt+0x1db>
					putch(padc, putdat);
  80054d:	83 ec 08             	sub    $0x8,%esp
  800550:	53                   	push   %ebx
  800551:	ff 75 e0             	pushl  -0x20(%ebp)
  800554:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800556:	83 ef 01             	sub    $0x1,%edi
  800559:	83 c4 10             	add    $0x10,%esp
  80055c:	85 ff                	test   %edi,%edi
  80055e:	7f ed                	jg     80054d <vprintfmt+0x1cc>
  800560:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  800563:	8b 4d c8             	mov    -0x38(%ebp),%ecx
  800566:	85 c9                	test   %ecx,%ecx
  800568:	b8 00 00 00 00       	mov    $0x0,%eax
  80056d:	0f 49 c1             	cmovns %ecx,%eax
  800570:	29 c1                	sub    %eax,%ecx
  800572:	89 75 08             	mov    %esi,0x8(%ebp)
  800575:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800578:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80057b:	89 cb                	mov    %ecx,%ebx
  80057d:	eb 4d                	jmp    8005cc <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  80057f:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800583:	74 1b                	je     8005a0 <vprintfmt+0x21f>
  800585:	0f be c0             	movsbl %al,%eax
  800588:	83 e8 20             	sub    $0x20,%eax
  80058b:	83 f8 5e             	cmp    $0x5e,%eax
  80058e:	76 10                	jbe    8005a0 <vprintfmt+0x21f>
					putch('?', putdat);
  800590:	83 ec 08             	sub    $0x8,%esp
  800593:	ff 75 0c             	pushl  0xc(%ebp)
  800596:	6a 3f                	push   $0x3f
  800598:	ff 55 08             	call   *0x8(%ebp)
  80059b:	83 c4 10             	add    $0x10,%esp
  80059e:	eb 0d                	jmp    8005ad <vprintfmt+0x22c>
				else
					putch(ch, putdat);
  8005a0:	83 ec 08             	sub    $0x8,%esp
  8005a3:	ff 75 0c             	pushl  0xc(%ebp)
  8005a6:	52                   	push   %edx
  8005a7:	ff 55 08             	call   *0x8(%ebp)
  8005aa:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8005ad:	83 eb 01             	sub    $0x1,%ebx
  8005b0:	eb 1a                	jmp    8005cc <vprintfmt+0x24b>
  8005b2:	89 75 08             	mov    %esi,0x8(%ebp)
  8005b5:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8005b8:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8005bb:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8005be:	eb 0c                	jmp    8005cc <vprintfmt+0x24b>
  8005c0:	89 75 08             	mov    %esi,0x8(%ebp)
  8005c3:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8005c6:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8005c9:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8005cc:	83 c7 01             	add    $0x1,%edi
  8005cf:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8005d3:	0f be d0             	movsbl %al,%edx
  8005d6:	85 d2                	test   %edx,%edx
  8005d8:	74 23                	je     8005fd <vprintfmt+0x27c>
  8005da:	85 f6                	test   %esi,%esi
  8005dc:	78 a1                	js     80057f <vprintfmt+0x1fe>
  8005de:	83 ee 01             	sub    $0x1,%esi
  8005e1:	79 9c                	jns    80057f <vprintfmt+0x1fe>
  8005e3:	89 df                	mov    %ebx,%edi
  8005e5:	8b 75 08             	mov    0x8(%ebp),%esi
  8005e8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8005eb:	eb 18                	jmp    800605 <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  8005ed:	83 ec 08             	sub    $0x8,%esp
  8005f0:	53                   	push   %ebx
  8005f1:	6a 20                	push   $0x20
  8005f3:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8005f5:	83 ef 01             	sub    $0x1,%edi
  8005f8:	83 c4 10             	add    $0x10,%esp
  8005fb:	eb 08                	jmp    800605 <vprintfmt+0x284>
  8005fd:	89 df                	mov    %ebx,%edi
  8005ff:	8b 75 08             	mov    0x8(%ebp),%esi
  800602:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800605:	85 ff                	test   %edi,%edi
  800607:	7f e4                	jg     8005ed <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800609:	8b 45 cc             	mov    -0x34(%ebp),%eax
  80060c:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80060f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800612:	e9 90 fd ff ff       	jmp    8003a7 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800617:	83 f9 01             	cmp    $0x1,%ecx
  80061a:	7e 19                	jle    800635 <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
  80061c:	8b 45 14             	mov    0x14(%ebp),%eax
  80061f:	8b 50 04             	mov    0x4(%eax),%edx
  800622:	8b 00                	mov    (%eax),%eax
  800624:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800627:	89 55 dc             	mov    %edx,-0x24(%ebp)
  80062a:	8b 45 14             	mov    0x14(%ebp),%eax
  80062d:	8d 40 08             	lea    0x8(%eax),%eax
  800630:	89 45 14             	mov    %eax,0x14(%ebp)
  800633:	eb 38                	jmp    80066d <vprintfmt+0x2ec>
	else if (lflag)
  800635:	85 c9                	test   %ecx,%ecx
  800637:	74 1b                	je     800654 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
  800639:	8b 45 14             	mov    0x14(%ebp),%eax
  80063c:	8b 00                	mov    (%eax),%eax
  80063e:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800641:	89 c1                	mov    %eax,%ecx
  800643:	c1 f9 1f             	sar    $0x1f,%ecx
  800646:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  800649:	8b 45 14             	mov    0x14(%ebp),%eax
  80064c:	8d 40 04             	lea    0x4(%eax),%eax
  80064f:	89 45 14             	mov    %eax,0x14(%ebp)
  800652:	eb 19                	jmp    80066d <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
  800654:	8b 45 14             	mov    0x14(%ebp),%eax
  800657:	8b 00                	mov    (%eax),%eax
  800659:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80065c:	89 c1                	mov    %eax,%ecx
  80065e:	c1 f9 1f             	sar    $0x1f,%ecx
  800661:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  800664:	8b 45 14             	mov    0x14(%ebp),%eax
  800667:	8d 40 04             	lea    0x4(%eax),%eax
  80066a:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  80066d:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800670:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800673:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800678:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  80067c:	0f 89 0e 01 00 00    	jns    800790 <vprintfmt+0x40f>
				putch('-', putdat);
  800682:	83 ec 08             	sub    $0x8,%esp
  800685:	53                   	push   %ebx
  800686:	6a 2d                	push   $0x2d
  800688:	ff d6                	call   *%esi
				num = -(long long) num;
  80068a:	8b 55 d8             	mov    -0x28(%ebp),%edx
  80068d:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800690:	f7 da                	neg    %edx
  800692:	83 d1 00             	adc    $0x0,%ecx
  800695:	f7 d9                	neg    %ecx
  800697:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  80069a:	b8 0a 00 00 00       	mov    $0xa,%eax
  80069f:	e9 ec 00 00 00       	jmp    800790 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8006a4:	83 f9 01             	cmp    $0x1,%ecx
  8006a7:	7e 18                	jle    8006c1 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
  8006a9:	8b 45 14             	mov    0x14(%ebp),%eax
  8006ac:	8b 10                	mov    (%eax),%edx
  8006ae:	8b 48 04             	mov    0x4(%eax),%ecx
  8006b1:	8d 40 08             	lea    0x8(%eax),%eax
  8006b4:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  8006b7:	b8 0a 00 00 00       	mov    $0xa,%eax
  8006bc:	e9 cf 00 00 00       	jmp    800790 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  8006c1:	85 c9                	test   %ecx,%ecx
  8006c3:	74 1a                	je     8006df <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
  8006c5:	8b 45 14             	mov    0x14(%ebp),%eax
  8006c8:	8b 10                	mov    (%eax),%edx
  8006ca:	b9 00 00 00 00       	mov    $0x0,%ecx
  8006cf:	8d 40 04             	lea    0x4(%eax),%eax
  8006d2:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  8006d5:	b8 0a 00 00 00       	mov    $0xa,%eax
  8006da:	e9 b1 00 00 00       	jmp    800790 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  8006df:	8b 45 14             	mov    0x14(%ebp),%eax
  8006e2:	8b 10                	mov    (%eax),%edx
  8006e4:	b9 00 00 00 00       	mov    $0x0,%ecx
  8006e9:	8d 40 04             	lea    0x4(%eax),%eax
  8006ec:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  8006ef:	b8 0a 00 00 00       	mov    $0xa,%eax
  8006f4:	e9 97 00 00 00       	jmp    800790 <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
  8006f9:	83 ec 08             	sub    $0x8,%esp
  8006fc:	53                   	push   %ebx
  8006fd:	6a 58                	push   $0x58
  8006ff:	ff d6                	call   *%esi
			putch('X', putdat);
  800701:	83 c4 08             	add    $0x8,%esp
  800704:	53                   	push   %ebx
  800705:	6a 58                	push   $0x58
  800707:	ff d6                	call   *%esi
			putch('X', putdat);
  800709:	83 c4 08             	add    $0x8,%esp
  80070c:	53                   	push   %ebx
  80070d:	6a 58                	push   $0x58
  80070f:	ff d6                	call   *%esi
			break;
  800711:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800714:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
  800717:	e9 8b fc ff ff       	jmp    8003a7 <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
  80071c:	83 ec 08             	sub    $0x8,%esp
  80071f:	53                   	push   %ebx
  800720:	6a 30                	push   $0x30
  800722:	ff d6                	call   *%esi
			putch('x', putdat);
  800724:	83 c4 08             	add    $0x8,%esp
  800727:	53                   	push   %ebx
  800728:	6a 78                	push   $0x78
  80072a:	ff d6                	call   *%esi
			num = (unsigned long long)
  80072c:	8b 45 14             	mov    0x14(%ebp),%eax
  80072f:	8b 10                	mov    (%eax),%edx
  800731:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  800736:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  800739:	8d 40 04             	lea    0x4(%eax),%eax
  80073c:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  80073f:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
  800744:	eb 4a                	jmp    800790 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800746:	83 f9 01             	cmp    $0x1,%ecx
  800749:	7e 15                	jle    800760 <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
  80074b:	8b 45 14             	mov    0x14(%ebp),%eax
  80074e:	8b 10                	mov    (%eax),%edx
  800750:	8b 48 04             	mov    0x4(%eax),%ecx
  800753:	8d 40 08             	lea    0x8(%eax),%eax
  800756:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800759:	b8 10 00 00 00       	mov    $0x10,%eax
  80075e:	eb 30                	jmp    800790 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  800760:	85 c9                	test   %ecx,%ecx
  800762:	74 17                	je     80077b <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
  800764:	8b 45 14             	mov    0x14(%ebp),%eax
  800767:	8b 10                	mov    (%eax),%edx
  800769:	b9 00 00 00 00       	mov    $0x0,%ecx
  80076e:	8d 40 04             	lea    0x4(%eax),%eax
  800771:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800774:	b8 10 00 00 00       	mov    $0x10,%eax
  800779:	eb 15                	jmp    800790 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  80077b:	8b 45 14             	mov    0x14(%ebp),%eax
  80077e:	8b 10                	mov    (%eax),%edx
  800780:	b9 00 00 00 00       	mov    $0x0,%ecx
  800785:	8d 40 04             	lea    0x4(%eax),%eax
  800788:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  80078b:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
  800790:	83 ec 0c             	sub    $0xc,%esp
  800793:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  800797:	57                   	push   %edi
  800798:	ff 75 e0             	pushl  -0x20(%ebp)
  80079b:	50                   	push   %eax
  80079c:	51                   	push   %ecx
  80079d:	52                   	push   %edx
  80079e:	89 da                	mov    %ebx,%edx
  8007a0:	89 f0                	mov    %esi,%eax
  8007a2:	e8 f1 fa ff ff       	call   800298 <printnum>
			break;
  8007a7:	83 c4 20             	add    $0x20,%esp
  8007aa:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8007ad:	e9 f5 fb ff ff       	jmp    8003a7 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8007b2:	83 ec 08             	sub    $0x8,%esp
  8007b5:	53                   	push   %ebx
  8007b6:	52                   	push   %edx
  8007b7:	ff d6                	call   *%esi
			break;
  8007b9:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8007bc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  8007bf:	e9 e3 fb ff ff       	jmp    8003a7 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8007c4:	83 ec 08             	sub    $0x8,%esp
  8007c7:	53                   	push   %ebx
  8007c8:	6a 25                	push   $0x25
  8007ca:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  8007cc:	83 c4 10             	add    $0x10,%esp
  8007cf:	eb 03                	jmp    8007d4 <vprintfmt+0x453>
  8007d1:	83 ef 01             	sub    $0x1,%edi
  8007d4:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  8007d8:	75 f7                	jne    8007d1 <vprintfmt+0x450>
  8007da:	e9 c8 fb ff ff       	jmp    8003a7 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  8007df:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8007e2:	5b                   	pop    %ebx
  8007e3:	5e                   	pop    %esi
  8007e4:	5f                   	pop    %edi
  8007e5:	5d                   	pop    %ebp
  8007e6:	c3                   	ret    

008007e7 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  8007e7:	55                   	push   %ebp
  8007e8:	89 e5                	mov    %esp,%ebp
  8007ea:	83 ec 18             	sub    $0x18,%esp
  8007ed:	8b 45 08             	mov    0x8(%ebp),%eax
  8007f0:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  8007f3:	89 45 ec             	mov    %eax,-0x14(%ebp)
  8007f6:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  8007fa:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  8007fd:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800804:	85 c0                	test   %eax,%eax
  800806:	74 26                	je     80082e <vsnprintf+0x47>
  800808:	85 d2                	test   %edx,%edx
  80080a:	7e 22                	jle    80082e <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  80080c:	ff 75 14             	pushl  0x14(%ebp)
  80080f:	ff 75 10             	pushl  0x10(%ebp)
  800812:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800815:	50                   	push   %eax
  800816:	68 47 03 80 00       	push   $0x800347
  80081b:	e8 61 fb ff ff       	call   800381 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800820:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800823:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800826:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800829:	83 c4 10             	add    $0x10,%esp
  80082c:	eb 05                	jmp    800833 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  80082e:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800833:	c9                   	leave  
  800834:	c3                   	ret    

00800835 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800835:	55                   	push   %ebp
  800836:	89 e5                	mov    %esp,%ebp
  800838:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  80083b:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  80083e:	50                   	push   %eax
  80083f:	ff 75 10             	pushl  0x10(%ebp)
  800842:	ff 75 0c             	pushl  0xc(%ebp)
  800845:	ff 75 08             	pushl  0x8(%ebp)
  800848:	e8 9a ff ff ff       	call   8007e7 <vsnprintf>
	va_end(ap);

	return rc;
}
  80084d:	c9                   	leave  
  80084e:	c3                   	ret    

0080084f <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  80084f:	55                   	push   %ebp
  800850:	89 e5                	mov    %esp,%ebp
  800852:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800855:	b8 00 00 00 00       	mov    $0x0,%eax
  80085a:	eb 03                	jmp    80085f <strlen+0x10>
		n++;
  80085c:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  80085f:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800863:	75 f7                	jne    80085c <strlen+0xd>
		n++;
	return n;
}
  800865:	5d                   	pop    %ebp
  800866:	c3                   	ret    

00800867 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800867:	55                   	push   %ebp
  800868:	89 e5                	mov    %esp,%ebp
  80086a:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80086d:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800870:	ba 00 00 00 00       	mov    $0x0,%edx
  800875:	eb 03                	jmp    80087a <strnlen+0x13>
		n++;
  800877:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80087a:	39 c2                	cmp    %eax,%edx
  80087c:	74 08                	je     800886 <strnlen+0x1f>
  80087e:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  800882:	75 f3                	jne    800877 <strnlen+0x10>
  800884:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  800886:	5d                   	pop    %ebp
  800887:	c3                   	ret    

00800888 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800888:	55                   	push   %ebp
  800889:	89 e5                	mov    %esp,%ebp
  80088b:	53                   	push   %ebx
  80088c:	8b 45 08             	mov    0x8(%ebp),%eax
  80088f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800892:	89 c2                	mov    %eax,%edx
  800894:	83 c2 01             	add    $0x1,%edx
  800897:	83 c1 01             	add    $0x1,%ecx
  80089a:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  80089e:	88 5a ff             	mov    %bl,-0x1(%edx)
  8008a1:	84 db                	test   %bl,%bl
  8008a3:	75 ef                	jne    800894 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8008a5:	5b                   	pop    %ebx
  8008a6:	5d                   	pop    %ebp
  8008a7:	c3                   	ret    

008008a8 <strcat>:

char *
strcat(char *dst, const char *src)
{
  8008a8:	55                   	push   %ebp
  8008a9:	89 e5                	mov    %esp,%ebp
  8008ab:	53                   	push   %ebx
  8008ac:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8008af:	53                   	push   %ebx
  8008b0:	e8 9a ff ff ff       	call   80084f <strlen>
  8008b5:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  8008b8:	ff 75 0c             	pushl  0xc(%ebp)
  8008bb:	01 d8                	add    %ebx,%eax
  8008bd:	50                   	push   %eax
  8008be:	e8 c5 ff ff ff       	call   800888 <strcpy>
	return dst;
}
  8008c3:	89 d8                	mov    %ebx,%eax
  8008c5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8008c8:	c9                   	leave  
  8008c9:	c3                   	ret    

008008ca <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8008ca:	55                   	push   %ebp
  8008cb:	89 e5                	mov    %esp,%ebp
  8008cd:	56                   	push   %esi
  8008ce:	53                   	push   %ebx
  8008cf:	8b 75 08             	mov    0x8(%ebp),%esi
  8008d2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8008d5:	89 f3                	mov    %esi,%ebx
  8008d7:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8008da:	89 f2                	mov    %esi,%edx
  8008dc:	eb 0f                	jmp    8008ed <strncpy+0x23>
		*dst++ = *src;
  8008de:	83 c2 01             	add    $0x1,%edx
  8008e1:	0f b6 01             	movzbl (%ecx),%eax
  8008e4:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  8008e7:	80 39 01             	cmpb   $0x1,(%ecx)
  8008ea:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8008ed:	39 da                	cmp    %ebx,%edx
  8008ef:	75 ed                	jne    8008de <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  8008f1:	89 f0                	mov    %esi,%eax
  8008f3:	5b                   	pop    %ebx
  8008f4:	5e                   	pop    %esi
  8008f5:	5d                   	pop    %ebp
  8008f6:	c3                   	ret    

008008f7 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  8008f7:	55                   	push   %ebp
  8008f8:	89 e5                	mov    %esp,%ebp
  8008fa:	56                   	push   %esi
  8008fb:	53                   	push   %ebx
  8008fc:	8b 75 08             	mov    0x8(%ebp),%esi
  8008ff:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800902:	8b 55 10             	mov    0x10(%ebp),%edx
  800905:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800907:	85 d2                	test   %edx,%edx
  800909:	74 21                	je     80092c <strlcpy+0x35>
  80090b:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  80090f:	89 f2                	mov    %esi,%edx
  800911:	eb 09                	jmp    80091c <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800913:	83 c2 01             	add    $0x1,%edx
  800916:	83 c1 01             	add    $0x1,%ecx
  800919:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  80091c:	39 c2                	cmp    %eax,%edx
  80091e:	74 09                	je     800929 <strlcpy+0x32>
  800920:	0f b6 19             	movzbl (%ecx),%ebx
  800923:	84 db                	test   %bl,%bl
  800925:	75 ec                	jne    800913 <strlcpy+0x1c>
  800927:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  800929:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  80092c:	29 f0                	sub    %esi,%eax
}
  80092e:	5b                   	pop    %ebx
  80092f:	5e                   	pop    %esi
  800930:	5d                   	pop    %ebp
  800931:	c3                   	ret    

00800932 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800932:	55                   	push   %ebp
  800933:	89 e5                	mov    %esp,%ebp
  800935:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800938:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  80093b:	eb 06                	jmp    800943 <strcmp+0x11>
		p++, q++;
  80093d:	83 c1 01             	add    $0x1,%ecx
  800940:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800943:	0f b6 01             	movzbl (%ecx),%eax
  800946:	84 c0                	test   %al,%al
  800948:	74 04                	je     80094e <strcmp+0x1c>
  80094a:	3a 02                	cmp    (%edx),%al
  80094c:	74 ef                	je     80093d <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  80094e:	0f b6 c0             	movzbl %al,%eax
  800951:	0f b6 12             	movzbl (%edx),%edx
  800954:	29 d0                	sub    %edx,%eax
}
  800956:	5d                   	pop    %ebp
  800957:	c3                   	ret    

00800958 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800958:	55                   	push   %ebp
  800959:	89 e5                	mov    %esp,%ebp
  80095b:	53                   	push   %ebx
  80095c:	8b 45 08             	mov    0x8(%ebp),%eax
  80095f:	8b 55 0c             	mov    0xc(%ebp),%edx
  800962:	89 c3                	mov    %eax,%ebx
  800964:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800967:	eb 06                	jmp    80096f <strncmp+0x17>
		n--, p++, q++;
  800969:	83 c0 01             	add    $0x1,%eax
  80096c:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  80096f:	39 d8                	cmp    %ebx,%eax
  800971:	74 15                	je     800988 <strncmp+0x30>
  800973:	0f b6 08             	movzbl (%eax),%ecx
  800976:	84 c9                	test   %cl,%cl
  800978:	74 04                	je     80097e <strncmp+0x26>
  80097a:	3a 0a                	cmp    (%edx),%cl
  80097c:	74 eb                	je     800969 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  80097e:	0f b6 00             	movzbl (%eax),%eax
  800981:	0f b6 12             	movzbl (%edx),%edx
  800984:	29 d0                	sub    %edx,%eax
  800986:	eb 05                	jmp    80098d <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800988:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  80098d:	5b                   	pop    %ebx
  80098e:	5d                   	pop    %ebp
  80098f:	c3                   	ret    

00800990 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800990:	55                   	push   %ebp
  800991:	89 e5                	mov    %esp,%ebp
  800993:	8b 45 08             	mov    0x8(%ebp),%eax
  800996:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  80099a:	eb 07                	jmp    8009a3 <strchr+0x13>
		if (*s == c)
  80099c:	38 ca                	cmp    %cl,%dl
  80099e:	74 0f                	je     8009af <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  8009a0:	83 c0 01             	add    $0x1,%eax
  8009a3:	0f b6 10             	movzbl (%eax),%edx
  8009a6:	84 d2                	test   %dl,%dl
  8009a8:	75 f2                	jne    80099c <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  8009aa:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009af:	5d                   	pop    %ebp
  8009b0:	c3                   	ret    

008009b1 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8009b1:	55                   	push   %ebp
  8009b2:	89 e5                	mov    %esp,%ebp
  8009b4:	8b 45 08             	mov    0x8(%ebp),%eax
  8009b7:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8009bb:	eb 03                	jmp    8009c0 <strfind+0xf>
  8009bd:	83 c0 01             	add    $0x1,%eax
  8009c0:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  8009c3:	38 ca                	cmp    %cl,%dl
  8009c5:	74 04                	je     8009cb <strfind+0x1a>
  8009c7:	84 d2                	test   %dl,%dl
  8009c9:	75 f2                	jne    8009bd <strfind+0xc>
			break;
	return (char *) s;
}
  8009cb:	5d                   	pop    %ebp
  8009cc:	c3                   	ret    

008009cd <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8009cd:	55                   	push   %ebp
  8009ce:	89 e5                	mov    %esp,%ebp
  8009d0:	57                   	push   %edi
  8009d1:	56                   	push   %esi
  8009d2:	53                   	push   %ebx
  8009d3:	8b 7d 08             	mov    0x8(%ebp),%edi
  8009d6:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  8009d9:	85 c9                	test   %ecx,%ecx
  8009db:	74 36                	je     800a13 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  8009dd:	f7 c7 03 00 00 00    	test   $0x3,%edi
  8009e3:	75 28                	jne    800a0d <memset+0x40>
  8009e5:	f6 c1 03             	test   $0x3,%cl
  8009e8:	75 23                	jne    800a0d <memset+0x40>
		c &= 0xFF;
  8009ea:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  8009ee:	89 d3                	mov    %edx,%ebx
  8009f0:	c1 e3 08             	shl    $0x8,%ebx
  8009f3:	89 d6                	mov    %edx,%esi
  8009f5:	c1 e6 18             	shl    $0x18,%esi
  8009f8:	89 d0                	mov    %edx,%eax
  8009fa:	c1 e0 10             	shl    $0x10,%eax
  8009fd:	09 f0                	or     %esi,%eax
  8009ff:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  800a01:	89 d8                	mov    %ebx,%eax
  800a03:	09 d0                	or     %edx,%eax
  800a05:	c1 e9 02             	shr    $0x2,%ecx
  800a08:	fc                   	cld    
  800a09:	f3 ab                	rep stos %eax,%es:(%edi)
  800a0b:	eb 06                	jmp    800a13 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800a0d:	8b 45 0c             	mov    0xc(%ebp),%eax
  800a10:	fc                   	cld    
  800a11:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800a13:	89 f8                	mov    %edi,%eax
  800a15:	5b                   	pop    %ebx
  800a16:	5e                   	pop    %esi
  800a17:	5f                   	pop    %edi
  800a18:	5d                   	pop    %ebp
  800a19:	c3                   	ret    

00800a1a <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800a1a:	55                   	push   %ebp
  800a1b:	89 e5                	mov    %esp,%ebp
  800a1d:	57                   	push   %edi
  800a1e:	56                   	push   %esi
  800a1f:	8b 45 08             	mov    0x8(%ebp),%eax
  800a22:	8b 75 0c             	mov    0xc(%ebp),%esi
  800a25:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800a28:	39 c6                	cmp    %eax,%esi
  800a2a:	73 35                	jae    800a61 <memmove+0x47>
  800a2c:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800a2f:	39 d0                	cmp    %edx,%eax
  800a31:	73 2e                	jae    800a61 <memmove+0x47>
		s += n;
		d += n;
  800a33:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a36:	89 d6                	mov    %edx,%esi
  800a38:	09 fe                	or     %edi,%esi
  800a3a:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800a40:	75 13                	jne    800a55 <memmove+0x3b>
  800a42:	f6 c1 03             	test   $0x3,%cl
  800a45:	75 0e                	jne    800a55 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  800a47:	83 ef 04             	sub    $0x4,%edi
  800a4a:	8d 72 fc             	lea    -0x4(%edx),%esi
  800a4d:	c1 e9 02             	shr    $0x2,%ecx
  800a50:	fd                   	std    
  800a51:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a53:	eb 09                	jmp    800a5e <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800a55:	83 ef 01             	sub    $0x1,%edi
  800a58:	8d 72 ff             	lea    -0x1(%edx),%esi
  800a5b:	fd                   	std    
  800a5c:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800a5e:	fc                   	cld    
  800a5f:	eb 1d                	jmp    800a7e <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a61:	89 f2                	mov    %esi,%edx
  800a63:	09 c2                	or     %eax,%edx
  800a65:	f6 c2 03             	test   $0x3,%dl
  800a68:	75 0f                	jne    800a79 <memmove+0x5f>
  800a6a:	f6 c1 03             	test   $0x3,%cl
  800a6d:	75 0a                	jne    800a79 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800a6f:	c1 e9 02             	shr    $0x2,%ecx
  800a72:	89 c7                	mov    %eax,%edi
  800a74:	fc                   	cld    
  800a75:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a77:	eb 05                	jmp    800a7e <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800a79:	89 c7                	mov    %eax,%edi
  800a7b:	fc                   	cld    
  800a7c:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800a7e:	5e                   	pop    %esi
  800a7f:	5f                   	pop    %edi
  800a80:	5d                   	pop    %ebp
  800a81:	c3                   	ret    

00800a82 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800a82:	55                   	push   %ebp
  800a83:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  800a85:	ff 75 10             	pushl  0x10(%ebp)
  800a88:	ff 75 0c             	pushl  0xc(%ebp)
  800a8b:	ff 75 08             	pushl  0x8(%ebp)
  800a8e:	e8 87 ff ff ff       	call   800a1a <memmove>
}
  800a93:	c9                   	leave  
  800a94:	c3                   	ret    

00800a95 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800a95:	55                   	push   %ebp
  800a96:	89 e5                	mov    %esp,%ebp
  800a98:	56                   	push   %esi
  800a99:	53                   	push   %ebx
  800a9a:	8b 45 08             	mov    0x8(%ebp),%eax
  800a9d:	8b 55 0c             	mov    0xc(%ebp),%edx
  800aa0:	89 c6                	mov    %eax,%esi
  800aa2:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800aa5:	eb 1a                	jmp    800ac1 <memcmp+0x2c>
		if (*s1 != *s2)
  800aa7:	0f b6 08             	movzbl (%eax),%ecx
  800aaa:	0f b6 1a             	movzbl (%edx),%ebx
  800aad:	38 d9                	cmp    %bl,%cl
  800aaf:	74 0a                	je     800abb <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800ab1:	0f b6 c1             	movzbl %cl,%eax
  800ab4:	0f b6 db             	movzbl %bl,%ebx
  800ab7:	29 d8                	sub    %ebx,%eax
  800ab9:	eb 0f                	jmp    800aca <memcmp+0x35>
		s1++, s2++;
  800abb:	83 c0 01             	add    $0x1,%eax
  800abe:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800ac1:	39 f0                	cmp    %esi,%eax
  800ac3:	75 e2                	jne    800aa7 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800ac5:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800aca:	5b                   	pop    %ebx
  800acb:	5e                   	pop    %esi
  800acc:	5d                   	pop    %ebp
  800acd:	c3                   	ret    

00800ace <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800ace:	55                   	push   %ebp
  800acf:	89 e5                	mov    %esp,%ebp
  800ad1:	53                   	push   %ebx
  800ad2:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  800ad5:	89 c1                	mov    %eax,%ecx
  800ad7:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  800ada:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800ade:	eb 0a                	jmp    800aea <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  800ae0:	0f b6 10             	movzbl (%eax),%edx
  800ae3:	39 da                	cmp    %ebx,%edx
  800ae5:	74 07                	je     800aee <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800ae7:	83 c0 01             	add    $0x1,%eax
  800aea:	39 c8                	cmp    %ecx,%eax
  800aec:	72 f2                	jb     800ae0 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800aee:	5b                   	pop    %ebx
  800aef:	5d                   	pop    %ebp
  800af0:	c3                   	ret    

00800af1 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800af1:	55                   	push   %ebp
  800af2:	89 e5                	mov    %esp,%ebp
  800af4:	57                   	push   %edi
  800af5:	56                   	push   %esi
  800af6:	53                   	push   %ebx
  800af7:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800afa:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800afd:	eb 03                	jmp    800b02 <strtol+0x11>
		s++;
  800aff:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800b02:	0f b6 01             	movzbl (%ecx),%eax
  800b05:	3c 20                	cmp    $0x20,%al
  800b07:	74 f6                	je     800aff <strtol+0xe>
  800b09:	3c 09                	cmp    $0x9,%al
  800b0b:	74 f2                	je     800aff <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800b0d:	3c 2b                	cmp    $0x2b,%al
  800b0f:	75 0a                	jne    800b1b <strtol+0x2a>
		s++;
  800b11:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800b14:	bf 00 00 00 00       	mov    $0x0,%edi
  800b19:	eb 11                	jmp    800b2c <strtol+0x3b>
  800b1b:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800b20:	3c 2d                	cmp    $0x2d,%al
  800b22:	75 08                	jne    800b2c <strtol+0x3b>
		s++, neg = 1;
  800b24:	83 c1 01             	add    $0x1,%ecx
  800b27:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800b2c:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800b32:	75 15                	jne    800b49 <strtol+0x58>
  800b34:	80 39 30             	cmpb   $0x30,(%ecx)
  800b37:	75 10                	jne    800b49 <strtol+0x58>
  800b39:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800b3d:	75 7c                	jne    800bbb <strtol+0xca>
		s += 2, base = 16;
  800b3f:	83 c1 02             	add    $0x2,%ecx
  800b42:	bb 10 00 00 00       	mov    $0x10,%ebx
  800b47:	eb 16                	jmp    800b5f <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800b49:	85 db                	test   %ebx,%ebx
  800b4b:	75 12                	jne    800b5f <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800b4d:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800b52:	80 39 30             	cmpb   $0x30,(%ecx)
  800b55:	75 08                	jne    800b5f <strtol+0x6e>
		s++, base = 8;
  800b57:	83 c1 01             	add    $0x1,%ecx
  800b5a:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800b5f:	b8 00 00 00 00       	mov    $0x0,%eax
  800b64:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800b67:	0f b6 11             	movzbl (%ecx),%edx
  800b6a:	8d 72 d0             	lea    -0x30(%edx),%esi
  800b6d:	89 f3                	mov    %esi,%ebx
  800b6f:	80 fb 09             	cmp    $0x9,%bl
  800b72:	77 08                	ja     800b7c <strtol+0x8b>
			dig = *s - '0';
  800b74:	0f be d2             	movsbl %dl,%edx
  800b77:	83 ea 30             	sub    $0x30,%edx
  800b7a:	eb 22                	jmp    800b9e <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800b7c:	8d 72 9f             	lea    -0x61(%edx),%esi
  800b7f:	89 f3                	mov    %esi,%ebx
  800b81:	80 fb 19             	cmp    $0x19,%bl
  800b84:	77 08                	ja     800b8e <strtol+0x9d>
			dig = *s - 'a' + 10;
  800b86:	0f be d2             	movsbl %dl,%edx
  800b89:	83 ea 57             	sub    $0x57,%edx
  800b8c:	eb 10                	jmp    800b9e <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800b8e:	8d 72 bf             	lea    -0x41(%edx),%esi
  800b91:	89 f3                	mov    %esi,%ebx
  800b93:	80 fb 19             	cmp    $0x19,%bl
  800b96:	77 16                	ja     800bae <strtol+0xbd>
			dig = *s - 'A' + 10;
  800b98:	0f be d2             	movsbl %dl,%edx
  800b9b:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800b9e:	3b 55 10             	cmp    0x10(%ebp),%edx
  800ba1:	7d 0b                	jge    800bae <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800ba3:	83 c1 01             	add    $0x1,%ecx
  800ba6:	0f af 45 10          	imul   0x10(%ebp),%eax
  800baa:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800bac:	eb b9                	jmp    800b67 <strtol+0x76>

	if (endptr)
  800bae:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800bb2:	74 0d                	je     800bc1 <strtol+0xd0>
		*endptr = (char *) s;
  800bb4:	8b 75 0c             	mov    0xc(%ebp),%esi
  800bb7:	89 0e                	mov    %ecx,(%esi)
  800bb9:	eb 06                	jmp    800bc1 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800bbb:	85 db                	test   %ebx,%ebx
  800bbd:	74 98                	je     800b57 <strtol+0x66>
  800bbf:	eb 9e                	jmp    800b5f <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800bc1:	89 c2                	mov    %eax,%edx
  800bc3:	f7 da                	neg    %edx
  800bc5:	85 ff                	test   %edi,%edi
  800bc7:	0f 45 c2             	cmovne %edx,%eax
}
  800bca:	5b                   	pop    %ebx
  800bcb:	5e                   	pop    %esi
  800bcc:	5f                   	pop    %edi
  800bcd:	5d                   	pop    %ebp
  800bce:	c3                   	ret    

00800bcf <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800bcf:	55                   	push   %ebp
  800bd0:	89 e5                	mov    %esp,%ebp
  800bd2:	57                   	push   %edi
  800bd3:	56                   	push   %esi
  800bd4:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800bd5:	b8 00 00 00 00       	mov    $0x0,%eax
  800bda:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800bdd:	8b 55 08             	mov    0x8(%ebp),%edx
  800be0:	89 c3                	mov    %eax,%ebx
  800be2:	89 c7                	mov    %eax,%edi
  800be4:	89 c6                	mov    %eax,%esi
  800be6:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800be8:	5b                   	pop    %ebx
  800be9:	5e                   	pop    %esi
  800bea:	5f                   	pop    %edi
  800beb:	5d                   	pop    %ebp
  800bec:	c3                   	ret    

00800bed <sys_cgetc>:

int
sys_cgetc(void)
{
  800bed:	55                   	push   %ebp
  800bee:	89 e5                	mov    %esp,%ebp
  800bf0:	57                   	push   %edi
  800bf1:	56                   	push   %esi
  800bf2:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800bf3:	ba 00 00 00 00       	mov    $0x0,%edx
  800bf8:	b8 01 00 00 00       	mov    $0x1,%eax
  800bfd:	89 d1                	mov    %edx,%ecx
  800bff:	89 d3                	mov    %edx,%ebx
  800c01:	89 d7                	mov    %edx,%edi
  800c03:	89 d6                	mov    %edx,%esi
  800c05:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800c07:	5b                   	pop    %ebx
  800c08:	5e                   	pop    %esi
  800c09:	5f                   	pop    %edi
  800c0a:	5d                   	pop    %ebp
  800c0b:	c3                   	ret    

00800c0c <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800c0c:	55                   	push   %ebp
  800c0d:	89 e5                	mov    %esp,%ebp
  800c0f:	57                   	push   %edi
  800c10:	56                   	push   %esi
  800c11:	53                   	push   %ebx
  800c12:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c15:	b9 00 00 00 00       	mov    $0x0,%ecx
  800c1a:	b8 03 00 00 00       	mov    $0x3,%eax
  800c1f:	8b 55 08             	mov    0x8(%ebp),%edx
  800c22:	89 cb                	mov    %ecx,%ebx
  800c24:	89 cf                	mov    %ecx,%edi
  800c26:	89 ce                	mov    %ecx,%esi
  800c28:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800c2a:	85 c0                	test   %eax,%eax
  800c2c:	7e 17                	jle    800c45 <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800c2e:	83 ec 0c             	sub    $0xc,%esp
  800c31:	50                   	push   %eax
  800c32:	6a 03                	push   $0x3
  800c34:	68 88 18 80 00       	push   $0x801888
  800c39:	6a 23                	push   $0x23
  800c3b:	68 a5 18 80 00       	push   $0x8018a5
  800c40:	e8 b9 05 00 00       	call   8011fe <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800c45:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800c48:	5b                   	pop    %ebx
  800c49:	5e                   	pop    %esi
  800c4a:	5f                   	pop    %edi
  800c4b:	5d                   	pop    %ebp
  800c4c:	c3                   	ret    

00800c4d <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800c4d:	55                   	push   %ebp
  800c4e:	89 e5                	mov    %esp,%ebp
  800c50:	57                   	push   %edi
  800c51:	56                   	push   %esi
  800c52:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c53:	ba 00 00 00 00       	mov    $0x0,%edx
  800c58:	b8 02 00 00 00       	mov    $0x2,%eax
  800c5d:	89 d1                	mov    %edx,%ecx
  800c5f:	89 d3                	mov    %edx,%ebx
  800c61:	89 d7                	mov    %edx,%edi
  800c63:	89 d6                	mov    %edx,%esi
  800c65:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800c67:	5b                   	pop    %ebx
  800c68:	5e                   	pop    %esi
  800c69:	5f                   	pop    %edi
  800c6a:	5d                   	pop    %ebp
  800c6b:	c3                   	ret    

00800c6c <sys_yield>:

void
sys_yield(void)
{
  800c6c:	55                   	push   %ebp
  800c6d:	89 e5                	mov    %esp,%ebp
  800c6f:	57                   	push   %edi
  800c70:	56                   	push   %esi
  800c71:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c72:	ba 00 00 00 00       	mov    $0x0,%edx
  800c77:	b8 0a 00 00 00       	mov    $0xa,%eax
  800c7c:	89 d1                	mov    %edx,%ecx
  800c7e:	89 d3                	mov    %edx,%ebx
  800c80:	89 d7                	mov    %edx,%edi
  800c82:	89 d6                	mov    %edx,%esi
  800c84:	cd 30                	int    $0x30

void
sys_yield(void)
{
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
}
  800c86:	5b                   	pop    %ebx
  800c87:	5e                   	pop    %esi
  800c88:	5f                   	pop    %edi
  800c89:	5d                   	pop    %ebp
  800c8a:	c3                   	ret    

00800c8b <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  800c8b:	55                   	push   %ebp
  800c8c:	89 e5                	mov    %esp,%ebp
  800c8e:	57                   	push   %edi
  800c8f:	56                   	push   %esi
  800c90:	53                   	push   %ebx
  800c91:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c94:	be 00 00 00 00       	mov    $0x0,%esi
  800c99:	b8 04 00 00 00       	mov    $0x4,%eax
  800c9e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800ca1:	8b 55 08             	mov    0x8(%ebp),%edx
  800ca4:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800ca7:	89 f7                	mov    %esi,%edi
  800ca9:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800cab:	85 c0                	test   %eax,%eax
  800cad:	7e 17                	jle    800cc6 <sys_page_alloc+0x3b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800caf:	83 ec 0c             	sub    $0xc,%esp
  800cb2:	50                   	push   %eax
  800cb3:	6a 04                	push   $0x4
  800cb5:	68 88 18 80 00       	push   $0x801888
  800cba:	6a 23                	push   $0x23
  800cbc:	68 a5 18 80 00       	push   $0x8018a5
  800cc1:	e8 38 05 00 00       	call   8011fe <_panic>

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
}
  800cc6:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800cc9:	5b                   	pop    %ebx
  800cca:	5e                   	pop    %esi
  800ccb:	5f                   	pop    %edi
  800ccc:	5d                   	pop    %ebp
  800ccd:	c3                   	ret    

00800cce <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  800cce:	55                   	push   %ebp
  800ccf:	89 e5                	mov    %esp,%ebp
  800cd1:	57                   	push   %edi
  800cd2:	56                   	push   %esi
  800cd3:	53                   	push   %ebx
  800cd4:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800cd7:	b8 05 00 00 00       	mov    $0x5,%eax
  800cdc:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800cdf:	8b 55 08             	mov    0x8(%ebp),%edx
  800ce2:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800ce5:	8b 7d 14             	mov    0x14(%ebp),%edi
  800ce8:	8b 75 18             	mov    0x18(%ebp),%esi
  800ceb:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800ced:	85 c0                	test   %eax,%eax
  800cef:	7e 17                	jle    800d08 <sys_page_map+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800cf1:	83 ec 0c             	sub    $0xc,%esp
  800cf4:	50                   	push   %eax
  800cf5:	6a 05                	push   $0x5
  800cf7:	68 88 18 80 00       	push   $0x801888
  800cfc:	6a 23                	push   $0x23
  800cfe:	68 a5 18 80 00       	push   $0x8018a5
  800d03:	e8 f6 04 00 00       	call   8011fe <_panic>

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
}
  800d08:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800d0b:	5b                   	pop    %ebx
  800d0c:	5e                   	pop    %esi
  800d0d:	5f                   	pop    %edi
  800d0e:	5d                   	pop    %ebp
  800d0f:	c3                   	ret    

00800d10 <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  800d10:	55                   	push   %ebp
  800d11:	89 e5                	mov    %esp,%ebp
  800d13:	57                   	push   %edi
  800d14:	56                   	push   %esi
  800d15:	53                   	push   %ebx
  800d16:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d19:	bb 00 00 00 00       	mov    $0x0,%ebx
  800d1e:	b8 06 00 00 00       	mov    $0x6,%eax
  800d23:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800d26:	8b 55 08             	mov    0x8(%ebp),%edx
  800d29:	89 df                	mov    %ebx,%edi
  800d2b:	89 de                	mov    %ebx,%esi
  800d2d:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800d2f:	85 c0                	test   %eax,%eax
  800d31:	7e 17                	jle    800d4a <sys_page_unmap+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800d33:	83 ec 0c             	sub    $0xc,%esp
  800d36:	50                   	push   %eax
  800d37:	6a 06                	push   $0x6
  800d39:	68 88 18 80 00       	push   $0x801888
  800d3e:	6a 23                	push   $0x23
  800d40:	68 a5 18 80 00       	push   $0x8018a5
  800d45:	e8 b4 04 00 00       	call   8011fe <_panic>

int
sys_page_unmap(envid_t envid, void *va)
{
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
}
  800d4a:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800d4d:	5b                   	pop    %ebx
  800d4e:	5e                   	pop    %esi
  800d4f:	5f                   	pop    %edi
  800d50:	5d                   	pop    %ebp
  800d51:	c3                   	ret    

00800d52 <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  800d52:	55                   	push   %ebp
  800d53:	89 e5                	mov    %esp,%ebp
  800d55:	57                   	push   %edi
  800d56:	56                   	push   %esi
  800d57:	53                   	push   %ebx
  800d58:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d5b:	bb 00 00 00 00       	mov    $0x0,%ebx
  800d60:	b8 08 00 00 00       	mov    $0x8,%eax
  800d65:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800d68:	8b 55 08             	mov    0x8(%ebp),%edx
  800d6b:	89 df                	mov    %ebx,%edi
  800d6d:	89 de                	mov    %ebx,%esi
  800d6f:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800d71:	85 c0                	test   %eax,%eax
  800d73:	7e 17                	jle    800d8c <sys_env_set_status+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800d75:	83 ec 0c             	sub    $0xc,%esp
  800d78:	50                   	push   %eax
  800d79:	6a 08                	push   $0x8
  800d7b:	68 88 18 80 00       	push   $0x801888
  800d80:	6a 23                	push   $0x23
  800d82:	68 a5 18 80 00       	push   $0x8018a5
  800d87:	e8 72 04 00 00       	call   8011fe <_panic>

int
sys_env_set_status(envid_t envid, int status)
{
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
}
  800d8c:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800d8f:	5b                   	pop    %ebx
  800d90:	5e                   	pop    %esi
  800d91:	5f                   	pop    %edi
  800d92:	5d                   	pop    %ebp
  800d93:	c3                   	ret    

00800d94 <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  800d94:	55                   	push   %ebp
  800d95:	89 e5                	mov    %esp,%ebp
  800d97:	57                   	push   %edi
  800d98:	56                   	push   %esi
  800d99:	53                   	push   %ebx
  800d9a:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d9d:	bb 00 00 00 00       	mov    $0x0,%ebx
  800da2:	b8 09 00 00 00       	mov    $0x9,%eax
  800da7:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800daa:	8b 55 08             	mov    0x8(%ebp),%edx
  800dad:	89 df                	mov    %ebx,%edi
  800daf:	89 de                	mov    %ebx,%esi
  800db1:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800db3:	85 c0                	test   %eax,%eax
  800db5:	7e 17                	jle    800dce <sys_env_set_pgfault_upcall+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800db7:	83 ec 0c             	sub    $0xc,%esp
  800dba:	50                   	push   %eax
  800dbb:	6a 09                	push   $0x9
  800dbd:	68 88 18 80 00       	push   $0x801888
  800dc2:	6a 23                	push   $0x23
  800dc4:	68 a5 18 80 00       	push   $0x8018a5
  800dc9:	e8 30 04 00 00       	call   8011fe <_panic>

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
}
  800dce:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800dd1:	5b                   	pop    %ebx
  800dd2:	5e                   	pop    %esi
  800dd3:	5f                   	pop    %edi
  800dd4:	5d                   	pop    %ebp
  800dd5:	c3                   	ret    

00800dd6 <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  800dd6:	55                   	push   %ebp
  800dd7:	89 e5                	mov    %esp,%ebp
  800dd9:	57                   	push   %edi
  800dda:	56                   	push   %esi
  800ddb:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800ddc:	be 00 00 00 00       	mov    $0x0,%esi
  800de1:	b8 0b 00 00 00       	mov    $0xb,%eax
  800de6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800de9:	8b 55 08             	mov    0x8(%ebp),%edx
  800dec:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800def:	8b 7d 14             	mov    0x14(%ebp),%edi
  800df2:	cd 30                	int    $0x30

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
}
  800df4:	5b                   	pop    %ebx
  800df5:	5e                   	pop    %esi
  800df6:	5f                   	pop    %edi
  800df7:	5d                   	pop    %ebp
  800df8:	c3                   	ret    

00800df9 <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  800df9:	55                   	push   %ebp
  800dfa:	89 e5                	mov    %esp,%ebp
  800dfc:	57                   	push   %edi
  800dfd:	56                   	push   %esi
  800dfe:	53                   	push   %ebx
  800dff:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800e02:	b9 00 00 00 00       	mov    $0x0,%ecx
  800e07:	b8 0c 00 00 00       	mov    $0xc,%eax
  800e0c:	8b 55 08             	mov    0x8(%ebp),%edx
  800e0f:	89 cb                	mov    %ecx,%ebx
  800e11:	89 cf                	mov    %ecx,%edi
  800e13:	89 ce                	mov    %ecx,%esi
  800e15:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800e17:	85 c0                	test   %eax,%eax
  800e19:	7e 17                	jle    800e32 <sys_ipc_recv+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800e1b:	83 ec 0c             	sub    $0xc,%esp
  800e1e:	50                   	push   %eax
  800e1f:	6a 0c                	push   $0xc
  800e21:	68 88 18 80 00       	push   $0x801888
  800e26:	6a 23                	push   $0x23
  800e28:	68 a5 18 80 00       	push   $0x8018a5
  800e2d:	e8 cc 03 00 00       	call   8011fe <_panic>

int
sys_ipc_recv(void *dstva)
{
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
}
  800e32:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800e35:	5b                   	pop    %ebx
  800e36:	5e                   	pop    %esi
  800e37:	5f                   	pop    %edi
  800e38:	5d                   	pop    %ebp
  800e39:	c3                   	ret    

00800e3a <pgfault>:
// Custom page fault handler - if faulting page is copy-on-write,
// map in our own private writable copy.
//
static void
pgfault(struct UTrapframe *utf)
{
  800e3a:	55                   	push   %ebp
  800e3b:	89 e5                	mov    %esp,%ebp
  800e3d:	53                   	push   %ebx
  800e3e:	83 ec 04             	sub    $0x4,%esp
  800e41:	8b 55 08             	mov    0x8(%ebp),%edx
	void *addr = (void *) utf->utf_fault_va;
  800e44:	8b 02                	mov    (%edx),%eax
	// Hint:
	//   Use the read-only page table mappings at uvpt
	//   (see <inc/memlayout.h>).

	// LAB 4: Your code here.
	if ((err & FEC_WR) == 0||(uvpd[PDX(addr)] & PTE_P) == 0 ||
  800e46:	f6 42 04 02          	testb  $0x2,0x4(%edx)
  800e4a:	74 27                	je     800e73 <pgfault+0x39>
  800e4c:	89 c2                	mov    %eax,%edx
  800e4e:	c1 ea 16             	shr    $0x16,%edx
  800e51:	8b 14 95 00 d0 7b ef 	mov    -0x10843000(,%edx,4),%edx
  800e58:	f6 c2 01             	test   $0x1,%dl
  800e5b:	74 16                	je     800e73 <pgfault+0x39>
		(~uvpt[PGNUM(addr)] & (PTE_COW|PTE_P)) != 0)
  800e5d:	89 c2                	mov    %eax,%edx
  800e5f:	c1 ea 0c             	shr    $0xc,%edx
  800e62:	8b 14 95 00 00 40 ef 	mov    -0x10c00000(,%edx,4),%edx
	// Hint:
	//   Use the read-only page table mappings at uvpt
	//   (see <inc/memlayout.h>).

	// LAB 4: Your code here.
	if ((err & FEC_WR) == 0||(uvpd[PDX(addr)] & PTE_P) == 0 ||
  800e69:	f7 d2                	not    %edx
  800e6b:	f7 c2 01 08 00 00    	test   $0x801,%edx
  800e71:	74 14                	je     800e87 <pgfault+0x4d>
		(~uvpt[PGNUM(addr)] & (PTE_COW|PTE_P)) != 0)
	{
		panic("not copy-on-write");
  800e73:	83 ec 04             	sub    $0x4,%esp
  800e76:	68 b3 18 80 00       	push   $0x8018b3
  800e7b:	6a 1f                	push   $0x1f
  800e7d:	68 c5 18 80 00       	push   $0x8018c5
  800e82:	e8 77 03 00 00       	call   8011fe <_panic>
	// page to the old page's address.
	// Hint:
	//   You should make three system calls.

	// LAB 4: Your code here.
	addr = ROUNDDOWN(addr, PGSIZE);
  800e87:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  800e8c:	89 c3                	mov    %eax,%ebx
	if (sys_page_alloc(0, PFTEMP, PTE_W|PTE_U|PTE_P) < 0)
  800e8e:	83 ec 04             	sub    $0x4,%esp
  800e91:	6a 07                	push   $0x7
  800e93:	68 00 f0 7f 00       	push   $0x7ff000
  800e98:	6a 00                	push   $0x0
  800e9a:	e8 ec fd ff ff       	call   800c8b <sys_page_alloc>
  800e9f:	83 c4 10             	add    $0x10,%esp
  800ea2:	85 c0                	test   %eax,%eax
  800ea4:	79 14                	jns    800eba <pgfault+0x80>
	{
		panic("sys_page_alloc failed");
  800ea6:	83 ec 04             	sub    $0x4,%esp
  800ea9:	68 d0 18 80 00       	push   $0x8018d0
  800eae:	6a 2b                	push   $0x2b
  800eb0:	68 c5 18 80 00       	push   $0x8018c5
  800eb5:	e8 44 03 00 00       	call   8011fe <_panic>
	}
	memcpy(PFTEMP, addr, PGSIZE);
  800eba:	83 ec 04             	sub    $0x4,%esp
  800ebd:	68 00 10 00 00       	push   $0x1000
  800ec2:	53                   	push   %ebx
  800ec3:	68 00 f0 7f 00       	push   $0x7ff000
  800ec8:	e8 b5 fb ff ff       	call   800a82 <memcpy>
	if (sys_page_map(0, PFTEMP, 0, addr, PTE_W|PTE_U|PTE_P) < 0)
  800ecd:	c7 04 24 07 00 00 00 	movl   $0x7,(%esp)
  800ed4:	53                   	push   %ebx
  800ed5:	6a 00                	push   $0x0
  800ed7:	68 00 f0 7f 00       	push   $0x7ff000
  800edc:	6a 00                	push   $0x0
  800ede:	e8 eb fd ff ff       	call   800cce <sys_page_map>
  800ee3:	83 c4 20             	add    $0x20,%esp
  800ee6:	85 c0                	test   %eax,%eax
  800ee8:	79 14                	jns    800efe <pgfault+0xc4>
		panic("sys_page_map failed");
  800eea:	83 ec 04             	sub    $0x4,%esp
  800eed:	68 e6 18 80 00       	push   $0x8018e6
  800ef2:	6a 2f                	push   $0x2f
  800ef4:	68 c5 18 80 00       	push   $0x8018c5
  800ef9:	e8 00 03 00 00       	call   8011fe <_panic>
	if (sys_page_unmap(0, PFTEMP) < 0)
  800efe:	83 ec 08             	sub    $0x8,%esp
  800f01:	68 00 f0 7f 00       	push   $0x7ff000
  800f06:	6a 00                	push   $0x0
  800f08:	e8 03 fe ff ff       	call   800d10 <sys_page_unmap>
  800f0d:	83 c4 10             	add    $0x10,%esp
  800f10:	85 c0                	test   %eax,%eax
  800f12:	79 14                	jns    800f28 <pgfault+0xee>
		panic("sys_page_unmap failed");
  800f14:	83 ec 04             	sub    $0x4,%esp
  800f17:	68 fa 18 80 00       	push   $0x8018fa
  800f1c:	6a 31                	push   $0x31
  800f1e:	68 c5 18 80 00       	push   $0x8018c5
  800f23:	e8 d6 02 00 00       	call   8011fe <_panic>
	return;
	//panic("pgfault not implemented");
}
  800f28:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800f2b:	c9                   	leave  
  800f2c:	c3                   	ret    

00800f2d <fork>:
//   Neither user exception stack should ever be marked copy-on-write,
//   so you must allocate a new page for the child's user exception stack.
//
envid_t
fork(void)
{
  800f2d:	55                   	push   %ebp
  800f2e:	89 e5                	mov    %esp,%ebp
  800f30:	57                   	push   %edi
  800f31:	56                   	push   %esi
  800f32:	53                   	push   %ebx
  800f33:	83 ec 28             	sub    $0x28,%esp
	// LAB 4: Your code here.
	set_pgfault_handler(pgfault); 
  800f36:	68 3a 0e 80 00       	push   $0x800e3a
  800f3b:	e8 04 03 00 00       	call   801244 <set_pgfault_handler>
// This must be inlined.  Exercise for reader: why?
static __inline envid_t __attribute__((always_inline))
sys_exofork(void)
{
	envid_t ret;
	__asm __volatile("int %2"
  800f40:	b8 07 00 00 00       	mov    $0x7,%eax
  800f45:	cd 30                	int    $0x30
  800f47:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	envid_t envid = sys_exofork(); 
	uint32_t addr;
	if(envid < 0)
  800f4a:	83 c4 10             	add    $0x10,%esp
  800f4d:	85 c0                	test   %eax,%eax
  800f4f:	79 14                	jns    800f65 <fork+0x38>
	{ 
		panic("sys_exofork failed");
  800f51:	83 ec 04             	sub    $0x4,%esp
  800f54:	68 10 19 80 00       	push   $0x801910
  800f59:	6a 77                	push   $0x77
  800f5b:	68 c5 18 80 00       	push   $0x8018c5
  800f60:	e8 99 02 00 00       	call   8011fe <_panic>
  800f65:	89 c7                	mov    %eax,%edi
  800f67:	bb 00 00 00 00       	mov    $0x0,%ebx
	}
	else if(envid == 0)
  800f6c:	85 c0                	test   %eax,%eax
  800f6e:	75 1c                	jne    800f8c <fork+0x5f>
	{ 
		thisenv = &envs[ENVX(sys_getenvid())];
  800f70:	e8 d8 fc ff ff       	call   800c4d <sys_getenvid>
  800f75:	25 ff 03 00 00       	and    $0x3ff,%eax
  800f7a:	6b c0 7c             	imul   $0x7c,%eax,%eax
  800f7d:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  800f82:	a3 0c 20 80 00       	mov    %eax,0x80200c
		return envid;
  800f87:	e9 56 01 00 00       	jmp    8010e2 <fork+0x1b5>
	}
	for(addr = 0;addr < USTACKTOP;addr += PGSIZE)
	{
		if ((uvpd[PDX(addr)] & PTE_P) && (uvpt[PGNUM(addr)] & PTE_P)
  800f8c:	89 d8                	mov    %ebx,%eax
  800f8e:	c1 e8 16             	shr    $0x16,%eax
  800f91:	8b 04 85 00 d0 7b ef 	mov    -0x10843000(,%eax,4),%eax
  800f98:	a8 01                	test   $0x1,%al
  800f9a:	0f 84 cb 00 00 00    	je     80106b <fork+0x13e>
  800fa0:	89 d8                	mov    %ebx,%eax
  800fa2:	c1 e8 0c             	shr    $0xc,%eax
  800fa5:	8b 14 85 00 00 40 ef 	mov    -0x10c00000(,%eax,4),%edx
  800fac:	f6 c2 01             	test   $0x1,%dl
  800faf:	0f 84 b6 00 00 00    	je     80106b <fork+0x13e>
			&& (uvpt[PGNUM(addr)] & PTE_U)) 
  800fb5:	8b 14 85 00 00 40 ef 	mov    -0x10c00000(,%eax,4),%edx
  800fbc:	f6 c2 04             	test   $0x4,%dl
  800fbf:	0f 84 a6 00 00 00    	je     80106b <fork+0x13e>
duppage(envid_t envid, unsigned pn)
{
	int r;

	// LAB 4: Your code here.
	void *addr = (void*)(pn * PGSIZE);
  800fc5:	89 c6                	mov    %eax,%esi
  800fc7:	c1 e6 0c             	shl    $0xc,%esi
	if ((uvpt[pn] & PTE_W) || (uvpt[pn] & PTE_COW)) 
  800fca:	8b 14 85 00 00 40 ef 	mov    -0x10c00000(,%eax,4),%edx
  800fd1:	f6 c2 02             	test   $0x2,%dl
  800fd4:	75 0c                	jne    800fe2 <fork+0xb5>
  800fd6:	8b 04 85 00 00 40 ef 	mov    -0x10c00000(,%eax,4),%eax
  800fdd:	f6 c4 08             	test   $0x8,%ah
  800fe0:	74 5d                	je     80103f <fork+0x112>
	{ 
		if (sys_page_map(0, addr, envid, addr, PTE_COW|PTE_U|PTE_P) < 0)
  800fe2:	83 ec 0c             	sub    $0xc,%esp
  800fe5:	68 05 08 00 00       	push   $0x805
  800fea:	56                   	push   %esi
  800feb:	ff 75 e4             	pushl  -0x1c(%ebp)
  800fee:	56                   	push   %esi
  800fef:	6a 00                	push   $0x0
  800ff1:	e8 d8 fc ff ff       	call   800cce <sys_page_map>
  800ff6:	83 c4 20             	add    $0x20,%esp
  800ff9:	85 c0                	test   %eax,%eax
  800ffb:	79 14                	jns    801011 <fork+0xe4>
		{ 
			panic("sys_page_map envid failed");
  800ffd:	83 ec 04             	sub    $0x4,%esp
  801000:	68 23 19 80 00       	push   $0x801923
  801005:	6a 4c                	push   $0x4c
  801007:	68 c5 18 80 00       	push   $0x8018c5
  80100c:	e8 ed 01 00 00       	call   8011fe <_panic>
		}
		if (sys_page_map(0, addr, 0, addr, PTE_COW|PTE_U|PTE_P) < 0)
  801011:	83 ec 0c             	sub    $0xc,%esp
  801014:	68 05 08 00 00       	push   $0x805
  801019:	56                   	push   %esi
  80101a:	6a 00                	push   $0x0
  80101c:	56                   	push   %esi
  80101d:	6a 00                	push   $0x0
  80101f:	e8 aa fc ff ff       	call   800cce <sys_page_map>
  801024:	83 c4 20             	add    $0x20,%esp
  801027:	85 c0                	test   %eax,%eax
  801029:	79 40                	jns    80106b <fork+0x13e>
		{ 
			panic("sys_page_map 0 failed");
  80102b:	83 ec 04             	sub    $0x4,%esp
  80102e:	68 3d 19 80 00       	push   $0x80193d
  801033:	6a 50                	push   $0x50
  801035:	68 c5 18 80 00       	push   $0x8018c5
  80103a:	e8 bf 01 00 00       	call   8011fe <_panic>
		}
	} 
	else 
	{ 
		if(sys_page_map(0, addr, envid, addr, PTE_U|PTE_P) < 0)
  80103f:	83 ec 0c             	sub    $0xc,%esp
  801042:	6a 05                	push   $0x5
  801044:	56                   	push   %esi
  801045:	ff 75 e4             	pushl  -0x1c(%ebp)
  801048:	56                   	push   %esi
  801049:	6a 00                	push   $0x0
  80104b:	e8 7e fc ff ff       	call   800cce <sys_page_map>
  801050:	83 c4 20             	add    $0x20,%esp
  801053:	85 c0                	test   %eax,%eax
  801055:	79 14                	jns    80106b <fork+0x13e>
		{
			panic("sys_page_map envid failed");
  801057:	83 ec 04             	sub    $0x4,%esp
  80105a:	68 23 19 80 00       	push   $0x801923
  80105f:	6a 57                	push   $0x57
  801061:	68 c5 18 80 00       	push   $0x8018c5
  801066:	e8 93 01 00 00       	call   8011fe <_panic>
	else if(envid == 0)
	{ 
		thisenv = &envs[ENVX(sys_getenvid())];
		return envid;
	}
	for(addr = 0;addr < USTACKTOP;addr += PGSIZE)
  80106b:	81 c3 00 10 00 00    	add    $0x1000,%ebx
  801071:	81 fb 00 e0 bf ee    	cmp    $0xeebfe000,%ebx
  801077:	0f 85 0f ff ff ff    	jne    800f8c <fork+0x5f>
			&& (uvpt[PGNUM(addr)] & PTE_U)) 
		{
			duppage(envid, PGNUM(addr));
		}
	}
	if (sys_page_alloc(envid, (void *)(UXSTACKTOP-PGSIZE), PTE_U|PTE_W|PTE_P) < 0)
  80107d:	83 ec 04             	sub    $0x4,%esp
  801080:	6a 07                	push   $0x7
  801082:	68 00 f0 bf ee       	push   $0xeebff000
  801087:	57                   	push   %edi
  801088:	e8 fe fb ff ff       	call   800c8b <sys_page_alloc>
  80108d:	83 c4 10             	add    $0x10,%esp
  801090:	85 c0                	test   %eax,%eax
  801092:	79 17                	jns    8010ab <fork+0x17e>
	{
		panic("sys_page_alloc failed");
  801094:	83 ec 04             	sub    $0x4,%esp
  801097:	68 d0 18 80 00       	push   $0x8018d0
  80109c:	68 88 00 00 00       	push   $0x88
  8010a1:	68 c5 18 80 00       	push   $0x8018c5
  8010a6:	e8 53 01 00 00       	call   8011fe <_panic>
	}
	extern void _pgfault_upcall();
	sys_env_set_pgfault_upcall(envid, _pgfault_upcall);
  8010ab:	83 ec 08             	sub    $0x8,%esp
  8010ae:	68 b3 12 80 00       	push   $0x8012b3
  8010b3:	57                   	push   %edi
  8010b4:	e8 db fc ff ff       	call   800d94 <sys_env_set_pgfault_upcall>
	if (sys_env_set_status(envid, ENV_RUNNABLE) < 0)
  8010b9:	83 c4 08             	add    $0x8,%esp
  8010bc:	6a 02                	push   $0x2
  8010be:	57                   	push   %edi
  8010bf:	e8 8e fc ff ff       	call   800d52 <sys_env_set_status>
  8010c4:	83 c4 10             	add    $0x10,%esp
  8010c7:	85 c0                	test   %eax,%eax
  8010c9:	79 17                	jns    8010e2 <fork+0x1b5>
	{
		panic("sys_env_set_status failed");
  8010cb:	83 ec 04             	sub    $0x4,%esp
  8010ce:	68 53 19 80 00       	push   $0x801953
  8010d3:	68 8e 00 00 00       	push   $0x8e
  8010d8:	68 c5 18 80 00       	push   $0x8018c5
  8010dd:	e8 1c 01 00 00       	call   8011fe <_panic>
	}
	return envid;
	//panic("fork not implemented");
}
  8010e2:	89 f8                	mov    %edi,%eax
  8010e4:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8010e7:	5b                   	pop    %ebx
  8010e8:	5e                   	pop    %esi
  8010e9:	5f                   	pop    %edi
  8010ea:	5d                   	pop    %ebp
  8010eb:	c3                   	ret    

008010ec <sfork>:

// Challenge!
int
sfork(void)
{
  8010ec:	55                   	push   %ebp
  8010ed:	89 e5                	mov    %esp,%ebp
  8010ef:	83 ec 0c             	sub    $0xc,%esp
	panic("sfork not implemented");
  8010f2:	68 6d 19 80 00       	push   $0x80196d
  8010f7:	68 98 00 00 00       	push   $0x98
  8010fc:	68 c5 18 80 00       	push   $0x8018c5
  801101:	e8 f8 00 00 00       	call   8011fe <_panic>

00801106 <ipc_recv>:
//   If 'pg' is null, pass sys_ipc_recv a value that it will understand
//   as meaning "no page".  (Zero is not the right value, since that's
//   a perfectly valid place to map a page.)
int32_t
ipc_recv(envid_t *from_env_store, void *pg, int *perm_store)
{
  801106:	55                   	push   %ebp
  801107:	89 e5                	mov    %esp,%ebp
  801109:	56                   	push   %esi
  80110a:	53                   	push   %ebx
  80110b:	8b 75 08             	mov    0x8(%ebp),%esi
  80110e:	8b 45 0c             	mov    0xc(%ebp),%eax
  801111:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// LAB 4: Your code here.
	if (pg == NULL) 
  801114:	85 c0                	test   %eax,%eax
	{
		pg = (void*)-1;
  801116:	ba ff ff ff ff       	mov    $0xffffffff,%edx
  80111b:	0f 44 c2             	cmove  %edx,%eax
	}
	int flag = sys_ipc_recv(pg);
  80111e:	83 ec 0c             	sub    $0xc,%esp
  801121:	50                   	push   %eax
  801122:	e8 d2 fc ff ff       	call   800df9 <sys_ipc_recv>
	if (flag < 0)
  801127:	83 c4 10             	add    $0x10,%esp
  80112a:	85 c0                	test   %eax,%eax
  80112c:	79 16                	jns    801144 <ipc_recv+0x3e>
	{
		if (from_env_store != NULL) 
  80112e:	85 f6                	test   %esi,%esi
  801130:	74 06                	je     801138 <ipc_recv+0x32>
		{
			*from_env_store = 0;
  801132:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
		}
		if (perm_store != NULL)
  801138:	85 db                	test   %ebx,%ebx
  80113a:	74 2c                	je     801168 <ipc_recv+0x62>
		{
			*perm_store = 0;
  80113c:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  801142:	eb 24                	jmp    801168 <ipc_recv+0x62>
		}
		return flag;
	}
	if (from_env_store != NULL)
  801144:	85 f6                	test   %esi,%esi
  801146:	74 0a                	je     801152 <ipc_recv+0x4c>
	{
		//cprintf("sender:%08x\n",thisenv->env_ipc_from);
		*from_env_store = thisenv->env_ipc_from;
  801148:	a1 0c 20 80 00       	mov    0x80200c,%eax
  80114d:	8b 40 74             	mov    0x74(%eax),%eax
  801150:	89 06                	mov    %eax,(%esi)
	}
	if (perm_store != NULL) 
  801152:	85 db                	test   %ebx,%ebx
  801154:	74 0a                	je     801160 <ipc_recv+0x5a>
	{
		*perm_store = thisenv->env_ipc_perm;
  801156:	a1 0c 20 80 00       	mov    0x80200c,%eax
  80115b:	8b 40 78             	mov    0x78(%eax),%eax
  80115e:	89 03                	mov    %eax,(%ebx)
	}
	return thisenv->env_ipc_value;
  801160:	a1 0c 20 80 00       	mov    0x80200c,%eax
  801165:	8b 40 70             	mov    0x70(%eax),%eax
	//panic("ipc_recv not implemented");
}
  801168:	8d 65 f8             	lea    -0x8(%ebp),%esp
  80116b:	5b                   	pop    %ebx
  80116c:	5e                   	pop    %esi
  80116d:	5d                   	pop    %ebp
  80116e:	c3                   	ret    

0080116f <ipc_send>:
//   Use sys_yield() to be CPU-friendly.
//   If 'pg' is null, pass sys_ipc_try_send a value that it will understand
//   as meaning "no page".  (Zero is not the right value.)
void
ipc_send(envid_t to_env, uint32_t val, void *pg, int perm)
{
  80116f:	55                   	push   %ebp
  801170:	89 e5                	mov    %esp,%ebp
  801172:	57                   	push   %edi
  801173:	56                   	push   %esi
  801174:	53                   	push   %ebx
  801175:	83 ec 0c             	sub    $0xc,%esp
  801178:	8b 7d 08             	mov    0x8(%ebp),%edi
  80117b:	8b 75 0c             	mov    0xc(%ebp),%esi
  80117e:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// LAB 4: Your code here.
	if(pg == NULL)
  801181:	85 db                	test   %ebx,%ebx
	{
		pg = (void*)-1; 
  801183:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  801188:	0f 44 d8             	cmove  %eax,%ebx
	}
	int flag;
	while (true) 
	{ //cprintf("%x\n\n\n", -E_IPC_NOT_RECV);
		flag = sys_ipc_try_send(to_env, val, pg, perm);
  80118b:	ff 75 14             	pushl  0x14(%ebp)
  80118e:	53                   	push   %ebx
  80118f:	56                   	push   %esi
  801190:	57                   	push   %edi
  801191:	e8 40 fc ff ff       	call   800dd6 <sys_ipc_try_send>
		if (flag == 0) 
  801196:	83 c4 10             	add    $0x10,%esp
  801199:	85 c0                	test   %eax,%eax
  80119b:	74 20                	je     8011bd <ipc_send+0x4e>
		{ 
			//cprintf("%08x send %d to %08x\n",thisenv->env_id,val,to_env);
			break;
		}
		if (flag != -E_IPC_NOT_RECV)
  80119d:	83 f8 f8             	cmp    $0xfffffff8,%eax
  8011a0:	74 14                	je     8011b6 <ipc_send+0x47>
		{
			panic("ipc_send failed");
  8011a2:	83 ec 04             	sub    $0x4,%esp
  8011a5:	68 83 19 80 00       	push   $0x801983
  8011aa:	6a 53                	push   $0x53
  8011ac:	68 93 19 80 00       	push   $0x801993
  8011b1:	e8 48 00 00 00       	call   8011fe <_panic>
		}
		sys_yield();
  8011b6:	e8 b1 fa ff ff       	call   800c6c <sys_yield>
	}
  8011bb:	eb ce                	jmp    80118b <ipc_send+0x1c>
	//panic("ipc_send not implemented");
}
  8011bd:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8011c0:	5b                   	pop    %ebx
  8011c1:	5e                   	pop    %esi
  8011c2:	5f                   	pop    %edi
  8011c3:	5d                   	pop    %ebp
  8011c4:	c3                   	ret    

008011c5 <ipc_find_env>:
// Find the first environment of the given type.  We'll use this to
// find special environments.
// Returns 0 if no such environment exists.
envid_t
ipc_find_env(enum EnvType type)
{
  8011c5:	55                   	push   %ebp
  8011c6:	89 e5                	mov    %esp,%ebp
  8011c8:	8b 4d 08             	mov    0x8(%ebp),%ecx
	int i;
	for (i = 0; i < NENV; i++)
  8011cb:	b8 00 00 00 00       	mov    $0x0,%eax
		if (envs[i].env_type == type)
  8011d0:	6b d0 7c             	imul   $0x7c,%eax,%edx
  8011d3:	81 c2 00 00 c0 ee    	add    $0xeec00000,%edx
  8011d9:	8b 52 50             	mov    0x50(%edx),%edx
  8011dc:	39 ca                	cmp    %ecx,%edx
  8011de:	75 0d                	jne    8011ed <ipc_find_env+0x28>
			return envs[i].env_id;
  8011e0:	6b c0 7c             	imul   $0x7c,%eax,%eax
  8011e3:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  8011e8:	8b 40 48             	mov    0x48(%eax),%eax
  8011eb:	eb 0f                	jmp    8011fc <ipc_find_env+0x37>
// Returns 0 if no such environment exists.
envid_t
ipc_find_env(enum EnvType type)
{
	int i;
	for (i = 0; i < NENV; i++)
  8011ed:	83 c0 01             	add    $0x1,%eax
  8011f0:	3d 00 04 00 00       	cmp    $0x400,%eax
  8011f5:	75 d9                	jne    8011d0 <ipc_find_env+0xb>
		if (envs[i].env_type == type)
			return envs[i].env_id;
	return 0;
  8011f7:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8011fc:	5d                   	pop    %ebp
  8011fd:	c3                   	ret    

008011fe <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  8011fe:	55                   	push   %ebp
  8011ff:	89 e5                	mov    %esp,%ebp
  801201:	56                   	push   %esi
  801202:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  801203:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  801206:	8b 35 08 20 80 00    	mov    0x802008,%esi
  80120c:	e8 3c fa ff ff       	call   800c4d <sys_getenvid>
  801211:	83 ec 0c             	sub    $0xc,%esp
  801214:	ff 75 0c             	pushl  0xc(%ebp)
  801217:	ff 75 08             	pushl  0x8(%ebp)
  80121a:	56                   	push   %esi
  80121b:	50                   	push   %eax
  80121c:	68 a0 19 80 00       	push   $0x8019a0
  801221:	e8 5e f0 ff ff       	call   800284 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  801226:	83 c4 18             	add    $0x18,%esp
  801229:	53                   	push   %ebx
  80122a:	ff 75 10             	pushl  0x10(%ebp)
  80122d:	e8 01 f0 ff ff       	call   800233 <vcprintf>
	cprintf("\n");
  801232:	c7 04 24 92 15 80 00 	movl   $0x801592,(%esp)
  801239:	e8 46 f0 ff ff       	call   800284 <cprintf>
  80123e:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  801241:	cc                   	int3   
  801242:	eb fd                	jmp    801241 <_panic+0x43>

00801244 <set_pgfault_handler>:
// at UXSTACKTOP), and tell the kernel to call the assembly-language
// _pgfault_upcall routine when a page fault occurs.
//
void
set_pgfault_handler(void (*handler)(struct UTrapframe *utf))
{
  801244:	55                   	push   %ebp
  801245:	89 e5                	mov    %esp,%ebp
  801247:	83 ec 08             	sub    $0x8,%esp
	int r;

	if (_pgfault_handler == 0) {
  80124a:	83 3d 10 20 80 00 00 	cmpl   $0x0,0x802010
  801251:	75 56                	jne    8012a9 <set_pgfault_handler+0x65>
		// First time through!
		// LAB 4: Your code here.
		r = sys_page_alloc(0, (void*)UXSTACKTOP-PGSIZE, PTE_U|PTE_W|PTE_P);
  801253:	83 ec 04             	sub    $0x4,%esp
  801256:	6a 07                	push   $0x7
  801258:	68 00 f0 bf ee       	push   $0xeebff000
  80125d:	6a 00                	push   $0x0
  80125f:	e8 27 fa ff ff       	call   800c8b <sys_page_alloc>
		//cprintf("%x", r);
		if(r != 0)
  801264:	83 c4 10             	add    $0x10,%esp
  801267:	85 c0                	test   %eax,%eax
  801269:	74 14                	je     80127f <set_pgfault_handler+0x3b>
		{
			panic("sys_page_alloc failed");
  80126b:	83 ec 04             	sub    $0x4,%esp
  80126e:	68 d0 18 80 00       	push   $0x8018d0
  801273:	6a 24                	push   $0x24
  801275:	68 c3 19 80 00       	push   $0x8019c3
  80127a:	e8 7f ff ff ff       	call   8011fe <_panic>
		}
		r = sys_env_set_pgfault_upcall(0, (void*)_pgfault_upcall); 
  80127f:	83 ec 08             	sub    $0x8,%esp
  801282:	68 b3 12 80 00       	push   $0x8012b3
  801287:	6a 00                	push   $0x0
  801289:	e8 06 fb ff ff       	call   800d94 <sys_env_set_pgfault_upcall>
		//cprintf("%x\n", _pgfault_upcall);//fixed bug:_pgfault_upcall-->_pgfault_handler
		if(r != 0)
  80128e:	83 c4 10             	add    $0x10,%esp
  801291:	85 c0                	test   %eax,%eax
  801293:	74 14                	je     8012a9 <set_pgfault_handler+0x65>
		{
			panic("sys_env_set_pgfault_upcall failed");
  801295:	83 ec 04             	sub    $0x4,%esp
  801298:	68 d4 19 80 00       	push   $0x8019d4
  80129d:	6a 2a                	push   $0x2a
  80129f:	68 c3 19 80 00       	push   $0x8019c3
  8012a4:	e8 55 ff ff ff       	call   8011fe <_panic>
		}
		//panic("set_pgfault_handler not implemented");
	}

	// Save handler pointer for assembly to call.
	_pgfault_handler = handler;
  8012a9:	8b 45 08             	mov    0x8(%ebp),%eax
  8012ac:	a3 10 20 80 00       	mov    %eax,0x802010
}
  8012b1:	c9                   	leave  
  8012b2:	c3                   	ret    

008012b3 <_pgfault_upcall>:

.text
.globl _pgfault_upcall
_pgfault_upcall:
	// Call the C page fault handler.
	pushl %esp			// function argument: pointer to UTF
  8012b3:	54                   	push   %esp
	movl _pgfault_handler, %eax
  8012b4:	a1 10 20 80 00       	mov    0x802010,%eax
	call *%eax
  8012b9:	ff d0                	call   *%eax
	addl $4, %esp			// pop function argument
  8012bb:	83 c4 04             	add    $0x4,%esp
	// registers are available for intermediate calculations.  You
	// may find that you have to rearrange your code in non-obvious
	// ways as registers become unavailable as scratch space.
	//
	// LAB 4: Your code here.
	movl 0x28(%esp), %eax
  8012be:	8b 44 24 28          	mov    0x28(%esp),%eax
    	subl $0x4, 0x30(%esp)
  8012c2:	83 6c 24 30 04       	subl   $0x4,0x30(%esp)
   	movl 0x30(%esp), %ebp
  8012c7:	8b 6c 24 30          	mov    0x30(%esp),%ebp
    	movl %eax, (%ebp)
  8012cb:	89 45 00             	mov    %eax,0x0(%ebp)
    	// pop fault_va, err
    	popl %eax
  8012ce:	58                   	pop    %eax
    	popl %eax
  8012cf:	58                   	pop    %eax
	// Restore the trap-time registers.  After you do this, you
	// can no longer modify any general-purpose registers.
	// LAB 4: Your code here.
	popal
  8012d0:	61                   	popa   
	// Restore eflags from the stack.  After you do this, you can
	// no longer use arithmetic operations or anything else that
	// modifies eflags.
	// LAB 4: Your code here.
	addl $0x4, %esp
  8012d1:	83 c4 04             	add    $0x4,%esp
	popfl
  8012d4:	9d                   	popf   
	// Switch back to the adjusted trap-time stack.
	// LAB 4: Your code here.
	popl %esp
  8012d5:	5c                   	pop    %esp
	// Return to re-execute the instruction that faulted.
	// LAB 4: Your code here.
	ret
  8012d6:	c3                   	ret    
  8012d7:	66 90                	xchg   %ax,%ax
  8012d9:	66 90                	xchg   %ax,%ax
  8012db:	66 90                	xchg   %ax,%ax
  8012dd:	66 90                	xchg   %ax,%ax
  8012df:	90                   	nop

008012e0 <__udivdi3>:
  8012e0:	55                   	push   %ebp
  8012e1:	57                   	push   %edi
  8012e2:	56                   	push   %esi
  8012e3:	53                   	push   %ebx
  8012e4:	83 ec 1c             	sub    $0x1c,%esp
  8012e7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  8012eb:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  8012ef:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  8012f3:	8b 7c 24 38          	mov    0x38(%esp),%edi
  8012f7:	85 f6                	test   %esi,%esi
  8012f9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  8012fd:	89 ca                	mov    %ecx,%edx
  8012ff:	89 f8                	mov    %edi,%eax
  801301:	75 3d                	jne    801340 <__udivdi3+0x60>
  801303:	39 cf                	cmp    %ecx,%edi
  801305:	0f 87 c5 00 00 00    	ja     8013d0 <__udivdi3+0xf0>
  80130b:	85 ff                	test   %edi,%edi
  80130d:	89 fd                	mov    %edi,%ebp
  80130f:	75 0b                	jne    80131c <__udivdi3+0x3c>
  801311:	b8 01 00 00 00       	mov    $0x1,%eax
  801316:	31 d2                	xor    %edx,%edx
  801318:	f7 f7                	div    %edi
  80131a:	89 c5                	mov    %eax,%ebp
  80131c:	89 c8                	mov    %ecx,%eax
  80131e:	31 d2                	xor    %edx,%edx
  801320:	f7 f5                	div    %ebp
  801322:	89 c1                	mov    %eax,%ecx
  801324:	89 d8                	mov    %ebx,%eax
  801326:	89 cf                	mov    %ecx,%edi
  801328:	f7 f5                	div    %ebp
  80132a:	89 c3                	mov    %eax,%ebx
  80132c:	89 d8                	mov    %ebx,%eax
  80132e:	89 fa                	mov    %edi,%edx
  801330:	83 c4 1c             	add    $0x1c,%esp
  801333:	5b                   	pop    %ebx
  801334:	5e                   	pop    %esi
  801335:	5f                   	pop    %edi
  801336:	5d                   	pop    %ebp
  801337:	c3                   	ret    
  801338:	90                   	nop
  801339:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  801340:	39 ce                	cmp    %ecx,%esi
  801342:	77 74                	ja     8013b8 <__udivdi3+0xd8>
  801344:	0f bd fe             	bsr    %esi,%edi
  801347:	83 f7 1f             	xor    $0x1f,%edi
  80134a:	0f 84 98 00 00 00    	je     8013e8 <__udivdi3+0x108>
  801350:	bb 20 00 00 00       	mov    $0x20,%ebx
  801355:	89 f9                	mov    %edi,%ecx
  801357:	89 c5                	mov    %eax,%ebp
  801359:	29 fb                	sub    %edi,%ebx
  80135b:	d3 e6                	shl    %cl,%esi
  80135d:	89 d9                	mov    %ebx,%ecx
  80135f:	d3 ed                	shr    %cl,%ebp
  801361:	89 f9                	mov    %edi,%ecx
  801363:	d3 e0                	shl    %cl,%eax
  801365:	09 ee                	or     %ebp,%esi
  801367:	89 d9                	mov    %ebx,%ecx
  801369:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80136d:	89 d5                	mov    %edx,%ebp
  80136f:	8b 44 24 08          	mov    0x8(%esp),%eax
  801373:	d3 ed                	shr    %cl,%ebp
  801375:	89 f9                	mov    %edi,%ecx
  801377:	d3 e2                	shl    %cl,%edx
  801379:	89 d9                	mov    %ebx,%ecx
  80137b:	d3 e8                	shr    %cl,%eax
  80137d:	09 c2                	or     %eax,%edx
  80137f:	89 d0                	mov    %edx,%eax
  801381:	89 ea                	mov    %ebp,%edx
  801383:	f7 f6                	div    %esi
  801385:	89 d5                	mov    %edx,%ebp
  801387:	89 c3                	mov    %eax,%ebx
  801389:	f7 64 24 0c          	mull   0xc(%esp)
  80138d:	39 d5                	cmp    %edx,%ebp
  80138f:	72 10                	jb     8013a1 <__udivdi3+0xc1>
  801391:	8b 74 24 08          	mov    0x8(%esp),%esi
  801395:	89 f9                	mov    %edi,%ecx
  801397:	d3 e6                	shl    %cl,%esi
  801399:	39 c6                	cmp    %eax,%esi
  80139b:	73 07                	jae    8013a4 <__udivdi3+0xc4>
  80139d:	39 d5                	cmp    %edx,%ebp
  80139f:	75 03                	jne    8013a4 <__udivdi3+0xc4>
  8013a1:	83 eb 01             	sub    $0x1,%ebx
  8013a4:	31 ff                	xor    %edi,%edi
  8013a6:	89 d8                	mov    %ebx,%eax
  8013a8:	89 fa                	mov    %edi,%edx
  8013aa:	83 c4 1c             	add    $0x1c,%esp
  8013ad:	5b                   	pop    %ebx
  8013ae:	5e                   	pop    %esi
  8013af:	5f                   	pop    %edi
  8013b0:	5d                   	pop    %ebp
  8013b1:	c3                   	ret    
  8013b2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  8013b8:	31 ff                	xor    %edi,%edi
  8013ba:	31 db                	xor    %ebx,%ebx
  8013bc:	89 d8                	mov    %ebx,%eax
  8013be:	89 fa                	mov    %edi,%edx
  8013c0:	83 c4 1c             	add    $0x1c,%esp
  8013c3:	5b                   	pop    %ebx
  8013c4:	5e                   	pop    %esi
  8013c5:	5f                   	pop    %edi
  8013c6:	5d                   	pop    %ebp
  8013c7:	c3                   	ret    
  8013c8:	90                   	nop
  8013c9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  8013d0:	89 d8                	mov    %ebx,%eax
  8013d2:	f7 f7                	div    %edi
  8013d4:	31 ff                	xor    %edi,%edi
  8013d6:	89 c3                	mov    %eax,%ebx
  8013d8:	89 d8                	mov    %ebx,%eax
  8013da:	89 fa                	mov    %edi,%edx
  8013dc:	83 c4 1c             	add    $0x1c,%esp
  8013df:	5b                   	pop    %ebx
  8013e0:	5e                   	pop    %esi
  8013e1:	5f                   	pop    %edi
  8013e2:	5d                   	pop    %ebp
  8013e3:	c3                   	ret    
  8013e4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  8013e8:	39 ce                	cmp    %ecx,%esi
  8013ea:	72 0c                	jb     8013f8 <__udivdi3+0x118>
  8013ec:	31 db                	xor    %ebx,%ebx
  8013ee:	3b 44 24 08          	cmp    0x8(%esp),%eax
  8013f2:	0f 87 34 ff ff ff    	ja     80132c <__udivdi3+0x4c>
  8013f8:	bb 01 00 00 00       	mov    $0x1,%ebx
  8013fd:	e9 2a ff ff ff       	jmp    80132c <__udivdi3+0x4c>
  801402:	66 90                	xchg   %ax,%ax
  801404:	66 90                	xchg   %ax,%ax
  801406:	66 90                	xchg   %ax,%ax
  801408:	66 90                	xchg   %ax,%ax
  80140a:	66 90                	xchg   %ax,%ax
  80140c:	66 90                	xchg   %ax,%ax
  80140e:	66 90                	xchg   %ax,%ax

00801410 <__umoddi3>:
  801410:	55                   	push   %ebp
  801411:	57                   	push   %edi
  801412:	56                   	push   %esi
  801413:	53                   	push   %ebx
  801414:	83 ec 1c             	sub    $0x1c,%esp
  801417:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  80141b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  80141f:	8b 74 24 34          	mov    0x34(%esp),%esi
  801423:	8b 7c 24 38          	mov    0x38(%esp),%edi
  801427:	85 d2                	test   %edx,%edx
  801429:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  80142d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  801431:	89 f3                	mov    %esi,%ebx
  801433:	89 3c 24             	mov    %edi,(%esp)
  801436:	89 74 24 04          	mov    %esi,0x4(%esp)
  80143a:	75 1c                	jne    801458 <__umoddi3+0x48>
  80143c:	39 f7                	cmp    %esi,%edi
  80143e:	76 50                	jbe    801490 <__umoddi3+0x80>
  801440:	89 c8                	mov    %ecx,%eax
  801442:	89 f2                	mov    %esi,%edx
  801444:	f7 f7                	div    %edi
  801446:	89 d0                	mov    %edx,%eax
  801448:	31 d2                	xor    %edx,%edx
  80144a:	83 c4 1c             	add    $0x1c,%esp
  80144d:	5b                   	pop    %ebx
  80144e:	5e                   	pop    %esi
  80144f:	5f                   	pop    %edi
  801450:	5d                   	pop    %ebp
  801451:	c3                   	ret    
  801452:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  801458:	39 f2                	cmp    %esi,%edx
  80145a:	89 d0                	mov    %edx,%eax
  80145c:	77 52                	ja     8014b0 <__umoddi3+0xa0>
  80145e:	0f bd ea             	bsr    %edx,%ebp
  801461:	83 f5 1f             	xor    $0x1f,%ebp
  801464:	75 5a                	jne    8014c0 <__umoddi3+0xb0>
  801466:	3b 54 24 04          	cmp    0x4(%esp),%edx
  80146a:	0f 82 e0 00 00 00    	jb     801550 <__umoddi3+0x140>
  801470:	39 0c 24             	cmp    %ecx,(%esp)
  801473:	0f 86 d7 00 00 00    	jbe    801550 <__umoddi3+0x140>
  801479:	8b 44 24 08          	mov    0x8(%esp),%eax
  80147d:	8b 54 24 04          	mov    0x4(%esp),%edx
  801481:	83 c4 1c             	add    $0x1c,%esp
  801484:	5b                   	pop    %ebx
  801485:	5e                   	pop    %esi
  801486:	5f                   	pop    %edi
  801487:	5d                   	pop    %ebp
  801488:	c3                   	ret    
  801489:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  801490:	85 ff                	test   %edi,%edi
  801492:	89 fd                	mov    %edi,%ebp
  801494:	75 0b                	jne    8014a1 <__umoddi3+0x91>
  801496:	b8 01 00 00 00       	mov    $0x1,%eax
  80149b:	31 d2                	xor    %edx,%edx
  80149d:	f7 f7                	div    %edi
  80149f:	89 c5                	mov    %eax,%ebp
  8014a1:	89 f0                	mov    %esi,%eax
  8014a3:	31 d2                	xor    %edx,%edx
  8014a5:	f7 f5                	div    %ebp
  8014a7:	89 c8                	mov    %ecx,%eax
  8014a9:	f7 f5                	div    %ebp
  8014ab:	89 d0                	mov    %edx,%eax
  8014ad:	eb 99                	jmp    801448 <__umoddi3+0x38>
  8014af:	90                   	nop
  8014b0:	89 c8                	mov    %ecx,%eax
  8014b2:	89 f2                	mov    %esi,%edx
  8014b4:	83 c4 1c             	add    $0x1c,%esp
  8014b7:	5b                   	pop    %ebx
  8014b8:	5e                   	pop    %esi
  8014b9:	5f                   	pop    %edi
  8014ba:	5d                   	pop    %ebp
  8014bb:	c3                   	ret    
  8014bc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  8014c0:	8b 34 24             	mov    (%esp),%esi
  8014c3:	bf 20 00 00 00       	mov    $0x20,%edi
  8014c8:	89 e9                	mov    %ebp,%ecx
  8014ca:	29 ef                	sub    %ebp,%edi
  8014cc:	d3 e0                	shl    %cl,%eax
  8014ce:	89 f9                	mov    %edi,%ecx
  8014d0:	89 f2                	mov    %esi,%edx
  8014d2:	d3 ea                	shr    %cl,%edx
  8014d4:	89 e9                	mov    %ebp,%ecx
  8014d6:	09 c2                	or     %eax,%edx
  8014d8:	89 d8                	mov    %ebx,%eax
  8014da:	89 14 24             	mov    %edx,(%esp)
  8014dd:	89 f2                	mov    %esi,%edx
  8014df:	d3 e2                	shl    %cl,%edx
  8014e1:	89 f9                	mov    %edi,%ecx
  8014e3:	89 54 24 04          	mov    %edx,0x4(%esp)
  8014e7:	8b 54 24 0c          	mov    0xc(%esp),%edx
  8014eb:	d3 e8                	shr    %cl,%eax
  8014ed:	89 e9                	mov    %ebp,%ecx
  8014ef:	89 c6                	mov    %eax,%esi
  8014f1:	d3 e3                	shl    %cl,%ebx
  8014f3:	89 f9                	mov    %edi,%ecx
  8014f5:	89 d0                	mov    %edx,%eax
  8014f7:	d3 e8                	shr    %cl,%eax
  8014f9:	89 e9                	mov    %ebp,%ecx
  8014fb:	09 d8                	or     %ebx,%eax
  8014fd:	89 d3                	mov    %edx,%ebx
  8014ff:	89 f2                	mov    %esi,%edx
  801501:	f7 34 24             	divl   (%esp)
  801504:	89 d6                	mov    %edx,%esi
  801506:	d3 e3                	shl    %cl,%ebx
  801508:	f7 64 24 04          	mull   0x4(%esp)
  80150c:	39 d6                	cmp    %edx,%esi
  80150e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  801512:	89 d1                	mov    %edx,%ecx
  801514:	89 c3                	mov    %eax,%ebx
  801516:	72 08                	jb     801520 <__umoddi3+0x110>
  801518:	75 11                	jne    80152b <__umoddi3+0x11b>
  80151a:	39 44 24 08          	cmp    %eax,0x8(%esp)
  80151e:	73 0b                	jae    80152b <__umoddi3+0x11b>
  801520:	2b 44 24 04          	sub    0x4(%esp),%eax
  801524:	1b 14 24             	sbb    (%esp),%edx
  801527:	89 d1                	mov    %edx,%ecx
  801529:	89 c3                	mov    %eax,%ebx
  80152b:	8b 54 24 08          	mov    0x8(%esp),%edx
  80152f:	29 da                	sub    %ebx,%edx
  801531:	19 ce                	sbb    %ecx,%esi
  801533:	89 f9                	mov    %edi,%ecx
  801535:	89 f0                	mov    %esi,%eax
  801537:	d3 e0                	shl    %cl,%eax
  801539:	89 e9                	mov    %ebp,%ecx
  80153b:	d3 ea                	shr    %cl,%edx
  80153d:	89 e9                	mov    %ebp,%ecx
  80153f:	d3 ee                	shr    %cl,%esi
  801541:	09 d0                	or     %edx,%eax
  801543:	89 f2                	mov    %esi,%edx
  801545:	83 c4 1c             	add    $0x1c,%esp
  801548:	5b                   	pop    %ebx
  801549:	5e                   	pop    %esi
  80154a:	5f                   	pop    %edi
  80154b:	5d                   	pop    %ebp
  80154c:	c3                   	ret    
  80154d:	8d 76 00             	lea    0x0(%esi),%esi
  801550:	29 f9                	sub    %edi,%ecx
  801552:	19 d6                	sbb    %edx,%esi
  801554:	89 74 24 04          	mov    %esi,0x4(%esp)
  801558:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  80155c:	e9 18 ff ff ff       	jmp    801479 <__umoddi3+0x69>
