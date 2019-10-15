
obj/kern/kernel：     文件格式 elf32-i386


セクション .text の逆アセンブル:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 56 00 00 00       	call   f0100094 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 0c             	sub    $0xc,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	53                   	push   %ebx
f010004b:	68 60 18 10 f0       	push   $0xf0101860
f0100050:	e8 0d 09 00 00       	call   f0100962 <cprintf>
	if (x > 0)
f0100055:	83 c4 10             	add    $0x10,%esp
f0100058:	85 db                	test   %ebx,%ebx
f010005a:	7e 11                	jle    f010006d <test_backtrace+0x2d>
		test_backtrace(x-1);
f010005c:	83 ec 0c             	sub    $0xc,%esp
f010005f:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100062:	50                   	push   %eax
f0100063:	e8 d8 ff ff ff       	call   f0100040 <test_backtrace>
f0100068:	83 c4 10             	add    $0x10,%esp
f010006b:	eb 11                	jmp    f010007e <test_backtrace+0x3e>
	else
		mon_backtrace(0, 0, 0);
f010006d:	83 ec 04             	sub    $0x4,%esp
f0100070:	6a 00                	push   $0x0
f0100072:	6a 00                	push   $0x0
f0100074:	6a 00                	push   $0x0
f0100076:	e8 e5 06 00 00       	call   f0100760 <mon_backtrace>
f010007b:	83 c4 10             	add    $0x10,%esp
	cprintf("leaving test_backtrace %d\n", x);
f010007e:	83 ec 08             	sub    $0x8,%esp
f0100081:	53                   	push   %ebx
f0100082:	68 7c 18 10 f0       	push   $0xf010187c
f0100087:	e8 d6 08 00 00       	call   f0100962 <cprintf>
}
f010008c:	83 c4 10             	add    $0x10,%esp
f010008f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100092:	c9                   	leave  
f0100093:	c3                   	ret    

f0100094 <i386_init>:

void
i386_init(void)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f010009a:	b8 44 29 11 f0       	mov    $0xf0112944,%eax
f010009f:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000a4:	50                   	push   %eax
f01000a5:	6a 00                	push   $0x0
f01000a7:	68 00 23 11 f0       	push   $0xf0112300
f01000ac:	e8 1b 13 00 00       	call   f01013cc <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b1:	e8 8f 04 00 00       	call   f0100545 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000b6:	83 c4 08             	add    $0x8,%esp
f01000b9:	68 ac 1a 00 00       	push   $0x1aac
f01000be:	68 97 18 10 f0       	push   $0xf0101897
f01000c3:	e8 9a 08 00 00       	call   f0100962 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000c8:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000cf:	e8 6c ff ff ff       	call   f0100040 <test_backtrace>
f01000d4:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000d7:	83 ec 0c             	sub    $0xc,%esp
f01000da:	6a 00                	push   $0x0
f01000dc:	e8 01 07 00 00       	call   f01007e2 <monitor>
f01000e1:	83 c4 10             	add    $0x10,%esp
f01000e4:	eb f1                	jmp    f01000d7 <i386_init+0x43>

f01000e6 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000e6:	55                   	push   %ebp
f01000e7:	89 e5                	mov    %esp,%ebp
f01000e9:	56                   	push   %esi
f01000ea:	53                   	push   %ebx
f01000eb:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000ee:	83 3d 40 29 11 f0 00 	cmpl   $0x0,0xf0112940
f01000f5:	75 37                	jne    f010012e <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000f7:	89 35 40 29 11 f0    	mov    %esi,0xf0112940

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000fd:	fa                   	cli    
f01000fe:	fc                   	cld    

	va_start(ap, fmt);
f01000ff:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100102:	83 ec 04             	sub    $0x4,%esp
f0100105:	ff 75 0c             	pushl  0xc(%ebp)
f0100108:	ff 75 08             	pushl  0x8(%ebp)
f010010b:	68 b2 18 10 f0       	push   $0xf01018b2
f0100110:	e8 4d 08 00 00       	call   f0100962 <cprintf>
	vcprintf(fmt, ap);
f0100115:	83 c4 08             	add    $0x8,%esp
f0100118:	53                   	push   %ebx
f0100119:	56                   	push   %esi
f010011a:	e8 1d 08 00 00       	call   f010093c <vcprintf>
	cprintf("\n");
f010011f:	c7 04 24 ee 18 10 f0 	movl   $0xf01018ee,(%esp)
f0100126:	e8 37 08 00 00       	call   f0100962 <cprintf>
	va_end(ap);
f010012b:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010012e:	83 ec 0c             	sub    $0xc,%esp
f0100131:	6a 00                	push   $0x0
f0100133:	e8 aa 06 00 00       	call   f01007e2 <monitor>
f0100138:	83 c4 10             	add    $0x10,%esp
f010013b:	eb f1                	jmp    f010012e <_panic+0x48>

f010013d <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010013d:	55                   	push   %ebp
f010013e:	89 e5                	mov    %esp,%ebp
f0100140:	53                   	push   %ebx
f0100141:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100144:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100147:	ff 75 0c             	pushl  0xc(%ebp)
f010014a:	ff 75 08             	pushl  0x8(%ebp)
f010014d:	68 ca 18 10 f0       	push   $0xf01018ca
f0100152:	e8 0b 08 00 00       	call   f0100962 <cprintf>
	vcprintf(fmt, ap);
f0100157:	83 c4 08             	add    $0x8,%esp
f010015a:	53                   	push   %ebx
f010015b:	ff 75 10             	pushl  0x10(%ebp)
f010015e:	e8 d9 07 00 00       	call   f010093c <vcprintf>
	cprintf("\n");
f0100163:	c7 04 24 ee 18 10 f0 	movl   $0xf01018ee,(%esp)
f010016a:	e8 f3 07 00 00       	call   f0100962 <cprintf>
	va_end(ap);
}
f010016f:	83 c4 10             	add    $0x10,%esp
f0100172:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100175:	c9                   	leave  
f0100176:	c3                   	ret    

f0100177 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100177:	55                   	push   %ebp
f0100178:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010017a:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010017f:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100180:	a8 01                	test   $0x1,%al
f0100182:	74 0b                	je     f010018f <serial_proc_data+0x18>
f0100184:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100189:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010018a:	0f b6 c0             	movzbl %al,%eax
f010018d:	eb 05                	jmp    f0100194 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f010018f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100194:	5d                   	pop    %ebp
f0100195:	c3                   	ret    

f0100196 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100196:	55                   	push   %ebp
f0100197:	89 e5                	mov    %esp,%ebp
f0100199:	53                   	push   %ebx
f010019a:	83 ec 04             	sub    $0x4,%esp
f010019d:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f010019f:	eb 2b                	jmp    f01001cc <cons_intr+0x36>
		if (c == 0)
f01001a1:	85 c0                	test   %eax,%eax
f01001a3:	74 27                	je     f01001cc <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f01001a5:	8b 0d 24 25 11 f0    	mov    0xf0112524,%ecx
f01001ab:	8d 51 01             	lea    0x1(%ecx),%edx
f01001ae:	89 15 24 25 11 f0    	mov    %edx,0xf0112524
f01001b4:	88 81 20 23 11 f0    	mov    %al,-0xfeedce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f01001ba:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01001c0:	75 0a                	jne    f01001cc <cons_intr+0x36>
			cons.wpos = 0;
f01001c2:	c7 05 24 25 11 f0 00 	movl   $0x0,0xf0112524
f01001c9:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001cc:	ff d3                	call   *%ebx
f01001ce:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001d1:	75 ce                	jne    f01001a1 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001d3:	83 c4 04             	add    $0x4,%esp
f01001d6:	5b                   	pop    %ebx
f01001d7:	5d                   	pop    %ebp
f01001d8:	c3                   	ret    

f01001d9 <kbd_proc_data>:
f01001d9:	ba 64 00 00 00       	mov    $0x64,%edx
f01001de:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01001df:	a8 01                	test   $0x1,%al
f01001e1:	0f 84 f0 00 00 00    	je     f01002d7 <kbd_proc_data+0xfe>
f01001e7:	ba 60 00 00 00       	mov    $0x60,%edx
f01001ec:	ec                   	in     (%dx),%al
f01001ed:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001ef:	3c e0                	cmp    $0xe0,%al
f01001f1:	75 0d                	jne    f0100200 <kbd_proc_data+0x27>
		// E0 escape character
		shift |= E0ESC;
f01001f3:	83 0d 00 23 11 f0 40 	orl    $0x40,0xf0112300
		return 0;
f01001fa:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001ff:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100200:	55                   	push   %ebp
f0100201:	89 e5                	mov    %esp,%ebp
f0100203:	53                   	push   %ebx
f0100204:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f0100207:	84 c0                	test   %al,%al
f0100209:	79 36                	jns    f0100241 <kbd_proc_data+0x68>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f010020b:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100211:	89 cb                	mov    %ecx,%ebx
f0100213:	83 e3 40             	and    $0x40,%ebx
f0100216:	83 e0 7f             	and    $0x7f,%eax
f0100219:	85 db                	test   %ebx,%ebx
f010021b:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f010021e:	0f b6 d2             	movzbl %dl,%edx
f0100221:	0f b6 82 40 1a 10 f0 	movzbl -0xfefe5c0(%edx),%eax
f0100228:	83 c8 40             	or     $0x40,%eax
f010022b:	0f b6 c0             	movzbl %al,%eax
f010022e:	f7 d0                	not    %eax
f0100230:	21 c8                	and    %ecx,%eax
f0100232:	a3 00 23 11 f0       	mov    %eax,0xf0112300
		return 0;
f0100237:	b8 00 00 00 00       	mov    $0x0,%eax
f010023c:	e9 9e 00 00 00       	jmp    f01002df <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f0100241:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100247:	f6 c1 40             	test   $0x40,%cl
f010024a:	74 0e                	je     f010025a <kbd_proc_data+0x81>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f010024c:	83 c8 80             	or     $0xffffff80,%eax
f010024f:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100251:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100254:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
	}

	shift |= shiftcode[data];
f010025a:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f010025d:	0f b6 82 40 1a 10 f0 	movzbl -0xfefe5c0(%edx),%eax
f0100264:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
f010026a:	0f b6 8a 40 19 10 f0 	movzbl -0xfefe6c0(%edx),%ecx
f0100271:	31 c8                	xor    %ecx,%eax
f0100273:	a3 00 23 11 f0       	mov    %eax,0xf0112300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100278:	89 c1                	mov    %eax,%ecx
f010027a:	83 e1 03             	and    $0x3,%ecx
f010027d:	8b 0c 8d 20 19 10 f0 	mov    -0xfefe6e0(,%ecx,4),%ecx
f0100284:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100288:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f010028b:	a8 08                	test   $0x8,%al
f010028d:	74 1b                	je     f01002aa <kbd_proc_data+0xd1>
		if ('a' <= c && c <= 'z')
f010028f:	89 da                	mov    %ebx,%edx
f0100291:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100294:	83 f9 19             	cmp    $0x19,%ecx
f0100297:	77 05                	ja     f010029e <kbd_proc_data+0xc5>
			c += 'A' - 'a';
f0100299:	83 eb 20             	sub    $0x20,%ebx
f010029c:	eb 0c                	jmp    f01002aa <kbd_proc_data+0xd1>
		else if ('A' <= c && c <= 'Z')
f010029e:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002a1:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002a4:	83 fa 19             	cmp    $0x19,%edx
f01002a7:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002aa:	f7 d0                	not    %eax
f01002ac:	a8 06                	test   $0x6,%al
f01002ae:	75 2d                	jne    f01002dd <kbd_proc_data+0x104>
f01002b0:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002b6:	75 25                	jne    f01002dd <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f01002b8:	83 ec 0c             	sub    $0xc,%esp
f01002bb:	68 e4 18 10 f0       	push   $0xf01018e4
f01002c0:	e8 9d 06 00 00       	call   f0100962 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002c5:	ba 92 00 00 00       	mov    $0x92,%edx
f01002ca:	b8 03 00 00 00       	mov    $0x3,%eax
f01002cf:	ee                   	out    %al,(%dx)
f01002d0:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002d3:	89 d8                	mov    %ebx,%eax
f01002d5:	eb 08                	jmp    f01002df <kbd_proc_data+0x106>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01002d7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002dc:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002dd:	89 d8                	mov    %ebx,%eax
}
f01002df:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01002e2:	c9                   	leave  
f01002e3:	c3                   	ret    

f01002e4 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002e4:	55                   	push   %ebp
f01002e5:	89 e5                	mov    %esp,%ebp
f01002e7:	57                   	push   %edi
f01002e8:	56                   	push   %esi
f01002e9:	53                   	push   %ebx
f01002ea:	83 ec 1c             	sub    $0x1c,%esp
f01002ed:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002ef:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002f4:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002f9:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002fe:	eb 09                	jmp    f0100309 <cons_putc+0x25>
f0100300:	89 ca                	mov    %ecx,%edx
f0100302:	ec                   	in     (%dx),%al
f0100303:	ec                   	in     (%dx),%al
f0100304:	ec                   	in     (%dx),%al
f0100305:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f0100306:	83 c3 01             	add    $0x1,%ebx
f0100309:	89 f2                	mov    %esi,%edx
f010030b:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010030c:	a8 20                	test   $0x20,%al
f010030e:	75 08                	jne    f0100318 <cons_putc+0x34>
f0100310:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100316:	7e e8                	jle    f0100300 <cons_putc+0x1c>
f0100318:	89 f8                	mov    %edi,%eax
f010031a:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010031d:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100322:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100323:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100328:	be 79 03 00 00       	mov    $0x379,%esi
f010032d:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100332:	eb 09                	jmp    f010033d <cons_putc+0x59>
f0100334:	89 ca                	mov    %ecx,%edx
f0100336:	ec                   	in     (%dx),%al
f0100337:	ec                   	in     (%dx),%al
f0100338:	ec                   	in     (%dx),%al
f0100339:	ec                   	in     (%dx),%al
f010033a:	83 c3 01             	add    $0x1,%ebx
f010033d:	89 f2                	mov    %esi,%edx
f010033f:	ec                   	in     (%dx),%al
f0100340:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100346:	7f 04                	jg     f010034c <cons_putc+0x68>
f0100348:	84 c0                	test   %al,%al
f010034a:	79 e8                	jns    f0100334 <cons_putc+0x50>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010034c:	ba 78 03 00 00       	mov    $0x378,%edx
f0100351:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100355:	ee                   	out    %al,(%dx)
f0100356:	ba 7a 03 00 00       	mov    $0x37a,%edx
f010035b:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100360:	ee                   	out    %al,(%dx)
f0100361:	b8 08 00 00 00       	mov    $0x8,%eax
f0100366:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF)) // set color
f0100367:	89 fa                	mov    %edi,%edx
f0100369:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010036f:	89 f8                	mov    %edi,%eax
f0100371:	80 cc 07             	or     $0x7,%ah
f0100374:	85 d2                	test   %edx,%edx
f0100376:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100379:	89 f8                	mov    %edi,%eax
f010037b:	0f b6 c0             	movzbl %al,%eax
f010037e:	83 f8 09             	cmp    $0x9,%eax
f0100381:	74 74                	je     f01003f7 <cons_putc+0x113>
f0100383:	83 f8 09             	cmp    $0x9,%eax
f0100386:	7f 0a                	jg     f0100392 <cons_putc+0xae>
f0100388:	83 f8 08             	cmp    $0x8,%eax
f010038b:	74 14                	je     f01003a1 <cons_putc+0xbd>
f010038d:	e9 99 00 00 00       	jmp    f010042b <cons_putc+0x147>
f0100392:	83 f8 0a             	cmp    $0xa,%eax
f0100395:	74 3a                	je     f01003d1 <cons_putc+0xed>
f0100397:	83 f8 0d             	cmp    $0xd,%eax
f010039a:	74 3d                	je     f01003d9 <cons_putc+0xf5>
f010039c:	e9 8a 00 00 00       	jmp    f010042b <cons_putc+0x147>
	case '\b':   //退格
		if (crt_pos > 0) {
f01003a1:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003a8:	66 85 c0             	test   %ax,%ax
f01003ab:	0f 84 e6 00 00 00    	je     f0100497 <cons_putc+0x1b3>
			crt_pos--;
f01003b1:	83 e8 01             	sub    $0x1,%eax
f01003b4:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003ba:	0f b7 c0             	movzwl %ax,%eax
f01003bd:	66 81 e7 00 ff       	and    $0xff00,%di
f01003c2:	83 cf 20             	or     $0x20,%edi
f01003c5:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f01003cb:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003cf:	eb 78                	jmp    f0100449 <cons_putc+0x165>
		}
		break;
	case '\n':   //换行
		crt_pos += CRT_COLS;
