
obj/user/faultread：     文件格式 elf32-i386


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
  80002c:	e8 1d 00 00 00       	call   80004e <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 10             	sub    $0x10,%esp
	cprintf("I read %08x from location 0!\n", *(unsigned*)0);
  800039:	ff 35 00 00 00 00    	pushl  0x0
  80003f:	68 00 0e 80 00       	push   $0x800e00
  800044:	e8 e8 00 00 00       	call   800131 <cprintf>
}
  800049:	83 c4 10             	add    $0x10,%esp
  80004c:	c9                   	leave  
  80004d:	c3                   	ret    

0080004e <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  80004e:	55                   	push   %ebp
  80004f:	89 e5                	mov    %esp,%ebp
  800051:	56                   	push   %esi
  800052:	53                   	push   %ebx
  800053:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800056:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	envid_t envid = sys_getenvid();
  800059:	e8 9c 0a 00 00       	call   800afa <sys_getenvid>
	thisenv = envs;
  80005e:	c7 05 04 20 80 00 00 	movl   $0xeec00000,0x802004
  800065:	00 c0 ee 
	// save the name of the program so that panic() can use it
	if (argc > 0)
  800068:	85 db                	test   %ebx,%ebx
  80006a:	7e 07                	jle    800073 <libmain+0x25>
		binaryname = argv[0];
  80006c:	8b 06                	mov    (%esi),%eax
  80006e:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  800073:	83 ec 08             	sub    $0x8,%esp
  800076:	56                   	push   %esi
  800077:	53                   	push   %ebx
  800078:	e8 b6 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  80007d:	e8 0a 00 00 00       	call   80008c <exit>
}
  800082:	83 c4 10             	add    $0x10,%esp
  800085:	8d 65 f8             	lea    -0x8(%ebp),%esp
  800088:	5b                   	pop    %ebx
  800089:	5e                   	pop    %esi
  80008a:	5d                   	pop    %ebp
  80008b:	c3                   	ret    

0080008c <exit>:

#include <inc/lib.h>

void
exit(void)
{
  80008c:	55                   	push   %ebp
  80008d:	89 e5                	mov    %esp,%ebp
  80008f:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  800092:	6a 00                	push   $0x0
  800094:	e8 20 0a 00 00       	call   800ab9 <sys_env_destroy>
}
  800099:	83 c4 10             	add    $0x10,%esp
  80009c:	c9                   	leave  
  80009d:	c3                   	ret    

0080009e <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  80009e:	55                   	push   %ebp
  80009f:	89 e5                	mov    %esp,%ebp
  8000a1:	53                   	push   %ebx
  8000a2:	83 ec 04             	sub    $0x4,%esp
  8000a5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8000a8:	8b 13                	mov    (%ebx),%edx
  8000aa:	8d 42 01             	lea    0x1(%edx),%eax
  8000ad:	89 03                	mov    %eax,(%ebx)
  8000af:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000b2:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8000b6:	3d ff 00 00 00       	cmp    $0xff,%eax
  8000bb:	75 1a                	jne    8000d7 <putch+0x39>
		sys_cputs(b->buf, b->idx);
  8000bd:	83 ec 08             	sub    $0x8,%esp
  8000c0:	68 ff 00 00 00       	push   $0xff
  8000c5:	8d 43 08             	lea    0x8(%ebx),%eax
  8000c8:	50                   	push   %eax
  8000c9:	e8 ae 09 00 00       	call   800a7c <sys_cputs>
		b->idx = 0;
  8000ce:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8000d4:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8000d7:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8000db:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8000de:	c9                   	leave  
  8000df:	c3                   	ret    

008000e0 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8000e0:	55                   	push   %ebp
  8000e1:	89 e5                	mov    %esp,%ebp
  8000e3:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8000e9:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8000f0:	00 00 00 
	b.cnt = 0;
  8000f3:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8000fa:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8000fd:	ff 75 0c             	pushl  0xc(%ebp)
  800100:	ff 75 08             	pushl  0x8(%ebp)
  800103:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800109:	50                   	push   %eax
  80010a:	68 9e 00 80 00       	push   $0x80009e
  80010f:	e8 1a 01 00 00       	call   80022e <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800114:	83 c4 08             	add    $0x8,%esp
  800117:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  80011d:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800123:	50                   	push   %eax
  800124:	e8 53 09 00 00       	call   800a7c <sys_cputs>

	return b.cnt;
}
  800129:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  80012f:	c9                   	leave  
  800130:	c3                   	ret    

00800131 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800131:	55                   	push   %ebp
  800132:	89 e5                	mov    %esp,%ebp
  800134:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800137:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  80013a:	50                   	push   %eax
  80013b:	ff 75 08             	pushl  0x8(%ebp)
  80013e:	e8 9d ff ff ff       	call   8000e0 <vcprintf>
	va_end(ap);

	return cnt;
}
  800143:	c9                   	leave  
  800144:	c3                   	ret    

00800145 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800145:	55                   	push   %ebp
  800146:	89 e5                	mov    %esp,%ebp
  800148:	57                   	push   %edi
  800149:	56                   	push   %esi
  80014a:	53                   	push   %ebx
  80014b:	83 ec 1c             	sub    $0x1c,%esp
  80014e:	89 c7                	mov    %eax,%edi
  800150:	89 d6                	mov    %edx,%esi
  800152:	8b 45 08             	mov    0x8(%ebp),%eax
  800155:	8b 55 0c             	mov    0xc(%ebp),%edx
  800158:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80015b:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  80015e:	8b 4d 10             	mov    0x10(%ebp),%ecx
  800161:	bb 00 00 00 00       	mov    $0x0,%ebx
  800166:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800169:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  80016c:	39 d3                	cmp    %edx,%ebx
  80016e:	72 05                	jb     800175 <printnum+0x30>
  800170:	39 45 10             	cmp    %eax,0x10(%ebp)
  800173:	77 45                	ja     8001ba <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800175:	83 ec 0c             	sub    $0xc,%esp
  800178:	ff 75 18             	pushl  0x18(%ebp)
  80017b:	8b 45 14             	mov    0x14(%ebp),%eax
  80017e:	8d 58 ff             	lea    -0x1(%eax),%ebx
  800181:	53                   	push   %ebx
  800182:	ff 75 10             	pushl  0x10(%ebp)
  800185:	83 ec 08             	sub    $0x8,%esp
  800188:	ff 75 e4             	pushl  -0x1c(%ebp)
  80018b:	ff 75 e0             	pushl  -0x20(%ebp)
  80018e:	ff 75 dc             	pushl  -0x24(%ebp)
  800191:	ff 75 d8             	pushl  -0x28(%ebp)
  800194:	e8 c7 09 00 00       	call   800b60 <__udivdi3>
  800199:	83 c4 18             	add    $0x18,%esp
  80019c:	52                   	push   %edx
  80019d:	50                   	push   %eax
  80019e:	89 f2                	mov    %esi,%edx
  8001a0:	89 f8                	mov    %edi,%eax
  8001a2:	e8 9e ff ff ff       	call   800145 <printnum>
  8001a7:	83 c4 20             	add    $0x20,%esp
  8001aa:	eb 18                	jmp    8001c4 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8001ac:	83 ec 08             	sub    $0x8,%esp
  8001af:	56                   	push   %esi
  8001b0:	ff 75 18             	pushl  0x18(%ebp)
  8001b3:	ff d7                	call   *%edi
  8001b5:	83 c4 10             	add    $0x10,%esp
  8001b8:	eb 03                	jmp    8001bd <printnum+0x78>
  8001ba:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8001bd:	83 eb 01             	sub    $0x1,%ebx
  8001c0:	85 db                	test   %ebx,%ebx
  8001c2:	7f e8                	jg     8001ac <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8001c4:	83 ec 08             	sub    $0x8,%esp
  8001c7:	56                   	push   %esi
  8001c8:	83 ec 04             	sub    $0x4,%esp
  8001cb:	ff 75 e4             	pushl  -0x1c(%ebp)
  8001ce:	ff 75 e0             	pushl  -0x20(%ebp)
  8001d1:	ff 75 dc             	pushl  -0x24(%ebp)
  8001d4:	ff 75 d8             	pushl  -0x28(%ebp)
  8001d7:	e8 b4 0a 00 00       	call   800c90 <__umoddi3>
  8001dc:	83 c4 14             	add    $0x14,%esp
  8001df:	0f be 80 28 0e 80 00 	movsbl 0x800e28(%eax),%eax
  8001e6:	50                   	push   %eax
  8001e7:	ff d7                	call   *%edi
}
  8001e9:	83 c4 10             	add    $0x10,%esp
  8001ec:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8001ef:	5b                   	pop    %ebx
  8001f0:	5e                   	pop    %esi
  8001f1:	5f                   	pop    %edi
  8001f2:	5d                   	pop    %ebp
  8001f3:	c3                   	ret    

