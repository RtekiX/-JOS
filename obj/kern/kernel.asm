
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
f0100015:	b8 00 40 11 00       	mov    $0x114000,%eax
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
f0100034:	bc 00 40 11 f0       	mov    $0xf0114000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 70 69 11 f0       	mov    $0xf0116970,%eax
f010004b:	2d 00 63 11 f0       	sub    $0xf0116300,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 00 63 11 f0       	push   $0xf0116300
f0100058:	e8 88 31 00 00       	call   f01031e5 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 88 04 00 00       	call   f01004ea <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 80 36 10 f0       	push   $0xf0103680
f010006f:	e8 07 27 00 00       	call   f010277b <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 14 10 00 00       	call   f010108d <mem_init>
f0100079:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010007c:	83 ec 0c             	sub    $0xc,%esp
f010007f:	6a 00                	push   $0x0
f0100081:	e8 01 07 00 00       	call   f0100787 <monitor>
f0100086:	83 c4 10             	add    $0x10,%esp
f0100089:	eb f1                	jmp    f010007c <i386_init+0x3c>

f010008b <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f010008b:	55                   	push   %ebp
f010008c:	89 e5                	mov    %esp,%ebp
f010008e:	56                   	push   %esi
f010008f:	53                   	push   %ebx
f0100090:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100093:	83 3d 60 69 11 f0 00 	cmpl   $0x0,0xf0116960
f010009a:	75 37                	jne    f01000d3 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f010009c:	89 35 60 69 11 f0    	mov    %esi,0xf0116960

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000a2:	fa                   	cli    
f01000a3:	fc                   	cld    

	va_start(ap, fmt);
f01000a4:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000a7:	83 ec 04             	sub    $0x4,%esp
f01000aa:	ff 75 0c             	pushl  0xc(%ebp)
f01000ad:	ff 75 08             	pushl  0x8(%ebp)
f01000b0:	68 9b 36 10 f0       	push   $0xf010369b
f01000b5:	e8 c1 26 00 00       	call   f010277b <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 91 26 00 00       	call   f0102755 <vcprintf>
	cprintf("\n");
f01000c4:	c7 04 24 33 3e 10 f0 	movl   $0xf0103e33,(%esp)
f01000cb:	e8 ab 26 00 00       	call   f010277b <cprintf>
	va_end(ap);
f01000d0:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000d3:	83 ec 0c             	sub    $0xc,%esp
f01000d6:	6a 00                	push   $0x0
f01000d8:	e8 aa 06 00 00       	call   f0100787 <monitor>
f01000dd:	83 c4 10             	add    $0x10,%esp
f01000e0:	eb f1                	jmp    f01000d3 <_panic+0x48>

f01000e2 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000e2:	55                   	push   %ebp
f01000e3:	89 e5                	mov    %esp,%ebp
f01000e5:	53                   	push   %ebx
f01000e6:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000e9:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000ec:	ff 75 0c             	pushl  0xc(%ebp)
f01000ef:	ff 75 08             	pushl  0x8(%ebp)
f01000f2:	68 b3 36 10 f0       	push   $0xf01036b3
f01000f7:	e8 7f 26 00 00       	call   f010277b <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 4d 26 00 00       	call   f0102755 <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 33 3e 10 f0 	movl   $0xf0103e33,(%esp)
f010010f:	e8 67 26 00 00       	call   f010277b <cprintf>
	va_end(ap);
}
f0100114:	83 c4 10             	add    $0x10,%esp
f0100117:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010011a:	c9                   	leave  
f010011b:	c3                   	ret    

f010011c <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010011c:	55                   	push   %ebp
f010011d:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010011f:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100124:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100125:	a8 01                	test   $0x1,%al
f0100127:	74 0b                	je     f0100134 <serial_proc_data+0x18>
f0100129:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010012e:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010012f:	0f b6 c0             	movzbl %al,%eax
f0100132:	eb 05                	jmp    f0100139 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100134:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100139:	5d                   	pop    %ebp
f010013a:	c3                   	ret    

f010013b <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010013b:	55                   	push   %ebp
f010013c:	89 e5                	mov    %esp,%ebp
f010013e:	53                   	push   %ebx
f010013f:	83 ec 04             	sub    $0x4,%esp
f0100142:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100144:	eb 2b                	jmp    f0100171 <cons_intr+0x36>
		if (c == 0)
f0100146:	85 c0                	test   %eax,%eax
f0100148:	74 27                	je     f0100171 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f010014a:	8b 0d 24 65 11 f0    	mov    0xf0116524,%ecx
f0100150:	8d 51 01             	lea    0x1(%ecx),%edx
f0100153:	89 15 24 65 11 f0    	mov    %edx,0xf0116524
f0100159:	88 81 20 63 11 f0    	mov    %al,-0xfee9ce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f010015f:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100165:	75 0a                	jne    f0100171 <cons_intr+0x36>
			cons.wpos = 0;
f0100167:	c7 05 24 65 11 f0 00 	movl   $0x0,0xf0116524
f010016e:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100171:	ff d3                	call   *%ebx
f0100173:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100176:	75 ce                	jne    f0100146 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100178:	83 c4 04             	add    $0x4,%esp
f010017b:	5b                   	pop    %ebx
f010017c:	5d                   	pop    %ebp
f010017d:	c3                   	ret    

f010017e <kbd_proc_data>:
f010017e:	ba 64 00 00 00       	mov    $0x64,%edx
f0100183:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100184:	a8 01                	test   $0x1,%al
f0100186:	0f 84 f0 00 00 00    	je     f010027c <kbd_proc_data+0xfe>
f010018c:	ba 60 00 00 00       	mov    $0x60,%edx
f0100191:	ec                   	in     (%dx),%al
f0100192:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100194:	3c e0                	cmp    $0xe0,%al
f0100196:	75 0d                	jne    f01001a5 <kbd_proc_data+0x27>
		// E0 escape character
		shift |= E0ESC;
f0100198:	83 0d 00 63 11 f0 40 	orl    $0x40,0xf0116300
		return 0;
f010019f:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001a4:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001a5:	55                   	push   %ebp
f01001a6:	89 e5                	mov    %esp,%ebp
f01001a8:	53                   	push   %ebx
f01001a9:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001ac:	84 c0                	test   %al,%al
f01001ae:	79 36                	jns    f01001e6 <kbd_proc_data+0x68>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001b0:	8b 0d 00 63 11 f0    	mov    0xf0116300,%ecx
f01001b6:	89 cb                	mov    %ecx,%ebx
f01001b8:	83 e3 40             	and    $0x40,%ebx
f01001bb:	83 e0 7f             	and    $0x7f,%eax
f01001be:	85 db                	test   %ebx,%ebx
f01001c0:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001c3:	0f b6 d2             	movzbl %dl,%edx
f01001c6:	0f b6 82 20 38 10 f0 	movzbl -0xfefc7e0(%edx),%eax
f01001cd:	83 c8 40             	or     $0x40,%eax
f01001d0:	0f b6 c0             	movzbl %al,%eax
f01001d3:	f7 d0                	not    %eax
f01001d5:	21 c8                	and    %ecx,%eax
f01001d7:	a3 00 63 11 f0       	mov    %eax,0xf0116300
		return 0;
f01001dc:	b8 00 00 00 00       	mov    $0x0,%eax
f01001e1:	e9 9e 00 00 00       	jmp    f0100284 <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f01001e6:	8b 0d 00 63 11 f0    	mov    0xf0116300,%ecx
f01001ec:	f6 c1 40             	test   $0x40,%cl
f01001ef:	74 0e                	je     f01001ff <kbd_proc_data+0x81>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01001f1:	83 c8 80             	or     $0xffffff80,%eax
f01001f4:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01001f6:	83 e1 bf             	and    $0xffffffbf,%ecx
f01001f9:	89 0d 00 63 11 f0    	mov    %ecx,0xf0116300
	}

	shift |= shiftcode[data];
f01001ff:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100202:	0f b6 82 20 38 10 f0 	movzbl -0xfefc7e0(%edx),%eax
f0100209:	0b 05 00 63 11 f0    	or     0xf0116300,%eax
f010020f:	0f b6 8a 20 37 10 f0 	movzbl -0xfefc8e0(%edx),%ecx
f0100216:	31 c8                	xor    %ecx,%eax
f0100218:	a3 00 63 11 f0       	mov    %eax,0xf0116300

	c = charcode[shift & (CTL | SHIFT)][data];
f010021d:	89 c1                	mov    %eax,%ecx
f010021f:	83 e1 03             	and    $0x3,%ecx
f0100222:	8b 0c 8d 00 37 10 f0 	mov    -0xfefc900(,%ecx,4),%ecx
f0100229:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010022d:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100230:	a8 08                	test   $0x8,%al
f0100232:	74 1b                	je     f010024f <kbd_proc_data+0xd1>
		if ('a' <= c && c <= 'z')
f0100234:	89 da                	mov    %ebx,%edx
f0100236:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100239:	83 f9 19             	cmp    $0x19,%ecx
f010023c:	77 05                	ja     f0100243 <kbd_proc_data+0xc5>
			c += 'A' - 'a';
f010023e:	83 eb 20             	sub    $0x20,%ebx
f0100241:	eb 0c                	jmp    f010024f <kbd_proc_data+0xd1>
		else if ('A' <= c && c <= 'Z')
f0100243:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100246:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100249:	83 fa 19             	cmp    $0x19,%edx
f010024c:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010024f:	f7 d0                	not    %eax
f0100251:	a8 06                	test   $0x6,%al
f0100253:	75 2d                	jne    f0100282 <kbd_proc_data+0x104>
f0100255:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f010025b:	75 25                	jne    f0100282 <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f010025d:	83 ec 0c             	sub    $0xc,%esp
f0100260:	68 cd 36 10 f0       	push   $0xf01036cd
f0100265:	e8 11 25 00 00       	call   f010277b <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010026a:	ba 92 00 00 00       	mov    $0x92,%edx
f010026f:	b8 03 00 00 00       	mov    $0x3,%eax
f0100274:	ee                   	out    %al,(%dx)
f0100275:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100278:	89 d8                	mov    %ebx,%eax
f010027a:	eb 08                	jmp    f0100284 <kbd_proc_data+0x106>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f010027c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100281:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100282:	89 d8                	mov    %ebx,%eax
}
f0100284:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100287:	c9                   	leave  
f0100288:	c3                   	ret    

f0100289 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100289:	55                   	push   %ebp
f010028a:	89 e5                	mov    %esp,%ebp
f010028c:	57                   	push   %edi
f010028d:	56                   	push   %esi
f010028e:	53                   	push   %ebx
f010028f:	83 ec 1c             	sub    $0x1c,%esp
f0100292:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f0100294:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100299:	be fd 03 00 00       	mov    $0x3fd,%esi
f010029e:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002a3:	eb 09                	jmp    f01002ae <cons_putc+0x25>
f01002a5:	89 ca                	mov    %ecx,%edx
f01002a7:	ec                   	in     (%dx),%al
f01002a8:	ec                   	in     (%dx),%al
f01002a9:	ec                   	in     (%dx),%al
f01002aa:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002ab:	83 c3 01             	add    $0x1,%ebx
f01002ae:	89 f2                	mov    %esi,%edx
f01002b0:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002b1:	a8 20                	test   $0x20,%al
f01002b3:	75 08                	jne    f01002bd <cons_putc+0x34>
f01002b5:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002bb:	7e e8                	jle    f01002a5 <cons_putc+0x1c>
f01002bd:	89 f8                	mov    %edi,%eax
f01002bf:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002c2:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002c7:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002c8:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002cd:	be 79 03 00 00       	mov    $0x379,%esi
f01002d2:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002d7:	eb 09                	jmp    f01002e2 <cons_putc+0x59>
f01002d9:	89 ca                	mov    %ecx,%edx
f01002db:	ec                   	in     (%dx),%al
f01002dc:	ec                   	in     (%dx),%al
f01002dd:	ec                   	in     (%dx),%al
f01002de:	ec                   	in     (%dx),%al
f01002df:	83 c3 01             	add    $0x1,%ebx
f01002e2:	89 f2                	mov    %esi,%edx
f01002e4:	ec                   	in     (%dx),%al
f01002e5:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002eb:	7f 04                	jg     f01002f1 <cons_putc+0x68>
f01002ed:	84 c0                	test   %al,%al
f01002ef:	79 e8                	jns    f01002d9 <cons_putc+0x50>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002f1:	ba 78 03 00 00       	mov    $0x378,%edx
f01002f6:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f01002fa:	ee                   	out    %al,(%dx)
f01002fb:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100300:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100305:	ee                   	out    %al,(%dx)
f0100306:	b8 08 00 00 00       	mov    $0x8,%eax
f010030b:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010030c:	89 fa                	mov    %edi,%edx
f010030e:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100314:	89 f8                	mov    %edi,%eax
f0100316:	80 cc 07             	or     $0x7,%ah
f0100319:	85 d2                	test   %edx,%edx
f010031b:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f010031e:	89 f8                	mov    %edi,%eax
f0100320:	0f b6 c0             	movzbl %al,%eax
f0100323:	83 f8 09             	cmp    $0x9,%eax
f0100326:	74 74                	je     f010039c <cons_putc+0x113>
f0100328:	83 f8 09             	cmp    $0x9,%eax
f010032b:	7f 0a                	jg     f0100337 <cons_putc+0xae>
f010032d:	83 f8 08             	cmp    $0x8,%eax
f0100330:	74 14                	je     f0100346 <cons_putc+0xbd>
f0100332:	e9 99 00 00 00       	jmp    f01003d0 <cons_putc+0x147>
f0100337:	83 f8 0a             	cmp    $0xa,%eax
f010033a:	74 3a                	je     f0100376 <cons_putc+0xed>
f010033c:	83 f8 0d             	cmp    $0xd,%eax
f010033f:	74 3d                	je     f010037e <cons_putc+0xf5>
f0100341:	e9 8a 00 00 00       	jmp    f01003d0 <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f0100346:	0f b7 05 28 65 11 f0 	movzwl 0xf0116528,%eax
f010034d:	66 85 c0             	test   %ax,%ax
f0100350:	0f 84 e6 00 00 00    	je     f010043c <cons_putc+0x1b3>
			crt_pos--;
f0100356:	83 e8 01             	sub    $0x1,%eax
f0100359:	66 a3 28 65 11 f0    	mov    %ax,0xf0116528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010035f:	0f b7 c0             	movzwl %ax,%eax
f0100362:	66 81 e7 00 ff       	and    $0xff00,%di
f0100367:	83 cf 20             	or     $0x20,%edi
f010036a:	8b 15 2c 65 11 f0    	mov    0xf011652c,%edx
f0100370:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100374:	eb 78                	jmp    f01003ee <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100376:	66 83 05 28 65 11 f0 	addw   $0x50,0xf0116528
f010037d:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010037e:	0f b7 05 28 65 11 f0 	movzwl 0xf0116528,%eax
f0100385:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f010038b:	c1 e8 16             	shr    $0x16,%eax
f010038e:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100391:	c1 e0 04             	shl    $0x4,%eax
f0100394:	66 a3 28 65 11 f0    	mov    %ax,0xf0116528
f010039a:	eb 52                	jmp    f01003ee <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f010039c:	b8 20 00 00 00       	mov    $0x20,%eax
f01003a1:	e8 e3 fe ff ff       	call   f0100289 <cons_putc>
		cons_putc(' ');
f01003a6:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ab:	e8 d9 fe ff ff       	call   f0100289 <cons_putc>
		cons_putc(' ');
f01003b0:	b8 20 00 00 00       	mov    $0x20,%eax
f01003b5:	e8 cf fe ff ff       	call   f0100289 <cons_putc>
		cons_putc(' ');
f01003ba:	b8 20 00 00 00       	mov    $0x20,%eax
f01003bf:	e8 c5 fe ff ff       	call   f0100289 <cons_putc>
		cons_putc(' ');
f01003c4:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c9:	e8 bb fe ff ff       	call   f0100289 <cons_putc>
f01003ce:	eb 1e                	jmp    f01003ee <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003d0:	0f b7 05 28 65 11 f0 	movzwl 0xf0116528,%eax
f01003d7:	8d 50 01             	lea    0x1(%eax),%edx
f01003da:	66 89 15 28 65 11 f0 	mov    %dx,0xf0116528
f01003e1:	0f b7 c0             	movzwl %ax,%eax
f01003e4:	8b 15 2c 65 11 f0    	mov    0xf011652c,%edx
f01003ea:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01003ee:	66 81 3d 28 65 11 f0 	cmpw   $0x7cf,0xf0116528
f01003f5:	cf 07 
f01003f7:	76 43                	jbe    f010043c <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01003f9:	a1 2c 65 11 f0       	mov    0xf011652c,%eax
f01003fe:	83 ec 04             	sub    $0x4,%esp
f0100401:	68 00 0f 00 00       	push   $0xf00
f0100406:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010040c:	52                   	push   %edx
f010040d:	50                   	push   %eax
f010040e:	e8 1f 2e 00 00       	call   f0103232 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100413:	8b 15 2c 65 11 f0    	mov    0xf011652c,%edx
f0100419:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f010041f:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100425:	83 c4 10             	add    $0x10,%esp
f0100428:	66 c7 00 20 07       	movw   $0x720,(%eax)
f010042d:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100430:	39 d0                	cmp    %edx,%eax
f0100432:	75 f4                	jne    f0100428 <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100434:	66 83 2d 28 65 11 f0 	subw   $0x50,0xf0116528
f010043b:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010043c:	8b 0d 30 65 11 f0    	mov    0xf0116530,%ecx
f0100442:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100447:	89 ca                	mov    %ecx,%edx
f0100449:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010044a:	0f b7 1d 28 65 11 f0 	movzwl 0xf0116528,%ebx
f0100451:	8d 71 01             	lea    0x1(%ecx),%esi
f0100454:	89 d8                	mov    %ebx,%eax
f0100456:	66 c1 e8 08          	shr    $0x8,%ax
f010045a:	89 f2                	mov    %esi,%edx
f010045c:	ee                   	out    %al,(%dx)
f010045d:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100462:	89 ca                	mov    %ecx,%edx
f0100464:	ee                   	out    %al,(%dx)
f0100465:	89 d8                	mov    %ebx,%eax
f0100467:	89 f2                	mov    %esi,%edx
f0100469:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010046a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010046d:	5b                   	pop    %ebx
f010046e:	5e                   	pop    %esi
f010046f:	5f                   	pop    %edi
f0100470:	5d                   	pop    %ebp
f0100471:	c3                   	ret    

f0100472 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100472:	80 3d 34 65 11 f0 00 	cmpb   $0x0,0xf0116534
f0100479:	74 11                	je     f010048c <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f010047b:	55                   	push   %ebp
f010047c:	89 e5                	mov    %esp,%ebp
f010047e:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100481:	b8 1c 01 10 f0       	mov    $0xf010011c,%eax
f0100486:	e8 b0 fc ff ff       	call   f010013b <cons_intr>
}
f010048b:	c9                   	leave  
f010048c:	f3 c3                	repz ret 

f010048e <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f010048e:	55                   	push   %ebp
f010048f:	89 e5                	mov    %esp,%ebp
f0100491:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100494:	b8 7e 01 10 f0       	mov    $0xf010017e,%eax
f0100499:	e8 9d fc ff ff       	call   f010013b <cons_intr>
}
f010049e:	c9                   	leave  
f010049f:	c3                   	ret    

f01004a0 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004a0:	55                   	push   %ebp
f01004a1:	89 e5                	mov    %esp,%ebp
f01004a3:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004a6:	e8 c7 ff ff ff       	call   f0100472 <serial_intr>
	kbd_intr();
f01004ab:	e8 de ff ff ff       	call   f010048e <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004b0:	a1 20 65 11 f0       	mov    0xf0116520,%eax
f01004b5:	3b 05 24 65 11 f0    	cmp    0xf0116524,%eax
f01004bb:	74 26                	je     f01004e3 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004bd:	8d 50 01             	lea    0x1(%eax),%edx
f01004c0:	89 15 20 65 11 f0    	mov    %edx,0xf0116520
f01004c6:	0f b6 88 20 63 11 f0 	movzbl -0xfee9ce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01004cd:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01004cf:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004d5:	75 11                	jne    f01004e8 <cons_getc+0x48>
			cons.rpos = 0;
f01004d7:	c7 05 20 65 11 f0 00 	movl   $0x0,0xf0116520
f01004de:	00 00 00 
f01004e1:	eb 05                	jmp    f01004e8 <cons_getc+0x48>
		return c;
	}
	return 0;
f01004e3:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01004e8:	c9                   	leave  
f01004e9:	c3                   	ret    

f01004ea <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004ea:	55                   	push   %ebp
f01004eb:	89 e5                	mov    %esp,%ebp
f01004ed:	57                   	push   %edi
f01004ee:	56                   	push   %esi
f01004ef:	53                   	push   %ebx
f01004f0:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f01004f3:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f01004fa:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100501:	5a a5 
	if (*cp != 0xA55A) {
f0100503:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010050a:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010050e:	74 11                	je     f0100521 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100510:	c7 05 30 65 11 f0 b4 	movl   $0x3b4,0xf0116530
f0100517:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010051a:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f010051f:	eb 16                	jmp    f0100537 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100521:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100528:	c7 05 30 65 11 f0 d4 	movl   $0x3d4,0xf0116530
f010052f:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100532:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100537:	8b 3d 30 65 11 f0    	mov    0xf0116530,%edi
f010053d:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100542:	89 fa                	mov    %edi,%edx
f0100544:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100545:	8d 5f 01             	lea    0x1(%edi),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100548:	89 da                	mov    %ebx,%edx
f010054a:	ec                   	in     (%dx),%al
f010054b:	0f b6 c8             	movzbl %al,%ecx
f010054e:	c1 e1 08             	shl    $0x8,%ecx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100551:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100556:	89 fa                	mov    %edi,%edx
f0100558:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100559:	89 da                	mov    %ebx,%edx
f010055b:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f010055c:	89 35 2c 65 11 f0    	mov    %esi,0xf011652c
	crt_pos = pos;
f0100562:	0f b6 c0             	movzbl %al,%eax
f0100565:	09 c8                	or     %ecx,%eax
f0100567:	66 a3 28 65 11 f0    	mov    %ax,0xf0116528
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010056d:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100572:	b8 00 00 00 00       	mov    $0x0,%eax
f0100577:	89 f2                	mov    %esi,%edx
f0100579:	ee                   	out    %al,(%dx)
f010057a:	ba fb 03 00 00       	mov    $0x3fb,%edx
f010057f:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100584:	ee                   	out    %al,(%dx)
f0100585:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f010058a:	b8 0c 00 00 00       	mov    $0xc,%eax
f010058f:	89 da                	mov    %ebx,%edx
f0100591:	ee                   	out    %al,(%dx)
f0100592:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100597:	b8 00 00 00 00       	mov    $0x0,%eax
f010059c:	ee                   	out    %al,(%dx)
f010059d:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005a2:	b8 03 00 00 00       	mov    $0x3,%eax
f01005a7:	ee                   	out    %al,(%dx)
f01005a8:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005ad:	b8 00 00 00 00       	mov    $0x0,%eax
f01005b2:	ee                   	out    %al,(%dx)
f01005b3:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005b8:	b8 01 00 00 00       	mov    $0x1,%eax
f01005bd:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005be:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01005c3:	ec                   	in     (%dx),%al
f01005c4:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005c6:	3c ff                	cmp    $0xff,%al
f01005c8:	0f 95 05 34 65 11 f0 	setne  0xf0116534
f01005cf:	89 f2                	mov    %esi,%edx
f01005d1:	ec                   	in     (%dx),%al
f01005d2:	89 da                	mov    %ebx,%edx
f01005d4:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005d5:	80 f9 ff             	cmp    $0xff,%cl
f01005d8:	75 10                	jne    f01005ea <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f01005da:	83 ec 0c             	sub    $0xc,%esp
f01005dd:	68 d9 36 10 f0       	push   $0xf01036d9
f01005e2:	e8 94 21 00 00       	call   f010277b <cprintf>
f01005e7:	83 c4 10             	add    $0x10,%esp
}
f01005ea:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01005ed:	5b                   	pop    %ebx
f01005ee:	5e                   	pop    %esi
f01005ef:	5f                   	pop    %edi
f01005f0:	5d                   	pop    %ebp
f01005f1:	c3                   	ret    

f01005f2 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01005f2:	55                   	push   %ebp
f01005f3:	89 e5                	mov    %esp,%ebp
f01005f5:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01005f8:	8b 45 08             	mov    0x8(%ebp),%eax
f01005fb:	e8 89 fc ff ff       	call   f0100289 <cons_putc>
}
f0100600:	c9                   	leave  
f0100601:	c3                   	ret    

f0100602 <getchar>:

int
getchar(void)
{
f0100602:	55                   	push   %ebp
f0100603:	89 e5                	mov    %esp,%ebp
f0100605:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100608:	e8 93 fe ff ff       	call   f01004a0 <cons_getc>
f010060d:	85 c0                	test   %eax,%eax
f010060f:	74 f7                	je     f0100608 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100611:	c9                   	leave  
f0100612:	c3                   	ret    

f0100613 <iscons>:

int
iscons(int fdnum)
{
f0100613:	55                   	push   %ebp
f0100614:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100616:	b8 01 00 00 00       	mov    $0x1,%eax
f010061b:	5d                   	pop    %ebp
f010061c:	c3                   	ret    

f010061d <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010061d:	55                   	push   %ebp
f010061e:	89 e5                	mov    %esp,%ebp
f0100620:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100623:	68 20 39 10 f0       	push   $0xf0103920
f0100628:	68 3e 39 10 f0       	push   $0xf010393e
f010062d:	68 43 39 10 f0       	push   $0xf0103943
f0100632:	e8 44 21 00 00       	call   f010277b <cprintf>
f0100637:	83 c4 0c             	add    $0xc,%esp
f010063a:	68 e0 39 10 f0       	push   $0xf01039e0
f010063f:	68 4c 39 10 f0       	push   $0xf010394c
f0100644:	68 43 39 10 f0       	push   $0xf0103943
f0100649:	e8 2d 21 00 00       	call   f010277b <cprintf>
	return 0;
}
f010064e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100653:	c9                   	leave  
f0100654:	c3                   	ret    

f0100655 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100655:	55                   	push   %ebp
f0100656:	89 e5                	mov    %esp,%ebp
f0100658:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f010065b:	68 55 39 10 f0       	push   $0xf0103955
f0100660:	e8 16 21 00 00       	call   f010277b <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100665:	83 c4 08             	add    $0x8,%esp
f0100668:	68 0c 00 10 00       	push   $0x10000c
f010066d:	68 08 3a 10 f0       	push   $0xf0103a08
f0100672:	e8 04 21 00 00       	call   f010277b <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100677:	83 c4 0c             	add    $0xc,%esp
f010067a:	68 0c 00 10 00       	push   $0x10000c
f010067f:	68 0c 00 10 f0       	push   $0xf010000c
f0100684:	68 30 3a 10 f0       	push   $0xf0103a30
f0100689:	e8 ed 20 00 00       	call   f010277b <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010068e:	83 c4 0c             	add    $0xc,%esp
f0100691:	68 71 36 10 00       	push   $0x103671
f0100696:	68 71 36 10 f0       	push   $0xf0103671
f010069b:	68 54 3a 10 f0       	push   $0xf0103a54
f01006a0:	e8 d6 20 00 00       	call   f010277b <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006a5:	83 c4 0c             	add    $0xc,%esp
f01006a8:	68 00 63 11 00       	push   $0x116300
f01006ad:	68 00 63 11 f0       	push   $0xf0116300
f01006b2:	68 78 3a 10 f0       	push   $0xf0103a78
f01006b7:	e8 bf 20 00 00       	call   f010277b <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006bc:	83 c4 0c             	add    $0xc,%esp
f01006bf:	68 70 69 11 00       	push   $0x116970
f01006c4:	68 70 69 11 f0       	push   $0xf0116970
f01006c9:	68 9c 3a 10 f0       	push   $0xf0103a9c
f01006ce:	e8 a8 20 00 00       	call   f010277b <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006d3:	b8 6f 6d 11 f0       	mov    $0xf0116d6f,%eax
f01006d8:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006dd:	83 c4 08             	add    $0x8,%esp
f01006e0:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f01006e5:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01006eb:	85 c0                	test   %eax,%eax
f01006ed:	0f 48 c2             	cmovs  %edx,%eax
f01006f0:	c1 f8 0a             	sar    $0xa,%eax
f01006f3:	50                   	push   %eax
f01006f4:	68 c0 3a 10 f0       	push   $0xf0103ac0
f01006f9:	e8 7d 20 00 00       	call   f010277b <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f01006fe:	b8 00 00 00 00       	mov    $0x0,%eax
f0100703:	c9                   	leave  
f0100704:	c3                   	ret    

f0100705 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100705:	55                   	push   %ebp
f0100706:	89 e5                	mov    %esp,%ebp
f0100708:	57                   	push   %edi
f0100709:	56                   	push   %esi
f010070a:	53                   	push   %ebx
f010070b:	83 ec 18             	sub    $0x18,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f010070e:	89 e8                	mov    %ebp,%eax
		// Your code here.
	uint32_t *ebp = (uint32_t*)read_ebp(); //定义指向当前ebp寄存器的指针,uint32_t因为寄存器存储的值为32位
f0100710:	89 c6                	mov    %eax,%esi
	uint32_t *eip = (uint32_t*)*(ebp + 1); //eip在ebp底下，储存返回地址
f0100712:	8b 58 04             	mov    0x4(%eax),%ebx
	cprintf("Stack backtrace:");
f0100715:	68 6e 39 10 f0       	push   $0xf010396e
f010071a:	e8 5c 20 00 00       	call   f010277b <cprintf>
	while(ebp != NULL){
f010071f:	83 c4 10             	add    $0x10,%esp
f0100722:	eb 52                	jmp    f0100776 <mon_backtrace+0x71>
		cprintf("ebp %08x  eip %08x", ebp, eip); //打印ebp、eip
f0100724:	83 ec 04             	sub    $0x4,%esp
f0100727:	53                   	push   %ebx
f0100728:	56                   	push   %esi
f0100729:	68 7f 39 10 f0       	push   $0xf010397f
f010072e:	e8 48 20 00 00       	call   f010277b <cprintf>
		cprintf("    arg ");
f0100733:	c7 04 24 92 39 10 f0 	movl   $0xf0103992,(%esp)
f010073a:	e8 3c 20 00 00       	call   f010277b <cprintf>
f010073f:	8d 5e 08             	lea    0x8(%esi),%ebx
f0100742:	8d 7e 1c             	lea    0x1c(%esi),%edi
f0100745:	83 c4 10             	add    $0x10,%esp
		for(int i = 0;i < 5;i++){
			cprintf("%08x ", *(ebp + i + 2));
f0100748:	83 ec 08             	sub    $0x8,%esp
f010074b:	ff 33                	pushl  (%ebx)
f010074d:	68 9b 39 10 f0       	push   $0xf010399b
f0100752:	e8 24 20 00 00       	call   f010277b <cprintf>
f0100757:	83 c3 04             	add    $0x4,%ebx
	uint32_t *eip = (uint32_t*)*(ebp + 1); //eip在ebp底下，储存返回地址
	cprintf("Stack backtrace:");
	while(ebp != NULL){
		cprintf("ebp %08x  eip %08x", ebp, eip); //打印ebp、eip
		cprintf("    arg ");
		for(int i = 0;i < 5;i++){
f010075a:	83 c4 10             	add    $0x10,%esp
f010075d:	39 fb                	cmp    %edi,%ebx
f010075f:	75 e7                	jne    f0100748 <mon_backtrace+0x43>
			cprintf("%08x ", *(ebp + i + 2));
		}
		cprintf("\n");
f0100761:	83 ec 0c             	sub    $0xc,%esp
f0100764:	68 33 3e 10 f0       	push   $0xf0103e33
f0100769:	e8 0d 20 00 00       	call   f010277b <cprintf>
		ebp = (uint32_t*)(*ebp); //被调用函数的ebp指向调用它函数ebp值存放的位置
f010076e:	8b 36                	mov    (%esi),%esi
		eip = (uint32_t*)*(ebp + 1); //eip在ebp底下，储存返回地址
f0100770:	8b 5e 04             	mov    0x4(%esi),%ebx
f0100773:	83 c4 10             	add    $0x10,%esp
{
		// Your code here.
	uint32_t *ebp = (uint32_t*)read_ebp(); //定义指向当前ebp寄存器的指针,uint32_t因为寄存器存储的值为32位
	uint32_t *eip = (uint32_t*)*(ebp + 1); //eip在ebp底下，储存返回地址
	cprintf("Stack backtrace:");
	while(ebp != NULL){
f0100776:	85 f6                	test   %esi,%esi
f0100778:	75 aa                	jne    f0100724 <mon_backtrace+0x1f>
		cprintf("\n");
		ebp = (uint32_t*)(*ebp); //被调用函数的ebp指向调用它函数ebp值存放的位置
		eip = (uint32_t*)*(ebp + 1); //eip在ebp底下，储存返回地址
	}
	return 0;
}
f010077a:	b8 00 00 00 00       	mov    $0x0,%eax
f010077f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100782:	5b                   	pop    %ebx
f0100783:	5e                   	pop    %esi
f0100784:	5f                   	pop    %edi
f0100785:	5d                   	pop    %ebp
f0100786:	c3                   	ret    

f0100787 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100787:	55                   	push   %ebp
f0100788:	89 e5                	mov    %esp,%ebp
f010078a:	57                   	push   %edi
f010078b:	56                   	push   %esi
f010078c:	53                   	push   %ebx
f010078d:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100790:	68 ec 3a 10 f0       	push   $0xf0103aec
f0100795:	e8 e1 1f 00 00       	call   f010277b <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010079a:	c7 04 24 10 3b 10 f0 	movl   $0xf0103b10,(%esp)
f01007a1:	e8 d5 1f 00 00       	call   f010277b <cprintf>
f01007a6:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01007a9:	83 ec 0c             	sub    $0xc,%esp
f01007ac:	68 a1 39 10 f0       	push   $0xf01039a1
f01007b1:	e8 d8 27 00 00       	call   f0102f8e <readline>
f01007b6:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007b8:	83 c4 10             	add    $0x10,%esp
f01007bb:	85 c0                	test   %eax,%eax
f01007bd:	74 ea                	je     f01007a9 <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01007bf:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01007c6:	be 00 00 00 00       	mov    $0x0,%esi
f01007cb:	eb 0a                	jmp    f01007d7 <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01007cd:	c6 03 00             	movb   $0x0,(%ebx)
f01007d0:	89 f7                	mov    %esi,%edi
f01007d2:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01007d5:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01007d7:	0f b6 03             	movzbl (%ebx),%eax
f01007da:	84 c0                	test   %al,%al
f01007dc:	74 63                	je     f0100841 <monitor+0xba>
f01007de:	83 ec 08             	sub    $0x8,%esp
f01007e1:	0f be c0             	movsbl %al,%eax
f01007e4:	50                   	push   %eax
f01007e5:	68 a5 39 10 f0       	push   $0xf01039a5
f01007ea:	e8 b9 29 00 00       	call   f01031a8 <strchr>
f01007ef:	83 c4 10             	add    $0x10,%esp
f01007f2:	85 c0                	test   %eax,%eax
f01007f4:	75 d7                	jne    f01007cd <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f01007f6:	80 3b 00             	cmpb   $0x0,(%ebx)
f01007f9:	74 46                	je     f0100841 <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01007fb:	83 fe 0f             	cmp    $0xf,%esi
f01007fe:	75 14                	jne    f0100814 <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100800:	83 ec 08             	sub    $0x8,%esp
f0100803:	6a 10                	push   $0x10
f0100805:	68 aa 39 10 f0       	push   $0xf01039aa
f010080a:	e8 6c 1f 00 00       	call   f010277b <cprintf>
f010080f:	83 c4 10             	add    $0x10,%esp
f0100812:	eb 95                	jmp    f01007a9 <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f0100814:	8d 7e 01             	lea    0x1(%esi),%edi
f0100817:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f010081b:	eb 03                	jmp    f0100820 <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f010081d:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100820:	0f b6 03             	movzbl (%ebx),%eax
f0100823:	84 c0                	test   %al,%al
f0100825:	74 ae                	je     f01007d5 <monitor+0x4e>
f0100827:	83 ec 08             	sub    $0x8,%esp
f010082a:	0f be c0             	movsbl %al,%eax
f010082d:	50                   	push   %eax
f010082e:	68 a5 39 10 f0       	push   $0xf01039a5
f0100833:	e8 70 29 00 00       	call   f01031a8 <strchr>
f0100838:	83 c4 10             	add    $0x10,%esp
f010083b:	85 c0                	test   %eax,%eax
f010083d:	74 de                	je     f010081d <monitor+0x96>
f010083f:	eb 94                	jmp    f01007d5 <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f0100841:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100848:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100849:	85 f6                	test   %esi,%esi
f010084b:	0f 84 58 ff ff ff    	je     f01007a9 <monitor+0x22>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100851:	83 ec 08             	sub    $0x8,%esp
f0100854:	68 3e 39 10 f0       	push   $0xf010393e
f0100859:	ff 75 a8             	pushl  -0x58(%ebp)
f010085c:	e8 e9 28 00 00       	call   f010314a <strcmp>
f0100861:	83 c4 10             	add    $0x10,%esp
f0100864:	85 c0                	test   %eax,%eax
f0100866:	74 1e                	je     f0100886 <monitor+0xff>
f0100868:	83 ec 08             	sub    $0x8,%esp
f010086b:	68 4c 39 10 f0       	push   $0xf010394c
f0100870:	ff 75 a8             	pushl  -0x58(%ebp)
f0100873:	e8 d2 28 00 00       	call   f010314a <strcmp>
f0100878:	83 c4 10             	add    $0x10,%esp
f010087b:	85 c0                	test   %eax,%eax
f010087d:	75 2f                	jne    f01008ae <monitor+0x127>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f010087f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100884:	eb 05                	jmp    f010088b <monitor+0x104>
		if (strcmp(argv[0], commands[i].name) == 0)
f0100886:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f010088b:	83 ec 04             	sub    $0x4,%esp
f010088e:	8d 14 00             	lea    (%eax,%eax,1),%edx
f0100891:	01 d0                	add    %edx,%eax
f0100893:	ff 75 08             	pushl  0x8(%ebp)
f0100896:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100899:	51                   	push   %ecx
f010089a:	56                   	push   %esi
f010089b:	ff 14 85 40 3b 10 f0 	call   *-0xfefc4c0(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008a2:	83 c4 10             	add    $0x10,%esp
f01008a5:	85 c0                	test   %eax,%eax
f01008a7:	78 1d                	js     f01008c6 <monitor+0x13f>
f01008a9:	e9 fb fe ff ff       	jmp    f01007a9 <monitor+0x22>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008ae:	83 ec 08             	sub    $0x8,%esp
f01008b1:	ff 75 a8             	pushl  -0x58(%ebp)
f01008b4:	68 c7 39 10 f0       	push   $0xf01039c7
f01008b9:	e8 bd 1e 00 00       	call   f010277b <cprintf>
f01008be:	83 c4 10             	add    $0x10,%esp
f01008c1:	e9 e3 fe ff ff       	jmp    f01007a9 <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008c6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008c9:	5b                   	pop    %ebx
f01008ca:	5e                   	pop    %esi
f01008cb:	5f                   	pop    %edi
f01008cc:	5d                   	pop    %ebp
f01008cd:	c3                   	ret    

f01008ce <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
<<<<<<< HEAD
	if (!nextfree) {//让nextfree指向一个空闲页地址
=======
	if (!nextfree) {
>>>>>>> lab2
f01008ce:	83 3d 38 65 11 f0 00 	cmpl   $0x0,0xf0116538
f01008d5:	75 5f                	jne    f0100936 <boot_alloc+0x68>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f01008d7:	ba 6f 79 11 f0       	mov    $0xf011796f,%edx
f01008dc:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01008e2:	89 15 38 65 11 f0    	mov    %edx,0xf0116538
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if (n > 0) {
f01008e8:	85 c0                	test   %eax,%eax
f01008ea:	74 44                	je     f0100930 <boot_alloc+0x62>
		if ((uint32_t)nextfree > KERNBASE + (npages * PGSIZE)) {
f01008ec:	8b 15 38 65 11 f0    	mov    0xf0116538,%edx
f01008f2:	8b 0d 64 69 11 f0    	mov    0xf0116964,%ecx
f01008f8:	81 c1 00 00 0f 00    	add    $0xf0000,%ecx
f01008fe:	c1 e1 0c             	shl    $0xc,%ecx
f0100901:	39 ca                	cmp    %ecx,%edx
f0100903:	76 17                	jbe    f010091c <boot_alloc+0x4e>
<<<<<<< HEAD


//分配足够容纳n字节的内存，返回虚拟地址
=======
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
>>>>>>> lab2
static void *
boot_alloc(uint32_t n)
{
f0100905:	55                   	push   %ebp
f0100906:	89 e5                	mov    %esp,%ebp
f0100908:	83 ec 0c             	sub    $0xc,%esp
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if (n > 0) {
		if ((uint32_t)nextfree > KERNBASE + (npages * PGSIZE)) {
<<<<<<< HEAD
			panic("out of memory"); //如果下一个空闲地址超过了内核允许分配的内存边界那么报错
f010090b:	68 50 3b 10 f0       	push   $0xf0103b50
f0100910:	6a 6a                	push   $0x6a
f0100912:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0100917:	e8 6f f7 ff ff       	call   f010008b <_panic>
		} else { //否则将当前nextfree指向的空闲内存的开始地址返回给result             
			result = nextfree; //并将nextfree的指针后移n，留出n个字节的空间
=======
			panic("out of memory"); // If we're out of memory, boot_alloc should panic.
f010090b:	68 50 3b 10 f0       	push   $0xf0103b50
f0100910:	6a 67                	push   $0x67
f0100912:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0100917:	e8 6f f7 ff ff       	call   f010008b <_panic>
		} else {               // If n>0, allocates enough pages of contiguous physical memory to hold 'n'
			result = nextfree; // bytes.  Doesn't initialize the memory.  Returns a kernel virtual address.
>>>>>>> lab2
			nextfree = ROUNDUP(nextfree + n, PGSIZE);
f010091c:	8d 84 02 ff 0f 00 00 	lea    0xfff(%edx,%eax,1),%eax
f0100923:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100928:	a3 38 65 11 f0       	mov    %eax,0xf0116538
			return result;
f010092d:	89 d0                	mov    %edx,%eax
f010092f:	c3                   	ret    
		}
	}
	if (n == 0) {  
<<<<<<< HEAD
		return nextfree;//如果n为0，按照要求直接返回nextfree，不做分配
=======
		return nextfree;// If n==0, returns the address of the next free page without allocating anything.
>>>>>>> lab2
f0100930:	a1 38 65 11 f0       	mov    0xf0116538,%eax
f0100935:	c3                   	ret    
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if (n > 0) {
f0100936:	85 c0                	test   %eax,%eax
f0100938:	75 b2                	jne    f01008ec <boot_alloc+0x1e>
f010093a:	eb f4                	jmp    f0100930 <boot_alloc+0x62>

f010093c <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f010093c:	89 d1                	mov    %edx,%ecx
f010093e:	c1 e9 16             	shr    $0x16,%ecx
f0100941:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100944:	a8 01                	test   $0x1,%al
f0100946:	74 52                	je     f010099a <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100948:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010094d:	89 c1                	mov    %eax,%ecx
f010094f:	c1 e9 0c             	shr    $0xc,%ecx
f0100952:	3b 0d 64 69 11 f0    	cmp    0xf0116964,%ecx
f0100958:	72 1b                	jb     f0100975 <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f010095a:	55                   	push   %ebp
f010095b:	89 e5                	mov    %esp,%ebp
f010095d:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100960:	50                   	push   %eax
f0100961:	68 68 3e 10 f0       	push   $0xf0103e68
<<<<<<< HEAD
f0100966:	68 04 03 00 00       	push   $0x304
=======
f0100966:	68 e5 02 00 00       	push   $0x2e5
>>>>>>> lab2
f010096b:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0100970:	e8 16 f7 ff ff       	call   f010008b <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100975:	c1 ea 0c             	shr    $0xc,%edx
f0100978:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f010097e:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100985:	89 c2                	mov    %eax,%edx
f0100987:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f010098a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010098f:	85 d2                	test   %edx,%edx
f0100991:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100996:	0f 44 c2             	cmove  %edx,%eax
f0100999:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f010099a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f010099f:	c3                   	ret    

f01009a0 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f01009a0:	55                   	push   %ebp
f01009a1:	89 e5                	mov    %esp,%ebp
f01009a3:	57                   	push   %edi
f01009a4:	56                   	push   %esi
f01009a5:	53                   	push   %ebx
f01009a6:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01009a9:	84 c0                	test   %al,%al
f01009ab:	0f 85 72 02 00 00    	jne    f0100c23 <check_page_free_list+0x283>
f01009b1:	e9 7f 02 00 00       	jmp    f0100c35 <check_page_free_list+0x295>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f01009b6:	83 ec 04             	sub    $0x4,%esp
f01009b9:	68 8c 3e 10 f0       	push   $0xf0103e8c
<<<<<<< HEAD
f01009be:	68 47 02 00 00       	push   $0x247
=======
f01009be:	68 28 02 00 00       	push   $0x228
>>>>>>> lab2
f01009c3:	68 5e 3b 10 f0       	push   $0xf0103b5e
f01009c8:	e8 be f6 ff ff       	call   f010008b <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f01009cd:	8d 55 d8             	lea    -0x28(%ebp),%edx
f01009d0:	89 55 e0             	mov    %edx,-0x20(%ebp)
f01009d3:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01009d6:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f01009d9:	89 c2                	mov    %eax,%edx
f01009db:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f01009e1:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f01009e7:	0f 95 c2             	setne  %dl
f01009ea:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f01009ed:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f01009f1:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f01009f3:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f01009f7:	8b 00                	mov    (%eax),%eax
f01009f9:	85 c0                	test   %eax,%eax
f01009fb:	75 dc                	jne    f01009d9 <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f01009fd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a00:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100a06:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a09:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100a0c:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100a0e:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100a11:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a16:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a1b:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
f0100a21:	eb 53                	jmp    f0100a76 <check_page_free_list+0xd6>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a23:	89 d8                	mov    %ebx,%eax
f0100a25:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0100a2b:	c1 f8 03             	sar    $0x3,%eax
f0100a2e:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100a31:	89 c2                	mov    %eax,%edx
f0100a33:	c1 ea 16             	shr    $0x16,%edx
f0100a36:	39 f2                	cmp    %esi,%edx
f0100a38:	73 3a                	jae    f0100a74 <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a3a:	89 c2                	mov    %eax,%edx
f0100a3c:	c1 ea 0c             	shr    $0xc,%edx
f0100a3f:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0100a45:	72 12                	jb     f0100a59 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a47:	50                   	push   %eax
f0100a48:	68 68 3e 10 f0       	push   $0xf0103e68
f0100a4d:	6a 52                	push   $0x52
f0100a4f:	68 6a 3b 10 f0       	push   $0xf0103b6a
f0100a54:	e8 32 f6 ff ff       	call   f010008b <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100a59:	83 ec 04             	sub    $0x4,%esp
f0100a5c:	68 80 00 00 00       	push   $0x80
f0100a61:	68 97 00 00 00       	push   $0x97
f0100a66:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100a6b:	50                   	push   %eax
f0100a6c:	e8 74 27 00 00       	call   f01031e5 <memset>
f0100a71:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a74:	8b 1b                	mov    (%ebx),%ebx
f0100a76:	85 db                	test   %ebx,%ebx
f0100a78:	75 a9                	jne    f0100a23 <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100a7a:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a7f:	e8 4a fe ff ff       	call   f01008ce <boot_alloc>
f0100a84:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a87:	8b 15 3c 65 11 f0    	mov    0xf011653c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100a8d:	8b 0d 6c 69 11 f0    	mov    0xf011696c,%ecx
		assert(pp < pages + npages);
f0100a93:	a1 64 69 11 f0       	mov    0xf0116964,%eax
f0100a98:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100a9b:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100a9e:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100aa1:	be 00 00 00 00       	mov    $0x0,%esi
f0100aa6:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100aa9:	e9 30 01 00 00       	jmp    f0100bde <check_page_free_list+0x23e>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100aae:	39 ca                	cmp    %ecx,%edx
f0100ab0:	73 19                	jae    f0100acb <check_page_free_list+0x12b>
f0100ab2:	68 78 3b 10 f0       	push   $0xf0103b78
f0100ab7:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0100abc:	68 61 02 00 00       	push   $0x261
=======
f0100abc:	68 42 02 00 00       	push   $0x242
>>>>>>> lab2
f0100ac1:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0100ac6:	e8 c0 f5 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100acb:	39 fa                	cmp    %edi,%edx
f0100acd:	72 19                	jb     f0100ae8 <check_page_free_list+0x148>
f0100acf:	68 99 3b 10 f0       	push   $0xf0103b99
f0100ad4:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0100ad9:	68 62 02 00 00       	push   $0x262
=======
f0100ad9:	68 43 02 00 00       	push   $0x243
>>>>>>> lab2
f0100ade:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0100ae3:	e8 a3 f5 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100ae8:	89 d0                	mov    %edx,%eax
f0100aea:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100aed:	a8 07                	test   $0x7,%al
f0100aef:	74 19                	je     f0100b0a <check_page_free_list+0x16a>
f0100af1:	68 b0 3e 10 f0       	push   $0xf0103eb0
f0100af6:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0100afb:	68 63 02 00 00       	push   $0x263
=======
f0100afb:	68 44 02 00 00       	push   $0x244
>>>>>>> lab2
f0100b00:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0100b05:	e8 81 f5 ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b0a:	c1 f8 03             	sar    $0x3,%eax
f0100b0d:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100b10:	85 c0                	test   %eax,%eax
f0100b12:	75 19                	jne    f0100b2d <check_page_free_list+0x18d>
f0100b14:	68 ad 3b 10 f0       	push   $0xf0103bad
f0100b19:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0100b1e:	68 66 02 00 00       	push   $0x266
=======
f0100b1e:	68 47 02 00 00       	push   $0x247
>>>>>>> lab2
f0100b23:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0100b28:	e8 5e f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b2d:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b32:	75 19                	jne    f0100b4d <check_page_free_list+0x1ad>
f0100b34:	68 be 3b 10 f0       	push   $0xf0103bbe
f0100b39:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0100b3e:	68 67 02 00 00       	push   $0x267
=======
f0100b3e:	68 48 02 00 00       	push   $0x248
>>>>>>> lab2
f0100b43:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0100b48:	e8 3e f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100b4d:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100b52:	75 19                	jne    f0100b6d <check_page_free_list+0x1cd>
f0100b54:	68 e4 3e 10 f0       	push   $0xf0103ee4
f0100b59:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0100b5e:	68 68 02 00 00       	push   $0x268
=======
f0100b5e:	68 49 02 00 00       	push   $0x249
>>>>>>> lab2
f0100b63:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0100b68:	e8 1e f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100b6d:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100b72:	75 19                	jne    f0100b8d <check_page_free_list+0x1ed>
f0100b74:	68 d7 3b 10 f0       	push   $0xf0103bd7
f0100b79:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0100b7e:	68 69 02 00 00       	push   $0x269
=======
f0100b7e:	68 4a 02 00 00       	push   $0x24a
>>>>>>> lab2
f0100b83:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0100b88:	e8 fe f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100b8d:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100b92:	76 3f                	jbe    f0100bd3 <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b94:	89 c3                	mov    %eax,%ebx
f0100b96:	c1 eb 0c             	shr    $0xc,%ebx
f0100b99:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100b9c:	77 12                	ja     f0100bb0 <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b9e:	50                   	push   %eax
f0100b9f:	68 68 3e 10 f0       	push   $0xf0103e68
f0100ba4:	6a 52                	push   $0x52
f0100ba6:	68 6a 3b 10 f0       	push   $0xf0103b6a
f0100bab:	e8 db f4 ff ff       	call   f010008b <_panic>
f0100bb0:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100bb5:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100bb8:	76 1e                	jbe    f0100bd8 <check_page_free_list+0x238>
f0100bba:	68 08 3f 10 f0       	push   $0xf0103f08
f0100bbf:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0100bc4:	68 6a 02 00 00       	push   $0x26a
=======
f0100bc4:	68 4b 02 00 00       	push   $0x24b
>>>>>>> lab2
f0100bc9:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0100bce:	e8 b8 f4 ff ff       	call   f010008b <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100bd3:	83 c6 01             	add    $0x1,%esi
f0100bd6:	eb 04                	jmp    f0100bdc <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f0100bd8:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100bdc:	8b 12                	mov    (%edx),%edx
f0100bde:	85 d2                	test   %edx,%edx
f0100be0:	0f 85 c8 fe ff ff    	jne    f0100aae <check_page_free_list+0x10e>
f0100be6:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100be9:	85 f6                	test   %esi,%esi
f0100beb:	7f 19                	jg     f0100c06 <check_page_free_list+0x266>
f0100bed:	68 f1 3b 10 f0       	push   $0xf0103bf1
f0100bf2:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0100bf7:	68 72 02 00 00       	push   $0x272
=======
f0100bf7:	68 53 02 00 00       	push   $0x253
>>>>>>> lab2
f0100bfc:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0100c01:	e8 85 f4 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0100c06:	85 db                	test   %ebx,%ebx
f0100c08:	7f 42                	jg     f0100c4c <check_page_free_list+0x2ac>
f0100c0a:	68 03 3c 10 f0       	push   $0xf0103c03
f0100c0f:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0100c14:	68 73 02 00 00       	push   $0x273
=======
f0100c14:	68 54 02 00 00       	push   $0x254
>>>>>>> lab2
f0100c19:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0100c1e:	e8 68 f4 ff ff       	call   f010008b <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100c23:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0100c28:	85 c0                	test   %eax,%eax
f0100c2a:	0f 85 9d fd ff ff    	jne    f01009cd <check_page_free_list+0x2d>
f0100c30:	e9 81 fd ff ff       	jmp    f01009b6 <check_page_free_list+0x16>
f0100c35:	83 3d 3c 65 11 f0 00 	cmpl   $0x0,0xf011653c
f0100c3c:	0f 84 74 fd ff ff    	je     f01009b6 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c42:	be 00 04 00 00       	mov    $0x400,%esi
f0100c47:	e9 cf fd ff ff       	jmp    f0100a1b <check_page_free_list+0x7b>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100c4c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c4f:	5b                   	pop    %ebx
f0100c50:	5e                   	pop    %esi
f0100c51:	5f                   	pop    %edi
f0100c52:	5d                   	pop    %ebp
f0100c53:	c3                   	ret    

f0100c54 <page_init>:
<<<<<<< HEAD
// memory via the page_free_list.
//

void //初始化页结构，将所有的页表项PageInfo与4K大小的页映射。
=======
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
>>>>>>> lab2
page_init(void)
{
f0100c54:	55                   	push   %ebp
f0100c55:	89 e5                	mov    %esp,%ebp
f0100c57:	57                   	push   %edi
f0100c58:	56                   	push   %esi
f0100c59:	53                   	push   %ebx
f0100c5a:	83 ec 1c             	sub    $0x1c,%esp
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	uint32_t nextfree = (uint32_t)boot_alloc(0);//returns the address of the next free page
f0100c5d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c62:	e8 67 fc ff ff       	call   f01008ce <boot_alloc>
	for (i = 0; i < npages; i++) {
<<<<<<< HEAD
		if(i == 0) { //首先将物理页0设置为正在使用
=======
		if(i == 0) {
>>>>>>> lab2
			pages[i].pp_ref = 1; //page 0 in use
			pages[i].pp_link = NULL;
		} else if(i < npages_basemem) {//0x00000~0xA0000
f0100c67:	8b 35 40 65 11 f0    	mov    0xf0116540,%esi
f0100c6d:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
<<<<<<< HEAD
            page_free_list = &pages[i];//page_free_list指向当前页的地址
		} else if(i >= IOPHYSMEM/PGSIZE && i < EXTPHYSMEM/PGSIZE) { //0xA0000~0x100000
		//Then comes the IO hole [IOPHYSMEM, EXTPHYSMEM), which must never be allocated.
	    //用于IO的物理内存是不能被分配的，设置为在用
=======
            page_free_list = &pages[i];
		} else if(i >= IOPHYSMEM/PGSIZE && i < EXTPHYSMEM/PGSIZE) { //0xA0000~0x100000
		//  3) Then comes the IO hole [IOPHYSMEM, EXTPHYSMEM), which must
	    //     never be allocated.
>>>>>>> lab2
			pages[i].pp_ref = 1; 
		} else  if (i >= IOPHYSMEM / PGSIZE && i < (nextfree - KERNBASE)/ PGSIZE) { //0xF0000000
f0100c73:	05 00 00 00 10       	add    $0x10000000,%eax
f0100c78:	c1 e8 0c             	shr    $0xc,%eax
f0100c7b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	uint32_t nextfree = (uint32_t)boot_alloc(0);//returns the address of the next free page
	for (i = 0; i < npages; i++) {
f0100c7e:	ba 00 00 00 00       	mov    $0x0,%edx
f0100c83:	bf 00 00 00 00       	mov    $0x0,%edi
f0100c88:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c8d:	e9 9a 00 00 00       	jmp    f0100d2c <page_init+0xd8>
<<<<<<< HEAD
		if(i == 0) { //首先将物理页0设置为正在使用
=======
		if(i == 0) {
>>>>>>> lab2
f0100c92:	85 c0                	test   %eax,%eax
f0100c94:	75 14                	jne    f0100caa <page_init+0x56>
			pages[i].pp_ref = 1; //page 0 in use
f0100c96:	8b 0d 6c 69 11 f0    	mov    0xf011696c,%ecx
f0100c9c:	66 c7 41 04 01 00    	movw   $0x1,0x4(%ecx)
			pages[i].pp_link = NULL;
f0100ca2:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
f0100ca8:	eb 7c                	jmp    f0100d26 <page_init+0xd2>
		} else if(i < npages_basemem) {//0x00000~0xA0000
f0100caa:	39 f0                	cmp    %esi,%eax
f0100cac:	73 1f                	jae    f0100ccd <page_init+0x79>
<<<<<<< HEAD
			//The rest of base memory, [PGSIZE, npages_basemem * PGSIZE)is free.
	        //从第一页到第npage页是可以使用的     
			pages[i].pp_ref = 0; //将此页设置为可用
f0100cae:	89 d1                	mov    %edx,%ecx
f0100cb0:	03 0d 6c 69 11 f0    	add    0xf011696c,%ecx
f0100cb6:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
            pages[i].pp_link = page_free_list;//将此页与当前page_free_list指向的空闲页映射
f0100cbc:	89 19                	mov    %ebx,(%ecx)
            page_free_list = &pages[i];//page_free_list指向当前页的地址
=======
			//  2) The rest of base memory, [PGSIZE, npages_basemem * PGSIZE)
	        //     is free.
			pages[i].pp_ref = 0;
f0100cae:	89 d1                	mov    %edx,%ecx
f0100cb0:	03 0d 6c 69 11 f0    	add    0xf011696c,%ecx
f0100cb6:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
            pages[i].pp_link = page_free_list;
f0100cbc:	89 19                	mov    %ebx,(%ecx)
            page_free_list = &pages[i];
>>>>>>> lab2
f0100cbe:	89 d3                	mov    %edx,%ebx
f0100cc0:	03 1d 6c 69 11 f0    	add    0xf011696c,%ebx
f0100cc6:	bf 01 00 00 00       	mov    $0x1,%edi
f0100ccb:	eb 59                	jmp    f0100d26 <page_init+0xd2>
		} else if(i >= IOPHYSMEM/PGSIZE && i < EXTPHYSMEM/PGSIZE) { //0xA0000~0x100000
f0100ccd:	8d 88 60 ff ff ff    	lea    -0xa0(%eax),%ecx
f0100cd3:	83 f9 5f             	cmp    $0x5f,%ecx
f0100cd6:	77 0f                	ja     f0100ce7 <page_init+0x93>
<<<<<<< HEAD
		//Then comes the IO hole [IOPHYSMEM, EXTPHYSMEM), which must never be allocated.
	    //用于IO的物理内存是不能被分配的，设置为在用
=======
		//  3) Then comes the IO hole [IOPHYSMEM, EXTPHYSMEM), which must
	    //     never be allocated.
>>>>>>> lab2
			pages[i].pp_ref = 1; 
f0100cd8:	8b 0d 6c 69 11 f0    	mov    0xf011696c,%ecx
f0100cde:	66 c7 44 11 04 01 00 	movw   $0x1,0x4(%ecx,%edx,1)
f0100ce5:	eb 3f                	jmp    f0100d26 <page_init+0xd2>
		} else  if (i >= IOPHYSMEM / PGSIZE && i < (nextfree - KERNBASE)/ PGSIZE) { //0xF0000000
f0100ce7:	3d 9f 00 00 00       	cmp    $0x9f,%eax
f0100cec:	76 1b                	jbe    f0100d09 <page_init+0xb5>
f0100cee:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
f0100cf1:	73 16                	jae    f0100d09 <page_init+0xb5>
<<<<<<< HEAD
		//从IOPHYSMEM开始有一部分内存是被使用的，用于保存kernel，这一部分不能被分配
		//直到nextfree开头
=======
>>>>>>> lab2
            pages[i].pp_ref = 1;
f0100cf3:	89 d1                	mov    %edx,%ecx
f0100cf5:	03 0d 6c 69 11 f0    	add    0xf011696c,%ecx
f0100cfb:	66 c7 41 04 01 00    	movw   $0x1,0x4(%ecx)
            pages[i].pp_link = NULL;
f0100d01:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
f0100d07:	eb 1d                	jmp    f0100d26 <page_init+0xd2>
        } else {
<<<<<<< HEAD
		//其余的部分可以被分配
=======
>>>>>>> lab2
			pages[i].pp_ref = 0;
f0100d09:	89 d1                	mov    %edx,%ecx
f0100d0b:	03 0d 6c 69 11 f0    	add    0xf011696c,%ecx
f0100d11:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
            pages[i].pp_link = page_free_list;
f0100d17:	89 19                	mov    %ebx,(%ecx)
            page_free_list = &pages[i];
f0100d19:	89 d3                	mov    %edx,%ebx
f0100d1b:	03 1d 6c 69 11 f0    	add    0xf011696c,%ebx
f0100d21:	bf 01 00 00 00       	mov    $0x1,%edi
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	uint32_t nextfree = (uint32_t)boot_alloc(0);//returns the address of the next free page
	for (i = 0; i < npages; i++) {
f0100d26:	83 c0 01             	add    $0x1,%eax
f0100d29:	83 c2 08             	add    $0x8,%edx
f0100d2c:	3b 05 64 69 11 f0    	cmp    0xf0116964,%eax
f0100d32:	0f 82 5a ff ff ff    	jb     f0100c92 <page_init+0x3e>
f0100d38:	89 f8                	mov    %edi,%eax
f0100d3a:	84 c0                	test   %al,%al
f0100d3c:	74 06                	je     f0100d44 <page_init+0xf0>
f0100d3e:	89 1d 3c 65 11 f0    	mov    %ebx,0xf011653c
			pages[i].pp_ref = 0;
            pages[i].pp_link = page_free_list;
            page_free_list = &pages[i];
		}
	}
}
f0100d44:	83 c4 1c             	add    $0x1c,%esp
f0100d47:	5b                   	pop    %ebx
f0100d48:	5e                   	pop    %esi
f0100d49:	5f                   	pop    %edi
f0100d4a:	5d                   	pop    %ebp
f0100d4b:	c3                   	ret    

f0100d4c <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
<<<<<<< HEAD
struct PageInfo * //分配一个物理页，返回物理页的指针
=======
struct PageInfo *
>>>>>>> lab2
page_alloc(int alloc_flags)
{
f0100d4c:	55                   	push   %ebp
f0100d4d:	89 e5                	mov    %esp,%ebp
f0100d4f:	53                   	push   %ebx
f0100d50:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in
	struct PageInfo *NewPage;
<<<<<<< HEAD
	if(page_free_list == NULL) { //如果page_free_list没有空闲内存了
f0100d53:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
f0100d59:	85 db                	test   %ebx,%ebx
f0100d5b:	74 58                	je     f0100db5 <page_alloc+0x69>
		return NULL; //那么返回空
	}
	NewPage = page_free_list; //从page_free_list分配一个空闲的物理页
	page_free_list = page_free_list->pp_link; //将page_free_list指向下一张空闲的页
=======
	if(page_free_list == NULL) {
f0100d53:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
f0100d59:	85 db                	test   %ebx,%ebx
f0100d5b:	74 58                	je     f0100db5 <page_alloc+0x69>
		return NULL;
	}
	NewPage = page_free_list; //分配新的物理页
	page_free_list = page_free_list->pp_link;
>>>>>>> lab2
f0100d5d:	8b 03                	mov    (%ebx),%eax
f0100d5f:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
	NewPage->pp_link = NULL;
f0100d64:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
// Allocates a physical page.  If (alloc_flags & ALLOC_ZERO), fills the entire
// returned physical page with '\0' bytes.  Does NOT increment the reference
<<<<<<< HEAD
//分配一个物理页，如果alloc_flags和ALLOC_ZERO均为真，将这个物理页清为0
//不增加reference数
=======
>>>>>>> lab2
	if (alloc_flags & ALLOC_ZERO) {
f0100d6a:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100d6e:	74 45                	je     f0100db5 <page_alloc+0x69>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100d70:	89 d8                	mov    %ebx,%eax
f0100d72:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0100d78:	c1 f8 03             	sar    $0x3,%eax
f0100d7b:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d7e:	89 c2                	mov    %eax,%edx
f0100d80:	c1 ea 0c             	shr    $0xc,%edx
f0100d83:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0100d89:	72 12                	jb     f0100d9d <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d8b:	50                   	push   %eax
f0100d8c:	68 68 3e 10 f0       	push   $0xf0103e68
f0100d91:	6a 52                	push   $0x52
f0100d93:	68 6a 3b 10 f0       	push   $0xf0103b6a
f0100d98:	e8 ee f2 ff ff       	call   f010008b <_panic>
		memset(page2kva(NewPage), 0, PGSIZE);
f0100d9d:	83 ec 04             	sub    $0x4,%esp
f0100da0:	68 00 10 00 00       	push   $0x1000
f0100da5:	6a 00                	push   $0x0
f0100da7:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100dac:	50                   	push   %eax
f0100dad:	e8 33 24 00 00       	call   f01031e5 <memset>
f0100db2:	83 c4 10             	add    $0x10,%esp
	}
<<<<<<< HEAD
	//page2kva根据当前的struct PageInfo类型的指针得出相应的虚拟地址
	return NewPage; //返回分配的物理页
=======
	//page2kva是根据当前的struct PageInfo类型的指针得出相应的虚拟地址
	return NewPage;
>>>>>>> lab2
}
f0100db5:	89 d8                	mov    %ebx,%eax
f0100db7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100dba:	c9                   	leave  
f0100dbb:	c3                   	ret    

f0100dbc <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
<<<<<<< HEAD
void //释放一个页，让其返回到空闲页链表中
=======
void
>>>>>>> lab2
page_free(struct PageInfo *pp)
{
f0100dbc:	55                   	push   %ebp
f0100dbd:	89 e5                	mov    %esp,%ebp
f0100dbf:	83 ec 08             	sub    $0x8,%esp
f0100dc2:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
<<<<<<< HEAD
	//如果参数中指向的页reference数不为0或它还连接了一张物理页
	//那么释放失败，此函数只能在pp->ref为0时被调用
=======
>>>>>>> lab2
	assert(pp->pp_ref == 0); //if not, panic
f0100dc5:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100dca:	74 19                	je     f0100de5 <page_free+0x29>
f0100dcc:	68 14 3c 10 f0       	push   $0xf0103c14
f0100dd1:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0100dd6:	68 5c 01 00 00       	push   $0x15c
=======
f0100dd6:	68 4e 01 00 00       	push   $0x14e
>>>>>>> lab2
f0100ddb:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0100de0:	e8 a6 f2 ff ff       	call   f010008b <_panic>
	assert(pp->pp_link == NULL);//if not, panic
f0100de5:	83 38 00             	cmpl   $0x0,(%eax)
f0100de8:	74 19                	je     f0100e03 <page_free+0x47>
f0100dea:	68 24 3c 10 f0       	push   $0xf0103c24
f0100def:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0100df4:	68 5d 01 00 00       	push   $0x15d
f0100df9:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0100dfe:	e8 88 f2 ff ff       	call   f010008b <_panic>
	//将这个page的指针指向pagefreelist，把这张页还给page_free_list
=======
f0100df4:	68 4f 01 00 00       	push   $0x14f
f0100df9:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0100dfe:	e8 88 f2 ff ff       	call   f010008b <_panic>
>>>>>>> lab2
	pp->pp_link = page_free_list;// Return a page to the free list.
f0100e03:	8b 15 3c 65 11 f0    	mov    0xf011653c,%edx
f0100e09:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100e0b:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
}
f0100e10:	c9                   	leave  
f0100e11:	c3                   	ret    

f0100e12 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100e12:	55                   	push   %ebp
f0100e13:	89 e5                	mov    %esp,%ebp
f0100e15:	83 ec 08             	sub    $0x8,%esp
f0100e18:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100e1b:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100e1f:	83 e8 01             	sub    $0x1,%eax
f0100e22:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100e26:	66 85 c0             	test   %ax,%ax
f0100e29:	75 0c                	jne    f0100e37 <page_decref+0x25>
		page_free(pp);
f0100e2b:	83 ec 0c             	sub    $0xc,%esp
f0100e2e:	52                   	push   %edx
f0100e2f:	e8 88 ff ff ff       	call   f0100dbc <page_free>
f0100e34:	83 c4 10             	add    $0x10,%esp
}
f0100e37:	c9                   	leave  
f0100e38:	c3                   	ret    

f0100e39 <pgdir_walk>:
<<<<<<< HEAD
// table and page directory entries.
//
//pgdir是页目录，里面的每一个元素都指向一个页表物理地址
pte_t *
=======
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *  //pgdir是页目录，里面元素指向页表，该函数返回page table entry页表入口
>>>>>>> lab2
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100e39:	55                   	push   %ebp
f0100e3a:	89 e5                	mov    %esp,%ebp
f0100e3c:	56                   	push   %esi
f0100e3d:	53                   	push   %ebx
f0100e3e:	8b 45 0c             	mov    0xc(%ebp),%eax
<<<<<<< HEAD
	*确定页目录，然后根据中间10位的页表索引在对应的页目录里找到页表
	*对应的物理地址，最后物理地址加上偏移量便找到了虚拟地址对应的物理地址
	*pgdir_walk根据pgdir和虚拟地址va获得虚拟地址va所在的页表项的物理地址
	*/
	int pd_index = PDX(va); //PDX根据虚拟地址头10位找到页目录索引
    int pte_index = PTX(va);//PTX根据虚拟地址11-20位找到页表索引
f0100e41:	89 c6                	mov    %eax,%esi
f0100e43:	c1 ee 0c             	shr    $0xc,%esi
f0100e46:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
    if (pgdir[pd_index] & PTE_P) {  //如果页目录存在且具有操作权限
=======
	// Fill this function in
	int pd_index = PDX(va); //PDX根据虚拟地址找到页目录索引
    int pte_index = PTX(va);//PTX根据虚拟地址找到页表索引
f0100e41:	89 c6                	mov    %eax,%esi
f0100e43:	c1 ee 0c             	shr    $0xc,%esi
f0100e46:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
    if (pgdir[pd_index] & PTE_P) {  //if exist page
>>>>>>> lab2
f0100e4c:	c1 e8 16             	shr    $0x16,%eax
f0100e4f:	8d 1c 85 00 00 00 00 	lea    0x0(,%eax,4),%ebx
f0100e56:	03 5d 08             	add    0x8(%ebp),%ebx
f0100e59:	8b 03                	mov    (%ebx),%eax
f0100e5b:	a8 01                	test   $0x1,%al
f0100e5d:	74 30                	je     f0100e8f <pgdir_walk+0x56>
<<<<<<< HEAD
		//那么获得该页目录的物理地址，再转化为虚拟地址
		//PTE_ADDR得到页目录的物理地址，KADDR将物理地址转换为虚拟地址
=======
		//PTE_ADDR得到页表的物理地址，KADDR将物理地址转换为虚拟地址
>>>>>>> lab2
        pte_t *pt_addr_v = KADDR(PTE_ADDR(pgdir[pd_index]));
f0100e5f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e64:	89 c2                	mov    %eax,%edx
f0100e66:	c1 ea 0c             	shr    $0xc,%edx
f0100e69:	39 15 64 69 11 f0    	cmp    %edx,0xf0116964
f0100e6f:	77 15                	ja     f0100e86 <pgdir_walk+0x4d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e71:	50                   	push   %eax
f0100e72:	68 68 3e 10 f0       	push   $0xf0103e68
<<<<<<< HEAD
f0100e77:	68 94 01 00 00       	push   $0x194
f0100e7c:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0100e81:	e8 05 f2 ff ff       	call   f010008b <_panic>
		//根据页目录的虚拟地址，加上页表的索引偏移量就得到了va对应的页表项的物理地址
        return (pte_t*)(pt_addr_v + pte_index);
f0100e86:	8d 84 b0 00 00 00 f0 	lea    -0x10000000(%eax,%esi,4),%eax
f0100e8d:	eb 6b                	jmp    f0100efa <pgdir_walk+0xc1>
    } else {            //if not exist page
        if (create) {//如果不存在该页并允许新建
f0100e8f:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100e93:	74 59                	je     f0100eee <pgdir_walk+0xb5>
			struct PageInfo *NewPt = page_alloc(ALLOC_ZERO); //那么分配一张新页
=======
f0100e77:	68 7d 01 00 00       	push   $0x17d
f0100e7c:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0100e81:	e8 05 f2 ff ff       	call   f010008b <_panic>
        return (pte_t*)(pt_addr_v + pte_index); //PTX根据虚拟地址找到页表索引
f0100e86:	8d 84 b0 00 00 00 f0 	lea    -0x10000000(%eax,%esi,4),%eax
f0100e8d:	eb 6b                	jmp    f0100efa <pgdir_walk+0xc1>
    } else {            //if not exist page
        if (create) {
f0100e8f:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100e93:	74 59                	je     f0100eee <pgdir_walk+0xb5>
			struct PageInfo *NewPt = page_alloc(ALLOC_ZERO); //创建新页表
>>>>>>> lab2
f0100e95:	83 ec 0c             	sub    $0xc,%esp
f0100e98:	6a 01                	push   $0x1
f0100e9a:	e8 ad fe ff ff       	call   f0100d4c <page_alloc>
			if(NewPt == NULL)
f0100e9f:	83 c4 10             	add    $0x10,%esp
f0100ea2:	85 c0                	test   %eax,%eax
f0100ea4:	74 4f                	je     f0100ef5 <pgdir_walk+0xbc>
				return NULL;
            NewPt->pp_ref++;
f0100ea6:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100eab:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0100eb1:	c1 f8 03             	sar    $0x3,%eax
f0100eb4:	c1 e0 0c             	shl    $0xc,%eax
<<<<<<< HEAD
			//page2pa将一个页表指针转换为物理地址
			//将虚拟地址va的页目录基地址与新页表的物理地址关联并设置权限位
            pgdir[pd_index] = page2pa(NewPt)|PTE_U|PTE_W|PTE_P; 
=======
			//将页转换为物理地址并设定权限
            pgdir[pd_index] = page2pa(NewPt)|PTE_U|PTE_W|PTE_P; //
>>>>>>> lab2
f0100eb7:	89 c2                	mov    %eax,%edx
f0100eb9:	83 ca 07             	or     $0x7,%edx
f0100ebc:	89 13                	mov    %edx,(%ebx)
f0100ebe:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ec3:	89 c2                	mov    %eax,%edx
f0100ec5:	c1 ea 0c             	shr    $0xc,%edx
f0100ec8:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0100ece:	72 15                	jb     f0100ee5 <pgdir_walk+0xac>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ed0:	50                   	push   %eax
f0100ed1:	68 68 3e 10 f0       	push   $0xf0103e68
<<<<<<< HEAD
f0100ed6:	68 a1 01 00 00       	push   $0x1a1
f0100edb:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0100ee0:	e8 a6 f1 ff ff       	call   f010008b <_panic>
			//最后根据页目录的虚拟地址和页表索引找到va对应的页表项物理地址
=======
f0100ed6:	68 87 01 00 00       	push   $0x187
f0100edb:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0100ee0:	e8 a6 f1 ff ff       	call   f010008b <_panic>
>>>>>>> lab2
            pte_t *pt_addr_v = KADDR(PTE_ADDR(pgdir[pd_index]));
            return (pte_t*)(pt_addr_v + pte_index);
f0100ee5:	8d 84 b0 00 00 00 f0 	lea    -0x10000000(%eax,%esi,4),%eax
f0100eec:	eb 0c                	jmp    f0100efa <pgdir_walk+0xc1>
        } else return NULL;
f0100eee:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ef3:	eb 05                	jmp    f0100efa <pgdir_walk+0xc1>
<<<<<<< HEAD
        return (pte_t*)(pt_addr_v + pte_index);
    } else {            //if not exist page
        if (create) {//如果不存在该页并允许新建
			struct PageInfo *NewPt = page_alloc(ALLOC_ZERO); //那么分配一张新页
			if(NewPt == NULL)
				return NULL;
f0100ef5:	b8 00 00 00 00       	mov    $0x0,%eax
			//最后根据页目录的虚拟地址和页表索引找到va对应的页表项物理地址
=======
        return (pte_t*)(pt_addr_v + pte_index); //PTX根据虚拟地址找到页表索引
    } else {            //if not exist page
        if (create) {
			struct PageInfo *NewPt = page_alloc(ALLOC_ZERO); //创建新页表
			if(NewPt == NULL)
				return NULL;
f0100ef5:	b8 00 00 00 00       	mov    $0x0,%eax
            pgdir[pd_index] = page2pa(NewPt)|PTE_U|PTE_W|PTE_P; //
>>>>>>> lab2
            pte_t *pt_addr_v = KADDR(PTE_ADDR(pgdir[pd_index]));
            return (pte_t*)(pt_addr_v + pte_index);
        } else return NULL;
    }
}
f0100efa:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100efd:	5b                   	pop    %ebx
f0100efe:	5e                   	pop    %esi
f0100eff:	5d                   	pop    %ebp
f0100f00:	c3                   	ret    

f0100f01 <boot_map_region>:
<<<<<<< HEAD
//
// Hint: the TA solution uses pgdir_walk

=======
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
>>>>>>> lab2
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100f01:	55                   	push   %ebp
f0100f02:	89 e5                	mov    %esp,%ebp
f0100f04:	57                   	push   %edi
f0100f05:	56                   	push   %esi
f0100f06:	53                   	push   %ebx
f0100f07:	83 ec 1c             	sub    $0x1c,%esp
f0100f0a:	89 45 e0             	mov    %eax,-0x20(%ebp)
<<<<<<< HEAD
	//boot_map_region将虚拟地址[va, va+size)映射到物理地址[pa, pa+size)
	//函数参数依次为页目录，虚拟地址起始，映射的大小，物理地址起始，权限位
=======
	// 将虚拟地址[va, va+size)映射到物理地址[pa, pa+size)
>>>>>>> lab2
	// Fill this function in
    size = ROUNDUP(size, PGSIZE);
f0100f0d:	81 c1 ff 0f 00 00    	add    $0xfff,%ecx
    size_t page_num = PGNUM(size);
f0100f13:	c1 e9 0c             	shr    $0xc,%ecx
f0100f16:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
    for (size_t i = 0; i < page_num; i++) {
f0100f19:	89 d3                	mov    %edx,%ebx
f0100f1b:	be 00 00 00 00       	mov    $0x0,%esi
<<<<<<< HEAD
		//利用pgdir_walk函数找到虚拟地址对应的页表项物理地址
        pte_t *pgtable_entry_ptr = pgdir_walk(pgdir, (char *)(va + i * PGSIZE), true);
		//将找到的物理页表设置物理地址中的起始位置和权限
=======

        pte_t *pgtable_entry_ptr = pgdir_walk(pgdir, (char *)(va + i * PGSIZE), true);
>>>>>>> lab2
        *pgtable_entry_ptr = (pa + i * PGSIZE) | perm | PTE_P;
f0100f20:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100f23:	29 d7                	sub    %edx,%edi
f0100f25:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f28:	83 c8 01             	or     $0x1,%eax
f0100f2b:	89 45 dc             	mov    %eax,-0x24(%ebp)
<<<<<<< HEAD
	//boot_map_region将虚拟地址[va, va+size)映射到物理地址[pa, pa+size)
	//函数参数依次为页目录，虚拟地址起始，映射的大小，物理地址起始，权限位
=======
{
	// 将虚拟地址[va, va+size)映射到物理地址[pa, pa+size)
>>>>>>> lab2
	// Fill this function in
    size = ROUNDUP(size, PGSIZE);
    size_t page_num = PGNUM(size);
    for (size_t i = 0; i < page_num; i++) {
f0100f2e:	eb 22                	jmp    f0100f52 <boot_map_region+0x51>
<<<<<<< HEAD
		//利用pgdir_walk函数找到虚拟地址对应的页表项物理地址
=======

>>>>>>> lab2
        pte_t *pgtable_entry_ptr = pgdir_walk(pgdir, (char *)(va + i * PGSIZE), true);
f0100f30:	83 ec 04             	sub    $0x4,%esp
f0100f33:	6a 01                	push   $0x1
f0100f35:	53                   	push   %ebx
f0100f36:	ff 75 e0             	pushl  -0x20(%ebp)
f0100f39:	e8 fb fe ff ff       	call   f0100e39 <pgdir_walk>
<<<<<<< HEAD
		//将找到的物理页表设置物理地址中的起始位置和权限
=======
>>>>>>> lab2
        *pgtable_entry_ptr = (pa + i * PGSIZE) | perm | PTE_P;
f0100f3e:	8d 14 1f             	lea    (%edi,%ebx,1),%edx
f0100f41:	0b 55 dc             	or     -0x24(%ebp),%edx
f0100f44:	89 10                	mov    %edx,(%eax)
<<<<<<< HEAD
	//boot_map_region将虚拟地址[va, va+size)映射到物理地址[pa, pa+size)
	//函数参数依次为页目录，虚拟地址起始，映射的大小，物理地址起始，权限位
=======
{
	// 将虚拟地址[va, va+size)映射到物理地址[pa, pa+size)
>>>>>>> lab2
	// Fill this function in
    size = ROUNDUP(size, PGSIZE);
    size_t page_num = PGNUM(size);
    for (size_t i = 0; i < page_num; i++) {
f0100f46:	83 c6 01             	add    $0x1,%esi
f0100f49:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100f4f:	83 c4 10             	add    $0x10,%esp
f0100f52:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0100f55:	75 d9                	jne    f0100f30 <boot_map_region+0x2f>
<<<<<<< HEAD
		//利用pgdir_walk函数找到虚拟地址对应的页表项物理地址
        pte_t *pgtable_entry_ptr = pgdir_walk(pgdir, (char *)(va + i * PGSIZE), true);
		//将找到的物理页表设置物理地址中的起始位置和权限
=======

        pte_t *pgtable_entry_ptr = pgdir_walk(pgdir, (char *)(va + i * PGSIZE), true);
>>>>>>> lab2
        *pgtable_entry_ptr = (pa + i * PGSIZE) | perm | PTE_P;
    }
}
f0100f57:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f5a:	5b                   	pop    %ebx
f0100f5b:	5e                   	pop    %esi
f0100f5c:	5f                   	pop    %edi
f0100f5d:	5d                   	pop    %ebp
f0100f5e:	c3                   	ret    

f0100f5f <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
<<<<<<< HEAD
struct PageInfo * //返回虚拟地址va对应的物理页
=======
struct PageInfo * //返回虚拟地址va的页
>>>>>>> lab2
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100f5f:	55                   	push   %ebp
f0100f60:	89 e5                	mov    %esp,%ebp
f0100f62:	53                   	push   %ebx
f0100f63:	83 ec 08             	sub    $0x8,%esp
f0100f66:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
<<<<<<< HEAD
	//首先用pgdir_walk寻找是否存在对应的物理页
=======
>>>>>>> lab2
	pte_t *pte = pgdir_walk(pgdir, va, 0);//如果不存在不创建新页表
f0100f69:	6a 00                	push   $0x0
f0100f6b:	ff 75 0c             	pushl  0xc(%ebp)
f0100f6e:	ff 75 08             	pushl  0x8(%ebp)
f0100f71:	e8 c3 fe ff ff       	call   f0100e39 <pgdir_walk>
	if(pte == NULL) { //不存在则返回NULL
f0100f76:	83 c4 10             	add    $0x10,%esp
f0100f79:	85 c0                	test   %eax,%eax
f0100f7b:	74 32                	je     f0100faf <page_lookup+0x50>
		return NULL;
	} else if(pte_store != 0){
f0100f7d:	85 db                	test   %ebx,%ebx
f0100f7f:	74 02                	je     f0100f83 <page_lookup+0x24>
<<<<<<< HEAD
		*pte_store = pte; //如果pte_store不为0，那么储存这个页的地址
=======
		*pte_store = pte; //如果pte_store不为0就将pte这一页存在这个地址中
>>>>>>> lab2
f0100f81:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f83:	8b 00                	mov    (%eax),%eax
f0100f85:	c1 e8 0c             	shr    $0xc,%eax
f0100f88:	3b 05 64 69 11 f0    	cmp    0xf0116964,%eax
f0100f8e:	72 14                	jb     f0100fa4 <page_lookup+0x45>
		panic("pa2page called with invalid pa");
f0100f90:	83 ec 04             	sub    $0x4,%esp
f0100f93:	68 50 3f 10 f0       	push   $0xf0103f50
f0100f98:	6a 4b                	push   $0x4b
f0100f9a:	68 6a 3b 10 f0       	push   $0xf0103b6a
f0100f9f:	e8 e7 f0 ff ff       	call   f010008b <_panic>
	return &pages[PGNUM(pa)];
f0100fa4:	8b 15 6c 69 11 f0    	mov    0xf011696c,%edx
f0100faa:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	}
<<<<<<< HEAD
	//PTE_ADDR得到页表的物理地址，pa2page将物理地址转为物理页指针
	return pa2page(PTE_ADDR(*pte));
f0100fad:	eb 05                	jmp    f0100fb4 <page_lookup+0x55>
{
	// Fill this function in
	//首先用pgdir_walk寻找是否存在对应的物理页
=======
	//PTE_ADDR得到页表的物理地址
	return pa2page(PTE_ADDR(*pte));//物理地址向pageinfo转换
f0100fad:	eb 05                	jmp    f0100fb4 <page_lookup+0x55>
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	// Fill this function in
>>>>>>> lab2
	pte_t *pte = pgdir_walk(pgdir, va, 0);//如果不存在不创建新页表
	if(pte == NULL) { //不存在则返回NULL
		return NULL;
f0100faf:	b8 00 00 00 00       	mov    $0x0,%eax
	} else if(pte_store != 0){
<<<<<<< HEAD
		*pte_store = pte; //如果pte_store不为0，那么储存这个页的地址
	}
	//PTE_ADDR得到页表的物理地址，pa2page将物理地址转为物理页指针
	return pa2page(PTE_ADDR(*pte));
=======
		*pte_store = pte; //如果pte_store不为0就将pte这一页存在这个地址中
	}
	//PTE_ADDR得到页表的物理地址
	return pa2page(PTE_ADDR(*pte));//物理地址向pageinfo转换
>>>>>>> lab2
}
f0100fb4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100fb7:	c9                   	leave  
f0100fb8:	c3                   	ret    

f0100fb9 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void //移除虚拟地址va和某个页表之间的映射
page_remove(pde_t *pgdir, void *va)
{
f0100fb9:	55                   	push   %ebp
f0100fba:	89 e5                	mov    %esp,%ebp
f0100fbc:	53                   	push   %ebx
f0100fbd:	83 ec 18             	sub    $0x18,%esp
f0100fc0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t *pte;
<<<<<<< HEAD
	//找到va关联的页表
	struct PageInfo *Fpage = page_lookup(pgdir, va, &pte);
=======
	struct PageInfo *Fpage = page_lookup(pgdir, va, &pte);//寻找va对应的页表并与pte关联
>>>>>>> lab2
f0100fc3:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100fc6:	50                   	push   %eax
f0100fc7:	53                   	push   %ebx
f0100fc8:	ff 75 08             	pushl  0x8(%ebp)
f0100fcb:	e8 8f ff ff ff       	call   f0100f5f <page_lookup>
	if(Fpage == NULL){ //如果没找到就直接结束
f0100fd0:	83 c4 10             	add    $0x10,%esp
f0100fd3:	85 c0                	test   %eax,%eax
f0100fd5:	74 18                	je     f0100fef <page_remove+0x36>
		return;
	}
	page_decref(Fpage); //找到了就使物理页的ref计数减1
f0100fd7:	83 ec 0c             	sub    $0xc,%esp
f0100fda:	50                   	push   %eax
f0100fdb:	e8 32 fe ff ff       	call   f0100e12 <page_decref>
<<<<<<< HEAD
	*pte = 0; //并且移除映射
=======
	*pte = 0; 
>>>>>>> lab2
f0100fe0:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100fe3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100fe9:	0f 01 3b             	invlpg (%ebx)
f0100fec:	83 c4 10             	add    $0x10,%esp
	tlb_invalidate(pgdir, va);
}
f0100fef:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100ff2:	c9                   	leave  
f0100ff3:	c3                   	ret    

f0100ff4 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int //将物理页PP和虚拟地址va建立映射
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0100ff4:	55                   	push   %ebp
f0100ff5:	89 e5                	mov    %esp,%ebp
f0100ff7:	57                   	push   %edi
f0100ff8:	56                   	push   %esi
f0100ff9:	53                   	push   %ebx
f0100ffa:	83 ec 10             	sub    $0x10,%esp
f0100ffd:	8b 75 08             	mov    0x8(%ebp),%esi
f0101000:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
<<<<<<< HEAD
    pte_t *pte = pgdir_walk(pgdir, va, 1);//首先利用pgdir_walk找到va的物理页地址
=======
    pte_t *pte = pgdir_walk(pgdir, va, 1);
>>>>>>> lab2
f0101003:	6a 01                	push   $0x1
f0101005:	ff 75 10             	pushl  0x10(%ebp)
f0101008:	56                   	push   %esi
f0101009:	e8 2b fe ff ff       	call   f0100e39 <pgdir_walk>
<<<<<<< HEAD
    if (pte == NULL) { //如果没找到，那么建立映射失败
=======
    if (pte == NULL) { //如果页表无法被初始化，则插入失败，outofmemory
>>>>>>> lab2
f010100e:	83 c4 10             	add    $0x10,%esp
f0101011:	85 c0                	test   %eax,%eax
f0101013:	74 6b                	je     f0101080 <page_insert+0x8c>
f0101015:	89 c7                	mov    %eax,%edi
<<<<<<< HEAD
        return -E_NO_MEM;//页表无法被分配
=======
        return -E_NO_MEM;
>>>>>>> lab2
    }  
    if (*pte & PTE_P) { //如果pte存在
f0101017:	8b 00                	mov    (%eax),%eax
f0101019:	a8 01                	test   $0x1,%al
f010101b:	74 33                	je     f0101050 <page_insert+0x5c>
<<<<<<< HEAD
        if (PTE_ADDR(*pte) == page2pa(pp)) { //且物理页表的地址与pp的物理地址相同
=======
        if (PTE_ADDR(*pte) == page2pa(pp)) { //且pte对应的物理地址就是pp的物理地址
>>>>>>> lab2
f010101d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0101022:	89 da                	mov    %ebx,%edx
f0101024:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f010102a:	c1 fa 03             	sar    $0x3,%edx
f010102d:	c1 e2 0c             	shl    $0xc,%edx
f0101030:	39 d0                	cmp    %edx,%eax
f0101032:	75 0d                	jne    f0101041 <page_insert+0x4d>
f0101034:	8b 45 10             	mov    0x10(%ebp),%eax
f0101037:	0f 01 38             	invlpg (%eax)
<<<<<<< HEAD
            tlb_invalidate(pgdir, va); //则映射已经建立
=======
            tlb_invalidate(pgdir, va); //则不需要插入
>>>>>>> lab2
            pp->pp_ref--; //为了抵消之后的pp_ref++效果，在这里--
f010103a:	66 83 6b 04 01       	subw   $0x1,0x4(%ebx)
f010103f:	eb 0f                	jmp    f0101050 <page_insert+0x5c>
        }
<<<<<<< HEAD
        else { //如果物理页表的地址与PP地址不同
            page_remove(pgdir, va); //则先移除这个映射
=======
        else { //如果pte对应的物理地址使另外的虚拟地址
            page_remove(pgdir, va); //则移除这个映射
>>>>>>> lab2
f0101041:	83 ec 08             	sub    $0x8,%esp
f0101044:	ff 75 10             	pushl  0x10(%ebp)
f0101047:	56                   	push   %esi
f0101048:	e8 6c ff ff ff       	call   f0100fb9 <page_remove>
f010104d:	83 c4 10             	add    $0x10,%esp
        }
    }
<<<<<<< HEAD
    *pte = page2pa(pp) | perm | PTE_P; //建立新的映射，并设置权限
=======
    *pte = page2pa(pp) | perm | PTE_P; //插入新的映射，并设置权限
>>>>>>> lab2
f0101050:	89 d8                	mov    %ebx,%eax
f0101052:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0101058:	c1 f8 03             	sar    $0x3,%eax
f010105b:	c1 e0 0c             	shl    $0xc,%eax
f010105e:	8b 55 14             	mov    0x14(%ebp),%edx
f0101061:	83 ca 01             	or     $0x1,%edx
f0101064:	09 d0                	or     %edx,%eax
f0101066:	89 07                	mov    %eax,(%edi)
<<<<<<< HEAD
    pp->pp_ref++; //pp的引用计数加一
f0101068:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
    pgdir[PDX(va)] |= perm; //页目录的权限加上perm
=======
    pp->pp_ref++; //pp_ref自增
f0101068:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
    pgdir[PDX(va)] |= perm; //将映射加入pagedictionary中
>>>>>>> lab2
f010106d:	8b 45 10             	mov    0x10(%ebp),%eax
f0101070:	c1 e8 16             	shr    $0x16,%eax
f0101073:	8b 4d 14             	mov    0x14(%ebp),%ecx
f0101076:	09 0c 86             	or     %ecx,(%esi,%eax,4)
    return 0;
f0101079:	b8 00 00 00 00       	mov    $0x0,%eax
f010107e:	eb 05                	jmp    f0101085 <page_insert+0x91>
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	// Fill this function in
<<<<<<< HEAD
    pte_t *pte = pgdir_walk(pgdir, va, 1);//首先利用pgdir_walk找到va的物理页地址
    if (pte == NULL) { //如果没找到，那么建立映射失败
        return -E_NO_MEM;//页表无法被分配
f0101080:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
    }
    *pte = page2pa(pp) | perm | PTE_P; //建立新的映射，并设置权限
    pp->pp_ref++; //pp的引用计数加一
    pgdir[PDX(va)] |= perm; //页目录的权限加上perm
=======
    pte_t *pte = pgdir_walk(pgdir, va, 1);
    if (pte == NULL) { //如果页表无法被初始化，则插入失败，outofmemory
        return -E_NO_MEM;
f0101080:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
    }
    *pte = page2pa(pp) | perm | PTE_P; //插入新的映射，并设置权限
    pp->pp_ref++; //pp_ref自增
    pgdir[PDX(va)] |= perm; //将映射加入pagedictionary中
>>>>>>> lab2
    return 0;
}
f0101085:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101088:	5b                   	pop    %ebx
f0101089:	5e                   	pop    %esi
f010108a:	5f                   	pop    %edi
f010108b:	5d                   	pop    %ebp
f010108c:	c3                   	ret    

f010108d <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f010108d:	55                   	push   %ebp
f010108e:	89 e5                	mov    %esp,%ebp
f0101090:	57                   	push   %edi
f0101091:	56                   	push   %esi
f0101092:	53                   	push   %ebx
f0101093:	83 ec 38             	sub    $0x38,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101096:	6a 15                	push   $0x15
f0101098:	e8 77 16 00 00       	call   f0102714 <mc146818_read>
f010109d:	89 c3                	mov    %eax,%ebx
f010109f:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f01010a6:	e8 69 16 00 00       	call   f0102714 <mc146818_read>
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f01010ab:	c1 e0 08             	shl    $0x8,%eax
f01010ae:	09 d8                	or     %ebx,%eax
f01010b0:	c1 e0 0a             	shl    $0xa,%eax
f01010b3:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01010b9:	85 c0                	test   %eax,%eax
f01010bb:	0f 48 c2             	cmovs  %edx,%eax
f01010be:	c1 f8 0c             	sar    $0xc,%eax
f01010c1:	a3 40 65 11 f0       	mov    %eax,0xf0116540
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01010c6:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f01010cd:	e8 42 16 00 00       	call   f0102714 <mc146818_read>
f01010d2:	89 c3                	mov    %eax,%ebx
f01010d4:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f01010db:	e8 34 16 00 00       	call   f0102714 <mc146818_read>
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f01010e0:	c1 e0 08             	shl    $0x8,%eax
f01010e3:	09 d8                	or     %ebx,%eax
f01010e5:	c1 e0 0a             	shl    $0xa,%eax
f01010e8:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01010ee:	83 c4 10             	add    $0x10,%esp
f01010f1:	85 c0                	test   %eax,%eax
f01010f3:	0f 48 c2             	cmovs  %edx,%eax
f01010f6:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f01010f9:	85 c0                	test   %eax,%eax
f01010fb:	74 0e                	je     f010110b <mem_init+0x7e>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f01010fd:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0101103:	89 15 64 69 11 f0    	mov    %edx,0xf0116964
f0101109:	eb 0c                	jmp    f0101117 <mem_init+0x8a>
	else
		npages = npages_basemem;
f010110b:	8b 15 40 65 11 f0    	mov    0xf0116540,%edx
f0101111:	89 15 64 69 11 f0    	mov    %edx,0xf0116964

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101117:	c1 e0 0c             	shl    $0xc,%eax
f010111a:	c1 e8 0a             	shr    $0xa,%eax
f010111d:	50                   	push   %eax
f010111e:	a1 40 65 11 f0       	mov    0xf0116540,%eax
f0101123:	c1 e0 0c             	shl    $0xc,%eax
f0101126:	c1 e8 0a             	shr    $0xa,%eax
f0101129:	50                   	push   %eax
f010112a:	a1 64 69 11 f0       	mov    0xf0116964,%eax
f010112f:	c1 e0 0c             	shl    $0xc,%eax
f0101132:	c1 e8 0a             	shr    $0xa,%eax
f0101135:	50                   	push   %eax
f0101136:	68 70 3f 10 f0       	push   $0xf0103f70
f010113b:	e8 3b 16 00 00       	call   f010277b <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
<<<<<<< HEAD
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE); //为内核页目录分配一个页表的空间
f0101140:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101145:	e8 84 f7 ff ff       	call   f01008ce <boot_alloc>
f010114a:	a3 68 69 11 f0       	mov    %eax,0xf0116968
	memset(kern_pgdir, 0, PGSIZE); //将内核页目录初始化为0
=======
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101140:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101145:	e8 84 f7 ff ff       	call   f01008ce <boot_alloc>
f010114a:	a3 68 69 11 f0       	mov    %eax,0xf0116968
	memset(kern_pgdir, 0, PGSIZE);
>>>>>>> lab2
f010114f:	83 c4 0c             	add    $0xc,%esp
f0101152:	68 00 10 00 00       	push   $0x1000
f0101157:	6a 00                	push   $0x0
f0101159:	50                   	push   %eax
f010115a:	e8 86 20 00 00       	call   f01031e5 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f010115f:	a1 68 69 11 f0       	mov    0xf0116968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101164:	83 c4 10             	add    $0x10,%esp
f0101167:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010116c:	77 15                	ja     f0101183 <mem_init+0xf6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010116e:	50                   	push   %eax
f010116f:	68 ac 3f 10 f0       	push   $0xf0103fac
<<<<<<< HEAD
f0101174:	68 98 00 00 00       	push   $0x98
=======
f0101174:	68 95 00 00 00       	push   $0x95
>>>>>>> lab2
f0101179:	68 5e 3b 10 f0       	push   $0xf0103b5e
f010117e:	e8 08 ef ff ff       	call   f010008b <_panic>
f0101183:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101189:	83 ca 05             	or     $0x5,%edx
f010118c:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
<<<<<<< HEAD
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	
	//这一部分将所有的页表初始化为0，首先确定页表大小为页表结构体大小*页表数
=======
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
>>>>>>> lab2
	uint32_t PageInfo_Size = sizeof(struct PageInfo) * npages; 
f0101192:	a1 64 69 11 f0       	mov    0xf0116964,%eax
f0101197:	c1 e0 03             	shl    $0x3,%eax
f010119a:	89 c7                	mov    %eax,%edi
f010119c:	89 45 cc             	mov    %eax,-0x34(%ebp)
<<<<<<< HEAD
	pages = (struct PageInfo*)boot_alloc(PageInfo_Size);//为物理页表分配等同大小的空间
f010119f:	e8 2a f7 ff ff       	call   f01008ce <boot_alloc>
f01011a4:	a3 6c 69 11 f0       	mov    %eax,0xf011696c
	memset(pages, 0, PageInfo_Size); //将物理页表初始化为0
=======
	pages = (struct PageInfo*)boot_alloc(PageInfo_Size);
f010119f:	e8 2a f7 ff ff       	call   f01008ce <boot_alloc>
f01011a4:	a3 6c 69 11 f0       	mov    %eax,0xf011696c
	memset(pages, 0, PageInfo_Size);
>>>>>>> lab2
f01011a9:	83 ec 04             	sub    $0x4,%esp
f01011ac:	57                   	push   %edi
f01011ad:	6a 00                	push   $0x0
f01011af:	50                   	push   %eax
f01011b0:	e8 30 20 00 00       	call   f01031e5 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
<<<<<<< HEAD
	page_init(); //这里初始化页结构
=======
	page_init();
>>>>>>> lab2
f01011b5:	e8 9a fa ff ff       	call   f0100c54 <page_init>

	check_page_free_list(1);
f01011ba:	b8 01 00 00 00       	mov    $0x1,%eax
f01011bf:	e8 dc f7 ff ff       	call   f01009a0 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f01011c4:	83 c4 10             	add    $0x10,%esp
f01011c7:	83 3d 6c 69 11 f0 00 	cmpl   $0x0,0xf011696c
f01011ce:	75 17                	jne    f01011e7 <mem_init+0x15a>
		panic("'pages' is a null pointer!");
f01011d0:	83 ec 04             	sub    $0x4,%esp
f01011d3:	68 38 3c 10 f0       	push   $0xf0103c38
<<<<<<< HEAD
f01011d8:	68 84 02 00 00       	push   $0x284
=======
f01011d8:	68 65 02 00 00       	push   $0x265
>>>>>>> lab2
f01011dd:	68 5e 3b 10 f0       	push   $0xf0103b5e
f01011e2:	e8 a4 ee ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01011e7:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f01011ec:	bb 00 00 00 00       	mov    $0x0,%ebx
f01011f1:	eb 05                	jmp    f01011f8 <mem_init+0x16b>
		++nfree;
f01011f3:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01011f6:	8b 00                	mov    (%eax),%eax
f01011f8:	85 c0                	test   %eax,%eax
f01011fa:	75 f7                	jne    f01011f3 <mem_init+0x166>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01011fc:	83 ec 0c             	sub    $0xc,%esp
f01011ff:	6a 00                	push   $0x0
f0101201:	e8 46 fb ff ff       	call   f0100d4c <page_alloc>
f0101206:	89 c7                	mov    %eax,%edi
f0101208:	83 c4 10             	add    $0x10,%esp
f010120b:	85 c0                	test   %eax,%eax
f010120d:	75 19                	jne    f0101228 <mem_init+0x19b>
f010120f:	68 53 3c 10 f0       	push   $0xf0103c53
f0101214:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0101219:	68 8c 02 00 00       	push   $0x28c
=======
f0101219:	68 6d 02 00 00       	push   $0x26d
>>>>>>> lab2
f010121e:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0101223:	e8 63 ee ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101228:	83 ec 0c             	sub    $0xc,%esp
f010122b:	6a 00                	push   $0x0
f010122d:	e8 1a fb ff ff       	call   f0100d4c <page_alloc>
f0101232:	89 c6                	mov    %eax,%esi
f0101234:	83 c4 10             	add    $0x10,%esp
f0101237:	85 c0                	test   %eax,%eax
f0101239:	75 19                	jne    f0101254 <mem_init+0x1c7>
f010123b:	68 69 3c 10 f0       	push   $0xf0103c69
f0101240:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0101245:	68 8d 02 00 00       	push   $0x28d
=======
f0101245:	68 6e 02 00 00       	push   $0x26e
>>>>>>> lab2
f010124a:	68 5e 3b 10 f0       	push   $0xf0103b5e
f010124f:	e8 37 ee ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101254:	83 ec 0c             	sub    $0xc,%esp
f0101257:	6a 00                	push   $0x0
f0101259:	e8 ee fa ff ff       	call   f0100d4c <page_alloc>
f010125e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101261:	83 c4 10             	add    $0x10,%esp
f0101264:	85 c0                	test   %eax,%eax
f0101266:	75 19                	jne    f0101281 <mem_init+0x1f4>
f0101268:	68 7f 3c 10 f0       	push   $0xf0103c7f
f010126d:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0101272:	68 8e 02 00 00       	push   $0x28e
=======
f0101272:	68 6f 02 00 00       	push   $0x26f
>>>>>>> lab2
f0101277:	68 5e 3b 10 f0       	push   $0xf0103b5e
f010127c:	e8 0a ee ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101281:	39 f7                	cmp    %esi,%edi
f0101283:	75 19                	jne    f010129e <mem_init+0x211>
f0101285:	68 95 3c 10 f0       	push   $0xf0103c95
f010128a:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f010128f:	68 91 02 00 00       	push   $0x291
=======
f010128f:	68 72 02 00 00       	push   $0x272
>>>>>>> lab2
f0101294:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0101299:	e8 ed ed ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010129e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01012a1:	39 c6                	cmp    %eax,%esi
f01012a3:	74 04                	je     f01012a9 <mem_init+0x21c>
f01012a5:	39 c7                	cmp    %eax,%edi
f01012a7:	75 19                	jne    f01012c2 <mem_init+0x235>
f01012a9:	68 d0 3f 10 f0       	push   $0xf0103fd0
f01012ae:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f01012b3:	68 92 02 00 00       	push   $0x292
=======
f01012b3:	68 73 02 00 00       	push   $0x273
>>>>>>> lab2
f01012b8:	68 5e 3b 10 f0       	push   $0xf0103b5e
f01012bd:	e8 c9 ed ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01012c2:	8b 0d 6c 69 11 f0    	mov    0xf011696c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f01012c8:	8b 15 64 69 11 f0    	mov    0xf0116964,%edx
f01012ce:	c1 e2 0c             	shl    $0xc,%edx
f01012d1:	89 f8                	mov    %edi,%eax
f01012d3:	29 c8                	sub    %ecx,%eax
f01012d5:	c1 f8 03             	sar    $0x3,%eax
f01012d8:	c1 e0 0c             	shl    $0xc,%eax
f01012db:	39 d0                	cmp    %edx,%eax
f01012dd:	72 19                	jb     f01012f8 <mem_init+0x26b>
f01012df:	68 a7 3c 10 f0       	push   $0xf0103ca7
f01012e4:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f01012e9:	68 93 02 00 00       	push   $0x293
=======
f01012e9:	68 74 02 00 00       	push   $0x274
>>>>>>> lab2
f01012ee:	68 5e 3b 10 f0       	push   $0xf0103b5e
f01012f3:	e8 93 ed ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01012f8:	89 f0                	mov    %esi,%eax
f01012fa:	29 c8                	sub    %ecx,%eax
f01012fc:	c1 f8 03             	sar    $0x3,%eax
f01012ff:	c1 e0 0c             	shl    $0xc,%eax
f0101302:	39 c2                	cmp    %eax,%edx
f0101304:	77 19                	ja     f010131f <mem_init+0x292>
f0101306:	68 c4 3c 10 f0       	push   $0xf0103cc4
f010130b:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0101310:	68 94 02 00 00       	push   $0x294
=======
f0101310:	68 75 02 00 00       	push   $0x275
>>>>>>> lab2
f0101315:	68 5e 3b 10 f0       	push   $0xf0103b5e
f010131a:	e8 6c ed ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f010131f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101322:	29 c8                	sub    %ecx,%eax
f0101324:	c1 f8 03             	sar    $0x3,%eax
f0101327:	c1 e0 0c             	shl    $0xc,%eax
f010132a:	39 c2                	cmp    %eax,%edx
f010132c:	77 19                	ja     f0101347 <mem_init+0x2ba>
f010132e:	68 e1 3c 10 f0       	push   $0xf0103ce1
f0101333:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0101338:	68 95 02 00 00       	push   $0x295
=======
f0101338:	68 76 02 00 00       	push   $0x276
>>>>>>> lab2
f010133d:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0101342:	e8 44 ed ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101347:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f010134c:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010134f:	c7 05 3c 65 11 f0 00 	movl   $0x0,0xf011653c
f0101356:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101359:	83 ec 0c             	sub    $0xc,%esp
f010135c:	6a 00                	push   $0x0
f010135e:	e8 e9 f9 ff ff       	call   f0100d4c <page_alloc>
f0101363:	83 c4 10             	add    $0x10,%esp
f0101366:	85 c0                	test   %eax,%eax
f0101368:	74 19                	je     f0101383 <mem_init+0x2f6>
f010136a:	68 fe 3c 10 f0       	push   $0xf0103cfe
f010136f:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0101374:	68 9c 02 00 00       	push   $0x29c
=======
f0101374:	68 7d 02 00 00       	push   $0x27d
>>>>>>> lab2
f0101379:	68 5e 3b 10 f0       	push   $0xf0103b5e
f010137e:	e8 08 ed ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101383:	83 ec 0c             	sub    $0xc,%esp
f0101386:	57                   	push   %edi
f0101387:	e8 30 fa ff ff       	call   f0100dbc <page_free>
	page_free(pp1);
f010138c:	89 34 24             	mov    %esi,(%esp)
f010138f:	e8 28 fa ff ff       	call   f0100dbc <page_free>
	page_free(pp2);
f0101394:	83 c4 04             	add    $0x4,%esp
f0101397:	ff 75 d4             	pushl  -0x2c(%ebp)
f010139a:	e8 1d fa ff ff       	call   f0100dbc <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010139f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013a6:	e8 a1 f9 ff ff       	call   f0100d4c <page_alloc>
f01013ab:	89 c6                	mov    %eax,%esi
f01013ad:	83 c4 10             	add    $0x10,%esp
f01013b0:	85 c0                	test   %eax,%eax
f01013b2:	75 19                	jne    f01013cd <mem_init+0x340>
f01013b4:	68 53 3c 10 f0       	push   $0xf0103c53
f01013b9:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f01013be:	68 a3 02 00 00       	push   $0x2a3
=======
f01013be:	68 84 02 00 00       	push   $0x284
>>>>>>> lab2
f01013c3:	68 5e 3b 10 f0       	push   $0xf0103b5e
f01013c8:	e8 be ec ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01013cd:	83 ec 0c             	sub    $0xc,%esp
f01013d0:	6a 00                	push   $0x0
f01013d2:	e8 75 f9 ff ff       	call   f0100d4c <page_alloc>
f01013d7:	89 c7                	mov    %eax,%edi
f01013d9:	83 c4 10             	add    $0x10,%esp
f01013dc:	85 c0                	test   %eax,%eax
f01013de:	75 19                	jne    f01013f9 <mem_init+0x36c>
f01013e0:	68 69 3c 10 f0       	push   $0xf0103c69
f01013e5:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f01013ea:	68 a4 02 00 00       	push   $0x2a4
=======
f01013ea:	68 85 02 00 00       	push   $0x285
>>>>>>> lab2
f01013ef:	68 5e 3b 10 f0       	push   $0xf0103b5e
f01013f4:	e8 92 ec ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01013f9:	83 ec 0c             	sub    $0xc,%esp
f01013fc:	6a 00                	push   $0x0
f01013fe:	e8 49 f9 ff ff       	call   f0100d4c <page_alloc>
f0101403:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101406:	83 c4 10             	add    $0x10,%esp
f0101409:	85 c0                	test   %eax,%eax
f010140b:	75 19                	jne    f0101426 <mem_init+0x399>
f010140d:	68 7f 3c 10 f0       	push   $0xf0103c7f
f0101412:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0101417:	68 a5 02 00 00       	push   $0x2a5
=======
f0101417:	68 86 02 00 00       	push   $0x286
>>>>>>> lab2
f010141c:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0101421:	e8 65 ec ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101426:	39 fe                	cmp    %edi,%esi
f0101428:	75 19                	jne    f0101443 <mem_init+0x3b6>
f010142a:	68 95 3c 10 f0       	push   $0xf0103c95
f010142f:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0101434:	68 a7 02 00 00       	push   $0x2a7
=======
f0101434:	68 88 02 00 00       	push   $0x288
>>>>>>> lab2
f0101439:	68 5e 3b 10 f0       	push   $0xf0103b5e
f010143e:	e8 48 ec ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101443:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101446:	39 c7                	cmp    %eax,%edi
f0101448:	74 04                	je     f010144e <mem_init+0x3c1>
f010144a:	39 c6                	cmp    %eax,%esi
f010144c:	75 19                	jne    f0101467 <mem_init+0x3da>
f010144e:	68 d0 3f 10 f0       	push   $0xf0103fd0
f0101453:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0101458:	68 a8 02 00 00       	push   $0x2a8
=======
f0101458:	68 89 02 00 00       	push   $0x289
>>>>>>> lab2
f010145d:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0101462:	e8 24 ec ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f0101467:	83 ec 0c             	sub    $0xc,%esp
f010146a:	6a 00                	push   $0x0
f010146c:	e8 db f8 ff ff       	call   f0100d4c <page_alloc>
f0101471:	83 c4 10             	add    $0x10,%esp
f0101474:	85 c0                	test   %eax,%eax
f0101476:	74 19                	je     f0101491 <mem_init+0x404>
f0101478:	68 fe 3c 10 f0       	push   $0xf0103cfe
f010147d:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0101482:	68 a9 02 00 00       	push   $0x2a9
=======
f0101482:	68 8a 02 00 00       	push   $0x28a
>>>>>>> lab2
f0101487:	68 5e 3b 10 f0       	push   $0xf0103b5e
f010148c:	e8 fa eb ff ff       	call   f010008b <_panic>
f0101491:	89 f0                	mov    %esi,%eax
f0101493:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0101499:	c1 f8 03             	sar    $0x3,%eax
f010149c:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010149f:	89 c2                	mov    %eax,%edx
f01014a1:	c1 ea 0c             	shr    $0xc,%edx
f01014a4:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f01014aa:	72 12                	jb     f01014be <mem_init+0x431>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01014ac:	50                   	push   %eax
f01014ad:	68 68 3e 10 f0       	push   $0xf0103e68
f01014b2:	6a 52                	push   $0x52
f01014b4:	68 6a 3b 10 f0       	push   $0xf0103b6a
f01014b9:	e8 cd eb ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01014be:	83 ec 04             	sub    $0x4,%esp
f01014c1:	68 00 10 00 00       	push   $0x1000
f01014c6:	6a 01                	push   $0x1
f01014c8:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01014cd:	50                   	push   %eax
f01014ce:	e8 12 1d 00 00       	call   f01031e5 <memset>
	page_free(pp0);
f01014d3:	89 34 24             	mov    %esi,(%esp)
f01014d6:	e8 e1 f8 ff ff       	call   f0100dbc <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01014db:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01014e2:	e8 65 f8 ff ff       	call   f0100d4c <page_alloc>
f01014e7:	83 c4 10             	add    $0x10,%esp
f01014ea:	85 c0                	test   %eax,%eax
f01014ec:	75 19                	jne    f0101507 <mem_init+0x47a>
f01014ee:	68 0d 3d 10 f0       	push   $0xf0103d0d
f01014f3:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f01014f8:	68 ae 02 00 00       	push   $0x2ae
=======
f01014f8:	68 8f 02 00 00       	push   $0x28f
>>>>>>> lab2
f01014fd:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0101502:	e8 84 eb ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f0101507:	39 c6                	cmp    %eax,%esi
f0101509:	74 19                	je     f0101524 <mem_init+0x497>
f010150b:	68 2b 3d 10 f0       	push   $0xf0103d2b
f0101510:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0101515:	68 af 02 00 00       	push   $0x2af
=======
f0101515:	68 90 02 00 00       	push   $0x290
>>>>>>> lab2
f010151a:	68 5e 3b 10 f0       	push   $0xf0103b5e
f010151f:	e8 67 eb ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101524:	89 f0                	mov    %esi,%eax
f0101526:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f010152c:	c1 f8 03             	sar    $0x3,%eax
f010152f:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101532:	89 c2                	mov    %eax,%edx
f0101534:	c1 ea 0c             	shr    $0xc,%edx
f0101537:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f010153d:	72 12                	jb     f0101551 <mem_init+0x4c4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010153f:	50                   	push   %eax
f0101540:	68 68 3e 10 f0       	push   $0xf0103e68
f0101545:	6a 52                	push   $0x52
f0101547:	68 6a 3b 10 f0       	push   $0xf0103b6a
f010154c:	e8 3a eb ff ff       	call   f010008b <_panic>
f0101551:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101557:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f010155d:	80 38 00             	cmpb   $0x0,(%eax)
f0101560:	74 19                	je     f010157b <mem_init+0x4ee>
f0101562:	68 3b 3d 10 f0       	push   $0xf0103d3b
f0101567:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f010156c:	68 b2 02 00 00       	push   $0x2b2
=======
f010156c:	68 93 02 00 00       	push   $0x293
>>>>>>> lab2
f0101571:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0101576:	e8 10 eb ff ff       	call   f010008b <_panic>
f010157b:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f010157e:	39 d0                	cmp    %edx,%eax
f0101580:	75 db                	jne    f010155d <mem_init+0x4d0>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101582:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101585:	a3 3c 65 11 f0       	mov    %eax,0xf011653c

	// free the pages we took
	page_free(pp0);
f010158a:	83 ec 0c             	sub    $0xc,%esp
f010158d:	56                   	push   %esi
f010158e:	e8 29 f8 ff ff       	call   f0100dbc <page_free>
	page_free(pp1);
f0101593:	89 3c 24             	mov    %edi,(%esp)
f0101596:	e8 21 f8 ff ff       	call   f0100dbc <page_free>
	page_free(pp2);
f010159b:	83 c4 04             	add    $0x4,%esp
f010159e:	ff 75 d4             	pushl  -0x2c(%ebp)
f01015a1:	e8 16 f8 ff ff       	call   f0100dbc <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01015a6:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f01015ab:	83 c4 10             	add    $0x10,%esp
f01015ae:	eb 05                	jmp    f01015b5 <mem_init+0x528>
		--nfree;
f01015b0:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01015b3:	8b 00                	mov    (%eax),%eax
f01015b5:	85 c0                	test   %eax,%eax
f01015b7:	75 f7                	jne    f01015b0 <mem_init+0x523>
		--nfree;
	assert(nfree == 0);
f01015b9:	85 db                	test   %ebx,%ebx
f01015bb:	74 19                	je     f01015d6 <mem_init+0x549>
f01015bd:	68 45 3d 10 f0       	push   $0xf0103d45
f01015c2:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f01015c7:	68 bf 02 00 00       	push   $0x2bf
=======
f01015c7:	68 a0 02 00 00       	push   $0x2a0
>>>>>>> lab2
f01015cc:	68 5e 3b 10 f0       	push   $0xf0103b5e
f01015d1:	e8 b5 ea ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01015d6:	83 ec 0c             	sub    $0xc,%esp
f01015d9:	68 f0 3f 10 f0       	push   $0xf0103ff0
f01015de:	e8 98 11 00 00       	call   f010277b <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01015e3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015ea:	e8 5d f7 ff ff       	call   f0100d4c <page_alloc>
f01015ef:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01015f2:	83 c4 10             	add    $0x10,%esp
f01015f5:	85 c0                	test   %eax,%eax
f01015f7:	75 19                	jne    f0101612 <mem_init+0x585>
f01015f9:	68 53 3c 10 f0       	push   $0xf0103c53
f01015fe:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0101603:	68 18 03 00 00       	push   $0x318
=======
f0101603:	68 f9 02 00 00       	push   $0x2f9
>>>>>>> lab2
f0101608:	68 5e 3b 10 f0       	push   $0xf0103b5e
f010160d:	e8 79 ea ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101612:	83 ec 0c             	sub    $0xc,%esp
f0101615:	6a 00                	push   $0x0
f0101617:	e8 30 f7 ff ff       	call   f0100d4c <page_alloc>
f010161c:	89 c3                	mov    %eax,%ebx
f010161e:	83 c4 10             	add    $0x10,%esp
f0101621:	85 c0                	test   %eax,%eax
f0101623:	75 19                	jne    f010163e <mem_init+0x5b1>
f0101625:	68 69 3c 10 f0       	push   $0xf0103c69
f010162a:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f010162f:	68 19 03 00 00       	push   $0x319
=======
f010162f:	68 fa 02 00 00       	push   $0x2fa
>>>>>>> lab2
f0101634:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0101639:	e8 4d ea ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f010163e:	83 ec 0c             	sub    $0xc,%esp
f0101641:	6a 00                	push   $0x0
f0101643:	e8 04 f7 ff ff       	call   f0100d4c <page_alloc>
f0101648:	89 c6                	mov    %eax,%esi
f010164a:	83 c4 10             	add    $0x10,%esp
f010164d:	85 c0                	test   %eax,%eax
f010164f:	75 19                	jne    f010166a <mem_init+0x5dd>
f0101651:	68 7f 3c 10 f0       	push   $0xf0103c7f
f0101656:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f010165b:	68 1a 03 00 00       	push   $0x31a
=======
f010165b:	68 fb 02 00 00       	push   $0x2fb
>>>>>>> lab2
f0101660:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0101665:	e8 21 ea ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010166a:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f010166d:	75 19                	jne    f0101688 <mem_init+0x5fb>
f010166f:	68 95 3c 10 f0       	push   $0xf0103c95
f0101674:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0101679:	68 1d 03 00 00       	push   $0x31d
=======
f0101679:	68 fe 02 00 00       	push   $0x2fe
>>>>>>> lab2
f010167e:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0101683:	e8 03 ea ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101688:	39 c3                	cmp    %eax,%ebx
f010168a:	74 05                	je     f0101691 <mem_init+0x604>
f010168c:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f010168f:	75 19                	jne    f01016aa <mem_init+0x61d>
f0101691:	68 d0 3f 10 f0       	push   $0xf0103fd0
f0101696:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f010169b:	68 1e 03 00 00       	push   $0x31e
=======
f010169b:	68 ff 02 00 00       	push   $0x2ff
>>>>>>> lab2
f01016a0:	68 5e 3b 10 f0       	push   $0xf0103b5e
f01016a5:	e8 e1 e9 ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01016aa:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f01016af:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01016b2:	c7 05 3c 65 11 f0 00 	movl   $0x0,0xf011653c
f01016b9:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01016bc:	83 ec 0c             	sub    $0xc,%esp
f01016bf:	6a 00                	push   $0x0
f01016c1:	e8 86 f6 ff ff       	call   f0100d4c <page_alloc>
f01016c6:	83 c4 10             	add    $0x10,%esp
f01016c9:	85 c0                	test   %eax,%eax
f01016cb:	74 19                	je     f01016e6 <mem_init+0x659>
f01016cd:	68 fe 3c 10 f0       	push   $0xf0103cfe
f01016d2:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f01016d7:	68 25 03 00 00       	push   $0x325
=======
f01016d7:	68 06 03 00 00       	push   $0x306
>>>>>>> lab2
f01016dc:	68 5e 3b 10 f0       	push   $0xf0103b5e
f01016e1:	e8 a5 e9 ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01016e6:	83 ec 04             	sub    $0x4,%esp
f01016e9:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01016ec:	50                   	push   %eax
f01016ed:	6a 00                	push   $0x0
f01016ef:	ff 35 68 69 11 f0    	pushl  0xf0116968
f01016f5:	e8 65 f8 ff ff       	call   f0100f5f <page_lookup>
f01016fa:	83 c4 10             	add    $0x10,%esp
f01016fd:	85 c0                	test   %eax,%eax
f01016ff:	74 19                	je     f010171a <mem_init+0x68d>
f0101701:	68 10 40 10 f0       	push   $0xf0104010
f0101706:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f010170b:	68 28 03 00 00       	push   $0x328
=======
f010170b:	68 09 03 00 00       	push   $0x309
>>>>>>> lab2
f0101710:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0101715:	e8 71 e9 ff ff       	call   f010008b <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f010171a:	6a 02                	push   $0x2
f010171c:	6a 00                	push   $0x0
f010171e:	53                   	push   %ebx
f010171f:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101725:	e8 ca f8 ff ff       	call   f0100ff4 <page_insert>
f010172a:	83 c4 10             	add    $0x10,%esp
f010172d:	85 c0                	test   %eax,%eax
f010172f:	78 19                	js     f010174a <mem_init+0x6bd>
f0101731:	68 48 40 10 f0       	push   $0xf0104048
f0101736:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f010173b:	68 2b 03 00 00       	push   $0x32b
=======
f010173b:	68 0c 03 00 00       	push   $0x30c
>>>>>>> lab2
f0101740:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0101745:	e8 41 e9 ff ff       	call   f010008b <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f010174a:	83 ec 0c             	sub    $0xc,%esp
f010174d:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101750:	e8 67 f6 ff ff       	call   f0100dbc <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101755:	6a 02                	push   $0x2
f0101757:	6a 00                	push   $0x0
f0101759:	53                   	push   %ebx
f010175a:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101760:	e8 8f f8 ff ff       	call   f0100ff4 <page_insert>
f0101765:	83 c4 20             	add    $0x20,%esp
f0101768:	85 c0                	test   %eax,%eax
f010176a:	74 19                	je     f0101785 <mem_init+0x6f8>
f010176c:	68 78 40 10 f0       	push   $0xf0104078
f0101771:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0101776:	68 2f 03 00 00       	push   $0x32f
=======
f0101776:	68 10 03 00 00       	push   $0x310
>>>>>>> lab2
f010177b:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0101780:	e8 06 e9 ff ff       	call   f010008b <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101785:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010178b:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
f0101790:	89 c1                	mov    %eax,%ecx
f0101792:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0101795:	8b 17                	mov    (%edi),%edx
f0101797:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010179d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01017a0:	29 c8                	sub    %ecx,%eax
f01017a2:	c1 f8 03             	sar    $0x3,%eax
f01017a5:	c1 e0 0c             	shl    $0xc,%eax
f01017a8:	39 c2                	cmp    %eax,%edx
f01017aa:	74 19                	je     f01017c5 <mem_init+0x738>
f01017ac:	68 a8 40 10 f0       	push   $0xf01040a8
f01017b1:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f01017b6:	68 30 03 00 00       	push   $0x330
=======
f01017b6:	68 11 03 00 00       	push   $0x311
>>>>>>> lab2
f01017bb:	68 5e 3b 10 f0       	push   $0xf0103b5e
f01017c0:	e8 c6 e8 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01017c5:	ba 00 00 00 00       	mov    $0x0,%edx
f01017ca:	89 f8                	mov    %edi,%eax
f01017cc:	e8 6b f1 ff ff       	call   f010093c <check_va2pa>
f01017d1:	89 da                	mov    %ebx,%edx
f01017d3:	2b 55 c8             	sub    -0x38(%ebp),%edx
f01017d6:	c1 fa 03             	sar    $0x3,%edx
f01017d9:	c1 e2 0c             	shl    $0xc,%edx
f01017dc:	39 d0                	cmp    %edx,%eax
f01017de:	74 19                	je     f01017f9 <mem_init+0x76c>
f01017e0:	68 d0 40 10 f0       	push   $0xf01040d0
f01017e5:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f01017ea:	68 31 03 00 00       	push   $0x331
=======
f01017ea:	68 12 03 00 00       	push   $0x312
>>>>>>> lab2
f01017ef:	68 5e 3b 10 f0       	push   $0xf0103b5e
f01017f4:	e8 92 e8 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f01017f9:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01017fe:	74 19                	je     f0101819 <mem_init+0x78c>
f0101800:	68 50 3d 10 f0       	push   $0xf0103d50
f0101805:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f010180a:	68 32 03 00 00       	push   $0x332
=======
f010180a:	68 13 03 00 00       	push   $0x313
>>>>>>> lab2
f010180f:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0101814:	e8 72 e8 ff ff       	call   f010008b <_panic>
	assert(pp0->pp_ref == 1);
f0101819:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010181c:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101821:	74 19                	je     f010183c <mem_init+0x7af>
f0101823:	68 61 3d 10 f0       	push   $0xf0103d61
f0101828:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f010182d:	68 33 03 00 00       	push   $0x333
=======
f010182d:	68 14 03 00 00       	push   $0x314
>>>>>>> lab2
f0101832:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0101837:	e8 4f e8 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010183c:	6a 02                	push   $0x2
f010183e:	68 00 10 00 00       	push   $0x1000
f0101843:	56                   	push   %esi
f0101844:	57                   	push   %edi
f0101845:	e8 aa f7 ff ff       	call   f0100ff4 <page_insert>
f010184a:	83 c4 10             	add    $0x10,%esp
f010184d:	85 c0                	test   %eax,%eax
f010184f:	74 19                	je     f010186a <mem_init+0x7dd>
f0101851:	68 00 41 10 f0       	push   $0xf0104100
f0101856:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f010185b:	68 36 03 00 00       	push   $0x336
=======
f010185b:	68 17 03 00 00       	push   $0x317
>>>>>>> lab2
f0101860:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0101865:	e8 21 e8 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010186a:	ba 00 10 00 00       	mov    $0x1000,%edx
f010186f:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0101874:	e8 c3 f0 ff ff       	call   f010093c <check_va2pa>
f0101879:	89 f2                	mov    %esi,%edx
f010187b:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f0101881:	c1 fa 03             	sar    $0x3,%edx
f0101884:	c1 e2 0c             	shl    $0xc,%edx
f0101887:	39 d0                	cmp    %edx,%eax
f0101889:	74 19                	je     f01018a4 <mem_init+0x817>
f010188b:	68 3c 41 10 f0       	push   $0xf010413c
f0101890:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0101895:	68 37 03 00 00       	push   $0x337
=======
f0101895:	68 18 03 00 00       	push   $0x318
>>>>>>> lab2
f010189a:	68 5e 3b 10 f0       	push   $0xf0103b5e
f010189f:	e8 e7 e7 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01018a4:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01018a9:	74 19                	je     f01018c4 <mem_init+0x837>
f01018ab:	68 72 3d 10 f0       	push   $0xf0103d72
f01018b0:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f01018b5:	68 38 03 00 00       	push   $0x338
=======
f01018b5:	68 19 03 00 00       	push   $0x319
>>>>>>> lab2
f01018ba:	68 5e 3b 10 f0       	push   $0xf0103b5e
f01018bf:	e8 c7 e7 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01018c4:	83 ec 0c             	sub    $0xc,%esp
f01018c7:	6a 00                	push   $0x0
f01018c9:	e8 7e f4 ff ff       	call   f0100d4c <page_alloc>
f01018ce:	83 c4 10             	add    $0x10,%esp
f01018d1:	85 c0                	test   %eax,%eax
f01018d3:	74 19                	je     f01018ee <mem_init+0x861>
f01018d5:	68 fe 3c 10 f0       	push   $0xf0103cfe
f01018da:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f01018df:	68 3b 03 00 00       	push   $0x33b
=======
f01018df:	68 1c 03 00 00       	push   $0x31c
>>>>>>> lab2
f01018e4:	68 5e 3b 10 f0       	push   $0xf0103b5e
f01018e9:	e8 9d e7 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01018ee:	6a 02                	push   $0x2
f01018f0:	68 00 10 00 00       	push   $0x1000
f01018f5:	56                   	push   %esi
f01018f6:	ff 35 68 69 11 f0    	pushl  0xf0116968
f01018fc:	e8 f3 f6 ff ff       	call   f0100ff4 <page_insert>
f0101901:	83 c4 10             	add    $0x10,%esp
f0101904:	85 c0                	test   %eax,%eax
f0101906:	74 19                	je     f0101921 <mem_init+0x894>
f0101908:	68 00 41 10 f0       	push   $0xf0104100
f010190d:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0101912:	68 3e 03 00 00       	push   $0x33e
=======
f0101912:	68 1f 03 00 00       	push   $0x31f
>>>>>>> lab2
f0101917:	68 5e 3b 10 f0       	push   $0xf0103b5e
f010191c:	e8 6a e7 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101921:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101926:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f010192b:	e8 0c f0 ff ff       	call   f010093c <check_va2pa>
f0101930:	89 f2                	mov    %esi,%edx
f0101932:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f0101938:	c1 fa 03             	sar    $0x3,%edx
f010193b:	c1 e2 0c             	shl    $0xc,%edx
f010193e:	39 d0                	cmp    %edx,%eax
f0101940:	74 19                	je     f010195b <mem_init+0x8ce>
f0101942:	68 3c 41 10 f0       	push   $0xf010413c
f0101947:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f010194c:	68 3f 03 00 00       	push   $0x33f
=======
f010194c:	68 20 03 00 00       	push   $0x320
>>>>>>> lab2
f0101951:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0101956:	e8 30 e7 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f010195b:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101960:	74 19                	je     f010197b <mem_init+0x8ee>
f0101962:	68 72 3d 10 f0       	push   $0xf0103d72
f0101967:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f010196c:	68 40 03 00 00       	push   $0x340
=======
f010196c:	68 21 03 00 00       	push   $0x321
>>>>>>> lab2
f0101971:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0101976:	e8 10 e7 ff ff       	call   f010008b <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f010197b:	83 ec 0c             	sub    $0xc,%esp
f010197e:	6a 00                	push   $0x0
f0101980:	e8 c7 f3 ff ff       	call   f0100d4c <page_alloc>
f0101985:	83 c4 10             	add    $0x10,%esp
f0101988:	85 c0                	test   %eax,%eax
f010198a:	74 19                	je     f01019a5 <mem_init+0x918>
f010198c:	68 fe 3c 10 f0       	push   $0xf0103cfe
f0101991:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0101996:	68 44 03 00 00       	push   $0x344
=======
f0101996:	68 25 03 00 00       	push   $0x325
>>>>>>> lab2
f010199b:	68 5e 3b 10 f0       	push   $0xf0103b5e
f01019a0:	e8 e6 e6 ff ff       	call   f010008b <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f01019a5:	8b 15 68 69 11 f0    	mov    0xf0116968,%edx
f01019ab:	8b 02                	mov    (%edx),%eax
f01019ad:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01019b2:	89 c1                	mov    %eax,%ecx
f01019b4:	c1 e9 0c             	shr    $0xc,%ecx
f01019b7:	3b 0d 64 69 11 f0    	cmp    0xf0116964,%ecx
f01019bd:	72 15                	jb     f01019d4 <mem_init+0x947>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01019bf:	50                   	push   %eax
f01019c0:	68 68 3e 10 f0       	push   $0xf0103e68
<<<<<<< HEAD
f01019c5:	68 47 03 00 00       	push   $0x347
=======
f01019c5:	68 28 03 00 00       	push   $0x328
>>>>>>> lab2
f01019ca:	68 5e 3b 10 f0       	push   $0xf0103b5e
f01019cf:	e8 b7 e6 ff ff       	call   f010008b <_panic>
f01019d4:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01019d9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f01019dc:	83 ec 04             	sub    $0x4,%esp
f01019df:	6a 00                	push   $0x0
f01019e1:	68 00 10 00 00       	push   $0x1000
f01019e6:	52                   	push   %edx
f01019e7:	e8 4d f4 ff ff       	call   f0100e39 <pgdir_walk>
f01019ec:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01019ef:	8d 51 04             	lea    0x4(%ecx),%edx
f01019f2:	83 c4 10             	add    $0x10,%esp
f01019f5:	39 d0                	cmp    %edx,%eax
f01019f7:	74 19                	je     f0101a12 <mem_init+0x985>
f01019f9:	68 6c 41 10 f0       	push   $0xf010416c
f01019fe:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0101a03:	68 48 03 00 00       	push   $0x348
=======
f0101a03:	68 29 03 00 00       	push   $0x329
>>>>>>> lab2
f0101a08:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0101a0d:	e8 79 e6 ff ff       	call   f010008b <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101a12:	6a 06                	push   $0x6
f0101a14:	68 00 10 00 00       	push   $0x1000
f0101a19:	56                   	push   %esi
f0101a1a:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101a20:	e8 cf f5 ff ff       	call   f0100ff4 <page_insert>
f0101a25:	83 c4 10             	add    $0x10,%esp
f0101a28:	85 c0                	test   %eax,%eax
f0101a2a:	74 19                	je     f0101a45 <mem_init+0x9b8>
f0101a2c:	68 ac 41 10 f0       	push   $0xf01041ac
f0101a31:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0101a36:	68 4b 03 00 00       	push   $0x34b
=======
f0101a36:	68 2c 03 00 00       	push   $0x32c
>>>>>>> lab2
f0101a3b:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0101a40:	e8 46 e6 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a45:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f0101a4b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a50:	89 f8                	mov    %edi,%eax
f0101a52:	e8 e5 ee ff ff       	call   f010093c <check_va2pa>
f0101a57:	89 f2                	mov    %esi,%edx
f0101a59:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f0101a5f:	c1 fa 03             	sar    $0x3,%edx
f0101a62:	c1 e2 0c             	shl    $0xc,%edx
f0101a65:	39 d0                	cmp    %edx,%eax
f0101a67:	74 19                	je     f0101a82 <mem_init+0x9f5>
f0101a69:	68 3c 41 10 f0       	push   $0xf010413c
f0101a6e:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0101a73:	68 4c 03 00 00       	push   $0x34c
=======
f0101a73:	68 2d 03 00 00       	push   $0x32d
>>>>>>> lab2
f0101a78:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0101a7d:	e8 09 e6 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101a82:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101a87:	74 19                	je     f0101aa2 <mem_init+0xa15>
f0101a89:	68 72 3d 10 f0       	push   $0xf0103d72
f0101a8e:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0101a93:	68 4d 03 00 00       	push   $0x34d
=======
f0101a93:	68 2e 03 00 00       	push   $0x32e
>>>>>>> lab2
f0101a98:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0101a9d:	e8 e9 e5 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101aa2:	83 ec 04             	sub    $0x4,%esp
f0101aa5:	6a 00                	push   $0x0
f0101aa7:	68 00 10 00 00       	push   $0x1000
f0101aac:	57                   	push   %edi
f0101aad:	e8 87 f3 ff ff       	call   f0100e39 <pgdir_walk>
f0101ab2:	83 c4 10             	add    $0x10,%esp
f0101ab5:	f6 00 04             	testb  $0x4,(%eax)
f0101ab8:	75 19                	jne    f0101ad3 <mem_init+0xa46>
f0101aba:	68 ec 41 10 f0       	push   $0xf01041ec
f0101abf:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0101ac4:	68 4e 03 00 00       	push   $0x34e
=======
f0101ac4:	68 2f 03 00 00       	push   $0x32f
>>>>>>> lab2
f0101ac9:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0101ace:	e8 b8 e5 ff ff       	call   f010008b <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101ad3:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0101ad8:	f6 00 04             	testb  $0x4,(%eax)
f0101adb:	75 19                	jne    f0101af6 <mem_init+0xa69>
f0101add:	68 83 3d 10 f0       	push   $0xf0103d83
f0101ae2:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0101ae7:	68 4f 03 00 00       	push   $0x34f
=======
f0101ae7:	68 30 03 00 00       	push   $0x330
>>>>>>> lab2
f0101aec:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0101af1:	e8 95 e5 ff ff       	call   f010008b <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101af6:	6a 02                	push   $0x2
f0101af8:	68 00 10 00 00       	push   $0x1000
f0101afd:	56                   	push   %esi
f0101afe:	50                   	push   %eax
f0101aff:	e8 f0 f4 ff ff       	call   f0100ff4 <page_insert>
f0101b04:	83 c4 10             	add    $0x10,%esp
f0101b07:	85 c0                	test   %eax,%eax
f0101b09:	74 19                	je     f0101b24 <mem_init+0xa97>
f0101b0b:	68 00 41 10 f0       	push   $0xf0104100
f0101b10:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0101b15:	68 52 03 00 00       	push   $0x352
=======
f0101b15:	68 33 03 00 00       	push   $0x333
>>>>>>> lab2
f0101b1a:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0101b1f:	e8 67 e5 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101b24:	83 ec 04             	sub    $0x4,%esp
f0101b27:	6a 00                	push   $0x0
f0101b29:	68 00 10 00 00       	push   $0x1000
f0101b2e:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101b34:	e8 00 f3 ff ff       	call   f0100e39 <pgdir_walk>
f0101b39:	83 c4 10             	add    $0x10,%esp
f0101b3c:	f6 00 02             	testb  $0x2,(%eax)
f0101b3f:	75 19                	jne    f0101b5a <mem_init+0xacd>
f0101b41:	68 20 42 10 f0       	push   $0xf0104220
f0101b46:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0101b4b:	68 53 03 00 00       	push   $0x353
=======
f0101b4b:	68 34 03 00 00       	push   $0x334
>>>>>>> lab2
f0101b50:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0101b55:	e8 31 e5 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101b5a:	83 ec 04             	sub    $0x4,%esp
f0101b5d:	6a 00                	push   $0x0
f0101b5f:	68 00 10 00 00       	push   $0x1000
f0101b64:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101b6a:	e8 ca f2 ff ff       	call   f0100e39 <pgdir_walk>
f0101b6f:	83 c4 10             	add    $0x10,%esp
f0101b72:	f6 00 04             	testb  $0x4,(%eax)
f0101b75:	74 19                	je     f0101b90 <mem_init+0xb03>
f0101b77:	68 54 42 10 f0       	push   $0xf0104254
f0101b7c:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0101b81:	68 54 03 00 00       	push   $0x354
=======
f0101b81:	68 35 03 00 00       	push   $0x335
>>>>>>> lab2
f0101b86:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0101b8b:	e8 fb e4 ff ff       	call   f010008b <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101b90:	6a 02                	push   $0x2
f0101b92:	68 00 00 40 00       	push   $0x400000
f0101b97:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101b9a:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101ba0:	e8 4f f4 ff ff       	call   f0100ff4 <page_insert>
f0101ba5:	83 c4 10             	add    $0x10,%esp
f0101ba8:	85 c0                	test   %eax,%eax
f0101baa:	78 19                	js     f0101bc5 <mem_init+0xb38>
f0101bac:	68 8c 42 10 f0       	push   $0xf010428c
f0101bb1:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0101bb6:	68 57 03 00 00       	push   $0x357
=======
f0101bb6:	68 38 03 00 00       	push   $0x338
>>>>>>> lab2
f0101bbb:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0101bc0:	e8 c6 e4 ff ff       	call   f010008b <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101bc5:	6a 02                	push   $0x2
f0101bc7:	68 00 10 00 00       	push   $0x1000
f0101bcc:	53                   	push   %ebx
f0101bcd:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101bd3:	e8 1c f4 ff ff       	call   f0100ff4 <page_insert>
f0101bd8:	83 c4 10             	add    $0x10,%esp
f0101bdb:	85 c0                	test   %eax,%eax
f0101bdd:	74 19                	je     f0101bf8 <mem_init+0xb6b>
f0101bdf:	68 c4 42 10 f0       	push   $0xf01042c4
f0101be4:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0101be9:	68 5a 03 00 00       	push   $0x35a
=======
f0101be9:	68 3b 03 00 00       	push   $0x33b
>>>>>>> lab2
f0101bee:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0101bf3:	e8 93 e4 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101bf8:	83 ec 04             	sub    $0x4,%esp
f0101bfb:	6a 00                	push   $0x0
f0101bfd:	68 00 10 00 00       	push   $0x1000
f0101c02:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101c08:	e8 2c f2 ff ff       	call   f0100e39 <pgdir_walk>
f0101c0d:	83 c4 10             	add    $0x10,%esp
f0101c10:	f6 00 04             	testb  $0x4,(%eax)
f0101c13:	74 19                	je     f0101c2e <mem_init+0xba1>
f0101c15:	68 54 42 10 f0       	push   $0xf0104254
f0101c1a:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0101c1f:	68 5b 03 00 00       	push   $0x35b
=======
f0101c1f:	68 3c 03 00 00       	push   $0x33c
>>>>>>> lab2
f0101c24:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0101c29:	e8 5d e4 ff ff       	call   f010008b <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101c2e:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f0101c34:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c39:	89 f8                	mov    %edi,%eax
f0101c3b:	e8 fc ec ff ff       	call   f010093c <check_va2pa>
f0101c40:	89 c1                	mov    %eax,%ecx
f0101c42:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0101c45:	89 d8                	mov    %ebx,%eax
f0101c47:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0101c4d:	c1 f8 03             	sar    $0x3,%eax
f0101c50:	c1 e0 0c             	shl    $0xc,%eax
f0101c53:	39 c1                	cmp    %eax,%ecx
f0101c55:	74 19                	je     f0101c70 <mem_init+0xbe3>
f0101c57:	68 00 43 10 f0       	push   $0xf0104300
f0101c5c:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0101c61:	68 5e 03 00 00       	push   $0x35e
=======
f0101c61:	68 3f 03 00 00       	push   $0x33f
>>>>>>> lab2
f0101c66:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0101c6b:	e8 1b e4 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101c70:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c75:	89 f8                	mov    %edi,%eax
f0101c77:	e8 c0 ec ff ff       	call   f010093c <check_va2pa>
f0101c7c:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0101c7f:	74 19                	je     f0101c9a <mem_init+0xc0d>
f0101c81:	68 2c 43 10 f0       	push   $0xf010432c
f0101c86:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0101c8b:	68 5f 03 00 00       	push   $0x35f
=======
f0101c8b:	68 40 03 00 00       	push   $0x340
>>>>>>> lab2
f0101c90:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0101c95:	e8 f1 e3 ff ff       	call   f010008b <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101c9a:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101c9f:	74 19                	je     f0101cba <mem_init+0xc2d>
f0101ca1:	68 99 3d 10 f0       	push   $0xf0103d99
f0101ca6:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0101cab:	68 61 03 00 00       	push   $0x361
=======
f0101cab:	68 42 03 00 00       	push   $0x342
>>>>>>> lab2
f0101cb0:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0101cb5:	e8 d1 e3 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101cba:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101cbf:	74 19                	je     f0101cda <mem_init+0xc4d>
f0101cc1:	68 aa 3d 10 f0       	push   $0xf0103daa
f0101cc6:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0101ccb:	68 62 03 00 00       	push   $0x362
=======
f0101ccb:	68 43 03 00 00       	push   $0x343
>>>>>>> lab2
f0101cd0:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0101cd5:	e8 b1 e3 ff ff       	call   f010008b <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101cda:	83 ec 0c             	sub    $0xc,%esp
f0101cdd:	6a 00                	push   $0x0
f0101cdf:	e8 68 f0 ff ff       	call   f0100d4c <page_alloc>
f0101ce4:	83 c4 10             	add    $0x10,%esp
f0101ce7:	85 c0                	test   %eax,%eax
f0101ce9:	74 04                	je     f0101cef <mem_init+0xc62>
f0101ceb:	39 c6                	cmp    %eax,%esi
f0101ced:	74 19                	je     f0101d08 <mem_init+0xc7b>
f0101cef:	68 5c 43 10 f0       	push   $0xf010435c
f0101cf4:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0101cf9:	68 65 03 00 00       	push   $0x365
=======
f0101cf9:	68 46 03 00 00       	push   $0x346
>>>>>>> lab2
f0101cfe:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0101d03:	e8 83 e3 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101d08:	83 ec 08             	sub    $0x8,%esp
f0101d0b:	6a 00                	push   $0x0
f0101d0d:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101d13:	e8 a1 f2 ff ff       	call   f0100fb9 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101d18:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f0101d1e:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d23:	89 f8                	mov    %edi,%eax
f0101d25:	e8 12 ec ff ff       	call   f010093c <check_va2pa>
f0101d2a:	83 c4 10             	add    $0x10,%esp
f0101d2d:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d30:	74 19                	je     f0101d4b <mem_init+0xcbe>
f0101d32:	68 80 43 10 f0       	push   $0xf0104380
f0101d37:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0101d3c:	68 69 03 00 00       	push   $0x369
=======
f0101d3c:	68 4a 03 00 00       	push   $0x34a
>>>>>>> lab2
f0101d41:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0101d46:	e8 40 e3 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101d4b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d50:	89 f8                	mov    %edi,%eax
f0101d52:	e8 e5 eb ff ff       	call   f010093c <check_va2pa>
f0101d57:	89 da                	mov    %ebx,%edx
f0101d59:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f0101d5f:	c1 fa 03             	sar    $0x3,%edx
f0101d62:	c1 e2 0c             	shl    $0xc,%edx
f0101d65:	39 d0                	cmp    %edx,%eax
f0101d67:	74 19                	je     f0101d82 <mem_init+0xcf5>
f0101d69:	68 2c 43 10 f0       	push   $0xf010432c
f0101d6e:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0101d73:	68 6a 03 00 00       	push   $0x36a
=======
f0101d73:	68 4b 03 00 00       	push   $0x34b
>>>>>>> lab2
f0101d78:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0101d7d:	e8 09 e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101d82:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101d87:	74 19                	je     f0101da2 <mem_init+0xd15>
f0101d89:	68 50 3d 10 f0       	push   $0xf0103d50
f0101d8e:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0101d93:	68 6b 03 00 00       	push   $0x36b
=======
f0101d93:	68 4c 03 00 00       	push   $0x34c
>>>>>>> lab2
f0101d98:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0101d9d:	e8 e9 e2 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101da2:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101da7:	74 19                	je     f0101dc2 <mem_init+0xd35>
f0101da9:	68 aa 3d 10 f0       	push   $0xf0103daa
f0101dae:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0101db3:	68 6c 03 00 00       	push   $0x36c
=======
f0101db3:	68 4d 03 00 00       	push   $0x34d
>>>>>>> lab2
f0101db8:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0101dbd:	e8 c9 e2 ff ff       	call   f010008b <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101dc2:	6a 00                	push   $0x0
f0101dc4:	68 00 10 00 00       	push   $0x1000
f0101dc9:	53                   	push   %ebx
f0101dca:	57                   	push   %edi
f0101dcb:	e8 24 f2 ff ff       	call   f0100ff4 <page_insert>
f0101dd0:	83 c4 10             	add    $0x10,%esp
f0101dd3:	85 c0                	test   %eax,%eax
f0101dd5:	74 19                	je     f0101df0 <mem_init+0xd63>
f0101dd7:	68 a4 43 10 f0       	push   $0xf01043a4
f0101ddc:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0101de1:	68 6f 03 00 00       	push   $0x36f
=======
f0101de1:	68 50 03 00 00       	push   $0x350
>>>>>>> lab2
f0101de6:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0101deb:	e8 9b e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref);
f0101df0:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101df5:	75 19                	jne    f0101e10 <mem_init+0xd83>
f0101df7:	68 bb 3d 10 f0       	push   $0xf0103dbb
f0101dfc:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0101e01:	68 70 03 00 00       	push   $0x370
=======
f0101e01:	68 51 03 00 00       	push   $0x351
>>>>>>> lab2
f0101e06:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0101e0b:	e8 7b e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_link == NULL);
f0101e10:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101e13:	74 19                	je     f0101e2e <mem_init+0xda1>
f0101e15:	68 c7 3d 10 f0       	push   $0xf0103dc7
f0101e1a:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0101e1f:	68 71 03 00 00       	push   $0x371
=======
f0101e1f:	68 52 03 00 00       	push   $0x352
>>>>>>> lab2
f0101e24:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0101e29:	e8 5d e2 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101e2e:	83 ec 08             	sub    $0x8,%esp
f0101e31:	68 00 10 00 00       	push   $0x1000
f0101e36:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101e3c:	e8 78 f1 ff ff       	call   f0100fb9 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e41:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f0101e47:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e4c:	89 f8                	mov    %edi,%eax
f0101e4e:	e8 e9 ea ff ff       	call   f010093c <check_va2pa>
f0101e53:	83 c4 10             	add    $0x10,%esp
f0101e56:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e59:	74 19                	je     f0101e74 <mem_init+0xde7>
f0101e5b:	68 80 43 10 f0       	push   $0xf0104380
f0101e60:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0101e65:	68 75 03 00 00       	push   $0x375
=======
f0101e65:	68 56 03 00 00       	push   $0x356
>>>>>>> lab2
f0101e6a:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0101e6f:	e8 17 e2 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101e74:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e79:	89 f8                	mov    %edi,%eax
f0101e7b:	e8 bc ea ff ff       	call   f010093c <check_va2pa>
f0101e80:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e83:	74 19                	je     f0101e9e <mem_init+0xe11>
f0101e85:	68 dc 43 10 f0       	push   $0xf01043dc
f0101e8a:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0101e8f:	68 76 03 00 00       	push   $0x376
=======
f0101e8f:	68 57 03 00 00       	push   $0x357
>>>>>>> lab2
f0101e94:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0101e99:	e8 ed e1 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f0101e9e:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101ea3:	74 19                	je     f0101ebe <mem_init+0xe31>
f0101ea5:	68 dc 3d 10 f0       	push   $0xf0103ddc
f0101eaa:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0101eaf:	68 77 03 00 00       	push   $0x377
=======
f0101eaf:	68 58 03 00 00       	push   $0x358
>>>>>>> lab2
f0101eb4:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0101eb9:	e8 cd e1 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101ebe:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101ec3:	74 19                	je     f0101ede <mem_init+0xe51>
f0101ec5:	68 aa 3d 10 f0       	push   $0xf0103daa
f0101eca:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0101ecf:	68 78 03 00 00       	push   $0x378
=======
f0101ecf:	68 59 03 00 00       	push   $0x359
>>>>>>> lab2
f0101ed4:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0101ed9:	e8 ad e1 ff ff       	call   f010008b <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101ede:	83 ec 0c             	sub    $0xc,%esp
f0101ee1:	6a 00                	push   $0x0
f0101ee3:	e8 64 ee ff ff       	call   f0100d4c <page_alloc>
f0101ee8:	83 c4 10             	add    $0x10,%esp
f0101eeb:	39 c3                	cmp    %eax,%ebx
f0101eed:	75 04                	jne    f0101ef3 <mem_init+0xe66>
f0101eef:	85 c0                	test   %eax,%eax
f0101ef1:	75 19                	jne    f0101f0c <mem_init+0xe7f>
f0101ef3:	68 04 44 10 f0       	push   $0xf0104404
f0101ef8:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0101efd:	68 7b 03 00 00       	push   $0x37b
=======
f0101efd:	68 5c 03 00 00       	push   $0x35c
>>>>>>> lab2
f0101f02:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0101f07:	e8 7f e1 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101f0c:	83 ec 0c             	sub    $0xc,%esp
f0101f0f:	6a 00                	push   $0x0
f0101f11:	e8 36 ee ff ff       	call   f0100d4c <page_alloc>
f0101f16:	83 c4 10             	add    $0x10,%esp
f0101f19:	85 c0                	test   %eax,%eax
f0101f1b:	74 19                	je     f0101f36 <mem_init+0xea9>
f0101f1d:	68 fe 3c 10 f0       	push   $0xf0103cfe
f0101f22:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0101f27:	68 7e 03 00 00       	push   $0x37e
=======
f0101f27:	68 5f 03 00 00       	push   $0x35f
>>>>>>> lab2
f0101f2c:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0101f31:	e8 55 e1 ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101f36:	8b 0d 68 69 11 f0    	mov    0xf0116968,%ecx
f0101f3c:	8b 11                	mov    (%ecx),%edx
f0101f3e:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101f44:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f47:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0101f4d:	c1 f8 03             	sar    $0x3,%eax
f0101f50:	c1 e0 0c             	shl    $0xc,%eax
f0101f53:	39 c2                	cmp    %eax,%edx
f0101f55:	74 19                	je     f0101f70 <mem_init+0xee3>
f0101f57:	68 a8 40 10 f0       	push   $0xf01040a8
f0101f5c:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0101f61:	68 81 03 00 00       	push   $0x381
=======
f0101f61:	68 62 03 00 00       	push   $0x362
>>>>>>> lab2
f0101f66:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0101f6b:	e8 1b e1 ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f0101f70:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101f76:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f79:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101f7e:	74 19                	je     f0101f99 <mem_init+0xf0c>
f0101f80:	68 61 3d 10 f0       	push   $0xf0103d61
f0101f85:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0101f8a:	68 83 03 00 00       	push   $0x383
=======
f0101f8a:	68 64 03 00 00       	push   $0x364
>>>>>>> lab2
f0101f8f:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0101f94:	e8 f2 e0 ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f0101f99:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f9c:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101fa2:	83 ec 0c             	sub    $0xc,%esp
f0101fa5:	50                   	push   %eax
f0101fa6:	e8 11 ee ff ff       	call   f0100dbc <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101fab:	83 c4 0c             	add    $0xc,%esp
f0101fae:	6a 01                	push   $0x1
f0101fb0:	68 00 10 40 00       	push   $0x401000
f0101fb5:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101fbb:	e8 79 ee ff ff       	call   f0100e39 <pgdir_walk>
f0101fc0:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0101fc3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101fc6:	8b 0d 68 69 11 f0    	mov    0xf0116968,%ecx
f0101fcc:	8b 51 04             	mov    0x4(%ecx),%edx
f0101fcf:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101fd5:	8b 3d 64 69 11 f0    	mov    0xf0116964,%edi
f0101fdb:	89 d0                	mov    %edx,%eax
f0101fdd:	c1 e8 0c             	shr    $0xc,%eax
f0101fe0:	83 c4 10             	add    $0x10,%esp
f0101fe3:	39 f8                	cmp    %edi,%eax
f0101fe5:	72 15                	jb     f0101ffc <mem_init+0xf6f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101fe7:	52                   	push   %edx
f0101fe8:	68 68 3e 10 f0       	push   $0xf0103e68
<<<<<<< HEAD
f0101fed:	68 8a 03 00 00       	push   $0x38a
=======
f0101fed:	68 6b 03 00 00       	push   $0x36b
>>>>>>> lab2
f0101ff2:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0101ff7:	e8 8f e0 ff ff       	call   f010008b <_panic>
	assert(ptep == ptep1 + PTX(va));
f0101ffc:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f0102002:	39 55 c8             	cmp    %edx,-0x38(%ebp)
f0102005:	74 19                	je     f0102020 <mem_init+0xf93>
f0102007:	68 ed 3d 10 f0       	push   $0xf0103ded
f010200c:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0102011:	68 8b 03 00 00       	push   $0x38b
=======
f0102011:	68 6c 03 00 00       	push   $0x36c
>>>>>>> lab2
f0102016:	68 5e 3b 10 f0       	push   $0xf0103b5e
f010201b:	e8 6b e0 ff ff       	call   f010008b <_panic>
	kern_pgdir[PDX(va)] = 0;
f0102020:	c7 41 04 00 00 00 00 	movl   $0x0,0x4(%ecx)
	pp0->pp_ref = 0;
f0102027:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010202a:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102030:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0102036:	c1 f8 03             	sar    $0x3,%eax
f0102039:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010203c:	89 c2                	mov    %eax,%edx
f010203e:	c1 ea 0c             	shr    $0xc,%edx
f0102041:	39 d7                	cmp    %edx,%edi
f0102043:	77 12                	ja     f0102057 <mem_init+0xfca>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102045:	50                   	push   %eax
f0102046:	68 68 3e 10 f0       	push   $0xf0103e68
f010204b:	6a 52                	push   $0x52
f010204d:	68 6a 3b 10 f0       	push   $0xf0103b6a
f0102052:	e8 34 e0 ff ff       	call   f010008b <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102057:	83 ec 04             	sub    $0x4,%esp
f010205a:	68 00 10 00 00       	push   $0x1000
f010205f:	68 ff 00 00 00       	push   $0xff
f0102064:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102069:	50                   	push   %eax
f010206a:	e8 76 11 00 00       	call   f01031e5 <memset>
	page_free(pp0);
f010206f:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102072:	89 3c 24             	mov    %edi,(%esp)
f0102075:	e8 42 ed ff ff       	call   f0100dbc <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f010207a:	83 c4 0c             	add    $0xc,%esp
f010207d:	6a 01                	push   $0x1
f010207f:	6a 00                	push   $0x0
f0102081:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0102087:	e8 ad ed ff ff       	call   f0100e39 <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010208c:	89 fa                	mov    %edi,%edx
f010208e:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f0102094:	c1 fa 03             	sar    $0x3,%edx
f0102097:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010209a:	89 d0                	mov    %edx,%eax
f010209c:	c1 e8 0c             	shr    $0xc,%eax
f010209f:	83 c4 10             	add    $0x10,%esp
f01020a2:	3b 05 64 69 11 f0    	cmp    0xf0116964,%eax
f01020a8:	72 12                	jb     f01020bc <mem_init+0x102f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01020aa:	52                   	push   %edx
f01020ab:	68 68 3e 10 f0       	push   $0xf0103e68
f01020b0:	6a 52                	push   $0x52
f01020b2:	68 6a 3b 10 f0       	push   $0xf0103b6a
f01020b7:	e8 cf df ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f01020bc:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f01020c2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01020c5:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01020cb:	f6 00 01             	testb  $0x1,(%eax)
f01020ce:	74 19                	je     f01020e9 <mem_init+0x105c>
f01020d0:	68 05 3e 10 f0       	push   $0xf0103e05
f01020d5:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f01020da:	68 95 03 00 00       	push   $0x395
=======
f01020da:	68 76 03 00 00       	push   $0x376
>>>>>>> lab2
f01020df:	68 5e 3b 10 f0       	push   $0xf0103b5e
f01020e4:	e8 a2 df ff ff       	call   f010008b <_panic>
f01020e9:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f01020ec:	39 d0                	cmp    %edx,%eax
f01020ee:	75 db                	jne    f01020cb <mem_init+0x103e>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01020f0:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f01020f5:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01020fb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020fe:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102104:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102107:	89 0d 3c 65 11 f0    	mov    %ecx,0xf011653c

	// free the pages we took
	page_free(pp0);
f010210d:	83 ec 0c             	sub    $0xc,%esp
f0102110:	50                   	push   %eax
f0102111:	e8 a6 ec ff ff       	call   f0100dbc <page_free>
	page_free(pp1);
f0102116:	89 1c 24             	mov    %ebx,(%esp)
f0102119:	e8 9e ec ff ff       	call   f0100dbc <page_free>
	page_free(pp2);
f010211e:	89 34 24             	mov    %esi,(%esp)
f0102121:	e8 96 ec ff ff       	call   f0100dbc <page_free>

	cprintf("check_page() succeeded!\n");
f0102126:	c7 04 24 1c 3e 10 f0 	movl   $0xf0103e1c,(%esp)
f010212d:	e8 49 06 00 00       	call   f010277b <cprintf>
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
<<<<<<< HEAD
	//这里将内核页表映射到用户只读的线性地址UPAGES处，大小为页表总大小
=======
	//              内核字典  虚拟地址 映射大小  页表物理地址 权限为PTE_U|PTE_P
>>>>>>> lab2
	boot_map_region(kern_pgdir, UPAGES, PageInfo_Size, PADDR(pages), (PTE_U|PTE_P));
f0102132:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102137:	83 c4 10             	add    $0x10,%esp
f010213a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010213f:	77 15                	ja     f0102156 <mem_init+0x10c9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102141:	50                   	push   %eax
f0102142:	68 ac 3f 10 f0       	push   $0xf0103fac
<<<<<<< HEAD
f0102147:	68 bd 00 00 00       	push   $0xbd
=======
f0102147:	68 b8 00 00 00       	push   $0xb8
>>>>>>> lab2
f010214c:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0102151:	e8 35 df ff ff       	call   f010008b <_panic>
f0102156:	83 ec 08             	sub    $0x8,%esp
f0102159:	6a 05                	push   $0x5
f010215b:	05 00 00 00 10       	add    $0x10000000,%eax
f0102160:	50                   	push   %eax
f0102161:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102164:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102169:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f010216e:	e8 8e ed ff ff       	call   f0100f01 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102173:	83 c4 10             	add    $0x10,%esp
f0102176:	b8 00 c0 10 f0       	mov    $0xf010c000,%eax
f010217b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102180:	77 15                	ja     f0102197 <mem_init+0x110a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102182:	50                   	push   %eax
f0102183:	68 ac 3f 10 f0       	push   $0xf0103fac
<<<<<<< HEAD
f0102188:	68 cb 00 00 00       	push   $0xcb
f010218d:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0102192:	e8 f4 de ff ff       	call   f010008b <_panic>
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	//映射的范围：* [KSTACKTOP-KSTKSIZE, KSTACKTOP)
	//内核页表映射到栈地址，内核栈从虚拟地址KSTACKTOP开始向下增长
=======
f0102188:	68 c5 00 00 00       	push   $0xc5
f010218d:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0102192:	e8 f4 de ff ff       	call   f010008b <_panic>
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	//内核地址映射到栈地址，内核栈从虚拟地址KSTACKTOP开始向下增长
>>>>>>> lab2
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), (PTE_W|PTE_P));
f0102197:	83 ec 08             	sub    $0x8,%esp
f010219a:	6a 03                	push   $0x3
f010219c:	68 00 c0 10 00       	push   $0x10c000
f01021a1:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01021a6:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01021ab:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f01021b0:	e8 4c ed ff ff       	call   f0100f01 <boot_map_region>
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	//将KERNBASE所有的物理内存从虚拟地址[KERNBASE, 2^32)映射到物理地址[0, 2^32 - KERNBASE)
	boot_map_region(kern_pgdir, KERNBASE, (0xffffffff-KERNBASE), 0, (PTE_W|PTE_P));
f01021b5:	83 c4 08             	add    $0x8,%esp
f01021b8:	6a 03                	push   $0x3
f01021ba:	6a 00                	push   $0x0
f01021bc:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f01021c1:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01021c6:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f01021cb:	e8 31 ed ff ff       	call   f0100f01 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01021d0:	8b 35 68 69 11 f0    	mov    0xf0116968,%esi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01021d6:	a1 64 69 11 f0       	mov    0xf0116964,%eax
f01021db:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01021de:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01021e5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01021ea:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01021ed:	8b 3d 6c 69 11 f0    	mov    0xf011696c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01021f3:	89 7d d0             	mov    %edi,-0x30(%ebp)
f01021f6:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01021f9:	bb 00 00 00 00       	mov    $0x0,%ebx
f01021fe:	eb 55                	jmp    f0102255 <mem_init+0x11c8>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102200:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f0102206:	89 f0                	mov    %esi,%eax
f0102208:	e8 2f e7 ff ff       	call   f010093c <check_va2pa>
f010220d:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f0102214:	77 15                	ja     f010222b <mem_init+0x119e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102216:	57                   	push   %edi
f0102217:	68 ac 3f 10 f0       	push   $0xf0103fac
<<<<<<< HEAD
f010221c:	68 d7 02 00 00       	push   $0x2d7
=======
f010221c:	68 b8 02 00 00       	push   $0x2b8
>>>>>>> lab2
f0102221:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0102226:	e8 60 de ff ff       	call   f010008b <_panic>
f010222b:	8d 94 1f 00 00 00 10 	lea    0x10000000(%edi,%ebx,1),%edx
f0102232:	39 c2                	cmp    %eax,%edx
f0102234:	74 19                	je     f010224f <mem_init+0x11c2>
f0102236:	68 28 44 10 f0       	push   $0xf0104428
f010223b:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0102240:	68 d7 02 00 00       	push   $0x2d7
=======
f0102240:	68 b8 02 00 00       	push   $0x2b8
>>>>>>> lab2
f0102245:	68 5e 3b 10 f0       	push   $0xf0103b5e
f010224a:	e8 3c de ff ff       	call   f010008b <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010224f:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102255:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0102258:	77 a6                	ja     f0102200 <mem_init+0x1173>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010225a:	8b 7d cc             	mov    -0x34(%ebp),%edi
f010225d:	c1 e7 0c             	shl    $0xc,%edi
f0102260:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102265:	eb 30                	jmp    f0102297 <mem_init+0x120a>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102267:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f010226d:	89 f0                	mov    %esi,%eax
f010226f:	e8 c8 e6 ff ff       	call   f010093c <check_va2pa>
f0102274:	39 c3                	cmp    %eax,%ebx
f0102276:	74 19                	je     f0102291 <mem_init+0x1204>
f0102278:	68 5c 44 10 f0       	push   $0xf010445c
f010227d:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0102282:	68 dc 02 00 00       	push   $0x2dc
=======
f0102282:	68 bd 02 00 00       	push   $0x2bd
>>>>>>> lab2
f0102287:	68 5e 3b 10 f0       	push   $0xf0103b5e
f010228c:	e8 fa dd ff ff       	call   f010008b <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102291:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102297:	39 fb                	cmp    %edi,%ebx
f0102299:	72 cc                	jb     f0102267 <mem_init+0x11da>
f010229b:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01022a0:	89 da                	mov    %ebx,%edx
f01022a2:	89 f0                	mov    %esi,%eax
f01022a4:	e8 93 e6 ff ff       	call   f010093c <check_va2pa>
f01022a9:	8d 93 00 40 11 10    	lea    0x10114000(%ebx),%edx
f01022af:	39 c2                	cmp    %eax,%edx
f01022b1:	74 19                	je     f01022cc <mem_init+0x123f>
f01022b3:	68 84 44 10 f0       	push   $0xf0104484
f01022b8:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f01022bd:	68 e0 02 00 00       	push   $0x2e0
=======
f01022bd:	68 c1 02 00 00       	push   $0x2c1
>>>>>>> lab2
f01022c2:	68 5e 3b 10 f0       	push   $0xf0103b5e
f01022c7:	e8 bf dd ff ff       	call   f010008b <_panic>
f01022cc:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01022d2:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f01022d8:	75 c6                	jne    f01022a0 <mem_init+0x1213>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01022da:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f01022df:	89 f0                	mov    %esi,%eax
f01022e1:	e8 56 e6 ff ff       	call   f010093c <check_va2pa>
f01022e6:	83 f8 ff             	cmp    $0xffffffff,%eax
f01022e9:	74 51                	je     f010233c <mem_init+0x12af>
f01022eb:	68 cc 44 10 f0       	push   $0xf01044cc
f01022f0:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f01022f5:	68 e1 02 00 00       	push   $0x2e1
=======
f01022f5:	68 c2 02 00 00       	push   $0x2c2
>>>>>>> lab2
f01022fa:	68 5e 3b 10 f0       	push   $0xf0103b5e
f01022ff:	e8 87 dd ff ff       	call   f010008b <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102304:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f0102309:	72 36                	jb     f0102341 <mem_init+0x12b4>
f010230b:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102310:	76 07                	jbe    f0102319 <mem_init+0x128c>
f0102312:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102317:	75 28                	jne    f0102341 <mem_init+0x12b4>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f0102319:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f010231d:	0f 85 83 00 00 00    	jne    f01023a6 <mem_init+0x1319>
f0102323:	68 35 3e 10 f0       	push   $0xf0103e35
f0102328:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f010232d:	68 e9 02 00 00       	push   $0x2e9
=======
f010232d:	68 ca 02 00 00       	push   $0x2ca
>>>>>>> lab2
f0102332:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0102337:	e8 4f dd ff ff       	call   f010008b <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f010233c:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102341:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102346:	76 3f                	jbe    f0102387 <mem_init+0x12fa>
				assert(pgdir[i] & PTE_P);
f0102348:	8b 14 86             	mov    (%esi,%eax,4),%edx
f010234b:	f6 c2 01             	test   $0x1,%dl
f010234e:	75 19                	jne    f0102369 <mem_init+0x12dc>
f0102350:	68 35 3e 10 f0       	push   $0xf0103e35
f0102355:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f010235a:	68 ed 02 00 00       	push   $0x2ed
=======
f010235a:	68 ce 02 00 00       	push   $0x2ce
>>>>>>> lab2
f010235f:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0102364:	e8 22 dd ff ff       	call   f010008b <_panic>
				assert(pgdir[i] & PTE_W);
f0102369:	f6 c2 02             	test   $0x2,%dl
f010236c:	75 38                	jne    f01023a6 <mem_init+0x1319>
f010236e:	68 46 3e 10 f0       	push   $0xf0103e46
f0102373:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0102378:	68 ee 02 00 00       	push   $0x2ee
=======
f0102378:	68 cf 02 00 00       	push   $0x2cf
>>>>>>> lab2
f010237d:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0102382:	e8 04 dd ff ff       	call   f010008b <_panic>
			} else
				assert(pgdir[i] == 0);
f0102387:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f010238b:	74 19                	je     f01023a6 <mem_init+0x1319>
f010238d:	68 57 3e 10 f0       	push   $0xf0103e57
f0102392:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0102397:	68 f0 02 00 00       	push   $0x2f0
=======
f0102397:	68 d1 02 00 00       	push   $0x2d1
>>>>>>> lab2
f010239c:	68 5e 3b 10 f0       	push   $0xf0103b5e
f01023a1:	e8 e5 dc ff ff       	call   f010008b <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f01023a6:	83 c0 01             	add    $0x1,%eax
f01023a9:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f01023ae:	0f 86 50 ff ff ff    	jbe    f0102304 <mem_init+0x1277>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f01023b4:	83 ec 0c             	sub    $0xc,%esp
f01023b7:	68 fc 44 10 f0       	push   $0xf01044fc
f01023bc:	e8 ba 03 00 00       	call   f010277b <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01023c1:	a1 68 69 11 f0       	mov    0xf0116968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01023c6:	83 c4 10             	add    $0x10,%esp
f01023c9:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01023ce:	77 15                	ja     f01023e5 <mem_init+0x1358>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01023d0:	50                   	push   %eax
f01023d1:	68 ac 3f 10 f0       	push   $0xf0103fac
<<<<<<< HEAD
f01023d6:	68 e0 00 00 00       	push   $0xe0
=======
f01023d6:	68 da 00 00 00       	push   $0xda
>>>>>>> lab2
f01023db:	68 5e 3b 10 f0       	push   $0xf0103b5e
f01023e0:	e8 a6 dc ff ff       	call   f010008b <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01023e5:	05 00 00 00 10       	add    $0x10000000,%eax
f01023ea:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01023ed:	b8 00 00 00 00       	mov    $0x0,%eax
f01023f2:	e8 a9 e5 ff ff       	call   f01009a0 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f01023f7:	0f 20 c0             	mov    %cr0,%eax
f01023fa:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f01023fd:	0d 23 00 05 80       	or     $0x80050023,%eax
f0102402:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102405:	83 ec 0c             	sub    $0xc,%esp
f0102408:	6a 00                	push   $0x0
f010240a:	e8 3d e9 ff ff       	call   f0100d4c <page_alloc>
f010240f:	89 c3                	mov    %eax,%ebx
f0102411:	83 c4 10             	add    $0x10,%esp
f0102414:	85 c0                	test   %eax,%eax
f0102416:	75 19                	jne    f0102431 <mem_init+0x13a4>
f0102418:	68 53 3c 10 f0       	push   $0xf0103c53
f010241d:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0102422:	68 b0 03 00 00       	push   $0x3b0
=======
f0102422:	68 91 03 00 00       	push   $0x391
>>>>>>> lab2
f0102427:	68 5e 3b 10 f0       	push   $0xf0103b5e
f010242c:	e8 5a dc ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0102431:	83 ec 0c             	sub    $0xc,%esp
f0102434:	6a 00                	push   $0x0
f0102436:	e8 11 e9 ff ff       	call   f0100d4c <page_alloc>
f010243b:	89 c7                	mov    %eax,%edi
f010243d:	83 c4 10             	add    $0x10,%esp
f0102440:	85 c0                	test   %eax,%eax
f0102442:	75 19                	jne    f010245d <mem_init+0x13d0>
f0102444:	68 69 3c 10 f0       	push   $0xf0103c69
f0102449:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f010244e:	68 b1 03 00 00       	push   $0x3b1
=======
f010244e:	68 92 03 00 00       	push   $0x392
>>>>>>> lab2
f0102453:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0102458:	e8 2e dc ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f010245d:	83 ec 0c             	sub    $0xc,%esp
f0102460:	6a 00                	push   $0x0
f0102462:	e8 e5 e8 ff ff       	call   f0100d4c <page_alloc>
f0102467:	89 c6                	mov    %eax,%esi
f0102469:	83 c4 10             	add    $0x10,%esp
f010246c:	85 c0                	test   %eax,%eax
f010246e:	75 19                	jne    f0102489 <mem_init+0x13fc>
f0102470:	68 7f 3c 10 f0       	push   $0xf0103c7f
f0102475:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f010247a:	68 b2 03 00 00       	push   $0x3b2
=======
f010247a:	68 93 03 00 00       	push   $0x393
>>>>>>> lab2
f010247f:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0102484:	e8 02 dc ff ff       	call   f010008b <_panic>
	page_free(pp0);
f0102489:	83 ec 0c             	sub    $0xc,%esp
f010248c:	53                   	push   %ebx
f010248d:	e8 2a e9 ff ff       	call   f0100dbc <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102492:	89 f8                	mov    %edi,%eax
f0102494:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f010249a:	c1 f8 03             	sar    $0x3,%eax
f010249d:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01024a0:	89 c2                	mov    %eax,%edx
f01024a2:	c1 ea 0c             	shr    $0xc,%edx
f01024a5:	83 c4 10             	add    $0x10,%esp
f01024a8:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f01024ae:	72 12                	jb     f01024c2 <mem_init+0x1435>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01024b0:	50                   	push   %eax
f01024b1:	68 68 3e 10 f0       	push   $0xf0103e68
f01024b6:	6a 52                	push   $0x52
f01024b8:	68 6a 3b 10 f0       	push   $0xf0103b6a
f01024bd:	e8 c9 db ff ff       	call   f010008b <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f01024c2:	83 ec 04             	sub    $0x4,%esp
f01024c5:	68 00 10 00 00       	push   $0x1000
f01024ca:	6a 01                	push   $0x1
f01024cc:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01024d1:	50                   	push   %eax
f01024d2:	e8 0e 0d 00 00       	call   f01031e5 <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01024d7:	89 f0                	mov    %esi,%eax
f01024d9:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f01024df:	c1 f8 03             	sar    $0x3,%eax
f01024e2:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01024e5:	89 c2                	mov    %eax,%edx
f01024e7:	c1 ea 0c             	shr    $0xc,%edx
f01024ea:	83 c4 10             	add    $0x10,%esp
f01024ed:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f01024f3:	72 12                	jb     f0102507 <mem_init+0x147a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01024f5:	50                   	push   %eax
f01024f6:	68 68 3e 10 f0       	push   $0xf0103e68
f01024fb:	6a 52                	push   $0x52
f01024fd:	68 6a 3b 10 f0       	push   $0xf0103b6a
f0102502:	e8 84 db ff ff       	call   f010008b <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102507:	83 ec 04             	sub    $0x4,%esp
f010250a:	68 00 10 00 00       	push   $0x1000
f010250f:	6a 02                	push   $0x2
f0102511:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102516:	50                   	push   %eax
f0102517:	e8 c9 0c 00 00       	call   f01031e5 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f010251c:	6a 02                	push   $0x2
f010251e:	68 00 10 00 00       	push   $0x1000
f0102523:	57                   	push   %edi
f0102524:	ff 35 68 69 11 f0    	pushl  0xf0116968
f010252a:	e8 c5 ea ff ff       	call   f0100ff4 <page_insert>
	assert(pp1->pp_ref == 1);
f010252f:	83 c4 20             	add    $0x20,%esp
f0102532:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102537:	74 19                	je     f0102552 <mem_init+0x14c5>
f0102539:	68 50 3d 10 f0       	push   $0xf0103d50
f010253e:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0102543:	68 b7 03 00 00       	push   $0x3b7
=======
f0102543:	68 98 03 00 00       	push   $0x398
>>>>>>> lab2
f0102548:	68 5e 3b 10 f0       	push   $0xf0103b5e
f010254d:	e8 39 db ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102552:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102559:	01 01 01 
f010255c:	74 19                	je     f0102577 <mem_init+0x14ea>
f010255e:	68 1c 45 10 f0       	push   $0xf010451c
f0102563:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0102568:	68 b8 03 00 00       	push   $0x3b8
=======
f0102568:	68 99 03 00 00       	push   $0x399
>>>>>>> lab2
f010256d:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0102572:	e8 14 db ff ff       	call   f010008b <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102577:	6a 02                	push   $0x2
f0102579:	68 00 10 00 00       	push   $0x1000
f010257e:	56                   	push   %esi
f010257f:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0102585:	e8 6a ea ff ff       	call   f0100ff4 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f010258a:	83 c4 10             	add    $0x10,%esp
f010258d:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102594:	02 02 02 
f0102597:	74 19                	je     f01025b2 <mem_init+0x1525>
f0102599:	68 40 45 10 f0       	push   $0xf0104540
f010259e:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f01025a3:	68 ba 03 00 00       	push   $0x3ba
=======
f01025a3:	68 9b 03 00 00       	push   $0x39b
>>>>>>> lab2
f01025a8:	68 5e 3b 10 f0       	push   $0xf0103b5e
f01025ad:	e8 d9 da ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01025b2:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01025b7:	74 19                	je     f01025d2 <mem_init+0x1545>
f01025b9:	68 72 3d 10 f0       	push   $0xf0103d72
f01025be:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f01025c3:	68 bb 03 00 00       	push   $0x3bb
=======
f01025c3:	68 9c 03 00 00       	push   $0x39c
>>>>>>> lab2
f01025c8:	68 5e 3b 10 f0       	push   $0xf0103b5e
f01025cd:	e8 b9 da ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f01025d2:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01025d7:	74 19                	je     f01025f2 <mem_init+0x1565>
f01025d9:	68 dc 3d 10 f0       	push   $0xf0103ddc
f01025de:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f01025e3:	68 bc 03 00 00       	push   $0x3bc
=======
f01025e3:	68 9d 03 00 00       	push   $0x39d
>>>>>>> lab2
f01025e8:	68 5e 3b 10 f0       	push   $0xf0103b5e
f01025ed:	e8 99 da ff ff       	call   f010008b <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f01025f2:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f01025f9:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01025fc:	89 f0                	mov    %esi,%eax
f01025fe:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0102604:	c1 f8 03             	sar    $0x3,%eax
f0102607:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010260a:	89 c2                	mov    %eax,%edx
f010260c:	c1 ea 0c             	shr    $0xc,%edx
f010260f:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0102615:	72 12                	jb     f0102629 <mem_init+0x159c>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102617:	50                   	push   %eax
f0102618:	68 68 3e 10 f0       	push   $0xf0103e68
f010261d:	6a 52                	push   $0x52
f010261f:	68 6a 3b 10 f0       	push   $0xf0103b6a
f0102624:	e8 62 da ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102629:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102630:	03 03 03 
f0102633:	74 19                	je     f010264e <mem_init+0x15c1>
f0102635:	68 64 45 10 f0       	push   $0xf0104564
f010263a:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f010263f:	68 be 03 00 00       	push   $0x3be
=======
f010263f:	68 9f 03 00 00       	push   $0x39f
>>>>>>> lab2
f0102644:	68 5e 3b 10 f0       	push   $0xf0103b5e
f0102649:	e8 3d da ff ff       	call   f010008b <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f010264e:	83 ec 08             	sub    $0x8,%esp
f0102651:	68 00 10 00 00       	push   $0x1000
f0102656:	ff 35 68 69 11 f0    	pushl  0xf0116968
f010265c:	e8 58 e9 ff ff       	call   f0100fb9 <page_remove>
	assert(pp2->pp_ref == 0);
f0102661:	83 c4 10             	add    $0x10,%esp
f0102664:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102669:	74 19                	je     f0102684 <mem_init+0x15f7>
f010266b:	68 aa 3d 10 f0       	push   $0xf0103daa
f0102670:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f0102675:	68 c0 03 00 00       	push   $0x3c0
=======
f0102675:	68 a1 03 00 00       	push   $0x3a1
>>>>>>> lab2
f010267a:	68 5e 3b 10 f0       	push   $0xf0103b5e
f010267f:	e8 07 da ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102684:	8b 0d 68 69 11 f0    	mov    0xf0116968,%ecx
f010268a:	8b 11                	mov    (%ecx),%edx
f010268c:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102692:	89 d8                	mov    %ebx,%eax
f0102694:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f010269a:	c1 f8 03             	sar    $0x3,%eax
f010269d:	c1 e0 0c             	shl    $0xc,%eax
f01026a0:	39 c2                	cmp    %eax,%edx
f01026a2:	74 19                	je     f01026bd <mem_init+0x1630>
f01026a4:	68 a8 40 10 f0       	push   $0xf01040a8
f01026a9:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f01026ae:	68 c3 03 00 00       	push   $0x3c3
=======
f01026ae:	68 a4 03 00 00       	push   $0x3a4
>>>>>>> lab2
f01026b3:	68 5e 3b 10 f0       	push   $0xf0103b5e
f01026b8:	e8 ce d9 ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f01026bd:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f01026c3:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01026c8:	74 19                	je     f01026e3 <mem_init+0x1656>
f01026ca:	68 61 3d 10 f0       	push   $0xf0103d61
f01026cf:	68 84 3b 10 f0       	push   $0xf0103b84
<<<<<<< HEAD
f01026d4:	68 c5 03 00 00       	push   $0x3c5
=======
f01026d4:	68 a6 03 00 00       	push   $0x3a6
>>>>>>> lab2
f01026d9:	68 5e 3b 10 f0       	push   $0xf0103b5e
f01026de:	e8 a8 d9 ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f01026e3:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f01026e9:	83 ec 0c             	sub    $0xc,%esp
f01026ec:	53                   	push   %ebx
f01026ed:	e8 ca e6 ff ff       	call   f0100dbc <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f01026f2:	c7 04 24 90 45 10 f0 	movl   $0xf0104590,(%esp)
f01026f9:	e8 7d 00 00 00       	call   f010277b <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f01026fe:	83 c4 10             	add    $0x10,%esp
f0102701:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102704:	5b                   	pop    %ebx
f0102705:	5e                   	pop    %esi
f0102706:	5f                   	pop    %edi
f0102707:	5d                   	pop    %ebp
f0102708:	c3                   	ret    

f0102709 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0102709:	55                   	push   %ebp
f010270a:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010270c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010270f:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0102712:	5d                   	pop    %ebp
f0102713:	c3                   	ret    

f0102714 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102714:	55                   	push   %ebp
f0102715:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102717:	ba 70 00 00 00       	mov    $0x70,%edx
f010271c:	8b 45 08             	mov    0x8(%ebp),%eax
f010271f:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102720:	ba 71 00 00 00       	mov    $0x71,%edx
f0102725:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102726:	0f b6 c0             	movzbl %al,%eax
}
f0102729:	5d                   	pop    %ebp
f010272a:	c3                   	ret    

f010272b <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f010272b:	55                   	push   %ebp
f010272c:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010272e:	ba 70 00 00 00       	mov    $0x70,%edx
f0102733:	8b 45 08             	mov    0x8(%ebp),%eax
f0102736:	ee                   	out    %al,(%dx)
f0102737:	ba 71 00 00 00       	mov    $0x71,%edx
f010273c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010273f:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102740:	5d                   	pop    %ebp
f0102741:	c3                   	ret    

f0102742 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102742:	55                   	push   %ebp
f0102743:	89 e5                	mov    %esp,%ebp
f0102745:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0102748:	ff 75 08             	pushl  0x8(%ebp)
f010274b:	e8 a2 de ff ff       	call   f01005f2 <cputchar>
	*cnt++;
}
f0102750:	83 c4 10             	add    $0x10,%esp
f0102753:	c9                   	leave  
f0102754:	c3                   	ret    

f0102755 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102755:	55                   	push   %ebp
f0102756:	89 e5                	mov    %esp,%ebp
f0102758:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f010275b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102762:	ff 75 0c             	pushl  0xc(%ebp)
f0102765:	ff 75 08             	pushl  0x8(%ebp)
f0102768:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010276b:	50                   	push   %eax
f010276c:	68 42 27 10 f0       	push   $0xf0102742
f0102771:	e8 03 04 00 00       	call   f0102b79 <vprintfmt>
	return cnt;
}
f0102776:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102779:	c9                   	leave  
f010277a:	c3                   	ret    

f010277b <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010277b:	55                   	push   %ebp
f010277c:	89 e5                	mov    %esp,%ebp
f010277e:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102781:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102784:	50                   	push   %eax
f0102785:	ff 75 08             	pushl  0x8(%ebp)
f0102788:	e8 c8 ff ff ff       	call   f0102755 <vcprintf>
	va_end(ap);

	return cnt;
}
f010278d:	c9                   	leave  
f010278e:	c3                   	ret    

f010278f <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010278f:	55                   	push   %ebp
f0102790:	89 e5                	mov    %esp,%ebp
f0102792:	57                   	push   %edi
f0102793:	56                   	push   %esi
f0102794:	53                   	push   %ebx
f0102795:	83 ec 14             	sub    $0x14,%esp
f0102798:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010279b:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010279e:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01027a1:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01027a4:	8b 1a                	mov    (%edx),%ebx
f01027a6:	8b 01                	mov    (%ecx),%eax
f01027a8:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01027ab:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01027b2:	eb 7f                	jmp    f0102833 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01027b4:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01027b7:	01 d8                	add    %ebx,%eax
f01027b9:	89 c6                	mov    %eax,%esi
f01027bb:	c1 ee 1f             	shr    $0x1f,%esi
f01027be:	01 c6                	add    %eax,%esi
f01027c0:	d1 fe                	sar    %esi
f01027c2:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01027c5:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01027c8:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01027cb:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01027cd:	eb 03                	jmp    f01027d2 <stab_binsearch+0x43>
			m--;
f01027cf:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01027d2:	39 c3                	cmp    %eax,%ebx
f01027d4:	7f 0d                	jg     f01027e3 <stab_binsearch+0x54>
f01027d6:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01027da:	83 ea 0c             	sub    $0xc,%edx
f01027dd:	39 f9                	cmp    %edi,%ecx
f01027df:	75 ee                	jne    f01027cf <stab_binsearch+0x40>
f01027e1:	eb 05                	jmp    f01027e8 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01027e3:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01027e6:	eb 4b                	jmp    f0102833 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01027e8:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01027eb:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01027ee:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01027f2:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01027f5:	76 11                	jbe    f0102808 <stab_binsearch+0x79>
			*region_left = m;
f01027f7:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01027fa:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01027fc:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01027ff:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102806:	eb 2b                	jmp    f0102833 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0102808:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010280b:	73 14                	jae    f0102821 <stab_binsearch+0x92>
			*region_right = m - 1;
f010280d:	83 e8 01             	sub    $0x1,%eax
f0102810:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102813:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0102816:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102818:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010281f:	eb 12                	jmp    f0102833 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0102821:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102824:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0102826:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f010282a:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010282c:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0102833:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0102836:	0f 8e 78 ff ff ff    	jle    f01027b4 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f010283c:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0102840:	75 0f                	jne    f0102851 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0102842:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102845:	8b 00                	mov    (%eax),%eax
f0102847:	83 e8 01             	sub    $0x1,%eax
f010284a:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010284d:	89 06                	mov    %eax,(%esi)
f010284f:	eb 2c                	jmp    f010287d <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102851:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102854:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102856:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102859:	8b 0e                	mov    (%esi),%ecx
f010285b:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010285e:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0102861:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102864:	eb 03                	jmp    f0102869 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102866:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102869:	39 c8                	cmp    %ecx,%eax
f010286b:	7e 0b                	jle    f0102878 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f010286d:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0102871:	83 ea 0c             	sub    $0xc,%edx
f0102874:	39 df                	cmp    %ebx,%edi
f0102876:	75 ee                	jne    f0102866 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0102878:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010287b:	89 06                	mov    %eax,(%esi)
	}
}
f010287d:	83 c4 14             	add    $0x14,%esp
f0102880:	5b                   	pop    %ebx
f0102881:	5e                   	pop    %esi
f0102882:	5f                   	pop    %edi
f0102883:	5d                   	pop    %ebp
f0102884:	c3                   	ret    

f0102885 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102885:	55                   	push   %ebp
f0102886:	89 e5                	mov    %esp,%ebp
f0102888:	57                   	push   %edi
f0102889:	56                   	push   %esi
f010288a:	53                   	push   %ebx
f010288b:	83 ec 1c             	sub    $0x1c,%esp
f010288e:	8b 7d 08             	mov    0x8(%ebp),%edi
f0102891:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102894:	c7 06 bc 45 10 f0    	movl   $0xf01045bc,(%esi)
	info->eip_line = 0;
f010289a:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f01028a1:	c7 46 08 bc 45 10 f0 	movl   $0xf01045bc,0x8(%esi)
	info->eip_fn_namelen = 9;
f01028a8:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f01028af:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f01028b2:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01028b9:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f01028bf:	76 11                	jbe    f01028d2 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01028c1:	b8 fd be 10 f0       	mov    $0xf010befd,%eax
f01028c6:	3d 49 a1 10 f0       	cmp    $0xf010a149,%eax
f01028cb:	77 19                	ja     f01028e6 <debuginfo_eip+0x61>
f01028cd:	e9 62 01 00 00       	jmp    f0102a34 <debuginfo_eip+0x1af>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f01028d2:	83 ec 04             	sub    $0x4,%esp
f01028d5:	68 c6 45 10 f0       	push   $0xf01045c6
f01028da:	6a 7f                	push   $0x7f
f01028dc:	68 d3 45 10 f0       	push   $0xf01045d3
f01028e1:	e8 a5 d7 ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01028e6:	80 3d fc be 10 f0 00 	cmpb   $0x0,0xf010befc
f01028ed:	0f 85 48 01 00 00    	jne    f0102a3b <debuginfo_eip+0x1b6>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01028f3:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01028fa:	b8 48 a1 10 f0       	mov    $0xf010a148,%eax
f01028ff:	2d f0 47 10 f0       	sub    $0xf01047f0,%eax
f0102904:	c1 f8 02             	sar    $0x2,%eax
f0102907:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f010290d:	83 e8 01             	sub    $0x1,%eax
f0102910:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0102913:	83 ec 08             	sub    $0x8,%esp
f0102916:	57                   	push   %edi
f0102917:	6a 64                	push   $0x64
f0102919:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f010291c:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f010291f:	b8 f0 47 10 f0       	mov    $0xf01047f0,%eax
f0102924:	e8 66 fe ff ff       	call   f010278f <stab_binsearch>
	if (lfile == 0)
f0102929:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010292c:	83 c4 10             	add    $0x10,%esp
f010292f:	85 c0                	test   %eax,%eax
f0102931:	0f 84 0b 01 00 00    	je     f0102a42 <debuginfo_eip+0x1bd>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0102937:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f010293a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010293d:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0102940:	83 ec 08             	sub    $0x8,%esp
f0102943:	57                   	push   %edi
f0102944:	6a 24                	push   $0x24
f0102946:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0102949:	8d 55 dc             	lea    -0x24(%ebp),%edx
f010294c:	b8 f0 47 10 f0       	mov    $0xf01047f0,%eax
f0102951:	e8 39 fe ff ff       	call   f010278f <stab_binsearch>

	if (lfun <= rfun) {
f0102956:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0102959:	83 c4 10             	add    $0x10,%esp
f010295c:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f010295f:	7f 31                	jg     f0102992 <debuginfo_eip+0x10d>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0102961:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0102964:	c1 e0 02             	shl    $0x2,%eax
f0102967:	8d 90 f0 47 10 f0    	lea    -0xfefb810(%eax),%edx
f010296d:	8b 88 f0 47 10 f0    	mov    -0xfefb810(%eax),%ecx
f0102973:	b8 fd be 10 f0       	mov    $0xf010befd,%eax
f0102978:	2d 49 a1 10 f0       	sub    $0xf010a149,%eax
f010297d:	39 c1                	cmp    %eax,%ecx
f010297f:	73 09                	jae    f010298a <debuginfo_eip+0x105>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0102981:	81 c1 49 a1 10 f0    	add    $0xf010a149,%ecx
f0102987:	89 4e 08             	mov    %ecx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f010298a:	8b 42 08             	mov    0x8(%edx),%eax
f010298d:	89 46 10             	mov    %eax,0x10(%esi)
f0102990:	eb 06                	jmp    f0102998 <debuginfo_eip+0x113>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0102992:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0102995:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0102998:	83 ec 08             	sub    $0x8,%esp
f010299b:	6a 3a                	push   $0x3a
f010299d:	ff 76 08             	pushl  0x8(%esi)
f01029a0:	e8 24 08 00 00       	call   f01031c9 <strfind>
f01029a5:	2b 46 08             	sub    0x8(%esi),%eax
f01029a8:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01029ab:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01029ae:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01029b1:	8d 04 85 f0 47 10 f0 	lea    -0xfefb810(,%eax,4),%eax
f01029b8:	83 c4 10             	add    $0x10,%esp
f01029bb:	eb 06                	jmp    f01029c3 <debuginfo_eip+0x13e>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f01029bd:	83 eb 01             	sub    $0x1,%ebx
f01029c0:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01029c3:	39 fb                	cmp    %edi,%ebx
f01029c5:	7c 34                	jl     f01029fb <debuginfo_eip+0x176>
	       && stabs[lline].n_type != N_SOL
f01029c7:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f01029cb:	80 fa 84             	cmp    $0x84,%dl
f01029ce:	74 0b                	je     f01029db <debuginfo_eip+0x156>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01029d0:	80 fa 64             	cmp    $0x64,%dl
f01029d3:	75 e8                	jne    f01029bd <debuginfo_eip+0x138>
f01029d5:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f01029d9:	74 e2                	je     f01029bd <debuginfo_eip+0x138>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01029db:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01029de:	8b 14 85 f0 47 10 f0 	mov    -0xfefb810(,%eax,4),%edx
f01029e5:	b8 fd be 10 f0       	mov    $0xf010befd,%eax
f01029ea:	2d 49 a1 10 f0       	sub    $0xf010a149,%eax
f01029ef:	39 c2                	cmp    %eax,%edx
f01029f1:	73 08                	jae    f01029fb <debuginfo_eip+0x176>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01029f3:	81 c2 49 a1 10 f0    	add    $0xf010a149,%edx
f01029f9:	89 16                	mov    %edx,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01029fb:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01029fe:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102a01:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102a06:	39 cb                	cmp    %ecx,%ebx
f0102a08:	7d 44                	jge    f0102a4e <debuginfo_eip+0x1c9>
		for (lline = lfun + 1;
f0102a0a:	8d 53 01             	lea    0x1(%ebx),%edx
f0102a0d:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0102a10:	8d 04 85 f0 47 10 f0 	lea    -0xfefb810(,%eax,4),%eax
f0102a17:	eb 07                	jmp    f0102a20 <debuginfo_eip+0x19b>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0102a19:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0102a1d:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0102a20:	39 ca                	cmp    %ecx,%edx
f0102a22:	74 25                	je     f0102a49 <debuginfo_eip+0x1c4>
f0102a24:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0102a27:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f0102a2b:	74 ec                	je     f0102a19 <debuginfo_eip+0x194>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102a2d:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a32:	eb 1a                	jmp    f0102a4e <debuginfo_eip+0x1c9>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102a34:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a39:	eb 13                	jmp    f0102a4e <debuginfo_eip+0x1c9>
f0102a3b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a40:	eb 0c                	jmp    f0102a4e <debuginfo_eip+0x1c9>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0102a42:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a47:	eb 05                	jmp    f0102a4e <debuginfo_eip+0x1c9>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102a49:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102a4e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102a51:	5b                   	pop    %ebx
f0102a52:	5e                   	pop    %esi
f0102a53:	5f                   	pop    %edi
f0102a54:	5d                   	pop    %ebp
f0102a55:	c3                   	ret    

f0102a56 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0102a56:	55                   	push   %ebp
f0102a57:	89 e5                	mov    %esp,%ebp
f0102a59:	57                   	push   %edi
f0102a5a:	56                   	push   %esi
f0102a5b:	53                   	push   %ebx
f0102a5c:	83 ec 1c             	sub    $0x1c,%esp
f0102a5f:	89 c7                	mov    %eax,%edi
f0102a61:	89 d6                	mov    %edx,%esi
f0102a63:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a66:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102a69:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102a6c:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0102a6f:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0102a72:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102a77:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102a7a:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0102a7d:	39 d3                	cmp    %edx,%ebx
f0102a7f:	72 05                	jb     f0102a86 <printnum+0x30>
f0102a81:	39 45 10             	cmp    %eax,0x10(%ebp)
f0102a84:	77 45                	ja     f0102acb <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0102a86:	83 ec 0c             	sub    $0xc,%esp
f0102a89:	ff 75 18             	pushl  0x18(%ebp)
f0102a8c:	8b 45 14             	mov    0x14(%ebp),%eax
f0102a8f:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0102a92:	53                   	push   %ebx
f0102a93:	ff 75 10             	pushl  0x10(%ebp)
f0102a96:	83 ec 08             	sub    $0x8,%esp
f0102a99:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102a9c:	ff 75 e0             	pushl  -0x20(%ebp)
f0102a9f:	ff 75 dc             	pushl  -0x24(%ebp)
f0102aa2:	ff 75 d8             	pushl  -0x28(%ebp)
f0102aa5:	e8 46 09 00 00       	call   f01033f0 <__udivdi3>
f0102aaa:	83 c4 18             	add    $0x18,%esp
f0102aad:	52                   	push   %edx
f0102aae:	50                   	push   %eax
f0102aaf:	89 f2                	mov    %esi,%edx
f0102ab1:	89 f8                	mov    %edi,%eax
f0102ab3:	e8 9e ff ff ff       	call   f0102a56 <printnum>
f0102ab8:	83 c4 20             	add    $0x20,%esp
f0102abb:	eb 18                	jmp    f0102ad5 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0102abd:	83 ec 08             	sub    $0x8,%esp
f0102ac0:	56                   	push   %esi
f0102ac1:	ff 75 18             	pushl  0x18(%ebp)
f0102ac4:	ff d7                	call   *%edi
f0102ac6:	83 c4 10             	add    $0x10,%esp
f0102ac9:	eb 03                	jmp    f0102ace <printnum+0x78>
f0102acb:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0102ace:	83 eb 01             	sub    $0x1,%ebx
f0102ad1:	85 db                	test   %ebx,%ebx
f0102ad3:	7f e8                	jg     f0102abd <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0102ad5:	83 ec 08             	sub    $0x8,%esp
f0102ad8:	56                   	push   %esi
f0102ad9:	83 ec 04             	sub    $0x4,%esp
f0102adc:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102adf:	ff 75 e0             	pushl  -0x20(%ebp)
f0102ae2:	ff 75 dc             	pushl  -0x24(%ebp)
f0102ae5:	ff 75 d8             	pushl  -0x28(%ebp)
f0102ae8:	e8 33 0a 00 00       	call   f0103520 <__umoddi3>
f0102aed:	83 c4 14             	add    $0x14,%esp
f0102af0:	0f be 80 e1 45 10 f0 	movsbl -0xfefba1f(%eax),%eax
f0102af7:	50                   	push   %eax
f0102af8:	ff d7                	call   *%edi
}
f0102afa:	83 c4 10             	add    $0x10,%esp
f0102afd:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102b00:	5b                   	pop    %ebx
f0102b01:	5e                   	pop    %esi
f0102b02:	5f                   	pop    %edi
f0102b03:	5d                   	pop    %ebp
f0102b04:	c3                   	ret    

f0102b05 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0102b05:	55                   	push   %ebp
f0102b06:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0102b08:	83 fa 01             	cmp    $0x1,%edx
f0102b0b:	7e 0e                	jle    f0102b1b <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0102b0d:	8b 10                	mov    (%eax),%edx
f0102b0f:	8d 4a 08             	lea    0x8(%edx),%ecx
f0102b12:	89 08                	mov    %ecx,(%eax)
f0102b14:	8b 02                	mov    (%edx),%eax
f0102b16:	8b 52 04             	mov    0x4(%edx),%edx
f0102b19:	eb 22                	jmp    f0102b3d <getuint+0x38>
	else if (lflag)
f0102b1b:	85 d2                	test   %edx,%edx
f0102b1d:	74 10                	je     f0102b2f <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0102b1f:	8b 10                	mov    (%eax),%edx
f0102b21:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102b24:	89 08                	mov    %ecx,(%eax)
f0102b26:	8b 02                	mov    (%edx),%eax
f0102b28:	ba 00 00 00 00       	mov    $0x0,%edx
f0102b2d:	eb 0e                	jmp    f0102b3d <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0102b2f:	8b 10                	mov    (%eax),%edx
f0102b31:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102b34:	89 08                	mov    %ecx,(%eax)
f0102b36:	8b 02                	mov    (%edx),%eax
f0102b38:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0102b3d:	5d                   	pop    %ebp
f0102b3e:	c3                   	ret    

f0102b3f <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0102b3f:	55                   	push   %ebp
f0102b40:	89 e5                	mov    %esp,%ebp
f0102b42:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0102b45:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0102b49:	8b 10                	mov    (%eax),%edx
f0102b4b:	3b 50 04             	cmp    0x4(%eax),%edx
f0102b4e:	73 0a                	jae    f0102b5a <sprintputch+0x1b>
		*b->buf++ = ch;
f0102b50:	8d 4a 01             	lea    0x1(%edx),%ecx
f0102b53:	89 08                	mov    %ecx,(%eax)
f0102b55:	8b 45 08             	mov    0x8(%ebp),%eax
f0102b58:	88 02                	mov    %al,(%edx)
}
f0102b5a:	5d                   	pop    %ebp
f0102b5b:	c3                   	ret    

f0102b5c <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0102b5c:	55                   	push   %ebp
f0102b5d:	89 e5                	mov    %esp,%ebp
f0102b5f:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0102b62:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0102b65:	50                   	push   %eax
f0102b66:	ff 75 10             	pushl  0x10(%ebp)
f0102b69:	ff 75 0c             	pushl  0xc(%ebp)
f0102b6c:	ff 75 08             	pushl  0x8(%ebp)
f0102b6f:	e8 05 00 00 00       	call   f0102b79 <vprintfmt>
	va_end(ap);
}
f0102b74:	83 c4 10             	add    $0x10,%esp
f0102b77:	c9                   	leave  
f0102b78:	c3                   	ret    

f0102b79 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0102b79:	55                   	push   %ebp
f0102b7a:	89 e5                	mov    %esp,%ebp
f0102b7c:	57                   	push   %edi
f0102b7d:	56                   	push   %esi
f0102b7e:	53                   	push   %ebx
f0102b7f:	83 ec 2c             	sub    $0x2c,%esp
f0102b82:	8b 75 08             	mov    0x8(%ebp),%esi
f0102b85:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102b88:	8b 7d 10             	mov    0x10(%ebp),%edi
f0102b8b:	eb 12                	jmp    f0102b9f <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0102b8d:	85 c0                	test   %eax,%eax
f0102b8f:	0f 84 89 03 00 00    	je     f0102f1e <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0102b95:	83 ec 08             	sub    $0x8,%esp
f0102b98:	53                   	push   %ebx
f0102b99:	50                   	push   %eax
f0102b9a:	ff d6                	call   *%esi
f0102b9c:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0102b9f:	83 c7 01             	add    $0x1,%edi
f0102ba2:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102ba6:	83 f8 25             	cmp    $0x25,%eax
f0102ba9:	75 e2                	jne    f0102b8d <vprintfmt+0x14>
f0102bab:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0102baf:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0102bb6:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102bbd:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0102bc4:	ba 00 00 00 00       	mov    $0x0,%edx
f0102bc9:	eb 07                	jmp    f0102bd2 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102bcb:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0102bce:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102bd2:	8d 47 01             	lea    0x1(%edi),%eax
f0102bd5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102bd8:	0f b6 07             	movzbl (%edi),%eax
f0102bdb:	0f b6 c8             	movzbl %al,%ecx
f0102bde:	83 e8 23             	sub    $0x23,%eax
f0102be1:	3c 55                	cmp    $0x55,%al
f0102be3:	0f 87 1a 03 00 00    	ja     f0102f03 <vprintfmt+0x38a>
f0102be9:	0f b6 c0             	movzbl %al,%eax
f0102bec:	ff 24 85 60 46 10 f0 	jmp    *-0xfefb9a0(,%eax,4)
f0102bf3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0102bf6:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0102bfa:	eb d6                	jmp    f0102bd2 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102bfc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102bff:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c04:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0102c07:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0102c0a:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0102c0e:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0102c11:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0102c14:	83 fa 09             	cmp    $0x9,%edx
f0102c17:	77 39                	ja     f0102c52 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0102c19:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0102c1c:	eb e9                	jmp    f0102c07 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0102c1e:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c21:	8d 48 04             	lea    0x4(%eax),%ecx
f0102c24:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0102c27:	8b 00                	mov    (%eax),%eax
f0102c29:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c2c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0102c2f:	eb 27                	jmp    f0102c58 <vprintfmt+0xdf>
f0102c31:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102c34:	85 c0                	test   %eax,%eax
f0102c36:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102c3b:	0f 49 c8             	cmovns %eax,%ecx
f0102c3e:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c41:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102c44:	eb 8c                	jmp    f0102bd2 <vprintfmt+0x59>
f0102c46:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0102c49:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0102c50:	eb 80                	jmp    f0102bd2 <vprintfmt+0x59>
f0102c52:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0102c55:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0102c58:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102c5c:	0f 89 70 ff ff ff    	jns    f0102bd2 <vprintfmt+0x59>
				width = precision, precision = -1;
f0102c62:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102c65:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102c68:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102c6f:	e9 5e ff ff ff       	jmp    f0102bd2 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0102c74:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c77:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0102c7a:	e9 53 ff ff ff       	jmp    f0102bd2 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102c7f:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c82:	8d 50 04             	lea    0x4(%eax),%edx
f0102c85:	89 55 14             	mov    %edx,0x14(%ebp)
f0102c88:	83 ec 08             	sub    $0x8,%esp
f0102c8b:	53                   	push   %ebx
f0102c8c:	ff 30                	pushl  (%eax)
f0102c8e:	ff d6                	call   *%esi
			break;
f0102c90:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c93:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0102c96:	e9 04 ff ff ff       	jmp    f0102b9f <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102c9b:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c9e:	8d 50 04             	lea    0x4(%eax),%edx
f0102ca1:	89 55 14             	mov    %edx,0x14(%ebp)
f0102ca4:	8b 00                	mov    (%eax),%eax
f0102ca6:	99                   	cltd   
f0102ca7:	31 d0                	xor    %edx,%eax
f0102ca9:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0102cab:	83 f8 07             	cmp    $0x7,%eax
f0102cae:	7f 0b                	jg     f0102cbb <vprintfmt+0x142>
f0102cb0:	8b 14 85 c0 47 10 f0 	mov    -0xfefb840(,%eax,4),%edx
f0102cb7:	85 d2                	test   %edx,%edx
f0102cb9:	75 18                	jne    f0102cd3 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0102cbb:	50                   	push   %eax
f0102cbc:	68 f9 45 10 f0       	push   $0xf01045f9
f0102cc1:	53                   	push   %ebx
f0102cc2:	56                   	push   %esi
f0102cc3:	e8 94 fe ff ff       	call   f0102b5c <printfmt>
f0102cc8:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102ccb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0102cce:	e9 cc fe ff ff       	jmp    f0102b9f <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0102cd3:	52                   	push   %edx
f0102cd4:	68 96 3b 10 f0       	push   $0xf0103b96
f0102cd9:	53                   	push   %ebx
f0102cda:	56                   	push   %esi
f0102cdb:	e8 7c fe ff ff       	call   f0102b5c <printfmt>
f0102ce0:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102ce3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102ce6:	e9 b4 fe ff ff       	jmp    f0102b9f <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102ceb:	8b 45 14             	mov    0x14(%ebp),%eax
f0102cee:	8d 50 04             	lea    0x4(%eax),%edx
f0102cf1:	89 55 14             	mov    %edx,0x14(%ebp)
f0102cf4:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0102cf6:	85 ff                	test   %edi,%edi
f0102cf8:	b8 f2 45 10 f0       	mov    $0xf01045f2,%eax
f0102cfd:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0102d00:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102d04:	0f 8e 94 00 00 00    	jle    f0102d9e <vprintfmt+0x225>
f0102d0a:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0102d0e:	0f 84 98 00 00 00    	je     f0102dac <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0102d14:	83 ec 08             	sub    $0x8,%esp
f0102d17:	ff 75 d0             	pushl  -0x30(%ebp)
f0102d1a:	57                   	push   %edi
f0102d1b:	e8 5f 03 00 00       	call   f010307f <strnlen>
f0102d20:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102d23:	29 c1                	sub    %eax,%ecx
f0102d25:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0102d28:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0102d2b:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0102d2f:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102d32:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102d35:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102d37:	eb 0f                	jmp    f0102d48 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0102d39:	83 ec 08             	sub    $0x8,%esp
f0102d3c:	53                   	push   %ebx
f0102d3d:	ff 75 e0             	pushl  -0x20(%ebp)
f0102d40:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102d42:	83 ef 01             	sub    $0x1,%edi
f0102d45:	83 c4 10             	add    $0x10,%esp
f0102d48:	85 ff                	test   %edi,%edi
f0102d4a:	7f ed                	jg     f0102d39 <vprintfmt+0x1c0>
f0102d4c:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102d4f:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102d52:	85 c9                	test   %ecx,%ecx
f0102d54:	b8 00 00 00 00       	mov    $0x0,%eax
f0102d59:	0f 49 c1             	cmovns %ecx,%eax
f0102d5c:	29 c1                	sub    %eax,%ecx
f0102d5e:	89 75 08             	mov    %esi,0x8(%ebp)
f0102d61:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102d64:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102d67:	89 cb                	mov    %ecx,%ebx
f0102d69:	eb 4d                	jmp    f0102db8 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0102d6b:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102d6f:	74 1b                	je     f0102d8c <vprintfmt+0x213>
f0102d71:	0f be c0             	movsbl %al,%eax
f0102d74:	83 e8 20             	sub    $0x20,%eax
f0102d77:	83 f8 5e             	cmp    $0x5e,%eax
f0102d7a:	76 10                	jbe    f0102d8c <vprintfmt+0x213>
					putch('?', putdat);
f0102d7c:	83 ec 08             	sub    $0x8,%esp
f0102d7f:	ff 75 0c             	pushl  0xc(%ebp)
f0102d82:	6a 3f                	push   $0x3f
f0102d84:	ff 55 08             	call   *0x8(%ebp)
f0102d87:	83 c4 10             	add    $0x10,%esp
f0102d8a:	eb 0d                	jmp    f0102d99 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0102d8c:	83 ec 08             	sub    $0x8,%esp
f0102d8f:	ff 75 0c             	pushl  0xc(%ebp)
f0102d92:	52                   	push   %edx
f0102d93:	ff 55 08             	call   *0x8(%ebp)
f0102d96:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102d99:	83 eb 01             	sub    $0x1,%ebx
f0102d9c:	eb 1a                	jmp    f0102db8 <vprintfmt+0x23f>
f0102d9e:	89 75 08             	mov    %esi,0x8(%ebp)
f0102da1:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102da4:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102da7:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102daa:	eb 0c                	jmp    f0102db8 <vprintfmt+0x23f>
f0102dac:	89 75 08             	mov    %esi,0x8(%ebp)
f0102daf:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102db2:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102db5:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102db8:	83 c7 01             	add    $0x1,%edi
f0102dbb:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102dbf:	0f be d0             	movsbl %al,%edx
f0102dc2:	85 d2                	test   %edx,%edx
f0102dc4:	74 23                	je     f0102de9 <vprintfmt+0x270>
f0102dc6:	85 f6                	test   %esi,%esi
f0102dc8:	78 a1                	js     f0102d6b <vprintfmt+0x1f2>
f0102dca:	83 ee 01             	sub    $0x1,%esi
f0102dcd:	79 9c                	jns    f0102d6b <vprintfmt+0x1f2>
f0102dcf:	89 df                	mov    %ebx,%edi
f0102dd1:	8b 75 08             	mov    0x8(%ebp),%esi
f0102dd4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102dd7:	eb 18                	jmp    f0102df1 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0102dd9:	83 ec 08             	sub    $0x8,%esp
f0102ddc:	53                   	push   %ebx
f0102ddd:	6a 20                	push   $0x20
f0102ddf:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0102de1:	83 ef 01             	sub    $0x1,%edi
f0102de4:	83 c4 10             	add    $0x10,%esp
f0102de7:	eb 08                	jmp    f0102df1 <vprintfmt+0x278>
f0102de9:	89 df                	mov    %ebx,%edi
f0102deb:	8b 75 08             	mov    0x8(%ebp),%esi
f0102dee:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102df1:	85 ff                	test   %edi,%edi
f0102df3:	7f e4                	jg     f0102dd9 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102df5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102df8:	e9 a2 fd ff ff       	jmp    f0102b9f <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102dfd:	83 fa 01             	cmp    $0x1,%edx
f0102e00:	7e 16                	jle    f0102e18 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0102e02:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e05:	8d 50 08             	lea    0x8(%eax),%edx
f0102e08:	89 55 14             	mov    %edx,0x14(%ebp)
f0102e0b:	8b 50 04             	mov    0x4(%eax),%edx
f0102e0e:	8b 00                	mov    (%eax),%eax
f0102e10:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102e13:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0102e16:	eb 32                	jmp    f0102e4a <vprintfmt+0x2d1>
	else if (lflag)
f0102e18:	85 d2                	test   %edx,%edx
f0102e1a:	74 18                	je     f0102e34 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0102e1c:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e1f:	8d 50 04             	lea    0x4(%eax),%edx
f0102e22:	89 55 14             	mov    %edx,0x14(%ebp)
f0102e25:	8b 00                	mov    (%eax),%eax
f0102e27:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102e2a:	89 c1                	mov    %eax,%ecx
f0102e2c:	c1 f9 1f             	sar    $0x1f,%ecx
f0102e2f:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102e32:	eb 16                	jmp    f0102e4a <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0102e34:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e37:	8d 50 04             	lea    0x4(%eax),%edx
f0102e3a:	89 55 14             	mov    %edx,0x14(%ebp)
f0102e3d:	8b 00                	mov    (%eax),%eax
f0102e3f:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102e42:	89 c1                	mov    %eax,%ecx
f0102e44:	c1 f9 1f             	sar    $0x1f,%ecx
f0102e47:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0102e4a:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102e4d:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0102e50:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0102e55:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0102e59:	79 74                	jns    f0102ecf <vprintfmt+0x356>
				putch('-', putdat);
f0102e5b:	83 ec 08             	sub    $0x8,%esp
f0102e5e:	53                   	push   %ebx
f0102e5f:	6a 2d                	push   $0x2d
f0102e61:	ff d6                	call   *%esi
				num = -(long long) num;
f0102e63:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102e66:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102e69:	f7 d8                	neg    %eax
f0102e6b:	83 d2 00             	adc    $0x0,%edx
f0102e6e:	f7 da                	neg    %edx
f0102e70:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0102e73:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0102e78:	eb 55                	jmp    f0102ecf <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0102e7a:	8d 45 14             	lea    0x14(%ebp),%eax
f0102e7d:	e8 83 fc ff ff       	call   f0102b05 <getuint>
			base = 10;
f0102e82:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0102e87:	eb 46                	jmp    f0102ecf <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0102e89:	8d 45 14             	lea    0x14(%ebp),%eax
f0102e8c:	e8 74 fc ff ff       	call   f0102b05 <getuint>
           		base = 8;
f0102e91:	b9 08 00 00 00       	mov    $0x8,%ecx
           		goto number;
f0102e96:	eb 37                	jmp    f0102ecf <vprintfmt+0x356>
			break;

		// pointer
		case 'p':
			putch('0', putdat);
f0102e98:	83 ec 08             	sub    $0x8,%esp
f0102e9b:	53                   	push   %ebx
f0102e9c:	6a 30                	push   $0x30
f0102e9e:	ff d6                	call   *%esi
			putch('x', putdat);
f0102ea0:	83 c4 08             	add    $0x8,%esp
f0102ea3:	53                   	push   %ebx
f0102ea4:	6a 78                	push   $0x78
f0102ea6:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0102ea8:	8b 45 14             	mov    0x14(%ebp),%eax
f0102eab:	8d 50 04             	lea    0x4(%eax),%edx
f0102eae:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0102eb1:	8b 00                	mov    (%eax),%eax
f0102eb3:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0102eb8:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0102ebb:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0102ec0:	eb 0d                	jmp    f0102ecf <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0102ec2:	8d 45 14             	lea    0x14(%ebp),%eax
f0102ec5:	e8 3b fc ff ff       	call   f0102b05 <getuint>
			base = 16;
f0102eca:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0102ecf:	83 ec 0c             	sub    $0xc,%esp
f0102ed2:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0102ed6:	57                   	push   %edi
f0102ed7:	ff 75 e0             	pushl  -0x20(%ebp)
f0102eda:	51                   	push   %ecx
f0102edb:	52                   	push   %edx
f0102edc:	50                   	push   %eax
f0102edd:	89 da                	mov    %ebx,%edx
f0102edf:	89 f0                	mov    %esi,%eax
f0102ee1:	e8 70 fb ff ff       	call   f0102a56 <printnum>
			break;
f0102ee6:	83 c4 20             	add    $0x20,%esp
f0102ee9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102eec:	e9 ae fc ff ff       	jmp    f0102b9f <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0102ef1:	83 ec 08             	sub    $0x8,%esp
f0102ef4:	53                   	push   %ebx
f0102ef5:	51                   	push   %ecx
f0102ef6:	ff d6                	call   *%esi
			break;
f0102ef8:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102efb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0102efe:	e9 9c fc ff ff       	jmp    f0102b9f <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0102f03:	83 ec 08             	sub    $0x8,%esp
f0102f06:	53                   	push   %ebx
f0102f07:	6a 25                	push   $0x25
f0102f09:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0102f0b:	83 c4 10             	add    $0x10,%esp
f0102f0e:	eb 03                	jmp    f0102f13 <vprintfmt+0x39a>
f0102f10:	83 ef 01             	sub    $0x1,%edi
f0102f13:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0102f17:	75 f7                	jne    f0102f10 <vprintfmt+0x397>
f0102f19:	e9 81 fc ff ff       	jmp    f0102b9f <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0102f1e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102f21:	5b                   	pop    %ebx
f0102f22:	5e                   	pop    %esi
f0102f23:	5f                   	pop    %edi
f0102f24:	5d                   	pop    %ebp
f0102f25:	c3                   	ret    

f0102f26 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0102f26:	55                   	push   %ebp
f0102f27:	89 e5                	mov    %esp,%ebp
f0102f29:	83 ec 18             	sub    $0x18,%esp
f0102f2c:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f2f:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0102f32:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102f35:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0102f39:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0102f3c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0102f43:	85 c0                	test   %eax,%eax
f0102f45:	74 26                	je     f0102f6d <vsnprintf+0x47>
f0102f47:	85 d2                	test   %edx,%edx
f0102f49:	7e 22                	jle    f0102f6d <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0102f4b:	ff 75 14             	pushl  0x14(%ebp)
f0102f4e:	ff 75 10             	pushl  0x10(%ebp)
f0102f51:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0102f54:	50                   	push   %eax
f0102f55:	68 3f 2b 10 f0       	push   $0xf0102b3f
f0102f5a:	e8 1a fc ff ff       	call   f0102b79 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0102f5f:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102f62:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0102f65:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102f68:	83 c4 10             	add    $0x10,%esp
f0102f6b:	eb 05                	jmp    f0102f72 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0102f6d:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0102f72:	c9                   	leave  
f0102f73:	c3                   	ret    

f0102f74 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0102f74:	55                   	push   %ebp
f0102f75:	89 e5                	mov    %esp,%ebp
f0102f77:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0102f7a:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0102f7d:	50                   	push   %eax
f0102f7e:	ff 75 10             	pushl  0x10(%ebp)
f0102f81:	ff 75 0c             	pushl  0xc(%ebp)
f0102f84:	ff 75 08             	pushl  0x8(%ebp)
f0102f87:	e8 9a ff ff ff       	call   f0102f26 <vsnprintf>
	va_end(ap);

	return rc;
}
f0102f8c:	c9                   	leave  
f0102f8d:	c3                   	ret    

f0102f8e <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0102f8e:	55                   	push   %ebp
f0102f8f:	89 e5                	mov    %esp,%ebp
f0102f91:	57                   	push   %edi
f0102f92:	56                   	push   %esi
f0102f93:	53                   	push   %ebx
f0102f94:	83 ec 0c             	sub    $0xc,%esp
f0102f97:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0102f9a:	85 c0                	test   %eax,%eax
f0102f9c:	74 11                	je     f0102faf <readline+0x21>
		cprintf("%s", prompt);
f0102f9e:	83 ec 08             	sub    $0x8,%esp
f0102fa1:	50                   	push   %eax
f0102fa2:	68 96 3b 10 f0       	push   $0xf0103b96
f0102fa7:	e8 cf f7 ff ff       	call   f010277b <cprintf>
f0102fac:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0102faf:	83 ec 0c             	sub    $0xc,%esp
f0102fb2:	6a 00                	push   $0x0
f0102fb4:	e8 5a d6 ff ff       	call   f0100613 <iscons>
f0102fb9:	89 c7                	mov    %eax,%edi
f0102fbb:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0102fbe:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0102fc3:	e8 3a d6 ff ff       	call   f0100602 <getchar>
f0102fc8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0102fca:	85 c0                	test   %eax,%eax
f0102fcc:	79 18                	jns    f0102fe6 <readline+0x58>
			cprintf("read error: %e\n", c);
f0102fce:	83 ec 08             	sub    $0x8,%esp
f0102fd1:	50                   	push   %eax
f0102fd2:	68 e0 47 10 f0       	push   $0xf01047e0
f0102fd7:	e8 9f f7 ff ff       	call   f010277b <cprintf>
			return NULL;
f0102fdc:	83 c4 10             	add    $0x10,%esp
f0102fdf:	b8 00 00 00 00       	mov    $0x0,%eax
f0102fe4:	eb 79                	jmp    f010305f <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0102fe6:	83 f8 08             	cmp    $0x8,%eax
f0102fe9:	0f 94 c2             	sete   %dl
f0102fec:	83 f8 7f             	cmp    $0x7f,%eax
f0102fef:	0f 94 c0             	sete   %al
f0102ff2:	08 c2                	or     %al,%dl
f0102ff4:	74 1a                	je     f0103010 <readline+0x82>
f0102ff6:	85 f6                	test   %esi,%esi
f0102ff8:	7e 16                	jle    f0103010 <readline+0x82>
			if (echoing)
f0102ffa:	85 ff                	test   %edi,%edi
f0102ffc:	74 0d                	je     f010300b <readline+0x7d>
				cputchar('\b');
f0102ffe:	83 ec 0c             	sub    $0xc,%esp
f0103001:	6a 08                	push   $0x8
f0103003:	e8 ea d5 ff ff       	call   f01005f2 <cputchar>
f0103008:	83 c4 10             	add    $0x10,%esp
			i--;
f010300b:	83 ee 01             	sub    $0x1,%esi
f010300e:	eb b3                	jmp    f0102fc3 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103010:	83 fb 1f             	cmp    $0x1f,%ebx
f0103013:	7e 23                	jle    f0103038 <readline+0xaa>
f0103015:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010301b:	7f 1b                	jg     f0103038 <readline+0xaa>
			if (echoing)
f010301d:	85 ff                	test   %edi,%edi
f010301f:	74 0c                	je     f010302d <readline+0x9f>
				cputchar(c);
f0103021:	83 ec 0c             	sub    $0xc,%esp
f0103024:	53                   	push   %ebx
f0103025:	e8 c8 d5 ff ff       	call   f01005f2 <cputchar>
f010302a:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f010302d:	88 9e 60 65 11 f0    	mov    %bl,-0xfee9aa0(%esi)
f0103033:	8d 76 01             	lea    0x1(%esi),%esi
f0103036:	eb 8b                	jmp    f0102fc3 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0103038:	83 fb 0a             	cmp    $0xa,%ebx
f010303b:	74 05                	je     f0103042 <readline+0xb4>
f010303d:	83 fb 0d             	cmp    $0xd,%ebx
f0103040:	75 81                	jne    f0102fc3 <readline+0x35>
			if (echoing)
f0103042:	85 ff                	test   %edi,%edi
f0103044:	74 0d                	je     f0103053 <readline+0xc5>
				cputchar('\n');
f0103046:	83 ec 0c             	sub    $0xc,%esp
f0103049:	6a 0a                	push   $0xa
f010304b:	e8 a2 d5 ff ff       	call   f01005f2 <cputchar>
f0103050:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0103053:	c6 86 60 65 11 f0 00 	movb   $0x0,-0xfee9aa0(%esi)
			return buf;
f010305a:	b8 60 65 11 f0       	mov    $0xf0116560,%eax
		}
	}
}
f010305f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103062:	5b                   	pop    %ebx
f0103063:	5e                   	pop    %esi
f0103064:	5f                   	pop    %edi
f0103065:	5d                   	pop    %ebp
f0103066:	c3                   	ret    

f0103067 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103067:	55                   	push   %ebp
f0103068:	89 e5                	mov    %esp,%ebp
f010306a:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f010306d:	b8 00 00 00 00       	mov    $0x0,%eax
f0103072:	eb 03                	jmp    f0103077 <strlen+0x10>
		n++;
f0103074:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103077:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f010307b:	75 f7                	jne    f0103074 <strlen+0xd>
		n++;
	return n;
}
f010307d:	5d                   	pop    %ebp
f010307e:	c3                   	ret    

f010307f <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010307f:	55                   	push   %ebp
f0103080:	89 e5                	mov    %esp,%ebp
f0103082:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103085:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103088:	ba 00 00 00 00       	mov    $0x0,%edx
f010308d:	eb 03                	jmp    f0103092 <strnlen+0x13>
		n++;
f010308f:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103092:	39 c2                	cmp    %eax,%edx
f0103094:	74 08                	je     f010309e <strnlen+0x1f>
f0103096:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f010309a:	75 f3                	jne    f010308f <strnlen+0x10>
f010309c:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f010309e:	5d                   	pop    %ebp
f010309f:	c3                   	ret    

f01030a0 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01030a0:	55                   	push   %ebp
f01030a1:	89 e5                	mov    %esp,%ebp
f01030a3:	53                   	push   %ebx
f01030a4:	8b 45 08             	mov    0x8(%ebp),%eax
f01030a7:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01030aa:	89 c2                	mov    %eax,%edx
f01030ac:	83 c2 01             	add    $0x1,%edx
f01030af:	83 c1 01             	add    $0x1,%ecx
f01030b2:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01030b6:	88 5a ff             	mov    %bl,-0x1(%edx)
f01030b9:	84 db                	test   %bl,%bl
f01030bb:	75 ef                	jne    f01030ac <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01030bd:	5b                   	pop    %ebx
f01030be:	5d                   	pop    %ebp
f01030bf:	c3                   	ret    

f01030c0 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01030c0:	55                   	push   %ebp
f01030c1:	89 e5                	mov    %esp,%ebp
f01030c3:	53                   	push   %ebx
f01030c4:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01030c7:	53                   	push   %ebx
f01030c8:	e8 9a ff ff ff       	call   f0103067 <strlen>
f01030cd:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01030d0:	ff 75 0c             	pushl  0xc(%ebp)
f01030d3:	01 d8                	add    %ebx,%eax
f01030d5:	50                   	push   %eax
f01030d6:	e8 c5 ff ff ff       	call   f01030a0 <strcpy>
	return dst;
}
f01030db:	89 d8                	mov    %ebx,%eax
f01030dd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01030e0:	c9                   	leave  
f01030e1:	c3                   	ret    

f01030e2 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01030e2:	55                   	push   %ebp
f01030e3:	89 e5                	mov    %esp,%ebp
f01030e5:	56                   	push   %esi
f01030e6:	53                   	push   %ebx
f01030e7:	8b 75 08             	mov    0x8(%ebp),%esi
f01030ea:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01030ed:	89 f3                	mov    %esi,%ebx
f01030ef:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01030f2:	89 f2                	mov    %esi,%edx
f01030f4:	eb 0f                	jmp    f0103105 <strncpy+0x23>
		*dst++ = *src;
f01030f6:	83 c2 01             	add    $0x1,%edx
f01030f9:	0f b6 01             	movzbl (%ecx),%eax
f01030fc:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01030ff:	80 39 01             	cmpb   $0x1,(%ecx)
f0103102:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103105:	39 da                	cmp    %ebx,%edx
f0103107:	75 ed                	jne    f01030f6 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103109:	89 f0                	mov    %esi,%eax
f010310b:	5b                   	pop    %ebx
f010310c:	5e                   	pop    %esi
f010310d:	5d                   	pop    %ebp
f010310e:	c3                   	ret    

f010310f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010310f:	55                   	push   %ebp
f0103110:	89 e5                	mov    %esp,%ebp
f0103112:	56                   	push   %esi
f0103113:	53                   	push   %ebx
f0103114:	8b 75 08             	mov    0x8(%ebp),%esi
f0103117:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010311a:	8b 55 10             	mov    0x10(%ebp),%edx
f010311d:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010311f:	85 d2                	test   %edx,%edx
f0103121:	74 21                	je     f0103144 <strlcpy+0x35>
f0103123:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0103127:	89 f2                	mov    %esi,%edx
f0103129:	eb 09                	jmp    f0103134 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010312b:	83 c2 01             	add    $0x1,%edx
f010312e:	83 c1 01             	add    $0x1,%ecx
f0103131:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0103134:	39 c2                	cmp    %eax,%edx
f0103136:	74 09                	je     f0103141 <strlcpy+0x32>
f0103138:	0f b6 19             	movzbl (%ecx),%ebx
f010313b:	84 db                	test   %bl,%bl
f010313d:	75 ec                	jne    f010312b <strlcpy+0x1c>
f010313f:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0103141:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103144:	29 f0                	sub    %esi,%eax
}
f0103146:	5b                   	pop    %ebx
f0103147:	5e                   	pop    %esi
f0103148:	5d                   	pop    %ebp
f0103149:	c3                   	ret    

f010314a <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010314a:	55                   	push   %ebp
f010314b:	89 e5                	mov    %esp,%ebp
f010314d:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103150:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103153:	eb 06                	jmp    f010315b <strcmp+0x11>
		p++, q++;
f0103155:	83 c1 01             	add    $0x1,%ecx
f0103158:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010315b:	0f b6 01             	movzbl (%ecx),%eax
f010315e:	84 c0                	test   %al,%al
f0103160:	74 04                	je     f0103166 <strcmp+0x1c>
f0103162:	3a 02                	cmp    (%edx),%al
f0103164:	74 ef                	je     f0103155 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103166:	0f b6 c0             	movzbl %al,%eax
f0103169:	0f b6 12             	movzbl (%edx),%edx
f010316c:	29 d0                	sub    %edx,%eax
}
f010316e:	5d                   	pop    %ebp
f010316f:	c3                   	ret    

f0103170 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103170:	55                   	push   %ebp
f0103171:	89 e5                	mov    %esp,%ebp
f0103173:	53                   	push   %ebx
f0103174:	8b 45 08             	mov    0x8(%ebp),%eax
f0103177:	8b 55 0c             	mov    0xc(%ebp),%edx
f010317a:	89 c3                	mov    %eax,%ebx
f010317c:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f010317f:	eb 06                	jmp    f0103187 <strncmp+0x17>
		n--, p++, q++;
f0103181:	83 c0 01             	add    $0x1,%eax
f0103184:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103187:	39 d8                	cmp    %ebx,%eax
f0103189:	74 15                	je     f01031a0 <strncmp+0x30>
f010318b:	0f b6 08             	movzbl (%eax),%ecx
f010318e:	84 c9                	test   %cl,%cl
f0103190:	74 04                	je     f0103196 <strncmp+0x26>
f0103192:	3a 0a                	cmp    (%edx),%cl
f0103194:	74 eb                	je     f0103181 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103196:	0f b6 00             	movzbl (%eax),%eax
f0103199:	0f b6 12             	movzbl (%edx),%edx
f010319c:	29 d0                	sub    %edx,%eax
f010319e:	eb 05                	jmp    f01031a5 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01031a0:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01031a5:	5b                   	pop    %ebx
f01031a6:	5d                   	pop    %ebp
f01031a7:	c3                   	ret    

f01031a8 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01031a8:	55                   	push   %ebp
f01031a9:	89 e5                	mov    %esp,%ebp
f01031ab:	8b 45 08             	mov    0x8(%ebp),%eax
f01031ae:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01031b2:	eb 07                	jmp    f01031bb <strchr+0x13>
		if (*s == c)
f01031b4:	38 ca                	cmp    %cl,%dl
f01031b6:	74 0f                	je     f01031c7 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01031b8:	83 c0 01             	add    $0x1,%eax
f01031bb:	0f b6 10             	movzbl (%eax),%edx
f01031be:	84 d2                	test   %dl,%dl
f01031c0:	75 f2                	jne    f01031b4 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01031c2:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01031c7:	5d                   	pop    %ebp
f01031c8:	c3                   	ret    

f01031c9 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01031c9:	55                   	push   %ebp
f01031ca:	89 e5                	mov    %esp,%ebp
f01031cc:	8b 45 08             	mov    0x8(%ebp),%eax
f01031cf:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01031d3:	eb 03                	jmp    f01031d8 <strfind+0xf>
f01031d5:	83 c0 01             	add    $0x1,%eax
f01031d8:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01031db:	38 ca                	cmp    %cl,%dl
f01031dd:	74 04                	je     f01031e3 <strfind+0x1a>
f01031df:	84 d2                	test   %dl,%dl
f01031e1:	75 f2                	jne    f01031d5 <strfind+0xc>
			break;
	return (char *) s;
}
f01031e3:	5d                   	pop    %ebp
f01031e4:	c3                   	ret    