f01003d1:	66 83 05 28 25 11 f0 	addw   $0x50,0xf0112528
f01003d8:	50 
		/* fallthru */
	case '\r':   //将光标位置移到本行开头
		crt_pos -= (crt_pos % CRT_COLS);
f01003d9:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003e0:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003e6:	c1 e8 16             	shr    $0x16,%eax
f01003e9:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003ec:	c1 e0 04             	shl    $0x4,%eax
f01003ef:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
f01003f5:	eb 52                	jmp    f0100449 <cons_putc+0x165>
		break;
	case '\t':   //水平制表TAB
		cons_putc(' ');
f01003f7:	b8 20 00 00 00       	mov    $0x20,%eax
f01003fc:	e8 e3 fe ff ff       	call   f01002e4 <cons_putc>
		cons_putc(' ');
f0100401:	b8 20 00 00 00       	mov    $0x20,%eax
f0100406:	e8 d9 fe ff ff       	call   f01002e4 <cons_putc>
		cons_putc(' ');
f010040b:	b8 20 00 00 00       	mov    $0x20,%eax
f0100410:	e8 cf fe ff ff       	call   f01002e4 <cons_putc>
		cons_putc(' ');
f0100415:	b8 20 00 00 00       	mov    $0x20,%eax
f010041a:	e8 c5 fe ff ff       	call   f01002e4 <cons_putc>
		cons_putc(' ');
f010041f:	b8 20 00 00 00       	mov    $0x20,%eax
f0100424:	e8 bb fe ff ff       	call   f01002e4 <cons_putc>
f0100429:	eb 1e                	jmp    f0100449 <cons_putc+0x165>
		break;
	default:   //如果不是转义字符就正常打印，光标位置+1
		crt_buf[crt_pos++] = c;		/* write the character */
f010042b:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f0100432:	8d 50 01             	lea    0x1(%eax),%edx
f0100435:	66 89 15 28 25 11 f0 	mov    %dx,0xf0112528
f010043c:	0f b7 c0             	movzwl %ax,%eax
f010043f:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100445:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) { //如果光标超出了缓冲区大小，即超出当前屏幕范围
f0100449:	66 81 3d 28 25 11 f0 	cmpw   $0x7cf,0xf0112528
f0100450:	cf 07 
f0100452:	76 43                	jbe    f0100497 <cons_putc+0x1b3>
		int i;
        //    缓冲区     缓冲区下一行         缓冲区大小减去一行
        //把输出缓冲区的第一行移除，把剩下的内容替换当前缓冲区的内容		
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100454:	a1 2c 25 11 f0       	mov    0xf011252c,%eax
f0100459:	83 ec 04             	sub    $0x4,%esp
f010045c:	68 00 0f 00 00       	push   $0xf00
f0100461:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100467:	52                   	push   %edx
f0100468:	50                   	push   %eax
f0100469:	e8 ab 0f 00 00       	call   f0101419 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' '; //将最后一行清空，全部置为' '
f010046e:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100474:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f010047a:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100480:	83 c4 10             	add    $0x10,%esp
f0100483:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100488:	83 c0 02             	add    $0x2,%eax
	if (crt_pos >= CRT_SIZE) { //如果光标超出了缓冲区大小，即超出当前屏幕范围
		int i;
        //    缓冲区     缓冲区下一行         缓冲区大小减去一行
        //把输出缓冲区的第一行移除，把剩下的内容替换当前缓冲区的内容		
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010048b:	39 d0                	cmp    %edx,%eax
f010048d:	75 f4                	jne    f0100483 <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' '; //将最后一行清空，全部置为' '
		crt_pos -= CRT_COLS;  //光标移到最后一行的开头
f010048f:	66 83 2d 28 25 11 f0 	subw   $0x50,0xf0112528
f0100496:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100497:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f010049d:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004a2:	89 ca                	mov    %ecx,%edx
f01004a4:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004a5:	0f b7 1d 28 25 11 f0 	movzwl 0xf0112528,%ebx
f01004ac:	8d 71 01             	lea    0x1(%ecx),%esi
f01004af:	89 d8                	mov    %ebx,%eax
f01004b1:	66 c1 e8 08          	shr    $0x8,%ax
f01004b5:	89 f2                	mov    %esi,%edx
f01004b7:	ee                   	out    %al,(%dx)
f01004b8:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004bd:	89 ca                	mov    %ecx,%edx
f01004bf:	ee                   	out    %al,(%dx)
f01004c0:	89 d8                	mov    %ebx,%eax
f01004c2:	89 f2                	mov    %esi,%edx
f01004c4:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004c5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01004c8:	5b                   	pop    %ebx
f01004c9:	5e                   	pop    %esi
f01004ca:	5f                   	pop    %edi
f01004cb:	5d                   	pop    %ebp
f01004cc:	c3                   	ret    

f01004cd <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004cd:	80 3d 34 25 11 f0 00 	cmpb   $0x0,0xf0112534
f01004d4:	74 11                	je     f01004e7 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004d6:	55                   	push   %ebp
f01004d7:	89 e5                	mov    %esp,%ebp
f01004d9:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004dc:	b8 77 01 10 f0       	mov    $0xf0100177,%eax
f01004e1:	e8 b0 fc ff ff       	call   f0100196 <cons_intr>
}
f01004e6:	c9                   	leave  
f01004e7:	f3 c3                	repz ret 

f01004e9 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004e9:	55                   	push   %ebp
f01004ea:	89 e5                	mov    %esp,%ebp
f01004ec:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004ef:	b8 d9 01 10 f0       	mov    $0xf01001d9,%eax
f01004f4:	e8 9d fc ff ff       	call   f0100196 <cons_intr>
}
f01004f9:	c9                   	leave  
f01004fa:	c3                   	ret    

f01004fb <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004fb:	55                   	push   %ebp
f01004fc:	89 e5                	mov    %esp,%ebp
f01004fe:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f0100501:	e8 c7 ff ff ff       	call   f01004cd <serial_intr>
	kbd_intr();
f0100506:	e8 de ff ff ff       	call   f01004e9 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f010050b:	a1 20 25 11 f0       	mov    0xf0112520,%eax
f0100510:	3b 05 24 25 11 f0    	cmp    0xf0112524,%eax
f0100516:	74 26                	je     f010053e <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100518:	8d 50 01             	lea    0x1(%eax),%edx
f010051b:	89 15 20 25 11 f0    	mov    %edx,0xf0112520
f0100521:	0f b6 88 20 23 11 f0 	movzbl -0xfeedce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100528:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f010052a:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100530:	75 11                	jne    f0100543 <cons_getc+0x48>
			cons.rpos = 0;
f0100532:	c7 05 20 25 11 f0 00 	movl   $0x0,0xf0112520
f0100539:	00 00 00 
f010053c:	eb 05                	jmp    f0100543 <cons_getc+0x48>
		return c;
	}
	return 0;
f010053e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100543:	c9                   	leave  
f0100544:	c3                   	ret    

f0100545 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100545:	55                   	push   %ebp
f0100546:	89 e5                	mov    %esp,%ebp
f0100548:	57                   	push   %edi
f0100549:	56                   	push   %esi
f010054a:	53                   	push   %ebx
f010054b:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f010054e:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100555:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010055c:	5a a5 
	if (*cp != 0xA55A) {
f010055e:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100565:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100569:	74 11                	je     f010057c <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010056b:	c7 05 30 25 11 f0 b4 	movl   $0x3b4,0xf0112530
f0100572:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100575:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f010057a:	eb 16                	jmp    f0100592 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010057c:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100583:	c7 05 30 25 11 f0 d4 	movl   $0x3d4,0xf0112530
f010058a:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010058d:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100592:	8b 3d 30 25 11 f0    	mov    0xf0112530,%edi
f0100598:	b8 0e 00 00 00       	mov    $0xe,%eax
f010059d:	89 fa                	mov    %edi,%edx
f010059f:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005a0:	8d 5f 01             	lea    0x1(%edi),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005a3:	89 da                	mov    %ebx,%edx
f01005a5:	ec                   	in     (%dx),%al
f01005a6:	0f b6 c8             	movzbl %al,%ecx
f01005a9:	c1 e1 08             	shl    $0x8,%ecx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005ac:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005b1:	89 fa                	mov    %edi,%edx
f01005b3:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005b4:	89 da                	mov    %ebx,%edx
f01005b6:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005b7:	89 35 2c 25 11 f0    	mov    %esi,0xf011252c
	crt_pos = pos;
f01005bd:	0f b6 c0             	movzbl %al,%eax
f01005c0:	09 c8                	or     %ecx,%eax
f01005c2:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005c8:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005cd:	b8 00 00 00 00       	mov    $0x0,%eax
f01005d2:	89 f2                	mov    %esi,%edx
f01005d4:	ee                   	out    %al,(%dx)
f01005d5:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005da:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005df:	ee                   	out    %al,(%dx)
f01005e0:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005e5:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005ea:	89 da                	mov    %ebx,%edx
f01005ec:	ee                   	out    %al,(%dx)
f01005ed:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005f2:	b8 00 00 00 00       	mov    $0x0,%eax
f01005f7:	ee                   	out    %al,(%dx)
f01005f8:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005fd:	b8 03 00 00 00       	mov    $0x3,%eax
f0100602:	ee                   	out    %al,(%dx)
f0100603:	ba fc 03 00 00       	mov    $0x3fc,%edx
f0100608:	b8 00 00 00 00       	mov    $0x0,%eax
f010060d:	ee                   	out    %al,(%dx)
f010060e:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100613:	b8 01 00 00 00       	mov    $0x1,%eax
f0100618:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100619:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010061e:	ec                   	in     (%dx),%al
f010061f:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100621:	3c ff                	cmp    $0xff,%al
f0100623:	0f 95 05 34 25 11 f0 	setne  0xf0112534
f010062a:	89 f2                	mov    %esi,%edx
f010062c:	ec                   	in     (%dx),%al
f010062d:	89 da                	mov    %ebx,%edx
f010062f:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100630:	80 f9 ff             	cmp    $0xff,%cl
f0100633:	75 10                	jne    f0100645 <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f0100635:	83 ec 0c             	sub    $0xc,%esp
f0100638:	68 f0 18 10 f0       	push   $0xf01018f0
f010063d:	e8 20 03 00 00       	call   f0100962 <cprintf>
f0100642:	83 c4 10             	add    $0x10,%esp
}
f0100645:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100648:	5b                   	pop    %ebx
f0100649:	5e                   	pop    %esi
f010064a:	5f                   	pop    %edi
f010064b:	5d                   	pop    %ebp
f010064c:	c3                   	ret    

f010064d <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010064d:	55                   	push   %ebp
f010064e:	89 e5                	mov    %esp,%ebp
f0100650:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100653:	8b 45 08             	mov    0x8(%ebp),%eax
f0100656:	e8 89 fc ff ff       	call   f01002e4 <cons_putc>
}
f010065b:	c9                   	leave  
f010065c:	c3                   	ret    

f010065d <getchar>:

int
getchar(void)
{
f010065d:	55                   	push   %ebp
f010065e:	89 e5                	mov    %esp,%ebp
f0100660:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100663:	e8 93 fe ff ff       	call   f01004fb <cons_getc>
f0100668:	85 c0                	test   %eax,%eax
f010066a:	74 f7                	je     f0100663 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010066c:	c9                   	leave  
f010066d:	c3                   	ret    

f010066e <iscons>:

int
iscons(int fdnum)
{
f010066e:	55                   	push   %ebp
f010066f:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100671:	b8 01 00 00 00       	mov    $0x1,%eax
f0100676:	5d                   	pop    %ebp
f0100677:	c3                   	ret    

f0100678 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100678:	55                   	push   %ebp
f0100679:	89 e5                	mov    %esp,%ebp
f010067b:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010067e:	68 40 1b 10 f0       	push   $0xf0101b40
f0100683:	68 5e 1b 10 f0       	push   $0xf0101b5e
f0100688:	68 63 1b 10 f0       	push   $0xf0101b63
f010068d:	e8 d0 02 00 00       	call   f0100962 <cprintf>
f0100692:	83 c4 0c             	add    $0xc,%esp
f0100695:	68 00 1c 10 f0       	push   $0xf0101c00
f010069a:	68 6c 1b 10 f0       	push   $0xf0101b6c
f010069f:	68 63 1b 10 f0       	push   $0xf0101b63
f01006a4:	e8 b9 02 00 00       	call   f0100962 <cprintf>
	return 0;
}
f01006a9:	b8 00 00 00 00       	mov    $0x0,%eax
f01006ae:	c9                   	leave  
f01006af:	c3                   	ret    

f01006b0 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006b0:	55                   	push   %ebp
f01006b1:	89 e5                	mov    %esp,%ebp
f01006b3:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006b6:	68 75 1b 10 f0       	push   $0xf0101b75
f01006bb:	e8 a2 02 00 00       	call   f0100962 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006c0:	83 c4 08             	add    $0x8,%esp
f01006c3:	68 0c 00 10 00       	push   $0x10000c
f01006c8:	68 28 1c 10 f0       	push   $0xf0101c28
f01006cd:	e8 90 02 00 00       	call   f0100962 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006d2:	83 c4 0c             	add    $0xc,%esp
f01006d5:	68 0c 00 10 00       	push   $0x10000c
f01006da:	68 0c 00 10 f0       	push   $0xf010000c
f01006df:	68 50 1c 10 f0       	push   $0xf0101c50
f01006e4:	e8 79 02 00 00       	call   f0100962 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006e9:	83 c4 0c             	add    $0xc,%esp
f01006ec:	68 51 18 10 00       	push   $0x101851
f01006f1:	68 51 18 10 f0       	push   $0xf0101851
f01006f6:	68 74 1c 10 f0       	push   $0xf0101c74
f01006fb:	e8 62 02 00 00       	call   f0100962 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100700:	83 c4 0c             	add    $0xc,%esp
f0100703:	68 00 23 11 00       	push   $0x112300
f0100708:	68 00 23 11 f0       	push   $0xf0112300
f010070d:	68 98 1c 10 f0       	push   $0xf0101c98
f0100712:	e8 4b 02 00 00       	call   f0100962 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100717:	83 c4 0c             	add    $0xc,%esp
f010071a:	68 44 29 11 00       	push   $0x112944
f010071f:	68 44 29 11 f0       	push   $0xf0112944
f0100724:	68 bc 1c 10 f0       	push   $0xf0101cbc
f0100729:	e8 34 02 00 00       	call   f0100962 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010072e:	b8 43 2d 11 f0       	mov    $0xf0112d43,%eax
f0100733:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100738:	83 c4 08             	add    $0x8,%esp
f010073b:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f0100740:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100746:	85 c0                	test   %eax,%eax
f0100748:	0f 48 c2             	cmovs  %edx,%eax
f010074b:	c1 f8 0a             	sar    $0xa,%eax
f010074e:	50                   	push   %eax
f010074f:	68 e0 1c 10 f0       	push   $0xf0101ce0
f0100754:	e8 09 02 00 00       	call   f0100962 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100759:	b8 00 00 00 00       	mov    $0x0,%eax
f010075e:	c9                   	leave  
f010075f:	c3                   	ret    

f0100760 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100760:	55                   	push   %ebp
f0100761:	89 e5                	mov    %esp,%ebp
f0100763:	57                   	push   %edi
f0100764:	56                   	push   %esi
f0100765:	53                   	push   %ebx
f0100766:	83 ec 18             	sub    $0x18,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0100769:	89 e8                	mov    %ebp,%eax
	// Your code here.
	uint32_t *ebp = (uint32_t*)read_ebp(); //定义指向当前ebp寄存器的指针,uint32_t因为寄存器存储的值为32位
f010076b:	89 c6                	mov    %eax,%esi
	uint32_t *eip = (uint32_t*)*(ebp + 1); //eip在ebp底下，储存返回地址
f010076d:	8b 58 04             	mov    0x4(%eax),%ebx
	cprintf("Stack backtrace:");
f0100770:	68 8e 1b 10 f0       	push   $0xf0101b8e
f0100775:	e8 e8 01 00 00       	call   f0100962 <cprintf>
	while(ebp != NULL){
f010077a:	83 c4 10             	add    $0x10,%esp
f010077d:	eb 52                	jmp    f01007d1 <mon_backtrace+0x71>
		cprintf("ebp %08x  eip %08x", ebp, eip); //打印ebp、eip
f010077f:	83 ec 04             	sub    $0x4,%esp
f0100782:	53                   	push   %ebx
f0100783:	56                   	push   %esi
f0100784:	68 9f 1b 10 f0       	push   $0xf0101b9f
f0100789:	e8 d4 01 00 00       	call   f0100962 <cprintf>
		cprintf("    arg ");
f010078e:	c7 04 24 b2 1b 10 f0 	movl   $0xf0101bb2,(%esp)
f0100795:	e8 c8 01 00 00       	call   f0100962 <cprintf>
f010079a:	8d 5e 08             	lea    0x8(%esi),%ebx
f010079d:	8d 7e 1c             	lea    0x1c(%esi),%edi
f01007a0:	83 c4 10             	add    $0x10,%esp
		for(int i = 0;i < 5;i++){
			cprintf("%08x ", *(ebp + i + 2));
f01007a3:	83 ec 08             	sub    $0x8,%esp
f01007a6:	ff 33                	pushl  (%ebx)
f01007a8:	68 bb 1b 10 f0       	push   $0xf0101bbb
f01007ad:	e8 b0 01 00 00       	call   f0100962 <cprintf>
f01007b2:	83 c3 04             	add    $0x4,%ebx
	uint32_t *eip = (uint32_t*)*(ebp + 1); //eip在ebp底下，储存返回地址
	cprintf("Stack backtrace:");
	while(ebp != NULL){
		cprintf("ebp %08x  eip %08x", ebp, eip); //打印ebp、eip
		cprintf("    arg ");
		for(int i = 0;i < 5;i++){
f01007b5:	83 c4 10             	add    $0x10,%esp
f01007b8:	39 fb                	cmp    %edi,%ebx
f01007ba:	75 e7                	jne    f01007a3 <mon_backtrace+0x43>
			cprintf("%08x ", *(ebp + i + 2));
		}
		cprintf("\n");
f01007bc:	83 ec 0c             	sub    $0xc,%esp
f01007bf:	68 ee 18 10 f0       	push   $0xf01018ee
f01007c4:	e8 99 01 00 00       	call   f0100962 <cprintf>
		ebp = (uint32_t*)(*ebp); //被调用函数的ebp指向调用它函数ebp值存放的位置
f01007c9:	8b 36                	mov    (%esi),%esi
		eip = (uint32_t*)*(ebp + 1); //eip在ebp底下，储存返回地址
f01007cb:	8b 5e 04             	mov    0x4(%esi),%ebx
f01007ce:	83 c4 10             	add    $0x10,%esp
{
	// Your code here.
	uint32_t *ebp = (uint32_t*)read_ebp(); //定义指向当前ebp寄存器的指针,uint32_t因为寄存器存储的值为32位
	uint32_t *eip = (uint32_t*)*(ebp + 1); //eip在ebp底下，储存返回地址
	cprintf("Stack backtrace:");
	while(ebp != NULL){
f01007d1:	85 f6                	test   %esi,%esi
f01007d3:	75 aa                	jne    f010077f <mon_backtrace+0x1f>
		cprintf("\n");
		ebp = (uint32_t*)(*ebp); //被调用函数的ebp指向调用它函数ebp值存放的位置
		eip = (uint32_t*)*(ebp + 1); //eip在ebp底下，储存返回地址
	}
	return 0;
}
f01007d5:	b8 00 00 00 00       	mov    $0x0,%eax
f01007da:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01007dd:	5b                   	pop    %ebx
f01007de:	5e                   	pop    %esi
f01007df:	5f                   	pop    %edi
f01007e0:	5d                   	pop    %ebp
f01007e1:	c3                   	ret    

f01007e2 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007e2:	55                   	push   %ebp
f01007e3:	89 e5                	mov    %esp,%ebp
f01007e5:	57                   	push   %edi
f01007e6:	56                   	push   %esi
f01007e7:	53                   	push   %ebx
f01007e8:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007eb:	68 0c 1d 10 f0       	push   $0xf0101d0c
f01007f0:	e8 6d 01 00 00       	call   f0100962 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007f5:	c7 04 24 30 1d 10 f0 	movl   $0xf0101d30,(%esp)
f01007fc:	e8 61 01 00 00       	call   f0100962 <cprintf>
f0100801:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f0100804:	83 ec 0c             	sub    $0xc,%esp
f0100807:	68 c1 1b 10 f0       	push   $0xf0101bc1
f010080c:	e8 64 09 00 00       	call   f0101175 <readline>
f0100811:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100813:	83 c4 10             	add    $0x10,%esp
f0100816:	85 c0                	test   %eax,%eax
f0100818:	74 ea                	je     f0100804 <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f010081a:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100821:	be 00 00 00 00       	mov    $0x0,%esi
f0100826:	eb 0a                	jmp    f0100832 <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100828:	c6 03 00             	movb   $0x0,(%ebx)
f010082b:	89 f7                	mov    %esi,%edi
f010082d:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100830:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100832:	0f b6 03             	movzbl (%ebx),%eax
f0100835:	84 c0                	test   %al,%al
f0100837:	74 63                	je     f010089c <monitor+0xba>
f0100839:	83 ec 08             	sub    $0x8,%esp
f010083c:	0f be c0             	movsbl %al,%eax
f010083f:	50                   	push   %eax
f0100840:	68 c5 1b 10 f0       	push   $0xf0101bc5
f0100845:	e8 45 0b 00 00       	call   f010138f <strchr>
f010084a:	83 c4 10             	add    $0x10,%esp
f010084d:	85 c0                	test   %eax,%eax
f010084f:	75 d7                	jne    f0100828 <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f0100851:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100854:	74 46                	je     f010089c <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100856:	83 fe 0f             	cmp    $0xf,%esi
f0100859:	75 14                	jne    f010086f <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010085b:	83 ec 08             	sub    $0x8,%esp
f010085e:	6a 10                	push   $0x10
f0100860:	68 ca 1b 10 f0       	push   $0xf0101bca
f0100865:	e8 f8 00 00 00       	call   f0100962 <cprintf>
f010086a:	83 c4 10             	add    $0x10,%esp
f010086d:	eb 95                	jmp    f0100804 <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f010086f:	8d 7e 01             	lea    0x1(%esi),%edi
f0100872:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100876:	eb 03                	jmp    f010087b <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100878:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010087b:	0f b6 03             	movzbl (%ebx),%eax
f010087e:	84 c0                	test   %al,%al
f0100880:	74 ae                	je     f0100830 <monitor+0x4e>
f0100882:	83 ec 08             	sub    $0x8,%esp
f0100885:	0f be c0             	movsbl %al,%eax
f0100888:	50                   	push   %eax
f0100889:	68 c5 1b 10 f0       	push   $0xf0101bc5
f010088e:	e8 fc 0a 00 00       	call   f010138f <strchr>
f0100893:	83 c4 10             	add    $0x10,%esp
f0100896:	85 c0                	test   %eax,%eax
f0100898:	74 de                	je     f0100878 <monitor+0x96>
f010089a:	eb 94                	jmp    f0100830 <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f010089c:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008a3:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008a4:	85 f6                	test   %esi,%esi
f01008a6:	0f 84 58 ff ff ff    	je     f0100804 <monitor+0x22>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008ac:	83 ec 08             	sub    $0x8,%esp
f01008af:	68 5e 1b 10 f0       	push   $0xf0101b5e
f01008b4:	ff 75 a8             	pushl  -0x58(%ebp)
f01008b7:	e8 75 0a 00 00       	call   f0101331 <strcmp>
f01008bc:	83 c4 10             	add    $0x10,%esp
f01008bf:	85 c0                	test   %eax,%eax
f01008c1:	74 1e                	je     f01008e1 <monitor+0xff>
f01008c3:	83 ec 08             	sub    $0x8,%esp
f01008c6:	68 6c 1b 10 f0       	push   $0xf0101b6c
f01008cb:	ff 75 a8             	pushl  -0x58(%ebp)
f01008ce:	e8 5e 0a 00 00       	call   f0101331 <strcmp>
f01008d3:	83 c4 10             	add    $0x10,%esp
f01008d6:	85 c0                	test   %eax,%eax
f01008d8:	75 2f                	jne    f0100909 <monitor+0x127>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f01008da:	b8 01 00 00 00       	mov    $0x1,%eax
f01008df:	eb 05                	jmp    f01008e6 <monitor+0x104>
		if (strcmp(argv[0], commands[i].name) == 0)
f01008e1:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f01008e6:	83 ec 04             	sub    $0x4,%esp
f01008e9:	8d 14 00             	lea    (%eax,%eax,1),%edx
f01008ec:	01 d0                	add    %edx,%eax
f01008ee:	ff 75 08             	pushl  0x8(%ebp)
f01008f1:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f01008f4:	51                   	push   %ecx
f01008f5:	56                   	push   %esi
f01008f6:	ff 14 85 60 1d 10 f0 	call   *-0xfefe2a0(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008fd:	83 c4 10             	add    $0x10,%esp
f0100900:	85 c0                	test   %eax,%eax
f0100902:	78 1d                	js     f0100921 <monitor+0x13f>
f0100904:	e9 fb fe ff ff       	jmp    f0100804 <monitor+0x22>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100909:	83 ec 08             	sub    $0x8,%esp
f010090c:	ff 75 a8             	pushl  -0x58(%ebp)
f010090f:	68 e7 1b 10 f0       	push   $0xf0101be7
f0100914:	e8 49 00 00 00       	call   f0100962 <cprintf>
f0100919:	83 c4 10             	add    $0x10,%esp
f010091c:	e9 e3 fe ff ff       	jmp    f0100804 <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100921:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100924:	5b                   	pop    %ebx
f0100925:	5e                   	pop    %esi
f0100926:	5f                   	pop    %edi
f0100927:	5d                   	pop    %ebp
f0100928:	c3                   	ret    

f0100929 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100929:	55                   	push   %ebp
f010092a:	89 e5                	mov    %esp,%ebp
f010092c:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f010092f:	ff 75 08             	pushl  0x8(%ebp)
f0100932:	e8 16 fd ff ff       	call   f010064d <cputchar>
	*cnt++;
}
f0100937:	83 c4 10             	add    $0x10,%esp
f010093a:	c9                   	leave  
f010093b:	c3                   	ret    

f010093c <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010093c:	55                   	push   %ebp
f010093d:	89 e5                	mov    %esp,%ebp
f010093f:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0100942:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100949:	ff 75 0c             	pushl  0xc(%ebp)
f010094c:	ff 75 08             	pushl  0x8(%ebp)
f010094f:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100952:	50                   	push   %eax
f0100953:	68 29 09 10 f0       	push   $0xf0100929
f0100958:	e8 03 04 00 00       	call   f0100d60 <vprintfmt>
	return cnt;
}
f010095d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100960:	c9                   	leave  
f0100961:	c3                   	ret    

f0100962 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100962:	55                   	push   %ebp
f0100963:	89 e5                	mov    %esp,%ebp
f0100965:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100968:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f010096b:	50                   	push   %eax
f010096c:	ff 75 08             	pushl  0x8(%ebp)
f010096f:	e8 c8 ff ff ff       	call   f010093c <vcprintf>
	va_end(ap);

	return cnt;
}
f0100974:	c9                   	leave  
f0100975:	c3                   	ret    

f0100976 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100976:	55                   	push   %ebp
f0100977:	89 e5                	mov    %esp,%ebp
f0100979:	57                   	push   %edi
f010097a:	56                   	push   %esi
f010097b:	53                   	push   %ebx
f010097c:	83 ec 14             	sub    $0x14,%esp
f010097f:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100982:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100985:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100988:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f010098b:	8b 1a                	mov    (%edx),%ebx
f010098d:	8b 01                	mov    (%ecx),%eax
f010098f:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100992:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0100999:	eb 7f                	jmp    f0100a1a <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f010099b:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010099e:	01 d8                	add    %ebx,%eax
f01009a0:	89 c6                	mov    %eax,%esi
f01009a2:	c1 ee 1f             	shr    $0x1f,%esi
f01009a5:	01 c6                	add    %eax,%esi
f01009a7:	d1 fe                	sar    %esi
f01009a9:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01009ac:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01009af:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01009b2:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01009b4:	eb 03                	jmp    f01009b9 <stab_binsearch+0x43>
			m--;
f01009b6:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01009b9:	39 c3                	cmp    %eax,%ebx
f01009bb:	7f 0d                	jg     f01009ca <stab_binsearch+0x54>
f01009bd:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01009c1:	83 ea 0c             	sub    $0xc,%edx
f01009c4:	39 f9                	cmp    %edi,%ecx
f01009c6:	75 ee                	jne    f01009b6 <stab_binsearch+0x40>
f01009c8:	eb 05                	jmp    f01009cf <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01009ca:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01009cd:	eb 4b                	jmp    f0100a1a <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01009cf:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01009d2:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01009d5:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01009d9:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01009dc:	76 11                	jbe    f01009ef <stab_binsearch+0x79>
			*region_left = m;
f01009de:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01009e1:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01009e3:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009e6:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01009ed:	eb 2b                	jmp    f0100a1a <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01009ef:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01009f2:	73 14                	jae    f0100a08 <stab_binsearch+0x92>
			*region_right = m - 1;
f01009f4:	83 e8 01             	sub    $0x1,%eax
f01009f7:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01009fa:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01009fd:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009ff:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100a06:	eb 12                	jmp    f0100a1a <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100a08:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a0b:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0100a0d:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100a11:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a13:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100a1a:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100a1d:	0f 8e 78 ff ff ff    	jle    f010099b <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100a23:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100a27:	75 0f                	jne    f0100a38 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0100a29:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a2c:	8b 00                	mov    (%eax),%eax
f0100a2e:	83 e8 01             	sub    $0x1,%eax
f0100a31:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100a34:	89 06                	mov    %eax,(%esi)
f0100a36:	eb 2c                	jmp    f0100a64 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a38:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a3b:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100a3d:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a40:	8b 0e                	mov    (%esi),%ecx
f0100a42:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100a45:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100a48:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a4b:	eb 03                	jmp    f0100a50 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100a4d:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a50:	39 c8                	cmp    %ecx,%eax
f0100a52:	7e 0b                	jle    f0100a5f <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0100a54:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0100a58:	83 ea 0c             	sub    $0xc,%edx
f0100a5b:	39 df                	cmp    %ebx,%edi
f0100a5d:	75 ee                	jne    f0100a4d <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100a5f:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a62:	89 06                	mov    %eax,(%esi)
	}
}
f0100a64:	83 c4 14             	add    $0x14,%esp
f0100a67:	5b                   	pop    %ebx
f0100a68:	5e                   	pop    %esi
f0100a69:	5f                   	pop    %edi
f0100a6a:	5d                   	pop    %ebp
f0100a6b:	c3                   	ret    