008001f4 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8001f4:	55                   	push   %ebp
  8001f5:	89 e5                	mov    %esp,%ebp
  8001f7:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8001fa:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8001fe:	8b 10                	mov    (%eax),%edx
  800200:	3b 50 04             	cmp    0x4(%eax),%edx
  800203:	73 0a                	jae    80020f <sprintputch+0x1b>
		*b->buf++ = ch;
  800205:	8d 4a 01             	lea    0x1(%edx),%ecx
  800208:	89 08                	mov    %ecx,(%eax)
  80020a:	8b 45 08             	mov    0x8(%ebp),%eax
  80020d:	88 02                	mov    %al,(%edx)
}
  80020f:	5d                   	pop    %ebp
  800210:	c3                   	ret    

00800211 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800211:	55                   	push   %ebp
  800212:	89 e5                	mov    %esp,%ebp
  800214:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  800217:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  80021a:	50                   	push   %eax
  80021b:	ff 75 10             	pushl  0x10(%ebp)
  80021e:	ff 75 0c             	pushl  0xc(%ebp)
  800221:	ff 75 08             	pushl  0x8(%ebp)
  800224:	e8 05 00 00 00       	call   80022e <vprintfmt>
	va_end(ap);
}
  800229:	83 c4 10             	add    $0x10,%esp
  80022c:	c9                   	leave  
  80022d:	c3                   	ret    