f01031e5 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01031e5:	55                   	push   %ebp
f01031e6:	89 e5                	mov    %esp,%ebp
f01031e8:	57                   	push   %edi
f01031e9:	56                   	push   %esi
f01031ea:	53                   	push   %ebx
f01031eb:	8b 7d 08             	mov    0x8(%ebp),%edi
f01031ee:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01031f1:	85 c9                	test   %ecx,%ecx
f01031f3:	74 36                	je     f010322b <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01031f5:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01031fb:	75 28                	jne    f0103225 <memset+0x40>
f01031fd:	f6 c1 03             	test   $0x3,%cl
f0103200:	75 23                	jne    f0103225 <memset+0x40>
		c &= 0xFF;
f0103202:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103206:	89 d3                	mov    %edx,%ebx
f0103208:	c1 e3 08             	shl    $0x8,%ebx
f010320b:	89 d6                	mov    %edx,%esi
f010320d:	c1 e6 18             	shl    $0x18,%esi
f0103210:	89 d0                	mov    %edx,%eax
f0103212:	c1 e0 10             	shl    $0x10,%eax
f0103215:	09 f0                	or     %esi,%eax
f0103217:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0103219:	89 d8                	mov    %ebx,%eax
f010321b:	09 d0                	or     %edx,%eax
f010321d:	c1 e9 02             	shr    $0x2,%ecx
f0103220:	fc                   	cld    
f0103221:	f3 ab                	rep stos %eax,%es:(%edi)
f0103223:	eb 06                	jmp    f010322b <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103225:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103228:	fc                   	cld    
f0103229:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010322b:	89 f8                	mov    %edi,%eax
f010322d:	5b                   	pop    %ebx
f010322e:	5e                   	pop    %esi
f010322f:	5f                   	pop    %edi
f0103230:	5d                   	pop    %ebp
f0103231:	c3                   	ret    