f0100a6c <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100a6c:	55                   	push   %ebp
f0100a6d:	89 e5                	mov    %esp,%ebp
f0100a6f:	57                   	push   %edi
f0100a70:	56                   	push   %esi
f0100a71:	53                   	push   %ebx
f0100a72:	83 ec 1c             	sub    $0x1c,%esp
f0100a75:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100a78:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100a7b:	c7 06 70 1d 10 f0    	movl   $0xf0101d70,(%esi)
	info->eip_line = 0;
f0100a81:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0100a88:	c7 46 08 70 1d 10 f0 	movl   $0xf0101d70,0x8(%esi)
	info->eip_fn_namelen = 9;
f0100a8f:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0100a96:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0100a99:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100aa0:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0100aa6:	76 11                	jbe    f0100ab9 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100aa8:	b8 1f 72 10 f0       	mov    $0xf010721f,%eax
f0100aad:	3d 0d 59 10 f0       	cmp    $0xf010590d,%eax
f0100ab2:	77 19                	ja     f0100acd <debuginfo_eip+0x61>
f0100ab4:	e9 62 01 00 00       	jmp    f0100c1b <debuginfo_eip+0x1af>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100ab9:	83 ec 04             	sub    $0x4,%esp
f0100abc:	68 7a 1d 10 f0       	push   $0xf0101d7a
f0100ac1:	6a 7f                	push   $0x7f
f0100ac3:	68 87 1d 10 f0       	push   $0xf0101d87
f0100ac8:	e8 19 f6 ff ff       	call   f01000e6 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100acd:	80 3d 1e 72 10 f0 00 	cmpb   $0x0,0xf010721e
f0100ad4:	0f 85 48 01 00 00    	jne    f0100c22 <debuginfo_eip+0x1b6>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100ada:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100ae1:	b8 0c 59 10 f0       	mov    $0xf010590c,%eax
f0100ae6:	2d d0 1f 10 f0       	sub    $0xf0101fd0,%eax
f0100aeb:	c1 f8 02             	sar    $0x2,%eax
f0100aee:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100af4:	83 e8 01             	sub    $0x1,%eax
f0100af7:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100afa:	83 ec 08             	sub    $0x8,%esp
f0100afd:	57                   	push   %edi
f0100afe:	6a 64                	push   $0x64
f0100b00:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100b03:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100b06:	b8 d0 1f 10 f0       	mov    $0xf0101fd0,%eax
f0100b0b:	e8 66 fe ff ff       	call   f0100976 <stab_binsearch>
	if (lfile == 0)
f0100b10:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b13:	83 c4 10             	add    $0x10,%esp
f0100b16:	85 c0                	test   %eax,%eax
f0100b18:	0f 84 0b 01 00 00    	je     f0100c29 <debuginfo_eip+0x1bd>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100b1e:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100b21:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b24:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100b27:	83 ec 08             	sub    $0x8,%esp
f0100b2a:	57                   	push   %edi
f0100b2b:	6a 24                	push   $0x24
f0100b2d:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100b30:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b33:	b8 d0 1f 10 f0       	mov    $0xf0101fd0,%eax
f0100b38:	e8 39 fe ff ff       	call   f0100976 <stab_binsearch>

	if (lfun <= rfun) {
f0100b3d:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100b40:	83 c4 10             	add    $0x10,%esp
f0100b43:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f0100b46:	7f 31                	jg     f0100b79 <debuginfo_eip+0x10d>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100b48:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100b4b:	c1 e0 02             	shl    $0x2,%eax
f0100b4e:	8d 90 d0 1f 10 f0    	lea    -0xfefe030(%eax),%edx
f0100b54:	8b 88 d0 1f 10 f0    	mov    -0xfefe030(%eax),%ecx
f0100b5a:	b8 1f 72 10 f0       	mov    $0xf010721f,%eax
f0100b5f:	2d 0d 59 10 f0       	sub    $0xf010590d,%eax
f0100b64:	39 c1                	cmp    %eax,%ecx
f0100b66:	73 09                	jae    f0100b71 <debuginfo_eip+0x105>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100b68:	81 c1 0d 59 10 f0    	add    $0xf010590d,%ecx
f0100b6e:	89 4e 08             	mov    %ecx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100b71:	8b 42 08             	mov    0x8(%edx),%eax
f0100b74:	89 46 10             	mov    %eax,0x10(%esi)
f0100b77:	eb 06                	jmp    f0100b7f <debuginfo_eip+0x113>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100b79:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0100b7c:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100b7f:	83 ec 08             	sub    $0x8,%esp
f0100b82:	6a 3a                	push   $0x3a
f0100b84:	ff 76 08             	pushl  0x8(%esi)
f0100b87:	e8 24 08 00 00       	call   f01013b0 <strfind>
f0100b8c:	2b 46 08             	sub    0x8(%esi),%eax
f0100b8f:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100b92:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100b95:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100b98:	8d 04 85 d0 1f 10 f0 	lea    -0xfefe030(,%eax,4),%eax
f0100b9f:	83 c4 10             	add    $0x10,%esp
f0100ba2:	eb 06                	jmp    f0100baa <debuginfo_eip+0x13e>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100ba4:	83 eb 01             	sub    $0x1,%ebx
f0100ba7:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100baa:	39 fb                	cmp    %edi,%ebx
f0100bac:	7c 34                	jl     f0100be2 <debuginfo_eip+0x176>
	       && stabs[lline].n_type != N_SOL
f0100bae:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f0100bb2:	80 fa 84             	cmp    $0x84,%dl
f0100bb5:	74 0b                	je     f0100bc2 <debuginfo_eip+0x156>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100bb7:	80 fa 64             	cmp    $0x64,%dl
f0100bba:	75 e8                	jne    f0100ba4 <debuginfo_eip+0x138>
f0100bbc:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100bc0:	74 e2                	je     f0100ba4 <debuginfo_eip+0x138>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100bc2:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100bc5:	8b 14 85 d0 1f 10 f0 	mov    -0xfefe030(,%eax,4),%edx
f0100bcc:	b8 1f 72 10 f0       	mov    $0xf010721f,%eax
f0100bd1:	2d 0d 59 10 f0       	sub    $0xf010590d,%eax
f0100bd6:	39 c2                	cmp    %eax,%edx
f0100bd8:	73 08                	jae    f0100be2 <debuginfo_eip+0x176>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100bda:	81 c2 0d 59 10 f0    	add    $0xf010590d,%edx
f0100be0:	89 16                	mov    %edx,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100be2:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100be5:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100be8:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100bed:	39 cb                	cmp    %ecx,%ebx
f0100bef:	7d 44                	jge    f0100c35 <debuginfo_eip+0x1c9>
		for (lline = lfun + 1;
f0100bf1:	8d 53 01             	lea    0x1(%ebx),%edx
f0100bf4:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100bf7:	8d 04 85 d0 1f 10 f0 	lea    -0xfefe030(,%eax,4),%eax
f0100bfe:	eb 07                	jmp    f0100c07 <debuginfo_eip+0x19b>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100c00:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100c04:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100c07:	39 ca                	cmp    %ecx,%edx
f0100c09:	74 25                	je     f0100c30 <debuginfo_eip+0x1c4>
f0100c0b:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100c0e:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f0100c12:	74 ec                	je     f0100c00 <debuginfo_eip+0x194>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c14:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c19:	eb 1a                	jmp    f0100c35 <debuginfo_eip+0x1c9>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100c1b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c20:	eb 13                	jmp    f0100c35 <debuginfo_eip+0x1c9>
f0100c22:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c27:	eb 0c                	jmp    f0100c35 <debuginfo_eip+0x1c9>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100c29:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c2e:	eb 05                	jmp    f0100c35 <debuginfo_eip+0x1c9>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c30:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100c35:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c38:	5b                   	pop    %ebx
f0100c39:	5e                   	pop    %esi
f0100c3a:	5f                   	pop    %edi
f0100c3b:	5d                   	pop    %ebp
f0100c3c:	c3                   	ret    

f0100c3d <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100c3d:	55                   	push   %ebp
f0100c3e:	89 e5                	mov    %esp,%ebp
f0100c40:	57                   	push   %edi
f0100c41:	56                   	push   %esi
f0100c42:	53                   	push   %ebx
f0100c43:	83 ec 1c             	sub    $0x1c,%esp
f0100c46:	89 c7                	mov    %eax,%edi
f0100c48:	89 d6                	mov    %edx,%esi
f0100c4a:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c4d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100c50:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100c53:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100c56:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0100c59:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100c5e:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100c61:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0100c64:	39 d3                	cmp    %edx,%ebx
f0100c66:	72 05                	jb     f0100c6d <printnum+0x30>
f0100c68:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100c6b:	77 45                	ja     f0100cb2 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100c6d:	83 ec 0c             	sub    $0xc,%esp
f0100c70:	ff 75 18             	pushl  0x18(%ebp)
f0100c73:	8b 45 14             	mov    0x14(%ebp),%eax
f0100c76:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100c79:	53                   	push   %ebx
f0100c7a:	ff 75 10             	pushl  0x10(%ebp)
f0100c7d:	83 ec 08             	sub    $0x8,%esp
f0100c80:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100c83:	ff 75 e0             	pushl  -0x20(%ebp)
f0100c86:	ff 75 dc             	pushl  -0x24(%ebp)
f0100c89:	ff 75 d8             	pushl  -0x28(%ebp)
f0100c8c:	e8 3f 09 00 00       	call   f01015d0 <__udivdi3>
f0100c91:	83 c4 18             	add    $0x18,%esp
f0100c94:	52                   	push   %edx
f0100c95:	50                   	push   %eax
f0100c96:	89 f2                	mov    %esi,%edx
f0100c98:	89 f8                	mov    %edi,%eax
f0100c9a:	e8 9e ff ff ff       	call   f0100c3d <printnum>
f0100c9f:	83 c4 20             	add    $0x20,%esp
f0100ca2:	eb 18                	jmp    f0100cbc <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100ca4:	83 ec 08             	sub    $0x8,%esp
f0100ca7:	56                   	push   %esi
f0100ca8:	ff 75 18             	pushl  0x18(%ebp)
f0100cab:	ff d7                	call   *%edi
f0100cad:	83 c4 10             	add    $0x10,%esp
f0100cb0:	eb 03                	jmp    f0100cb5 <printnum+0x78>
f0100cb2:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100cb5:	83 eb 01             	sub    $0x1,%ebx
f0100cb8:	85 db                	test   %ebx,%ebx
f0100cba:	7f e8                	jg     f0100ca4 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100cbc:	83 ec 08             	sub    $0x8,%esp
f0100cbf:	56                   	push   %esi
f0100cc0:	83 ec 04             	sub    $0x4,%esp
f0100cc3:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100cc6:	ff 75 e0             	pushl  -0x20(%ebp)
f0100cc9:	ff 75 dc             	pushl  -0x24(%ebp)
f0100ccc:	ff 75 d8             	pushl  -0x28(%ebp)
f0100ccf:	e8 2c 0a 00 00       	call   f0101700 <__umoddi3>
f0100cd4:	83 c4 14             	add    $0x14,%esp
f0100cd7:	0f be 80 95 1d 10 f0 	movsbl -0xfefe26b(%eax),%eax
f0100cde:	50                   	push   %eax
f0100cdf:	ff d7                	call   *%edi
}
f0100ce1:	83 c4 10             	add    $0x10,%esp
f0100ce4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100ce7:	5b                   	pop    %ebx
f0100ce8:	5e                   	pop    %esi
f0100ce9:	5f                   	pop    %edi
f0100cea:	5d                   	pop    %ebp
f0100ceb:	c3                   	ret    

f0100cec <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100cec:	55                   	push   %ebp
f0100ced:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100cef:	83 fa 01             	cmp    $0x1,%edx
f0100cf2:	7e 0e                	jle    f0100d02 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100cf4:	8b 10                	mov    (%eax),%edx
f0100cf6:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100cf9:	89 08                	mov    %ecx,(%eax)
f0100cfb:	8b 02                	mov    (%edx),%eax
f0100cfd:	8b 52 04             	mov    0x4(%edx),%edx
f0100d00:	eb 22                	jmp    f0100d24 <getuint+0x38>
	else if (lflag)
f0100d02:	85 d2                	test   %edx,%edx
f0100d04:	74 10                	je     f0100d16 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100d06:	8b 10                	mov    (%eax),%edx
f0100d08:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100d0b:	89 08                	mov    %ecx,(%eax)
f0100d0d:	8b 02                	mov    (%edx),%eax
f0100d0f:	ba 00 00 00 00       	mov    $0x0,%edx
f0100d14:	eb 0e                	jmp    f0100d24 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100d16:	8b 10                	mov    (%eax),%edx
f0100d18:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100d1b:	89 08                	mov    %ecx,(%eax)
f0100d1d:	8b 02                	mov    (%edx),%eax
f0100d1f:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100d24:	5d                   	pop    %ebp
f0100d25:	c3                   	ret    

f0100d26 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100d26:	55                   	push   %ebp
f0100d27:	89 e5                	mov    %esp,%ebp
f0100d29:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100d2c:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100d30:	8b 10                	mov    (%eax),%edx
f0100d32:	3b 50 04             	cmp    0x4(%eax),%edx
f0100d35:	73 0a                	jae    f0100d41 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100d37:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100d3a:	89 08                	mov    %ecx,(%eax)
f0100d3c:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d3f:	88 02                	mov    %al,(%edx)
}
f0100d41:	5d                   	pop    %ebp
f0100d42:	c3                   	ret    

