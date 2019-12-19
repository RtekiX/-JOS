
obj/user/hello：     文件格式 elf32-i386


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
  80002c:	e8 2d 00 00 00       	call   80005e <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:
// hello, world
#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 14             	sub    $0x14,%esp
	cprintf("hello, world\n");
  800039:	68 00 0e 80 00       	push   $0x800e00
  80003e:	e8 fe 00 00 00       	call   800141 <cprintf>
	cprintf("i am environment %08x\n", thisenv->env_id);
  800043:	a1 04 20 80 00       	mov    0x802004,%eax
  800048:	8b 40 48             	mov    0x48(%eax),%eax
  80004b:	83 c4 08             	add    $0x8,%esp
  80004e:	50                   	push   %eax
  80004f:	68 0e 0e 80 00       	push   $0x800e0e
  800054:	e8 e8 00 00 00       	call   800141 <cprintf>
}
  800059:	83 c4 10             	add    $0x10,%esp
  80005c:	c9                   	leave  
  80005d:	c3                   	ret    

0080005e <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  80005e:	55                   	push   %ebp
  80005f:	89 e5                	mov    %esp,%ebp
  800061:	56                   	push   %esi
  800062:	53                   	push   %ebx
  800063:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800066:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	envid_t envid = sys_getenvid();
  800069:	e8 9c 0a 00 00       	call   800b0a <sys_getenvid>
	thisenv = envs;
  80006e:	c7 05 04 20 80 00 00 	movl   $0xeec00000,0x802004
  800075:	00 c0 ee 
	// save the name of the program so that panic() can use it
	if (argc > 0)
  800078:	85 db                	test   %ebx,%ebx
  80007a:	7e 07                	jle    800083 <libmain+0x25>
		binaryname = argv[0];
  80007c:	8b 06                	mov    (%esi),%eax
  80007e:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  800083:	83 ec 08             	sub    $0x8,%esp
  800086:	56                   	push   %esi
  800087:	53                   	push   %ebx
  800088:	e8 a6 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  80008d:	e8 0a 00 00 00       	call   80009c <exit>
}
  800092:	83 c4 10             	add    $0x10,%esp
  800095:	8d 65 f8             	lea    -0x8(%ebp),%esp
  800098:	5b                   	pop    %ebx
  800099:	5e                   	pop    %esi
  80009a:	5d                   	pop    %ebp
  80009b:	c3                   	ret    

0080009c <exit>:

#include <inc/lib.h>

void
exit(void)
{
  80009c:	55                   	push   %ebp
  80009d:	89 e5                	mov    %esp,%ebp
  80009f:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  8000a2:	6a 00                	push   $0x0
  8000a4:	e8 20 0a 00 00       	call   800ac9 <sys_env_destroy>
}
  8000a9:	83 c4 10             	add    $0x10,%esp
  8000ac:	c9                   	leave  
  8000ad:	c3                   	ret    

008000ae <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8000ae:	55                   	push   %ebp
  8000af:	89 e5                	mov    %esp,%ebp
  8000b1:	53                   	push   %ebx
  8000b2:	83 ec 04             	sub    $0x4,%esp
  8000b5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8000b8:	8b 13                	mov    (%ebx),%edx
  8000ba:	8d 42 01             	lea    0x1(%edx),%eax
  8000bd:	89 03                	mov    %eax,(%ebx)
  8000bf:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000c2:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8000c6:	3d ff 00 00 00       	cmp    $0xff,%eax
  8000cb:	75 1a                	jne    8000e7 <putch+0x39>
		sys_cputs(b->buf, b->idx);
  8000cd:	83 ec 08             	sub    $0x8,%esp
  8000d0:	68 ff 00 00 00       	push   $0xff
  8000d5:	8d 43 08             	lea    0x8(%ebx),%eax
  8000d8:	50                   	push   %eax
  8000d9:	e8 ae 09 00 00       	call   800a8c <sys_cputs>
		b->idx = 0;
  8000de:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8000e4:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8000e7:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8000eb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8000ee:	c9                   	leave  
  8000ef:	c3                   	ret    

008000f0 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8000f0:	55                   	push   %ebp
  8000f1:	89 e5                	mov    %esp,%ebp
  8000f3:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8000f9:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  800100:	00 00 00 
	b.cnt = 0;
  800103:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  80010a:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  80010d:	ff 75 0c             	pushl  0xc(%ebp)
  800110:	ff 75 08             	pushl  0x8(%ebp)
  800113:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800119:	50                   	push   %eax
  80011a:	68 ae 00 80 00       	push   $0x8000ae
  80011f:	e8 1a 01 00 00       	call   80023e <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800124:	83 c4 08             	add    $0x8,%esp
  800127:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  80012d:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800133:	50                   	push   %eax
  800134:	e8 53 09 00 00       	call   800a8c <sys_cputs>

	return b.cnt;
}
  800139:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  80013f:	c9                   	leave  
  800140:	c3                   	ret    

00800141 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800141:	55                   	push   %ebp
  800142:	89 e5                	mov    %esp,%ebp
  800144:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800147:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  80014a:	50                   	push   %eax
  80014b:	ff 75 08             	pushl  0x8(%ebp)
  80014e:	e8 9d ff ff ff       	call   8000f0 <vcprintf>
	va_end(ap);

	return cnt;
}
  800153:	c9                   	leave  
  800154:	c3                   	ret    

00800155 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800155:	55                   	push   %ebp
  800156:	89 e5                	mov    %esp,%ebp
  800158:	57                   	push   %edi
  800159:	56                   	push   %esi
  80015a:	53                   	push   %ebx
  80015b:	83 ec 1c             	sub    $0x1c,%esp
  80015e:	89 c7                	mov    %eax,%edi
  800160:	89 d6                	mov    %edx,%esi
  800162:	8b 45 08             	mov    0x8(%ebp),%eax
  800165:	8b 55 0c             	mov    0xc(%ebp),%edx
  800168:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80016b:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  80016e:	8b 4d 10             	mov    0x10(%ebp),%ecx
  800171:	bb 00 00 00 00       	mov    $0x0,%ebx
  800176:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800179:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  80017c:	39 d3                	cmp    %edx,%ebx
  80017e:	72 05                	jb     800185 <printnum+0x30>
  800180:	39 45 10             	cmp    %eax,0x10(%ebp)
  800183:	77 45                	ja     8001ca <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800185:	83 ec 0c             	sub    $0xc,%esp
  800188:	ff 75 18             	pushl  0x18(%ebp)
  80018b:	8b 45 14             	mov    0x14(%ebp),%eax
  80018e:	8d 58 ff             	lea    -0x1(%eax),%ebx
  800191:	53                   	push   %ebx
  800192:	ff 75 10             	pushl  0x10(%ebp)
  800195:	83 ec 08             	sub    $0x8,%esp
  800198:	ff 75 e4             	pushl  -0x1c(%ebp)
  80019b:	ff 75 e0             	pushl  -0x20(%ebp)
  80019e:	ff 75 dc             	pushl  -0x24(%ebp)
  8001a1:	ff 75 d8             	pushl  -0x28(%ebp)
  8001a4:	e8 c7 09 00 00       	call   800b70 <__udivdi3>
  8001a9:	83 c4 18             	add    $0x18,%esp
  8001ac:	52                   	push   %edx
  8001ad:	50                   	push   %eax
  8001ae:	89 f2                	mov    %esi,%edx
  8001b0:	89 f8                	mov    %edi,%eax
  8001b2:	e8 9e ff ff ff       	call   800155 <printnum>
  8001b7:	83 c4 20             	add    $0x20,%esp
  8001ba:	eb 18                	jmp    8001d4 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8001bc:	83 ec 08             	sub    $0x8,%esp
  8001bf:	56                   	push   %esi
  8001c0:	ff 75 18             	pushl  0x18(%ebp)
  8001c3:	ff d7                	call   *%edi
  8001c5:	83 c4 10             	add    $0x10,%esp
  8001c8:	eb 03                	jmp    8001cd <printnum+0x78>
  8001ca:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8001cd:	83 eb 01             	sub    $0x1,%ebx
  8001d0:	85 db                	test   %ebx,%ebx
  8001d2:	7f e8                	jg     8001bc <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8001d4:	83 ec 08             	sub    $0x8,%esp
  8001d7:	56                   	push   %esi
  8001d8:	83 ec 04             	sub    $0x4,%esp
  8001db:	ff 75 e4             	pushl  -0x1c(%ebp)
  8001de:	ff 75 e0             	pushl  -0x20(%ebp)
  8001e1:	ff 75 dc             	pushl  -0x24(%ebp)
  8001e4:	ff 75 d8             	pushl  -0x28(%ebp)
  8001e7:	e8 b4 0a 00 00       	call   800ca0 <__umoddi3>
  8001ec:	83 c4 14             	add    $0x14,%esp
  8001ef:	0f be 80 2f 0e 80 00 	movsbl 0x800e2f(%eax),%eax
  8001f6:	50                   	push   %eax
  8001f7:	ff d7                	call   *%edi
}
  8001f9:	83 c4 10             	add    $0x10,%esp
  8001fc:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8001ff:	5b                   	pop    %ebx
  800200:	5e                   	pop    %esi
  800201:	5f                   	pop    %edi
  800202:	5d                   	pop    %ebp
  800203:	c3                   	ret    