f0103232 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103232:	55                   	push   %ebp
f0103233:	89 e5                	mov    %esp,%ebp
f0103235:	57                   	push   %edi
f0103236:	56                   	push   %esi
f0103237:	8b 45 08             	mov    0x8(%ebp),%eax
f010323a:	8b 75 0c             	mov    0xc(%ebp),%esi
f010323d:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103240:	39 c6                	cmp    %eax,%esi
f0103242:	73 35                	jae    f0103279 <memmove+0x47>
f0103244:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103247:	39 d0                	cmp    %edx,%eax
f0103249:	73 2e                	jae    f0103279 <memmove+0x47>
		s += n;
		d += n;
f010324b:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010324e:	89 d6                	mov    %edx,%esi
f0103250:	09 fe                	or     %edi,%esi
f0103252:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103258:	75 13                	jne    f010326d <memmove+0x3b>
f010325a:	f6 c1 03             	test   $0x3,%cl
f010325d:	75 0e                	jne    f010326d <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f010325f:	83 ef 04             	sub    $0x4,%edi
f0103262:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103265:	c1 e9 02             	shr    $0x2,%ecx
f0103268:	fd                   	std    
f0103269:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010326b:	eb 09                	jmp    f0103276 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010326d:	83 ef 01             	sub    $0x1,%edi
f0103270:	8d 72 ff             	lea    -0x1(%edx),%esi
f0103273:	fd                   	std    
f0103274:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103276:	fc                   	cld    
f0103277:	eb 1d                	jmp    f0103296 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103279:	89 f2                	mov    %esi,%edx
f010327b:	09 c2                	or     %eax,%edx
f010327d:	f6 c2 03             	test   $0x3,%dl
f0103280:	75 0f                	jne    f0103291 <memmove+0x5f>
f0103282:	f6 c1 03             	test   $0x3,%cl
f0103285:	75 0a                	jne    f0103291 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0103287:	c1 e9 02             	shr    $0x2,%ecx
f010328a:	89 c7                	mov    %eax,%edi
f010328c:	fc                   	cld    
f010328d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010328f:	eb 05                	jmp    f0103296 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103291:	89 c7                	mov    %eax,%edi
f0103293:	fc                   	cld    
f0103294:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103296:	5e                   	pop    %esi
f0103297:	5f                   	pop    %edi
f0103298:	5d                   	pop    %ebp
f0103299:	c3                   	ret    