f0100d43 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100d43:	55                   	push   %ebp
f0100d44:	89 e5                	mov    %esp,%ebp
f0100d46:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100d49:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100d4c:	50                   	push   %eax
f0100d4d:	ff 75 10             	pushl  0x10(%ebp)
f0100d50:	ff 75 0c             	pushl  0xc(%ebp)
f0100d53:	ff 75 08             	pushl  0x8(%ebp)
f0100d56:	e8 05 00 00 00       	call   f0100d60 <vprintfmt>
	va_end(ap);
}
f0100d5b:	83 c4 10             	add    $0x10,%esp
f0100d5e:	c9                   	leave  
f0100d5f:	c3                   	ret    

f0100d60 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100d60:	55                   	push   %ebp
f0100d61:	89 e5                	mov    %esp,%ebp
f0100d63:	57                   	push   %edi
f0100d64:	56                   	push   %esi
f0100d65:	53                   	push   %ebx
f0100d66:	83 ec 2c             	sub    $0x2c,%esp
f0100d69:	8b 75 08             	mov    0x8(%ebp),%esi
f0100d6c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100d6f:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100d72:	eb 12                	jmp    f0100d86 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100d74:	85 c0                	test   %eax,%eax
f0100d76:	0f 84 89 03 00 00    	je     f0101105 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0100d7c:	83 ec 08             	sub    $0x8,%esp
f0100d7f:	53                   	push   %ebx
f0100d80:	50                   	push   %eax
f0100d81:	ff d6                	call   *%esi
f0100d83:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100d86:	83 c7 01             	add    $0x1,%edi
f0100d89:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100d8d:	83 f8 25             	cmp    $0x25,%eax
f0100d90:	75 e2                	jne    f0100d74 <vprintfmt+0x14>
f0100d92:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0100d96:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100d9d:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100da4:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0100dab:	ba 00 00 00 00       	mov    $0x0,%edx
f0100db0:	eb 07                	jmp    f0100db9 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100db2:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100db5:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100db9:	8d 47 01             	lea    0x1(%edi),%eax
f0100dbc:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100dbf:	0f b6 07             	movzbl (%edi),%eax
f0100dc2:	0f b6 c8             	movzbl %al,%ecx
f0100dc5:	83 e8 23             	sub    $0x23,%eax
f0100dc8:	3c 55                	cmp    $0x55,%al
f0100dca:	0f 87 1a 03 00 00    	ja     f01010ea <vprintfmt+0x38a>
f0100dd0:	0f b6 c0             	movzbl %al,%eax
f0100dd3:	ff 24 85 40 1e 10 f0 	jmp    *-0xfefe1c0(,%eax,4)
f0100dda:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100ddd:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100de1:	eb d6                	jmp    f0100db9 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100de3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100de6:	b8 00 00 00 00       	mov    $0x0,%eax
f0100deb:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100dee:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100df1:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0100df5:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0100df8:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0100dfb:	83 fa 09             	cmp    $0x9,%edx
f0100dfe:	77 39                	ja     f0100e39 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100e00:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100e03:	eb e9                	jmp    f0100dee <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100e05:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e08:	8d 48 04             	lea    0x4(%eax),%ecx
f0100e0b:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100e0e:	8b 00                	mov    (%eax),%eax
f0100e10:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e13:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100e16:	eb 27                	jmp    f0100e3f <vprintfmt+0xdf>
f0100e18:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100e1b:	85 c0                	test   %eax,%eax
f0100e1d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100e22:	0f 49 c8             	cmovns %eax,%ecx
f0100e25:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e28:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100e2b:	eb 8c                	jmp    f0100db9 <vprintfmt+0x59>
f0100e2d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100e30:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100e37:	eb 80                	jmp    f0100db9 <vprintfmt+0x59>
f0100e39:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100e3c:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0100e3f:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100e43:	0f 89 70 ff ff ff    	jns    f0100db9 <vprintfmt+0x59>
				width = precision, precision = -1;
f0100e49:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100e4c:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100e4f:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100e56:	e9 5e ff ff ff       	jmp    f0100db9 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100e5b:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e5e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100e61:	e9 53 ff ff ff       	jmp    f0100db9 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100e66:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e69:	8d 50 04             	lea    0x4(%eax),%edx
f0100e6c:	89 55 14             	mov    %edx,0x14(%ebp)
f0100e6f:	83 ec 08             	sub    $0x8,%esp
f0100e72:	53                   	push   %ebx
f0100e73:	ff 30                	pushl  (%eax)
f0100e75:	ff d6                	call   *%esi
			break;
f0100e77:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e7a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0100e7d:	e9 04 ff ff ff       	jmp    f0100d86 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100e82:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e85:	8d 50 04             	lea    0x4(%eax),%edx
f0100e88:	89 55 14             	mov    %edx,0x14(%ebp)
f0100e8b:	8b 00                	mov    (%eax),%eax
f0100e8d:	99                   	cltd   
f0100e8e:	31 d0                	xor    %edx,%eax
f0100e90:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100e92:	83 f8 07             	cmp    $0x7,%eax
f0100e95:	7f 0b                	jg     f0100ea2 <vprintfmt+0x142>
f0100e97:	8b 14 85 a0 1f 10 f0 	mov    -0xfefe060(,%eax,4),%edx
f0100e9e:	85 d2                	test   %edx,%edx
f0100ea0:	75 18                	jne    f0100eba <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0100ea2:	50                   	push   %eax
f0100ea3:	68 ad 1d 10 f0       	push   $0xf0101dad
f0100ea8:	53                   	push   %ebx
f0100ea9:	56                   	push   %esi
f0100eaa:	e8 94 fe ff ff       	call   f0100d43 <printfmt>
f0100eaf:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100eb2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100eb5:	e9 cc fe ff ff       	jmp    f0100d86 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0100eba:	52                   	push   %edx
f0100ebb:	68 b6 1d 10 f0       	push   $0xf0101db6
f0100ec0:	53                   	push   %ebx
f0100ec1:	56                   	push   %esi
f0100ec2:	e8 7c fe ff ff       	call   f0100d43 <printfmt>
f0100ec7:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100eca:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100ecd:	e9 b4 fe ff ff       	jmp    f0100d86 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100ed2:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ed5:	8d 50 04             	lea    0x4(%eax),%edx
f0100ed8:	89 55 14             	mov    %edx,0x14(%ebp)
f0100edb:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0100edd:	85 ff                	test   %edi,%edi
f0100edf:	b8 a6 1d 10 f0       	mov    $0xf0101da6,%eax
f0100ee4:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0100ee7:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100eeb:	0f 8e 94 00 00 00    	jle    f0100f85 <vprintfmt+0x225>
f0100ef1:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0100ef5:	0f 84 98 00 00 00    	je     f0100f93 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0100efb:	83 ec 08             	sub    $0x8,%esp
f0100efe:	ff 75 d0             	pushl  -0x30(%ebp)
f0100f01:	57                   	push   %edi
f0100f02:	e8 5f 03 00 00       	call   f0101266 <strnlen>
f0100f07:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100f0a:	29 c1                	sub    %eax,%ecx
f0100f0c:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0100f0f:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0100f12:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0100f16:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100f19:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100f1c:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f1e:	eb 0f                	jmp    f0100f2f <vprintfmt+0x1cf>
					putch(padc, putdat);
f0100f20:	83 ec 08             	sub    $0x8,%esp
f0100f23:	53                   	push   %ebx
f0100f24:	ff 75 e0             	pushl  -0x20(%ebp)
f0100f27:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f29:	83 ef 01             	sub    $0x1,%edi
f0100f2c:	83 c4 10             	add    $0x10,%esp
f0100f2f:	85 ff                	test   %edi,%edi
f0100f31:	7f ed                	jg     f0100f20 <vprintfmt+0x1c0>
f0100f33:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0100f36:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0100f39:	85 c9                	test   %ecx,%ecx
f0100f3b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f40:	0f 49 c1             	cmovns %ecx,%eax
f0100f43:	29 c1                	sub    %eax,%ecx
f0100f45:	89 75 08             	mov    %esi,0x8(%ebp)
f0100f48:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100f4b:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100f4e:	89 cb                	mov    %ecx,%ebx
f0100f50:	eb 4d                	jmp    f0100f9f <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0100f52:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100f56:	74 1b                	je     f0100f73 <vprintfmt+0x213>
f0100f58:	0f be c0             	movsbl %al,%eax
f0100f5b:	83 e8 20             	sub    $0x20,%eax
f0100f5e:	83 f8 5e             	cmp    $0x5e,%eax
f0100f61:	76 10                	jbe    f0100f73 <vprintfmt+0x213>
					putch('?', putdat);
f0100f63:	83 ec 08             	sub    $0x8,%esp
f0100f66:	ff 75 0c             	pushl  0xc(%ebp)
f0100f69:	6a 3f                	push   $0x3f
f0100f6b:	ff 55 08             	call   *0x8(%ebp)
f0100f6e:	83 c4 10             	add    $0x10,%esp
f0100f71:	eb 0d                	jmp    f0100f80 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0100f73:	83 ec 08             	sub    $0x8,%esp
f0100f76:	ff 75 0c             	pushl  0xc(%ebp)
f0100f79:	52                   	push   %edx
f0100f7a:	ff 55 08             	call   *0x8(%ebp)
f0100f7d:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100f80:	83 eb 01             	sub    $0x1,%ebx
f0100f83:	eb 1a                	jmp    f0100f9f <vprintfmt+0x23f>
f0100f85:	89 75 08             	mov    %esi,0x8(%ebp)
f0100f88:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100f8b:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100f8e:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100f91:	eb 0c                	jmp    f0100f9f <vprintfmt+0x23f>
f0100f93:	89 75 08             	mov    %esi,0x8(%ebp)
f0100f96:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100f99:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100f9c:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100f9f:	83 c7 01             	add    $0x1,%edi
f0100fa2:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100fa6:	0f be d0             	movsbl %al,%edx
f0100fa9:	85 d2                	test   %edx,%edx
f0100fab:	74 23                	je     f0100fd0 <vprintfmt+0x270>
f0100fad:	85 f6                	test   %esi,%esi
f0100faf:	78 a1                	js     f0100f52 <vprintfmt+0x1f2>
f0100fb1:	83 ee 01             	sub    $0x1,%esi
f0100fb4:	79 9c                	jns    f0100f52 <vprintfmt+0x1f2>
f0100fb6:	89 df                	mov    %ebx,%edi
f0100fb8:	8b 75 08             	mov    0x8(%ebp),%esi
f0100fbb:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100fbe:	eb 18                	jmp    f0100fd8 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0100fc0:	83 ec 08             	sub    $0x8,%esp
f0100fc3:	53                   	push   %ebx
f0100fc4:	6a 20                	push   $0x20
f0100fc6:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0100fc8:	83 ef 01             	sub    $0x1,%edi
f0100fcb:	83 c4 10             	add    $0x10,%esp
f0100fce:	eb 08                	jmp    f0100fd8 <vprintfmt+0x278>
f0100fd0:	89 df                	mov    %ebx,%edi
f0100fd2:	8b 75 08             	mov    0x8(%ebp),%esi
f0100fd5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100fd8:	85 ff                	test   %edi,%edi
f0100fda:	7f e4                	jg     f0100fc0 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fdc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100fdf:	e9 a2 fd ff ff       	jmp    f0100d86 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0100fe4:	83 fa 01             	cmp    $0x1,%edx
f0100fe7:	7e 16                	jle    f0100fff <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0100fe9:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fec:	8d 50 08             	lea    0x8(%eax),%edx
f0100fef:	89 55 14             	mov    %edx,0x14(%ebp)
f0100ff2:	8b 50 04             	mov    0x4(%eax),%edx
f0100ff5:	8b 00                	mov    (%eax),%eax
f0100ff7:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100ffa:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0100ffd:	eb 32                	jmp    f0101031 <vprintfmt+0x2d1>
	else if (lflag)
f0100fff:	85 d2                	test   %edx,%edx
f0101001:	74 18                	je     f010101b <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0101003:	8b 45 14             	mov    0x14(%ebp),%eax
f0101006:	8d 50 04             	lea    0x4(%eax),%edx
f0101009:	89 55 14             	mov    %edx,0x14(%ebp)
f010100c:	8b 00                	mov    (%eax),%eax
f010100e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101011:	89 c1                	mov    %eax,%ecx
f0101013:	c1 f9 1f             	sar    $0x1f,%ecx
f0101016:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0101019:	eb 16                	jmp    f0101031 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f010101b:	8b 45 14             	mov    0x14(%ebp),%eax
f010101e:	8d 50 04             	lea    0x4(%eax),%edx
f0101021:	89 55 14             	mov    %edx,0x14(%ebp)
f0101024:	8b 00                	mov    (%eax),%eax
f0101026:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101029:	89 c1                	mov    %eax,%ecx
f010102b:	c1 f9 1f             	sar    $0x1f,%ecx
f010102e:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0101031:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101034:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0101037:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f010103c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101040:	79 74                	jns    f01010b6 <vprintfmt+0x356>
				putch('-', putdat);
f0101042:	83 ec 08             	sub    $0x8,%esp
f0101045:	53                   	push   %ebx
f0101046:	6a 2d                	push   $0x2d
f0101048:	ff d6                	call   *%esi
				num = -(long long) num;
f010104a:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010104d:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101050:	f7 d8                	neg    %eax
f0101052:	83 d2 00             	adc    $0x0,%edx
f0101055:	f7 da                	neg    %edx
f0101057:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f010105a:	b9 0a 00 00 00       	mov    $0xa,%ecx
f010105f:	eb 55                	jmp    f01010b6 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0101061:	8d 45 14             	lea    0x14(%ebp),%eax
f0101064:	e8 83 fc ff ff       	call   f0100cec <getuint>
			base = 10;
