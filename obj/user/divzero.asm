
obj/user/divzero：     文件格式 elf32-i386


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
  80002c:	e8 2f 00 00 00       	call   800060 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

int zero;

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 10             	sub    $0x10,%esp
	zero = 0;
  800039:	c7 05 04 20 80 00 00 	movl   $0x0,0x802004
  800040:	00 00 00 
	cprintf("1/0 is %08x!\n", 1/zero);
  800043:	b8 01 00 00 00       	mov    $0x1,%eax
  800048:	b9 00 00 00 00       	mov    $0x0,%ecx
  80004d:	99                   	cltd   
  80004e:	f7 f9                	idiv   %ecx
  800050:	50                   	push   %eax
  800051:	68 20 0e 80 00       	push   $0x800e20
  800056:	e8 e8 00 00 00       	call   800143 <cprintf>
}
  80005b:	83 c4 10             	add    $0x10,%esp
  80005e:	c9                   	leave  
  80005f:	c3                   	ret    

00800060 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800060:	55                   	push   %ebp
  800061:	89 e5                	mov    %esp,%ebp
  800063:	56                   	push   %esi
  800064:	53                   	push   %ebx
  800065:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800068:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	envid_t envid = sys_getenvid();
  80006b:	e8 9c 0a 00 00       	call   800b0c <sys_getenvid>
	thisenv = envs;
  800070:	c7 05 08 20 80 00 00 	movl   $0xeec00000,0x802008
  800077:	00 c0 ee 
	// save the name of the program so that panic() can use it
	if (argc > 0)
  80007a:	85 db                	test   %ebx,%ebx
  80007c:	7e 07                	jle    800085 <libmain+0x25>
		binaryname = argv[0];
  80007e:	8b 06                	mov    (%esi),%eax
  800080:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  800085:	83 ec 08             	sub    $0x8,%esp
  800088:	56                   	push   %esi
  800089:	53                   	push   %ebx
  80008a:	e8 a4 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  80008f:	e8 0a 00 00 00       	call   80009e <exit>
}
  800094:	83 c4 10             	add    $0x10,%esp
  800097:	8d 65 f8             	lea    -0x8(%ebp),%esp
  80009a:	5b                   	pop    %ebx
  80009b:	5e                   	pop    %esi
  80009c:	5d                   	pop    %ebp
  80009d:	c3                   	ret    

0080009e <exit>:

#include <inc/lib.h>

void
exit(void)
{
  80009e:	55                   	push   %ebp
  80009f:	89 e5                	mov    %esp,%ebp
  8000a1:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  8000a4:	6a 00                	push   $0x0
  8000a6:	e8 20 0a 00 00       	call   800acb <sys_env_destroy>
}
  8000ab:	83 c4 10             	add    $0x10,%esp
  8000ae:	c9                   	leave  
  8000af:	c3                   	ret    

008000b0 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8000b0:	55                   	push   %ebp
  8000b1:	89 e5                	mov    %esp,%ebp
  8000b3:	53                   	push   %ebx
  8000b4:	83 ec 04             	sub    $0x4,%esp
  8000b7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8000ba:	8b 13                	mov    (%ebx),%edx
  8000bc:	8d 42 01             	lea    0x1(%edx),%eax
  8000bf:	89 03                	mov    %eax,(%ebx)
  8000c1:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000c4:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8000c8:	3d ff 00 00 00       	cmp    $0xff,%eax
  8000cd:	75 1a                	jne    8000e9 <putch+0x39>
		sys_cputs(b->buf, b->idx);
  8000cf:	83 ec 08             	sub    $0x8,%esp
  8000d2:	68 ff 00 00 00       	push   $0xff
  8000d7:	8d 43 08             	lea    0x8(%ebx),%eax
  8000da:	50                   	push   %eax
  8000db:	e8 ae 09 00 00       	call   800a8e <sys_cputs>
		b->idx = 0;
  8000e0:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8000e6:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8000e9:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8000ed:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8000f0:	c9                   	leave  
  8000f1:	c3                   	ret    

008000f2 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8000f2:	55                   	push   %ebp
  8000f3:	89 e5                	mov    %esp,%ebp
  8000f5:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8000fb:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  800102:	00 00 00 
	b.cnt = 0;
  800105:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  80010c:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  80010f:	ff 75 0c             	pushl  0xc(%ebp)
  800112:	ff 75 08             	pushl  0x8(%ebp)
  800115:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  80011b:	50                   	push   %eax
  80011c:	68 b0 00 80 00       	push   $0x8000b0
  800121:	e8 1a 01 00 00       	call   800240 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800126:	83 c4 08             	add    $0x8,%esp
  800129:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  80012f:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800135:	50                   	push   %eax
  800136:	e8 53 09 00 00       	call   800a8e <sys_cputs>

	return b.cnt;
}
  80013b:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800141:	c9                   	leave  
  800142:	c3                   	ret    

00800143 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800143:	55                   	push   %ebp
  800144:	89 e5                	mov    %esp,%ebp
  800146:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800149:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  80014c:	50                   	push   %eax
  80014d:	ff 75 08             	pushl  0x8(%ebp)
  800150:	e8 9d ff ff ff       	call   8000f2 <vcprintf>
	va_end(ap);

	return cnt;
}
  800155:	c9                   	leave  
  800156:	c3                   	ret    

00800157 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800157:	55                   	push   %ebp
  800158:	89 e5                	mov    %esp,%ebp
  80015a:	57                   	push   %edi
  80015b:	56                   	push   %esi
  80015c:	53                   	push   %ebx
  80015d:	83 ec 1c             	sub    $0x1c,%esp
  800160:	89 c7                	mov    %eax,%edi
  800162:	89 d6                	mov    %edx,%esi
  800164:	8b 45 08             	mov    0x8(%ebp),%eax
  800167:	8b 55 0c             	mov    0xc(%ebp),%edx
  80016a:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80016d:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800170:	8b 4d 10             	mov    0x10(%ebp),%ecx
  800173:	bb 00 00 00 00       	mov    $0x0,%ebx
  800178:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  80017b:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  80017e:	39 d3                	cmp    %edx,%ebx
  800180:	72 05                	jb     800187 <printnum+0x30>
  800182:	39 45 10             	cmp    %eax,0x10(%ebp)
  800185:	77 45                	ja     8001cc <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800187:	83 ec 0c             	sub    $0xc,%esp
  80018a:	ff 75 18             	pushl  0x18(%ebp)
  80018d:	8b 45 14             	mov    0x14(%ebp),%eax
  800190:	8d 58 ff             	lea    -0x1(%eax),%ebx
  800193:	53                   	push   %ebx
  800194:	ff 75 10             	pushl  0x10(%ebp)
  800197:	83 ec 08             	sub    $0x8,%esp
  80019a:	ff 75 e4             	pushl  -0x1c(%ebp)
  80019d:	ff 75 e0             	pushl  -0x20(%ebp)
  8001a0:	ff 75 dc             	pushl  -0x24(%ebp)
  8001a3:	ff 75 d8             	pushl  -0x28(%ebp)
  8001a6:	e8 d5 09 00 00       	call   800b80 <__udivdi3>
  8001ab:	83 c4 18             	add    $0x18,%esp
  8001ae:	52                   	push   %edx
  8001af:	50                   	push   %eax
  8001b0:	89 f2                	mov    %esi,%edx
  8001b2:	89 f8                	mov    %edi,%eax
  8001b4:	e8 9e ff ff ff       	call   800157 <printnum>
  8001b9:	83 c4 20             	add    $0x20,%esp
  8001bc:	eb 18                	jmp    8001d6 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8001be:	83 ec 08             	sub    $0x8,%esp
  8001c1:	56                   	push   %esi
  8001c2:	ff 75 18             	pushl  0x18(%ebp)
  8001c5:	ff d7                	call   *%edi
  8001c7:	83 c4 10             	add    $0x10,%esp
  8001ca:	eb 03                	jmp    8001cf <printnum+0x78>
  8001cc:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8001cf:	83 eb 01             	sub    $0x1,%ebx
  8001d2:	85 db                	test   %ebx,%ebx
  8001d4:	7f e8                	jg     8001be <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8001d6:	83 ec 08             	sub    $0x8,%esp
  8001d9:	56                   	push   %esi
  8001da:	83 ec 04             	sub    $0x4,%esp
  8001dd:	ff 75 e4             	pushl  -0x1c(%ebp)
  8001e0:	ff 75 e0             	pushl  -0x20(%ebp)
  8001e3:	ff 75 dc             	pushl  -0x24(%ebp)
  8001e6:	ff 75 d8             	pushl  -0x28(%ebp)
  8001e9:	e8 c2 0a 00 00       	call   800cb0 <__umoddi3>
  8001ee:	83 c4 14             	add    $0x14,%esp
  8001f1:	0f be 80 38 0e 80 00 	movsbl 0x800e38(%eax),%eax
  8001f8:	50                   	push   %eax
  8001f9:	ff d7                	call   *%edi
}
  8001fb:	83 c4 10             	add    $0x10,%esp
  8001fe:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800201:	5b                   	pop    %ebx
  800202:	5e                   	pop    %esi
  800203:	5f                   	pop    %edi
  800204:	5d                   	pop    %ebp
  800205:	c3                   	ret    