f010329a <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010329a:	55                   	push   %ebp
f010329b:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f010329d:	ff 75 10             	pushl  0x10(%ebp)
f01032a0:	ff 75 0c             	pushl  0xc(%ebp)
f01032a3:	ff 75 08             	pushl  0x8(%ebp)
f01032a6:	e8 87 ff ff ff       	call   f0103232 <memmove>
}
f01032ab:	c9                   	leave  
f01032ac:	c3                   	ret    

f01032ad <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01032ad:	55                   	push   %ebp
f01032ae:	89 e5                	mov    %esp,%ebp
f01032b0:	56                   	push   %esi
f01032b1:	53                   	push   %ebx
f01032b2:	8b 45 08             	mov    0x8(%ebp),%eax
f01032b5:	8b 55 0c             	mov    0xc(%ebp),%edx
f01032b8:	89 c6                	mov    %eax,%esi
f01032ba:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01032bd:	eb 1a                	jmp    f01032d9 <memcmp+0x2c>
		if (*s1 != *s2)
f01032bf:	0f b6 08             	movzbl (%eax),%ecx
f01032c2:	0f b6 1a             	movzbl (%edx),%ebx
f01032c5:	38 d9                	cmp    %bl,%cl
f01032c7:	74 0a                	je     f01032d3 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01032c9:	0f b6 c1             	movzbl %cl,%eax
f01032cc:	0f b6 db             	movzbl %bl,%ebx
f01032cf:	29 d8                	sub    %ebx,%eax
f01032d1:	eb 0f                	jmp    f01032e2 <memcmp+0x35>
		s1++, s2++;