f0101069:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f010106e:	eb 46                	jmp    f01010b6 <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0101070:	8d 45 14             	lea    0x14(%ebp),%eax
f0101073:	e8 74 fc ff ff       	call   f0100cec <getuint>
           		base = 8;
f0101078:	b9 08 00 00 00       	mov    $0x8,%ecx
           		goto number;
f010107d:	eb 37                	jmp    f01010b6 <vprintfmt+0x356>
			break;

		// pointer
		case 'p':
			putch('0', putdat);
f010107f:	83 ec 08             	sub    $0x8,%esp
f0101082:	53                   	push   %ebx
f0101083:	6a 30                	push   $0x30
f0101085:	ff d6                	call   *%esi
			putch('x', putdat);
f0101087:	83 c4 08             	add    $0x8,%esp
f010108a:	53                   	push   %ebx
f010108b:	6a 78                	push   $0x78
f010108d:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010108f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101092:	8d 50 04             	lea    0x4(%eax),%edx
f0101095:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0101098:	8b 00                	mov    (%eax),%eax
f010109a:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f010109f:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01010a2:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01010a7:	eb 0d                	jmp    f01010b6 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01010a9:	8d 45 14             	lea    0x14(%ebp),%eax
f01010ac:	e8 3b fc ff ff       	call   f0100cec <getuint>
			base = 16;
f01010b1:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f01010b6:	83 ec 0c             	sub    $0xc,%esp
f01010b9:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f01010bd:	57                   	push   %edi
f01010be:	ff 75 e0             	pushl  -0x20(%ebp)
f01010c1:	51                   	push   %ecx
f01010c2:	52                   	push   %edx
f01010c3:	50                   	push   %eax
f01010c4:	89 da                	mov    %ebx,%edx
f01010c6:	89 f0                	mov    %esi,%eax
f01010c8:	e8 70 fb ff ff       	call   f0100c3d <printnum>
			break;
f01010cd:	83 c4 20             	add    $0x20,%esp
f01010d0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01010d3:	e9 ae fc ff ff       	jmp    f0100d86 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01010d8:	83 ec 08             	sub    $0x8,%esp
f01010db:	53                   	push   %ebx
f01010dc:	51                   	push   %ecx
f01010dd:	ff d6                	call   *%esi
			break;
f01010df:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01010e2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01010e5:	e9 9c fc ff ff       	jmp    f0100d86 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01010ea:	83 ec 08             	sub    $0x8,%esp
f01010ed:	53                   	push   %ebx
f01010ee:	6a 25                	push   $0x25
f01010f0:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01010f2:	83 c4 10             	add    $0x10,%esp
f01010f5:	eb 03                	jmp    f01010fa <vprintfmt+0x39a>
f01010f7:	83 ef 01             	sub    $0x1,%edi
f01010fa:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f01010fe:	75 f7                	jne    f01010f7 <vprintfmt+0x397>
f0101100:	e9 81 fc ff ff       	jmp    f0100d86 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0101105:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101108:	5b                   	pop    %ebx
f0101109:	5e                   	pop    %esi
f010110a:	5f                   	pop    %edi
f010110b:	5d                   	pop    %ebp
f010110c:	c3                   	ret    

f010110d <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f010110d:	55                   	push   %ebp
f010110e:	89 e5                	mov    %esp,%ebp
f0101110:	83 ec 18             	sub    $0x18,%esp
f0101113:	8b 45 08             	mov    0x8(%ebp),%eax
f0101116:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101119:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010111c:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101120:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101123:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010112a:	85 c0                	test   %eax,%eax
f010112c:	74 26                	je     f0101154 <vsnprintf+0x47>
f010112e:	85 d2                	test   %edx,%edx
f0101130:	7e 22                	jle    f0101154 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101132:	ff 75 14             	pushl  0x14(%ebp)
f0101135:	ff 75 10             	pushl  0x10(%ebp)
f0101138:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010113b:	50                   	push   %eax
f010113c:	68 26 0d 10 f0       	push   $0xf0100d26
f0101141:	e8 1a fc ff ff       	call   f0100d60 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101146:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101149:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010114c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010114f:	83 c4 10             	add    $0x10,%esp
f0101152:	eb 05                	jmp    f0101159 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101154:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0101159:	c9                   	leave  
f010115a:	c3                   	ret    

f010115b <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010115b:	55                   	push   %ebp
f010115c:	89 e5                	mov    %esp,%ebp
f010115e:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101161:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101164:	50                   	push   %eax
f0101165:	ff 75 10             	pushl  0x10(%ebp)
f0101168:	ff 75 0c             	pushl  0xc(%ebp)
f010116b:	ff 75 08             	pushl  0x8(%ebp)
f010116e:	e8 9a ff ff ff       	call   f010110d <vsnprintf>
	va_end(ap);

	return rc;
}
f0101173:	c9                   	leave  
f0101174:	c3                   	ret    

f0101175 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101175:	55                   	push   %ebp
f0101176:	89 e5                	mov    %esp,%ebp
f0101178:	57                   	push   %edi
f0101179:	56                   	push   %esi
f010117a:	53                   	push   %ebx
f010117b:	83 ec 0c             	sub    $0xc,%esp
f010117e:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0101181:	85 c0                	test   %eax,%eax
f0101183:	74 11                	je     f0101196 <readline+0x21>
		cprintf("%s", prompt);
f0101185:	83 ec 08             	sub    $0x8,%esp
f0101188:	50                   	push   %eax
f0101189:	68 b6 1d 10 f0       	push   $0xf0101db6
f010118e:	e8 cf f7 ff ff       	call   f0100962 <cprintf>
f0101193:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0101196:	83 ec 0c             	sub    $0xc,%esp
f0101199:	6a 00                	push   $0x0
f010119b:	e8 ce f4 ff ff       	call   f010066e <iscons>
f01011a0:	89 c7                	mov    %eax,%edi
f01011a2:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01011a5:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01011aa:	e8 ae f4 ff ff       	call   f010065d <getchar>
f01011af:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01011b1:	85 c0                	test   %eax,%eax
f01011b3:	79 18                	jns    f01011cd <readline+0x58>
			cprintf("read error: %e\n", c);
f01011b5:	83 ec 08             	sub    $0x8,%esp
f01011b8:	50                   	push   %eax
f01011b9:	68 c0 1f 10 f0       	push   $0xf0101fc0
f01011be:	e8 9f f7 ff ff       	call   f0100962 <cprintf>
			return NULL;
f01011c3:	83 c4 10             	add    $0x10,%esp
f01011c6:	b8 00 00 00 00       	mov    $0x0,%eax
f01011cb:	eb 79                	jmp    f0101246 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01011cd:	83 f8 08             	cmp    $0x8,%eax
f01011d0:	0f 94 c2             	sete   %dl
f01011d3:	83 f8 7f             	cmp    $0x7f,%eax
f01011d6:	0f 94 c0             	sete   %al
f01011d9:	08 c2                	or     %al,%dl
f01011db:	74 1a                	je     f01011f7 <readline+0x82>
f01011dd:	85 f6                	test   %esi,%esi
f01011df:	7e 16                	jle    f01011f7 <readline+0x82>
			if (echoing)
f01011e1:	85 ff                	test   %edi,%edi
f01011e3:	74 0d                	je     f01011f2 <readline+0x7d>
				cputchar('\b');
f01011e5:	83 ec 0c             	sub    $0xc,%esp
f01011e8:	6a 08                	push   $0x8
f01011ea:	e8 5e f4 ff ff       	call   f010064d <cputchar>
f01011ef:	83 c4 10             	add    $0x10,%esp
			i--;
f01011f2:	83 ee 01             	sub    $0x1,%esi
f01011f5:	eb b3                	jmp    f01011aa <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01011f7:	83 fb 1f             	cmp    $0x1f,%ebx
f01011fa:	7e 23                	jle    f010121f <readline+0xaa>
f01011fc:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101202:	7f 1b                	jg     f010121f <readline+0xaa>
			if (echoing)
f0101204:	85 ff                	test   %edi,%edi
f0101206:	74 0c                	je     f0101214 <readline+0x9f>
				cputchar(c);
f0101208:	83 ec 0c             	sub    $0xc,%esp
f010120b:	53                   	push   %ebx
f010120c:	e8 3c f4 ff ff       	call   f010064d <cputchar>
f0101211:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0101214:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f010121a:	8d 76 01             	lea    0x1(%esi),%esi
f010121d:	eb 8b                	jmp    f01011aa <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f010121f:	83 fb 0a             	cmp    $0xa,%ebx
f0101222:	74 05                	je     f0101229 <readline+0xb4>
f0101224:	83 fb 0d             	cmp    $0xd,%ebx
f0101227:	75 81                	jne    f01011aa <readline+0x35>
			if (echoing)
f0101229:	85 ff                	test   %edi,%edi
f010122b:	74 0d                	je     f010123a <readline+0xc5>
				cputchar('\n');
f010122d:	83 ec 0c             	sub    $0xc,%esp
f0101230:	6a 0a                	push   $0xa
f0101232:	e8 16 f4 ff ff       	call   f010064d <cputchar>
f0101237:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f010123a:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f0101241:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f0101246:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101249:	5b                   	pop    %ebx
f010124a:	5e                   	pop    %esi
f010124b:	5f                   	pop    %edi
f010124c:	5d                   	pop    %ebp
f010124d:	c3                   	ret    

f010124e <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f010124e:	55                   	push   %ebp
f010124f:	89 e5                	mov    %esp,%ebp
f0101251:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101254:	b8 00 00 00 00       	mov    $0x0,%eax
f0101259:	eb 03                	jmp    f010125e <strlen+0x10>
		n++;
f010125b:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f010125e:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101262:	75 f7                	jne    f010125b <strlen+0xd>
		n++;
	return n;
}
f0101264:	5d                   	pop    %ebp
f0101265:	c3                   	ret    

f0101266 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101266:	55                   	push   %ebp
f0101267:	89 e5                	mov    %esp,%ebp
f0101269:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010126c:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010126f:	ba 00 00 00 00       	mov    $0x0,%edx
f0101274:	eb 03                	jmp    f0101279 <strnlen+0x13>
		n++;
f0101276:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101279:	39 c2                	cmp    %eax,%edx
f010127b:	74 08                	je     f0101285 <strnlen+0x1f>
f010127d:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0101281:	75 f3                	jne    f0101276 <strnlen+0x10>
f0101283:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0101285:	5d                   	pop    %ebp
f0101286:	c3                   	ret    

f0101287 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101287:	55                   	push   %ebp
f0101288:	89 e5                	mov    %esp,%ebp
f010128a:	53                   	push   %ebx
f010128b:	8b 45 08             	mov    0x8(%ebp),%eax
f010128e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101291:	89 c2                	mov    %eax,%edx
f0101293:	83 c2 01             	add    $0x1,%edx
f0101296:	83 c1 01             	add    $0x1,%ecx
f0101299:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010129d:	88 5a ff             	mov    %bl,-0x1(%edx)
f01012a0:	84 db                	test   %bl,%bl
f01012a2:	75 ef                	jne    f0101293 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01012a4:	5b                   	pop    %ebx
f01012a5:	5d                   	pop    %ebp
f01012a6:	c3                   	ret    

f01012a7 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01012a7:	55                   	push   %ebp
f01012a8:	89 e5                	mov    %esp,%ebp
f01012aa:	53                   	push   %ebx
f01012ab:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01012ae:	53                   	push   %ebx
f01012af:	e8 9a ff ff ff       	call   f010124e <strlen>
f01012b4:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01012b7:	ff 75 0c             	pushl  0xc(%ebp)
f01012ba:	01 d8                	add    %ebx,%eax
f01012bc:	50                   	push   %eax
f01012bd:	e8 c5 ff ff ff       	call   f0101287 <strcpy>
	return dst;
}
f01012c2:	89 d8                	mov    %ebx,%eax
f01012c4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01012c7:	c9                   	leave  
f01012c8:	c3                   	ret    

f01012c9 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01012c9:	55                   	push   %ebp
f01012ca:	89 e5                	mov    %esp,%ebp
f01012cc:	56                   	push   %esi
f01012cd:	53                   	push   %ebx
f01012ce:	8b 75 08             	mov    0x8(%ebp),%esi
f01012d1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01012d4:	89 f3                	mov    %esi,%ebx
f01012d6:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01012d9:	89 f2                	mov    %esi,%edx
f01012db:	eb 0f                	jmp    f01012ec <strncpy+0x23>
		*dst++ = *src;
f01012dd:	83 c2 01             	add    $0x1,%edx
f01012e0:	0f b6 01             	movzbl (%ecx),%eax
f01012e3:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01012e6:	80 39 01             	cmpb   $0x1,(%ecx)
f01012e9:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01012ec:	39 da                	cmp    %ebx,%edx
f01012ee:	75 ed                	jne    f01012dd <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01012f0:	89 f0                	mov    %esi,%eax
f01012f2:	5b                   	pop    %ebx
f01012f3:	5e                   	pop    %esi
f01012f4:	5d                   	pop    %ebp
f01012f5:	c3                   	ret    

f01012f6 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01012f6:	55                   	push   %ebp
f01012f7:	89 e5                	mov    %esp,%ebp
f01012f9:	56                   	push   %esi
f01012fa:	53                   	push   %ebx
f01012fb:	8b 75 08             	mov    0x8(%ebp),%esi
f01012fe:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101301:	8b 55 10             	mov    0x10(%ebp),%edx
f0101304:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101306:	85 d2                	test   %edx,%edx
f0101308:	74 21                	je     f010132b <strlcpy+0x35>
f010130a:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f010130e:	89 f2                	mov    %esi,%edx
f0101310:	eb 09                	jmp    f010131b <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101312:	83 c2 01             	add    $0x1,%edx
f0101315:	83 c1 01             	add    $0x1,%ecx
f0101318:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f010131b:	39 c2                	cmp    %eax,%edx
f010131d:	74 09                	je     f0101328 <strlcpy+0x32>
f010131f:	0f b6 19             	movzbl (%ecx),%ebx
f0101322:	84 db                	test   %bl,%bl
f0101324:	75 ec                	jne    f0101312 <strlcpy+0x1c>
f0101326:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0101328:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f010132b:	29 f0                	sub    %esi,%eax
}
f010132d:	5b                   	pop    %ebx
f010132e:	5e                   	pop    %esi
f010132f:	5d                   	pop    %ebp
f0101330:	c3                   	ret    

f0101331 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101331:	55                   	push   %ebp
f0101332:	89 e5                	mov    %esp,%ebp
f0101334:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101337:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f010133a:	eb 06                	jmp    f0101342 <strcmp+0x11>
		p++, q++;