00800206 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  800206:	55                   	push   %ebp
  800207:	89 e5                	mov    %esp,%ebp
  800209:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  80020c:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800210:	8b 10                	mov    (%eax),%edx
  800212:	3b 50 04             	cmp    0x4(%eax),%edx
  800215:	73 0a                	jae    800221 <sprintputch+0x1b>
		*b->buf++ = ch;
  800217:	8d 4a 01             	lea    0x1(%edx),%ecx
  80021a:	89 08                	mov    %ecx,(%eax)
  80021c:	8b 45 08             	mov    0x8(%ebp),%eax
  80021f:	88 02                	mov    %al,(%edx)
}
  800221:	5d                   	pop    %ebp
  800222:	c3                   	ret    

00800223 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800223:	55                   	push   %ebp
  800224:	89 e5                	mov    %esp,%ebp
  800226:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  800229:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  80022c:	50                   	push   %eax
  80022d:	ff 75 10             	pushl  0x10(%ebp)
  800230:	ff 75 0c             	pushl  0xc(%ebp)
  800233:	ff 75 08             	pushl  0x8(%ebp)
  800236:	e8 05 00 00 00       	call   800240 <vprintfmt>
	va_end(ap);
}
  80023b:	83 c4 10             	add    $0x10,%esp
  80023e:	c9                   	leave  
  80023f:	c3                   	ret    