00800204 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  800204:	55                   	push   %ebp
  800205:	89 e5                	mov    %esp,%ebp
  800207:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  80020a:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  80020e:	8b 10                	mov    (%eax),%edx
  800210:	3b 50 04             	cmp    0x4(%eax),%edx
  800213:	73 0a                	jae    80021f <sprintputch+0x1b>
		*b->buf++ = ch;
  800215:	8d 4a 01             	lea    0x1(%edx),%ecx
  800218:	89 08                	mov    %ecx,(%eax)
  80021a:	8b 45 08             	mov    0x8(%ebp),%eax
  80021d:	88 02                	mov    %al,(%edx)
}
  80021f:	5d                   	pop    %ebp
  800220:	c3                   	ret    

00800221 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800221:	55                   	push   %ebp
  800222:	89 e5                	mov    %esp,%ebp
  800224:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  800227:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  80022a:	50                   	push   %eax
  80022b:	ff 75 10             	pushl  0x10(%ebp)
  80022e:	ff 75 0c             	pushl  0xc(%ebp)
  800231:	ff 75 08             	pushl  0x8(%ebp)
  800234:	e8 05 00 00 00       	call   80023e <vprintfmt>
	va_end(ap);
}
  800239:	83 c4 10             	add    $0x10,%esp
  80023c:	c9                   	leave  
  80023d:	c3                   	ret    

