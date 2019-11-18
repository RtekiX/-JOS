
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
f0100015:	b8 00 90 11 00       	mov    $0x119000,%eax
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
f0100034:	bc 00 90 11 f0       	mov    $0xf0119000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/trap.h>


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
f0100046:	b8 50 5c 17 f0       	mov    $0xf0175c50,%eax
f010004b:	2d 26 4d 17 f0       	sub    $0xf0174d26,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 26 4d 17 f0       	push   $0xf0174d26
f0100058:	e8 d9 42 00 00       	call   f0104336 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 9d 04 00 00       	call   f01004ff <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 e0 47 10 f0       	push   $0xf01047e0
f010006f:	e8 51 2f 00 00       	call   f0102fc5 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 3d 10 00 00       	call   f01010b6 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100079:	e8 94 29 00 00       	call   f0102a12 <env_init>
	trap_init();
f010007e:	e8 b3 2f 00 00       	call   f0103036 <trap_init>
#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
#else
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
f0100083:	83 c4 08             	add    $0x8,%esp
f0100086:	6a 00                	push   $0x0
f0100088:	68 56 b3 11 f0       	push   $0xf011b356
f010008d:	e8 2d 2b 00 00       	call   f0102bbf <env_create>
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f0100092:	83 c4 04             	add    $0x4,%esp
f0100095:	ff 35 8c 4f 17 f0    	pushl  0xf0174f8c
f010009b:	e8 5c 2e 00 00       	call   f0102efc <env_run>

f01000a0 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000a0:	55                   	push   %ebp
f01000a1:	89 e5                	mov    %esp,%ebp
f01000a3:	56                   	push   %esi
f01000a4:	53                   	push   %ebx
f01000a5:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000a8:	83 3d 40 5c 17 f0 00 	cmpl   $0x0,0xf0175c40
f01000af:	75 37                	jne    f01000e8 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000b1:	89 35 40 5c 17 f0    	mov    %esi,0xf0175c40

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000b7:	fa                   	cli    
f01000b8:	fc                   	cld    

	va_start(ap, fmt);
f01000b9:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000bc:	83 ec 04             	sub    $0x4,%esp
f01000bf:	ff 75 0c             	pushl  0xc(%ebp)
f01000c2:	ff 75 08             	pushl  0x8(%ebp)
f01000c5:	68 fb 47 10 f0       	push   $0xf01047fb
f01000ca:	e8 f6 2e 00 00       	call   f0102fc5 <cprintf>
	vcprintf(fmt, ap);
f01000cf:	83 c4 08             	add    $0x8,%esp
f01000d2:	53                   	push   %ebx
f01000d3:	56                   	push   %esi
f01000d4:	e8 c6 2e 00 00       	call   f0102f9f <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 93 4f 10 f0 	movl   $0xf0104f93,(%esp)
f01000e0:	e8 e0 2e 00 00       	call   f0102fc5 <cprintf>
	va_end(ap);
f01000e5:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e8:	83 ec 0c             	sub    $0xc,%esp
f01000eb:	6a 00                	push   $0x0
f01000ed:	e8 aa 06 00 00       	call   f010079c <monitor>
f01000f2:	83 c4 10             	add    $0x10,%esp
f01000f5:	eb f1                	jmp    f01000e8 <_panic+0x48>

f01000f7 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000f7:	55                   	push   %ebp
f01000f8:	89 e5                	mov    %esp,%ebp
f01000fa:	53                   	push   %ebx
f01000fb:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000fe:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100101:	ff 75 0c             	pushl  0xc(%ebp)
f0100104:	ff 75 08             	pushl  0x8(%ebp)
f0100107:	68 13 48 10 f0       	push   $0xf0104813
f010010c:	e8 b4 2e 00 00       	call   f0102fc5 <cprintf>
	vcprintf(fmt, ap);
f0100111:	83 c4 08             	add    $0x8,%esp
f0100114:	53                   	push   %ebx
f0100115:	ff 75 10             	pushl  0x10(%ebp)
f0100118:	e8 82 2e 00 00       	call   f0102f9f <vcprintf>
	cprintf("\n");
f010011d:	c7 04 24 93 4f 10 f0 	movl   $0xf0104f93,(%esp)
f0100124:	e8 9c 2e 00 00       	call   f0102fc5 <cprintf>
	va_end(ap);
}
f0100129:	83 c4 10             	add    $0x10,%esp
f010012c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010012f:	c9                   	leave  
f0100130:	c3                   	ret    

f0100131 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100131:	55                   	push   %ebp
f0100132:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100134:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100139:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010013a:	a8 01                	test   $0x1,%al
f010013c:	74 0b                	je     f0100149 <serial_proc_data+0x18>
f010013e:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100143:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100144:	0f b6 c0             	movzbl %al,%eax
f0100147:	eb 05                	jmp    f010014e <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100149:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f010014e:	5d                   	pop    %ebp
f010014f:	c3                   	ret    

f0100150 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100150:	55                   	push   %ebp
f0100151:	89 e5                	mov    %esp,%ebp
f0100153:	53                   	push   %ebx
f0100154:	83 ec 04             	sub    $0x4,%esp
f0100157:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100159:	eb 2b                	jmp    f0100186 <cons_intr+0x36>
		if (c == 0)
f010015b:	85 c0                	test   %eax,%eax
f010015d:	74 27                	je     f0100186 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f010015f:	8b 0d 64 4f 17 f0    	mov    0xf0174f64,%ecx
f0100165:	8d 51 01             	lea    0x1(%ecx),%edx
f0100168:	89 15 64 4f 17 f0    	mov    %edx,0xf0174f64
f010016e:	88 81 60 4d 17 f0    	mov    %al,-0xfe8b2a0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f0100174:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010017a:	75 0a                	jne    f0100186 <cons_intr+0x36>
			cons.wpos = 0;
f010017c:	c7 05 64 4f 17 f0 00 	movl   $0x0,0xf0174f64
f0100183:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100186:	ff d3                	call   *%ebx
f0100188:	83 f8 ff             	cmp    $0xffffffff,%eax
f010018b:	75 ce                	jne    f010015b <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f010018d:	83 c4 04             	add    $0x4,%esp
f0100190:	5b                   	pop    %ebx
f0100191:	5d                   	pop    %ebp
f0100192:	c3                   	ret    

f0100193 <kbd_proc_data>:
f0100193:	ba 64 00 00 00       	mov    $0x64,%edx
f0100198:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100199:	a8 01                	test   $0x1,%al
f010019b:	0f 84 f0 00 00 00    	je     f0100291 <kbd_proc_data+0xfe>
f01001a1:	ba 60 00 00 00       	mov    $0x60,%edx
f01001a6:	ec                   	in     (%dx),%al
f01001a7:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001a9:	3c e0                	cmp    $0xe0,%al
f01001ab:	75 0d                	jne    f01001ba <kbd_proc_data+0x27>
		// E0 escape character
		shift |= E0ESC;
f01001ad:	83 0d 40 4d 17 f0 40 	orl    $0x40,0xf0174d40
		return 0;
f01001b4:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001b9:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001ba:	55                   	push   %ebp
f01001bb:	89 e5                	mov    %esp,%ebp
f01001bd:	53                   	push   %ebx
f01001be:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001c1:	84 c0                	test   %al,%al
f01001c3:	79 36                	jns    f01001fb <kbd_proc_data+0x68>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001c5:	8b 0d 40 4d 17 f0    	mov    0xf0174d40,%ecx
f01001cb:	89 cb                	mov    %ecx,%ebx
f01001cd:	83 e3 40             	and    $0x40,%ebx
f01001d0:	83 e0 7f             	and    $0x7f,%eax
f01001d3:	85 db                	test   %ebx,%ebx
f01001d5:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001d8:	0f b6 d2             	movzbl %dl,%edx
f01001db:	0f b6 82 80 49 10 f0 	movzbl -0xfefb680(%edx),%eax
f01001e2:	83 c8 40             	or     $0x40,%eax
f01001e5:	0f b6 c0             	movzbl %al,%eax
f01001e8:	f7 d0                	not    %eax
f01001ea:	21 c8                	and    %ecx,%eax
f01001ec:	a3 40 4d 17 f0       	mov    %eax,0xf0174d40
		return 0;
f01001f1:	b8 00 00 00 00       	mov    $0x0,%eax
f01001f6:	e9 9e 00 00 00       	jmp    f0100299 <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f01001fb:	8b 0d 40 4d 17 f0    	mov    0xf0174d40,%ecx
f0100201:	f6 c1 40             	test   $0x40,%cl
f0100204:	74 0e                	je     f0100214 <kbd_proc_data+0x81>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100206:	83 c8 80             	or     $0xffffff80,%eax
f0100209:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010020b:	83 e1 bf             	and    $0xffffffbf,%ecx
f010020e:	89 0d 40 4d 17 f0    	mov    %ecx,0xf0174d40
	}

	shift |= shiftcode[data];
f0100214:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100217:	0f b6 82 80 49 10 f0 	movzbl -0xfefb680(%edx),%eax
f010021e:	0b 05 40 4d 17 f0    	or     0xf0174d40,%eax
f0100224:	0f b6 8a 80 48 10 f0 	movzbl -0xfefb780(%edx),%ecx
f010022b:	31 c8                	xor    %ecx,%eax
f010022d:	a3 40 4d 17 f0       	mov    %eax,0xf0174d40

	c = charcode[shift & (CTL | SHIFT)][data];
f0100232:	89 c1                	mov    %eax,%ecx
f0100234:	83 e1 03             	and    $0x3,%ecx
f0100237:	8b 0c 8d 60 48 10 f0 	mov    -0xfefb7a0(,%ecx,4),%ecx
f010023e:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100242:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100245:	a8 08                	test   $0x8,%al
f0100247:	74 1b                	je     f0100264 <kbd_proc_data+0xd1>
		if ('a' <= c && c <= 'z')
f0100249:	89 da                	mov    %ebx,%edx
f010024b:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f010024e:	83 f9 19             	cmp    $0x19,%ecx
f0100251:	77 05                	ja     f0100258 <kbd_proc_data+0xc5>
			c += 'A' - 'a';
f0100253:	83 eb 20             	sub    $0x20,%ebx
f0100256:	eb 0c                	jmp    f0100264 <kbd_proc_data+0xd1>
		else if ('A' <= c && c <= 'Z')
f0100258:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f010025b:	8d 4b 20             	lea    0x20(%ebx),%ecx
f010025e:	83 fa 19             	cmp    $0x19,%edx
f0100261:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100264:	f7 d0                	not    %eax
f0100266:	a8 06                	test   $0x6,%al
f0100268:	75 2d                	jne    f0100297 <kbd_proc_data+0x104>
f010026a:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100270:	75 25                	jne    f0100297 <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f0100272:	83 ec 0c             	sub    $0xc,%esp
f0100275:	68 2d 48 10 f0       	push   $0xf010482d
f010027a:	e8 46 2d 00 00       	call   f0102fc5 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010027f:	ba 92 00 00 00       	mov    $0x92,%edx
f0100284:	b8 03 00 00 00       	mov    $0x3,%eax
f0100289:	ee                   	out    %al,(%dx)
f010028a:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f010028d:	89 d8                	mov    %ebx,%eax
f010028f:	eb 08                	jmp    f0100299 <kbd_proc_data+0x106>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f0100291:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100296:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100297:	89 d8                	mov    %ebx,%eax
}
f0100299:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010029c:	c9                   	leave  
f010029d:	c3                   	ret    

f010029e <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f010029e:	55                   	push   %ebp
f010029f:	89 e5                	mov    %esp,%ebp
f01002a1:	57                   	push   %edi
f01002a2:	56                   	push   %esi
f01002a3:	53                   	push   %ebx
f01002a4:	83 ec 1c             	sub    $0x1c,%esp
f01002a7:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002a9:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002ae:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002b3:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002b8:	eb 09                	jmp    f01002c3 <cons_putc+0x25>
f01002ba:	89 ca                	mov    %ecx,%edx
f01002bc:	ec                   	in     (%dx),%al
f01002bd:	ec                   	in     (%dx),%al
f01002be:	ec                   	in     (%dx),%al
f01002bf:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002c0:	83 c3 01             	add    $0x1,%ebx
f01002c3:	89 f2                	mov    %esi,%edx
f01002c5:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002c6:	a8 20                	test   $0x20,%al
f01002c8:	75 08                	jne    f01002d2 <cons_putc+0x34>
f01002ca:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002d0:	7e e8                	jle    f01002ba <cons_putc+0x1c>
f01002d2:	89 f8                	mov    %edi,%eax
f01002d4:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002d7:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002dc:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002dd:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002e2:	be 79 03 00 00       	mov    $0x379,%esi
f01002e7:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002ec:	eb 09                	jmp    f01002f7 <cons_putc+0x59>
f01002ee:	89 ca                	mov    %ecx,%edx
f01002f0:	ec                   	in     (%dx),%al
f01002f1:	ec                   	in     (%dx),%al
f01002f2:	ec                   	in     (%dx),%al
f01002f3:	ec                   	in     (%dx),%al
f01002f4:	83 c3 01             	add    $0x1,%ebx
f01002f7:	89 f2                	mov    %esi,%edx
f01002f9:	ec                   	in     (%dx),%al
f01002fa:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100300:	7f 04                	jg     f0100306 <cons_putc+0x68>
f0100302:	84 c0                	test   %al,%al
f0100304:	79 e8                	jns    f01002ee <cons_putc+0x50>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100306:	ba 78 03 00 00       	mov    $0x378,%edx
f010030b:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010030f:	ee                   	out    %al,(%dx)
f0100310:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100315:	b8 0d 00 00 00       	mov    $0xd,%eax
f010031a:	ee                   	out    %al,(%dx)
f010031b:	b8 08 00 00 00       	mov    $0x8,%eax
f0100320:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100321:	89 fa                	mov    %edi,%edx
f0100323:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100329:	89 f8                	mov    %edi,%eax
f010032b:	80 cc 07             	or     $0x7,%ah
f010032e:	85 d2                	test   %edx,%edx
f0100330:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100333:	89 f8                	mov    %edi,%eax
f0100335:	0f b6 c0             	movzbl %al,%eax
f0100338:	83 f8 09             	cmp    $0x9,%eax
f010033b:	74 74                	je     f01003b1 <cons_putc+0x113>
f010033d:	83 f8 09             	cmp    $0x9,%eax
f0100340:	7f 0a                	jg     f010034c <cons_putc+0xae>
f0100342:	83 f8 08             	cmp    $0x8,%eax
f0100345:	74 14                	je     f010035b <cons_putc+0xbd>
f0100347:	e9 99 00 00 00       	jmp    f01003e5 <cons_putc+0x147>
f010034c:	83 f8 0a             	cmp    $0xa,%eax
f010034f:	74 3a                	je     f010038b <cons_putc+0xed>
f0100351:	83 f8 0d             	cmp    $0xd,%eax
f0100354:	74 3d                	je     f0100393 <cons_putc+0xf5>
f0100356:	e9 8a 00 00 00       	jmp    f01003e5 <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f010035b:	0f b7 05 68 4f 17 f0 	movzwl 0xf0174f68,%eax
f0100362:	66 85 c0             	test   %ax,%ax
f0100365:	0f 84 e6 00 00 00    	je     f0100451 <cons_putc+0x1b3>
			crt_pos--;
f010036b:	83 e8 01             	sub    $0x1,%eax
f010036e:	66 a3 68 4f 17 f0    	mov    %ax,0xf0174f68
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100374:	0f b7 c0             	movzwl %ax,%eax
f0100377:	66 81 e7 00 ff       	and    $0xff00,%di
f010037c:	83 cf 20             	or     $0x20,%edi
f010037f:	8b 15 6c 4f 17 f0    	mov    0xf0174f6c,%edx
f0100385:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100389:	eb 78                	jmp    f0100403 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f010038b:	66 83 05 68 4f 17 f0 	addw   $0x50,0xf0174f68
f0100392:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100393:	0f b7 05 68 4f 17 f0 	movzwl 0xf0174f68,%eax
f010039a:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003a0:	c1 e8 16             	shr    $0x16,%eax
f01003a3:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003a6:	c1 e0 04             	shl    $0x4,%eax
f01003a9:	66 a3 68 4f 17 f0    	mov    %ax,0xf0174f68
f01003af:	eb 52                	jmp    f0100403 <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f01003b1:	b8 20 00 00 00       	mov    $0x20,%eax
f01003b6:	e8 e3 fe ff ff       	call   f010029e <cons_putc>
		cons_putc(' ');
f01003bb:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c0:	e8 d9 fe ff ff       	call   f010029e <cons_putc>
		cons_putc(' ');
f01003c5:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ca:	e8 cf fe ff ff       	call   f010029e <cons_putc>
		cons_putc(' ');
f01003cf:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d4:	e8 c5 fe ff ff       	call   f010029e <cons_putc>
		cons_putc(' ');
f01003d9:	b8 20 00 00 00       	mov    $0x20,%eax
f01003de:	e8 bb fe ff ff       	call   f010029e <cons_putc>
f01003e3:	eb 1e                	jmp    f0100403 <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003e5:	0f b7 05 68 4f 17 f0 	movzwl 0xf0174f68,%eax
f01003ec:	8d 50 01             	lea    0x1(%eax),%edx
f01003ef:	66 89 15 68 4f 17 f0 	mov    %dx,0xf0174f68
f01003f6:	0f b7 c0             	movzwl %ax,%eax
f01003f9:	8b 15 6c 4f 17 f0    	mov    0xf0174f6c,%edx
f01003ff:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100403:	66 81 3d 68 4f 17 f0 	cmpw   $0x7cf,0xf0174f68
f010040a:	cf 07 
f010040c:	76 43                	jbe    f0100451 <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010040e:	a1 6c 4f 17 f0       	mov    0xf0174f6c,%eax
f0100413:	83 ec 04             	sub    $0x4,%esp
f0100416:	68 00 0f 00 00       	push   $0xf00
f010041b:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100421:	52                   	push   %edx
f0100422:	50                   	push   %eax
f0100423:	e8 5b 3f 00 00       	call   f0104383 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100428:	8b 15 6c 4f 17 f0    	mov    0xf0174f6c,%edx
f010042e:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100434:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f010043a:	83 c4 10             	add    $0x10,%esp
f010043d:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100442:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100445:	39 d0                	cmp    %edx,%eax
f0100447:	75 f4                	jne    f010043d <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100449:	66 83 2d 68 4f 17 f0 	subw   $0x50,0xf0174f68
f0100450:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100451:	8b 0d 70 4f 17 f0    	mov    0xf0174f70,%ecx
f0100457:	b8 0e 00 00 00       	mov    $0xe,%eax
f010045c:	89 ca                	mov    %ecx,%edx
f010045e:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010045f:	0f b7 1d 68 4f 17 f0 	movzwl 0xf0174f68,%ebx
f0100466:	8d 71 01             	lea    0x1(%ecx),%esi
f0100469:	89 d8                	mov    %ebx,%eax
f010046b:	66 c1 e8 08          	shr    $0x8,%ax
f010046f:	89 f2                	mov    %esi,%edx
f0100471:	ee                   	out    %al,(%dx)
f0100472:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100477:	89 ca                	mov    %ecx,%edx
f0100479:	ee                   	out    %al,(%dx)
f010047a:	89 d8                	mov    %ebx,%eax
f010047c:	89 f2                	mov    %esi,%edx
f010047e:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010047f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100482:	5b                   	pop    %ebx
f0100483:	5e                   	pop    %esi
f0100484:	5f                   	pop    %edi
f0100485:	5d                   	pop    %ebp
f0100486:	c3                   	ret    

f0100487 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100487:	80 3d 74 4f 17 f0 00 	cmpb   $0x0,0xf0174f74
f010048e:	74 11                	je     f01004a1 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100490:	55                   	push   %ebp
f0100491:	89 e5                	mov    %esp,%ebp
f0100493:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100496:	b8 31 01 10 f0       	mov    $0xf0100131,%eax
f010049b:	e8 b0 fc ff ff       	call   f0100150 <cons_intr>
}
f01004a0:	c9                   	leave  
f01004a1:	f3 c3                	repz ret 

f01004a3 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004a3:	55                   	push   %ebp
f01004a4:	89 e5                	mov    %esp,%ebp
f01004a6:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004a9:	b8 93 01 10 f0       	mov    $0xf0100193,%eax
f01004ae:	e8 9d fc ff ff       	call   f0100150 <cons_intr>
}
f01004b3:	c9                   	leave  
f01004b4:	c3                   	ret    

f01004b5 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004b5:	55                   	push   %ebp
f01004b6:	89 e5                	mov    %esp,%ebp
f01004b8:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004bb:	e8 c7 ff ff ff       	call   f0100487 <serial_intr>
	kbd_intr();
f01004c0:	e8 de ff ff ff       	call   f01004a3 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004c5:	a1 60 4f 17 f0       	mov    0xf0174f60,%eax
f01004ca:	3b 05 64 4f 17 f0    	cmp    0xf0174f64,%eax
f01004d0:	74 26                	je     f01004f8 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004d2:	8d 50 01             	lea    0x1(%eax),%edx
f01004d5:	89 15 60 4f 17 f0    	mov    %edx,0xf0174f60
f01004db:	0f b6 88 60 4d 17 f0 	movzbl -0xfe8b2a0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01004e2:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01004e4:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004ea:	75 11                	jne    f01004fd <cons_getc+0x48>
			cons.rpos = 0;
f01004ec:	c7 05 60 4f 17 f0 00 	movl   $0x0,0xf0174f60
f01004f3:	00 00 00 
f01004f6:	eb 05                	jmp    f01004fd <cons_getc+0x48>
		return c;
	}
	return 0;
f01004f8:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01004fd:	c9                   	leave  
f01004fe:	c3                   	ret    

f01004ff <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004ff:	55                   	push   %ebp
f0100500:	89 e5                	mov    %esp,%ebp
f0100502:	57                   	push   %edi
f0100503:	56                   	push   %esi
f0100504:	53                   	push   %ebx
f0100505:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100508:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010050f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100516:	5a a5 
	if (*cp != 0xA55A) {
f0100518:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010051f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100523:	74 11                	je     f0100536 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100525:	c7 05 70 4f 17 f0 b4 	movl   $0x3b4,0xf0174f70
f010052c:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010052f:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100534:	eb 16                	jmp    f010054c <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100536:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010053d:	c7 05 70 4f 17 f0 d4 	movl   $0x3d4,0xf0174f70
f0100544:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100547:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010054c:	8b 3d 70 4f 17 f0    	mov    0xf0174f70,%edi
f0100552:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100557:	89 fa                	mov    %edi,%edx
f0100559:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010055a:	8d 5f 01             	lea    0x1(%edi),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010055d:	89 da                	mov    %ebx,%edx
f010055f:	ec                   	in     (%dx),%al
f0100560:	0f b6 c8             	movzbl %al,%ecx
f0100563:	c1 e1 08             	shl    $0x8,%ecx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100566:	b8 0f 00 00 00       	mov    $0xf,%eax
f010056b:	89 fa                	mov    %edi,%edx
f010056d:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010056e:	89 da                	mov    %ebx,%edx
f0100570:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100571:	89 35 6c 4f 17 f0    	mov    %esi,0xf0174f6c
	crt_pos = pos;
f0100577:	0f b6 c0             	movzbl %al,%eax
f010057a:	09 c8                	or     %ecx,%eax
f010057c:	66 a3 68 4f 17 f0    	mov    %ax,0xf0174f68
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100582:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100587:	b8 00 00 00 00       	mov    $0x0,%eax
f010058c:	89 f2                	mov    %esi,%edx
f010058e:	ee                   	out    %al,(%dx)
f010058f:	ba fb 03 00 00       	mov    $0x3fb,%edx
f0100594:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100599:	ee                   	out    %al,(%dx)
f010059a:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f010059f:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005a4:	89 da                	mov    %ebx,%edx
f01005a6:	ee                   	out    %al,(%dx)
f01005a7:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005ac:	b8 00 00 00 00       	mov    $0x0,%eax
f01005b1:	ee                   	out    %al,(%dx)
f01005b2:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005b7:	b8 03 00 00 00       	mov    $0x3,%eax
f01005bc:	ee                   	out    %al,(%dx)
f01005bd:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005c2:	b8 00 00 00 00       	mov    $0x0,%eax
f01005c7:	ee                   	out    %al,(%dx)
f01005c8:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005cd:	b8 01 00 00 00       	mov    $0x1,%eax
f01005d2:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005d3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01005d8:	ec                   	in     (%dx),%al
f01005d9:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005db:	3c ff                	cmp    $0xff,%al
f01005dd:	0f 95 05 74 4f 17 f0 	setne  0xf0174f74
f01005e4:	89 f2                	mov    %esi,%edx
f01005e6:	ec                   	in     (%dx),%al
f01005e7:	89 da                	mov    %ebx,%edx
f01005e9:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005ea:	80 f9 ff             	cmp    $0xff,%cl
f01005ed:	75 10                	jne    f01005ff <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f01005ef:	83 ec 0c             	sub    $0xc,%esp
f01005f2:	68 39 48 10 f0       	push   $0xf0104839
f01005f7:	e8 c9 29 00 00       	call   f0102fc5 <cprintf>
f01005fc:	83 c4 10             	add    $0x10,%esp
}
f01005ff:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100602:	5b                   	pop    %ebx
f0100603:	5e                   	pop    %esi
f0100604:	5f                   	pop    %edi
f0100605:	5d                   	pop    %ebp
f0100606:	c3                   	ret    

f0100607 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100607:	55                   	push   %ebp
f0100608:	89 e5                	mov    %esp,%ebp
f010060a:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010060d:	8b 45 08             	mov    0x8(%ebp),%eax
f0100610:	e8 89 fc ff ff       	call   f010029e <cons_putc>
}
f0100615:	c9                   	leave  
f0100616:	c3                   	ret    

f0100617 <getchar>:

int
getchar(void)
{
f0100617:	55                   	push   %ebp
f0100618:	89 e5                	mov    %esp,%ebp
f010061a:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010061d:	e8 93 fe ff ff       	call   f01004b5 <cons_getc>
f0100622:	85 c0                	test   %eax,%eax
f0100624:	74 f7                	je     f010061d <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100626:	c9                   	leave  
f0100627:	c3                   	ret    

f0100628 <iscons>:

int
iscons(int fdnum)
{
f0100628:	55                   	push   %ebp
f0100629:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f010062b:	b8 01 00 00 00       	mov    $0x1,%eax
f0100630:	5d                   	pop    %ebp
f0100631:	c3                   	ret    

f0100632 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100632:	55                   	push   %ebp
f0100633:	89 e5                	mov    %esp,%ebp
f0100635:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100638:	68 80 4a 10 f0       	push   $0xf0104a80
f010063d:	68 9e 4a 10 f0       	push   $0xf0104a9e
f0100642:	68 a3 4a 10 f0       	push   $0xf0104aa3
f0100647:	e8 79 29 00 00       	call   f0102fc5 <cprintf>
f010064c:	83 c4 0c             	add    $0xc,%esp
f010064f:	68 40 4b 10 f0       	push   $0xf0104b40
f0100654:	68 ac 4a 10 f0       	push   $0xf0104aac
f0100659:	68 a3 4a 10 f0       	push   $0xf0104aa3
f010065e:	e8 62 29 00 00       	call   f0102fc5 <cprintf>
	return 0;
}
f0100663:	b8 00 00 00 00       	mov    $0x0,%eax
f0100668:	c9                   	leave  
f0100669:	c3                   	ret    

f010066a <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f010066a:	55                   	push   %ebp
f010066b:	89 e5                	mov    %esp,%ebp
f010066d:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100670:	68 b5 4a 10 f0       	push   $0xf0104ab5
f0100675:	e8 4b 29 00 00       	call   f0102fc5 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010067a:	83 c4 08             	add    $0x8,%esp
f010067d:	68 0c 00 10 00       	push   $0x10000c
f0100682:	68 68 4b 10 f0       	push   $0xf0104b68
f0100687:	e8 39 29 00 00       	call   f0102fc5 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010068c:	83 c4 0c             	add    $0xc,%esp
f010068f:	68 0c 00 10 00       	push   $0x10000c
f0100694:	68 0c 00 10 f0       	push   $0xf010000c
f0100699:	68 90 4b 10 f0       	push   $0xf0104b90
f010069e:	e8 22 29 00 00       	call   f0102fc5 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006a3:	83 c4 0c             	add    $0xc,%esp
f01006a6:	68 c1 47 10 00       	push   $0x1047c1
f01006ab:	68 c1 47 10 f0       	push   $0xf01047c1
f01006b0:	68 b4 4b 10 f0       	push   $0xf0104bb4
f01006b5:	e8 0b 29 00 00       	call   f0102fc5 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006ba:	83 c4 0c             	add    $0xc,%esp
f01006bd:	68 26 4d 17 00       	push   $0x174d26
f01006c2:	68 26 4d 17 f0       	push   $0xf0174d26
f01006c7:	68 d8 4b 10 f0       	push   $0xf0104bd8
f01006cc:	e8 f4 28 00 00       	call   f0102fc5 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006d1:	83 c4 0c             	add    $0xc,%esp
f01006d4:	68 50 5c 17 00       	push   $0x175c50
f01006d9:	68 50 5c 17 f0       	push   $0xf0175c50
f01006de:	68 fc 4b 10 f0       	push   $0xf0104bfc
f01006e3:	e8 dd 28 00 00       	call   f0102fc5 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006e8:	b8 4f 60 17 f0       	mov    $0xf017604f,%eax
f01006ed:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006f2:	83 c4 08             	add    $0x8,%esp
f01006f5:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f01006fa:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100700:	85 c0                	test   %eax,%eax
f0100702:	0f 48 c2             	cmovs  %edx,%eax
f0100705:	c1 f8 0a             	sar    $0xa,%eax
f0100708:	50                   	push   %eax
f0100709:	68 20 4c 10 f0       	push   $0xf0104c20
f010070e:	e8 b2 28 00 00       	call   f0102fc5 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100713:	b8 00 00 00 00       	mov    $0x0,%eax
f0100718:	c9                   	leave  
f0100719:	c3                   	ret    

f010071a <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010071a:	55                   	push   %ebp
f010071b:	89 e5                	mov    %esp,%ebp
f010071d:	57                   	push   %edi
f010071e:	56                   	push   %esi
f010071f:	53                   	push   %ebx
f0100720:	83 ec 18             	sub    $0x18,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0100723:	89 e8                	mov    %ebp,%eax
		// Your code here.
	uint32_t *ebp = (uint32_t*)read_ebp(); //定义指向当前ebp寄存器的指针,uint32_t因为寄存器存储的值为32位
f0100725:	89 c6                	mov    %eax,%esi
	uint32_t *eip = (uint32_t*)*(ebp + 1); //eip在ebp底下，储存返回地址
f0100727:	8b 58 04             	mov    0x4(%eax),%ebx
	cprintf("Stack backtrace:");
f010072a:	68 ce 4a 10 f0       	push   $0xf0104ace
f010072f:	e8 91 28 00 00       	call   f0102fc5 <cprintf>
	while(ebp != NULL){
f0100734:	83 c4 10             	add    $0x10,%esp
f0100737:	eb 52                	jmp    f010078b <mon_backtrace+0x71>
		cprintf("ebp %08x  eip %08x", ebp, eip); //打印ebp、eip
f0100739:	83 ec 04             	sub    $0x4,%esp
f010073c:	53                   	push   %ebx
f010073d:	56                   	push   %esi
f010073e:	68 df 4a 10 f0       	push   $0xf0104adf
f0100743:	e8 7d 28 00 00       	call   f0102fc5 <cprintf>
		cprintf("    arg ");
f0100748:	c7 04 24 f2 4a 10 f0 	movl   $0xf0104af2,(%esp)
f010074f:	e8 71 28 00 00       	call   f0102fc5 <cprintf>
f0100754:	8d 5e 08             	lea    0x8(%esi),%ebx
f0100757:	8d 7e 1c             	lea    0x1c(%esi),%edi
f010075a:	83 c4 10             	add    $0x10,%esp
		for(int i = 0;i < 5;i++){
			cprintf("%08x ", *(ebp + i + 2));
f010075d:	83 ec 08             	sub    $0x8,%esp
f0100760:	ff 33                	pushl  (%ebx)
f0100762:	68 fb 4a 10 f0       	push   $0xf0104afb
f0100767:	e8 59 28 00 00       	call   f0102fc5 <cprintf>
f010076c:	83 c3 04             	add    $0x4,%ebx
	uint32_t *eip = (uint32_t*)*(ebp + 1); //eip在ebp底下，储存返回地址
	cprintf("Stack backtrace:");
	while(ebp != NULL){
		cprintf("ebp %08x  eip %08x", ebp, eip); //打印ebp、eip
		cprintf("    arg ");
		for(int i = 0;i < 5;i++){
f010076f:	83 c4 10             	add    $0x10,%esp
f0100772:	39 fb                	cmp    %edi,%ebx
f0100774:	75 e7                	jne    f010075d <mon_backtrace+0x43>
			cprintf("%08x ", *(ebp + i + 2));
		}
		cprintf("\n");
f0100776:	83 ec 0c             	sub    $0xc,%esp
f0100779:	68 93 4f 10 f0       	push   $0xf0104f93
f010077e:	e8 42 28 00 00       	call   f0102fc5 <cprintf>
		ebp = (uint32_t*)(*ebp); //被调用函数的ebp指向调用它函数ebp值存放的位置
f0100783:	8b 36                	mov    (%esi),%esi
		eip = (uint32_t*)*(ebp + 1); //eip在ebp底下，储存返回地址
f0100785:	8b 5e 04             	mov    0x4(%esi),%ebx
f0100788:	83 c4 10             	add    $0x10,%esp
{
		// Your code here.
	uint32_t *ebp = (uint32_t*)read_ebp(); //定义指向当前ebp寄存器的指针,uint32_t因为寄存器存储的值为32位
	uint32_t *eip = (uint32_t*)*(ebp + 1); //eip在ebp底下，储存返回地址
	cprintf("Stack backtrace:");
	while(ebp != NULL){
f010078b:	85 f6                	test   %esi,%esi
f010078d:	75 aa                	jne    f0100739 <mon_backtrace+0x1f>
		cprintf("\n");
		ebp = (uint32_t*)(*ebp); //被调用函数的ebp指向调用它函数ebp值存放的位置
		eip = (uint32_t*)*(ebp + 1); //eip在ebp底下，储存返回地址
	}
	return 0;
}
f010078f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100794:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100797:	5b                   	pop    %ebx
f0100798:	5e                   	pop    %esi
f0100799:	5f                   	pop    %edi
f010079a:	5d                   	pop    %ebp
f010079b:	c3                   	ret    

f010079c <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f010079c:	55                   	push   %ebp
f010079d:	89 e5                	mov    %esp,%ebp
f010079f:	57                   	push   %edi
f01007a0:	56                   	push   %esi
f01007a1:	53                   	push   %ebx
f01007a2:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007a5:	68 4c 4c 10 f0       	push   $0xf0104c4c
f01007aa:	e8 16 28 00 00       	call   f0102fc5 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007af:	c7 04 24 70 4c 10 f0 	movl   $0xf0104c70,(%esp)
f01007b6:	e8 0a 28 00 00       	call   f0102fc5 <cprintf>

	if (tf != NULL)
f01007bb:	83 c4 10             	add    $0x10,%esp
f01007be:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f01007c2:	74 0e                	je     f01007d2 <monitor+0x36>
		print_trapframe(tf);
f01007c4:	83 ec 0c             	sub    $0xc,%esp
f01007c7:	ff 75 08             	pushl  0x8(%ebp)
f01007ca:	e8 30 2c 00 00       	call   f01033ff <print_trapframe>
f01007cf:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f01007d2:	83 ec 0c             	sub    $0xc,%esp
f01007d5:	68 01 4b 10 f0       	push   $0xf0104b01
f01007da:	e8 00 39 00 00       	call   f01040df <readline>
f01007df:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007e1:	83 c4 10             	add    $0x10,%esp
f01007e4:	85 c0                	test   %eax,%eax
f01007e6:	74 ea                	je     f01007d2 <monitor+0x36>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01007e8:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01007ef:	be 00 00 00 00       	mov    $0x0,%esi
f01007f4:	eb 0a                	jmp    f0100800 <monitor+0x64>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01007f6:	c6 03 00             	movb   $0x0,(%ebx)
f01007f9:	89 f7                	mov    %esi,%edi
f01007fb:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01007fe:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100800:	0f b6 03             	movzbl (%ebx),%eax
f0100803:	84 c0                	test   %al,%al
f0100805:	74 63                	je     f010086a <monitor+0xce>
f0100807:	83 ec 08             	sub    $0x8,%esp
f010080a:	0f be c0             	movsbl %al,%eax
f010080d:	50                   	push   %eax
f010080e:	68 05 4b 10 f0       	push   $0xf0104b05
f0100813:	e8 e1 3a 00 00       	call   f01042f9 <strchr>
f0100818:	83 c4 10             	add    $0x10,%esp
f010081b:	85 c0                	test   %eax,%eax
f010081d:	75 d7                	jne    f01007f6 <monitor+0x5a>
			*buf++ = 0;
		if (*buf == 0)
f010081f:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100822:	74 46                	je     f010086a <monitor+0xce>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100824:	83 fe 0f             	cmp    $0xf,%esi
f0100827:	75 14                	jne    f010083d <monitor+0xa1>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100829:	83 ec 08             	sub    $0x8,%esp
f010082c:	6a 10                	push   $0x10
f010082e:	68 0a 4b 10 f0       	push   $0xf0104b0a
f0100833:	e8 8d 27 00 00       	call   f0102fc5 <cprintf>
f0100838:	83 c4 10             	add    $0x10,%esp
f010083b:	eb 95                	jmp    f01007d2 <monitor+0x36>
			return 0;
		}
		argv[argc++] = buf;
f010083d:	8d 7e 01             	lea    0x1(%esi),%edi
f0100840:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100844:	eb 03                	jmp    f0100849 <monitor+0xad>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100846:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100849:	0f b6 03             	movzbl (%ebx),%eax
f010084c:	84 c0                	test   %al,%al
f010084e:	74 ae                	je     f01007fe <monitor+0x62>
f0100850:	83 ec 08             	sub    $0x8,%esp
f0100853:	0f be c0             	movsbl %al,%eax
f0100856:	50                   	push   %eax
f0100857:	68 05 4b 10 f0       	push   $0xf0104b05
f010085c:	e8 98 3a 00 00       	call   f01042f9 <strchr>
f0100861:	83 c4 10             	add    $0x10,%esp
f0100864:	85 c0                	test   %eax,%eax
f0100866:	74 de                	je     f0100846 <monitor+0xaa>
f0100868:	eb 94                	jmp    f01007fe <monitor+0x62>
			buf++;
	}
	argv[argc] = 0;
f010086a:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100871:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100872:	85 f6                	test   %esi,%esi
f0100874:	0f 84 58 ff ff ff    	je     f01007d2 <monitor+0x36>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f010087a:	83 ec 08             	sub    $0x8,%esp
f010087d:	68 9e 4a 10 f0       	push   $0xf0104a9e
f0100882:	ff 75 a8             	pushl  -0x58(%ebp)
f0100885:	e8 11 3a 00 00       	call   f010429b <strcmp>
f010088a:	83 c4 10             	add    $0x10,%esp
f010088d:	85 c0                	test   %eax,%eax
f010088f:	74 1e                	je     f01008af <monitor+0x113>
f0100891:	83 ec 08             	sub    $0x8,%esp
f0100894:	68 ac 4a 10 f0       	push   $0xf0104aac
f0100899:	ff 75 a8             	pushl  -0x58(%ebp)
f010089c:	e8 fa 39 00 00       	call   f010429b <strcmp>
f01008a1:	83 c4 10             	add    $0x10,%esp
f01008a4:	85 c0                	test   %eax,%eax
f01008a6:	75 2f                	jne    f01008d7 <monitor+0x13b>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f01008a8:	b8 01 00 00 00       	mov    $0x1,%eax
f01008ad:	eb 05                	jmp    f01008b4 <monitor+0x118>
		if (strcmp(argv[0], commands[i].name) == 0)
f01008af:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f01008b4:	83 ec 04             	sub    $0x4,%esp
f01008b7:	8d 14 00             	lea    (%eax,%eax,1),%edx
f01008ba:	01 d0                	add    %edx,%eax
f01008bc:	ff 75 08             	pushl  0x8(%ebp)
f01008bf:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f01008c2:	51                   	push   %ecx
f01008c3:	56                   	push   %esi
f01008c4:	ff 14 85 a0 4c 10 f0 	call   *-0xfefb360(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008cb:	83 c4 10             	add    $0x10,%esp
f01008ce:	85 c0                	test   %eax,%eax
f01008d0:	78 1d                	js     f01008ef <monitor+0x153>
f01008d2:	e9 fb fe ff ff       	jmp    f01007d2 <monitor+0x36>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008d7:	83 ec 08             	sub    $0x8,%esp
f01008da:	ff 75 a8             	pushl  -0x58(%ebp)
f01008dd:	68 27 4b 10 f0       	push   $0xf0104b27
f01008e2:	e8 de 26 00 00       	call   f0102fc5 <cprintf>
f01008e7:	83 c4 10             	add    $0x10,%esp
f01008ea:	e9 e3 fe ff ff       	jmp    f01007d2 <monitor+0x36>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008ef:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008f2:	5b                   	pop    %ebx
f01008f3:	5e                   	pop    %esi
f01008f4:	5f                   	pop    %edi
f01008f5:	5d                   	pop    %ebp
f01008f6:	c3                   	ret    

f01008f7 <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {//让nextfree指向一个空闲页地址
f01008f7:	83 3d 78 4f 17 f0 00 	cmpl   $0x0,0xf0174f78
f01008fe:	75 5f                	jne    f010095f <boot_alloc+0x68>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100900:	ba 4f 6c 17 f0       	mov    $0xf0176c4f,%edx
f0100905:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010090b:	89 15 78 4f 17 f0    	mov    %edx,0xf0174f78
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if (n > 0) {
f0100911:	85 c0                	test   %eax,%eax
f0100913:	74 44                	je     f0100959 <boot_alloc+0x62>
		if ((uint32_t)nextfree > KERNBASE + (npages * PGSIZE)) {
f0100915:	8b 15 78 4f 17 f0    	mov    0xf0174f78,%edx
f010091b:	8b 0d 44 5c 17 f0    	mov    0xf0175c44,%ecx
f0100921:	81 c1 00 00 0f 00    	add    $0xf0000,%ecx
f0100927:	c1 e1 0c             	shl    $0xc,%ecx
f010092a:	39 ca                	cmp    %ecx,%edx
f010092c:	76 17                	jbe    f0100945 <boot_alloc+0x4e>

//分配足够容纳n字节的内存，返回虚拟地址
//
static void *
boot_alloc(uint32_t n)
{
f010092e:	55                   	push   %ebp
f010092f:	89 e5                	mov    %esp,%ebp
f0100931:	83 ec 0c             	sub    $0xc,%esp
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if (n > 0) {
		if ((uint32_t)nextfree > KERNBASE + (npages * PGSIZE)) {
			panic("out of memory"); //如果下一个空闲地址超过了内核允许分配的内存边界那么报错
f0100934:	68 b0 4c 10 f0       	push   $0xf0104cb0
f0100939:	6a 6c                	push   $0x6c
f010093b:	68 be 4c 10 f0       	push   $0xf0104cbe
f0100940:	e8 5b f7 ff ff       	call   f01000a0 <_panic>
		} else { //否则将当前nextfree指向的空闲内存的开始地址返回给result             
			result = nextfree; //并将nextfree的指针后移n，留出n个字节的空间
			nextfree = ROUNDUP(nextfree + n, PGSIZE);
f0100945:	8d 84 02 ff 0f 00 00 	lea    0xfff(%edx,%eax,1),%eax
f010094c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100951:	a3 78 4f 17 f0       	mov    %eax,0xf0174f78
			return result;
f0100956:	89 d0                	mov    %edx,%eax
f0100958:	c3                   	ret    
		}
	}
	if (n == 0) {  
		return nextfree;//如果n为0，按照要求直接返回nextfree，不做分配
f0100959:	a1 78 4f 17 f0       	mov    0xf0174f78,%eax
f010095e:	c3                   	ret    
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if (n > 0) {
f010095f:	85 c0                	test   %eax,%eax
f0100961:	75 b2                	jne    f0100915 <boot_alloc+0x1e>
f0100963:	eb f4                	jmp    f0100959 <boot_alloc+0x62>

f0100965 <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100965:	89 d1                	mov    %edx,%ecx
f0100967:	c1 e9 16             	shr    $0x16,%ecx
f010096a:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f010096d:	a8 01                	test   $0x1,%al
f010096f:	74 52                	je     f01009c3 <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100971:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100976:	89 c1                	mov    %eax,%ecx
f0100978:	c1 e9 0c             	shr    $0xc,%ecx
f010097b:	3b 0d 44 5c 17 f0    	cmp    0xf0175c44,%ecx
f0100981:	72 1b                	jb     f010099e <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100983:	55                   	push   %ebp
f0100984:	89 e5                	mov    %esp,%ebp
f0100986:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100989:	50                   	push   %eax
f010098a:	68 c8 4f 10 f0       	push   $0xf0104fc8
f010098f:	68 5d 03 00 00       	push   $0x35d
f0100994:	68 be 4c 10 f0       	push   $0xf0104cbe
f0100999:	e8 02 f7 ff ff       	call   f01000a0 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f010099e:	c1 ea 0c             	shr    $0xc,%edx
f01009a1:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f01009a7:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f01009ae:	89 c2                	mov    %eax,%edx
f01009b0:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f01009b3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009b8:	85 d2                	test   %edx,%edx
f01009ba:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01009bf:	0f 44 c2             	cmove  %edx,%eax
f01009c2:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f01009c3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f01009c8:	c3                   	ret    

f01009c9 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f01009c9:	55                   	push   %ebp
f01009ca:	89 e5                	mov    %esp,%ebp
f01009cc:	57                   	push   %edi
f01009cd:	56                   	push   %esi
f01009ce:	53                   	push   %ebx
f01009cf:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01009d2:	84 c0                	test   %al,%al
f01009d4:	0f 85 72 02 00 00    	jne    f0100c4c <check_page_free_list+0x283>
f01009da:	e9 7f 02 00 00       	jmp    f0100c5e <check_page_free_list+0x295>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f01009df:	83 ec 04             	sub    $0x4,%esp
f01009e2:	68 ec 4f 10 f0       	push   $0xf0104fec
f01009e7:	68 9b 02 00 00       	push   $0x29b
f01009ec:	68 be 4c 10 f0       	push   $0xf0104cbe
f01009f1:	e8 aa f6 ff ff       	call   f01000a0 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f01009f6:	8d 55 d8             	lea    -0x28(%ebp),%edx
f01009f9:	89 55 e0             	mov    %edx,-0x20(%ebp)
f01009fc:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01009ff:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100a02:	89 c2                	mov    %eax,%edx
f0100a04:	2b 15 4c 5c 17 f0    	sub    0xf0175c4c,%edx
f0100a0a:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100a10:	0f 95 c2             	setne  %dl
f0100a13:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100a16:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100a1a:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100a1c:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a20:	8b 00                	mov    (%eax),%eax
f0100a22:	85 c0                	test   %eax,%eax
f0100a24:	75 dc                	jne    f0100a02 <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100a26:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a29:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100a2f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a32:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100a35:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100a37:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100a3a:	a3 80 4f 17 f0       	mov    %eax,0xf0174f80
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a3f:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a44:	8b 1d 80 4f 17 f0    	mov    0xf0174f80,%ebx
f0100a4a:	eb 53                	jmp    f0100a9f <check_page_free_list+0xd6>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a4c:	89 d8                	mov    %ebx,%eax
f0100a4e:	2b 05 4c 5c 17 f0    	sub    0xf0175c4c,%eax
f0100a54:	c1 f8 03             	sar    $0x3,%eax
f0100a57:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100a5a:	89 c2                	mov    %eax,%edx
f0100a5c:	c1 ea 16             	shr    $0x16,%edx
f0100a5f:	39 f2                	cmp    %esi,%edx
f0100a61:	73 3a                	jae    f0100a9d <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a63:	89 c2                	mov    %eax,%edx
f0100a65:	c1 ea 0c             	shr    $0xc,%edx
f0100a68:	3b 15 44 5c 17 f0    	cmp    0xf0175c44,%edx
f0100a6e:	72 12                	jb     f0100a82 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a70:	50                   	push   %eax
f0100a71:	68 c8 4f 10 f0       	push   $0xf0104fc8
f0100a76:	6a 56                	push   $0x56
f0100a78:	68 ca 4c 10 f0       	push   $0xf0104cca
f0100a7d:	e8 1e f6 ff ff       	call   f01000a0 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100a82:	83 ec 04             	sub    $0x4,%esp
f0100a85:	68 80 00 00 00       	push   $0x80
f0100a8a:	68 97 00 00 00       	push   $0x97
f0100a8f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100a94:	50                   	push   %eax
f0100a95:	e8 9c 38 00 00       	call   f0104336 <memset>
f0100a9a:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a9d:	8b 1b                	mov    (%ebx),%ebx
f0100a9f:	85 db                	test   %ebx,%ebx
f0100aa1:	75 a9                	jne    f0100a4c <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100aa3:	b8 00 00 00 00       	mov    $0x0,%eax
f0100aa8:	e8 4a fe ff ff       	call   f01008f7 <boot_alloc>
f0100aad:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ab0:	8b 15 80 4f 17 f0    	mov    0xf0174f80,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100ab6:	8b 0d 4c 5c 17 f0    	mov    0xf0175c4c,%ecx
		assert(pp < pages + npages);
f0100abc:	a1 44 5c 17 f0       	mov    0xf0175c44,%eax
f0100ac1:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100ac4:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100ac7:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100aca:	be 00 00 00 00       	mov    $0x0,%esi
f0100acf:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ad2:	e9 30 01 00 00       	jmp    f0100c07 <check_page_free_list+0x23e>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100ad7:	39 ca                	cmp    %ecx,%edx
f0100ad9:	73 19                	jae    f0100af4 <check_page_free_list+0x12b>
f0100adb:	68 d8 4c 10 f0       	push   $0xf0104cd8
f0100ae0:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0100ae5:	68 b5 02 00 00       	push   $0x2b5
f0100aea:	68 be 4c 10 f0       	push   $0xf0104cbe
f0100aef:	e8 ac f5 ff ff       	call   f01000a0 <_panic>
		assert(pp < pages + npages);
f0100af4:	39 fa                	cmp    %edi,%edx
f0100af6:	72 19                	jb     f0100b11 <check_page_free_list+0x148>
f0100af8:	68 f9 4c 10 f0       	push   $0xf0104cf9
f0100afd:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0100b02:	68 b6 02 00 00       	push   $0x2b6
f0100b07:	68 be 4c 10 f0       	push   $0xf0104cbe
f0100b0c:	e8 8f f5 ff ff       	call   f01000a0 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b11:	89 d0                	mov    %edx,%eax
f0100b13:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100b16:	a8 07                	test   $0x7,%al
f0100b18:	74 19                	je     f0100b33 <check_page_free_list+0x16a>
f0100b1a:	68 10 50 10 f0       	push   $0xf0105010
f0100b1f:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0100b24:	68 b7 02 00 00       	push   $0x2b7
f0100b29:	68 be 4c 10 f0       	push   $0xf0104cbe
f0100b2e:	e8 6d f5 ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b33:	c1 f8 03             	sar    $0x3,%eax
f0100b36:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100b39:	85 c0                	test   %eax,%eax
f0100b3b:	75 19                	jne    f0100b56 <check_page_free_list+0x18d>
f0100b3d:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0100b42:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0100b47:	68 ba 02 00 00       	push   $0x2ba
f0100b4c:	68 be 4c 10 f0       	push   $0xf0104cbe
f0100b51:	e8 4a f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b56:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b5b:	75 19                	jne    f0100b76 <check_page_free_list+0x1ad>
f0100b5d:	68 1e 4d 10 f0       	push   $0xf0104d1e
f0100b62:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0100b67:	68 bb 02 00 00       	push   $0x2bb
f0100b6c:	68 be 4c 10 f0       	push   $0xf0104cbe
f0100b71:	e8 2a f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100b76:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100b7b:	75 19                	jne    f0100b96 <check_page_free_list+0x1cd>
f0100b7d:	68 44 50 10 f0       	push   $0xf0105044
f0100b82:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0100b87:	68 bc 02 00 00       	push   $0x2bc
f0100b8c:	68 be 4c 10 f0       	push   $0xf0104cbe
f0100b91:	e8 0a f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100b96:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100b9b:	75 19                	jne    f0100bb6 <check_page_free_list+0x1ed>
f0100b9d:	68 37 4d 10 f0       	push   $0xf0104d37
f0100ba2:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0100ba7:	68 bd 02 00 00       	push   $0x2bd
f0100bac:	68 be 4c 10 f0       	push   $0xf0104cbe
f0100bb1:	e8 ea f4 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100bb6:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100bbb:	76 3f                	jbe    f0100bfc <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100bbd:	89 c3                	mov    %eax,%ebx
f0100bbf:	c1 eb 0c             	shr    $0xc,%ebx
f0100bc2:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100bc5:	77 12                	ja     f0100bd9 <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100bc7:	50                   	push   %eax
f0100bc8:	68 c8 4f 10 f0       	push   $0xf0104fc8
f0100bcd:	6a 56                	push   $0x56
f0100bcf:	68 ca 4c 10 f0       	push   $0xf0104cca
f0100bd4:	e8 c7 f4 ff ff       	call   f01000a0 <_panic>
f0100bd9:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100bde:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100be1:	76 1e                	jbe    f0100c01 <check_page_free_list+0x238>
f0100be3:	68 68 50 10 f0       	push   $0xf0105068
f0100be8:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0100bed:	68 be 02 00 00       	push   $0x2be
f0100bf2:	68 be 4c 10 f0       	push   $0xf0104cbe
f0100bf7:	e8 a4 f4 ff ff       	call   f01000a0 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100bfc:	83 c6 01             	add    $0x1,%esi
f0100bff:	eb 04                	jmp    f0100c05 <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f0100c01:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c05:	8b 12                	mov    (%edx),%edx
f0100c07:	85 d2                	test   %edx,%edx
f0100c09:	0f 85 c8 fe ff ff    	jne    f0100ad7 <check_page_free_list+0x10e>
f0100c0f:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100c12:	85 f6                	test   %esi,%esi
f0100c14:	7f 19                	jg     f0100c2f <check_page_free_list+0x266>
f0100c16:	68 51 4d 10 f0       	push   $0xf0104d51
f0100c1b:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0100c20:	68 c6 02 00 00       	push   $0x2c6
f0100c25:	68 be 4c 10 f0       	push   $0xf0104cbe
f0100c2a:	e8 71 f4 ff ff       	call   f01000a0 <_panic>
	assert(nfree_extmem > 0);
f0100c2f:	85 db                	test   %ebx,%ebx
f0100c31:	7f 42                	jg     f0100c75 <check_page_free_list+0x2ac>
f0100c33:	68 63 4d 10 f0       	push   $0xf0104d63
f0100c38:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0100c3d:	68 c7 02 00 00       	push   $0x2c7
f0100c42:	68 be 4c 10 f0       	push   $0xf0104cbe
f0100c47:	e8 54 f4 ff ff       	call   f01000a0 <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100c4c:	a1 80 4f 17 f0       	mov    0xf0174f80,%eax
f0100c51:	85 c0                	test   %eax,%eax
f0100c53:	0f 85 9d fd ff ff    	jne    f01009f6 <check_page_free_list+0x2d>
f0100c59:	e9 81 fd ff ff       	jmp    f01009df <check_page_free_list+0x16>
f0100c5e:	83 3d 80 4f 17 f0 00 	cmpl   $0x0,0xf0174f80
f0100c65:	0f 84 74 fd ff ff    	je     f01009df <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c6b:	be 00 04 00 00       	mov    $0x400,%esi
f0100c70:	e9 cf fd ff ff       	jmp    f0100a44 <check_page_free_list+0x7b>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100c75:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c78:	5b                   	pop    %ebx
f0100c79:	5e                   	pop    %esi
f0100c7a:	5f                   	pop    %edi
f0100c7b:	5d                   	pop    %ebp
f0100c7c:	c3                   	ret    

f0100c7d <page_init>:
// memory via the page_free_list.
//

void //初始化页结构，将所有的页表项PageInfo与4K大小的页映射。
page_init(void)
{
f0100c7d:	55                   	push   %ebp
f0100c7e:	89 e5                	mov    %esp,%ebp
f0100c80:	57                   	push   %edi
f0100c81:	56                   	push   %esi
f0100c82:	53                   	push   %ebx
f0100c83:	83 ec 1c             	sub    $0x1c,%esp
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	uint32_t nextfree = (uint32_t)boot_alloc(0);//returns the address of the next free page
f0100c86:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c8b:	e8 67 fc ff ff       	call   f01008f7 <boot_alloc>
	for (i = 0; i < npages; i++) {
		if(i == 0) { //首先将物理页0设置为正在使用
			pages[i].pp_ref = 1; //page 0 in use
			pages[i].pp_link = NULL;//不能与page_free_list建立连接
		} else if(i < npages_basemem) {
f0100c90:	8b 35 84 4f 17 f0    	mov    0xf0174f84,%esi
f0100c96:	8b 1d 80 4f 17 f0    	mov    0xf0174f80,%ebx
            page_free_list = &pages[i];//page_free_list指向当前页的地址
		} else if(i >= IOPHYSMEM/PGSIZE && i < EXTPHYSMEM/PGSIZE) { 
		//Then comes the IO hole [IOPHYSMEM, EXTPHYSMEM), which must never be allocated.
	    //用于IO的物理内存是不能被分配的，设置为在用
			pages[i].pp_ref = 1; 
		} else  if (i >= IOPHYSMEM / PGSIZE && i < (nextfree - KERNBASE)/ PGSIZE) { 
f0100c9c:	05 00 00 00 10       	add    $0x10000000,%eax
f0100ca1:	c1 e8 0c             	shr    $0xc,%eax
f0100ca4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	uint32_t nextfree = (uint32_t)boot_alloc(0);//returns the address of the next free page
	for (i = 0; i < npages; i++) {
f0100ca7:	ba 00 00 00 00       	mov    $0x0,%edx
f0100cac:	bf 00 00 00 00       	mov    $0x0,%edi
f0100cb1:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cb6:	e9 9a 00 00 00       	jmp    f0100d55 <page_init+0xd8>
		if(i == 0) { //首先将物理页0设置为正在使用
f0100cbb:	85 c0                	test   %eax,%eax
f0100cbd:	75 14                	jne    f0100cd3 <page_init+0x56>
			pages[i].pp_ref = 1; //page 0 in use
f0100cbf:	8b 0d 4c 5c 17 f0    	mov    0xf0175c4c,%ecx
f0100cc5:	66 c7 41 04 01 00    	movw   $0x1,0x4(%ecx)
			pages[i].pp_link = NULL;//不能与page_free_list建立连接
f0100ccb:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
f0100cd1:	eb 7c                	jmp    f0100d4f <page_init+0xd2>
		} else if(i < npages_basemem) {
f0100cd3:	39 f0                	cmp    %esi,%eax
f0100cd5:	73 1f                	jae    f0100cf6 <page_init+0x79>
			//The rest of base memory, [PGSIZE, npages_basemem * PGSIZE)is free.
	        //从第一页到第npage页是可以使用的     
			pages[i].pp_ref = 0; //将此页设置为可用
f0100cd7:	89 d1                	mov    %edx,%ecx
f0100cd9:	03 0d 4c 5c 17 f0    	add    0xf0175c4c,%ecx
f0100cdf:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
            pages[i].pp_link = page_free_list;//将此页与当前page_free_list指向的空闲页映射
f0100ce5:	89 19                	mov    %ebx,(%ecx)
            page_free_list = &pages[i];//page_free_list指向当前页的地址
f0100ce7:	89 d3                	mov    %edx,%ebx
f0100ce9:	03 1d 4c 5c 17 f0    	add    0xf0175c4c,%ebx
f0100cef:	bf 01 00 00 00       	mov    $0x1,%edi
f0100cf4:	eb 59                	jmp    f0100d4f <page_init+0xd2>
		} else if(i >= IOPHYSMEM/PGSIZE && i < EXTPHYSMEM/PGSIZE) { 
f0100cf6:	8d 88 60 ff ff ff    	lea    -0xa0(%eax),%ecx
f0100cfc:	83 f9 5f             	cmp    $0x5f,%ecx
f0100cff:	77 0f                	ja     f0100d10 <page_init+0x93>
		//Then comes the IO hole [IOPHYSMEM, EXTPHYSMEM), which must never be allocated.
	    //用于IO的物理内存是不能被分配的，设置为在用
			pages[i].pp_ref = 1; 
f0100d01:	8b 0d 4c 5c 17 f0    	mov    0xf0175c4c,%ecx
f0100d07:	66 c7 44 11 04 01 00 	movw   $0x1,0x4(%ecx,%edx,1)
f0100d0e:	eb 3f                	jmp    f0100d4f <page_init+0xd2>
		} else  if (i >= IOPHYSMEM / PGSIZE && i < (nextfree - KERNBASE)/ PGSIZE) { 
f0100d10:	3d 9f 00 00 00       	cmp    $0x9f,%eax
f0100d15:	76 1b                	jbe    f0100d32 <page_init+0xb5>
f0100d17:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
f0100d1a:	73 16                	jae    f0100d32 <page_init+0xb5>
		//从IOPHYSMEM开始有一部分内存是被使用的，用于保存kernel，这一部分不能被分配
		//直到nextfree开头
            pages[i].pp_ref = 1;
f0100d1c:	89 d1                	mov    %edx,%ecx
f0100d1e:	03 0d 4c 5c 17 f0    	add    0xf0175c4c,%ecx
f0100d24:	66 c7 41 04 01 00    	movw   $0x1,0x4(%ecx)
            pages[i].pp_link = NULL;
f0100d2a:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
f0100d30:	eb 1d                	jmp    f0100d4f <page_init+0xd2>
        } else {
		//其余的部分可以被分配
			pages[i].pp_ref = 0;
f0100d32:	89 d1                	mov    %edx,%ecx
f0100d34:	03 0d 4c 5c 17 f0    	add    0xf0175c4c,%ecx
f0100d3a:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
            pages[i].pp_link = page_free_list;
f0100d40:	89 19                	mov    %ebx,(%ecx)
            page_free_list = &pages[i];
f0100d42:	89 d3                	mov    %edx,%ebx
f0100d44:	03 1d 4c 5c 17 f0    	add    0xf0175c4c,%ebx
f0100d4a:	bf 01 00 00 00       	mov    $0x1,%edi
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	uint32_t nextfree = (uint32_t)boot_alloc(0);//returns the address of the next free page
	for (i = 0; i < npages; i++) {
f0100d4f:	83 c0 01             	add    $0x1,%eax
f0100d52:	83 c2 08             	add    $0x8,%edx
f0100d55:	3b 05 44 5c 17 f0    	cmp    0xf0175c44,%eax
f0100d5b:	0f 82 5a ff ff ff    	jb     f0100cbb <page_init+0x3e>
f0100d61:	89 f8                	mov    %edi,%eax
f0100d63:	84 c0                	test   %al,%al
f0100d65:	74 06                	je     f0100d6d <page_init+0xf0>
f0100d67:	89 1d 80 4f 17 f0    	mov    %ebx,0xf0174f80
			pages[i].pp_ref = 0;
            pages[i].pp_link = page_free_list;
            page_free_list = &pages[i];
		}
	}
}
f0100d6d:	83 c4 1c             	add    $0x1c,%esp
f0100d70:	5b                   	pop    %ebx
f0100d71:	5e                   	pop    %esi
f0100d72:	5f                   	pop    %edi
f0100d73:	5d                   	pop    %ebp
f0100d74:	c3                   	ret    

f0100d75 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo * //分配一个物理页，返回物理页的指针
page_alloc(int alloc_flags)
{
f0100d75:	55                   	push   %ebp
f0100d76:	89 e5                	mov    %esp,%ebp
f0100d78:	53                   	push   %ebx
f0100d79:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in
	struct PageInfo *NewPage;
	if(page_free_list == NULL) { //如果page_free_list没有空闲内存了
f0100d7c:	8b 1d 80 4f 17 f0    	mov    0xf0174f80,%ebx
f0100d82:	85 db                	test   %ebx,%ebx
f0100d84:	74 58                	je     f0100dde <page_alloc+0x69>
		return NULL; //那么返回空
	}
	NewPage = page_free_list; //从page_free_list分配一个空闲的物理页
	page_free_list = page_free_list->pp_link; //将page_free_list指向下一张空闲的页
f0100d86:	8b 03                	mov    (%ebx),%eax
f0100d88:	a3 80 4f 17 f0       	mov    %eax,0xf0174f80
	NewPage->pp_link = NULL;
f0100d8d:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
// Allocates a physical page.  If (alloc_flags & ALLOC_ZERO), fills the entire
// returned physical page with '\0' bytes.  Does NOT increment the reference
//分配一个物理页，如果alloc_flags和ALLOC_ZERO均为真，将这个物理页清为0
//不增加reference数
	if (alloc_flags & ALLOC_ZERO) {
f0100d93:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100d97:	74 45                	je     f0100dde <page_alloc+0x69>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100d99:	89 d8                	mov    %ebx,%eax
f0100d9b:	2b 05 4c 5c 17 f0    	sub    0xf0175c4c,%eax
f0100da1:	c1 f8 03             	sar    $0x3,%eax
f0100da4:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100da7:	89 c2                	mov    %eax,%edx
f0100da9:	c1 ea 0c             	shr    $0xc,%edx
f0100dac:	3b 15 44 5c 17 f0    	cmp    0xf0175c44,%edx
f0100db2:	72 12                	jb     f0100dc6 <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100db4:	50                   	push   %eax
f0100db5:	68 c8 4f 10 f0       	push   $0xf0104fc8
f0100dba:	6a 56                	push   $0x56
f0100dbc:	68 ca 4c 10 f0       	push   $0xf0104cca
f0100dc1:	e8 da f2 ff ff       	call   f01000a0 <_panic>
		memset(page2kva(NewPage), 0, PGSIZE);
f0100dc6:	83 ec 04             	sub    $0x4,%esp
f0100dc9:	68 00 10 00 00       	push   $0x1000
f0100dce:	6a 00                	push   $0x0
f0100dd0:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100dd5:	50                   	push   %eax
f0100dd6:	e8 5b 35 00 00       	call   f0104336 <memset>
f0100ddb:	83 c4 10             	add    $0x10,%esp
	}
	//page2kva根据当前的struct PageInfo类型的指针得出相应的虚拟地址
	return NewPage; //返回分配的物理页
}
f0100dde:	89 d8                	mov    %ebx,%eax
f0100de0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100de3:	c9                   	leave  
f0100de4:	c3                   	ret    

f0100de5 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void //释放一个页，让其返回到空闲页链表中
page_free(struct PageInfo *pp)
{
f0100de5:	55                   	push   %ebp
f0100de6:	89 e5                	mov    %esp,%ebp
f0100de8:	83 ec 08             	sub    $0x8,%esp
f0100deb:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	//如果参数中指向的页reference数不为0或它还连接了一张物理页
	//那么释放失败，此函数只能在pp->ref为0时被调用
	assert(pp->pp_ref == 0); //if not, panic
f0100dee:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100df3:	74 19                	je     f0100e0e <page_free+0x29>
f0100df5:	68 74 4d 10 f0       	push   $0xf0104d74
f0100dfa:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0100dff:	68 6f 01 00 00       	push   $0x16f
f0100e04:	68 be 4c 10 f0       	push   $0xf0104cbe
f0100e09:	e8 92 f2 ff ff       	call   f01000a0 <_panic>
	assert(pp->pp_link == NULL);//if not, panic
f0100e0e:	83 38 00             	cmpl   $0x0,(%eax)
f0100e11:	74 19                	je     f0100e2c <page_free+0x47>
f0100e13:	68 84 4d 10 f0       	push   $0xf0104d84
f0100e18:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0100e1d:	68 70 01 00 00       	push   $0x170
f0100e22:	68 be 4c 10 f0       	push   $0xf0104cbe
f0100e27:	e8 74 f2 ff ff       	call   f01000a0 <_panic>
	//将这个page的指针指向pagefreelist，把这张页还给page_free_list
	pp->pp_link = page_free_list;// Return a page to the free list.
f0100e2c:	8b 15 80 4f 17 f0    	mov    0xf0174f80,%edx
f0100e32:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100e34:	a3 80 4f 17 f0       	mov    %eax,0xf0174f80
}
f0100e39:	c9                   	leave  
f0100e3a:	c3                   	ret    

f0100e3b <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100e3b:	55                   	push   %ebp
f0100e3c:	89 e5                	mov    %esp,%ebp
f0100e3e:	83 ec 08             	sub    $0x8,%esp
f0100e41:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100e44:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100e48:	83 e8 01             	sub    $0x1,%eax
f0100e4b:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100e4f:	66 85 c0             	test   %ax,%ax
f0100e52:	75 0c                	jne    f0100e60 <page_decref+0x25>
		page_free(pp);
f0100e54:	83 ec 0c             	sub    $0xc,%esp
f0100e57:	52                   	push   %edx
f0100e58:	e8 88 ff ff ff       	call   f0100de5 <page_free>
f0100e5d:	83 c4 10             	add    $0x10,%esp
}
f0100e60:	c9                   	leave  
f0100e61:	c3                   	ret    

f0100e62 <pgdir_walk>:
// table and page directory entries.
//
//pgdir是页目录，里面的每一个元素都指向一个页表物理地址
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100e62:	55                   	push   %ebp
f0100e63:	89 e5                	mov    %esp,%ebp
f0100e65:	56                   	push   %esi
f0100e66:	53                   	push   %ebx
f0100e67:	8b 45 0c             	mov    0xc(%ebp),%eax
	*对应的物理地址，最后物理地址加上偏移量便找到了虚拟地址对应的物理地址
	*pgdir_walk根据pgdir和虚拟地址va获得虚拟地址va所在的页表项的物理地址
	*/
	// Fill this function in
	int pd_index = PDX(va); //PDX根据虚拟地址头10位找到页目录索引
    int pte_index = PTX(va);//PTX根据虚拟地址11-20位找到页表索引
f0100e6a:	89 c6                	mov    %eax,%esi
f0100e6c:	c1 ee 0c             	shr    $0xc,%esi
f0100e6f:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
    if (pgdir[pd_index] & PTE_P) {  //如果页目录存在且具有操作权限
f0100e75:	c1 e8 16             	shr    $0x16,%eax
f0100e78:	8d 1c 85 00 00 00 00 	lea    0x0(,%eax,4),%ebx
f0100e7f:	03 5d 08             	add    0x8(%ebp),%ebx
f0100e82:	8b 03                	mov    (%ebx),%eax
f0100e84:	a8 01                	test   $0x1,%al
f0100e86:	74 30                	je     f0100eb8 <pgdir_walk+0x56>
		//那么获得该页目录的物理地址，再转化为虚拟地址
		//PTE_ADDR得到页目录的物理地址，KADDR将物理地址转换为虚拟地址
        pte_t *pt_addr_v = KADDR(PTE_ADDR(pgdir[pd_index]));
f0100e88:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e8d:	89 c2                	mov    %eax,%edx
f0100e8f:	c1 ea 0c             	shr    $0xc,%edx
f0100e92:	39 15 44 5c 17 f0    	cmp    %edx,0xf0175c44
f0100e98:	77 15                	ja     f0100eaf <pgdir_walk+0x4d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e9a:	50                   	push   %eax
f0100e9b:	68 c8 4f 10 f0       	push   $0xf0104fc8
f0100ea0:	68 a8 01 00 00       	push   $0x1a8
f0100ea5:	68 be 4c 10 f0       	push   $0xf0104cbe
f0100eaa:	e8 f1 f1 ff ff       	call   f01000a0 <_panic>
		//根据页目录的虚拟地址，加上页表的索引偏移量就得到了va对应的页表项的物理地址
        return (pte_t*)(pt_addr_v + pte_index);
f0100eaf:	8d 84 b0 00 00 00 f0 	lea    -0x10000000(%eax,%esi,4),%eax
f0100eb6:	eb 6b                	jmp    f0100f23 <pgdir_walk+0xc1>
    } else {            //if not exist page
        if (create) {//如果不存在该页并允许新建
f0100eb8:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100ebc:	74 59                	je     f0100f17 <pgdir_walk+0xb5>
			struct PageInfo *NewPt = page_alloc(ALLOC_ZERO); //那么分配一张新页
f0100ebe:	83 ec 0c             	sub    $0xc,%esp
f0100ec1:	6a 01                	push   $0x1
f0100ec3:	e8 ad fe ff ff       	call   f0100d75 <page_alloc>
			if(NewPt == NULL)
f0100ec8:	83 c4 10             	add    $0x10,%esp
f0100ecb:	85 c0                	test   %eax,%eax
f0100ecd:	74 4f                	je     f0100f1e <pgdir_walk+0xbc>
				return NULL;
            NewPt->pp_ref++;
f0100ecf:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ed4:	2b 05 4c 5c 17 f0    	sub    0xf0175c4c,%eax
f0100eda:	c1 f8 03             	sar    $0x3,%eax
f0100edd:	c1 e0 0c             	shl    $0xc,%eax
			//page2pa将一个页表指针转换为物理地址
			//将虚拟地址va的页目录基地址与新页表的物理地址关联并设置权限位
            pgdir[pd_index] = page2pa(NewPt)|PTE_U|PTE_W|PTE_P; 
f0100ee0:	89 c2                	mov    %eax,%edx
f0100ee2:	83 ca 07             	or     $0x7,%edx
f0100ee5:	89 13                	mov    %edx,(%ebx)
f0100ee7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100eec:	89 c2                	mov    %eax,%edx
f0100eee:	c1 ea 0c             	shr    $0xc,%edx
f0100ef1:	3b 15 44 5c 17 f0    	cmp    0xf0175c44,%edx
f0100ef7:	72 15                	jb     f0100f0e <pgdir_walk+0xac>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ef9:	50                   	push   %eax
f0100efa:	68 c8 4f 10 f0       	push   $0xf0104fc8
f0100eff:	68 b5 01 00 00       	push   $0x1b5
f0100f04:	68 be 4c 10 f0       	push   $0xf0104cbe
f0100f09:	e8 92 f1 ff ff       	call   f01000a0 <_panic>
			//最后根据页目录的虚拟地址和页表索引找到va对应的页表项物理地址
            pte_t *pt_addr_v = KADDR(PTE_ADDR(pgdir[pd_index]));
            return (pte_t*)(pt_addr_v + pte_index);
f0100f0e:	8d 84 b0 00 00 00 f0 	lea    -0x10000000(%eax,%esi,4),%eax
f0100f15:	eb 0c                	jmp    f0100f23 <pgdir_walk+0xc1>
        } else return NULL;
f0100f17:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f1c:	eb 05                	jmp    f0100f23 <pgdir_walk+0xc1>
        return (pte_t*)(pt_addr_v + pte_index);
    } else {            //if not exist page
        if (create) {//如果不存在该页并允许新建
			struct PageInfo *NewPt = page_alloc(ALLOC_ZERO); //那么分配一张新页
			if(NewPt == NULL)
				return NULL;
f0100f1e:	b8 00 00 00 00       	mov    $0x0,%eax
			//最后根据页目录的虚拟地址和页表索引找到va对应的页表项物理地址
            pte_t *pt_addr_v = KADDR(PTE_ADDR(pgdir[pd_index]));
            return (pte_t*)(pt_addr_v + pte_index);
        } else return NULL;
    }
}
f0100f23:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100f26:	5b                   	pop    %ebx
f0100f27:	5e                   	pop    %esi
f0100f28:	5d                   	pop    %ebp
f0100f29:	c3                   	ret    

f0100f2a <boot_map_region>:
//
// Hint: the TA solution uses pgdir_walk

static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100f2a:	55                   	push   %ebp
f0100f2b:	89 e5                	mov    %esp,%ebp
f0100f2d:	57                   	push   %edi
f0100f2e:	56                   	push   %esi
f0100f2f:	53                   	push   %ebx
f0100f30:	83 ec 1c             	sub    $0x1c,%esp
f0100f33:	89 45 e0             	mov    %eax,-0x20(%ebp)
	//boot_map_region将虚拟地址[va, va+size)映射到物理地址[pa, pa+size)
	//函数参数依次为页目录，虚拟地址起始，映射的大小，物理地址起始，权限位
	// Fill this function in
    size = ROUNDUP(size, PGSIZE);
f0100f36:	81 c1 ff 0f 00 00    	add    $0xfff,%ecx
    size_t page_num = PGNUM(size);
f0100f3c:	c1 e9 0c             	shr    $0xc,%ecx
f0100f3f:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
    for (size_t i = 0; i < page_num; i++) {
f0100f42:	89 d3                	mov    %edx,%ebx
f0100f44:	be 00 00 00 00       	mov    $0x0,%esi
		//利用pgdir_walk函数找到虚拟地址对应的页表项物理地址
        pte_t *pgtable_entry_ptr = pgdir_walk(pgdir, (char *)(va + i * PGSIZE), true);
		//将找到的物理页表设置物理地址中的起始位置和权限
        *pgtable_entry_ptr = (pa + i * PGSIZE) | perm | PTE_P;
f0100f49:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100f4c:	29 d7                	sub    %edx,%edi
f0100f4e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f51:	83 c8 01             	or     $0x1,%eax
f0100f54:	89 45 dc             	mov    %eax,-0x24(%ebp)
	//boot_map_region将虚拟地址[va, va+size)映射到物理地址[pa, pa+size)
	//函数参数依次为页目录，虚拟地址起始，映射的大小，物理地址起始，权限位
	// Fill this function in
    size = ROUNDUP(size, PGSIZE);
    size_t page_num = PGNUM(size);
    for (size_t i = 0; i < page_num; i++) {
f0100f57:	eb 22                	jmp    f0100f7b <boot_map_region+0x51>
		//利用pgdir_walk函数找到虚拟地址对应的页表项物理地址
        pte_t *pgtable_entry_ptr = pgdir_walk(pgdir, (char *)(va + i * PGSIZE), true);
f0100f59:	83 ec 04             	sub    $0x4,%esp
f0100f5c:	6a 01                	push   $0x1
f0100f5e:	53                   	push   %ebx
f0100f5f:	ff 75 e0             	pushl  -0x20(%ebp)
f0100f62:	e8 fb fe ff ff       	call   f0100e62 <pgdir_walk>
		//将找到的物理页表设置物理地址中的起始位置和权限
        *pgtable_entry_ptr = (pa + i * PGSIZE) | perm | PTE_P;
f0100f67:	8d 14 1f             	lea    (%edi,%ebx,1),%edx
f0100f6a:	0b 55 dc             	or     -0x24(%ebp),%edx
f0100f6d:	89 10                	mov    %edx,(%eax)
	//boot_map_region将虚拟地址[va, va+size)映射到物理地址[pa, pa+size)
	//函数参数依次为页目录，虚拟地址起始，映射的大小，物理地址起始，权限位
	// Fill this function in
    size = ROUNDUP(size, PGSIZE);
    size_t page_num = PGNUM(size);
    for (size_t i = 0; i < page_num; i++) {
f0100f6f:	83 c6 01             	add    $0x1,%esi
f0100f72:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100f78:	83 c4 10             	add    $0x10,%esp
f0100f7b:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0100f7e:	75 d9                	jne    f0100f59 <boot_map_region+0x2f>
		//利用pgdir_walk函数找到虚拟地址对应的页表项物理地址
        pte_t *pgtable_entry_ptr = pgdir_walk(pgdir, (char *)(va + i * PGSIZE), true);
		//将找到的物理页表设置物理地址中的起始位置和权限
        *pgtable_entry_ptr = (pa + i * PGSIZE) | perm | PTE_P;
    }
}
f0100f80:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f83:	5b                   	pop    %ebx
f0100f84:	5e                   	pop    %esi
f0100f85:	5f                   	pop    %edi
f0100f86:	5d                   	pop    %ebp
f0100f87:	c3                   	ret    

f0100f88 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo * //返回虚拟地址va对应的物理页
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100f88:	55                   	push   %ebp
f0100f89:	89 e5                	mov    %esp,%ebp
f0100f8b:	53                   	push   %ebx
f0100f8c:	83 ec 08             	sub    $0x8,%esp
f0100f8f:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	//首先用pgdir_walk寻找是否存在对应的物理页
	pte_t *pte = pgdir_walk(pgdir, va, 0);//如果不存在不创建新页表
f0100f92:	6a 00                	push   $0x0
f0100f94:	ff 75 0c             	pushl  0xc(%ebp)
f0100f97:	ff 75 08             	pushl  0x8(%ebp)
f0100f9a:	e8 c3 fe ff ff       	call   f0100e62 <pgdir_walk>
	if(pte == NULL) { //不存在则返回NULL
f0100f9f:	83 c4 10             	add    $0x10,%esp
f0100fa2:	85 c0                	test   %eax,%eax
f0100fa4:	74 32                	je     f0100fd8 <page_lookup+0x50>
		return NULL;
	} else if(pte_store != 0){
f0100fa6:	85 db                	test   %ebx,%ebx
f0100fa8:	74 02                	je     f0100fac <page_lookup+0x24>
		*pte_store = pte; //如果pte_store不为0，那么储存这个页的地址
f0100faa:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fac:	8b 00                	mov    (%eax),%eax
f0100fae:	c1 e8 0c             	shr    $0xc,%eax
f0100fb1:	3b 05 44 5c 17 f0    	cmp    0xf0175c44,%eax
f0100fb7:	72 14                	jb     f0100fcd <page_lookup+0x45>
		panic("pa2page called with invalid pa");
f0100fb9:	83 ec 04             	sub    $0x4,%esp
f0100fbc:	68 b0 50 10 f0       	push   $0xf01050b0
f0100fc1:	6a 4f                	push   $0x4f
f0100fc3:	68 ca 4c 10 f0       	push   $0xf0104cca
f0100fc8:	e8 d3 f0 ff ff       	call   f01000a0 <_panic>
	return &pages[PGNUM(pa)];
f0100fcd:	8b 15 4c 5c 17 f0    	mov    0xf0175c4c,%edx
f0100fd3:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	}
	//PTE_ADDR得到页表的物理地址，pa2page将物理地址转为物理页指针
	return pa2page(PTE_ADDR(*pte));
f0100fd6:	eb 05                	jmp    f0100fdd <page_lookup+0x55>
{
	// Fill this function in
	//首先用pgdir_walk寻找是否存在对应的物理页
	pte_t *pte = pgdir_walk(pgdir, va, 0);//如果不存在不创建新页表
	if(pte == NULL) { //不存在则返回NULL
		return NULL;
f0100fd8:	b8 00 00 00 00       	mov    $0x0,%eax
	} else if(pte_store != 0){
		*pte_store = pte; //如果pte_store不为0，那么储存这个页的地址
	}
	//PTE_ADDR得到页表的物理地址，pa2page将物理地址转为物理页指针
	return pa2page(PTE_ADDR(*pte));
}
f0100fdd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100fe0:	c9                   	leave  
f0100fe1:	c3                   	ret    

f0100fe2 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void //移除虚拟地址va和某个页表之间的映射
page_remove(pde_t *pgdir, void *va)
{
f0100fe2:	55                   	push   %ebp
f0100fe3:	89 e5                	mov    %esp,%ebp
f0100fe5:	53                   	push   %ebx
f0100fe6:	83 ec 18             	sub    $0x18,%esp
f0100fe9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t *pte;
	//找到va关联的页表
	struct PageInfo *Fpage = page_lookup(pgdir, va, &pte);
f0100fec:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100fef:	50                   	push   %eax
f0100ff0:	53                   	push   %ebx
f0100ff1:	ff 75 08             	pushl  0x8(%ebp)
f0100ff4:	e8 8f ff ff ff       	call   f0100f88 <page_lookup>
	if(Fpage == NULL){ //如果没找到就直接结束
f0100ff9:	83 c4 10             	add    $0x10,%esp
f0100ffc:	85 c0                	test   %eax,%eax
f0100ffe:	74 18                	je     f0101018 <page_remove+0x36>
		return;
	}
	page_decref(Fpage); //找到了就使物理页的ref计数减1
f0101000:	83 ec 0c             	sub    $0xc,%esp
f0101003:	50                   	push   %eax
f0101004:	e8 32 fe ff ff       	call   f0100e3b <page_decref>
	*pte = 0; //并且移除映射
f0101009:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010100c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101012:	0f 01 3b             	invlpg (%ebx)
f0101015:	83 c4 10             	add    $0x10,%esp
	tlb_invalidate(pgdir, va);
}
f0101018:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010101b:	c9                   	leave  
f010101c:	c3                   	ret    

f010101d <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int //将物理页PP和虚拟地址va建立映射
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f010101d:	55                   	push   %ebp
f010101e:	89 e5                	mov    %esp,%ebp
f0101020:	57                   	push   %edi
f0101021:	56                   	push   %esi
f0101022:	53                   	push   %ebx
f0101023:	83 ec 10             	sub    $0x10,%esp
f0101026:	8b 75 08             	mov    0x8(%ebp),%esi
f0101029:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
    pte_t *pte = pgdir_walk(pgdir, va, 1);//首先利用pgdir_walk找到va的物理页地址
f010102c:	6a 01                	push   $0x1
f010102e:	ff 75 10             	pushl  0x10(%ebp)
f0101031:	56                   	push   %esi
f0101032:	e8 2b fe ff ff       	call   f0100e62 <pgdir_walk>
    if (pte == NULL) { //如果没找到，那么建立映射失败
f0101037:	83 c4 10             	add    $0x10,%esp
f010103a:	85 c0                	test   %eax,%eax
f010103c:	74 6b                	je     f01010a9 <page_insert+0x8c>
f010103e:	89 c7                	mov    %eax,%edi
        return -E_NO_MEM;//页表无法被分配
    }  
    if (*pte & PTE_P) { //如果pte存在
f0101040:	8b 00                	mov    (%eax),%eax
f0101042:	a8 01                	test   $0x1,%al
f0101044:	74 33                	je     f0101079 <page_insert+0x5c>
        if (PTE_ADDR(*pte) == page2pa(pp)) { //且物理页表的地址与pp的物理地址相同
f0101046:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010104b:	89 da                	mov    %ebx,%edx
f010104d:	2b 15 4c 5c 17 f0    	sub    0xf0175c4c,%edx
f0101053:	c1 fa 03             	sar    $0x3,%edx
f0101056:	c1 e2 0c             	shl    $0xc,%edx
f0101059:	39 d0                	cmp    %edx,%eax
f010105b:	75 0d                	jne    f010106a <page_insert+0x4d>
f010105d:	8b 45 10             	mov    0x10(%ebp),%eax
f0101060:	0f 01 38             	invlpg (%eax)
            tlb_invalidate(pgdir, va); //则映射已经建立
            pp->pp_ref--; //为了抵消之后的pp_ref++效果，在这里--
f0101063:	66 83 6b 04 01       	subw   $0x1,0x4(%ebx)
f0101068:	eb 0f                	jmp    f0101079 <page_insert+0x5c>
        }
        else { //如果物理页表的地址与PP地址不同
            page_remove(pgdir, va); //则先移除这个映射
f010106a:	83 ec 08             	sub    $0x8,%esp
f010106d:	ff 75 10             	pushl  0x10(%ebp)
f0101070:	56                   	push   %esi
f0101071:	e8 6c ff ff ff       	call   f0100fe2 <page_remove>
f0101076:	83 c4 10             	add    $0x10,%esp
        }
    }
    *pte = page2pa(pp) | perm | PTE_P; //建立新的映射，并设置权限
f0101079:	89 d8                	mov    %ebx,%eax
f010107b:	2b 05 4c 5c 17 f0    	sub    0xf0175c4c,%eax
f0101081:	c1 f8 03             	sar    $0x3,%eax
f0101084:	c1 e0 0c             	shl    $0xc,%eax
f0101087:	8b 55 14             	mov    0x14(%ebp),%edx
f010108a:	83 ca 01             	or     $0x1,%edx
f010108d:	09 d0                	or     %edx,%eax
f010108f:	89 07                	mov    %eax,(%edi)
    pp->pp_ref++; //pp的引用计数加一
f0101091:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
    pgdir[PDX(va)] |= perm; //页目录的权限加上perm
f0101096:	8b 45 10             	mov    0x10(%ebp),%eax
f0101099:	c1 e8 16             	shr    $0x16,%eax
f010109c:	8b 4d 14             	mov    0x14(%ebp),%ecx
f010109f:	09 0c 86             	or     %ecx,(%esi,%eax,4)
    return 0;
f01010a2:	b8 00 00 00 00       	mov    $0x0,%eax
f01010a7:	eb 05                	jmp    f01010ae <page_insert+0x91>
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	// Fill this function in
    pte_t *pte = pgdir_walk(pgdir, va, 1);//首先利用pgdir_walk找到va的物理页地址
    if (pte == NULL) { //如果没找到，那么建立映射失败
        return -E_NO_MEM;//页表无法被分配
f01010a9:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
    }
    *pte = page2pa(pp) | perm | PTE_P; //建立新的映射，并设置权限
    pp->pp_ref++; //pp的引用计数加一
    pgdir[PDX(va)] |= perm; //页目录的权限加上perm
    return 0;
}
f01010ae:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01010b1:	5b                   	pop    %ebx
f01010b2:	5e                   	pop    %esi
f01010b3:	5f                   	pop    %edi
f01010b4:	5d                   	pop    %ebp
f01010b5:	c3                   	ret    

f01010b6 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01010b6:	55                   	push   %ebp
f01010b7:	89 e5                	mov    %esp,%ebp
f01010b9:	57                   	push   %edi
f01010ba:	56                   	push   %esi
f01010bb:	53                   	push   %ebx
f01010bc:	83 ec 38             	sub    $0x38,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01010bf:	6a 15                	push   $0x15
f01010c1:	e8 98 1e 00 00       	call   f0102f5e <mc146818_read>
f01010c6:	89 c3                	mov    %eax,%ebx
f01010c8:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f01010cf:	e8 8a 1e 00 00       	call   f0102f5e <mc146818_read>
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f01010d4:	c1 e0 08             	shl    $0x8,%eax
f01010d7:	09 d8                	or     %ebx,%eax
f01010d9:	c1 e0 0a             	shl    $0xa,%eax
f01010dc:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01010e2:	85 c0                	test   %eax,%eax
f01010e4:	0f 48 c2             	cmovs  %edx,%eax
f01010e7:	c1 f8 0c             	sar    $0xc,%eax
f01010ea:	a3 84 4f 17 f0       	mov    %eax,0xf0174f84
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01010ef:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f01010f6:	e8 63 1e 00 00       	call   f0102f5e <mc146818_read>
f01010fb:	89 c3                	mov    %eax,%ebx
f01010fd:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f0101104:	e8 55 1e 00 00       	call   f0102f5e <mc146818_read>
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0101109:	c1 e0 08             	shl    $0x8,%eax
f010110c:	09 d8                	or     %ebx,%eax
f010110e:	c1 e0 0a             	shl    $0xa,%eax
f0101111:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101117:	83 c4 10             	add    $0x10,%esp
f010111a:	85 c0                	test   %eax,%eax
f010111c:	0f 48 c2             	cmovs  %edx,%eax
f010111f:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0101122:	85 c0                	test   %eax,%eax
f0101124:	74 0e                	je     f0101134 <mem_init+0x7e>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0101126:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f010112c:	89 15 44 5c 17 f0    	mov    %edx,0xf0175c44
f0101132:	eb 0c                	jmp    f0101140 <mem_init+0x8a>
	else
		npages = npages_basemem;
f0101134:	8b 15 84 4f 17 f0    	mov    0xf0174f84,%edx
f010113a:	89 15 44 5c 17 f0    	mov    %edx,0xf0175c44

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101140:	c1 e0 0c             	shl    $0xc,%eax
f0101143:	c1 e8 0a             	shr    $0xa,%eax
f0101146:	50                   	push   %eax
f0101147:	a1 84 4f 17 f0       	mov    0xf0174f84,%eax
f010114c:	c1 e0 0c             	shl    $0xc,%eax
f010114f:	c1 e8 0a             	shr    $0xa,%eax
f0101152:	50                   	push   %eax
f0101153:	a1 44 5c 17 f0       	mov    0xf0175c44,%eax
f0101158:	c1 e0 0c             	shl    $0xc,%eax
f010115b:	c1 e8 0a             	shr    $0xa,%eax
f010115e:	50                   	push   %eax
f010115f:	68 d0 50 10 f0       	push   $0xf01050d0
f0101164:	e8 5c 1e 00 00       	call   f0102fc5 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE); //为内核页目录分配4K的空间
f0101169:	b8 00 10 00 00       	mov    $0x1000,%eax
f010116e:	e8 84 f7 ff ff       	call   f01008f7 <boot_alloc>
f0101173:	a3 48 5c 17 f0       	mov    %eax,0xf0175c48
	memset(kern_pgdir, 0, PGSIZE); //将内核页目录初始化为0
f0101178:	83 c4 0c             	add    $0xc,%esp
f010117b:	68 00 10 00 00       	push   $0x1000
f0101180:	6a 00                	push   $0x0
f0101182:	50                   	push   %eax
f0101183:	e8 ae 31 00 00       	call   f0104336 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101188:	a1 48 5c 17 f0       	mov    0xf0175c48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010118d:	83 c4 10             	add    $0x10,%esp
f0101190:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101195:	77 15                	ja     f01011ac <mem_init+0xf6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101197:	50                   	push   %eax
f0101198:	68 0c 51 10 f0       	push   $0xf010510c
f010119d:	68 9a 00 00 00       	push   $0x9a
f01011a2:	68 be 4c 10 f0       	push   $0xf0104cbe
f01011a7:	e8 f4 ee ff ff       	call   f01000a0 <_panic>
f01011ac:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01011b2:	83 ca 05             	or     $0x5,%edx
f01011b5:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	
	//这一部分将所有的页表初始化为0，首先确定页表大小为页表结构体大小*页表数
	uint32_t PageInfo_Size = sizeof(struct PageInfo) * npages; 
f01011bb:	a1 44 5c 17 f0       	mov    0xf0175c44,%eax
f01011c0:	c1 e0 03             	shl    $0x3,%eax
f01011c3:	89 c7                	mov    %eax,%edi
f01011c5:	89 45 cc             	mov    %eax,-0x34(%ebp)
	pages = (struct PageInfo*)boot_alloc(PageInfo_Size);//为物理页表分配等同大小的空间
f01011c8:	e8 2a f7 ff ff       	call   f01008f7 <boot_alloc>
f01011cd:	a3 4c 5c 17 f0       	mov    %eax,0xf0175c4c
	memset(pages, 0, PageInfo_Size); //将物理页表初始化为0
f01011d2:	83 ec 04             	sub    $0x4,%esp
f01011d5:	57                   	push   %edi
f01011d6:	6a 00                	push   $0x0
f01011d8:	50                   	push   %eax
f01011d9:	e8 58 31 00 00       	call   f0104336 <memset>
	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	//为Env结构体的数组envs分配空间，这一步与给页表分配空间类似
	// LAB 3: Your code here.
	uint32_t Env_size = sizeof(struct Env) * NENV; //进程数组大小为进程结构体*进程数量NENV
	envs = (struct Env*)boot_alloc(Env_size); //为进程数组分配等大的空间
f01011de:	b8 00 80 01 00       	mov    $0x18000,%eax
f01011e3:	e8 0f f7 ff ff       	call   f01008f7 <boot_alloc>
f01011e8:	a3 8c 4f 17 f0       	mov    %eax,0xf0174f8c
    memset(envs, 0, Env_size); //将进程数组初始化为0
f01011ed:	83 c4 0c             	add    $0xc,%esp
f01011f0:	68 00 80 01 00       	push   $0x18000
f01011f5:	6a 00                	push   $0x0
f01011f7:	50                   	push   %eax
f01011f8:	e8 39 31 00 00       	call   f0104336 <memset>
	//并将页表中的线性地址UENVS映射到进程数组envs的起始地址
	boot_map_region(kern_pgdir, UENVS, PTSIZE, PADDR(envs), PTE_U);
f01011fd:	a1 8c 4f 17 f0       	mov    0xf0174f8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101202:	83 c4 10             	add    $0x10,%esp
f0101205:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010120a:	77 15                	ja     f0101221 <mem_init+0x16b>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010120c:	50                   	push   %eax
f010120d:	68 0c 51 10 f0       	push   $0xf010510c
f0101212:	68 b0 00 00 00       	push   $0xb0
f0101217:	68 be 4c 10 f0       	push   $0xf0104cbe
f010121c:	e8 7f ee ff ff       	call   f01000a0 <_panic>
f0101221:	83 ec 08             	sub    $0x8,%esp
f0101224:	6a 04                	push   $0x4
f0101226:	05 00 00 00 10       	add    $0x10000000,%eax
f010122b:	50                   	push   %eax
f010122c:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0101231:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0101236:	a1 48 5c 17 f0       	mov    0xf0175c48,%eax
f010123b:	e8 ea fc ff ff       	call   f0100f2a <boot_map_region>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init(); //这里初始化页结构
f0101240:	e8 38 fa ff ff       	call   f0100c7d <page_init>

	check_page_free_list(1);
f0101245:	b8 01 00 00 00       	mov    $0x1,%eax
f010124a:	e8 7a f7 ff ff       	call   f01009c9 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f010124f:	83 c4 10             	add    $0x10,%esp
f0101252:	83 3d 4c 5c 17 f0 00 	cmpl   $0x0,0xf0175c4c
f0101259:	75 17                	jne    f0101272 <mem_init+0x1bc>
		panic("'pages' is a null pointer!");
f010125b:	83 ec 04             	sub    $0x4,%esp
f010125e:	68 98 4d 10 f0       	push   $0xf0104d98
f0101263:	68 d8 02 00 00       	push   $0x2d8
f0101268:	68 be 4c 10 f0       	push   $0xf0104cbe
f010126d:	e8 2e ee ff ff       	call   f01000a0 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101272:	a1 80 4f 17 f0       	mov    0xf0174f80,%eax
f0101277:	bb 00 00 00 00       	mov    $0x0,%ebx
f010127c:	eb 05                	jmp    f0101283 <mem_init+0x1cd>
		++nfree;
f010127e:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101281:	8b 00                	mov    (%eax),%eax
f0101283:	85 c0                	test   %eax,%eax
f0101285:	75 f7                	jne    f010127e <mem_init+0x1c8>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101287:	83 ec 0c             	sub    $0xc,%esp
f010128a:	6a 00                	push   $0x0
f010128c:	e8 e4 fa ff ff       	call   f0100d75 <page_alloc>
f0101291:	89 c7                	mov    %eax,%edi
f0101293:	83 c4 10             	add    $0x10,%esp
f0101296:	85 c0                	test   %eax,%eax
f0101298:	75 19                	jne    f01012b3 <mem_init+0x1fd>
f010129a:	68 b3 4d 10 f0       	push   $0xf0104db3
f010129f:	68 e4 4c 10 f0       	push   $0xf0104ce4
f01012a4:	68 e0 02 00 00       	push   $0x2e0
f01012a9:	68 be 4c 10 f0       	push   $0xf0104cbe
f01012ae:	e8 ed ed ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f01012b3:	83 ec 0c             	sub    $0xc,%esp
f01012b6:	6a 00                	push   $0x0
f01012b8:	e8 b8 fa ff ff       	call   f0100d75 <page_alloc>
f01012bd:	89 c6                	mov    %eax,%esi
f01012bf:	83 c4 10             	add    $0x10,%esp
f01012c2:	85 c0                	test   %eax,%eax
f01012c4:	75 19                	jne    f01012df <mem_init+0x229>
f01012c6:	68 c9 4d 10 f0       	push   $0xf0104dc9
f01012cb:	68 e4 4c 10 f0       	push   $0xf0104ce4
f01012d0:	68 e1 02 00 00       	push   $0x2e1
f01012d5:	68 be 4c 10 f0       	push   $0xf0104cbe
f01012da:	e8 c1 ed ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f01012df:	83 ec 0c             	sub    $0xc,%esp
f01012e2:	6a 00                	push   $0x0
f01012e4:	e8 8c fa ff ff       	call   f0100d75 <page_alloc>
f01012e9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01012ec:	83 c4 10             	add    $0x10,%esp
f01012ef:	85 c0                	test   %eax,%eax
f01012f1:	75 19                	jne    f010130c <mem_init+0x256>
f01012f3:	68 df 4d 10 f0       	push   $0xf0104ddf
f01012f8:	68 e4 4c 10 f0       	push   $0xf0104ce4
f01012fd:	68 e2 02 00 00       	push   $0x2e2
f0101302:	68 be 4c 10 f0       	push   $0xf0104cbe
f0101307:	e8 94 ed ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010130c:	39 f7                	cmp    %esi,%edi
f010130e:	75 19                	jne    f0101329 <mem_init+0x273>
f0101310:	68 f5 4d 10 f0       	push   $0xf0104df5
f0101315:	68 e4 4c 10 f0       	push   $0xf0104ce4
f010131a:	68 e5 02 00 00       	push   $0x2e5
f010131f:	68 be 4c 10 f0       	push   $0xf0104cbe
f0101324:	e8 77 ed ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101329:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010132c:	39 c6                	cmp    %eax,%esi
f010132e:	74 04                	je     f0101334 <mem_init+0x27e>
f0101330:	39 c7                	cmp    %eax,%edi
f0101332:	75 19                	jne    f010134d <mem_init+0x297>
f0101334:	68 30 51 10 f0       	push   $0xf0105130
f0101339:	68 e4 4c 10 f0       	push   $0xf0104ce4
f010133e:	68 e6 02 00 00       	push   $0x2e6
f0101343:	68 be 4c 10 f0       	push   $0xf0104cbe
f0101348:	e8 53 ed ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010134d:	8b 0d 4c 5c 17 f0    	mov    0xf0175c4c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101353:	8b 15 44 5c 17 f0    	mov    0xf0175c44,%edx
f0101359:	c1 e2 0c             	shl    $0xc,%edx
f010135c:	89 f8                	mov    %edi,%eax
f010135e:	29 c8                	sub    %ecx,%eax
f0101360:	c1 f8 03             	sar    $0x3,%eax
f0101363:	c1 e0 0c             	shl    $0xc,%eax
f0101366:	39 d0                	cmp    %edx,%eax
f0101368:	72 19                	jb     f0101383 <mem_init+0x2cd>
f010136a:	68 07 4e 10 f0       	push   $0xf0104e07
f010136f:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0101374:	68 e7 02 00 00       	push   $0x2e7
f0101379:	68 be 4c 10 f0       	push   $0xf0104cbe
f010137e:	e8 1d ed ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101383:	89 f0                	mov    %esi,%eax
f0101385:	29 c8                	sub    %ecx,%eax
f0101387:	c1 f8 03             	sar    $0x3,%eax
f010138a:	c1 e0 0c             	shl    $0xc,%eax
f010138d:	39 c2                	cmp    %eax,%edx
f010138f:	77 19                	ja     f01013aa <mem_init+0x2f4>
f0101391:	68 24 4e 10 f0       	push   $0xf0104e24
f0101396:	68 e4 4c 10 f0       	push   $0xf0104ce4
f010139b:	68 e8 02 00 00       	push   $0x2e8
f01013a0:	68 be 4c 10 f0       	push   $0xf0104cbe
f01013a5:	e8 f6 ec ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01013aa:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01013ad:	29 c8                	sub    %ecx,%eax
f01013af:	c1 f8 03             	sar    $0x3,%eax
f01013b2:	c1 e0 0c             	shl    $0xc,%eax
f01013b5:	39 c2                	cmp    %eax,%edx
f01013b7:	77 19                	ja     f01013d2 <mem_init+0x31c>
f01013b9:	68 41 4e 10 f0       	push   $0xf0104e41
f01013be:	68 e4 4c 10 f0       	push   $0xf0104ce4
f01013c3:	68 e9 02 00 00       	push   $0x2e9
f01013c8:	68 be 4c 10 f0       	push   $0xf0104cbe
f01013cd:	e8 ce ec ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01013d2:	a1 80 4f 17 f0       	mov    0xf0174f80,%eax
f01013d7:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01013da:	c7 05 80 4f 17 f0 00 	movl   $0x0,0xf0174f80
f01013e1:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01013e4:	83 ec 0c             	sub    $0xc,%esp
f01013e7:	6a 00                	push   $0x0
f01013e9:	e8 87 f9 ff ff       	call   f0100d75 <page_alloc>
f01013ee:	83 c4 10             	add    $0x10,%esp
f01013f1:	85 c0                	test   %eax,%eax
f01013f3:	74 19                	je     f010140e <mem_init+0x358>
f01013f5:	68 5e 4e 10 f0       	push   $0xf0104e5e
f01013fa:	68 e4 4c 10 f0       	push   $0xf0104ce4
f01013ff:	68 f0 02 00 00       	push   $0x2f0
f0101404:	68 be 4c 10 f0       	push   $0xf0104cbe
f0101409:	e8 92 ec ff ff       	call   f01000a0 <_panic>

	// free and re-allocate?
	page_free(pp0);
f010140e:	83 ec 0c             	sub    $0xc,%esp
f0101411:	57                   	push   %edi
f0101412:	e8 ce f9 ff ff       	call   f0100de5 <page_free>
	page_free(pp1);
f0101417:	89 34 24             	mov    %esi,(%esp)
f010141a:	e8 c6 f9 ff ff       	call   f0100de5 <page_free>
	page_free(pp2);
f010141f:	83 c4 04             	add    $0x4,%esp
f0101422:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101425:	e8 bb f9 ff ff       	call   f0100de5 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010142a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101431:	e8 3f f9 ff ff       	call   f0100d75 <page_alloc>
f0101436:	89 c6                	mov    %eax,%esi
f0101438:	83 c4 10             	add    $0x10,%esp
f010143b:	85 c0                	test   %eax,%eax
f010143d:	75 19                	jne    f0101458 <mem_init+0x3a2>
f010143f:	68 b3 4d 10 f0       	push   $0xf0104db3
f0101444:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0101449:	68 f7 02 00 00       	push   $0x2f7
f010144e:	68 be 4c 10 f0       	push   $0xf0104cbe
f0101453:	e8 48 ec ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0101458:	83 ec 0c             	sub    $0xc,%esp
f010145b:	6a 00                	push   $0x0
f010145d:	e8 13 f9 ff ff       	call   f0100d75 <page_alloc>
f0101462:	89 c7                	mov    %eax,%edi
f0101464:	83 c4 10             	add    $0x10,%esp
f0101467:	85 c0                	test   %eax,%eax
f0101469:	75 19                	jne    f0101484 <mem_init+0x3ce>
f010146b:	68 c9 4d 10 f0       	push   $0xf0104dc9
f0101470:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0101475:	68 f8 02 00 00       	push   $0x2f8
f010147a:	68 be 4c 10 f0       	push   $0xf0104cbe
f010147f:	e8 1c ec ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f0101484:	83 ec 0c             	sub    $0xc,%esp
f0101487:	6a 00                	push   $0x0
f0101489:	e8 e7 f8 ff ff       	call   f0100d75 <page_alloc>
f010148e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101491:	83 c4 10             	add    $0x10,%esp
f0101494:	85 c0                	test   %eax,%eax
f0101496:	75 19                	jne    f01014b1 <mem_init+0x3fb>
f0101498:	68 df 4d 10 f0       	push   $0xf0104ddf
f010149d:	68 e4 4c 10 f0       	push   $0xf0104ce4
f01014a2:	68 f9 02 00 00       	push   $0x2f9
f01014a7:	68 be 4c 10 f0       	push   $0xf0104cbe
f01014ac:	e8 ef eb ff ff       	call   f01000a0 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01014b1:	39 fe                	cmp    %edi,%esi
f01014b3:	75 19                	jne    f01014ce <mem_init+0x418>
f01014b5:	68 f5 4d 10 f0       	push   $0xf0104df5
f01014ba:	68 e4 4c 10 f0       	push   $0xf0104ce4
f01014bf:	68 fb 02 00 00       	push   $0x2fb
f01014c4:	68 be 4c 10 f0       	push   $0xf0104cbe
f01014c9:	e8 d2 eb ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01014ce:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01014d1:	39 c7                	cmp    %eax,%edi
f01014d3:	74 04                	je     f01014d9 <mem_init+0x423>
f01014d5:	39 c6                	cmp    %eax,%esi
f01014d7:	75 19                	jne    f01014f2 <mem_init+0x43c>
f01014d9:	68 30 51 10 f0       	push   $0xf0105130
f01014de:	68 e4 4c 10 f0       	push   $0xf0104ce4
f01014e3:	68 fc 02 00 00       	push   $0x2fc
f01014e8:	68 be 4c 10 f0       	push   $0xf0104cbe
f01014ed:	e8 ae eb ff ff       	call   f01000a0 <_panic>
	assert(!page_alloc(0));
f01014f2:	83 ec 0c             	sub    $0xc,%esp
f01014f5:	6a 00                	push   $0x0
f01014f7:	e8 79 f8 ff ff       	call   f0100d75 <page_alloc>
f01014fc:	83 c4 10             	add    $0x10,%esp
f01014ff:	85 c0                	test   %eax,%eax
f0101501:	74 19                	je     f010151c <mem_init+0x466>
f0101503:	68 5e 4e 10 f0       	push   $0xf0104e5e
f0101508:	68 e4 4c 10 f0       	push   $0xf0104ce4
f010150d:	68 fd 02 00 00       	push   $0x2fd
f0101512:	68 be 4c 10 f0       	push   $0xf0104cbe
f0101517:	e8 84 eb ff ff       	call   f01000a0 <_panic>
f010151c:	89 f0                	mov    %esi,%eax
f010151e:	2b 05 4c 5c 17 f0    	sub    0xf0175c4c,%eax
f0101524:	c1 f8 03             	sar    $0x3,%eax
f0101527:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010152a:	89 c2                	mov    %eax,%edx
f010152c:	c1 ea 0c             	shr    $0xc,%edx
f010152f:	3b 15 44 5c 17 f0    	cmp    0xf0175c44,%edx
f0101535:	72 12                	jb     f0101549 <mem_init+0x493>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101537:	50                   	push   %eax
f0101538:	68 c8 4f 10 f0       	push   $0xf0104fc8
f010153d:	6a 56                	push   $0x56
f010153f:	68 ca 4c 10 f0       	push   $0xf0104cca
f0101544:	e8 57 eb ff ff       	call   f01000a0 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101549:	83 ec 04             	sub    $0x4,%esp
f010154c:	68 00 10 00 00       	push   $0x1000
f0101551:	6a 01                	push   $0x1
f0101553:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101558:	50                   	push   %eax
f0101559:	e8 d8 2d 00 00       	call   f0104336 <memset>
	page_free(pp0);
f010155e:	89 34 24             	mov    %esi,(%esp)
f0101561:	e8 7f f8 ff ff       	call   f0100de5 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101566:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010156d:	e8 03 f8 ff ff       	call   f0100d75 <page_alloc>
f0101572:	83 c4 10             	add    $0x10,%esp
f0101575:	85 c0                	test   %eax,%eax
f0101577:	75 19                	jne    f0101592 <mem_init+0x4dc>
f0101579:	68 6d 4e 10 f0       	push   $0xf0104e6d
f010157e:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0101583:	68 02 03 00 00       	push   $0x302
f0101588:	68 be 4c 10 f0       	push   $0xf0104cbe
f010158d:	e8 0e eb ff ff       	call   f01000a0 <_panic>
	assert(pp && pp0 == pp);
f0101592:	39 c6                	cmp    %eax,%esi
f0101594:	74 19                	je     f01015af <mem_init+0x4f9>
f0101596:	68 8b 4e 10 f0       	push   $0xf0104e8b
f010159b:	68 e4 4c 10 f0       	push   $0xf0104ce4
f01015a0:	68 03 03 00 00       	push   $0x303
f01015a5:	68 be 4c 10 f0       	push   $0xf0104cbe
f01015aa:	e8 f1 ea ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01015af:	89 f0                	mov    %esi,%eax
f01015b1:	2b 05 4c 5c 17 f0    	sub    0xf0175c4c,%eax
f01015b7:	c1 f8 03             	sar    $0x3,%eax
f01015ba:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01015bd:	89 c2                	mov    %eax,%edx
f01015bf:	c1 ea 0c             	shr    $0xc,%edx
f01015c2:	3b 15 44 5c 17 f0    	cmp    0xf0175c44,%edx
f01015c8:	72 12                	jb     f01015dc <mem_init+0x526>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01015ca:	50                   	push   %eax
f01015cb:	68 c8 4f 10 f0       	push   $0xf0104fc8
f01015d0:	6a 56                	push   $0x56
f01015d2:	68 ca 4c 10 f0       	push   $0xf0104cca
f01015d7:	e8 c4 ea ff ff       	call   f01000a0 <_panic>
f01015dc:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01015e2:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01015e8:	80 38 00             	cmpb   $0x0,(%eax)
f01015eb:	74 19                	je     f0101606 <mem_init+0x550>
f01015ed:	68 9b 4e 10 f0       	push   $0xf0104e9b
f01015f2:	68 e4 4c 10 f0       	push   $0xf0104ce4
f01015f7:	68 06 03 00 00       	push   $0x306
f01015fc:	68 be 4c 10 f0       	push   $0xf0104cbe
f0101601:	e8 9a ea ff ff       	call   f01000a0 <_panic>
f0101606:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101609:	39 d0                	cmp    %edx,%eax
f010160b:	75 db                	jne    f01015e8 <mem_init+0x532>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f010160d:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101610:	a3 80 4f 17 f0       	mov    %eax,0xf0174f80

	// free the pages we took
	page_free(pp0);
f0101615:	83 ec 0c             	sub    $0xc,%esp
f0101618:	56                   	push   %esi
f0101619:	e8 c7 f7 ff ff       	call   f0100de5 <page_free>
	page_free(pp1);
f010161e:	89 3c 24             	mov    %edi,(%esp)
f0101621:	e8 bf f7 ff ff       	call   f0100de5 <page_free>
	page_free(pp2);
f0101626:	83 c4 04             	add    $0x4,%esp
f0101629:	ff 75 d4             	pushl  -0x2c(%ebp)
f010162c:	e8 b4 f7 ff ff       	call   f0100de5 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101631:	a1 80 4f 17 f0       	mov    0xf0174f80,%eax
f0101636:	83 c4 10             	add    $0x10,%esp
f0101639:	eb 05                	jmp    f0101640 <mem_init+0x58a>
		--nfree;
f010163b:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010163e:	8b 00                	mov    (%eax),%eax
f0101640:	85 c0                	test   %eax,%eax
f0101642:	75 f7                	jne    f010163b <mem_init+0x585>
		--nfree;
	assert(nfree == 0);
f0101644:	85 db                	test   %ebx,%ebx
f0101646:	74 19                	je     f0101661 <mem_init+0x5ab>
f0101648:	68 a5 4e 10 f0       	push   $0xf0104ea5
f010164d:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0101652:	68 13 03 00 00       	push   $0x313
f0101657:	68 be 4c 10 f0       	push   $0xf0104cbe
f010165c:	e8 3f ea ff ff       	call   f01000a0 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101661:	83 ec 0c             	sub    $0xc,%esp
f0101664:	68 50 51 10 f0       	push   $0xf0105150
f0101669:	e8 57 19 00 00       	call   f0102fc5 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010166e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101675:	e8 fb f6 ff ff       	call   f0100d75 <page_alloc>
f010167a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010167d:	83 c4 10             	add    $0x10,%esp
f0101680:	85 c0                	test   %eax,%eax
f0101682:	75 19                	jne    f010169d <mem_init+0x5e7>
f0101684:	68 b3 4d 10 f0       	push   $0xf0104db3
f0101689:	68 e4 4c 10 f0       	push   $0xf0104ce4
f010168e:	68 71 03 00 00       	push   $0x371
f0101693:	68 be 4c 10 f0       	push   $0xf0104cbe
f0101698:	e8 03 ea ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f010169d:	83 ec 0c             	sub    $0xc,%esp
f01016a0:	6a 00                	push   $0x0
f01016a2:	e8 ce f6 ff ff       	call   f0100d75 <page_alloc>
f01016a7:	89 c3                	mov    %eax,%ebx
f01016a9:	83 c4 10             	add    $0x10,%esp
f01016ac:	85 c0                	test   %eax,%eax
f01016ae:	75 19                	jne    f01016c9 <mem_init+0x613>
f01016b0:	68 c9 4d 10 f0       	push   $0xf0104dc9
f01016b5:	68 e4 4c 10 f0       	push   $0xf0104ce4
f01016ba:	68 72 03 00 00       	push   $0x372
f01016bf:	68 be 4c 10 f0       	push   $0xf0104cbe
f01016c4:	e8 d7 e9 ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f01016c9:	83 ec 0c             	sub    $0xc,%esp
f01016cc:	6a 00                	push   $0x0
f01016ce:	e8 a2 f6 ff ff       	call   f0100d75 <page_alloc>
f01016d3:	89 c6                	mov    %eax,%esi
f01016d5:	83 c4 10             	add    $0x10,%esp
f01016d8:	85 c0                	test   %eax,%eax
f01016da:	75 19                	jne    f01016f5 <mem_init+0x63f>
f01016dc:	68 df 4d 10 f0       	push   $0xf0104ddf
f01016e1:	68 e4 4c 10 f0       	push   $0xf0104ce4
f01016e6:	68 73 03 00 00       	push   $0x373
f01016eb:	68 be 4c 10 f0       	push   $0xf0104cbe
f01016f0:	e8 ab e9 ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01016f5:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01016f8:	75 19                	jne    f0101713 <mem_init+0x65d>
f01016fa:	68 f5 4d 10 f0       	push   $0xf0104df5
f01016ff:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0101704:	68 76 03 00 00       	push   $0x376
f0101709:	68 be 4c 10 f0       	push   $0xf0104cbe
f010170e:	e8 8d e9 ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101713:	39 c3                	cmp    %eax,%ebx
f0101715:	74 05                	je     f010171c <mem_init+0x666>
f0101717:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f010171a:	75 19                	jne    f0101735 <mem_init+0x67f>
f010171c:	68 30 51 10 f0       	push   $0xf0105130
f0101721:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0101726:	68 77 03 00 00       	push   $0x377
f010172b:	68 be 4c 10 f0       	push   $0xf0104cbe
f0101730:	e8 6b e9 ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101735:	a1 80 4f 17 f0       	mov    0xf0174f80,%eax
f010173a:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010173d:	c7 05 80 4f 17 f0 00 	movl   $0x0,0xf0174f80
f0101744:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101747:	83 ec 0c             	sub    $0xc,%esp
f010174a:	6a 00                	push   $0x0
f010174c:	e8 24 f6 ff ff       	call   f0100d75 <page_alloc>
f0101751:	83 c4 10             	add    $0x10,%esp
f0101754:	85 c0                	test   %eax,%eax
f0101756:	74 19                	je     f0101771 <mem_init+0x6bb>
f0101758:	68 5e 4e 10 f0       	push   $0xf0104e5e
f010175d:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0101762:	68 7e 03 00 00       	push   $0x37e
f0101767:	68 be 4c 10 f0       	push   $0xf0104cbe
f010176c:	e8 2f e9 ff ff       	call   f01000a0 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101771:	83 ec 04             	sub    $0x4,%esp
f0101774:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101777:	50                   	push   %eax
f0101778:	6a 00                	push   $0x0
f010177a:	ff 35 48 5c 17 f0    	pushl  0xf0175c48
f0101780:	e8 03 f8 ff ff       	call   f0100f88 <page_lookup>
f0101785:	83 c4 10             	add    $0x10,%esp
f0101788:	85 c0                	test   %eax,%eax
f010178a:	74 19                	je     f01017a5 <mem_init+0x6ef>
f010178c:	68 70 51 10 f0       	push   $0xf0105170
f0101791:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0101796:	68 81 03 00 00       	push   $0x381
f010179b:	68 be 4c 10 f0       	push   $0xf0104cbe
f01017a0:	e8 fb e8 ff ff       	call   f01000a0 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01017a5:	6a 02                	push   $0x2
f01017a7:	6a 00                	push   $0x0
f01017a9:	53                   	push   %ebx
f01017aa:	ff 35 48 5c 17 f0    	pushl  0xf0175c48
f01017b0:	e8 68 f8 ff ff       	call   f010101d <page_insert>
f01017b5:	83 c4 10             	add    $0x10,%esp
f01017b8:	85 c0                	test   %eax,%eax
f01017ba:	78 19                	js     f01017d5 <mem_init+0x71f>
f01017bc:	68 a8 51 10 f0       	push   $0xf01051a8
f01017c1:	68 e4 4c 10 f0       	push   $0xf0104ce4
f01017c6:	68 84 03 00 00       	push   $0x384
f01017cb:	68 be 4c 10 f0       	push   $0xf0104cbe
f01017d0:	e8 cb e8 ff ff       	call   f01000a0 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01017d5:	83 ec 0c             	sub    $0xc,%esp
f01017d8:	ff 75 d4             	pushl  -0x2c(%ebp)
f01017db:	e8 05 f6 ff ff       	call   f0100de5 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01017e0:	6a 02                	push   $0x2
f01017e2:	6a 00                	push   $0x0
f01017e4:	53                   	push   %ebx
f01017e5:	ff 35 48 5c 17 f0    	pushl  0xf0175c48
f01017eb:	e8 2d f8 ff ff       	call   f010101d <page_insert>
f01017f0:	83 c4 20             	add    $0x20,%esp
f01017f3:	85 c0                	test   %eax,%eax
f01017f5:	74 19                	je     f0101810 <mem_init+0x75a>
f01017f7:	68 d8 51 10 f0       	push   $0xf01051d8
f01017fc:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0101801:	68 88 03 00 00       	push   $0x388
f0101806:	68 be 4c 10 f0       	push   $0xf0104cbe
f010180b:	e8 90 e8 ff ff       	call   f01000a0 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101810:	8b 3d 48 5c 17 f0    	mov    0xf0175c48,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101816:	a1 4c 5c 17 f0       	mov    0xf0175c4c,%eax
f010181b:	89 c1                	mov    %eax,%ecx
f010181d:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0101820:	8b 17                	mov    (%edi),%edx
f0101822:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101828:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010182b:	29 c8                	sub    %ecx,%eax
f010182d:	c1 f8 03             	sar    $0x3,%eax
f0101830:	c1 e0 0c             	shl    $0xc,%eax
f0101833:	39 c2                	cmp    %eax,%edx
f0101835:	74 19                	je     f0101850 <mem_init+0x79a>
f0101837:	68 08 52 10 f0       	push   $0xf0105208
f010183c:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0101841:	68 89 03 00 00       	push   $0x389
f0101846:	68 be 4c 10 f0       	push   $0xf0104cbe
f010184b:	e8 50 e8 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101850:	ba 00 00 00 00       	mov    $0x0,%edx
f0101855:	89 f8                	mov    %edi,%eax
f0101857:	e8 09 f1 ff ff       	call   f0100965 <check_va2pa>
f010185c:	89 da                	mov    %ebx,%edx
f010185e:	2b 55 c8             	sub    -0x38(%ebp),%edx
f0101861:	c1 fa 03             	sar    $0x3,%edx
f0101864:	c1 e2 0c             	shl    $0xc,%edx
f0101867:	39 d0                	cmp    %edx,%eax
f0101869:	74 19                	je     f0101884 <mem_init+0x7ce>
f010186b:	68 30 52 10 f0       	push   $0xf0105230
f0101870:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0101875:	68 8a 03 00 00       	push   $0x38a
f010187a:	68 be 4c 10 f0       	push   $0xf0104cbe
f010187f:	e8 1c e8 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f0101884:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101889:	74 19                	je     f01018a4 <mem_init+0x7ee>
f010188b:	68 b0 4e 10 f0       	push   $0xf0104eb0
f0101890:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0101895:	68 8b 03 00 00       	push   $0x38b
f010189a:	68 be 4c 10 f0       	push   $0xf0104cbe
f010189f:	e8 fc e7 ff ff       	call   f01000a0 <_panic>
	assert(pp0->pp_ref == 1);
f01018a4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01018a7:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01018ac:	74 19                	je     f01018c7 <mem_init+0x811>
f01018ae:	68 c1 4e 10 f0       	push   $0xf0104ec1
f01018b3:	68 e4 4c 10 f0       	push   $0xf0104ce4
f01018b8:	68 8c 03 00 00       	push   $0x38c
f01018bd:	68 be 4c 10 f0       	push   $0xf0104cbe
f01018c2:	e8 d9 e7 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01018c7:	6a 02                	push   $0x2
f01018c9:	68 00 10 00 00       	push   $0x1000
f01018ce:	56                   	push   %esi
f01018cf:	57                   	push   %edi
f01018d0:	e8 48 f7 ff ff       	call   f010101d <page_insert>
f01018d5:	83 c4 10             	add    $0x10,%esp
f01018d8:	85 c0                	test   %eax,%eax
f01018da:	74 19                	je     f01018f5 <mem_init+0x83f>
f01018dc:	68 60 52 10 f0       	push   $0xf0105260
f01018e1:	68 e4 4c 10 f0       	push   $0xf0104ce4
f01018e6:	68 8f 03 00 00       	push   $0x38f
f01018eb:	68 be 4c 10 f0       	push   $0xf0104cbe
f01018f0:	e8 ab e7 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01018f5:	ba 00 10 00 00       	mov    $0x1000,%edx
f01018fa:	a1 48 5c 17 f0       	mov    0xf0175c48,%eax
f01018ff:	e8 61 f0 ff ff       	call   f0100965 <check_va2pa>
f0101904:	89 f2                	mov    %esi,%edx
f0101906:	2b 15 4c 5c 17 f0    	sub    0xf0175c4c,%edx
f010190c:	c1 fa 03             	sar    $0x3,%edx
f010190f:	c1 e2 0c             	shl    $0xc,%edx
f0101912:	39 d0                	cmp    %edx,%eax
f0101914:	74 19                	je     f010192f <mem_init+0x879>
f0101916:	68 9c 52 10 f0       	push   $0xf010529c
f010191b:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0101920:	68 90 03 00 00       	push   $0x390
f0101925:	68 be 4c 10 f0       	push   $0xf0104cbe
f010192a:	e8 71 e7 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f010192f:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101934:	74 19                	je     f010194f <mem_init+0x899>
f0101936:	68 d2 4e 10 f0       	push   $0xf0104ed2
f010193b:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0101940:	68 91 03 00 00       	push   $0x391
f0101945:	68 be 4c 10 f0       	push   $0xf0104cbe
f010194a:	e8 51 e7 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010194f:	83 ec 0c             	sub    $0xc,%esp
f0101952:	6a 00                	push   $0x0
f0101954:	e8 1c f4 ff ff       	call   f0100d75 <page_alloc>
f0101959:	83 c4 10             	add    $0x10,%esp
f010195c:	85 c0                	test   %eax,%eax
f010195e:	74 19                	je     f0101979 <mem_init+0x8c3>
f0101960:	68 5e 4e 10 f0       	push   $0xf0104e5e
f0101965:	68 e4 4c 10 f0       	push   $0xf0104ce4
f010196a:	68 94 03 00 00       	push   $0x394
f010196f:	68 be 4c 10 f0       	push   $0xf0104cbe
f0101974:	e8 27 e7 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101979:	6a 02                	push   $0x2
f010197b:	68 00 10 00 00       	push   $0x1000
f0101980:	56                   	push   %esi
f0101981:	ff 35 48 5c 17 f0    	pushl  0xf0175c48
f0101987:	e8 91 f6 ff ff       	call   f010101d <page_insert>
f010198c:	83 c4 10             	add    $0x10,%esp
f010198f:	85 c0                	test   %eax,%eax
f0101991:	74 19                	je     f01019ac <mem_init+0x8f6>
f0101993:	68 60 52 10 f0       	push   $0xf0105260
f0101998:	68 e4 4c 10 f0       	push   $0xf0104ce4
f010199d:	68 97 03 00 00       	push   $0x397
f01019a2:	68 be 4c 10 f0       	push   $0xf0104cbe
f01019a7:	e8 f4 e6 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01019ac:	ba 00 10 00 00       	mov    $0x1000,%edx
f01019b1:	a1 48 5c 17 f0       	mov    0xf0175c48,%eax
f01019b6:	e8 aa ef ff ff       	call   f0100965 <check_va2pa>
f01019bb:	89 f2                	mov    %esi,%edx
f01019bd:	2b 15 4c 5c 17 f0    	sub    0xf0175c4c,%edx
f01019c3:	c1 fa 03             	sar    $0x3,%edx
f01019c6:	c1 e2 0c             	shl    $0xc,%edx
f01019c9:	39 d0                	cmp    %edx,%eax
f01019cb:	74 19                	je     f01019e6 <mem_init+0x930>
f01019cd:	68 9c 52 10 f0       	push   $0xf010529c
f01019d2:	68 e4 4c 10 f0       	push   $0xf0104ce4
f01019d7:	68 98 03 00 00       	push   $0x398
f01019dc:	68 be 4c 10 f0       	push   $0xf0104cbe
f01019e1:	e8 ba e6 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f01019e6:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01019eb:	74 19                	je     f0101a06 <mem_init+0x950>
f01019ed:	68 d2 4e 10 f0       	push   $0xf0104ed2
f01019f2:	68 e4 4c 10 f0       	push   $0xf0104ce4
f01019f7:	68 99 03 00 00       	push   $0x399
f01019fc:	68 be 4c 10 f0       	push   $0xf0104cbe
f0101a01:	e8 9a e6 ff ff       	call   f01000a0 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101a06:	83 ec 0c             	sub    $0xc,%esp
f0101a09:	6a 00                	push   $0x0
f0101a0b:	e8 65 f3 ff ff       	call   f0100d75 <page_alloc>
f0101a10:	83 c4 10             	add    $0x10,%esp
f0101a13:	85 c0                	test   %eax,%eax
f0101a15:	74 19                	je     f0101a30 <mem_init+0x97a>
f0101a17:	68 5e 4e 10 f0       	push   $0xf0104e5e
f0101a1c:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0101a21:	68 9d 03 00 00       	push   $0x39d
f0101a26:	68 be 4c 10 f0       	push   $0xf0104cbe
f0101a2b:	e8 70 e6 ff ff       	call   f01000a0 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101a30:	8b 15 48 5c 17 f0    	mov    0xf0175c48,%edx
f0101a36:	8b 02                	mov    (%edx),%eax
f0101a38:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101a3d:	89 c1                	mov    %eax,%ecx
f0101a3f:	c1 e9 0c             	shr    $0xc,%ecx
f0101a42:	3b 0d 44 5c 17 f0    	cmp    0xf0175c44,%ecx
f0101a48:	72 15                	jb     f0101a5f <mem_init+0x9a9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101a4a:	50                   	push   %eax
f0101a4b:	68 c8 4f 10 f0       	push   $0xf0104fc8
f0101a50:	68 a0 03 00 00       	push   $0x3a0
f0101a55:	68 be 4c 10 f0       	push   $0xf0104cbe
f0101a5a:	e8 41 e6 ff ff       	call   f01000a0 <_panic>
f0101a5f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101a64:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101a67:	83 ec 04             	sub    $0x4,%esp
f0101a6a:	6a 00                	push   $0x0
f0101a6c:	68 00 10 00 00       	push   $0x1000
f0101a71:	52                   	push   %edx
f0101a72:	e8 eb f3 ff ff       	call   f0100e62 <pgdir_walk>
f0101a77:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101a7a:	8d 57 04             	lea    0x4(%edi),%edx
f0101a7d:	83 c4 10             	add    $0x10,%esp
f0101a80:	39 d0                	cmp    %edx,%eax
f0101a82:	74 19                	je     f0101a9d <mem_init+0x9e7>
f0101a84:	68 cc 52 10 f0       	push   $0xf01052cc
f0101a89:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0101a8e:	68 a1 03 00 00       	push   $0x3a1
f0101a93:	68 be 4c 10 f0       	push   $0xf0104cbe
f0101a98:	e8 03 e6 ff ff       	call   f01000a0 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101a9d:	6a 06                	push   $0x6
f0101a9f:	68 00 10 00 00       	push   $0x1000
f0101aa4:	56                   	push   %esi
f0101aa5:	ff 35 48 5c 17 f0    	pushl  0xf0175c48
f0101aab:	e8 6d f5 ff ff       	call   f010101d <page_insert>
f0101ab0:	83 c4 10             	add    $0x10,%esp
f0101ab3:	85 c0                	test   %eax,%eax
f0101ab5:	74 19                	je     f0101ad0 <mem_init+0xa1a>
f0101ab7:	68 0c 53 10 f0       	push   $0xf010530c
f0101abc:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0101ac1:	68 a4 03 00 00       	push   $0x3a4
f0101ac6:	68 be 4c 10 f0       	push   $0xf0104cbe
f0101acb:	e8 d0 e5 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101ad0:	8b 3d 48 5c 17 f0    	mov    0xf0175c48,%edi
f0101ad6:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101adb:	89 f8                	mov    %edi,%eax
f0101add:	e8 83 ee ff ff       	call   f0100965 <check_va2pa>
f0101ae2:	89 f2                	mov    %esi,%edx
f0101ae4:	2b 15 4c 5c 17 f0    	sub    0xf0175c4c,%edx
f0101aea:	c1 fa 03             	sar    $0x3,%edx
f0101aed:	c1 e2 0c             	shl    $0xc,%edx
f0101af0:	39 d0                	cmp    %edx,%eax
f0101af2:	74 19                	je     f0101b0d <mem_init+0xa57>
f0101af4:	68 9c 52 10 f0       	push   $0xf010529c
f0101af9:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0101afe:	68 a5 03 00 00       	push   $0x3a5
f0101b03:	68 be 4c 10 f0       	push   $0xf0104cbe
f0101b08:	e8 93 e5 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101b0d:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101b12:	74 19                	je     f0101b2d <mem_init+0xa77>
f0101b14:	68 d2 4e 10 f0       	push   $0xf0104ed2
f0101b19:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0101b1e:	68 a6 03 00 00       	push   $0x3a6
f0101b23:	68 be 4c 10 f0       	push   $0xf0104cbe
f0101b28:	e8 73 e5 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101b2d:	83 ec 04             	sub    $0x4,%esp
f0101b30:	6a 00                	push   $0x0
f0101b32:	68 00 10 00 00       	push   $0x1000
f0101b37:	57                   	push   %edi
f0101b38:	e8 25 f3 ff ff       	call   f0100e62 <pgdir_walk>
f0101b3d:	83 c4 10             	add    $0x10,%esp
f0101b40:	f6 00 04             	testb  $0x4,(%eax)
f0101b43:	75 19                	jne    f0101b5e <mem_init+0xaa8>
f0101b45:	68 4c 53 10 f0       	push   $0xf010534c
f0101b4a:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0101b4f:	68 a7 03 00 00       	push   $0x3a7
f0101b54:	68 be 4c 10 f0       	push   $0xf0104cbe
f0101b59:	e8 42 e5 ff ff       	call   f01000a0 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101b5e:	a1 48 5c 17 f0       	mov    0xf0175c48,%eax
f0101b63:	f6 00 04             	testb  $0x4,(%eax)
f0101b66:	75 19                	jne    f0101b81 <mem_init+0xacb>
f0101b68:	68 e3 4e 10 f0       	push   $0xf0104ee3
f0101b6d:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0101b72:	68 a8 03 00 00       	push   $0x3a8
f0101b77:	68 be 4c 10 f0       	push   $0xf0104cbe
f0101b7c:	e8 1f e5 ff ff       	call   f01000a0 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b81:	6a 02                	push   $0x2
f0101b83:	68 00 10 00 00       	push   $0x1000
f0101b88:	56                   	push   %esi
f0101b89:	50                   	push   %eax
f0101b8a:	e8 8e f4 ff ff       	call   f010101d <page_insert>
f0101b8f:	83 c4 10             	add    $0x10,%esp
f0101b92:	85 c0                	test   %eax,%eax
f0101b94:	74 19                	je     f0101baf <mem_init+0xaf9>
f0101b96:	68 60 52 10 f0       	push   $0xf0105260
f0101b9b:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0101ba0:	68 ab 03 00 00       	push   $0x3ab
f0101ba5:	68 be 4c 10 f0       	push   $0xf0104cbe
f0101baa:	e8 f1 e4 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101baf:	83 ec 04             	sub    $0x4,%esp
f0101bb2:	6a 00                	push   $0x0
f0101bb4:	68 00 10 00 00       	push   $0x1000
f0101bb9:	ff 35 48 5c 17 f0    	pushl  0xf0175c48
f0101bbf:	e8 9e f2 ff ff       	call   f0100e62 <pgdir_walk>
f0101bc4:	83 c4 10             	add    $0x10,%esp
f0101bc7:	f6 00 02             	testb  $0x2,(%eax)
f0101bca:	75 19                	jne    f0101be5 <mem_init+0xb2f>
f0101bcc:	68 80 53 10 f0       	push   $0xf0105380
f0101bd1:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0101bd6:	68 ac 03 00 00       	push   $0x3ac
f0101bdb:	68 be 4c 10 f0       	push   $0xf0104cbe
f0101be0:	e8 bb e4 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101be5:	83 ec 04             	sub    $0x4,%esp
f0101be8:	6a 00                	push   $0x0
f0101bea:	68 00 10 00 00       	push   $0x1000
f0101bef:	ff 35 48 5c 17 f0    	pushl  0xf0175c48
f0101bf5:	e8 68 f2 ff ff       	call   f0100e62 <pgdir_walk>
f0101bfa:	83 c4 10             	add    $0x10,%esp
f0101bfd:	f6 00 04             	testb  $0x4,(%eax)
f0101c00:	74 19                	je     f0101c1b <mem_init+0xb65>
f0101c02:	68 b4 53 10 f0       	push   $0xf01053b4
f0101c07:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0101c0c:	68 ad 03 00 00       	push   $0x3ad
f0101c11:	68 be 4c 10 f0       	push   $0xf0104cbe
f0101c16:	e8 85 e4 ff ff       	call   f01000a0 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101c1b:	6a 02                	push   $0x2
f0101c1d:	68 00 00 40 00       	push   $0x400000
f0101c22:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101c25:	ff 35 48 5c 17 f0    	pushl  0xf0175c48
f0101c2b:	e8 ed f3 ff ff       	call   f010101d <page_insert>
f0101c30:	83 c4 10             	add    $0x10,%esp
f0101c33:	85 c0                	test   %eax,%eax
f0101c35:	78 19                	js     f0101c50 <mem_init+0xb9a>
f0101c37:	68 ec 53 10 f0       	push   $0xf01053ec
f0101c3c:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0101c41:	68 b0 03 00 00       	push   $0x3b0
f0101c46:	68 be 4c 10 f0       	push   $0xf0104cbe
f0101c4b:	e8 50 e4 ff ff       	call   f01000a0 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101c50:	6a 02                	push   $0x2
f0101c52:	68 00 10 00 00       	push   $0x1000
f0101c57:	53                   	push   %ebx
f0101c58:	ff 35 48 5c 17 f0    	pushl  0xf0175c48
f0101c5e:	e8 ba f3 ff ff       	call   f010101d <page_insert>
f0101c63:	83 c4 10             	add    $0x10,%esp
f0101c66:	85 c0                	test   %eax,%eax
f0101c68:	74 19                	je     f0101c83 <mem_init+0xbcd>
f0101c6a:	68 24 54 10 f0       	push   $0xf0105424
f0101c6f:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0101c74:	68 b3 03 00 00       	push   $0x3b3
f0101c79:	68 be 4c 10 f0       	push   $0xf0104cbe
f0101c7e:	e8 1d e4 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101c83:	83 ec 04             	sub    $0x4,%esp
f0101c86:	6a 00                	push   $0x0
f0101c88:	68 00 10 00 00       	push   $0x1000
f0101c8d:	ff 35 48 5c 17 f0    	pushl  0xf0175c48
f0101c93:	e8 ca f1 ff ff       	call   f0100e62 <pgdir_walk>
f0101c98:	83 c4 10             	add    $0x10,%esp
f0101c9b:	f6 00 04             	testb  $0x4,(%eax)
f0101c9e:	74 19                	je     f0101cb9 <mem_init+0xc03>
f0101ca0:	68 b4 53 10 f0       	push   $0xf01053b4
f0101ca5:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0101caa:	68 b4 03 00 00       	push   $0x3b4
f0101caf:	68 be 4c 10 f0       	push   $0xf0104cbe
f0101cb4:	e8 e7 e3 ff ff       	call   f01000a0 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101cb9:	8b 3d 48 5c 17 f0    	mov    0xf0175c48,%edi
f0101cbf:	ba 00 00 00 00       	mov    $0x0,%edx
f0101cc4:	89 f8                	mov    %edi,%eax
f0101cc6:	e8 9a ec ff ff       	call   f0100965 <check_va2pa>
f0101ccb:	89 c1                	mov    %eax,%ecx
f0101ccd:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0101cd0:	89 d8                	mov    %ebx,%eax
f0101cd2:	2b 05 4c 5c 17 f0    	sub    0xf0175c4c,%eax
f0101cd8:	c1 f8 03             	sar    $0x3,%eax
f0101cdb:	c1 e0 0c             	shl    $0xc,%eax
f0101cde:	39 c1                	cmp    %eax,%ecx
f0101ce0:	74 19                	je     f0101cfb <mem_init+0xc45>
f0101ce2:	68 60 54 10 f0       	push   $0xf0105460
f0101ce7:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0101cec:	68 b7 03 00 00       	push   $0x3b7
f0101cf1:	68 be 4c 10 f0       	push   $0xf0104cbe
f0101cf6:	e8 a5 e3 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101cfb:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d00:	89 f8                	mov    %edi,%eax
f0101d02:	e8 5e ec ff ff       	call   f0100965 <check_va2pa>
f0101d07:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0101d0a:	74 19                	je     f0101d25 <mem_init+0xc6f>
f0101d0c:	68 8c 54 10 f0       	push   $0xf010548c
f0101d11:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0101d16:	68 b8 03 00 00       	push   $0x3b8
f0101d1b:	68 be 4c 10 f0       	push   $0xf0104cbe
f0101d20:	e8 7b e3 ff ff       	call   f01000a0 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101d25:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101d2a:	74 19                	je     f0101d45 <mem_init+0xc8f>
f0101d2c:	68 f9 4e 10 f0       	push   $0xf0104ef9
f0101d31:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0101d36:	68 ba 03 00 00       	push   $0x3ba
f0101d3b:	68 be 4c 10 f0       	push   $0xf0104cbe
f0101d40:	e8 5b e3 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101d45:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101d4a:	74 19                	je     f0101d65 <mem_init+0xcaf>
f0101d4c:	68 0a 4f 10 f0       	push   $0xf0104f0a
f0101d51:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0101d56:	68 bb 03 00 00       	push   $0x3bb
f0101d5b:	68 be 4c 10 f0       	push   $0xf0104cbe
f0101d60:	e8 3b e3 ff ff       	call   f01000a0 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101d65:	83 ec 0c             	sub    $0xc,%esp
f0101d68:	6a 00                	push   $0x0
f0101d6a:	e8 06 f0 ff ff       	call   f0100d75 <page_alloc>
f0101d6f:	83 c4 10             	add    $0x10,%esp
f0101d72:	85 c0                	test   %eax,%eax
f0101d74:	74 04                	je     f0101d7a <mem_init+0xcc4>
f0101d76:	39 c6                	cmp    %eax,%esi
f0101d78:	74 19                	je     f0101d93 <mem_init+0xcdd>
f0101d7a:	68 bc 54 10 f0       	push   $0xf01054bc
f0101d7f:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0101d84:	68 be 03 00 00       	push   $0x3be
f0101d89:	68 be 4c 10 f0       	push   $0xf0104cbe
f0101d8e:	e8 0d e3 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101d93:	83 ec 08             	sub    $0x8,%esp
f0101d96:	6a 00                	push   $0x0
f0101d98:	ff 35 48 5c 17 f0    	pushl  0xf0175c48
f0101d9e:	e8 3f f2 ff ff       	call   f0100fe2 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101da3:	8b 3d 48 5c 17 f0    	mov    0xf0175c48,%edi
f0101da9:	ba 00 00 00 00       	mov    $0x0,%edx
f0101dae:	89 f8                	mov    %edi,%eax
f0101db0:	e8 b0 eb ff ff       	call   f0100965 <check_va2pa>
f0101db5:	83 c4 10             	add    $0x10,%esp
f0101db8:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101dbb:	74 19                	je     f0101dd6 <mem_init+0xd20>
f0101dbd:	68 e0 54 10 f0       	push   $0xf01054e0
f0101dc2:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0101dc7:	68 c2 03 00 00       	push   $0x3c2
f0101dcc:	68 be 4c 10 f0       	push   $0xf0104cbe
f0101dd1:	e8 ca e2 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101dd6:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ddb:	89 f8                	mov    %edi,%eax
f0101ddd:	e8 83 eb ff ff       	call   f0100965 <check_va2pa>
f0101de2:	89 da                	mov    %ebx,%edx
f0101de4:	2b 15 4c 5c 17 f0    	sub    0xf0175c4c,%edx
f0101dea:	c1 fa 03             	sar    $0x3,%edx
f0101ded:	c1 e2 0c             	shl    $0xc,%edx
f0101df0:	39 d0                	cmp    %edx,%eax
f0101df2:	74 19                	je     f0101e0d <mem_init+0xd57>
f0101df4:	68 8c 54 10 f0       	push   $0xf010548c
f0101df9:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0101dfe:	68 c3 03 00 00       	push   $0x3c3
f0101e03:	68 be 4c 10 f0       	push   $0xf0104cbe
f0101e08:	e8 93 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f0101e0d:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101e12:	74 19                	je     f0101e2d <mem_init+0xd77>
f0101e14:	68 b0 4e 10 f0       	push   $0xf0104eb0
f0101e19:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0101e1e:	68 c4 03 00 00       	push   $0x3c4
f0101e23:	68 be 4c 10 f0       	push   $0xf0104cbe
f0101e28:	e8 73 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101e2d:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101e32:	74 19                	je     f0101e4d <mem_init+0xd97>
f0101e34:	68 0a 4f 10 f0       	push   $0xf0104f0a
f0101e39:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0101e3e:	68 c5 03 00 00       	push   $0x3c5
f0101e43:	68 be 4c 10 f0       	push   $0xf0104cbe
f0101e48:	e8 53 e2 ff ff       	call   f01000a0 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101e4d:	6a 00                	push   $0x0
f0101e4f:	68 00 10 00 00       	push   $0x1000
f0101e54:	53                   	push   %ebx
f0101e55:	57                   	push   %edi
f0101e56:	e8 c2 f1 ff ff       	call   f010101d <page_insert>
f0101e5b:	83 c4 10             	add    $0x10,%esp
f0101e5e:	85 c0                	test   %eax,%eax
f0101e60:	74 19                	je     f0101e7b <mem_init+0xdc5>
f0101e62:	68 04 55 10 f0       	push   $0xf0105504
f0101e67:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0101e6c:	68 c8 03 00 00       	push   $0x3c8
f0101e71:	68 be 4c 10 f0       	push   $0xf0104cbe
f0101e76:	e8 25 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref);
f0101e7b:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101e80:	75 19                	jne    f0101e9b <mem_init+0xde5>
f0101e82:	68 1b 4f 10 f0       	push   $0xf0104f1b
f0101e87:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0101e8c:	68 c9 03 00 00       	push   $0x3c9
f0101e91:	68 be 4c 10 f0       	push   $0xf0104cbe
f0101e96:	e8 05 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_link == NULL);
f0101e9b:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101e9e:	74 19                	je     f0101eb9 <mem_init+0xe03>
f0101ea0:	68 27 4f 10 f0       	push   $0xf0104f27
f0101ea5:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0101eaa:	68 ca 03 00 00       	push   $0x3ca
f0101eaf:	68 be 4c 10 f0       	push   $0xf0104cbe
f0101eb4:	e8 e7 e1 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101eb9:	83 ec 08             	sub    $0x8,%esp
f0101ebc:	68 00 10 00 00       	push   $0x1000
f0101ec1:	ff 35 48 5c 17 f0    	pushl  0xf0175c48
f0101ec7:	e8 16 f1 ff ff       	call   f0100fe2 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101ecc:	8b 3d 48 5c 17 f0    	mov    0xf0175c48,%edi
f0101ed2:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ed7:	89 f8                	mov    %edi,%eax
f0101ed9:	e8 87 ea ff ff       	call   f0100965 <check_va2pa>
f0101ede:	83 c4 10             	add    $0x10,%esp
f0101ee1:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101ee4:	74 19                	je     f0101eff <mem_init+0xe49>
f0101ee6:	68 e0 54 10 f0       	push   $0xf01054e0
f0101eeb:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0101ef0:	68 ce 03 00 00       	push   $0x3ce
f0101ef5:	68 be 4c 10 f0       	push   $0xf0104cbe
f0101efa:	e8 a1 e1 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101eff:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f04:	89 f8                	mov    %edi,%eax
f0101f06:	e8 5a ea ff ff       	call   f0100965 <check_va2pa>
f0101f0b:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f0e:	74 19                	je     f0101f29 <mem_init+0xe73>
f0101f10:	68 3c 55 10 f0       	push   $0xf010553c
f0101f15:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0101f1a:	68 cf 03 00 00       	push   $0x3cf
f0101f1f:	68 be 4c 10 f0       	push   $0xf0104cbe
f0101f24:	e8 77 e1 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f0101f29:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101f2e:	74 19                	je     f0101f49 <mem_init+0xe93>
f0101f30:	68 3c 4f 10 f0       	push   $0xf0104f3c
f0101f35:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0101f3a:	68 d0 03 00 00       	push   $0x3d0
f0101f3f:	68 be 4c 10 f0       	push   $0xf0104cbe
f0101f44:	e8 57 e1 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101f49:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101f4e:	74 19                	je     f0101f69 <mem_init+0xeb3>
f0101f50:	68 0a 4f 10 f0       	push   $0xf0104f0a
f0101f55:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0101f5a:	68 d1 03 00 00       	push   $0x3d1
f0101f5f:	68 be 4c 10 f0       	push   $0xf0104cbe
f0101f64:	e8 37 e1 ff ff       	call   f01000a0 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101f69:	83 ec 0c             	sub    $0xc,%esp
f0101f6c:	6a 00                	push   $0x0
f0101f6e:	e8 02 ee ff ff       	call   f0100d75 <page_alloc>
f0101f73:	83 c4 10             	add    $0x10,%esp
f0101f76:	39 c3                	cmp    %eax,%ebx
f0101f78:	75 04                	jne    f0101f7e <mem_init+0xec8>
f0101f7a:	85 c0                	test   %eax,%eax
f0101f7c:	75 19                	jne    f0101f97 <mem_init+0xee1>
f0101f7e:	68 64 55 10 f0       	push   $0xf0105564
f0101f83:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0101f88:	68 d4 03 00 00       	push   $0x3d4
f0101f8d:	68 be 4c 10 f0       	push   $0xf0104cbe
f0101f92:	e8 09 e1 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101f97:	83 ec 0c             	sub    $0xc,%esp
f0101f9a:	6a 00                	push   $0x0
f0101f9c:	e8 d4 ed ff ff       	call   f0100d75 <page_alloc>
f0101fa1:	83 c4 10             	add    $0x10,%esp
f0101fa4:	85 c0                	test   %eax,%eax
f0101fa6:	74 19                	je     f0101fc1 <mem_init+0xf0b>
f0101fa8:	68 5e 4e 10 f0       	push   $0xf0104e5e
f0101fad:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0101fb2:	68 d7 03 00 00       	push   $0x3d7
f0101fb7:	68 be 4c 10 f0       	push   $0xf0104cbe
f0101fbc:	e8 df e0 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101fc1:	8b 0d 48 5c 17 f0    	mov    0xf0175c48,%ecx
f0101fc7:	8b 11                	mov    (%ecx),%edx
f0101fc9:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101fcf:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fd2:	2b 05 4c 5c 17 f0    	sub    0xf0175c4c,%eax
f0101fd8:	c1 f8 03             	sar    $0x3,%eax
f0101fdb:	c1 e0 0c             	shl    $0xc,%eax
f0101fde:	39 c2                	cmp    %eax,%edx
f0101fe0:	74 19                	je     f0101ffb <mem_init+0xf45>
f0101fe2:	68 08 52 10 f0       	push   $0xf0105208
f0101fe7:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0101fec:	68 da 03 00 00       	push   $0x3da
f0101ff1:	68 be 4c 10 f0       	push   $0xf0104cbe
f0101ff6:	e8 a5 e0 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f0101ffb:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102001:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102004:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102009:	74 19                	je     f0102024 <mem_init+0xf6e>
f010200b:	68 c1 4e 10 f0       	push   $0xf0104ec1
f0102010:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0102015:	68 dc 03 00 00       	push   $0x3dc
f010201a:	68 be 4c 10 f0       	push   $0xf0104cbe
f010201f:	e8 7c e0 ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f0102024:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102027:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f010202d:	83 ec 0c             	sub    $0xc,%esp
f0102030:	50                   	push   %eax
f0102031:	e8 af ed ff ff       	call   f0100de5 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102036:	83 c4 0c             	add    $0xc,%esp
f0102039:	6a 01                	push   $0x1
f010203b:	68 00 10 40 00       	push   $0x401000
f0102040:	ff 35 48 5c 17 f0    	pushl  0xf0175c48
f0102046:	e8 17 ee ff ff       	call   f0100e62 <pgdir_walk>
f010204b:	89 45 c8             	mov    %eax,-0x38(%ebp)
f010204e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102051:	8b 0d 48 5c 17 f0    	mov    0xf0175c48,%ecx
f0102057:	8b 51 04             	mov    0x4(%ecx),%edx
f010205a:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102060:	8b 3d 44 5c 17 f0    	mov    0xf0175c44,%edi
f0102066:	89 d0                	mov    %edx,%eax
f0102068:	c1 e8 0c             	shr    $0xc,%eax
f010206b:	83 c4 10             	add    $0x10,%esp
f010206e:	39 f8                	cmp    %edi,%eax
f0102070:	72 15                	jb     f0102087 <mem_init+0xfd1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102072:	52                   	push   %edx
f0102073:	68 c8 4f 10 f0       	push   $0xf0104fc8
f0102078:	68 e3 03 00 00       	push   $0x3e3
f010207d:	68 be 4c 10 f0       	push   $0xf0104cbe
f0102082:	e8 19 e0 ff ff       	call   f01000a0 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102087:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f010208d:	39 55 c8             	cmp    %edx,-0x38(%ebp)
f0102090:	74 19                	je     f01020ab <mem_init+0xff5>
f0102092:	68 4d 4f 10 f0       	push   $0xf0104f4d
f0102097:	68 e4 4c 10 f0       	push   $0xf0104ce4
f010209c:	68 e4 03 00 00       	push   $0x3e4
f01020a1:	68 be 4c 10 f0       	push   $0xf0104cbe
f01020a6:	e8 f5 df ff ff       	call   f01000a0 <_panic>
	kern_pgdir[PDX(va)] = 0;
f01020ab:	c7 41 04 00 00 00 00 	movl   $0x0,0x4(%ecx)
	pp0->pp_ref = 0;
f01020b2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020b5:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01020bb:	2b 05 4c 5c 17 f0    	sub    0xf0175c4c,%eax
f01020c1:	c1 f8 03             	sar    $0x3,%eax
f01020c4:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01020c7:	89 c2                	mov    %eax,%edx
f01020c9:	c1 ea 0c             	shr    $0xc,%edx
f01020cc:	39 d7                	cmp    %edx,%edi
f01020ce:	77 12                	ja     f01020e2 <mem_init+0x102c>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01020d0:	50                   	push   %eax
f01020d1:	68 c8 4f 10 f0       	push   $0xf0104fc8
f01020d6:	6a 56                	push   $0x56
f01020d8:	68 ca 4c 10 f0       	push   $0xf0104cca
f01020dd:	e8 be df ff ff       	call   f01000a0 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01020e2:	83 ec 04             	sub    $0x4,%esp
f01020e5:	68 00 10 00 00       	push   $0x1000
f01020ea:	68 ff 00 00 00       	push   $0xff
f01020ef:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01020f4:	50                   	push   %eax
f01020f5:	e8 3c 22 00 00       	call   f0104336 <memset>
	page_free(pp0);
f01020fa:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01020fd:	89 3c 24             	mov    %edi,(%esp)
f0102100:	e8 e0 ec ff ff       	call   f0100de5 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102105:	83 c4 0c             	add    $0xc,%esp
f0102108:	6a 01                	push   $0x1
f010210a:	6a 00                	push   $0x0
f010210c:	ff 35 48 5c 17 f0    	pushl  0xf0175c48
f0102112:	e8 4b ed ff ff       	call   f0100e62 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102117:	89 fa                	mov    %edi,%edx
f0102119:	2b 15 4c 5c 17 f0    	sub    0xf0175c4c,%edx
f010211f:	c1 fa 03             	sar    $0x3,%edx
f0102122:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102125:	89 d0                	mov    %edx,%eax
f0102127:	c1 e8 0c             	shr    $0xc,%eax
f010212a:	83 c4 10             	add    $0x10,%esp
f010212d:	3b 05 44 5c 17 f0    	cmp    0xf0175c44,%eax
f0102133:	72 12                	jb     f0102147 <mem_init+0x1091>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102135:	52                   	push   %edx
f0102136:	68 c8 4f 10 f0       	push   $0xf0104fc8
f010213b:	6a 56                	push   $0x56
f010213d:	68 ca 4c 10 f0       	push   $0xf0104cca
f0102142:	e8 59 df ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f0102147:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f010214d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102150:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102156:	f6 00 01             	testb  $0x1,(%eax)
f0102159:	74 19                	je     f0102174 <mem_init+0x10be>
f010215b:	68 65 4f 10 f0       	push   $0xf0104f65
f0102160:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0102165:	68 ee 03 00 00       	push   $0x3ee
f010216a:	68 be 4c 10 f0       	push   $0xf0104cbe
f010216f:	e8 2c df ff ff       	call   f01000a0 <_panic>
f0102174:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102177:	39 c2                	cmp    %eax,%edx
f0102179:	75 db                	jne    f0102156 <mem_init+0x10a0>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f010217b:	a1 48 5c 17 f0       	mov    0xf0175c48,%eax
f0102180:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102186:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102189:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f010218f:	8b 7d d0             	mov    -0x30(%ebp),%edi
f0102192:	89 3d 80 4f 17 f0    	mov    %edi,0xf0174f80

	// free the pages we took
	page_free(pp0);
f0102198:	83 ec 0c             	sub    $0xc,%esp
f010219b:	50                   	push   %eax
f010219c:	e8 44 ec ff ff       	call   f0100de5 <page_free>
	page_free(pp1);
f01021a1:	89 1c 24             	mov    %ebx,(%esp)
f01021a4:	e8 3c ec ff ff       	call   f0100de5 <page_free>
	page_free(pp2);
f01021a9:	89 34 24             	mov    %esi,(%esp)
f01021ac:	e8 34 ec ff ff       	call   f0100de5 <page_free>

	cprintf("check_page() succeeded!\n");
f01021b1:	c7 04 24 7c 4f 10 f0 	movl   $0xf0104f7c,(%esp)
f01021b8:	e8 08 0e 00 00       	call   f0102fc5 <cprintf>
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	//这里将内核页表映射到用户只读的线性地址UPAGES处，大小为页表总大小
	boot_map_region(kern_pgdir, UPAGES, PageInfo_Size, PADDR(pages), (PTE_U|PTE_P));
f01021bd:	a1 4c 5c 17 f0       	mov    0xf0175c4c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01021c2:	83 c4 10             	add    $0x10,%esp
f01021c5:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01021ca:	77 15                	ja     f01021e1 <mem_init+0x112b>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01021cc:	50                   	push   %eax
f01021cd:	68 0c 51 10 f0       	push   $0xf010510c
f01021d2:	68 c8 00 00 00       	push   $0xc8
f01021d7:	68 be 4c 10 f0       	push   $0xf0104cbe
f01021dc:	e8 bf de ff ff       	call   f01000a0 <_panic>
f01021e1:	83 ec 08             	sub    $0x8,%esp
f01021e4:	6a 05                	push   $0x5
f01021e6:	05 00 00 00 10       	add    $0x10000000,%eax
f01021eb:	50                   	push   %eax
f01021ec:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f01021ef:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01021f4:	a1 48 5c 17 f0       	mov    0xf0175c48,%eax
f01021f9:	e8 2c ed ff ff       	call   f0100f2a <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01021fe:	83 c4 10             	add    $0x10,%esp
f0102201:	b8 00 10 11 f0       	mov    $0xf0111000,%eax
f0102206:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010220b:	77 15                	ja     f0102222 <mem_init+0x116c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010220d:	50                   	push   %eax
f010220e:	68 0c 51 10 f0       	push   $0xf010510c
f0102213:	68 de 00 00 00       	push   $0xde
f0102218:	68 be 4c 10 f0       	push   $0xf0104cbe
f010221d:	e8 7e de ff ff       	call   f01000a0 <_panic>
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	//映射的范围：* [KSTACKTOP-KSTKSIZE, KSTACKTOP)
	//内核页表映射到栈地址，内核栈从虚拟地址KSTACKTOP开始向下增长
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), (PTE_W|PTE_P));
f0102222:	83 ec 08             	sub    $0x8,%esp
f0102225:	6a 03                	push   $0x3
f0102227:	68 00 10 11 00       	push   $0x111000
f010222c:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102231:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102236:	a1 48 5c 17 f0       	mov    0xf0175c48,%eax
f010223b:	e8 ea ec ff ff       	call   f0100f2a <boot_map_region>
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	//将KERNBASE所有的物理内存从虚拟地址[KERNBASE, 2^32)映射到物理地址[0, 2^32 - KERNBASE)
	boot_map_region(kern_pgdir, KERNBASE, (0xffffffff-KERNBASE), 0, (PTE_W|PTE_P));
f0102240:	83 c4 08             	add    $0x8,%esp
f0102243:	6a 03                	push   $0x3
f0102245:	6a 00                	push   $0x0
f0102247:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f010224c:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102251:	a1 48 5c 17 f0       	mov    0xf0175c48,%eax
f0102256:	e8 cf ec ff ff       	call   f0100f2a <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f010225b:	8b 1d 48 5c 17 f0    	mov    0xf0175c48,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102261:	a1 44 5c 17 f0       	mov    0xf0175c44,%eax
f0102266:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102269:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102270:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102275:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102278:	8b 3d 4c 5c 17 f0    	mov    0xf0175c4c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010227e:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0102281:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102284:	be 00 00 00 00       	mov    $0x0,%esi
f0102289:	eb 55                	jmp    f01022e0 <mem_init+0x122a>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010228b:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
f0102291:	89 d8                	mov    %ebx,%eax
f0102293:	e8 cd e6 ff ff       	call   f0100965 <check_va2pa>
f0102298:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f010229f:	77 15                	ja     f01022b6 <mem_init+0x1200>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01022a1:	57                   	push   %edi
f01022a2:	68 0c 51 10 f0       	push   $0xf010510c
f01022a7:	68 2b 03 00 00       	push   $0x32b
f01022ac:	68 be 4c 10 f0       	push   $0xf0104cbe
f01022b1:	e8 ea dd ff ff       	call   f01000a0 <_panic>
f01022b6:	8d 94 37 00 00 00 10 	lea    0x10000000(%edi,%esi,1),%edx
f01022bd:	39 d0                	cmp    %edx,%eax
f01022bf:	74 19                	je     f01022da <mem_init+0x1224>
f01022c1:	68 88 55 10 f0       	push   $0xf0105588
f01022c6:	68 e4 4c 10 f0       	push   $0xf0104ce4
f01022cb:	68 2b 03 00 00       	push   $0x32b
f01022d0:	68 be 4c 10 f0       	push   $0xf0104cbe
f01022d5:	e8 c6 dd ff ff       	call   f01000a0 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01022da:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01022e0:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f01022e3:	77 a6                	ja     f010228b <mem_init+0x11d5>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f01022e5:	8b 3d 8c 4f 17 f0    	mov    0xf0174f8c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01022eb:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01022ee:	be 00 00 c0 ee       	mov    $0xeec00000,%esi
f01022f3:	89 f2                	mov    %esi,%edx
f01022f5:	89 d8                	mov    %ebx,%eax
f01022f7:	e8 69 e6 ff ff       	call   f0100965 <check_va2pa>
f01022fc:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f0102303:	77 15                	ja     f010231a <mem_init+0x1264>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102305:	57                   	push   %edi
f0102306:	68 0c 51 10 f0       	push   $0xf010510c
f010230b:	68 30 03 00 00       	push   $0x330
f0102310:	68 be 4c 10 f0       	push   $0xf0104cbe
f0102315:	e8 86 dd ff ff       	call   f01000a0 <_panic>
f010231a:	8d 94 37 00 00 40 21 	lea    0x21400000(%edi,%esi,1),%edx
f0102321:	39 c2                	cmp    %eax,%edx
f0102323:	74 19                	je     f010233e <mem_init+0x1288>
f0102325:	68 bc 55 10 f0       	push   $0xf01055bc
f010232a:	68 e4 4c 10 f0       	push   $0xf0104ce4
f010232f:	68 30 03 00 00       	push   $0x330
f0102334:	68 be 4c 10 f0       	push   $0xf0104cbe
f0102339:	e8 62 dd ff ff       	call   f01000a0 <_panic>
f010233e:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102344:	81 fe 00 80 c1 ee    	cmp    $0xeec18000,%esi
f010234a:	75 a7                	jne    f01022f3 <mem_init+0x123d>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010234c:	8b 7d cc             	mov    -0x34(%ebp),%edi
f010234f:	c1 e7 0c             	shl    $0xc,%edi
f0102352:	be 00 00 00 00       	mov    $0x0,%esi
f0102357:	eb 30                	jmp    f0102389 <mem_init+0x12d3>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102359:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
f010235f:	89 d8                	mov    %ebx,%eax
f0102361:	e8 ff e5 ff ff       	call   f0100965 <check_va2pa>
f0102366:	39 c6                	cmp    %eax,%esi
f0102368:	74 19                	je     f0102383 <mem_init+0x12cd>
f010236a:	68 f0 55 10 f0       	push   $0xf01055f0
f010236f:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0102374:	68 34 03 00 00       	push   $0x334
f0102379:	68 be 4c 10 f0       	push   $0xf0104cbe
f010237e:	e8 1d dd ff ff       	call   f01000a0 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102383:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102389:	39 fe                	cmp    %edi,%esi
f010238b:	72 cc                	jb     f0102359 <mem_init+0x12a3>
f010238d:	be 00 80 ff ef       	mov    $0xefff8000,%esi
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102392:	89 f2                	mov    %esi,%edx
f0102394:	89 d8                	mov    %ebx,%eax
f0102396:	e8 ca e5 ff ff       	call   f0100965 <check_va2pa>
f010239b:	8d 96 00 90 11 10    	lea    0x10119000(%esi),%edx
f01023a1:	39 c2                	cmp    %eax,%edx
f01023a3:	74 19                	je     f01023be <mem_init+0x1308>
f01023a5:	68 18 56 10 f0       	push   $0xf0105618
f01023aa:	68 e4 4c 10 f0       	push   $0xf0104ce4
f01023af:	68 38 03 00 00       	push   $0x338
f01023b4:	68 be 4c 10 f0       	push   $0xf0104cbe
f01023b9:	e8 e2 dc ff ff       	call   f01000a0 <_panic>
f01023be:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01023c4:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f01023ca:	75 c6                	jne    f0102392 <mem_init+0x12dc>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01023cc:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f01023d1:	89 d8                	mov    %ebx,%eax
f01023d3:	e8 8d e5 ff ff       	call   f0100965 <check_va2pa>
f01023d8:	83 f8 ff             	cmp    $0xffffffff,%eax
f01023db:	74 51                	je     f010242e <mem_init+0x1378>
f01023dd:	68 60 56 10 f0       	push   $0xf0105660
f01023e2:	68 e4 4c 10 f0       	push   $0xf0104ce4
f01023e7:	68 39 03 00 00       	push   $0x339
f01023ec:	68 be 4c 10 f0       	push   $0xf0104cbe
f01023f1:	e8 aa dc ff ff       	call   f01000a0 <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f01023f6:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f01023fb:	72 36                	jb     f0102433 <mem_init+0x137d>
f01023fd:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102402:	76 07                	jbe    f010240b <mem_init+0x1355>
f0102404:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102409:	75 28                	jne    f0102433 <mem_init+0x137d>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
f010240b:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f010240f:	0f 85 83 00 00 00    	jne    f0102498 <mem_init+0x13e2>
f0102415:	68 95 4f 10 f0       	push   $0xf0104f95
f010241a:	68 e4 4c 10 f0       	push   $0xf0104ce4
f010241f:	68 42 03 00 00       	push   $0x342
f0102424:	68 be 4c 10 f0       	push   $0xf0104cbe
f0102429:	e8 72 dc ff ff       	call   f01000a0 <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f010242e:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102433:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102438:	76 3f                	jbe    f0102479 <mem_init+0x13c3>
				assert(pgdir[i] & PTE_P);
f010243a:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f010243d:	f6 c2 01             	test   $0x1,%dl
f0102440:	75 19                	jne    f010245b <mem_init+0x13a5>
f0102442:	68 95 4f 10 f0       	push   $0xf0104f95
f0102447:	68 e4 4c 10 f0       	push   $0xf0104ce4
f010244c:	68 46 03 00 00       	push   $0x346
f0102451:	68 be 4c 10 f0       	push   $0xf0104cbe
f0102456:	e8 45 dc ff ff       	call   f01000a0 <_panic>
				assert(pgdir[i] & PTE_W);
f010245b:	f6 c2 02             	test   $0x2,%dl
f010245e:	75 38                	jne    f0102498 <mem_init+0x13e2>
f0102460:	68 a6 4f 10 f0       	push   $0xf0104fa6
f0102465:	68 e4 4c 10 f0       	push   $0xf0104ce4
f010246a:	68 47 03 00 00       	push   $0x347
f010246f:	68 be 4c 10 f0       	push   $0xf0104cbe
f0102474:	e8 27 dc ff ff       	call   f01000a0 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102479:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f010247d:	74 19                	je     f0102498 <mem_init+0x13e2>
f010247f:	68 b7 4f 10 f0       	push   $0xf0104fb7
f0102484:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0102489:	68 49 03 00 00       	push   $0x349
f010248e:	68 be 4c 10 f0       	push   $0xf0104cbe
f0102493:	e8 08 dc ff ff       	call   f01000a0 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102498:	83 c0 01             	add    $0x1,%eax
f010249b:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f01024a0:	0f 86 50 ff ff ff    	jbe    f01023f6 <mem_init+0x1340>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f01024a6:	83 ec 0c             	sub    $0xc,%esp
f01024a9:	68 90 56 10 f0       	push   $0xf0105690
f01024ae:	e8 12 0b 00 00       	call   f0102fc5 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01024b3:	a1 48 5c 17 f0       	mov    0xf0175c48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01024b8:	83 c4 10             	add    $0x10,%esp
f01024bb:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01024c0:	77 15                	ja     f01024d7 <mem_init+0x1421>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01024c2:	50                   	push   %eax
f01024c3:	68 0c 51 10 f0       	push   $0xf010510c
f01024c8:	68 f3 00 00 00       	push   $0xf3
f01024cd:	68 be 4c 10 f0       	push   $0xf0104cbe
f01024d2:	e8 c9 db ff ff       	call   f01000a0 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01024d7:	05 00 00 00 10       	add    $0x10000000,%eax
f01024dc:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01024df:	b8 00 00 00 00       	mov    $0x0,%eax
f01024e4:	e8 e0 e4 ff ff       	call   f01009c9 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f01024e9:	0f 20 c0             	mov    %cr0,%eax
f01024ec:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f01024ef:	0d 23 00 05 80       	or     $0x80050023,%eax
f01024f4:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01024f7:	83 ec 0c             	sub    $0xc,%esp
f01024fa:	6a 00                	push   $0x0
f01024fc:	e8 74 e8 ff ff       	call   f0100d75 <page_alloc>
f0102501:	89 c3                	mov    %eax,%ebx
f0102503:	83 c4 10             	add    $0x10,%esp
f0102506:	85 c0                	test   %eax,%eax
f0102508:	75 19                	jne    f0102523 <mem_init+0x146d>
f010250a:	68 b3 4d 10 f0       	push   $0xf0104db3
f010250f:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0102514:	68 09 04 00 00       	push   $0x409
f0102519:	68 be 4c 10 f0       	push   $0xf0104cbe
f010251e:	e8 7d db ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0102523:	83 ec 0c             	sub    $0xc,%esp
f0102526:	6a 00                	push   $0x0
f0102528:	e8 48 e8 ff ff       	call   f0100d75 <page_alloc>
f010252d:	89 c7                	mov    %eax,%edi
f010252f:	83 c4 10             	add    $0x10,%esp
f0102532:	85 c0                	test   %eax,%eax
f0102534:	75 19                	jne    f010254f <mem_init+0x1499>
f0102536:	68 c9 4d 10 f0       	push   $0xf0104dc9
f010253b:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0102540:	68 0a 04 00 00       	push   $0x40a
f0102545:	68 be 4c 10 f0       	push   $0xf0104cbe
f010254a:	e8 51 db ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f010254f:	83 ec 0c             	sub    $0xc,%esp
f0102552:	6a 00                	push   $0x0
f0102554:	e8 1c e8 ff ff       	call   f0100d75 <page_alloc>
f0102559:	89 c6                	mov    %eax,%esi
f010255b:	83 c4 10             	add    $0x10,%esp
f010255e:	85 c0                	test   %eax,%eax
f0102560:	75 19                	jne    f010257b <mem_init+0x14c5>
f0102562:	68 df 4d 10 f0       	push   $0xf0104ddf
f0102567:	68 e4 4c 10 f0       	push   $0xf0104ce4
f010256c:	68 0b 04 00 00       	push   $0x40b
f0102571:	68 be 4c 10 f0       	push   $0xf0104cbe
f0102576:	e8 25 db ff ff       	call   f01000a0 <_panic>
	page_free(pp0);
f010257b:	83 ec 0c             	sub    $0xc,%esp
f010257e:	53                   	push   %ebx
f010257f:	e8 61 e8 ff ff       	call   f0100de5 <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102584:	89 f8                	mov    %edi,%eax
f0102586:	2b 05 4c 5c 17 f0    	sub    0xf0175c4c,%eax
f010258c:	c1 f8 03             	sar    $0x3,%eax
f010258f:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102592:	89 c2                	mov    %eax,%edx
f0102594:	c1 ea 0c             	shr    $0xc,%edx
f0102597:	83 c4 10             	add    $0x10,%esp
f010259a:	3b 15 44 5c 17 f0    	cmp    0xf0175c44,%edx
f01025a0:	72 12                	jb     f01025b4 <mem_init+0x14fe>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01025a2:	50                   	push   %eax
f01025a3:	68 c8 4f 10 f0       	push   $0xf0104fc8
f01025a8:	6a 56                	push   $0x56
f01025aa:	68 ca 4c 10 f0       	push   $0xf0104cca
f01025af:	e8 ec da ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f01025b4:	83 ec 04             	sub    $0x4,%esp
f01025b7:	68 00 10 00 00       	push   $0x1000
f01025bc:	6a 01                	push   $0x1
f01025be:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01025c3:	50                   	push   %eax
f01025c4:	e8 6d 1d 00 00       	call   f0104336 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01025c9:	89 f0                	mov    %esi,%eax
f01025cb:	2b 05 4c 5c 17 f0    	sub    0xf0175c4c,%eax
f01025d1:	c1 f8 03             	sar    $0x3,%eax
f01025d4:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01025d7:	89 c2                	mov    %eax,%edx
f01025d9:	c1 ea 0c             	shr    $0xc,%edx
f01025dc:	83 c4 10             	add    $0x10,%esp
f01025df:	3b 15 44 5c 17 f0    	cmp    0xf0175c44,%edx
f01025e5:	72 12                	jb     f01025f9 <mem_init+0x1543>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01025e7:	50                   	push   %eax
f01025e8:	68 c8 4f 10 f0       	push   $0xf0104fc8
f01025ed:	6a 56                	push   $0x56
f01025ef:	68 ca 4c 10 f0       	push   $0xf0104cca
f01025f4:	e8 a7 da ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f01025f9:	83 ec 04             	sub    $0x4,%esp
f01025fc:	68 00 10 00 00       	push   $0x1000
f0102601:	6a 02                	push   $0x2
f0102603:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102608:	50                   	push   %eax
f0102609:	e8 28 1d 00 00       	call   f0104336 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f010260e:	6a 02                	push   $0x2
f0102610:	68 00 10 00 00       	push   $0x1000
f0102615:	57                   	push   %edi
f0102616:	ff 35 48 5c 17 f0    	pushl  0xf0175c48
f010261c:	e8 fc e9 ff ff       	call   f010101d <page_insert>
	assert(pp1->pp_ref == 1);
f0102621:	83 c4 20             	add    $0x20,%esp
f0102624:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102629:	74 19                	je     f0102644 <mem_init+0x158e>
f010262b:	68 b0 4e 10 f0       	push   $0xf0104eb0
f0102630:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0102635:	68 10 04 00 00       	push   $0x410
f010263a:	68 be 4c 10 f0       	push   $0xf0104cbe
f010263f:	e8 5c da ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102644:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f010264b:	01 01 01 
f010264e:	74 19                	je     f0102669 <mem_init+0x15b3>
f0102650:	68 b0 56 10 f0       	push   $0xf01056b0
f0102655:	68 e4 4c 10 f0       	push   $0xf0104ce4
f010265a:	68 11 04 00 00       	push   $0x411
f010265f:	68 be 4c 10 f0       	push   $0xf0104cbe
f0102664:	e8 37 da ff ff       	call   f01000a0 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102669:	6a 02                	push   $0x2
f010266b:	68 00 10 00 00       	push   $0x1000
f0102670:	56                   	push   %esi
f0102671:	ff 35 48 5c 17 f0    	pushl  0xf0175c48
f0102677:	e8 a1 e9 ff ff       	call   f010101d <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f010267c:	83 c4 10             	add    $0x10,%esp
f010267f:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102686:	02 02 02 
f0102689:	74 19                	je     f01026a4 <mem_init+0x15ee>
f010268b:	68 d4 56 10 f0       	push   $0xf01056d4
f0102690:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0102695:	68 13 04 00 00       	push   $0x413
f010269a:	68 be 4c 10 f0       	push   $0xf0104cbe
f010269f:	e8 fc d9 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f01026a4:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01026a9:	74 19                	je     f01026c4 <mem_init+0x160e>
f01026ab:	68 d2 4e 10 f0       	push   $0xf0104ed2
f01026b0:	68 e4 4c 10 f0       	push   $0xf0104ce4
f01026b5:	68 14 04 00 00       	push   $0x414
f01026ba:	68 be 4c 10 f0       	push   $0xf0104cbe
f01026bf:	e8 dc d9 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f01026c4:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01026c9:	74 19                	je     f01026e4 <mem_init+0x162e>
f01026cb:	68 3c 4f 10 f0       	push   $0xf0104f3c
f01026d0:	68 e4 4c 10 f0       	push   $0xf0104ce4
f01026d5:	68 15 04 00 00       	push   $0x415
f01026da:	68 be 4c 10 f0       	push   $0xf0104cbe
f01026df:	e8 bc d9 ff ff       	call   f01000a0 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f01026e4:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f01026eb:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01026ee:	89 f0                	mov    %esi,%eax
f01026f0:	2b 05 4c 5c 17 f0    	sub    0xf0175c4c,%eax
f01026f6:	c1 f8 03             	sar    $0x3,%eax
f01026f9:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01026fc:	89 c2                	mov    %eax,%edx
f01026fe:	c1 ea 0c             	shr    $0xc,%edx
f0102701:	3b 15 44 5c 17 f0    	cmp    0xf0175c44,%edx
f0102707:	72 12                	jb     f010271b <mem_init+0x1665>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102709:	50                   	push   %eax
f010270a:	68 c8 4f 10 f0       	push   $0xf0104fc8
f010270f:	6a 56                	push   $0x56
f0102711:	68 ca 4c 10 f0       	push   $0xf0104cca
f0102716:	e8 85 d9 ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f010271b:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102722:	03 03 03 
f0102725:	74 19                	je     f0102740 <mem_init+0x168a>
f0102727:	68 f8 56 10 f0       	push   $0xf01056f8
f010272c:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0102731:	68 17 04 00 00       	push   $0x417
f0102736:	68 be 4c 10 f0       	push   $0xf0104cbe
f010273b:	e8 60 d9 ff ff       	call   f01000a0 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102740:	83 ec 08             	sub    $0x8,%esp
f0102743:	68 00 10 00 00       	push   $0x1000
f0102748:	ff 35 48 5c 17 f0    	pushl  0xf0175c48
f010274e:	e8 8f e8 ff ff       	call   f0100fe2 <page_remove>
	assert(pp2->pp_ref == 0);
f0102753:	83 c4 10             	add    $0x10,%esp
f0102756:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010275b:	74 19                	je     f0102776 <mem_init+0x16c0>
f010275d:	68 0a 4f 10 f0       	push   $0xf0104f0a
f0102762:	68 e4 4c 10 f0       	push   $0xf0104ce4
f0102767:	68 19 04 00 00       	push   $0x419
f010276c:	68 be 4c 10 f0       	push   $0xf0104cbe
f0102771:	e8 2a d9 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102776:	8b 0d 48 5c 17 f0    	mov    0xf0175c48,%ecx
f010277c:	8b 11                	mov    (%ecx),%edx
f010277e:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102784:	89 d8                	mov    %ebx,%eax
f0102786:	2b 05 4c 5c 17 f0    	sub    0xf0175c4c,%eax
f010278c:	c1 f8 03             	sar    $0x3,%eax
f010278f:	c1 e0 0c             	shl    $0xc,%eax
f0102792:	39 c2                	cmp    %eax,%edx
f0102794:	74 19                	je     f01027af <mem_init+0x16f9>
f0102796:	68 08 52 10 f0       	push   $0xf0105208
f010279b:	68 e4 4c 10 f0       	push   $0xf0104ce4
f01027a0:	68 1c 04 00 00       	push   $0x41c
f01027a5:	68 be 4c 10 f0       	push   $0xf0104cbe
f01027aa:	e8 f1 d8 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f01027af:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f01027b5:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01027ba:	74 19                	je     f01027d5 <mem_init+0x171f>
f01027bc:	68 c1 4e 10 f0       	push   $0xf0104ec1
f01027c1:	68 e4 4c 10 f0       	push   $0xf0104ce4
f01027c6:	68 1e 04 00 00       	push   $0x41e
f01027cb:	68 be 4c 10 f0       	push   $0xf0104cbe
f01027d0:	e8 cb d8 ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f01027d5:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f01027db:	83 ec 0c             	sub    $0xc,%esp
f01027de:	53                   	push   %ebx
f01027df:	e8 01 e6 ff ff       	call   f0100de5 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f01027e4:	c7 04 24 24 57 10 f0 	movl   $0xf0105724,(%esp)
f01027eb:	e8 d5 07 00 00       	call   f0102fc5 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f01027f0:	83 c4 10             	add    $0x10,%esp
f01027f3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01027f6:	5b                   	pop    %ebx
f01027f7:	5e                   	pop    %esi
f01027f8:	5f                   	pop    %edi
f01027f9:	5d                   	pop    %ebp
f01027fa:	c3                   	ret    

f01027fb <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01027fb:	55                   	push   %ebp
f01027fc:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01027fe:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102801:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0102804:	5d                   	pop    %ebp
f0102805:	c3                   	ret    

f0102806 <user_mem_check>:
// and -E_FAULT otherwise.
//
//内核检查一个指针指向的是否是用户空间
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0102806:	55                   	push   %ebp
f0102807:	89 e5                	mov    %esp,%ebp
f0102809:	57                   	push   %edi
f010280a:	56                   	push   %esi
f010280b:	53                   	push   %ebx
f010280c:	83 ec 1c             	sub    $0x1c,%esp
f010280f:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	uintptr_t begin = (uintptr_t)ROUNDDOWN(va, PGSIZE);
f0102812:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102815:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uintptr_t end = (uintptr_t)ROUNDUP(va + len, PGSIZE);
f010281b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010281e:	03 45 10             	add    0x10(%ebp),%eax
f0102821:	05 ff 0f 00 00       	add    $0xfff,%eax
f0102826:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010282b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(uintptr_t i = begin;i < end;i += PGSIZE)
	{
		pte_t *pte = pgdir_walk(env->env_pgdir, (void*)i, 0);//找到虚拟地址对应的物理页
		if(pte == NULL||i >= ULIM||(*pte & (perm|PTE_P))!=(perm|PTE_P))
f010282e:	8b 75 14             	mov    0x14(%ebp),%esi
f0102831:	83 ce 01             	or     $0x1,%esi
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
	// LAB 3: Your code here.
	uintptr_t begin = (uintptr_t)ROUNDDOWN(va, PGSIZE);
	uintptr_t end = (uintptr_t)ROUNDUP(va + len, PGSIZE);
	for(uintptr_t i = begin;i < end;i += PGSIZE)
f0102834:	eb 4c                	jmp    f0102882 <user_mem_check+0x7c>
	{
		pte_t *pte = pgdir_walk(env->env_pgdir, (void*)i, 0);//找到虚拟地址对应的物理页
f0102836:	83 ec 04             	sub    $0x4,%esp
f0102839:	6a 00                	push   $0x0
f010283b:	53                   	push   %ebx
f010283c:	ff 77 5c             	pushl  0x5c(%edi)
f010283f:	e8 1e e6 ff ff       	call   f0100e62 <pgdir_walk>
		if(pte == NULL||i >= ULIM||(*pte & (perm|PTE_P))!=(perm|PTE_P))
f0102844:	83 c4 10             	add    $0x10,%esp
f0102847:	85 c0                	test   %eax,%eax
f0102849:	74 10                	je     f010285b <user_mem_check+0x55>
f010284b:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0102851:	77 08                	ja     f010285b <user_mem_check+0x55>
f0102853:	89 f2                	mov    %esi,%edx
f0102855:	23 10                	and    (%eax),%edx
f0102857:	39 d6                	cmp    %edx,%esi
f0102859:	74 21                	je     f010287c <user_mem_check+0x76>
		{ //如果不存在该页，或者虚拟地址不在用户空间，或者没有权限操作
			//将该虚拟地址设为无效
			if(i < (uintptr_t)va)
f010285b:	3b 5d 0c             	cmp    0xc(%ebp),%ebx
f010285e:	73 0f                	jae    f010286f <user_mem_check+0x69>
			{
				user_mem_check_addr = (uintptr_t)va;
f0102860:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102863:	a3 7c 4f 17 f0       	mov    %eax,0xf0174f7c
			}
			else
			{
				user_mem_check_addr = (uintptr_t)i;
			}
			return -E_FAULT;
f0102868:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f010286d:	eb 1d                	jmp    f010288c <user_mem_check+0x86>
			{
				user_mem_check_addr = (uintptr_t)va;
			}
			else
			{
				user_mem_check_addr = (uintptr_t)i;
f010286f:	89 1d 7c 4f 17 f0    	mov    %ebx,0xf0174f7c
			}
			return -E_FAULT;
f0102875:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f010287a:	eb 10                	jmp    f010288c <user_mem_check+0x86>
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
	// LAB 3: Your code here.
	uintptr_t begin = (uintptr_t)ROUNDDOWN(va, PGSIZE);
	uintptr_t end = (uintptr_t)ROUNDUP(va + len, PGSIZE);
	for(uintptr_t i = begin;i < end;i += PGSIZE)
f010287c:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102882:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0102885:	72 af                	jb     f0102836 <user_mem_check+0x30>
				user_mem_check_addr = (uintptr_t)i;
			}
			return -E_FAULT;
		}
	}
	return 0;
f0102887:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010288c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010288f:	5b                   	pop    %ebx
f0102890:	5e                   	pop    %esi
f0102891:	5f                   	pop    %edi
f0102892:	5d                   	pop    %ebp
f0102893:	c3                   	ret    

f0102894 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102894:	55                   	push   %ebp
f0102895:	89 e5                	mov    %esp,%ebp
f0102897:	53                   	push   %ebx
f0102898:	83 ec 04             	sub    $0x4,%esp
f010289b:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f010289e:	8b 45 14             	mov    0x14(%ebp),%eax
f01028a1:	83 c8 04             	or     $0x4,%eax
f01028a4:	50                   	push   %eax
f01028a5:	ff 75 10             	pushl  0x10(%ebp)
f01028a8:	ff 75 0c             	pushl  0xc(%ebp)
f01028ab:	53                   	push   %ebx
f01028ac:	e8 55 ff ff ff       	call   f0102806 <user_mem_check>
f01028b1:	83 c4 10             	add    $0x10,%esp
f01028b4:	85 c0                	test   %eax,%eax
f01028b6:	79 21                	jns    f01028d9 <user_mem_assert+0x45>
		cprintf("[%08x] user_mem_check assertion failure for "
f01028b8:	83 ec 04             	sub    $0x4,%esp
f01028bb:	ff 35 7c 4f 17 f0    	pushl  0xf0174f7c
f01028c1:	ff 73 48             	pushl  0x48(%ebx)
f01028c4:	68 50 57 10 f0       	push   $0xf0105750
f01028c9:	e8 f7 06 00 00       	call   f0102fc5 <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f01028ce:	89 1c 24             	mov    %ebx,(%esp)
f01028d1:	e8 d6 05 00 00       	call   f0102eac <env_destroy>
f01028d6:	83 c4 10             	add    $0x10,%esp
	}
}
f01028d9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01028dc:	c9                   	leave  
f01028dd:	c3                   	ret    

f01028de <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
// 为进程分配len字节的物理内存，将其映射到进程空间的虚拟地址va
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f01028de:	55                   	push   %ebp
f01028df:	89 e5                	mov    %esp,%ebp
f01028e1:	57                   	push   %edi
f01028e2:	56                   	push   %esi
f01028e3:	53                   	push   %ebx
f01028e4:	83 ec 0c             	sub    $0xc,%esp
f01028e7:	89 c7                	mov    %eax,%edi
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	int flag;
	void *begin = ROUNDDOWN(va, PGSIZE);
f01028e9:	89 d3                	mov    %edx,%ebx
f01028eb:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	void *end = ROUNDUP(va + len, PGSIZE);
f01028f1:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f01028f8:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	//分配从线性地址begin到end之间的物理页
	for(begin; begin < end; begin += PGSIZE)
f01028fe:	eb 58                	jmp    f0102958 <region_alloc+0x7a>
	{
		struct PageInfo *NewPage = page_alloc(0);
f0102900:	83 ec 0c             	sub    $0xc,%esp
f0102903:	6a 00                	push   $0x0
f0102905:	e8 6b e4 ff ff       	call   f0100d75 <page_alloc>
		if(NewPage == NULL)
f010290a:	83 c4 10             	add    $0x10,%esp
f010290d:	85 c0                	test   %eax,%eax
f010290f:	75 17                	jne    f0102928 <region_alloc+0x4a>
		{ //如果无法分配物理页，panic
			panic("can't allocate a new page");
f0102911:	83 ec 04             	sub    $0x4,%esp
f0102914:	68 85 57 10 f0       	push   $0xf0105785
f0102919:	68 28 01 00 00       	push   $0x128
f010291e:	68 9f 57 10 f0       	push   $0xf010579f
f0102923:	e8 78 d7 ff ff       	call   f01000a0 <_panic>
		}
		//建立线性地址bengin到物理页NewPage之间的映射，插入到进程页目录中
		flag = page_insert(e->env_pgdir, NewPage, begin, PTE_W|PTE_U);
f0102928:	6a 06                	push   $0x6
f010292a:	53                   	push   %ebx
f010292b:	50                   	push   %eax
f010292c:	ff 77 5c             	pushl  0x5c(%edi)
f010292f:	e8 e9 e6 ff ff       	call   f010101d <page_insert>
		if(flag != 0)
f0102934:	83 c4 10             	add    $0x10,%esp
f0102937:	85 c0                	test   %eax,%eax
f0102939:	74 17                	je     f0102952 <region_alloc+0x74>
		{ //如果无法建立映射，panic
			panic("map creation failed");
f010293b:	83 ec 04             	sub    $0x4,%esp
f010293e:	68 aa 57 10 f0       	push   $0xf01057aa
f0102943:	68 2e 01 00 00       	push   $0x12e
f0102948:	68 9f 57 10 f0       	push   $0xf010579f
f010294d:	e8 4e d7 ff ff       	call   f01000a0 <_panic>
	//   (Watch out for corner-cases!)
	int flag;
	void *begin = ROUNDDOWN(va, PGSIZE);
	void *end = ROUNDUP(va + len, PGSIZE);
	//分配从线性地址begin到end之间的物理页
	for(begin; begin < end; begin += PGSIZE)
f0102952:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102958:	39 f3                	cmp    %esi,%ebx
f010295a:	72 a4                	jb     f0102900 <region_alloc+0x22>
		if(flag != 0)
		{ //如果无法建立映射，panic
			panic("map creation failed");
		}
	}
}
f010295c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010295f:	5b                   	pop    %ebx
f0102960:	5e                   	pop    %esi
f0102961:	5f                   	pop    %edi
f0102962:	5d                   	pop    %ebp
f0102963:	c3                   	ret    

f0102964 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0102964:	55                   	push   %ebp
f0102965:	89 e5                	mov    %esp,%ebp
f0102967:	8b 55 08             	mov    0x8(%ebp),%edx
f010296a:	8b 4d 10             	mov    0x10(%ebp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f010296d:	85 d2                	test   %edx,%edx
f010296f:	75 11                	jne    f0102982 <envid2env+0x1e>
		*env_store = curenv;
f0102971:	a1 88 4f 17 f0       	mov    0xf0174f88,%eax
f0102976:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102979:	89 01                	mov    %eax,(%ecx)
		return 0;
f010297b:	b8 00 00 00 00       	mov    $0x0,%eax
f0102980:	eb 5e                	jmp    f01029e0 <envid2env+0x7c>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0102982:	89 d0                	mov    %edx,%eax
f0102984:	25 ff 03 00 00       	and    $0x3ff,%eax
f0102989:	8d 04 40             	lea    (%eax,%eax,2),%eax
f010298c:	c1 e0 05             	shl    $0x5,%eax
f010298f:	03 05 8c 4f 17 f0    	add    0xf0174f8c,%eax
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0102995:	83 78 54 00          	cmpl   $0x0,0x54(%eax)
f0102999:	74 05                	je     f01029a0 <envid2env+0x3c>
f010299b:	3b 50 48             	cmp    0x48(%eax),%edx
f010299e:	74 10                	je     f01029b0 <envid2env+0x4c>
		*env_store = 0;
f01029a0:	8b 45 0c             	mov    0xc(%ebp),%eax
f01029a3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01029a9:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01029ae:	eb 30                	jmp    f01029e0 <envid2env+0x7c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f01029b0:	84 c9                	test   %cl,%cl
f01029b2:	74 22                	je     f01029d6 <envid2env+0x72>
f01029b4:	8b 15 88 4f 17 f0    	mov    0xf0174f88,%edx
f01029ba:	39 d0                	cmp    %edx,%eax
f01029bc:	74 18                	je     f01029d6 <envid2env+0x72>
f01029be:	8b 4a 48             	mov    0x48(%edx),%ecx
f01029c1:	39 48 4c             	cmp    %ecx,0x4c(%eax)
f01029c4:	74 10                	je     f01029d6 <envid2env+0x72>
		*env_store = 0;
f01029c6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01029c9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01029cf:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01029d4:	eb 0a                	jmp    f01029e0 <envid2env+0x7c>
	}

	*env_store = e;
f01029d6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01029d9:	89 01                	mov    %eax,(%ecx)
	return 0;
f01029db:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01029e0:	5d                   	pop    %ebp
f01029e1:	c3                   	ret    

f01029e2 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f01029e2:	55                   	push   %ebp
f01029e3:	89 e5                	mov    %esp,%ebp
}

static __inline void
lgdt(void *p)
{
	__asm __volatile("lgdt (%0)" : : "r" (p));
f01029e5:	b8 00 b3 11 f0       	mov    $0xf011b300,%eax
f01029ea:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f01029ed:	b8 23 00 00 00       	mov    $0x23,%eax
f01029f2:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f01029f4:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f01029f6:	b8 10 00 00 00       	mov    $0x10,%eax
f01029fb:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f01029fd:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f01029ff:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f0102a01:	ea 08 2a 10 f0 08 00 	ljmp   $0x8,$0xf0102a08
}

static __inline void
lldt(uint16_t sel)
{
	__asm __volatile("lldt %0" : : "r" (sel));
f0102a08:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a0d:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0102a10:	5d                   	pop    %ebp
f0102a11:	c3                   	ret    

f0102a12 <env_init>:
//
//将所有envs数组中的进程设置为空闲，id设为0
//然后插入到env_free_list中
void
env_init(void)
{
f0102a12:	55                   	push   %ebp
f0102a13:	89 e5                	mov    %esp,%ebp
f0102a15:	56                   	push   %esi
f0102a16:	53                   	push   %ebx
	env_free_list = NULL; //最开始env_free_list为空
	for(int i = NENV - 1;i >= 0;i--)
	{
		//为了保证调用env_alloc()是按照0-NENV的顺序
		//将ENV从最后一个Env开始依次插入到env_free_list中
		envs[i].env_id = 0;  //id设为0
f0102a17:	8b 35 8c 4f 17 f0    	mov    0xf0174f8c,%esi
f0102a1d:	8d 86 a0 7f 01 00    	lea    0x17fa0(%esi),%eax
f0102a23:	8d 5e a0             	lea    -0x60(%esi),%ebx
f0102a26:	ba 00 00 00 00       	mov    $0x0,%edx
f0102a2b:	89 c1                	mov    %eax,%ecx
f0102a2d:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_link = env_free_list; //下一个空闲Env在env_free_list中寻找
f0102a34:	89 50 44             	mov    %edx,0x44(%eax)
		envs[i].env_status = ENV_FREE; //进程状态为空闲
f0102a37:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
f0102a3e:	83 e8 60             	sub    $0x60,%eax
		env_free_list = &envs[i]; //将当前Env插入env_free_list
f0102a41:	89 ca                	mov    %ecx,%edx
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.
	env_free_list = NULL; //最开始env_free_list为空
	for(int i = NENV - 1;i >= 0;i--)
f0102a43:	39 d8                	cmp    %ebx,%eax
f0102a45:	75 e4                	jne    f0102a2b <env_init+0x19>
f0102a47:	89 35 90 4f 17 f0    	mov    %esi,0xf0174f90
		env_free_list = &envs[i]; //将当前Env插入env_free_list
	}
	// Per-CPU part of the initialization
	//这个函数通过配置段硬件，将其分隔为
	//特权等级0(内核)和特权等级(用户)两个不同的段
	env_init_percpu();
f0102a4d:	e8 90 ff ff ff       	call   f01029e2 <env_init_percpu>
}
f0102a52:	5b                   	pop    %ebx
f0102a53:	5e                   	pop    %esi
f0102a54:	5d                   	pop    %ebp
f0102a55:	c3                   	ret    

f0102a56 <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0102a56:	55                   	push   %ebp
f0102a57:	89 e5                	mov    %esp,%ebp
f0102a59:	53                   	push   %ebx
f0102a5a:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0102a5d:	8b 1d 90 4f 17 f0    	mov    0xf0174f90,%ebx
f0102a63:	85 db                	test   %ebx,%ebx
f0102a65:	0f 84 43 01 00 00    	je     f0102bae <env_alloc+0x158>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	//为页目录分配一个物理页
	if (!(p = page_alloc(ALLOC_ZERO)))
f0102a6b:	83 ec 0c             	sub    $0xc,%esp
f0102a6e:	6a 01                	push   $0x1
f0102a70:	e8 00 e3 ff ff       	call   f0100d75 <page_alloc>
f0102a75:	83 c4 10             	add    $0x10,%esp
f0102a78:	85 c0                	test   %eax,%eax
f0102a7a:	0f 84 35 01 00 00    	je     f0102bb5 <env_alloc+0x15f>
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.
	//            page2kva
	// LAB 3: Your code here.
	p->pp_ref++; //需要自增env_pgdir的pp_ref使其能正常工作
f0102a80:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102a85:	2b 05 4c 5c 17 f0    	sub    0xf0175c4c,%eax
f0102a8b:	c1 f8 03             	sar    $0x3,%eax
f0102a8e:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102a91:	89 c2                	mov    %eax,%edx
f0102a93:	c1 ea 0c             	shr    $0xc,%edx
f0102a96:	3b 15 44 5c 17 f0    	cmp    0xf0175c44,%edx
f0102a9c:	72 12                	jb     f0102ab0 <env_alloc+0x5a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102a9e:	50                   	push   %eax
f0102a9f:	68 c8 4f 10 f0       	push   $0xf0104fc8
f0102aa4:	6a 56                	push   $0x56
f0102aa6:	68 ca 4c 10 f0       	push   $0xf0104cca
f0102aab:	e8 f0 d5 ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f0102ab0:	2d 00 00 00 10       	sub    $0x10000000,%eax
	e->env_pgdir = page2kva(p); //env_pgdir指向进程页目录的虚拟地址
f0102ab5:	89 43 5c             	mov    %eax,0x5c(%ebx)
	memcpy(e->env_pgdir, kern_pgdir, PGSIZE); //使用内核页目录作为模板创建进程页目录
f0102ab8:	83 ec 04             	sub    $0x4,%esp
f0102abb:	68 00 10 00 00       	push   $0x1000
f0102ac0:	ff 35 48 5c 17 f0    	pushl  0xf0175c48
f0102ac6:	50                   	push   %eax
f0102ac7:	e8 1f 19 00 00       	call   f01043eb <memcpy>
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0102acc:	8b 43 5c             	mov    0x5c(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102acf:	83 c4 10             	add    $0x10,%esp
f0102ad2:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102ad7:	77 15                	ja     f0102aee <env_alloc+0x98>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102ad9:	50                   	push   %eax
f0102ada:	68 0c 51 10 f0       	push   $0xf010510c
f0102adf:	68 ca 00 00 00       	push   $0xca
f0102ae4:	68 9f 57 10 f0       	push   $0xf010579f
f0102ae9:	e8 b2 d5 ff ff       	call   f01000a0 <_panic>
f0102aee:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0102af4:	83 ca 05             	or     $0x5,%edx
f0102af7:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0102afd:	8b 43 48             	mov    0x48(%ebx),%eax
f0102b00:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0102b05:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0102b0a:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102b0f:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0102b12:	89 da                	mov    %ebx,%edx
f0102b14:	2b 15 8c 4f 17 f0    	sub    0xf0174f8c,%edx
f0102b1a:	c1 fa 05             	sar    $0x5,%edx
f0102b1d:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0102b23:	09 d0                	or     %edx,%eax
f0102b25:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0102b28:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102b2b:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0102b2e:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0102b35:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0102b3c:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0102b43:	83 ec 04             	sub    $0x4,%esp
f0102b46:	6a 44                	push   $0x44
f0102b48:	6a 00                	push   $0x0
f0102b4a:	53                   	push   %ebx
f0102b4b:	e8 e6 17 00 00       	call   f0104336 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0102b50:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0102b56:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0102b5c:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0102b62:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0102b69:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f0102b6f:	8b 43 44             	mov    0x44(%ebx),%eax
f0102b72:	a3 90 4f 17 f0       	mov    %eax,0xf0174f90
	*newenv_store = e;
f0102b77:	8b 45 08             	mov    0x8(%ebp),%eax
f0102b7a:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102b7c:	8b 53 48             	mov    0x48(%ebx),%edx
f0102b7f:	a1 88 4f 17 f0       	mov    0xf0174f88,%eax
f0102b84:	83 c4 10             	add    $0x10,%esp
f0102b87:	85 c0                	test   %eax,%eax
f0102b89:	74 05                	je     f0102b90 <env_alloc+0x13a>
f0102b8b:	8b 40 48             	mov    0x48(%eax),%eax
f0102b8e:	eb 05                	jmp    f0102b95 <env_alloc+0x13f>
f0102b90:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b95:	83 ec 04             	sub    $0x4,%esp
f0102b98:	52                   	push   %edx
f0102b99:	50                   	push   %eax
f0102b9a:	68 be 57 10 f0       	push   $0xf01057be
f0102b9f:	e8 21 04 00 00       	call   f0102fc5 <cprintf>
	return 0;
f0102ba4:	83 c4 10             	add    $0x10,%esp
f0102ba7:	b8 00 00 00 00       	mov    $0x0,%eax
f0102bac:	eb 0c                	jmp    f0102bba <env_alloc+0x164>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0102bae:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0102bb3:	eb 05                	jmp    f0102bba <env_alloc+0x164>
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	//为页目录分配一个物理页
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0102bb5:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0102bba:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102bbd:	c9                   	leave  
f0102bbe:	c3                   	ret    

f0102bbf <env_create>:
//
//env_create调用env_alloc分配一个新进程
//并用load_icode读入elf二进制映像
void
env_create(uint8_t *binary, enum EnvType type)
{
f0102bbf:	55                   	push   %ebp
f0102bc0:	89 e5                	mov    %esp,%ebp
f0102bc2:	57                   	push   %edi
f0102bc3:	56                   	push   %esi
f0102bc4:	53                   	push   %ebx
f0102bc5:	83 ec 34             	sub    $0x34,%esp
f0102bc8:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env *e;
	int flag = env_alloc(&e, 0);//为e分配一个空闲进程空间，无父进程
f0102bcb:	6a 00                	push   $0x0
f0102bcd:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0102bd0:	50                   	push   %eax
f0102bd1:	e8 80 fe ff ff       	call   f0102a56 <env_alloc>
	if(flag != 0) //如果返回值不是0，说明分配失败
f0102bd6:	83 c4 10             	add    $0x10,%esp
f0102bd9:	85 c0                	test   %eax,%eax
f0102bdb:	74 17                	je     f0102bf4 <env_create+0x35>
	{
		panic("create new env failed!");
f0102bdd:	83 ec 04             	sub    $0x4,%esp
f0102be0:	68 d3 57 10 f0       	push   $0xf01057d3
f0102be5:	68 9a 01 00 00       	push   $0x19a
f0102bea:	68 9f 57 10 f0       	push   $0xf010579f
f0102bef:	e8 ac d4 ff ff       	call   f01000a0 <_panic>
	}
	load_icode(e, binary); //加载binary
f0102bf4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102bf7:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	//  What?  (See env_run() and env_pop_tf() below.)

	// LAB 3: Your code here.
	struct Elf *elf_header = (struct Elf*)binary; //获取binary的elf文件头
	struct Proghdr *ph, *eph; //程序头，参照/boot/main.c
	if (elf_header->e_magic != ELF_MAGIC)
f0102bfa:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f0102c00:	74 17                	je     f0102c19 <env_create+0x5a>
	{
		panic("binary is not a elf file"); //如果读入的不是elf头文件格式，panic
f0102c02:	83 ec 04             	sub    $0x4,%esp
f0102c05:	68 ea 57 10 f0       	push   $0xf01057ea
f0102c0a:	68 6e 01 00 00       	push   $0x16e
f0102c0f:	68 9f 57 10 f0       	push   $0xf010579f
f0102c14:	e8 87 d4 ff ff       	call   f01000a0 <_panic>
	}
	// 加载程序段
	ph = (struct Proghdr*) ((uint8_t*)elf_header + elf_header->e_phoff);
f0102c19:	89 fb                	mov    %edi,%ebx
f0102c1b:	03 5f 1c             	add    0x1c(%edi),%ebx
	eph = ph + elf_header->e_phnum;
f0102c1e:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f0102c22:	c1 e6 05             	shl    $0x5,%esi
f0102c25:	01 de                	add    %ebx,%esi
	lcr3(PADDR(e->env_pgdir)); //把进程页目录的起始地址存入CR3寄存器
f0102c27:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102c2a:	8b 40 5c             	mov    0x5c(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102c2d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102c32:	77 15                	ja     f0102c49 <env_create+0x8a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102c34:	50                   	push   %eax
f0102c35:	68 0c 51 10 f0       	push   $0xf010510c
f0102c3a:	68 73 01 00 00       	push   $0x173
f0102c3f:	68 9f 57 10 f0       	push   $0xf010579f
f0102c44:	e8 57 d4 ff ff       	call   f01000a0 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102c49:	05 00 00 00 10       	add    $0x10000000,%eax
f0102c4e:	0f 22 d8             	mov    %eax,%cr3
f0102c51:	eb 44                	jmp    f0102c97 <env_create+0xd8>
	for (; ph < eph; ph++)
	{
		if(ph->p_type == ELF_PROG_LOAD) //只加载允许加载的部分
f0102c53:	83 3b 01             	cmpl   $0x1,(%ebx)
f0102c56:	75 3c                	jne    f0102c94 <env_create+0xd5>
		{
			//根据程序头的va和memsiz为进程e分配物理内存
			region_alloc(e, (void*)ph->p_va, ph->p_memsz); 
f0102c58:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0102c5b:	8b 53 08             	mov    0x8(%ebx),%edx
f0102c5e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102c61:	e8 78 fc ff ff       	call   f01028de <region_alloc>
			//binary + ph->p_offset被复制到虚拟地址ph->p_va处
			memmove((void*)ph->p_va, binary + ph->p_offset, ph->p_filesz);
f0102c66:	83 ec 04             	sub    $0x4,%esp
f0102c69:	ff 73 10             	pushl  0x10(%ebx)
f0102c6c:	89 f8                	mov    %edi,%eax
f0102c6e:	03 43 04             	add    0x4(%ebx),%eax
f0102c71:	50                   	push   %eax
f0102c72:	ff 73 08             	pushl  0x8(%ebx)
f0102c75:	e8 09 17 00 00       	call   f0104383 <memmove>
			//剩下的内存被清为0
            memset((void*)(ph->p_va + ph->p_filesz), 0, ph->p_memsz - ph->p_filesz);
f0102c7a:	8b 43 10             	mov    0x10(%ebx),%eax
f0102c7d:	83 c4 0c             	add    $0xc,%esp
f0102c80:	8b 53 14             	mov    0x14(%ebx),%edx
f0102c83:	29 c2                	sub    %eax,%edx
f0102c85:	52                   	push   %edx
f0102c86:	6a 00                	push   $0x0
f0102c88:	03 43 08             	add    0x8(%ebx),%eax
f0102c8b:	50                   	push   %eax
f0102c8c:	e8 a5 16 00 00       	call   f0104336 <memset>
f0102c91:	83 c4 10             	add    $0x10,%esp
	}
	// 加载程序段
	ph = (struct Proghdr*) ((uint8_t*)elf_header + elf_header->e_phoff);
	eph = ph + elf_header->e_phnum;
	lcr3(PADDR(e->env_pgdir)); //把进程页目录的起始地址存入CR3寄存器
	for (; ph < eph; ph++)
f0102c94:	83 c3 20             	add    $0x20,%ebx
f0102c97:	39 de                	cmp    %ebx,%esi
f0102c99:	77 b8                	ja     f0102c53 <env_create+0x94>
			memmove((void*)ph->p_va, binary + ph->p_offset, ph->p_filesz);
			//剩下的内存被清为0
            memset((void*)(ph->p_va + ph->p_filesz), 0, ph->p_memsz - ph->p_filesz);
		}
	}
	e->env_tf.tf_eip = elf_header->e_entry; //在eip寄存器中储存程序的入口
f0102c9b:	8b 47 18             	mov    0x18(%edi),%eax
f0102c9e:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102ca1:	89 41 30             	mov    %eax,0x30(%ecx)
	lcr3(PADDR(kern_pgdir)); //把内核页目录的起始地址存回CR3寄存器
f0102ca4:	a1 48 5c 17 f0       	mov    0xf0175c48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102ca9:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102cae:	77 15                	ja     f0102cc5 <env_create+0x106>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102cb0:	50                   	push   %eax
f0102cb1:	68 0c 51 10 f0       	push   $0xf010510c
f0102cb6:	68 81 01 00 00       	push   $0x181
f0102cbb:	68 9f 57 10 f0       	push   $0xf010579f
f0102cc0:	e8 db d3 ff ff       	call   f01000a0 <_panic>
f0102cc5:	05 00 00 00 10       	add    $0x10000000,%eax
f0102cca:	0f 22 d8             	mov    %eax,%cr3
	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here.
	region_alloc(e, (void*)(USTACKTOP - PGSIZE), PGSIZE);//为用户进程分配栈空间
f0102ccd:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0102cd2:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0102cd7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102cda:	e8 ff fb ff ff       	call   f01028de <region_alloc>
	if(flag != 0) //如果返回值不是0，说明分配失败
	{
		panic("create new env failed!");
	}
	load_icode(e, binary); //加载binary
	e->env_type = type; //标志为用户进程
f0102cdf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102ce2:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102ce5:	89 50 50             	mov    %edx,0x50(%eax)
}
f0102ce8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102ceb:	5b                   	pop    %ebx
f0102cec:	5e                   	pop    %esi
f0102ced:	5f                   	pop    %edi
f0102cee:	5d                   	pop    %ebp
f0102cef:	c3                   	ret    

f0102cf0 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0102cf0:	55                   	push   %ebp
f0102cf1:	89 e5                	mov    %esp,%ebp
f0102cf3:	57                   	push   %edi
f0102cf4:	56                   	push   %esi
f0102cf5:	53                   	push   %ebx
f0102cf6:	83 ec 1c             	sub    $0x1c,%esp
f0102cf9:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0102cfc:	8b 15 88 4f 17 f0    	mov    0xf0174f88,%edx
f0102d02:	39 fa                	cmp    %edi,%edx
f0102d04:	75 29                	jne    f0102d2f <env_free+0x3f>
		lcr3(PADDR(kern_pgdir));
f0102d06:	a1 48 5c 17 f0       	mov    0xf0175c48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102d0b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102d10:	77 15                	ja     f0102d27 <env_free+0x37>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102d12:	50                   	push   %eax
f0102d13:	68 0c 51 10 f0       	push   $0xf010510c
f0102d18:	68 ae 01 00 00       	push   $0x1ae
f0102d1d:	68 9f 57 10 f0       	push   $0xf010579f
f0102d22:	e8 79 d3 ff ff       	call   f01000a0 <_panic>
f0102d27:	05 00 00 00 10       	add    $0x10000000,%eax
f0102d2c:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102d2f:	8b 4f 48             	mov    0x48(%edi),%ecx
f0102d32:	85 d2                	test   %edx,%edx
f0102d34:	74 05                	je     f0102d3b <env_free+0x4b>
f0102d36:	8b 42 48             	mov    0x48(%edx),%eax
f0102d39:	eb 05                	jmp    f0102d40 <env_free+0x50>
f0102d3b:	b8 00 00 00 00       	mov    $0x0,%eax
f0102d40:	83 ec 04             	sub    $0x4,%esp
f0102d43:	51                   	push   %ecx
f0102d44:	50                   	push   %eax
f0102d45:	68 03 58 10 f0       	push   $0xf0105803
f0102d4a:	e8 76 02 00 00       	call   f0102fc5 <cprintf>
f0102d4f:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102d52:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0102d59:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0102d5c:	89 d0                	mov    %edx,%eax
f0102d5e:	c1 e0 02             	shl    $0x2,%eax
f0102d61:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0102d64:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102d67:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0102d6a:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0102d70:	0f 84 a8 00 00 00    	je     f0102e1e <env_free+0x12e>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0102d76:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102d7c:	89 f0                	mov    %esi,%eax
f0102d7e:	c1 e8 0c             	shr    $0xc,%eax
f0102d81:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102d84:	39 05 44 5c 17 f0    	cmp    %eax,0xf0175c44
f0102d8a:	77 15                	ja     f0102da1 <env_free+0xb1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102d8c:	56                   	push   %esi
f0102d8d:	68 c8 4f 10 f0       	push   $0xf0104fc8
f0102d92:	68 bd 01 00 00       	push   $0x1bd
f0102d97:	68 9f 57 10 f0       	push   $0xf010579f
f0102d9c:	e8 ff d2 ff ff       	call   f01000a0 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102da1:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102da4:	c1 e0 16             	shl    $0x16,%eax
f0102da7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102daa:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0102daf:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0102db6:	01 
f0102db7:	74 17                	je     f0102dd0 <env_free+0xe0>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102db9:	83 ec 08             	sub    $0x8,%esp
f0102dbc:	89 d8                	mov    %ebx,%eax
f0102dbe:	c1 e0 0c             	shl    $0xc,%eax
f0102dc1:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0102dc4:	50                   	push   %eax
f0102dc5:	ff 77 5c             	pushl  0x5c(%edi)
f0102dc8:	e8 15 e2 ff ff       	call   f0100fe2 <page_remove>
f0102dcd:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102dd0:	83 c3 01             	add    $0x1,%ebx
f0102dd3:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0102dd9:	75 d4                	jne    f0102daf <env_free+0xbf>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0102ddb:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102dde:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102de1:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102de8:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102deb:	3b 05 44 5c 17 f0    	cmp    0xf0175c44,%eax
f0102df1:	72 14                	jb     f0102e07 <env_free+0x117>
		panic("pa2page called with invalid pa");
f0102df3:	83 ec 04             	sub    $0x4,%esp
f0102df6:	68 b0 50 10 f0       	push   $0xf01050b0
f0102dfb:	6a 4f                	push   $0x4f
f0102dfd:	68 ca 4c 10 f0       	push   $0xf0104cca
f0102e02:	e8 99 d2 ff ff       	call   f01000a0 <_panic>
		page_decref(pa2page(pa));
f0102e07:	83 ec 0c             	sub    $0xc,%esp
f0102e0a:	a1 4c 5c 17 f0       	mov    0xf0175c4c,%eax
f0102e0f:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102e12:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f0102e15:	50                   	push   %eax
f0102e16:	e8 20 e0 ff ff       	call   f0100e3b <page_decref>
f0102e1b:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102e1e:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0102e22:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102e25:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102e2a:	0f 85 29 ff ff ff    	jne    f0102d59 <env_free+0x69>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0102e30:	8b 47 5c             	mov    0x5c(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102e33:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102e38:	77 15                	ja     f0102e4f <env_free+0x15f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102e3a:	50                   	push   %eax
f0102e3b:	68 0c 51 10 f0       	push   $0xf010510c
f0102e40:	68 cb 01 00 00       	push   $0x1cb
f0102e45:	68 9f 57 10 f0       	push   $0xf010579f
f0102e4a:	e8 51 d2 ff ff       	call   f01000a0 <_panic>
	e->env_pgdir = 0;
f0102e4f:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102e56:	05 00 00 00 10       	add    $0x10000000,%eax
f0102e5b:	c1 e8 0c             	shr    $0xc,%eax
f0102e5e:	3b 05 44 5c 17 f0    	cmp    0xf0175c44,%eax
f0102e64:	72 14                	jb     f0102e7a <env_free+0x18a>
		panic("pa2page called with invalid pa");
f0102e66:	83 ec 04             	sub    $0x4,%esp
f0102e69:	68 b0 50 10 f0       	push   $0xf01050b0
f0102e6e:	6a 4f                	push   $0x4f
f0102e70:	68 ca 4c 10 f0       	push   $0xf0104cca
f0102e75:	e8 26 d2 ff ff       	call   f01000a0 <_panic>
	page_decref(pa2page(pa));
f0102e7a:	83 ec 0c             	sub    $0xc,%esp
f0102e7d:	8b 15 4c 5c 17 f0    	mov    0xf0175c4c,%edx
f0102e83:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0102e86:	50                   	push   %eax
f0102e87:	e8 af df ff ff       	call   f0100e3b <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0102e8c:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0102e93:	a1 90 4f 17 f0       	mov    0xf0174f90,%eax
f0102e98:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0102e9b:	89 3d 90 4f 17 f0    	mov    %edi,0xf0174f90
}
f0102ea1:	83 c4 10             	add    $0x10,%esp
f0102ea4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102ea7:	5b                   	pop    %ebx
f0102ea8:	5e                   	pop    %esi
f0102ea9:	5f                   	pop    %edi
f0102eaa:	5d                   	pop    %ebp
f0102eab:	c3                   	ret    

f0102eac <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f0102eac:	55                   	push   %ebp
f0102ead:	89 e5                	mov    %esp,%ebp
f0102eaf:	83 ec 14             	sub    $0x14,%esp
	env_free(e);
f0102eb2:	ff 75 08             	pushl  0x8(%ebp)
f0102eb5:	e8 36 fe ff ff       	call   f0102cf0 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f0102eba:	c7 04 24 28 58 10 f0 	movl   $0xf0105828,(%esp)
f0102ec1:	e8 ff 00 00 00       	call   f0102fc5 <cprintf>
f0102ec6:	83 c4 10             	add    $0x10,%esp
	while (1)
		monitor(NULL);
f0102ec9:	83 ec 0c             	sub    $0xc,%esp
f0102ecc:	6a 00                	push   $0x0
f0102ece:	e8 c9 d8 ff ff       	call   f010079c <monitor>
f0102ed3:	83 c4 10             	add    $0x10,%esp
f0102ed6:	eb f1                	jmp    f0102ec9 <env_destroy+0x1d>

f0102ed8 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0102ed8:	55                   	push   %ebp
f0102ed9:	89 e5                	mov    %esp,%ebp
f0102edb:	83 ec 0c             	sub    $0xc,%esp
	__asm __volatile("movl %0,%%esp\n"
f0102ede:	8b 65 08             	mov    0x8(%ebp),%esp
f0102ee1:	61                   	popa   
f0102ee2:	07                   	pop    %es
f0102ee3:	1f                   	pop    %ds
f0102ee4:	83 c4 08             	add    $0x8,%esp
f0102ee7:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0102ee8:	68 19 58 10 f0       	push   $0xf0105819
f0102eed:	68 f3 01 00 00       	push   $0x1f3
f0102ef2:	68 9f 57 10 f0       	push   $0xf010579f
f0102ef7:	e8 a4 d1 ff ff       	call   f01000a0 <_panic>

f0102efc <env_run>:
// This function does not return.
//
//启动一个进程，curenv变成当前启动的进程e
void
env_run(struct Env *e)
{
f0102efc:	55                   	push   %ebp
f0102efd:	89 e5                	mov    %esp,%ebp
f0102eff:	83 ec 08             	sub    $0x8,%esp
f0102f02:	8b 45 08             	mov    0x8(%ebp),%eax
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	if(curenv != NULL && curenv->env_status == ENV_RUNNING)
f0102f05:	8b 15 88 4f 17 f0    	mov    0xf0174f88,%edx
f0102f0b:	85 d2                	test   %edx,%edx
f0102f0d:	74 0d                	je     f0102f1c <env_run+0x20>
f0102f0f:	83 7a 54 03          	cmpl   $0x3,0x54(%edx)
f0102f13:	75 07                	jne    f0102f1c <env_run+0x20>
	{ //如果当前有进程正在执行，先将它挂起
		curenv->env_status = ENV_RUNNABLE;
f0102f15:	c7 42 54 02 00 00 00 	movl   $0x2,0x54(%edx)
	}
	curenv = e; //将正在执行的进程变为e
f0102f1c:	a3 88 4f 17 f0       	mov    %eax,0xf0174f88
	e->env_status = ENV_RUNNING; //改变e的状态
f0102f21:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	e->env_runs++; //e的执行次数+1
f0102f28:	83 40 58 01          	addl   $0x1,0x58(%eax)
	lcr3(PADDR(e->env_pgdir)); //加载进程的线性地址空间
f0102f2c:	8b 50 5c             	mov    0x5c(%eax),%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102f2f:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0102f35:	77 15                	ja     f0102f4c <env_run+0x50>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102f37:	52                   	push   %edx
f0102f38:	68 0c 51 10 f0       	push   $0xf010510c
f0102f3d:	68 19 02 00 00       	push   $0x219
f0102f42:	68 9f 57 10 f0       	push   $0xf010579f
f0102f47:	e8 54 d1 ff ff       	call   f01000a0 <_panic>
f0102f4c:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0102f52:	0f 22 da             	mov    %edx,%cr3
	env_pop_tf(&e->env_tf); //弹出进程的寄存器结构，开始从进程的eip地址读取指令
f0102f55:	83 ec 0c             	sub    $0xc,%esp
f0102f58:	50                   	push   %eax
f0102f59:	e8 7a ff ff ff       	call   f0102ed8 <env_pop_tf>

f0102f5e <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102f5e:	55                   	push   %ebp
f0102f5f:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102f61:	ba 70 00 00 00       	mov    $0x70,%edx
f0102f66:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f69:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102f6a:	ba 71 00 00 00       	mov    $0x71,%edx
f0102f6f:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102f70:	0f b6 c0             	movzbl %al,%eax
}
f0102f73:	5d                   	pop    %ebp
f0102f74:	c3                   	ret    

f0102f75 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102f75:	55                   	push   %ebp
f0102f76:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102f78:	ba 70 00 00 00       	mov    $0x70,%edx
f0102f7d:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f80:	ee                   	out    %al,(%dx)
f0102f81:	ba 71 00 00 00       	mov    $0x71,%edx
f0102f86:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102f89:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102f8a:	5d                   	pop    %ebp
f0102f8b:	c3                   	ret    

f0102f8c <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102f8c:	55                   	push   %ebp
f0102f8d:	89 e5                	mov    %esp,%ebp
f0102f8f:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0102f92:	ff 75 08             	pushl  0x8(%ebp)
f0102f95:	e8 6d d6 ff ff       	call   f0100607 <cputchar>
	*cnt++;
}
f0102f9a:	83 c4 10             	add    $0x10,%esp
f0102f9d:	c9                   	leave  
f0102f9e:	c3                   	ret    

f0102f9f <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102f9f:	55                   	push   %ebp
f0102fa0:	89 e5                	mov    %esp,%ebp
f0102fa2:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0102fa5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102fac:	ff 75 0c             	pushl  0xc(%ebp)
f0102faf:	ff 75 08             	pushl  0x8(%ebp)
f0102fb2:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102fb5:	50                   	push   %eax
f0102fb6:	68 8c 2f 10 f0       	push   $0xf0102f8c
f0102fbb:	e8 0a 0d 00 00       	call   f0103cca <vprintfmt>
	return cnt;
}
f0102fc0:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102fc3:	c9                   	leave  
f0102fc4:	c3                   	ret    

f0102fc5 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102fc5:	55                   	push   %ebp
f0102fc6:	89 e5                	mov    %esp,%ebp
f0102fc8:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102fcb:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102fce:	50                   	push   %eax
f0102fcf:	ff 75 08             	pushl  0x8(%ebp)
f0102fd2:	e8 c8 ff ff ff       	call   f0102f9f <vcprintf>
	va_end(ap);

	return cnt;
}
f0102fd7:	c9                   	leave  
f0102fd8:	c3                   	ret    

f0102fd9 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0102fd9:	55                   	push   %ebp
f0102fda:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0102fdc:	b8 c0 57 17 f0       	mov    $0xf01757c0,%eax
f0102fe1:	c7 05 c4 57 17 f0 00 	movl   $0xf0000000,0xf01757c4
f0102fe8:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f0102feb:	66 c7 05 c8 57 17 f0 	movw   $0x10,0xf01757c8
f0102ff2:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f0102ff4:	66 c7 05 48 b3 11 f0 	movw   $0x67,0xf011b348
f0102ffb:	67 00 
f0102ffd:	66 a3 4a b3 11 f0    	mov    %ax,0xf011b34a
f0103003:	89 c2                	mov    %eax,%edx
f0103005:	c1 ea 10             	shr    $0x10,%edx
f0103008:	88 15 4c b3 11 f0    	mov    %dl,0xf011b34c
f010300e:	c6 05 4e b3 11 f0 40 	movb   $0x40,0xf011b34e
f0103015:	c1 e8 18             	shr    $0x18,%eax
f0103018:	a2 4f b3 11 f0       	mov    %al,0xf011b34f
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f010301d:	c6 05 4d b3 11 f0 89 	movb   $0x89,0xf011b34d
}

static __inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f0103024:	b8 28 00 00 00       	mov    $0x28,%eax
f0103029:	0f 00 d8             	ltr    %ax
}

static __inline void
lidt(void *p)
{
	__asm __volatile("lidt (%0)" : : "r" (p));
f010302c:	b8 50 b3 11 f0       	mov    $0xf011b350,%eax
f0103031:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f0103034:	5d                   	pop    %ebp
f0103035:	c3                   	ret    

f0103036 <trap_init>:
}

//初始化IDT，使其指向每一个定义在trapentry.S中的入口点
void
trap_init(void)
{
f0103036:	55                   	push   %ebp
f0103037:	89 e5                	mov    %esp,%ebp
    void t_simderr();
    void t_syscall();
	//SETGATE(gate, istrap, sel, off, dpl)
	//gate为入口，istrap 0表示是中断入口，
	//sel是中断处理函数的段选择子，off是中断处理函数的偏移量，dpl是权限等级
    SETGATE(idt[T_DIVIDE], 0, GD_KT, t_divide, 0);
f0103039:	b8 0a 37 10 f0       	mov    $0xf010370a,%eax
f010303e:	66 a3 a0 4f 17 f0    	mov    %ax,0xf0174fa0
f0103044:	66 c7 05 a2 4f 17 f0 	movw   $0x8,0xf0174fa2
f010304b:	08 00 
f010304d:	c6 05 a4 4f 17 f0 00 	movb   $0x0,0xf0174fa4
f0103054:	c6 05 a5 4f 17 f0 8e 	movb   $0x8e,0xf0174fa5
f010305b:	c1 e8 10             	shr    $0x10,%eax
f010305e:	66 a3 a6 4f 17 f0    	mov    %ax,0xf0174fa6
    SETGATE(idt[T_DEBUG], 0, GD_KT, t_debug, 0);
f0103064:	b8 10 37 10 f0       	mov    $0xf0103710,%eax
f0103069:	66 a3 a8 4f 17 f0    	mov    %ax,0xf0174fa8
f010306f:	66 c7 05 aa 4f 17 f0 	movw   $0x8,0xf0174faa
f0103076:	08 00 
f0103078:	c6 05 ac 4f 17 f0 00 	movb   $0x0,0xf0174fac
f010307f:	c6 05 ad 4f 17 f0 8e 	movb   $0x8e,0xf0174fad
f0103086:	c1 e8 10             	shr    $0x10,%eax
f0103089:	66 a3 ae 4f 17 f0    	mov    %ax,0xf0174fae
    SETGATE(idt[T_NMI], 0, GD_KT, t_nmi, 0);
f010308f:	b8 16 37 10 f0       	mov    $0xf0103716,%eax
f0103094:	66 a3 b0 4f 17 f0    	mov    %ax,0xf0174fb0
f010309a:	66 c7 05 b2 4f 17 f0 	movw   $0x8,0xf0174fb2
f01030a1:	08 00 
f01030a3:	c6 05 b4 4f 17 f0 00 	movb   $0x0,0xf0174fb4
f01030aa:	c6 05 b5 4f 17 f0 8e 	movb   $0x8e,0xf0174fb5
f01030b1:	c1 e8 10             	shr    $0x10,%eax
f01030b4:	66 a3 b6 4f 17 f0    	mov    %ax,0xf0174fb6
    SETGATE(idt[T_BRKPT], 1, GD_KT, t_brkpt, 3);
f01030ba:	b8 1c 37 10 f0       	mov    $0xf010371c,%eax
f01030bf:	66 a3 b8 4f 17 f0    	mov    %ax,0xf0174fb8
f01030c5:	66 c7 05 ba 4f 17 f0 	movw   $0x8,0xf0174fba
f01030cc:	08 00 
f01030ce:	c6 05 bc 4f 17 f0 00 	movb   $0x0,0xf0174fbc
f01030d5:	c6 05 bd 4f 17 f0 ef 	movb   $0xef,0xf0174fbd
f01030dc:	c1 e8 10             	shr    $0x10,%eax
f01030df:	66 a3 be 4f 17 f0    	mov    %ax,0xf0174fbe
    SETGATE(idt[T_OFLOW], 0, GD_KT, t_oflow, 0);
f01030e5:	b8 22 37 10 f0       	mov    $0xf0103722,%eax
f01030ea:	66 a3 c0 4f 17 f0    	mov    %ax,0xf0174fc0
f01030f0:	66 c7 05 c2 4f 17 f0 	movw   $0x8,0xf0174fc2
f01030f7:	08 00 
f01030f9:	c6 05 c4 4f 17 f0 00 	movb   $0x0,0xf0174fc4
f0103100:	c6 05 c5 4f 17 f0 8e 	movb   $0x8e,0xf0174fc5
f0103107:	c1 e8 10             	shr    $0x10,%eax
f010310a:	66 a3 c6 4f 17 f0    	mov    %ax,0xf0174fc6
    SETGATE(idt[T_BOUND], 0, GD_KT, t_bound, 0);
f0103110:	b8 28 37 10 f0       	mov    $0xf0103728,%eax
f0103115:	66 a3 c8 4f 17 f0    	mov    %ax,0xf0174fc8
f010311b:	66 c7 05 ca 4f 17 f0 	movw   $0x8,0xf0174fca
f0103122:	08 00 
f0103124:	c6 05 cc 4f 17 f0 00 	movb   $0x0,0xf0174fcc
f010312b:	c6 05 cd 4f 17 f0 8e 	movb   $0x8e,0xf0174fcd
f0103132:	c1 e8 10             	shr    $0x10,%eax
f0103135:	66 a3 ce 4f 17 f0    	mov    %ax,0xf0174fce
    SETGATE(idt[T_ILLOP], 0, GD_KT, t_illop, 0);
f010313b:	b8 2e 37 10 f0       	mov    $0xf010372e,%eax
f0103140:	66 a3 d0 4f 17 f0    	mov    %ax,0xf0174fd0
f0103146:	66 c7 05 d2 4f 17 f0 	movw   $0x8,0xf0174fd2
f010314d:	08 00 
f010314f:	c6 05 d4 4f 17 f0 00 	movb   $0x0,0xf0174fd4
f0103156:	c6 05 d5 4f 17 f0 8e 	movb   $0x8e,0xf0174fd5
f010315d:	c1 e8 10             	shr    $0x10,%eax
f0103160:	66 a3 d6 4f 17 f0    	mov    %ax,0xf0174fd6
    SETGATE(idt[T_DEVICE], 0, GD_KT, t_device, 0);
f0103166:	b8 34 37 10 f0       	mov    $0xf0103734,%eax
f010316b:	66 a3 d8 4f 17 f0    	mov    %ax,0xf0174fd8
f0103171:	66 c7 05 da 4f 17 f0 	movw   $0x8,0xf0174fda
f0103178:	08 00 
f010317a:	c6 05 dc 4f 17 f0 00 	movb   $0x0,0xf0174fdc
f0103181:	c6 05 dd 4f 17 f0 8e 	movb   $0x8e,0xf0174fdd
f0103188:	c1 e8 10             	shr    $0x10,%eax
f010318b:	66 a3 de 4f 17 f0    	mov    %ax,0xf0174fde
    SETGATE(idt[T_DBLFLT], 0, GD_KT, t_dblflt, 0);
f0103191:	b8 3a 37 10 f0       	mov    $0xf010373a,%eax
f0103196:	66 a3 e0 4f 17 f0    	mov    %ax,0xf0174fe0
f010319c:	66 c7 05 e2 4f 17 f0 	movw   $0x8,0xf0174fe2
f01031a3:	08 00 
f01031a5:	c6 05 e4 4f 17 f0 00 	movb   $0x0,0xf0174fe4
f01031ac:	c6 05 e5 4f 17 f0 8e 	movb   $0x8e,0xf0174fe5
f01031b3:	c1 e8 10             	shr    $0x10,%eax
f01031b6:	66 a3 e6 4f 17 f0    	mov    %ax,0xf0174fe6
    SETGATE(idt[T_TSS], 0, GD_KT, t_tss, 0);
f01031bc:	b8 3e 37 10 f0       	mov    $0xf010373e,%eax
f01031c1:	66 a3 f0 4f 17 f0    	mov    %ax,0xf0174ff0
f01031c7:	66 c7 05 f2 4f 17 f0 	movw   $0x8,0xf0174ff2
f01031ce:	08 00 
f01031d0:	c6 05 f4 4f 17 f0 00 	movb   $0x0,0xf0174ff4
f01031d7:	c6 05 f5 4f 17 f0 8e 	movb   $0x8e,0xf0174ff5
f01031de:	c1 e8 10             	shr    $0x10,%eax
f01031e1:	66 a3 f6 4f 17 f0    	mov    %ax,0xf0174ff6
    SETGATE(idt[T_SEGNP], 0, GD_KT, t_segnp, 0);
f01031e7:	b8 42 37 10 f0       	mov    $0xf0103742,%eax
f01031ec:	66 a3 f8 4f 17 f0    	mov    %ax,0xf0174ff8
f01031f2:	66 c7 05 fa 4f 17 f0 	movw   $0x8,0xf0174ffa
f01031f9:	08 00 
f01031fb:	c6 05 fc 4f 17 f0 00 	movb   $0x0,0xf0174ffc
f0103202:	c6 05 fd 4f 17 f0 8e 	movb   $0x8e,0xf0174ffd
f0103209:	c1 e8 10             	shr    $0x10,%eax
f010320c:	66 a3 fe 4f 17 f0    	mov    %ax,0xf0174ffe
    SETGATE(idt[T_STACK], 0, GD_KT, t_stack, 0);
f0103212:	b8 46 37 10 f0       	mov    $0xf0103746,%eax
f0103217:	66 a3 00 50 17 f0    	mov    %ax,0xf0175000
f010321d:	66 c7 05 02 50 17 f0 	movw   $0x8,0xf0175002
f0103224:	08 00 
f0103226:	c6 05 04 50 17 f0 00 	movb   $0x0,0xf0175004
f010322d:	c6 05 05 50 17 f0 8e 	movb   $0x8e,0xf0175005
f0103234:	c1 e8 10             	shr    $0x10,%eax
f0103237:	66 a3 06 50 17 f0    	mov    %ax,0xf0175006
    SETGATE(idt[T_GPFLT], 0, GD_KT, t_gpflt, 0);
f010323d:	b8 4a 37 10 f0       	mov    $0xf010374a,%eax
f0103242:	66 a3 08 50 17 f0    	mov    %ax,0xf0175008
f0103248:	66 c7 05 0a 50 17 f0 	movw   $0x8,0xf017500a
f010324f:	08 00 
f0103251:	c6 05 0c 50 17 f0 00 	movb   $0x0,0xf017500c
f0103258:	c6 05 0d 50 17 f0 8e 	movb   $0x8e,0xf017500d
f010325f:	c1 e8 10             	shr    $0x10,%eax
f0103262:	66 a3 0e 50 17 f0    	mov    %ax,0xf017500e
    SETGATE(idt[T_PGFLT], 0, GD_KT, t_pgflt, 0);
f0103268:	b8 4e 37 10 f0       	mov    $0xf010374e,%eax
f010326d:	66 a3 10 50 17 f0    	mov    %ax,0xf0175010
f0103273:	66 c7 05 12 50 17 f0 	movw   $0x8,0xf0175012
f010327a:	08 00 
f010327c:	c6 05 14 50 17 f0 00 	movb   $0x0,0xf0175014
f0103283:	c6 05 15 50 17 f0 8e 	movb   $0x8e,0xf0175015
f010328a:	c1 e8 10             	shr    $0x10,%eax
f010328d:	66 a3 16 50 17 f0    	mov    %ax,0xf0175016
    SETGATE(idt[T_FPERR], 0, GD_KT, t_fperr, 0);
f0103293:	b8 52 37 10 f0       	mov    $0xf0103752,%eax
f0103298:	66 a3 20 50 17 f0    	mov    %ax,0xf0175020
f010329e:	66 c7 05 22 50 17 f0 	movw   $0x8,0xf0175022
f01032a5:	08 00 
f01032a7:	c6 05 24 50 17 f0 00 	movb   $0x0,0xf0175024
f01032ae:	c6 05 25 50 17 f0 8e 	movb   $0x8e,0xf0175025
f01032b5:	c1 e8 10             	shr    $0x10,%eax
f01032b8:	66 a3 26 50 17 f0    	mov    %ax,0xf0175026
    SETGATE(idt[T_ALIGN], 0, GD_KT, t_align, 0);
f01032be:	b8 58 37 10 f0       	mov    $0xf0103758,%eax
f01032c3:	66 a3 28 50 17 f0    	mov    %ax,0xf0175028
f01032c9:	66 c7 05 2a 50 17 f0 	movw   $0x8,0xf017502a
f01032d0:	08 00 
f01032d2:	c6 05 2c 50 17 f0 00 	movb   $0x0,0xf017502c
f01032d9:	c6 05 2d 50 17 f0 8e 	movb   $0x8e,0xf017502d
f01032e0:	c1 e8 10             	shr    $0x10,%eax
f01032e3:	66 a3 2e 50 17 f0    	mov    %ax,0xf017502e
    SETGATE(idt[T_MCHK], 0, GD_KT, t_mchk, 0);
f01032e9:	b8 5c 37 10 f0       	mov    $0xf010375c,%eax
f01032ee:	66 a3 30 50 17 f0    	mov    %ax,0xf0175030
f01032f4:	66 c7 05 32 50 17 f0 	movw   $0x8,0xf0175032
f01032fb:	08 00 
f01032fd:	c6 05 34 50 17 f0 00 	movb   $0x0,0xf0175034
f0103304:	c6 05 35 50 17 f0 8e 	movb   $0x8e,0xf0175035
f010330b:	c1 e8 10             	shr    $0x10,%eax
f010330e:	66 a3 36 50 17 f0    	mov    %ax,0xf0175036
    SETGATE(idt[T_SIMDERR], 0, GD_KT, t_simderr, 0);
f0103314:	b8 62 37 10 f0       	mov    $0xf0103762,%eax
f0103319:	66 a3 38 50 17 f0    	mov    %ax,0xf0175038
f010331f:	66 c7 05 3a 50 17 f0 	movw   $0x8,0xf017503a
f0103326:	08 00 
f0103328:	c6 05 3c 50 17 f0 00 	movb   $0x0,0xf017503c
f010332f:	c6 05 3d 50 17 f0 8e 	movb   $0x8e,0xf017503d
f0103336:	c1 e8 10             	shr    $0x10,%eax
f0103339:	66 a3 3e 50 17 f0    	mov    %ax,0xf017503e
    SETGATE(idt[T_SYSCALL], 0, GD_KT, t_syscall, 3);
f010333f:	b8 68 37 10 f0       	mov    $0xf0103768,%eax
f0103344:	66 a3 20 51 17 f0    	mov    %ax,0xf0175120
f010334a:	66 c7 05 22 51 17 f0 	movw   $0x8,0xf0175122
f0103351:	08 00 
f0103353:	c6 05 24 51 17 f0 00 	movb   $0x0,0xf0175124
f010335a:	c6 05 25 51 17 f0 ee 	movb   $0xee,0xf0175125
f0103361:	c1 e8 10             	shr    $0x10,%eax
f0103364:	66 a3 26 51 17 f0    	mov    %ax,0xf0175126
	// Per-CPU setup 
	trap_init_percpu();
f010336a:	e8 6a fc ff ff       	call   f0102fd9 <trap_init_percpu>
}
f010336f:	5d                   	pop    %ebp
f0103370:	c3                   	ret    

f0103371 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0103371:	55                   	push   %ebp
f0103372:	89 e5                	mov    %esp,%ebp
f0103374:	53                   	push   %ebx
f0103375:	83 ec 0c             	sub    $0xc,%esp
f0103378:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f010337b:	ff 33                	pushl  (%ebx)
f010337d:	68 5e 58 10 f0       	push   $0xf010585e
f0103382:	e8 3e fc ff ff       	call   f0102fc5 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0103387:	83 c4 08             	add    $0x8,%esp
f010338a:	ff 73 04             	pushl  0x4(%ebx)
f010338d:	68 6d 58 10 f0       	push   $0xf010586d
f0103392:	e8 2e fc ff ff       	call   f0102fc5 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103397:	83 c4 08             	add    $0x8,%esp
f010339a:	ff 73 08             	pushl  0x8(%ebx)
f010339d:	68 7c 58 10 f0       	push   $0xf010587c
f01033a2:	e8 1e fc ff ff       	call   f0102fc5 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f01033a7:	83 c4 08             	add    $0x8,%esp
f01033aa:	ff 73 0c             	pushl  0xc(%ebx)
f01033ad:	68 8b 58 10 f0       	push   $0xf010588b
f01033b2:	e8 0e fc ff ff       	call   f0102fc5 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f01033b7:	83 c4 08             	add    $0x8,%esp
f01033ba:	ff 73 10             	pushl  0x10(%ebx)
f01033bd:	68 9a 58 10 f0       	push   $0xf010589a
f01033c2:	e8 fe fb ff ff       	call   f0102fc5 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f01033c7:	83 c4 08             	add    $0x8,%esp
f01033ca:	ff 73 14             	pushl  0x14(%ebx)
f01033cd:	68 a9 58 10 f0       	push   $0xf01058a9
f01033d2:	e8 ee fb ff ff       	call   f0102fc5 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f01033d7:	83 c4 08             	add    $0x8,%esp
f01033da:	ff 73 18             	pushl  0x18(%ebx)
f01033dd:	68 b8 58 10 f0       	push   $0xf01058b8
f01033e2:	e8 de fb ff ff       	call   f0102fc5 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f01033e7:	83 c4 08             	add    $0x8,%esp
f01033ea:	ff 73 1c             	pushl  0x1c(%ebx)
f01033ed:	68 c7 58 10 f0       	push   $0xf01058c7
f01033f2:	e8 ce fb ff ff       	call   f0102fc5 <cprintf>
}
f01033f7:	83 c4 10             	add    $0x10,%esp
f01033fa:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01033fd:	c9                   	leave  
f01033fe:	c3                   	ret    

f01033ff <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f01033ff:	55                   	push   %ebp
f0103400:	89 e5                	mov    %esp,%ebp
f0103402:	56                   	push   %esi
f0103403:	53                   	push   %ebx
f0103404:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f0103407:	83 ec 08             	sub    $0x8,%esp
f010340a:	53                   	push   %ebx
f010340b:	68 1b 5a 10 f0       	push   $0xf0105a1b
f0103410:	e8 b0 fb ff ff       	call   f0102fc5 <cprintf>
	print_regs(&tf->tf_regs);
f0103415:	89 1c 24             	mov    %ebx,(%esp)
f0103418:	e8 54 ff ff ff       	call   f0103371 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f010341d:	83 c4 08             	add    $0x8,%esp
f0103420:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103424:	50                   	push   %eax
f0103425:	68 18 59 10 f0       	push   $0xf0105918
f010342a:	e8 96 fb ff ff       	call   f0102fc5 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f010342f:	83 c4 08             	add    $0x8,%esp
f0103432:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103436:	50                   	push   %eax
f0103437:	68 2b 59 10 f0       	push   $0xf010592b
f010343c:	e8 84 fb ff ff       	call   f0102fc5 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103441:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f0103444:	83 c4 10             	add    $0x10,%esp
f0103447:	83 f8 13             	cmp    $0x13,%eax
f010344a:	77 09                	ja     f0103455 <print_trapframe+0x56>
		return excnames[trapno];
f010344c:	8b 14 85 e0 5b 10 f0 	mov    -0xfefa420(,%eax,4),%edx
f0103453:	eb 10                	jmp    f0103465 <print_trapframe+0x66>
	if (trapno == T_SYSCALL)
		return "System call";
	return "(unknown trap)";
f0103455:	83 f8 30             	cmp    $0x30,%eax
f0103458:	b9 e2 58 10 f0       	mov    $0xf01058e2,%ecx
f010345d:	ba d6 58 10 f0       	mov    $0xf01058d6,%edx
f0103462:	0f 45 d1             	cmovne %ecx,%edx
{
	cprintf("TRAP frame at %p\n", tf);
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103465:	83 ec 04             	sub    $0x4,%esp
f0103468:	52                   	push   %edx
f0103469:	50                   	push   %eax
f010346a:	68 3e 59 10 f0       	push   $0xf010593e
f010346f:	e8 51 fb ff ff       	call   f0102fc5 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103474:	83 c4 10             	add    $0x10,%esp
f0103477:	3b 1d a0 57 17 f0    	cmp    0xf01757a0,%ebx
f010347d:	75 1a                	jne    f0103499 <print_trapframe+0x9a>
f010347f:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103483:	75 14                	jne    f0103499 <print_trapframe+0x9a>

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0103485:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103488:	83 ec 08             	sub    $0x8,%esp
f010348b:	50                   	push   %eax
f010348c:	68 50 59 10 f0       	push   $0xf0105950
f0103491:	e8 2f fb ff ff       	call   f0102fc5 <cprintf>
f0103496:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f0103499:	83 ec 08             	sub    $0x8,%esp
f010349c:	ff 73 2c             	pushl  0x2c(%ebx)
f010349f:	68 5f 59 10 f0       	push   $0xf010595f
f01034a4:	e8 1c fb ff ff       	call   f0102fc5 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f01034a9:	83 c4 10             	add    $0x10,%esp
f01034ac:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f01034b0:	75 49                	jne    f01034fb <print_trapframe+0xfc>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f01034b2:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f01034b5:	89 c2                	mov    %eax,%edx
f01034b7:	83 e2 01             	and    $0x1,%edx
f01034ba:	ba fc 58 10 f0       	mov    $0xf01058fc,%edx
f01034bf:	b9 f1 58 10 f0       	mov    $0xf01058f1,%ecx
f01034c4:	0f 44 ca             	cmove  %edx,%ecx
f01034c7:	89 c2                	mov    %eax,%edx
f01034c9:	83 e2 02             	and    $0x2,%edx
f01034cc:	ba 0e 59 10 f0       	mov    $0xf010590e,%edx
f01034d1:	be 08 59 10 f0       	mov    $0xf0105908,%esi
f01034d6:	0f 45 d6             	cmovne %esi,%edx
f01034d9:	83 e0 04             	and    $0x4,%eax
f01034dc:	be e6 59 10 f0       	mov    $0xf01059e6,%esi
f01034e1:	b8 13 59 10 f0       	mov    $0xf0105913,%eax
f01034e6:	0f 44 c6             	cmove  %esi,%eax
f01034e9:	51                   	push   %ecx
f01034ea:	52                   	push   %edx
f01034eb:	50                   	push   %eax
f01034ec:	68 6d 59 10 f0       	push   $0xf010596d
f01034f1:	e8 cf fa ff ff       	call   f0102fc5 <cprintf>
f01034f6:	83 c4 10             	add    $0x10,%esp
f01034f9:	eb 10                	jmp    f010350b <print_trapframe+0x10c>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f01034fb:	83 ec 0c             	sub    $0xc,%esp
f01034fe:	68 93 4f 10 f0       	push   $0xf0104f93
f0103503:	e8 bd fa ff ff       	call   f0102fc5 <cprintf>
f0103508:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f010350b:	83 ec 08             	sub    $0x8,%esp
f010350e:	ff 73 30             	pushl  0x30(%ebx)
f0103511:	68 7c 59 10 f0       	push   $0xf010597c
f0103516:	e8 aa fa ff ff       	call   f0102fc5 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f010351b:	83 c4 08             	add    $0x8,%esp
f010351e:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103522:	50                   	push   %eax
f0103523:	68 8b 59 10 f0       	push   $0xf010598b
f0103528:	e8 98 fa ff ff       	call   f0102fc5 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f010352d:	83 c4 08             	add    $0x8,%esp
f0103530:	ff 73 38             	pushl  0x38(%ebx)
f0103533:	68 9e 59 10 f0       	push   $0xf010599e
f0103538:	e8 88 fa ff ff       	call   f0102fc5 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f010353d:	83 c4 10             	add    $0x10,%esp
f0103540:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103544:	74 25                	je     f010356b <print_trapframe+0x16c>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103546:	83 ec 08             	sub    $0x8,%esp
f0103549:	ff 73 3c             	pushl  0x3c(%ebx)
f010354c:	68 ad 59 10 f0       	push   $0xf01059ad
f0103551:	e8 6f fa ff ff       	call   f0102fc5 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103556:	83 c4 08             	add    $0x8,%esp
f0103559:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f010355d:	50                   	push   %eax
f010355e:	68 bc 59 10 f0       	push   $0xf01059bc
f0103563:	e8 5d fa ff ff       	call   f0102fc5 <cprintf>
f0103568:	83 c4 10             	add    $0x10,%esp
	}
}
f010356b:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010356e:	5b                   	pop    %ebx
f010356f:	5e                   	pop    %esi
f0103570:	5d                   	pop    %ebp
f0103571:	c3                   	ret    

f0103572 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103572:	55                   	push   %ebp
f0103573:	89 e5                	mov    %esp,%ebp
f0103575:	53                   	push   %ebx
f0103576:	83 ec 04             	sub    $0x4,%esp
f0103579:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010357c:	0f 20 d0             	mov    %cr2,%eax
	fault_va = rcr2();

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
	if((tf->tf_cs & 3) == 0)//如果缺页发生在内核，panic
f010357f:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103583:	75 17                	jne    f010359c <page_fault_handler+0x2a>
	{
		panic("page fault happened in kernel");
f0103585:	83 ec 04             	sub    $0x4,%esp
f0103588:	68 cf 59 10 f0       	push   $0xf01059cf
f010358d:	68 0e 01 00 00       	push   $0x10e
f0103592:	68 ed 59 10 f0       	push   $0xf01059ed
f0103597:	e8 04 cb ff ff       	call   f01000a0 <_panic>
	}
	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f010359c:	ff 73 30             	pushl  0x30(%ebx)
f010359f:	50                   	push   %eax
f01035a0:	a1 88 4f 17 f0       	mov    0xf0174f88,%eax
f01035a5:	ff 70 48             	pushl  0x48(%eax)
f01035a8:	68 90 5b 10 f0       	push   $0xf0105b90
f01035ad:	e8 13 fa ff ff       	call   f0102fc5 <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f01035b2:	89 1c 24             	mov    %ebx,(%esp)
f01035b5:	e8 45 fe ff ff       	call   f01033ff <print_trapframe>
	env_destroy(curenv);
f01035ba:	83 c4 04             	add    $0x4,%esp
f01035bd:	ff 35 88 4f 17 f0    	pushl  0xf0174f88
f01035c3:	e8 e4 f8 ff ff       	call   f0102eac <env_destroy>
}
f01035c8:	83 c4 10             	add    $0x10,%esp
f01035cb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01035ce:	c9                   	leave  
f01035cf:	c3                   	ret    

f01035d0 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f01035d0:	55                   	push   %ebp
f01035d1:	89 e5                	mov    %esp,%ebp
f01035d3:	57                   	push   %edi
f01035d4:	56                   	push   %esi
f01035d5:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f01035d8:	fc                   	cld    

static __inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	__asm __volatile("pushfl; popl %0" : "=r" (eflags));
f01035d9:	9c                   	pushf  
f01035da:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f01035db:	f6 c4 02             	test   $0x2,%ah
f01035de:	74 19                	je     f01035f9 <trap+0x29>
f01035e0:	68 f9 59 10 f0       	push   $0xf01059f9
f01035e5:	68 e4 4c 10 f0       	push   $0xf0104ce4
f01035ea:	68 e4 00 00 00       	push   $0xe4
f01035ef:	68 ed 59 10 f0       	push   $0xf01059ed
f01035f4:	e8 a7 ca ff ff       	call   f01000a0 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f01035f9:	83 ec 08             	sub    $0x8,%esp
f01035fc:	56                   	push   %esi
f01035fd:	68 12 5a 10 f0       	push   $0xf0105a12
f0103602:	e8 be f9 ff ff       	call   f0102fc5 <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f0103607:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f010360b:	83 e0 03             	and    $0x3,%eax
f010360e:	83 c4 10             	add    $0x10,%esp
f0103611:	66 83 f8 03          	cmp    $0x3,%ax
f0103615:	75 31                	jne    f0103648 <trap+0x78>
		// Trapped from user mode.
		assert(curenv);
f0103617:	a1 88 4f 17 f0       	mov    0xf0174f88,%eax
f010361c:	85 c0                	test   %eax,%eax
f010361e:	75 19                	jne    f0103639 <trap+0x69>
f0103620:	68 2d 5a 10 f0       	push   $0xf0105a2d
f0103625:	68 e4 4c 10 f0       	push   $0xf0104ce4
f010362a:	68 ea 00 00 00       	push   $0xea
f010362f:	68 ed 59 10 f0       	push   $0xf01059ed
f0103634:	e8 67 ca ff ff       	call   f01000a0 <_panic>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103639:	b9 11 00 00 00       	mov    $0x11,%ecx
f010363e:	89 c7                	mov    %eax,%edi
f0103640:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103642:	8b 35 88 4f 17 f0    	mov    0xf0174f88,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103648:	89 35 a0 57 17 f0    	mov    %esi,0xf01757a0
static void
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	if (tf->tf_trapno == T_PGFLT) 
f010364e:	8b 46 28             	mov    0x28(%esi),%eax
f0103651:	83 f8 0e             	cmp    $0xe,%eax
f0103654:	75 0e                	jne    f0103664 <trap+0x94>
	{ //处理缺页异常
        page_fault_handler(tf);
f0103656:	83 ec 0c             	sub    $0xc,%esp
f0103659:	56                   	push   %esi
f010365a:	e8 13 ff ff ff       	call   f0103572 <page_fault_handler>
f010365f:	83 c4 10             	add    $0x10,%esp
f0103662:	eb 74                	jmp    f01036d8 <trap+0x108>
        return;
    }
	if (tf->tf_trapno == T_BRKPT) 
f0103664:	83 f8 03             	cmp    $0x3,%eax
f0103667:	75 0e                	jne    f0103677 <trap+0xa7>
	{ //处理断点异常
        monitor(tf);
f0103669:	83 ec 0c             	sub    $0xc,%esp
f010366c:	56                   	push   %esi
f010366d:	e8 2a d1 ff ff       	call   f010079c <monitor>
f0103672:	83 c4 10             	add    $0x10,%esp
f0103675:	eb 61                	jmp    f01036d8 <trap+0x108>
        return;
    }
	if(tf->tf_trapno == T_SYSCALL)
f0103677:	83 f8 30             	cmp    $0x30,%eax
f010367a:	75 21                	jne    f010369d <trap+0xcd>
	{   //处理系统调用
		//调用syscall函数，将返回值保存在eax寄存器中
		tf->tf_regs.reg_eax = syscall(
f010367c:	83 ec 08             	sub    $0x8,%esp
f010367f:	ff 76 04             	pushl  0x4(%esi)
f0103682:	ff 36                	pushl  (%esi)
f0103684:	ff 76 10             	pushl  0x10(%esi)
f0103687:	ff 76 18             	pushl  0x18(%esi)
f010368a:	ff 76 14             	pushl  0x14(%esi)
f010368d:	ff 76 1c             	pushl  0x1c(%esi)
f0103690:	e8 e8 00 00 00       	call   f010377d <syscall>
f0103695:	89 46 1c             	mov    %eax,0x1c(%esi)
f0103698:	83 c4 20             	add    $0x20,%esp
f010369b:	eb 3b                	jmp    f01036d8 <trap+0x108>
        tf->tf_regs.reg_edi,
        tf->tf_regs.reg_esi);
		return;
	}
	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f010369d:	83 ec 0c             	sub    $0xc,%esp
f01036a0:	56                   	push   %esi
f01036a1:	e8 59 fd ff ff       	call   f01033ff <print_trapframe>
	if (tf->tf_cs == GD_KT)
f01036a6:	83 c4 10             	add    $0x10,%esp
f01036a9:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f01036ae:	75 17                	jne    f01036c7 <trap+0xf7>
		panic("unhandled trap in kernel");
f01036b0:	83 ec 04             	sub    $0x4,%esp
f01036b3:	68 34 5a 10 f0       	push   $0xf0105a34
f01036b8:	68 d3 00 00 00       	push   $0xd3
f01036bd:	68 ed 59 10 f0       	push   $0xf01059ed
f01036c2:	e8 d9 c9 ff ff       	call   f01000a0 <_panic>
	else {
		env_destroy(curenv);
f01036c7:	83 ec 0c             	sub    $0xc,%esp
f01036ca:	ff 35 88 4f 17 f0    	pushl  0xf0174f88
f01036d0:	e8 d7 f7 ff ff       	call   f0102eac <env_destroy>
f01036d5:	83 c4 10             	add    $0x10,%esp

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f01036d8:	a1 88 4f 17 f0       	mov    0xf0174f88,%eax
f01036dd:	85 c0                	test   %eax,%eax
f01036df:	74 06                	je     f01036e7 <trap+0x117>
f01036e1:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f01036e5:	74 19                	je     f0103700 <trap+0x130>
f01036e7:	68 b4 5b 10 f0       	push   $0xf0105bb4
f01036ec:	68 e4 4c 10 f0       	push   $0xf0104ce4
f01036f1:	68 fc 00 00 00       	push   $0xfc
f01036f6:	68 ed 59 10 f0       	push   $0xf01059ed
f01036fb:	e8 a0 c9 ff ff       	call   f01000a0 <_panic>
	env_run(curenv);
f0103700:	83 ec 0c             	sub    $0xc,%esp
f0103703:	50                   	push   %eax
f0103704:	e8 f3 f7 ff ff       	call   f0102efc <env_run>
f0103709:	90                   	nop

f010370a <t_divide>:
.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
TRAPHANDLER_NOEC(t_divide, T_DIVIDE)   // 0
f010370a:	6a 00                	push   $0x0
f010370c:	6a 00                	push   $0x0
f010370e:	eb 5e                	jmp    f010376e <_alltraps>

f0103710 <t_debug>:
TRAPHANDLER_NOEC(t_debug, T_DEBUG)     // 1
f0103710:	6a 00                	push   $0x0
f0103712:	6a 01                	push   $0x1
f0103714:	eb 58                	jmp    f010376e <_alltraps>

f0103716 <t_nmi>:
TRAPHANDLER_NOEC(t_nmi, T_NMI)         // 2
f0103716:	6a 00                	push   $0x0
f0103718:	6a 02                	push   $0x2
f010371a:	eb 52                	jmp    f010376e <_alltraps>

f010371c <t_brkpt>:
TRAPHANDLER_NOEC(t_brkpt, T_BRKPT)     // 3
f010371c:	6a 00                	push   $0x0
f010371e:	6a 03                	push   $0x3
f0103720:	eb 4c                	jmp    f010376e <_alltraps>

f0103722 <t_oflow>:
TRAPHANDLER_NOEC(t_oflow, T_OFLOW)     // 4
f0103722:	6a 00                	push   $0x0
f0103724:	6a 04                	push   $0x4
f0103726:	eb 46                	jmp    f010376e <_alltraps>

f0103728 <t_bound>:
TRAPHANDLER_NOEC(t_bound, T_BOUND)     // 5
f0103728:	6a 00                	push   $0x0
f010372a:	6a 05                	push   $0x5
f010372c:	eb 40                	jmp    f010376e <_alltraps>

f010372e <t_illop>:
TRAPHANDLER_NOEC(t_illop, T_ILLOP)     // 6
f010372e:	6a 00                	push   $0x0
f0103730:	6a 06                	push   $0x6
f0103732:	eb 3a                	jmp    f010376e <_alltraps>

f0103734 <t_device>:
TRAPHANDLER_NOEC(t_device, T_DEVICE)   // 7
f0103734:	6a 00                	push   $0x0
f0103736:	6a 07                	push   $0x7
f0103738:	eb 34                	jmp    f010376e <_alltraps>

f010373a <t_dblflt>:
TRAPHANDLER(t_dblflt, T_DBLFLT)        // 8
f010373a:	6a 08                	push   $0x8
f010373c:	eb 30                	jmp    f010376e <_alltraps>

f010373e <t_tss>:
                                       // 9
TRAPHANDLER(t_tss, T_TSS)              // 10
f010373e:	6a 0a                	push   $0xa
f0103740:	eb 2c                	jmp    f010376e <_alltraps>

f0103742 <t_segnp>:
TRAPHANDLER(t_segnp, T_SEGNP)          // 11
f0103742:	6a 0b                	push   $0xb
f0103744:	eb 28                	jmp    f010376e <_alltraps>

f0103746 <t_stack>:
TRAPHANDLER(t_stack, T_STACK)          // 12
f0103746:	6a 0c                	push   $0xc
f0103748:	eb 24                	jmp    f010376e <_alltraps>

f010374a <t_gpflt>:
TRAPHANDLER(t_gpflt, T_GPFLT)          // 13
f010374a:	6a 0d                	push   $0xd
f010374c:	eb 20                	jmp    f010376e <_alltraps>

f010374e <t_pgflt>:
TRAPHANDLER(t_pgflt, T_PGFLT)          // 14
f010374e:	6a 0e                	push   $0xe
f0103750:	eb 1c                	jmp    f010376e <_alltraps>

f0103752 <t_fperr>:
                                       // 15
TRAPHANDLER_NOEC(t_fperr, T_FPERR)     // 16
f0103752:	6a 00                	push   $0x0
f0103754:	6a 10                	push   $0x10
f0103756:	eb 16                	jmp    f010376e <_alltraps>

f0103758 <t_align>:
TRAPHANDLER(t_align, T_ALIGN)          // 17
f0103758:	6a 11                	push   $0x11
f010375a:	eb 12                	jmp    f010376e <_alltraps>

f010375c <t_mchk>:
TRAPHANDLER_NOEC(t_mchk, T_MCHK)       // 18
f010375c:	6a 00                	push   $0x0
f010375e:	6a 12                	push   $0x12
f0103760:	eb 0c                	jmp    f010376e <_alltraps>

f0103762 <t_simderr>:
TRAPHANDLER_NOEC(t_simderr, T_SIMDERR) // 19
f0103762:	6a 00                	push   $0x0
f0103764:	6a 13                	push   $0x13
f0103766:	eb 06                	jmp    f010376e <_alltraps>

f0103768 <t_syscall>:
//...
TRAPHANDLER_NOEC(t_syscall, T_SYSCALL) // 48
f0103768:	6a 00                	push   $0x0
f010376a:	6a 30                	push   $0x30
f010376c:	eb 00                	jmp    f010376e <_alltraps>

f010376e <_alltraps>:
/*参考inc/trap.h，将寄存器压栈形成一个Trapframe的结构
 *寄存器tf_ss，tf_esp，tf_eflags，tf_cs，tf_eip，tf_err
 *在中断发生时由CPU压入。只需压栈剩下的寄存器
 */
_alltraps:
    pushl %ds
f010376e:	1e                   	push   %ds
    pushl %es
f010376f:	06                   	push   %es
    pushal //把AX,CX,DX,BX,SP,BP,SI,DI压栈
f0103770:	60                   	pusha  
	//加载GD_KD到ds和es
    pushl $GD_KD
f0103771:	6a 10                	push   $0x10
    popl %ds
f0103773:	1f                   	pop    %ds
    pushl $GD_KD
f0103774:	6a 10                	push   $0x10
    popl %es
f0103776:	07                   	pop    %es
    pushl %esp //压入trap()的参数tf，%esp指向Trapframe结构的起始地址
f0103777:	54                   	push   %esp
    call trap  //调用trap
f0103778:	e8 53 fe ff ff       	call   f01035d0 <trap>

f010377d <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f010377d:	55                   	push   %ebp
f010377e:	89 e5                	mov    %esp,%ebp
f0103780:	83 ec 18             	sub    $0x18,%esp
f0103783:	8b 45 08             	mov    0x8(%ebp),%eax
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.
	//panic("syscall not implemented");
	int32_t ret = 0;
	switch (syscallno) { 
f0103786:	83 f8 01             	cmp    $0x1,%eax
f0103789:	74 4b                	je     f01037d6 <syscall+0x59>
f010378b:	83 f8 01             	cmp    $0x1,%eax
f010378e:	72 13                	jb     f01037a3 <syscall+0x26>
f0103790:	83 f8 02             	cmp    $0x2,%eax
f0103793:	0f 84 a9 00 00 00    	je     f0103842 <syscall+0xc5>
f0103799:	83 f8 03             	cmp    $0x3,%eax
f010379c:	74 3f                	je     f01037dd <syscall+0x60>
f010379e:	e9 ae 00 00 00       	jmp    f0103851 <syscall+0xd4>
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	user_mem_assert(curenv, s, len, PTE_U); //对指针进行检查
f01037a3:	6a 04                	push   $0x4
f01037a5:	ff 75 10             	pushl  0x10(%ebp)
f01037a8:	ff 75 0c             	pushl  0xc(%ebp)
f01037ab:	ff 35 88 4f 17 f0    	pushl  0xf0174f88
f01037b1:	e8 de f0 ff ff       	call   f0102894 <user_mem_assert>
	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f01037b6:	83 c4 0c             	add    $0xc,%esp
f01037b9:	ff 75 0c             	pushl  0xc(%ebp)
f01037bc:	ff 75 10             	pushl  0x10(%ebp)
f01037bf:	68 30 5c 10 f0       	push   $0xf0105c30
f01037c4:	e8 fc f7 ff ff       	call   f0102fc5 <cprintf>
f01037c9:	83 c4 10             	add    $0x10,%esp
{
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.
	//panic("syscall not implemented");
	int32_t ret = 0;
f01037cc:	b8 00 00 00 00       	mov    $0x0,%eax
f01037d1:	e9 80 00 00 00       	jmp    f0103856 <syscall+0xd9>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f01037d6:	e8 da cc ff ff       	call   f01004b5 <cons_getc>
		case SYS_cputs:
			sys_cputs((const char*)a1, a2);
			break;
		case SYS_cgetc:
			ret = sys_cgetc();
			break;
f01037db:	eb 79                	jmp    f0103856 <syscall+0xd9>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f01037dd:	83 ec 04             	sub    $0x4,%esp
f01037e0:	6a 01                	push   $0x1
f01037e2:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01037e5:	50                   	push   %eax
f01037e6:	ff 75 0c             	pushl  0xc(%ebp)
f01037e9:	e8 76 f1 ff ff       	call   f0102964 <envid2env>
f01037ee:	83 c4 10             	add    $0x10,%esp
f01037f1:	85 c0                	test   %eax,%eax
f01037f3:	78 61                	js     f0103856 <syscall+0xd9>
		return r;
	if (e == curenv)
f01037f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01037f8:	8b 15 88 4f 17 f0    	mov    0xf0174f88,%edx
f01037fe:	39 d0                	cmp    %edx,%eax
f0103800:	75 15                	jne    f0103817 <syscall+0x9a>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f0103802:	83 ec 08             	sub    $0x8,%esp
f0103805:	ff 70 48             	pushl  0x48(%eax)
f0103808:	68 35 5c 10 f0       	push   $0xf0105c35
f010380d:	e8 b3 f7 ff ff       	call   f0102fc5 <cprintf>
f0103812:	83 c4 10             	add    $0x10,%esp
f0103815:	eb 16                	jmp    f010382d <syscall+0xb0>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f0103817:	83 ec 04             	sub    $0x4,%esp
f010381a:	ff 70 48             	pushl  0x48(%eax)
f010381d:	ff 72 48             	pushl  0x48(%edx)
f0103820:	68 50 5c 10 f0       	push   $0xf0105c50
f0103825:	e8 9b f7 ff ff       	call   f0102fc5 <cprintf>
f010382a:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f010382d:	83 ec 0c             	sub    $0xc,%esp
f0103830:	ff 75 f4             	pushl  -0xc(%ebp)
f0103833:	e8 74 f6 ff ff       	call   f0102eac <env_destroy>
f0103838:	83 c4 10             	add    $0x10,%esp
	return 0;
f010383b:	b8 00 00 00 00       	mov    $0x0,%eax
f0103840:	eb 14                	jmp    f0103856 <syscall+0xd9>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f0103842:	a1 88 4f 17 f0       	mov    0xf0174f88,%eax
			break;
		case SYS_env_destroy:
			ret = sys_env_destroy(a1);
			break;
		case SYS_getenvid:
			ret = sys_getenvid() >= 0;
f0103847:	8b 40 48             	mov    0x48(%eax),%eax
f010384a:	f7 d0                	not    %eax
f010384c:	c1 e8 1f             	shr    $0x1f,%eax
			break;
f010384f:	eb 05                	jmp    f0103856 <syscall+0xd9>
		default:
			return -E_NO_SYS;
f0103851:	b8 f9 ff ff ff       	mov    $0xfffffff9,%eax
	}
	return ret;
}
f0103856:	c9                   	leave  
f0103857:	c3                   	ret    

f0103858 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0103858:	55                   	push   %ebp
f0103859:	89 e5                	mov    %esp,%ebp
f010385b:	57                   	push   %edi
f010385c:	56                   	push   %esi
f010385d:	53                   	push   %ebx
f010385e:	83 ec 14             	sub    $0x14,%esp
f0103861:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103864:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0103867:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010386a:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f010386d:	8b 1a                	mov    (%edx),%ebx
f010386f:	8b 01                	mov    (%ecx),%eax
f0103871:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103874:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f010387b:	eb 7f                	jmp    f01038fc <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f010387d:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103880:	01 d8                	add    %ebx,%eax
f0103882:	89 c6                	mov    %eax,%esi
f0103884:	c1 ee 1f             	shr    $0x1f,%esi
f0103887:	01 c6                	add    %eax,%esi
f0103889:	d1 fe                	sar    %esi
f010388b:	8d 04 76             	lea    (%esi,%esi,2),%eax
f010388e:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103891:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0103894:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103896:	eb 03                	jmp    f010389b <stab_binsearch+0x43>
			m--;
f0103898:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010389b:	39 c3                	cmp    %eax,%ebx
f010389d:	7f 0d                	jg     f01038ac <stab_binsearch+0x54>
f010389f:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01038a3:	83 ea 0c             	sub    $0xc,%edx
f01038a6:	39 f9                	cmp    %edi,%ecx
f01038a8:	75 ee                	jne    f0103898 <stab_binsearch+0x40>
f01038aa:	eb 05                	jmp    f01038b1 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01038ac:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01038af:	eb 4b                	jmp    f01038fc <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01038b1:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01038b4:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01038b7:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01038bb:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01038be:	76 11                	jbe    f01038d1 <stab_binsearch+0x79>
			*region_left = m;
f01038c0:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01038c3:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01038c5:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01038c8:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01038cf:	eb 2b                	jmp    f01038fc <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01038d1:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01038d4:	73 14                	jae    f01038ea <stab_binsearch+0x92>
			*region_right = m - 1;
f01038d6:	83 e8 01             	sub    $0x1,%eax
f01038d9:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01038dc:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01038df:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01038e1:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01038e8:	eb 12                	jmp    f01038fc <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01038ea:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01038ed:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01038ef:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01038f3:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01038f5:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01038fc:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01038ff:	0f 8e 78 ff ff ff    	jle    f010387d <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0103905:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0103909:	75 0f                	jne    f010391a <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f010390b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010390e:	8b 00                	mov    (%eax),%eax
f0103910:	83 e8 01             	sub    $0x1,%eax
f0103913:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103916:	89 06                	mov    %eax,(%esi)
f0103918:	eb 2c                	jmp    f0103946 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010391a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010391d:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f010391f:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103922:	8b 0e                	mov    (%esi),%ecx
f0103924:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103927:	8b 75 ec             	mov    -0x14(%ebp),%esi
f010392a:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010392d:	eb 03                	jmp    f0103932 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f010392f:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103932:	39 c8                	cmp    %ecx,%eax
f0103934:	7e 0b                	jle    f0103941 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0103936:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f010393a:	83 ea 0c             	sub    $0xc,%edx
f010393d:	39 df                	cmp    %ebx,%edi
f010393f:	75 ee                	jne    f010392f <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0103941:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103944:	89 06                	mov    %eax,(%esi)
	}
}
f0103946:	83 c4 14             	add    $0x14,%esp
f0103949:	5b                   	pop    %ebx
f010394a:	5e                   	pop    %esi
f010394b:	5f                   	pop    %edi
f010394c:	5d                   	pop    %ebp
f010394d:	c3                   	ret    

f010394e <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f010394e:	55                   	push   %ebp
f010394f:	89 e5                	mov    %esp,%ebp
f0103951:	57                   	push   %edi
f0103952:	56                   	push   %esi
f0103953:	53                   	push   %ebx
f0103954:	83 ec 2c             	sub    $0x2c,%esp
f0103957:	8b 7d 08             	mov    0x8(%ebp),%edi
f010395a:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f010395d:	c7 06 68 5c 10 f0    	movl   $0xf0105c68,(%esi)
	info->eip_line = 0;
f0103963:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f010396a:	c7 46 08 68 5c 10 f0 	movl   $0xf0105c68,0x8(%esi)
	info->eip_fn_namelen = 9;
f0103971:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0103978:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f010397b:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0103982:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0103988:	0f 87 8a 00 00 00    	ja     f0103a18 <debuginfo_eip+0xca>
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (void *)usd, sizeof(struct UserStabData), PTE_U) != 0) 
f010398e:	6a 04                	push   $0x4
f0103990:	6a 10                	push   $0x10
f0103992:	68 00 00 20 00       	push   $0x200000
f0103997:	ff 35 88 4f 17 f0    	pushl  0xf0174f88
f010399d:	e8 64 ee ff ff       	call   f0102806 <user_mem_check>
f01039a2:	83 c4 10             	add    $0x10,%esp
f01039a5:	85 c0                	test   %eax,%eax
f01039a7:	0f 85 c3 01 00 00    	jne    f0103b70 <debuginfo_eip+0x222>
		{
            return -1;
        }
		stabs = usd->stabs;
f01039ad:	a1 00 00 20 00       	mov    0x200000,%eax
f01039b2:	89 c1                	mov    %eax,%ecx
f01039b4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		stab_end = usd->stab_end;
f01039b7:	8b 1d 04 00 20 00    	mov    0x200004,%ebx
		stabstr = usd->stabstr;
f01039bd:	a1 08 00 20 00       	mov    0x200008,%eax
f01039c2:	89 45 cc             	mov    %eax,-0x34(%ebp)
		stabstr_end = usd->stabstr_end;
f01039c5:	8b 15 0c 00 20 00    	mov    0x20000c,%edx
f01039cb:	89 55 d0             	mov    %edx,-0x30(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (void *)stabs,stab_end - stabs, PTE_U) != 0) 
f01039ce:	6a 04                	push   $0x4
f01039d0:	89 d8                	mov    %ebx,%eax
f01039d2:	29 c8                	sub    %ecx,%eax
f01039d4:	c1 f8 02             	sar    $0x2,%eax
f01039d7:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f01039dd:	50                   	push   %eax
f01039de:	51                   	push   %ecx
f01039df:	ff 35 88 4f 17 f0    	pushl  0xf0174f88
f01039e5:	e8 1c ee ff ff       	call   f0102806 <user_mem_check>
f01039ea:	83 c4 10             	add    $0x10,%esp
f01039ed:	85 c0                	test   %eax,%eax
f01039ef:	0f 85 82 01 00 00    	jne    f0103b77 <debuginfo_eip+0x229>
		{
            return -1;
        }
		if (user_mem_check(curenv, (void *)stabstr, stabstr_end - stabstr, PTE_U) != 0) 
f01039f5:	6a 04                	push   $0x4
f01039f7:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01039fa:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f01039fd:	29 ca                	sub    %ecx,%edx
f01039ff:	52                   	push   %edx
f0103a00:	51                   	push   %ecx
f0103a01:	ff 35 88 4f 17 f0    	pushl  0xf0174f88
f0103a07:	e8 fa ed ff ff       	call   f0102806 <user_mem_check>
f0103a0c:	83 c4 10             	add    $0x10,%esp
f0103a0f:	85 c0                	test   %eax,%eax
f0103a11:	74 1f                	je     f0103a32 <debuginfo_eip+0xe4>
f0103a13:	e9 66 01 00 00       	jmp    f0103b7e <debuginfo_eip+0x230>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0103a18:	c7 45 d0 0f 02 11 f0 	movl   $0xf011020f,-0x30(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0103a1f:	c7 45 cc b1 d7 10 f0 	movl   $0xf010d7b1,-0x34(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0103a26:	bb b0 d7 10 f0       	mov    $0xf010d7b0,%ebx
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0103a2b:	c7 45 d4 90 5e 10 f0 	movl   $0xf0105e90,-0x2c(%ebp)
            return -1;
        }
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103a32:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103a35:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0103a38:	0f 83 47 01 00 00    	jae    f0103b85 <debuginfo_eip+0x237>
f0103a3e:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0103a42:	0f 85 44 01 00 00    	jne    f0103b8c <debuginfo_eip+0x23e>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103a48:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0103a4f:	2b 5d d4             	sub    -0x2c(%ebp),%ebx
f0103a52:	c1 fb 02             	sar    $0x2,%ebx
f0103a55:	69 c3 ab aa aa aa    	imul   $0xaaaaaaab,%ebx,%eax
f0103a5b:	83 e8 01             	sub    $0x1,%eax
f0103a5e:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0103a61:	83 ec 08             	sub    $0x8,%esp
f0103a64:	57                   	push   %edi
f0103a65:	6a 64                	push   $0x64
f0103a67:	8d 55 e0             	lea    -0x20(%ebp),%edx
f0103a6a:	89 d1                	mov    %edx,%ecx
f0103a6c:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0103a6f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103a72:	89 d8                	mov    %ebx,%eax
f0103a74:	e8 df fd ff ff       	call   f0103858 <stab_binsearch>
	if (lfile == 0)
f0103a79:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103a7c:	83 c4 10             	add    $0x10,%esp
f0103a7f:	85 c0                	test   %eax,%eax
f0103a81:	0f 84 0c 01 00 00    	je     f0103b93 <debuginfo_eip+0x245>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0103a87:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0103a8a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103a8d:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0103a90:	83 ec 08             	sub    $0x8,%esp
f0103a93:	57                   	push   %edi
f0103a94:	6a 24                	push   $0x24
f0103a96:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0103a99:	89 d1                	mov    %edx,%ecx
f0103a9b:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0103a9e:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
f0103aa1:	89 d8                	mov    %ebx,%eax
f0103aa3:	e8 b0 fd ff ff       	call   f0103858 <stab_binsearch>

	if (lfun <= rfun) {
f0103aa8:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0103aab:	83 c4 10             	add    $0x10,%esp
f0103aae:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f0103ab1:	7f 24                	jg     f0103ad7 <debuginfo_eip+0x189>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103ab3:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0103ab6:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103ab9:	8d 14 87             	lea    (%edi,%eax,4),%edx
f0103abc:	8b 02                	mov    (%edx),%eax
f0103abe:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0103ac1:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0103ac4:	29 f9                	sub    %edi,%ecx
f0103ac6:	39 c8                	cmp    %ecx,%eax
f0103ac8:	73 05                	jae    f0103acf <debuginfo_eip+0x181>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0103aca:	01 f8                	add    %edi,%eax
f0103acc:	89 46 08             	mov    %eax,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0103acf:	8b 42 08             	mov    0x8(%edx),%eax
f0103ad2:	89 46 10             	mov    %eax,0x10(%esi)
f0103ad5:	eb 06                	jmp    f0103add <debuginfo_eip+0x18f>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0103ad7:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0103ada:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103add:	83 ec 08             	sub    $0x8,%esp
f0103ae0:	6a 3a                	push   $0x3a
f0103ae2:	ff 76 08             	pushl  0x8(%esi)
f0103ae5:	e8 30 08 00 00       	call   f010431a <strfind>
f0103aea:	2b 46 08             	sub    0x8(%esi),%eax
f0103aed:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103af0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103af3:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0103af6:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0103af9:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f0103afc:	83 c4 10             	add    $0x10,%esp
f0103aff:	eb 06                	jmp    f0103b07 <debuginfo_eip+0x1b9>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0103b01:	83 eb 01             	sub    $0x1,%ebx
f0103b04:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103b07:	39 fb                	cmp    %edi,%ebx
f0103b09:	7c 2d                	jl     f0103b38 <debuginfo_eip+0x1ea>
	       && stabs[lline].n_type != N_SOL
f0103b0b:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f0103b0f:	80 fa 84             	cmp    $0x84,%dl
f0103b12:	74 0b                	je     f0103b1f <debuginfo_eip+0x1d1>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103b14:	80 fa 64             	cmp    $0x64,%dl
f0103b17:	75 e8                	jne    f0103b01 <debuginfo_eip+0x1b3>
f0103b19:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0103b1d:	74 e2                	je     f0103b01 <debuginfo_eip+0x1b3>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103b1f:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0103b22:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103b25:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0103b28:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103b2b:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0103b2e:	29 f8                	sub    %edi,%eax
f0103b30:	39 c2                	cmp    %eax,%edx
f0103b32:	73 04                	jae    f0103b38 <debuginfo_eip+0x1ea>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103b34:	01 fa                	add    %edi,%edx
f0103b36:	89 16                	mov    %edx,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103b38:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0103b3b:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103b3e:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103b43:	39 cb                	cmp    %ecx,%ebx
f0103b45:	7d 58                	jge    f0103b9f <debuginfo_eip+0x251>
		for (lline = lfun + 1;
f0103b47:	8d 53 01             	lea    0x1(%ebx),%edx
f0103b4a:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0103b4d:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103b50:	8d 04 87             	lea    (%edi,%eax,4),%eax
f0103b53:	eb 07                	jmp    f0103b5c <debuginfo_eip+0x20e>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0103b55:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0103b59:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0103b5c:	39 ca                	cmp    %ecx,%edx
f0103b5e:	74 3a                	je     f0103b9a <debuginfo_eip+0x24c>
f0103b60:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103b63:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f0103b67:	74 ec                	je     f0103b55 <debuginfo_eip+0x207>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103b69:	b8 00 00 00 00       	mov    $0x0,%eax
f0103b6e:	eb 2f                	jmp    f0103b9f <debuginfo_eip+0x251>
		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (void *)usd, sizeof(struct UserStabData), PTE_U) != 0) 
		{
            return -1;
f0103b70:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103b75:	eb 28                	jmp    f0103b9f <debuginfo_eip+0x251>

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (void *)stabs,stab_end - stabs, PTE_U) != 0) 
		{
            return -1;
f0103b77:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103b7c:	eb 21                	jmp    f0103b9f <debuginfo_eip+0x251>
        }
		if (user_mem_check(curenv, (void *)stabstr, stabstr_end - stabstr, PTE_U) != 0) 
		{
            return -1;
f0103b7e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103b83:	eb 1a                	jmp    f0103b9f <debuginfo_eip+0x251>
        }
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0103b85:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103b8a:	eb 13                	jmp    f0103b9f <debuginfo_eip+0x251>
f0103b8c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103b91:	eb 0c                	jmp    f0103b9f <debuginfo_eip+0x251>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0103b93:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103b98:	eb 05                	jmp    f0103b9f <debuginfo_eip+0x251>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103b9a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103b9f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103ba2:	5b                   	pop    %ebx
f0103ba3:	5e                   	pop    %esi
f0103ba4:	5f                   	pop    %edi
f0103ba5:	5d                   	pop    %ebp
f0103ba6:	c3                   	ret    

f0103ba7 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103ba7:	55                   	push   %ebp
f0103ba8:	89 e5                	mov    %esp,%ebp
f0103baa:	57                   	push   %edi
f0103bab:	56                   	push   %esi
f0103bac:	53                   	push   %ebx
f0103bad:	83 ec 1c             	sub    $0x1c,%esp
f0103bb0:	89 c7                	mov    %eax,%edi
f0103bb2:	89 d6                	mov    %edx,%esi
f0103bb4:	8b 45 08             	mov    0x8(%ebp),%eax
f0103bb7:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103bba:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103bbd:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103bc0:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103bc3:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103bc8:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103bcb:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0103bce:	39 d3                	cmp    %edx,%ebx
f0103bd0:	72 05                	jb     f0103bd7 <printnum+0x30>
f0103bd2:	39 45 10             	cmp    %eax,0x10(%ebp)
f0103bd5:	77 45                	ja     f0103c1c <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103bd7:	83 ec 0c             	sub    $0xc,%esp
f0103bda:	ff 75 18             	pushl  0x18(%ebp)
f0103bdd:	8b 45 14             	mov    0x14(%ebp),%eax
f0103be0:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0103be3:	53                   	push   %ebx
f0103be4:	ff 75 10             	pushl  0x10(%ebp)
f0103be7:	83 ec 08             	sub    $0x8,%esp
f0103bea:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103bed:	ff 75 e0             	pushl  -0x20(%ebp)
f0103bf0:	ff 75 dc             	pushl  -0x24(%ebp)
f0103bf3:	ff 75 d8             	pushl  -0x28(%ebp)
f0103bf6:	e8 45 09 00 00       	call   f0104540 <__udivdi3>
f0103bfb:	83 c4 18             	add    $0x18,%esp
f0103bfe:	52                   	push   %edx
f0103bff:	50                   	push   %eax
f0103c00:	89 f2                	mov    %esi,%edx
f0103c02:	89 f8                	mov    %edi,%eax
f0103c04:	e8 9e ff ff ff       	call   f0103ba7 <printnum>
f0103c09:	83 c4 20             	add    $0x20,%esp
f0103c0c:	eb 18                	jmp    f0103c26 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103c0e:	83 ec 08             	sub    $0x8,%esp
f0103c11:	56                   	push   %esi
f0103c12:	ff 75 18             	pushl  0x18(%ebp)
f0103c15:	ff d7                	call   *%edi
f0103c17:	83 c4 10             	add    $0x10,%esp
f0103c1a:	eb 03                	jmp    f0103c1f <printnum+0x78>
f0103c1c:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103c1f:	83 eb 01             	sub    $0x1,%ebx
f0103c22:	85 db                	test   %ebx,%ebx
f0103c24:	7f e8                	jg     f0103c0e <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103c26:	83 ec 08             	sub    $0x8,%esp
f0103c29:	56                   	push   %esi
f0103c2a:	83 ec 04             	sub    $0x4,%esp
f0103c2d:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103c30:	ff 75 e0             	pushl  -0x20(%ebp)
f0103c33:	ff 75 dc             	pushl  -0x24(%ebp)
f0103c36:	ff 75 d8             	pushl  -0x28(%ebp)
f0103c39:	e8 32 0a 00 00       	call   f0104670 <__umoddi3>
f0103c3e:	83 c4 14             	add    $0x14,%esp
f0103c41:	0f be 80 72 5c 10 f0 	movsbl -0xfefa38e(%eax),%eax
f0103c48:	50                   	push   %eax
f0103c49:	ff d7                	call   *%edi
}
f0103c4b:	83 c4 10             	add    $0x10,%esp
f0103c4e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103c51:	5b                   	pop    %ebx
f0103c52:	5e                   	pop    %esi
f0103c53:	5f                   	pop    %edi
f0103c54:	5d                   	pop    %ebp
f0103c55:	c3                   	ret    

f0103c56 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0103c56:	55                   	push   %ebp
f0103c57:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0103c59:	83 fa 01             	cmp    $0x1,%edx
f0103c5c:	7e 0e                	jle    f0103c6c <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0103c5e:	8b 10                	mov    (%eax),%edx
f0103c60:	8d 4a 08             	lea    0x8(%edx),%ecx
f0103c63:	89 08                	mov    %ecx,(%eax)
f0103c65:	8b 02                	mov    (%edx),%eax
f0103c67:	8b 52 04             	mov    0x4(%edx),%edx
f0103c6a:	eb 22                	jmp    f0103c8e <getuint+0x38>
	else if (lflag)
f0103c6c:	85 d2                	test   %edx,%edx
f0103c6e:	74 10                	je     f0103c80 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0103c70:	8b 10                	mov    (%eax),%edx
f0103c72:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103c75:	89 08                	mov    %ecx,(%eax)
f0103c77:	8b 02                	mov    (%edx),%eax
f0103c79:	ba 00 00 00 00       	mov    $0x0,%edx
f0103c7e:	eb 0e                	jmp    f0103c8e <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0103c80:	8b 10                	mov    (%eax),%edx
f0103c82:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103c85:	89 08                	mov    %ecx,(%eax)
f0103c87:	8b 02                	mov    (%edx),%eax
f0103c89:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0103c8e:	5d                   	pop    %ebp
f0103c8f:	c3                   	ret    

f0103c90 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103c90:	55                   	push   %ebp
f0103c91:	89 e5                	mov    %esp,%ebp
f0103c93:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103c96:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103c9a:	8b 10                	mov    (%eax),%edx
f0103c9c:	3b 50 04             	cmp    0x4(%eax),%edx
f0103c9f:	73 0a                	jae    f0103cab <sprintputch+0x1b>
		*b->buf++ = ch;
f0103ca1:	8d 4a 01             	lea    0x1(%edx),%ecx
f0103ca4:	89 08                	mov    %ecx,(%eax)
f0103ca6:	8b 45 08             	mov    0x8(%ebp),%eax
f0103ca9:	88 02                	mov    %al,(%edx)
}
f0103cab:	5d                   	pop    %ebp
f0103cac:	c3                   	ret    

f0103cad <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103cad:	55                   	push   %ebp
f0103cae:	89 e5                	mov    %esp,%ebp
f0103cb0:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0103cb3:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103cb6:	50                   	push   %eax
f0103cb7:	ff 75 10             	pushl  0x10(%ebp)
f0103cba:	ff 75 0c             	pushl  0xc(%ebp)
f0103cbd:	ff 75 08             	pushl  0x8(%ebp)
f0103cc0:	e8 05 00 00 00       	call   f0103cca <vprintfmt>
	va_end(ap);
}
f0103cc5:	83 c4 10             	add    $0x10,%esp
f0103cc8:	c9                   	leave  
f0103cc9:	c3                   	ret    

f0103cca <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0103cca:	55                   	push   %ebp
f0103ccb:	89 e5                	mov    %esp,%ebp
f0103ccd:	57                   	push   %edi
f0103cce:	56                   	push   %esi
f0103ccf:	53                   	push   %ebx
f0103cd0:	83 ec 2c             	sub    $0x2c,%esp
f0103cd3:	8b 75 08             	mov    0x8(%ebp),%esi
f0103cd6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103cd9:	8b 7d 10             	mov    0x10(%ebp),%edi
f0103cdc:	eb 12                	jmp    f0103cf0 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0103cde:	85 c0                	test   %eax,%eax
f0103ce0:	0f 84 89 03 00 00    	je     f010406f <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0103ce6:	83 ec 08             	sub    $0x8,%esp
f0103ce9:	53                   	push   %ebx
f0103cea:	50                   	push   %eax
f0103ceb:	ff d6                	call   *%esi
f0103ced:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103cf0:	83 c7 01             	add    $0x1,%edi
f0103cf3:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103cf7:	83 f8 25             	cmp    $0x25,%eax
f0103cfa:	75 e2                	jne    f0103cde <vprintfmt+0x14>
f0103cfc:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0103d00:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0103d07:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103d0e:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0103d15:	ba 00 00 00 00       	mov    $0x0,%edx
f0103d1a:	eb 07                	jmp    f0103d23 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d1c:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0103d1f:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d23:	8d 47 01             	lea    0x1(%edi),%eax
f0103d26:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103d29:	0f b6 07             	movzbl (%edi),%eax
f0103d2c:	0f b6 c8             	movzbl %al,%ecx
f0103d2f:	83 e8 23             	sub    $0x23,%eax
f0103d32:	3c 55                	cmp    $0x55,%al
f0103d34:	0f 87 1a 03 00 00    	ja     f0104054 <vprintfmt+0x38a>
f0103d3a:	0f b6 c0             	movzbl %al,%eax
f0103d3d:	ff 24 85 00 5d 10 f0 	jmp    *-0xfefa300(,%eax,4)
f0103d44:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0103d47:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0103d4b:	eb d6                	jmp    f0103d23 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d4d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103d50:	b8 00 00 00 00       	mov    $0x0,%eax
f0103d55:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0103d58:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0103d5b:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0103d5f:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0103d62:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0103d65:	83 fa 09             	cmp    $0x9,%edx
f0103d68:	77 39                	ja     f0103da3 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0103d6a:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0103d6d:	eb e9                	jmp    f0103d58 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0103d6f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d72:	8d 48 04             	lea    0x4(%eax),%ecx
f0103d75:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0103d78:	8b 00                	mov    (%eax),%eax
f0103d7a:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d7d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103d80:	eb 27                	jmp    f0103da9 <vprintfmt+0xdf>
f0103d82:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103d85:	85 c0                	test   %eax,%eax
f0103d87:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103d8c:	0f 49 c8             	cmovns %eax,%ecx
f0103d8f:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d92:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103d95:	eb 8c                	jmp    f0103d23 <vprintfmt+0x59>
f0103d97:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0103d9a:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0103da1:	eb 80                	jmp    f0103d23 <vprintfmt+0x59>
f0103da3:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0103da6:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0103da9:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103dad:	0f 89 70 ff ff ff    	jns    f0103d23 <vprintfmt+0x59>
				width = precision, precision = -1;
f0103db3:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103db6:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103db9:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103dc0:	e9 5e ff ff ff       	jmp    f0103d23 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103dc5:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103dc8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0103dcb:	e9 53 ff ff ff       	jmp    f0103d23 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103dd0:	8b 45 14             	mov    0x14(%ebp),%eax
f0103dd3:	8d 50 04             	lea    0x4(%eax),%edx
f0103dd6:	89 55 14             	mov    %edx,0x14(%ebp)
f0103dd9:	83 ec 08             	sub    $0x8,%esp
f0103ddc:	53                   	push   %ebx
f0103ddd:	ff 30                	pushl  (%eax)
f0103ddf:	ff d6                	call   *%esi
			break;
f0103de1:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103de4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0103de7:	e9 04 ff ff ff       	jmp    f0103cf0 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103dec:	8b 45 14             	mov    0x14(%ebp),%eax
f0103def:	8d 50 04             	lea    0x4(%eax),%edx
f0103df2:	89 55 14             	mov    %edx,0x14(%ebp)
f0103df5:	8b 00                	mov    (%eax),%eax
f0103df7:	99                   	cltd   
f0103df8:	31 d0                	xor    %edx,%eax
f0103dfa:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103dfc:	83 f8 07             	cmp    $0x7,%eax
f0103dff:	7f 0b                	jg     f0103e0c <vprintfmt+0x142>
f0103e01:	8b 14 85 60 5e 10 f0 	mov    -0xfefa1a0(,%eax,4),%edx
f0103e08:	85 d2                	test   %edx,%edx
f0103e0a:	75 18                	jne    f0103e24 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0103e0c:	50                   	push   %eax
f0103e0d:	68 8a 5c 10 f0       	push   $0xf0105c8a
f0103e12:	53                   	push   %ebx
f0103e13:	56                   	push   %esi
f0103e14:	e8 94 fe ff ff       	call   f0103cad <printfmt>
f0103e19:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103e1c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0103e1f:	e9 cc fe ff ff       	jmp    f0103cf0 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0103e24:	52                   	push   %edx
f0103e25:	68 f6 4c 10 f0       	push   $0xf0104cf6
f0103e2a:	53                   	push   %ebx
f0103e2b:	56                   	push   %esi
f0103e2c:	e8 7c fe ff ff       	call   f0103cad <printfmt>
f0103e31:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103e34:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103e37:	e9 b4 fe ff ff       	jmp    f0103cf0 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103e3c:	8b 45 14             	mov    0x14(%ebp),%eax
f0103e3f:	8d 50 04             	lea    0x4(%eax),%edx
f0103e42:	89 55 14             	mov    %edx,0x14(%ebp)
f0103e45:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0103e47:	85 ff                	test   %edi,%edi
f0103e49:	b8 83 5c 10 f0       	mov    $0xf0105c83,%eax
f0103e4e:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0103e51:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103e55:	0f 8e 94 00 00 00    	jle    f0103eef <vprintfmt+0x225>
f0103e5b:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0103e5f:	0f 84 98 00 00 00    	je     f0103efd <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0103e65:	83 ec 08             	sub    $0x8,%esp
f0103e68:	ff 75 d0             	pushl  -0x30(%ebp)
f0103e6b:	57                   	push   %edi
f0103e6c:	e8 5f 03 00 00       	call   f01041d0 <strnlen>
f0103e71:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103e74:	29 c1                	sub    %eax,%ecx
f0103e76:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0103e79:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0103e7c:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0103e80:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103e83:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103e86:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103e88:	eb 0f                	jmp    f0103e99 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0103e8a:	83 ec 08             	sub    $0x8,%esp
f0103e8d:	53                   	push   %ebx
f0103e8e:	ff 75 e0             	pushl  -0x20(%ebp)
f0103e91:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103e93:	83 ef 01             	sub    $0x1,%edi
f0103e96:	83 c4 10             	add    $0x10,%esp
f0103e99:	85 ff                	test   %edi,%edi
f0103e9b:	7f ed                	jg     f0103e8a <vprintfmt+0x1c0>
f0103e9d:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103ea0:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0103ea3:	85 c9                	test   %ecx,%ecx
f0103ea5:	b8 00 00 00 00       	mov    $0x0,%eax
f0103eaa:	0f 49 c1             	cmovns %ecx,%eax
f0103ead:	29 c1                	sub    %eax,%ecx
f0103eaf:	89 75 08             	mov    %esi,0x8(%ebp)
f0103eb2:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103eb5:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103eb8:	89 cb                	mov    %ecx,%ebx
f0103eba:	eb 4d                	jmp    f0103f09 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103ebc:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0103ec0:	74 1b                	je     f0103edd <vprintfmt+0x213>
f0103ec2:	0f be c0             	movsbl %al,%eax
f0103ec5:	83 e8 20             	sub    $0x20,%eax
f0103ec8:	83 f8 5e             	cmp    $0x5e,%eax
f0103ecb:	76 10                	jbe    f0103edd <vprintfmt+0x213>
					putch('?', putdat);
f0103ecd:	83 ec 08             	sub    $0x8,%esp
f0103ed0:	ff 75 0c             	pushl  0xc(%ebp)
f0103ed3:	6a 3f                	push   $0x3f
f0103ed5:	ff 55 08             	call   *0x8(%ebp)
f0103ed8:	83 c4 10             	add    $0x10,%esp
f0103edb:	eb 0d                	jmp    f0103eea <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0103edd:	83 ec 08             	sub    $0x8,%esp
f0103ee0:	ff 75 0c             	pushl  0xc(%ebp)
f0103ee3:	52                   	push   %edx
f0103ee4:	ff 55 08             	call   *0x8(%ebp)
f0103ee7:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103eea:	83 eb 01             	sub    $0x1,%ebx
f0103eed:	eb 1a                	jmp    f0103f09 <vprintfmt+0x23f>
f0103eef:	89 75 08             	mov    %esi,0x8(%ebp)
f0103ef2:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103ef5:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103ef8:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103efb:	eb 0c                	jmp    f0103f09 <vprintfmt+0x23f>
f0103efd:	89 75 08             	mov    %esi,0x8(%ebp)
f0103f00:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103f03:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103f06:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103f09:	83 c7 01             	add    $0x1,%edi
f0103f0c:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103f10:	0f be d0             	movsbl %al,%edx
f0103f13:	85 d2                	test   %edx,%edx
f0103f15:	74 23                	je     f0103f3a <vprintfmt+0x270>
f0103f17:	85 f6                	test   %esi,%esi
f0103f19:	78 a1                	js     f0103ebc <vprintfmt+0x1f2>
f0103f1b:	83 ee 01             	sub    $0x1,%esi
f0103f1e:	79 9c                	jns    f0103ebc <vprintfmt+0x1f2>
f0103f20:	89 df                	mov    %ebx,%edi
f0103f22:	8b 75 08             	mov    0x8(%ebp),%esi
f0103f25:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103f28:	eb 18                	jmp    f0103f42 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0103f2a:	83 ec 08             	sub    $0x8,%esp
f0103f2d:	53                   	push   %ebx
f0103f2e:	6a 20                	push   $0x20
f0103f30:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103f32:	83 ef 01             	sub    $0x1,%edi
f0103f35:	83 c4 10             	add    $0x10,%esp
f0103f38:	eb 08                	jmp    f0103f42 <vprintfmt+0x278>
f0103f3a:	89 df                	mov    %ebx,%edi
f0103f3c:	8b 75 08             	mov    0x8(%ebp),%esi
f0103f3f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103f42:	85 ff                	test   %edi,%edi
f0103f44:	7f e4                	jg     f0103f2a <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103f46:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103f49:	e9 a2 fd ff ff       	jmp    f0103cf0 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103f4e:	83 fa 01             	cmp    $0x1,%edx
f0103f51:	7e 16                	jle    f0103f69 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0103f53:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f56:	8d 50 08             	lea    0x8(%eax),%edx
f0103f59:	89 55 14             	mov    %edx,0x14(%ebp)
f0103f5c:	8b 50 04             	mov    0x4(%eax),%edx
f0103f5f:	8b 00                	mov    (%eax),%eax
f0103f61:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103f64:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103f67:	eb 32                	jmp    f0103f9b <vprintfmt+0x2d1>
	else if (lflag)
f0103f69:	85 d2                	test   %edx,%edx
f0103f6b:	74 18                	je     f0103f85 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0103f6d:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f70:	8d 50 04             	lea    0x4(%eax),%edx
f0103f73:	89 55 14             	mov    %edx,0x14(%ebp)
f0103f76:	8b 00                	mov    (%eax),%eax
f0103f78:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103f7b:	89 c1                	mov    %eax,%ecx
f0103f7d:	c1 f9 1f             	sar    $0x1f,%ecx
f0103f80:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0103f83:	eb 16                	jmp    f0103f9b <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0103f85:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f88:	8d 50 04             	lea    0x4(%eax),%edx
f0103f8b:	89 55 14             	mov    %edx,0x14(%ebp)
f0103f8e:	8b 00                	mov    (%eax),%eax
f0103f90:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103f93:	89 c1                	mov    %eax,%ecx
f0103f95:	c1 f9 1f             	sar    $0x1f,%ecx
f0103f98:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0103f9b:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103f9e:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0103fa1:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103fa6:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103faa:	79 74                	jns    f0104020 <vprintfmt+0x356>
				putch('-', putdat);
f0103fac:	83 ec 08             	sub    $0x8,%esp
f0103faf:	53                   	push   %ebx
f0103fb0:	6a 2d                	push   $0x2d
f0103fb2:	ff d6                	call   *%esi
				num = -(long long) num;
f0103fb4:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103fb7:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103fba:	f7 d8                	neg    %eax
f0103fbc:	83 d2 00             	adc    $0x0,%edx
f0103fbf:	f7 da                	neg    %edx
f0103fc1:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0103fc4:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0103fc9:	eb 55                	jmp    f0104020 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0103fcb:	8d 45 14             	lea    0x14(%ebp),%eax
f0103fce:	e8 83 fc ff ff       	call   f0103c56 <getuint>
			base = 10;
f0103fd3:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0103fd8:	eb 46                	jmp    f0104020 <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0103fda:	8d 45 14             	lea    0x14(%ebp),%eax
f0103fdd:	e8 74 fc ff ff       	call   f0103c56 <getuint>
           		base = 8;
f0103fe2:	b9 08 00 00 00       	mov    $0x8,%ecx
           		goto number;
f0103fe7:	eb 37                	jmp    f0104020 <vprintfmt+0x356>
			break;

		// pointer
		case 'p':
			putch('0', putdat);
f0103fe9:	83 ec 08             	sub    $0x8,%esp
f0103fec:	53                   	push   %ebx
f0103fed:	6a 30                	push   $0x30
f0103fef:	ff d6                	call   *%esi
			putch('x', putdat);
f0103ff1:	83 c4 08             	add    $0x8,%esp
f0103ff4:	53                   	push   %ebx
f0103ff5:	6a 78                	push   $0x78
f0103ff7:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0103ff9:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ffc:	8d 50 04             	lea    0x4(%eax),%edx
f0103fff:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0104002:	8b 00                	mov    (%eax),%eax
f0104004:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0104009:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010400c:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0104011:	eb 0d                	jmp    f0104020 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0104013:	8d 45 14             	lea    0x14(%ebp),%eax
f0104016:	e8 3b fc ff ff       	call   f0103c56 <getuint>
			base = 16;
f010401b:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0104020:	83 ec 0c             	sub    $0xc,%esp
f0104023:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0104027:	57                   	push   %edi
f0104028:	ff 75 e0             	pushl  -0x20(%ebp)
f010402b:	51                   	push   %ecx
f010402c:	52                   	push   %edx
f010402d:	50                   	push   %eax
f010402e:	89 da                	mov    %ebx,%edx
f0104030:	89 f0                	mov    %esi,%eax
f0104032:	e8 70 fb ff ff       	call   f0103ba7 <printnum>
			break;
f0104037:	83 c4 20             	add    $0x20,%esp
f010403a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010403d:	e9 ae fc ff ff       	jmp    f0103cf0 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0104042:	83 ec 08             	sub    $0x8,%esp
f0104045:	53                   	push   %ebx
f0104046:	51                   	push   %ecx
f0104047:	ff d6                	call   *%esi
			break;
f0104049:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010404c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f010404f:	e9 9c fc ff ff       	jmp    f0103cf0 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0104054:	83 ec 08             	sub    $0x8,%esp
f0104057:	53                   	push   %ebx
f0104058:	6a 25                	push   $0x25
f010405a:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f010405c:	83 c4 10             	add    $0x10,%esp
f010405f:	eb 03                	jmp    f0104064 <vprintfmt+0x39a>
f0104061:	83 ef 01             	sub    $0x1,%edi
f0104064:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0104068:	75 f7                	jne    f0104061 <vprintfmt+0x397>
f010406a:	e9 81 fc ff ff       	jmp    f0103cf0 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f010406f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104072:	5b                   	pop    %ebx
f0104073:	5e                   	pop    %esi
f0104074:	5f                   	pop    %edi
f0104075:	5d                   	pop    %ebp
f0104076:	c3                   	ret    

f0104077 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0104077:	55                   	push   %ebp
f0104078:	89 e5                	mov    %esp,%ebp
f010407a:	83 ec 18             	sub    $0x18,%esp
f010407d:	8b 45 08             	mov    0x8(%ebp),%eax
f0104080:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0104083:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104086:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010408a:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010408d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0104094:	85 c0                	test   %eax,%eax
f0104096:	74 26                	je     f01040be <vsnprintf+0x47>
f0104098:	85 d2                	test   %edx,%edx
f010409a:	7e 22                	jle    f01040be <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010409c:	ff 75 14             	pushl  0x14(%ebp)
f010409f:	ff 75 10             	pushl  0x10(%ebp)
f01040a2:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01040a5:	50                   	push   %eax
f01040a6:	68 90 3c 10 f0       	push   $0xf0103c90
f01040ab:	e8 1a fc ff ff       	call   f0103cca <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01040b0:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01040b3:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01040b6:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01040b9:	83 c4 10             	add    $0x10,%esp
f01040bc:	eb 05                	jmp    f01040c3 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01040be:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01040c3:	c9                   	leave  
f01040c4:	c3                   	ret    

f01040c5 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01040c5:	55                   	push   %ebp
f01040c6:	89 e5                	mov    %esp,%ebp
f01040c8:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01040cb:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01040ce:	50                   	push   %eax
f01040cf:	ff 75 10             	pushl  0x10(%ebp)
f01040d2:	ff 75 0c             	pushl  0xc(%ebp)
f01040d5:	ff 75 08             	pushl  0x8(%ebp)
f01040d8:	e8 9a ff ff ff       	call   f0104077 <vsnprintf>
	va_end(ap);

	return rc;
}
f01040dd:	c9                   	leave  
f01040de:	c3                   	ret    

f01040df <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01040df:	55                   	push   %ebp
f01040e0:	89 e5                	mov    %esp,%ebp
f01040e2:	57                   	push   %edi
f01040e3:	56                   	push   %esi
f01040e4:	53                   	push   %ebx
f01040e5:	83 ec 0c             	sub    $0xc,%esp
f01040e8:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01040eb:	85 c0                	test   %eax,%eax
f01040ed:	74 11                	je     f0104100 <readline+0x21>
		cprintf("%s", prompt);
f01040ef:	83 ec 08             	sub    $0x8,%esp
f01040f2:	50                   	push   %eax
f01040f3:	68 f6 4c 10 f0       	push   $0xf0104cf6
f01040f8:	e8 c8 ee ff ff       	call   f0102fc5 <cprintf>
f01040fd:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0104100:	83 ec 0c             	sub    $0xc,%esp
f0104103:	6a 00                	push   $0x0
f0104105:	e8 1e c5 ff ff       	call   f0100628 <iscons>
f010410a:	89 c7                	mov    %eax,%edi
f010410c:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010410f:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0104114:	e8 fe c4 ff ff       	call   f0100617 <getchar>
f0104119:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010411b:	85 c0                	test   %eax,%eax
f010411d:	79 18                	jns    f0104137 <readline+0x58>
			cprintf("read error: %e\n", c);
f010411f:	83 ec 08             	sub    $0x8,%esp
f0104122:	50                   	push   %eax
f0104123:	68 80 5e 10 f0       	push   $0xf0105e80
f0104128:	e8 98 ee ff ff       	call   f0102fc5 <cprintf>
			return NULL;
f010412d:	83 c4 10             	add    $0x10,%esp
f0104130:	b8 00 00 00 00       	mov    $0x0,%eax
f0104135:	eb 79                	jmp    f01041b0 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0104137:	83 f8 08             	cmp    $0x8,%eax
f010413a:	0f 94 c2             	sete   %dl
f010413d:	83 f8 7f             	cmp    $0x7f,%eax
f0104140:	0f 94 c0             	sete   %al
f0104143:	08 c2                	or     %al,%dl
f0104145:	74 1a                	je     f0104161 <readline+0x82>
f0104147:	85 f6                	test   %esi,%esi
f0104149:	7e 16                	jle    f0104161 <readline+0x82>
			if (echoing)
f010414b:	85 ff                	test   %edi,%edi
f010414d:	74 0d                	je     f010415c <readline+0x7d>
				cputchar('\b');
f010414f:	83 ec 0c             	sub    $0xc,%esp
f0104152:	6a 08                	push   $0x8
f0104154:	e8 ae c4 ff ff       	call   f0100607 <cputchar>
f0104159:	83 c4 10             	add    $0x10,%esp
			i--;
f010415c:	83 ee 01             	sub    $0x1,%esi
f010415f:	eb b3                	jmp    f0104114 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0104161:	83 fb 1f             	cmp    $0x1f,%ebx
f0104164:	7e 23                	jle    f0104189 <readline+0xaa>
f0104166:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010416c:	7f 1b                	jg     f0104189 <readline+0xaa>
			if (echoing)
f010416e:	85 ff                	test   %edi,%edi
f0104170:	74 0c                	je     f010417e <readline+0x9f>
				cputchar(c);
f0104172:	83 ec 0c             	sub    $0xc,%esp
f0104175:	53                   	push   %ebx
f0104176:	e8 8c c4 ff ff       	call   f0100607 <cputchar>
f010417b:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f010417e:	88 9e 40 58 17 f0    	mov    %bl,-0xfe8a7c0(%esi)
f0104184:	8d 76 01             	lea    0x1(%esi),%esi
f0104187:	eb 8b                	jmp    f0104114 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0104189:	83 fb 0a             	cmp    $0xa,%ebx
f010418c:	74 05                	je     f0104193 <readline+0xb4>
f010418e:	83 fb 0d             	cmp    $0xd,%ebx
f0104191:	75 81                	jne    f0104114 <readline+0x35>
			if (echoing)
f0104193:	85 ff                	test   %edi,%edi
f0104195:	74 0d                	je     f01041a4 <readline+0xc5>
				cputchar('\n');
f0104197:	83 ec 0c             	sub    $0xc,%esp
f010419a:	6a 0a                	push   $0xa
f010419c:	e8 66 c4 ff ff       	call   f0100607 <cputchar>
f01041a1:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f01041a4:	c6 86 40 58 17 f0 00 	movb   $0x0,-0xfe8a7c0(%esi)
			return buf;
f01041ab:	b8 40 58 17 f0       	mov    $0xf0175840,%eax
		}
	}
}
f01041b0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01041b3:	5b                   	pop    %ebx
f01041b4:	5e                   	pop    %esi
f01041b5:	5f                   	pop    %edi
f01041b6:	5d                   	pop    %ebp
f01041b7:	c3                   	ret    

f01041b8 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01041b8:	55                   	push   %ebp
f01041b9:	89 e5                	mov    %esp,%ebp
f01041bb:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01041be:	b8 00 00 00 00       	mov    $0x0,%eax
f01041c3:	eb 03                	jmp    f01041c8 <strlen+0x10>
		n++;
f01041c5:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01041c8:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01041cc:	75 f7                	jne    f01041c5 <strlen+0xd>
		n++;
	return n;
}
f01041ce:	5d                   	pop    %ebp
f01041cf:	c3                   	ret    

f01041d0 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01041d0:	55                   	push   %ebp
f01041d1:	89 e5                	mov    %esp,%ebp
f01041d3:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01041d6:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01041d9:	ba 00 00 00 00       	mov    $0x0,%edx
f01041de:	eb 03                	jmp    f01041e3 <strnlen+0x13>
		n++;
f01041e0:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01041e3:	39 c2                	cmp    %eax,%edx
f01041e5:	74 08                	je     f01041ef <strnlen+0x1f>
f01041e7:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f01041eb:	75 f3                	jne    f01041e0 <strnlen+0x10>
f01041ed:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f01041ef:	5d                   	pop    %ebp
f01041f0:	c3                   	ret    

f01041f1 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01041f1:	55                   	push   %ebp
f01041f2:	89 e5                	mov    %esp,%ebp
f01041f4:	53                   	push   %ebx
f01041f5:	8b 45 08             	mov    0x8(%ebp),%eax
f01041f8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01041fb:	89 c2                	mov    %eax,%edx
f01041fd:	83 c2 01             	add    $0x1,%edx
f0104200:	83 c1 01             	add    $0x1,%ecx
f0104203:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0104207:	88 5a ff             	mov    %bl,-0x1(%edx)
f010420a:	84 db                	test   %bl,%bl
f010420c:	75 ef                	jne    f01041fd <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f010420e:	5b                   	pop    %ebx
f010420f:	5d                   	pop    %ebp
f0104210:	c3                   	ret    

f0104211 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0104211:	55                   	push   %ebp
f0104212:	89 e5                	mov    %esp,%ebp
f0104214:	53                   	push   %ebx
f0104215:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0104218:	53                   	push   %ebx
f0104219:	e8 9a ff ff ff       	call   f01041b8 <strlen>
f010421e:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0104221:	ff 75 0c             	pushl  0xc(%ebp)
f0104224:	01 d8                	add    %ebx,%eax
f0104226:	50                   	push   %eax
f0104227:	e8 c5 ff ff ff       	call   f01041f1 <strcpy>
	return dst;
}
f010422c:	89 d8                	mov    %ebx,%eax
f010422e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104231:	c9                   	leave  
f0104232:	c3                   	ret    

f0104233 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104233:	55                   	push   %ebp
f0104234:	89 e5                	mov    %esp,%ebp
f0104236:	56                   	push   %esi
f0104237:	53                   	push   %ebx
f0104238:	8b 75 08             	mov    0x8(%ebp),%esi
f010423b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010423e:	89 f3                	mov    %esi,%ebx
f0104240:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104243:	89 f2                	mov    %esi,%edx
f0104245:	eb 0f                	jmp    f0104256 <strncpy+0x23>
		*dst++ = *src;
f0104247:	83 c2 01             	add    $0x1,%edx
f010424a:	0f b6 01             	movzbl (%ecx),%eax
f010424d:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104250:	80 39 01             	cmpb   $0x1,(%ecx)
f0104253:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104256:	39 da                	cmp    %ebx,%edx
f0104258:	75 ed                	jne    f0104247 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f010425a:	89 f0                	mov    %esi,%eax
f010425c:	5b                   	pop    %ebx
f010425d:	5e                   	pop    %esi
f010425e:	5d                   	pop    %ebp
f010425f:	c3                   	ret    

f0104260 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0104260:	55                   	push   %ebp
f0104261:	89 e5                	mov    %esp,%ebp
f0104263:	56                   	push   %esi
f0104264:	53                   	push   %ebx
f0104265:	8b 75 08             	mov    0x8(%ebp),%esi
f0104268:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010426b:	8b 55 10             	mov    0x10(%ebp),%edx
f010426e:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104270:	85 d2                	test   %edx,%edx
f0104272:	74 21                	je     f0104295 <strlcpy+0x35>
f0104274:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0104278:	89 f2                	mov    %esi,%edx
f010427a:	eb 09                	jmp    f0104285 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010427c:	83 c2 01             	add    $0x1,%edx
f010427f:	83 c1 01             	add    $0x1,%ecx
f0104282:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0104285:	39 c2                	cmp    %eax,%edx
f0104287:	74 09                	je     f0104292 <strlcpy+0x32>
f0104289:	0f b6 19             	movzbl (%ecx),%ebx
f010428c:	84 db                	test   %bl,%bl
f010428e:	75 ec                	jne    f010427c <strlcpy+0x1c>
f0104290:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0104292:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0104295:	29 f0                	sub    %esi,%eax
}
f0104297:	5b                   	pop    %ebx
f0104298:	5e                   	pop    %esi
f0104299:	5d                   	pop    %ebp
f010429a:	c3                   	ret    

f010429b <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010429b:	55                   	push   %ebp
f010429c:	89 e5                	mov    %esp,%ebp
f010429e:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01042a1:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01042a4:	eb 06                	jmp    f01042ac <strcmp+0x11>
		p++, q++;
f01042a6:	83 c1 01             	add    $0x1,%ecx
f01042a9:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01042ac:	0f b6 01             	movzbl (%ecx),%eax
f01042af:	84 c0                	test   %al,%al
f01042b1:	74 04                	je     f01042b7 <strcmp+0x1c>
f01042b3:	3a 02                	cmp    (%edx),%al
f01042b5:	74 ef                	je     f01042a6 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01042b7:	0f b6 c0             	movzbl %al,%eax
f01042ba:	0f b6 12             	movzbl (%edx),%edx
f01042bd:	29 d0                	sub    %edx,%eax
}
f01042bf:	5d                   	pop    %ebp
f01042c0:	c3                   	ret    

f01042c1 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01042c1:	55                   	push   %ebp
f01042c2:	89 e5                	mov    %esp,%ebp
f01042c4:	53                   	push   %ebx
f01042c5:	8b 45 08             	mov    0x8(%ebp),%eax
f01042c8:	8b 55 0c             	mov    0xc(%ebp),%edx
f01042cb:	89 c3                	mov    %eax,%ebx
f01042cd:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01042d0:	eb 06                	jmp    f01042d8 <strncmp+0x17>
		n--, p++, q++;
f01042d2:	83 c0 01             	add    $0x1,%eax
f01042d5:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01042d8:	39 d8                	cmp    %ebx,%eax
f01042da:	74 15                	je     f01042f1 <strncmp+0x30>
f01042dc:	0f b6 08             	movzbl (%eax),%ecx
f01042df:	84 c9                	test   %cl,%cl
f01042e1:	74 04                	je     f01042e7 <strncmp+0x26>
f01042e3:	3a 0a                	cmp    (%edx),%cl
f01042e5:	74 eb                	je     f01042d2 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01042e7:	0f b6 00             	movzbl (%eax),%eax
f01042ea:	0f b6 12             	movzbl (%edx),%edx
f01042ed:	29 d0                	sub    %edx,%eax
f01042ef:	eb 05                	jmp    f01042f6 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01042f1:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01042f6:	5b                   	pop    %ebx
f01042f7:	5d                   	pop    %ebp
f01042f8:	c3                   	ret    

f01042f9 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01042f9:	55                   	push   %ebp
f01042fa:	89 e5                	mov    %esp,%ebp
f01042fc:	8b 45 08             	mov    0x8(%ebp),%eax
f01042ff:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104303:	eb 07                	jmp    f010430c <strchr+0x13>
		if (*s == c)
f0104305:	38 ca                	cmp    %cl,%dl
f0104307:	74 0f                	je     f0104318 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0104309:	83 c0 01             	add    $0x1,%eax
f010430c:	0f b6 10             	movzbl (%eax),%edx
f010430f:	84 d2                	test   %dl,%dl
f0104311:	75 f2                	jne    f0104305 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0104313:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104318:	5d                   	pop    %ebp
f0104319:	c3                   	ret    

f010431a <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010431a:	55                   	push   %ebp
f010431b:	89 e5                	mov    %esp,%ebp
f010431d:	8b 45 08             	mov    0x8(%ebp),%eax
f0104320:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104324:	eb 03                	jmp    f0104329 <strfind+0xf>
f0104326:	83 c0 01             	add    $0x1,%eax
f0104329:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f010432c:	38 ca                	cmp    %cl,%dl
f010432e:	74 04                	je     f0104334 <strfind+0x1a>
f0104330:	84 d2                	test   %dl,%dl
f0104332:	75 f2                	jne    f0104326 <strfind+0xc>
			break;
	return (char *) s;
}
f0104334:	5d                   	pop    %ebp
f0104335:	c3                   	ret    

f0104336 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0104336:	55                   	push   %ebp
f0104337:	89 e5                	mov    %esp,%ebp
f0104339:	57                   	push   %edi
f010433a:	56                   	push   %esi
f010433b:	53                   	push   %ebx
f010433c:	8b 7d 08             	mov    0x8(%ebp),%edi
f010433f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0104342:	85 c9                	test   %ecx,%ecx
f0104344:	74 36                	je     f010437c <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0104346:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010434c:	75 28                	jne    f0104376 <memset+0x40>
f010434e:	f6 c1 03             	test   $0x3,%cl
f0104351:	75 23                	jne    f0104376 <memset+0x40>
		c &= 0xFF;
f0104353:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0104357:	89 d3                	mov    %edx,%ebx
f0104359:	c1 e3 08             	shl    $0x8,%ebx
f010435c:	89 d6                	mov    %edx,%esi
f010435e:	c1 e6 18             	shl    $0x18,%esi
f0104361:	89 d0                	mov    %edx,%eax
f0104363:	c1 e0 10             	shl    $0x10,%eax
f0104366:	09 f0                	or     %esi,%eax
f0104368:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f010436a:	89 d8                	mov    %ebx,%eax
f010436c:	09 d0                	or     %edx,%eax
f010436e:	c1 e9 02             	shr    $0x2,%ecx
f0104371:	fc                   	cld    
f0104372:	f3 ab                	rep stos %eax,%es:(%edi)
f0104374:	eb 06                	jmp    f010437c <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0104376:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104379:	fc                   	cld    
f010437a:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010437c:	89 f8                	mov    %edi,%eax
f010437e:	5b                   	pop    %ebx
f010437f:	5e                   	pop    %esi
f0104380:	5f                   	pop    %edi
f0104381:	5d                   	pop    %ebp
f0104382:	c3                   	ret    

f0104383 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0104383:	55                   	push   %ebp
f0104384:	89 e5                	mov    %esp,%ebp
f0104386:	57                   	push   %edi
f0104387:	56                   	push   %esi
f0104388:	8b 45 08             	mov    0x8(%ebp),%eax
f010438b:	8b 75 0c             	mov    0xc(%ebp),%esi
f010438e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0104391:	39 c6                	cmp    %eax,%esi
f0104393:	73 35                	jae    f01043ca <memmove+0x47>
f0104395:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0104398:	39 d0                	cmp    %edx,%eax
f010439a:	73 2e                	jae    f01043ca <memmove+0x47>
		s += n;
		d += n;
f010439c:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010439f:	89 d6                	mov    %edx,%esi
f01043a1:	09 fe                	or     %edi,%esi
f01043a3:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01043a9:	75 13                	jne    f01043be <memmove+0x3b>
f01043ab:	f6 c1 03             	test   $0x3,%cl
f01043ae:	75 0e                	jne    f01043be <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f01043b0:	83 ef 04             	sub    $0x4,%edi
f01043b3:	8d 72 fc             	lea    -0x4(%edx),%esi
f01043b6:	c1 e9 02             	shr    $0x2,%ecx
f01043b9:	fd                   	std    
f01043ba:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01043bc:	eb 09                	jmp    f01043c7 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01043be:	83 ef 01             	sub    $0x1,%edi
f01043c1:	8d 72 ff             	lea    -0x1(%edx),%esi
f01043c4:	fd                   	std    
f01043c5:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01043c7:	fc                   	cld    
f01043c8:	eb 1d                	jmp    f01043e7 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01043ca:	89 f2                	mov    %esi,%edx
f01043cc:	09 c2                	or     %eax,%edx
f01043ce:	f6 c2 03             	test   $0x3,%dl
f01043d1:	75 0f                	jne    f01043e2 <memmove+0x5f>
f01043d3:	f6 c1 03             	test   $0x3,%cl
f01043d6:	75 0a                	jne    f01043e2 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f01043d8:	c1 e9 02             	shr    $0x2,%ecx
f01043db:	89 c7                	mov    %eax,%edi
f01043dd:	fc                   	cld    
f01043de:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01043e0:	eb 05                	jmp    f01043e7 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01043e2:	89 c7                	mov    %eax,%edi
f01043e4:	fc                   	cld    
f01043e5:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01043e7:	5e                   	pop    %esi
f01043e8:	5f                   	pop    %edi
f01043e9:	5d                   	pop    %ebp
f01043ea:	c3                   	ret    

f01043eb <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01043eb:	55                   	push   %ebp
f01043ec:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01043ee:	ff 75 10             	pushl  0x10(%ebp)
f01043f1:	ff 75 0c             	pushl  0xc(%ebp)
f01043f4:	ff 75 08             	pushl  0x8(%ebp)
f01043f7:	e8 87 ff ff ff       	call   f0104383 <memmove>
}
f01043fc:	c9                   	leave  
f01043fd:	c3                   	ret    

f01043fe <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01043fe:	55                   	push   %ebp
f01043ff:	89 e5                	mov    %esp,%ebp
f0104401:	56                   	push   %esi
f0104402:	53                   	push   %ebx
f0104403:	8b 45 08             	mov    0x8(%ebp),%eax
f0104406:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104409:	89 c6                	mov    %eax,%esi
f010440b:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010440e:	eb 1a                	jmp    f010442a <memcmp+0x2c>
		if (*s1 != *s2)
f0104410:	0f b6 08             	movzbl (%eax),%ecx
f0104413:	0f b6 1a             	movzbl (%edx),%ebx
f0104416:	38 d9                	cmp    %bl,%cl
f0104418:	74 0a                	je     f0104424 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f010441a:	0f b6 c1             	movzbl %cl,%eax
f010441d:	0f b6 db             	movzbl %bl,%ebx
f0104420:	29 d8                	sub    %ebx,%eax
f0104422:	eb 0f                	jmp    f0104433 <memcmp+0x35>
		s1++, s2++;
f0104424:	83 c0 01             	add    $0x1,%eax
f0104427:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010442a:	39 f0                	cmp    %esi,%eax
f010442c:	75 e2                	jne    f0104410 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010442e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104433:	5b                   	pop    %ebx
f0104434:	5e                   	pop    %esi
f0104435:	5d                   	pop    %ebp
f0104436:	c3                   	ret    

f0104437 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0104437:	55                   	push   %ebp
f0104438:	89 e5                	mov    %esp,%ebp
f010443a:	53                   	push   %ebx
f010443b:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f010443e:	89 c1                	mov    %eax,%ecx
f0104440:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0104443:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104447:	eb 0a                	jmp    f0104453 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0104449:	0f b6 10             	movzbl (%eax),%edx
f010444c:	39 da                	cmp    %ebx,%edx
f010444e:	74 07                	je     f0104457 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104450:	83 c0 01             	add    $0x1,%eax
f0104453:	39 c8                	cmp    %ecx,%eax
f0104455:	72 f2                	jb     f0104449 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0104457:	5b                   	pop    %ebx
f0104458:	5d                   	pop    %ebp
f0104459:	c3                   	ret    

f010445a <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010445a:	55                   	push   %ebp
f010445b:	89 e5                	mov    %esp,%ebp
f010445d:	57                   	push   %edi
f010445e:	56                   	push   %esi
f010445f:	53                   	push   %ebx
f0104460:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104463:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104466:	eb 03                	jmp    f010446b <strtol+0x11>
		s++;
f0104468:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010446b:	0f b6 01             	movzbl (%ecx),%eax
f010446e:	3c 20                	cmp    $0x20,%al
f0104470:	74 f6                	je     f0104468 <strtol+0xe>
f0104472:	3c 09                	cmp    $0x9,%al
f0104474:	74 f2                	je     f0104468 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0104476:	3c 2b                	cmp    $0x2b,%al
f0104478:	75 0a                	jne    f0104484 <strtol+0x2a>
		s++;
f010447a:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f010447d:	bf 00 00 00 00       	mov    $0x0,%edi
f0104482:	eb 11                	jmp    f0104495 <strtol+0x3b>
f0104484:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0104489:	3c 2d                	cmp    $0x2d,%al
f010448b:	75 08                	jne    f0104495 <strtol+0x3b>
		s++, neg = 1;
f010448d:	83 c1 01             	add    $0x1,%ecx
f0104490:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104495:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f010449b:	75 15                	jne    f01044b2 <strtol+0x58>
f010449d:	80 39 30             	cmpb   $0x30,(%ecx)
f01044a0:	75 10                	jne    f01044b2 <strtol+0x58>
f01044a2:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01044a6:	75 7c                	jne    f0104524 <strtol+0xca>
		s += 2, base = 16;
f01044a8:	83 c1 02             	add    $0x2,%ecx
f01044ab:	bb 10 00 00 00       	mov    $0x10,%ebx
f01044b0:	eb 16                	jmp    f01044c8 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f01044b2:	85 db                	test   %ebx,%ebx
f01044b4:	75 12                	jne    f01044c8 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01044b6:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01044bb:	80 39 30             	cmpb   $0x30,(%ecx)
f01044be:	75 08                	jne    f01044c8 <strtol+0x6e>
		s++, base = 8;
f01044c0:	83 c1 01             	add    $0x1,%ecx
f01044c3:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01044c8:	b8 00 00 00 00       	mov    $0x0,%eax
f01044cd:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01044d0:	0f b6 11             	movzbl (%ecx),%edx
f01044d3:	8d 72 d0             	lea    -0x30(%edx),%esi
f01044d6:	89 f3                	mov    %esi,%ebx
f01044d8:	80 fb 09             	cmp    $0x9,%bl
f01044db:	77 08                	ja     f01044e5 <strtol+0x8b>
			dig = *s - '0';
f01044dd:	0f be d2             	movsbl %dl,%edx
f01044e0:	83 ea 30             	sub    $0x30,%edx
f01044e3:	eb 22                	jmp    f0104507 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f01044e5:	8d 72 9f             	lea    -0x61(%edx),%esi
f01044e8:	89 f3                	mov    %esi,%ebx
f01044ea:	80 fb 19             	cmp    $0x19,%bl
f01044ed:	77 08                	ja     f01044f7 <strtol+0x9d>
			dig = *s - 'a' + 10;
f01044ef:	0f be d2             	movsbl %dl,%edx
f01044f2:	83 ea 57             	sub    $0x57,%edx
f01044f5:	eb 10                	jmp    f0104507 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f01044f7:	8d 72 bf             	lea    -0x41(%edx),%esi
f01044fa:	89 f3                	mov    %esi,%ebx
f01044fc:	80 fb 19             	cmp    $0x19,%bl
f01044ff:	77 16                	ja     f0104517 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0104501:	0f be d2             	movsbl %dl,%edx
f0104504:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0104507:	3b 55 10             	cmp    0x10(%ebp),%edx
f010450a:	7d 0b                	jge    f0104517 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f010450c:	83 c1 01             	add    $0x1,%ecx
f010450f:	0f af 45 10          	imul   0x10(%ebp),%eax
f0104513:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0104515:	eb b9                	jmp    f01044d0 <strtol+0x76>

	if (endptr)
f0104517:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010451b:	74 0d                	je     f010452a <strtol+0xd0>
		*endptr = (char *) s;
f010451d:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104520:	89 0e                	mov    %ecx,(%esi)
f0104522:	eb 06                	jmp    f010452a <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104524:	85 db                	test   %ebx,%ebx
f0104526:	74 98                	je     f01044c0 <strtol+0x66>
f0104528:	eb 9e                	jmp    f01044c8 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f010452a:	89 c2                	mov    %eax,%edx
f010452c:	f7 da                	neg    %edx
f010452e:	85 ff                	test   %edi,%edi
f0104530:	0f 45 c2             	cmovne %edx,%eax
}
f0104533:	5b                   	pop    %ebx
f0104534:	5e                   	pop    %esi
f0104535:	5f                   	pop    %edi
f0104536:	5d                   	pop    %ebp
f0104537:	c3                   	ret    
f0104538:	66 90                	xchg   %ax,%ax
f010453a:	66 90                	xchg   %ax,%ax
f010453c:	66 90                	xchg   %ax,%ax
f010453e:	66 90                	xchg   %ax,%ax

f0104540 <__udivdi3>:
f0104540:	55                   	push   %ebp
f0104541:	57                   	push   %edi
f0104542:	56                   	push   %esi
f0104543:	53                   	push   %ebx
f0104544:	83 ec 1c             	sub    $0x1c,%esp
f0104547:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010454b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010454f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0104553:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0104557:	85 f6                	test   %esi,%esi
f0104559:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010455d:	89 ca                	mov    %ecx,%edx
f010455f:	89 f8                	mov    %edi,%eax
f0104561:	75 3d                	jne    f01045a0 <__udivdi3+0x60>
f0104563:	39 cf                	cmp    %ecx,%edi
f0104565:	0f 87 c5 00 00 00    	ja     f0104630 <__udivdi3+0xf0>
f010456b:	85 ff                	test   %edi,%edi
f010456d:	89 fd                	mov    %edi,%ebp
f010456f:	75 0b                	jne    f010457c <__udivdi3+0x3c>
f0104571:	b8 01 00 00 00       	mov    $0x1,%eax
f0104576:	31 d2                	xor    %edx,%edx
f0104578:	f7 f7                	div    %edi
f010457a:	89 c5                	mov    %eax,%ebp
f010457c:	89 c8                	mov    %ecx,%eax
f010457e:	31 d2                	xor    %edx,%edx
f0104580:	f7 f5                	div    %ebp
f0104582:	89 c1                	mov    %eax,%ecx
f0104584:	89 d8                	mov    %ebx,%eax
f0104586:	89 cf                	mov    %ecx,%edi
f0104588:	f7 f5                	div    %ebp
f010458a:	89 c3                	mov    %eax,%ebx
f010458c:	89 d8                	mov    %ebx,%eax
f010458e:	89 fa                	mov    %edi,%edx
f0104590:	83 c4 1c             	add    $0x1c,%esp
f0104593:	5b                   	pop    %ebx
f0104594:	5e                   	pop    %esi
f0104595:	5f                   	pop    %edi
f0104596:	5d                   	pop    %ebp
f0104597:	c3                   	ret    
f0104598:	90                   	nop
f0104599:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01045a0:	39 ce                	cmp    %ecx,%esi
f01045a2:	77 74                	ja     f0104618 <__udivdi3+0xd8>
f01045a4:	0f bd fe             	bsr    %esi,%edi
f01045a7:	83 f7 1f             	xor    $0x1f,%edi
f01045aa:	0f 84 98 00 00 00    	je     f0104648 <__udivdi3+0x108>
f01045b0:	bb 20 00 00 00       	mov    $0x20,%ebx
f01045b5:	89 f9                	mov    %edi,%ecx
f01045b7:	89 c5                	mov    %eax,%ebp
f01045b9:	29 fb                	sub    %edi,%ebx
f01045bb:	d3 e6                	shl    %cl,%esi
f01045bd:	89 d9                	mov    %ebx,%ecx
f01045bf:	d3 ed                	shr    %cl,%ebp
f01045c1:	89 f9                	mov    %edi,%ecx
f01045c3:	d3 e0                	shl    %cl,%eax
f01045c5:	09 ee                	or     %ebp,%esi
f01045c7:	89 d9                	mov    %ebx,%ecx
f01045c9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01045cd:	89 d5                	mov    %edx,%ebp
f01045cf:	8b 44 24 08          	mov    0x8(%esp),%eax
f01045d3:	d3 ed                	shr    %cl,%ebp
f01045d5:	89 f9                	mov    %edi,%ecx
f01045d7:	d3 e2                	shl    %cl,%edx
f01045d9:	89 d9                	mov    %ebx,%ecx
f01045db:	d3 e8                	shr    %cl,%eax
f01045dd:	09 c2                	or     %eax,%edx
f01045df:	89 d0                	mov    %edx,%eax
f01045e1:	89 ea                	mov    %ebp,%edx
f01045e3:	f7 f6                	div    %esi
f01045e5:	89 d5                	mov    %edx,%ebp
f01045e7:	89 c3                	mov    %eax,%ebx
f01045e9:	f7 64 24 0c          	mull   0xc(%esp)
f01045ed:	39 d5                	cmp    %edx,%ebp
f01045ef:	72 10                	jb     f0104601 <__udivdi3+0xc1>
f01045f1:	8b 74 24 08          	mov    0x8(%esp),%esi
f01045f5:	89 f9                	mov    %edi,%ecx
f01045f7:	d3 e6                	shl    %cl,%esi
f01045f9:	39 c6                	cmp    %eax,%esi
f01045fb:	73 07                	jae    f0104604 <__udivdi3+0xc4>
f01045fd:	39 d5                	cmp    %edx,%ebp
f01045ff:	75 03                	jne    f0104604 <__udivdi3+0xc4>
f0104601:	83 eb 01             	sub    $0x1,%ebx
f0104604:	31 ff                	xor    %edi,%edi
f0104606:	89 d8                	mov    %ebx,%eax
f0104608:	89 fa                	mov    %edi,%edx
f010460a:	83 c4 1c             	add    $0x1c,%esp
f010460d:	5b                   	pop    %ebx
f010460e:	5e                   	pop    %esi
f010460f:	5f                   	pop    %edi
f0104610:	5d                   	pop    %ebp
f0104611:	c3                   	ret    
f0104612:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104618:	31 ff                	xor    %edi,%edi
f010461a:	31 db                	xor    %ebx,%ebx
f010461c:	89 d8                	mov    %ebx,%eax
f010461e:	89 fa                	mov    %edi,%edx
f0104620:	83 c4 1c             	add    $0x1c,%esp
f0104623:	5b                   	pop    %ebx
f0104624:	5e                   	pop    %esi
f0104625:	5f                   	pop    %edi
f0104626:	5d                   	pop    %ebp
f0104627:	c3                   	ret    
f0104628:	90                   	nop
f0104629:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104630:	89 d8                	mov    %ebx,%eax
f0104632:	f7 f7                	div    %edi
f0104634:	31 ff                	xor    %edi,%edi
f0104636:	89 c3                	mov    %eax,%ebx
f0104638:	89 d8                	mov    %ebx,%eax
f010463a:	89 fa                	mov    %edi,%edx
f010463c:	83 c4 1c             	add    $0x1c,%esp
f010463f:	5b                   	pop    %ebx
f0104640:	5e                   	pop    %esi
f0104641:	5f                   	pop    %edi
f0104642:	5d                   	pop    %ebp
f0104643:	c3                   	ret    
f0104644:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104648:	39 ce                	cmp    %ecx,%esi
f010464a:	72 0c                	jb     f0104658 <__udivdi3+0x118>
f010464c:	31 db                	xor    %ebx,%ebx
f010464e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0104652:	0f 87 34 ff ff ff    	ja     f010458c <__udivdi3+0x4c>
f0104658:	bb 01 00 00 00       	mov    $0x1,%ebx
f010465d:	e9 2a ff ff ff       	jmp    f010458c <__udivdi3+0x4c>
f0104662:	66 90                	xchg   %ax,%ax
f0104664:	66 90                	xchg   %ax,%ax
f0104666:	66 90                	xchg   %ax,%ax
f0104668:	66 90                	xchg   %ax,%ax
f010466a:	66 90                	xchg   %ax,%ax
f010466c:	66 90                	xchg   %ax,%ax
f010466e:	66 90                	xchg   %ax,%ax

f0104670 <__umoddi3>:
f0104670:	55                   	push   %ebp
f0104671:	57                   	push   %edi
f0104672:	56                   	push   %esi
f0104673:	53                   	push   %ebx
f0104674:	83 ec 1c             	sub    $0x1c,%esp
f0104677:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010467b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010467f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0104683:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0104687:	85 d2                	test   %edx,%edx
f0104689:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010468d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104691:	89 f3                	mov    %esi,%ebx
f0104693:	89 3c 24             	mov    %edi,(%esp)
f0104696:	89 74 24 04          	mov    %esi,0x4(%esp)
f010469a:	75 1c                	jne    f01046b8 <__umoddi3+0x48>
f010469c:	39 f7                	cmp    %esi,%edi
f010469e:	76 50                	jbe    f01046f0 <__umoddi3+0x80>
f01046a0:	89 c8                	mov    %ecx,%eax
f01046a2:	89 f2                	mov    %esi,%edx
f01046a4:	f7 f7                	div    %edi
f01046a6:	89 d0                	mov    %edx,%eax
f01046a8:	31 d2                	xor    %edx,%edx
f01046aa:	83 c4 1c             	add    $0x1c,%esp
f01046ad:	5b                   	pop    %ebx
f01046ae:	5e                   	pop    %esi
f01046af:	5f                   	pop    %edi
f01046b0:	5d                   	pop    %ebp
f01046b1:	c3                   	ret    
f01046b2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01046b8:	39 f2                	cmp    %esi,%edx
f01046ba:	89 d0                	mov    %edx,%eax
f01046bc:	77 52                	ja     f0104710 <__umoddi3+0xa0>
f01046be:	0f bd ea             	bsr    %edx,%ebp
f01046c1:	83 f5 1f             	xor    $0x1f,%ebp
f01046c4:	75 5a                	jne    f0104720 <__umoddi3+0xb0>
f01046c6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f01046ca:	0f 82 e0 00 00 00    	jb     f01047b0 <__umoddi3+0x140>
f01046d0:	39 0c 24             	cmp    %ecx,(%esp)
f01046d3:	0f 86 d7 00 00 00    	jbe    f01047b0 <__umoddi3+0x140>
f01046d9:	8b 44 24 08          	mov    0x8(%esp),%eax
f01046dd:	8b 54 24 04          	mov    0x4(%esp),%edx
f01046e1:	83 c4 1c             	add    $0x1c,%esp
f01046e4:	5b                   	pop    %ebx
f01046e5:	5e                   	pop    %esi
f01046e6:	5f                   	pop    %edi
f01046e7:	5d                   	pop    %ebp
f01046e8:	c3                   	ret    
f01046e9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01046f0:	85 ff                	test   %edi,%edi
f01046f2:	89 fd                	mov    %edi,%ebp
f01046f4:	75 0b                	jne    f0104701 <__umoddi3+0x91>
f01046f6:	b8 01 00 00 00       	mov    $0x1,%eax
f01046fb:	31 d2                	xor    %edx,%edx
f01046fd:	f7 f7                	div    %edi
f01046ff:	89 c5                	mov    %eax,%ebp
f0104701:	89 f0                	mov    %esi,%eax
f0104703:	31 d2                	xor    %edx,%edx
f0104705:	f7 f5                	div    %ebp
f0104707:	89 c8                	mov    %ecx,%eax
f0104709:	f7 f5                	div    %ebp
f010470b:	89 d0                	mov    %edx,%eax
f010470d:	eb 99                	jmp    f01046a8 <__umoddi3+0x38>
f010470f:	90                   	nop
f0104710:	89 c8                	mov    %ecx,%eax
f0104712:	89 f2                	mov    %esi,%edx
f0104714:	83 c4 1c             	add    $0x1c,%esp
f0104717:	5b                   	pop    %ebx
f0104718:	5e                   	pop    %esi
f0104719:	5f                   	pop    %edi
f010471a:	5d                   	pop    %ebp
f010471b:	c3                   	ret    
f010471c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104720:	8b 34 24             	mov    (%esp),%esi
f0104723:	bf 20 00 00 00       	mov    $0x20,%edi
f0104728:	89 e9                	mov    %ebp,%ecx
f010472a:	29 ef                	sub    %ebp,%edi
f010472c:	d3 e0                	shl    %cl,%eax
f010472e:	89 f9                	mov    %edi,%ecx
f0104730:	89 f2                	mov    %esi,%edx
f0104732:	d3 ea                	shr    %cl,%edx
f0104734:	89 e9                	mov    %ebp,%ecx
f0104736:	09 c2                	or     %eax,%edx
f0104738:	89 d8                	mov    %ebx,%eax
f010473a:	89 14 24             	mov    %edx,(%esp)
f010473d:	89 f2                	mov    %esi,%edx
f010473f:	d3 e2                	shl    %cl,%edx
f0104741:	89 f9                	mov    %edi,%ecx
f0104743:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104747:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010474b:	d3 e8                	shr    %cl,%eax
f010474d:	89 e9                	mov    %ebp,%ecx
f010474f:	89 c6                	mov    %eax,%esi
f0104751:	d3 e3                	shl    %cl,%ebx
f0104753:	89 f9                	mov    %edi,%ecx
f0104755:	89 d0                	mov    %edx,%eax
f0104757:	d3 e8                	shr    %cl,%eax
f0104759:	89 e9                	mov    %ebp,%ecx
f010475b:	09 d8                	or     %ebx,%eax
f010475d:	89 d3                	mov    %edx,%ebx
f010475f:	89 f2                	mov    %esi,%edx
f0104761:	f7 34 24             	divl   (%esp)
f0104764:	89 d6                	mov    %edx,%esi
f0104766:	d3 e3                	shl    %cl,%ebx
f0104768:	f7 64 24 04          	mull   0x4(%esp)
f010476c:	39 d6                	cmp    %edx,%esi
f010476e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0104772:	89 d1                	mov    %edx,%ecx
f0104774:	89 c3                	mov    %eax,%ebx
f0104776:	72 08                	jb     f0104780 <__umoddi3+0x110>
f0104778:	75 11                	jne    f010478b <__umoddi3+0x11b>
f010477a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010477e:	73 0b                	jae    f010478b <__umoddi3+0x11b>
f0104780:	2b 44 24 04          	sub    0x4(%esp),%eax
f0104784:	1b 14 24             	sbb    (%esp),%edx
f0104787:	89 d1                	mov    %edx,%ecx
f0104789:	89 c3                	mov    %eax,%ebx
f010478b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010478f:	29 da                	sub    %ebx,%edx
f0104791:	19 ce                	sbb    %ecx,%esi
f0104793:	89 f9                	mov    %edi,%ecx
f0104795:	89 f0                	mov    %esi,%eax
f0104797:	d3 e0                	shl    %cl,%eax
f0104799:	89 e9                	mov    %ebp,%ecx
f010479b:	d3 ea                	shr    %cl,%edx
f010479d:	89 e9                	mov    %ebp,%ecx
f010479f:	d3 ee                	shr    %cl,%esi
f01047a1:	09 d0                	or     %edx,%eax
f01047a3:	89 f2                	mov    %esi,%edx
f01047a5:	83 c4 1c             	add    $0x1c,%esp
f01047a8:	5b                   	pop    %ebx
f01047a9:	5e                   	pop    %esi
f01047aa:	5f                   	pop    %edi
f01047ab:	5d                   	pop    %ebp
f01047ac:	c3                   	ret    
f01047ad:	8d 76 00             	lea    0x0(%esi),%esi
f01047b0:	29 f9                	sub    %edi,%ecx
f01047b2:	19 d6                	sbb    %edx,%esi
f01047b4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01047b8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01047bc:	e9 18 ff ff ff       	jmp    f01046d9 <__umoddi3+0x69>