f010133c:	83 c1 01             	add    $0x1,%ecx
f010133f:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101342:	0f b6 01             	movzbl (%ecx),%eax
f0101345:	84 c0                	test   %al,%al
f0101347:	74 04                	je     f010134d <strcmp+0x1c>
f0101349:	3a 02                	cmp    (%edx),%al
f010134b:	74 ef                	je     f010133c <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f010134d:	0f b6 c0             	movzbl %al,%eax
f0101350:	0f b6 12             	movzbl (%edx),%edx
f0101353:	29 d0                	sub    %edx,%eax
}
f0101355:	5d                   	pop    %ebp
f0101356:	c3                   	ret    

f0101357 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101357:	55                   	push   %ebp
f0101358:	89 e5                	mov    %esp,%ebp
f010135a:	53                   	push   %ebx
f010135b:	8b 45 08             	mov    0x8(%ebp),%eax
f010135e:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101361:	89 c3                	mov    %eax,%ebx
f0101363:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0101366:	eb 06                	jmp    f010136e <strncmp+0x17>
		n--, p++, q++;
f0101368:	83 c0 01             	add    $0x1,%eax
f010136b:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010136e:	39 d8                	cmp    %ebx,%eax
f0101370:	74 15                	je     f0101387 <strncmp+0x30>
f0101372:	0f b6 08             	movzbl (%eax),%ecx
f0101375:	84 c9                	test   %cl,%cl
f0101377:	74 04                	je     f010137d <strncmp+0x26>
f0101379:	3a 0a                	cmp    (%edx),%cl
f010137b:	74 eb                	je     f0101368 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f010137d:	0f b6 00             	movzbl (%eax),%eax
f0101380:	0f b6 12             	movzbl (%edx),%edx
f0101383:	29 d0                	sub    %edx,%eax
f0101385:	eb 05                	jmp    f010138c <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101387:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f010138c:	5b                   	pop    %ebx
f010138d:	5d                   	pop    %ebp
f010138e:	c3                   	ret    

f010138f <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010138f:	55                   	push   %ebp
f0101390:	89 e5                	mov    %esp,%ebp
f0101392:	8b 45 08             	mov    0x8(%ebp),%eax
f0101395:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101399:	eb 07                	jmp    f01013a2 <strchr+0x13>
		if (*s == c)
f010139b:	38 ca                	cmp    %cl,%dl
f010139d:	74 0f                	je     f01013ae <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010139f:	83 c0 01             	add    $0x1,%eax
f01013a2:	0f b6 10             	movzbl (%eax),%edx
f01013a5:	84 d2                	test   %dl,%dl
f01013a7:	75 f2                	jne    f010139b <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01013a9:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01013ae:	5d                   	pop    %ebp
f01013af:	c3                   	ret    

f01013b0 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01013b0:	55                   	push   %ebp
f01013b1:	89 e5                	mov    %esp,%ebp
f01013b3:	8b 45 08             	mov    0x8(%ebp),%eax
f01013b6:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01013ba:	eb 03                	jmp    f01013bf <strfind+0xf>
f01013bc:	83 c0 01             	add    $0x1,%eax
f01013bf:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01013c2:	38 ca                	cmp    %cl,%dl
f01013c4:	74 04                	je     f01013ca <strfind+0x1a>
f01013c6:	84 d2                	test   %dl,%dl
f01013c8:	75 f2                	jne    f01013bc <strfind+0xc>
			break;
	return (char *) s;
}
f01013ca:	5d                   	pop    %ebp
f01013cb:	c3                   	ret    

f01013cc <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01013cc:	55                   	push   %ebp
f01013cd:	89 e5                	mov    %esp,%ebp
f01013cf:	57                   	push   %edi
f01013d0:	56                   	push   %esi
f01013d1:	53                   	push   %ebx
f01013d2:	8b 7d 08             	mov    0x8(%ebp),%edi
f01013d5:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01013d8:	85 c9                	test   %ecx,%ecx
f01013da:	74 36                	je     f0101412 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01013dc:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01013e2:	75 28                	jne    f010140c <memset+0x40>
f01013e4:	f6 c1 03             	test   $0x3,%cl
f01013e7:	75 23                	jne    f010140c <memset+0x40>
		c &= 0xFF;
f01013e9:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01013ed:	89 d3                	mov    %edx,%ebx
f01013ef:	c1 e3 08             	shl    $0x8,%ebx
f01013f2:	89 d6                	mov    %edx,%esi
f01013f4:	c1 e6 18             	shl    $0x18,%esi
f01013f7:	89 d0                	mov    %edx,%eax
f01013f9:	c1 e0 10             	shl    $0x10,%eax
f01013fc:	09 f0                	or     %esi,%eax
f01013fe:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0101400:	89 d8                	mov    %ebx,%eax
f0101402:	09 d0                	or     %edx,%eax
f0101404:	c1 e9 02             	shr    $0x2,%ecx
f0101407:	fc                   	cld    
f0101408:	f3 ab                	rep stos %eax,%es:(%edi)
f010140a:	eb 06                	jmp    f0101412 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010140c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010140f:	fc                   	cld    
f0101410:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101412:	89 f8                	mov    %edi,%eax
f0101414:	5b                   	pop    %ebx
f0101415:	5e                   	pop    %esi
f0101416:	5f                   	pop    %edi
f0101417:	5d                   	pop    %ebp
f0101418:	c3                   	ret    

f0101419 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101419:	55                   	push   %ebp
f010141a:	89 e5                	mov    %esp,%ebp
f010141c:	57                   	push   %edi
f010141d:	56                   	push   %esi
f010141e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101421:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101424:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101427:	39 c6                	cmp    %eax,%esi
f0101429:	73 35                	jae    f0101460 <memmove+0x47>
f010142b:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010142e:	39 d0                	cmp    %edx,%eax
f0101430:	73 2e                	jae    f0101460 <memmove+0x47>
		s += n;
		d += n;
f0101432:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101435:	89 d6                	mov    %edx,%esi
f0101437:	09 fe                	or     %edi,%esi
f0101439:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010143f:	75 13                	jne    f0101454 <memmove+0x3b>
f0101441:	f6 c1 03             	test   $0x3,%cl
f0101444:	75 0e                	jne    f0101454 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0101446:	83 ef 04             	sub    $0x4,%edi
f0101449:	8d 72 fc             	lea    -0x4(%edx),%esi
f010144c:	c1 e9 02             	shr    $0x2,%ecx
f010144f:	fd                   	std    
f0101450:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101452:	eb 09                	jmp    f010145d <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0101454:	83 ef 01             	sub    $0x1,%edi
f0101457:	8d 72 ff             	lea    -0x1(%edx),%esi
f010145a:	fd                   	std    
f010145b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f010145d:	fc                   	cld    
f010145e:	eb 1d                	jmp    f010147d <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101460:	89 f2                	mov    %esi,%edx
f0101462:	09 c2                	or     %eax,%edx
f0101464:	f6 c2 03             	test   $0x3,%dl
f0101467:	75 0f                	jne    f0101478 <memmove+0x5f>
f0101469:	f6 c1 03             	test   $0x3,%cl
f010146c:	75 0a                	jne    f0101478 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f010146e:	c1 e9 02             	shr    $0x2,%ecx
f0101471:	89 c7                	mov    %eax,%edi
f0101473:	fc                   	cld    
f0101474:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101476:	eb 05                	jmp    f010147d <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101478:	89 c7                	mov    %eax,%edi
f010147a:	fc                   	cld    
f010147b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010147d:	5e                   	pop    %esi
f010147e:	5f                   	pop    %edi
f010147f:	5d                   	pop    %ebp
f0101480:	c3                   	ret    

f0101481 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0101481:	55                   	push   %ebp
f0101482:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0101484:	ff 75 10             	pushl  0x10(%ebp)
f0101487:	ff 75 0c             	pushl  0xc(%ebp)
f010148a:	ff 75 08             	pushl  0x8(%ebp)
f010148d:	e8 87 ff ff ff       	call   f0101419 <memmove>
}
f0101492:	c9                   	leave  
f0101493:	c3                   	ret    

f0101494 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101494:	55                   	push   %ebp
f0101495:	89 e5                	mov    %esp,%ebp
f0101497:	56                   	push   %esi
f0101498:	53                   	push   %ebx
f0101499:	8b 45 08             	mov    0x8(%ebp),%eax
f010149c:	8b 55 0c             	mov    0xc(%ebp),%edx
f010149f:	89 c6                	mov    %eax,%esi
f01014a1:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01014a4:	eb 1a                	jmp    f01014c0 <memcmp+0x2c>
		if (*s1 != *s2)
f01014a6:	0f b6 08             	movzbl (%eax),%ecx
f01014a9:	0f b6 1a             	movzbl (%edx),%ebx
f01014ac:	38 d9                	cmp    %bl,%cl
f01014ae:	74 0a                	je     f01014ba <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01014b0:	0f b6 c1             	movzbl %cl,%eax
f01014b3:	0f b6 db             	movzbl %bl,%ebx
f01014b6:	29 d8                	sub    %ebx,%eax
f01014b8:	eb 0f                	jmp    f01014c9 <memcmp+0x35>
		s1++, s2++;
f01014ba:	83 c0 01             	add    $0x1,%eax
f01014bd:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01014c0:	39 f0                	cmp    %esi,%eax
f01014c2:	75 e2                	jne    f01014a6 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01014c4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01014c9:	5b                   	pop    %ebx
f01014ca:	5e                   	pop    %esi
f01014cb:	5d                   	pop    %ebp
f01014cc:	c3                   	ret    

f01014cd <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01014cd:	55                   	push   %ebp
f01014ce:	89 e5                	mov    %esp,%ebp
f01014d0:	53                   	push   %ebx
f01014d1:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01014d4:	89 c1                	mov    %eax,%ecx
f01014d6:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f01014d9:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01014dd:	eb 0a                	jmp    f01014e9 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f01014df:	0f b6 10             	movzbl (%eax),%edx
f01014e2:	39 da                	cmp    %ebx,%edx
f01014e4:	74 07                	je     f01014ed <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01014e6:	83 c0 01             	add    $0x1,%eax
f01014e9:	39 c8                	cmp    %ecx,%eax
f01014eb:	72 f2                	jb     f01014df <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01014ed:	5b                   	pop    %ebx
f01014ee:	5d                   	pop    %ebp
f01014ef:	c3                   	ret    

f01014f0 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01014f0:	55                   	push   %ebp
f01014f1:	89 e5                	mov    %esp,%ebp
f01014f3:	57                   	push   %edi
f01014f4:	56                   	push   %esi
f01014f5:	53                   	push   %ebx
f01014f6:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01014f9:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01014fc:	eb 03                	jmp    f0101501 <strtol+0x11>
		s++;
f01014fe:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101501:	0f b6 01             	movzbl (%ecx),%eax
f0101504:	3c 20                	cmp    $0x20,%al
f0101506:	74 f6                	je     f01014fe <strtol+0xe>
f0101508:	3c 09                	cmp    $0x9,%al
f010150a:	74 f2                	je     f01014fe <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f010150c:	3c 2b                	cmp    $0x2b,%al
f010150e:	75 0a                	jne    f010151a <strtol+0x2a>
		s++;
f0101510:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101513:	bf 00 00 00 00       	mov    $0x0,%edi
f0101518:	eb 11                	jmp    f010152b <strtol+0x3b>
f010151a:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f010151f:	3c 2d                	cmp    $0x2d,%al
f0101521:	75 08                	jne    f010152b <strtol+0x3b>
		s++, neg = 1;
f0101523:	83 c1 01             	add    $0x1,%ecx
f0101526:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010152b:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0101531:	75 15                	jne    f0101548 <strtol+0x58>
f0101533:	80 39 30             	cmpb   $0x30,(%ecx)
f0101536:	75 10                	jne    f0101548 <strtol+0x58>
f0101538:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f010153c:	75 7c                	jne    f01015ba <strtol+0xca>
		s += 2, base = 16;
f010153e:	83 c1 02             	add    $0x2,%ecx
f0101541:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101546:	eb 16                	jmp    f010155e <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0101548:	85 db                	test   %ebx,%ebx
f010154a:	75 12                	jne    f010155e <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010154c:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101551:	80 39 30             	cmpb   $0x30,(%ecx)
f0101554:	75 08                	jne    f010155e <strtol+0x6e>
		s++, base = 8;
f0101556:	83 c1 01             	add    $0x1,%ecx
f0101559:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f010155e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101563:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101566:	0f b6 11             	movzbl (%ecx),%edx
f0101569:	8d 72 d0             	lea    -0x30(%edx),%esi
f010156c:	89 f3                	mov    %esi,%ebx
f010156e:	80 fb 09             	cmp    $0x9,%bl
f0101571:	77 08                	ja     f010157b <strtol+0x8b>
			dig = *s - '0';
f0101573:	0f be d2             	movsbl %dl,%edx
f0101576:	83 ea 30             	sub    $0x30,%edx
f0101579:	eb 22                	jmp    f010159d <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f010157b:	8d 72 9f             	lea    -0x61(%edx),%esi
f010157e:	89 f3                	mov    %esi,%ebx
f0101580:	80 fb 19             	cmp    $0x19,%bl
f0101583:	77 08                	ja     f010158d <strtol+0x9d>
			dig = *s - 'a' + 10;
f0101585:	0f be d2             	movsbl %dl,%edx
f0101588:	83 ea 57             	sub    $0x57,%edx
f010158b:	eb 10                	jmp    f010159d <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f010158d:	8d 72 bf             	lea    -0x41(%edx),%esi
f0101590:	89 f3                	mov    %esi,%ebx
f0101592:	80 fb 19             	cmp    $0x19,%bl
f0101595:	77 16                	ja     f01015ad <strtol+0xbd>
			dig = *s - 'A' + 10;
f0101597:	0f be d2             	movsbl %dl,%edx
f010159a:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f010159d:	3b 55 10             	cmp    0x10(%ebp),%edx
f01015a0:	7d 0b                	jge    f01015ad <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f01015a2:	83 c1 01             	add    $0x1,%ecx
f01015a5:	0f af 45 10          	imul   0x10(%ebp),%eax
f01015a9:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f01015ab:	eb b9                	jmp    f0101566 <strtol+0x76>

	if (endptr)
f01015ad:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01015b1:	74 0d                	je     f01015c0 <strtol+0xd0>
		*endptr = (char *) s;
f01015b3:	8b 75 0c             	mov    0xc(%ebp),%esi
f01015b6:	89 0e                	mov    %ecx,(%esi)
f01015b8:	eb 06                	jmp    f01015c0 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01015ba:	85 db                	test   %ebx,%ebx
f01015bc:	74 98                	je     f0101556 <strtol+0x66>
f01015be:	eb 9e                	jmp    f010155e <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01015c0:	89 c2                	mov    %eax,%edx
f01015c2:	f7 da                	neg    %edx
f01015c4:	85 ff                	test   %edi,%edi
f01015c6:	0f 45 c2             	cmovne %edx,%eax
}
f01015c9:	5b                   	pop    %ebx
f01015ca:	5e                   	pop    %esi
f01015cb:	5f                   	pop    %edi
f01015cc:	5d                   	pop    %ebp
f01015cd:	c3                   	ret    
f01015ce:	66 90                	xchg   %ax,%ax