0080023e <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  80023e:	55                   	push   %ebp
  80023f:	89 e5                	mov    %esp,%ebp
  800241:	57                   	push   %edi
  800242:	56                   	push   %esi
  800243:	53                   	push   %ebx
  800244:	83 ec 2c             	sub    $0x2c,%esp
  800247:	8b 75 08             	mov    0x8(%ebp),%esi
  80024a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80024d:	8b 7d 10             	mov    0x10(%ebp),%edi
  800250:	eb 12                	jmp    800264 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800252:	85 c0                	test   %eax,%eax
  800254:	0f 84 42 04 00 00    	je     80069c <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
  80025a:	83 ec 08             	sub    $0x8,%esp
  80025d:	53                   	push   %ebx
  80025e:	50                   	push   %eax
  80025f:	ff d6                	call   *%esi
  800261:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800264:	83 c7 01             	add    $0x1,%edi
  800267:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  80026b:	83 f8 25             	cmp    $0x25,%eax
  80026e:	75 e2                	jne    800252 <vprintfmt+0x14>
  800270:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  800274:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  80027b:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800282:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  800289:	b9 00 00 00 00       	mov    $0x0,%ecx
  80028e:	eb 07                	jmp    800297 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800290:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  800293:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800297:	8d 47 01             	lea    0x1(%edi),%eax
  80029a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  80029d:	0f b6 07             	movzbl (%edi),%eax
  8002a0:	0f b6 d0             	movzbl %al,%edx
  8002a3:	83 e8 23             	sub    $0x23,%eax
  8002a6:	3c 55                	cmp    $0x55,%al
  8002a8:	0f 87 d3 03 00 00    	ja     800681 <vprintfmt+0x443>
  8002ae:	0f b6 c0             	movzbl %al,%eax
  8002b1:	ff 24 85 c0 0e 80 00 	jmp    *0x800ec0(,%eax,4)
  8002b8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  8002bb:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  8002bf:	eb d6                	jmp    800297 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002c1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8002c4:	b8 00 00 00 00       	mov    $0x0,%eax
  8002c9:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  8002cc:	8d 04 80             	lea    (%eax,%eax,4),%eax
  8002cf:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
  8002d3:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
  8002d6:	8d 4a d0             	lea    -0x30(%edx),%ecx
  8002d9:	83 f9 09             	cmp    $0x9,%ecx
  8002dc:	77 3f                	ja     80031d <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8002de:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8002e1:	eb e9                	jmp    8002cc <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8002e3:	8b 45 14             	mov    0x14(%ebp),%eax
  8002e6:	8b 00                	mov    (%eax),%eax
  8002e8:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8002eb:	8b 45 14             	mov    0x14(%ebp),%eax
  8002ee:	8d 40 04             	lea    0x4(%eax),%eax
  8002f1:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002f4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8002f7:	eb 2a                	jmp    800323 <vprintfmt+0xe5>
  8002f9:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8002fc:	85 c0                	test   %eax,%eax
  8002fe:	ba 00 00 00 00       	mov    $0x0,%edx
  800303:	0f 49 d0             	cmovns %eax,%edx
  800306:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800309:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80030c:	eb 89                	jmp    800297 <vprintfmt+0x59>
  80030e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  800311:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  800318:	e9 7a ff ff ff       	jmp    800297 <vprintfmt+0x59>
  80031d:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  800320:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  800323:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800327:	0f 89 6a ff ff ff    	jns    800297 <vprintfmt+0x59>
				width = precision, precision = -1;
  80032d:	8b 45 d0             	mov    -0x30(%ebp),%eax
  800330:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800333:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  80033a:	e9 58 ff ff ff       	jmp    800297 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  80033f:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800342:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  800345:	e9 4d ff ff ff       	jmp    800297 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  80034a:	8b 45 14             	mov    0x14(%ebp),%eax
  80034d:	8d 78 04             	lea    0x4(%eax),%edi
  800350:	83 ec 08             	sub    $0x8,%esp
  800353:	53                   	push   %ebx
  800354:	ff 30                	pushl  (%eax)
  800356:	ff d6                	call   *%esi
			break;
  800358:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  80035b:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80035e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  800361:	e9 fe fe ff ff       	jmp    800264 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800366:	8b 45 14             	mov    0x14(%ebp),%eax
  800369:	8d 78 04             	lea    0x4(%eax),%edi
  80036c:	8b 00                	mov    (%eax),%eax
  80036e:	99                   	cltd   
  80036f:	31 d0                	xor    %edx,%eax
  800371:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800373:	83 f8 07             	cmp    $0x7,%eax
  800376:	7f 0b                	jg     800383 <vprintfmt+0x145>
  800378:	8b 14 85 20 10 80 00 	mov    0x801020(,%eax,4),%edx
  80037f:	85 d2                	test   %edx,%edx
  800381:	75 1b                	jne    80039e <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
  800383:	50                   	push   %eax
  800384:	68 47 0e 80 00       	push   $0x800e47
  800389:	53                   	push   %ebx
  80038a:	56                   	push   %esi
  80038b:	e8 91 fe ff ff       	call   800221 <printfmt>
  800390:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  800393:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800396:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  800399:	e9 c6 fe ff ff       	jmp    800264 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  80039e:	52                   	push   %edx
  80039f:	68 50 0e 80 00       	push   $0x800e50
  8003a4:	53                   	push   %ebx
  8003a5:	56                   	push   %esi
  8003a6:	e8 76 fe ff ff       	call   800221 <printfmt>
  8003ab:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  8003ae:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003b1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003b4:	e9 ab fe ff ff       	jmp    800264 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8003b9:	8b 45 14             	mov    0x14(%ebp),%eax
  8003bc:	83 c0 04             	add    $0x4,%eax
  8003bf:	89 45 cc             	mov    %eax,-0x34(%ebp)
  8003c2:	8b 45 14             	mov    0x14(%ebp),%eax
  8003c5:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  8003c7:	85 ff                	test   %edi,%edi
  8003c9:	b8 40 0e 80 00       	mov    $0x800e40,%eax
  8003ce:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  8003d1:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8003d5:	0f 8e 94 00 00 00    	jle    80046f <vprintfmt+0x231>
  8003db:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  8003df:	0f 84 98 00 00 00    	je     80047d <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
  8003e5:	83 ec 08             	sub    $0x8,%esp
  8003e8:	ff 75 d0             	pushl  -0x30(%ebp)
  8003eb:	57                   	push   %edi
  8003ec:	e8 33 03 00 00       	call   800724 <strnlen>
  8003f1:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8003f4:	29 c1                	sub    %eax,%ecx
  8003f6:	89 4d c8             	mov    %ecx,-0x38(%ebp)
  8003f9:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  8003fc:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  800400:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800403:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  800406:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800408:	eb 0f                	jmp    800419 <vprintfmt+0x1db>
					putch(padc, putdat);
  80040a:	83 ec 08             	sub    $0x8,%esp
  80040d:	53                   	push   %ebx
  80040e:	ff 75 e0             	pushl  -0x20(%ebp)
  800411:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800413:	83 ef 01             	sub    $0x1,%edi
  800416:	83 c4 10             	add    $0x10,%esp
  800419:	85 ff                	test   %edi,%edi
  80041b:	7f ed                	jg     80040a <vprintfmt+0x1cc>
  80041d:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  800420:	8b 4d c8             	mov    -0x38(%ebp),%ecx
  800423:	85 c9                	test   %ecx,%ecx
  800425:	b8 00 00 00 00       	mov    $0x0,%eax
  80042a:	0f 49 c1             	cmovns %ecx,%eax
  80042d:	29 c1                	sub    %eax,%ecx
  80042f:	89 75 08             	mov    %esi,0x8(%ebp)
  800432:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800435:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800438:	89 cb                	mov    %ecx,%ebx
  80043a:	eb 4d                	jmp    800489 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  80043c:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800440:	74 1b                	je     80045d <vprintfmt+0x21f>
  800442:	0f be c0             	movsbl %al,%eax
  800445:	83 e8 20             	sub    $0x20,%eax
  800448:	83 f8 5e             	cmp    $0x5e,%eax
  80044b:	76 10                	jbe    80045d <vprintfmt+0x21f>
					putch('?', putdat);
  80044d:	83 ec 08             	sub    $0x8,%esp
  800450:	ff 75 0c             	pushl  0xc(%ebp)
  800453:	6a 3f                	push   $0x3f
  800455:	ff 55 08             	call   *0x8(%ebp)
  800458:	83 c4 10             	add    $0x10,%esp
  80045b:	eb 0d                	jmp    80046a <vprintfmt+0x22c>
				else
					putch(ch, putdat);
  80045d:	83 ec 08             	sub    $0x8,%esp
  800460:	ff 75 0c             	pushl  0xc(%ebp)
  800463:	52                   	push   %edx
  800464:	ff 55 08             	call   *0x8(%ebp)
  800467:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  80046a:	83 eb 01             	sub    $0x1,%ebx
  80046d:	eb 1a                	jmp    800489 <vprintfmt+0x24b>
  80046f:	89 75 08             	mov    %esi,0x8(%ebp)
  800472:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800475:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800478:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  80047b:	eb 0c                	jmp    800489 <vprintfmt+0x24b>
  80047d:	89 75 08             	mov    %esi,0x8(%ebp)
  800480:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800483:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800486:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800489:	83 c7 01             	add    $0x1,%edi
  80048c:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800490:	0f be d0             	movsbl %al,%edx
  800493:	85 d2                	test   %edx,%edx
  800495:	74 23                	je     8004ba <vprintfmt+0x27c>
  800497:	85 f6                	test   %esi,%esi
  800499:	78 a1                	js     80043c <vprintfmt+0x1fe>
  80049b:	83 ee 01             	sub    $0x1,%esi
  80049e:	79 9c                	jns    80043c <vprintfmt+0x1fe>
  8004a0:	89 df                	mov    %ebx,%edi
  8004a2:	8b 75 08             	mov    0x8(%ebp),%esi
  8004a5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8004a8:	eb 18                	jmp    8004c2 <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  8004aa:	83 ec 08             	sub    $0x8,%esp
  8004ad:	53                   	push   %ebx
  8004ae:	6a 20                	push   $0x20
  8004b0:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8004b2:	83 ef 01             	sub    $0x1,%edi
  8004b5:	83 c4 10             	add    $0x10,%esp
  8004b8:	eb 08                	jmp    8004c2 <vprintfmt+0x284>
  8004ba:	89 df                	mov    %ebx,%edi
  8004bc:	8b 75 08             	mov    0x8(%ebp),%esi
  8004bf:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8004c2:	85 ff                	test   %edi,%edi
  8004c4:	7f e4                	jg     8004aa <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8004c6:	8b 45 cc             	mov    -0x34(%ebp),%eax
  8004c9:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004cc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8004cf:	e9 90 fd ff ff       	jmp    800264 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8004d4:	83 f9 01             	cmp    $0x1,%ecx
  8004d7:	7e 19                	jle    8004f2 <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
  8004d9:	8b 45 14             	mov    0x14(%ebp),%eax
  8004dc:	8b 50 04             	mov    0x4(%eax),%edx
  8004df:	8b 00                	mov    (%eax),%eax
  8004e1:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8004e4:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8004e7:	8b 45 14             	mov    0x14(%ebp),%eax
  8004ea:	8d 40 08             	lea    0x8(%eax),%eax
  8004ed:	89 45 14             	mov    %eax,0x14(%ebp)
  8004f0:	eb 38                	jmp    80052a <vprintfmt+0x2ec>
	else if (lflag)
  8004f2:	85 c9                	test   %ecx,%ecx
  8004f4:	74 1b                	je     800511 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
  8004f6:	8b 45 14             	mov    0x14(%ebp),%eax
  8004f9:	8b 00                	mov    (%eax),%eax
  8004fb:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8004fe:	89 c1                	mov    %eax,%ecx
  800500:	c1 f9 1f             	sar    $0x1f,%ecx
  800503:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  800506:	8b 45 14             	mov    0x14(%ebp),%eax
  800509:	8d 40 04             	lea    0x4(%eax),%eax
  80050c:	89 45 14             	mov    %eax,0x14(%ebp)
  80050f:	eb 19                	jmp    80052a <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
  800511:	8b 45 14             	mov    0x14(%ebp),%eax
  800514:	8b 00                	mov    (%eax),%eax
  800516:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800519:	89 c1                	mov    %eax,%ecx
  80051b:	c1 f9 1f             	sar    $0x1f,%ecx
  80051e:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  800521:	8b 45 14             	mov    0x14(%ebp),%eax
  800524:	8d 40 04             	lea    0x4(%eax),%eax
  800527:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  80052a:	8b 55 d8             	mov    -0x28(%ebp),%edx
  80052d:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800530:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800535:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800539:	0f 89 0e 01 00 00    	jns    80064d <vprintfmt+0x40f>
				putch('-', putdat);
  80053f:	83 ec 08             	sub    $0x8,%esp
  800542:	53                   	push   %ebx
  800543:	6a 2d                	push   $0x2d
  800545:	ff d6                	call   *%esi
				num = -(long long) num;
  800547:	8b 55 d8             	mov    -0x28(%ebp),%edx
  80054a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  80054d:	f7 da                	neg    %edx
  80054f:	83 d1 00             	adc    $0x0,%ecx
  800552:	f7 d9                	neg    %ecx
  800554:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  800557:	b8 0a 00 00 00       	mov    $0xa,%eax
  80055c:	e9 ec 00 00 00       	jmp    80064d <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800561:	83 f9 01             	cmp    $0x1,%ecx
  800564:	7e 18                	jle    80057e <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
  800566:	8b 45 14             	mov    0x14(%ebp),%eax
  800569:	8b 10                	mov    (%eax),%edx
  80056b:	8b 48 04             	mov    0x4(%eax),%ecx
  80056e:	8d 40 08             	lea    0x8(%eax),%eax
  800571:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800574:	b8 0a 00 00 00       	mov    $0xa,%eax
  800579:	e9 cf 00 00 00       	jmp    80064d <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  80057e:	85 c9                	test   %ecx,%ecx
  800580:	74 1a                	je     80059c <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
  800582:	8b 45 14             	mov    0x14(%ebp),%eax
  800585:	8b 10                	mov    (%eax),%edx
  800587:	b9 00 00 00 00       	mov    $0x0,%ecx
  80058c:	8d 40 04             	lea    0x4(%eax),%eax
  80058f:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800592:	b8 0a 00 00 00       	mov    $0xa,%eax
  800597:	e9 b1 00 00 00       	jmp    80064d <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  80059c:	8b 45 14             	mov    0x14(%ebp),%eax
  80059f:	8b 10                	mov    (%eax),%edx
  8005a1:	b9 00 00 00 00       	mov    $0x0,%ecx
  8005a6:	8d 40 04             	lea    0x4(%eax),%eax
  8005a9:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  8005ac:	b8 0a 00 00 00       	mov    $0xa,%eax
  8005b1:	e9 97 00 00 00       	jmp    80064d <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
  8005b6:	83 ec 08             	sub    $0x8,%esp
  8005b9:	53                   	push   %ebx
  8005ba:	6a 58                	push   $0x58
  8005bc:	ff d6                	call   *%esi
			putch('X', putdat);
  8005be:	83 c4 08             	add    $0x8,%esp
  8005c1:	53                   	push   %ebx
  8005c2:	6a 58                	push   $0x58
  8005c4:	ff d6                	call   *%esi
			putch('X', putdat);
  8005c6:	83 c4 08             	add    $0x8,%esp
  8005c9:	53                   	push   %ebx
  8005ca:	6a 58                	push   $0x58
  8005cc:	ff d6                	call   *%esi
			break;
  8005ce:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005d1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
  8005d4:	e9 8b fc ff ff       	jmp    800264 <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
  8005d9:	83 ec 08             	sub    $0x8,%esp
  8005dc:	53                   	push   %ebx
  8005dd:	6a 30                	push   $0x30
  8005df:	ff d6                	call   *%esi
			putch('x', putdat);
  8005e1:	83 c4 08             	add    $0x8,%esp
  8005e4:	53                   	push   %ebx
  8005e5:	6a 78                	push   $0x78
  8005e7:	ff d6                	call   *%esi
			num = (unsigned long long)
  8005e9:	8b 45 14             	mov    0x14(%ebp),%eax
  8005ec:	8b 10                	mov    (%eax),%edx
  8005ee:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  8005f3:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  8005f6:	8d 40 04             	lea    0x4(%eax),%eax
  8005f9:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  8005fc:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
  800601:	eb 4a                	jmp    80064d <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800603:	83 f9 01             	cmp    $0x1,%ecx
  800606:	7e 15                	jle    80061d <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
  800608:	8b 45 14             	mov    0x14(%ebp),%eax
  80060b:	8b 10                	mov    (%eax),%edx
  80060d:	8b 48 04             	mov    0x4(%eax),%ecx
  800610:	8d 40 08             	lea    0x8(%eax),%eax
  800613:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800616:	b8 10 00 00 00       	mov    $0x10,%eax
  80061b:	eb 30                	jmp    80064d <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  80061d:	85 c9                	test   %ecx,%ecx
  80061f:	74 17                	je     800638 <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
  800621:	8b 45 14             	mov    0x14(%ebp),%eax
  800624:	8b 10                	mov    (%eax),%edx
  800626:	b9 00 00 00 00       	mov    $0x0,%ecx
  80062b:	8d 40 04             	lea    0x4(%eax),%eax
  80062e:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800631:	b8 10 00 00 00       	mov    $0x10,%eax
  800636:	eb 15                	jmp    80064d <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  800638:	8b 45 14             	mov    0x14(%ebp),%eax
  80063b:	8b 10                	mov    (%eax),%edx
  80063d:	b9 00 00 00 00       	mov    $0x0,%ecx
  800642:	8d 40 04             	lea    0x4(%eax),%eax
  800645:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800648:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
  80064d:	83 ec 0c             	sub    $0xc,%esp
  800650:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  800654:	57                   	push   %edi
  800655:	ff 75 e0             	pushl  -0x20(%ebp)
  800658:	50                   	push   %eax
  800659:	51                   	push   %ecx
  80065a:	52                   	push   %edx
  80065b:	89 da                	mov    %ebx,%edx
  80065d:	89 f0                	mov    %esi,%eax
  80065f:	e8 f1 fa ff ff       	call   800155 <printnum>
			break;
  800664:	83 c4 20             	add    $0x20,%esp
  800667:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80066a:	e9 f5 fb ff ff       	jmp    800264 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  80066f:	83 ec 08             	sub    $0x8,%esp
  800672:	53                   	push   %ebx
  800673:	52                   	push   %edx
  800674:	ff d6                	call   *%esi
			break;
  800676:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800679:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  80067c:	e9 e3 fb ff ff       	jmp    800264 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  800681:	83 ec 08             	sub    $0x8,%esp
  800684:	53                   	push   %ebx
  800685:	6a 25                	push   $0x25
  800687:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800689:	83 c4 10             	add    $0x10,%esp
  80068c:	eb 03                	jmp    800691 <vprintfmt+0x453>
  80068e:	83 ef 01             	sub    $0x1,%edi
  800691:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800695:	75 f7                	jne    80068e <vprintfmt+0x450>
  800697:	e9 c8 fb ff ff       	jmp    800264 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  80069c:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80069f:	5b                   	pop    %ebx
  8006a0:	5e                   	pop    %esi
  8006a1:	5f                   	pop    %edi
  8006a2:	5d                   	pop    %ebp
  8006a3:	c3                   	ret    