00800240 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800240:	55                   	push   %ebp
  800241:	89 e5                	mov    %esp,%ebp
  800243:	57                   	push   %edi
  800244:	56                   	push   %esi
  800245:	53                   	push   %ebx
  800246:	83 ec 2c             	sub    $0x2c,%esp
  800249:	8b 75 08             	mov    0x8(%ebp),%esi
  80024c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80024f:	8b 7d 10             	mov    0x10(%ebp),%edi
  800252:	eb 12                	jmp    800266 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800254:	85 c0                	test   %eax,%eax
  800256:	0f 84 42 04 00 00    	je     80069e <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
  80025c:	83 ec 08             	sub    $0x8,%esp
  80025f:	53                   	push   %ebx
  800260:	50                   	push   %eax
  800261:	ff d6                	call   *%esi
  800263:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800266:	83 c7 01             	add    $0x1,%edi
  800269:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  80026d:	83 f8 25             	cmp    $0x25,%eax
  800270:	75 e2                	jne    800254 <vprintfmt+0x14>
  800272:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  800276:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  80027d:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800284:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  80028b:	b9 00 00 00 00       	mov    $0x0,%ecx
  800290:	eb 07                	jmp    800299 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800292:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  800295:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800299:	8d 47 01             	lea    0x1(%edi),%eax
  80029c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  80029f:	0f b6 07             	movzbl (%edi),%eax
  8002a2:	0f b6 d0             	movzbl %al,%edx
  8002a5:	83 e8 23             	sub    $0x23,%eax
  8002a8:	3c 55                	cmp    $0x55,%al
  8002aa:	0f 87 d3 03 00 00    	ja     800683 <vprintfmt+0x443>
  8002b0:	0f b6 c0             	movzbl %al,%eax
  8002b3:	ff 24 85 e0 0e 80 00 	jmp    *0x800ee0(,%eax,4)
  8002ba:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  8002bd:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  8002c1:	eb d6                	jmp    800299 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002c3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8002c6:	b8 00 00 00 00       	mov    $0x0,%eax
  8002cb:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  8002ce:	8d 04 80             	lea    (%eax,%eax,4),%eax
  8002d1:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
  8002d5:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
  8002d8:	8d 4a d0             	lea    -0x30(%edx),%ecx
  8002db:	83 f9 09             	cmp    $0x9,%ecx
  8002de:	77 3f                	ja     80031f <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8002e0:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8002e3:	eb e9                	jmp    8002ce <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8002e5:	8b 45 14             	mov    0x14(%ebp),%eax
  8002e8:	8b 00                	mov    (%eax),%eax
  8002ea:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8002ed:	8b 45 14             	mov    0x14(%ebp),%eax
  8002f0:	8d 40 04             	lea    0x4(%eax),%eax
  8002f3:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002f6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8002f9:	eb 2a                	jmp    800325 <vprintfmt+0xe5>
  8002fb:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8002fe:	85 c0                	test   %eax,%eax
  800300:	ba 00 00 00 00       	mov    $0x0,%edx
  800305:	0f 49 d0             	cmovns %eax,%edx
  800308:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80030b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80030e:	eb 89                	jmp    800299 <vprintfmt+0x59>
  800310:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  800313:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  80031a:	e9 7a ff ff ff       	jmp    800299 <vprintfmt+0x59>
  80031f:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  800322:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  800325:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800329:	0f 89 6a ff ff ff    	jns    800299 <vprintfmt+0x59>
				width = precision, precision = -1;
  80032f:	8b 45 d0             	mov    -0x30(%ebp),%eax
  800332:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800335:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  80033c:	e9 58 ff ff ff       	jmp    800299 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800341:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800344:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  800347:	e9 4d ff ff ff       	jmp    800299 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  80034c:	8b 45 14             	mov    0x14(%ebp),%eax
  80034f:	8d 78 04             	lea    0x4(%eax),%edi
  800352:	83 ec 08             	sub    $0x8,%esp
  800355:	53                   	push   %ebx
  800356:	ff 30                	pushl  (%eax)
  800358:	ff d6                	call   *%esi
			break;
  80035a:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  80035d:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800360:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  800363:	e9 fe fe ff ff       	jmp    800266 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800368:	8b 45 14             	mov    0x14(%ebp),%eax
  80036b:	8d 78 04             	lea    0x4(%eax),%edi
  80036e:	8b 00                	mov    (%eax),%eax
  800370:	99                   	cltd   
  800371:	31 d0                	xor    %edx,%eax
  800373:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800375:	83 f8 07             	cmp    $0x7,%eax
  800378:	7f 0b                	jg     800385 <vprintfmt+0x145>
  80037a:	8b 14 85 40 10 80 00 	mov    0x801040(,%eax,4),%edx
  800381:	85 d2                	test   %edx,%edx
  800383:	75 1b                	jne    8003a0 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
  800385:	50                   	push   %eax
  800386:	68 50 0e 80 00       	push   $0x800e50
  80038b:	53                   	push   %ebx
  80038c:	56                   	push   %esi
  80038d:	e8 91 fe ff ff       	call   800223 <printfmt>
  800392:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  800395:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800398:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  80039b:	e9 c6 fe ff ff       	jmp    800266 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  8003a0:	52                   	push   %edx
  8003a1:	68 59 0e 80 00       	push   $0x800e59
  8003a6:	53                   	push   %ebx
  8003a7:	56                   	push   %esi
  8003a8:	e8 76 fe ff ff       	call   800223 <printfmt>
  8003ad:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  8003b0:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003b3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003b6:	e9 ab fe ff ff       	jmp    800266 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8003bb:	8b 45 14             	mov    0x14(%ebp),%eax
  8003be:	83 c0 04             	add    $0x4,%eax
  8003c1:	89 45 cc             	mov    %eax,-0x34(%ebp)
  8003c4:	8b 45 14             	mov    0x14(%ebp),%eax
  8003c7:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  8003c9:	85 ff                	test   %edi,%edi
  8003cb:	b8 49 0e 80 00       	mov    $0x800e49,%eax
  8003d0:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  8003d3:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8003d7:	0f 8e 94 00 00 00    	jle    800471 <vprintfmt+0x231>
  8003dd:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  8003e1:	0f 84 98 00 00 00    	je     80047f <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
  8003e7:	83 ec 08             	sub    $0x8,%esp
  8003ea:	ff 75 d0             	pushl  -0x30(%ebp)
  8003ed:	57                   	push   %edi
  8003ee:	e8 33 03 00 00       	call   800726 <strnlen>
  8003f3:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8003f6:	29 c1                	sub    %eax,%ecx
  8003f8:	89 4d c8             	mov    %ecx,-0x38(%ebp)
  8003fb:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  8003fe:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  800402:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800405:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  800408:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  80040a:	eb 0f                	jmp    80041b <vprintfmt+0x1db>
					putch(padc, putdat);
  80040c:	83 ec 08             	sub    $0x8,%esp
  80040f:	53                   	push   %ebx
  800410:	ff 75 e0             	pushl  -0x20(%ebp)
  800413:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800415:	83 ef 01             	sub    $0x1,%edi
  800418:	83 c4 10             	add    $0x10,%esp
  80041b:	85 ff                	test   %edi,%edi
  80041d:	7f ed                	jg     80040c <vprintfmt+0x1cc>
  80041f:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  800422:	8b 4d c8             	mov    -0x38(%ebp),%ecx
  800425:	85 c9                	test   %ecx,%ecx
  800427:	b8 00 00 00 00       	mov    $0x0,%eax
  80042c:	0f 49 c1             	cmovns %ecx,%eax
  80042f:	29 c1                	sub    %eax,%ecx
  800431:	89 75 08             	mov    %esi,0x8(%ebp)
  800434:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800437:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80043a:	89 cb                	mov    %ecx,%ebx
  80043c:	eb 4d                	jmp    80048b <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  80043e:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800442:	74 1b                	je     80045f <vprintfmt+0x21f>
  800444:	0f be c0             	movsbl %al,%eax
  800447:	83 e8 20             	sub    $0x20,%eax
  80044a:	83 f8 5e             	cmp    $0x5e,%eax
  80044d:	76 10                	jbe    80045f <vprintfmt+0x21f>
					putch('?', putdat);
  80044f:	83 ec 08             	sub    $0x8,%esp
  800452:	ff 75 0c             	pushl  0xc(%ebp)
  800455:	6a 3f                	push   $0x3f
  800457:	ff 55 08             	call   *0x8(%ebp)
  80045a:	83 c4 10             	add    $0x10,%esp
  80045d:	eb 0d                	jmp    80046c <vprintfmt+0x22c>
				else
					putch(ch, putdat);
  80045f:	83 ec 08             	sub    $0x8,%esp
  800462:	ff 75 0c             	pushl  0xc(%ebp)
  800465:	52                   	push   %edx
  800466:	ff 55 08             	call   *0x8(%ebp)
  800469:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  80046c:	83 eb 01             	sub    $0x1,%ebx
  80046f:	eb 1a                	jmp    80048b <vprintfmt+0x24b>
  800471:	89 75 08             	mov    %esi,0x8(%ebp)
  800474:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800477:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80047a:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  80047d:	eb 0c                	jmp    80048b <vprintfmt+0x24b>
  80047f:	89 75 08             	mov    %esi,0x8(%ebp)
  800482:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800485:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800488:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  80048b:	83 c7 01             	add    $0x1,%edi
  80048e:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800492:	0f be d0             	movsbl %al,%edx
  800495:	85 d2                	test   %edx,%edx
  800497:	74 23                	je     8004bc <vprintfmt+0x27c>
  800499:	85 f6                	test   %esi,%esi
  80049b:	78 a1                	js     80043e <vprintfmt+0x1fe>
  80049d:	83 ee 01             	sub    $0x1,%esi
  8004a0:	79 9c                	jns    80043e <vprintfmt+0x1fe>
  8004a2:	89 df                	mov    %ebx,%edi
  8004a4:	8b 75 08             	mov    0x8(%ebp),%esi
  8004a7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8004aa:	eb 18                	jmp    8004c4 <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  8004ac:	83 ec 08             	sub    $0x8,%esp
  8004af:	53                   	push   %ebx
  8004b0:	6a 20                	push   $0x20
  8004b2:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8004b4:	83 ef 01             	sub    $0x1,%edi
  8004b7:	83 c4 10             	add    $0x10,%esp
  8004ba:	eb 08                	jmp    8004c4 <vprintfmt+0x284>
  8004bc:	89 df                	mov    %ebx,%edi
  8004be:	8b 75 08             	mov    0x8(%ebp),%esi
  8004c1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8004c4:	85 ff                	test   %edi,%edi
  8004c6:	7f e4                	jg     8004ac <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8004c8:	8b 45 cc             	mov    -0x34(%ebp),%eax
  8004cb:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004ce:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8004d1:	e9 90 fd ff ff       	jmp    800266 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8004d6:	83 f9 01             	cmp    $0x1,%ecx
  8004d9:	7e 19                	jle    8004f4 <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
  8004db:	8b 45 14             	mov    0x14(%ebp),%eax
  8004de:	8b 50 04             	mov    0x4(%eax),%edx
  8004e1:	8b 00                	mov    (%eax),%eax
  8004e3:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8004e6:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8004e9:	8b 45 14             	mov    0x14(%ebp),%eax
  8004ec:	8d 40 08             	lea    0x8(%eax),%eax
  8004ef:	89 45 14             	mov    %eax,0x14(%ebp)
  8004f2:	eb 38                	jmp    80052c <vprintfmt+0x2ec>
	else if (lflag)
  8004f4:	85 c9                	test   %ecx,%ecx
  8004f6:	74 1b                	je     800513 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
  8004f8:	8b 45 14             	mov    0x14(%ebp),%eax
  8004fb:	8b 00                	mov    (%eax),%eax
  8004fd:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800500:	89 c1                	mov    %eax,%ecx
  800502:	c1 f9 1f             	sar    $0x1f,%ecx
  800505:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  800508:	8b 45 14             	mov    0x14(%ebp),%eax
  80050b:	8d 40 04             	lea    0x4(%eax),%eax
  80050e:	89 45 14             	mov    %eax,0x14(%ebp)
  800511:	eb 19                	jmp    80052c <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
  800513:	8b 45 14             	mov    0x14(%ebp),%eax
  800516:	8b 00                	mov    (%eax),%eax
  800518:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80051b:	89 c1                	mov    %eax,%ecx
  80051d:	c1 f9 1f             	sar    $0x1f,%ecx
  800520:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  800523:	8b 45 14             	mov    0x14(%ebp),%eax
  800526:	8d 40 04             	lea    0x4(%eax),%eax
  800529:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  80052c:	8b 55 d8             	mov    -0x28(%ebp),%edx
  80052f:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800532:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800537:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  80053b:	0f 89 0e 01 00 00    	jns    80064f <vprintfmt+0x40f>
				putch('-', putdat);
  800541:	83 ec 08             	sub    $0x8,%esp
  800544:	53                   	push   %ebx
  800545:	6a 2d                	push   $0x2d
  800547:	ff d6                	call   *%esi
				num = -(long long) num;
  800549:	8b 55 d8             	mov    -0x28(%ebp),%edx
  80054c:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  80054f:	f7 da                	neg    %edx
  800551:	83 d1 00             	adc    $0x0,%ecx
  800554:	f7 d9                	neg    %ecx
  800556:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  800559:	b8 0a 00 00 00       	mov    $0xa,%eax
  80055e:	e9 ec 00 00 00       	jmp    80064f <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800563:	83 f9 01             	cmp    $0x1,%ecx
  800566:	7e 18                	jle    800580 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
  800568:	8b 45 14             	mov    0x14(%ebp),%eax
  80056b:	8b 10                	mov    (%eax),%edx
  80056d:	8b 48 04             	mov    0x4(%eax),%ecx
  800570:	8d 40 08             	lea    0x8(%eax),%eax
  800573:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800576:	b8 0a 00 00 00       	mov    $0xa,%eax
  80057b:	e9 cf 00 00 00       	jmp    80064f <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  800580:	85 c9                	test   %ecx,%ecx
  800582:	74 1a                	je     80059e <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
  800584:	8b 45 14             	mov    0x14(%ebp),%eax
  800587:	8b 10                	mov    (%eax),%edx
  800589:	b9 00 00 00 00       	mov    $0x0,%ecx
  80058e:	8d 40 04             	lea    0x4(%eax),%eax
  800591:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800594:	b8 0a 00 00 00       	mov    $0xa,%eax
  800599:	e9 b1 00 00 00       	jmp    80064f <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  80059e:	8b 45 14             	mov    0x14(%ebp),%eax
  8005a1:	8b 10                	mov    (%eax),%edx
  8005a3:	b9 00 00 00 00       	mov    $0x0,%ecx
  8005a8:	8d 40 04             	lea    0x4(%eax),%eax
  8005ab:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  8005ae:	b8 0a 00 00 00       	mov    $0xa,%eax
  8005b3:	e9 97 00 00 00       	jmp    80064f <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
  8005b8:	83 ec 08             	sub    $0x8,%esp
  8005bb:	53                   	push   %ebx
  8005bc:	6a 58                	push   $0x58
  8005be:	ff d6                	call   *%esi
			putch('X', putdat);
  8005c0:	83 c4 08             	add    $0x8,%esp
  8005c3:	53                   	push   %ebx
  8005c4:	6a 58                	push   $0x58
  8005c6:	ff d6                	call   *%esi
			putch('X', putdat);
  8005c8:	83 c4 08             	add    $0x8,%esp
  8005cb:	53                   	push   %ebx
  8005cc:	6a 58                	push   $0x58
  8005ce:	ff d6                	call   *%esi
			break;
  8005d0:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005d3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
  8005d6:	e9 8b fc ff ff       	jmp    800266 <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
  8005db:	83 ec 08             	sub    $0x8,%esp
  8005de:	53                   	push   %ebx
  8005df:	6a 30                	push   $0x30
  8005e1:	ff d6                	call   *%esi
			putch('x', putdat);
  8005e3:	83 c4 08             	add    $0x8,%esp
  8005e6:	53                   	push   %ebx
  8005e7:	6a 78                	push   $0x78
  8005e9:	ff d6                	call   *%esi
			num = (unsigned long long)
  8005eb:	8b 45 14             	mov    0x14(%ebp),%eax
  8005ee:	8b 10                	mov    (%eax),%edx
  8005f0:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  8005f5:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  8005f8:	8d 40 04             	lea    0x4(%eax),%eax
  8005fb:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  8005fe:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
  800603:	eb 4a                	jmp    80064f <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800605:	83 f9 01             	cmp    $0x1,%ecx
  800608:	7e 15                	jle    80061f <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
  80060a:	8b 45 14             	mov    0x14(%ebp),%eax
  80060d:	8b 10                	mov    (%eax),%edx
  80060f:	8b 48 04             	mov    0x4(%eax),%ecx
  800612:	8d 40 08             	lea    0x8(%eax),%eax
  800615:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800618:	b8 10 00 00 00       	mov    $0x10,%eax
  80061d:	eb 30                	jmp    80064f <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  80061f:	85 c9                	test   %ecx,%ecx
  800621:	74 17                	je     80063a <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
  800623:	8b 45 14             	mov    0x14(%ebp),%eax
  800626:	8b 10                	mov    (%eax),%edx
  800628:	b9 00 00 00 00       	mov    $0x0,%ecx
  80062d:	8d 40 04             	lea    0x4(%eax),%eax
  800630:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800633:	b8 10 00 00 00       	mov    $0x10,%eax
  800638:	eb 15                	jmp    80064f <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  80063a:	8b 45 14             	mov    0x14(%ebp),%eax
  80063d:	8b 10                	mov    (%eax),%edx
  80063f:	b9 00 00 00 00       	mov    $0x0,%ecx
  800644:	8d 40 04             	lea    0x4(%eax),%eax
  800647:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  80064a:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
  80064f:	83 ec 0c             	sub    $0xc,%esp
  800652:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  800656:	57                   	push   %edi
  800657:	ff 75 e0             	pushl  -0x20(%ebp)
  80065a:	50                   	push   %eax
  80065b:	51                   	push   %ecx
  80065c:	52                   	push   %edx
  80065d:	89 da                	mov    %ebx,%edx
  80065f:	89 f0                	mov    %esi,%eax
  800661:	e8 f1 fa ff ff       	call   800157 <printnum>
			break;
  800666:	83 c4 20             	add    $0x20,%esp
  800669:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80066c:	e9 f5 fb ff ff       	jmp    800266 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  800671:	83 ec 08             	sub    $0x8,%esp
  800674:	53                   	push   %ebx
  800675:	52                   	push   %edx
  800676:	ff d6                	call   *%esi
			break;
  800678:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80067b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  80067e:	e9 e3 fb ff ff       	jmp    800266 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  800683:	83 ec 08             	sub    $0x8,%esp
  800686:	53                   	push   %ebx
  800687:	6a 25                	push   $0x25
  800689:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  80068b:	83 c4 10             	add    $0x10,%esp
  80068e:	eb 03                	jmp    800693 <vprintfmt+0x453>
  800690:	83 ef 01             	sub    $0x1,%edi
  800693:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800697:	75 f7                	jne    800690 <vprintfmt+0x450>
  800699:	e9 c8 fb ff ff       	jmp    800266 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  80069e:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8006a1:	5b                   	pop    %ebx
  8006a2:	5e                   	pop    %esi
  8006a3:	5f                   	pop    %edi
  8006a4:	5d                   	pop    %ebp
  8006a5:	c3                   	ret    

