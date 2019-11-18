
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
f0100046:	b8 10 db 17 f0       	mov    $0xf017db10,%eax
f010004b:	2d ee cb 17 f0       	sub    $0xf017cbee,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 ee cb 17 f0       	push   $0xf017cbee
f0100058:	e8 56 43 00 00       	call   f01043b3 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 9d 04 00 00       	call   f01004ff <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 60 48 10 f0       	push   $0xf0104860
f010006f:	e8 4f 2f 00 00       	call   f0102fc3 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 41 10 00 00       	call   f01010ba <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100079:	e8 98 29 00 00       	call   f0102a16 <env_init>
	trap_init();
f010007e:	e8 b1 2f 00 00       	call   f0103034 <trap_init>

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f0100083:	83 c4 08             	add    $0x8,%esp
f0100086:	6a 00                	push   $0x0
f0100088:	68 7e 1b 13 f0       	push   $0xf0131b7e
f010008d:	e8 31 2b 00 00       	call   f0102bc3 <env_create>
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f0100092:	83 c4 04             	add    $0x4,%esp
f0100095:	ff 35 4c ce 17 f0    	pushl  0xf017ce4c
f010009b:	e8 60 2e 00 00       	call   f0102f00 <env_run>

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
f01000a8:	83 3d 00 db 17 f0 00 	cmpl   $0x0,0xf017db00
f01000af:	75 37                	jne    f01000e8 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000b1:	89 35 00 db 17 f0    	mov    %esi,0xf017db00

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
f01000c5:	68 7b 48 10 f0       	push   $0xf010487b
f01000ca:	e8 f4 2e 00 00       	call   f0102fc3 <cprintf>
	vcprintf(fmt, ap);
f01000cf:	83 c4 08             	add    $0x8,%esp
f01000d2:	53                   	push   %ebx
f01000d3:	56                   	push   %esi
f01000d4:	e8 c4 2e 00 00       	call   f0102f9d <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 47 50 10 f0 	movl   $0xf0105047,(%esp)
f01000e0:	e8 de 2e 00 00       	call   f0102fc3 <cprintf>
	va_end(ap);
f01000e5:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e8:	83 ec 0c             	sub    $0xc,%esp
f01000eb:	6a 00                	push   $0x0
f01000ed:	e8 c1 06 00 00       	call   f01007b3 <monitor>
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
f0100107:	68 93 48 10 f0       	push   $0xf0104893
f010010c:	e8 b2 2e 00 00       	call   f0102fc3 <cprintf>
	vcprintf(fmt, ap);
f0100111:	83 c4 08             	add    $0x8,%esp
f0100114:	53                   	push   %ebx
f0100115:	ff 75 10             	pushl  0x10(%ebp)
f0100118:	e8 80 2e 00 00       	call   f0102f9d <vcprintf>
	cprintf("\n");
f010011d:	c7 04 24 47 50 10 f0 	movl   $0xf0105047,(%esp)
f0100124:	e8 9a 2e 00 00       	call   f0102fc3 <cprintf>
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
f010015f:	8b 0d 24 ce 17 f0    	mov    0xf017ce24,%ecx
f0100165:	8d 51 01             	lea    0x1(%ecx),%edx
f0100168:	89 15 24 ce 17 f0    	mov    %edx,0xf017ce24
f010016e:	88 81 20 cc 17 f0    	mov    %al,-0xfe833e0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f0100174:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010017a:	75 0a                	jne    f0100186 <cons_intr+0x36>
			cons.wpos = 0;
f010017c:	c7 05 24 ce 17 f0 00 	movl   $0x0,0xf017ce24
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
f01001ad:	83 0d 00 cc 17 f0 40 	orl    $0x40,0xf017cc00
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
f01001c5:	8b 0d 00 cc 17 f0    	mov    0xf017cc00,%ecx
f01001cb:	89 cb                	mov    %ecx,%ebx
f01001cd:	83 e3 40             	and    $0x40,%ebx
f01001d0:	83 e0 7f             	and    $0x7f,%eax
f01001d3:	85 db                	test   %ebx,%ebx
f01001d5:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001d8:	0f b6 d2             	movzbl %dl,%edx
f01001db:	0f b6 82 00 4a 10 f0 	movzbl -0xfefb600(%edx),%eax
f01001e2:	83 c8 40             	or     $0x40,%eax
f01001e5:	0f b6 c0             	movzbl %al,%eax
f01001e8:	f7 d0                	not    %eax
f01001ea:	21 c8                	and    %ecx,%eax
f01001ec:	a3 00 cc 17 f0       	mov    %eax,0xf017cc00
		return 0;
f01001f1:	b8 00 00 00 00       	mov    $0x0,%eax
f01001f6:	e9 9e 00 00 00       	jmp    f0100299 <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f01001fb:	8b 0d 00 cc 17 f0    	mov    0xf017cc00,%ecx
f0100201:	f6 c1 40             	test   $0x40,%cl
f0100204:	74 0e                	je     f0100214 <kbd_proc_data+0x81>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100206:	83 c8 80             	or     $0xffffff80,%eax
f0100209:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010020b:	83 e1 bf             	and    $0xffffffbf,%ecx
f010020e:	89 0d 00 cc 17 f0    	mov    %ecx,0xf017cc00
	}

	shift |= shiftcode[data];
f0100214:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100217:	0f b6 82 00 4a 10 f0 	movzbl -0xfefb600(%edx),%eax
f010021e:	0b 05 00 cc 17 f0    	or     0xf017cc00,%eax
f0100224:	0f b6 8a 00 49 10 f0 	movzbl -0xfefb700(%edx),%ecx
f010022b:	31 c8                	xor    %ecx,%eax
f010022d:	a3 00 cc 17 f0       	mov    %eax,0xf017cc00

	c = charcode[shift & (CTL | SHIFT)][data];
f0100232:	89 c1                	mov    %eax,%ecx
f0100234:	83 e1 03             	and    $0x3,%ecx
f0100237:	8b 0c 8d e0 48 10 f0 	mov    -0xfefb720(,%ecx,4),%ecx
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
f0100275:	68 ad 48 10 f0       	push   $0xf01048ad
f010027a:	e8 44 2d 00 00       	call   f0102fc3 <cprintf>
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
f010035b:	0f b7 05 28 ce 17 f0 	movzwl 0xf017ce28,%eax
f0100362:	66 85 c0             	test   %ax,%ax
f0100365:	0f 84 e6 00 00 00    	je     f0100451 <cons_putc+0x1b3>
			crt_pos--;
f010036b:	83 e8 01             	sub    $0x1,%eax
f010036e:	66 a3 28 ce 17 f0    	mov    %ax,0xf017ce28
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100374:	0f b7 c0             	movzwl %ax,%eax
f0100377:	66 81 e7 00 ff       	and    $0xff00,%di
f010037c:	83 cf 20             	or     $0x20,%edi
f010037f:	8b 15 2c ce 17 f0    	mov    0xf017ce2c,%edx
f0100385:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100389:	eb 78                	jmp    f0100403 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f010038b:	66 83 05 28 ce 17 f0 	addw   $0x50,0xf017ce28
f0100392:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100393:	0f b7 05 28 ce 17 f0 	movzwl 0xf017ce28,%eax
f010039a:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003a0:	c1 e8 16             	shr    $0x16,%eax
f01003a3:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003a6:	c1 e0 04             	shl    $0x4,%eax
f01003a9:	66 a3 28 ce 17 f0    	mov    %ax,0xf017ce28
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
f01003e5:	0f b7 05 28 ce 17 f0 	movzwl 0xf017ce28,%eax
f01003ec:	8d 50 01             	lea    0x1(%eax),%edx
f01003ef:	66 89 15 28 ce 17 f0 	mov    %dx,0xf017ce28
f01003f6:	0f b7 c0             	movzwl %ax,%eax
f01003f9:	8b 15 2c ce 17 f0    	mov    0xf017ce2c,%edx
f01003ff:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100403:	66 81 3d 28 ce 17 f0 	cmpw   $0x7cf,0xf017ce28
f010040a:	cf 07 
f010040c:	76 43                	jbe    f0100451 <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010040e:	a1 2c ce 17 f0       	mov    0xf017ce2c,%eax
f0100413:	83 ec 04             	sub    $0x4,%esp
f0100416:	68 00 0f 00 00       	push   $0xf00
f010041b:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100421:	52                   	push   %edx
f0100422:	50                   	push   %eax
f0100423:	e8 d8 3f 00 00       	call   f0104400 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100428:	8b 15 2c ce 17 f0    	mov    0xf017ce2c,%edx
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
f0100449:	66 83 2d 28 ce 17 f0 	subw   $0x50,0xf017ce28
f0100450:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100451:	8b 0d 30 ce 17 f0    	mov    0xf017ce30,%ecx
f0100457:	b8 0e 00 00 00       	mov    $0xe,%eax
f010045c:	89 ca                	mov    %ecx,%edx
f010045e:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010045f:	0f b7 1d 28 ce 17 f0 	movzwl 0xf017ce28,%ebx
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
f0100487:	80 3d 34 ce 17 f0 00 	cmpb   $0x0,0xf017ce34
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
f01004c5:	a1 20 ce 17 f0       	mov    0xf017ce20,%eax
f01004ca:	3b 05 24 ce 17 f0    	cmp    0xf017ce24,%eax
f01004d0:	74 26                	je     f01004f8 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004d2:	8d 50 01             	lea    0x1(%eax),%edx
f01004d5:	89 15 20 ce 17 f0    	mov    %edx,0xf017ce20
f01004db:	0f b6 88 20 cc 17 f0 	movzbl -0xfe833e0(%eax),%ecx
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
f01004ec:	c7 05 20 ce 17 f0 00 	movl   $0x0,0xf017ce20
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
f0100525:	c7 05 30 ce 17 f0 b4 	movl   $0x3b4,0xf017ce30
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
f010053d:	c7 05 30 ce 17 f0 d4 	movl   $0x3d4,0xf017ce30
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
f010054c:	8b 3d 30 ce 17 f0    	mov    0xf017ce30,%edi
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
f0100571:	89 35 2c ce 17 f0    	mov    %esi,0xf017ce2c
	crt_pos = pos;
f0100577:	0f b6 c0             	movzbl %al,%eax
f010057a:	09 c8                	or     %ecx,%eax
f010057c:	66 a3 28 ce 17 f0    	mov    %ax,0xf017ce28
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
f01005dd:	0f 95 05 34 ce 17 f0 	setne  0xf017ce34
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
f01005f2:	68 b9 48 10 f0       	push   $0xf01048b9
f01005f7:	e8 c7 29 00 00       	call   f0102fc3 <cprintf>
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
f0100638:	68 00 4b 10 f0       	push   $0xf0104b00
f010063d:	68 1e 4b 10 f0       	push   $0xf0104b1e
f0100642:	68 23 4b 10 f0       	push   $0xf0104b23
f0100647:	e8 77 29 00 00       	call   f0102fc3 <cprintf>
f010064c:	83 c4 0c             	add    $0xc,%esp
f010064f:	68 d4 4b 10 f0       	push   $0xf0104bd4
f0100654:	68 2c 4b 10 f0       	push   $0xf0104b2c
f0100659:	68 23 4b 10 f0       	push   $0xf0104b23
f010065e:	e8 60 29 00 00       	call   f0102fc3 <cprintf>
f0100663:	83 c4 0c             	add    $0xc,%esp
f0100666:	68 35 4b 10 f0       	push   $0xf0104b35
f010066b:	68 41 4b 10 f0       	push   $0xf0104b41
f0100670:	68 23 4b 10 f0       	push   $0xf0104b23
f0100675:	e8 49 29 00 00       	call   f0102fc3 <cprintf>
	return 0;
}
f010067a:	b8 00 00 00 00       	mov    $0x0,%eax
f010067f:	c9                   	leave  
f0100680:	c3                   	ret    

f0100681 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100681:	55                   	push   %ebp
f0100682:	89 e5                	mov    %esp,%ebp
f0100684:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100687:	68 4b 4b 10 f0       	push   $0xf0104b4b
f010068c:	e8 32 29 00 00       	call   f0102fc3 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100691:	83 c4 08             	add    $0x8,%esp
f0100694:	68 0c 00 10 00       	push   $0x10000c
f0100699:	68 fc 4b 10 f0       	push   $0xf0104bfc
f010069e:	e8 20 29 00 00       	call   f0102fc3 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006a3:	83 c4 0c             	add    $0xc,%esp
f01006a6:	68 0c 00 10 00       	push   $0x10000c
f01006ab:	68 0c 00 10 f0       	push   $0xf010000c
f01006b0:	68 24 4c 10 f0       	push   $0xf0104c24
f01006b5:	e8 09 29 00 00       	call   f0102fc3 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006ba:	83 c4 0c             	add    $0xc,%esp
f01006bd:	68 41 48 10 00       	push   $0x104841
f01006c2:	68 41 48 10 f0       	push   $0xf0104841
f01006c7:	68 48 4c 10 f0       	push   $0xf0104c48
f01006cc:	e8 f2 28 00 00       	call   f0102fc3 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006d1:	83 c4 0c             	add    $0xc,%esp
f01006d4:	68 ee cb 17 00       	push   $0x17cbee
f01006d9:	68 ee cb 17 f0       	push   $0xf017cbee
f01006de:	68 6c 4c 10 f0       	push   $0xf0104c6c
f01006e3:	e8 db 28 00 00       	call   f0102fc3 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006e8:	83 c4 0c             	add    $0xc,%esp
f01006eb:	68 10 db 17 00       	push   $0x17db10
f01006f0:	68 10 db 17 f0       	push   $0xf017db10
f01006f5:	68 90 4c 10 f0       	push   $0xf0104c90
f01006fa:	e8 c4 28 00 00       	call   f0102fc3 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006ff:	b8 0f df 17 f0       	mov    $0xf017df0f,%eax
f0100704:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100709:	83 c4 08             	add    $0x8,%esp
f010070c:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f0100711:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100717:	85 c0                	test   %eax,%eax
f0100719:	0f 48 c2             	cmovs  %edx,%eax
f010071c:	c1 f8 0a             	sar    $0xa,%eax
f010071f:	50                   	push   %eax
f0100720:	68 b4 4c 10 f0       	push   $0xf0104cb4
f0100725:	e8 99 28 00 00       	call   f0102fc3 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f010072a:	b8 00 00 00 00       	mov    $0x0,%eax
f010072f:	c9                   	leave  
f0100730:	c3                   	ret    

f0100731 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100731:	55                   	push   %ebp
f0100732:	89 e5                	mov    %esp,%ebp
f0100734:	57                   	push   %edi
f0100735:	56                   	push   %esi
f0100736:	53                   	push   %ebx
f0100737:	83 ec 18             	sub    $0x18,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f010073a:	89 e8                	mov    %ebp,%eax
	// Your code here.
	uint32_t *ebp = (uint32_t*)read_ebp(); 
f010073c:	89 c6                	mov    %eax,%esi
	uint32_t *eip = (uint32_t*)*(ebp + 1); 
f010073e:	8b 58 04             	mov    0x4(%eax),%ebx
	cprintf("Stack backtrace:");
f0100741:	68 64 4b 10 f0       	push   $0xf0104b64
f0100746:	e8 78 28 00 00       	call   f0102fc3 <cprintf>
	while(ebp != NULL){
f010074b:	83 c4 10             	add    $0x10,%esp
f010074e:	eb 52                	jmp    f01007a2 <mon_backtrace+0x71>
		cprintf("ebp %08x  eip %08x", ebp, eip);
f0100750:	83 ec 04             	sub    $0x4,%esp
f0100753:	53                   	push   %ebx
f0100754:	56                   	push   %esi
f0100755:	68 75 4b 10 f0       	push   $0xf0104b75
f010075a:	e8 64 28 00 00       	call   f0102fc3 <cprintf>
		cprintf("    arg ");
f010075f:	c7 04 24 88 4b 10 f0 	movl   $0xf0104b88,(%esp)
f0100766:	e8 58 28 00 00       	call   f0102fc3 <cprintf>
f010076b:	8d 5e 08             	lea    0x8(%esi),%ebx
f010076e:	8d 7e 1c             	lea    0x1c(%esi),%edi
f0100771:	83 c4 10             	add    $0x10,%esp
		for(int i = 0;i < 5;i++){
			cprintf("%08x ", *(ebp + i + 2));
f0100774:	83 ec 08             	sub    $0x8,%esp
f0100777:	ff 33                	pushl  (%ebx)
f0100779:	68 91 4b 10 f0       	push   $0xf0104b91
f010077e:	e8 40 28 00 00       	call   f0102fc3 <cprintf>
f0100783:	83 c3 04             	add    $0x4,%ebx
	uint32_t *eip = (uint32_t*)*(ebp + 1); 
	cprintf("Stack backtrace:");
	while(ebp != NULL){
		cprintf("ebp %08x  eip %08x", ebp, eip);
		cprintf("    arg ");
		for(int i = 0;i < 5;i++){
f0100786:	83 c4 10             	add    $0x10,%esp
f0100789:	39 fb                	cmp    %edi,%ebx
f010078b:	75 e7                	jne    f0100774 <mon_backtrace+0x43>
			cprintf("%08x ", *(ebp + i + 2));
		}
		cprintf("\n");
f010078d:	83 ec 0c             	sub    $0xc,%esp
f0100790:	68 47 50 10 f0       	push   $0xf0105047
f0100795:	e8 29 28 00 00       	call   f0102fc3 <cprintf>
		ebp = (uint32_t*)(*ebp); 
f010079a:	8b 36                	mov    (%esi),%esi
		eip = (uint32_t*)*(ebp + 1);
f010079c:	8b 5e 04             	mov    0x4(%esi),%ebx
f010079f:	83 c4 10             	add    $0x10,%esp
{
	// Your code here.
	uint32_t *ebp = (uint32_t*)read_ebp(); 
	uint32_t *eip = (uint32_t*)*(ebp + 1); 
	cprintf("Stack backtrace:");
	while(ebp != NULL){
f01007a2:	85 f6                	test   %esi,%esi
f01007a4:	75 aa                	jne    f0100750 <mon_backtrace+0x1f>
		cprintf("\n");
		ebp = (uint32_t*)(*ebp); 
		eip = (uint32_t*)*(ebp + 1);
	}
	return 0;
}
f01007a6:	b8 00 00 00 00       	mov    $0x0,%eax
f01007ab:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01007ae:	5b                   	pop    %ebx
f01007af:	5e                   	pop    %esi
f01007b0:	5f                   	pop    %edi
f01007b1:	5d                   	pop    %ebp
f01007b2:	c3                   	ret    

f01007b3 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007b3:	55                   	push   %ebp
f01007b4:	89 e5                	mov    %esp,%ebp
f01007b6:	57                   	push   %edi
f01007b7:	56                   	push   %esi
f01007b8:	53                   	push   %ebx
f01007b9:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007bc:	68 e0 4c 10 f0       	push   $0xf0104ce0
f01007c1:	e8 fd 27 00 00       	call   f0102fc3 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007c6:	c7 04 24 04 4d 10 f0 	movl   $0xf0104d04,(%esp)
f01007cd:	e8 f1 27 00 00       	call   f0102fc3 <cprintf>

	if (tf != NULL)
f01007d2:	83 c4 10             	add    $0x10,%esp
f01007d5:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f01007d9:	74 0e                	je     f01007e9 <monitor+0x36>
		print_trapframe(tf);
f01007db:	83 ec 0c             	sub    $0xc,%esp
f01007de:	ff 75 08             	pushl  0x8(%ebp)
f01007e1:	e8 17 2c 00 00       	call   f01033fd <print_trapframe>
f01007e6:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f01007e9:	83 ec 0c             	sub    $0xc,%esp
f01007ec:	68 97 4b 10 f0       	push   $0xf0104b97
f01007f1:	e8 66 39 00 00       	call   f010415c <readline>
f01007f6:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007f8:	83 c4 10             	add    $0x10,%esp
f01007fb:	85 c0                	test   %eax,%eax
f01007fd:	74 ea                	je     f01007e9 <monitor+0x36>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01007ff:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100806:	be 00 00 00 00       	mov    $0x0,%esi
f010080b:	eb 0a                	jmp    f0100817 <monitor+0x64>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010080d:	c6 03 00             	movb   $0x0,(%ebx)
f0100810:	89 f7                	mov    %esi,%edi
f0100812:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100815:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100817:	0f b6 03             	movzbl (%ebx),%eax
f010081a:	84 c0                	test   %al,%al
f010081c:	74 63                	je     f0100881 <monitor+0xce>
f010081e:	83 ec 08             	sub    $0x8,%esp
f0100821:	0f be c0             	movsbl %al,%eax
f0100824:	50                   	push   %eax
f0100825:	68 9b 4b 10 f0       	push   $0xf0104b9b
f010082a:	e8 47 3b 00 00       	call   f0104376 <strchr>
f010082f:	83 c4 10             	add    $0x10,%esp
f0100832:	85 c0                	test   %eax,%eax
f0100834:	75 d7                	jne    f010080d <monitor+0x5a>
			*buf++ = 0;
		if (*buf == 0)
f0100836:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100839:	74 46                	je     f0100881 <monitor+0xce>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f010083b:	83 fe 0f             	cmp    $0xf,%esi
f010083e:	75 14                	jne    f0100854 <monitor+0xa1>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100840:	83 ec 08             	sub    $0x8,%esp
f0100843:	6a 10                	push   $0x10
f0100845:	68 a0 4b 10 f0       	push   $0xf0104ba0
f010084a:	e8 74 27 00 00       	call   f0102fc3 <cprintf>
f010084f:	83 c4 10             	add    $0x10,%esp
f0100852:	eb 95                	jmp    f01007e9 <monitor+0x36>
			return 0;
		}
		argv[argc++] = buf;
f0100854:	8d 7e 01             	lea    0x1(%esi),%edi
f0100857:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f010085b:	eb 03                	jmp    f0100860 <monitor+0xad>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f010085d:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100860:	0f b6 03             	movzbl (%ebx),%eax
f0100863:	84 c0                	test   %al,%al
f0100865:	74 ae                	je     f0100815 <monitor+0x62>
f0100867:	83 ec 08             	sub    $0x8,%esp
f010086a:	0f be c0             	movsbl %al,%eax
f010086d:	50                   	push   %eax
f010086e:	68 9b 4b 10 f0       	push   $0xf0104b9b
f0100873:	e8 fe 3a 00 00       	call   f0104376 <strchr>
f0100878:	83 c4 10             	add    $0x10,%esp
f010087b:	85 c0                	test   %eax,%eax
f010087d:	74 de                	je     f010085d <monitor+0xaa>
f010087f:	eb 94                	jmp    f0100815 <monitor+0x62>
			buf++;
	}
	argv[argc] = 0;
f0100881:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100888:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100889:	85 f6                	test   %esi,%esi
f010088b:	0f 84 58 ff ff ff    	je     f01007e9 <monitor+0x36>
f0100891:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100896:	83 ec 08             	sub    $0x8,%esp
f0100899:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010089c:	ff 34 85 40 4d 10 f0 	pushl  -0xfefb2c0(,%eax,4)
f01008a3:	ff 75 a8             	pushl  -0x58(%ebp)
f01008a6:	e8 6d 3a 00 00       	call   f0104318 <strcmp>
f01008ab:	83 c4 10             	add    $0x10,%esp
f01008ae:	85 c0                	test   %eax,%eax
f01008b0:	75 21                	jne    f01008d3 <monitor+0x120>
			return commands[i].func(argc, argv, tf);
f01008b2:	83 ec 04             	sub    $0x4,%esp
f01008b5:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008b8:	ff 75 08             	pushl  0x8(%ebp)
f01008bb:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01008be:	52                   	push   %edx
f01008bf:	56                   	push   %esi
f01008c0:	ff 14 85 48 4d 10 f0 	call   *-0xfefb2b8(,%eax,4)

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
		{
			if (runcmd(buf, tf) < 0)
f01008c7:	83 c4 10             	add    $0x10,%esp
f01008ca:	85 c0                	test   %eax,%eax
f01008cc:	78 25                	js     f01008f3 <monitor+0x140>
f01008ce:	e9 16 ff ff ff       	jmp    f01007e9 <monitor+0x36>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f01008d3:	83 c3 01             	add    $0x1,%ebx
f01008d6:	83 fb 03             	cmp    $0x3,%ebx
f01008d9:	75 bb                	jne    f0100896 <monitor+0xe3>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008db:	83 ec 08             	sub    $0x8,%esp
f01008de:	ff 75 a8             	pushl  -0x58(%ebp)
f01008e1:	68 bd 4b 10 f0       	push   $0xf0104bbd
f01008e6:	e8 d8 26 00 00       	call   f0102fc3 <cprintf>
f01008eb:	83 c4 10             	add    $0x10,%esp
f01008ee:	e9 f6 fe ff ff       	jmp    f01007e9 <monitor+0x36>
		{
			if (runcmd(buf, tf) < 0)
				break;
		}
	}
}
f01008f3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008f6:	5b                   	pop    %ebx
f01008f7:	5e                   	pop    %esi
f01008f8:	5f                   	pop    %edi
f01008f9:	5d                   	pop    %ebp
f01008fa:	c3                   	ret    

f01008fb <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f01008fb:	83 3d 38 ce 17 f0 00 	cmpl   $0x0,0xf017ce38
f0100902:	75 5f                	jne    f0100963 <boot_alloc+0x68>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100904:	ba 0f eb 17 f0       	mov    $0xf017eb0f,%edx
f0100909:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010090f:	89 15 38 ce 17 f0    	mov    %edx,0xf017ce38
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if (n > 0) {
f0100915:	85 c0                	test   %eax,%eax
f0100917:	74 44                	je     f010095d <boot_alloc+0x62>
		if ((uint32_t)nextfree > KERNBASE + (npages * PGSIZE)) {
f0100919:	8b 15 38 ce 17 f0    	mov    0xf017ce38,%edx
f010091f:	8b 0d 04 db 17 f0    	mov    0xf017db04,%ecx
f0100925:	81 c1 00 00 0f 00    	add    $0xf0000,%ecx
f010092b:	c1 e1 0c             	shl    $0xc,%ecx
f010092e:	39 ca                	cmp    %ecx,%edx
f0100930:	76 17                	jbe    f0100949 <boot_alloc+0x4e>
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100932:	55                   	push   %ebp
f0100933:	89 e5                	mov    %esp,%ebp
f0100935:	83 ec 0c             	sub    $0xc,%esp
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if (n > 0) {
		if ((uint32_t)nextfree > KERNBASE + (npages * PGSIZE)) {
			panic("out of memory"); 
f0100938:	68 64 4d 10 f0       	push   $0xf0104d64
f010093d:	6a 68                	push   $0x68
f010093f:	68 72 4d 10 f0       	push   $0xf0104d72
f0100944:	e8 57 f7 ff ff       	call   f01000a0 <_panic>
		} else {             
			result = nextfree; 
			nextfree = ROUNDUP(nextfree + n, PGSIZE);
f0100949:	8d 84 02 ff 0f 00 00 	lea    0xfff(%edx,%eax,1),%eax
f0100950:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100955:	a3 38 ce 17 f0       	mov    %eax,0xf017ce38
			return result;
f010095a:	89 d0                	mov    %edx,%eax
f010095c:	c3                   	ret    
		}
	}
	if (n == 0) {  
		return nextfree;
f010095d:	a1 38 ce 17 f0       	mov    0xf017ce38,%eax
f0100962:	c3                   	ret    
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if (n > 0) {
f0100963:	85 c0                	test   %eax,%eax
f0100965:	75 b2                	jne    f0100919 <boot_alloc+0x1e>
f0100967:	eb f4                	jmp    f010095d <boot_alloc+0x62>

f0100969 <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100969:	89 d1                	mov    %edx,%ecx
f010096b:	c1 e9 16             	shr    $0x16,%ecx
f010096e:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100971:	a8 01                	test   $0x1,%al
f0100973:	74 52                	je     f01009c7 <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100975:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010097a:	89 c1                	mov    %eax,%ecx
f010097c:	c1 e9 0c             	shr    $0xc,%ecx
f010097f:	3b 0d 04 db 17 f0    	cmp    0xf017db04,%ecx
f0100985:	72 1b                	jb     f01009a2 <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100987:	55                   	push   %ebp
f0100988:	89 e5                	mov    %esp,%ebp
f010098a:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010098d:	50                   	push   %eax
f010098e:	68 7c 50 10 f0       	push   $0xf010507c
f0100993:	68 2a 03 00 00       	push   $0x32a
f0100998:	68 72 4d 10 f0       	push   $0xf0104d72
f010099d:	e8 fe f6 ff ff       	call   f01000a0 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f01009a2:	c1 ea 0c             	shr    $0xc,%edx
f01009a5:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f01009ab:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f01009b2:	89 c2                	mov    %eax,%edx
f01009b4:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f01009b7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009bc:	85 d2                	test   %edx,%edx
f01009be:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01009c3:	0f 44 c2             	cmove  %edx,%eax
f01009c6:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f01009c7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f01009cc:	c3                   	ret    

f01009cd <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f01009cd:	55                   	push   %ebp
f01009ce:	89 e5                	mov    %esp,%ebp
f01009d0:	57                   	push   %edi
f01009d1:	56                   	push   %esi
f01009d2:	53                   	push   %ebx
f01009d3:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01009d6:	84 c0                	test   %al,%al
f01009d8:	0f 85 72 02 00 00    	jne    f0100c50 <check_page_free_list+0x283>
f01009de:	e9 7f 02 00 00       	jmp    f0100c62 <check_page_free_list+0x295>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f01009e3:	83 ec 04             	sub    $0x4,%esp
f01009e6:	68 a0 50 10 f0       	push   $0xf01050a0
f01009eb:	68 68 02 00 00       	push   $0x268
f01009f0:	68 72 4d 10 f0       	push   $0xf0104d72
f01009f5:	e8 a6 f6 ff ff       	call   f01000a0 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f01009fa:	8d 55 d8             	lea    -0x28(%ebp),%edx
f01009fd:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100a00:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100a03:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100a06:	89 c2                	mov    %eax,%edx
f0100a08:	2b 15 0c db 17 f0    	sub    0xf017db0c,%edx
f0100a0e:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100a14:	0f 95 c2             	setne  %dl
f0100a17:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100a1a:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100a1e:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100a20:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a24:	8b 00                	mov    (%eax),%eax
f0100a26:	85 c0                	test   %eax,%eax
f0100a28:	75 dc                	jne    f0100a06 <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100a2a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a2d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100a33:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a36:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100a39:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100a3b:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100a3e:	a3 40 ce 17 f0       	mov    %eax,0xf017ce40
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a43:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a48:	8b 1d 40 ce 17 f0    	mov    0xf017ce40,%ebx
f0100a4e:	eb 53                	jmp    f0100aa3 <check_page_free_list+0xd6>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a50:	89 d8                	mov    %ebx,%eax
f0100a52:	2b 05 0c db 17 f0    	sub    0xf017db0c,%eax
f0100a58:	c1 f8 03             	sar    $0x3,%eax
f0100a5b:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100a5e:	89 c2                	mov    %eax,%edx
f0100a60:	c1 ea 16             	shr    $0x16,%edx
f0100a63:	39 f2                	cmp    %esi,%edx
f0100a65:	73 3a                	jae    f0100aa1 <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a67:	89 c2                	mov    %eax,%edx
f0100a69:	c1 ea 0c             	shr    $0xc,%edx
f0100a6c:	3b 15 04 db 17 f0    	cmp    0xf017db04,%edx
f0100a72:	72 12                	jb     f0100a86 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a74:	50                   	push   %eax
f0100a75:	68 7c 50 10 f0       	push   $0xf010507c
f0100a7a:	6a 56                	push   $0x56
f0100a7c:	68 7e 4d 10 f0       	push   $0xf0104d7e
f0100a81:	e8 1a f6 ff ff       	call   f01000a0 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100a86:	83 ec 04             	sub    $0x4,%esp
f0100a89:	68 80 00 00 00       	push   $0x80
f0100a8e:	68 97 00 00 00       	push   $0x97
f0100a93:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100a98:	50                   	push   %eax
f0100a99:	e8 15 39 00 00       	call   f01043b3 <memset>
f0100a9e:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100aa1:	8b 1b                	mov    (%ebx),%ebx
f0100aa3:	85 db                	test   %ebx,%ebx
f0100aa5:	75 a9                	jne    f0100a50 <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100aa7:	b8 00 00 00 00       	mov    $0x0,%eax
f0100aac:	e8 4a fe ff ff       	call   f01008fb <boot_alloc>
f0100ab1:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ab4:	8b 15 40 ce 17 f0    	mov    0xf017ce40,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100aba:	8b 0d 0c db 17 f0    	mov    0xf017db0c,%ecx
		assert(pp < pages + npages);
f0100ac0:	a1 04 db 17 f0       	mov    0xf017db04,%eax
f0100ac5:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100ac8:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100acb:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100ace:	be 00 00 00 00       	mov    $0x0,%esi
f0100ad3:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ad6:	e9 30 01 00 00       	jmp    f0100c0b <check_page_free_list+0x23e>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100adb:	39 ca                	cmp    %ecx,%edx
f0100add:	73 19                	jae    f0100af8 <check_page_free_list+0x12b>
f0100adf:	68 8c 4d 10 f0       	push   $0xf0104d8c
f0100ae4:	68 98 4d 10 f0       	push   $0xf0104d98
f0100ae9:	68 82 02 00 00       	push   $0x282
f0100aee:	68 72 4d 10 f0       	push   $0xf0104d72
f0100af3:	e8 a8 f5 ff ff       	call   f01000a0 <_panic>
		assert(pp < pages + npages);
f0100af8:	39 fa                	cmp    %edi,%edx
f0100afa:	72 19                	jb     f0100b15 <check_page_free_list+0x148>
f0100afc:	68 ad 4d 10 f0       	push   $0xf0104dad
f0100b01:	68 98 4d 10 f0       	push   $0xf0104d98
f0100b06:	68 83 02 00 00       	push   $0x283
f0100b0b:	68 72 4d 10 f0       	push   $0xf0104d72
f0100b10:	e8 8b f5 ff ff       	call   f01000a0 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b15:	89 d0                	mov    %edx,%eax
f0100b17:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100b1a:	a8 07                	test   $0x7,%al
f0100b1c:	74 19                	je     f0100b37 <check_page_free_list+0x16a>
f0100b1e:	68 c4 50 10 f0       	push   $0xf01050c4
f0100b23:	68 98 4d 10 f0       	push   $0xf0104d98
f0100b28:	68 84 02 00 00       	push   $0x284
f0100b2d:	68 72 4d 10 f0       	push   $0xf0104d72
f0100b32:	e8 69 f5 ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b37:	c1 f8 03             	sar    $0x3,%eax
f0100b3a:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100b3d:	85 c0                	test   %eax,%eax
f0100b3f:	75 19                	jne    f0100b5a <check_page_free_list+0x18d>
f0100b41:	68 c1 4d 10 f0       	push   $0xf0104dc1
f0100b46:	68 98 4d 10 f0       	push   $0xf0104d98
f0100b4b:	68 87 02 00 00       	push   $0x287
f0100b50:	68 72 4d 10 f0       	push   $0xf0104d72
f0100b55:	e8 46 f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b5a:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b5f:	75 19                	jne    f0100b7a <check_page_free_list+0x1ad>
f0100b61:	68 d2 4d 10 f0       	push   $0xf0104dd2
f0100b66:	68 98 4d 10 f0       	push   $0xf0104d98
f0100b6b:	68 88 02 00 00       	push   $0x288
f0100b70:	68 72 4d 10 f0       	push   $0xf0104d72
f0100b75:	e8 26 f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100b7a:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100b7f:	75 19                	jne    f0100b9a <check_page_free_list+0x1cd>
f0100b81:	68 f8 50 10 f0       	push   $0xf01050f8
f0100b86:	68 98 4d 10 f0       	push   $0xf0104d98
f0100b8b:	68 89 02 00 00       	push   $0x289
f0100b90:	68 72 4d 10 f0       	push   $0xf0104d72
f0100b95:	e8 06 f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100b9a:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100b9f:	75 19                	jne    f0100bba <check_page_free_list+0x1ed>
f0100ba1:	68 eb 4d 10 f0       	push   $0xf0104deb
f0100ba6:	68 98 4d 10 f0       	push   $0xf0104d98
f0100bab:	68 8a 02 00 00       	push   $0x28a
f0100bb0:	68 72 4d 10 f0       	push   $0xf0104d72
f0100bb5:	e8 e6 f4 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100bba:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100bbf:	76 3f                	jbe    f0100c00 <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100bc1:	89 c3                	mov    %eax,%ebx
f0100bc3:	c1 eb 0c             	shr    $0xc,%ebx
f0100bc6:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100bc9:	77 12                	ja     f0100bdd <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100bcb:	50                   	push   %eax
f0100bcc:	68 7c 50 10 f0       	push   $0xf010507c
f0100bd1:	6a 56                	push   $0x56
f0100bd3:	68 7e 4d 10 f0       	push   $0xf0104d7e
f0100bd8:	e8 c3 f4 ff ff       	call   f01000a0 <_panic>
f0100bdd:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100be2:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100be5:	76 1e                	jbe    f0100c05 <check_page_free_list+0x238>
f0100be7:	68 1c 51 10 f0       	push   $0xf010511c
f0100bec:	68 98 4d 10 f0       	push   $0xf0104d98
f0100bf1:	68 8b 02 00 00       	push   $0x28b
f0100bf6:	68 72 4d 10 f0       	push   $0xf0104d72
f0100bfb:	e8 a0 f4 ff ff       	call   f01000a0 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100c00:	83 c6 01             	add    $0x1,%esi
f0100c03:	eb 04                	jmp    f0100c09 <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f0100c05:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c09:	8b 12                	mov    (%edx),%edx
f0100c0b:	85 d2                	test   %edx,%edx
f0100c0d:	0f 85 c8 fe ff ff    	jne    f0100adb <check_page_free_list+0x10e>
f0100c13:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100c16:	85 f6                	test   %esi,%esi
f0100c18:	7f 19                	jg     f0100c33 <check_page_free_list+0x266>
f0100c1a:	68 05 4e 10 f0       	push   $0xf0104e05
f0100c1f:	68 98 4d 10 f0       	push   $0xf0104d98
f0100c24:	68 93 02 00 00       	push   $0x293
f0100c29:	68 72 4d 10 f0       	push   $0xf0104d72
f0100c2e:	e8 6d f4 ff ff       	call   f01000a0 <_panic>
	assert(nfree_extmem > 0);
f0100c33:	85 db                	test   %ebx,%ebx
f0100c35:	7f 42                	jg     f0100c79 <check_page_free_list+0x2ac>
f0100c37:	68 17 4e 10 f0       	push   $0xf0104e17
f0100c3c:	68 98 4d 10 f0       	push   $0xf0104d98
f0100c41:	68 94 02 00 00       	push   $0x294
f0100c46:	68 72 4d 10 f0       	push   $0xf0104d72
f0100c4b:	e8 50 f4 ff ff       	call   f01000a0 <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100c50:	a1 40 ce 17 f0       	mov    0xf017ce40,%eax
f0100c55:	85 c0                	test   %eax,%eax
f0100c57:	0f 85 9d fd ff ff    	jne    f01009fa <check_page_free_list+0x2d>
f0100c5d:	e9 81 fd ff ff       	jmp    f01009e3 <check_page_free_list+0x16>
f0100c62:	83 3d 40 ce 17 f0 00 	cmpl   $0x0,0xf017ce40
f0100c69:	0f 84 74 fd ff ff    	je     f01009e3 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c6f:	be 00 04 00 00       	mov    $0x400,%esi
f0100c74:	e9 cf fd ff ff       	jmp    f0100a48 <check_page_free_list+0x7b>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100c79:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c7c:	5b                   	pop    %ebx
f0100c7d:	5e                   	pop    %esi
f0100c7e:	5f                   	pop    %edi
f0100c7f:	5d                   	pop    %ebp
f0100c80:	c3                   	ret    

f0100c81 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100c81:	55                   	push   %ebp
f0100c82:	89 e5                	mov    %esp,%ebp
f0100c84:	57                   	push   %edi
f0100c85:	56                   	push   %esi
f0100c86:	53                   	push   %ebx
f0100c87:	83 ec 1c             	sub    $0x1c,%esp
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	uint32_t nextfree = (uint32_t)boot_alloc(0);
f0100c8a:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c8f:	e8 67 fc ff ff       	call   f01008fb <boot_alloc>
	for (i = 0; i < npages; i++) {
		if(i == 0) { 
			pages[i].pp_ref = 1; 
			pages[i].pp_link = NULL;
		} else if(i < npages_basemem) {   
f0100c94:	8b 35 44 ce 17 f0    	mov    0xf017ce44,%esi
f0100c9a:	8b 1d 40 ce 17 f0    	mov    0xf017ce40,%ebx
			pages[i].pp_ref = 0; 
            		pages[i].pp_link = page_free_list;
           		 page_free_list = &pages[i];
		} else if(i >= IOPHYSMEM/PGSIZE && i < EXTPHYSMEM/PGSIZE) { 
			pages[i].pp_ref = 1; 
		} else  if (i >= IOPHYSMEM / PGSIZE && i < (nextfree - KERNBASE)/ PGSIZE) { 
f0100ca0:	05 00 00 00 10       	add    $0x10000000,%eax
f0100ca5:	c1 e8 0c             	shr    $0xc,%eax
f0100ca8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	uint32_t nextfree = (uint32_t)boot_alloc(0);
	for (i = 0; i < npages; i++) {
f0100cab:	ba 00 00 00 00       	mov    $0x0,%edx
f0100cb0:	bf 00 00 00 00       	mov    $0x0,%edi
f0100cb5:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cba:	e9 9a 00 00 00       	jmp    f0100d59 <page_init+0xd8>
		if(i == 0) { 
f0100cbf:	85 c0                	test   %eax,%eax
f0100cc1:	75 14                	jne    f0100cd7 <page_init+0x56>
			pages[i].pp_ref = 1; 
f0100cc3:	8b 0d 0c db 17 f0    	mov    0xf017db0c,%ecx
f0100cc9:	66 c7 41 04 01 00    	movw   $0x1,0x4(%ecx)
			pages[i].pp_link = NULL;
f0100ccf:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
f0100cd5:	eb 7c                	jmp    f0100d53 <page_init+0xd2>
		} else if(i < npages_basemem) {   
f0100cd7:	39 f0                	cmp    %esi,%eax
f0100cd9:	73 1f                	jae    f0100cfa <page_init+0x79>
			pages[i].pp_ref = 0; 
f0100cdb:	89 d1                	mov    %edx,%ecx
f0100cdd:	03 0d 0c db 17 f0    	add    0xf017db0c,%ecx
f0100ce3:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
            		pages[i].pp_link = page_free_list;
f0100ce9:	89 19                	mov    %ebx,(%ecx)
           		 page_free_list = &pages[i];
f0100ceb:	89 d3                	mov    %edx,%ebx
f0100ced:	03 1d 0c db 17 f0    	add    0xf017db0c,%ebx
f0100cf3:	bf 01 00 00 00       	mov    $0x1,%edi
f0100cf8:	eb 59                	jmp    f0100d53 <page_init+0xd2>
		} else if(i >= IOPHYSMEM/PGSIZE && i < EXTPHYSMEM/PGSIZE) { 
f0100cfa:	8d 88 60 ff ff ff    	lea    -0xa0(%eax),%ecx
f0100d00:	83 f9 5f             	cmp    $0x5f,%ecx
f0100d03:	77 0f                	ja     f0100d14 <page_init+0x93>
			pages[i].pp_ref = 1; 
f0100d05:	8b 0d 0c db 17 f0    	mov    0xf017db0c,%ecx
f0100d0b:	66 c7 44 11 04 01 00 	movw   $0x1,0x4(%ecx,%edx,1)
f0100d12:	eb 3f                	jmp    f0100d53 <page_init+0xd2>
		} else  if (i >= IOPHYSMEM / PGSIZE && i < (nextfree - KERNBASE)/ PGSIZE) { 
f0100d14:	3d 9f 00 00 00       	cmp    $0x9f,%eax
f0100d19:	76 1b                	jbe    f0100d36 <page_init+0xb5>
f0100d1b:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
f0100d1e:	73 16                	jae    f0100d36 <page_init+0xb5>
            		pages[i].pp_ref = 1;
f0100d20:	89 d1                	mov    %edx,%ecx
f0100d22:	03 0d 0c db 17 f0    	add    0xf017db0c,%ecx
f0100d28:	66 c7 41 04 01 00    	movw   $0x1,0x4(%ecx)
            		pages[i].pp_link = NULL;
f0100d2e:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
f0100d34:	eb 1d                	jmp    f0100d53 <page_init+0xd2>
       		} else {
			pages[i].pp_ref = 0;
f0100d36:	89 d1                	mov    %edx,%ecx
f0100d38:	03 0d 0c db 17 f0    	add    0xf017db0c,%ecx
f0100d3e:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
            		pages[i].pp_link = page_free_list;
f0100d44:	89 19                	mov    %ebx,(%ecx)
            		page_free_list = &pages[i];
f0100d46:	89 d3                	mov    %edx,%ebx
f0100d48:	03 1d 0c db 17 f0    	add    0xf017db0c,%ebx
f0100d4e:	bf 01 00 00 00       	mov    $0x1,%edi
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	uint32_t nextfree = (uint32_t)boot_alloc(0);
	for (i = 0; i < npages; i++) {
f0100d53:	83 c0 01             	add    $0x1,%eax
f0100d56:	83 c2 08             	add    $0x8,%edx
f0100d59:	3b 05 04 db 17 f0    	cmp    0xf017db04,%eax
f0100d5f:	0f 82 5a ff ff ff    	jb     f0100cbf <page_init+0x3e>
f0100d65:	89 f8                	mov    %edi,%eax
f0100d67:	84 c0                	test   %al,%al
f0100d69:	74 06                	je     f0100d71 <page_init+0xf0>
f0100d6b:	89 1d 40 ce 17 f0    	mov    %ebx,0xf017ce40
			pages[i].pp_ref = 0;
            		pages[i].pp_link = page_free_list;
            		page_free_list = &pages[i];
		}
	}
}
f0100d71:	83 c4 1c             	add    $0x1c,%esp
f0100d74:	5b                   	pop    %ebx
f0100d75:	5e                   	pop    %esi
f0100d76:	5f                   	pop    %edi
f0100d77:	5d                   	pop    %ebp
f0100d78:	c3                   	ret    

f0100d79 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100d79:	55                   	push   %ebp
f0100d7a:	89 e5                	mov    %esp,%ebp
f0100d7c:	53                   	push   %ebx
f0100d7d:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in
	struct PageInfo *NewPage;
	if(page_free_list == NULL) {
f0100d80:	8b 1d 40 ce 17 f0    	mov    0xf017ce40,%ebx
f0100d86:	85 db                	test   %ebx,%ebx
f0100d88:	74 58                	je     f0100de2 <page_alloc+0x69>
		return NULL; 
	}
	NewPage = page_free_list; 
	page_free_list = page_free_list->pp_link; 
f0100d8a:	8b 03                	mov    (%ebx),%eax
f0100d8c:	a3 40 ce 17 f0       	mov    %eax,0xf017ce40
	NewPage->pp_link = NULL;
f0100d91:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if (alloc_flags & ALLOC_ZERO) {
f0100d97:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100d9b:	74 45                	je     f0100de2 <page_alloc+0x69>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100d9d:	89 d8                	mov    %ebx,%eax
f0100d9f:	2b 05 0c db 17 f0    	sub    0xf017db0c,%eax
f0100da5:	c1 f8 03             	sar    $0x3,%eax
f0100da8:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100dab:	89 c2                	mov    %eax,%edx
f0100dad:	c1 ea 0c             	shr    $0xc,%edx
f0100db0:	3b 15 04 db 17 f0    	cmp    0xf017db04,%edx
f0100db6:	72 12                	jb     f0100dca <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100db8:	50                   	push   %eax
f0100db9:	68 7c 50 10 f0       	push   $0xf010507c
f0100dbe:	6a 56                	push   $0x56
f0100dc0:	68 7e 4d 10 f0       	push   $0xf0104d7e
f0100dc5:	e8 d6 f2 ff ff       	call   f01000a0 <_panic>
		memset(page2kva(NewPage), 0, PGSIZE);
f0100dca:	83 ec 04             	sub    $0x4,%esp
f0100dcd:	68 00 10 00 00       	push   $0x1000
f0100dd2:	6a 00                	push   $0x0
f0100dd4:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100dd9:	50                   	push   %eax
f0100dda:	e8 d4 35 00 00       	call   f01043b3 <memset>
f0100ddf:	83 c4 10             	add    $0x10,%esp
	}
	return NewPage; 
}
f0100de2:	89 d8                	mov    %ebx,%eax
f0100de4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100de7:	c9                   	leave  
f0100de8:	c3                   	ret    

f0100de9 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100de9:	55                   	push   %ebp
f0100dea:	89 e5                	mov    %esp,%ebp
f0100dec:	83 ec 08             	sub    $0x8,%esp
f0100def:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	assert(pp->pp_ref == 0); 
f0100df2:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100df7:	74 19                	je     f0100e12 <page_free+0x29>
f0100df9:	68 28 4e 10 f0       	push   $0xf0104e28
f0100dfe:	68 98 4d 10 f0       	push   $0xf0104d98
f0100e03:	68 54 01 00 00       	push   $0x154
f0100e08:	68 72 4d 10 f0       	push   $0xf0104d72
f0100e0d:	e8 8e f2 ff ff       	call   f01000a0 <_panic>
	assert(pp->pp_link == NULL);
f0100e12:	83 38 00             	cmpl   $0x0,(%eax)
f0100e15:	74 19                	je     f0100e30 <page_free+0x47>
f0100e17:	68 38 4e 10 f0       	push   $0xf0104e38
f0100e1c:	68 98 4d 10 f0       	push   $0xf0104d98
f0100e21:	68 55 01 00 00       	push   $0x155
f0100e26:	68 72 4d 10 f0       	push   $0xf0104d72
f0100e2b:	e8 70 f2 ff ff       	call   f01000a0 <_panic>
	pp->pp_link = page_free_list;
f0100e30:	8b 15 40 ce 17 f0    	mov    0xf017ce40,%edx
f0100e36:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100e38:	a3 40 ce 17 f0       	mov    %eax,0xf017ce40
}
f0100e3d:	c9                   	leave  
f0100e3e:	c3                   	ret    

f0100e3f <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100e3f:	55                   	push   %ebp
f0100e40:	89 e5                	mov    %esp,%ebp
f0100e42:	83 ec 08             	sub    $0x8,%esp
f0100e45:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100e48:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100e4c:	83 e8 01             	sub    $0x1,%eax
f0100e4f:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100e53:	66 85 c0             	test   %ax,%ax
f0100e56:	75 0c                	jne    f0100e64 <page_decref+0x25>
		page_free(pp);
f0100e58:	83 ec 0c             	sub    $0xc,%esp
f0100e5b:	52                   	push   %edx
f0100e5c:	e8 88 ff ff ff       	call   f0100de9 <page_free>
f0100e61:	83 c4 10             	add    $0x10,%esp
}
f0100e64:	c9                   	leave  
f0100e65:	c3                   	ret    

f0100e66 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100e66:	55                   	push   %ebp
f0100e67:	89 e5                	mov    %esp,%ebp
f0100e69:	56                   	push   %esi
f0100e6a:	53                   	push   %ebx
f0100e6b:	8b 45 0c             	mov    0xc(%ebp),%eax
	// Fill this function in
    int pd_index = PDX(va); 
    int pte_index = PTX(va);
f0100e6e:	89 c6                	mov    %eax,%esi
f0100e70:	c1 ee 0c             	shr    $0xc,%esi
f0100e73:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
    if (pgdir[pd_index] & PTE_P) {  
f0100e79:	c1 e8 16             	shr    $0x16,%eax
f0100e7c:	8d 1c 85 00 00 00 00 	lea    0x0(,%eax,4),%ebx
f0100e83:	03 5d 08             	add    0x8(%ebp),%ebx
f0100e86:	8b 03                	mov    (%ebx),%eax
f0100e88:	a8 01                	test   $0x1,%al
f0100e8a:	74 30                	je     f0100ebc <pgdir_walk+0x56>
        pte_t *pt_addr_v = KADDR(PTE_ADDR(pgdir[pd_index]));
f0100e8c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e91:	89 c2                	mov    %eax,%edx
f0100e93:	c1 ea 0c             	shr    $0xc,%edx
f0100e96:	39 15 04 db 17 f0    	cmp    %edx,0xf017db04
f0100e9c:	77 15                	ja     f0100eb3 <pgdir_walk+0x4d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e9e:	50                   	push   %eax
f0100e9f:	68 7c 50 10 f0       	push   $0xf010507c
f0100ea4:	68 82 01 00 00       	push   $0x182
f0100ea9:	68 72 4d 10 f0       	push   $0xf0104d72
f0100eae:	e8 ed f1 ff ff       	call   f01000a0 <_panic>
        return (pte_t*)(pt_addr_v + pte_index);
f0100eb3:	8d 84 b0 00 00 00 f0 	lea    -0x10000000(%eax,%esi,4),%eax
f0100eba:	eb 6b                	jmp    f0100f27 <pgdir_walk+0xc1>
    } else {           
        if (create) {
f0100ebc:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100ec0:	74 59                	je     f0100f1b <pgdir_walk+0xb5>
	    struct PageInfo *NewPt = page_alloc(ALLOC_ZERO); 
f0100ec2:	83 ec 0c             	sub    $0xc,%esp
f0100ec5:	6a 01                	push   $0x1
f0100ec7:	e8 ad fe ff ff       	call   f0100d79 <page_alloc>
	    if(NewPt == NULL)
f0100ecc:	83 c4 10             	add    $0x10,%esp
f0100ecf:	85 c0                	test   %eax,%eax
f0100ed1:	74 4f                	je     f0100f22 <pgdir_walk+0xbc>
		return NULL;
            NewPt->pp_ref++;
f0100ed3:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ed8:	2b 05 0c db 17 f0    	sub    0xf017db0c,%eax
f0100ede:	c1 f8 03             	sar    $0x3,%eax
f0100ee1:	c1 e0 0c             	shl    $0xc,%eax
            pgdir[pd_index] = page2pa(NewPt)|PTE_U|PTE_W|PTE_P; 
f0100ee4:	89 c2                	mov    %eax,%edx
f0100ee6:	83 ca 07             	or     $0x7,%edx
f0100ee9:	89 13                	mov    %edx,(%ebx)
f0100eeb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ef0:	89 c2                	mov    %eax,%edx
f0100ef2:	c1 ea 0c             	shr    $0xc,%edx
f0100ef5:	3b 15 04 db 17 f0    	cmp    0xf017db04,%edx
f0100efb:	72 15                	jb     f0100f12 <pgdir_walk+0xac>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100efd:	50                   	push   %eax
f0100efe:	68 7c 50 10 f0       	push   $0xf010507c
f0100f03:	68 8b 01 00 00       	push   $0x18b
f0100f08:	68 72 4d 10 f0       	push   $0xf0104d72
f0100f0d:	e8 8e f1 ff ff       	call   f01000a0 <_panic>
            pte_t *pt_addr_v = KADDR(PTE_ADDR(pgdir[pd_index]));
            return (pte_t*)(pt_addr_v + pte_index);
f0100f12:	8d 84 b0 00 00 00 f0 	lea    -0x10000000(%eax,%esi,4),%eax
f0100f19:	eb 0c                	jmp    f0100f27 <pgdir_walk+0xc1>
        } else return NULL;
f0100f1b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f20:	eb 05                	jmp    f0100f27 <pgdir_walk+0xc1>
        return (pte_t*)(pt_addr_v + pte_index);
    } else {           
        if (create) {
	    struct PageInfo *NewPt = page_alloc(ALLOC_ZERO); 
	    if(NewPt == NULL)
		return NULL;
f0100f22:	b8 00 00 00 00       	mov    $0x0,%eax
            pgdir[pd_index] = page2pa(NewPt)|PTE_U|PTE_W|PTE_P; 
            pte_t *pt_addr_v = KADDR(PTE_ADDR(pgdir[pd_index]));
            return (pte_t*)(pt_addr_v + pte_index);
        } else return NULL;
    }
}
f0100f27:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100f2a:	5b                   	pop    %ebx
f0100f2b:	5e                   	pop    %esi
f0100f2c:	5d                   	pop    %ebp
f0100f2d:	c3                   	ret    

f0100f2e <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100f2e:	55                   	push   %ebp
f0100f2f:	89 e5                	mov    %esp,%ebp
f0100f31:	57                   	push   %edi
f0100f32:	56                   	push   %esi
f0100f33:	53                   	push   %ebx
f0100f34:	83 ec 1c             	sub    $0x1c,%esp
f0100f37:	89 45 e0             	mov    %eax,-0x20(%ebp)
	// Fill this function in
    size = ROUNDUP(size, PGSIZE);
f0100f3a:	81 c1 ff 0f 00 00    	add    $0xfff,%ecx
    size_t page_num = PGNUM(size);
f0100f40:	c1 e9 0c             	shr    $0xc,%ecx
f0100f43:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
    for (size_t i = 0; i < page_num; i++) {
f0100f46:	89 d3                	mov    %edx,%ebx
f0100f48:	be 00 00 00 00       	mov    $0x0,%esi
        pte_t *pgtable_entry_ptr = pgdir_walk(pgdir, (char *)(va + i * PGSIZE), true);
        *pgtable_entry_ptr = (pa + i * PGSIZE) | perm | PTE_P;
f0100f4d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100f50:	29 d7                	sub    %edx,%edi
f0100f52:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f55:	83 c8 01             	or     $0x1,%eax
f0100f58:	89 45 dc             	mov    %eax,-0x24(%ebp)
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
    size = ROUNDUP(size, PGSIZE);
    size_t page_num = PGNUM(size);
    for (size_t i = 0; i < page_num; i++) {
f0100f5b:	eb 22                	jmp    f0100f7f <boot_map_region+0x51>
        pte_t *pgtable_entry_ptr = pgdir_walk(pgdir, (char *)(va + i * PGSIZE), true);
f0100f5d:	83 ec 04             	sub    $0x4,%esp
f0100f60:	6a 01                	push   $0x1
f0100f62:	53                   	push   %ebx
f0100f63:	ff 75 e0             	pushl  -0x20(%ebp)
f0100f66:	e8 fb fe ff ff       	call   f0100e66 <pgdir_walk>
        *pgtable_entry_ptr = (pa + i * PGSIZE) | perm | PTE_P;
f0100f6b:	8d 14 1f             	lea    (%edi,%ebx,1),%edx
f0100f6e:	0b 55 dc             	or     -0x24(%ebp),%edx
f0100f71:	89 10                	mov    %edx,(%eax)
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
    size = ROUNDUP(size, PGSIZE);
    size_t page_num = PGNUM(size);
    for (size_t i = 0; i < page_num; i++) {
f0100f73:	83 c6 01             	add    $0x1,%esi
f0100f76:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100f7c:	83 c4 10             	add    $0x10,%esp
f0100f7f:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0100f82:	75 d9                	jne    f0100f5d <boot_map_region+0x2f>
        pte_t *pgtable_entry_ptr = pgdir_walk(pgdir, (char *)(va + i * PGSIZE), true);
        *pgtable_entry_ptr = (pa + i * PGSIZE) | perm | PTE_P;
    }
}
f0100f84:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f87:	5b                   	pop    %ebx
f0100f88:	5e                   	pop    %esi
f0100f89:	5f                   	pop    %edi
f0100f8a:	5d                   	pop    %ebp
f0100f8b:	c3                   	ret    

f0100f8c <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100f8c:	55                   	push   %ebp
f0100f8d:	89 e5                	mov    %esp,%ebp
f0100f8f:	53                   	push   %ebx
f0100f90:	83 ec 08             	sub    $0x8,%esp
f0100f93:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, 0);
f0100f96:	6a 00                	push   $0x0
f0100f98:	ff 75 0c             	pushl  0xc(%ebp)
f0100f9b:	ff 75 08             	pushl  0x8(%ebp)
f0100f9e:	e8 c3 fe ff ff       	call   f0100e66 <pgdir_walk>
	if(pte == NULL) { 
f0100fa3:	83 c4 10             	add    $0x10,%esp
f0100fa6:	85 c0                	test   %eax,%eax
f0100fa8:	74 32                	je     f0100fdc <page_lookup+0x50>
		return NULL;
	} else if(pte_store != 0){
f0100faa:	85 db                	test   %ebx,%ebx
f0100fac:	74 02                	je     f0100fb0 <page_lookup+0x24>
		*pte_store = pte; 
f0100fae:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fb0:	8b 00                	mov    (%eax),%eax
f0100fb2:	c1 e8 0c             	shr    $0xc,%eax
f0100fb5:	3b 05 04 db 17 f0    	cmp    0xf017db04,%eax
f0100fbb:	72 14                	jb     f0100fd1 <page_lookup+0x45>
		panic("pa2page called with invalid pa");
f0100fbd:	83 ec 04             	sub    $0x4,%esp
f0100fc0:	68 64 51 10 f0       	push   $0xf0105164
f0100fc5:	6a 4f                	push   $0x4f
f0100fc7:	68 7e 4d 10 f0       	push   $0xf0104d7e
f0100fcc:	e8 cf f0 ff ff       	call   f01000a0 <_panic>
	return &pages[PGNUM(pa)];
f0100fd1:	8b 15 0c db 17 f0    	mov    0xf017db0c,%edx
f0100fd7:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	}
	return pa2page(PTE_ADDR(*pte));
f0100fda:	eb 05                	jmp    f0100fe1 <page_lookup+0x55>
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, 0);
	if(pte == NULL) { 
		return NULL;
f0100fdc:	b8 00 00 00 00       	mov    $0x0,%eax
	} else if(pte_store != 0){
		*pte_store = pte; 
	}
	return pa2page(PTE_ADDR(*pte));
}
f0100fe1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100fe4:	c9                   	leave  
f0100fe5:	c3                   	ret    

f0100fe6 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100fe6:	55                   	push   %ebp
f0100fe7:	89 e5                	mov    %esp,%ebp
f0100fe9:	53                   	push   %ebx
f0100fea:	83 ec 18             	sub    $0x18,%esp
f0100fed:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t *pte;
	struct PageInfo *Fpage = page_lookup(pgdir, va, &pte);
f0100ff0:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100ff3:	50                   	push   %eax
f0100ff4:	53                   	push   %ebx
f0100ff5:	ff 75 08             	pushl  0x8(%ebp)
f0100ff8:	e8 8f ff ff ff       	call   f0100f8c <page_lookup>
	if(Fpage == NULL){ 
f0100ffd:	83 c4 10             	add    $0x10,%esp
f0101000:	85 c0                	test   %eax,%eax
f0101002:	74 18                	je     f010101c <page_remove+0x36>
		return;
	}
	page_decref(Fpage); 
f0101004:	83 ec 0c             	sub    $0xc,%esp
f0101007:	50                   	push   %eax
f0101008:	e8 32 fe ff ff       	call   f0100e3f <page_decref>
	*pte = 0;
f010100d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101010:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101016:	0f 01 3b             	invlpg (%ebx)
f0101019:	83 c4 10             	add    $0x10,%esp
	tlb_invalidate(pgdir, va);
}
f010101c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010101f:	c9                   	leave  
f0101020:	c3                   	ret    

f0101021 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0101021:	55                   	push   %ebp
f0101022:	89 e5                	mov    %esp,%ebp
f0101024:	57                   	push   %edi
f0101025:	56                   	push   %esi
f0101026:	53                   	push   %ebx
f0101027:	83 ec 10             	sub    $0x10,%esp
f010102a:	8b 75 08             	mov    0x8(%ebp),%esi
f010102d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
    pte_t *pte = pgdir_walk(pgdir, va, 1);
f0101030:	6a 01                	push   $0x1
f0101032:	ff 75 10             	pushl  0x10(%ebp)
f0101035:	56                   	push   %esi
f0101036:	e8 2b fe ff ff       	call   f0100e66 <pgdir_walk>
    if (pte == NULL) { 
f010103b:	83 c4 10             	add    $0x10,%esp
f010103e:	85 c0                	test   %eax,%eax
f0101040:	74 6b                	je     f01010ad <page_insert+0x8c>
f0101042:	89 c7                	mov    %eax,%edi
        return -E_NO_MEM;
    }  
    if (*pte & PTE_P) { 
f0101044:	8b 00                	mov    (%eax),%eax
f0101046:	a8 01                	test   $0x1,%al
f0101048:	74 33                	je     f010107d <page_insert+0x5c>
        if (PTE_ADDR(*pte) == page2pa(pp)) { 
f010104a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010104f:	89 da                	mov    %ebx,%edx
f0101051:	2b 15 0c db 17 f0    	sub    0xf017db0c,%edx
f0101057:	c1 fa 03             	sar    $0x3,%edx
f010105a:	c1 e2 0c             	shl    $0xc,%edx
f010105d:	39 d0                	cmp    %edx,%eax
f010105f:	75 0d                	jne    f010106e <page_insert+0x4d>
f0101061:	8b 45 10             	mov    0x10(%ebp),%eax
f0101064:	0f 01 38             	invlpg (%eax)
            tlb_invalidate(pgdir, va); 
            pp->pp_ref--;
f0101067:	66 83 6b 04 01       	subw   $0x1,0x4(%ebx)
f010106c:	eb 0f                	jmp    f010107d <page_insert+0x5c>
        }
        else {
            page_remove(pgdir, va);
f010106e:	83 ec 08             	sub    $0x8,%esp
f0101071:	ff 75 10             	pushl  0x10(%ebp)
f0101074:	56                   	push   %esi
f0101075:	e8 6c ff ff ff       	call   f0100fe6 <page_remove>
f010107a:	83 c4 10             	add    $0x10,%esp
        }
    }
    *pte = page2pa(pp) | perm | PTE_P;
f010107d:	89 d8                	mov    %ebx,%eax
f010107f:	2b 05 0c db 17 f0    	sub    0xf017db0c,%eax
f0101085:	c1 f8 03             	sar    $0x3,%eax
f0101088:	c1 e0 0c             	shl    $0xc,%eax
f010108b:	8b 55 14             	mov    0x14(%ebp),%edx
f010108e:	83 ca 01             	or     $0x1,%edx
f0101091:	09 d0                	or     %edx,%eax
f0101093:	89 07                	mov    %eax,(%edi)
    pp->pp_ref++;
f0101095:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
    pgdir[PDX(va)] |= perm;
f010109a:	8b 45 10             	mov    0x10(%ebp),%eax
f010109d:	c1 e8 16             	shr    $0x16,%eax
f01010a0:	8b 4d 14             	mov    0x14(%ebp),%ecx
f01010a3:	09 0c 86             	or     %ecx,(%esi,%eax,4)
    return 0;
f01010a6:	b8 00 00 00 00       	mov    $0x0,%eax
f01010ab:	eb 05                	jmp    f01010b2 <page_insert+0x91>
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	// Fill this function in
    pte_t *pte = pgdir_walk(pgdir, va, 1);
    if (pte == NULL) { 
        return -E_NO_MEM;
f01010ad:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
    }
    *pte = page2pa(pp) | perm | PTE_P;
    pp->pp_ref++;
    pgdir[PDX(va)] |= perm;
    return 0;
}
f01010b2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01010b5:	5b                   	pop    %ebx
f01010b6:	5e                   	pop    %esi
f01010b7:	5f                   	pop    %edi
f01010b8:	5d                   	pop    %ebp
f01010b9:	c3                   	ret    

f01010ba <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01010ba:	55                   	push   %ebp
f01010bb:	89 e5                	mov    %esp,%ebp
f01010bd:	57                   	push   %edi
f01010be:	56                   	push   %esi
f01010bf:	53                   	push   %ebx
f01010c0:	83 ec 38             	sub    $0x38,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01010c3:	6a 15                	push   $0x15
f01010c5:	e8 92 1e 00 00       	call   f0102f5c <mc146818_read>
f01010ca:	89 c3                	mov    %eax,%ebx
f01010cc:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f01010d3:	e8 84 1e 00 00       	call   f0102f5c <mc146818_read>
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f01010d8:	c1 e0 08             	shl    $0x8,%eax
f01010db:	09 d8                	or     %ebx,%eax
f01010dd:	c1 e0 0a             	shl    $0xa,%eax
f01010e0:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01010e6:	85 c0                	test   %eax,%eax
f01010e8:	0f 48 c2             	cmovs  %edx,%eax
f01010eb:	c1 f8 0c             	sar    $0xc,%eax
f01010ee:	a3 44 ce 17 f0       	mov    %eax,0xf017ce44
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01010f3:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f01010fa:	e8 5d 1e 00 00       	call   f0102f5c <mc146818_read>
f01010ff:	89 c3                	mov    %eax,%ebx
f0101101:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f0101108:	e8 4f 1e 00 00       	call   f0102f5c <mc146818_read>
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f010110d:	c1 e0 08             	shl    $0x8,%eax
f0101110:	09 d8                	or     %ebx,%eax
f0101112:	c1 e0 0a             	shl    $0xa,%eax
f0101115:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f010111b:	83 c4 10             	add    $0x10,%esp
f010111e:	85 c0                	test   %eax,%eax
f0101120:	0f 48 c2             	cmovs  %edx,%eax
f0101123:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0101126:	85 c0                	test   %eax,%eax
f0101128:	74 0e                	je     f0101138 <mem_init+0x7e>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f010112a:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0101130:	89 15 04 db 17 f0    	mov    %edx,0xf017db04
f0101136:	eb 0c                	jmp    f0101144 <mem_init+0x8a>
	else
		npages = npages_basemem;
f0101138:	8b 15 44 ce 17 f0    	mov    0xf017ce44,%edx
f010113e:	89 15 04 db 17 f0    	mov    %edx,0xf017db04

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101144:	c1 e0 0c             	shl    $0xc,%eax
f0101147:	c1 e8 0a             	shr    $0xa,%eax
f010114a:	50                   	push   %eax
f010114b:	a1 44 ce 17 f0       	mov    0xf017ce44,%eax
f0101150:	c1 e0 0c             	shl    $0xc,%eax
f0101153:	c1 e8 0a             	shr    $0xa,%eax
f0101156:	50                   	push   %eax
f0101157:	a1 04 db 17 f0       	mov    0xf017db04,%eax
f010115c:	c1 e0 0c             	shl    $0xc,%eax
f010115f:	c1 e8 0a             	shr    $0xa,%eax
f0101162:	50                   	push   %eax
f0101163:	68 84 51 10 f0       	push   $0xf0105184
f0101168:	e8 56 1e 00 00       	call   f0102fc3 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f010116d:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101172:	e8 84 f7 ff ff       	call   f01008fb <boot_alloc>
f0101177:	a3 08 db 17 f0       	mov    %eax,0xf017db08
	memset(kern_pgdir, 0, PGSIZE);
f010117c:	83 c4 0c             	add    $0xc,%esp
f010117f:	68 00 10 00 00       	push   $0x1000
f0101184:	6a 00                	push   $0x0
f0101186:	50                   	push   %eax
f0101187:	e8 27 32 00 00       	call   f01043b3 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f010118c:	a1 08 db 17 f0       	mov    0xf017db08,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101191:	83 c4 10             	add    $0x10,%esp
f0101194:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101199:	77 15                	ja     f01011b0 <mem_init+0xf6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010119b:	50                   	push   %eax
f010119c:	68 c0 51 10 f0       	push   $0xf01051c0
f01011a1:	68 96 00 00 00       	push   $0x96
f01011a6:	68 72 4d 10 f0       	push   $0xf0104d72
f01011ab:	e8 f0 ee ff ff       	call   f01000a0 <_panic>
f01011b0:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01011b6:	83 ca 05             	or     $0x5,%edx
f01011b9:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	uint32_t PageInfo_Size = sizeof(struct PageInfo) * npages; 
f01011bf:	a1 04 db 17 f0       	mov    0xf017db04,%eax
f01011c4:	c1 e0 03             	shl    $0x3,%eax
f01011c7:	89 c7                	mov    %eax,%edi
f01011c9:	89 45 cc             	mov    %eax,-0x34(%ebp)
	pages = (struct PageInfo*)boot_alloc(PageInfo_Size);
f01011cc:	e8 2a f7 ff ff       	call   f01008fb <boot_alloc>
f01011d1:	a3 0c db 17 f0       	mov    %eax,0xf017db0c
	memset(pages, 0, PageInfo_Size); 
f01011d6:	83 ec 04             	sub    $0x4,%esp
f01011d9:	57                   	push   %edi
f01011da:	6a 00                	push   $0x0
f01011dc:	50                   	push   %eax
f01011dd:	e8 d1 31 00 00       	call   f01043b3 <memset>

	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	uint32_t Env_size = sizeof(struct Env) * NENV; 
	envs = (struct Env*)boot_alloc(Env_size); 
f01011e2:	b8 00 80 01 00       	mov    $0x18000,%eax
f01011e7:	e8 0f f7 ff ff       	call   f01008fb <boot_alloc>
f01011ec:	a3 4c ce 17 f0       	mov    %eax,0xf017ce4c
    	memset(envs, 0, Env_size); 
f01011f1:	83 c4 0c             	add    $0xc,%esp
f01011f4:	68 00 80 01 00       	push   $0x18000
f01011f9:	6a 00                	push   $0x0
f01011fb:	50                   	push   %eax
f01011fc:	e8 b2 31 00 00       	call   f01043b3 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101201:	e8 7b fa ff ff       	call   f0100c81 <page_init>

	check_page_free_list(1);
f0101206:	b8 01 00 00 00       	mov    $0x1,%eax
f010120b:	e8 bd f7 ff ff       	call   f01009cd <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101210:	83 c4 10             	add    $0x10,%esp
f0101213:	83 3d 0c db 17 f0 00 	cmpl   $0x0,0xf017db0c
f010121a:	75 17                	jne    f0101233 <mem_init+0x179>
		panic("'pages' is a null pointer!");
f010121c:	83 ec 04             	sub    $0x4,%esp
f010121f:	68 4c 4e 10 f0       	push   $0xf0104e4c
f0101224:	68 a5 02 00 00       	push   $0x2a5
f0101229:	68 72 4d 10 f0       	push   $0xf0104d72
f010122e:	e8 6d ee ff ff       	call   f01000a0 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101233:	a1 40 ce 17 f0       	mov    0xf017ce40,%eax
f0101238:	bb 00 00 00 00       	mov    $0x0,%ebx
f010123d:	eb 05                	jmp    f0101244 <mem_init+0x18a>
		++nfree;
f010123f:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101242:	8b 00                	mov    (%eax),%eax
f0101244:	85 c0                	test   %eax,%eax
f0101246:	75 f7                	jne    f010123f <mem_init+0x185>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101248:	83 ec 0c             	sub    $0xc,%esp
f010124b:	6a 00                	push   $0x0
f010124d:	e8 27 fb ff ff       	call   f0100d79 <page_alloc>
f0101252:	89 c7                	mov    %eax,%edi
f0101254:	83 c4 10             	add    $0x10,%esp
f0101257:	85 c0                	test   %eax,%eax
f0101259:	75 19                	jne    f0101274 <mem_init+0x1ba>
f010125b:	68 67 4e 10 f0       	push   $0xf0104e67
f0101260:	68 98 4d 10 f0       	push   $0xf0104d98
f0101265:	68 ad 02 00 00       	push   $0x2ad
f010126a:	68 72 4d 10 f0       	push   $0xf0104d72
f010126f:	e8 2c ee ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0101274:	83 ec 0c             	sub    $0xc,%esp
f0101277:	6a 00                	push   $0x0
f0101279:	e8 fb fa ff ff       	call   f0100d79 <page_alloc>
f010127e:	89 c6                	mov    %eax,%esi
f0101280:	83 c4 10             	add    $0x10,%esp
f0101283:	85 c0                	test   %eax,%eax
f0101285:	75 19                	jne    f01012a0 <mem_init+0x1e6>
f0101287:	68 7d 4e 10 f0       	push   $0xf0104e7d
f010128c:	68 98 4d 10 f0       	push   $0xf0104d98
f0101291:	68 ae 02 00 00       	push   $0x2ae
f0101296:	68 72 4d 10 f0       	push   $0xf0104d72
f010129b:	e8 00 ee ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f01012a0:	83 ec 0c             	sub    $0xc,%esp
f01012a3:	6a 00                	push   $0x0
f01012a5:	e8 cf fa ff ff       	call   f0100d79 <page_alloc>
f01012aa:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01012ad:	83 c4 10             	add    $0x10,%esp
f01012b0:	85 c0                	test   %eax,%eax
f01012b2:	75 19                	jne    f01012cd <mem_init+0x213>
f01012b4:	68 93 4e 10 f0       	push   $0xf0104e93
f01012b9:	68 98 4d 10 f0       	push   $0xf0104d98
f01012be:	68 af 02 00 00       	push   $0x2af
f01012c3:	68 72 4d 10 f0       	push   $0xf0104d72
f01012c8:	e8 d3 ed ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01012cd:	39 f7                	cmp    %esi,%edi
f01012cf:	75 19                	jne    f01012ea <mem_init+0x230>
f01012d1:	68 a9 4e 10 f0       	push   $0xf0104ea9
f01012d6:	68 98 4d 10 f0       	push   $0xf0104d98
f01012db:	68 b2 02 00 00       	push   $0x2b2
f01012e0:	68 72 4d 10 f0       	push   $0xf0104d72
f01012e5:	e8 b6 ed ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01012ea:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01012ed:	39 c6                	cmp    %eax,%esi
f01012ef:	74 04                	je     f01012f5 <mem_init+0x23b>
f01012f1:	39 c7                	cmp    %eax,%edi
f01012f3:	75 19                	jne    f010130e <mem_init+0x254>
f01012f5:	68 e4 51 10 f0       	push   $0xf01051e4
f01012fa:	68 98 4d 10 f0       	push   $0xf0104d98
f01012ff:	68 b3 02 00 00       	push   $0x2b3
f0101304:	68 72 4d 10 f0       	push   $0xf0104d72
f0101309:	e8 92 ed ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010130e:	8b 0d 0c db 17 f0    	mov    0xf017db0c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101314:	8b 15 04 db 17 f0    	mov    0xf017db04,%edx
f010131a:	c1 e2 0c             	shl    $0xc,%edx
f010131d:	89 f8                	mov    %edi,%eax
f010131f:	29 c8                	sub    %ecx,%eax
f0101321:	c1 f8 03             	sar    $0x3,%eax
f0101324:	c1 e0 0c             	shl    $0xc,%eax
f0101327:	39 d0                	cmp    %edx,%eax
f0101329:	72 19                	jb     f0101344 <mem_init+0x28a>
f010132b:	68 bb 4e 10 f0       	push   $0xf0104ebb
f0101330:	68 98 4d 10 f0       	push   $0xf0104d98
f0101335:	68 b4 02 00 00       	push   $0x2b4
f010133a:	68 72 4d 10 f0       	push   $0xf0104d72
f010133f:	e8 5c ed ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101344:	89 f0                	mov    %esi,%eax
f0101346:	29 c8                	sub    %ecx,%eax
f0101348:	c1 f8 03             	sar    $0x3,%eax
f010134b:	c1 e0 0c             	shl    $0xc,%eax
f010134e:	39 c2                	cmp    %eax,%edx
f0101350:	77 19                	ja     f010136b <mem_init+0x2b1>
f0101352:	68 d8 4e 10 f0       	push   $0xf0104ed8
f0101357:	68 98 4d 10 f0       	push   $0xf0104d98
f010135c:	68 b5 02 00 00       	push   $0x2b5
f0101361:	68 72 4d 10 f0       	push   $0xf0104d72
f0101366:	e8 35 ed ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f010136b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010136e:	29 c8                	sub    %ecx,%eax
f0101370:	c1 f8 03             	sar    $0x3,%eax
f0101373:	c1 e0 0c             	shl    $0xc,%eax
f0101376:	39 c2                	cmp    %eax,%edx
f0101378:	77 19                	ja     f0101393 <mem_init+0x2d9>
f010137a:	68 f5 4e 10 f0       	push   $0xf0104ef5
f010137f:	68 98 4d 10 f0       	push   $0xf0104d98
f0101384:	68 b6 02 00 00       	push   $0x2b6
f0101389:	68 72 4d 10 f0       	push   $0xf0104d72
f010138e:	e8 0d ed ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101393:	a1 40 ce 17 f0       	mov    0xf017ce40,%eax
f0101398:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010139b:	c7 05 40 ce 17 f0 00 	movl   $0x0,0xf017ce40
f01013a2:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01013a5:	83 ec 0c             	sub    $0xc,%esp
f01013a8:	6a 00                	push   $0x0
f01013aa:	e8 ca f9 ff ff       	call   f0100d79 <page_alloc>
f01013af:	83 c4 10             	add    $0x10,%esp
f01013b2:	85 c0                	test   %eax,%eax
f01013b4:	74 19                	je     f01013cf <mem_init+0x315>
f01013b6:	68 12 4f 10 f0       	push   $0xf0104f12
f01013bb:	68 98 4d 10 f0       	push   $0xf0104d98
f01013c0:	68 bd 02 00 00       	push   $0x2bd
f01013c5:	68 72 4d 10 f0       	push   $0xf0104d72
f01013ca:	e8 d1 ec ff ff       	call   f01000a0 <_panic>

	// free and re-allocate?
	page_free(pp0);
f01013cf:	83 ec 0c             	sub    $0xc,%esp
f01013d2:	57                   	push   %edi
f01013d3:	e8 11 fa ff ff       	call   f0100de9 <page_free>
	page_free(pp1);
f01013d8:	89 34 24             	mov    %esi,(%esp)
f01013db:	e8 09 fa ff ff       	call   f0100de9 <page_free>
	page_free(pp2);
f01013e0:	83 c4 04             	add    $0x4,%esp
f01013e3:	ff 75 d4             	pushl  -0x2c(%ebp)
f01013e6:	e8 fe f9 ff ff       	call   f0100de9 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01013eb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013f2:	e8 82 f9 ff ff       	call   f0100d79 <page_alloc>
f01013f7:	89 c6                	mov    %eax,%esi
f01013f9:	83 c4 10             	add    $0x10,%esp
f01013fc:	85 c0                	test   %eax,%eax
f01013fe:	75 19                	jne    f0101419 <mem_init+0x35f>
f0101400:	68 67 4e 10 f0       	push   $0xf0104e67
f0101405:	68 98 4d 10 f0       	push   $0xf0104d98
f010140a:	68 c4 02 00 00       	push   $0x2c4
f010140f:	68 72 4d 10 f0       	push   $0xf0104d72
f0101414:	e8 87 ec ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0101419:	83 ec 0c             	sub    $0xc,%esp
f010141c:	6a 00                	push   $0x0
f010141e:	e8 56 f9 ff ff       	call   f0100d79 <page_alloc>
f0101423:	89 c7                	mov    %eax,%edi
f0101425:	83 c4 10             	add    $0x10,%esp
f0101428:	85 c0                	test   %eax,%eax
f010142a:	75 19                	jne    f0101445 <mem_init+0x38b>
f010142c:	68 7d 4e 10 f0       	push   $0xf0104e7d
f0101431:	68 98 4d 10 f0       	push   $0xf0104d98
f0101436:	68 c5 02 00 00       	push   $0x2c5
f010143b:	68 72 4d 10 f0       	push   $0xf0104d72
f0101440:	e8 5b ec ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f0101445:	83 ec 0c             	sub    $0xc,%esp
f0101448:	6a 00                	push   $0x0
f010144a:	e8 2a f9 ff ff       	call   f0100d79 <page_alloc>
f010144f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101452:	83 c4 10             	add    $0x10,%esp
f0101455:	85 c0                	test   %eax,%eax
f0101457:	75 19                	jne    f0101472 <mem_init+0x3b8>
f0101459:	68 93 4e 10 f0       	push   $0xf0104e93
f010145e:	68 98 4d 10 f0       	push   $0xf0104d98
f0101463:	68 c6 02 00 00       	push   $0x2c6
f0101468:	68 72 4d 10 f0       	push   $0xf0104d72
f010146d:	e8 2e ec ff ff       	call   f01000a0 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101472:	39 fe                	cmp    %edi,%esi
f0101474:	75 19                	jne    f010148f <mem_init+0x3d5>
f0101476:	68 a9 4e 10 f0       	push   $0xf0104ea9
f010147b:	68 98 4d 10 f0       	push   $0xf0104d98
f0101480:	68 c8 02 00 00       	push   $0x2c8
f0101485:	68 72 4d 10 f0       	push   $0xf0104d72
f010148a:	e8 11 ec ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010148f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101492:	39 c7                	cmp    %eax,%edi
f0101494:	74 04                	je     f010149a <mem_init+0x3e0>
f0101496:	39 c6                	cmp    %eax,%esi
f0101498:	75 19                	jne    f01014b3 <mem_init+0x3f9>
f010149a:	68 e4 51 10 f0       	push   $0xf01051e4
f010149f:	68 98 4d 10 f0       	push   $0xf0104d98
f01014a4:	68 c9 02 00 00       	push   $0x2c9
f01014a9:	68 72 4d 10 f0       	push   $0xf0104d72
f01014ae:	e8 ed eb ff ff       	call   f01000a0 <_panic>
	assert(!page_alloc(0));
f01014b3:	83 ec 0c             	sub    $0xc,%esp
f01014b6:	6a 00                	push   $0x0
f01014b8:	e8 bc f8 ff ff       	call   f0100d79 <page_alloc>
f01014bd:	83 c4 10             	add    $0x10,%esp
f01014c0:	85 c0                	test   %eax,%eax
f01014c2:	74 19                	je     f01014dd <mem_init+0x423>
f01014c4:	68 12 4f 10 f0       	push   $0xf0104f12
f01014c9:	68 98 4d 10 f0       	push   $0xf0104d98
f01014ce:	68 ca 02 00 00       	push   $0x2ca
f01014d3:	68 72 4d 10 f0       	push   $0xf0104d72
f01014d8:	e8 c3 eb ff ff       	call   f01000a0 <_panic>
f01014dd:	89 f0                	mov    %esi,%eax
f01014df:	2b 05 0c db 17 f0    	sub    0xf017db0c,%eax
f01014e5:	c1 f8 03             	sar    $0x3,%eax
f01014e8:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01014eb:	89 c2                	mov    %eax,%edx
f01014ed:	c1 ea 0c             	shr    $0xc,%edx
f01014f0:	3b 15 04 db 17 f0    	cmp    0xf017db04,%edx
f01014f6:	72 12                	jb     f010150a <mem_init+0x450>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01014f8:	50                   	push   %eax
f01014f9:	68 7c 50 10 f0       	push   $0xf010507c
f01014fe:	6a 56                	push   $0x56
f0101500:	68 7e 4d 10 f0       	push   $0xf0104d7e
f0101505:	e8 96 eb ff ff       	call   f01000a0 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f010150a:	83 ec 04             	sub    $0x4,%esp
f010150d:	68 00 10 00 00       	push   $0x1000
f0101512:	6a 01                	push   $0x1
f0101514:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101519:	50                   	push   %eax
f010151a:	e8 94 2e 00 00       	call   f01043b3 <memset>
	page_free(pp0);
f010151f:	89 34 24             	mov    %esi,(%esp)
f0101522:	e8 c2 f8 ff ff       	call   f0100de9 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101527:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010152e:	e8 46 f8 ff ff       	call   f0100d79 <page_alloc>
f0101533:	83 c4 10             	add    $0x10,%esp
f0101536:	85 c0                	test   %eax,%eax
f0101538:	75 19                	jne    f0101553 <mem_init+0x499>
f010153a:	68 21 4f 10 f0       	push   $0xf0104f21
f010153f:	68 98 4d 10 f0       	push   $0xf0104d98
f0101544:	68 cf 02 00 00       	push   $0x2cf
f0101549:	68 72 4d 10 f0       	push   $0xf0104d72
f010154e:	e8 4d eb ff ff       	call   f01000a0 <_panic>
	assert(pp && pp0 == pp);
f0101553:	39 c6                	cmp    %eax,%esi
f0101555:	74 19                	je     f0101570 <mem_init+0x4b6>
f0101557:	68 3f 4f 10 f0       	push   $0xf0104f3f
f010155c:	68 98 4d 10 f0       	push   $0xf0104d98
f0101561:	68 d0 02 00 00       	push   $0x2d0
f0101566:	68 72 4d 10 f0       	push   $0xf0104d72
f010156b:	e8 30 eb ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101570:	89 f0                	mov    %esi,%eax
f0101572:	2b 05 0c db 17 f0    	sub    0xf017db0c,%eax
f0101578:	c1 f8 03             	sar    $0x3,%eax
f010157b:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010157e:	89 c2                	mov    %eax,%edx
f0101580:	c1 ea 0c             	shr    $0xc,%edx
f0101583:	3b 15 04 db 17 f0    	cmp    0xf017db04,%edx
f0101589:	72 12                	jb     f010159d <mem_init+0x4e3>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010158b:	50                   	push   %eax
f010158c:	68 7c 50 10 f0       	push   $0xf010507c
f0101591:	6a 56                	push   $0x56
f0101593:	68 7e 4d 10 f0       	push   $0xf0104d7e
f0101598:	e8 03 eb ff ff       	call   f01000a0 <_panic>
f010159d:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01015a3:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01015a9:	80 38 00             	cmpb   $0x0,(%eax)
f01015ac:	74 19                	je     f01015c7 <mem_init+0x50d>
f01015ae:	68 4f 4f 10 f0       	push   $0xf0104f4f
f01015b3:	68 98 4d 10 f0       	push   $0xf0104d98
f01015b8:	68 d3 02 00 00       	push   $0x2d3
f01015bd:	68 72 4d 10 f0       	push   $0xf0104d72
f01015c2:	e8 d9 ea ff ff       	call   f01000a0 <_panic>
f01015c7:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01015ca:	39 d0                	cmp    %edx,%eax
f01015cc:	75 db                	jne    f01015a9 <mem_init+0x4ef>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01015ce:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01015d1:	a3 40 ce 17 f0       	mov    %eax,0xf017ce40

	// free the pages we took
	page_free(pp0);
f01015d6:	83 ec 0c             	sub    $0xc,%esp
f01015d9:	56                   	push   %esi
f01015da:	e8 0a f8 ff ff       	call   f0100de9 <page_free>
	page_free(pp1);
f01015df:	89 3c 24             	mov    %edi,(%esp)
f01015e2:	e8 02 f8 ff ff       	call   f0100de9 <page_free>
	page_free(pp2);
f01015e7:	83 c4 04             	add    $0x4,%esp
f01015ea:	ff 75 d4             	pushl  -0x2c(%ebp)
f01015ed:	e8 f7 f7 ff ff       	call   f0100de9 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01015f2:	a1 40 ce 17 f0       	mov    0xf017ce40,%eax
f01015f7:	83 c4 10             	add    $0x10,%esp
f01015fa:	eb 05                	jmp    f0101601 <mem_init+0x547>
		--nfree;
f01015fc:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01015ff:	8b 00                	mov    (%eax),%eax
f0101601:	85 c0                	test   %eax,%eax
f0101603:	75 f7                	jne    f01015fc <mem_init+0x542>
		--nfree;
	assert(nfree == 0);
f0101605:	85 db                	test   %ebx,%ebx
f0101607:	74 19                	je     f0101622 <mem_init+0x568>
f0101609:	68 59 4f 10 f0       	push   $0xf0104f59
f010160e:	68 98 4d 10 f0       	push   $0xf0104d98
f0101613:	68 e0 02 00 00       	push   $0x2e0
f0101618:	68 72 4d 10 f0       	push   $0xf0104d72
f010161d:	e8 7e ea ff ff       	call   f01000a0 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101622:	83 ec 0c             	sub    $0xc,%esp
f0101625:	68 04 52 10 f0       	push   $0xf0105204
f010162a:	e8 94 19 00 00       	call   f0102fc3 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010162f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101636:	e8 3e f7 ff ff       	call   f0100d79 <page_alloc>
f010163b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010163e:	83 c4 10             	add    $0x10,%esp
f0101641:	85 c0                	test   %eax,%eax
f0101643:	75 19                	jne    f010165e <mem_init+0x5a4>
f0101645:	68 67 4e 10 f0       	push   $0xf0104e67
f010164a:	68 98 4d 10 f0       	push   $0xf0104d98
f010164f:	68 3e 03 00 00       	push   $0x33e
f0101654:	68 72 4d 10 f0       	push   $0xf0104d72
f0101659:	e8 42 ea ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f010165e:	83 ec 0c             	sub    $0xc,%esp
f0101661:	6a 00                	push   $0x0
f0101663:	e8 11 f7 ff ff       	call   f0100d79 <page_alloc>
f0101668:	89 c3                	mov    %eax,%ebx
f010166a:	83 c4 10             	add    $0x10,%esp
f010166d:	85 c0                	test   %eax,%eax
f010166f:	75 19                	jne    f010168a <mem_init+0x5d0>
f0101671:	68 7d 4e 10 f0       	push   $0xf0104e7d
f0101676:	68 98 4d 10 f0       	push   $0xf0104d98
f010167b:	68 3f 03 00 00       	push   $0x33f
f0101680:	68 72 4d 10 f0       	push   $0xf0104d72
f0101685:	e8 16 ea ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f010168a:	83 ec 0c             	sub    $0xc,%esp
f010168d:	6a 00                	push   $0x0
f010168f:	e8 e5 f6 ff ff       	call   f0100d79 <page_alloc>
f0101694:	89 c6                	mov    %eax,%esi
f0101696:	83 c4 10             	add    $0x10,%esp
f0101699:	85 c0                	test   %eax,%eax
f010169b:	75 19                	jne    f01016b6 <mem_init+0x5fc>
f010169d:	68 93 4e 10 f0       	push   $0xf0104e93
f01016a2:	68 98 4d 10 f0       	push   $0xf0104d98
f01016a7:	68 40 03 00 00       	push   $0x340
f01016ac:	68 72 4d 10 f0       	push   $0xf0104d72
f01016b1:	e8 ea e9 ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01016b6:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01016b9:	75 19                	jne    f01016d4 <mem_init+0x61a>
f01016bb:	68 a9 4e 10 f0       	push   $0xf0104ea9
f01016c0:	68 98 4d 10 f0       	push   $0xf0104d98
f01016c5:	68 43 03 00 00       	push   $0x343
f01016ca:	68 72 4d 10 f0       	push   $0xf0104d72
f01016cf:	e8 cc e9 ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01016d4:	39 c3                	cmp    %eax,%ebx
f01016d6:	74 05                	je     f01016dd <mem_init+0x623>
f01016d8:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01016db:	75 19                	jne    f01016f6 <mem_init+0x63c>
f01016dd:	68 e4 51 10 f0       	push   $0xf01051e4
f01016e2:	68 98 4d 10 f0       	push   $0xf0104d98
f01016e7:	68 44 03 00 00       	push   $0x344
f01016ec:	68 72 4d 10 f0       	push   $0xf0104d72
f01016f1:	e8 aa e9 ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01016f6:	a1 40 ce 17 f0       	mov    0xf017ce40,%eax
f01016fb:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01016fe:	c7 05 40 ce 17 f0 00 	movl   $0x0,0xf017ce40
f0101705:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101708:	83 ec 0c             	sub    $0xc,%esp
f010170b:	6a 00                	push   $0x0
f010170d:	e8 67 f6 ff ff       	call   f0100d79 <page_alloc>
f0101712:	83 c4 10             	add    $0x10,%esp
f0101715:	85 c0                	test   %eax,%eax
f0101717:	74 19                	je     f0101732 <mem_init+0x678>
f0101719:	68 12 4f 10 f0       	push   $0xf0104f12
f010171e:	68 98 4d 10 f0       	push   $0xf0104d98
f0101723:	68 4b 03 00 00       	push   $0x34b
f0101728:	68 72 4d 10 f0       	push   $0xf0104d72
f010172d:	e8 6e e9 ff ff       	call   f01000a0 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101732:	83 ec 04             	sub    $0x4,%esp
f0101735:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101738:	50                   	push   %eax
f0101739:	6a 00                	push   $0x0
f010173b:	ff 35 08 db 17 f0    	pushl  0xf017db08
f0101741:	e8 46 f8 ff ff       	call   f0100f8c <page_lookup>
f0101746:	83 c4 10             	add    $0x10,%esp
f0101749:	85 c0                	test   %eax,%eax
f010174b:	74 19                	je     f0101766 <mem_init+0x6ac>
f010174d:	68 24 52 10 f0       	push   $0xf0105224
f0101752:	68 98 4d 10 f0       	push   $0xf0104d98
f0101757:	68 4e 03 00 00       	push   $0x34e
f010175c:	68 72 4d 10 f0       	push   $0xf0104d72
f0101761:	e8 3a e9 ff ff       	call   f01000a0 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101766:	6a 02                	push   $0x2
f0101768:	6a 00                	push   $0x0
f010176a:	53                   	push   %ebx
f010176b:	ff 35 08 db 17 f0    	pushl  0xf017db08
f0101771:	e8 ab f8 ff ff       	call   f0101021 <page_insert>
f0101776:	83 c4 10             	add    $0x10,%esp
f0101779:	85 c0                	test   %eax,%eax
f010177b:	78 19                	js     f0101796 <mem_init+0x6dc>
f010177d:	68 5c 52 10 f0       	push   $0xf010525c
f0101782:	68 98 4d 10 f0       	push   $0xf0104d98
f0101787:	68 51 03 00 00       	push   $0x351
f010178c:	68 72 4d 10 f0       	push   $0xf0104d72
f0101791:	e8 0a e9 ff ff       	call   f01000a0 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101796:	83 ec 0c             	sub    $0xc,%esp
f0101799:	ff 75 d4             	pushl  -0x2c(%ebp)
f010179c:	e8 48 f6 ff ff       	call   f0100de9 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01017a1:	6a 02                	push   $0x2
f01017a3:	6a 00                	push   $0x0
f01017a5:	53                   	push   %ebx
f01017a6:	ff 35 08 db 17 f0    	pushl  0xf017db08
f01017ac:	e8 70 f8 ff ff       	call   f0101021 <page_insert>
f01017b1:	83 c4 20             	add    $0x20,%esp
f01017b4:	85 c0                	test   %eax,%eax
f01017b6:	74 19                	je     f01017d1 <mem_init+0x717>
f01017b8:	68 8c 52 10 f0       	push   $0xf010528c
f01017bd:	68 98 4d 10 f0       	push   $0xf0104d98
f01017c2:	68 55 03 00 00       	push   $0x355
f01017c7:	68 72 4d 10 f0       	push   $0xf0104d72
f01017cc:	e8 cf e8 ff ff       	call   f01000a0 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01017d1:	8b 3d 08 db 17 f0    	mov    0xf017db08,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01017d7:	a1 0c db 17 f0       	mov    0xf017db0c,%eax
f01017dc:	89 c1                	mov    %eax,%ecx
f01017de:	89 45 c8             	mov    %eax,-0x38(%ebp)
f01017e1:	8b 17                	mov    (%edi),%edx
f01017e3:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01017e9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01017ec:	29 c8                	sub    %ecx,%eax
f01017ee:	c1 f8 03             	sar    $0x3,%eax
f01017f1:	c1 e0 0c             	shl    $0xc,%eax
f01017f4:	39 c2                	cmp    %eax,%edx
f01017f6:	74 19                	je     f0101811 <mem_init+0x757>
f01017f8:	68 bc 52 10 f0       	push   $0xf01052bc
f01017fd:	68 98 4d 10 f0       	push   $0xf0104d98
f0101802:	68 56 03 00 00       	push   $0x356
f0101807:	68 72 4d 10 f0       	push   $0xf0104d72
f010180c:	e8 8f e8 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101811:	ba 00 00 00 00       	mov    $0x0,%edx
f0101816:	89 f8                	mov    %edi,%eax
f0101818:	e8 4c f1 ff ff       	call   f0100969 <check_va2pa>
f010181d:	89 da                	mov    %ebx,%edx
f010181f:	2b 55 c8             	sub    -0x38(%ebp),%edx
f0101822:	c1 fa 03             	sar    $0x3,%edx
f0101825:	c1 e2 0c             	shl    $0xc,%edx
f0101828:	39 d0                	cmp    %edx,%eax
f010182a:	74 19                	je     f0101845 <mem_init+0x78b>
f010182c:	68 e4 52 10 f0       	push   $0xf01052e4
f0101831:	68 98 4d 10 f0       	push   $0xf0104d98
f0101836:	68 57 03 00 00       	push   $0x357
f010183b:	68 72 4d 10 f0       	push   $0xf0104d72
f0101840:	e8 5b e8 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f0101845:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010184a:	74 19                	je     f0101865 <mem_init+0x7ab>
f010184c:	68 64 4f 10 f0       	push   $0xf0104f64
f0101851:	68 98 4d 10 f0       	push   $0xf0104d98
f0101856:	68 58 03 00 00       	push   $0x358
f010185b:	68 72 4d 10 f0       	push   $0xf0104d72
f0101860:	e8 3b e8 ff ff       	call   f01000a0 <_panic>
	assert(pp0->pp_ref == 1);
f0101865:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101868:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f010186d:	74 19                	je     f0101888 <mem_init+0x7ce>
f010186f:	68 75 4f 10 f0       	push   $0xf0104f75
f0101874:	68 98 4d 10 f0       	push   $0xf0104d98
f0101879:	68 59 03 00 00       	push   $0x359
f010187e:	68 72 4d 10 f0       	push   $0xf0104d72
f0101883:	e8 18 e8 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101888:	6a 02                	push   $0x2
f010188a:	68 00 10 00 00       	push   $0x1000
f010188f:	56                   	push   %esi
f0101890:	57                   	push   %edi
f0101891:	e8 8b f7 ff ff       	call   f0101021 <page_insert>
f0101896:	83 c4 10             	add    $0x10,%esp
f0101899:	85 c0                	test   %eax,%eax
f010189b:	74 19                	je     f01018b6 <mem_init+0x7fc>
f010189d:	68 14 53 10 f0       	push   $0xf0105314
f01018a2:	68 98 4d 10 f0       	push   $0xf0104d98
f01018a7:	68 5c 03 00 00       	push   $0x35c
f01018ac:	68 72 4d 10 f0       	push   $0xf0104d72
f01018b1:	e8 ea e7 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01018b6:	ba 00 10 00 00       	mov    $0x1000,%edx
f01018bb:	a1 08 db 17 f0       	mov    0xf017db08,%eax
f01018c0:	e8 a4 f0 ff ff       	call   f0100969 <check_va2pa>
f01018c5:	89 f2                	mov    %esi,%edx
f01018c7:	2b 15 0c db 17 f0    	sub    0xf017db0c,%edx
f01018cd:	c1 fa 03             	sar    $0x3,%edx
f01018d0:	c1 e2 0c             	shl    $0xc,%edx
f01018d3:	39 d0                	cmp    %edx,%eax
f01018d5:	74 19                	je     f01018f0 <mem_init+0x836>
f01018d7:	68 50 53 10 f0       	push   $0xf0105350
f01018dc:	68 98 4d 10 f0       	push   $0xf0104d98
f01018e1:	68 5d 03 00 00       	push   $0x35d
f01018e6:	68 72 4d 10 f0       	push   $0xf0104d72
f01018eb:	e8 b0 e7 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f01018f0:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01018f5:	74 19                	je     f0101910 <mem_init+0x856>
f01018f7:	68 86 4f 10 f0       	push   $0xf0104f86
f01018fc:	68 98 4d 10 f0       	push   $0xf0104d98
f0101901:	68 5e 03 00 00       	push   $0x35e
f0101906:	68 72 4d 10 f0       	push   $0xf0104d72
f010190b:	e8 90 e7 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101910:	83 ec 0c             	sub    $0xc,%esp
f0101913:	6a 00                	push   $0x0
f0101915:	e8 5f f4 ff ff       	call   f0100d79 <page_alloc>
f010191a:	83 c4 10             	add    $0x10,%esp
f010191d:	85 c0                	test   %eax,%eax
f010191f:	74 19                	je     f010193a <mem_init+0x880>
f0101921:	68 12 4f 10 f0       	push   $0xf0104f12
f0101926:	68 98 4d 10 f0       	push   $0xf0104d98
f010192b:	68 61 03 00 00       	push   $0x361
f0101930:	68 72 4d 10 f0       	push   $0xf0104d72
f0101935:	e8 66 e7 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010193a:	6a 02                	push   $0x2
f010193c:	68 00 10 00 00       	push   $0x1000
f0101941:	56                   	push   %esi
f0101942:	ff 35 08 db 17 f0    	pushl  0xf017db08
f0101948:	e8 d4 f6 ff ff       	call   f0101021 <page_insert>
f010194d:	83 c4 10             	add    $0x10,%esp
f0101950:	85 c0                	test   %eax,%eax
f0101952:	74 19                	je     f010196d <mem_init+0x8b3>
f0101954:	68 14 53 10 f0       	push   $0xf0105314
f0101959:	68 98 4d 10 f0       	push   $0xf0104d98
f010195e:	68 64 03 00 00       	push   $0x364
f0101963:	68 72 4d 10 f0       	push   $0xf0104d72
f0101968:	e8 33 e7 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010196d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101972:	a1 08 db 17 f0       	mov    0xf017db08,%eax
f0101977:	e8 ed ef ff ff       	call   f0100969 <check_va2pa>
f010197c:	89 f2                	mov    %esi,%edx
f010197e:	2b 15 0c db 17 f0    	sub    0xf017db0c,%edx
f0101984:	c1 fa 03             	sar    $0x3,%edx
f0101987:	c1 e2 0c             	shl    $0xc,%edx
f010198a:	39 d0                	cmp    %edx,%eax
f010198c:	74 19                	je     f01019a7 <mem_init+0x8ed>
f010198e:	68 50 53 10 f0       	push   $0xf0105350
f0101993:	68 98 4d 10 f0       	push   $0xf0104d98
f0101998:	68 65 03 00 00       	push   $0x365
f010199d:	68 72 4d 10 f0       	push   $0xf0104d72
f01019a2:	e8 f9 e6 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f01019a7:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01019ac:	74 19                	je     f01019c7 <mem_init+0x90d>
f01019ae:	68 86 4f 10 f0       	push   $0xf0104f86
f01019b3:	68 98 4d 10 f0       	push   $0xf0104d98
f01019b8:	68 66 03 00 00       	push   $0x366
f01019bd:	68 72 4d 10 f0       	push   $0xf0104d72
f01019c2:	e8 d9 e6 ff ff       	call   f01000a0 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f01019c7:	83 ec 0c             	sub    $0xc,%esp
f01019ca:	6a 00                	push   $0x0
f01019cc:	e8 a8 f3 ff ff       	call   f0100d79 <page_alloc>
f01019d1:	83 c4 10             	add    $0x10,%esp
f01019d4:	85 c0                	test   %eax,%eax
f01019d6:	74 19                	je     f01019f1 <mem_init+0x937>
f01019d8:	68 12 4f 10 f0       	push   $0xf0104f12
f01019dd:	68 98 4d 10 f0       	push   $0xf0104d98
f01019e2:	68 6a 03 00 00       	push   $0x36a
f01019e7:	68 72 4d 10 f0       	push   $0xf0104d72
f01019ec:	e8 af e6 ff ff       	call   f01000a0 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f01019f1:	8b 15 08 db 17 f0    	mov    0xf017db08,%edx
f01019f7:	8b 02                	mov    (%edx),%eax
f01019f9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01019fe:	89 c1                	mov    %eax,%ecx
f0101a00:	c1 e9 0c             	shr    $0xc,%ecx
f0101a03:	3b 0d 04 db 17 f0    	cmp    0xf017db04,%ecx
f0101a09:	72 15                	jb     f0101a20 <mem_init+0x966>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101a0b:	50                   	push   %eax
f0101a0c:	68 7c 50 10 f0       	push   $0xf010507c
f0101a11:	68 6d 03 00 00       	push   $0x36d
f0101a16:	68 72 4d 10 f0       	push   $0xf0104d72
f0101a1b:	e8 80 e6 ff ff       	call   f01000a0 <_panic>
f0101a20:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101a25:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101a28:	83 ec 04             	sub    $0x4,%esp
f0101a2b:	6a 00                	push   $0x0
f0101a2d:	68 00 10 00 00       	push   $0x1000
f0101a32:	52                   	push   %edx
f0101a33:	e8 2e f4 ff ff       	call   f0100e66 <pgdir_walk>
f0101a38:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101a3b:	8d 57 04             	lea    0x4(%edi),%edx
f0101a3e:	83 c4 10             	add    $0x10,%esp
f0101a41:	39 d0                	cmp    %edx,%eax
f0101a43:	74 19                	je     f0101a5e <mem_init+0x9a4>
f0101a45:	68 80 53 10 f0       	push   $0xf0105380
f0101a4a:	68 98 4d 10 f0       	push   $0xf0104d98
f0101a4f:	68 6e 03 00 00       	push   $0x36e
f0101a54:	68 72 4d 10 f0       	push   $0xf0104d72
f0101a59:	e8 42 e6 ff ff       	call   f01000a0 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101a5e:	6a 06                	push   $0x6
f0101a60:	68 00 10 00 00       	push   $0x1000
f0101a65:	56                   	push   %esi
f0101a66:	ff 35 08 db 17 f0    	pushl  0xf017db08
f0101a6c:	e8 b0 f5 ff ff       	call   f0101021 <page_insert>
f0101a71:	83 c4 10             	add    $0x10,%esp
f0101a74:	85 c0                	test   %eax,%eax
f0101a76:	74 19                	je     f0101a91 <mem_init+0x9d7>
f0101a78:	68 c0 53 10 f0       	push   $0xf01053c0
f0101a7d:	68 98 4d 10 f0       	push   $0xf0104d98
f0101a82:	68 71 03 00 00       	push   $0x371
f0101a87:	68 72 4d 10 f0       	push   $0xf0104d72
f0101a8c:	e8 0f e6 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a91:	8b 3d 08 db 17 f0    	mov    0xf017db08,%edi
f0101a97:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a9c:	89 f8                	mov    %edi,%eax
f0101a9e:	e8 c6 ee ff ff       	call   f0100969 <check_va2pa>
f0101aa3:	89 f2                	mov    %esi,%edx
f0101aa5:	2b 15 0c db 17 f0    	sub    0xf017db0c,%edx
f0101aab:	c1 fa 03             	sar    $0x3,%edx
f0101aae:	c1 e2 0c             	shl    $0xc,%edx
f0101ab1:	39 d0                	cmp    %edx,%eax
f0101ab3:	74 19                	je     f0101ace <mem_init+0xa14>
f0101ab5:	68 50 53 10 f0       	push   $0xf0105350
f0101aba:	68 98 4d 10 f0       	push   $0xf0104d98
f0101abf:	68 72 03 00 00       	push   $0x372
f0101ac4:	68 72 4d 10 f0       	push   $0xf0104d72
f0101ac9:	e8 d2 e5 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101ace:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101ad3:	74 19                	je     f0101aee <mem_init+0xa34>
f0101ad5:	68 86 4f 10 f0       	push   $0xf0104f86
f0101ada:	68 98 4d 10 f0       	push   $0xf0104d98
f0101adf:	68 73 03 00 00       	push   $0x373
f0101ae4:	68 72 4d 10 f0       	push   $0xf0104d72
f0101ae9:	e8 b2 e5 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101aee:	83 ec 04             	sub    $0x4,%esp
f0101af1:	6a 00                	push   $0x0
f0101af3:	68 00 10 00 00       	push   $0x1000
f0101af8:	57                   	push   %edi
f0101af9:	e8 68 f3 ff ff       	call   f0100e66 <pgdir_walk>
f0101afe:	83 c4 10             	add    $0x10,%esp
f0101b01:	f6 00 04             	testb  $0x4,(%eax)
f0101b04:	75 19                	jne    f0101b1f <mem_init+0xa65>
f0101b06:	68 00 54 10 f0       	push   $0xf0105400
f0101b0b:	68 98 4d 10 f0       	push   $0xf0104d98
f0101b10:	68 74 03 00 00       	push   $0x374
f0101b15:	68 72 4d 10 f0       	push   $0xf0104d72
f0101b1a:	e8 81 e5 ff ff       	call   f01000a0 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101b1f:	a1 08 db 17 f0       	mov    0xf017db08,%eax
f0101b24:	f6 00 04             	testb  $0x4,(%eax)
f0101b27:	75 19                	jne    f0101b42 <mem_init+0xa88>
f0101b29:	68 97 4f 10 f0       	push   $0xf0104f97
f0101b2e:	68 98 4d 10 f0       	push   $0xf0104d98
f0101b33:	68 75 03 00 00       	push   $0x375
f0101b38:	68 72 4d 10 f0       	push   $0xf0104d72
f0101b3d:	e8 5e e5 ff ff       	call   f01000a0 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b42:	6a 02                	push   $0x2
f0101b44:	68 00 10 00 00       	push   $0x1000
f0101b49:	56                   	push   %esi
f0101b4a:	50                   	push   %eax
f0101b4b:	e8 d1 f4 ff ff       	call   f0101021 <page_insert>
f0101b50:	83 c4 10             	add    $0x10,%esp
f0101b53:	85 c0                	test   %eax,%eax
f0101b55:	74 19                	je     f0101b70 <mem_init+0xab6>
f0101b57:	68 14 53 10 f0       	push   $0xf0105314
f0101b5c:	68 98 4d 10 f0       	push   $0xf0104d98
f0101b61:	68 78 03 00 00       	push   $0x378
f0101b66:	68 72 4d 10 f0       	push   $0xf0104d72
f0101b6b:	e8 30 e5 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101b70:	83 ec 04             	sub    $0x4,%esp
f0101b73:	6a 00                	push   $0x0
f0101b75:	68 00 10 00 00       	push   $0x1000
f0101b7a:	ff 35 08 db 17 f0    	pushl  0xf017db08
f0101b80:	e8 e1 f2 ff ff       	call   f0100e66 <pgdir_walk>
f0101b85:	83 c4 10             	add    $0x10,%esp
f0101b88:	f6 00 02             	testb  $0x2,(%eax)
f0101b8b:	75 19                	jne    f0101ba6 <mem_init+0xaec>
f0101b8d:	68 34 54 10 f0       	push   $0xf0105434
f0101b92:	68 98 4d 10 f0       	push   $0xf0104d98
f0101b97:	68 79 03 00 00       	push   $0x379
f0101b9c:	68 72 4d 10 f0       	push   $0xf0104d72
f0101ba1:	e8 fa e4 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101ba6:	83 ec 04             	sub    $0x4,%esp
f0101ba9:	6a 00                	push   $0x0
f0101bab:	68 00 10 00 00       	push   $0x1000
f0101bb0:	ff 35 08 db 17 f0    	pushl  0xf017db08
f0101bb6:	e8 ab f2 ff ff       	call   f0100e66 <pgdir_walk>
f0101bbb:	83 c4 10             	add    $0x10,%esp
f0101bbe:	f6 00 04             	testb  $0x4,(%eax)
f0101bc1:	74 19                	je     f0101bdc <mem_init+0xb22>
f0101bc3:	68 68 54 10 f0       	push   $0xf0105468
f0101bc8:	68 98 4d 10 f0       	push   $0xf0104d98
f0101bcd:	68 7a 03 00 00       	push   $0x37a
f0101bd2:	68 72 4d 10 f0       	push   $0xf0104d72
f0101bd7:	e8 c4 e4 ff ff       	call   f01000a0 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101bdc:	6a 02                	push   $0x2
f0101bde:	68 00 00 40 00       	push   $0x400000
f0101be3:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101be6:	ff 35 08 db 17 f0    	pushl  0xf017db08
f0101bec:	e8 30 f4 ff ff       	call   f0101021 <page_insert>
f0101bf1:	83 c4 10             	add    $0x10,%esp
f0101bf4:	85 c0                	test   %eax,%eax
f0101bf6:	78 19                	js     f0101c11 <mem_init+0xb57>
f0101bf8:	68 a0 54 10 f0       	push   $0xf01054a0
f0101bfd:	68 98 4d 10 f0       	push   $0xf0104d98
f0101c02:	68 7d 03 00 00       	push   $0x37d
f0101c07:	68 72 4d 10 f0       	push   $0xf0104d72
f0101c0c:	e8 8f e4 ff ff       	call   f01000a0 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101c11:	6a 02                	push   $0x2
f0101c13:	68 00 10 00 00       	push   $0x1000
f0101c18:	53                   	push   %ebx
f0101c19:	ff 35 08 db 17 f0    	pushl  0xf017db08
f0101c1f:	e8 fd f3 ff ff       	call   f0101021 <page_insert>
f0101c24:	83 c4 10             	add    $0x10,%esp
f0101c27:	85 c0                	test   %eax,%eax
f0101c29:	74 19                	je     f0101c44 <mem_init+0xb8a>
f0101c2b:	68 d8 54 10 f0       	push   $0xf01054d8
f0101c30:	68 98 4d 10 f0       	push   $0xf0104d98
f0101c35:	68 80 03 00 00       	push   $0x380
f0101c3a:	68 72 4d 10 f0       	push   $0xf0104d72
f0101c3f:	e8 5c e4 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101c44:	83 ec 04             	sub    $0x4,%esp
f0101c47:	6a 00                	push   $0x0
f0101c49:	68 00 10 00 00       	push   $0x1000
f0101c4e:	ff 35 08 db 17 f0    	pushl  0xf017db08
f0101c54:	e8 0d f2 ff ff       	call   f0100e66 <pgdir_walk>
f0101c59:	83 c4 10             	add    $0x10,%esp
f0101c5c:	f6 00 04             	testb  $0x4,(%eax)
f0101c5f:	74 19                	je     f0101c7a <mem_init+0xbc0>
f0101c61:	68 68 54 10 f0       	push   $0xf0105468
f0101c66:	68 98 4d 10 f0       	push   $0xf0104d98
f0101c6b:	68 81 03 00 00       	push   $0x381
f0101c70:	68 72 4d 10 f0       	push   $0xf0104d72
f0101c75:	e8 26 e4 ff ff       	call   f01000a0 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101c7a:	8b 3d 08 db 17 f0    	mov    0xf017db08,%edi
f0101c80:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c85:	89 f8                	mov    %edi,%eax
f0101c87:	e8 dd ec ff ff       	call   f0100969 <check_va2pa>
f0101c8c:	89 c1                	mov    %eax,%ecx
f0101c8e:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0101c91:	89 d8                	mov    %ebx,%eax
f0101c93:	2b 05 0c db 17 f0    	sub    0xf017db0c,%eax
f0101c99:	c1 f8 03             	sar    $0x3,%eax
f0101c9c:	c1 e0 0c             	shl    $0xc,%eax
f0101c9f:	39 c1                	cmp    %eax,%ecx
f0101ca1:	74 19                	je     f0101cbc <mem_init+0xc02>
f0101ca3:	68 14 55 10 f0       	push   $0xf0105514
f0101ca8:	68 98 4d 10 f0       	push   $0xf0104d98
f0101cad:	68 84 03 00 00       	push   $0x384
f0101cb2:	68 72 4d 10 f0       	push   $0xf0104d72
f0101cb7:	e8 e4 e3 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101cbc:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101cc1:	89 f8                	mov    %edi,%eax
f0101cc3:	e8 a1 ec ff ff       	call   f0100969 <check_va2pa>
f0101cc8:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0101ccb:	74 19                	je     f0101ce6 <mem_init+0xc2c>
f0101ccd:	68 40 55 10 f0       	push   $0xf0105540
f0101cd2:	68 98 4d 10 f0       	push   $0xf0104d98
f0101cd7:	68 85 03 00 00       	push   $0x385
f0101cdc:	68 72 4d 10 f0       	push   $0xf0104d72
f0101ce1:	e8 ba e3 ff ff       	call   f01000a0 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101ce6:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101ceb:	74 19                	je     f0101d06 <mem_init+0xc4c>
f0101ced:	68 ad 4f 10 f0       	push   $0xf0104fad
f0101cf2:	68 98 4d 10 f0       	push   $0xf0104d98
f0101cf7:	68 87 03 00 00       	push   $0x387
f0101cfc:	68 72 4d 10 f0       	push   $0xf0104d72
f0101d01:	e8 9a e3 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101d06:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101d0b:	74 19                	je     f0101d26 <mem_init+0xc6c>
f0101d0d:	68 be 4f 10 f0       	push   $0xf0104fbe
f0101d12:	68 98 4d 10 f0       	push   $0xf0104d98
f0101d17:	68 88 03 00 00       	push   $0x388
f0101d1c:	68 72 4d 10 f0       	push   $0xf0104d72
f0101d21:	e8 7a e3 ff ff       	call   f01000a0 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101d26:	83 ec 0c             	sub    $0xc,%esp
f0101d29:	6a 00                	push   $0x0
f0101d2b:	e8 49 f0 ff ff       	call   f0100d79 <page_alloc>
f0101d30:	83 c4 10             	add    $0x10,%esp
f0101d33:	85 c0                	test   %eax,%eax
f0101d35:	74 04                	je     f0101d3b <mem_init+0xc81>
f0101d37:	39 c6                	cmp    %eax,%esi
f0101d39:	74 19                	je     f0101d54 <mem_init+0xc9a>
f0101d3b:	68 70 55 10 f0       	push   $0xf0105570
f0101d40:	68 98 4d 10 f0       	push   $0xf0104d98
f0101d45:	68 8b 03 00 00       	push   $0x38b
f0101d4a:	68 72 4d 10 f0       	push   $0xf0104d72
f0101d4f:	e8 4c e3 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101d54:	83 ec 08             	sub    $0x8,%esp
f0101d57:	6a 00                	push   $0x0
f0101d59:	ff 35 08 db 17 f0    	pushl  0xf017db08
f0101d5f:	e8 82 f2 ff ff       	call   f0100fe6 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101d64:	8b 3d 08 db 17 f0    	mov    0xf017db08,%edi
f0101d6a:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d6f:	89 f8                	mov    %edi,%eax
f0101d71:	e8 f3 eb ff ff       	call   f0100969 <check_va2pa>
f0101d76:	83 c4 10             	add    $0x10,%esp
f0101d79:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d7c:	74 19                	je     f0101d97 <mem_init+0xcdd>
f0101d7e:	68 94 55 10 f0       	push   $0xf0105594
f0101d83:	68 98 4d 10 f0       	push   $0xf0104d98
f0101d88:	68 8f 03 00 00       	push   $0x38f
f0101d8d:	68 72 4d 10 f0       	push   $0xf0104d72
f0101d92:	e8 09 e3 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101d97:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d9c:	89 f8                	mov    %edi,%eax
f0101d9e:	e8 c6 eb ff ff       	call   f0100969 <check_va2pa>
f0101da3:	89 da                	mov    %ebx,%edx
f0101da5:	2b 15 0c db 17 f0    	sub    0xf017db0c,%edx
f0101dab:	c1 fa 03             	sar    $0x3,%edx
f0101dae:	c1 e2 0c             	shl    $0xc,%edx
f0101db1:	39 d0                	cmp    %edx,%eax
f0101db3:	74 19                	je     f0101dce <mem_init+0xd14>
f0101db5:	68 40 55 10 f0       	push   $0xf0105540
f0101dba:	68 98 4d 10 f0       	push   $0xf0104d98
f0101dbf:	68 90 03 00 00       	push   $0x390
f0101dc4:	68 72 4d 10 f0       	push   $0xf0104d72
f0101dc9:	e8 d2 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f0101dce:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101dd3:	74 19                	je     f0101dee <mem_init+0xd34>
f0101dd5:	68 64 4f 10 f0       	push   $0xf0104f64
f0101dda:	68 98 4d 10 f0       	push   $0xf0104d98
f0101ddf:	68 91 03 00 00       	push   $0x391
f0101de4:	68 72 4d 10 f0       	push   $0xf0104d72
f0101de9:	e8 b2 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101dee:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101df3:	74 19                	je     f0101e0e <mem_init+0xd54>
f0101df5:	68 be 4f 10 f0       	push   $0xf0104fbe
f0101dfa:	68 98 4d 10 f0       	push   $0xf0104d98
f0101dff:	68 92 03 00 00       	push   $0x392
f0101e04:	68 72 4d 10 f0       	push   $0xf0104d72
f0101e09:	e8 92 e2 ff ff       	call   f01000a0 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101e0e:	6a 00                	push   $0x0
f0101e10:	68 00 10 00 00       	push   $0x1000
f0101e15:	53                   	push   %ebx
f0101e16:	57                   	push   %edi
f0101e17:	e8 05 f2 ff ff       	call   f0101021 <page_insert>
f0101e1c:	83 c4 10             	add    $0x10,%esp
f0101e1f:	85 c0                	test   %eax,%eax
f0101e21:	74 19                	je     f0101e3c <mem_init+0xd82>
f0101e23:	68 b8 55 10 f0       	push   $0xf01055b8
f0101e28:	68 98 4d 10 f0       	push   $0xf0104d98
f0101e2d:	68 95 03 00 00       	push   $0x395
f0101e32:	68 72 4d 10 f0       	push   $0xf0104d72
f0101e37:	e8 64 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref);
f0101e3c:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101e41:	75 19                	jne    f0101e5c <mem_init+0xda2>
f0101e43:	68 cf 4f 10 f0       	push   $0xf0104fcf
f0101e48:	68 98 4d 10 f0       	push   $0xf0104d98
f0101e4d:	68 96 03 00 00       	push   $0x396
f0101e52:	68 72 4d 10 f0       	push   $0xf0104d72
f0101e57:	e8 44 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_link == NULL);
f0101e5c:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101e5f:	74 19                	je     f0101e7a <mem_init+0xdc0>
f0101e61:	68 db 4f 10 f0       	push   $0xf0104fdb
f0101e66:	68 98 4d 10 f0       	push   $0xf0104d98
f0101e6b:	68 97 03 00 00       	push   $0x397
f0101e70:	68 72 4d 10 f0       	push   $0xf0104d72
f0101e75:	e8 26 e2 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101e7a:	83 ec 08             	sub    $0x8,%esp
f0101e7d:	68 00 10 00 00       	push   $0x1000
f0101e82:	ff 35 08 db 17 f0    	pushl  0xf017db08
f0101e88:	e8 59 f1 ff ff       	call   f0100fe6 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e8d:	8b 3d 08 db 17 f0    	mov    0xf017db08,%edi
f0101e93:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e98:	89 f8                	mov    %edi,%eax
f0101e9a:	e8 ca ea ff ff       	call   f0100969 <check_va2pa>
f0101e9f:	83 c4 10             	add    $0x10,%esp
f0101ea2:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101ea5:	74 19                	je     f0101ec0 <mem_init+0xe06>
f0101ea7:	68 94 55 10 f0       	push   $0xf0105594
f0101eac:	68 98 4d 10 f0       	push   $0xf0104d98
f0101eb1:	68 9b 03 00 00       	push   $0x39b
f0101eb6:	68 72 4d 10 f0       	push   $0xf0104d72
f0101ebb:	e8 e0 e1 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101ec0:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ec5:	89 f8                	mov    %edi,%eax
f0101ec7:	e8 9d ea ff ff       	call   f0100969 <check_va2pa>
f0101ecc:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101ecf:	74 19                	je     f0101eea <mem_init+0xe30>
f0101ed1:	68 f0 55 10 f0       	push   $0xf01055f0
f0101ed6:	68 98 4d 10 f0       	push   $0xf0104d98
f0101edb:	68 9c 03 00 00       	push   $0x39c
f0101ee0:	68 72 4d 10 f0       	push   $0xf0104d72
f0101ee5:	e8 b6 e1 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f0101eea:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101eef:	74 19                	je     f0101f0a <mem_init+0xe50>
f0101ef1:	68 f0 4f 10 f0       	push   $0xf0104ff0
f0101ef6:	68 98 4d 10 f0       	push   $0xf0104d98
f0101efb:	68 9d 03 00 00       	push   $0x39d
f0101f00:	68 72 4d 10 f0       	push   $0xf0104d72
f0101f05:	e8 96 e1 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101f0a:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101f0f:	74 19                	je     f0101f2a <mem_init+0xe70>
f0101f11:	68 be 4f 10 f0       	push   $0xf0104fbe
f0101f16:	68 98 4d 10 f0       	push   $0xf0104d98
f0101f1b:	68 9e 03 00 00       	push   $0x39e
f0101f20:	68 72 4d 10 f0       	push   $0xf0104d72
f0101f25:	e8 76 e1 ff ff       	call   f01000a0 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101f2a:	83 ec 0c             	sub    $0xc,%esp
f0101f2d:	6a 00                	push   $0x0
f0101f2f:	e8 45 ee ff ff       	call   f0100d79 <page_alloc>
f0101f34:	83 c4 10             	add    $0x10,%esp
f0101f37:	39 c3                	cmp    %eax,%ebx
f0101f39:	75 04                	jne    f0101f3f <mem_init+0xe85>
f0101f3b:	85 c0                	test   %eax,%eax
f0101f3d:	75 19                	jne    f0101f58 <mem_init+0xe9e>
f0101f3f:	68 18 56 10 f0       	push   $0xf0105618
f0101f44:	68 98 4d 10 f0       	push   $0xf0104d98
f0101f49:	68 a1 03 00 00       	push   $0x3a1
f0101f4e:	68 72 4d 10 f0       	push   $0xf0104d72
f0101f53:	e8 48 e1 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101f58:	83 ec 0c             	sub    $0xc,%esp
f0101f5b:	6a 00                	push   $0x0
f0101f5d:	e8 17 ee ff ff       	call   f0100d79 <page_alloc>
f0101f62:	83 c4 10             	add    $0x10,%esp
f0101f65:	85 c0                	test   %eax,%eax
f0101f67:	74 19                	je     f0101f82 <mem_init+0xec8>
f0101f69:	68 12 4f 10 f0       	push   $0xf0104f12
f0101f6e:	68 98 4d 10 f0       	push   $0xf0104d98
f0101f73:	68 a4 03 00 00       	push   $0x3a4
f0101f78:	68 72 4d 10 f0       	push   $0xf0104d72
f0101f7d:	e8 1e e1 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101f82:	8b 0d 08 db 17 f0    	mov    0xf017db08,%ecx
f0101f88:	8b 11                	mov    (%ecx),%edx
f0101f8a:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101f90:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f93:	2b 05 0c db 17 f0    	sub    0xf017db0c,%eax
f0101f99:	c1 f8 03             	sar    $0x3,%eax
f0101f9c:	c1 e0 0c             	shl    $0xc,%eax
f0101f9f:	39 c2                	cmp    %eax,%edx
f0101fa1:	74 19                	je     f0101fbc <mem_init+0xf02>
f0101fa3:	68 bc 52 10 f0       	push   $0xf01052bc
f0101fa8:	68 98 4d 10 f0       	push   $0xf0104d98
f0101fad:	68 a7 03 00 00       	push   $0x3a7
f0101fb2:	68 72 4d 10 f0       	push   $0xf0104d72
f0101fb7:	e8 e4 e0 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f0101fbc:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101fc2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fc5:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101fca:	74 19                	je     f0101fe5 <mem_init+0xf2b>
f0101fcc:	68 75 4f 10 f0       	push   $0xf0104f75
f0101fd1:	68 98 4d 10 f0       	push   $0xf0104d98
f0101fd6:	68 a9 03 00 00       	push   $0x3a9
f0101fdb:	68 72 4d 10 f0       	push   $0xf0104d72
f0101fe0:	e8 bb e0 ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f0101fe5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fe8:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101fee:	83 ec 0c             	sub    $0xc,%esp
f0101ff1:	50                   	push   %eax
f0101ff2:	e8 f2 ed ff ff       	call   f0100de9 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101ff7:	83 c4 0c             	add    $0xc,%esp
f0101ffa:	6a 01                	push   $0x1
f0101ffc:	68 00 10 40 00       	push   $0x401000
f0102001:	ff 35 08 db 17 f0    	pushl  0xf017db08
f0102007:	e8 5a ee ff ff       	call   f0100e66 <pgdir_walk>
f010200c:	89 45 c8             	mov    %eax,-0x38(%ebp)
f010200f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102012:	8b 0d 08 db 17 f0    	mov    0xf017db08,%ecx
f0102018:	8b 51 04             	mov    0x4(%ecx),%edx
f010201b:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102021:	8b 3d 04 db 17 f0    	mov    0xf017db04,%edi
f0102027:	89 d0                	mov    %edx,%eax
f0102029:	c1 e8 0c             	shr    $0xc,%eax
f010202c:	83 c4 10             	add    $0x10,%esp
f010202f:	39 f8                	cmp    %edi,%eax
f0102031:	72 15                	jb     f0102048 <mem_init+0xf8e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102033:	52                   	push   %edx
f0102034:	68 7c 50 10 f0       	push   $0xf010507c
f0102039:	68 b0 03 00 00       	push   $0x3b0
f010203e:	68 72 4d 10 f0       	push   $0xf0104d72
f0102043:	e8 58 e0 ff ff       	call   f01000a0 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102048:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f010204e:	39 55 c8             	cmp    %edx,-0x38(%ebp)
f0102051:	74 19                	je     f010206c <mem_init+0xfb2>
f0102053:	68 01 50 10 f0       	push   $0xf0105001
f0102058:	68 98 4d 10 f0       	push   $0xf0104d98
f010205d:	68 b1 03 00 00       	push   $0x3b1
f0102062:	68 72 4d 10 f0       	push   $0xf0104d72
f0102067:	e8 34 e0 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[PDX(va)] = 0;
f010206c:	c7 41 04 00 00 00 00 	movl   $0x0,0x4(%ecx)
	pp0->pp_ref = 0;
f0102073:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102076:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010207c:	2b 05 0c db 17 f0    	sub    0xf017db0c,%eax
f0102082:	c1 f8 03             	sar    $0x3,%eax
f0102085:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102088:	89 c2                	mov    %eax,%edx
f010208a:	c1 ea 0c             	shr    $0xc,%edx
f010208d:	39 d7                	cmp    %edx,%edi
f010208f:	77 12                	ja     f01020a3 <mem_init+0xfe9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102091:	50                   	push   %eax
f0102092:	68 7c 50 10 f0       	push   $0xf010507c
f0102097:	6a 56                	push   $0x56
f0102099:	68 7e 4d 10 f0       	push   $0xf0104d7e
f010209e:	e8 fd df ff ff       	call   f01000a0 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01020a3:	83 ec 04             	sub    $0x4,%esp
f01020a6:	68 00 10 00 00       	push   $0x1000
f01020ab:	68 ff 00 00 00       	push   $0xff
f01020b0:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01020b5:	50                   	push   %eax
f01020b6:	e8 f8 22 00 00       	call   f01043b3 <memset>
	page_free(pp0);
f01020bb:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01020be:	89 3c 24             	mov    %edi,(%esp)
f01020c1:	e8 23 ed ff ff       	call   f0100de9 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01020c6:	83 c4 0c             	add    $0xc,%esp
f01020c9:	6a 01                	push   $0x1
f01020cb:	6a 00                	push   $0x0
f01020cd:	ff 35 08 db 17 f0    	pushl  0xf017db08
f01020d3:	e8 8e ed ff ff       	call   f0100e66 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01020d8:	89 fa                	mov    %edi,%edx
f01020da:	2b 15 0c db 17 f0    	sub    0xf017db0c,%edx
f01020e0:	c1 fa 03             	sar    $0x3,%edx
f01020e3:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01020e6:	89 d0                	mov    %edx,%eax
f01020e8:	c1 e8 0c             	shr    $0xc,%eax
f01020eb:	83 c4 10             	add    $0x10,%esp
f01020ee:	3b 05 04 db 17 f0    	cmp    0xf017db04,%eax
f01020f4:	72 12                	jb     f0102108 <mem_init+0x104e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01020f6:	52                   	push   %edx
f01020f7:	68 7c 50 10 f0       	push   $0xf010507c
f01020fc:	6a 56                	push   $0x56
f01020fe:	68 7e 4d 10 f0       	push   $0xf0104d7e
f0102103:	e8 98 df ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f0102108:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f010210e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102111:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102117:	f6 00 01             	testb  $0x1,(%eax)
f010211a:	74 19                	je     f0102135 <mem_init+0x107b>
f010211c:	68 19 50 10 f0       	push   $0xf0105019
f0102121:	68 98 4d 10 f0       	push   $0xf0104d98
f0102126:	68 bb 03 00 00       	push   $0x3bb
f010212b:	68 72 4d 10 f0       	push   $0xf0104d72
f0102130:	e8 6b df ff ff       	call   f01000a0 <_panic>
f0102135:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102138:	39 c2                	cmp    %eax,%edx
f010213a:	75 db                	jne    f0102117 <mem_init+0x105d>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f010213c:	a1 08 db 17 f0       	mov    0xf017db08,%eax
f0102141:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102147:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010214a:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102150:	8b 7d d0             	mov    -0x30(%ebp),%edi
f0102153:	89 3d 40 ce 17 f0    	mov    %edi,0xf017ce40

	// free the pages we took
	page_free(pp0);
f0102159:	83 ec 0c             	sub    $0xc,%esp
f010215c:	50                   	push   %eax
f010215d:	e8 87 ec ff ff       	call   f0100de9 <page_free>
	page_free(pp1);
f0102162:	89 1c 24             	mov    %ebx,(%esp)
f0102165:	e8 7f ec ff ff       	call   f0100de9 <page_free>
	page_free(pp2);
f010216a:	89 34 24             	mov    %esi,(%esp)
f010216d:	e8 77 ec ff ff       	call   f0100de9 <page_free>

	cprintf("check_page() succeeded!\n");
f0102172:	c7 04 24 30 50 10 f0 	movl   $0xf0105030,(%esp)
f0102179:	e8 45 0e 00 00       	call   f0102fc3 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, PageInfo_Size, PADDR(pages), (PTE_U|PTE_P));
f010217e:	a1 0c db 17 f0       	mov    0xf017db0c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102183:	83 c4 10             	add    $0x10,%esp
f0102186:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010218b:	77 15                	ja     f01021a2 <mem_init+0x10e8>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010218d:	50                   	push   %eax
f010218e:	68 c0 51 10 f0       	push   $0xf01051c0
f0102193:	68 bf 00 00 00       	push   $0xbf
f0102198:	68 72 4d 10 f0       	push   $0xf0104d72
f010219d:	e8 fe de ff ff       	call   f01000a0 <_panic>
f01021a2:	83 ec 08             	sub    $0x8,%esp
f01021a5:	6a 05                	push   $0x5
f01021a7:	05 00 00 00 10       	add    $0x10000000,%eax
f01021ac:	50                   	push   %eax
f01021ad:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f01021b0:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01021b5:	a1 08 db 17 f0       	mov    0xf017db08,%eax
f01021ba:	e8 6f ed ff ff       	call   f0100f2e <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, PTSIZE, PADDR(envs), PTE_U);
f01021bf:	a1 4c ce 17 f0       	mov    0xf017ce4c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01021c4:	83 c4 10             	add    $0x10,%esp
f01021c7:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01021cc:	77 15                	ja     f01021e3 <mem_init+0x1129>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01021ce:	50                   	push   %eax
f01021cf:	68 c0 51 10 f0       	push   $0xf01051c0
f01021d4:	68 c7 00 00 00       	push   $0xc7
f01021d9:	68 72 4d 10 f0       	push   $0xf0104d72
f01021de:	e8 bd de ff ff       	call   f01000a0 <_panic>
f01021e3:	83 ec 08             	sub    $0x8,%esp
f01021e6:	6a 04                	push   $0x4
f01021e8:	05 00 00 00 10       	add    $0x10000000,%eax
f01021ed:	50                   	push   %eax
f01021ee:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01021f3:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f01021f8:	a1 08 db 17 f0       	mov    0xf017db08,%eax
f01021fd:	e8 2c ed ff ff       	call   f0100f2e <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102202:	83 c4 10             	add    $0x10,%esp
f0102205:	b8 00 10 11 f0       	mov    $0xf0111000,%eax
f010220a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010220f:	77 15                	ja     f0102226 <mem_init+0x116c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102211:	50                   	push   %eax
f0102212:	68 c0 51 10 f0       	push   $0xf01051c0
f0102217:	68 d3 00 00 00       	push   $0xd3
f010221c:	68 72 4d 10 f0       	push   $0xf0104d72
f0102221:	e8 7a de ff ff       	call   f01000a0 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), (PTE_W|PTE_P));
f0102226:	83 ec 08             	sub    $0x8,%esp
f0102229:	6a 03                	push   $0x3
f010222b:	68 00 10 11 00       	push   $0x111000
f0102230:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102235:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f010223a:	a1 08 db 17 f0       	mov    0xf017db08,%eax
f010223f:	e8 ea ec ff ff       	call   f0100f2e <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KERNBASE, (0xffffffff-KERNBASE), 0, (PTE_W|PTE_P));
f0102244:	83 c4 08             	add    $0x8,%esp
f0102247:	6a 03                	push   $0x3
f0102249:	6a 00                	push   $0x0
f010224b:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f0102250:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102255:	a1 08 db 17 f0       	mov    0xf017db08,%eax
f010225a:	e8 cf ec ff ff       	call   f0100f2e <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f010225f:	8b 1d 08 db 17 f0    	mov    0xf017db08,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102265:	a1 04 db 17 f0       	mov    0xf017db04,%eax
f010226a:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010226d:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102274:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102279:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010227c:	8b 3d 0c db 17 f0    	mov    0xf017db0c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102282:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0102285:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102288:	be 00 00 00 00       	mov    $0x0,%esi
f010228d:	eb 55                	jmp    f01022e4 <mem_init+0x122a>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010228f:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
f0102295:	89 d8                	mov    %ebx,%eax
f0102297:	e8 cd e6 ff ff       	call   f0100969 <check_va2pa>
f010229c:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f01022a3:	77 15                	ja     f01022ba <mem_init+0x1200>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01022a5:	57                   	push   %edi
f01022a6:	68 c0 51 10 f0       	push   $0xf01051c0
f01022ab:	68 f8 02 00 00       	push   $0x2f8
f01022b0:	68 72 4d 10 f0       	push   $0xf0104d72
f01022b5:	e8 e6 dd ff ff       	call   f01000a0 <_panic>
f01022ba:	8d 94 37 00 00 00 10 	lea    0x10000000(%edi,%esi,1),%edx
f01022c1:	39 d0                	cmp    %edx,%eax
f01022c3:	74 19                	je     f01022de <mem_init+0x1224>
f01022c5:	68 3c 56 10 f0       	push   $0xf010563c
f01022ca:	68 98 4d 10 f0       	push   $0xf0104d98
f01022cf:	68 f8 02 00 00       	push   $0x2f8
f01022d4:	68 72 4d 10 f0       	push   $0xf0104d72
f01022d9:	e8 c2 dd ff ff       	call   f01000a0 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01022de:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01022e4:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f01022e7:	77 a6                	ja     f010228f <mem_init+0x11d5>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f01022e9:	8b 3d 4c ce 17 f0    	mov    0xf017ce4c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01022ef:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01022f2:	be 00 00 c0 ee       	mov    $0xeec00000,%esi
f01022f7:	89 f2                	mov    %esi,%edx
f01022f9:	89 d8                	mov    %ebx,%eax
f01022fb:	e8 69 e6 ff ff       	call   f0100969 <check_va2pa>
f0102300:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f0102307:	77 15                	ja     f010231e <mem_init+0x1264>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102309:	57                   	push   %edi
f010230a:	68 c0 51 10 f0       	push   $0xf01051c0
f010230f:	68 fd 02 00 00       	push   $0x2fd
f0102314:	68 72 4d 10 f0       	push   $0xf0104d72
f0102319:	e8 82 dd ff ff       	call   f01000a0 <_panic>
f010231e:	8d 94 37 00 00 40 21 	lea    0x21400000(%edi,%esi,1),%edx
f0102325:	39 c2                	cmp    %eax,%edx
f0102327:	74 19                	je     f0102342 <mem_init+0x1288>
f0102329:	68 70 56 10 f0       	push   $0xf0105670
f010232e:	68 98 4d 10 f0       	push   $0xf0104d98
f0102333:	68 fd 02 00 00       	push   $0x2fd
f0102338:	68 72 4d 10 f0       	push   $0xf0104d72
f010233d:	e8 5e dd ff ff       	call   f01000a0 <_panic>
f0102342:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102348:	81 fe 00 80 c1 ee    	cmp    $0xeec18000,%esi
f010234e:	75 a7                	jne    f01022f7 <mem_init+0x123d>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102350:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0102353:	c1 e7 0c             	shl    $0xc,%edi
f0102356:	be 00 00 00 00       	mov    $0x0,%esi
f010235b:	eb 30                	jmp    f010238d <mem_init+0x12d3>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f010235d:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
f0102363:	89 d8                	mov    %ebx,%eax
f0102365:	e8 ff e5 ff ff       	call   f0100969 <check_va2pa>
f010236a:	39 c6                	cmp    %eax,%esi
f010236c:	74 19                	je     f0102387 <mem_init+0x12cd>
f010236e:	68 a4 56 10 f0       	push   $0xf01056a4
f0102373:	68 98 4d 10 f0       	push   $0xf0104d98
f0102378:	68 01 03 00 00       	push   $0x301
f010237d:	68 72 4d 10 f0       	push   $0xf0104d72
f0102382:	e8 19 dd ff ff       	call   f01000a0 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102387:	81 c6 00 10 00 00    	add    $0x1000,%esi
f010238d:	39 fe                	cmp    %edi,%esi
f010238f:	72 cc                	jb     f010235d <mem_init+0x12a3>
f0102391:	be 00 80 ff ef       	mov    $0xefff8000,%esi
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102396:	89 f2                	mov    %esi,%edx
f0102398:	89 d8                	mov    %ebx,%eax
f010239a:	e8 ca e5 ff ff       	call   f0100969 <check_va2pa>
f010239f:	8d 96 00 90 11 10    	lea    0x10119000(%esi),%edx
f01023a5:	39 c2                	cmp    %eax,%edx
f01023a7:	74 19                	je     f01023c2 <mem_init+0x1308>
f01023a9:	68 cc 56 10 f0       	push   $0xf01056cc
f01023ae:	68 98 4d 10 f0       	push   $0xf0104d98
f01023b3:	68 05 03 00 00       	push   $0x305
f01023b8:	68 72 4d 10 f0       	push   $0xf0104d72
f01023bd:	e8 de dc ff ff       	call   f01000a0 <_panic>
f01023c2:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01023c8:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f01023ce:	75 c6                	jne    f0102396 <mem_init+0x12dc>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01023d0:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f01023d5:	89 d8                	mov    %ebx,%eax
f01023d7:	e8 8d e5 ff ff       	call   f0100969 <check_va2pa>
f01023dc:	83 f8 ff             	cmp    $0xffffffff,%eax
f01023df:	74 51                	je     f0102432 <mem_init+0x1378>
f01023e1:	68 14 57 10 f0       	push   $0xf0105714
f01023e6:	68 98 4d 10 f0       	push   $0xf0104d98
f01023eb:	68 06 03 00 00       	push   $0x306
f01023f0:	68 72 4d 10 f0       	push   $0xf0104d72
f01023f5:	e8 a6 dc ff ff       	call   f01000a0 <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f01023fa:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f01023ff:	72 36                	jb     f0102437 <mem_init+0x137d>
f0102401:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102406:	76 07                	jbe    f010240f <mem_init+0x1355>
f0102408:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f010240d:	75 28                	jne    f0102437 <mem_init+0x137d>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
f010240f:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f0102413:	0f 85 83 00 00 00    	jne    f010249c <mem_init+0x13e2>
f0102419:	68 49 50 10 f0       	push   $0xf0105049
f010241e:	68 98 4d 10 f0       	push   $0xf0104d98
f0102423:	68 0f 03 00 00       	push   $0x30f
f0102428:	68 72 4d 10 f0       	push   $0xf0104d72
f010242d:	e8 6e dc ff ff       	call   f01000a0 <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102432:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102437:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f010243c:	76 3f                	jbe    f010247d <mem_init+0x13c3>
				assert(pgdir[i] & PTE_P);
f010243e:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f0102441:	f6 c2 01             	test   $0x1,%dl
f0102444:	75 19                	jne    f010245f <mem_init+0x13a5>
f0102446:	68 49 50 10 f0       	push   $0xf0105049
f010244b:	68 98 4d 10 f0       	push   $0xf0104d98
f0102450:	68 13 03 00 00       	push   $0x313
f0102455:	68 72 4d 10 f0       	push   $0xf0104d72
f010245a:	e8 41 dc ff ff       	call   f01000a0 <_panic>
				assert(pgdir[i] & PTE_W);
f010245f:	f6 c2 02             	test   $0x2,%dl
f0102462:	75 38                	jne    f010249c <mem_init+0x13e2>
f0102464:	68 5a 50 10 f0       	push   $0xf010505a
f0102469:	68 98 4d 10 f0       	push   $0xf0104d98
f010246e:	68 14 03 00 00       	push   $0x314
f0102473:	68 72 4d 10 f0       	push   $0xf0104d72
f0102478:	e8 23 dc ff ff       	call   f01000a0 <_panic>
			} else
				assert(pgdir[i] == 0);
f010247d:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f0102481:	74 19                	je     f010249c <mem_init+0x13e2>
f0102483:	68 6b 50 10 f0       	push   $0xf010506b
f0102488:	68 98 4d 10 f0       	push   $0xf0104d98
f010248d:	68 16 03 00 00       	push   $0x316
f0102492:	68 72 4d 10 f0       	push   $0xf0104d72
f0102497:	e8 04 dc ff ff       	call   f01000a0 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f010249c:	83 c0 01             	add    $0x1,%eax
f010249f:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f01024a4:	0f 86 50 ff ff ff    	jbe    f01023fa <mem_init+0x1340>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f01024aa:	83 ec 0c             	sub    $0xc,%esp
f01024ad:	68 44 57 10 f0       	push   $0xf0105744
f01024b2:	e8 0c 0b 00 00       	call   f0102fc3 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01024b7:	a1 08 db 17 f0       	mov    0xf017db08,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01024bc:	83 c4 10             	add    $0x10,%esp
f01024bf:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01024c4:	77 15                	ja     f01024db <mem_init+0x1421>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01024c6:	50                   	push   %eax
f01024c7:	68 c0 51 10 f0       	push   $0xf01051c0
f01024cc:	68 e7 00 00 00       	push   $0xe7
f01024d1:	68 72 4d 10 f0       	push   $0xf0104d72
f01024d6:	e8 c5 db ff ff       	call   f01000a0 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01024db:	05 00 00 00 10       	add    $0x10000000,%eax
f01024e0:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01024e3:	b8 00 00 00 00       	mov    $0x0,%eax
f01024e8:	e8 e0 e4 ff ff       	call   f01009cd <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f01024ed:	0f 20 c0             	mov    %cr0,%eax
f01024f0:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f01024f3:	0d 23 00 05 80       	or     $0x80050023,%eax
f01024f8:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01024fb:	83 ec 0c             	sub    $0xc,%esp
f01024fe:	6a 00                	push   $0x0
f0102500:	e8 74 e8 ff ff       	call   f0100d79 <page_alloc>
f0102505:	89 c3                	mov    %eax,%ebx
f0102507:	83 c4 10             	add    $0x10,%esp
f010250a:	85 c0                	test   %eax,%eax
f010250c:	75 19                	jne    f0102527 <mem_init+0x146d>
f010250e:	68 67 4e 10 f0       	push   $0xf0104e67
f0102513:	68 98 4d 10 f0       	push   $0xf0104d98
f0102518:	68 d6 03 00 00       	push   $0x3d6
f010251d:	68 72 4d 10 f0       	push   $0xf0104d72
f0102522:	e8 79 db ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0102527:	83 ec 0c             	sub    $0xc,%esp
f010252a:	6a 00                	push   $0x0
f010252c:	e8 48 e8 ff ff       	call   f0100d79 <page_alloc>
f0102531:	89 c7                	mov    %eax,%edi
f0102533:	83 c4 10             	add    $0x10,%esp
f0102536:	85 c0                	test   %eax,%eax
f0102538:	75 19                	jne    f0102553 <mem_init+0x1499>
f010253a:	68 7d 4e 10 f0       	push   $0xf0104e7d
f010253f:	68 98 4d 10 f0       	push   $0xf0104d98
f0102544:	68 d7 03 00 00       	push   $0x3d7
f0102549:	68 72 4d 10 f0       	push   $0xf0104d72
f010254e:	e8 4d db ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f0102553:	83 ec 0c             	sub    $0xc,%esp
f0102556:	6a 00                	push   $0x0
f0102558:	e8 1c e8 ff ff       	call   f0100d79 <page_alloc>
f010255d:	89 c6                	mov    %eax,%esi
f010255f:	83 c4 10             	add    $0x10,%esp
f0102562:	85 c0                	test   %eax,%eax
f0102564:	75 19                	jne    f010257f <mem_init+0x14c5>
f0102566:	68 93 4e 10 f0       	push   $0xf0104e93
f010256b:	68 98 4d 10 f0       	push   $0xf0104d98
f0102570:	68 d8 03 00 00       	push   $0x3d8
f0102575:	68 72 4d 10 f0       	push   $0xf0104d72
f010257a:	e8 21 db ff ff       	call   f01000a0 <_panic>
	page_free(pp0);
f010257f:	83 ec 0c             	sub    $0xc,%esp
f0102582:	53                   	push   %ebx
f0102583:	e8 61 e8 ff ff       	call   f0100de9 <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102588:	89 f8                	mov    %edi,%eax
f010258a:	2b 05 0c db 17 f0    	sub    0xf017db0c,%eax
f0102590:	c1 f8 03             	sar    $0x3,%eax
f0102593:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102596:	89 c2                	mov    %eax,%edx
f0102598:	c1 ea 0c             	shr    $0xc,%edx
f010259b:	83 c4 10             	add    $0x10,%esp
f010259e:	3b 15 04 db 17 f0    	cmp    0xf017db04,%edx
f01025a4:	72 12                	jb     f01025b8 <mem_init+0x14fe>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01025a6:	50                   	push   %eax
f01025a7:	68 7c 50 10 f0       	push   $0xf010507c
f01025ac:	6a 56                	push   $0x56
f01025ae:	68 7e 4d 10 f0       	push   $0xf0104d7e
f01025b3:	e8 e8 da ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f01025b8:	83 ec 04             	sub    $0x4,%esp
f01025bb:	68 00 10 00 00       	push   $0x1000
f01025c0:	6a 01                	push   $0x1
f01025c2:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01025c7:	50                   	push   %eax
f01025c8:	e8 e6 1d 00 00       	call   f01043b3 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01025cd:	89 f0                	mov    %esi,%eax
f01025cf:	2b 05 0c db 17 f0    	sub    0xf017db0c,%eax
f01025d5:	c1 f8 03             	sar    $0x3,%eax
f01025d8:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01025db:	89 c2                	mov    %eax,%edx
f01025dd:	c1 ea 0c             	shr    $0xc,%edx
f01025e0:	83 c4 10             	add    $0x10,%esp
f01025e3:	3b 15 04 db 17 f0    	cmp    0xf017db04,%edx
f01025e9:	72 12                	jb     f01025fd <mem_init+0x1543>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01025eb:	50                   	push   %eax
f01025ec:	68 7c 50 10 f0       	push   $0xf010507c
f01025f1:	6a 56                	push   $0x56
f01025f3:	68 7e 4d 10 f0       	push   $0xf0104d7e
f01025f8:	e8 a3 da ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f01025fd:	83 ec 04             	sub    $0x4,%esp
f0102600:	68 00 10 00 00       	push   $0x1000
f0102605:	6a 02                	push   $0x2
f0102607:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010260c:	50                   	push   %eax
f010260d:	e8 a1 1d 00 00       	call   f01043b3 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102612:	6a 02                	push   $0x2
f0102614:	68 00 10 00 00       	push   $0x1000
f0102619:	57                   	push   %edi
f010261a:	ff 35 08 db 17 f0    	pushl  0xf017db08
f0102620:	e8 fc e9 ff ff       	call   f0101021 <page_insert>
	assert(pp1->pp_ref == 1);
f0102625:	83 c4 20             	add    $0x20,%esp
f0102628:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f010262d:	74 19                	je     f0102648 <mem_init+0x158e>
f010262f:	68 64 4f 10 f0       	push   $0xf0104f64
f0102634:	68 98 4d 10 f0       	push   $0xf0104d98
f0102639:	68 dd 03 00 00       	push   $0x3dd
f010263e:	68 72 4d 10 f0       	push   $0xf0104d72
f0102643:	e8 58 da ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102648:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f010264f:	01 01 01 
f0102652:	74 19                	je     f010266d <mem_init+0x15b3>
f0102654:	68 64 57 10 f0       	push   $0xf0105764
f0102659:	68 98 4d 10 f0       	push   $0xf0104d98
f010265e:	68 de 03 00 00       	push   $0x3de
f0102663:	68 72 4d 10 f0       	push   $0xf0104d72
f0102668:	e8 33 da ff ff       	call   f01000a0 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f010266d:	6a 02                	push   $0x2
f010266f:	68 00 10 00 00       	push   $0x1000
f0102674:	56                   	push   %esi
f0102675:	ff 35 08 db 17 f0    	pushl  0xf017db08
f010267b:	e8 a1 e9 ff ff       	call   f0101021 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102680:	83 c4 10             	add    $0x10,%esp
f0102683:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f010268a:	02 02 02 
f010268d:	74 19                	je     f01026a8 <mem_init+0x15ee>
f010268f:	68 88 57 10 f0       	push   $0xf0105788
f0102694:	68 98 4d 10 f0       	push   $0xf0104d98
f0102699:	68 e0 03 00 00       	push   $0x3e0
f010269e:	68 72 4d 10 f0       	push   $0xf0104d72
f01026a3:	e8 f8 d9 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f01026a8:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01026ad:	74 19                	je     f01026c8 <mem_init+0x160e>
f01026af:	68 86 4f 10 f0       	push   $0xf0104f86
f01026b4:	68 98 4d 10 f0       	push   $0xf0104d98
f01026b9:	68 e1 03 00 00       	push   $0x3e1
f01026be:	68 72 4d 10 f0       	push   $0xf0104d72
f01026c3:	e8 d8 d9 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f01026c8:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01026cd:	74 19                	je     f01026e8 <mem_init+0x162e>
f01026cf:	68 f0 4f 10 f0       	push   $0xf0104ff0
f01026d4:	68 98 4d 10 f0       	push   $0xf0104d98
f01026d9:	68 e2 03 00 00       	push   $0x3e2
f01026de:	68 72 4d 10 f0       	push   $0xf0104d72
f01026e3:	e8 b8 d9 ff ff       	call   f01000a0 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f01026e8:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f01026ef:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01026f2:	89 f0                	mov    %esi,%eax
f01026f4:	2b 05 0c db 17 f0    	sub    0xf017db0c,%eax
f01026fa:	c1 f8 03             	sar    $0x3,%eax
f01026fd:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102700:	89 c2                	mov    %eax,%edx
f0102702:	c1 ea 0c             	shr    $0xc,%edx
f0102705:	3b 15 04 db 17 f0    	cmp    0xf017db04,%edx
f010270b:	72 12                	jb     f010271f <mem_init+0x1665>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010270d:	50                   	push   %eax
f010270e:	68 7c 50 10 f0       	push   $0xf010507c
f0102713:	6a 56                	push   $0x56
f0102715:	68 7e 4d 10 f0       	push   $0xf0104d7e
f010271a:	e8 81 d9 ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f010271f:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102726:	03 03 03 
f0102729:	74 19                	je     f0102744 <mem_init+0x168a>
f010272b:	68 ac 57 10 f0       	push   $0xf01057ac
f0102730:	68 98 4d 10 f0       	push   $0xf0104d98
f0102735:	68 e4 03 00 00       	push   $0x3e4
f010273a:	68 72 4d 10 f0       	push   $0xf0104d72
f010273f:	e8 5c d9 ff ff       	call   f01000a0 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102744:	83 ec 08             	sub    $0x8,%esp
f0102747:	68 00 10 00 00       	push   $0x1000
f010274c:	ff 35 08 db 17 f0    	pushl  0xf017db08
f0102752:	e8 8f e8 ff ff       	call   f0100fe6 <page_remove>
	assert(pp2->pp_ref == 0);
f0102757:	83 c4 10             	add    $0x10,%esp
f010275a:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010275f:	74 19                	je     f010277a <mem_init+0x16c0>
f0102761:	68 be 4f 10 f0       	push   $0xf0104fbe
f0102766:	68 98 4d 10 f0       	push   $0xf0104d98
f010276b:	68 e6 03 00 00       	push   $0x3e6
f0102770:	68 72 4d 10 f0       	push   $0xf0104d72
f0102775:	e8 26 d9 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010277a:	8b 0d 08 db 17 f0    	mov    0xf017db08,%ecx
f0102780:	8b 11                	mov    (%ecx),%edx
f0102782:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102788:	89 d8                	mov    %ebx,%eax
f010278a:	2b 05 0c db 17 f0    	sub    0xf017db0c,%eax
f0102790:	c1 f8 03             	sar    $0x3,%eax
f0102793:	c1 e0 0c             	shl    $0xc,%eax
f0102796:	39 c2                	cmp    %eax,%edx
f0102798:	74 19                	je     f01027b3 <mem_init+0x16f9>
f010279a:	68 bc 52 10 f0       	push   $0xf01052bc
f010279f:	68 98 4d 10 f0       	push   $0xf0104d98
f01027a4:	68 e9 03 00 00       	push   $0x3e9
f01027a9:	68 72 4d 10 f0       	push   $0xf0104d72
f01027ae:	e8 ed d8 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f01027b3:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f01027b9:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01027be:	74 19                	je     f01027d9 <mem_init+0x171f>
f01027c0:	68 75 4f 10 f0       	push   $0xf0104f75
f01027c5:	68 98 4d 10 f0       	push   $0xf0104d98
f01027ca:	68 eb 03 00 00       	push   $0x3eb
f01027cf:	68 72 4d 10 f0       	push   $0xf0104d72
f01027d4:	e8 c7 d8 ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f01027d9:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f01027df:	83 ec 0c             	sub    $0xc,%esp
f01027e2:	53                   	push   %ebx
f01027e3:	e8 01 e6 ff ff       	call   f0100de9 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f01027e8:	c7 04 24 d8 57 10 f0 	movl   $0xf01057d8,(%esp)
f01027ef:	e8 cf 07 00 00       	call   f0102fc3 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f01027f4:	83 c4 10             	add    $0x10,%esp
f01027f7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01027fa:	5b                   	pop    %ebx
f01027fb:	5e                   	pop    %esi
f01027fc:	5f                   	pop    %edi
f01027fd:	5d                   	pop    %ebp
f01027fe:	c3                   	ret    

f01027ff <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01027ff:	55                   	push   %ebp
f0102800:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102802:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102805:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0102808:	5d                   	pop    %ebp
f0102809:	c3                   	ret    

f010280a <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f010280a:	55                   	push   %ebp
f010280b:	89 e5                	mov    %esp,%ebp
f010280d:	57                   	push   %edi
f010280e:	56                   	push   %esi
f010280f:	53                   	push   %ebx
f0102810:	83 ec 1c             	sub    $0x1c,%esp
f0102813:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	uintptr_t begin = (uintptr_t)ROUNDDOWN(va, PGSIZE);
f0102816:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102819:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uintptr_t end = (uintptr_t)ROUNDUP(va + len, PGSIZE);
f010281f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102822:	03 45 10             	add    0x10(%ebp),%eax
f0102825:	05 ff 0f 00 00       	add    $0xfff,%eax
f010282a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010282f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(uintptr_t i = begin;i < end;i += PGSIZE)
	{
		pte_t *pte = pgdir_walk(env->env_pgdir, (void*)i, 0);
		if(pte == NULL||i >= ULIM||(*pte & (perm|PTE_P))!=(perm|PTE_P))
f0102832:	8b 75 14             	mov    0x14(%ebp),%esi
f0102835:	83 ce 01             	or     $0x1,%esi
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
	// LAB 3: Your code here.
	uintptr_t begin = (uintptr_t)ROUNDDOWN(va, PGSIZE);
	uintptr_t end = (uintptr_t)ROUNDUP(va + len, PGSIZE);
	for(uintptr_t i = begin;i < end;i += PGSIZE)
f0102838:	eb 4c                	jmp    f0102886 <user_mem_check+0x7c>
	{
		pte_t *pte = pgdir_walk(env->env_pgdir, (void*)i, 0);
f010283a:	83 ec 04             	sub    $0x4,%esp
f010283d:	6a 00                	push   $0x0
f010283f:	53                   	push   %ebx
f0102840:	ff 77 5c             	pushl  0x5c(%edi)
f0102843:	e8 1e e6 ff ff       	call   f0100e66 <pgdir_walk>
		if(pte == NULL||i >= ULIM||(*pte & (perm|PTE_P))!=(perm|PTE_P))
f0102848:	83 c4 10             	add    $0x10,%esp
f010284b:	85 c0                	test   %eax,%eax
f010284d:	74 10                	je     f010285f <user_mem_check+0x55>
f010284f:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0102855:	77 08                	ja     f010285f <user_mem_check+0x55>
f0102857:	89 f2                	mov    %esi,%edx
f0102859:	23 10                	and    (%eax),%edx
f010285b:	39 d6                	cmp    %edx,%esi
f010285d:	74 21                	je     f0102880 <user_mem_check+0x76>
		{ 
			if(i < (uintptr_t)va)
f010285f:	3b 5d 0c             	cmp    0xc(%ebp),%ebx
f0102862:	73 0f                	jae    f0102873 <user_mem_check+0x69>
			{
				user_mem_check_addr = (uintptr_t)va;
f0102864:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102867:	a3 3c ce 17 f0       	mov    %eax,0xf017ce3c
			}
			else
			{
				user_mem_check_addr = (uintptr_t)i;
			}
			return -E_FAULT;
f010286c:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102871:	eb 1d                	jmp    f0102890 <user_mem_check+0x86>
			{
				user_mem_check_addr = (uintptr_t)va;
			}
			else
			{
				user_mem_check_addr = (uintptr_t)i;
f0102873:	89 1d 3c ce 17 f0    	mov    %ebx,0xf017ce3c
			}
			return -E_FAULT;
f0102879:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f010287e:	eb 10                	jmp    f0102890 <user_mem_check+0x86>
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
	// LAB 3: Your code here.
	uintptr_t begin = (uintptr_t)ROUNDDOWN(va, PGSIZE);
	uintptr_t end = (uintptr_t)ROUNDUP(va + len, PGSIZE);
	for(uintptr_t i = begin;i < end;i += PGSIZE)
f0102880:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102886:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0102889:	72 af                	jb     f010283a <user_mem_check+0x30>
				user_mem_check_addr = (uintptr_t)i;
			}
			return -E_FAULT;
		}
	}
	return 0;
f010288b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102890:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102893:	5b                   	pop    %ebx
f0102894:	5e                   	pop    %esi
f0102895:	5f                   	pop    %edi
f0102896:	5d                   	pop    %ebp
f0102897:	c3                   	ret    

f0102898 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102898:	55                   	push   %ebp
f0102899:	89 e5                	mov    %esp,%ebp
f010289b:	53                   	push   %ebx
f010289c:	83 ec 04             	sub    $0x4,%esp
f010289f:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f01028a2:	8b 45 14             	mov    0x14(%ebp),%eax
f01028a5:	83 c8 04             	or     $0x4,%eax
f01028a8:	50                   	push   %eax
f01028a9:	ff 75 10             	pushl  0x10(%ebp)
f01028ac:	ff 75 0c             	pushl  0xc(%ebp)
f01028af:	53                   	push   %ebx
f01028b0:	e8 55 ff ff ff       	call   f010280a <user_mem_check>
f01028b5:	83 c4 10             	add    $0x10,%esp
f01028b8:	85 c0                	test   %eax,%eax
f01028ba:	79 21                	jns    f01028dd <user_mem_assert+0x45>
		cprintf("[%08x] user_mem_check assertion failure for "
f01028bc:	83 ec 04             	sub    $0x4,%esp
f01028bf:	ff 35 3c ce 17 f0    	pushl  0xf017ce3c
f01028c5:	ff 73 48             	pushl  0x48(%ebx)
f01028c8:	68 04 58 10 f0       	push   $0xf0105804
f01028cd:	e8 f1 06 00 00       	call   f0102fc3 <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f01028d2:	89 1c 24             	mov    %ebx,(%esp)
f01028d5:	e8 d6 05 00 00       	call   f0102eb0 <env_destroy>
f01028da:	83 c4 10             	add    $0x10,%esp
	}
}
f01028dd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01028e0:	c9                   	leave  
f01028e1:	c3                   	ret    

f01028e2 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f01028e2:	55                   	push   %ebp
f01028e3:	89 e5                	mov    %esp,%ebp
f01028e5:	57                   	push   %edi
f01028e6:	56                   	push   %esi
f01028e7:	53                   	push   %ebx
f01028e8:	83 ec 0c             	sub    $0xc,%esp
f01028eb:	89 c7                	mov    %eax,%edi
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	int flag;
	void *begin = ROUNDDOWN(va, PGSIZE);
f01028ed:	89 d3                	mov    %edx,%ebx
f01028ef:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	void *end = ROUNDUP(va + len, PGSIZE);
f01028f5:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f01028fc:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	for(begin; begin < end; begin += PGSIZE)
f0102902:	eb 58                	jmp    f010295c <region_alloc+0x7a>
	{
		struct PageInfo *NewPage = page_alloc(0);
f0102904:	83 ec 0c             	sub    $0xc,%esp
f0102907:	6a 00                	push   $0x0
f0102909:	e8 6b e4 ff ff       	call   f0100d79 <page_alloc>
		if(NewPage == NULL)
f010290e:	83 c4 10             	add    $0x10,%esp
f0102911:	85 c0                	test   %eax,%eax
f0102913:	75 17                	jne    f010292c <region_alloc+0x4a>
		{ 
			panic("can't allocate a new page");
f0102915:	83 ec 04             	sub    $0x4,%esp
f0102918:	68 39 58 10 f0       	push   $0xf0105839
f010291d:	68 1f 01 00 00       	push   $0x11f
f0102922:	68 53 58 10 f0       	push   $0xf0105853
f0102927:	e8 74 d7 ff ff       	call   f01000a0 <_panic>
		}
		flag = page_insert(e->env_pgdir, NewPage, begin, PTE_W|PTE_U);
f010292c:	6a 06                	push   $0x6
f010292e:	53                   	push   %ebx
f010292f:	50                   	push   %eax
f0102930:	ff 77 5c             	pushl  0x5c(%edi)
f0102933:	e8 e9 e6 ff ff       	call   f0101021 <page_insert>
		if(flag != 0)
f0102938:	83 c4 10             	add    $0x10,%esp
f010293b:	85 c0                	test   %eax,%eax
f010293d:	74 17                	je     f0102956 <region_alloc+0x74>
		{ 
			panic("map creation failed");
f010293f:	83 ec 04             	sub    $0x4,%esp
f0102942:	68 5e 58 10 f0       	push   $0xf010585e
f0102947:	68 24 01 00 00       	push   $0x124
f010294c:	68 53 58 10 f0       	push   $0xf0105853
f0102951:	e8 4a d7 ff ff       	call   f01000a0 <_panic>
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	int flag;
	void *begin = ROUNDDOWN(va, PGSIZE);
	void *end = ROUNDUP(va + len, PGSIZE);
	for(begin; begin < end; begin += PGSIZE)
f0102956:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010295c:	39 f3                	cmp    %esi,%ebx
f010295e:	72 a4                	jb     f0102904 <region_alloc+0x22>
		if(flag != 0)
		{ 
			panic("map creation failed");
		}
	}
}
f0102960:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102963:	5b                   	pop    %ebx
f0102964:	5e                   	pop    %esi
f0102965:	5f                   	pop    %edi
f0102966:	5d                   	pop    %ebp
f0102967:	c3                   	ret    

f0102968 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0102968:	55                   	push   %ebp
f0102969:	89 e5                	mov    %esp,%ebp
f010296b:	8b 55 08             	mov    0x8(%ebp),%edx
f010296e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0102971:	85 d2                	test   %edx,%edx
f0102973:	75 11                	jne    f0102986 <envid2env+0x1e>
		*env_store = curenv;
f0102975:	a1 48 ce 17 f0       	mov    0xf017ce48,%eax
f010297a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010297d:	89 01                	mov    %eax,(%ecx)
		return 0;
f010297f:	b8 00 00 00 00       	mov    $0x0,%eax
f0102984:	eb 5e                	jmp    f01029e4 <envid2env+0x7c>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0102986:	89 d0                	mov    %edx,%eax
f0102988:	25 ff 03 00 00       	and    $0x3ff,%eax
f010298d:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0102990:	c1 e0 05             	shl    $0x5,%eax
f0102993:	03 05 4c ce 17 f0    	add    0xf017ce4c,%eax
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0102999:	83 78 54 00          	cmpl   $0x0,0x54(%eax)
f010299d:	74 05                	je     f01029a4 <envid2env+0x3c>
f010299f:	3b 50 48             	cmp    0x48(%eax),%edx
f01029a2:	74 10                	je     f01029b4 <envid2env+0x4c>
		*env_store = 0;
f01029a4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01029a7:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01029ad:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01029b2:	eb 30                	jmp    f01029e4 <envid2env+0x7c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f01029b4:	84 c9                	test   %cl,%cl
f01029b6:	74 22                	je     f01029da <envid2env+0x72>
f01029b8:	8b 15 48 ce 17 f0    	mov    0xf017ce48,%edx
f01029be:	39 d0                	cmp    %edx,%eax
f01029c0:	74 18                	je     f01029da <envid2env+0x72>
f01029c2:	8b 4a 48             	mov    0x48(%edx),%ecx
f01029c5:	39 48 4c             	cmp    %ecx,0x4c(%eax)
f01029c8:	74 10                	je     f01029da <envid2env+0x72>
		*env_store = 0;
f01029ca:	8b 45 0c             	mov    0xc(%ebp),%eax
f01029cd:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01029d3:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01029d8:	eb 0a                	jmp    f01029e4 <envid2env+0x7c>
	}

	*env_store = e;
f01029da:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01029dd:	89 01                	mov    %eax,(%ecx)
	return 0;
f01029df:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01029e4:	5d                   	pop    %ebp
f01029e5:	c3                   	ret    

f01029e6 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f01029e6:	55                   	push   %ebp
f01029e7:	89 e5                	mov    %esp,%ebp
}

static __inline void
lgdt(void *p)
{
	__asm __volatile("lgdt (%0)" : : "r" (p));
f01029e9:	b8 00 b3 11 f0       	mov    $0xf011b300,%eax
f01029ee:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f01029f1:	b8 23 00 00 00       	mov    $0x23,%eax
f01029f6:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f01029f8:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f01029fa:	b8 10 00 00 00       	mov    $0x10,%eax
f01029ff:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f0102a01:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f0102a03:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f0102a05:	ea 0c 2a 10 f0 08 00 	ljmp   $0x8,$0xf0102a0c
}

static __inline void
lldt(uint16_t sel)
{
	__asm __volatile("lldt %0" : : "r" (sel));
f0102a0c:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a11:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0102a14:	5d                   	pop    %ebp
f0102a15:	c3                   	ret    

f0102a16 <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0102a16:	55                   	push   %ebp
f0102a17:	89 e5                	mov    %esp,%ebp
f0102a19:	56                   	push   %esi
f0102a1a:	53                   	push   %ebx
	// Set up envs array
	// LAB 3: Your code here.
	env_free_list = NULL; 
	for(int i = NENV - 1;i >= 0;i--)
	{
		envs[i].env_id = 0;  
f0102a1b:	8b 35 4c ce 17 f0    	mov    0xf017ce4c,%esi
f0102a21:	8d 86 a0 7f 01 00    	lea    0x17fa0(%esi),%eax
f0102a27:	8d 5e a0             	lea    -0x60(%esi),%ebx
f0102a2a:	ba 00 00 00 00       	mov    $0x0,%edx
f0102a2f:	89 c1                	mov    %eax,%ecx
f0102a31:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_link = env_free_list; 
f0102a38:	89 50 44             	mov    %edx,0x44(%eax)
		envs[i].env_status = ENV_FREE; 
f0102a3b:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
f0102a42:	83 e8 60             	sub    $0x60,%eax
		env_free_list = &envs[i]; 
f0102a45:	89 ca                	mov    %ecx,%edx
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.
	env_free_list = NULL; 
	for(int i = NENV - 1;i >= 0;i--)
f0102a47:	39 d8                	cmp    %ebx,%eax
f0102a49:	75 e4                	jne    f0102a2f <env_init+0x19>
f0102a4b:	89 35 50 ce 17 f0    	mov    %esi,0xf017ce50
		envs[i].env_link = env_free_list; 
		envs[i].env_status = ENV_FREE; 
		env_free_list = &envs[i]; 
	}
	// Per-CPU part of the initialization
	env_init_percpu();
f0102a51:	e8 90 ff ff ff       	call   f01029e6 <env_init_percpu>
}
f0102a56:	5b                   	pop    %ebx
f0102a57:	5e                   	pop    %esi
f0102a58:	5d                   	pop    %ebp
f0102a59:	c3                   	ret    

f0102a5a <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0102a5a:	55                   	push   %ebp
f0102a5b:	89 e5                	mov    %esp,%ebp
f0102a5d:	53                   	push   %ebx
f0102a5e:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0102a61:	8b 1d 50 ce 17 f0    	mov    0xf017ce50,%ebx
f0102a67:	85 db                	test   %ebx,%ebx
f0102a69:	0f 84 43 01 00 00    	je     f0102bb2 <env_alloc+0x158>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0102a6f:	83 ec 0c             	sub    $0xc,%esp
f0102a72:	6a 01                	push   $0x1
f0102a74:	e8 00 e3 ff ff       	call   f0100d79 <page_alloc>
f0102a79:	83 c4 10             	add    $0x10,%esp
f0102a7c:	85 c0                	test   %eax,%eax
f0102a7e:	0f 84 35 01 00 00    	je     f0102bb9 <env_alloc+0x15f>
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	p->pp_ref++; 
f0102a84:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102a89:	2b 05 0c db 17 f0    	sub    0xf017db0c,%eax
f0102a8f:	c1 f8 03             	sar    $0x3,%eax
f0102a92:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102a95:	89 c2                	mov    %eax,%edx
f0102a97:	c1 ea 0c             	shr    $0xc,%edx
f0102a9a:	3b 15 04 db 17 f0    	cmp    0xf017db04,%edx
f0102aa0:	72 12                	jb     f0102ab4 <env_alloc+0x5a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102aa2:	50                   	push   %eax
f0102aa3:	68 7c 50 10 f0       	push   $0xf010507c
f0102aa8:	6a 56                	push   $0x56
f0102aaa:	68 7e 4d 10 f0       	push   $0xf0104d7e
f0102aaf:	e8 ec d5 ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f0102ab4:	2d 00 00 00 10       	sub    $0x10000000,%eax
	e->env_pgdir = page2kva(p); 
f0102ab9:	89 43 5c             	mov    %eax,0x5c(%ebx)
	memcpy(e->env_pgdir, kern_pgdir, PGSIZE);
f0102abc:	83 ec 04             	sub    $0x4,%esp
f0102abf:	68 00 10 00 00       	push   $0x1000
f0102ac4:	ff 35 08 db 17 f0    	pushl  0xf017db08
f0102aca:	50                   	push   %eax
f0102acb:	e8 98 19 00 00       	call   f0104468 <memcpy>
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0102ad0:	8b 43 5c             	mov    0x5c(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102ad3:	83 c4 10             	add    $0x10,%esp
f0102ad6:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102adb:	77 15                	ja     f0102af2 <env_alloc+0x98>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102add:	50                   	push   %eax
f0102ade:	68 c0 51 10 f0       	push   $0xf01051c0
f0102ae3:	68 c2 00 00 00       	push   $0xc2
f0102ae8:	68 53 58 10 f0       	push   $0xf0105853
f0102aed:	e8 ae d5 ff ff       	call   f01000a0 <_panic>
f0102af2:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0102af8:	83 ca 05             	or     $0x5,%edx
f0102afb:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0102b01:	8b 43 48             	mov    0x48(%ebx),%eax
f0102b04:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0102b09:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0102b0e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102b13:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0102b16:	89 da                	mov    %ebx,%edx
f0102b18:	2b 15 4c ce 17 f0    	sub    0xf017ce4c,%edx
f0102b1e:	c1 fa 05             	sar    $0x5,%edx
f0102b21:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0102b27:	09 d0                	or     %edx,%eax
f0102b29:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0102b2c:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102b2f:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0102b32:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0102b39:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0102b40:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0102b47:	83 ec 04             	sub    $0x4,%esp
f0102b4a:	6a 44                	push   $0x44
f0102b4c:	6a 00                	push   $0x0
f0102b4e:	53                   	push   %ebx
f0102b4f:	e8 5f 18 00 00       	call   f01043b3 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0102b54:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0102b5a:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0102b60:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0102b66:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0102b6d:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f0102b73:	8b 43 44             	mov    0x44(%ebx),%eax
f0102b76:	a3 50 ce 17 f0       	mov    %eax,0xf017ce50
	*newenv_store = e;
f0102b7b:	8b 45 08             	mov    0x8(%ebp),%eax
f0102b7e:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102b80:	8b 53 48             	mov    0x48(%ebx),%edx
f0102b83:	a1 48 ce 17 f0       	mov    0xf017ce48,%eax
f0102b88:	83 c4 10             	add    $0x10,%esp
f0102b8b:	85 c0                	test   %eax,%eax
f0102b8d:	74 05                	je     f0102b94 <env_alloc+0x13a>
f0102b8f:	8b 40 48             	mov    0x48(%eax),%eax
f0102b92:	eb 05                	jmp    f0102b99 <env_alloc+0x13f>
f0102b94:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b99:	83 ec 04             	sub    $0x4,%esp
f0102b9c:	52                   	push   %edx
f0102b9d:	50                   	push   %eax
f0102b9e:	68 72 58 10 f0       	push   $0xf0105872
f0102ba3:	e8 1b 04 00 00       	call   f0102fc3 <cprintf>
	return 0;
f0102ba8:	83 c4 10             	add    $0x10,%esp
f0102bab:	b8 00 00 00 00       	mov    $0x0,%eax
f0102bb0:	eb 0c                	jmp    f0102bbe <env_alloc+0x164>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0102bb2:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0102bb7:	eb 05                	jmp    f0102bbe <env_alloc+0x164>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0102bb9:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0102bbe:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102bc1:	c9                   	leave  
f0102bc2:	c3                   	ret    

f0102bc3 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0102bc3:	55                   	push   %ebp
f0102bc4:	89 e5                	mov    %esp,%ebp
f0102bc6:	57                   	push   %edi
f0102bc7:	56                   	push   %esi
f0102bc8:	53                   	push   %ebx
f0102bc9:	83 ec 34             	sub    $0x34,%esp
f0102bcc:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env *e;
	int flag = env_alloc(&e, 0);
f0102bcf:	6a 00                	push   $0x0
f0102bd1:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0102bd4:	50                   	push   %eax
f0102bd5:	e8 80 fe ff ff       	call   f0102a5a <env_alloc>
	if(flag != 0) 
f0102bda:	83 c4 10             	add    $0x10,%esp
f0102bdd:	85 c0                	test   %eax,%eax
f0102bdf:	74 17                	je     f0102bf8 <env_create+0x35>
	{
		panic("create new env failed!");
f0102be1:	83 ec 04             	sub    $0x4,%esp
f0102be4:	68 87 58 10 f0       	push   $0xf0105887
f0102be9:	68 89 01 00 00       	push   $0x189
f0102bee:	68 53 58 10 f0       	push   $0xf0105853
f0102bf3:	e8 a8 d4 ff ff       	call   f01000a0 <_panic>
	}
	load_icode(e, binary);
f0102bf8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102bfb:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	//  What?  (See env_run() and env_pop_tf() below.)

	// LAB 3: Your code here.
	struct Elf *elf_header = (struct Elf*)binary; 
	struct Proghdr *ph, *eph;
	if (elf_header->e_magic != ELF_MAGIC)
f0102bfe:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f0102c04:	74 17                	je     f0102c1d <env_create+0x5a>
	{
		panic("binary is not a elf file"); 
f0102c06:	83 ec 04             	sub    $0x4,%esp
f0102c09:	68 9e 58 10 f0       	push   $0xf010589e
f0102c0e:	68 63 01 00 00       	push   $0x163
f0102c13:	68 53 58 10 f0       	push   $0xf0105853
f0102c18:	e8 83 d4 ff ff       	call   f01000a0 <_panic>
	}
	ph = (struct Proghdr*) ((uint8_t*)elf_header + elf_header->e_phoff);
f0102c1d:	89 fb                	mov    %edi,%ebx
f0102c1f:	03 5f 1c             	add    0x1c(%edi),%ebx
	eph = ph + elf_header->e_phnum;
f0102c22:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f0102c26:	c1 e6 05             	shl    $0x5,%esi
f0102c29:	01 de                	add    %ebx,%esi
	lcr3(PADDR(e->env_pgdir)); 
f0102c2b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102c2e:	8b 40 5c             	mov    0x5c(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102c31:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102c36:	77 15                	ja     f0102c4d <env_create+0x8a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102c38:	50                   	push   %eax
f0102c39:	68 c0 51 10 f0       	push   $0xf01051c0
f0102c3e:	68 67 01 00 00       	push   $0x167
f0102c43:	68 53 58 10 f0       	push   $0xf0105853
f0102c48:	e8 53 d4 ff ff       	call   f01000a0 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102c4d:	05 00 00 00 10       	add    $0x10000000,%eax
f0102c52:	0f 22 d8             	mov    %eax,%cr3
f0102c55:	eb 44                	jmp    f0102c9b <env_create+0xd8>
	for (; ph < eph; ph++)
	{
		if(ph->p_type == ELF_PROG_LOAD) 
f0102c57:	83 3b 01             	cmpl   $0x1,(%ebx)
f0102c5a:	75 3c                	jne    f0102c98 <env_create+0xd5>
		{
			region_alloc(e, (void*)ph->p_va, ph->p_memsz); 
f0102c5c:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0102c5f:	8b 53 08             	mov    0x8(%ebx),%edx
f0102c62:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102c65:	e8 78 fc ff ff       	call   f01028e2 <region_alloc>
			memmove((void*)ph->p_va, binary + ph->p_offset, ph->p_filesz);
f0102c6a:	83 ec 04             	sub    $0x4,%esp
f0102c6d:	ff 73 10             	pushl  0x10(%ebx)
f0102c70:	89 f8                	mov    %edi,%eax
f0102c72:	03 43 04             	add    0x4(%ebx),%eax
f0102c75:	50                   	push   %eax
f0102c76:	ff 73 08             	pushl  0x8(%ebx)
f0102c79:	e8 82 17 00 00       	call   f0104400 <memmove>
            		memset((void*)(ph->p_va + ph->p_filesz), 0, ph->p_memsz - ph->p_filesz);
f0102c7e:	8b 43 10             	mov    0x10(%ebx),%eax
f0102c81:	83 c4 0c             	add    $0xc,%esp
f0102c84:	8b 53 14             	mov    0x14(%ebx),%edx
f0102c87:	29 c2                	sub    %eax,%edx
f0102c89:	52                   	push   %edx
f0102c8a:	6a 00                	push   $0x0
f0102c8c:	03 43 08             	add    0x8(%ebx),%eax
f0102c8f:	50                   	push   %eax
f0102c90:	e8 1e 17 00 00       	call   f01043b3 <memset>
f0102c95:	83 c4 10             	add    $0x10,%esp
		panic("binary is not a elf file"); 
	}
	ph = (struct Proghdr*) ((uint8_t*)elf_header + elf_header->e_phoff);
	eph = ph + elf_header->e_phnum;
	lcr3(PADDR(e->env_pgdir)); 
	for (; ph < eph; ph++)
f0102c98:	83 c3 20             	add    $0x20,%ebx
f0102c9b:	39 de                	cmp    %ebx,%esi
f0102c9d:	77 b8                	ja     f0102c57 <env_create+0x94>
			region_alloc(e, (void*)ph->p_va, ph->p_memsz); 
			memmove((void*)ph->p_va, binary + ph->p_offset, ph->p_filesz);
            		memset((void*)(ph->p_va + ph->p_filesz), 0, ph->p_memsz - ph->p_filesz);
		}
	}
	e->env_tf.tf_eip = elf_header->e_entry; 
f0102c9f:	8b 47 18             	mov    0x18(%edi),%eax
f0102ca2:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102ca5:	89 41 30             	mov    %eax,0x30(%ecx)
	lcr3(PADDR(kern_pgdir)); 
f0102ca8:	a1 08 db 17 f0       	mov    0xf017db08,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102cad:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102cb2:	77 15                	ja     f0102cc9 <env_create+0x106>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102cb4:	50                   	push   %eax
f0102cb5:	68 c0 51 10 f0       	push   $0xf01051c0
f0102cba:	68 72 01 00 00       	push   $0x172
f0102cbf:	68 53 58 10 f0       	push   $0xf0105853
f0102cc4:	e8 d7 d3 ff ff       	call   f01000a0 <_panic>
f0102cc9:	05 00 00 00 10       	add    $0x10000000,%eax
f0102cce:	0f 22 d8             	mov    %eax,%cr3
	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here.
	region_alloc(e, (void*)(USTACKTOP - PGSIZE), PGSIZE);
f0102cd1:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0102cd6:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0102cdb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102cde:	e8 ff fb ff ff       	call   f01028e2 <region_alloc>
	if(flag != 0) 
	{
		panic("create new env failed!");
	}
	load_icode(e, binary);
	e->env_type = type; 
f0102ce3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102ce6:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102ce9:	89 50 50             	mov    %edx,0x50(%eax)
}
f0102cec:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102cef:	5b                   	pop    %ebx
f0102cf0:	5e                   	pop    %esi
f0102cf1:	5f                   	pop    %edi
f0102cf2:	5d                   	pop    %ebp
f0102cf3:	c3                   	ret    

f0102cf4 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0102cf4:	55                   	push   %ebp
f0102cf5:	89 e5                	mov    %esp,%ebp
f0102cf7:	57                   	push   %edi
f0102cf8:	56                   	push   %esi
f0102cf9:	53                   	push   %ebx
f0102cfa:	83 ec 1c             	sub    $0x1c,%esp
f0102cfd:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0102d00:	8b 15 48 ce 17 f0    	mov    0xf017ce48,%edx
f0102d06:	39 fa                	cmp    %edi,%edx
f0102d08:	75 29                	jne    f0102d33 <env_free+0x3f>
		lcr3(PADDR(kern_pgdir));
f0102d0a:	a1 08 db 17 f0       	mov    0xf017db08,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102d0f:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102d14:	77 15                	ja     f0102d2b <env_free+0x37>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102d16:	50                   	push   %eax
f0102d17:	68 c0 51 10 f0       	push   $0xf01051c0
f0102d1c:	68 9d 01 00 00       	push   $0x19d
f0102d21:	68 53 58 10 f0       	push   $0xf0105853
f0102d26:	e8 75 d3 ff ff       	call   f01000a0 <_panic>
f0102d2b:	05 00 00 00 10       	add    $0x10000000,%eax
f0102d30:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102d33:	8b 4f 48             	mov    0x48(%edi),%ecx
f0102d36:	85 d2                	test   %edx,%edx
f0102d38:	74 05                	je     f0102d3f <env_free+0x4b>
f0102d3a:	8b 42 48             	mov    0x48(%edx),%eax
f0102d3d:	eb 05                	jmp    f0102d44 <env_free+0x50>
f0102d3f:	b8 00 00 00 00       	mov    $0x0,%eax
f0102d44:	83 ec 04             	sub    $0x4,%esp
f0102d47:	51                   	push   %ecx
f0102d48:	50                   	push   %eax
f0102d49:	68 b7 58 10 f0       	push   $0xf01058b7
f0102d4e:	e8 70 02 00 00       	call   f0102fc3 <cprintf>
f0102d53:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102d56:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0102d5d:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0102d60:	89 d0                	mov    %edx,%eax
f0102d62:	c1 e0 02             	shl    $0x2,%eax
f0102d65:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0102d68:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102d6b:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0102d6e:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0102d74:	0f 84 a8 00 00 00    	je     f0102e22 <env_free+0x12e>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0102d7a:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102d80:	89 f0                	mov    %esi,%eax
f0102d82:	c1 e8 0c             	shr    $0xc,%eax
f0102d85:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102d88:	39 05 04 db 17 f0    	cmp    %eax,0xf017db04
f0102d8e:	77 15                	ja     f0102da5 <env_free+0xb1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102d90:	56                   	push   %esi
f0102d91:	68 7c 50 10 f0       	push   $0xf010507c
f0102d96:	68 ac 01 00 00       	push   $0x1ac
f0102d9b:	68 53 58 10 f0       	push   $0xf0105853
f0102da0:	e8 fb d2 ff ff       	call   f01000a0 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102da5:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102da8:	c1 e0 16             	shl    $0x16,%eax
f0102dab:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102dae:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0102db3:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0102dba:	01 
f0102dbb:	74 17                	je     f0102dd4 <env_free+0xe0>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102dbd:	83 ec 08             	sub    $0x8,%esp
f0102dc0:	89 d8                	mov    %ebx,%eax
f0102dc2:	c1 e0 0c             	shl    $0xc,%eax
f0102dc5:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0102dc8:	50                   	push   %eax
f0102dc9:	ff 77 5c             	pushl  0x5c(%edi)
f0102dcc:	e8 15 e2 ff ff       	call   f0100fe6 <page_remove>
f0102dd1:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102dd4:	83 c3 01             	add    $0x1,%ebx
f0102dd7:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0102ddd:	75 d4                	jne    f0102db3 <env_free+0xbf>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0102ddf:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102de2:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102de5:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102dec:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102def:	3b 05 04 db 17 f0    	cmp    0xf017db04,%eax
f0102df5:	72 14                	jb     f0102e0b <env_free+0x117>
		panic("pa2page called with invalid pa");
f0102df7:	83 ec 04             	sub    $0x4,%esp
f0102dfa:	68 64 51 10 f0       	push   $0xf0105164
f0102dff:	6a 4f                	push   $0x4f
f0102e01:	68 7e 4d 10 f0       	push   $0xf0104d7e
f0102e06:	e8 95 d2 ff ff       	call   f01000a0 <_panic>
		page_decref(pa2page(pa));
f0102e0b:	83 ec 0c             	sub    $0xc,%esp
f0102e0e:	a1 0c db 17 f0       	mov    0xf017db0c,%eax
f0102e13:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102e16:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f0102e19:	50                   	push   %eax
f0102e1a:	e8 20 e0 ff ff       	call   f0100e3f <page_decref>
f0102e1f:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102e22:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0102e26:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102e29:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102e2e:	0f 85 29 ff ff ff    	jne    f0102d5d <env_free+0x69>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0102e34:	8b 47 5c             	mov    0x5c(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102e37:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102e3c:	77 15                	ja     f0102e53 <env_free+0x15f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102e3e:	50                   	push   %eax
f0102e3f:	68 c0 51 10 f0       	push   $0xf01051c0
f0102e44:	68 ba 01 00 00       	push   $0x1ba
f0102e49:	68 53 58 10 f0       	push   $0xf0105853
f0102e4e:	e8 4d d2 ff ff       	call   f01000a0 <_panic>
	e->env_pgdir = 0;
f0102e53:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102e5a:	05 00 00 00 10       	add    $0x10000000,%eax
f0102e5f:	c1 e8 0c             	shr    $0xc,%eax
f0102e62:	3b 05 04 db 17 f0    	cmp    0xf017db04,%eax
f0102e68:	72 14                	jb     f0102e7e <env_free+0x18a>
		panic("pa2page called with invalid pa");
f0102e6a:	83 ec 04             	sub    $0x4,%esp
f0102e6d:	68 64 51 10 f0       	push   $0xf0105164
f0102e72:	6a 4f                	push   $0x4f
f0102e74:	68 7e 4d 10 f0       	push   $0xf0104d7e
f0102e79:	e8 22 d2 ff ff       	call   f01000a0 <_panic>
	page_decref(pa2page(pa));
f0102e7e:	83 ec 0c             	sub    $0xc,%esp
f0102e81:	8b 15 0c db 17 f0    	mov    0xf017db0c,%edx
f0102e87:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0102e8a:	50                   	push   %eax
f0102e8b:	e8 af df ff ff       	call   f0100e3f <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0102e90:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0102e97:	a1 50 ce 17 f0       	mov    0xf017ce50,%eax
f0102e9c:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0102e9f:	89 3d 50 ce 17 f0    	mov    %edi,0xf017ce50
}
f0102ea5:	83 c4 10             	add    $0x10,%esp
f0102ea8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102eab:	5b                   	pop    %ebx
f0102eac:	5e                   	pop    %esi
f0102ead:	5f                   	pop    %edi
f0102eae:	5d                   	pop    %ebp
f0102eaf:	c3                   	ret    

f0102eb0 <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f0102eb0:	55                   	push   %ebp
f0102eb1:	89 e5                	mov    %esp,%ebp
f0102eb3:	83 ec 14             	sub    $0x14,%esp
	env_free(e);
f0102eb6:	ff 75 08             	pushl  0x8(%ebp)
f0102eb9:	e8 36 fe ff ff       	call   f0102cf4 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f0102ebe:	c7 04 24 dc 58 10 f0 	movl   $0xf01058dc,(%esp)
f0102ec5:	e8 f9 00 00 00       	call   f0102fc3 <cprintf>
f0102eca:	83 c4 10             	add    $0x10,%esp
	while (1)
		monitor(NULL);
f0102ecd:	83 ec 0c             	sub    $0xc,%esp
f0102ed0:	6a 00                	push   $0x0
f0102ed2:	e8 dc d8 ff ff       	call   f01007b3 <monitor>
f0102ed7:	83 c4 10             	add    $0x10,%esp
f0102eda:	eb f1                	jmp    f0102ecd <env_destroy+0x1d>

f0102edc <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0102edc:	55                   	push   %ebp
f0102edd:	89 e5                	mov    %esp,%ebp
f0102edf:	83 ec 0c             	sub    $0xc,%esp
	__asm __volatile("movl %0,%%esp\n"
f0102ee2:	8b 65 08             	mov    0x8(%ebp),%esp
f0102ee5:	61                   	popa   
f0102ee6:	07                   	pop    %es
f0102ee7:	1f                   	pop    %ds
f0102ee8:	83 c4 08             	add    $0x8,%esp
f0102eeb:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0102eec:	68 cd 58 10 f0       	push   $0xf01058cd
f0102ef1:	68 e2 01 00 00       	push   $0x1e2
f0102ef6:	68 53 58 10 f0       	push   $0xf0105853
f0102efb:	e8 a0 d1 ff ff       	call   f01000a0 <_panic>

f0102f00 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0102f00:	55                   	push   %ebp
f0102f01:	89 e5                	mov    %esp,%ebp
f0102f03:	83 ec 08             	sub    $0x8,%esp
f0102f06:	8b 45 08             	mov    0x8(%ebp),%eax
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	if(curenv != NULL)
f0102f09:	8b 15 48 ce 17 f0    	mov    0xf017ce48,%edx
f0102f0f:	85 d2                	test   %edx,%edx
f0102f11:	74 07                	je     f0102f1a <env_run+0x1a>
	{
		curenv->env_status = ENV_RUNNABLE;
f0102f13:	c7 42 54 02 00 00 00 	movl   $0x2,0x54(%edx)
	}
	curenv = e; 
f0102f1a:	a3 48 ce 17 f0       	mov    %eax,0xf017ce48
	e->env_status = ENV_RUNNING; 
f0102f1f:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	e->env_runs++; 
f0102f26:	83 40 58 01          	addl   $0x1,0x58(%eax)
	lcr3(PADDR(e->env_pgdir)); 
f0102f2a:	8b 50 5c             	mov    0x5c(%eax),%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102f2d:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0102f33:	77 15                	ja     f0102f4a <env_run+0x4a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102f35:	52                   	push   %edx
f0102f36:	68 c0 51 10 f0       	push   $0xf01051c0
f0102f3b:	68 07 02 00 00       	push   $0x207
f0102f40:	68 53 58 10 f0       	push   $0xf0105853
f0102f45:	e8 56 d1 ff ff       	call   f01000a0 <_panic>
f0102f4a:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0102f50:	0f 22 da             	mov    %edx,%cr3
	env_pop_tf(&(e->env_tf));
f0102f53:	83 ec 0c             	sub    $0xc,%esp
f0102f56:	50                   	push   %eax
f0102f57:	e8 80 ff ff ff       	call   f0102edc <env_pop_tf>

f0102f5c <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102f5c:	55                   	push   %ebp
f0102f5d:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102f5f:	ba 70 00 00 00       	mov    $0x70,%edx
f0102f64:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f67:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102f68:	ba 71 00 00 00       	mov    $0x71,%edx
f0102f6d:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102f6e:	0f b6 c0             	movzbl %al,%eax
}
f0102f71:	5d                   	pop    %ebp
f0102f72:	c3                   	ret    

f0102f73 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102f73:	55                   	push   %ebp
f0102f74:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102f76:	ba 70 00 00 00       	mov    $0x70,%edx
f0102f7b:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f7e:	ee                   	out    %al,(%dx)
f0102f7f:	ba 71 00 00 00       	mov    $0x71,%edx
f0102f84:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102f87:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102f88:	5d                   	pop    %ebp
f0102f89:	c3                   	ret    

f0102f8a <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102f8a:	55                   	push   %ebp
f0102f8b:	89 e5                	mov    %esp,%ebp
f0102f8d:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0102f90:	ff 75 08             	pushl  0x8(%ebp)
f0102f93:	e8 6f d6 ff ff       	call   f0100607 <cputchar>
	*cnt++;
}
f0102f98:	83 c4 10             	add    $0x10,%esp
f0102f9b:	c9                   	leave  
f0102f9c:	c3                   	ret    

f0102f9d <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102f9d:	55                   	push   %ebp
f0102f9e:	89 e5                	mov    %esp,%ebp
f0102fa0:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0102fa3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102faa:	ff 75 0c             	pushl  0xc(%ebp)
f0102fad:	ff 75 08             	pushl  0x8(%ebp)
f0102fb0:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102fb3:	50                   	push   %eax
f0102fb4:	68 8a 2f 10 f0       	push   $0xf0102f8a
f0102fb9:	e8 d0 0c 00 00       	call   f0103c8e <vprintfmt>
	return cnt;
}
f0102fbe:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102fc1:	c9                   	leave  
f0102fc2:	c3                   	ret    

f0102fc3 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102fc3:	55                   	push   %ebp
f0102fc4:	89 e5                	mov    %esp,%ebp
f0102fc6:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102fc9:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102fcc:	50                   	push   %eax
f0102fcd:	ff 75 08             	pushl  0x8(%ebp)
f0102fd0:	e8 c8 ff ff ff       	call   f0102f9d <vcprintf>
	va_end(ap);

	return cnt;
}
f0102fd5:	c9                   	leave  
f0102fd6:	c3                   	ret    

f0102fd7 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0102fd7:	55                   	push   %ebp
f0102fd8:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0102fda:	b8 80 d6 17 f0       	mov    $0xf017d680,%eax
f0102fdf:	c7 05 84 d6 17 f0 00 	movl   $0xf0000000,0xf017d684
f0102fe6:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f0102fe9:	66 c7 05 88 d6 17 f0 	movw   $0x10,0xf017d688
f0102ff0:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f0102ff2:	66 c7 05 48 b3 11 f0 	movw   $0x67,0xf011b348
f0102ff9:	67 00 
f0102ffb:	66 a3 4a b3 11 f0    	mov    %ax,0xf011b34a
f0103001:	89 c2                	mov    %eax,%edx
f0103003:	c1 ea 10             	shr    $0x10,%edx
f0103006:	88 15 4c b3 11 f0    	mov    %dl,0xf011b34c
f010300c:	c6 05 4e b3 11 f0 40 	movb   $0x40,0xf011b34e
f0103013:	c1 e8 18             	shr    $0x18,%eax
f0103016:	a2 4f b3 11 f0       	mov    %al,0xf011b34f
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f010301b:	c6 05 4d b3 11 f0 89 	movb   $0x89,0xf011b34d
}

static __inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f0103022:	b8 28 00 00 00       	mov    $0x28,%eax
f0103027:	0f 00 d8             	ltr    %ax
}

static __inline void
lidt(void *p)
{
	__asm __volatile("lidt (%0)" : : "r" (p));
f010302a:	b8 50 b3 11 f0       	mov    $0xf011b350,%eax
f010302f:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f0103032:	5d                   	pop    %ebp
f0103033:	c3                   	ret    

f0103034 <trap_init>:
}


void
trap_init(void)
{
f0103034:	55                   	push   %ebp
f0103035:	89 e5                	mov    %esp,%ebp
    void t_fperr();
    void t_align();
    void t_mchk();
    void t_simderr();
    void t_syscall();
    SETGATE(idt[T_DIVIDE], 0, GD_KT, t_divide, 0);
f0103037:	b8 08 37 10 f0       	mov    $0xf0103708,%eax
f010303c:	66 a3 60 ce 17 f0    	mov    %ax,0xf017ce60
f0103042:	66 c7 05 62 ce 17 f0 	movw   $0x8,0xf017ce62
f0103049:	08 00 
f010304b:	c6 05 64 ce 17 f0 00 	movb   $0x0,0xf017ce64
f0103052:	c6 05 65 ce 17 f0 8e 	movb   $0x8e,0xf017ce65
f0103059:	c1 e8 10             	shr    $0x10,%eax
f010305c:	66 a3 66 ce 17 f0    	mov    %ax,0xf017ce66
    SETGATE(idt[T_DEBUG], 0, GD_KT, t_debug, 0);
f0103062:	b8 0e 37 10 f0       	mov    $0xf010370e,%eax
f0103067:	66 a3 68 ce 17 f0    	mov    %ax,0xf017ce68
f010306d:	66 c7 05 6a ce 17 f0 	movw   $0x8,0xf017ce6a
f0103074:	08 00 
f0103076:	c6 05 6c ce 17 f0 00 	movb   $0x0,0xf017ce6c
f010307d:	c6 05 6d ce 17 f0 8e 	movb   $0x8e,0xf017ce6d
f0103084:	c1 e8 10             	shr    $0x10,%eax
f0103087:	66 a3 6e ce 17 f0    	mov    %ax,0xf017ce6e
    SETGATE(idt[T_NMI], 0, GD_KT, t_nmi, 0);
f010308d:	b8 14 37 10 f0       	mov    $0xf0103714,%eax
f0103092:	66 a3 70 ce 17 f0    	mov    %ax,0xf017ce70
f0103098:	66 c7 05 72 ce 17 f0 	movw   $0x8,0xf017ce72
f010309f:	08 00 
f01030a1:	c6 05 74 ce 17 f0 00 	movb   $0x0,0xf017ce74
f01030a8:	c6 05 75 ce 17 f0 8e 	movb   $0x8e,0xf017ce75
f01030af:	c1 e8 10             	shr    $0x10,%eax
f01030b2:	66 a3 76 ce 17 f0    	mov    %ax,0xf017ce76
    SETGATE(idt[T_BRKPT], 1, GD_KT, t_brkpt, 3);
f01030b8:	b8 1a 37 10 f0       	mov    $0xf010371a,%eax
f01030bd:	66 a3 78 ce 17 f0    	mov    %ax,0xf017ce78
f01030c3:	66 c7 05 7a ce 17 f0 	movw   $0x8,0xf017ce7a
f01030ca:	08 00 
f01030cc:	c6 05 7c ce 17 f0 00 	movb   $0x0,0xf017ce7c
f01030d3:	c6 05 7d ce 17 f0 ef 	movb   $0xef,0xf017ce7d
f01030da:	c1 e8 10             	shr    $0x10,%eax
f01030dd:	66 a3 7e ce 17 f0    	mov    %ax,0xf017ce7e
    SETGATE(idt[T_OFLOW], 0, GD_KT, t_oflow, 0);
f01030e3:	b8 20 37 10 f0       	mov    $0xf0103720,%eax
f01030e8:	66 a3 80 ce 17 f0    	mov    %ax,0xf017ce80
f01030ee:	66 c7 05 82 ce 17 f0 	movw   $0x8,0xf017ce82
f01030f5:	08 00 
f01030f7:	c6 05 84 ce 17 f0 00 	movb   $0x0,0xf017ce84
f01030fe:	c6 05 85 ce 17 f0 8e 	movb   $0x8e,0xf017ce85
f0103105:	c1 e8 10             	shr    $0x10,%eax
f0103108:	66 a3 86 ce 17 f0    	mov    %ax,0xf017ce86
    SETGATE(idt[T_BOUND], 0, GD_KT, t_bound, 0);
f010310e:	b8 26 37 10 f0       	mov    $0xf0103726,%eax
f0103113:	66 a3 88 ce 17 f0    	mov    %ax,0xf017ce88
f0103119:	66 c7 05 8a ce 17 f0 	movw   $0x8,0xf017ce8a
f0103120:	08 00 
f0103122:	c6 05 8c ce 17 f0 00 	movb   $0x0,0xf017ce8c
f0103129:	c6 05 8d ce 17 f0 8e 	movb   $0x8e,0xf017ce8d
f0103130:	c1 e8 10             	shr    $0x10,%eax
f0103133:	66 a3 8e ce 17 f0    	mov    %ax,0xf017ce8e
    SETGATE(idt[T_ILLOP], 0, GD_KT, t_illop, 0);
f0103139:	b8 2c 37 10 f0       	mov    $0xf010372c,%eax
f010313e:	66 a3 90 ce 17 f0    	mov    %ax,0xf017ce90
f0103144:	66 c7 05 92 ce 17 f0 	movw   $0x8,0xf017ce92
f010314b:	08 00 
f010314d:	c6 05 94 ce 17 f0 00 	movb   $0x0,0xf017ce94
f0103154:	c6 05 95 ce 17 f0 8e 	movb   $0x8e,0xf017ce95
f010315b:	c1 e8 10             	shr    $0x10,%eax
f010315e:	66 a3 96 ce 17 f0    	mov    %ax,0xf017ce96
    SETGATE(idt[T_DEVICE], 0, GD_KT, t_device, 0);
f0103164:	b8 32 37 10 f0       	mov    $0xf0103732,%eax
f0103169:	66 a3 98 ce 17 f0    	mov    %ax,0xf017ce98
f010316f:	66 c7 05 9a ce 17 f0 	movw   $0x8,0xf017ce9a
f0103176:	08 00 
f0103178:	c6 05 9c ce 17 f0 00 	movb   $0x0,0xf017ce9c
f010317f:	c6 05 9d ce 17 f0 8e 	movb   $0x8e,0xf017ce9d
f0103186:	c1 e8 10             	shr    $0x10,%eax
f0103189:	66 a3 9e ce 17 f0    	mov    %ax,0xf017ce9e
    SETGATE(idt[T_DBLFLT], 0, GD_KT, t_dblflt, 0);
f010318f:	b8 38 37 10 f0       	mov    $0xf0103738,%eax
f0103194:	66 a3 a0 ce 17 f0    	mov    %ax,0xf017cea0
f010319a:	66 c7 05 a2 ce 17 f0 	movw   $0x8,0xf017cea2
f01031a1:	08 00 
f01031a3:	c6 05 a4 ce 17 f0 00 	movb   $0x0,0xf017cea4
f01031aa:	c6 05 a5 ce 17 f0 8e 	movb   $0x8e,0xf017cea5
f01031b1:	c1 e8 10             	shr    $0x10,%eax
f01031b4:	66 a3 a6 ce 17 f0    	mov    %ax,0xf017cea6
    SETGATE(idt[T_TSS], 0, GD_KT, t_tss, 0);
f01031ba:	b8 3c 37 10 f0       	mov    $0xf010373c,%eax
f01031bf:	66 a3 b0 ce 17 f0    	mov    %ax,0xf017ceb0
f01031c5:	66 c7 05 b2 ce 17 f0 	movw   $0x8,0xf017ceb2
f01031cc:	08 00 
f01031ce:	c6 05 b4 ce 17 f0 00 	movb   $0x0,0xf017ceb4
f01031d5:	c6 05 b5 ce 17 f0 8e 	movb   $0x8e,0xf017ceb5
f01031dc:	c1 e8 10             	shr    $0x10,%eax
f01031df:	66 a3 b6 ce 17 f0    	mov    %ax,0xf017ceb6
    SETGATE(idt[T_SEGNP], 0, GD_KT, t_segnp, 0);
f01031e5:	b8 40 37 10 f0       	mov    $0xf0103740,%eax
f01031ea:	66 a3 b8 ce 17 f0    	mov    %ax,0xf017ceb8
f01031f0:	66 c7 05 ba ce 17 f0 	movw   $0x8,0xf017ceba
f01031f7:	08 00 
f01031f9:	c6 05 bc ce 17 f0 00 	movb   $0x0,0xf017cebc
f0103200:	c6 05 bd ce 17 f0 8e 	movb   $0x8e,0xf017cebd
f0103207:	c1 e8 10             	shr    $0x10,%eax
f010320a:	66 a3 be ce 17 f0    	mov    %ax,0xf017cebe
    SETGATE(idt[T_STACK], 0, GD_KT, t_stack, 0);
f0103210:	b8 44 37 10 f0       	mov    $0xf0103744,%eax
f0103215:	66 a3 c0 ce 17 f0    	mov    %ax,0xf017cec0
f010321b:	66 c7 05 c2 ce 17 f0 	movw   $0x8,0xf017cec2
f0103222:	08 00 
f0103224:	c6 05 c4 ce 17 f0 00 	movb   $0x0,0xf017cec4
f010322b:	c6 05 c5 ce 17 f0 8e 	movb   $0x8e,0xf017cec5
f0103232:	c1 e8 10             	shr    $0x10,%eax
f0103235:	66 a3 c6 ce 17 f0    	mov    %ax,0xf017cec6
    SETGATE(idt[T_GPFLT], 0, GD_KT, t_gpflt, 0);
f010323b:	b8 48 37 10 f0       	mov    $0xf0103748,%eax
f0103240:	66 a3 c8 ce 17 f0    	mov    %ax,0xf017cec8
f0103246:	66 c7 05 ca ce 17 f0 	movw   $0x8,0xf017ceca
f010324d:	08 00 
f010324f:	c6 05 cc ce 17 f0 00 	movb   $0x0,0xf017cecc
f0103256:	c6 05 cd ce 17 f0 8e 	movb   $0x8e,0xf017cecd
f010325d:	c1 e8 10             	shr    $0x10,%eax
f0103260:	66 a3 ce ce 17 f0    	mov    %ax,0xf017cece
    SETGATE(idt[T_PGFLT], 0, GD_KT, t_pgflt, 0);
f0103266:	b8 4c 37 10 f0       	mov    $0xf010374c,%eax
f010326b:	66 a3 d0 ce 17 f0    	mov    %ax,0xf017ced0
f0103271:	66 c7 05 d2 ce 17 f0 	movw   $0x8,0xf017ced2
f0103278:	08 00 
f010327a:	c6 05 d4 ce 17 f0 00 	movb   $0x0,0xf017ced4
f0103281:	c6 05 d5 ce 17 f0 8e 	movb   $0x8e,0xf017ced5
f0103288:	c1 e8 10             	shr    $0x10,%eax
f010328b:	66 a3 d6 ce 17 f0    	mov    %ax,0xf017ced6
    SETGATE(idt[T_FPERR], 0, GD_KT, t_fperr, 0);
f0103291:	b8 50 37 10 f0       	mov    $0xf0103750,%eax
f0103296:	66 a3 e0 ce 17 f0    	mov    %ax,0xf017cee0
f010329c:	66 c7 05 e2 ce 17 f0 	movw   $0x8,0xf017cee2
f01032a3:	08 00 
f01032a5:	c6 05 e4 ce 17 f0 00 	movb   $0x0,0xf017cee4
f01032ac:	c6 05 e5 ce 17 f0 8e 	movb   $0x8e,0xf017cee5
f01032b3:	c1 e8 10             	shr    $0x10,%eax
f01032b6:	66 a3 e6 ce 17 f0    	mov    %ax,0xf017cee6
    SETGATE(idt[T_ALIGN], 0, GD_KT, t_align, 0);
f01032bc:	b8 56 37 10 f0       	mov    $0xf0103756,%eax
f01032c1:	66 a3 e8 ce 17 f0    	mov    %ax,0xf017cee8
f01032c7:	66 c7 05 ea ce 17 f0 	movw   $0x8,0xf017ceea
f01032ce:	08 00 
f01032d0:	c6 05 ec ce 17 f0 00 	movb   $0x0,0xf017ceec
f01032d7:	c6 05 ed ce 17 f0 8e 	movb   $0x8e,0xf017ceed
f01032de:	c1 e8 10             	shr    $0x10,%eax
f01032e1:	66 a3 ee ce 17 f0    	mov    %ax,0xf017ceee
    SETGATE(idt[T_MCHK], 0, GD_KT, t_mchk, 0);
f01032e7:	b8 5a 37 10 f0       	mov    $0xf010375a,%eax
f01032ec:	66 a3 f0 ce 17 f0    	mov    %ax,0xf017cef0
f01032f2:	66 c7 05 f2 ce 17 f0 	movw   $0x8,0xf017cef2
f01032f9:	08 00 
f01032fb:	c6 05 f4 ce 17 f0 00 	movb   $0x0,0xf017cef4
f0103302:	c6 05 f5 ce 17 f0 8e 	movb   $0x8e,0xf017cef5
f0103309:	c1 e8 10             	shr    $0x10,%eax
f010330c:	66 a3 f6 ce 17 f0    	mov    %ax,0xf017cef6
    SETGATE(idt[T_SIMDERR], 0, GD_KT, t_simderr, 0);
f0103312:	b8 60 37 10 f0       	mov    $0xf0103760,%eax
f0103317:	66 a3 f8 ce 17 f0    	mov    %ax,0xf017cef8
f010331d:	66 c7 05 fa ce 17 f0 	movw   $0x8,0xf017cefa
f0103324:	08 00 
f0103326:	c6 05 fc ce 17 f0 00 	movb   $0x0,0xf017cefc
f010332d:	c6 05 fd ce 17 f0 8e 	movb   $0x8e,0xf017cefd
f0103334:	c1 e8 10             	shr    $0x10,%eax
f0103337:	66 a3 fe ce 17 f0    	mov    %ax,0xf017cefe
    SETGATE(idt[T_SYSCALL], 0, GD_KT, t_syscall, 3);
f010333d:	b8 66 37 10 f0       	mov    $0xf0103766,%eax
f0103342:	66 a3 e0 cf 17 f0    	mov    %ax,0xf017cfe0
f0103348:	66 c7 05 e2 cf 17 f0 	movw   $0x8,0xf017cfe2
f010334f:	08 00 
f0103351:	c6 05 e4 cf 17 f0 00 	movb   $0x0,0xf017cfe4
f0103358:	c6 05 e5 cf 17 f0 ee 	movb   $0xee,0xf017cfe5
f010335f:	c1 e8 10             	shr    $0x10,%eax
f0103362:	66 a3 e6 cf 17 f0    	mov    %ax,0xf017cfe6
	// Per-CPU setup 
	trap_init_percpu();
f0103368:	e8 6a fc ff ff       	call   f0102fd7 <trap_init_percpu>
}
f010336d:	5d                   	pop    %ebp
f010336e:	c3                   	ret    

f010336f <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f010336f:	55                   	push   %ebp
f0103370:	89 e5                	mov    %esp,%ebp
f0103372:	53                   	push   %ebx
f0103373:	83 ec 0c             	sub    $0xc,%esp
f0103376:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0103379:	ff 33                	pushl  (%ebx)
f010337b:	68 12 59 10 f0       	push   $0xf0105912
f0103380:	e8 3e fc ff ff       	call   f0102fc3 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0103385:	83 c4 08             	add    $0x8,%esp
f0103388:	ff 73 04             	pushl  0x4(%ebx)
f010338b:	68 21 59 10 f0       	push   $0xf0105921
f0103390:	e8 2e fc ff ff       	call   f0102fc3 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103395:	83 c4 08             	add    $0x8,%esp
f0103398:	ff 73 08             	pushl  0x8(%ebx)
f010339b:	68 30 59 10 f0       	push   $0xf0105930
f01033a0:	e8 1e fc ff ff       	call   f0102fc3 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f01033a5:	83 c4 08             	add    $0x8,%esp
f01033a8:	ff 73 0c             	pushl  0xc(%ebx)
f01033ab:	68 3f 59 10 f0       	push   $0xf010593f
f01033b0:	e8 0e fc ff ff       	call   f0102fc3 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f01033b5:	83 c4 08             	add    $0x8,%esp
f01033b8:	ff 73 10             	pushl  0x10(%ebx)
f01033bb:	68 4e 59 10 f0       	push   $0xf010594e
f01033c0:	e8 fe fb ff ff       	call   f0102fc3 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f01033c5:	83 c4 08             	add    $0x8,%esp
f01033c8:	ff 73 14             	pushl  0x14(%ebx)
f01033cb:	68 5d 59 10 f0       	push   $0xf010595d
f01033d0:	e8 ee fb ff ff       	call   f0102fc3 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f01033d5:	83 c4 08             	add    $0x8,%esp
f01033d8:	ff 73 18             	pushl  0x18(%ebx)
f01033db:	68 6c 59 10 f0       	push   $0xf010596c
f01033e0:	e8 de fb ff ff       	call   f0102fc3 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f01033e5:	83 c4 08             	add    $0x8,%esp
f01033e8:	ff 73 1c             	pushl  0x1c(%ebx)
f01033eb:	68 7b 59 10 f0       	push   $0xf010597b
f01033f0:	e8 ce fb ff ff       	call   f0102fc3 <cprintf>
}
f01033f5:	83 c4 10             	add    $0x10,%esp
f01033f8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01033fb:	c9                   	leave  
f01033fc:	c3                   	ret    

f01033fd <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f01033fd:	55                   	push   %ebp
f01033fe:	89 e5                	mov    %esp,%ebp
f0103400:	56                   	push   %esi
f0103401:	53                   	push   %ebx
f0103402:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f0103405:	83 ec 08             	sub    $0x8,%esp
f0103408:	53                   	push   %ebx
f0103409:	68 cf 5a 10 f0       	push   $0xf0105acf
f010340e:	e8 b0 fb ff ff       	call   f0102fc3 <cprintf>
	print_regs(&tf->tf_regs);
f0103413:	89 1c 24             	mov    %ebx,(%esp)
f0103416:	e8 54 ff ff ff       	call   f010336f <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f010341b:	83 c4 08             	add    $0x8,%esp
f010341e:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103422:	50                   	push   %eax
f0103423:	68 cc 59 10 f0       	push   $0xf01059cc
f0103428:	e8 96 fb ff ff       	call   f0102fc3 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f010342d:	83 c4 08             	add    $0x8,%esp
f0103430:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103434:	50                   	push   %eax
f0103435:	68 df 59 10 f0       	push   $0xf01059df
f010343a:	e8 84 fb ff ff       	call   f0102fc3 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f010343f:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f0103442:	83 c4 10             	add    $0x10,%esp
f0103445:	83 f8 13             	cmp    $0x13,%eax
f0103448:	77 09                	ja     f0103453 <print_trapframe+0x56>
		return excnames[trapno];
f010344a:	8b 14 85 a0 5c 10 f0 	mov    -0xfefa360(,%eax,4),%edx
f0103451:	eb 10                	jmp    f0103463 <print_trapframe+0x66>
	if (trapno == T_SYSCALL)
		return "System call";
	return "(unknown trap)";
f0103453:	83 f8 30             	cmp    $0x30,%eax
f0103456:	b9 96 59 10 f0       	mov    $0xf0105996,%ecx
f010345b:	ba 8a 59 10 f0       	mov    $0xf010598a,%edx
f0103460:	0f 45 d1             	cmovne %ecx,%edx
{
	cprintf("TRAP frame at %p\n", tf);
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103463:	83 ec 04             	sub    $0x4,%esp
f0103466:	52                   	push   %edx
f0103467:	50                   	push   %eax
f0103468:	68 f2 59 10 f0       	push   $0xf01059f2
f010346d:	e8 51 fb ff ff       	call   f0102fc3 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103472:	83 c4 10             	add    $0x10,%esp
f0103475:	3b 1d 60 d6 17 f0    	cmp    0xf017d660,%ebx
f010347b:	75 1a                	jne    f0103497 <print_trapframe+0x9a>
f010347d:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103481:	75 14                	jne    f0103497 <print_trapframe+0x9a>

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0103483:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103486:	83 ec 08             	sub    $0x8,%esp
f0103489:	50                   	push   %eax
f010348a:	68 04 5a 10 f0       	push   $0xf0105a04
f010348f:	e8 2f fb ff ff       	call   f0102fc3 <cprintf>
f0103494:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f0103497:	83 ec 08             	sub    $0x8,%esp
f010349a:	ff 73 2c             	pushl  0x2c(%ebx)
f010349d:	68 13 5a 10 f0       	push   $0xf0105a13
f01034a2:	e8 1c fb ff ff       	call   f0102fc3 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f01034a7:	83 c4 10             	add    $0x10,%esp
f01034aa:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f01034ae:	75 49                	jne    f01034f9 <print_trapframe+0xfc>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f01034b0:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f01034b3:	89 c2                	mov    %eax,%edx
f01034b5:	83 e2 01             	and    $0x1,%edx
f01034b8:	ba b0 59 10 f0       	mov    $0xf01059b0,%edx
f01034bd:	b9 a5 59 10 f0       	mov    $0xf01059a5,%ecx
f01034c2:	0f 44 ca             	cmove  %edx,%ecx
f01034c5:	89 c2                	mov    %eax,%edx
f01034c7:	83 e2 02             	and    $0x2,%edx
f01034ca:	ba c2 59 10 f0       	mov    $0xf01059c2,%edx
f01034cf:	be bc 59 10 f0       	mov    $0xf01059bc,%esi
f01034d4:	0f 45 d6             	cmovne %esi,%edx
f01034d7:	83 e0 04             	and    $0x4,%eax
f01034da:	be 9a 5a 10 f0       	mov    $0xf0105a9a,%esi
f01034df:	b8 c7 59 10 f0       	mov    $0xf01059c7,%eax
f01034e4:	0f 44 c6             	cmove  %esi,%eax
f01034e7:	51                   	push   %ecx
f01034e8:	52                   	push   %edx
f01034e9:	50                   	push   %eax
f01034ea:	68 21 5a 10 f0       	push   $0xf0105a21
f01034ef:	e8 cf fa ff ff       	call   f0102fc3 <cprintf>
f01034f4:	83 c4 10             	add    $0x10,%esp
f01034f7:	eb 10                	jmp    f0103509 <print_trapframe+0x10c>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f01034f9:	83 ec 0c             	sub    $0xc,%esp
f01034fc:	68 47 50 10 f0       	push   $0xf0105047
f0103501:	e8 bd fa ff ff       	call   f0102fc3 <cprintf>
f0103506:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103509:	83 ec 08             	sub    $0x8,%esp
f010350c:	ff 73 30             	pushl  0x30(%ebx)
f010350f:	68 30 5a 10 f0       	push   $0xf0105a30
f0103514:	e8 aa fa ff ff       	call   f0102fc3 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103519:	83 c4 08             	add    $0x8,%esp
f010351c:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103520:	50                   	push   %eax
f0103521:	68 3f 5a 10 f0       	push   $0xf0105a3f
f0103526:	e8 98 fa ff ff       	call   f0102fc3 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f010352b:	83 c4 08             	add    $0x8,%esp
f010352e:	ff 73 38             	pushl  0x38(%ebx)
f0103531:	68 52 5a 10 f0       	push   $0xf0105a52
f0103536:	e8 88 fa ff ff       	call   f0102fc3 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f010353b:	83 c4 10             	add    $0x10,%esp
f010353e:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103542:	74 25                	je     f0103569 <print_trapframe+0x16c>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103544:	83 ec 08             	sub    $0x8,%esp
f0103547:	ff 73 3c             	pushl  0x3c(%ebx)
f010354a:	68 61 5a 10 f0       	push   $0xf0105a61
f010354f:	e8 6f fa ff ff       	call   f0102fc3 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103554:	83 c4 08             	add    $0x8,%esp
f0103557:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f010355b:	50                   	push   %eax
f010355c:	68 70 5a 10 f0       	push   $0xf0105a70
f0103561:	e8 5d fa ff ff       	call   f0102fc3 <cprintf>
f0103566:	83 c4 10             	add    $0x10,%esp
	}
}
f0103569:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010356c:	5b                   	pop    %ebx
f010356d:	5e                   	pop    %esi
f010356e:	5d                   	pop    %ebp
f010356f:	c3                   	ret    

f0103570 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103570:	55                   	push   %ebp
f0103571:	89 e5                	mov    %esp,%ebp
f0103573:	53                   	push   %ebx
f0103574:	83 ec 04             	sub    $0x4,%esp
f0103577:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010357a:	0f 20 d0             	mov    %cr2,%eax
	fault_va = rcr2();

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
	if((tf->tf_cs & 3) == 0)
f010357d:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103581:	75 17                	jne    f010359a <page_fault_handler+0x2a>
	{
		panic("page fault happened in kernel");
f0103583:	83 ec 04             	sub    $0x4,%esp
f0103586:	68 83 5a 10 f0       	push   $0xf0105a83
f010358b:	68 0a 01 00 00       	push   $0x10a
f0103590:	68 a1 5a 10 f0       	push   $0xf0105aa1
f0103595:	e8 06 cb ff ff       	call   f01000a0 <_panic>
	}
	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f010359a:	ff 73 30             	pushl  0x30(%ebx)
f010359d:	50                   	push   %eax
f010359e:	a1 48 ce 17 f0       	mov    0xf017ce48,%eax
f01035a3:	ff 70 48             	pushl  0x48(%eax)
f01035a6:	68 44 5c 10 f0       	push   $0xf0105c44
f01035ab:	e8 13 fa ff ff       	call   f0102fc3 <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f01035b0:	89 1c 24             	mov    %ebx,(%esp)
f01035b3:	e8 45 fe ff ff       	call   f01033fd <print_trapframe>
	env_destroy(curenv);
f01035b8:	83 c4 04             	add    $0x4,%esp
f01035bb:	ff 35 48 ce 17 f0    	pushl  0xf017ce48
f01035c1:	e8 ea f8 ff ff       	call   f0102eb0 <env_destroy>
}
f01035c6:	83 c4 10             	add    $0x10,%esp
f01035c9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01035cc:	c9                   	leave  
f01035cd:	c3                   	ret    

f01035ce <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f01035ce:	55                   	push   %ebp
f01035cf:	89 e5                	mov    %esp,%ebp
f01035d1:	57                   	push   %edi
f01035d2:	56                   	push   %esi
f01035d3:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f01035d6:	fc                   	cld    

static __inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	__asm __volatile("pushfl; popl %0" : "=r" (eflags));
f01035d7:	9c                   	pushf  
f01035d8:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f01035d9:	f6 c4 02             	test   $0x2,%ah
f01035dc:	74 19                	je     f01035f7 <trap+0x29>
f01035de:	68 ad 5a 10 f0       	push   $0xf0105aad
f01035e3:	68 98 4d 10 f0       	push   $0xf0104d98
f01035e8:	68 e0 00 00 00       	push   $0xe0
f01035ed:	68 a1 5a 10 f0       	push   $0xf0105aa1
f01035f2:	e8 a9 ca ff ff       	call   f01000a0 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f01035f7:	83 ec 08             	sub    $0x8,%esp
f01035fa:	56                   	push   %esi
f01035fb:	68 c6 5a 10 f0       	push   $0xf0105ac6
f0103600:	e8 be f9 ff ff       	call   f0102fc3 <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f0103605:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103609:	83 e0 03             	and    $0x3,%eax
f010360c:	83 c4 10             	add    $0x10,%esp
f010360f:	66 83 f8 03          	cmp    $0x3,%ax
f0103613:	75 31                	jne    f0103646 <trap+0x78>
		// Trapped from user mode.
		assert(curenv);
f0103615:	a1 48 ce 17 f0       	mov    0xf017ce48,%eax
f010361a:	85 c0                	test   %eax,%eax
f010361c:	75 19                	jne    f0103637 <trap+0x69>
f010361e:	68 e1 5a 10 f0       	push   $0xf0105ae1
f0103623:	68 98 4d 10 f0       	push   $0xf0104d98
f0103628:	68 e6 00 00 00       	push   $0xe6
f010362d:	68 a1 5a 10 f0       	push   $0xf0105aa1
f0103632:	e8 69 ca ff ff       	call   f01000a0 <_panic>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103637:	b9 11 00 00 00       	mov    $0x11,%ecx
f010363c:	89 c7                	mov    %eax,%edi
f010363e:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103640:	8b 35 48 ce 17 f0    	mov    0xf017ce48,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103646:	89 35 60 d6 17 f0    	mov    %esi,0xf017d660
static void
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	if (tf->tf_trapno == T_PGFLT) 
f010364c:	8b 46 28             	mov    0x28(%esi),%eax
f010364f:	83 f8 0e             	cmp    $0xe,%eax
f0103652:	75 0e                	jne    f0103662 <trap+0x94>
	{ 
        page_fault_handler(tf);
f0103654:	83 ec 0c             	sub    $0xc,%esp
f0103657:	56                   	push   %esi
f0103658:	e8 13 ff ff ff       	call   f0103570 <page_fault_handler>
f010365d:	83 c4 10             	add    $0x10,%esp
f0103660:	eb 74                	jmp    f01036d6 <trap+0x108>
        return;
   	 }
	if (tf->tf_trapno == T_BRKPT) 
f0103662:	83 f8 03             	cmp    $0x3,%eax
f0103665:	75 0e                	jne    f0103675 <trap+0xa7>
	{ 	
        	monitor(tf);
f0103667:	83 ec 0c             	sub    $0xc,%esp
f010366a:	56                   	push   %esi
f010366b:	e8 43 d1 ff ff       	call   f01007b3 <monitor>
f0103670:	83 c4 10             	add    $0x10,%esp
f0103673:	eb 61                	jmp    f01036d6 <trap+0x108>
        	return;
    	}
	if(tf->tf_trapno == T_SYSCALL)
f0103675:	83 f8 30             	cmp    $0x30,%eax
f0103678:	75 21                	jne    f010369b <trap+0xcd>
	{   
	tf->tf_regs.reg_eax = syscall(
f010367a:	83 ec 08             	sub    $0x8,%esp
f010367d:	ff 76 04             	pushl  0x4(%esi)
f0103680:	ff 36                	pushl  (%esi)
f0103682:	ff 76 10             	pushl  0x10(%esi)
f0103685:	ff 76 18             	pushl  0x18(%esi)
f0103688:	ff 76 14             	pushl  0x14(%esi)
f010368b:	ff 76 1c             	pushl  0x1c(%esi)
f010368e:	e8 e8 00 00 00       	call   f010377b <syscall>
f0103693:	89 46 1c             	mov    %eax,0x1c(%esi)
f0103696:	83 c4 20             	add    $0x20,%esp
f0103699:	eb 3b                	jmp    f01036d6 <trap+0x108>
        tf->tf_regs.reg_edi,
        tf->tf_regs.reg_esi);
		return;
	}
	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f010369b:	83 ec 0c             	sub    $0xc,%esp
f010369e:	56                   	push   %esi
f010369f:	e8 59 fd ff ff       	call   f01033fd <print_trapframe>
	if (tf->tf_cs == GD_KT)
f01036a4:	83 c4 10             	add    $0x10,%esp
f01036a7:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f01036ac:	75 17                	jne    f01036c5 <trap+0xf7>
		panic("unhandled trap in kernel");
f01036ae:	83 ec 04             	sub    $0x4,%esp
f01036b1:	68 e8 5a 10 f0       	push   $0xf0105ae8
f01036b6:	68 cf 00 00 00       	push   $0xcf
f01036bb:	68 a1 5a 10 f0       	push   $0xf0105aa1
f01036c0:	e8 db c9 ff ff       	call   f01000a0 <_panic>
	else {
		env_destroy(curenv);
f01036c5:	83 ec 0c             	sub    $0xc,%esp
f01036c8:	ff 35 48 ce 17 f0    	pushl  0xf017ce48
f01036ce:	e8 dd f7 ff ff       	call   f0102eb0 <env_destroy>
f01036d3:	83 c4 10             	add    $0x10,%esp

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f01036d6:	a1 48 ce 17 f0       	mov    0xf017ce48,%eax
f01036db:	85 c0                	test   %eax,%eax
f01036dd:	74 06                	je     f01036e5 <trap+0x117>
f01036df:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f01036e3:	74 19                	je     f01036fe <trap+0x130>
f01036e5:	68 68 5c 10 f0       	push   $0xf0105c68
f01036ea:	68 98 4d 10 f0       	push   $0xf0104d98
f01036ef:	68 f8 00 00 00       	push   $0xf8
f01036f4:	68 a1 5a 10 f0       	push   $0xf0105aa1
f01036f9:	e8 a2 c9 ff ff       	call   f01000a0 <_panic>
	env_run(curenv);
f01036fe:	83 ec 0c             	sub    $0xc,%esp
f0103701:	50                   	push   %eax
f0103702:	e8 f9 f7 ff ff       	call   f0102f00 <env_run>
f0103707:	90                   	nop

f0103708 <t_divide>:
.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
TRAPHANDLER_NOEC(t_divide, T_DIVIDE)   // 0
f0103708:	6a 00                	push   $0x0
f010370a:	6a 00                	push   $0x0
f010370c:	eb 5e                	jmp    f010376c <_alltraps>

f010370e <t_debug>:
TRAPHANDLER_NOEC(t_debug, T_DEBUG)     // 1
f010370e:	6a 00                	push   $0x0
f0103710:	6a 01                	push   $0x1
f0103712:	eb 58                	jmp    f010376c <_alltraps>

f0103714 <t_nmi>:
TRAPHANDLER_NOEC(t_nmi, T_NMI)         // 2
f0103714:	6a 00                	push   $0x0
f0103716:	6a 02                	push   $0x2
f0103718:	eb 52                	jmp    f010376c <_alltraps>

f010371a <t_brkpt>:
TRAPHANDLER_NOEC(t_brkpt, T_BRKPT)     // 3
f010371a:	6a 00                	push   $0x0
f010371c:	6a 03                	push   $0x3
f010371e:	eb 4c                	jmp    f010376c <_alltraps>

f0103720 <t_oflow>:
TRAPHANDLER_NOEC(t_oflow, T_OFLOW)     // 4
f0103720:	6a 00                	push   $0x0
f0103722:	6a 04                	push   $0x4
f0103724:	eb 46                	jmp    f010376c <_alltraps>

f0103726 <t_bound>:
TRAPHANDLER_NOEC(t_bound, T_BOUND)     // 5
f0103726:	6a 00                	push   $0x0
f0103728:	6a 05                	push   $0x5
f010372a:	eb 40                	jmp    f010376c <_alltraps>

f010372c <t_illop>:
TRAPHANDLER_NOEC(t_illop, T_ILLOP)     // 6
f010372c:	6a 00                	push   $0x0
f010372e:	6a 06                	push   $0x6
f0103730:	eb 3a                	jmp    f010376c <_alltraps>

f0103732 <t_device>:
TRAPHANDLER_NOEC(t_device, T_DEVICE)   // 7
f0103732:	6a 00                	push   $0x0
f0103734:	6a 07                	push   $0x7
f0103736:	eb 34                	jmp    f010376c <_alltraps>

f0103738 <t_dblflt>:
TRAPHANDLER(t_dblflt, T_DBLFLT)        // 8
f0103738:	6a 08                	push   $0x8
f010373a:	eb 30                	jmp    f010376c <_alltraps>

f010373c <t_tss>:
                                       // 9
TRAPHANDLER(t_tss, T_TSS)              // 10
f010373c:	6a 0a                	push   $0xa
f010373e:	eb 2c                	jmp    f010376c <_alltraps>

f0103740 <t_segnp>:
TRAPHANDLER(t_segnp, T_SEGNP)          // 11
f0103740:	6a 0b                	push   $0xb
f0103742:	eb 28                	jmp    f010376c <_alltraps>

f0103744 <t_stack>:
TRAPHANDLER(t_stack, T_STACK)          // 12
f0103744:	6a 0c                	push   $0xc
f0103746:	eb 24                	jmp    f010376c <_alltraps>

f0103748 <t_gpflt>:
TRAPHANDLER(t_gpflt, T_GPFLT)          // 13
f0103748:	6a 0d                	push   $0xd
f010374a:	eb 20                	jmp    f010376c <_alltraps>

f010374c <t_pgflt>:
TRAPHANDLER(t_pgflt, T_PGFLT)          // 14
f010374c:	6a 0e                	push   $0xe
f010374e:	eb 1c                	jmp    f010376c <_alltraps>

f0103750 <t_fperr>:
                                       // 15
TRAPHANDLER_NOEC(t_fperr, T_FPERR)     // 16
f0103750:	6a 00                	push   $0x0
f0103752:	6a 10                	push   $0x10
f0103754:	eb 16                	jmp    f010376c <_alltraps>

f0103756 <t_align>:
TRAPHANDLER(t_align, T_ALIGN)          // 17
f0103756:	6a 11                	push   $0x11
f0103758:	eb 12                	jmp    f010376c <_alltraps>

f010375a <t_mchk>:
TRAPHANDLER_NOEC(t_mchk, T_MCHK)       // 18
f010375a:	6a 00                	push   $0x0
f010375c:	6a 12                	push   $0x12
f010375e:	eb 0c                	jmp    f010376c <_alltraps>

f0103760 <t_simderr>:
TRAPHANDLER_NOEC(t_simderr, T_SIMDERR) // 19
f0103760:	6a 00                	push   $0x0
f0103762:	6a 13                	push   $0x13
f0103764:	eb 06                	jmp    f010376c <_alltraps>

f0103766 <t_syscall>:
//...
TRAPHANDLER_NOEC(t_syscall, T_SYSCALL) // 48
f0103766:	6a 00                	push   $0x0
f0103768:	6a 30                	push   $0x30
f010376a:	eb 00                	jmp    f010376c <_alltraps>

f010376c <_alltraps>:

/*
 * Lab 3: Your code here for _alltraps
 */
_alltraps:
    pushl %ds
f010376c:	1e                   	push   %ds
    pushl %es
f010376d:	06                   	push   %es
    pushal
f010376e:	60                   	pusha  
    pushl $GD_KD
f010376f:	6a 10                	push   $0x10
    popl %ds
f0103771:	1f                   	pop    %ds
    pushl $GD_KD
f0103772:	6a 10                	push   $0x10
    popl %es
f0103774:	07                   	pop    %es
    pushl %esp 
f0103775:	54                   	push   %esp
    call trap 
f0103776:	e8 53 fe ff ff       	call   f01035ce <trap>

f010377b <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f010377b:	55                   	push   %ebp
f010377c:	89 e5                	mov    %esp,%ebp
f010377e:	83 ec 18             	sub    $0x18,%esp
f0103781:	8b 45 08             	mov    0x8(%ebp),%eax
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.
	int32_t ret = 0;
	switch (syscallno) { 
f0103784:	83 f8 01             	cmp    $0x1,%eax
f0103787:	74 4b                	je     f01037d4 <syscall+0x59>
f0103789:	83 f8 01             	cmp    $0x1,%eax
f010378c:	72 13                	jb     f01037a1 <syscall+0x26>
f010378e:	83 f8 02             	cmp    $0x2,%eax
f0103791:	0f 84 a9 00 00 00    	je     f0103840 <syscall+0xc5>
f0103797:	83 f8 03             	cmp    $0x3,%eax
f010379a:	74 3f                	je     f01037db <syscall+0x60>
f010379c:	e9 ae 00 00 00       	jmp    f010384f <syscall+0xd4>
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	user_mem_assert(curenv, s, len, PTE_U);
f01037a1:	6a 04                	push   $0x4
f01037a3:	ff 75 10             	pushl  0x10(%ebp)
f01037a6:	ff 75 0c             	pushl  0xc(%ebp)
f01037a9:	ff 35 48 ce 17 f0    	pushl  0xf017ce48
f01037af:	e8 e4 f0 ff ff       	call   f0102898 <user_mem_assert>
	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f01037b4:	83 c4 0c             	add    $0xc,%esp
f01037b7:	ff 75 0c             	pushl  0xc(%ebp)
f01037ba:	ff 75 10             	pushl  0x10(%ebp)
f01037bd:	68 f0 5c 10 f0       	push   $0xf0105cf0
f01037c2:	e8 fc f7 ff ff       	call   f0102fc3 <cprintf>
f01037c7:	83 c4 10             	add    $0x10,%esp
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.
	int32_t ret = 0;
f01037ca:	b8 00 00 00 00       	mov    $0x0,%eax
f01037cf:	e9 80 00 00 00       	jmp    f0103854 <syscall+0xd9>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f01037d4:	e8 dc cc ff ff       	call   f01004b5 <cons_getc>
		case SYS_cputs:
			sys_cputs((const char*)a1, a2);
			break;
		case SYS_cgetc:
			ret = sys_cgetc();
			break;
f01037d9:	eb 79                	jmp    f0103854 <syscall+0xd9>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f01037db:	83 ec 04             	sub    $0x4,%esp
f01037de:	6a 01                	push   $0x1
f01037e0:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01037e3:	50                   	push   %eax
f01037e4:	ff 75 0c             	pushl  0xc(%ebp)
f01037e7:	e8 7c f1 ff ff       	call   f0102968 <envid2env>
f01037ec:	83 c4 10             	add    $0x10,%esp
f01037ef:	85 c0                	test   %eax,%eax
f01037f1:	78 61                	js     f0103854 <syscall+0xd9>
		return r;
	if (e == curenv)
f01037f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01037f6:	8b 15 48 ce 17 f0    	mov    0xf017ce48,%edx
f01037fc:	39 d0                	cmp    %edx,%eax
f01037fe:	75 15                	jne    f0103815 <syscall+0x9a>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f0103800:	83 ec 08             	sub    $0x8,%esp
f0103803:	ff 70 48             	pushl  0x48(%eax)
f0103806:	68 f5 5c 10 f0       	push   $0xf0105cf5
f010380b:	e8 b3 f7 ff ff       	call   f0102fc3 <cprintf>
f0103810:	83 c4 10             	add    $0x10,%esp
f0103813:	eb 16                	jmp    f010382b <syscall+0xb0>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f0103815:	83 ec 04             	sub    $0x4,%esp
f0103818:	ff 70 48             	pushl  0x48(%eax)
f010381b:	ff 72 48             	pushl  0x48(%edx)
f010381e:	68 10 5d 10 f0       	push   $0xf0105d10
f0103823:	e8 9b f7 ff ff       	call   f0102fc3 <cprintf>
f0103828:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f010382b:	83 ec 0c             	sub    $0xc,%esp
f010382e:	ff 75 f4             	pushl  -0xc(%ebp)
f0103831:	e8 7a f6 ff ff       	call   f0102eb0 <env_destroy>
f0103836:	83 c4 10             	add    $0x10,%esp
	return 0;
f0103839:	b8 00 00 00 00       	mov    $0x0,%eax
f010383e:	eb 14                	jmp    f0103854 <syscall+0xd9>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f0103840:	a1 48 ce 17 f0       	mov    0xf017ce48,%eax
			break;
		case SYS_env_destroy:
			ret = sys_env_destroy(a1);
			break;
		case SYS_getenvid:
			ret = sys_getenvid() >= 0;
f0103845:	8b 40 48             	mov    0x48(%eax),%eax
f0103848:	f7 d0                	not    %eax
f010384a:	c1 e8 1f             	shr    $0x1f,%eax
			break;
f010384d:	eb 05                	jmp    f0103854 <syscall+0xd9>
		default:
			return -E_NO_SYS;
f010384f:	b8 f9 ff ff ff       	mov    $0xfffffff9,%eax
	}
	return ret;
	//panic("syscall not implemented");
}
f0103854:	c9                   	leave  
f0103855:	c3                   	ret    

f0103856 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0103856:	55                   	push   %ebp
f0103857:	89 e5                	mov    %esp,%ebp
f0103859:	57                   	push   %edi
f010385a:	56                   	push   %esi
f010385b:	53                   	push   %ebx
f010385c:	83 ec 14             	sub    $0x14,%esp
f010385f:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103862:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0103865:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103868:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f010386b:	8b 1a                	mov    (%edx),%ebx
f010386d:	8b 01                	mov    (%ecx),%eax
f010386f:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103872:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0103879:	eb 7f                	jmp    f01038fa <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f010387b:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010387e:	01 d8                	add    %ebx,%eax
f0103880:	89 c6                	mov    %eax,%esi
f0103882:	c1 ee 1f             	shr    $0x1f,%esi
f0103885:	01 c6                	add    %eax,%esi
f0103887:	d1 fe                	sar    %esi
f0103889:	8d 04 76             	lea    (%esi,%esi,2),%eax
f010388c:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010388f:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0103892:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103894:	eb 03                	jmp    f0103899 <stab_binsearch+0x43>
			m--;
f0103896:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103899:	39 c3                	cmp    %eax,%ebx
f010389b:	7f 0d                	jg     f01038aa <stab_binsearch+0x54>
f010389d:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01038a1:	83 ea 0c             	sub    $0xc,%edx
f01038a4:	39 f9                	cmp    %edi,%ecx
f01038a6:	75 ee                	jne    f0103896 <stab_binsearch+0x40>
f01038a8:	eb 05                	jmp    f01038af <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01038aa:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01038ad:	eb 4b                	jmp    f01038fa <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01038af:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01038b2:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01038b5:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01038b9:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01038bc:	76 11                	jbe    f01038cf <stab_binsearch+0x79>
			*region_left = m;
f01038be:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01038c1:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01038c3:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01038c6:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01038cd:	eb 2b                	jmp    f01038fa <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01038cf:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01038d2:	73 14                	jae    f01038e8 <stab_binsearch+0x92>
			*region_right = m - 1;
f01038d4:	83 e8 01             	sub    $0x1,%eax
f01038d7:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01038da:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01038dd:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01038df:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01038e6:	eb 12                	jmp    f01038fa <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01038e8:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01038eb:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01038ed:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01038f1:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01038f3:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01038fa:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01038fd:	0f 8e 78 ff ff ff    	jle    f010387b <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0103903:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0103907:	75 0f                	jne    f0103918 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0103909:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010390c:	8b 00                	mov    (%eax),%eax
f010390e:	83 e8 01             	sub    $0x1,%eax
f0103911:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103914:	89 06                	mov    %eax,(%esi)
f0103916:	eb 2c                	jmp    f0103944 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103918:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010391b:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f010391d:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103920:	8b 0e                	mov    (%esi),%ecx
f0103922:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103925:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0103928:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010392b:	eb 03                	jmp    f0103930 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f010392d:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103930:	39 c8                	cmp    %ecx,%eax
f0103932:	7e 0b                	jle    f010393f <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0103934:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0103938:	83 ea 0c             	sub    $0xc,%edx
f010393b:	39 df                	cmp    %ebx,%edi
f010393d:	75 ee                	jne    f010392d <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f010393f:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103942:	89 06                	mov    %eax,(%esi)
	}
}
f0103944:	83 c4 14             	add    $0x14,%esp
f0103947:	5b                   	pop    %ebx
f0103948:	5e                   	pop    %esi
f0103949:	5f                   	pop    %edi
f010394a:	5d                   	pop    %ebp
f010394b:	c3                   	ret    

f010394c <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f010394c:	55                   	push   %ebp
f010394d:	89 e5                	mov    %esp,%ebp
f010394f:	57                   	push   %edi
f0103950:	56                   	push   %esi
f0103951:	53                   	push   %ebx
f0103952:	83 ec 2c             	sub    $0x2c,%esp
f0103955:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103958:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f010395b:	c7 06 28 5d 10 f0    	movl   $0xf0105d28,(%esi)
	info->eip_line = 0;
f0103961:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0103968:	c7 46 08 28 5d 10 f0 	movl   $0xf0105d28,0x8(%esi)
	info->eip_fn_namelen = 9;
f010396f:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0103976:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0103979:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0103980:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0103986:	0f 87 8a 00 00 00    	ja     f0103a16 <debuginfo_eip+0xca>
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (void *)usd, sizeof(struct UserStabData), PTE_U) != 0) 
f010398c:	6a 04                	push   $0x4
f010398e:	6a 10                	push   $0x10
f0103990:	68 00 00 20 00       	push   $0x200000
f0103995:	ff 35 48 ce 17 f0    	pushl  0xf017ce48
f010399b:	e8 6a ee ff ff       	call   f010280a <user_mem_check>
f01039a0:	83 c4 10             	add    $0x10,%esp
f01039a3:	85 c0                	test   %eax,%eax
f01039a5:	0f 85 c3 01 00 00    	jne    f0103b6e <debuginfo_eip+0x222>
		{
           		return -1;
        	}
		stabs = usd->stabs;
f01039ab:	a1 00 00 20 00       	mov    0x200000,%eax
f01039b0:	89 c1                	mov    %eax,%ecx
f01039b2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		stab_end = usd->stab_end;
f01039b5:	8b 1d 04 00 20 00    	mov    0x200004,%ebx
		stabstr = usd->stabstr;
f01039bb:	a1 08 00 20 00       	mov    0x200008,%eax
f01039c0:	89 45 cc             	mov    %eax,-0x34(%ebp)
		stabstr_end = usd->stabstr_end;
f01039c3:	8b 15 0c 00 20 00    	mov    0x20000c,%edx
f01039c9:	89 55 d0             	mov    %edx,-0x30(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (void *)stabs,stab_end - stabs, PTE_U) != 0) 
f01039cc:	6a 04                	push   $0x4
f01039ce:	89 d8                	mov    %ebx,%eax
f01039d0:	29 c8                	sub    %ecx,%eax
f01039d2:	c1 f8 02             	sar    $0x2,%eax
f01039d5:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f01039db:	50                   	push   %eax
f01039dc:	51                   	push   %ecx
f01039dd:	ff 35 48 ce 17 f0    	pushl  0xf017ce48
f01039e3:	e8 22 ee ff ff       	call   f010280a <user_mem_check>
f01039e8:	83 c4 10             	add    $0x10,%esp
f01039eb:	85 c0                	test   %eax,%eax
f01039ed:	0f 85 82 01 00 00    	jne    f0103b75 <debuginfo_eip+0x229>
		{
            		return -1;
        	}
		if (user_mem_check(curenv, (void *)stabstr, stabstr_end - stabstr, PTE_U) != 0) 
f01039f3:	6a 04                	push   $0x4
f01039f5:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01039f8:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f01039fb:	29 ca                	sub    %ecx,%edx
f01039fd:	52                   	push   %edx
f01039fe:	51                   	push   %ecx
f01039ff:	ff 35 48 ce 17 f0    	pushl  0xf017ce48
f0103a05:	e8 00 ee ff ff       	call   f010280a <user_mem_check>
f0103a0a:	83 c4 10             	add    $0x10,%esp
f0103a0d:	85 c0                	test   %eax,%eax
f0103a0f:	74 1f                	je     f0103a30 <debuginfo_eip+0xe4>
f0103a11:	e9 66 01 00 00       	jmp    f0103b7c <debuginfo_eip+0x230>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0103a16:	c7 45 d0 e9 02 11 f0 	movl   $0xf01102e9,-0x30(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0103a1d:	c7 45 cc b9 d8 10 f0 	movl   $0xf010d8b9,-0x34(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0103a24:	bb b8 d8 10 f0       	mov    $0xf010d8b8,%ebx
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0103a29:	c7 45 d4 50 5f 10 f0 	movl   $0xf0105f50,-0x2c(%ebp)
            		return -1;
        	}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103a30:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103a33:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0103a36:	0f 83 47 01 00 00    	jae    f0103b83 <debuginfo_eip+0x237>
f0103a3c:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0103a40:	0f 85 44 01 00 00    	jne    f0103b8a <debuginfo_eip+0x23e>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103a46:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0103a4d:	2b 5d d4             	sub    -0x2c(%ebp),%ebx
f0103a50:	c1 fb 02             	sar    $0x2,%ebx
f0103a53:	69 c3 ab aa aa aa    	imul   $0xaaaaaaab,%ebx,%eax
f0103a59:	83 e8 01             	sub    $0x1,%eax
f0103a5c:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0103a5f:	83 ec 08             	sub    $0x8,%esp
f0103a62:	57                   	push   %edi
f0103a63:	6a 64                	push   $0x64
f0103a65:	8d 55 e0             	lea    -0x20(%ebp),%edx
f0103a68:	89 d1                	mov    %edx,%ecx
f0103a6a:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0103a6d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103a70:	89 d8                	mov    %ebx,%eax
f0103a72:	e8 df fd ff ff       	call   f0103856 <stab_binsearch>
	if (lfile == 0)
f0103a77:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103a7a:	83 c4 10             	add    $0x10,%esp
f0103a7d:	85 c0                	test   %eax,%eax
f0103a7f:	0f 84 0c 01 00 00    	je     f0103b91 <debuginfo_eip+0x245>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0103a85:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0103a88:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103a8b:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0103a8e:	83 ec 08             	sub    $0x8,%esp
f0103a91:	57                   	push   %edi
f0103a92:	6a 24                	push   $0x24
f0103a94:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0103a97:	89 d1                	mov    %edx,%ecx
f0103a99:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0103a9c:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
f0103a9f:	89 d8                	mov    %ebx,%eax
f0103aa1:	e8 b0 fd ff ff       	call   f0103856 <stab_binsearch>

	if (lfun <= rfun) {
f0103aa6:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0103aa9:	83 c4 10             	add    $0x10,%esp
f0103aac:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f0103aaf:	7f 24                	jg     f0103ad5 <debuginfo_eip+0x189>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103ab1:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0103ab4:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103ab7:	8d 14 87             	lea    (%edi,%eax,4),%edx
f0103aba:	8b 02                	mov    (%edx),%eax
f0103abc:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0103abf:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0103ac2:	29 f9                	sub    %edi,%ecx
f0103ac4:	39 c8                	cmp    %ecx,%eax
f0103ac6:	73 05                	jae    f0103acd <debuginfo_eip+0x181>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0103ac8:	01 f8                	add    %edi,%eax
f0103aca:	89 46 08             	mov    %eax,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0103acd:	8b 42 08             	mov    0x8(%edx),%eax
f0103ad0:	89 46 10             	mov    %eax,0x10(%esi)
f0103ad3:	eb 06                	jmp    f0103adb <debuginfo_eip+0x18f>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0103ad5:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0103ad8:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103adb:	83 ec 08             	sub    $0x8,%esp
f0103ade:	6a 3a                	push   $0x3a
f0103ae0:	ff 76 08             	pushl  0x8(%esi)
f0103ae3:	e8 af 08 00 00       	call   f0104397 <strfind>
f0103ae8:	2b 46 08             	sub    0x8(%esi),%eax
f0103aeb:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103aee:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103af1:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0103af4:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0103af7:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f0103afa:	83 c4 10             	add    $0x10,%esp
f0103afd:	eb 06                	jmp    f0103b05 <debuginfo_eip+0x1b9>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0103aff:	83 eb 01             	sub    $0x1,%ebx
f0103b02:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103b05:	39 fb                	cmp    %edi,%ebx
f0103b07:	7c 2d                	jl     f0103b36 <debuginfo_eip+0x1ea>
	       && stabs[lline].n_type != N_SOL
f0103b09:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f0103b0d:	80 fa 84             	cmp    $0x84,%dl
f0103b10:	74 0b                	je     f0103b1d <debuginfo_eip+0x1d1>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103b12:	80 fa 64             	cmp    $0x64,%dl
f0103b15:	75 e8                	jne    f0103aff <debuginfo_eip+0x1b3>
f0103b17:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0103b1b:	74 e2                	je     f0103aff <debuginfo_eip+0x1b3>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103b1d:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0103b20:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103b23:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0103b26:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103b29:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0103b2c:	29 f8                	sub    %edi,%eax
f0103b2e:	39 c2                	cmp    %eax,%edx
f0103b30:	73 04                	jae    f0103b36 <debuginfo_eip+0x1ea>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103b32:	01 fa                	add    %edi,%edx
f0103b34:	89 16                	mov    %edx,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103b36:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0103b39:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103b3c:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103b41:	39 cb                	cmp    %ecx,%ebx
f0103b43:	7d 58                	jge    f0103b9d <debuginfo_eip+0x251>
		for (lline = lfun + 1;
f0103b45:	8d 53 01             	lea    0x1(%ebx),%edx
f0103b48:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0103b4b:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103b4e:	8d 04 87             	lea    (%edi,%eax,4),%eax
f0103b51:	eb 07                	jmp    f0103b5a <debuginfo_eip+0x20e>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0103b53:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0103b57:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0103b5a:	39 ca                	cmp    %ecx,%edx
f0103b5c:	74 3a                	je     f0103b98 <debuginfo_eip+0x24c>
f0103b5e:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103b61:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f0103b65:	74 ec                	je     f0103b53 <debuginfo_eip+0x207>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103b67:	b8 00 00 00 00       	mov    $0x0,%eax
f0103b6c:	eb 2f                	jmp    f0103b9d <debuginfo_eip+0x251>
		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (void *)usd, sizeof(struct UserStabData), PTE_U) != 0) 
		{
           		return -1;
f0103b6e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103b73:	eb 28                	jmp    f0103b9d <debuginfo_eip+0x251>

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (void *)stabs,stab_end - stabs, PTE_U) != 0) 
		{
            		return -1;
f0103b75:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103b7a:	eb 21                	jmp    f0103b9d <debuginfo_eip+0x251>
        	}
		if (user_mem_check(curenv, (void *)stabstr, stabstr_end - stabstr, PTE_U) != 0) 
		{
            		return -1;
f0103b7c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103b81:	eb 1a                	jmp    f0103b9d <debuginfo_eip+0x251>
        	}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0103b83:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103b88:	eb 13                	jmp    f0103b9d <debuginfo_eip+0x251>
f0103b8a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103b8f:	eb 0c                	jmp    f0103b9d <debuginfo_eip+0x251>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0103b91:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103b96:	eb 05                	jmp    f0103b9d <debuginfo_eip+0x251>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103b98:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103b9d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103ba0:	5b                   	pop    %ebx
f0103ba1:	5e                   	pop    %esi
f0103ba2:	5f                   	pop    %edi
f0103ba3:	5d                   	pop    %ebp
f0103ba4:	c3                   	ret    

f0103ba5 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103ba5:	55                   	push   %ebp
f0103ba6:	89 e5                	mov    %esp,%ebp
f0103ba8:	57                   	push   %edi
f0103ba9:	56                   	push   %esi
f0103baa:	53                   	push   %ebx
f0103bab:	83 ec 1c             	sub    $0x1c,%esp
f0103bae:	89 c7                	mov    %eax,%edi
f0103bb0:	89 d6                	mov    %edx,%esi
f0103bb2:	8b 45 08             	mov    0x8(%ebp),%eax
f0103bb5:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103bb8:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103bbb:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103bbe:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103bc1:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103bc6:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103bc9:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0103bcc:	39 d3                	cmp    %edx,%ebx
f0103bce:	72 05                	jb     f0103bd5 <printnum+0x30>
f0103bd0:	39 45 10             	cmp    %eax,0x10(%ebp)
f0103bd3:	77 45                	ja     f0103c1a <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103bd5:	83 ec 0c             	sub    $0xc,%esp
f0103bd8:	ff 75 18             	pushl  0x18(%ebp)
f0103bdb:	8b 45 14             	mov    0x14(%ebp),%eax
f0103bde:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0103be1:	53                   	push   %ebx
f0103be2:	ff 75 10             	pushl  0x10(%ebp)
f0103be5:	83 ec 08             	sub    $0x8,%esp
f0103be8:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103beb:	ff 75 e0             	pushl  -0x20(%ebp)
f0103bee:	ff 75 dc             	pushl  -0x24(%ebp)
f0103bf1:	ff 75 d8             	pushl  -0x28(%ebp)
f0103bf4:	e8 c7 09 00 00       	call   f01045c0 <__udivdi3>
f0103bf9:	83 c4 18             	add    $0x18,%esp
f0103bfc:	52                   	push   %edx
f0103bfd:	50                   	push   %eax
f0103bfe:	89 f2                	mov    %esi,%edx
f0103c00:	89 f8                	mov    %edi,%eax
f0103c02:	e8 9e ff ff ff       	call   f0103ba5 <printnum>
f0103c07:	83 c4 20             	add    $0x20,%esp
f0103c0a:	eb 18                	jmp    f0103c24 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103c0c:	83 ec 08             	sub    $0x8,%esp
f0103c0f:	56                   	push   %esi
f0103c10:	ff 75 18             	pushl  0x18(%ebp)
f0103c13:	ff d7                	call   *%edi
f0103c15:	83 c4 10             	add    $0x10,%esp
f0103c18:	eb 03                	jmp    f0103c1d <printnum+0x78>
f0103c1a:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103c1d:	83 eb 01             	sub    $0x1,%ebx
f0103c20:	85 db                	test   %ebx,%ebx
f0103c22:	7f e8                	jg     f0103c0c <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103c24:	83 ec 08             	sub    $0x8,%esp
f0103c27:	56                   	push   %esi
f0103c28:	83 ec 04             	sub    $0x4,%esp
f0103c2b:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103c2e:	ff 75 e0             	pushl  -0x20(%ebp)
f0103c31:	ff 75 dc             	pushl  -0x24(%ebp)
f0103c34:	ff 75 d8             	pushl  -0x28(%ebp)
f0103c37:	e8 b4 0a 00 00       	call   f01046f0 <__umoddi3>
f0103c3c:	83 c4 14             	add    $0x14,%esp
f0103c3f:	0f be 80 32 5d 10 f0 	movsbl -0xfefa2ce(%eax),%eax
f0103c46:	50                   	push   %eax
f0103c47:	ff d7                	call   *%edi
}
f0103c49:	83 c4 10             	add    $0x10,%esp
f0103c4c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103c4f:	5b                   	pop    %ebx
f0103c50:	5e                   	pop    %esi
f0103c51:	5f                   	pop    %edi
f0103c52:	5d                   	pop    %ebp
f0103c53:	c3                   	ret    

f0103c54 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103c54:	55                   	push   %ebp
f0103c55:	89 e5                	mov    %esp,%ebp
f0103c57:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103c5a:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103c5e:	8b 10                	mov    (%eax),%edx
f0103c60:	3b 50 04             	cmp    0x4(%eax),%edx
f0103c63:	73 0a                	jae    f0103c6f <sprintputch+0x1b>
		*b->buf++ = ch;
f0103c65:	8d 4a 01             	lea    0x1(%edx),%ecx
f0103c68:	89 08                	mov    %ecx,(%eax)
f0103c6a:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c6d:	88 02                	mov    %al,(%edx)
}
f0103c6f:	5d                   	pop    %ebp
f0103c70:	c3                   	ret    

f0103c71 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103c71:	55                   	push   %ebp
f0103c72:	89 e5                	mov    %esp,%ebp
f0103c74:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0103c77:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103c7a:	50                   	push   %eax
f0103c7b:	ff 75 10             	pushl  0x10(%ebp)
f0103c7e:	ff 75 0c             	pushl  0xc(%ebp)
f0103c81:	ff 75 08             	pushl  0x8(%ebp)
f0103c84:	e8 05 00 00 00       	call   f0103c8e <vprintfmt>
	va_end(ap);
}
f0103c89:	83 c4 10             	add    $0x10,%esp
f0103c8c:	c9                   	leave  
f0103c8d:	c3                   	ret    

f0103c8e <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0103c8e:	55                   	push   %ebp
f0103c8f:	89 e5                	mov    %esp,%ebp
f0103c91:	57                   	push   %edi
f0103c92:	56                   	push   %esi
f0103c93:	53                   	push   %ebx
f0103c94:	83 ec 2c             	sub    $0x2c,%esp
f0103c97:	8b 75 08             	mov    0x8(%ebp),%esi
f0103c9a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103c9d:	8b 7d 10             	mov    0x10(%ebp),%edi
f0103ca0:	eb 12                	jmp    f0103cb4 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0103ca2:	85 c0                	test   %eax,%eax
f0103ca4:	0f 84 42 04 00 00    	je     f01040ec <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
f0103caa:	83 ec 08             	sub    $0x8,%esp
f0103cad:	53                   	push   %ebx
f0103cae:	50                   	push   %eax
f0103caf:	ff d6                	call   *%esi
f0103cb1:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103cb4:	83 c7 01             	add    $0x1,%edi
f0103cb7:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103cbb:	83 f8 25             	cmp    $0x25,%eax
f0103cbe:	75 e2                	jne    f0103ca2 <vprintfmt+0x14>
f0103cc0:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0103cc4:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0103ccb:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103cd2:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0103cd9:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103cde:	eb 07                	jmp    f0103ce7 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103ce0:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0103ce3:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103ce7:	8d 47 01             	lea    0x1(%edi),%eax
f0103cea:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103ced:	0f b6 07             	movzbl (%edi),%eax
f0103cf0:	0f b6 d0             	movzbl %al,%edx
f0103cf3:	83 e8 23             	sub    $0x23,%eax
f0103cf6:	3c 55                	cmp    $0x55,%al
f0103cf8:	0f 87 d3 03 00 00    	ja     f01040d1 <vprintfmt+0x443>
f0103cfe:	0f b6 c0             	movzbl %al,%eax
f0103d01:	ff 24 85 c0 5d 10 f0 	jmp    *-0xfefa240(,%eax,4)
f0103d08:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0103d0b:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0103d0f:	eb d6                	jmp    f0103ce7 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d11:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103d14:	b8 00 00 00 00       	mov    $0x0,%eax
f0103d19:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0103d1c:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0103d1f:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0103d23:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0103d26:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0103d29:	83 f9 09             	cmp    $0x9,%ecx
f0103d2c:	77 3f                	ja     f0103d6d <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0103d2e:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0103d31:	eb e9                	jmp    f0103d1c <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0103d33:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d36:	8b 00                	mov    (%eax),%eax
f0103d38:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103d3b:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d3e:	8d 40 04             	lea    0x4(%eax),%eax
f0103d41:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d44:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103d47:	eb 2a                	jmp    f0103d73 <vprintfmt+0xe5>
f0103d49:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103d4c:	85 c0                	test   %eax,%eax
f0103d4e:	ba 00 00 00 00       	mov    $0x0,%edx
f0103d53:	0f 49 d0             	cmovns %eax,%edx
f0103d56:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d59:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103d5c:	eb 89                	jmp    f0103ce7 <vprintfmt+0x59>
f0103d5e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0103d61:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0103d68:	e9 7a ff ff ff       	jmp    f0103ce7 <vprintfmt+0x59>
f0103d6d:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0103d70:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0103d73:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103d77:	0f 89 6a ff ff ff    	jns    f0103ce7 <vprintfmt+0x59>
				width = precision, precision = -1;
f0103d7d:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103d80:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103d83:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103d8a:	e9 58 ff ff ff       	jmp    f0103ce7 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103d8f:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d92:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0103d95:	e9 4d ff ff ff       	jmp    f0103ce7 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103d9a:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d9d:	8d 78 04             	lea    0x4(%eax),%edi
f0103da0:	83 ec 08             	sub    $0x8,%esp
f0103da3:	53                   	push   %ebx
f0103da4:	ff 30                	pushl  (%eax)
f0103da6:	ff d6                	call   *%esi
			break;
f0103da8:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103dab:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103dae:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0103db1:	e9 fe fe ff ff       	jmp    f0103cb4 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103db6:	8b 45 14             	mov    0x14(%ebp),%eax
f0103db9:	8d 78 04             	lea    0x4(%eax),%edi
f0103dbc:	8b 00                	mov    (%eax),%eax
f0103dbe:	99                   	cltd   
f0103dbf:	31 d0                	xor    %edx,%eax
f0103dc1:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103dc3:	83 f8 07             	cmp    $0x7,%eax
f0103dc6:	7f 0b                	jg     f0103dd3 <vprintfmt+0x145>
f0103dc8:	8b 14 85 20 5f 10 f0 	mov    -0xfefa0e0(,%eax,4),%edx
f0103dcf:	85 d2                	test   %edx,%edx
f0103dd1:	75 1b                	jne    f0103dee <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
f0103dd3:	50                   	push   %eax
f0103dd4:	68 4a 5d 10 f0       	push   $0xf0105d4a
f0103dd9:	53                   	push   %ebx
f0103dda:	56                   	push   %esi
f0103ddb:	e8 91 fe ff ff       	call   f0103c71 <printfmt>
f0103de0:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103de3:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103de6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0103de9:	e9 c6 fe ff ff       	jmp    f0103cb4 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0103dee:	52                   	push   %edx
f0103def:	68 aa 4d 10 f0       	push   $0xf0104daa
f0103df4:	53                   	push   %ebx
f0103df5:	56                   	push   %esi
f0103df6:	e8 76 fe ff ff       	call   f0103c71 <printfmt>
f0103dfb:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103dfe:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103e01:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103e04:	e9 ab fe ff ff       	jmp    f0103cb4 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103e09:	8b 45 14             	mov    0x14(%ebp),%eax
f0103e0c:	83 c0 04             	add    $0x4,%eax
f0103e0f:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0103e12:	8b 45 14             	mov    0x14(%ebp),%eax
f0103e15:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0103e17:	85 ff                	test   %edi,%edi
f0103e19:	b8 43 5d 10 f0       	mov    $0xf0105d43,%eax
f0103e1e:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0103e21:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103e25:	0f 8e 94 00 00 00    	jle    f0103ebf <vprintfmt+0x231>
f0103e2b:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0103e2f:	0f 84 98 00 00 00    	je     f0103ecd <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
f0103e35:	83 ec 08             	sub    $0x8,%esp
f0103e38:	ff 75 d0             	pushl  -0x30(%ebp)
f0103e3b:	57                   	push   %edi
f0103e3c:	e8 0c 04 00 00       	call   f010424d <strnlen>
f0103e41:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103e44:	29 c1                	sub    %eax,%ecx
f0103e46:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0103e49:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0103e4c:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0103e50:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103e53:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103e56:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103e58:	eb 0f                	jmp    f0103e69 <vprintfmt+0x1db>
					putch(padc, putdat);
f0103e5a:	83 ec 08             	sub    $0x8,%esp
f0103e5d:	53                   	push   %ebx
f0103e5e:	ff 75 e0             	pushl  -0x20(%ebp)
f0103e61:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103e63:	83 ef 01             	sub    $0x1,%edi
f0103e66:	83 c4 10             	add    $0x10,%esp
f0103e69:	85 ff                	test   %edi,%edi
f0103e6b:	7f ed                	jg     f0103e5a <vprintfmt+0x1cc>
f0103e6d:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103e70:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0103e73:	85 c9                	test   %ecx,%ecx
f0103e75:	b8 00 00 00 00       	mov    $0x0,%eax
f0103e7a:	0f 49 c1             	cmovns %ecx,%eax
f0103e7d:	29 c1                	sub    %eax,%ecx
f0103e7f:	89 75 08             	mov    %esi,0x8(%ebp)
f0103e82:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103e85:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103e88:	89 cb                	mov    %ecx,%ebx
f0103e8a:	eb 4d                	jmp    f0103ed9 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103e8c:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0103e90:	74 1b                	je     f0103ead <vprintfmt+0x21f>
f0103e92:	0f be c0             	movsbl %al,%eax
f0103e95:	83 e8 20             	sub    $0x20,%eax
f0103e98:	83 f8 5e             	cmp    $0x5e,%eax
f0103e9b:	76 10                	jbe    f0103ead <vprintfmt+0x21f>
					putch('?', putdat);
f0103e9d:	83 ec 08             	sub    $0x8,%esp
f0103ea0:	ff 75 0c             	pushl  0xc(%ebp)
f0103ea3:	6a 3f                	push   $0x3f
f0103ea5:	ff 55 08             	call   *0x8(%ebp)
f0103ea8:	83 c4 10             	add    $0x10,%esp
f0103eab:	eb 0d                	jmp    f0103eba <vprintfmt+0x22c>
				else
					putch(ch, putdat);
f0103ead:	83 ec 08             	sub    $0x8,%esp
f0103eb0:	ff 75 0c             	pushl  0xc(%ebp)
f0103eb3:	52                   	push   %edx
f0103eb4:	ff 55 08             	call   *0x8(%ebp)
f0103eb7:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103eba:	83 eb 01             	sub    $0x1,%ebx
f0103ebd:	eb 1a                	jmp    f0103ed9 <vprintfmt+0x24b>
f0103ebf:	89 75 08             	mov    %esi,0x8(%ebp)
f0103ec2:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103ec5:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103ec8:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103ecb:	eb 0c                	jmp    f0103ed9 <vprintfmt+0x24b>
f0103ecd:	89 75 08             	mov    %esi,0x8(%ebp)
f0103ed0:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103ed3:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103ed6:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103ed9:	83 c7 01             	add    $0x1,%edi
f0103edc:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103ee0:	0f be d0             	movsbl %al,%edx
f0103ee3:	85 d2                	test   %edx,%edx
f0103ee5:	74 23                	je     f0103f0a <vprintfmt+0x27c>
f0103ee7:	85 f6                	test   %esi,%esi
f0103ee9:	78 a1                	js     f0103e8c <vprintfmt+0x1fe>
f0103eeb:	83 ee 01             	sub    $0x1,%esi
f0103eee:	79 9c                	jns    f0103e8c <vprintfmt+0x1fe>
f0103ef0:	89 df                	mov    %ebx,%edi
f0103ef2:	8b 75 08             	mov    0x8(%ebp),%esi
f0103ef5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103ef8:	eb 18                	jmp    f0103f12 <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0103efa:	83 ec 08             	sub    $0x8,%esp
f0103efd:	53                   	push   %ebx
f0103efe:	6a 20                	push   $0x20
f0103f00:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103f02:	83 ef 01             	sub    $0x1,%edi
f0103f05:	83 c4 10             	add    $0x10,%esp
f0103f08:	eb 08                	jmp    f0103f12 <vprintfmt+0x284>
f0103f0a:	89 df                	mov    %ebx,%edi
f0103f0c:	8b 75 08             	mov    0x8(%ebp),%esi
f0103f0f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103f12:	85 ff                	test   %edi,%edi
f0103f14:	7f e4                	jg     f0103efa <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103f16:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0103f19:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103f1c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103f1f:	e9 90 fd ff ff       	jmp    f0103cb4 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103f24:	83 f9 01             	cmp    $0x1,%ecx
f0103f27:	7e 19                	jle    f0103f42 <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
f0103f29:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f2c:	8b 50 04             	mov    0x4(%eax),%edx
f0103f2f:	8b 00                	mov    (%eax),%eax
f0103f31:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103f34:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103f37:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f3a:	8d 40 08             	lea    0x8(%eax),%eax
f0103f3d:	89 45 14             	mov    %eax,0x14(%ebp)
f0103f40:	eb 38                	jmp    f0103f7a <vprintfmt+0x2ec>
	else if (lflag)
f0103f42:	85 c9                	test   %ecx,%ecx
f0103f44:	74 1b                	je     f0103f61 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
f0103f46:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f49:	8b 00                	mov    (%eax),%eax
f0103f4b:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103f4e:	89 c1                	mov    %eax,%ecx
f0103f50:	c1 f9 1f             	sar    $0x1f,%ecx
f0103f53:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0103f56:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f59:	8d 40 04             	lea    0x4(%eax),%eax
f0103f5c:	89 45 14             	mov    %eax,0x14(%ebp)
f0103f5f:	eb 19                	jmp    f0103f7a <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
f0103f61:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f64:	8b 00                	mov    (%eax),%eax
f0103f66:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103f69:	89 c1                	mov    %eax,%ecx
f0103f6b:	c1 f9 1f             	sar    $0x1f,%ecx
f0103f6e:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0103f71:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f74:	8d 40 04             	lea    0x4(%eax),%eax
f0103f77:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0103f7a:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103f7d:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0103f80:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103f85:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103f89:	0f 89 0e 01 00 00    	jns    f010409d <vprintfmt+0x40f>
				putch('-', putdat);
f0103f8f:	83 ec 08             	sub    $0x8,%esp
f0103f92:	53                   	push   %ebx
f0103f93:	6a 2d                	push   $0x2d
f0103f95:	ff d6                	call   *%esi
				num = -(long long) num;
f0103f97:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103f9a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0103f9d:	f7 da                	neg    %edx
f0103f9f:	83 d1 00             	adc    $0x0,%ecx
f0103fa2:	f7 d9                	neg    %ecx
f0103fa4:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0103fa7:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103fac:	e9 ec 00 00 00       	jmp    f010409d <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103fb1:	83 f9 01             	cmp    $0x1,%ecx
f0103fb4:	7e 18                	jle    f0103fce <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
f0103fb6:	8b 45 14             	mov    0x14(%ebp),%eax
f0103fb9:	8b 10                	mov    (%eax),%edx
f0103fbb:	8b 48 04             	mov    0x4(%eax),%ecx
f0103fbe:	8d 40 08             	lea    0x8(%eax),%eax
f0103fc1:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0103fc4:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103fc9:	e9 cf 00 00 00       	jmp    f010409d <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0103fce:	85 c9                	test   %ecx,%ecx
f0103fd0:	74 1a                	je     f0103fec <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
f0103fd2:	8b 45 14             	mov    0x14(%ebp),%eax
f0103fd5:	8b 10                	mov    (%eax),%edx
f0103fd7:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103fdc:	8d 40 04             	lea    0x4(%eax),%eax
f0103fdf:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0103fe2:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103fe7:	e9 b1 00 00 00       	jmp    f010409d <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0103fec:	8b 45 14             	mov    0x14(%ebp),%eax
f0103fef:	8b 10                	mov    (%eax),%edx
f0103ff1:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103ff6:	8d 40 04             	lea    0x4(%eax),%eax
f0103ff9:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0103ffc:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104001:	e9 97 00 00 00       	jmp    f010409d <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f0104006:	83 ec 08             	sub    $0x8,%esp
f0104009:	53                   	push   %ebx
f010400a:	6a 58                	push   $0x58
f010400c:	ff d6                	call   *%esi
			putch('X', putdat);
f010400e:	83 c4 08             	add    $0x8,%esp
f0104011:	53                   	push   %ebx
f0104012:	6a 58                	push   $0x58
f0104014:	ff d6                	call   *%esi
			putch('X', putdat);
f0104016:	83 c4 08             	add    $0x8,%esp
f0104019:	53                   	push   %ebx
f010401a:	6a 58                	push   $0x58
f010401c:	ff d6                	call   *%esi
			break;
f010401e:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104021:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f0104024:	e9 8b fc ff ff       	jmp    f0103cb4 <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
f0104029:	83 ec 08             	sub    $0x8,%esp
f010402c:	53                   	push   %ebx
f010402d:	6a 30                	push   $0x30
f010402f:	ff d6                	call   *%esi
			putch('x', putdat);
f0104031:	83 c4 08             	add    $0x8,%esp
f0104034:	53                   	push   %ebx
f0104035:	6a 78                	push   $0x78
f0104037:	ff d6                	call   *%esi
			num = (unsigned long long)
f0104039:	8b 45 14             	mov    0x14(%ebp),%eax
f010403c:	8b 10                	mov    (%eax),%edx
f010403e:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0104043:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0104046:	8d 40 04             	lea    0x4(%eax),%eax
f0104049:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010404c:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0104051:	eb 4a                	jmp    f010409d <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0104053:	83 f9 01             	cmp    $0x1,%ecx
f0104056:	7e 15                	jle    f010406d <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
f0104058:	8b 45 14             	mov    0x14(%ebp),%eax
f010405b:	8b 10                	mov    (%eax),%edx
f010405d:	8b 48 04             	mov    0x4(%eax),%ecx
f0104060:	8d 40 08             	lea    0x8(%eax),%eax
f0104063:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0104066:	b8 10 00 00 00       	mov    $0x10,%eax
f010406b:	eb 30                	jmp    f010409d <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f010406d:	85 c9                	test   %ecx,%ecx
f010406f:	74 17                	je     f0104088 <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
f0104071:	8b 45 14             	mov    0x14(%ebp),%eax
f0104074:	8b 10                	mov    (%eax),%edx
f0104076:	b9 00 00 00 00       	mov    $0x0,%ecx
f010407b:	8d 40 04             	lea    0x4(%eax),%eax
f010407e:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0104081:	b8 10 00 00 00       	mov    $0x10,%eax
f0104086:	eb 15                	jmp    f010409d <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0104088:	8b 45 14             	mov    0x14(%ebp),%eax
f010408b:	8b 10                	mov    (%eax),%edx
f010408d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104092:	8d 40 04             	lea    0x4(%eax),%eax
f0104095:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0104098:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f010409d:	83 ec 0c             	sub    $0xc,%esp
f01040a0:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f01040a4:	57                   	push   %edi
f01040a5:	ff 75 e0             	pushl  -0x20(%ebp)
f01040a8:	50                   	push   %eax
f01040a9:	51                   	push   %ecx
f01040aa:	52                   	push   %edx
f01040ab:	89 da                	mov    %ebx,%edx
f01040ad:	89 f0                	mov    %esi,%eax
f01040af:	e8 f1 fa ff ff       	call   f0103ba5 <printnum>
			break;
f01040b4:	83 c4 20             	add    $0x20,%esp
f01040b7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01040ba:	e9 f5 fb ff ff       	jmp    f0103cb4 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01040bf:	83 ec 08             	sub    $0x8,%esp
f01040c2:	53                   	push   %ebx
f01040c3:	52                   	push   %edx
f01040c4:	ff d6                	call   *%esi
			break;
f01040c6:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01040c9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01040cc:	e9 e3 fb ff ff       	jmp    f0103cb4 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01040d1:	83 ec 08             	sub    $0x8,%esp
f01040d4:	53                   	push   %ebx
f01040d5:	6a 25                	push   $0x25
f01040d7:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01040d9:	83 c4 10             	add    $0x10,%esp
f01040dc:	eb 03                	jmp    f01040e1 <vprintfmt+0x453>
f01040de:	83 ef 01             	sub    $0x1,%edi
f01040e1:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f01040e5:	75 f7                	jne    f01040de <vprintfmt+0x450>
f01040e7:	e9 c8 fb ff ff       	jmp    f0103cb4 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f01040ec:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01040ef:	5b                   	pop    %ebx
f01040f0:	5e                   	pop    %esi
f01040f1:	5f                   	pop    %edi
f01040f2:	5d                   	pop    %ebp
f01040f3:	c3                   	ret    

f01040f4 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01040f4:	55                   	push   %ebp
f01040f5:	89 e5                	mov    %esp,%ebp
f01040f7:	83 ec 18             	sub    $0x18,%esp
f01040fa:	8b 45 08             	mov    0x8(%ebp),%eax
f01040fd:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0104100:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104103:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0104107:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010410a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0104111:	85 c0                	test   %eax,%eax
f0104113:	74 26                	je     f010413b <vsnprintf+0x47>
f0104115:	85 d2                	test   %edx,%edx
f0104117:	7e 22                	jle    f010413b <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0104119:	ff 75 14             	pushl  0x14(%ebp)
f010411c:	ff 75 10             	pushl  0x10(%ebp)
f010411f:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0104122:	50                   	push   %eax
f0104123:	68 54 3c 10 f0       	push   $0xf0103c54
f0104128:	e8 61 fb ff ff       	call   f0103c8e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010412d:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104130:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0104133:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104136:	83 c4 10             	add    $0x10,%esp
f0104139:	eb 05                	jmp    f0104140 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f010413b:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0104140:	c9                   	leave  
f0104141:	c3                   	ret    

f0104142 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0104142:	55                   	push   %ebp
f0104143:	89 e5                	mov    %esp,%ebp
f0104145:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0104148:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f010414b:	50                   	push   %eax
f010414c:	ff 75 10             	pushl  0x10(%ebp)
f010414f:	ff 75 0c             	pushl  0xc(%ebp)
f0104152:	ff 75 08             	pushl  0x8(%ebp)
f0104155:	e8 9a ff ff ff       	call   f01040f4 <vsnprintf>
	va_end(ap);

	return rc;
}
f010415a:	c9                   	leave  
f010415b:	c3                   	ret    

f010415c <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f010415c:	55                   	push   %ebp
f010415d:	89 e5                	mov    %esp,%ebp
f010415f:	57                   	push   %edi
f0104160:	56                   	push   %esi
f0104161:	53                   	push   %ebx
f0104162:	83 ec 0c             	sub    $0xc,%esp
f0104165:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0104168:	85 c0                	test   %eax,%eax
f010416a:	74 11                	je     f010417d <readline+0x21>
		cprintf("%s", prompt);
f010416c:	83 ec 08             	sub    $0x8,%esp
f010416f:	50                   	push   %eax
f0104170:	68 aa 4d 10 f0       	push   $0xf0104daa
f0104175:	e8 49 ee ff ff       	call   f0102fc3 <cprintf>
f010417a:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f010417d:	83 ec 0c             	sub    $0xc,%esp
f0104180:	6a 00                	push   $0x0
f0104182:	e8 a1 c4 ff ff       	call   f0100628 <iscons>
f0104187:	89 c7                	mov    %eax,%edi
f0104189:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010418c:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0104191:	e8 81 c4 ff ff       	call   f0100617 <getchar>
f0104196:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0104198:	85 c0                	test   %eax,%eax
f010419a:	79 18                	jns    f01041b4 <readline+0x58>
			cprintf("read error: %e\n", c);
f010419c:	83 ec 08             	sub    $0x8,%esp
f010419f:	50                   	push   %eax
f01041a0:	68 40 5f 10 f0       	push   $0xf0105f40
f01041a5:	e8 19 ee ff ff       	call   f0102fc3 <cprintf>
			return NULL;
f01041aa:	83 c4 10             	add    $0x10,%esp
f01041ad:	b8 00 00 00 00       	mov    $0x0,%eax
f01041b2:	eb 79                	jmp    f010422d <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01041b4:	83 f8 08             	cmp    $0x8,%eax
f01041b7:	0f 94 c2             	sete   %dl
f01041ba:	83 f8 7f             	cmp    $0x7f,%eax
f01041bd:	0f 94 c0             	sete   %al
f01041c0:	08 c2                	or     %al,%dl
f01041c2:	74 1a                	je     f01041de <readline+0x82>
f01041c4:	85 f6                	test   %esi,%esi
f01041c6:	7e 16                	jle    f01041de <readline+0x82>
			if (echoing)
f01041c8:	85 ff                	test   %edi,%edi
f01041ca:	74 0d                	je     f01041d9 <readline+0x7d>
				cputchar('\b');
f01041cc:	83 ec 0c             	sub    $0xc,%esp
f01041cf:	6a 08                	push   $0x8
f01041d1:	e8 31 c4 ff ff       	call   f0100607 <cputchar>
f01041d6:	83 c4 10             	add    $0x10,%esp
			i--;
f01041d9:	83 ee 01             	sub    $0x1,%esi
f01041dc:	eb b3                	jmp    f0104191 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01041de:	83 fb 1f             	cmp    $0x1f,%ebx
f01041e1:	7e 23                	jle    f0104206 <readline+0xaa>
f01041e3:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01041e9:	7f 1b                	jg     f0104206 <readline+0xaa>
			if (echoing)
f01041eb:	85 ff                	test   %edi,%edi
f01041ed:	74 0c                	je     f01041fb <readline+0x9f>
				cputchar(c);
f01041ef:	83 ec 0c             	sub    $0xc,%esp
f01041f2:	53                   	push   %ebx
f01041f3:	e8 0f c4 ff ff       	call   f0100607 <cputchar>
f01041f8:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f01041fb:	88 9e 00 d7 17 f0    	mov    %bl,-0xfe82900(%esi)
f0104201:	8d 76 01             	lea    0x1(%esi),%esi
f0104204:	eb 8b                	jmp    f0104191 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0104206:	83 fb 0a             	cmp    $0xa,%ebx
f0104209:	74 05                	je     f0104210 <readline+0xb4>
f010420b:	83 fb 0d             	cmp    $0xd,%ebx
f010420e:	75 81                	jne    f0104191 <readline+0x35>
			if (echoing)
f0104210:	85 ff                	test   %edi,%edi
f0104212:	74 0d                	je     f0104221 <readline+0xc5>
				cputchar('\n');
f0104214:	83 ec 0c             	sub    $0xc,%esp
f0104217:	6a 0a                	push   $0xa
f0104219:	e8 e9 c3 ff ff       	call   f0100607 <cputchar>
f010421e:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0104221:	c6 86 00 d7 17 f0 00 	movb   $0x0,-0xfe82900(%esi)
			return buf;
f0104228:	b8 00 d7 17 f0       	mov    $0xf017d700,%eax
		}
	}
}
f010422d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104230:	5b                   	pop    %ebx
f0104231:	5e                   	pop    %esi
f0104232:	5f                   	pop    %edi
f0104233:	5d                   	pop    %ebp
f0104234:	c3                   	ret    

f0104235 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0104235:	55                   	push   %ebp
f0104236:	89 e5                	mov    %esp,%ebp
f0104238:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f010423b:	b8 00 00 00 00       	mov    $0x0,%eax
f0104240:	eb 03                	jmp    f0104245 <strlen+0x10>
		n++;
f0104242:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0104245:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0104249:	75 f7                	jne    f0104242 <strlen+0xd>
		n++;
	return n;
}
f010424b:	5d                   	pop    %ebp
f010424c:	c3                   	ret    

f010424d <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010424d:	55                   	push   %ebp
f010424e:	89 e5                	mov    %esp,%ebp
f0104250:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104253:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104256:	ba 00 00 00 00       	mov    $0x0,%edx
f010425b:	eb 03                	jmp    f0104260 <strnlen+0x13>
		n++;
f010425d:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104260:	39 c2                	cmp    %eax,%edx
f0104262:	74 08                	je     f010426c <strnlen+0x1f>
f0104264:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0104268:	75 f3                	jne    f010425d <strnlen+0x10>
f010426a:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f010426c:	5d                   	pop    %ebp
f010426d:	c3                   	ret    

f010426e <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010426e:	55                   	push   %ebp
f010426f:	89 e5                	mov    %esp,%ebp
f0104271:	53                   	push   %ebx
f0104272:	8b 45 08             	mov    0x8(%ebp),%eax
f0104275:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0104278:	89 c2                	mov    %eax,%edx
f010427a:	83 c2 01             	add    $0x1,%edx
f010427d:	83 c1 01             	add    $0x1,%ecx
f0104280:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0104284:	88 5a ff             	mov    %bl,-0x1(%edx)
f0104287:	84 db                	test   %bl,%bl
f0104289:	75 ef                	jne    f010427a <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f010428b:	5b                   	pop    %ebx
f010428c:	5d                   	pop    %ebp
f010428d:	c3                   	ret    

f010428e <strcat>:

char *
strcat(char *dst, const char *src)
{
f010428e:	55                   	push   %ebp
f010428f:	89 e5                	mov    %esp,%ebp
f0104291:	53                   	push   %ebx
f0104292:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0104295:	53                   	push   %ebx
f0104296:	e8 9a ff ff ff       	call   f0104235 <strlen>
f010429b:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f010429e:	ff 75 0c             	pushl  0xc(%ebp)
f01042a1:	01 d8                	add    %ebx,%eax
f01042a3:	50                   	push   %eax
f01042a4:	e8 c5 ff ff ff       	call   f010426e <strcpy>
	return dst;
}
f01042a9:	89 d8                	mov    %ebx,%eax
f01042ab:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01042ae:	c9                   	leave  
f01042af:	c3                   	ret    

f01042b0 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01042b0:	55                   	push   %ebp
f01042b1:	89 e5                	mov    %esp,%ebp
f01042b3:	56                   	push   %esi
f01042b4:	53                   	push   %ebx
f01042b5:	8b 75 08             	mov    0x8(%ebp),%esi
f01042b8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01042bb:	89 f3                	mov    %esi,%ebx
f01042bd:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01042c0:	89 f2                	mov    %esi,%edx
f01042c2:	eb 0f                	jmp    f01042d3 <strncpy+0x23>
		*dst++ = *src;
f01042c4:	83 c2 01             	add    $0x1,%edx
f01042c7:	0f b6 01             	movzbl (%ecx),%eax
f01042ca:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01042cd:	80 39 01             	cmpb   $0x1,(%ecx)
f01042d0:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01042d3:	39 da                	cmp    %ebx,%edx
f01042d5:	75 ed                	jne    f01042c4 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01042d7:	89 f0                	mov    %esi,%eax
f01042d9:	5b                   	pop    %ebx
f01042da:	5e                   	pop    %esi
f01042db:	5d                   	pop    %ebp
f01042dc:	c3                   	ret    

f01042dd <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01042dd:	55                   	push   %ebp
f01042de:	89 e5                	mov    %esp,%ebp
f01042e0:	56                   	push   %esi
f01042e1:	53                   	push   %ebx
f01042e2:	8b 75 08             	mov    0x8(%ebp),%esi
f01042e5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01042e8:	8b 55 10             	mov    0x10(%ebp),%edx
f01042eb:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01042ed:	85 d2                	test   %edx,%edx
f01042ef:	74 21                	je     f0104312 <strlcpy+0x35>
f01042f1:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f01042f5:	89 f2                	mov    %esi,%edx
f01042f7:	eb 09                	jmp    f0104302 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01042f9:	83 c2 01             	add    $0x1,%edx
f01042fc:	83 c1 01             	add    $0x1,%ecx
f01042ff:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0104302:	39 c2                	cmp    %eax,%edx
f0104304:	74 09                	je     f010430f <strlcpy+0x32>
f0104306:	0f b6 19             	movzbl (%ecx),%ebx
f0104309:	84 db                	test   %bl,%bl
f010430b:	75 ec                	jne    f01042f9 <strlcpy+0x1c>
f010430d:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f010430f:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0104312:	29 f0                	sub    %esi,%eax
}
f0104314:	5b                   	pop    %ebx
f0104315:	5e                   	pop    %esi
f0104316:	5d                   	pop    %ebp
f0104317:	c3                   	ret    

f0104318 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0104318:	55                   	push   %ebp
f0104319:	89 e5                	mov    %esp,%ebp
f010431b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010431e:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0104321:	eb 06                	jmp    f0104329 <strcmp+0x11>
		p++, q++;
f0104323:	83 c1 01             	add    $0x1,%ecx
f0104326:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0104329:	0f b6 01             	movzbl (%ecx),%eax
f010432c:	84 c0                	test   %al,%al
f010432e:	74 04                	je     f0104334 <strcmp+0x1c>
f0104330:	3a 02                	cmp    (%edx),%al
f0104332:	74 ef                	je     f0104323 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0104334:	0f b6 c0             	movzbl %al,%eax
f0104337:	0f b6 12             	movzbl (%edx),%edx
f010433a:	29 d0                	sub    %edx,%eax
}
f010433c:	5d                   	pop    %ebp
f010433d:	c3                   	ret    

f010433e <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010433e:	55                   	push   %ebp
f010433f:	89 e5                	mov    %esp,%ebp
f0104341:	53                   	push   %ebx
f0104342:	8b 45 08             	mov    0x8(%ebp),%eax
f0104345:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104348:	89 c3                	mov    %eax,%ebx
f010434a:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f010434d:	eb 06                	jmp    f0104355 <strncmp+0x17>
		n--, p++, q++;
f010434f:	83 c0 01             	add    $0x1,%eax
f0104352:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0104355:	39 d8                	cmp    %ebx,%eax
f0104357:	74 15                	je     f010436e <strncmp+0x30>
f0104359:	0f b6 08             	movzbl (%eax),%ecx
f010435c:	84 c9                	test   %cl,%cl
f010435e:	74 04                	je     f0104364 <strncmp+0x26>
f0104360:	3a 0a                	cmp    (%edx),%cl
f0104362:	74 eb                	je     f010434f <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0104364:	0f b6 00             	movzbl (%eax),%eax
f0104367:	0f b6 12             	movzbl (%edx),%edx
f010436a:	29 d0                	sub    %edx,%eax
f010436c:	eb 05                	jmp    f0104373 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f010436e:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0104373:	5b                   	pop    %ebx
f0104374:	5d                   	pop    %ebp
f0104375:	c3                   	ret    

f0104376 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0104376:	55                   	push   %ebp
f0104377:	89 e5                	mov    %esp,%ebp
f0104379:	8b 45 08             	mov    0x8(%ebp),%eax
f010437c:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104380:	eb 07                	jmp    f0104389 <strchr+0x13>
		if (*s == c)
f0104382:	38 ca                	cmp    %cl,%dl
f0104384:	74 0f                	je     f0104395 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0104386:	83 c0 01             	add    $0x1,%eax
f0104389:	0f b6 10             	movzbl (%eax),%edx
f010438c:	84 d2                	test   %dl,%dl
f010438e:	75 f2                	jne    f0104382 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0104390:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104395:	5d                   	pop    %ebp
f0104396:	c3                   	ret    

f0104397 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0104397:	55                   	push   %ebp
f0104398:	89 e5                	mov    %esp,%ebp
f010439a:	8b 45 08             	mov    0x8(%ebp),%eax
f010439d:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01043a1:	eb 03                	jmp    f01043a6 <strfind+0xf>
f01043a3:	83 c0 01             	add    $0x1,%eax
f01043a6:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01043a9:	38 ca                	cmp    %cl,%dl
f01043ab:	74 04                	je     f01043b1 <strfind+0x1a>
f01043ad:	84 d2                	test   %dl,%dl
f01043af:	75 f2                	jne    f01043a3 <strfind+0xc>
			break;
	return (char *) s;
}
f01043b1:	5d                   	pop    %ebp
f01043b2:	c3                   	ret    

f01043b3 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01043b3:	55                   	push   %ebp
f01043b4:	89 e5                	mov    %esp,%ebp
f01043b6:	57                   	push   %edi
f01043b7:	56                   	push   %esi
f01043b8:	53                   	push   %ebx
f01043b9:	8b 7d 08             	mov    0x8(%ebp),%edi
f01043bc:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01043bf:	85 c9                	test   %ecx,%ecx
f01043c1:	74 36                	je     f01043f9 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01043c3:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01043c9:	75 28                	jne    f01043f3 <memset+0x40>
f01043cb:	f6 c1 03             	test   $0x3,%cl
f01043ce:	75 23                	jne    f01043f3 <memset+0x40>
		c &= 0xFF;
f01043d0:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01043d4:	89 d3                	mov    %edx,%ebx
f01043d6:	c1 e3 08             	shl    $0x8,%ebx
f01043d9:	89 d6                	mov    %edx,%esi
f01043db:	c1 e6 18             	shl    $0x18,%esi
f01043de:	89 d0                	mov    %edx,%eax
f01043e0:	c1 e0 10             	shl    $0x10,%eax
f01043e3:	09 f0                	or     %esi,%eax
f01043e5:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f01043e7:	89 d8                	mov    %ebx,%eax
f01043e9:	09 d0                	or     %edx,%eax
f01043eb:	c1 e9 02             	shr    $0x2,%ecx
f01043ee:	fc                   	cld    
f01043ef:	f3 ab                	rep stos %eax,%es:(%edi)
f01043f1:	eb 06                	jmp    f01043f9 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01043f3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01043f6:	fc                   	cld    
f01043f7:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01043f9:	89 f8                	mov    %edi,%eax
f01043fb:	5b                   	pop    %ebx
f01043fc:	5e                   	pop    %esi
f01043fd:	5f                   	pop    %edi
f01043fe:	5d                   	pop    %ebp
f01043ff:	c3                   	ret    

f0104400 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0104400:	55                   	push   %ebp
f0104401:	89 e5                	mov    %esp,%ebp
f0104403:	57                   	push   %edi
f0104404:	56                   	push   %esi
f0104405:	8b 45 08             	mov    0x8(%ebp),%eax
f0104408:	8b 75 0c             	mov    0xc(%ebp),%esi
f010440b:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010440e:	39 c6                	cmp    %eax,%esi
f0104410:	73 35                	jae    f0104447 <memmove+0x47>
f0104412:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0104415:	39 d0                	cmp    %edx,%eax
f0104417:	73 2e                	jae    f0104447 <memmove+0x47>
		s += n;
		d += n;
f0104419:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010441c:	89 d6                	mov    %edx,%esi
f010441e:	09 fe                	or     %edi,%esi
f0104420:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0104426:	75 13                	jne    f010443b <memmove+0x3b>
f0104428:	f6 c1 03             	test   $0x3,%cl
f010442b:	75 0e                	jne    f010443b <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f010442d:	83 ef 04             	sub    $0x4,%edi
f0104430:	8d 72 fc             	lea    -0x4(%edx),%esi
f0104433:	c1 e9 02             	shr    $0x2,%ecx
f0104436:	fd                   	std    
f0104437:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104439:	eb 09                	jmp    f0104444 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010443b:	83 ef 01             	sub    $0x1,%edi
f010443e:	8d 72 ff             	lea    -0x1(%edx),%esi
f0104441:	fd                   	std    
f0104442:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0104444:	fc                   	cld    
f0104445:	eb 1d                	jmp    f0104464 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104447:	89 f2                	mov    %esi,%edx
f0104449:	09 c2                	or     %eax,%edx
f010444b:	f6 c2 03             	test   $0x3,%dl
f010444e:	75 0f                	jne    f010445f <memmove+0x5f>
f0104450:	f6 c1 03             	test   $0x3,%cl
f0104453:	75 0a                	jne    f010445f <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0104455:	c1 e9 02             	shr    $0x2,%ecx
f0104458:	89 c7                	mov    %eax,%edi
f010445a:	fc                   	cld    
f010445b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010445d:	eb 05                	jmp    f0104464 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010445f:	89 c7                	mov    %eax,%edi
f0104461:	fc                   	cld    
f0104462:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0104464:	5e                   	pop    %esi
f0104465:	5f                   	pop    %edi
f0104466:	5d                   	pop    %ebp
f0104467:	c3                   	ret    

f0104468 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0104468:	55                   	push   %ebp
f0104469:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f010446b:	ff 75 10             	pushl  0x10(%ebp)
f010446e:	ff 75 0c             	pushl  0xc(%ebp)
f0104471:	ff 75 08             	pushl  0x8(%ebp)
f0104474:	e8 87 ff ff ff       	call   f0104400 <memmove>
}
f0104479:	c9                   	leave  
f010447a:	c3                   	ret    

f010447b <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010447b:	55                   	push   %ebp
f010447c:	89 e5                	mov    %esp,%ebp
f010447e:	56                   	push   %esi
f010447f:	53                   	push   %ebx
f0104480:	8b 45 08             	mov    0x8(%ebp),%eax
f0104483:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104486:	89 c6                	mov    %eax,%esi
f0104488:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010448b:	eb 1a                	jmp    f01044a7 <memcmp+0x2c>
		if (*s1 != *s2)
f010448d:	0f b6 08             	movzbl (%eax),%ecx
f0104490:	0f b6 1a             	movzbl (%edx),%ebx
f0104493:	38 d9                	cmp    %bl,%cl
f0104495:	74 0a                	je     f01044a1 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0104497:	0f b6 c1             	movzbl %cl,%eax
f010449a:	0f b6 db             	movzbl %bl,%ebx
f010449d:	29 d8                	sub    %ebx,%eax
f010449f:	eb 0f                	jmp    f01044b0 <memcmp+0x35>
		s1++, s2++;
f01044a1:	83 c0 01             	add    $0x1,%eax
f01044a4:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01044a7:	39 f0                	cmp    %esi,%eax
f01044a9:	75 e2                	jne    f010448d <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01044ab:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01044b0:	5b                   	pop    %ebx
f01044b1:	5e                   	pop    %esi
f01044b2:	5d                   	pop    %ebp
f01044b3:	c3                   	ret    

f01044b4 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01044b4:	55                   	push   %ebp
f01044b5:	89 e5                	mov    %esp,%ebp
f01044b7:	53                   	push   %ebx
f01044b8:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01044bb:	89 c1                	mov    %eax,%ecx
f01044bd:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f01044c0:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01044c4:	eb 0a                	jmp    f01044d0 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f01044c6:	0f b6 10             	movzbl (%eax),%edx
f01044c9:	39 da                	cmp    %ebx,%edx
f01044cb:	74 07                	je     f01044d4 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01044cd:	83 c0 01             	add    $0x1,%eax
f01044d0:	39 c8                	cmp    %ecx,%eax
f01044d2:	72 f2                	jb     f01044c6 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01044d4:	5b                   	pop    %ebx
f01044d5:	5d                   	pop    %ebp
f01044d6:	c3                   	ret    

f01044d7 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01044d7:	55                   	push   %ebp
f01044d8:	89 e5                	mov    %esp,%ebp
f01044da:	57                   	push   %edi
f01044db:	56                   	push   %esi
f01044dc:	53                   	push   %ebx
f01044dd:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01044e0:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01044e3:	eb 03                	jmp    f01044e8 <strtol+0x11>
		s++;
f01044e5:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01044e8:	0f b6 01             	movzbl (%ecx),%eax
f01044eb:	3c 20                	cmp    $0x20,%al
f01044ed:	74 f6                	je     f01044e5 <strtol+0xe>
f01044ef:	3c 09                	cmp    $0x9,%al
f01044f1:	74 f2                	je     f01044e5 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01044f3:	3c 2b                	cmp    $0x2b,%al
f01044f5:	75 0a                	jne    f0104501 <strtol+0x2a>
		s++;
f01044f7:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01044fa:	bf 00 00 00 00       	mov    $0x0,%edi
f01044ff:	eb 11                	jmp    f0104512 <strtol+0x3b>
f0104501:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0104506:	3c 2d                	cmp    $0x2d,%al
f0104508:	75 08                	jne    f0104512 <strtol+0x3b>
		s++, neg = 1;
f010450a:	83 c1 01             	add    $0x1,%ecx
f010450d:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104512:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0104518:	75 15                	jne    f010452f <strtol+0x58>
f010451a:	80 39 30             	cmpb   $0x30,(%ecx)
f010451d:	75 10                	jne    f010452f <strtol+0x58>
f010451f:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0104523:	75 7c                	jne    f01045a1 <strtol+0xca>
		s += 2, base = 16;
f0104525:	83 c1 02             	add    $0x2,%ecx
f0104528:	bb 10 00 00 00       	mov    $0x10,%ebx
f010452d:	eb 16                	jmp    f0104545 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f010452f:	85 db                	test   %ebx,%ebx
f0104531:	75 12                	jne    f0104545 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0104533:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104538:	80 39 30             	cmpb   $0x30,(%ecx)
f010453b:	75 08                	jne    f0104545 <strtol+0x6e>
		s++, base = 8;
f010453d:	83 c1 01             	add    $0x1,%ecx
f0104540:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0104545:	b8 00 00 00 00       	mov    $0x0,%eax
f010454a:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f010454d:	0f b6 11             	movzbl (%ecx),%edx
f0104550:	8d 72 d0             	lea    -0x30(%edx),%esi
f0104553:	89 f3                	mov    %esi,%ebx
f0104555:	80 fb 09             	cmp    $0x9,%bl
f0104558:	77 08                	ja     f0104562 <strtol+0x8b>
			dig = *s - '0';
f010455a:	0f be d2             	movsbl %dl,%edx
f010455d:	83 ea 30             	sub    $0x30,%edx
f0104560:	eb 22                	jmp    f0104584 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0104562:	8d 72 9f             	lea    -0x61(%edx),%esi
f0104565:	89 f3                	mov    %esi,%ebx
f0104567:	80 fb 19             	cmp    $0x19,%bl
f010456a:	77 08                	ja     f0104574 <strtol+0x9d>
			dig = *s - 'a' + 10;
f010456c:	0f be d2             	movsbl %dl,%edx
f010456f:	83 ea 57             	sub    $0x57,%edx
f0104572:	eb 10                	jmp    f0104584 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0104574:	8d 72 bf             	lea    -0x41(%edx),%esi
f0104577:	89 f3                	mov    %esi,%ebx
f0104579:	80 fb 19             	cmp    $0x19,%bl
f010457c:	77 16                	ja     f0104594 <strtol+0xbd>
			dig = *s - 'A' + 10;
f010457e:	0f be d2             	movsbl %dl,%edx
f0104581:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0104584:	3b 55 10             	cmp    0x10(%ebp),%edx
f0104587:	7d 0b                	jge    f0104594 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0104589:	83 c1 01             	add    $0x1,%ecx
f010458c:	0f af 45 10          	imul   0x10(%ebp),%eax
f0104590:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0104592:	eb b9                	jmp    f010454d <strtol+0x76>

	if (endptr)
f0104594:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0104598:	74 0d                	je     f01045a7 <strtol+0xd0>
		*endptr = (char *) s;
f010459a:	8b 75 0c             	mov    0xc(%ebp),%esi
f010459d:	89 0e                	mov    %ecx,(%esi)
f010459f:	eb 06                	jmp    f01045a7 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01045a1:	85 db                	test   %ebx,%ebx
f01045a3:	74 98                	je     f010453d <strtol+0x66>
f01045a5:	eb 9e                	jmp    f0104545 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01045a7:	89 c2                	mov    %eax,%edx
f01045a9:	f7 da                	neg    %edx
f01045ab:	85 ff                	test   %edi,%edi
f01045ad:	0f 45 c2             	cmovne %edx,%eax
}
f01045b0:	5b                   	pop    %ebx
f01045b1:	5e                   	pop    %esi
f01045b2:	5f                   	pop    %edi
f01045b3:	5d                   	pop    %ebp
f01045b4:	c3                   	ret    
f01045b5:	66 90                	xchg   %ax,%ax
f01045b7:	66 90                	xchg   %ax,%ax
f01045b9:	66 90                	xchg   %ax,%ax
f01045bb:	66 90                	xchg   %ax,%ax
f01045bd:	66 90                	xchg   %ax,%ax
f01045bf:	90                   	nop

f01045c0 <__udivdi3>:
f01045c0:	55                   	push   %ebp
f01045c1:	57                   	push   %edi
f01045c2:	56                   	push   %esi
f01045c3:	53                   	push   %ebx
f01045c4:	83 ec 1c             	sub    $0x1c,%esp
f01045c7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f01045cb:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f01045cf:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f01045d3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01045d7:	85 f6                	test   %esi,%esi
f01045d9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01045dd:	89 ca                	mov    %ecx,%edx
f01045df:	89 f8                	mov    %edi,%eax
f01045e1:	75 3d                	jne    f0104620 <__udivdi3+0x60>
f01045e3:	39 cf                	cmp    %ecx,%edi
f01045e5:	0f 87 c5 00 00 00    	ja     f01046b0 <__udivdi3+0xf0>
f01045eb:	85 ff                	test   %edi,%edi
f01045ed:	89 fd                	mov    %edi,%ebp
f01045ef:	75 0b                	jne    f01045fc <__udivdi3+0x3c>
f01045f1:	b8 01 00 00 00       	mov    $0x1,%eax
f01045f6:	31 d2                	xor    %edx,%edx
f01045f8:	f7 f7                	div    %edi
f01045fa:	89 c5                	mov    %eax,%ebp
f01045fc:	89 c8                	mov    %ecx,%eax
f01045fe:	31 d2                	xor    %edx,%edx
f0104600:	f7 f5                	div    %ebp
f0104602:	89 c1                	mov    %eax,%ecx
f0104604:	89 d8                	mov    %ebx,%eax
f0104606:	89 cf                	mov    %ecx,%edi
f0104608:	f7 f5                	div    %ebp
f010460a:	89 c3                	mov    %eax,%ebx
f010460c:	89 d8                	mov    %ebx,%eax
f010460e:	89 fa                	mov    %edi,%edx
f0104610:	83 c4 1c             	add    $0x1c,%esp
f0104613:	5b                   	pop    %ebx
f0104614:	5e                   	pop    %esi
f0104615:	5f                   	pop    %edi
f0104616:	5d                   	pop    %ebp
f0104617:	c3                   	ret    
f0104618:	90                   	nop
f0104619:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104620:	39 ce                	cmp    %ecx,%esi
f0104622:	77 74                	ja     f0104698 <__udivdi3+0xd8>
f0104624:	0f bd fe             	bsr    %esi,%edi
f0104627:	83 f7 1f             	xor    $0x1f,%edi
f010462a:	0f 84 98 00 00 00    	je     f01046c8 <__udivdi3+0x108>
f0104630:	bb 20 00 00 00       	mov    $0x20,%ebx
f0104635:	89 f9                	mov    %edi,%ecx
f0104637:	89 c5                	mov    %eax,%ebp
f0104639:	29 fb                	sub    %edi,%ebx
f010463b:	d3 e6                	shl    %cl,%esi
f010463d:	89 d9                	mov    %ebx,%ecx
f010463f:	d3 ed                	shr    %cl,%ebp
f0104641:	89 f9                	mov    %edi,%ecx
f0104643:	d3 e0                	shl    %cl,%eax
f0104645:	09 ee                	or     %ebp,%esi
f0104647:	89 d9                	mov    %ebx,%ecx
f0104649:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010464d:	89 d5                	mov    %edx,%ebp
f010464f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0104653:	d3 ed                	shr    %cl,%ebp
f0104655:	89 f9                	mov    %edi,%ecx
f0104657:	d3 e2                	shl    %cl,%edx
f0104659:	89 d9                	mov    %ebx,%ecx
f010465b:	d3 e8                	shr    %cl,%eax
f010465d:	09 c2                	or     %eax,%edx
f010465f:	89 d0                	mov    %edx,%eax
f0104661:	89 ea                	mov    %ebp,%edx
f0104663:	f7 f6                	div    %esi
f0104665:	89 d5                	mov    %edx,%ebp
f0104667:	89 c3                	mov    %eax,%ebx
f0104669:	f7 64 24 0c          	mull   0xc(%esp)
f010466d:	39 d5                	cmp    %edx,%ebp
f010466f:	72 10                	jb     f0104681 <__udivdi3+0xc1>
f0104671:	8b 74 24 08          	mov    0x8(%esp),%esi
f0104675:	89 f9                	mov    %edi,%ecx
f0104677:	d3 e6                	shl    %cl,%esi
f0104679:	39 c6                	cmp    %eax,%esi
f010467b:	73 07                	jae    f0104684 <__udivdi3+0xc4>
f010467d:	39 d5                	cmp    %edx,%ebp
f010467f:	75 03                	jne    f0104684 <__udivdi3+0xc4>
f0104681:	83 eb 01             	sub    $0x1,%ebx
f0104684:	31 ff                	xor    %edi,%edi
f0104686:	89 d8                	mov    %ebx,%eax
f0104688:	89 fa                	mov    %edi,%edx
f010468a:	83 c4 1c             	add    $0x1c,%esp
f010468d:	5b                   	pop    %ebx
f010468e:	5e                   	pop    %esi
f010468f:	5f                   	pop    %edi
f0104690:	5d                   	pop    %ebp
f0104691:	c3                   	ret    
f0104692:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104698:	31 ff                	xor    %edi,%edi
f010469a:	31 db                	xor    %ebx,%ebx
f010469c:	89 d8                	mov    %ebx,%eax
f010469e:	89 fa                	mov    %edi,%edx
f01046a0:	83 c4 1c             	add    $0x1c,%esp
f01046a3:	5b                   	pop    %ebx
f01046a4:	5e                   	pop    %esi
f01046a5:	5f                   	pop    %edi
f01046a6:	5d                   	pop    %ebp
f01046a7:	c3                   	ret    
f01046a8:	90                   	nop
f01046a9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01046b0:	89 d8                	mov    %ebx,%eax
f01046b2:	f7 f7                	div    %edi
f01046b4:	31 ff                	xor    %edi,%edi
f01046b6:	89 c3                	mov    %eax,%ebx
f01046b8:	89 d8                	mov    %ebx,%eax
f01046ba:	89 fa                	mov    %edi,%edx
f01046bc:	83 c4 1c             	add    $0x1c,%esp
f01046bf:	5b                   	pop    %ebx
f01046c0:	5e                   	pop    %esi
f01046c1:	5f                   	pop    %edi
f01046c2:	5d                   	pop    %ebp
f01046c3:	c3                   	ret    
f01046c4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01046c8:	39 ce                	cmp    %ecx,%esi
f01046ca:	72 0c                	jb     f01046d8 <__udivdi3+0x118>
f01046cc:	31 db                	xor    %ebx,%ebx
f01046ce:	3b 44 24 08          	cmp    0x8(%esp),%eax
f01046d2:	0f 87 34 ff ff ff    	ja     f010460c <__udivdi3+0x4c>
f01046d8:	bb 01 00 00 00       	mov    $0x1,%ebx
f01046dd:	e9 2a ff ff ff       	jmp    f010460c <__udivdi3+0x4c>
f01046e2:	66 90                	xchg   %ax,%ax
f01046e4:	66 90                	xchg   %ax,%ax
f01046e6:	66 90                	xchg   %ax,%ax
f01046e8:	66 90                	xchg   %ax,%ax
f01046ea:	66 90                	xchg   %ax,%ax
f01046ec:	66 90                	xchg   %ax,%ax
f01046ee:	66 90                	xchg   %ax,%ax

f01046f0 <__umoddi3>:
f01046f0:	55                   	push   %ebp
f01046f1:	57                   	push   %edi
f01046f2:	56                   	push   %esi
f01046f3:	53                   	push   %ebx
f01046f4:	83 ec 1c             	sub    $0x1c,%esp
f01046f7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01046fb:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01046ff:	8b 74 24 34          	mov    0x34(%esp),%esi
f0104703:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0104707:	85 d2                	test   %edx,%edx
f0104709:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010470d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104711:	89 f3                	mov    %esi,%ebx
f0104713:	89 3c 24             	mov    %edi,(%esp)
f0104716:	89 74 24 04          	mov    %esi,0x4(%esp)
f010471a:	75 1c                	jne    f0104738 <__umoddi3+0x48>
f010471c:	39 f7                	cmp    %esi,%edi
f010471e:	76 50                	jbe    f0104770 <__umoddi3+0x80>
f0104720:	89 c8                	mov    %ecx,%eax
f0104722:	89 f2                	mov    %esi,%edx
f0104724:	f7 f7                	div    %edi
f0104726:	89 d0                	mov    %edx,%eax
f0104728:	31 d2                	xor    %edx,%edx
f010472a:	83 c4 1c             	add    $0x1c,%esp
f010472d:	5b                   	pop    %ebx
f010472e:	5e                   	pop    %esi
f010472f:	5f                   	pop    %edi
f0104730:	5d                   	pop    %ebp
f0104731:	c3                   	ret    
f0104732:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104738:	39 f2                	cmp    %esi,%edx
f010473a:	89 d0                	mov    %edx,%eax
f010473c:	77 52                	ja     f0104790 <__umoddi3+0xa0>
f010473e:	0f bd ea             	bsr    %edx,%ebp
f0104741:	83 f5 1f             	xor    $0x1f,%ebp
f0104744:	75 5a                	jne    f01047a0 <__umoddi3+0xb0>
f0104746:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010474a:	0f 82 e0 00 00 00    	jb     f0104830 <__umoddi3+0x140>
f0104750:	39 0c 24             	cmp    %ecx,(%esp)
f0104753:	0f 86 d7 00 00 00    	jbe    f0104830 <__umoddi3+0x140>
f0104759:	8b 44 24 08          	mov    0x8(%esp),%eax
f010475d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0104761:	83 c4 1c             	add    $0x1c,%esp
f0104764:	5b                   	pop    %ebx
f0104765:	5e                   	pop    %esi
f0104766:	5f                   	pop    %edi
f0104767:	5d                   	pop    %ebp
f0104768:	c3                   	ret    
f0104769:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104770:	85 ff                	test   %edi,%edi
f0104772:	89 fd                	mov    %edi,%ebp
f0104774:	75 0b                	jne    f0104781 <__umoddi3+0x91>
f0104776:	b8 01 00 00 00       	mov    $0x1,%eax
f010477b:	31 d2                	xor    %edx,%edx
f010477d:	f7 f7                	div    %edi
f010477f:	89 c5                	mov    %eax,%ebp
f0104781:	89 f0                	mov    %esi,%eax
f0104783:	31 d2                	xor    %edx,%edx
f0104785:	f7 f5                	div    %ebp
f0104787:	89 c8                	mov    %ecx,%eax
f0104789:	f7 f5                	div    %ebp
f010478b:	89 d0                	mov    %edx,%eax
f010478d:	eb 99                	jmp    f0104728 <__umoddi3+0x38>
f010478f:	90                   	nop
f0104790:	89 c8                	mov    %ecx,%eax
f0104792:	89 f2                	mov    %esi,%edx
f0104794:	83 c4 1c             	add    $0x1c,%esp
f0104797:	5b                   	pop    %ebx
f0104798:	5e                   	pop    %esi
f0104799:	5f                   	pop    %edi
f010479a:	5d                   	pop    %ebp
f010479b:	c3                   	ret    
f010479c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01047a0:	8b 34 24             	mov    (%esp),%esi
f01047a3:	bf 20 00 00 00       	mov    $0x20,%edi
f01047a8:	89 e9                	mov    %ebp,%ecx
f01047aa:	29 ef                	sub    %ebp,%edi
f01047ac:	d3 e0                	shl    %cl,%eax
f01047ae:	89 f9                	mov    %edi,%ecx
f01047b0:	89 f2                	mov    %esi,%edx
f01047b2:	d3 ea                	shr    %cl,%edx
f01047b4:	89 e9                	mov    %ebp,%ecx
f01047b6:	09 c2                	or     %eax,%edx
f01047b8:	89 d8                	mov    %ebx,%eax
f01047ba:	89 14 24             	mov    %edx,(%esp)
f01047bd:	89 f2                	mov    %esi,%edx
f01047bf:	d3 e2                	shl    %cl,%edx
f01047c1:	89 f9                	mov    %edi,%ecx
f01047c3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01047c7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01047cb:	d3 e8                	shr    %cl,%eax
f01047cd:	89 e9                	mov    %ebp,%ecx
f01047cf:	89 c6                	mov    %eax,%esi
f01047d1:	d3 e3                	shl    %cl,%ebx
f01047d3:	89 f9                	mov    %edi,%ecx
f01047d5:	89 d0                	mov    %edx,%eax
f01047d7:	d3 e8                	shr    %cl,%eax
f01047d9:	89 e9                	mov    %ebp,%ecx
f01047db:	09 d8                	or     %ebx,%eax
f01047dd:	89 d3                	mov    %edx,%ebx
f01047df:	89 f2                	mov    %esi,%edx
f01047e1:	f7 34 24             	divl   (%esp)
f01047e4:	89 d6                	mov    %edx,%esi
f01047e6:	d3 e3                	shl    %cl,%ebx
f01047e8:	f7 64 24 04          	mull   0x4(%esp)
f01047ec:	39 d6                	cmp    %edx,%esi
f01047ee:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01047f2:	89 d1                	mov    %edx,%ecx
f01047f4:	89 c3                	mov    %eax,%ebx
f01047f6:	72 08                	jb     f0104800 <__umoddi3+0x110>
f01047f8:	75 11                	jne    f010480b <__umoddi3+0x11b>
f01047fa:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01047fe:	73 0b                	jae    f010480b <__umoddi3+0x11b>
f0104800:	2b 44 24 04          	sub    0x4(%esp),%eax
f0104804:	1b 14 24             	sbb    (%esp),%edx
f0104807:	89 d1                	mov    %edx,%ecx
f0104809:	89 c3                	mov    %eax,%ebx
f010480b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010480f:	29 da                	sub    %ebx,%edx
f0104811:	19 ce                	sbb    %ecx,%esi
f0104813:	89 f9                	mov    %edi,%ecx
f0104815:	89 f0                	mov    %esi,%eax
f0104817:	d3 e0                	shl    %cl,%eax
f0104819:	89 e9                	mov    %ebp,%ecx
f010481b:	d3 ea                	shr    %cl,%edx
f010481d:	89 e9                	mov    %ebp,%ecx
f010481f:	d3 ee                	shr    %cl,%esi
f0104821:	09 d0                	or     %edx,%eax
f0104823:	89 f2                	mov    %esi,%edx
f0104825:	83 c4 1c             	add    $0x1c,%esp
f0104828:	5b                   	pop    %ebx
f0104829:	5e                   	pop    %esi
f010482a:	5f                   	pop    %edi
f010482b:	5d                   	pop    %ebp
f010482c:	c3                   	ret    
f010482d:	8d 76 00             	lea    0x0(%esi),%esi
f0104830:	29 f9                	sub    %edi,%ecx
f0104832:	19 d6                	sbb    %edx,%esi
f0104834:	89 74 24 04          	mov    %esi,0x4(%esp)
f0104838:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010483c:	e9 18 ff ff ff       	jmp    f0104759 <__umoddi3+0x69>