008006a4 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  8006a4:	55                   	push   %ebp
  8006a5:	89 e5                	mov    %esp,%ebp
  8006a7:	83 ec 18             	sub    $0x18,%esp
  8006aa:	8b 45 08             	mov    0x8(%ebp),%eax
  8006ad:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  8006b0:	89 45 ec             	mov    %eax,-0x14(%ebp)
  8006b3:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  8006b7:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  8006ba:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8006c1:	85 c0                	test   %eax,%eax
  8006c3:	74 26                	je     8006eb <vsnprintf+0x47>
  8006c5:	85 d2                	test   %edx,%edx
  8006c7:	7e 22                	jle    8006eb <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  8006c9:	ff 75 14             	pushl  0x14(%ebp)
  8006cc:	ff 75 10             	pushl  0x10(%ebp)
  8006cf:	8d 45 ec             	lea    -0x14(%ebp),%eax
  8006d2:	50                   	push   %eax
  8006d3:	68 04 02 80 00       	push   $0x800204
  8006d8:	e8 61 fb ff ff       	call   80023e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  8006dd:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8006e0:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  8006e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8006e6:	83 c4 10             	add    $0x10,%esp
  8006e9:	eb 05                	jmp    8006f0 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  8006eb:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  8006f0:	c9                   	leave  
  8006f1:	c3                   	ret    

008006f2 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  8006f2:	55                   	push   %ebp
  8006f3:	89 e5                	mov    %esp,%ebp
  8006f5:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  8006f8:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  8006fb:	50                   	push   %eax
  8006fc:	ff 75 10             	pushl  0x10(%ebp)
  8006ff:	ff 75 0c             	pushl  0xc(%ebp)
  800702:	ff 75 08             	pushl  0x8(%ebp)
  800705:	e8 9a ff ff ff       	call   8006a4 <vsnprintf>
	va_end(ap);

	return rc;
}
  80070a:	c9                   	leave  
  80070b:	c3                   	ret    

0080070c <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  80070c:	55                   	push   %ebp
  80070d:	89 e5                	mov    %esp,%ebp
  80070f:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800712:	b8 00 00 00 00       	mov    $0x0,%eax
  800717:	eb 03                	jmp    80071c <strlen+0x10>
		n++;
  800719:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  80071c:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800720:	75 f7                	jne    800719 <strlen+0xd>
		n++;
	return n;
}
  800722:	5d                   	pop    %ebp
  800723:	c3                   	ret    

00800724 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800724:	55                   	push   %ebp
  800725:	89 e5                	mov    %esp,%ebp
  800727:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80072a:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80072d:	ba 00 00 00 00       	mov    $0x0,%edx
  800732:	eb 03                	jmp    800737 <strnlen+0x13>
		n++;
  800734:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800737:	39 c2                	cmp    %eax,%edx
  800739:	74 08                	je     800743 <strnlen+0x1f>
  80073b:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  80073f:	75 f3                	jne    800734 <strnlen+0x10>
  800741:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  800743:	5d                   	pop    %ebp
  800744:	c3                   	ret    

00800745 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800745:	55                   	push   %ebp
  800746:	89 e5                	mov    %esp,%ebp
  800748:	53                   	push   %ebx
  800749:	8b 45 08             	mov    0x8(%ebp),%eax
  80074c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  80074f:	89 c2                	mov    %eax,%edx
  800751:	83 c2 01             	add    $0x1,%edx
  800754:	83 c1 01             	add    $0x1,%ecx
  800757:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  80075b:	88 5a ff             	mov    %bl,-0x1(%edx)
  80075e:	84 db                	test   %bl,%bl
  800760:	75 ef                	jne    800751 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800762:	5b                   	pop    %ebx
  800763:	5d                   	pop    %ebp
  800764:	c3                   	ret    

00800765 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800765:	55                   	push   %ebp
  800766:	89 e5                	mov    %esp,%ebp
  800768:	53                   	push   %ebx
  800769:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  80076c:	53                   	push   %ebx
  80076d:	e8 9a ff ff ff       	call   80070c <strlen>
  800772:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  800775:	ff 75 0c             	pushl  0xc(%ebp)
  800778:	01 d8                	add    %ebx,%eax
  80077a:	50                   	push   %eax
  80077b:	e8 c5 ff ff ff       	call   800745 <strcpy>
	return dst;
}
  800780:	89 d8                	mov    %ebx,%eax
  800782:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800785:	c9                   	leave  
  800786:	c3                   	ret    

00800787 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800787:	55                   	push   %ebp
  800788:	89 e5                	mov    %esp,%ebp
  80078a:	56                   	push   %esi
  80078b:	53                   	push   %ebx
  80078c:	8b 75 08             	mov    0x8(%ebp),%esi
  80078f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800792:	89 f3                	mov    %esi,%ebx
  800794:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800797:	89 f2                	mov    %esi,%edx
  800799:	eb 0f                	jmp    8007aa <strncpy+0x23>
		*dst++ = *src;
  80079b:	83 c2 01             	add    $0x1,%edx
  80079e:	0f b6 01             	movzbl (%ecx),%eax
  8007a1:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  8007a4:	80 39 01             	cmpb   $0x1,(%ecx)
  8007a7:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007aa:	39 da                	cmp    %ebx,%edx
  8007ac:	75 ed                	jne    80079b <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  8007ae:	89 f0                	mov    %esi,%eax
  8007b0:	5b                   	pop    %ebx
  8007b1:	5e                   	pop    %esi
  8007b2:	5d                   	pop    %ebp
  8007b3:	c3                   	ret    

008007b4 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  8007b4:	55                   	push   %ebp
  8007b5:	89 e5                	mov    %esp,%ebp
  8007b7:	56                   	push   %esi
  8007b8:	53                   	push   %ebx
  8007b9:	8b 75 08             	mov    0x8(%ebp),%esi
  8007bc:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8007bf:	8b 55 10             	mov    0x10(%ebp),%edx
  8007c2:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  8007c4:	85 d2                	test   %edx,%edx
  8007c6:	74 21                	je     8007e9 <strlcpy+0x35>
  8007c8:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  8007cc:	89 f2                	mov    %esi,%edx
  8007ce:	eb 09                	jmp    8007d9 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  8007d0:	83 c2 01             	add    $0x1,%edx
  8007d3:	83 c1 01             	add    $0x1,%ecx
  8007d6:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  8007d9:	39 c2                	cmp    %eax,%edx
  8007db:	74 09                	je     8007e6 <strlcpy+0x32>
  8007dd:	0f b6 19             	movzbl (%ecx),%ebx
  8007e0:	84 db                	test   %bl,%bl
  8007e2:	75 ec                	jne    8007d0 <strlcpy+0x1c>
  8007e4:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  8007e6:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  8007e9:	29 f0                	sub    %esi,%eax
}
  8007eb:	5b                   	pop    %ebx
  8007ec:	5e                   	pop    %esi
  8007ed:	5d                   	pop    %ebp
  8007ee:	c3                   	ret    