008006a6 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  8006a6:	55                   	push   %ebp
  8006a7:	89 e5                	mov    %esp,%ebp
  8006a9:	83 ec 18             	sub    $0x18,%esp
  8006ac:	8b 45 08             	mov    0x8(%ebp),%eax
  8006af:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  8006b2:	89 45 ec             	mov    %eax,-0x14(%ebp)
  8006b5:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  8006b9:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  8006bc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8006c3:	85 c0                	test   %eax,%eax
  8006c5:	74 26                	je     8006ed <vsnprintf+0x47>
  8006c7:	85 d2                	test   %edx,%edx
  8006c9:	7e 22                	jle    8006ed <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  8006cb:	ff 75 14             	pushl  0x14(%ebp)
  8006ce:	ff 75 10             	pushl  0x10(%ebp)
  8006d1:	8d 45 ec             	lea    -0x14(%ebp),%eax
  8006d4:	50                   	push   %eax
  8006d5:	68 06 02 80 00       	push   $0x800206
  8006da:	e8 61 fb ff ff       	call   800240 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  8006df:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8006e2:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  8006e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8006e8:	83 c4 10             	add    $0x10,%esp
  8006eb:	eb 05                	jmp    8006f2 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  8006ed:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  8006f2:	c9                   	leave  
  8006f3:	c3                   	ret    

008006f4 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  8006f4:	55                   	push   %ebp
  8006f5:	89 e5                	mov    %esp,%ebp
  8006f7:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  8006fa:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  8006fd:	50                   	push   %eax
  8006fe:	ff 75 10             	pushl  0x10(%ebp)
  800701:	ff 75 0c             	pushl  0xc(%ebp)
  800704:	ff 75 08             	pushl  0x8(%ebp)
  800707:	e8 9a ff ff ff       	call   8006a6 <vsnprintf>
	va_end(ap);

	return rc;
}
  80070c:	c9                   	leave  
  80070d:	c3                   	ret    

0080070e <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  80070e:	55                   	push   %ebp
  80070f:	89 e5                	mov    %esp,%ebp
  800711:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800714:	b8 00 00 00 00       	mov    $0x0,%eax
  800719:	eb 03                	jmp    80071e <strlen+0x10>
		n++;
  80071b:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  80071e:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800722:	75 f7                	jne    80071b <strlen+0xd>
		n++;
	return n;
}
  800724:	5d                   	pop    %ebp
  800725:	c3                   	ret    

00800726 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800726:	55                   	push   %ebp
  800727:	89 e5                	mov    %esp,%ebp
  800729:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80072c:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80072f:	ba 00 00 00 00       	mov    $0x0,%edx
  800734:	eb 03                	jmp    800739 <strnlen+0x13>
		n++;
  800736:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800739:	39 c2                	cmp    %eax,%edx
  80073b:	74 08                	je     800745 <strnlen+0x1f>
  80073d:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  800741:	75 f3                	jne    800736 <strnlen+0x10>
  800743:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  800745:	5d                   	pop    %ebp
  800746:	c3                   	ret    

00800747 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800747:	55                   	push   %ebp
  800748:	89 e5                	mov    %esp,%ebp
  80074a:	53                   	push   %ebx
  80074b:	8b 45 08             	mov    0x8(%ebp),%eax
  80074e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800751:	89 c2                	mov    %eax,%edx
  800753:	83 c2 01             	add    $0x1,%edx
  800756:	83 c1 01             	add    $0x1,%ecx
  800759:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  80075d:	88 5a ff             	mov    %bl,-0x1(%edx)
  800760:	84 db                	test   %bl,%bl
  800762:	75 ef                	jne    800753 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800764:	5b                   	pop    %ebx
  800765:	5d                   	pop    %ebp
  800766:	c3                   	ret    

00800767 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800767:	55                   	push   %ebp
  800768:	89 e5                	mov    %esp,%ebp
  80076a:	53                   	push   %ebx
  80076b:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  80076e:	53                   	push   %ebx
  80076f:	e8 9a ff ff ff       	call   80070e <strlen>
  800774:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  800777:	ff 75 0c             	pushl  0xc(%ebp)
  80077a:	01 d8                	add    %ebx,%eax
  80077c:	50                   	push   %eax
  80077d:	e8 c5 ff ff ff       	call   800747 <strcpy>
	return dst;
}
  800782:	89 d8                	mov    %ebx,%eax
  800784:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800787:	c9                   	leave  
  800788:	c3                   	ret    

00800789 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800789:	55                   	push   %ebp
  80078a:	89 e5                	mov    %esp,%ebp
  80078c:	56                   	push   %esi
  80078d:	53                   	push   %ebx
  80078e:	8b 75 08             	mov    0x8(%ebp),%esi
  800791:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800794:	89 f3                	mov    %esi,%ebx
  800796:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800799:	89 f2                	mov    %esi,%edx
  80079b:	eb 0f                	jmp    8007ac <strncpy+0x23>
		*dst++ = *src;
  80079d:	83 c2 01             	add    $0x1,%edx
  8007a0:	0f b6 01             	movzbl (%ecx),%eax
  8007a3:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  8007a6:	80 39 01             	cmpb   $0x1,(%ecx)
  8007a9:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007ac:	39 da                	cmp    %ebx,%edx
  8007ae:	75 ed                	jne    80079d <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  8007b0:	89 f0                	mov    %esi,%eax
  8007b2:	5b                   	pop    %ebx
  8007b3:	5e                   	pop    %esi
  8007b4:	5d                   	pop    %ebp
  8007b5:	c3                   	ret    

008007b6 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  8007b6:	55                   	push   %ebp
  8007b7:	89 e5                	mov    %esp,%ebp
  8007b9:	56                   	push   %esi
  8007ba:	53                   	push   %ebx
  8007bb:	8b 75 08             	mov    0x8(%ebp),%esi
  8007be:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8007c1:	8b 55 10             	mov    0x10(%ebp),%edx
  8007c4:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  8007c6:	85 d2                	test   %edx,%edx
  8007c8:	74 21                	je     8007eb <strlcpy+0x35>
  8007ca:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  8007ce:	89 f2                	mov    %esi,%edx
  8007d0:	eb 09                	jmp    8007db <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  8007d2:	83 c2 01             	add    $0x1,%edx
  8007d5:	83 c1 01             	add    $0x1,%ecx
  8007d8:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  8007db:	39 c2                	cmp    %eax,%edx
  8007dd:	74 09                	je     8007e8 <strlcpy+0x32>
  8007df:	0f b6 19             	movzbl (%ecx),%ebx
  8007e2:	84 db                	test   %bl,%bl
  8007e4:	75 ec                	jne    8007d2 <strlcpy+0x1c>
  8007e6:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  8007e8:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  8007eb:	29 f0                	sub    %esi,%eax
}
  8007ed:	5b                   	pop    %ebx
  8007ee:	5e                   	pop    %esi
  8007ef:	5d                   	pop    %ebp
  8007f0:	c3                   	ret    