0080022e <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  80022e:	55                   	push   %ebp
  80022f:	89 e5                	mov    %esp,%ebp
  800231:	57                   	push   %edi
  800232:	56                   	push   %esi
  800233:	53                   	push   %ebx
  800234:	83 ec 2c             	sub    $0x2c,%esp
  800237:	8b 75 08             	mov    0x8(%ebp),%esi
  80023a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80023d:	8b 7d 10             	mov    0x10(%ebp),%edi
  800240:	eb 12                	jmp    800254 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800242:	85 c0                	test   %eax,%eax
  800244:	0f 84 42 04 00 00    	je     80068c <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
  80024a:	83 ec 08             	sub    $0x8,%esp
  80024d:	53                   	push   %ebx
  80024e:	50                   	push   %eax
  80024f:	ff d6                	call   *%esi
  800251:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800254:	83 c7 01             	add    $0x1,%edi
  800257:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  80025b:	83 f8 25             	cmp    $0x25,%eax
  80025e:	75 e2                	jne    800242 <vprintfmt+0x14>
  800260:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  800264:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  80026b:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800272:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  800279:	b9 00 00 00 00       	mov    $0x0,%ecx
  80027e:	eb 07                	jmp    800287 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800280:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  800283:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800287:	8d 47 01             	lea    0x1(%edi),%eax
  80028a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  80028d:	0f b6 07             	movzbl (%edi),%eax
  800290:	0f b6 d0             	movzbl %al,%edx
  800293:	83 e8 23             	sub    $0x23,%eax
  800296:	3c 55                	cmp    $0x55,%al
  800298:	0f 87 d3 03 00 00    	ja     800671 <vprintfmt+0x443>
  80029e:	0f b6 c0             	movzbl %al,%eax
  8002a1:	ff 24 85 c0 0e 80 00 	jmp    *0x800ec0(,%eax,4)
  8002a8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  8002ab:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  8002af:	eb d6                	jmp    800287 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002b1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8002b4:	b8 00 00 00 00       	mov    $0x0,%eax
  8002b9:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  8002bc:	8d 04 80             	lea    (%eax,%eax,4),%eax
  8002bf:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
  8002c3:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
  8002c6:	8d 4a d0             	lea    -0x30(%edx),%ecx
  8002c9:	83 f9 09             	cmp    $0x9,%ecx
  8002cc:	77 3f                	ja     80030d <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8002ce:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8002d1:	eb e9                	jmp    8002bc <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8002d3:	8b 45 14             	mov    0x14(%ebp),%eax
  8002d6:	8b 00                	mov    (%eax),%eax
  8002d8:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8002db:	8b 45 14             	mov    0x14(%ebp),%eax
  8002de:	8d 40 04             	lea    0x4(%eax),%eax
  8002e1:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002e4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8002e7:	eb 2a                	jmp    800313 <vprintfmt+0xe5>
  8002e9:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8002ec:	85 c0                	test   %eax,%eax
  8002ee:	ba 00 00 00 00       	mov    $0x0,%edx
  8002f3:	0f 49 d0             	cmovns %eax,%edx
  8002f6:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002f9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8002fc:	eb 89                	jmp    800287 <vprintfmt+0x59>
  8002fe:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  800301:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  800308:	e9 7a ff ff ff       	jmp    800287 <vprintfmt+0x59>
  80030d:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  800310:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  800313:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800317:	0f 89 6a ff ff ff    	jns    800287 <vprintfmt+0x59>
				width = precision, precision = -1;
  80031d:	8b 45 d0             	mov    -0x30(%ebp),%eax
  800320:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800323:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  80032a:	e9 58 ff ff ff       	jmp    800287 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  80032f:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800332:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  800335:	e9 4d ff ff ff       	jmp    800287 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  80033a:	8b 45 14             	mov    0x14(%ebp),%eax
  80033d:	8d 78 04             	lea    0x4(%eax),%edi
  800340:	83 ec 08             	sub    $0x8,%esp
  800343:	53                   	push   %ebx
  800344:	ff 30                	pushl  (%eax)
  800346:	ff d6                	call   *%esi
			break;
  800348:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  80034b:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80034e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  800351:	e9 fe fe ff ff       	jmp    800254 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800356:	8b 45 14             	mov    0x14(%ebp),%eax
  800359:	8d 78 04             	lea    0x4(%eax),%edi
  80035c:	8b 00                	mov    (%eax),%eax
  80035e:	99                   	cltd   
  80035f:	31 d0                	xor    %edx,%eax
  800361:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800363:	83 f8 07             	cmp    $0x7,%eax
  800366:	7f 0b                	jg     800373 <vprintfmt+0x145>
  800368:	8b 14 85 20 10 80 00 	mov    0x801020(,%eax,4),%edx
  80036f:	85 d2                	test   %edx,%edx
  800371:	75 1b                	jne    80038e <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
  800373:	50                   	push   %eax
  800374:	68 40 0e 80 00       	push   $0x800e40
  800379:	53                   	push   %ebx
  80037a:	56                   	push   %esi
  80037b:	e8 91 fe ff ff       	call   800211 <printfmt>
  800380:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  800383:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800386:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  800389:	e9 c6 fe ff ff       	jmp    800254 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  80038e:	52                   	push   %edx
  80038f:	68 49 0e 80 00       	push   $0x800e49
  800394:	53                   	push   %ebx
  800395:	56                   	push   %esi
  800396:	e8 76 fe ff ff       	call   800211 <printfmt>
  80039b:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  80039e:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003a1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003a4:	e9 ab fe ff ff       	jmp    800254 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8003a9:	8b 45 14             	mov    0x14(%ebp),%eax
  8003ac:	83 c0 04             	add    $0x4,%eax
  8003af:	89 45 cc             	mov    %eax,-0x34(%ebp)
  8003b2:	8b 45 14             	mov    0x14(%ebp),%eax
  8003b5:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  8003b7:	85 ff                	test   %edi,%edi
  8003b9:	b8 39 0e 80 00       	mov    $0x800e39,%eax
  8003be:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  8003c1:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8003c5:	0f 8e 94 00 00 00    	jle    80045f <vprintfmt+0x231>
  8003cb:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  8003cf:	0f 84 98 00 00 00    	je     80046d <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
  8003d5:	83 ec 08             	sub    $0x8,%esp
  8003d8:	ff 75 d0             	pushl  -0x30(%ebp)
  8003db:	57                   	push   %edi
  8003dc:	e8 33 03 00 00       	call   800714 <strnlen>
  8003e1:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8003e4:	29 c1                	sub    %eax,%ecx
  8003e6:	89 4d c8             	mov    %ecx,-0x38(%ebp)
  8003e9:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  8003ec:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  8003f0:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8003f3:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  8003f6:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8003f8:	eb 0f                	jmp    800409 <vprintfmt+0x1db>
					putch(padc, putdat);
  8003fa:	83 ec 08             	sub    $0x8,%esp
  8003fd:	53                   	push   %ebx
  8003fe:	ff 75 e0             	pushl  -0x20(%ebp)
  800401:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800403:	83 ef 01             	sub    $0x1,%edi
  800406:	83 c4 10             	add    $0x10,%esp
  800409:	85 ff                	test   %edi,%edi
  80040b:	7f ed                	jg     8003fa <vprintfmt+0x1cc>
  80040d:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  800410:	8b 4d c8             	mov    -0x38(%ebp),%ecx
  800413:	85 c9                	test   %ecx,%ecx
  800415:	b8 00 00 00 00       	mov    $0x0,%eax
  80041a:	0f 49 c1             	cmovns %ecx,%eax
  80041d:	29 c1                	sub    %eax,%ecx
  80041f:	89 75 08             	mov    %esi,0x8(%ebp)
  800422:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800425:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800428:	89 cb                	mov    %ecx,%ebx
  80042a:	eb 4d                	jmp    800479 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  80042c:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800430:	74 1b                	je     80044d <vprintfmt+0x21f>
  800432:	0f be c0             	movsbl %al,%eax
  800435:	83 e8 20             	sub    $0x20,%eax
  800438:	83 f8 5e             	cmp    $0x5e,%eax
  80043b:	76 10                	jbe    80044d <vprintfmt+0x21f>
					putch('?', putdat);
  80043d:	83 ec 08             	sub    $0x8,%esp
  800440:	ff 75 0c             	pushl  0xc(%ebp)
  800443:	6a 3f                	push   $0x3f
  800445:	ff 55 08             	call   *0x8(%ebp)
  800448:	83 c4 10             	add    $0x10,%esp
  80044b:	eb 0d                	jmp    80045a <vprintfmt+0x22c>
				else
					putch(ch, putdat);
  80044d:	83 ec 08             	sub    $0x8,%esp
  800450:	ff 75 0c             	pushl  0xc(%ebp)
  800453:	52                   	push   %edx
  800454:	ff 55 08             	call   *0x8(%ebp)
  800457:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  80045a:	83 eb 01             	sub    $0x1,%ebx
  80045d:	eb 1a                	jmp    800479 <vprintfmt+0x24b>
  80045f:	89 75 08             	mov    %esi,0x8(%ebp)
  800462:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800465:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800468:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  80046b:	eb 0c                	jmp    800479 <vprintfmt+0x24b>
  80046d:	89 75 08             	mov    %esi,0x8(%ebp)
  800470:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800473:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800476:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800479:	83 c7 01             	add    $0x1,%edi
  80047c:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800480:	0f be d0             	movsbl %al,%edx
  800483:	85 d2                	test   %edx,%edx
  800485:	74 23                	je     8004aa <vprintfmt+0x27c>
  800487:	85 f6                	test   %esi,%esi
  800489:	78 a1                	js     80042c <vprintfmt+0x1fe>
  80048b:	83 ee 01             	sub    $0x1,%esi
  80048e:	79 9c                	jns    80042c <vprintfmt+0x1fe>
  800490:	89 df                	mov    %ebx,%edi
  800492:	8b 75 08             	mov    0x8(%ebp),%esi
  800495:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800498:	eb 18                	jmp    8004b2 <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  80049a:	83 ec 08             	sub    $0x8,%esp
  80049d:	53                   	push   %ebx
  80049e:	6a 20                	push   $0x20
  8004a0:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8004a2:	83 ef 01             	sub    $0x1,%edi
  8004a5:	83 c4 10             	add    $0x10,%esp
  8004a8:	eb 08                	jmp    8004b2 <vprintfmt+0x284>
  8004aa:	89 df                	mov    %ebx,%edi
  8004ac:	8b 75 08             	mov    0x8(%ebp),%esi
  8004af:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8004b2:	85 ff                	test   %edi,%edi
  8004b4:	7f e4                	jg     80049a <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8004b6:	8b 45 cc             	mov    -0x34(%ebp),%eax
  8004b9:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004bc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8004bf:	e9 90 fd ff ff       	jmp    800254 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8004c4:	83 f9 01             	cmp    $0x1,%ecx
  8004c7:	7e 19                	jle    8004e2 <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
  8004c9:	8b 45 14             	mov    0x14(%ebp),%eax
  8004cc:	8b 50 04             	mov    0x4(%eax),%edx
  8004cf:	8b 00                	mov    (%eax),%eax
  8004d1:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8004d4:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8004d7:	8b 45 14             	mov    0x14(%ebp),%eax
  8004da:	8d 40 08             	lea    0x8(%eax),%eax
  8004dd:	89 45 14             	mov    %eax,0x14(%ebp)
  8004e0:	eb 38                	jmp    80051a <vprintfmt+0x2ec>
	else if (lflag)
  8004e2:	85 c9                	test   %ecx,%ecx
  8004e4:	74 1b                	je     800501 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
  8004e6:	8b 45 14             	mov    0x14(%ebp),%eax
  8004e9:	8b 00                	mov    (%eax),%eax
  8004eb:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8004ee:	89 c1                	mov    %eax,%ecx
  8004f0:	c1 f9 1f             	sar    $0x1f,%ecx
  8004f3:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8004f6:	8b 45 14             	mov    0x14(%ebp),%eax
  8004f9:	8d 40 04             	lea    0x4(%eax),%eax
  8004fc:	89 45 14             	mov    %eax,0x14(%ebp)
  8004ff:	eb 19                	jmp    80051a <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
  800501:	8b 45 14             	mov    0x14(%ebp),%eax
  800504:	8b 00                	mov    (%eax),%eax
  800506:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800509:	89 c1                	mov    %eax,%ecx
  80050b:	c1 f9 1f             	sar    $0x1f,%ecx
  80050e:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  800511:	8b 45 14             	mov    0x14(%ebp),%eax
  800514:	8d 40 04             	lea    0x4(%eax),%eax
  800517:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  80051a:	8b 55 d8             	mov    -0x28(%ebp),%edx
  80051d:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800520:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800525:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800529:	0f 89 0e 01 00 00    	jns    80063d <vprintfmt+0x40f>
				putch('-', putdat);
  80052f:	83 ec 08             	sub    $0x8,%esp
  800532:	53                   	push   %ebx
  800533:	6a 2d                	push   $0x2d
  800535:	ff d6                	call   *%esi
				num = -(long long) num;
  800537:	8b 55 d8             	mov    -0x28(%ebp),%edx
  80053a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  80053d:	f7 da                	neg    %edx
  80053f:	83 d1 00             	adc    $0x0,%ecx
  800542:	f7 d9                	neg    %ecx
  800544:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  800547:	b8 0a 00 00 00       	mov    $0xa,%eax
  80054c:	e9 ec 00 00 00       	jmp    80063d <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800551:	83 f9 01             	cmp    $0x1,%ecx
  800554:	7e 18                	jle    80056e <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
  800556:	8b 45 14             	mov    0x14(%ebp),%eax
  800559:	8b 10                	mov    (%eax),%edx
  80055b:	8b 48 04             	mov    0x4(%eax),%ecx
  80055e:	8d 40 08             	lea    0x8(%eax),%eax
  800561:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800564:	b8 0a 00 00 00       	mov    $0xa,%eax
  800569:	e9 cf 00 00 00       	jmp    80063d <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  80056e:	85 c9                	test   %ecx,%ecx
  800570:	74 1a                	je     80058c <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
  800572:	8b 45 14             	mov    0x14(%ebp),%eax
  800575:	8b 10                	mov    (%eax),%edx
  800577:	b9 00 00 00 00       	mov    $0x0,%ecx
  80057c:	8d 40 04             	lea    0x4(%eax),%eax
  80057f:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800582:	b8 0a 00 00 00       	mov    $0xa,%eax
  800587:	e9 b1 00 00 00       	jmp    80063d <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  80058c:	8b 45 14             	mov    0x14(%ebp),%eax
  80058f:	8b 10                	mov    (%eax),%edx
  800591:	b9 00 00 00 00       	mov    $0x0,%ecx
  800596:	8d 40 04             	lea    0x4(%eax),%eax
  800599:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  80059c:	b8 0a 00 00 00       	mov    $0xa,%eax
  8005a1:	e9 97 00 00 00       	jmp    80063d <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
  8005a6:	83 ec 08             	sub    $0x8,%esp
  8005a9:	53                   	push   %ebx
  8005aa:	6a 58                	push   $0x58
  8005ac:	ff d6                	call   *%esi
			putch('X', putdat);
  8005ae:	83 c4 08             	add    $0x8,%esp
  8005b1:	53                   	push   %ebx
  8005b2:	6a 58                	push   $0x58
  8005b4:	ff d6                	call   *%esi
			putch('X', putdat);
  8005b6:	83 c4 08             	add    $0x8,%esp
  8005b9:	53                   	push   %ebx
  8005ba:	6a 58                	push   $0x58
  8005bc:	ff d6                	call   *%esi
			break;
  8005be:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005c1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
  8005c4:	e9 8b fc ff ff       	jmp    800254 <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
  8005c9:	83 ec 08             	sub    $0x8,%esp
  8005cc:	53                   	push   %ebx
  8005cd:	6a 30                	push   $0x30
  8005cf:	ff d6                	call   *%esi
			putch('x', putdat);
  8005d1:	83 c4 08             	add    $0x8,%esp
  8005d4:	53                   	push   %ebx
  8005d5:	6a 78                	push   $0x78
  8005d7:	ff d6                	call   *%esi
			num = (unsigned long long)
  8005d9:	8b 45 14             	mov    0x14(%ebp),%eax
  8005dc:	8b 10                	mov    (%eax),%edx
  8005de:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  8005e3:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  8005e6:	8d 40 04             	lea    0x4(%eax),%eax
  8005e9:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  8005ec:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
  8005f1:	eb 4a                	jmp    80063d <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8005f3:	83 f9 01             	cmp    $0x1,%ecx
  8005f6:	7e 15                	jle    80060d <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
  8005f8:	8b 45 14             	mov    0x14(%ebp),%eax
  8005fb:	8b 10                	mov    (%eax),%edx
  8005fd:	8b 48 04             	mov    0x4(%eax),%ecx
  800600:	8d 40 08             	lea    0x8(%eax),%eax
  800603:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800606:	b8 10 00 00 00       	mov    $0x10,%eax
  80060b:	eb 30                	jmp    80063d <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  80060d:	85 c9                	test   %ecx,%ecx
  80060f:	74 17                	je     800628 <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
  800611:	8b 45 14             	mov    0x14(%ebp),%eax
  800614:	8b 10                	mov    (%eax),%edx
  800616:	b9 00 00 00 00       	mov    $0x0,%ecx
  80061b:	8d 40 04             	lea    0x4(%eax),%eax
  80061e:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800621:	b8 10 00 00 00       	mov    $0x10,%eax
  800626:	eb 15                	jmp    80063d <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  800628:	8b 45 14             	mov    0x14(%ebp),%eax
  80062b:	8b 10                	mov    (%eax),%edx
  80062d:	b9 00 00 00 00       	mov    $0x0,%ecx
  800632:	8d 40 04             	lea    0x4(%eax),%eax
  800635:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800638:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
  80063d:	83 ec 0c             	sub    $0xc,%esp
  800640:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  800644:	57                   	push   %edi
  800645:	ff 75 e0             	pushl  -0x20(%ebp)
  800648:	50                   	push   %eax
  800649:	51                   	push   %ecx
  80064a:	52                   	push   %edx
  80064b:	89 da                	mov    %ebx,%edx
  80064d:	89 f0                	mov    %esi,%eax
  80064f:	e8 f1 fa ff ff       	call   800145 <printnum>
			break;
  800654:	83 c4 20             	add    $0x20,%esp
  800657:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80065a:	e9 f5 fb ff ff       	jmp    800254 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  80065f:	83 ec 08             	sub    $0x8,%esp
  800662:	53                   	push   %ebx
  800663:	52                   	push   %edx
  800664:	ff d6                	call   *%esi
			break;
  800666:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800669:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  80066c:	e9 e3 fb ff ff       	jmp    800254 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  800671:	83 ec 08             	sub    $0x8,%esp
  800674:	53                   	push   %ebx
  800675:	6a 25                	push   $0x25
  800677:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800679:	83 c4 10             	add    $0x10,%esp
  80067c:	eb 03                	jmp    800681 <vprintfmt+0x453>
  80067e:	83 ef 01             	sub    $0x1,%edi
  800681:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800685:	75 f7                	jne    80067e <vprintfmt+0x450>
  800687:	e9 c8 fb ff ff       	jmp    800254 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  80068c:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80068f:	5b                   	pop    %ebx
  800690:	5e                   	pop    %esi
  800691:	5f                   	pop    %edi
  800692:	5d                   	pop    %ebp
  800693:	c3                   	ret    