f01032d3:	83 c0 01             	add    $0x1,%eax
f01032d6:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01032d9:	39 f0                	cmp    %esi,%eax
f01032db:	75 e2                	jne    f01032bf <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01032dd:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01032e2:	5b                   	pop    %ebx
f01032e3:	5e                   	pop    %esi
f01032e4:	5d                   	pop    %ebp
f01032e5:	c3                   	ret    

f01032e6 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01032e6:	55                   	push   %ebp
f01032e7:	89 e5                	mov    %esp,%ebp
f01032e9:	53                   	push   %ebx
f01032ea:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01032ed:	89 c1                	mov    %eax,%ecx
f01032ef:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f01032f2:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01032f6:	eb 0a                	jmp    f0103302 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f01032f8:	0f b6 10             	movzbl (%eax),%edx
f01032fb:	39 da                	cmp    %ebx,%edx
f01032fd:	74 07                	je     f0103306 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01032ff:	83 c0 01             	add    $0x1,%eax
f0103302:	39 c8                	cmp    %ecx,%eax
f0103304:	72 f2                	jb     f01032f8 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103306:	5b                   	pop    %ebx
f0103307:	5d                   	pop    %ebp
f0103308:	c3                   	ret    

f0103309 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103309:	55                   	push   %ebp
f010330a:	89 e5                	mov    %esp,%ebp
f010330c:	57                   	push   %edi
f010330d:	56                   	push   %esi
f010330e:	53                   	push   %ebx
f010330f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103312:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103315:	eb 03                	jmp    f010331a <strtol+0x11>
		s++;