008007f1 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  8007f1:	55                   	push   %ebp
  8007f2:	89 e5                	mov    %esp,%ebp
  8007f4:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8007f7:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  8007fa:	eb 06                	jmp    800802 <strcmp+0x11>
		p++, q++;
  8007fc:	83 c1 01             	add    $0x1,%ecx
  8007ff:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800802:	0f b6 01             	movzbl (%ecx),%eax
  800805:	84 c0                	test   %al,%al
  800807:	74 04                	je     80080d <strcmp+0x1c>
  800809:	3a 02                	cmp    (%edx),%al
  80080b:	74 ef                	je     8007fc <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  80080d:	0f b6 c0             	movzbl %al,%eax
  800810:	0f b6 12             	movzbl (%edx),%edx
  800813:	29 d0                	sub    %edx,%eax
}
  800815:	5d                   	pop    %ebp
  800816:	c3                   	ret    

00800817 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800817:	55                   	push   %ebp
  800818:	89 e5                	mov    %esp,%ebp
  80081a:	53                   	push   %ebx
  80081b:	8b 45 08             	mov    0x8(%ebp),%eax
  80081e:	8b 55 0c             	mov    0xc(%ebp),%edx
  800821:	89 c3                	mov    %eax,%ebx
  800823:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800826:	eb 06                	jmp    80082e <strncmp+0x17>
		n--, p++, q++;
  800828:	83 c0 01             	add    $0x1,%eax
  80082b:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  80082e:	39 d8                	cmp    %ebx,%eax
  800830:	74 15                	je     800847 <strncmp+0x30>
  800832:	0f b6 08             	movzbl (%eax),%ecx
  800835:	84 c9                	test   %cl,%cl
  800837:	74 04                	je     80083d <strncmp+0x26>
  800839:	3a 0a                	cmp    (%edx),%cl
  80083b:	74 eb                	je     800828 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  80083d:	0f b6 00             	movzbl (%eax),%eax
  800840:	0f b6 12             	movzbl (%edx),%edx
  800843:	29 d0                	sub    %edx,%eax
  800845:	eb 05                	jmp    80084c <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800847:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  80084c:	5b                   	pop    %ebx
  80084d:	5d                   	pop    %ebp
  80084e:	c3                   	ret    

0080084f <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  80084f:	55                   	push   %ebp
  800850:	89 e5                	mov    %esp,%ebp
  800852:	8b 45 08             	mov    0x8(%ebp),%eax
  800855:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800859:	eb 07                	jmp    800862 <strchr+0x13>
		if (*s == c)
  80085b:	38 ca                	cmp    %cl,%dl
  80085d:	74 0f                	je     80086e <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  80085f:	83 c0 01             	add    $0x1,%eax
  800862:	0f b6 10             	movzbl (%eax),%edx
  800865:	84 d2                	test   %dl,%dl
  800867:	75 f2                	jne    80085b <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800869:	b8 00 00 00 00       	mov    $0x0,%eax
}
  80086e:	5d                   	pop    %ebp
  80086f:	c3                   	ret    

00800870 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800870:	55                   	push   %ebp
  800871:	89 e5                	mov    %esp,%ebp
  800873:	8b 45 08             	mov    0x8(%ebp),%eax
  800876:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  80087a:	eb 03                	jmp    80087f <strfind+0xf>
  80087c:	83 c0 01             	add    $0x1,%eax
  80087f:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  800882:	38 ca                	cmp    %cl,%dl
  800884:	74 04                	je     80088a <strfind+0x1a>
  800886:	84 d2                	test   %dl,%dl
  800888:	75 f2                	jne    80087c <strfind+0xc>
			break;
	return (char *) s;
}
  80088a:	5d                   	pop    %ebp
  80088b:	c3                   	ret    

0080088c <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  80088c:	55                   	push   %ebp
  80088d:	89 e5                	mov    %esp,%ebp
  80088f:	57                   	push   %edi
  800890:	56                   	push   %esi
  800891:	53                   	push   %ebx
  800892:	8b 7d 08             	mov    0x8(%ebp),%edi
  800895:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800898:	85 c9                	test   %ecx,%ecx
  80089a:	74 36                	je     8008d2 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  80089c:	f7 c7 03 00 00 00    	test   $0x3,%edi
  8008a2:	75 28                	jne    8008cc <memset+0x40>
  8008a4:	f6 c1 03             	test   $0x3,%cl
  8008a7:	75 23                	jne    8008cc <memset+0x40>
		c &= 0xFF;
  8008a9:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  8008ad:	89 d3                	mov    %edx,%ebx
  8008af:	c1 e3 08             	shl    $0x8,%ebx
  8008b2:	89 d6                	mov    %edx,%esi
  8008b4:	c1 e6 18             	shl    $0x18,%esi
  8008b7:	89 d0                	mov    %edx,%eax
  8008b9:	c1 e0 10             	shl    $0x10,%eax
  8008bc:	09 f0                	or     %esi,%eax
  8008be:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  8008c0:	89 d8                	mov    %ebx,%eax
  8008c2:	09 d0                	or     %edx,%eax
  8008c4:	c1 e9 02             	shr    $0x2,%ecx
  8008c7:	fc                   	cld    
  8008c8:	f3 ab                	rep stos %eax,%es:(%edi)
  8008ca:	eb 06                	jmp    8008d2 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  8008cc:	8b 45 0c             	mov    0xc(%ebp),%eax
  8008cf:	fc                   	cld    
  8008d0:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  8008d2:	89 f8                	mov    %edi,%eax
  8008d4:	5b                   	pop    %ebx
  8008d5:	5e                   	pop    %esi
  8008d6:	5f                   	pop    %edi
  8008d7:	5d                   	pop    %ebp
  8008d8:	c3                   	ret    

008008d9 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  8008d9:	55                   	push   %ebp
  8008da:	89 e5                	mov    %esp,%ebp
  8008dc:	57                   	push   %edi
  8008dd:	56                   	push   %esi
  8008de:	8b 45 08             	mov    0x8(%ebp),%eax
  8008e1:	8b 75 0c             	mov    0xc(%ebp),%esi
  8008e4:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  8008e7:	39 c6                	cmp    %eax,%esi
  8008e9:	73 35                	jae    800920 <memmove+0x47>
  8008eb:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  8008ee:	39 d0                	cmp    %edx,%eax
  8008f0:	73 2e                	jae    800920 <memmove+0x47>
		s += n;
		d += n;
  8008f2:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  8008f5:	89 d6                	mov    %edx,%esi
  8008f7:	09 fe                	or     %edi,%esi
  8008f9:	f7 c6 03 00 00 00    	test   $0x3,%esi
  8008ff:	75 13                	jne    800914 <memmove+0x3b>
  800901:	f6 c1 03             	test   $0x3,%cl
  800904:	75 0e                	jne    800914 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  800906:	83 ef 04             	sub    $0x4,%edi
  800909:	8d 72 fc             	lea    -0x4(%edx),%esi
  80090c:	c1 e9 02             	shr    $0x2,%ecx
  80090f:	fd                   	std    
  800910:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800912:	eb 09                	jmp    80091d <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800914:	83 ef 01             	sub    $0x1,%edi
  800917:	8d 72 ff             	lea    -0x1(%edx),%esi
  80091a:	fd                   	std    
  80091b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  80091d:	fc                   	cld    
  80091e:	eb 1d                	jmp    80093d <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800920:	89 f2                	mov    %esi,%edx
  800922:	09 c2                	or     %eax,%edx
  800924:	f6 c2 03             	test   $0x3,%dl
  800927:	75 0f                	jne    800938 <memmove+0x5f>
  800929:	f6 c1 03             	test   $0x3,%cl
  80092c:	75 0a                	jne    800938 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  80092e:	c1 e9 02             	shr    $0x2,%ecx
  800931:	89 c7                	mov    %eax,%edi
  800933:	fc                   	cld    
  800934:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800936:	eb 05                	jmp    80093d <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800938:	89 c7                	mov    %eax,%edi
  80093a:	fc                   	cld    
  80093b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  80093d:	5e                   	pop    %esi
  80093e:	5f                   	pop    %edi
  80093f:	5d                   	pop    %ebp
  800940:	c3                   	ret    

00800941 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800941:	55                   	push   %ebp
  800942:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  800944:	ff 75 10             	pushl  0x10(%ebp)
  800947:	ff 75 0c             	pushl  0xc(%ebp)
  80094a:	ff 75 08             	pushl  0x8(%ebp)
  80094d:	e8 87 ff ff ff       	call   8008d9 <memmove>
}
  800952:	c9                   	leave  
  800953:	c3                   	ret    

00800954 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800954:	55                   	push   %ebp
  800955:	89 e5                	mov    %esp,%ebp
  800957:	56                   	push   %esi
  800958:	53                   	push   %ebx
  800959:	8b 45 08             	mov    0x8(%ebp),%eax
  80095c:	8b 55 0c             	mov    0xc(%ebp),%edx
  80095f:	89 c6                	mov    %eax,%esi
  800961:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800964:	eb 1a                	jmp    800980 <memcmp+0x2c>
		if (*s1 != *s2)
  800966:	0f b6 08             	movzbl (%eax),%ecx
  800969:	0f b6 1a             	movzbl (%edx),%ebx
  80096c:	38 d9                	cmp    %bl,%cl
  80096e:	74 0a                	je     80097a <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800970:	0f b6 c1             	movzbl %cl,%eax
  800973:	0f b6 db             	movzbl %bl,%ebx
  800976:	29 d8                	sub    %ebx,%eax
  800978:	eb 0f                	jmp    800989 <memcmp+0x35>
		s1++, s2++;
  80097a:	83 c0 01             	add    $0x1,%eax
  80097d:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800980:	39 f0                	cmp    %esi,%eax
  800982:	75 e2                	jne    800966 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800984:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800989:	5b                   	pop    %ebx
  80098a:	5e                   	pop    %esi
  80098b:	5d                   	pop    %ebp
  80098c:	c3                   	ret    