00800694 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800694:	55                   	push   %ebp
  800695:	89 e5                	mov    %esp,%ebp
  800697:	83 ec 18             	sub    $0x18,%esp
  80069a:	8b 45 08             	mov    0x8(%ebp),%eax
  80069d:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  8006a0:	89 45 ec             	mov    %eax,-0x14(%ebp)
  8006a3:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  8006a7:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  8006aa:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8006b1:	85 c0                	test   %eax,%eax
  8006b3:	74 26                	je     8006db <vsnprintf+0x47>
  8006b5:	85 d2                	test   %edx,%edx
  8006b7:	7e 22                	jle    8006db <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  8006b9:	ff 75 14             	pushl  0x14(%ebp)
  8006bc:	ff 75 10             	pushl  0x10(%ebp)
  8006bf:	8d 45 ec             	lea    -0x14(%ebp),%eax
  8006c2:	50                   	push   %eax
  8006c3:	68 f4 01 80 00       	push   $0x8001f4
  8006c8:	e8 61 fb ff ff       	call   80022e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  8006cd:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8006d0:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  8006d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8006d6:	83 c4 10             	add    $0x10,%esp
  8006d9:	eb 05                	jmp    8006e0 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  8006db:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  8006e0:	c9                   	leave  
  8006e1:	c3                   	ret    

008006e2 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  8006e2:	55                   	push   %ebp
  8006e3:	89 e5                	mov    %esp,%ebp
  8006e5:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  8006e8:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  8006eb:	50                   	push   %eax
  8006ec:	ff 75 10             	pushl  0x10(%ebp)
  8006ef:	ff 75 0c             	pushl  0xc(%ebp)
  8006f2:	ff 75 08             	pushl  0x8(%ebp)
  8006f5:	e8 9a ff ff ff       	call   800694 <vsnprintf>
	va_end(ap);

	return rc;
}
  8006fa:	c9                   	leave  
  8006fb:	c3                   	ret    

008006fc <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  8006fc:	55                   	push   %ebp
  8006fd:	89 e5                	mov    %esp,%ebp
  8006ff:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800702:	b8 00 00 00 00       	mov    $0x0,%eax
  800707:	eb 03                	jmp    80070c <strlen+0x10>
		n++;
  800709:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  80070c:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800710:	75 f7                	jne    800709 <strlen+0xd>
		n++;
	return n;
}
  800712:	5d                   	pop    %ebp
  800713:	c3                   	ret    

00800714 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800714:	55                   	push   %ebp
  800715:	89 e5                	mov    %esp,%ebp
  800717:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80071a:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80071d:	ba 00 00 00 00       	mov    $0x0,%edx
  800722:	eb 03                	jmp    800727 <strnlen+0x13>
		n++;
  800724:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800727:	39 c2                	cmp    %eax,%edx
  800729:	74 08                	je     800733 <strnlen+0x1f>
  80072b:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  80072f:	75 f3                	jne    800724 <strnlen+0x10>
  800731:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  800733:	5d                   	pop    %ebp
  800734:	c3                   	ret    

00800735 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800735:	55                   	push   %ebp
  800736:	89 e5                	mov    %esp,%ebp
  800738:	53                   	push   %ebx
  800739:	8b 45 08             	mov    0x8(%ebp),%eax
  80073c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  80073f:	89 c2                	mov    %eax,%edx
  800741:	83 c2 01             	add    $0x1,%edx
  800744:	83 c1 01             	add    $0x1,%ecx
  800747:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  80074b:	88 5a ff             	mov    %bl,-0x1(%edx)
  80074e:	84 db                	test   %bl,%bl
  800750:	75 ef                	jne    800741 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800752:	5b                   	pop    %ebx
  800753:	5d                   	pop    %ebp
  800754:	c3                   	ret    

00800755 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800755:	55                   	push   %ebp
  800756:	89 e5                	mov    %esp,%ebp
  800758:	53                   	push   %ebx
  800759:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  80075c:	53                   	push   %ebx
  80075d:	e8 9a ff ff ff       	call   8006fc <strlen>
  800762:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  800765:	ff 75 0c             	pushl  0xc(%ebp)
  800768:	01 d8                	add    %ebx,%eax
  80076a:	50                   	push   %eax
  80076b:	e8 c5 ff ff ff       	call   800735 <strcpy>
	return dst;
}
  800770:	89 d8                	mov    %ebx,%eax
  800772:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800775:	c9                   	leave  
  800776:	c3                   	ret    

00800777 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800777:	55                   	push   %ebp
  800778:	89 e5                	mov    %esp,%ebp
  80077a:	56                   	push   %esi
  80077b:	53                   	push   %ebx
  80077c:	8b 75 08             	mov    0x8(%ebp),%esi
  80077f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800782:	89 f3                	mov    %esi,%ebx
  800784:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800787:	89 f2                	mov    %esi,%edx
  800789:	eb 0f                	jmp    80079a <strncpy+0x23>
		*dst++ = *src;
  80078b:	83 c2 01             	add    $0x1,%edx
  80078e:	0f b6 01             	movzbl (%ecx),%eax
  800791:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800794:	80 39 01             	cmpb   $0x1,(%ecx)
  800797:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  80079a:	39 da                	cmp    %ebx,%edx
  80079c:	75 ed                	jne    80078b <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  80079e:	89 f0                	mov    %esi,%eax
  8007a0:	5b                   	pop    %ebx
  8007a1:	5e                   	pop    %esi
  8007a2:	5d                   	pop    %ebp
  8007a3:	c3                   	ret    

008007a4 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  8007a4:	55                   	push   %ebp
  8007a5:	89 e5                	mov    %esp,%ebp
  8007a7:	56                   	push   %esi
  8007a8:	53                   	push   %ebx
  8007a9:	8b 75 08             	mov    0x8(%ebp),%esi
  8007ac:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8007af:	8b 55 10             	mov    0x10(%ebp),%edx
  8007b2:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  8007b4:	85 d2                	test   %edx,%edx
  8007b6:	74 21                	je     8007d9 <strlcpy+0x35>
  8007b8:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  8007bc:	89 f2                	mov    %esi,%edx
  8007be:	eb 09                	jmp    8007c9 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  8007c0:	83 c2 01             	add    $0x1,%edx
  8007c3:	83 c1 01             	add    $0x1,%ecx
  8007c6:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  8007c9:	39 c2                	cmp    %eax,%edx
  8007cb:	74 09                	je     8007d6 <strlcpy+0x32>
  8007cd:	0f b6 19             	movzbl (%ecx),%ebx
  8007d0:	84 db                	test   %bl,%bl
  8007d2:	75 ec                	jne    8007c0 <strlcpy+0x1c>
  8007d4:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  8007d6:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  8007d9:	29 f0                	sub    %esi,%eax
}
  8007db:	5b                   	pop    %ebx
  8007dc:	5e                   	pop    %esi
  8007dd:	5d                   	pop    %ebp
  8007de:	c3                   	ret    

008007df <strcmp>:

int
strcmp(const char *p, const char *q)
{
  8007df:	55                   	push   %ebp
  8007e0:	89 e5                	mov    %esp,%ebp
  8007e2:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8007e5:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  8007e8:	eb 06                	jmp    8007f0 <strcmp+0x11>
		p++, q++;
  8007ea:	83 c1 01             	add    $0x1,%ecx
  8007ed:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  8007f0:	0f b6 01             	movzbl (%ecx),%eax
  8007f3:	84 c0                	test   %al,%al
  8007f5:	74 04                	je     8007fb <strcmp+0x1c>
  8007f7:	3a 02                	cmp    (%edx),%al
  8007f9:	74 ef                	je     8007ea <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  8007fb:	0f b6 c0             	movzbl %al,%eax
  8007fe:	0f b6 12             	movzbl (%edx),%edx
  800801:	29 d0                	sub    %edx,%eax
}
  800803:	5d                   	pop    %ebp
  800804:	c3                   	ret    

00800805 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800805:	55                   	push   %ebp
  800806:	89 e5                	mov    %esp,%ebp
  800808:	53                   	push   %ebx
  800809:	8b 45 08             	mov    0x8(%ebp),%eax
  80080c:	8b 55 0c             	mov    0xc(%ebp),%edx
  80080f:	89 c3                	mov    %eax,%ebx
  800811:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800814:	eb 06                	jmp    80081c <strncmp+0x17>
		n--, p++, q++;
  800816:	83 c0 01             	add    $0x1,%eax
  800819:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  80081c:	39 d8                	cmp    %ebx,%eax
  80081e:	74 15                	je     800835 <strncmp+0x30>
  800820:	0f b6 08             	movzbl (%eax),%ecx
  800823:	84 c9                	test   %cl,%cl
  800825:	74 04                	je     80082b <strncmp+0x26>
  800827:	3a 0a                	cmp    (%edx),%cl
  800829:	74 eb                	je     800816 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  80082b:	0f b6 00             	movzbl (%eax),%eax
  80082e:	0f b6 12             	movzbl (%edx),%edx
  800831:	29 d0                	sub    %edx,%eax
  800833:	eb 05                	jmp    80083a <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800835:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  80083a:	5b                   	pop    %ebx
  80083b:	5d                   	pop    %ebp
  80083c:	c3                   	ret    

0080083d <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  80083d:	55                   	push   %ebp
  80083e:	89 e5                	mov    %esp,%ebp
  800840:	8b 45 08             	mov    0x8(%ebp),%eax
  800843:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800847:	eb 07                	jmp    800850 <strchr+0x13>
		if (*s == c)
  800849:	38 ca                	cmp    %cl,%dl
  80084b:	74 0f                	je     80085c <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  80084d:	83 c0 01             	add    $0x1,%eax
  800850:	0f b6 10             	movzbl (%eax),%edx
  800853:	84 d2                	test   %dl,%dl
  800855:	75 f2                	jne    800849 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800857:	b8 00 00 00 00       	mov    $0x0,%eax
}
  80085c:	5d                   	pop    %ebp
  80085d:	c3                   	ret    

0080085e <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  80085e:	55                   	push   %ebp
  80085f:	89 e5                	mov    %esp,%ebp
  800861:	8b 45 08             	mov    0x8(%ebp),%eax
  800864:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800868:	eb 03                	jmp    80086d <strfind+0xf>
  80086a:	83 c0 01             	add    $0x1,%eax
  80086d:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  800870:	38 ca                	cmp    %cl,%dl
  800872:	74 04                	je     800878 <strfind+0x1a>
  800874:	84 d2                	test   %dl,%dl
  800876:	75 f2                	jne    80086a <strfind+0xc>
			break;
	return (char *) s;
}
  800878:	5d                   	pop    %ebp
  800879:	c3                   	ret    

0080087a <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  80087a:	55                   	push   %ebp
  80087b:	89 e5                	mov    %esp,%ebp
  80087d:	57                   	push   %edi
  80087e:	56                   	push   %esi
  80087f:	53                   	push   %ebx
  800880:	8b 7d 08             	mov    0x8(%ebp),%edi
  800883:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800886:	85 c9                	test   %ecx,%ecx
  800888:	74 36                	je     8008c0 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  80088a:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800890:	75 28                	jne    8008ba <memset+0x40>
  800892:	f6 c1 03             	test   $0x3,%cl
  800895:	75 23                	jne    8008ba <memset+0x40>
		c &= 0xFF;
  800897:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  80089b:	89 d3                	mov    %edx,%ebx
  80089d:	c1 e3 08             	shl    $0x8,%ebx
  8008a0:	89 d6                	mov    %edx,%esi
  8008a2:	c1 e6 18             	shl    $0x18,%esi
  8008a5:	89 d0                	mov    %edx,%eax
  8008a7:	c1 e0 10             	shl    $0x10,%eax
  8008aa:	09 f0                	or     %esi,%eax
  8008ac:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  8008ae:	89 d8                	mov    %ebx,%eax
  8008b0:	09 d0                	or     %edx,%eax
  8008b2:	c1 e9 02             	shr    $0x2,%ecx
  8008b5:	fc                   	cld    
  8008b6:	f3 ab                	rep stos %eax,%es:(%edi)
  8008b8:	eb 06                	jmp    8008c0 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  8008ba:	8b 45 0c             	mov    0xc(%ebp),%eax
  8008bd:	fc                   	cld    
  8008be:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  8008c0:	89 f8                	mov    %edi,%eax
  8008c2:	5b                   	pop    %ebx
  8008c3:	5e                   	pop    %esi
  8008c4:	5f                   	pop    %edi
  8008c5:	5d                   	pop    %ebp
  8008c6:	c3                   	ret    

008008c7 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  8008c7:	55                   	push   %ebp
  8008c8:	89 e5                	mov    %esp,%ebp
  8008ca:	57                   	push   %edi
  8008cb:	56                   	push   %esi
  8008cc:	8b 45 08             	mov    0x8(%ebp),%eax
  8008cf:	8b 75 0c             	mov    0xc(%ebp),%esi
  8008d2:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  8008d5:	39 c6                	cmp    %eax,%esi
  8008d7:	73 35                	jae    80090e <memmove+0x47>
  8008d9:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  8008dc:	39 d0                	cmp    %edx,%eax
  8008de:	73 2e                	jae    80090e <memmove+0x47>
		s += n;
		d += n;
  8008e0:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  8008e3:	89 d6                	mov    %edx,%esi
  8008e5:	09 fe                	or     %edi,%esi
  8008e7:	f7 c6 03 00 00 00    	test   $0x3,%esi
  8008ed:	75 13                	jne    800902 <memmove+0x3b>
  8008ef:	f6 c1 03             	test   $0x3,%cl
  8008f2:	75 0e                	jne    800902 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  8008f4:	83 ef 04             	sub    $0x4,%edi
  8008f7:	8d 72 fc             	lea    -0x4(%edx),%esi
  8008fa:	c1 e9 02             	shr    $0x2,%ecx
  8008fd:	fd                   	std    
  8008fe:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800900:	eb 09                	jmp    80090b <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800902:	83 ef 01             	sub    $0x1,%edi
  800905:	8d 72 ff             	lea    -0x1(%edx),%esi
  800908:	fd                   	std    
  800909:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  80090b:	fc                   	cld    
  80090c:	eb 1d                	jmp    80092b <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  80090e:	89 f2                	mov    %esi,%edx
  800910:	09 c2                	or     %eax,%edx
  800912:	f6 c2 03             	test   $0x3,%dl
  800915:	75 0f                	jne    800926 <memmove+0x5f>
  800917:	f6 c1 03             	test   $0x3,%cl
  80091a:	75 0a                	jne    800926 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  80091c:	c1 e9 02             	shr    $0x2,%ecx
  80091f:	89 c7                	mov    %eax,%edi
  800921:	fc                   	cld    
  800922:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800924:	eb 05                	jmp    80092b <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800926:	89 c7                	mov    %eax,%edi
  800928:	fc                   	cld    
  800929:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  80092b:	5e                   	pop    %esi
  80092c:	5f                   	pop    %edi
  80092d:	5d                   	pop    %ebp
  80092e:	c3                   	ret    

0080092f <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  80092f:	55                   	push   %ebp
  800930:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  800932:	ff 75 10             	pushl  0x10(%ebp)
  800935:	ff 75 0c             	pushl  0xc(%ebp)
  800938:	ff 75 08             	pushl  0x8(%ebp)
  80093b:	e8 87 ff ff ff       	call   8008c7 <memmove>
}
  800940:	c9                   	leave  
  800941:	c3                   	ret    