008007ef <strcmp>:

int
strcmp(const char *p, const char *q)
{
  8007ef:	55                   	push   %ebp
  8007f0:	89 e5                	mov    %esp,%ebp
  8007f2:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8007f5:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  8007f8:	eb 06                	jmp    800800 <strcmp+0x11>
		p++, q++;
  8007fa:	83 c1 01             	add    $0x1,%ecx
  8007fd:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800800:	0f b6 01             	movzbl (%ecx),%eax
  800803:	84 c0                	test   %al,%al
  800805:	74 04                	je     80080b <strcmp+0x1c>
  800807:	3a 02                	cmp    (%edx),%al
  800809:	74 ef                	je     8007fa <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  80080b:	0f b6 c0             	movzbl %al,%eax
  80080e:	0f b6 12             	movzbl (%edx),%edx
  800811:	29 d0                	sub    %edx,%eax
}
  800813:	5d                   	pop    %ebp
  800814:	c3                   	ret    

00800815 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800815:	55                   	push   %ebp
  800816:	89 e5                	mov    %esp,%ebp
  800818:	53                   	push   %ebx
  800819:	8b 45 08             	mov    0x8(%ebp),%eax
  80081c:	8b 55 0c             	mov    0xc(%ebp),%edx
  80081f:	89 c3                	mov    %eax,%ebx
  800821:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800824:	eb 06                	jmp    80082c <strncmp+0x17>
		n--, p++, q++;
  800826:	83 c0 01             	add    $0x1,%eax
  800829:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  80082c:	39 d8                	cmp    %ebx,%eax
  80082e:	74 15                	je     800845 <strncmp+0x30>
  800830:	0f b6 08             	movzbl (%eax),%ecx
  800833:	84 c9                	test   %cl,%cl
  800835:	74 04                	je     80083b <strncmp+0x26>
  800837:	3a 0a                	cmp    (%edx),%cl
  800839:	74 eb                	je     800826 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  80083b:	0f b6 00             	movzbl (%eax),%eax
  80083e:	0f b6 12             	movzbl (%edx),%edx
  800841:	29 d0                	sub    %edx,%eax
  800843:	eb 05                	jmp    80084a <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800845:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  80084a:	5b                   	pop    %ebx
  80084b:	5d                   	pop    %ebp
  80084c:	c3                   	ret    

0080084d <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  80084d:	55                   	push   %ebp
  80084e:	89 e5                	mov    %esp,%ebp
  800850:	8b 45 08             	mov    0x8(%ebp),%eax
  800853:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800857:	eb 07                	jmp    800860 <strchr+0x13>
		if (*s == c)
  800859:	38 ca                	cmp    %cl,%dl
  80085b:	74 0f                	je     80086c <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  80085d:	83 c0 01             	add    $0x1,%eax
  800860:	0f b6 10             	movzbl (%eax),%edx
  800863:	84 d2                	test   %dl,%dl
  800865:	75 f2                	jne    800859 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800867:	b8 00 00 00 00       	mov    $0x0,%eax
}
  80086c:	5d                   	pop    %ebp
  80086d:	c3                   	ret    

0080086e <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  80086e:	55                   	push   %ebp
  80086f:	89 e5                	mov    %esp,%ebp
  800871:	8b 45 08             	mov    0x8(%ebp),%eax
  800874:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800878:	eb 03                	jmp    80087d <strfind+0xf>
  80087a:	83 c0 01             	add    $0x1,%eax
  80087d:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  800880:	38 ca                	cmp    %cl,%dl
  800882:	74 04                	je     800888 <strfind+0x1a>
  800884:	84 d2                	test   %dl,%dl
  800886:	75 f2                	jne    80087a <strfind+0xc>
			break;
	return (char *) s;
}
  800888:	5d                   	pop    %ebp
  800889:	c3                   	ret    

0080088a <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  80088a:	55                   	push   %ebp
  80088b:	89 e5                	mov    %esp,%ebp
  80088d:	57                   	push   %edi
  80088e:	56                   	push   %esi
  80088f:	53                   	push   %ebx
  800890:	8b 7d 08             	mov    0x8(%ebp),%edi
  800893:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800896:	85 c9                	test   %ecx,%ecx
  800898:	74 36                	je     8008d0 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  80089a:	f7 c7 03 00 00 00    	test   $0x3,%edi
  8008a0:	75 28                	jne    8008ca <memset+0x40>
  8008a2:	f6 c1 03             	test   $0x3,%cl
  8008a5:	75 23                	jne    8008ca <memset+0x40>
		c &= 0xFF;
  8008a7:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  8008ab:	89 d3                	mov    %edx,%ebx
  8008ad:	c1 e3 08             	shl    $0x8,%ebx
  8008b0:	89 d6                	mov    %edx,%esi
  8008b2:	c1 e6 18             	shl    $0x18,%esi
  8008b5:	89 d0                	mov    %edx,%eax
  8008b7:	c1 e0 10             	shl    $0x10,%eax
  8008ba:	09 f0                	or     %esi,%eax
  8008bc:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  8008be:	89 d8                	mov    %ebx,%eax
  8008c0:	09 d0                	or     %edx,%eax
  8008c2:	c1 e9 02             	shr    $0x2,%ecx
  8008c5:	fc                   	cld    
  8008c6:	f3 ab                	rep stos %eax,%es:(%edi)
  8008c8:	eb 06                	jmp    8008d0 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  8008ca:	8b 45 0c             	mov    0xc(%ebp),%eax
  8008cd:	fc                   	cld    
  8008ce:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  8008d0:	89 f8                	mov    %edi,%eax
  8008d2:	5b                   	pop    %ebx
  8008d3:	5e                   	pop    %esi
  8008d4:	5f                   	pop    %edi
  8008d5:	5d                   	pop    %ebp
  8008d6:	c3                   	ret    

008008d7 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  8008d7:	55                   	push   %ebp
  8008d8:	89 e5                	mov    %esp,%ebp
  8008da:	57                   	push   %edi
  8008db:	56                   	push   %esi
  8008dc:	8b 45 08             	mov    0x8(%ebp),%eax
  8008df:	8b 75 0c             	mov    0xc(%ebp),%esi
  8008e2:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  8008e5:	39 c6                	cmp    %eax,%esi
  8008e7:	73 35                	jae    80091e <memmove+0x47>
  8008e9:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  8008ec:	39 d0                	cmp    %edx,%eax
  8008ee:	73 2e                	jae    80091e <memmove+0x47>
		s += n;
		d += n;
  8008f0:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  8008f3:	89 d6                	mov    %edx,%esi
  8008f5:	09 fe                	or     %edi,%esi
  8008f7:	f7 c6 03 00 00 00    	test   $0x3,%esi
  8008fd:	75 13                	jne    800912 <memmove+0x3b>
  8008ff:	f6 c1 03             	test   $0x3,%cl
  800902:	75 0e                	jne    800912 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  800904:	83 ef 04             	sub    $0x4,%edi
  800907:	8d 72 fc             	lea    -0x4(%edx),%esi
  80090a:	c1 e9 02             	shr    $0x2,%ecx
  80090d:	fd                   	std    
  80090e:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800910:	eb 09                	jmp    80091b <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800912:	83 ef 01             	sub    $0x1,%edi
  800915:	8d 72 ff             	lea    -0x1(%edx),%esi
  800918:	fd                   	std    
  800919:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  80091b:	fc                   	cld    
  80091c:	eb 1d                	jmp    80093b <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  80091e:	89 f2                	mov    %esi,%edx
  800920:	09 c2                	or     %eax,%edx
  800922:	f6 c2 03             	test   $0x3,%dl
  800925:	75 0f                	jne    800936 <memmove+0x5f>
  800927:	f6 c1 03             	test   $0x3,%cl
  80092a:	75 0a                	jne    800936 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  80092c:	c1 e9 02             	shr    $0x2,%ecx
  80092f:	89 c7                	mov    %eax,%edi
  800931:	fc                   	cld    
  800932:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800934:	eb 05                	jmp    80093b <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800936:	89 c7                	mov    %eax,%edi
  800938:	fc                   	cld    
  800939:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  80093b:	5e                   	pop    %esi
  80093c:	5f                   	pop    %edi
  80093d:	5d                   	pop    %ebp
  80093e:	c3                   	ret    

0080093f <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  80093f:	55                   	push   %ebp
  800940:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  800942:	ff 75 10             	pushl  0x10(%ebp)
  800945:	ff 75 0c             	pushl  0xc(%ebp)
  800948:	ff 75 08             	pushl  0x8(%ebp)
  80094b:	e8 87 ff ff ff       	call   8008d7 <memmove>
}
  800950:	c9                   	leave  
  800951:	c3                   	ret    