0080098d <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  80098d:	55                   	push   %ebp
  80098e:	89 e5                	mov    %esp,%ebp
  800990:	53                   	push   %ebx
  800991:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  800994:	89 c1                	mov    %eax,%ecx
  800996:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  800999:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  80099d:	eb 0a                	jmp    8009a9 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  80099f:	0f b6 10             	movzbl (%eax),%edx
  8009a2:	39 da                	cmp    %ebx,%edx
  8009a4:	74 07                	je     8009ad <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  8009a6:	83 c0 01             	add    $0x1,%eax
  8009a9:	39 c8                	cmp    %ecx,%eax
  8009ab:	72 f2                	jb     80099f <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  8009ad:	5b                   	pop    %ebx
  8009ae:	5d                   	pop    %ebp
  8009af:	c3                   	ret    

008009b0 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  8009b0:	55                   	push   %ebp
  8009b1:	89 e5                	mov    %esp,%ebp
  8009b3:	57                   	push   %edi
  8009b4:	56                   	push   %esi
  8009b5:	53                   	push   %ebx
  8009b6:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8009b9:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  8009bc:	eb 03                	jmp    8009c1 <strtol+0x11>
		s++;
  8009be:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  8009c1:	0f b6 01             	movzbl (%ecx),%eax
  8009c4:	3c 20                	cmp    $0x20,%al
  8009c6:	74 f6                	je     8009be <strtol+0xe>
  8009c8:	3c 09                	cmp    $0x9,%al
  8009ca:	74 f2                	je     8009be <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  8009cc:	3c 2b                	cmp    $0x2b,%al
  8009ce:	75 0a                	jne    8009da <strtol+0x2a>
		s++;
  8009d0:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  8009d3:	bf 00 00 00 00       	mov    $0x0,%edi
  8009d8:	eb 11                	jmp    8009eb <strtol+0x3b>
  8009da:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  8009df:	3c 2d                	cmp    $0x2d,%al
  8009e1:	75 08                	jne    8009eb <strtol+0x3b>
		s++, neg = 1;
  8009e3:	83 c1 01             	add    $0x1,%ecx
  8009e6:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  8009eb:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  8009f1:	75 15                	jne    800a08 <strtol+0x58>
  8009f3:	80 39 30             	cmpb   $0x30,(%ecx)
  8009f6:	75 10                	jne    800a08 <strtol+0x58>
  8009f8:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  8009fc:	75 7c                	jne    800a7a <strtol+0xca>
		s += 2, base = 16;
  8009fe:	83 c1 02             	add    $0x2,%ecx
  800a01:	bb 10 00 00 00       	mov    $0x10,%ebx
  800a06:	eb 16                	jmp    800a1e <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800a08:	85 db                	test   %ebx,%ebx
  800a0a:	75 12                	jne    800a1e <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800a0c:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a11:	80 39 30             	cmpb   $0x30,(%ecx)
  800a14:	75 08                	jne    800a1e <strtol+0x6e>
		s++, base = 8;
  800a16:	83 c1 01             	add    $0x1,%ecx
  800a19:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800a1e:	b8 00 00 00 00       	mov    $0x0,%eax
  800a23:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800a26:	0f b6 11             	movzbl (%ecx),%edx
  800a29:	8d 72 d0             	lea    -0x30(%edx),%esi
  800a2c:	89 f3                	mov    %esi,%ebx
  800a2e:	80 fb 09             	cmp    $0x9,%bl
  800a31:	77 08                	ja     800a3b <strtol+0x8b>
			dig = *s - '0';
  800a33:	0f be d2             	movsbl %dl,%edx
  800a36:	83 ea 30             	sub    $0x30,%edx
  800a39:	eb 22                	jmp    800a5d <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800a3b:	8d 72 9f             	lea    -0x61(%edx),%esi
  800a3e:	89 f3                	mov    %esi,%ebx
  800a40:	80 fb 19             	cmp    $0x19,%bl
  800a43:	77 08                	ja     800a4d <strtol+0x9d>
			dig = *s - 'a' + 10;
  800a45:	0f be d2             	movsbl %dl,%edx
  800a48:	83 ea 57             	sub    $0x57,%edx
  800a4b:	eb 10                	jmp    800a5d <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800a4d:	8d 72 bf             	lea    -0x41(%edx),%esi
  800a50:	89 f3                	mov    %esi,%ebx
  800a52:	80 fb 19             	cmp    $0x19,%bl
  800a55:	77 16                	ja     800a6d <strtol+0xbd>
			dig = *s - 'A' + 10;
  800a57:	0f be d2             	movsbl %dl,%edx
  800a5a:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800a5d:	3b 55 10             	cmp    0x10(%ebp),%edx
  800a60:	7d 0b                	jge    800a6d <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800a62:	83 c1 01             	add    $0x1,%ecx
  800a65:	0f af 45 10          	imul   0x10(%ebp),%eax
  800a69:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800a6b:	eb b9                	jmp    800a26 <strtol+0x76>

	if (endptr)
  800a6d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800a71:	74 0d                	je     800a80 <strtol+0xd0>
		*endptr = (char *) s;
  800a73:	8b 75 0c             	mov    0xc(%ebp),%esi
  800a76:	89 0e                	mov    %ecx,(%esi)
  800a78:	eb 06                	jmp    800a80 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a7a:	85 db                	test   %ebx,%ebx
  800a7c:	74 98                	je     800a16 <strtol+0x66>
  800a7e:	eb 9e                	jmp    800a1e <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800a80:	89 c2                	mov    %eax,%edx
  800a82:	f7 da                	neg    %edx
  800a84:	85 ff                	test   %edi,%edi
  800a86:	0f 45 c2             	cmovne %edx,%eax
}
  800a89:	5b                   	pop    %ebx
  800a8a:	5e                   	pop    %esi
  800a8b:	5f                   	pop    %edi
  800a8c:	5d                   	pop    %ebp
  800a8d:	c3                   	ret    

00800a8e <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800a8e:	55                   	push   %ebp
  800a8f:	89 e5                	mov    %esp,%ebp
  800a91:	57                   	push   %edi
  800a92:	56                   	push   %esi
  800a93:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800a94:	b8 00 00 00 00       	mov    $0x0,%eax
  800a99:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800a9c:	8b 55 08             	mov    0x8(%ebp),%edx
  800a9f:	89 c3                	mov    %eax,%ebx
  800aa1:	89 c7                	mov    %eax,%edi
  800aa3:	89 c6                	mov    %eax,%esi
  800aa5:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800aa7:	5b                   	pop    %ebx
  800aa8:	5e                   	pop    %esi
  800aa9:	5f                   	pop    %edi
  800aaa:	5d                   	pop    %ebp
  800aab:	c3                   	ret    

00800aac <sys_cgetc>:

int
sys_cgetc(void)
{
  800aac:	55                   	push   %ebp
  800aad:	89 e5                	mov    %esp,%ebp
  800aaf:	57                   	push   %edi
  800ab0:	56                   	push   %esi
  800ab1:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800ab2:	ba 00 00 00 00       	mov    $0x0,%edx
  800ab7:	b8 01 00 00 00       	mov    $0x1,%eax
  800abc:	89 d1                	mov    %edx,%ecx
  800abe:	89 d3                	mov    %edx,%ebx
  800ac0:	89 d7                	mov    %edx,%edi
  800ac2:	89 d6                	mov    %edx,%esi
  800ac4:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800ac6:	5b                   	pop    %ebx
  800ac7:	5e                   	pop    %esi
  800ac8:	5f                   	pop    %edi
  800ac9:	5d                   	pop    %ebp
  800aca:	c3                   	ret    

00800acb <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800acb:	55                   	push   %ebp
  800acc:	89 e5                	mov    %esp,%ebp
  800ace:	57                   	push   %edi
  800acf:	56                   	push   %esi
  800ad0:	53                   	push   %ebx
  800ad1:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800ad4:	b9 00 00 00 00       	mov    $0x0,%ecx
  800ad9:	b8 03 00 00 00       	mov    $0x3,%eax
  800ade:	8b 55 08             	mov    0x8(%ebp),%edx
  800ae1:	89 cb                	mov    %ecx,%ebx
  800ae3:	89 cf                	mov    %ecx,%edi
  800ae5:	89 ce                	mov    %ecx,%esi
  800ae7:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800ae9:	85 c0                	test   %eax,%eax
  800aeb:	7e 17                	jle    800b04 <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800aed:	83 ec 0c             	sub    $0xc,%esp
  800af0:	50                   	push   %eax
  800af1:	6a 03                	push   $0x3
  800af3:	68 60 10 80 00       	push   $0x801060
  800af8:	6a 23                	push   $0x23
  800afa:	68 7d 10 80 00       	push   $0x80107d
  800aff:	e8 27 00 00 00       	call   800b2b <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800b04:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800b07:	5b                   	pop    %ebx
  800b08:	5e                   	pop    %esi
  800b09:	5f                   	pop    %edi
  800b0a:	5d                   	pop    %ebp
  800b0b:	c3                   	ret    

00800b0c <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800b0c:	55                   	push   %ebp
  800b0d:	89 e5                	mov    %esp,%ebp
  800b0f:	57                   	push   %edi
  800b10:	56                   	push   %esi
  800b11:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b12:	ba 00 00 00 00       	mov    $0x0,%edx
  800b17:	b8 02 00 00 00       	mov    $0x2,%eax
  800b1c:	89 d1                	mov    %edx,%ecx
  800b1e:	89 d3                	mov    %edx,%ebx
  800b20:	89 d7                	mov    %edx,%edi
  800b22:	89 d6                	mov    %edx,%esi
  800b24:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800b26:	5b                   	pop    %ebx
  800b27:	5e                   	pop    %esi
  800b28:	5f                   	pop    %edi
  800b29:	5d                   	pop    %ebp
  800b2a:	c3                   	ret    

00800b2b <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800b2b:	55                   	push   %ebp
  800b2c:	89 e5                	mov    %esp,%ebp
  800b2e:	56                   	push   %esi
  800b2f:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800b30:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800b33:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800b39:	e8 ce ff ff ff       	call   800b0c <sys_getenvid>
  800b3e:	83 ec 0c             	sub    $0xc,%esp
  800b41:	ff 75 0c             	pushl  0xc(%ebp)
  800b44:	ff 75 08             	pushl  0x8(%ebp)
  800b47:	56                   	push   %esi
  800b48:	50                   	push   %eax
  800b49:	68 8c 10 80 00       	push   $0x80108c
  800b4e:	e8 f0 f5 ff ff       	call   800143 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800b53:	83 c4 18             	add    $0x18,%esp
  800b56:	53                   	push   %ebx
  800b57:	ff 75 10             	pushl  0x10(%ebp)
  800b5a:	e8 93 f5 ff ff       	call   8000f2 <vcprintf>
	cprintf("\n");
  800b5f:	c7 04 24 2c 0e 80 00 	movl   $0x800e2c,(%esp)
  800b66:	e8 d8 f5 ff ff       	call   800143 <cprintf>
  800b6b:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800b6e:	cc                   	int3   
  800b6f:	eb fd                	jmp    800b6e <_panic+0x43>
  800b71:	66 90                	xchg   %ax,%ax
  800b73:	66 90                	xchg   %ax,%ax
  800b75:	66 90                	xchg   %ax,%ax
  800b77:	66 90                	xchg   %ax,%ax
  800b79:	66 90                	xchg   %ax,%ax
  800b7b:	66 90                	xchg   %ax,%ax
  800b7d:	66 90                	xchg   %ax,%ax
  800b7f:	90                   	nop

00800b80 <__udivdi3>:
  800b80:	55                   	push   %ebp
  800b81:	57                   	push   %edi
  800b82:	56                   	push   %esi
  800b83:	53                   	push   %ebx
  800b84:	83 ec 1c             	sub    $0x1c,%esp
  800b87:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  800b8b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  800b8f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  800b93:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800b97:	85 f6                	test   %esi,%esi
  800b99:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800b9d:	89 ca                	mov    %ecx,%edx
  800b9f:	89 f8                	mov    %edi,%eax
  800ba1:	75 3d                	jne    800be0 <__udivdi3+0x60>
  800ba3:	39 cf                	cmp    %ecx,%edi
  800ba5:	0f 87 c5 00 00 00    	ja     800c70 <__udivdi3+0xf0>
  800bab:	85 ff                	test   %edi,%edi
  800bad:	89 fd                	mov    %edi,%ebp
  800baf:	75 0b                	jne    800bbc <__udivdi3+0x3c>
  800bb1:	b8 01 00 00 00       	mov    $0x1,%eax
  800bb6:	31 d2                	xor    %edx,%edx
  800bb8:	f7 f7                	div    %edi
  800bba:	89 c5                	mov    %eax,%ebp
  800bbc:	89 c8                	mov    %ecx,%eax
  800bbe:	31 d2                	xor    %edx,%edx
  800bc0:	f7 f5                	div    %ebp
  800bc2:	89 c1                	mov    %eax,%ecx
  800bc4:	89 d8                	mov    %ebx,%eax
  800bc6:	89 cf                	mov    %ecx,%edi
  800bc8:	f7 f5                	div    %ebp
  800bca:	89 c3                	mov    %eax,%ebx
  800bcc:	89 d8                	mov    %ebx,%eax
  800bce:	89 fa                	mov    %edi,%edx
  800bd0:	83 c4 1c             	add    $0x1c,%esp
  800bd3:	5b                   	pop    %ebx
  800bd4:	5e                   	pop    %esi
  800bd5:	5f                   	pop    %edi
  800bd6:	5d                   	pop    %ebp
  800bd7:	c3                   	ret    
  800bd8:	90                   	nop
  800bd9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800be0:	39 ce                	cmp    %ecx,%esi
  800be2:	77 74                	ja     800c58 <__udivdi3+0xd8>
  800be4:	0f bd fe             	bsr    %esi,%edi
  800be7:	83 f7 1f             	xor    $0x1f,%edi
  800bea:	0f 84 98 00 00 00    	je     800c88 <__udivdi3+0x108>
  800bf0:	bb 20 00 00 00       	mov    $0x20,%ebx
  800bf5:	89 f9                	mov    %edi,%ecx
  800bf7:	89 c5                	mov    %eax,%ebp
  800bf9:	29 fb                	sub    %edi,%ebx
  800bfb:	d3 e6                	shl    %cl,%esi
  800bfd:	89 d9                	mov    %ebx,%ecx
  800bff:	d3 ed                	shr    %cl,%ebp
  800c01:	89 f9                	mov    %edi,%ecx
  800c03:	d3 e0                	shl    %cl,%eax
  800c05:	09 ee                	or     %ebp,%esi
  800c07:	89 d9                	mov    %ebx,%ecx
  800c09:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800c0d:	89 d5                	mov    %edx,%ebp
  800c0f:	8b 44 24 08          	mov    0x8(%esp),%eax
  800c13:	d3 ed                	shr    %cl,%ebp
  800c15:	89 f9                	mov    %edi,%ecx
  800c17:	d3 e2                	shl    %cl,%edx
  800c19:	89 d9                	mov    %ebx,%ecx
  800c1b:	d3 e8                	shr    %cl,%eax
  800c1d:	09 c2                	or     %eax,%edx
  800c1f:	89 d0                	mov    %edx,%eax
  800c21:	89 ea                	mov    %ebp,%edx
  800c23:	f7 f6                	div    %esi
  800c25:	89 d5                	mov    %edx,%ebp
  800c27:	89 c3                	mov    %eax,%ebx
  800c29:	f7 64 24 0c          	mull   0xc(%esp)
  800c2d:	39 d5                	cmp    %edx,%ebp
  800c2f:	72 10                	jb     800c41 <__udivdi3+0xc1>
  800c31:	8b 74 24 08          	mov    0x8(%esp),%esi
  800c35:	89 f9                	mov    %edi,%ecx
  800c37:	d3 e6                	shl    %cl,%esi
  800c39:	39 c6                	cmp    %eax,%esi
  800c3b:	73 07                	jae    800c44 <__udivdi3+0xc4>
  800c3d:	39 d5                	cmp    %edx,%ebp
  800c3f:	75 03                	jne    800c44 <__udivdi3+0xc4>
  800c41:	83 eb 01             	sub    $0x1,%ebx
  800c44:	31 ff                	xor    %edi,%edi
  800c46:	89 d8                	mov    %ebx,%eax
  800c48:	89 fa                	mov    %edi,%edx
  800c4a:	83 c4 1c             	add    $0x1c,%esp
  800c4d:	5b                   	pop    %ebx
  800c4e:	5e                   	pop    %esi
  800c4f:	5f                   	pop    %edi
  800c50:	5d                   	pop    %ebp
  800c51:	c3                   	ret    
  800c52:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800c58:	31 ff                	xor    %edi,%edi
  800c5a:	31 db                	xor    %ebx,%ebx
  800c5c:	89 d8                	mov    %ebx,%eax
  800c5e:	89 fa                	mov    %edi,%edx
  800c60:	83 c4 1c             	add    $0x1c,%esp
  800c63:	5b                   	pop    %ebx
  800c64:	5e                   	pop    %esi
  800c65:	5f                   	pop    %edi
  800c66:	5d                   	pop    %ebp
  800c67:	c3                   	ret    
  800c68:	90                   	nop
  800c69:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800c70:	89 d8                	mov    %ebx,%eax
  800c72:	f7 f7                	div    %edi
  800c74:	31 ff                	xor    %edi,%edi
  800c76:	89 c3                	mov    %eax,%ebx
  800c78:	89 d8                	mov    %ebx,%eax
  800c7a:	89 fa                	mov    %edi,%edx
  800c7c:	83 c4 1c             	add    $0x1c,%esp
  800c7f:	5b                   	pop    %ebx
  800c80:	5e                   	pop    %esi
  800c81:	5f                   	pop    %edi
  800c82:	5d                   	pop    %ebp
  800c83:	c3                   	ret    
  800c84:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800c88:	39 ce                	cmp    %ecx,%esi
  800c8a:	72 0c                	jb     800c98 <__udivdi3+0x118>
  800c8c:	31 db                	xor    %ebx,%ebx
  800c8e:	3b 44 24 08          	cmp    0x8(%esp),%eax
  800c92:	0f 87 34 ff ff ff    	ja     800bcc <__udivdi3+0x4c>
  800c98:	bb 01 00 00 00       	mov    $0x1,%ebx
  800c9d:	e9 2a ff ff ff       	jmp    800bcc <__udivdi3+0x4c>
  800ca2:	66 90                	xchg   %ax,%ax
  800ca4:	66 90                	xchg   %ax,%ax
  800ca6:	66 90                	xchg   %ax,%ax
  800ca8:	66 90                	xchg   %ax,%ax
  800caa:	66 90                	xchg   %ax,%ax
  800cac:	66 90                	xchg   %ax,%ax
  800cae:	66 90                	xchg   %ax,%ax

00800cb0 <__umoddi3>:
  800cb0:	55                   	push   %ebp
  800cb1:	57                   	push   %edi
  800cb2:	56                   	push   %esi
  800cb3:	53                   	push   %ebx
  800cb4:	83 ec 1c             	sub    $0x1c,%esp
  800cb7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  800cbb:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  800cbf:	8b 74 24 34          	mov    0x34(%esp),%esi
  800cc3:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800cc7:	85 d2                	test   %edx,%edx
  800cc9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800ccd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800cd1:	89 f3                	mov    %esi,%ebx
  800cd3:	89 3c 24             	mov    %edi,(%esp)
  800cd6:	89 74 24 04          	mov    %esi,0x4(%esp)
  800cda:	75 1c                	jne    800cf8 <__umoddi3+0x48>
  800cdc:	39 f7                	cmp    %esi,%edi
  800cde:	76 50                	jbe    800d30 <__umoddi3+0x80>
  800ce0:	89 c8                	mov    %ecx,%eax
  800ce2:	89 f2                	mov    %esi,%edx
  800ce4:	f7 f7                	div    %edi
  800ce6:	89 d0                	mov    %edx,%eax
  800ce8:	31 d2                	xor    %edx,%edx
  800cea:	83 c4 1c             	add    $0x1c,%esp
  800ced:	5b                   	pop    %ebx
  800cee:	5e                   	pop    %esi
  800cef:	5f                   	pop    %edi
  800cf0:	5d                   	pop    %ebp
  800cf1:	c3                   	ret    
  800cf2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800cf8:	39 f2                	cmp    %esi,%edx
  800cfa:	89 d0                	mov    %edx,%eax
  800cfc:	77 52                	ja     800d50 <__umoddi3+0xa0>
  800cfe:	0f bd ea             	bsr    %edx,%ebp
  800d01:	83 f5 1f             	xor    $0x1f,%ebp
  800d04:	75 5a                	jne    800d60 <__umoddi3+0xb0>
  800d06:	3b 54 24 04          	cmp    0x4(%esp),%edx
  800d0a:	0f 82 e0 00 00 00    	jb     800df0 <__umoddi3+0x140>
  800d10:	39 0c 24             	cmp    %ecx,(%esp)
  800d13:	0f 86 d7 00 00 00    	jbe    800df0 <__umoddi3+0x140>
  800d19:	8b 44 24 08          	mov    0x8(%esp),%eax
  800d1d:	8b 54 24 04          	mov    0x4(%esp),%edx
  800d21:	83 c4 1c             	add    $0x1c,%esp
  800d24:	5b                   	pop    %ebx
  800d25:	5e                   	pop    %esi
  800d26:	5f                   	pop    %edi
  800d27:	5d                   	pop    %ebp
  800d28:	c3                   	ret    
  800d29:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800d30:	85 ff                	test   %edi,%edi
  800d32:	89 fd                	mov    %edi,%ebp
  800d34:	75 0b                	jne    800d41 <__umoddi3+0x91>
  800d36:	b8 01 00 00 00       	mov    $0x1,%eax
  800d3b:	31 d2                	xor    %edx,%edx
  800d3d:	f7 f7                	div    %edi
  800d3f:	89 c5                	mov    %eax,%ebp
  800d41:	89 f0                	mov    %esi,%eax
  800d43:	31 d2                	xor    %edx,%edx
  800d45:	f7 f5                	div    %ebp
  800d47:	89 c8                	mov    %ecx,%eax
  800d49:	f7 f5                	div    %ebp
  800d4b:	89 d0                	mov    %edx,%eax
  800d4d:	eb 99                	jmp    800ce8 <__umoddi3+0x38>
  800d4f:	90                   	nop
  800d50:	89 c8                	mov    %ecx,%eax
  800d52:	89 f2                	mov    %esi,%edx
  800d54:	83 c4 1c             	add    $0x1c,%esp
  800d57:	5b                   	pop    %ebx
  800d58:	5e                   	pop    %esi
  800d59:	5f                   	pop    %edi
  800d5a:	5d                   	pop    %ebp
  800d5b:	c3                   	ret    
  800d5c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800d60:	8b 34 24             	mov    (%esp),%esi
  800d63:	bf 20 00 00 00       	mov    $0x20,%edi
  800d68:	89 e9                	mov    %ebp,%ecx
  800d6a:	29 ef                	sub    %ebp,%edi
  800d6c:	d3 e0                	shl    %cl,%eax
  800d6e:	89 f9                	mov    %edi,%ecx
  800d70:	89 f2                	mov    %esi,%edx
  800d72:	d3 ea                	shr    %cl,%edx
  800d74:	89 e9                	mov    %ebp,%ecx
  800d76:	09 c2                	or     %eax,%edx
  800d78:	89 d8                	mov    %ebx,%eax
  800d7a:	89 14 24             	mov    %edx,(%esp)
  800d7d:	89 f2                	mov    %esi,%edx
  800d7f:	d3 e2                	shl    %cl,%edx
  800d81:	89 f9                	mov    %edi,%ecx
  800d83:	89 54 24 04          	mov    %edx,0x4(%esp)
  800d87:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800d8b:	d3 e8                	shr    %cl,%eax
  800d8d:	89 e9                	mov    %ebp,%ecx
  800d8f:	89 c6                	mov    %eax,%esi
  800d91:	d3 e3                	shl    %cl,%ebx
  800d93:	89 f9                	mov    %edi,%ecx
  800d95:	89 d0                	mov    %edx,%eax
  800d97:	d3 e8                	shr    %cl,%eax
  800d99:	89 e9                	mov    %ebp,%ecx
  800d9b:	09 d8                	or     %ebx,%eax
  800d9d:	89 d3                	mov    %edx,%ebx
  800d9f:	89 f2                	mov    %esi,%edx
  800da1:	f7 34 24             	divl   (%esp)
  800da4:	89 d6                	mov    %edx,%esi
  800da6:	d3 e3                	shl    %cl,%ebx
  800da8:	f7 64 24 04          	mull   0x4(%esp)
  800dac:	39 d6                	cmp    %edx,%esi
  800dae:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800db2:	89 d1                	mov    %edx,%ecx
  800db4:	89 c3                	mov    %eax,%ebx
  800db6:	72 08                	jb     800dc0 <__umoddi3+0x110>
  800db8:	75 11                	jne    800dcb <__umoddi3+0x11b>
  800dba:	39 44 24 08          	cmp    %eax,0x8(%esp)
  800dbe:	73 0b                	jae    800dcb <__umoddi3+0x11b>
  800dc0:	2b 44 24 04          	sub    0x4(%esp),%eax
  800dc4:	1b 14 24             	sbb    (%esp),%edx
  800dc7:	89 d1                	mov    %edx,%ecx
  800dc9:	89 c3                	mov    %eax,%ebx
  800dcb:	8b 54 24 08          	mov    0x8(%esp),%edx
  800dcf:	29 da                	sub    %ebx,%edx
  800dd1:	19 ce                	sbb    %ecx,%esi
  800dd3:	89 f9                	mov    %edi,%ecx
  800dd5:	89 f0                	mov    %esi,%eax
  800dd7:	d3 e0                	shl    %cl,%eax
  800dd9:	89 e9                	mov    %ebp,%ecx
  800ddb:	d3 ea                	shr    %cl,%edx
  800ddd:	89 e9                	mov    %ebp,%ecx
  800ddf:	d3 ee                	shr    %cl,%esi
  800de1:	09 d0                	or     %edx,%eax
  800de3:	89 f2                	mov    %esi,%edx
  800de5:	83 c4 1c             	add    $0x1c,%esp
  800de8:	5b                   	pop    %ebx
  800de9:	5e                   	pop    %esi
  800dea:	5f                   	pop    %edi
  800deb:	5d                   	pop    %ebp
  800dec:	c3                   	ret    
  800ded:	8d 76 00             	lea    0x0(%esi),%esi
  800df0:	29 f9                	sub    %edi,%ecx
  800df2:	19 d6                	sbb    %edx,%esi
  800df4:	89 74 24 04          	mov    %esi,0x4(%esp)
  800df8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800dfc:	e9 18 ff ff ff       	jmp    800d19 <__umoddi3+0x69>