00800942 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800942:	55                   	push   %ebp
  800943:	89 e5                	mov    %esp,%ebp
  800945:	56                   	push   %esi
  800946:	53                   	push   %ebx
  800947:	8b 45 08             	mov    0x8(%ebp),%eax
  80094a:	8b 55 0c             	mov    0xc(%ebp),%edx
  80094d:	89 c6                	mov    %eax,%esi
  80094f:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800952:	eb 1a                	jmp    80096e <memcmp+0x2c>
		if (*s1 != *s2)
  800954:	0f b6 08             	movzbl (%eax),%ecx
  800957:	0f b6 1a             	movzbl (%edx),%ebx
  80095a:	38 d9                	cmp    %bl,%cl
  80095c:	74 0a                	je     800968 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  80095e:	0f b6 c1             	movzbl %cl,%eax
  800961:	0f b6 db             	movzbl %bl,%ebx
  800964:	29 d8                	sub    %ebx,%eax
  800966:	eb 0f                	jmp    800977 <memcmp+0x35>
		s1++, s2++;
  800968:	83 c0 01             	add    $0x1,%eax
  80096b:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  80096e:	39 f0                	cmp    %esi,%eax
  800970:	75 e2                	jne    800954 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800972:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800977:	5b                   	pop    %ebx
  800978:	5e                   	pop    %esi
  800979:	5d                   	pop    %ebp
  80097a:	c3                   	ret    

0080097b <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  80097b:	55                   	push   %ebp
  80097c:	89 e5                	mov    %esp,%ebp
  80097e:	53                   	push   %ebx
  80097f:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  800982:	89 c1                	mov    %eax,%ecx
  800984:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  800987:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  80098b:	eb 0a                	jmp    800997 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  80098d:	0f b6 10             	movzbl (%eax),%edx
  800990:	39 da                	cmp    %ebx,%edx
  800992:	74 07                	je     80099b <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800994:	83 c0 01             	add    $0x1,%eax
  800997:	39 c8                	cmp    %ecx,%eax
  800999:	72 f2                	jb     80098d <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  80099b:	5b                   	pop    %ebx
  80099c:	5d                   	pop    %ebp
  80099d:	c3                   	ret    

0080099e <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  80099e:	55                   	push   %ebp
  80099f:	89 e5                	mov    %esp,%ebp
  8009a1:	57                   	push   %edi
  8009a2:	56                   	push   %esi
  8009a3:	53                   	push   %ebx
  8009a4:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8009a7:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  8009aa:	eb 03                	jmp    8009af <strtol+0x11>
		s++;
  8009ac:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  8009af:	0f b6 01             	movzbl (%ecx),%eax
  8009b2:	3c 20                	cmp    $0x20,%al
  8009b4:	74 f6                	je     8009ac <strtol+0xe>
  8009b6:	3c 09                	cmp    $0x9,%al
  8009b8:	74 f2                	je     8009ac <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  8009ba:	3c 2b                	cmp    $0x2b,%al
  8009bc:	75 0a                	jne    8009c8 <strtol+0x2a>
		s++;
  8009be:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  8009c1:	bf 00 00 00 00       	mov    $0x0,%edi
  8009c6:	eb 11                	jmp    8009d9 <strtol+0x3b>
  8009c8:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  8009cd:	3c 2d                	cmp    $0x2d,%al
  8009cf:	75 08                	jne    8009d9 <strtol+0x3b>
		s++, neg = 1;
  8009d1:	83 c1 01             	add    $0x1,%ecx
  8009d4:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  8009d9:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  8009df:	75 15                	jne    8009f6 <strtol+0x58>
  8009e1:	80 39 30             	cmpb   $0x30,(%ecx)
  8009e4:	75 10                	jne    8009f6 <strtol+0x58>
  8009e6:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  8009ea:	75 7c                	jne    800a68 <strtol+0xca>
		s += 2, base = 16;
  8009ec:	83 c1 02             	add    $0x2,%ecx
  8009ef:	bb 10 00 00 00       	mov    $0x10,%ebx
  8009f4:	eb 16                	jmp    800a0c <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  8009f6:	85 db                	test   %ebx,%ebx
  8009f8:	75 12                	jne    800a0c <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  8009fa:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  8009ff:	80 39 30             	cmpb   $0x30,(%ecx)
  800a02:	75 08                	jne    800a0c <strtol+0x6e>
		s++, base = 8;
  800a04:	83 c1 01             	add    $0x1,%ecx
  800a07:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800a0c:	b8 00 00 00 00       	mov    $0x0,%eax
  800a11:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800a14:	0f b6 11             	movzbl (%ecx),%edx
  800a17:	8d 72 d0             	lea    -0x30(%edx),%esi
  800a1a:	89 f3                	mov    %esi,%ebx
  800a1c:	80 fb 09             	cmp    $0x9,%bl
  800a1f:	77 08                	ja     800a29 <strtol+0x8b>
			dig = *s - '0';
  800a21:	0f be d2             	movsbl %dl,%edx
  800a24:	83 ea 30             	sub    $0x30,%edx
  800a27:	eb 22                	jmp    800a4b <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800a29:	8d 72 9f             	lea    -0x61(%edx),%esi
  800a2c:	89 f3                	mov    %esi,%ebx
  800a2e:	80 fb 19             	cmp    $0x19,%bl
  800a31:	77 08                	ja     800a3b <strtol+0x9d>
			dig = *s - 'a' + 10;
  800a33:	0f be d2             	movsbl %dl,%edx
  800a36:	83 ea 57             	sub    $0x57,%edx
  800a39:	eb 10                	jmp    800a4b <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800a3b:	8d 72 bf             	lea    -0x41(%edx),%esi
  800a3e:	89 f3                	mov    %esi,%ebx
  800a40:	80 fb 19             	cmp    $0x19,%bl
  800a43:	77 16                	ja     800a5b <strtol+0xbd>
			dig = *s - 'A' + 10;
  800a45:	0f be d2             	movsbl %dl,%edx
  800a48:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800a4b:	3b 55 10             	cmp    0x10(%ebp),%edx
  800a4e:	7d 0b                	jge    800a5b <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800a50:	83 c1 01             	add    $0x1,%ecx
  800a53:	0f af 45 10          	imul   0x10(%ebp),%eax
  800a57:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800a59:	eb b9                	jmp    800a14 <strtol+0x76>

	if (endptr)
  800a5b:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800a5f:	74 0d                	je     800a6e <strtol+0xd0>
		*endptr = (char *) s;
  800a61:	8b 75 0c             	mov    0xc(%ebp),%esi
  800a64:	89 0e                	mov    %ecx,(%esi)
  800a66:	eb 06                	jmp    800a6e <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a68:	85 db                	test   %ebx,%ebx
  800a6a:	74 98                	je     800a04 <strtol+0x66>
  800a6c:	eb 9e                	jmp    800a0c <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800a6e:	89 c2                	mov    %eax,%edx
  800a70:	f7 da                	neg    %edx
  800a72:	85 ff                	test   %edi,%edi
  800a74:	0f 45 c2             	cmovne %edx,%eax
}
  800a77:	5b                   	pop    %ebx
  800a78:	5e                   	pop    %esi
  800a79:	5f                   	pop    %edi
  800a7a:	5d                   	pop    %ebp
  800a7b:	c3                   	ret    

00800a7c <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800a7c:	55                   	push   %ebp
  800a7d:	89 e5                	mov    %esp,%ebp
  800a7f:	57                   	push   %edi
  800a80:	56                   	push   %esi
  800a81:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800a82:	b8 00 00 00 00       	mov    $0x0,%eax
  800a87:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800a8a:	8b 55 08             	mov    0x8(%ebp),%edx
  800a8d:	89 c3                	mov    %eax,%ebx
  800a8f:	89 c7                	mov    %eax,%edi
  800a91:	89 c6                	mov    %eax,%esi
  800a93:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800a95:	5b                   	pop    %ebx
  800a96:	5e                   	pop    %esi
  800a97:	5f                   	pop    %edi
  800a98:	5d                   	pop    %ebp
  800a99:	c3                   	ret    

00800a9a <sys_cgetc>:

int
sys_cgetc(void)
{
  800a9a:	55                   	push   %ebp
  800a9b:	89 e5                	mov    %esp,%ebp
  800a9d:	57                   	push   %edi
  800a9e:	56                   	push   %esi
  800a9f:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800aa0:	ba 00 00 00 00       	mov    $0x0,%edx
  800aa5:	b8 01 00 00 00       	mov    $0x1,%eax
  800aaa:	89 d1                	mov    %edx,%ecx
  800aac:	89 d3                	mov    %edx,%ebx
  800aae:	89 d7                	mov    %edx,%edi
  800ab0:	89 d6                	mov    %edx,%esi
  800ab2:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800ab4:	5b                   	pop    %ebx
  800ab5:	5e                   	pop    %esi
  800ab6:	5f                   	pop    %edi
  800ab7:	5d                   	pop    %ebp
  800ab8:	c3                   	ret    

00800ab9 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800ab9:	55                   	push   %ebp
  800aba:	89 e5                	mov    %esp,%ebp
  800abc:	57                   	push   %edi
  800abd:	56                   	push   %esi
  800abe:	53                   	push   %ebx
  800abf:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800ac2:	b9 00 00 00 00       	mov    $0x0,%ecx
  800ac7:	b8 03 00 00 00       	mov    $0x3,%eax
  800acc:	8b 55 08             	mov    0x8(%ebp),%edx
  800acf:	89 cb                	mov    %ecx,%ebx
  800ad1:	89 cf                	mov    %ecx,%edi
  800ad3:	89 ce                	mov    %ecx,%esi
  800ad5:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800ad7:	85 c0                	test   %eax,%eax
  800ad9:	7e 17                	jle    800af2 <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800adb:	83 ec 0c             	sub    $0xc,%esp
  800ade:	50                   	push   %eax
  800adf:	6a 03                	push   $0x3
  800ae1:	68 40 10 80 00       	push   $0x801040
  800ae6:	6a 23                	push   $0x23
  800ae8:	68 5d 10 80 00       	push   $0x80105d
  800aed:	e8 27 00 00 00       	call   800b19 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800af2:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800af5:	5b                   	pop    %ebx
  800af6:	5e                   	pop    %esi
  800af7:	5f                   	pop    %edi
  800af8:	5d                   	pop    %ebp
  800af9:	c3                   	ret    

00800afa <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800afa:	55                   	push   %ebp
  800afb:	89 e5                	mov    %esp,%ebp
  800afd:	57                   	push   %edi
  800afe:	56                   	push   %esi
  800aff:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b00:	ba 00 00 00 00       	mov    $0x0,%edx
  800b05:	b8 02 00 00 00       	mov    $0x2,%eax
  800b0a:	89 d1                	mov    %edx,%ecx
  800b0c:	89 d3                	mov    %edx,%ebx
  800b0e:	89 d7                	mov    %edx,%edi
  800b10:	89 d6                	mov    %edx,%esi
  800b12:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800b14:	5b                   	pop    %ebx
  800b15:	5e                   	pop    %esi
  800b16:	5f                   	pop    %edi
  800b17:	5d                   	pop    %ebp
  800b18:	c3                   	ret    

00800b19 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800b19:	55                   	push   %ebp
  800b1a:	89 e5                	mov    %esp,%ebp
  800b1c:	56                   	push   %esi
  800b1d:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800b1e:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800b21:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800b27:	e8 ce ff ff ff       	call   800afa <sys_getenvid>
  800b2c:	83 ec 0c             	sub    $0xc,%esp
  800b2f:	ff 75 0c             	pushl  0xc(%ebp)
  800b32:	ff 75 08             	pushl  0x8(%ebp)
  800b35:	56                   	push   %esi
  800b36:	50                   	push   %eax
  800b37:	68 6c 10 80 00       	push   $0x80106c
  800b3c:	e8 f0 f5 ff ff       	call   800131 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800b41:	83 c4 18             	add    $0x18,%esp
  800b44:	53                   	push   %ebx
  800b45:	ff 75 10             	pushl  0x10(%ebp)
  800b48:	e8 93 f5 ff ff       	call   8000e0 <vcprintf>
	cprintf("\n");
  800b4d:	c7 04 24 1c 0e 80 00 	movl   $0x800e1c,(%esp)
  800b54:	e8 d8 f5 ff ff       	call   800131 <cprintf>
  800b59:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800b5c:	cc                   	int3   
  800b5d:	eb fd                	jmp    800b5c <_panic+0x43>
  800b5f:	90                   	nop

00800b60 <__udivdi3>:
  800b60:	55                   	push   %ebp
  800b61:	57                   	push   %edi
  800b62:	56                   	push   %esi
  800b63:	53                   	push   %ebx
  800b64:	83 ec 1c             	sub    $0x1c,%esp
  800b67:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  800b6b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  800b6f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  800b73:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800b77:	85 f6                	test   %esi,%esi
  800b79:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800b7d:	89 ca                	mov    %ecx,%edx
  800b7f:	89 f8                	mov    %edi,%eax
  800b81:	75 3d                	jne    800bc0 <__udivdi3+0x60>
  800b83:	39 cf                	cmp    %ecx,%edi
  800b85:	0f 87 c5 00 00 00    	ja     800c50 <__udivdi3+0xf0>
  800b8b:	85 ff                	test   %edi,%edi
  800b8d:	89 fd                	mov    %edi,%ebp
  800b8f:	75 0b                	jne    800b9c <__udivdi3+0x3c>
  800b91:	b8 01 00 00 00       	mov    $0x1,%eax
  800b96:	31 d2                	xor    %edx,%edx
  800b98:	f7 f7                	div    %edi
  800b9a:	89 c5                	mov    %eax,%ebp
  800b9c:	89 c8                	mov    %ecx,%eax
  800b9e:	31 d2                	xor    %edx,%edx
  800ba0:	f7 f5                	div    %ebp
  800ba2:	89 c1                	mov    %eax,%ecx
  800ba4:	89 d8                	mov    %ebx,%eax
  800ba6:	89 cf                	mov    %ecx,%edi
  800ba8:	f7 f5                	div    %ebp
  800baa:	89 c3                	mov    %eax,%ebx
  800bac:	89 d8                	mov    %ebx,%eax
  800bae:	89 fa                	mov    %edi,%edx
  800bb0:	83 c4 1c             	add    $0x1c,%esp
  800bb3:	5b                   	pop    %ebx
  800bb4:	5e                   	pop    %esi
  800bb5:	5f                   	pop    %edi
  800bb6:	5d                   	pop    %ebp
  800bb7:	c3                   	ret    
  800bb8:	90                   	nop
  800bb9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800bc0:	39 ce                	cmp    %ecx,%esi
  800bc2:	77 74                	ja     800c38 <__udivdi3+0xd8>
  800bc4:	0f bd fe             	bsr    %esi,%edi
  800bc7:	83 f7 1f             	xor    $0x1f,%edi
  800bca:	0f 84 98 00 00 00    	je     800c68 <__udivdi3+0x108>
  800bd0:	bb 20 00 00 00       	mov    $0x20,%ebx
  800bd5:	89 f9                	mov    %edi,%ecx
  800bd7:	89 c5                	mov    %eax,%ebp
  800bd9:	29 fb                	sub    %edi,%ebx
  800bdb:	d3 e6                	shl    %cl,%esi
  800bdd:	89 d9                	mov    %ebx,%ecx
  800bdf:	d3 ed                	shr    %cl,%ebp
  800be1:	89 f9                	mov    %edi,%ecx
  800be3:	d3 e0                	shl    %cl,%eax
  800be5:	09 ee                	or     %ebp,%esi
  800be7:	89 d9                	mov    %ebx,%ecx
  800be9:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800bed:	89 d5                	mov    %edx,%ebp
  800bef:	8b 44 24 08          	mov    0x8(%esp),%eax
  800bf3:	d3 ed                	shr    %cl,%ebp
  800bf5:	89 f9                	mov    %edi,%ecx
  800bf7:	d3 e2                	shl    %cl,%edx
  800bf9:	89 d9                	mov    %ebx,%ecx
  800bfb:	d3 e8                	shr    %cl,%eax
  800bfd:	09 c2                	or     %eax,%edx
  800bff:	89 d0                	mov    %edx,%eax
  800c01:	89 ea                	mov    %ebp,%edx
  800c03:	f7 f6                	div    %esi
  800c05:	89 d5                	mov    %edx,%ebp
  800c07:	89 c3                	mov    %eax,%ebx
  800c09:	f7 64 24 0c          	mull   0xc(%esp)
  800c0d:	39 d5                	cmp    %edx,%ebp
  800c0f:	72 10                	jb     800c21 <__udivdi3+0xc1>
  800c11:	8b 74 24 08          	mov    0x8(%esp),%esi
  800c15:	89 f9                	mov    %edi,%ecx
  800c17:	d3 e6                	shl    %cl,%esi
  800c19:	39 c6                	cmp    %eax,%esi
  800c1b:	73 07                	jae    800c24 <__udivdi3+0xc4>
  800c1d:	39 d5                	cmp    %edx,%ebp
  800c1f:	75 03                	jne    800c24 <__udivdi3+0xc4>
  800c21:	83 eb 01             	sub    $0x1,%ebx
  800c24:	31 ff                	xor    %edi,%edi
  800c26:	89 d8                	mov    %ebx,%eax
  800c28:	89 fa                	mov    %edi,%edx
  800c2a:	83 c4 1c             	add    $0x1c,%esp
  800c2d:	5b                   	pop    %ebx
  800c2e:	5e                   	pop    %esi
  800c2f:	5f                   	pop    %edi
  800c30:	5d                   	pop    %ebp
  800c31:	c3                   	ret    
  800c32:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800c38:	31 ff                	xor    %edi,%edi
  800c3a:	31 db                	xor    %ebx,%ebx
  800c3c:	89 d8                	mov    %ebx,%eax
  800c3e:	89 fa                	mov    %edi,%edx
  800c40:	83 c4 1c             	add    $0x1c,%esp
  800c43:	5b                   	pop    %ebx
  800c44:	5e                   	pop    %esi
  800c45:	5f                   	pop    %edi
  800c46:	5d                   	pop    %ebp
  800c47:	c3                   	ret    
  800c48:	90                   	nop
  800c49:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800c50:	89 d8                	mov    %ebx,%eax
  800c52:	f7 f7                	div    %edi
  800c54:	31 ff                	xor    %edi,%edi
  800c56:	89 c3                	mov    %eax,%ebx
  800c58:	89 d8                	mov    %ebx,%eax
  800c5a:	89 fa                	mov    %edi,%edx
  800c5c:	83 c4 1c             	add    $0x1c,%esp
  800c5f:	5b                   	pop    %ebx
  800c60:	5e                   	pop    %esi
  800c61:	5f                   	pop    %edi
  800c62:	5d                   	pop    %ebp
  800c63:	c3                   	ret    
  800c64:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800c68:	39 ce                	cmp    %ecx,%esi
  800c6a:	72 0c                	jb     800c78 <__udivdi3+0x118>
  800c6c:	31 db                	xor    %ebx,%ebx
  800c6e:	3b 44 24 08          	cmp    0x8(%esp),%eax
  800c72:	0f 87 34 ff ff ff    	ja     800bac <__udivdi3+0x4c>
  800c78:	bb 01 00 00 00       	mov    $0x1,%ebx
  800c7d:	e9 2a ff ff ff       	jmp    800bac <__udivdi3+0x4c>
  800c82:	66 90                	xchg   %ax,%ax
  800c84:	66 90                	xchg   %ax,%ax
  800c86:	66 90                	xchg   %ax,%ax
  800c88:	66 90                	xchg   %ax,%ax
  800c8a:	66 90                	xchg   %ax,%ax
  800c8c:	66 90                	xchg   %ax,%ax
  800c8e:	66 90                	xchg   %ax,%ax

00800c90 <__umoddi3>:
  800c90:	55                   	push   %ebp
  800c91:	57                   	push   %edi
  800c92:	56                   	push   %esi
  800c93:	53                   	push   %ebx
  800c94:	83 ec 1c             	sub    $0x1c,%esp
  800c97:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  800c9b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  800c9f:	8b 74 24 34          	mov    0x34(%esp),%esi
  800ca3:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800ca7:	85 d2                	test   %edx,%edx
  800ca9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800cad:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800cb1:	89 f3                	mov    %esi,%ebx
  800cb3:	89 3c 24             	mov    %edi,(%esp)
  800cb6:	89 74 24 04          	mov    %esi,0x4(%esp)
  800cba:	75 1c                	jne    800cd8 <__umoddi3+0x48>
  800cbc:	39 f7                	cmp    %esi,%edi
  800cbe:	76 50                	jbe    800d10 <__umoddi3+0x80>
  800cc0:	89 c8                	mov    %ecx,%eax
  800cc2:	89 f2                	mov    %esi,%edx
  800cc4:	f7 f7                	div    %edi
  800cc6:	89 d0                	mov    %edx,%eax
  800cc8:	31 d2                	xor    %edx,%edx
  800cca:	83 c4 1c             	add    $0x1c,%esp
  800ccd:	5b                   	pop    %ebx
  800cce:	5e                   	pop    %esi
  800ccf:	5f                   	pop    %edi
  800cd0:	5d                   	pop    %ebp
  800cd1:	c3                   	ret    
  800cd2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800cd8:	39 f2                	cmp    %esi,%edx
  800cda:	89 d0                	mov    %edx,%eax
  800cdc:	77 52                	ja     800d30 <__umoddi3+0xa0>
  800cde:	0f bd ea             	bsr    %edx,%ebp
  800ce1:	83 f5 1f             	xor    $0x1f,%ebp
  800ce4:	75 5a                	jne    800d40 <__umoddi3+0xb0>
  800ce6:	3b 54 24 04          	cmp    0x4(%esp),%edx
  800cea:	0f 82 e0 00 00 00    	jb     800dd0 <__umoddi3+0x140>
  800cf0:	39 0c 24             	cmp    %ecx,(%esp)
  800cf3:	0f 86 d7 00 00 00    	jbe    800dd0 <__umoddi3+0x140>
  800cf9:	8b 44 24 08          	mov    0x8(%esp),%eax
  800cfd:	8b 54 24 04          	mov    0x4(%esp),%edx
  800d01:	83 c4 1c             	add    $0x1c,%esp
  800d04:	5b                   	pop    %ebx
  800d05:	5e                   	pop    %esi
  800d06:	5f                   	pop    %edi
  800d07:	5d                   	pop    %ebp
  800d08:	c3                   	ret    
  800d09:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800d10:	85 ff                	test   %edi,%edi
  800d12:	89 fd                	mov    %edi,%ebp
  800d14:	75 0b                	jne    800d21 <__umoddi3+0x91>
  800d16:	b8 01 00 00 00       	mov    $0x1,%eax
  800d1b:	31 d2                	xor    %edx,%edx
  800d1d:	f7 f7                	div    %edi
  800d1f:	89 c5                	mov    %eax,%ebp
  800d21:	89 f0                	mov    %esi,%eax
  800d23:	31 d2                	xor    %edx,%edx
  800d25:	f7 f5                	div    %ebp
  800d27:	89 c8                	mov    %ecx,%eax
  800d29:	f7 f5                	div    %ebp
  800d2b:	89 d0                	mov    %edx,%eax
  800d2d:	eb 99                	jmp    800cc8 <__umoddi3+0x38>
  800d2f:	90                   	nop
  800d30:	89 c8                	mov    %ecx,%eax
  800d32:	89 f2                	mov    %esi,%edx
  800d34:	83 c4 1c             	add    $0x1c,%esp
  800d37:	5b                   	pop    %ebx
  800d38:	5e                   	pop    %esi
  800d39:	5f                   	pop    %edi
  800d3a:	5d                   	pop    %ebp
  800d3b:	c3                   	ret    
  800d3c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800d40:	8b 34 24             	mov    (%esp),%esi
  800d43:	bf 20 00 00 00       	mov    $0x20,%edi
  800d48:	89 e9                	mov    %ebp,%ecx
  800d4a:	29 ef                	sub    %ebp,%edi
  800d4c:	d3 e0                	shl    %cl,%eax
  800d4e:	89 f9                	mov    %edi,%ecx
  800d50:	89 f2                	mov    %esi,%edx
  800d52:	d3 ea                	shr    %cl,%edx
  800d54:	89 e9                	mov    %ebp,%ecx
  800d56:	09 c2                	or     %eax,%edx
  800d58:	89 d8                	mov    %ebx,%eax
  800d5a:	89 14 24             	mov    %edx,(%esp)
  800d5d:	89 f2                	mov    %esi,%edx
  800d5f:	d3 e2                	shl    %cl,%edx
  800d61:	89 f9                	mov    %edi,%ecx
  800d63:	89 54 24 04          	mov    %edx,0x4(%esp)
  800d67:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800d6b:	d3 e8                	shr    %cl,%eax
  800d6d:	89 e9                	mov    %ebp,%ecx
  800d6f:	89 c6                	mov    %eax,%esi
  800d71:	d3 e3                	shl    %cl,%ebx
  800d73:	89 f9                	mov    %edi,%ecx
  800d75:	89 d0                	mov    %edx,%eax
  800d77:	d3 e8                	shr    %cl,%eax
  800d79:	89 e9                	mov    %ebp,%ecx
  800d7b:	09 d8                	or     %ebx,%eax
  800d7d:	89 d3                	mov    %edx,%ebx
  800d7f:	89 f2                	mov    %esi,%edx
  800d81:	f7 34 24             	divl   (%esp)
  800d84:	89 d6                	mov    %edx,%esi
  800d86:	d3 e3                	shl    %cl,%ebx
  800d88:	f7 64 24 04          	mull   0x4(%esp)
  800d8c:	39 d6                	cmp    %edx,%esi
  800d8e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800d92:	89 d1                	mov    %edx,%ecx
  800d94:	89 c3                	mov    %eax,%ebx
  800d96:	72 08                	jb     800da0 <__umoddi3+0x110>
  800d98:	75 11                	jne    800dab <__umoddi3+0x11b>
  800d9a:	39 44 24 08          	cmp    %eax,0x8(%esp)
  800d9e:	73 0b                	jae    800dab <__umoddi3+0x11b>
  800da0:	2b 44 24 04          	sub    0x4(%esp),%eax
  800da4:	1b 14 24             	sbb    (%esp),%edx
  800da7:	89 d1                	mov    %edx,%ecx
  800da9:	89 c3                	mov    %eax,%ebx
  800dab:	8b 54 24 08          	mov    0x8(%esp),%edx
  800daf:	29 da                	sub    %ebx,%edx
  800db1:	19 ce                	sbb    %ecx,%esi
  800db3:	89 f9                	mov    %edi,%ecx
  800db5:	89 f0                	mov    %esi,%eax
  800db7:	d3 e0                	shl    %cl,%eax
  800db9:	89 e9                	mov    %ebp,%ecx
  800dbb:	d3 ea                	shr    %cl,%edx
  800dbd:	89 e9                	mov    %ebp,%ecx
  800dbf:	d3 ee                	shr    %cl,%esi
  800dc1:	09 d0                	or     %edx,%eax
  800dc3:	89 f2                	mov    %esi,%edx
  800dc5:	83 c4 1c             	add    $0x1c,%esp
  800dc8:	5b                   	pop    %ebx
  800dc9:	5e                   	pop    %esi
  800dca:	5f                   	pop    %edi
  800dcb:	5d                   	pop    %ebp
  800dcc:	c3                   	ret    
  800dcd:	8d 76 00             	lea    0x0(%esi),%esi
  800dd0:	29 f9                	sub    %edi,%ecx
  800dd2:	19 d6                	sbb    %edx,%esi
  800dd4:	89 74 24 04          	mov    %esi,0x4(%esp)
  800dd8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800ddc:	e9 18 ff ff ff       	jmp    800cf9 <__umoddi3+0x69>