f0103317:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010331a:	0f b6 01             	movzbl (%ecx),%eax
f010331d:	3c 20                	cmp    $0x20,%al
f010331f:	74 f6                	je     f0103317 <strtol+0xe>
f0103321:	3c 09                	cmp    $0x9,%al
f0103323:	74 f2                	je     f0103317 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103325:	3c 2b                	cmp    $0x2b,%al
f0103327:	75 0a                	jne    f0103333 <strtol+0x2a>
		s++;
f0103329:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f010332c:	bf 00 00 00 00       	mov    $0x0,%edi
f0103331:	eb 11                	jmp    f0103344 <strtol+0x3b>
f0103333:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103338:	3c 2d                	cmp    $0x2d,%al
f010333a:	75 08                	jne    f0103344 <strtol+0x3b>
		s++, neg = 1;
f010333c:	83 c1 01             	add    $0x1,%ecx
f010333f:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103344:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f010334a:	75 15                	jne    f0103361 <strtol+0x58>
f010334c:	80 39 30             	cmpb   $0x30,(%ecx)
f010334f:	75 10                	jne    f0103361 <strtol+0x58>
f0103351:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0103355:	75 7c                	jne    f01033d3 <strtol+0xca>
		s += 2, base = 16;
f0103357:	83 c1 02             	add    $0x2,%ecx
f010335a:	bb 10 00 00 00       	mov    $0x10,%ebx
f010335f:	eb 16                	jmp    f0103377 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0103361:	85 db                	test   %ebx,%ebx
f0103363:	75 12                	jne    f0103377 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103365:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010336a:	80 39 30             	cmpb   $0x30,(%ecx)
f010336d:	75 08                	jne    f0103377 <strtol+0x6e>
		s++, base = 8;