00800952 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800952:	55                   	push   %ebp
  800953:	89 e5                	mov    %esp,%ebp
  800955:	56                   	push   %esi
  800956:	53                   	push   %ebx
  800957:	8b 45 08             	mov    0x8(%ebp),%eax
  80095a:	8b 55 0c             	mov    0xc(%ebp),%edx
  80095d:	89 c6                	mov    %eax,%esi
  80095f:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800962:	eb 1a                	jmp    80097e <memcmp+0x2c>
		if (*s1 != *s2)
  800964:	0f b6 08             	movzbl (%eax),%ecx
  800967:	0f b6 1a             	movzbl (%edx),%ebx
  80096a:	38 d9                	cmp    %bl,%cl
  80096c:	74 0a                	je     800978 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  80096e:	0f b6 c1             	movzbl %cl,%eax
  800971:	0f b6 db             	movzbl %bl,%ebx
  800974:	29 d8                	sub    %ebx,%eax
  800976:	eb 0f                	jmp    800987 <memcmp+0x35>
		s1++, s2++;
  800978:	83 c0 01             	add    $0x1,%eax
  80097b:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  80097e:	39 f0                	cmp    %esi,%eax
  800980:	75 e2                	jne    800964 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800982:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800987:	5b                   	pop    %ebx
  800988:	5e                   	pop    %esi
  800989:	5d                   	pop    %ebp
  80098a:	c3                   	ret    

0080098b <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  80098b:	55                   	push   %ebp
  80098c:	89 e5                	mov    %esp,%ebp
  80098e:	53                   	push   %ebx
  80098f:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  800992:	89 c1                	mov    %eax,%ecx
  800994:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  800997:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  80099b:	eb 0a                	jmp    8009a7 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  80099d:	0f b6 10             	movzbl (%eax),%edx
  8009a0:	39 da                	cmp    %ebx,%edx
  8009a2:	74 07                	je     8009ab <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  8009a4:	83 c0 01             	add    $0x1,%eax
  8009a7:	39 c8                	cmp    %ecx,%eax
  8009a9:	72 f2                	jb     80099d <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  8009ab:	5b                   	pop    %ebx
  8009ac:	5d                   	pop    %ebp
  8009ad:	c3                   	ret    

008009ae <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  8009ae:	55                   	push   %ebp
  8009af:	89 e5                	mov    %esp,%ebp
  8009b1:	57                   	push   %edi
  8009b2:	56                   	push   %esi
  8009b3:	53                   	push   %ebx
  8009b4:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8009b7:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  8009ba:	eb 03                	jmp    8009bf <strtol+0x11>
		s++;
  8009bc:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  8009bf:	0f b6 01             	movzbl (%ecx),%eax
  8009c2:	3c 20                	cmp    $0x20,%al
  8009c4:	74 f6                	je     8009bc <strtol+0xe>
  8009c6:	3c 09                	cmp    $0x9,%al
  8009c8:	74 f2                	je     8009bc <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  8009ca:	3c 2b                	cmp    $0x2b,%al
  8009cc:	75 0a                	jne    8009d8 <strtol+0x2a>
		s++;
  8009ce:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  8009d1:	bf 00 00 00 00       	mov    $0x0,%edi
  8009d6:	eb 11                	jmp    8009e9 <strtol+0x3b>
  8009d8:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  8009dd:	3c 2d                	cmp    $0x2d,%al
  8009df:	75 08                	jne    8009e9 <strtol+0x3b>
		s++, neg = 1;
  8009e1:	83 c1 01             	add    $0x1,%ecx
  8009e4:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  8009e9:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  8009ef:	75 15                	jne    800a06 <strtol+0x58>
  8009f1:	80 39 30             	cmpb   $0x30,(%ecx)
  8009f4:	75 10                	jne    800a06 <strtol+0x58>
  8009f6:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  8009fa:	75 7c                	jne    800a78 <strtol+0xca>
		s += 2, base = 16;
  8009fc:	83 c1 02             	add    $0x2,%ecx
  8009ff:	bb 10 00 00 00       	mov    $0x10,%ebx
  800a04:	eb 16                	jmp    800a1c <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800a06:	85 db                	test   %ebx,%ebx
  800a08:	75 12                	jne    800a1c <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800a0a:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a0f:	80 39 30             	cmpb   $0x30,(%ecx)
  800a12:	75 08                	jne    800a1c <strtol+0x6e>
		s++, base = 8;
  800a14:	83 c1 01             	add    $0x1,%ecx
  800a17:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800a1c:	b8 00 00 00 00       	mov    $0x0,%eax
  800a21:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800a24:	0f b6 11             	movzbl (%ecx),%edx
  800a27:	8d 72 d0             	lea    -0x30(%edx),%esi
  800a2a:	89 f3                	mov    %esi,%ebx
  800a2c:	80 fb 09             	cmp    $0x9,%bl
  800a2f:	77 08                	ja     800a39 <strtol+0x8b>
			dig = *s - '0';
  800a31:	0f be d2             	movsbl %dl,%edx
  800a34:	83 ea 30             	sub    $0x30,%edx
  800a37:	eb 22                	jmp    800a5b <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800a39:	8d 72 9f             	lea    -0x61(%edx),%esi
  800a3c:	89 f3                	mov    %esi,%ebx
  800a3e:	80 fb 19             	cmp    $0x19,%bl
  800a41:	77 08                	ja     800a4b <strtol+0x9d>
			dig = *s - 'a' + 10;
  800a43:	0f be d2             	movsbl %dl,%edx
  800a46:	83 ea 57             	sub    $0x57,%edx
  800a49:	eb 10                	jmp    800a5b <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800a4b:	8d 72 bf             	lea    -0x41(%edx),%esi
  800a4e:	89 f3                	mov    %esi,%ebx
  800a50:	80 fb 19             	cmp    $0x19,%bl
  800a53:	77 16                	ja     800a6b <strtol+0xbd>
			dig = *s - 'A' + 10;
  800a55:	0f be d2             	movsbl %dl,%edx
  800a58:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800a5b:	3b 55 10             	cmp    0x10(%ebp),%edx
  800a5e:	7d 0b                	jge    800a6b <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800a60:	83 c1 01             	add    $0x1,%ecx
  800a63:	0f af 45 10          	imul   0x10(%ebp),%eax
  800a67:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800a69:	eb b9                	jmp    800a24 <strtol+0x76>

	if (endptr)
  800a6b:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800a6f:	74 0d                	je     800a7e <strtol+0xd0>
		*endptr = (char *) s;
  800a71:	8b 75 0c             	mov    0xc(%ebp),%esi
  800a74:	89 0e                	mov    %ecx,(%esi)
  800a76:	eb 06                	jmp    800a7e <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a78:	85 db                	test   %ebx,%ebx
  800a7a:	74 98                	je     800a14 <strtol+0x66>
  800a7c:	eb 9e                	jmp    800a1c <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800a7e:	89 c2                	mov    %eax,%edx
  800a80:	f7 da                	neg    %edx
  800a82:	85 ff                	test   %edi,%edi
  800a84:	0f 45 c2             	cmovne %edx,%eax
}
  800a87:	5b                   	pop    %ebx
  800a88:	5e                   	pop    %esi
  800a89:	5f                   	pop    %edi
  800a8a:	5d                   	pop    %ebp
  800a8b:	c3                   	ret    

00800a8c <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800a8c:	55                   	push   %ebp
  800a8d:	89 e5                	mov    %esp,%ebp
  800a8f:	57                   	push   %edi
  800a90:	56                   	push   %esi
  800a91:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800a92:	b8 00 00 00 00       	mov    $0x0,%eax
  800a97:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800a9a:	8b 55 08             	mov    0x8(%ebp),%edx
  800a9d:	89 c3                	mov    %eax,%ebx
  800a9f:	89 c7                	mov    %eax,%edi
  800aa1:	89 c6                	mov    %eax,%esi
  800aa3:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800aa5:	5b                   	pop    %ebx
  800aa6:	5e                   	pop    %esi
  800aa7:	5f                   	pop    %edi
  800aa8:	5d                   	pop    %ebp
  800aa9:	c3                   	ret    

00800aaa <sys_cgetc>:

int
sys_cgetc(void)
{
  800aaa:	55                   	push   %ebp
  800aab:	89 e5                	mov    %esp,%ebp
  800aad:	57                   	push   %edi
  800aae:	56                   	push   %esi
  800aaf:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800ab0:	ba 00 00 00 00       	mov    $0x0,%edx
  800ab5:	b8 01 00 00 00       	mov    $0x1,%eax
  800aba:	89 d1                	mov    %edx,%ecx
  800abc:	89 d3                	mov    %edx,%ebx
  800abe:	89 d7                	mov    %edx,%edi
  800ac0:	89 d6                	mov    %edx,%esi
  800ac2:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800ac4:	5b                   	pop    %ebx
  800ac5:	5e                   	pop    %esi
  800ac6:	5f                   	pop    %edi
  800ac7:	5d                   	pop    %ebp
  800ac8:	c3                   	ret    

00800ac9 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800ac9:	55                   	push   %ebp
  800aca:	89 e5                	mov    %esp,%ebp
  800acc:	57                   	push   %edi
  800acd:	56                   	push   %esi
  800ace:	53                   	push   %ebx
  800acf:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800ad2:	b9 00 00 00 00       	mov    $0x0,%ecx
  800ad7:	b8 03 00 00 00       	mov    $0x3,%eax
  800adc:	8b 55 08             	mov    0x8(%ebp),%edx
  800adf:	89 cb                	mov    %ecx,%ebx
  800ae1:	89 cf                	mov    %ecx,%edi
  800ae3:	89 ce                	mov    %ecx,%esi
  800ae5:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800ae7:	85 c0                	test   %eax,%eax
  800ae9:	7e 17                	jle    800b02 <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800aeb:	83 ec 0c             	sub    $0xc,%esp
  800aee:	50                   	push   %eax
  800aef:	6a 03                	push   $0x3
  800af1:	68 40 10 80 00       	push   $0x801040
  800af6:	6a 23                	push   $0x23
  800af8:	68 5d 10 80 00       	push   $0x80105d
  800afd:	e8 27 00 00 00       	call   800b29 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800b02:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800b05:	5b                   	pop    %ebx
  800b06:	5e                   	pop    %esi
  800b07:	5f                   	pop    %edi
  800b08:	5d                   	pop    %ebp
  800b09:	c3                   	ret    

00800b0a <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800b0a:	55                   	push   %ebp
  800b0b:	89 e5                	mov    %esp,%ebp
  800b0d:	57                   	push   %edi
  800b0e:	56                   	push   %esi
  800b0f:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b10:	ba 00 00 00 00       	mov    $0x0,%edx
  800b15:	b8 02 00 00 00       	mov    $0x2,%eax
  800b1a:	89 d1                	mov    %edx,%ecx
  800b1c:	89 d3                	mov    %edx,%ebx
  800b1e:	89 d7                	mov    %edx,%edi
  800b20:	89 d6                	mov    %edx,%esi
  800b22:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800b24:	5b                   	pop    %ebx
  800b25:	5e                   	pop    %esi
  800b26:	5f                   	pop    %edi
  800b27:	5d                   	pop    %ebp
  800b28:	c3                   	ret    

00800b29 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800b29:	55                   	push   %ebp
  800b2a:	89 e5                	mov    %esp,%ebp
  800b2c:	56                   	push   %esi
  800b2d:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800b2e:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800b31:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800b37:	e8 ce ff ff ff       	call   800b0a <sys_getenvid>
  800b3c:	83 ec 0c             	sub    $0xc,%esp
  800b3f:	ff 75 0c             	pushl  0xc(%ebp)
  800b42:	ff 75 08             	pushl  0x8(%ebp)
  800b45:	56                   	push   %esi
  800b46:	50                   	push   %eax
  800b47:	68 6c 10 80 00       	push   $0x80106c
  800b4c:	e8 f0 f5 ff ff       	call   800141 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800b51:	83 c4 18             	add    $0x18,%esp
  800b54:	53                   	push   %ebx
  800b55:	ff 75 10             	pushl  0x10(%ebp)
  800b58:	e8 93 f5 ff ff       	call   8000f0 <vcprintf>
	cprintf("\n");
  800b5d:	c7 04 24 0c 0e 80 00 	movl   $0x800e0c,(%esp)
  800b64:	e8 d8 f5 ff ff       	call   800141 <cprintf>
  800b69:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800b6c:	cc                   	int3   
  800b6d:	eb fd                	jmp    800b6c <_panic+0x43>
  800b6f:	90                   	nop

00800b70 <__udivdi3>:
  800b70:	55                   	push   %ebp
  800b71:	57                   	push   %edi
  800b72:	56                   	push   %esi
  800b73:	53                   	push   %ebx
  800b74:	83 ec 1c             	sub    $0x1c,%esp
  800b77:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  800b7b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  800b7f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  800b83:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800b87:	85 f6                	test   %esi,%esi
  800b89:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800b8d:	89 ca                	mov    %ecx,%edx
  800b8f:	89 f8                	mov    %edi,%eax
  800b91:	75 3d                	jne    800bd0 <__udivdi3+0x60>
  800b93:	39 cf                	cmp    %ecx,%edi
  800b95:	0f 87 c5 00 00 00    	ja     800c60 <__udivdi3+0xf0>
  800b9b:	85 ff                	test   %edi,%edi
  800b9d:	89 fd                	mov    %edi,%ebp
  800b9f:	75 0b                	jne    800bac <__udivdi3+0x3c>
  800ba1:	b8 01 00 00 00       	mov    $0x1,%eax
  800ba6:	31 d2                	xor    %edx,%edx
  800ba8:	f7 f7                	div    %edi
  800baa:	89 c5                	mov    %eax,%ebp
  800bac:	89 c8                	mov    %ecx,%eax
  800bae:	31 d2                	xor    %edx,%edx
  800bb0:	f7 f5                	div    %ebp
  800bb2:	89 c1                	mov    %eax,%ecx
  800bb4:	89 d8                	mov    %ebx,%eax
  800bb6:	89 cf                	mov    %ecx,%edi
  800bb8:	f7 f5                	div    %ebp
  800bba:	89 c3                	mov    %eax,%ebx
  800bbc:	89 d8                	mov    %ebx,%eax
  800bbe:	89 fa                	mov    %edi,%edx
  800bc0:	83 c4 1c             	add    $0x1c,%esp
  800bc3:	5b                   	pop    %ebx
  800bc4:	5e                   	pop    %esi
  800bc5:	5f                   	pop    %edi
  800bc6:	5d                   	pop    %ebp
  800bc7:	c3                   	ret    
  800bc8:	90                   	nop
  800bc9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800bd0:	39 ce                	cmp    %ecx,%esi
  800bd2:	77 74                	ja     800c48 <__udivdi3+0xd8>
  800bd4:	0f bd fe             	bsr    %esi,%edi
  800bd7:	83 f7 1f             	xor    $0x1f,%edi
  800bda:	0f 84 98 00 00 00    	je     800c78 <__udivdi3+0x108>
  800be0:	bb 20 00 00 00       	mov    $0x20,%ebx
  800be5:	89 f9                	mov    %edi,%ecx
  800be7:	89 c5                	mov    %eax,%ebp
  800be9:	29 fb                	sub    %edi,%ebx
  800beb:	d3 e6                	shl    %cl,%esi
  800bed:	89 d9                	mov    %ebx,%ecx
  800bef:	d3 ed                	shr    %cl,%ebp
  800bf1:	89 f9                	mov    %edi,%ecx
  800bf3:	d3 e0                	shl    %cl,%eax
  800bf5:	09 ee                	or     %ebp,%esi
  800bf7:	89 d9                	mov    %ebx,%ecx
  800bf9:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800bfd:	89 d5                	mov    %edx,%ebp
  800bff:	8b 44 24 08          	mov    0x8(%esp),%eax
  800c03:	d3 ed                	shr    %cl,%ebp
  800c05:	89 f9                	mov    %edi,%ecx
  800c07:	d3 e2                	shl    %cl,%edx
  800c09:	89 d9                	mov    %ebx,%ecx
  800c0b:	d3 e8                	shr    %cl,%eax
  800c0d:	09 c2                	or     %eax,%edx
  800c0f:	89 d0                	mov    %edx,%eax
  800c11:	89 ea                	mov    %ebp,%edx
  800c13:	f7 f6                	div    %esi
  800c15:	89 d5                	mov    %edx,%ebp
  800c17:	89 c3                	mov    %eax,%ebx
  800c19:	f7 64 24 0c          	mull   0xc(%esp)
  800c1d:	39 d5                	cmp    %edx,%ebp
  800c1f:	72 10                	jb     800c31 <__udivdi3+0xc1>
  800c21:	8b 74 24 08          	mov    0x8(%esp),%esi
  800c25:	89 f9                	mov    %edi,%ecx
  800c27:	d3 e6                	shl    %cl,%esi
  800c29:	39 c6                	cmp    %eax,%esi
  800c2b:	73 07                	jae    800c34 <__udivdi3+0xc4>
  800c2d:	39 d5                	cmp    %edx,%ebp
  800c2f:	75 03                	jne    800c34 <__udivdi3+0xc4>
  800c31:	83 eb 01             	sub    $0x1,%ebx
  800c34:	31 ff                	xor    %edi,%edi
  800c36:	89 d8                	mov    %ebx,%eax
  800c38:	89 fa                	mov    %edi,%edx
  800c3a:	83 c4 1c             	add    $0x1c,%esp
  800c3d:	5b                   	pop    %ebx
  800c3e:	5e                   	pop    %esi
  800c3f:	5f                   	pop    %edi
  800c40:	5d                   	pop    %ebp
  800c41:	c3                   	ret    
  800c42:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800c48:	31 ff                	xor    %edi,%edi
  800c4a:	31 db                	xor    %ebx,%ebx
  800c4c:	89 d8                	mov    %ebx,%eax
  800c4e:	89 fa                	mov    %edi,%edx
  800c50:	83 c4 1c             	add    $0x1c,%esp
  800c53:	5b                   	pop    %ebx
  800c54:	5e                   	pop    %esi
  800c55:	5f                   	pop    %edi
  800c56:	5d                   	pop    %ebp
  800c57:	c3                   	ret    
  800c58:	90                   	nop
  800c59:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800c60:	89 d8                	mov    %ebx,%eax
  800c62:	f7 f7                	div    %edi
  800c64:	31 ff                	xor    %edi,%edi
  800c66:	89 c3                	mov    %eax,%ebx
  800c68:	89 d8                	mov    %ebx,%eax
  800c6a:	89 fa                	mov    %edi,%edx
  800c6c:	83 c4 1c             	add    $0x1c,%esp
  800c6f:	5b                   	pop    %ebx
  800c70:	5e                   	pop    %esi
  800c71:	5f                   	pop    %edi
  800c72:	5d                   	pop    %ebp
  800c73:	c3                   	ret    
  800c74:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800c78:	39 ce                	cmp    %ecx,%esi
  800c7a:	72 0c                	jb     800c88 <__udivdi3+0x118>
  800c7c:	31 db                	xor    %ebx,%ebx
  800c7e:	3b 44 24 08          	cmp    0x8(%esp),%eax
  800c82:	0f 87 34 ff ff ff    	ja     800bbc <__udivdi3+0x4c>
  800c88:	bb 01 00 00 00       	mov    $0x1,%ebx
  800c8d:	e9 2a ff ff ff       	jmp    800bbc <__udivdi3+0x4c>
  800c92:	66 90                	xchg   %ax,%ax
  800c94:	66 90                	xchg   %ax,%ax
  800c96:	66 90                	xchg   %ax,%ax
  800c98:	66 90                	xchg   %ax,%ax
  800c9a:	66 90                	xchg   %ax,%ax
  800c9c:	66 90                	xchg   %ax,%ax
  800c9e:	66 90                	xchg   %ax,%ax

00800ca0 <__umoddi3>:
  800ca0:	55                   	push   %ebp
  800ca1:	57                   	push   %edi
  800ca2:	56                   	push   %esi
  800ca3:	53                   	push   %ebx
  800ca4:	83 ec 1c             	sub    $0x1c,%esp
  800ca7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  800cab:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  800caf:	8b 74 24 34          	mov    0x34(%esp),%esi
  800cb3:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800cb7:	85 d2                	test   %edx,%edx
  800cb9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800cbd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800cc1:	89 f3                	mov    %esi,%ebx
  800cc3:	89 3c 24             	mov    %edi,(%esp)
  800cc6:	89 74 24 04          	mov    %esi,0x4(%esp)
  800cca:	75 1c                	jne    800ce8 <__umoddi3+0x48>
  800ccc:	39 f7                	cmp    %esi,%edi
  800cce:	76 50                	jbe    800d20 <__umoddi3+0x80>
  800cd0:	89 c8                	mov    %ecx,%eax
  800cd2:	89 f2                	mov    %esi,%edx
  800cd4:	f7 f7                	div    %edi
  800cd6:	89 d0                	mov    %edx,%eax
  800cd8:	31 d2                	xor    %edx,%edx
  800cda:	83 c4 1c             	add    $0x1c,%esp
  800cdd:	5b                   	pop    %ebx
  800cde:	5e                   	pop    %esi
  800cdf:	5f                   	pop    %edi
  800ce0:	5d                   	pop    %ebp
  800ce1:	c3                   	ret    
  800ce2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800ce8:	39 f2                	cmp    %esi,%edx
  800cea:	89 d0                	mov    %edx,%eax
  800cec:	77 52                	ja     800d40 <__umoddi3+0xa0>
  800cee:	0f bd ea             	bsr    %edx,%ebp
  800cf1:	83 f5 1f             	xor    $0x1f,%ebp
  800cf4:	75 5a                	jne    800d50 <__umoddi3+0xb0>
  800cf6:	3b 54 24 04          	cmp    0x4(%esp),%edx
  800cfa:	0f 82 e0 00 00 00    	jb     800de0 <__umoddi3+0x140>
  800d00:	39 0c 24             	cmp    %ecx,(%esp)
  800d03:	0f 86 d7 00 00 00    	jbe    800de0 <__umoddi3+0x140>
  800d09:	8b 44 24 08          	mov    0x8(%esp),%eax
  800d0d:	8b 54 24 04          	mov    0x4(%esp),%edx
  800d11:	83 c4 1c             	add    $0x1c,%esp
  800d14:	5b                   	pop    %ebx
  800d15:	5e                   	pop    %esi
  800d16:	5f                   	pop    %edi
  800d17:	5d                   	pop    %ebp
  800d18:	c3                   	ret    
  800d19:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800d20:	85 ff                	test   %edi,%edi
  800d22:	89 fd                	mov    %edi,%ebp
  800d24:	75 0b                	jne    800d31 <__umoddi3+0x91>
  800d26:	b8 01 00 00 00       	mov    $0x1,%eax
  800d2b:	31 d2                	xor    %edx,%edx
  800d2d:	f7 f7                	div    %edi
  800d2f:	89 c5                	mov    %eax,%ebp
  800d31:	89 f0                	mov    %esi,%eax
  800d33:	31 d2                	xor    %edx,%edx
  800d35:	f7 f5                	div    %ebp
  800d37:	89 c8                	mov    %ecx,%eax
  800d39:	f7 f5                	div    %ebp
  800d3b:	89 d0                	mov    %edx,%eax
  800d3d:	eb 99                	jmp    800cd8 <__umoddi3+0x38>
  800d3f:	90                   	nop
  800d40:	89 c8                	mov    %ecx,%eax
  800d42:	89 f2                	mov    %esi,%edx
  800d44:	83 c4 1c             	add    $0x1c,%esp
  800d47:	5b                   	pop    %ebx
  800d48:	5e                   	pop    %esi
  800d49:	5f                   	pop    %edi
  800d4a:	5d                   	pop    %ebp
  800d4b:	c3                   	ret    
  800d4c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800d50:	8b 34 24             	mov    (%esp),%esi
  800d53:	bf 20 00 00 00       	mov    $0x20,%edi
  800d58:	89 e9                	mov    %ebp,%ecx
  800d5a:	29 ef                	sub    %ebp,%edi
  800d5c:	d3 e0                	shl    %cl,%eax
  800d5e:	89 f9                	mov    %edi,%ecx
  800d60:	89 f2                	mov    %esi,%edx
  800d62:	d3 ea                	shr    %cl,%edx
  800d64:	89 e9                	mov    %ebp,%ecx
  800d66:	09 c2                	or     %eax,%edx
  800d68:	89 d8                	mov    %ebx,%eax
  800d6a:	89 14 24             	mov    %edx,(%esp)
  800d6d:	89 f2                	mov    %esi,%edx
  800d6f:	d3 e2                	shl    %cl,%edx
  800d71:	89 f9                	mov    %edi,%ecx
  800d73:	89 54 24 04          	mov    %edx,0x4(%esp)
  800d77:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800d7b:	d3 e8                	shr    %cl,%eax
  800d7d:	89 e9                	mov    %ebp,%ecx
  800d7f:	89 c6                	mov    %eax,%esi
  800d81:	d3 e3                	shl    %cl,%ebx
  800d83:	89 f9                	mov    %edi,%ecx
  800d85:	89 d0                	mov    %edx,%eax
  800d87:	d3 e8                	shr    %cl,%eax
  800d89:	89 e9                	mov    %ebp,%ecx
  800d8b:	09 d8                	or     %ebx,%eax
  800d8d:	89 d3                	mov    %edx,%ebx
  800d8f:	89 f2                	mov    %esi,%edx
  800d91:	f7 34 24             	divl   (%esp)
  800d94:	89 d6                	mov    %edx,%esi
  800d96:	d3 e3                	shl    %cl,%ebx
  800d98:	f7 64 24 04          	mull   0x4(%esp)
  800d9c:	39 d6                	cmp    %edx,%esi
  800d9e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800da2:	89 d1                	mov    %edx,%ecx
  800da4:	89 c3                	mov    %eax,%ebx
  800da6:	72 08                	jb     800db0 <__umoddi3+0x110>
  800da8:	75 11                	jne    800dbb <__umoddi3+0x11b>
  800daa:	39 44 24 08          	cmp    %eax,0x8(%esp)
  800dae:	73 0b                	jae    800dbb <__umoddi3+0x11b>
  800db0:	2b 44 24 04          	sub    0x4(%esp),%eax
  800db4:	1b 14 24             	sbb    (%esp),%edx
  800db7:	89 d1                	mov    %edx,%ecx
  800db9:	89 c3                	mov    %eax,%ebx
  800dbb:	8b 54 24 08          	mov    0x8(%esp),%edx
  800dbf:	29 da                	sub    %ebx,%edx
  800dc1:	19 ce                	sbb    %ecx,%esi
  800dc3:	89 f9                	mov    %edi,%ecx
  800dc5:	89 f0                	mov    %esi,%eax
  800dc7:	d3 e0                	shl    %cl,%eax
  800dc9:	89 e9                	mov    %ebp,%ecx
  800dcb:	d3 ea                	shr    %cl,%edx
  800dcd:	89 e9                	mov    %ebp,%ecx
  800dcf:	d3 ee                	shr    %cl,%esi
  800dd1:	09 d0                	or     %edx,%eax
  800dd3:	89 f2                	mov    %esi,%edx
  800dd5:	83 c4 1c             	add    $0x1c,%esp
  800dd8:	5b                   	pop    %ebx
  800dd9:	5e                   	pop    %esi
  800dda:	5f                   	pop    %edi
  800ddb:	5d                   	pop    %ebp
  800ddc:	c3                   	ret    
  800ddd:	8d 76 00             	lea    0x0(%esi),%esi
  800de0:	29 f9                	sub    %edi,%ecx
  800de2:	19 d6                	sbb    %edx,%esi
  800de4:	89 74 24 04          	mov    %esi,0x4(%esp)
  800de8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800dec:	e9 18 ff ff ff       	jmp    800d09 <__umoddi3+0x69>