f01015d0 <__udivdi3>:
f01015d0:	55                   	push   %ebp
f01015d1:	57                   	push   %edi
f01015d2:	56                   	push   %esi
f01015d3:	53                   	push   %ebx
f01015d4:	83 ec 1c             	sub    $0x1c,%esp
f01015d7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f01015db:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f01015df:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f01015e3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01015e7:	85 f6                	test   %esi,%esi
f01015e9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01015ed:	89 ca                	mov    %ecx,%edx
f01015ef:	89 f8                	mov    %edi,%eax
f01015f1:	75 3d                	jne    f0101630 <__udivdi3+0x60>
f01015f3:	39 cf                	cmp    %ecx,%edi
f01015f5:	0f 87 c5 00 00 00    	ja     f01016c0 <__udivdi3+0xf0>
f01015fb:	85 ff                	test   %edi,%edi
f01015fd:	89 fd                	mov    %edi,%ebp
f01015ff:	75 0b                	jne    f010160c <__udivdi3+0x3c>
f0101601:	b8 01 00 00 00       	mov    $0x1,%eax
f0101606:	31 d2                	xor    %edx,%edx
f0101608:	f7 f7                	div    %edi
f010160a:	89 c5                	mov    %eax,%ebp
f010160c:	89 c8                	mov    %ecx,%eax
f010160e:	31 d2                	xor    %edx,%edx
f0101610:	f7 f5                	div    %ebp
f0101612:	89 c1                	mov    %eax,%ecx
f0101614:	89 d8                	mov    %ebx,%eax
f0101616:	89 cf                	mov    %ecx,%edi
f0101618:	f7 f5                	div    %ebp
f010161a:	89 c3                	mov    %eax,%ebx
f010161c:	89 d8                	mov    %ebx,%eax
f010161e:	89 fa                	mov    %edi,%edx
f0101620:	83 c4 1c             	add    $0x1c,%esp
f0101623:	5b                   	pop    %ebx
f0101624:	5e                   	pop    %esi
f0101625:	5f                   	pop    %edi
f0101626:	5d                   	pop    %ebp
f0101627:	c3                   	ret    
f0101628:	90                   	nop
f0101629:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101630:	39 ce                	cmp    %ecx,%esi
f0101632:	77 74                	ja     f01016a8 <__udivdi3+0xd8>
f0101634:	0f bd fe             	bsr    %esi,%edi
f0101637:	83 f7 1f             	xor    $0x1f,%edi
f010163a:	0f 84 98 00 00 00    	je     f01016d8 <__udivdi3+0x108>
f0101640:	bb 20 00 00 00       	mov    $0x20,%ebx
f0101645:	89 f9                	mov    %edi,%ecx
f0101647:	89 c5                	mov    %eax,%ebp
f0101649:	29 fb                	sub    %edi,%ebx
f010164b:	d3 e6                	shl    %cl,%esi
f010164d:	89 d9                	mov    %ebx,%ecx
f010164f:	d3 ed                	shr    %cl,%ebp
f0101651:	89 f9                	mov    %edi,%ecx
f0101653:	d3 e0                	shl    %cl,%eax
f0101655:	09 ee                	or     %ebp,%esi
f0101657:	89 d9                	mov    %ebx,%ecx
f0101659:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010165d:	89 d5                	mov    %edx,%ebp
f010165f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101663:	d3 ed                	shr    %cl,%ebp
f0101665:	89 f9                	mov    %edi,%ecx
f0101667:	d3 e2                	shl    %cl,%edx
f0101669:	89 d9                	mov    %ebx,%ecx
f010166b:	d3 e8                	shr    %cl,%eax
f010166d:	09 c2                	or     %eax,%edx
f010166f:	89 d0                	mov    %edx,%eax
f0101671:	89 ea                	mov    %ebp,%edx
f0101673:	f7 f6                	div    %esi
f0101675:	89 d5                	mov    %edx,%ebp
f0101677:	89 c3                	mov    %eax,%ebx
f0101679:	f7 64 24 0c          	mull   0xc(%esp)
f010167d:	39 d5                	cmp    %edx,%ebp
f010167f:	72 10                	jb     f0101691 <__udivdi3+0xc1>
f0101681:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101685:	89 f9                	mov    %edi,%ecx
f0101687:	d3 e6                	shl    %cl,%esi
f0101689:	39 c6                	cmp    %eax,%esi
f010168b:	73 07                	jae    f0101694 <__udivdi3+0xc4>
f010168d:	39 d5                	cmp    %edx,%ebp
f010168f:	75 03                	jne    f0101694 <__udivdi3+0xc4>
f0101691:	83 eb 01             	sub    $0x1,%ebx
f0101694:	31 ff                	xor    %edi,%edi
f0101696:	89 d8                	mov    %ebx,%eax
f0101698:	89 fa                	mov    %edi,%edx
f010169a:	83 c4 1c             	add    $0x1c,%esp
f010169d:	5b                   	pop    %ebx
f010169e:	5e                   	pop    %esi
f010169f:	5f                   	pop    %edi
f01016a0:	5d                   	pop    %ebp
f01016a1:	c3                   	ret    
f01016a2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01016a8:	31 ff                	xor    %edi,%edi
f01016aa:	31 db                	xor    %ebx,%ebx
f01016ac:	89 d8                	mov    %ebx,%eax
f01016ae:	89 fa                	mov    %edi,%edx
f01016b0:	83 c4 1c             	add    $0x1c,%esp
f01016b3:	5b                   	pop    %ebx
f01016b4:	5e                   	pop    %esi
f01016b5:	5f                   	pop    %edi
f01016b6:	5d                   	pop    %ebp
f01016b7:	c3                   	ret    
f01016b8:	90                   	nop
f01016b9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01016c0:	89 d8                	mov    %ebx,%eax
f01016c2:	f7 f7                	div    %edi
f01016c4:	31 ff                	xor    %edi,%edi
f01016c6:	89 c3                	mov    %eax,%ebx
f01016c8:	89 d8                	mov    %ebx,%eax
f01016ca:	89 fa                	mov    %edi,%edx
f01016cc:	83 c4 1c             	add    $0x1c,%esp
f01016cf:	5b                   	pop    %ebx
f01016d0:	5e                   	pop    %esi
f01016d1:	5f                   	pop    %edi
f01016d2:	5d                   	pop    %ebp
f01016d3:	c3                   	ret    
f01016d4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01016d8:	39 ce                	cmp    %ecx,%esi
f01016da:	72 0c                	jb     f01016e8 <__udivdi3+0x118>
f01016dc:	31 db                	xor    %ebx,%ebx
f01016de:	3b 44 24 08          	cmp    0x8(%esp),%eax
f01016e2:	0f 87 34 ff ff ff    	ja     f010161c <__udivdi3+0x4c>
f01016e8:	bb 01 00 00 00       	mov    $0x1,%ebx
f01016ed:	e9 2a ff ff ff       	jmp    f010161c <__udivdi3+0x4c>
f01016f2:	66 90                	xchg   %ax,%ax
f01016f4:	66 90                	xchg   %ax,%ax
f01016f6:	66 90                	xchg   %ax,%ax
f01016f8:	66 90                	xchg   %ax,%ax
f01016fa:	66 90                	xchg   %ax,%ax
f01016fc:	66 90                	xchg   %ax,%ax
f01016fe:	66 90                	xchg   %ax,%ax

f0101700 <__umoddi3>:
f0101700:	55                   	push   %ebp
f0101701:	57                   	push   %edi
f0101702:	56                   	push   %esi
f0101703:	53                   	push   %ebx
f0101704:	83 ec 1c             	sub    $0x1c,%esp
f0101707:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010170b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010170f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0101713:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101717:	85 d2                	test   %edx,%edx
f0101719:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010171d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101721:	89 f3                	mov    %esi,%ebx
f0101723:	89 3c 24             	mov    %edi,(%esp)
f0101726:	89 74 24 04          	mov    %esi,0x4(%esp)
f010172a:	75 1c                	jne    f0101748 <__umoddi3+0x48>
f010172c:	39 f7                	cmp    %esi,%edi
f010172e:	76 50                	jbe    f0101780 <__umoddi3+0x80>
f0101730:	89 c8                	mov    %ecx,%eax
f0101732:	89 f2                	mov    %esi,%edx
f0101734:	f7 f7                	div    %edi
f0101736:	89 d0                	mov    %edx,%eax
f0101738:	31 d2                	xor    %edx,%edx
f010173a:	83 c4 1c             	add    $0x1c,%esp
f010173d:	5b                   	pop    %ebx
f010173e:	5e                   	pop    %esi
f010173f:	5f                   	pop    %edi
f0101740:	5d                   	pop    %ebp
f0101741:	c3                   	ret    
f0101742:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101748:	39 f2                	cmp    %esi,%edx
f010174a:	89 d0                	mov    %edx,%eax
f010174c:	77 52                	ja     f01017a0 <__umoddi3+0xa0>
f010174e:	0f bd ea             	bsr    %edx,%ebp
f0101751:	83 f5 1f             	xor    $0x1f,%ebp
f0101754:	75 5a                	jne    f01017b0 <__umoddi3+0xb0>
f0101756:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010175a:	0f 82 e0 00 00 00    	jb     f0101840 <__umoddi3+0x140>
f0101760:	39 0c 24             	cmp    %ecx,(%esp)
f0101763:	0f 86 d7 00 00 00    	jbe    f0101840 <__umoddi3+0x140>
f0101769:	8b 44 24 08          	mov    0x8(%esp),%eax
f010176d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0101771:	83 c4 1c             	add    $0x1c,%esp
f0101774:	5b                   	pop    %ebx
f0101775:	5e                   	pop    %esi
f0101776:	5f                   	pop    %edi
f0101777:	5d                   	pop    %ebp
f0101778:	c3                   	ret    
f0101779:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101780:	85 ff                	test   %edi,%edi
f0101782:	89 fd                	mov    %edi,%ebp
f0101784:	75 0b                	jne    f0101791 <__umoddi3+0x91>
f0101786:	b8 01 00 00 00       	mov    $0x1,%eax
f010178b:	31 d2                	xor    %edx,%edx
f010178d:	f7 f7                	div    %edi
f010178f:	89 c5                	mov    %eax,%ebp
f0101791:	89 f0                	mov    %esi,%eax
f0101793:	31 d2                	xor    %edx,%edx
f0101795:	f7 f5                	div    %ebp
f0101797:	89 c8                	mov    %ecx,%eax
f0101799:	f7 f5                	div    %ebp
f010179b:	89 d0                	mov    %edx,%eax
f010179d:	eb 99                	jmp    f0101738 <__umoddi3+0x38>
f010179f:	90                   	nop
f01017a0:	89 c8                	mov    %ecx,%eax
f01017a2:	89 f2                	mov    %esi,%edx
f01017a4:	83 c4 1c             	add    $0x1c,%esp
f01017a7:	5b                   	pop    %ebx
f01017a8:	5e                   	pop    %esi
f01017a9:	5f                   	pop    %edi
f01017aa:	5d                   	pop    %ebp
f01017ab:	c3                   	ret    
f01017ac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01017b0:	8b 34 24             	mov    (%esp),%esi
f01017b3:	bf 20 00 00 00       	mov    $0x20,%edi
f01017b8:	89 e9                	mov    %ebp,%ecx
f01017ba:	29 ef                	sub    %ebp,%edi
f01017bc:	d3 e0                	shl    %cl,%eax
f01017be:	89 f9                	mov    %edi,%ecx
f01017c0:	89 f2                	mov    %esi,%edx
f01017c2:	d3 ea                	shr    %cl,%edx
f01017c4:	89 e9                	mov    %ebp,%ecx
f01017c6:	09 c2                	or     %eax,%edx
f01017c8:	89 d8                	mov    %ebx,%eax
f01017ca:	89 14 24             	mov    %edx,(%esp)
f01017cd:	89 f2                	mov    %esi,%edx
f01017cf:	d3 e2                	shl    %cl,%edx
f01017d1:	89 f9                	mov    %edi,%ecx
f01017d3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01017d7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01017db:	d3 e8                	shr    %cl,%eax
f01017dd:	89 e9                	mov    %ebp,%ecx
f01017df:	89 c6                	mov    %eax,%esi
f01017e1:	d3 e3                	shl    %cl,%ebx
f01017e3:	89 f9                	mov    %edi,%ecx
f01017e5:	89 d0                	mov    %edx,%eax
f01017e7:	d3 e8                	shr    %cl,%eax
f01017e9:	89 e9                	mov    %ebp,%ecx
f01017eb:	09 d8                	or     %ebx,%eax
f01017ed:	89 d3                	mov    %edx,%ebx
f01017ef:	89 f2                	mov    %esi,%edx
f01017f1:	f7 34 24             	divl   (%esp)
f01017f4:	89 d6                	mov    %edx,%esi
f01017f6:	d3 e3                	shl    %cl,%ebx
f01017f8:	f7 64 24 04          	mull   0x4(%esp)
f01017fc:	39 d6                	cmp    %edx,%esi
f01017fe:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0101802:	89 d1                	mov    %edx,%ecx
f0101804:	89 c3                	mov    %eax,%ebx
f0101806:	72 08                	jb     f0101810 <__umoddi3+0x110>
f0101808:	75 11                	jne    f010181b <__umoddi3+0x11b>
f010180a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010180e:	73 0b                	jae    f010181b <__umoddi3+0x11b>
f0101810:	2b 44 24 04          	sub    0x4(%esp),%eax
f0101814:	1b 14 24             	sbb    (%esp),%edx
f0101817:	89 d1                	mov    %edx,%ecx
f0101819:	89 c3                	mov    %eax,%ebx
f010181b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010181f:	29 da                	sub    %ebx,%edx
f0101821:	19 ce                	sbb    %ecx,%esi
f0101823:	89 f9                	mov    %edi,%ecx
f0101825:	89 f0                	mov    %esi,%eax
f0101827:	d3 e0                	shl    %cl,%eax
f0101829:	89 e9                	mov    %ebp,%ecx
f010182b:	d3 ea                	shr    %cl,%edx
f010182d:	89 e9                	mov    %ebp,%ecx
f010182f:	d3 ee                	shr    %cl,%esi
f0101831:	09 d0                	or     %edx,%eax
f0101833:	89 f2                	mov    %esi,%edx
f0101835:	83 c4 1c             	add    $0x1c,%esp
f0101838:	5b                   	pop    %ebx
f0101839:	5e                   	pop    %esi
f010183a:	5f                   	pop    %edi
f010183b:	5d                   	pop    %ebp
f010183c:	c3                   	ret    
f010183d:	8d 76 00             	lea    0x0(%esi),%esi
f0101840:	29 f9                	sub    %edi,%ecx
f0101842:	19 d6                	sbb    %edx,%esi
f0101844:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101848:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010184c:	e9 18 ff ff ff       	jmp    f0101769 <__umoddi3+0x69>