f010336f:	83 c1 01             	add    $0x1,%ecx
f0103372:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0103377:	b8 00 00 00 00       	mov    $0x0,%eax
f010337c:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f010337f:	0f b6 11             	movzbl (%ecx),%edx
f0103382:	8d 72 d0             	lea    -0x30(%edx),%esi
f0103385:	89 f3                	mov    %esi,%ebx
f0103387:	80 fb 09             	cmp    $0x9,%bl
f010338a:	77 08                	ja     f0103394 <strtol+0x8b>
			dig = *s - '0';
f010338c:	0f be d2             	movsbl %dl,%edx
f010338f:	83 ea 30             	sub    $0x30,%edx
f0103392:	eb 22                	jmp    f01033b6 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0103394:	8d 72 9f             	lea    -0x61(%edx),%esi
f0103397:	89 f3                	mov    %esi,%ebx
f0103399:	80 fb 19             	cmp    $0x19,%bl
f010339c:	77 08                	ja     f01033a6 <strtol+0x9d>
			dig = *s - 'a' + 10;
f010339e:	0f be d2             	movsbl %dl,%edx
f01033a1:	83 ea 57             	sub    $0x57,%edx
f01033a4:	eb 10                	jmp    f01033b6 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f01033a6:	8d 72 bf             	lea    -0x41(%edx),%esi
f01033a9:	89 f3                	mov    %esi,%ebx
f01033ab:	80 fb 19             	cmp    $0x19,%bl
f01033ae:	77 16                	ja     f01033c6 <strtol+0xbd>
			dig = *s - 'A' + 10;
f01033b0:	0f be d2             	movsbl %dl,%edx
f01033b3:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f01033b6:	3b 55 10             	cmp    0x10(%ebp),%edx
f01033b9:	7d 0b                	jge    f01033c6 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f01033bb:	83 c1 01             	add    $0x1,%ecx
f01033be:	0f af 45 10          	imul   0x10(%ebp),%eax
f01033c2:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f01033c4:	eb b9                	jmp    f010337f <strtol+0x76>

	if (endptr)
f01033c6:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01033ca:	74 0d                	je     f01033d9 <strtol+0xd0>
		*endptr = (char *) s;
f01033cc:	8b 75 0c             	mov    0xc(%ebp),%esi
f01033cf:	89 0e                	mov    %ecx,(%esi)
f01033d1:	eb 06                	jmp    f01033d9 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01033d3:	85 db                	test   %ebx,%ebx
f01033d5:	74 98                	je     f010336f <strtol+0x66>
f01033d7:	eb 9e                	jmp    f0103377 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01033d9:	89 c2                	mov    %eax,%edx
f01033db:	f7 da                	neg    %edx
f01033dd:	85 ff                	test   %edi,%edi
f01033df:	0f 45 c2             	cmovne %edx,%eax
}
f01033e2:	5b                   	pop    %ebx
f01033e3:	5e                   	pop    %esi
f01033e4:	5f                   	pop    %edi
f01033e5:	5d                   	pop    %ebp
f01033e6:	c3                   	ret    
f01033e7:	66 90                	xchg   %ax,%ax
f01033e9:	66 90                	xchg   %ax,%ax
f01033eb:	66 90                	xchg   %ax,%ax
f01033ed:	66 90                	xchg   %ax,%ax
f01033ef:	90                   	nop

f01033f0 <__udivdi3>:
f01033f0:	55                   	push   %ebp
f01033f1:	57                   	push   %edi
f01033f2:	56                   	push   %esi
f01033f3:	53                   	push   %ebx
f01033f4:	83 ec 1c             	sub    $0x1c,%esp
f01033f7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f01033fb:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f01033ff:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0103403:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103407:	85 f6                	test   %esi,%esi
f0103409:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010340d:	89 ca                	mov    %ecx,%edx
f010340f:	89 f8                	mov    %edi,%eax
f0103411:	75 3d                	jne    f0103450 <__udivdi3+0x60>
f0103413:	39 cf                	cmp    %ecx,%edi
f0103415:	0f 87 c5 00 00 00    	ja     f01034e0 <__udivdi3+0xf0>
f010341b:	85 ff                	test   %edi,%edi
f010341d:	89 fd                	mov    %edi,%ebp
f010341f:	75 0b                	jne    f010342c <__udivdi3+0x3c>
f0103421:	b8 01 00 00 00       	mov    $0x1,%eax
f0103426:	31 d2                	xor    %edx,%edx
f0103428:	f7 f7                	div    %edi
f010342a:	89 c5                	mov    %eax,%ebp
f010342c:	89 c8                	mov    %ecx,%eax
f010342e:	31 d2                	xor    %edx,%edx
f0103430:	f7 f5                	div    %ebp
f0103432:	89 c1                	mov    %eax,%ecx
f0103434:	89 d8                	mov    %ebx,%eax
f0103436:	89 cf                	mov    %ecx,%edi
f0103438:	f7 f5                	div    %ebp
f010343a:	89 c3                	mov    %eax,%ebx
f010343c:	89 d8                	mov    %ebx,%eax
f010343e:	89 fa                	mov    %edi,%edx
f0103440:	83 c4 1c             	add    $0x1c,%esp
f0103443:	5b                   	pop    %ebx
f0103444:	5e                   	pop    %esi
f0103445:	5f                   	pop    %edi
f0103446:	5d                   	pop    %ebp
f0103447:	c3                   	ret    
f0103448:	90                   	nop
f0103449:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103450:	39 ce                	cmp    %ecx,%esi
f0103452:	77 74                	ja     f01034c8 <__udivdi3+0xd8>
f0103454:	0f bd fe             	bsr    %esi,%edi
f0103457:	83 f7 1f             	xor    $0x1f,%edi
f010345a:	0f 84 98 00 00 00    	je     f01034f8 <__udivdi3+0x108>
f0103460:	bb 20 00 00 00       	mov    $0x20,%ebx
f0103465:	89 f9                	mov    %edi,%ecx
f0103467:	89 c5                	mov    %eax,%ebp
f0103469:	29 fb                	sub    %edi,%ebx
f010346b:	d3 e6                	shl    %cl,%esi
f010346d:	89 d9                	mov    %ebx,%ecx
f010346f:	d3 ed                	shr    %cl,%ebp
f0103471:	89 f9                	mov    %edi,%ecx
f0103473:	d3 e0                	shl    %cl,%eax
f0103475:	09 ee                	or     %ebp,%esi
f0103477:	89 d9                	mov    %ebx,%ecx
f0103479:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010347d:	89 d5                	mov    %edx,%ebp
f010347f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103483:	d3 ed                	shr    %cl,%ebp
f0103485:	89 f9                	mov    %edi,%ecx
f0103487:	d3 e2                	shl    %cl,%edx
f0103489:	89 d9                	mov    %ebx,%ecx
f010348b:	d3 e8                	shr    %cl,%eax
f010348d:	09 c2                	or     %eax,%edx
f010348f:	89 d0                	mov    %edx,%eax
f0103491:	89 ea                	mov    %ebp,%edx
f0103493:	f7 f6                	div    %esi
f0103495:	89 d5                	mov    %edx,%ebp
f0103497:	89 c3                	mov    %eax,%ebx
f0103499:	f7 64 24 0c          	mull   0xc(%esp)
f010349d:	39 d5                	cmp    %edx,%ebp
f010349f:	72 10                	jb     f01034b1 <__udivdi3+0xc1>
f01034a1:	8b 74 24 08          	mov    0x8(%esp),%esi
f01034a5:	89 f9                	mov    %edi,%ecx
f01034a7:	d3 e6                	shl    %cl,%esi
f01034a9:	39 c6                	cmp    %eax,%esi
f01034ab:	73 07                	jae    f01034b4 <__udivdi3+0xc4>
f01034ad:	39 d5                	cmp    %edx,%ebp
f01034af:	75 03                	jne    f01034b4 <__udivdi3+0xc4>
f01034b1:	83 eb 01             	sub    $0x1,%ebx
f01034b4:	31 ff                	xor    %edi,%edi
f01034b6:	89 d8                	mov    %ebx,%eax
f01034b8:	89 fa                	mov    %edi,%edx
f01034ba:	83 c4 1c             	add    $0x1c,%esp
f01034bd:	5b                   	pop    %ebx
f01034be:	5e                   	pop    %esi
f01034bf:	5f                   	pop    %edi
f01034c0:	5d                   	pop    %ebp
f01034c1:	c3                   	ret    
f01034c2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01034c8:	31 ff                	xor    %edi,%edi
f01034ca:	31 db                	xor    %ebx,%ebx
f01034cc:	89 d8                	mov    %ebx,%eax
f01034ce:	89 fa                	mov    %edi,%edx
f01034d0:	83 c4 1c             	add    $0x1c,%esp
f01034d3:	5b                   	pop    %ebx
f01034d4:	5e                   	pop    %esi
f01034d5:	5f                   	pop    %edi
f01034d6:	5d                   	pop    %ebp
f01034d7:	c3                   	ret    
f01034d8:	90                   	nop
f01034d9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01034e0:	89 d8                	mov    %ebx,%eax
f01034e2:	f7 f7                	div    %edi
f01034e4:	31 ff                	xor    %edi,%edi
f01034e6:	89 c3                	mov    %eax,%ebx
f01034e8:	89 d8                	mov    %ebx,%eax
f01034ea:	89 fa                	mov    %edi,%edx
f01034ec:	83 c4 1c             	add    $0x1c,%esp
f01034ef:	5b                   	pop    %ebx
f01034f0:	5e                   	pop    %esi
f01034f1:	5f                   	pop    %edi
f01034f2:	5d                   	pop    %ebp
f01034f3:	c3                   	ret    
f01034f4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01034f8:	39 ce                	cmp    %ecx,%esi
f01034fa:	72 0c                	jb     f0103508 <__udivdi3+0x118>
f01034fc:	31 db                	xor    %ebx,%ebx
f01034fe:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0103502:	0f 87 34 ff ff ff    	ja     f010343c <__udivdi3+0x4c>
f0103508:	bb 01 00 00 00       	mov    $0x1,%ebx
f010350d:	e9 2a ff ff ff       	jmp    f010343c <__udivdi3+0x4c>
f0103512:	66 90                	xchg   %ax,%ax
f0103514:	66 90                	xchg   %ax,%ax
f0103516:	66 90                	xchg   %ax,%ax
f0103518:	66 90                	xchg   %ax,%ax
f010351a:	66 90                	xchg   %ax,%ax
f010351c:	66 90                	xchg   %ax,%ax
f010351e:	66 90                	xchg   %ax,%ax

f0103520 <__umoddi3>:
f0103520:	55                   	push   %ebp
f0103521:	57                   	push   %edi
f0103522:	56                   	push   %esi
f0103523:	53                   	push   %ebx
f0103524:	83 ec 1c             	sub    $0x1c,%esp
f0103527:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010352b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010352f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0103533:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103537:	85 d2                	test   %edx,%edx
f0103539:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010353d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103541:	89 f3                	mov    %esi,%ebx
f0103543:	89 3c 24             	mov    %edi,(%esp)
f0103546:	89 74 24 04          	mov    %esi,0x4(%esp)
f010354a:	75 1c                	jne    f0103568 <__umoddi3+0x48>
f010354c:	39 f7                	cmp    %esi,%edi
f010354e:	76 50                	jbe    f01035a0 <__umoddi3+0x80>
f0103550:	89 c8                	mov    %ecx,%eax
f0103552:	89 f2                	mov    %esi,%edx
f0103554:	f7 f7                	div    %edi
f0103556:	89 d0                	mov    %edx,%eax
f0103558:	31 d2                	xor    %edx,%edx
f010355a:	83 c4 1c             	add    $0x1c,%esp
f010355d:	5b                   	pop    %ebx
f010355e:	5e                   	pop    %esi
f010355f:	5f                   	pop    %edi
f0103560:	5d                   	pop    %ebp
f0103561:	c3                   	ret    
f0103562:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103568:	39 f2                	cmp    %esi,%edx
f010356a:	89 d0                	mov    %edx,%eax
f010356c:	77 52                	ja     f01035c0 <__umoddi3+0xa0>
f010356e:	0f bd ea             	bsr    %edx,%ebp
f0103571:	83 f5 1f             	xor    $0x1f,%ebp
f0103574:	75 5a                	jne    f01035d0 <__umoddi3+0xb0>
f0103576:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010357a:	0f 82 e0 00 00 00    	jb     f0103660 <__umoddi3+0x140>
f0103580:	39 0c 24             	cmp    %ecx,(%esp)
f0103583:	0f 86 d7 00 00 00    	jbe    f0103660 <__umoddi3+0x140>
f0103589:	8b 44 24 08          	mov    0x8(%esp),%eax
f010358d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103591:	83 c4 1c             	add    $0x1c,%esp
f0103594:	5b                   	pop    %ebx
f0103595:	5e                   	pop    %esi
f0103596:	5f                   	pop    %edi
f0103597:	5d                   	pop    %ebp
f0103598:	c3                   	ret    
f0103599:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01035a0:	85 ff                	test   %edi,%edi
f01035a2:	89 fd                	mov    %edi,%ebp
f01035a4:	75 0b                	jne    f01035b1 <__umoddi3+0x91>
f01035a6:	b8 01 00 00 00       	mov    $0x1,%eax
f01035ab:	31 d2                	xor    %edx,%edx
f01035ad:	f7 f7                	div    %edi
f01035af:	89 c5                	mov    %eax,%ebp
f01035b1:	89 f0                	mov    %esi,%eax
f01035b3:	31 d2                	xor    %edx,%edx
f01035b5:	f7 f5                	div    %ebp
f01035b7:	89 c8                	mov    %ecx,%eax
f01035b9:	f7 f5                	div    %ebp
f01035bb:	89 d0                	mov    %edx,%eax
f01035bd:	eb 99                	jmp    f0103558 <__umoddi3+0x38>
f01035bf:	90                   	nop
f01035c0:	89 c8                	mov    %ecx,%eax
f01035c2:	89 f2                	mov    %esi,%edx
f01035c4:	83 c4 1c             	add    $0x1c,%esp
f01035c7:	5b                   	pop    %ebx
f01035c8:	5e                   	pop    %esi
f01035c9:	5f                   	pop    %edi
f01035ca:	5d                   	pop    %ebp
f01035cb:	c3                   	ret    
f01035cc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01035d0:	8b 34 24             	mov    (%esp),%esi
f01035d3:	bf 20 00 00 00       	mov    $0x20,%edi
f01035d8:	89 e9                	mov    %ebp,%ecx
f01035da:	29 ef                	sub    %ebp,%edi
f01035dc:	d3 e0                	shl    %cl,%eax
f01035de:	89 f9                	mov    %edi,%ecx
f01035e0:	89 f2                	mov    %esi,%edx
f01035e2:	d3 ea                	shr    %cl,%edx
f01035e4:	89 e9                	mov    %ebp,%ecx
f01035e6:	09 c2                	or     %eax,%edx
f01035e8:	89 d8                	mov    %ebx,%eax
f01035ea:	89 14 24             	mov    %edx,(%esp)
f01035ed:	89 f2                	mov    %esi,%edx
f01035ef:	d3 e2                	shl    %cl,%edx
f01035f1:	89 f9                	mov    %edi,%ecx
f01035f3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01035f7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01035fb:	d3 e8                	shr    %cl,%eax
f01035fd:	89 e9                	mov    %ebp,%ecx
f01035ff:	89 c6                	mov    %eax,%esi
f0103601:	d3 e3                	shl    %cl,%ebx
f0103603:	89 f9                	mov    %edi,%ecx
f0103605:	89 d0                	mov    %edx,%eax
f0103607:	d3 e8                	shr    %cl,%eax
f0103609:	89 e9                	mov    %ebp,%ecx
f010360b:	09 d8                	or     %ebx,%eax
f010360d:	89 d3                	mov    %edx,%ebx
f010360f:	89 f2                	mov    %esi,%edx
f0103611:	f7 34 24             	divl   (%esp)
f0103614:	89 d6                	mov    %edx,%esi
f0103616:	d3 e3                	shl    %cl,%ebx
f0103618:	f7 64 24 04          	mull   0x4(%esp)
f010361c:	39 d6                	cmp    %edx,%esi
f010361e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103622:	89 d1                	mov    %edx,%ecx
f0103624:	89 c3                	mov    %eax,%ebx
f0103626:	72 08                	jb     f0103630 <__umoddi3+0x110>
f0103628:	75 11                	jne    f010363b <__umoddi3+0x11b>
f010362a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010362e:	73 0b                	jae    f010363b <__umoddi3+0x11b>
f0103630:	2b 44 24 04          	sub    0x4(%esp),%eax
f0103634:	1b 14 24             	sbb    (%esp),%edx
f0103637:	89 d1                	mov    %edx,%ecx
f0103639:	89 c3                	mov    %eax,%ebx
f010363b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010363f:	29 da                	sub    %ebx,%edx
f0103641:	19 ce                	sbb    %ecx,%esi
f0103643:	89 f9                	mov    %edi,%ecx
f0103645:	89 f0                	mov    %esi,%eax
f0103647:	d3 e0                	shl    %cl,%eax
f0103649:	89 e9                	mov    %ebp,%ecx
f010364b:	d3 ea                	shr    %cl,%edx
f010364d:	89 e9                	mov    %ebp,%ecx
f010364f:	d3 ee                	shr    %cl,%esi
f0103651:	09 d0                	or     %edx,%eax
f0103653:	89 f2                	mov    %esi,%edx
f0103655:	83 c4 1c             	add    $0x1c,%esp
f0103658:	5b                   	pop    %ebx
f0103659:	5e                   	pop    %esi
f010365a:	5f                   	pop    %edi
f010365b:	5d                   	pop    %ebp
f010365c:	c3                   	ret    
f010365d:	8d 76 00             	lea    0x0(%esi),%esi
f0103660:	29 f9                	sub    %edi,%ecx
f0103662:	19 d6                	sbb    %edx,%esi
f0103664:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103668:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010366c:	e9 18 ff ff ff       	jmp    f0103589 <__umoddi3+0x69>
