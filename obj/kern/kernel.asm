
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
f0100015:	b8 00 e0 11 00       	mov    $0x11e000,%eax
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
f0100034:	bc 00 e0 11 f0       	mov    $0xf011e000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 5c 00 00 00       	call   f010009a <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	56                   	push   %esi
f0100044:	53                   	push   %ebx
f0100045:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100048:	83 3d 80 fe 22 f0 00 	cmpl   $0x0,0xf022fe80
f010004f:	75 3a                	jne    f010008b <_panic+0x4b>
		goto dead;
	panicstr = fmt;
f0100051:	89 35 80 fe 22 f0    	mov    %esi,0xf022fe80

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f0100057:	fa                   	cli    
f0100058:	fc                   	cld    

	va_start(ap, fmt);
f0100059:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic on CPU %d at %s:%d: ", cpunum(), file, line);
f010005c:	e8 e9 5b 00 00       	call   f0105c4a <cpunum>
f0100061:	ff 75 0c             	pushl  0xc(%ebp)
f0100064:	ff 75 08             	pushl  0x8(%ebp)
f0100067:	50                   	push   %eax
f0100068:	68 e0 62 10 f0       	push   $0xf01062e0
f010006d:	e8 b2 36 00 00       	call   f0103724 <cprintf>
	vcprintf(fmt, ap);
f0100072:	83 c4 08             	add    $0x8,%esp
f0100075:	53                   	push   %ebx
f0100076:	56                   	push   %esi
f0100077:	e8 82 36 00 00       	call   f01036fe <vcprintf>
	cprintf("\n");
f010007c:	c7 04 24 94 6b 10 f0 	movl   $0xf0106b94,(%esp)
f0100083:	e8 9c 36 00 00       	call   f0103724 <cprintf>
	va_end(ap);
f0100088:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010008b:	83 ec 0c             	sub    $0xc,%esp
f010008e:	6a 00                	push   $0x0
f0100090:	e8 6d 08 00 00       	call   f0100902 <monitor>
f0100095:	83 c4 10             	add    $0x10,%esp
f0100098:	eb f1                	jmp    f010008b <_panic+0x4b>

f010009a <i386_init>:
static void boot_aps(void);


void
i386_init(void)
{
f010009a:	55                   	push   %ebp
f010009b:	89 e5                	mov    %esp,%ebp
f010009d:	53                   	push   %ebx
f010009e:	83 ec 08             	sub    $0x8,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a1:	b8 08 10 27 f0       	mov    $0xf0271008,%eax
f01000a6:	2d 28 e6 22 f0       	sub    $0xf022e628,%eax
f01000ab:	50                   	push   %eax
f01000ac:	6a 00                	push   $0x0
f01000ae:	68 28 e6 22 f0       	push   $0xf022e628
f01000b3:	e8 70 55 00 00       	call   f0105628 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b8:	e8 74 05 00 00       	call   f0100631 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000bd:	83 c4 08             	add    $0x8,%esp
f01000c0:	68 ac 1a 00 00       	push   $0x1aac
f01000c5:	68 4c 63 10 f0       	push   $0xf010634c
f01000ca:	e8 55 36 00 00       	call   f0103724 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f01000cf:	e8 24 12 00 00       	call   f01012f8 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f01000d4:	e8 7c 2e 00 00       	call   f0102f55 <env_init>
	trap_init();
f01000d9:	e8 19 37 00 00       	call   f01037f7 <trap_init>

	// Lab 4 multiprocessor initialization functions
	mp_init();
f01000de:	e8 5d 58 00 00       	call   f0105940 <mp_init>
	lapic_init();
f01000e3:	e8 7d 5b 00 00       	call   f0105c65 <lapic_init>

	// Lab 4 multitasking initialization functions
	pic_init();
f01000e8:	e8 5e 35 00 00       	call   f010364b <pic_init>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f01000ed:	c7 04 24 c0 03 12 f0 	movl   $0xf01203c0,(%esp)
f01000f4:	e8 bf 5d 00 00       	call   f0105eb8 <spin_lock>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01000f9:	83 c4 10             	add    $0x10,%esp
f01000fc:	83 3d 88 fe 22 f0 07 	cmpl   $0x7,0xf022fe88
f0100103:	77 16                	ja     f010011b <i386_init+0x81>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100105:	68 00 70 00 00       	push   $0x7000
f010010a:	68 04 63 10 f0       	push   $0xf0106304
f010010f:	6a 56                	push   $0x56
f0100111:	68 67 63 10 f0       	push   $0xf0106367
f0100116:	e8 25 ff ff ff       	call   f0100040 <_panic>
	void *code;
	struct CpuInfo *c;

	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
f010011b:	83 ec 04             	sub    $0x4,%esp
f010011e:	b8 a6 58 10 f0       	mov    $0xf01058a6,%eax
f0100123:	2d 2c 58 10 f0       	sub    $0xf010582c,%eax
f0100128:	50                   	push   %eax
f0100129:	68 2c 58 10 f0       	push   $0xf010582c
f010012e:	68 00 70 00 f0       	push   $0xf0007000
f0100133:	e8 3d 55 00 00       	call   f0105675 <memmove>
f0100138:	83 c4 10             	add    $0x10,%esp

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f010013b:	bb 20 00 23 f0       	mov    $0xf0230020,%ebx
f0100140:	eb 4d                	jmp    f010018f <i386_init+0xf5>
		if (c == cpus + cpunum())  // We've started already.
f0100142:	e8 03 5b 00 00       	call   f0105c4a <cpunum>
f0100147:	6b c0 74             	imul   $0x74,%eax,%eax
f010014a:	05 20 00 23 f0       	add    $0xf0230020,%eax
f010014f:	39 c3                	cmp    %eax,%ebx
f0100151:	74 39                	je     f010018c <i386_init+0xf2>
			continue;

		// Tell mpentry.S what stack to use 
		mpentry_kstack = percpu_kstacks[c - cpus] + KSTKSIZE;
f0100153:	89 d8                	mov    %ebx,%eax
f0100155:	2d 20 00 23 f0       	sub    $0xf0230020,%eax
f010015a:	c1 f8 02             	sar    $0x2,%eax
f010015d:	69 c0 35 c2 72 4f    	imul   $0x4f72c235,%eax,%eax
f0100163:	c1 e0 0f             	shl    $0xf,%eax
f0100166:	05 00 90 23 f0       	add    $0xf0239000,%eax
f010016b:	a3 84 fe 22 f0       	mov    %eax,0xf022fe84
		// Start the CPU at mpentry_start
		lapic_startap(c->cpu_id, PADDR(code));
f0100170:	83 ec 08             	sub    $0x8,%esp
f0100173:	68 00 70 00 00       	push   $0x7000
f0100178:	0f b6 03             	movzbl (%ebx),%eax
f010017b:	50                   	push   %eax
f010017c:	e8 32 5c 00 00       	call   f0105db3 <lapic_startap>
f0100181:	83 c4 10             	add    $0x10,%esp
		// Wait for the CPU to finish some basic setup in mp_main()
		while(c->cpu_status != CPU_STARTED)
f0100184:	8b 43 04             	mov    0x4(%ebx),%eax
f0100187:	83 f8 01             	cmp    $0x1,%eax
f010018a:	75 f8                	jne    f0100184 <i386_init+0xea>
	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f010018c:	83 c3 74             	add    $0x74,%ebx
f010018f:	6b 05 c4 03 23 f0 74 	imul   $0x74,0xf02303c4,%eax
f0100196:	05 20 00 23 f0       	add    $0xf0230020,%eax
f010019b:	39 c3                	cmp    %eax,%ebx
f010019d:	72 a3                	jb     f0100142 <i386_init+0xa8>
	// Starting non-boot CPUs
	boot_aps();

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f010019f:	83 ec 08             	sub    $0x8,%esp
f01001a2:	6a 00                	push   $0x0
f01001a4:	68 fc 4b 22 f0       	push   $0xf0224bfc
f01001a9:	e8 7a 2f 00 00       	call   f0103128 <env_create>
	ENV_CREATE(user_yield, ENV_TYPE_USER);
	ENV_CREATE(user_yield, ENV_TYPE_USER);
#endif // TEST*

	// Schedule and run the first user environment!
	sched_yield();
f01001ae:	e8 44 43 00 00       	call   f01044f7 <sched_yield>

f01001b3 <mp_main>:
}

// Setup code for APs
void
mp_main(void)
{
f01001b3:	55                   	push   %ebp
f01001b4:	89 e5                	mov    %esp,%ebp
f01001b6:	83 ec 08             	sub    $0x8,%esp
	// We are in high EIP now, safe to switch to kern_pgdir 
	lcr3(PADDR(kern_pgdir));
f01001b9:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01001be:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01001c3:	77 12                	ja     f01001d7 <mp_main+0x24>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01001c5:	50                   	push   %eax
f01001c6:	68 28 63 10 f0       	push   $0xf0106328
f01001cb:	6a 6d                	push   $0x6d
f01001cd:	68 67 63 10 f0       	push   $0xf0106367
f01001d2:	e8 69 fe ff ff       	call   f0100040 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01001d7:	05 00 00 00 10       	add    $0x10000000,%eax
f01001dc:	0f 22 d8             	mov    %eax,%cr3
	cprintf("SMP: CPU %d starting\n", cpunum());
f01001df:	e8 66 5a 00 00       	call   f0105c4a <cpunum>
f01001e4:	83 ec 08             	sub    $0x8,%esp
f01001e7:	50                   	push   %eax
f01001e8:	68 73 63 10 f0       	push   $0xf0106373
f01001ed:	e8 32 35 00 00       	call   f0103724 <cprintf>

	lapic_init();
f01001f2:	e8 6e 5a 00 00       	call   f0105c65 <lapic_init>
	env_init_percpu();
f01001f7:	e8 29 2d 00 00       	call   f0102f25 <env_init_percpu>
	trap_init_percpu();
f01001fc:	e8 37 35 00 00       	call   f0103738 <trap_init_percpu>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f0100201:	e8 44 5a 00 00       	call   f0105c4a <cpunum>
f0100206:	6b d0 74             	imul   $0x74,%eax,%edx
f0100209:	81 c2 20 00 23 f0    	add    $0xf0230020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f010020f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100214:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0100218:	c7 04 24 c0 03 12 f0 	movl   $0xf01203c0,(%esp)
f010021f:	e8 94 5c 00 00       	call   f0105eb8 <spin_lock>
	// to start running processes on this CPU.  But make sure that
	// only one CPU can enter the scheduler at a time!
	//
	// Your code here:
	lock_kernel();
	sched_yield();
f0100224:	e8 ce 42 00 00       	call   f01044f7 <sched_yield>

f0100229 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100229:	55                   	push   %ebp
f010022a:	89 e5                	mov    %esp,%ebp
f010022c:	53                   	push   %ebx
f010022d:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100230:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100233:	ff 75 0c             	pushl  0xc(%ebp)
f0100236:	ff 75 08             	pushl  0x8(%ebp)
f0100239:	68 89 63 10 f0       	push   $0xf0106389
f010023e:	e8 e1 34 00 00       	call   f0103724 <cprintf>
	vcprintf(fmt, ap);
f0100243:	83 c4 08             	add    $0x8,%esp
f0100246:	53                   	push   %ebx
f0100247:	ff 75 10             	pushl  0x10(%ebp)
f010024a:	e8 af 34 00 00       	call   f01036fe <vcprintf>
	cprintf("\n");
f010024f:	c7 04 24 94 6b 10 f0 	movl   $0xf0106b94,(%esp)
f0100256:	e8 c9 34 00 00       	call   f0103724 <cprintf>
	va_end(ap);
}
f010025b:	83 c4 10             	add    $0x10,%esp
f010025e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100261:	c9                   	leave  
f0100262:	c3                   	ret    

f0100263 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100263:	55                   	push   %ebp
f0100264:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100266:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010026b:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010026c:	a8 01                	test   $0x1,%al
f010026e:	74 0b                	je     f010027b <serial_proc_data+0x18>
f0100270:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100275:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100276:	0f b6 c0             	movzbl %al,%eax
f0100279:	eb 05                	jmp    f0100280 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f010027b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100280:	5d                   	pop    %ebp
f0100281:	c3                   	ret    

f0100282 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100282:	55                   	push   %ebp
f0100283:	89 e5                	mov    %esp,%ebp
f0100285:	53                   	push   %ebx
f0100286:	83 ec 04             	sub    $0x4,%esp
f0100289:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f010028b:	eb 2b                	jmp    f01002b8 <cons_intr+0x36>
		if (c == 0)
f010028d:	85 c0                	test   %eax,%eax
f010028f:	74 27                	je     f01002b8 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f0100291:	8b 0d 24 f2 22 f0    	mov    0xf022f224,%ecx
f0100297:	8d 51 01             	lea    0x1(%ecx),%edx
f010029a:	89 15 24 f2 22 f0    	mov    %edx,0xf022f224
f01002a0:	88 81 20 f0 22 f0    	mov    %al,-0xfdd0fe0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f01002a6:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01002ac:	75 0a                	jne    f01002b8 <cons_intr+0x36>
			cons.wpos = 0;
f01002ae:	c7 05 24 f2 22 f0 00 	movl   $0x0,0xf022f224
f01002b5:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01002b8:	ff d3                	call   *%ebx
f01002ba:	83 f8 ff             	cmp    $0xffffffff,%eax
f01002bd:	75 ce                	jne    f010028d <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01002bf:	83 c4 04             	add    $0x4,%esp
f01002c2:	5b                   	pop    %ebx
f01002c3:	5d                   	pop    %ebp
f01002c4:	c3                   	ret    

f01002c5 <kbd_proc_data>:
f01002c5:	ba 64 00 00 00       	mov    $0x64,%edx
f01002ca:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01002cb:	a8 01                	test   $0x1,%al
f01002cd:	0f 84 f0 00 00 00    	je     f01003c3 <kbd_proc_data+0xfe>
f01002d3:	ba 60 00 00 00       	mov    $0x60,%edx
f01002d8:	ec                   	in     (%dx),%al
f01002d9:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01002db:	3c e0                	cmp    $0xe0,%al
f01002dd:	75 0d                	jne    f01002ec <kbd_proc_data+0x27>
		// E0 escape character
		shift |= E0ESC;
f01002df:	83 0d 00 f0 22 f0 40 	orl    $0x40,0xf022f000
		return 0;
f01002e6:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01002eb:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01002ec:	55                   	push   %ebp
f01002ed:	89 e5                	mov    %esp,%ebp
f01002ef:	53                   	push   %ebx
f01002f0:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01002f3:	84 c0                	test   %al,%al
f01002f5:	79 36                	jns    f010032d <kbd_proc_data+0x68>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01002f7:	8b 0d 00 f0 22 f0    	mov    0xf022f000,%ecx
f01002fd:	89 cb                	mov    %ecx,%ebx
f01002ff:	83 e3 40             	and    $0x40,%ebx
f0100302:	83 e0 7f             	and    $0x7f,%eax
f0100305:	85 db                	test   %ebx,%ebx
f0100307:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f010030a:	0f b6 d2             	movzbl %dl,%edx
f010030d:	0f b6 82 00 65 10 f0 	movzbl -0xfef9b00(%edx),%eax
f0100314:	83 c8 40             	or     $0x40,%eax
f0100317:	0f b6 c0             	movzbl %al,%eax
f010031a:	f7 d0                	not    %eax
f010031c:	21 c8                	and    %ecx,%eax
f010031e:	a3 00 f0 22 f0       	mov    %eax,0xf022f000
		return 0;
f0100323:	b8 00 00 00 00       	mov    $0x0,%eax
f0100328:	e9 9e 00 00 00       	jmp    f01003cb <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f010032d:	8b 0d 00 f0 22 f0    	mov    0xf022f000,%ecx
f0100333:	f6 c1 40             	test   $0x40,%cl
f0100336:	74 0e                	je     f0100346 <kbd_proc_data+0x81>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100338:	83 c8 80             	or     $0xffffff80,%eax
f010033b:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010033d:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100340:	89 0d 00 f0 22 f0    	mov    %ecx,0xf022f000
	}

	shift |= shiftcode[data];
f0100346:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100349:	0f b6 82 00 65 10 f0 	movzbl -0xfef9b00(%edx),%eax
f0100350:	0b 05 00 f0 22 f0    	or     0xf022f000,%eax
f0100356:	0f b6 8a 00 64 10 f0 	movzbl -0xfef9c00(%edx),%ecx
f010035d:	31 c8                	xor    %ecx,%eax
f010035f:	a3 00 f0 22 f0       	mov    %eax,0xf022f000

	c = charcode[shift & (CTL | SHIFT)][data];
f0100364:	89 c1                	mov    %eax,%ecx
f0100366:	83 e1 03             	and    $0x3,%ecx
f0100369:	8b 0c 8d e0 63 10 f0 	mov    -0xfef9c20(,%ecx,4),%ecx
f0100370:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100374:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100377:	a8 08                	test   $0x8,%al
f0100379:	74 1b                	je     f0100396 <kbd_proc_data+0xd1>
		if ('a' <= c && c <= 'z')
f010037b:	89 da                	mov    %ebx,%edx
f010037d:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100380:	83 f9 19             	cmp    $0x19,%ecx
f0100383:	77 05                	ja     f010038a <kbd_proc_data+0xc5>
			c += 'A' - 'a';
f0100385:	83 eb 20             	sub    $0x20,%ebx
f0100388:	eb 0c                	jmp    f0100396 <kbd_proc_data+0xd1>
		else if ('A' <= c && c <= 'Z')
f010038a:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f010038d:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100390:	83 fa 19             	cmp    $0x19,%edx
f0100393:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100396:	f7 d0                	not    %eax
f0100398:	a8 06                	test   $0x6,%al
f010039a:	75 2d                	jne    f01003c9 <kbd_proc_data+0x104>
f010039c:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01003a2:	75 25                	jne    f01003c9 <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f01003a4:	83 ec 0c             	sub    $0xc,%esp
f01003a7:	68 a3 63 10 f0       	push   $0xf01063a3
f01003ac:	e8 73 33 00 00       	call   f0103724 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003b1:	ba 92 00 00 00       	mov    $0x92,%edx
f01003b6:	b8 03 00 00 00       	mov    $0x3,%eax
f01003bb:	ee                   	out    %al,(%dx)
f01003bc:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01003bf:	89 d8                	mov    %ebx,%eax
f01003c1:	eb 08                	jmp    f01003cb <kbd_proc_data+0x106>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01003c3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01003c8:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01003c9:	89 d8                	mov    %ebx,%eax
}
f01003cb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01003ce:	c9                   	leave  
f01003cf:	c3                   	ret    

f01003d0 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01003d0:	55                   	push   %ebp
f01003d1:	89 e5                	mov    %esp,%ebp
f01003d3:	57                   	push   %edi
f01003d4:	56                   	push   %esi
f01003d5:	53                   	push   %ebx
f01003d6:	83 ec 1c             	sub    $0x1c,%esp
f01003d9:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01003db:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003e0:	be fd 03 00 00       	mov    $0x3fd,%esi
f01003e5:	b9 84 00 00 00       	mov    $0x84,%ecx
f01003ea:	eb 09                	jmp    f01003f5 <cons_putc+0x25>
f01003ec:	89 ca                	mov    %ecx,%edx
f01003ee:	ec                   	in     (%dx),%al
f01003ef:	ec                   	in     (%dx),%al
f01003f0:	ec                   	in     (%dx),%al
f01003f1:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01003f2:	83 c3 01             	add    $0x1,%ebx
f01003f5:	89 f2                	mov    %esi,%edx
f01003f7:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01003f8:	a8 20                	test   $0x20,%al
f01003fa:	75 08                	jne    f0100404 <cons_putc+0x34>
f01003fc:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100402:	7e e8                	jle    f01003ec <cons_putc+0x1c>
f0100404:	89 f8                	mov    %edi,%eax
f0100406:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100409:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010040e:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010040f:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100414:	be 79 03 00 00       	mov    $0x379,%esi
f0100419:	b9 84 00 00 00       	mov    $0x84,%ecx
f010041e:	eb 09                	jmp    f0100429 <cons_putc+0x59>
f0100420:	89 ca                	mov    %ecx,%edx
f0100422:	ec                   	in     (%dx),%al
f0100423:	ec                   	in     (%dx),%al
f0100424:	ec                   	in     (%dx),%al
f0100425:	ec                   	in     (%dx),%al
f0100426:	83 c3 01             	add    $0x1,%ebx
f0100429:	89 f2                	mov    %esi,%edx
f010042b:	ec                   	in     (%dx),%al
f010042c:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100432:	7f 04                	jg     f0100438 <cons_putc+0x68>
f0100434:	84 c0                	test   %al,%al
f0100436:	79 e8                	jns    f0100420 <cons_putc+0x50>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100438:	ba 78 03 00 00       	mov    $0x378,%edx
f010043d:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100441:	ee                   	out    %al,(%dx)
f0100442:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100447:	b8 0d 00 00 00       	mov    $0xd,%eax
f010044c:	ee                   	out    %al,(%dx)
f010044d:	b8 08 00 00 00       	mov    $0x8,%eax
f0100452:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100453:	89 fa                	mov    %edi,%edx
f0100455:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010045b:	89 f8                	mov    %edi,%eax
f010045d:	80 cc 07             	or     $0x7,%ah
f0100460:	85 d2                	test   %edx,%edx
f0100462:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100465:	89 f8                	mov    %edi,%eax
f0100467:	0f b6 c0             	movzbl %al,%eax
f010046a:	83 f8 09             	cmp    $0x9,%eax
f010046d:	74 74                	je     f01004e3 <cons_putc+0x113>
f010046f:	83 f8 09             	cmp    $0x9,%eax
f0100472:	7f 0a                	jg     f010047e <cons_putc+0xae>
f0100474:	83 f8 08             	cmp    $0x8,%eax
f0100477:	74 14                	je     f010048d <cons_putc+0xbd>
f0100479:	e9 99 00 00 00       	jmp    f0100517 <cons_putc+0x147>
f010047e:	83 f8 0a             	cmp    $0xa,%eax
f0100481:	74 3a                	je     f01004bd <cons_putc+0xed>
f0100483:	83 f8 0d             	cmp    $0xd,%eax
f0100486:	74 3d                	je     f01004c5 <cons_putc+0xf5>
f0100488:	e9 8a 00 00 00       	jmp    f0100517 <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f010048d:	0f b7 05 28 f2 22 f0 	movzwl 0xf022f228,%eax
f0100494:	66 85 c0             	test   %ax,%ax
f0100497:	0f 84 e6 00 00 00    	je     f0100583 <cons_putc+0x1b3>
			crt_pos--;
f010049d:	83 e8 01             	sub    $0x1,%eax
f01004a0:	66 a3 28 f2 22 f0    	mov    %ax,0xf022f228
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01004a6:	0f b7 c0             	movzwl %ax,%eax
f01004a9:	66 81 e7 00 ff       	and    $0xff00,%di
f01004ae:	83 cf 20             	or     $0x20,%edi
f01004b1:	8b 15 2c f2 22 f0    	mov    0xf022f22c,%edx
f01004b7:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01004bb:	eb 78                	jmp    f0100535 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01004bd:	66 83 05 28 f2 22 f0 	addw   $0x50,0xf022f228
f01004c4:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01004c5:	0f b7 05 28 f2 22 f0 	movzwl 0xf022f228,%eax
f01004cc:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01004d2:	c1 e8 16             	shr    $0x16,%eax
f01004d5:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01004d8:	c1 e0 04             	shl    $0x4,%eax
f01004db:	66 a3 28 f2 22 f0    	mov    %ax,0xf022f228
f01004e1:	eb 52                	jmp    f0100535 <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f01004e3:	b8 20 00 00 00       	mov    $0x20,%eax
f01004e8:	e8 e3 fe ff ff       	call   f01003d0 <cons_putc>
		cons_putc(' ');
f01004ed:	b8 20 00 00 00       	mov    $0x20,%eax
f01004f2:	e8 d9 fe ff ff       	call   f01003d0 <cons_putc>
		cons_putc(' ');
f01004f7:	b8 20 00 00 00       	mov    $0x20,%eax
f01004fc:	e8 cf fe ff ff       	call   f01003d0 <cons_putc>
		cons_putc(' ');
f0100501:	b8 20 00 00 00       	mov    $0x20,%eax
f0100506:	e8 c5 fe ff ff       	call   f01003d0 <cons_putc>
		cons_putc(' ');
f010050b:	b8 20 00 00 00       	mov    $0x20,%eax
f0100510:	e8 bb fe ff ff       	call   f01003d0 <cons_putc>
f0100515:	eb 1e                	jmp    f0100535 <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100517:	0f b7 05 28 f2 22 f0 	movzwl 0xf022f228,%eax
f010051e:	8d 50 01             	lea    0x1(%eax),%edx
f0100521:	66 89 15 28 f2 22 f0 	mov    %dx,0xf022f228
f0100528:	0f b7 c0             	movzwl %ax,%eax
f010052b:	8b 15 2c f2 22 f0    	mov    0xf022f22c,%edx
f0100531:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100535:	66 81 3d 28 f2 22 f0 	cmpw   $0x7cf,0xf022f228
f010053c:	cf 07 
f010053e:	76 43                	jbe    f0100583 <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100540:	a1 2c f2 22 f0       	mov    0xf022f22c,%eax
f0100545:	83 ec 04             	sub    $0x4,%esp
f0100548:	68 00 0f 00 00       	push   $0xf00
f010054d:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100553:	52                   	push   %edx
f0100554:	50                   	push   %eax
f0100555:	e8 1b 51 00 00       	call   f0105675 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010055a:	8b 15 2c f2 22 f0    	mov    0xf022f22c,%edx
f0100560:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100566:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f010056c:	83 c4 10             	add    $0x10,%esp
f010056f:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100574:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100577:	39 d0                	cmp    %edx,%eax
f0100579:	75 f4                	jne    f010056f <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010057b:	66 83 2d 28 f2 22 f0 	subw   $0x50,0xf022f228
f0100582:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100583:	8b 0d 30 f2 22 f0    	mov    0xf022f230,%ecx
f0100589:	b8 0e 00 00 00       	mov    $0xe,%eax
f010058e:	89 ca                	mov    %ecx,%edx
f0100590:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100591:	0f b7 1d 28 f2 22 f0 	movzwl 0xf022f228,%ebx
f0100598:	8d 71 01             	lea    0x1(%ecx),%esi
f010059b:	89 d8                	mov    %ebx,%eax
f010059d:	66 c1 e8 08          	shr    $0x8,%ax
f01005a1:	89 f2                	mov    %esi,%edx
f01005a3:	ee                   	out    %al,(%dx)
f01005a4:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005a9:	89 ca                	mov    %ecx,%edx
f01005ab:	ee                   	out    %al,(%dx)
f01005ac:	89 d8                	mov    %ebx,%eax
f01005ae:	89 f2                	mov    %esi,%edx
f01005b0:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01005b1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01005b4:	5b                   	pop    %ebx
f01005b5:	5e                   	pop    %esi
f01005b6:	5f                   	pop    %edi
f01005b7:	5d                   	pop    %ebp
f01005b8:	c3                   	ret    

f01005b9 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01005b9:	80 3d 34 f2 22 f0 00 	cmpb   $0x0,0xf022f234
f01005c0:	74 11                	je     f01005d3 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01005c2:	55                   	push   %ebp
f01005c3:	89 e5                	mov    %esp,%ebp
f01005c5:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01005c8:	b8 63 02 10 f0       	mov    $0xf0100263,%eax
f01005cd:	e8 b0 fc ff ff       	call   f0100282 <cons_intr>
}
f01005d2:	c9                   	leave  
f01005d3:	f3 c3                	repz ret 

f01005d5 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01005d5:	55                   	push   %ebp
f01005d6:	89 e5                	mov    %esp,%ebp
f01005d8:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01005db:	b8 c5 02 10 f0       	mov    $0xf01002c5,%eax
f01005e0:	e8 9d fc ff ff       	call   f0100282 <cons_intr>
}
f01005e5:	c9                   	leave  
f01005e6:	c3                   	ret    

f01005e7 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01005e7:	55                   	push   %ebp
f01005e8:	89 e5                	mov    %esp,%ebp
f01005ea:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01005ed:	e8 c7 ff ff ff       	call   f01005b9 <serial_intr>
	kbd_intr();
f01005f2:	e8 de ff ff ff       	call   f01005d5 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01005f7:	a1 20 f2 22 f0       	mov    0xf022f220,%eax
f01005fc:	3b 05 24 f2 22 f0    	cmp    0xf022f224,%eax
f0100602:	74 26                	je     f010062a <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100604:	8d 50 01             	lea    0x1(%eax),%edx
f0100607:	89 15 20 f2 22 f0    	mov    %edx,0xf022f220
f010060d:	0f b6 88 20 f0 22 f0 	movzbl -0xfdd0fe0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100614:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100616:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010061c:	75 11                	jne    f010062f <cons_getc+0x48>
			cons.rpos = 0;
f010061e:	c7 05 20 f2 22 f0 00 	movl   $0x0,0xf022f220
f0100625:	00 00 00 
f0100628:	eb 05                	jmp    f010062f <cons_getc+0x48>
		return c;
	}
	return 0;
f010062a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010062f:	c9                   	leave  
f0100630:	c3                   	ret    

f0100631 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100631:	55                   	push   %ebp
f0100632:	89 e5                	mov    %esp,%ebp
f0100634:	57                   	push   %edi
f0100635:	56                   	push   %esi
f0100636:	53                   	push   %ebx
f0100637:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f010063a:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100641:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100648:	5a a5 
	if (*cp != 0xA55A) {
f010064a:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100651:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100655:	74 11                	je     f0100668 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100657:	c7 05 30 f2 22 f0 b4 	movl   $0x3b4,0xf022f230
f010065e:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100661:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100666:	eb 16                	jmp    f010067e <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100668:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010066f:	c7 05 30 f2 22 f0 d4 	movl   $0x3d4,0xf022f230
f0100676:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100679:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010067e:	8b 3d 30 f2 22 f0    	mov    0xf022f230,%edi
f0100684:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100689:	89 fa                	mov    %edi,%edx
f010068b:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010068c:	8d 5f 01             	lea    0x1(%edi),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010068f:	89 da                	mov    %ebx,%edx
f0100691:	ec                   	in     (%dx),%al
f0100692:	0f b6 c8             	movzbl %al,%ecx
f0100695:	c1 e1 08             	shl    $0x8,%ecx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100698:	b8 0f 00 00 00       	mov    $0xf,%eax
f010069d:	89 fa                	mov    %edi,%edx
f010069f:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006a0:	89 da                	mov    %ebx,%edx
f01006a2:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01006a3:	89 35 2c f2 22 f0    	mov    %esi,0xf022f22c
	crt_pos = pos;
f01006a9:	0f b6 c0             	movzbl %al,%eax
f01006ac:	09 c8                	or     %ecx,%eax
f01006ae:	66 a3 28 f2 22 f0    	mov    %ax,0xf022f228

static void
kbd_init(void)
{
	// Drain the kbd buffer so that QEMU generates interrupts.
	kbd_intr();
f01006b4:	e8 1c ff ff ff       	call   f01005d5 <kbd_intr>
	irq_setmask_8259A(irq_mask_8259A & ~(1<<1));
f01006b9:	83 ec 0c             	sub    $0xc,%esp
f01006bc:	0f b7 05 a8 03 12 f0 	movzwl 0xf01203a8,%eax
f01006c3:	25 fd ff 00 00       	and    $0xfffd,%eax
f01006c8:	50                   	push   %eax
f01006c9:	e8 05 2f 00 00       	call   f01035d3 <irq_setmask_8259A>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006ce:	be fa 03 00 00       	mov    $0x3fa,%esi
f01006d3:	b8 00 00 00 00       	mov    $0x0,%eax
f01006d8:	89 f2                	mov    %esi,%edx
f01006da:	ee                   	out    %al,(%dx)
f01006db:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01006e0:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01006e5:	ee                   	out    %al,(%dx)
f01006e6:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01006eb:	b8 0c 00 00 00       	mov    $0xc,%eax
f01006f0:	89 da                	mov    %ebx,%edx
f01006f2:	ee                   	out    %al,(%dx)
f01006f3:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01006f8:	b8 00 00 00 00       	mov    $0x0,%eax
f01006fd:	ee                   	out    %al,(%dx)
f01006fe:	ba fb 03 00 00       	mov    $0x3fb,%edx
f0100703:	b8 03 00 00 00       	mov    $0x3,%eax
f0100708:	ee                   	out    %al,(%dx)
f0100709:	ba fc 03 00 00       	mov    $0x3fc,%edx
f010070e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100713:	ee                   	out    %al,(%dx)
f0100714:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100719:	b8 01 00 00 00       	mov    $0x1,%eax
f010071e:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010071f:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100724:	ec                   	in     (%dx),%al
f0100725:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100727:	83 c4 10             	add    $0x10,%esp
f010072a:	3c ff                	cmp    $0xff,%al
f010072c:	0f 95 05 34 f2 22 f0 	setne  0xf022f234
f0100733:	89 f2                	mov    %esi,%edx
f0100735:	ec                   	in     (%dx),%al
f0100736:	89 da                	mov    %ebx,%edx
f0100738:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100739:	80 f9 ff             	cmp    $0xff,%cl
f010073c:	75 10                	jne    f010074e <cons_init+0x11d>
		cprintf("Serial port does not exist!\n");
f010073e:	83 ec 0c             	sub    $0xc,%esp
f0100741:	68 af 63 10 f0       	push   $0xf01063af
f0100746:	e8 d9 2f 00 00       	call   f0103724 <cprintf>
f010074b:	83 c4 10             	add    $0x10,%esp
}
f010074e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100751:	5b                   	pop    %ebx
f0100752:	5e                   	pop    %esi
f0100753:	5f                   	pop    %edi
f0100754:	5d                   	pop    %ebp
f0100755:	c3                   	ret    

f0100756 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100756:	55                   	push   %ebp
f0100757:	89 e5                	mov    %esp,%ebp
f0100759:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010075c:	8b 45 08             	mov    0x8(%ebp),%eax
f010075f:	e8 6c fc ff ff       	call   f01003d0 <cons_putc>
}
f0100764:	c9                   	leave  
f0100765:	c3                   	ret    

f0100766 <getchar>:

int
getchar(void)
{
f0100766:	55                   	push   %ebp
f0100767:	89 e5                	mov    %esp,%ebp
f0100769:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010076c:	e8 76 fe ff ff       	call   f01005e7 <cons_getc>
f0100771:	85 c0                	test   %eax,%eax
f0100773:	74 f7                	je     f010076c <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100775:	c9                   	leave  
f0100776:	c3                   	ret    

f0100777 <iscons>:

int
iscons(int fdnum)
{
f0100777:	55                   	push   %ebp
f0100778:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f010077a:	b8 01 00 00 00       	mov    $0x1,%eax
f010077f:	5d                   	pop    %ebp
f0100780:	c3                   	ret    

f0100781 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100781:	55                   	push   %ebp
f0100782:	89 e5                	mov    %esp,%ebp
f0100784:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100787:	68 00 66 10 f0       	push   $0xf0106600
f010078c:	68 1e 66 10 f0       	push   $0xf010661e
f0100791:	68 23 66 10 f0       	push   $0xf0106623
f0100796:	e8 89 2f 00 00       	call   f0103724 <cprintf>
f010079b:	83 c4 0c             	add    $0xc,%esp
f010079e:	68 d4 66 10 f0       	push   $0xf01066d4
f01007a3:	68 2c 66 10 f0       	push   $0xf010662c
f01007a8:	68 23 66 10 f0       	push   $0xf0106623
f01007ad:	e8 72 2f 00 00       	call   f0103724 <cprintf>
f01007b2:	83 c4 0c             	add    $0xc,%esp
f01007b5:	68 35 66 10 f0       	push   $0xf0106635
f01007ba:	68 41 66 10 f0       	push   $0xf0106641
f01007bf:	68 23 66 10 f0       	push   $0xf0106623
f01007c4:	e8 5b 2f 00 00       	call   f0103724 <cprintf>
	return 0;
}
f01007c9:	b8 00 00 00 00       	mov    $0x0,%eax
f01007ce:	c9                   	leave  
f01007cf:	c3                   	ret    

f01007d0 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01007d0:	55                   	push   %ebp
f01007d1:	89 e5                	mov    %esp,%ebp
f01007d3:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01007d6:	68 4b 66 10 f0       	push   $0xf010664b
f01007db:	e8 44 2f 00 00       	call   f0103724 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007e0:	83 c4 08             	add    $0x8,%esp
f01007e3:	68 0c 00 10 00       	push   $0x10000c
f01007e8:	68 fc 66 10 f0       	push   $0xf01066fc
f01007ed:	e8 32 2f 00 00       	call   f0103724 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007f2:	83 c4 0c             	add    $0xc,%esp
f01007f5:	68 0c 00 10 00       	push   $0x10000c
f01007fa:	68 0c 00 10 f0       	push   $0xf010000c
f01007ff:	68 24 67 10 f0       	push   $0xf0106724
f0100804:	e8 1b 2f 00 00       	call   f0103724 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100809:	83 c4 0c             	add    $0xc,%esp
f010080c:	68 d1 62 10 00       	push   $0x1062d1
f0100811:	68 d1 62 10 f0       	push   $0xf01062d1
f0100816:	68 48 67 10 f0       	push   $0xf0106748
f010081b:	e8 04 2f 00 00       	call   f0103724 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100820:	83 c4 0c             	add    $0xc,%esp
f0100823:	68 28 e6 22 00       	push   $0x22e628
f0100828:	68 28 e6 22 f0       	push   $0xf022e628
f010082d:	68 6c 67 10 f0       	push   $0xf010676c
f0100832:	e8 ed 2e 00 00       	call   f0103724 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100837:	83 c4 0c             	add    $0xc,%esp
f010083a:	68 08 10 27 00       	push   $0x271008
f010083f:	68 08 10 27 f0       	push   $0xf0271008
f0100844:	68 90 67 10 f0       	push   $0xf0106790
f0100849:	e8 d6 2e 00 00       	call   f0103724 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010084e:	b8 07 14 27 f0       	mov    $0xf0271407,%eax
f0100853:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100858:	83 c4 08             	add    $0x8,%esp
f010085b:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f0100860:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100866:	85 c0                	test   %eax,%eax
f0100868:	0f 48 c2             	cmovs  %edx,%eax
f010086b:	c1 f8 0a             	sar    $0xa,%eax
f010086e:	50                   	push   %eax
f010086f:	68 b4 67 10 f0       	push   $0xf01067b4
f0100874:	e8 ab 2e 00 00       	call   f0103724 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100879:	b8 00 00 00 00       	mov    $0x0,%eax
f010087e:	c9                   	leave  
f010087f:	c3                   	ret    

f0100880 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100880:	55                   	push   %ebp
f0100881:	89 e5                	mov    %esp,%ebp
f0100883:	57                   	push   %edi
f0100884:	56                   	push   %esi
f0100885:	53                   	push   %ebx
f0100886:	83 ec 18             	sub    $0x18,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0100889:	89 e8                	mov    %ebp,%eax
	// Your code here.
	uint32_t *ebp = (uint32_t*)read_ebp(); 
f010088b:	89 c6                	mov    %eax,%esi
	uint32_t *eip = (uint32_t*)*(ebp + 1); 
f010088d:	8b 58 04             	mov    0x4(%eax),%ebx
	cprintf("Stack backtrace:");
f0100890:	68 64 66 10 f0       	push   $0xf0106664
f0100895:	e8 8a 2e 00 00       	call   f0103724 <cprintf>
	while(ebp != NULL){
f010089a:	83 c4 10             	add    $0x10,%esp
f010089d:	eb 52                	jmp    f01008f1 <mon_backtrace+0x71>
		cprintf("ebp %08x  eip %08x", ebp, eip);
f010089f:	83 ec 04             	sub    $0x4,%esp
f01008a2:	53                   	push   %ebx
f01008a3:	56                   	push   %esi
f01008a4:	68 75 66 10 f0       	push   $0xf0106675
f01008a9:	e8 76 2e 00 00       	call   f0103724 <cprintf>
		cprintf("    arg ");
f01008ae:	c7 04 24 88 66 10 f0 	movl   $0xf0106688,(%esp)
f01008b5:	e8 6a 2e 00 00       	call   f0103724 <cprintf>
f01008ba:	8d 5e 08             	lea    0x8(%esi),%ebx
f01008bd:	8d 7e 1c             	lea    0x1c(%esi),%edi
f01008c0:	83 c4 10             	add    $0x10,%esp
		for(int i = 0;i < 5;i++){
			cprintf("%08x ", *(ebp + i + 2));
f01008c3:	83 ec 08             	sub    $0x8,%esp
f01008c6:	ff 33                	pushl  (%ebx)
f01008c8:	68 91 66 10 f0       	push   $0xf0106691
f01008cd:	e8 52 2e 00 00       	call   f0103724 <cprintf>
f01008d2:	83 c3 04             	add    $0x4,%ebx
	uint32_t *eip = (uint32_t*)*(ebp + 1); 
	cprintf("Stack backtrace:");
	while(ebp != NULL){
		cprintf("ebp %08x  eip %08x", ebp, eip);
		cprintf("    arg ");
		for(int i = 0;i < 5;i++){
f01008d5:	83 c4 10             	add    $0x10,%esp
f01008d8:	39 fb                	cmp    %edi,%ebx
f01008da:	75 e7                	jne    f01008c3 <mon_backtrace+0x43>
			cprintf("%08x ", *(ebp + i + 2));
		}
		cprintf("\n");
f01008dc:	83 ec 0c             	sub    $0xc,%esp
f01008df:	68 94 6b 10 f0       	push   $0xf0106b94
f01008e4:	e8 3b 2e 00 00       	call   f0103724 <cprintf>
		ebp = (uint32_t*)(*ebp); 
f01008e9:	8b 36                	mov    (%esi),%esi
		eip = (uint32_t*)*(ebp + 1);
f01008eb:	8b 5e 04             	mov    0x4(%esi),%ebx
f01008ee:	83 c4 10             	add    $0x10,%esp
{
	// Your code here.
	uint32_t *ebp = (uint32_t*)read_ebp(); 
	uint32_t *eip = (uint32_t*)*(ebp + 1); 
	cprintf("Stack backtrace:");
	while(ebp != NULL){
f01008f1:	85 f6                	test   %esi,%esi
f01008f3:	75 aa                	jne    f010089f <mon_backtrace+0x1f>
		cprintf("\n");
		ebp = (uint32_t*)(*ebp); 
		eip = (uint32_t*)*(ebp + 1);
	}
	return 0;
}
f01008f5:	b8 00 00 00 00       	mov    $0x0,%eax
f01008fa:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008fd:	5b                   	pop    %ebx
f01008fe:	5e                   	pop    %esi
f01008ff:	5f                   	pop    %edi
f0100900:	5d                   	pop    %ebp
f0100901:	c3                   	ret    

f0100902 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100902:	55                   	push   %ebp
f0100903:	89 e5                	mov    %esp,%ebp
f0100905:	57                   	push   %edi
f0100906:	56                   	push   %esi
f0100907:	53                   	push   %ebx
f0100908:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010090b:	68 e0 67 10 f0       	push   $0xf01067e0
f0100910:	e8 0f 2e 00 00       	call   f0103724 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100915:	c7 04 24 04 68 10 f0 	movl   $0xf0106804,(%esp)
f010091c:	e8 03 2e 00 00       	call   f0103724 <cprintf>

	if (tf != NULL)
f0100921:	83 c4 10             	add    $0x10,%esp
f0100924:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100928:	74 0e                	je     f0100938 <monitor+0x36>
		print_trapframe(tf);
f010092a:	83 ec 0c             	sub    $0xc,%esp
f010092d:	ff 75 08             	pushl  0x8(%ebp)
f0100930:	e8 3e 35 00 00       	call   f0103e73 <print_trapframe>
f0100935:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f0100938:	83 ec 0c             	sub    $0xc,%esp
f010093b:	68 97 66 10 f0       	push   $0xf0106697
f0100940:	e8 8c 4a 00 00       	call   f01053d1 <readline>
f0100945:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100947:	83 c4 10             	add    $0x10,%esp
f010094a:	85 c0                	test   %eax,%eax
f010094c:	74 ea                	je     f0100938 <monitor+0x36>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f010094e:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100955:	be 00 00 00 00       	mov    $0x0,%esi
f010095a:	eb 0a                	jmp    f0100966 <monitor+0x64>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010095c:	c6 03 00             	movb   $0x0,(%ebx)
f010095f:	89 f7                	mov    %esi,%edi
f0100961:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100964:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100966:	0f b6 03             	movzbl (%ebx),%eax
f0100969:	84 c0                	test   %al,%al
f010096b:	74 63                	je     f01009d0 <monitor+0xce>
f010096d:	83 ec 08             	sub    $0x8,%esp
f0100970:	0f be c0             	movsbl %al,%eax
f0100973:	50                   	push   %eax
f0100974:	68 9b 66 10 f0       	push   $0xf010669b
f0100979:	e8 6d 4c 00 00       	call   f01055eb <strchr>
f010097e:	83 c4 10             	add    $0x10,%esp
f0100981:	85 c0                	test   %eax,%eax
f0100983:	75 d7                	jne    f010095c <monitor+0x5a>
			*buf++ = 0;
		if (*buf == 0)
f0100985:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100988:	74 46                	je     f01009d0 <monitor+0xce>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f010098a:	83 fe 0f             	cmp    $0xf,%esi
f010098d:	75 14                	jne    f01009a3 <monitor+0xa1>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010098f:	83 ec 08             	sub    $0x8,%esp
f0100992:	6a 10                	push   $0x10
f0100994:	68 a0 66 10 f0       	push   $0xf01066a0
f0100999:	e8 86 2d 00 00       	call   f0103724 <cprintf>
f010099e:	83 c4 10             	add    $0x10,%esp
f01009a1:	eb 95                	jmp    f0100938 <monitor+0x36>
			return 0;
		}
		argv[argc++] = buf;
f01009a3:	8d 7e 01             	lea    0x1(%esi),%edi
f01009a6:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01009aa:	eb 03                	jmp    f01009af <monitor+0xad>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01009ac:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01009af:	0f b6 03             	movzbl (%ebx),%eax
f01009b2:	84 c0                	test   %al,%al
f01009b4:	74 ae                	je     f0100964 <monitor+0x62>
f01009b6:	83 ec 08             	sub    $0x8,%esp
f01009b9:	0f be c0             	movsbl %al,%eax
f01009bc:	50                   	push   %eax
f01009bd:	68 9b 66 10 f0       	push   $0xf010669b
f01009c2:	e8 24 4c 00 00       	call   f01055eb <strchr>
f01009c7:	83 c4 10             	add    $0x10,%esp
f01009ca:	85 c0                	test   %eax,%eax
f01009cc:	74 de                	je     f01009ac <monitor+0xaa>
f01009ce:	eb 94                	jmp    f0100964 <monitor+0x62>
			buf++;
	}
	argv[argc] = 0;
f01009d0:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01009d7:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01009d8:	85 f6                	test   %esi,%esi
f01009da:	0f 84 58 ff ff ff    	je     f0100938 <monitor+0x36>
f01009e0:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01009e5:	83 ec 08             	sub    $0x8,%esp
f01009e8:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01009eb:	ff 34 85 40 68 10 f0 	pushl  -0xfef97c0(,%eax,4)
f01009f2:	ff 75 a8             	pushl  -0x58(%ebp)
f01009f5:	e8 93 4b 00 00       	call   f010558d <strcmp>
f01009fa:	83 c4 10             	add    $0x10,%esp
f01009fd:	85 c0                	test   %eax,%eax
f01009ff:	75 21                	jne    f0100a22 <monitor+0x120>
			return commands[i].func(argc, argv, tf);
f0100a01:	83 ec 04             	sub    $0x4,%esp
f0100a04:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100a07:	ff 75 08             	pushl  0x8(%ebp)
f0100a0a:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100a0d:	52                   	push   %edx
f0100a0e:	56                   	push   %esi
f0100a0f:	ff 14 85 48 68 10 f0 	call   *-0xfef97b8(,%eax,4)

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
		{
			if (runcmd(buf, tf) < 0)
f0100a16:	83 c4 10             	add    $0x10,%esp
f0100a19:	85 c0                	test   %eax,%eax
f0100a1b:	78 25                	js     f0100a42 <monitor+0x140>
f0100a1d:	e9 16 ff ff ff       	jmp    f0100938 <monitor+0x36>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100a22:	83 c3 01             	add    $0x1,%ebx
f0100a25:	83 fb 03             	cmp    $0x3,%ebx
f0100a28:	75 bb                	jne    f01009e5 <monitor+0xe3>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100a2a:	83 ec 08             	sub    $0x8,%esp
f0100a2d:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a30:	68 bd 66 10 f0       	push   $0xf01066bd
f0100a35:	e8 ea 2c 00 00       	call   f0103724 <cprintf>
f0100a3a:	83 c4 10             	add    $0x10,%esp
f0100a3d:	e9 f6 fe ff ff       	jmp    f0100938 <monitor+0x36>
		{
			if (runcmd(buf, tf) < 0)
				break;
		}
	}
}
f0100a42:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a45:	5b                   	pop    %ebx
f0100a46:	5e                   	pop    %esi
f0100a47:	5f                   	pop    %edi
f0100a48:	5d                   	pop    %ebp
f0100a49:	c3                   	ret    

f0100a4a <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100a4a:	83 3d 38 f2 22 f0 00 	cmpl   $0x0,0xf022f238
f0100a51:	75 5f                	jne    f0100ab2 <boot_alloc+0x68>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100a53:	ba 07 20 27 f0       	mov    $0xf0272007,%edx
f0100a58:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100a5e:	89 15 38 f2 22 f0    	mov    %edx,0xf022f238
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if (n > 0) {
f0100a64:	85 c0                	test   %eax,%eax
f0100a66:	74 44                	je     f0100aac <boot_alloc+0x62>
		if ((uint32_t)nextfree > KERNBASE + (npages * PGSIZE)) {
f0100a68:	8b 15 38 f2 22 f0    	mov    0xf022f238,%edx
f0100a6e:	8b 0d 88 fe 22 f0    	mov    0xf022fe88,%ecx
f0100a74:	81 c1 00 00 0f 00    	add    $0xf0000,%ecx
f0100a7a:	c1 e1 0c             	shl    $0xc,%ecx
f0100a7d:	39 ca                	cmp    %ecx,%edx
f0100a7f:	76 17                	jbe    f0100a98 <boot_alloc+0x4e>
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100a81:	55                   	push   %ebp
f0100a82:	89 e5                	mov    %esp,%ebp
f0100a84:	83 ec 0c             	sub    $0xc,%esp
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if (n > 0) {
		if ((uint32_t)nextfree > KERNBASE + (npages * PGSIZE)) {
			panic("out of memory"); 
f0100a87:	68 64 68 10 f0       	push   $0xf0106864
f0100a8c:	6a 6a                	push   $0x6a
f0100a8e:	68 72 68 10 f0       	push   $0xf0106872
f0100a93:	e8 a8 f5 ff ff       	call   f0100040 <_panic>
		} else {             
			result = nextfree; 
			nextfree = ROUNDUP(nextfree + n, PGSIZE);
f0100a98:	8d 84 02 ff 0f 00 00 	lea    0xfff(%edx,%eax,1),%eax
f0100a9f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100aa4:	a3 38 f2 22 f0       	mov    %eax,0xf022f238
			return result;
f0100aa9:	89 d0                	mov    %edx,%eax
f0100aab:	c3                   	ret    
		}
	}
	if (n == 0) {  
		return nextfree;
f0100aac:	a1 38 f2 22 f0       	mov    0xf022f238,%eax
f0100ab1:	c3                   	ret    
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if (n > 0) {
f0100ab2:	85 c0                	test   %eax,%eax
f0100ab4:	75 b2                	jne    f0100a68 <boot_alloc+0x1e>
f0100ab6:	eb f4                	jmp    f0100aac <boot_alloc+0x62>

f0100ab8 <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100ab8:	89 d1                	mov    %edx,%ecx
f0100aba:	c1 e9 16             	shr    $0x16,%ecx
f0100abd:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100ac0:	a8 01                	test   $0x1,%al
f0100ac2:	74 52                	je     f0100b16 <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100ac4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ac9:	89 c1                	mov    %eax,%ecx
f0100acb:	c1 e9 0c             	shr    $0xc,%ecx
f0100ace:	3b 0d 88 fe 22 f0    	cmp    0xf022fe88,%ecx
f0100ad4:	72 1b                	jb     f0100af1 <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100ad6:	55                   	push   %ebp
f0100ad7:	89 e5                	mov    %esp,%ebp
f0100ad9:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100adc:	50                   	push   %eax
f0100add:	68 04 63 10 f0       	push   $0xf0106304
f0100ae2:	68 87 03 00 00       	push   $0x387
f0100ae7:	68 72 68 10 f0       	push   $0xf0106872
f0100aec:	e8 4f f5 ff ff       	call   f0100040 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100af1:	c1 ea 0c             	shr    $0xc,%edx
f0100af4:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100afa:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100b01:	89 c2                	mov    %eax,%edx
f0100b03:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100b06:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b0b:	85 d2                	test   %edx,%edx
f0100b0d:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100b12:	0f 44 c2             	cmove  %edx,%eax
f0100b15:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100b16:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100b1b:	c3                   	ret    

f0100b1c <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100b1c:	55                   	push   %ebp
f0100b1d:	89 e5                	mov    %esp,%ebp
f0100b1f:	57                   	push   %edi
f0100b20:	56                   	push   %esi
f0100b21:	53                   	push   %ebx
f0100b22:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b25:	84 c0                	test   %al,%al
f0100b27:	0f 85 91 02 00 00    	jne    f0100dbe <check_page_free_list+0x2a2>
f0100b2d:	e9 9e 02 00 00       	jmp    f0100dd0 <check_page_free_list+0x2b4>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100b32:	83 ec 04             	sub    $0x4,%esp
f0100b35:	68 c8 6b 10 f0       	push   $0xf0106bc8
f0100b3a:	68 bc 02 00 00       	push   $0x2bc
f0100b3f:	68 72 68 10 f0       	push   $0xf0106872
f0100b44:	e8 f7 f4 ff ff       	call   f0100040 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100b49:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100b4c:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100b4f:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b52:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100b55:	89 c2                	mov    %eax,%edx
f0100b57:	2b 15 90 fe 22 f0    	sub    0xf022fe90,%edx
f0100b5d:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100b63:	0f 95 c2             	setne  %dl
f0100b66:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100b69:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100b6d:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100b6f:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b73:	8b 00                	mov    (%eax),%eax
f0100b75:	85 c0                	test   %eax,%eax
f0100b77:	75 dc                	jne    f0100b55 <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100b79:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b7c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100b82:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b85:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100b88:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100b8a:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100b8d:	a3 40 f2 22 f0       	mov    %eax,0xf022f240
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b92:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b97:	8b 1d 40 f2 22 f0    	mov    0xf022f240,%ebx
f0100b9d:	eb 53                	jmp    f0100bf2 <check_page_free_list+0xd6>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b9f:	89 d8                	mov    %ebx,%eax
f0100ba1:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0100ba7:	c1 f8 03             	sar    $0x3,%eax
f0100baa:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100bad:	89 c2                	mov    %eax,%edx
f0100baf:	c1 ea 16             	shr    $0x16,%edx
f0100bb2:	39 f2                	cmp    %esi,%edx
f0100bb4:	73 3a                	jae    f0100bf0 <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100bb6:	89 c2                	mov    %eax,%edx
f0100bb8:	c1 ea 0c             	shr    $0xc,%edx
f0100bbb:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f0100bc1:	72 12                	jb     f0100bd5 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100bc3:	50                   	push   %eax
f0100bc4:	68 04 63 10 f0       	push   $0xf0106304
f0100bc9:	6a 58                	push   $0x58
f0100bcb:	68 7e 68 10 f0       	push   $0xf010687e
f0100bd0:	e8 6b f4 ff ff       	call   f0100040 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100bd5:	83 ec 04             	sub    $0x4,%esp
f0100bd8:	68 80 00 00 00       	push   $0x80
f0100bdd:	68 97 00 00 00       	push   $0x97
f0100be2:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100be7:	50                   	push   %eax
f0100be8:	e8 3b 4a 00 00       	call   f0105628 <memset>
f0100bed:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100bf0:	8b 1b                	mov    (%ebx),%ebx
f0100bf2:	85 db                	test   %ebx,%ebx
f0100bf4:	75 a9                	jne    f0100b9f <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100bf6:	b8 00 00 00 00       	mov    $0x0,%eax
f0100bfb:	e8 4a fe ff ff       	call   f0100a4a <boot_alloc>
f0100c00:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c03:	8b 15 40 f2 22 f0    	mov    0xf022f240,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100c09:	8b 0d 90 fe 22 f0    	mov    0xf022fe90,%ecx
		assert(pp < pages + npages);
f0100c0f:	a1 88 fe 22 f0       	mov    0xf022fe88,%eax
f0100c14:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100c17:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100c1a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c1d:	89 4d d0             	mov    %ecx,-0x30(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100c20:	be 00 00 00 00       	mov    $0x0,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c25:	e9 52 01 00 00       	jmp    f0100d7c <check_page_free_list+0x260>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100c2a:	39 ca                	cmp    %ecx,%edx
f0100c2c:	73 19                	jae    f0100c47 <check_page_free_list+0x12b>
f0100c2e:	68 8c 68 10 f0       	push   $0xf010688c
f0100c33:	68 98 68 10 f0       	push   $0xf0106898
f0100c38:	68 d6 02 00 00       	push   $0x2d6
f0100c3d:	68 72 68 10 f0       	push   $0xf0106872
f0100c42:	e8 f9 f3 ff ff       	call   f0100040 <_panic>
		assert(pp < pages + npages);
f0100c47:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100c4a:	72 19                	jb     f0100c65 <check_page_free_list+0x149>
f0100c4c:	68 ad 68 10 f0       	push   $0xf01068ad
f0100c51:	68 98 68 10 f0       	push   $0xf0106898
f0100c56:	68 d7 02 00 00       	push   $0x2d7
f0100c5b:	68 72 68 10 f0       	push   $0xf0106872
f0100c60:	e8 db f3 ff ff       	call   f0100040 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c65:	89 d0                	mov    %edx,%eax
f0100c67:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100c6a:	a8 07                	test   $0x7,%al
f0100c6c:	74 19                	je     f0100c87 <check_page_free_list+0x16b>
f0100c6e:	68 ec 6b 10 f0       	push   $0xf0106bec
f0100c73:	68 98 68 10 f0       	push   $0xf0106898
f0100c78:	68 d8 02 00 00       	push   $0x2d8
f0100c7d:	68 72 68 10 f0       	push   $0xf0106872
f0100c82:	e8 b9 f3 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c87:	c1 f8 03             	sar    $0x3,%eax
f0100c8a:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100c8d:	85 c0                	test   %eax,%eax
f0100c8f:	75 19                	jne    f0100caa <check_page_free_list+0x18e>
f0100c91:	68 c1 68 10 f0       	push   $0xf01068c1
f0100c96:	68 98 68 10 f0       	push   $0xf0106898
f0100c9b:	68 db 02 00 00       	push   $0x2db
f0100ca0:	68 72 68 10 f0       	push   $0xf0106872
f0100ca5:	e8 96 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100caa:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100caf:	75 19                	jne    f0100cca <check_page_free_list+0x1ae>
f0100cb1:	68 d2 68 10 f0       	push   $0xf01068d2
f0100cb6:	68 98 68 10 f0       	push   $0xf0106898
f0100cbb:	68 dc 02 00 00       	push   $0x2dc
f0100cc0:	68 72 68 10 f0       	push   $0xf0106872
f0100cc5:	e8 76 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100cca:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100ccf:	75 19                	jne    f0100cea <check_page_free_list+0x1ce>
f0100cd1:	68 20 6c 10 f0       	push   $0xf0106c20
f0100cd6:	68 98 68 10 f0       	push   $0xf0106898
f0100cdb:	68 dd 02 00 00       	push   $0x2dd
f0100ce0:	68 72 68 10 f0       	push   $0xf0106872
f0100ce5:	e8 56 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100cea:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100cef:	75 19                	jne    f0100d0a <check_page_free_list+0x1ee>
f0100cf1:	68 eb 68 10 f0       	push   $0xf01068eb
f0100cf6:	68 98 68 10 f0       	push   $0xf0106898
f0100cfb:	68 de 02 00 00       	push   $0x2de
f0100d00:	68 72 68 10 f0       	push   $0xf0106872
f0100d05:	e8 36 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100d0a:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100d0f:	0f 86 de 00 00 00    	jbe    f0100df3 <check_page_free_list+0x2d7>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d15:	89 c7                	mov    %eax,%edi
f0100d17:	c1 ef 0c             	shr    $0xc,%edi
f0100d1a:	39 7d c8             	cmp    %edi,-0x38(%ebp)
f0100d1d:	77 12                	ja     f0100d31 <check_page_free_list+0x215>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d1f:	50                   	push   %eax
f0100d20:	68 04 63 10 f0       	push   $0xf0106304
f0100d25:	6a 58                	push   $0x58
f0100d27:	68 7e 68 10 f0       	push   $0xf010687e
f0100d2c:	e8 0f f3 ff ff       	call   f0100040 <_panic>
f0100d31:	8d b8 00 00 00 f0    	lea    -0x10000000(%eax),%edi
f0100d37:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0100d3a:	0f 86 a7 00 00 00    	jbe    f0100de7 <check_page_free_list+0x2cb>
f0100d40:	68 44 6c 10 f0       	push   $0xf0106c44
f0100d45:	68 98 68 10 f0       	push   $0xf0106898
f0100d4a:	68 df 02 00 00       	push   $0x2df
f0100d4f:	68 72 68 10 f0       	push   $0xf0106872
f0100d54:	e8 e7 f2 ff ff       	call   f0100040 <_panic>
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100d59:	68 05 69 10 f0       	push   $0xf0106905
f0100d5e:	68 98 68 10 f0       	push   $0xf0106898
f0100d63:	68 e1 02 00 00       	push   $0x2e1
f0100d68:	68 72 68 10 f0       	push   $0xf0106872
f0100d6d:	e8 ce f2 ff ff       	call   f0100040 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100d72:	83 c6 01             	add    $0x1,%esi
f0100d75:	eb 03                	jmp    f0100d7a <check_page_free_list+0x25e>
		else
			++nfree_extmem;
f0100d77:	83 c3 01             	add    $0x1,%ebx
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d7a:	8b 12                	mov    (%edx),%edx
f0100d7c:	85 d2                	test   %edx,%edx
f0100d7e:	0f 85 a6 fe ff ff    	jne    f0100c2a <check_page_free_list+0x10e>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100d84:	85 f6                	test   %esi,%esi
f0100d86:	7f 19                	jg     f0100da1 <check_page_free_list+0x285>
f0100d88:	68 22 69 10 f0       	push   $0xf0106922
f0100d8d:	68 98 68 10 f0       	push   $0xf0106898
f0100d92:	68 e9 02 00 00       	push   $0x2e9
f0100d97:	68 72 68 10 f0       	push   $0xf0106872
f0100d9c:	e8 9f f2 ff ff       	call   f0100040 <_panic>
	assert(nfree_extmem > 0);
f0100da1:	85 db                	test   %ebx,%ebx
f0100da3:	7f 5e                	jg     f0100e03 <check_page_free_list+0x2e7>
f0100da5:	68 34 69 10 f0       	push   $0xf0106934
f0100daa:	68 98 68 10 f0       	push   $0xf0106898
f0100daf:	68 ea 02 00 00       	push   $0x2ea
f0100db4:	68 72 68 10 f0       	push   $0xf0106872
f0100db9:	e8 82 f2 ff ff       	call   f0100040 <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100dbe:	a1 40 f2 22 f0       	mov    0xf022f240,%eax
f0100dc3:	85 c0                	test   %eax,%eax
f0100dc5:	0f 85 7e fd ff ff    	jne    f0100b49 <check_page_free_list+0x2d>
f0100dcb:	e9 62 fd ff ff       	jmp    f0100b32 <check_page_free_list+0x16>
f0100dd0:	83 3d 40 f2 22 f0 00 	cmpl   $0x0,0xf022f240
f0100dd7:	0f 84 55 fd ff ff    	je     f0100b32 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100ddd:	be 00 04 00 00       	mov    $0x400,%esi
f0100de2:	e9 b0 fd ff ff       	jmp    f0100b97 <check_page_free_list+0x7b>
		assert(page2pa(pp) != IOPHYSMEM);
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
		assert(page2pa(pp) != EXTPHYSMEM);
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100de7:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100dec:	75 89                	jne    f0100d77 <check_page_free_list+0x25b>
f0100dee:	e9 66 ff ff ff       	jmp    f0100d59 <check_page_free_list+0x23d>
f0100df3:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100df8:	0f 85 74 ff ff ff    	jne    f0100d72 <check_page_free_list+0x256>
f0100dfe:	e9 56 ff ff ff       	jmp    f0100d59 <check_page_free_list+0x23d>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100e03:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e06:	5b                   	pop    %ebx
f0100e07:	5e                   	pop    %esi
f0100e08:	5f                   	pop    %edi
f0100e09:	5d                   	pop    %ebp
f0100e0a:	c3                   	ret    

f0100e0b <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100e0b:	55                   	push   %ebp
f0100e0c:	89 e5                	mov    %esp,%ebp
f0100e0e:	57                   	push   %edi
f0100e0f:	56                   	push   %esi
f0100e10:	53                   	push   %ebx
f0100e11:	83 ec 1c             	sub    $0x1c,%esp
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	uint32_t nextfree = (uint32_t)boot_alloc(0);
f0100e14:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e19:	e8 2c fc ff ff       	call   f0100a4a <boot_alloc>
		if(i == 0) { 
			pages[i].pp_ref = 1; 
			pages[i].pp_link = NULL;
		} else if(i == MPENTRY_PADDR/PGSIZE){
			continue;
		} else if(i < npages_basemem) {   
f0100e1e:	8b 35 44 f2 22 f0    	mov    0xf022f244,%esi
f0100e24:	8b 1d 40 f2 22 f0    	mov    0xf022f240,%ebx
			pages[i].pp_ref = 0; 
            		pages[i].pp_link = page_free_list;
           		 page_free_list = &pages[i];
		} else if(i >= IOPHYSMEM/PGSIZE && i < EXTPHYSMEM/PGSIZE) { 
			pages[i].pp_ref = 1; 
		} else if (i >= IOPHYSMEM / PGSIZE && i < (nextfree - KERNBASE)/ PGSIZE) { 
f0100e2a:	05 00 00 00 10       	add    $0x10000000,%eax
f0100e2f:	c1 e8 0c             	shr    $0xc,%eax
f0100e32:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	uint32_t nextfree = (uint32_t)boot_alloc(0);
	for (i = 0; i < npages; i++) {
f0100e35:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e3a:	bf 00 00 00 00       	mov    $0x0,%edi
f0100e3f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e44:	e9 a2 00 00 00       	jmp    f0100eeb <page_init+0xe0>
		if(i == 0) { 
f0100e49:	85 c0                	test   %eax,%eax
f0100e4b:	75 17                	jne    f0100e64 <page_init+0x59>
			pages[i].pp_ref = 1; 
f0100e4d:	8b 0d 90 fe 22 f0    	mov    0xf022fe90,%ecx
f0100e53:	66 c7 41 04 01 00    	movw   $0x1,0x4(%ecx)
			pages[i].pp_link = NULL;
f0100e59:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
f0100e5f:	e9 81 00 00 00       	jmp    f0100ee5 <page_init+0xda>
		} else if(i == MPENTRY_PADDR/PGSIZE){
f0100e64:	83 f8 07             	cmp    $0x7,%eax
f0100e67:	74 7c                	je     f0100ee5 <page_init+0xda>
			continue;
		} else if(i < npages_basemem) {   
f0100e69:	39 f0                	cmp    %esi,%eax
f0100e6b:	73 1f                	jae    f0100e8c <page_init+0x81>
			pages[i].pp_ref = 0; 
f0100e6d:	89 d1                	mov    %edx,%ecx
f0100e6f:	03 0d 90 fe 22 f0    	add    0xf022fe90,%ecx
f0100e75:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
            		pages[i].pp_link = page_free_list;
f0100e7b:	89 19                	mov    %ebx,(%ecx)
           		 page_free_list = &pages[i];
f0100e7d:	89 d3                	mov    %edx,%ebx
f0100e7f:	03 1d 90 fe 22 f0    	add    0xf022fe90,%ebx
f0100e85:	bf 01 00 00 00       	mov    $0x1,%edi
f0100e8a:	eb 59                	jmp    f0100ee5 <page_init+0xda>
		} else if(i >= IOPHYSMEM/PGSIZE && i < EXTPHYSMEM/PGSIZE) { 
f0100e8c:	8d 88 60 ff ff ff    	lea    -0xa0(%eax),%ecx
f0100e92:	83 f9 5f             	cmp    $0x5f,%ecx
f0100e95:	77 0f                	ja     f0100ea6 <page_init+0x9b>
			pages[i].pp_ref = 1; 
f0100e97:	8b 0d 90 fe 22 f0    	mov    0xf022fe90,%ecx
f0100e9d:	66 c7 44 11 04 01 00 	movw   $0x1,0x4(%ecx,%edx,1)
f0100ea4:	eb 3f                	jmp    f0100ee5 <page_init+0xda>
		} else if (i >= IOPHYSMEM / PGSIZE && i < (nextfree - KERNBASE)/ PGSIZE) { 
f0100ea6:	3d 9f 00 00 00       	cmp    $0x9f,%eax
f0100eab:	76 1b                	jbe    f0100ec8 <page_init+0xbd>
f0100ead:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
f0100eb0:	73 16                	jae    f0100ec8 <page_init+0xbd>
            		pages[i].pp_ref = 1;
f0100eb2:	89 d1                	mov    %edx,%ecx
f0100eb4:	03 0d 90 fe 22 f0    	add    0xf022fe90,%ecx
f0100eba:	66 c7 41 04 01 00    	movw   $0x1,0x4(%ecx)
            		pages[i].pp_link = NULL;
f0100ec0:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
f0100ec6:	eb 1d                	jmp    f0100ee5 <page_init+0xda>
       		} else {
			pages[i].pp_ref = 0;
f0100ec8:	89 d1                	mov    %edx,%ecx
f0100eca:	03 0d 90 fe 22 f0    	add    0xf022fe90,%ecx
f0100ed0:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
            		pages[i].pp_link = page_free_list;
f0100ed6:	89 19                	mov    %ebx,(%ecx)
            		page_free_list = &pages[i];
f0100ed8:	89 d3                	mov    %edx,%ebx
f0100eda:	03 1d 90 fe 22 f0    	add    0xf022fe90,%ebx
f0100ee0:	bf 01 00 00 00       	mov    $0x1,%edi
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	uint32_t nextfree = (uint32_t)boot_alloc(0);
	for (i = 0; i < npages; i++) {
f0100ee5:	83 c0 01             	add    $0x1,%eax
f0100ee8:	83 c2 08             	add    $0x8,%edx
f0100eeb:	3b 05 88 fe 22 f0    	cmp    0xf022fe88,%eax
f0100ef1:	0f 82 52 ff ff ff    	jb     f0100e49 <page_init+0x3e>
f0100ef7:	89 f8                	mov    %edi,%eax
f0100ef9:	84 c0                	test   %al,%al
f0100efb:	74 06                	je     f0100f03 <page_init+0xf8>
f0100efd:	89 1d 40 f2 22 f0    	mov    %ebx,0xf022f240
			pages[i].pp_ref = 0;
            		pages[i].pp_link = page_free_list;
            		page_free_list = &pages[i];
		}
	}
}
f0100f03:	83 c4 1c             	add    $0x1c,%esp
f0100f06:	5b                   	pop    %ebx
f0100f07:	5e                   	pop    %esi
f0100f08:	5f                   	pop    %edi
f0100f09:	5d                   	pop    %ebp
f0100f0a:	c3                   	ret    

f0100f0b <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100f0b:	55                   	push   %ebp
f0100f0c:	89 e5                	mov    %esp,%ebp
f0100f0e:	53                   	push   %ebx
f0100f0f:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in
	struct PageInfo *NewPage;
	if(page_free_list == NULL) {
f0100f12:	8b 1d 40 f2 22 f0    	mov    0xf022f240,%ebx
f0100f18:	85 db                	test   %ebx,%ebx
f0100f1a:	74 58                	je     f0100f74 <page_alloc+0x69>
		return NULL; 
	}
	NewPage = page_free_list; 
	page_free_list = page_free_list->pp_link; 
f0100f1c:	8b 03                	mov    (%ebx),%eax
f0100f1e:	a3 40 f2 22 f0       	mov    %eax,0xf022f240
	NewPage->pp_link = NULL;
f0100f23:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if (alloc_flags & ALLOC_ZERO) {
f0100f29:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100f2d:	74 45                	je     f0100f74 <page_alloc+0x69>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100f2f:	89 d8                	mov    %ebx,%eax
f0100f31:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0100f37:	c1 f8 03             	sar    $0x3,%eax
f0100f3a:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f3d:	89 c2                	mov    %eax,%edx
f0100f3f:	c1 ea 0c             	shr    $0xc,%edx
f0100f42:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f0100f48:	72 12                	jb     f0100f5c <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f4a:	50                   	push   %eax
f0100f4b:	68 04 63 10 f0       	push   $0xf0106304
f0100f50:	6a 58                	push   $0x58
f0100f52:	68 7e 68 10 f0       	push   $0xf010687e
f0100f57:	e8 e4 f0 ff ff       	call   f0100040 <_panic>
		memset(page2kva(NewPage), 0, PGSIZE);
f0100f5c:	83 ec 04             	sub    $0x4,%esp
f0100f5f:	68 00 10 00 00       	push   $0x1000
f0100f64:	6a 00                	push   $0x0
f0100f66:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100f6b:	50                   	push   %eax
f0100f6c:	e8 b7 46 00 00       	call   f0105628 <memset>
f0100f71:	83 c4 10             	add    $0x10,%esp
	}
	return NewPage; 
}
f0100f74:	89 d8                	mov    %ebx,%eax
f0100f76:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100f79:	c9                   	leave  
f0100f7a:	c3                   	ret    

f0100f7b <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100f7b:	55                   	push   %ebp
f0100f7c:	89 e5                	mov    %esp,%ebp
f0100f7e:	83 ec 08             	sub    $0x8,%esp
f0100f81:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	assert(pp->pp_ref == 0); 
f0100f84:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100f89:	74 19                	je     f0100fa4 <page_free+0x29>
f0100f8b:	68 45 69 10 f0       	push   $0xf0106945
f0100f90:	68 98 68 10 f0       	push   $0xf0106898
f0100f95:	68 7e 01 00 00       	push   $0x17e
f0100f9a:	68 72 68 10 f0       	push   $0xf0106872
f0100f9f:	e8 9c f0 ff ff       	call   f0100040 <_panic>
	assert(pp->pp_link == NULL);
f0100fa4:	83 38 00             	cmpl   $0x0,(%eax)
f0100fa7:	74 19                	je     f0100fc2 <page_free+0x47>
f0100fa9:	68 55 69 10 f0       	push   $0xf0106955
f0100fae:	68 98 68 10 f0       	push   $0xf0106898
f0100fb3:	68 7f 01 00 00       	push   $0x17f
f0100fb8:	68 72 68 10 f0       	push   $0xf0106872
f0100fbd:	e8 7e f0 ff ff       	call   f0100040 <_panic>
	pp->pp_link = page_free_list;
f0100fc2:	8b 15 40 f2 22 f0    	mov    0xf022f240,%edx
f0100fc8:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100fca:	a3 40 f2 22 f0       	mov    %eax,0xf022f240
}
f0100fcf:	c9                   	leave  
f0100fd0:	c3                   	ret    

f0100fd1 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100fd1:	55                   	push   %ebp
f0100fd2:	89 e5                	mov    %esp,%ebp
f0100fd4:	83 ec 08             	sub    $0x8,%esp
f0100fd7:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100fda:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100fde:	83 e8 01             	sub    $0x1,%eax
f0100fe1:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100fe5:	66 85 c0             	test   %ax,%ax
f0100fe8:	75 0c                	jne    f0100ff6 <page_decref+0x25>
		page_free(pp);
f0100fea:	83 ec 0c             	sub    $0xc,%esp
f0100fed:	52                   	push   %edx
f0100fee:	e8 88 ff ff ff       	call   f0100f7b <page_free>
f0100ff3:	83 c4 10             	add    $0x10,%esp
}
f0100ff6:	c9                   	leave  
f0100ff7:	c3                   	ret    

f0100ff8 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100ff8:	55                   	push   %ebp
f0100ff9:	89 e5                	mov    %esp,%ebp
f0100ffb:	56                   	push   %esi
f0100ffc:	53                   	push   %ebx
f0100ffd:	8b 45 0c             	mov    0xc(%ebp),%eax
	// Fill this function in
    int pd_index = PDX(va); 
    int pte_index = PTX(va);
f0101000:	89 c6                	mov    %eax,%esi
f0101002:	c1 ee 0c             	shr    $0xc,%esi
f0101005:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
    if (pgdir[pd_index] & PTE_P) {  
f010100b:	c1 e8 16             	shr    $0x16,%eax
f010100e:	8d 1c 85 00 00 00 00 	lea    0x0(,%eax,4),%ebx
f0101015:	03 5d 08             	add    0x8(%ebp),%ebx
f0101018:	8b 03                	mov    (%ebx),%eax
f010101a:	a8 01                	test   $0x1,%al
f010101c:	74 30                	je     f010104e <pgdir_walk+0x56>
        pte_t *pt_addr_v = KADDR(PTE_ADDR(pgdir[pd_index]));
f010101e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101023:	89 c2                	mov    %eax,%edx
f0101025:	c1 ea 0c             	shr    $0xc,%edx
f0101028:	39 15 88 fe 22 f0    	cmp    %edx,0xf022fe88
f010102e:	77 15                	ja     f0101045 <pgdir_walk+0x4d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101030:	50                   	push   %eax
f0101031:	68 04 63 10 f0       	push   $0xf0106304
f0101036:	68 ac 01 00 00       	push   $0x1ac
f010103b:	68 72 68 10 f0       	push   $0xf0106872
f0101040:	e8 fb ef ff ff       	call   f0100040 <_panic>
        return (pte_t*)(pt_addr_v + pte_index);
f0101045:	8d 84 b0 00 00 00 f0 	lea    -0x10000000(%eax,%esi,4),%eax
f010104c:	eb 6b                	jmp    f01010b9 <pgdir_walk+0xc1>
    } else {           
        if (create) {
f010104e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101052:	74 59                	je     f01010ad <pgdir_walk+0xb5>
	    struct PageInfo *NewPt = page_alloc(ALLOC_ZERO); 
f0101054:	83 ec 0c             	sub    $0xc,%esp
f0101057:	6a 01                	push   $0x1
f0101059:	e8 ad fe ff ff       	call   f0100f0b <page_alloc>
	    if(NewPt == NULL)
f010105e:	83 c4 10             	add    $0x10,%esp
f0101061:	85 c0                	test   %eax,%eax
f0101063:	74 4f                	je     f01010b4 <pgdir_walk+0xbc>
		return NULL;
            NewPt->pp_ref++;
f0101065:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010106a:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0101070:	c1 f8 03             	sar    $0x3,%eax
f0101073:	c1 e0 0c             	shl    $0xc,%eax
            pgdir[pd_index] = page2pa(NewPt)|PTE_U|PTE_W|PTE_P; 
f0101076:	89 c2                	mov    %eax,%edx
f0101078:	83 ca 07             	or     $0x7,%edx
f010107b:	89 13                	mov    %edx,(%ebx)
f010107d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101082:	89 c2                	mov    %eax,%edx
f0101084:	c1 ea 0c             	shr    $0xc,%edx
f0101087:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f010108d:	72 15                	jb     f01010a4 <pgdir_walk+0xac>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010108f:	50                   	push   %eax
f0101090:	68 04 63 10 f0       	push   $0xf0106304
f0101095:	68 b5 01 00 00       	push   $0x1b5
f010109a:	68 72 68 10 f0       	push   $0xf0106872
f010109f:	e8 9c ef ff ff       	call   f0100040 <_panic>
            pte_t *pt_addr_v = KADDR(PTE_ADDR(pgdir[pd_index]));
            return (pte_t*)(pt_addr_v + pte_index);
f01010a4:	8d 84 b0 00 00 00 f0 	lea    -0x10000000(%eax,%esi,4),%eax
f01010ab:	eb 0c                	jmp    f01010b9 <pgdir_walk+0xc1>
        } else return NULL;
f01010ad:	b8 00 00 00 00       	mov    $0x0,%eax
f01010b2:	eb 05                	jmp    f01010b9 <pgdir_walk+0xc1>
        return (pte_t*)(pt_addr_v + pte_index);
    } else {           
        if (create) {
	    struct PageInfo *NewPt = page_alloc(ALLOC_ZERO); 
	    if(NewPt == NULL)
		return NULL;
f01010b4:	b8 00 00 00 00       	mov    $0x0,%eax
            pgdir[pd_index] = page2pa(NewPt)|PTE_U|PTE_W|PTE_P; 
            pte_t *pt_addr_v = KADDR(PTE_ADDR(pgdir[pd_index]));
            return (pte_t*)(pt_addr_v + pte_index);
        } else return NULL;
    }
}
f01010b9:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01010bc:	5b                   	pop    %ebx
f01010bd:	5e                   	pop    %esi
f01010be:	5d                   	pop    %ebp
f01010bf:	c3                   	ret    

f01010c0 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f01010c0:	55                   	push   %ebp
f01010c1:	89 e5                	mov    %esp,%ebp
f01010c3:	57                   	push   %edi
f01010c4:	56                   	push   %esi
f01010c5:	53                   	push   %ebx
f01010c6:	83 ec 1c             	sub    $0x1c,%esp
f01010c9:	89 45 e0             	mov    %eax,-0x20(%ebp)
	// Fill this function in
    size = ROUNDUP(size, PGSIZE);
f01010cc:	81 c1 ff 0f 00 00    	add    $0xfff,%ecx
    size_t page_num = PGNUM(size);
f01010d2:	c1 e9 0c             	shr    $0xc,%ecx
f01010d5:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
    for (size_t i = 0; i < page_num; i++) {
f01010d8:	89 d3                	mov    %edx,%ebx
f01010da:	be 00 00 00 00       	mov    $0x0,%esi
        pte_t *pgtable_entry_ptr = pgdir_walk(pgdir, (char *)(va + i * PGSIZE), true);
        *pgtable_entry_ptr = (pa + i * PGSIZE) | perm | PTE_P;
f01010df:	8b 7d 08             	mov    0x8(%ebp),%edi
f01010e2:	29 d7                	sub    %edx,%edi
f01010e4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01010e7:	83 c8 01             	or     $0x1,%eax
f01010ea:	89 45 dc             	mov    %eax,-0x24(%ebp)
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
    size = ROUNDUP(size, PGSIZE);
    size_t page_num = PGNUM(size);
    for (size_t i = 0; i < page_num; i++) {
f01010ed:	eb 22                	jmp    f0101111 <boot_map_region+0x51>
        pte_t *pgtable_entry_ptr = pgdir_walk(pgdir, (char *)(va + i * PGSIZE), true);
f01010ef:	83 ec 04             	sub    $0x4,%esp
f01010f2:	6a 01                	push   $0x1
f01010f4:	53                   	push   %ebx
f01010f5:	ff 75 e0             	pushl  -0x20(%ebp)
f01010f8:	e8 fb fe ff ff       	call   f0100ff8 <pgdir_walk>
        *pgtable_entry_ptr = (pa + i * PGSIZE) | perm | PTE_P;
f01010fd:	8d 14 1f             	lea    (%edi,%ebx,1),%edx
f0101100:	0b 55 dc             	or     -0x24(%ebp),%edx
f0101103:	89 10                	mov    %edx,(%eax)
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
    size = ROUNDUP(size, PGSIZE);
    size_t page_num = PGNUM(size);
    for (size_t i = 0; i < page_num; i++) {
f0101105:	83 c6 01             	add    $0x1,%esi
f0101108:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010110e:	83 c4 10             	add    $0x10,%esp
f0101111:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0101114:	75 d9                	jne    f01010ef <boot_map_region+0x2f>
        pte_t *pgtable_entry_ptr = pgdir_walk(pgdir, (char *)(va + i * PGSIZE), true);
        *pgtable_entry_ptr = (pa + i * PGSIZE) | perm | PTE_P;
    }
}
f0101116:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101119:	5b                   	pop    %ebx
f010111a:	5e                   	pop    %esi
f010111b:	5f                   	pop    %edi
f010111c:	5d                   	pop    %ebp
f010111d:	c3                   	ret    

f010111e <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f010111e:	55                   	push   %ebp
f010111f:	89 e5                	mov    %esp,%ebp
f0101121:	53                   	push   %ebx
f0101122:	83 ec 08             	sub    $0x8,%esp
f0101125:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, 0);
f0101128:	6a 00                	push   $0x0
f010112a:	ff 75 0c             	pushl  0xc(%ebp)
f010112d:	ff 75 08             	pushl  0x8(%ebp)
f0101130:	e8 c3 fe ff ff       	call   f0100ff8 <pgdir_walk>
	if(pte == NULL) { 
f0101135:	83 c4 10             	add    $0x10,%esp
f0101138:	85 c0                	test   %eax,%eax
f010113a:	74 32                	je     f010116e <page_lookup+0x50>
		return NULL;
	} else if(pte_store != 0){
f010113c:	85 db                	test   %ebx,%ebx
f010113e:	74 02                	je     f0101142 <page_lookup+0x24>
		*pte_store = pte; 
f0101140:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101142:	8b 00                	mov    (%eax),%eax
f0101144:	c1 e8 0c             	shr    $0xc,%eax
f0101147:	3b 05 88 fe 22 f0    	cmp    0xf022fe88,%eax
f010114d:	72 14                	jb     f0101163 <page_lookup+0x45>
		panic("pa2page called with invalid pa");
f010114f:	83 ec 04             	sub    $0x4,%esp
f0101152:	68 8c 6c 10 f0       	push   $0xf0106c8c
f0101157:	6a 51                	push   $0x51
f0101159:	68 7e 68 10 f0       	push   $0xf010687e
f010115e:	e8 dd ee ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f0101163:	8b 15 90 fe 22 f0    	mov    0xf022fe90,%edx
f0101169:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	}
	return pa2page(PTE_ADDR(*pte));
f010116c:	eb 05                	jmp    f0101173 <page_lookup+0x55>
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, 0);
	if(pte == NULL) { 
		return NULL;
f010116e:	b8 00 00 00 00       	mov    $0x0,%eax
	} else if(pte_store != 0){
		*pte_store = pte; 
	}
	return pa2page(PTE_ADDR(*pte));
}
f0101173:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101176:	c9                   	leave  
f0101177:	c3                   	ret    

f0101178 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0101178:	55                   	push   %ebp
f0101179:	89 e5                	mov    %esp,%ebp
f010117b:	83 ec 08             	sub    $0x8,%esp
	// Flush the entry only if we're modifying the current address space.
	if (!curenv || curenv->env_pgdir == pgdir)
f010117e:	e8 c7 4a 00 00       	call   f0105c4a <cpunum>
f0101183:	6b c0 74             	imul   $0x74,%eax,%eax
f0101186:	83 b8 28 00 23 f0 00 	cmpl   $0x0,-0xfdcffd8(%eax)
f010118d:	74 16                	je     f01011a5 <tlb_invalidate+0x2d>
f010118f:	e8 b6 4a 00 00       	call   f0105c4a <cpunum>
f0101194:	6b c0 74             	imul   $0x74,%eax,%eax
f0101197:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f010119d:	8b 55 08             	mov    0x8(%ebp),%edx
f01011a0:	39 50 60             	cmp    %edx,0x60(%eax)
f01011a3:	75 06                	jne    f01011ab <tlb_invalidate+0x33>
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01011a5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01011a8:	0f 01 38             	invlpg (%eax)
		invlpg(va);
}
f01011ab:	c9                   	leave  
f01011ac:	c3                   	ret    

f01011ad <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f01011ad:	55                   	push   %ebp
f01011ae:	89 e5                	mov    %esp,%ebp
f01011b0:	56                   	push   %esi
f01011b1:	53                   	push   %ebx
f01011b2:	83 ec 14             	sub    $0x14,%esp
f01011b5:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01011b8:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	pte_t *pte;
	struct PageInfo *Fpage = page_lookup(pgdir, va, &pte);
f01011bb:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01011be:	50                   	push   %eax
f01011bf:	56                   	push   %esi
f01011c0:	53                   	push   %ebx
f01011c1:	e8 58 ff ff ff       	call   f010111e <page_lookup>
	if(Fpage == NULL){ 
f01011c6:	83 c4 10             	add    $0x10,%esp
f01011c9:	85 c0                	test   %eax,%eax
f01011cb:	74 1f                	je     f01011ec <page_remove+0x3f>
		return;
	}
	page_decref(Fpage); 
f01011cd:	83 ec 0c             	sub    $0xc,%esp
f01011d0:	50                   	push   %eax
f01011d1:	e8 fb fd ff ff       	call   f0100fd1 <page_decref>
	*pte = 0;
f01011d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01011d9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	tlb_invalidate(pgdir, va);
f01011df:	83 c4 08             	add    $0x8,%esp
f01011e2:	56                   	push   %esi
f01011e3:	53                   	push   %ebx
f01011e4:	e8 8f ff ff ff       	call   f0101178 <tlb_invalidate>
f01011e9:	83 c4 10             	add    $0x10,%esp
}
f01011ec:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01011ef:	5b                   	pop    %ebx
f01011f0:	5e                   	pop    %esi
f01011f1:	5d                   	pop    %ebp
f01011f2:	c3                   	ret    

f01011f3 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f01011f3:	55                   	push   %ebp
f01011f4:	89 e5                	mov    %esp,%ebp
f01011f6:	57                   	push   %edi
f01011f7:	56                   	push   %esi
f01011f8:	53                   	push   %ebx
f01011f9:	83 ec 10             	sub    $0x10,%esp
f01011fc:	8b 75 08             	mov    0x8(%ebp),%esi
f01011ff:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
    pte_t *pte = pgdir_walk(pgdir, va, 1);
f0101202:	6a 01                	push   $0x1
f0101204:	ff 75 10             	pushl  0x10(%ebp)
f0101207:	56                   	push   %esi
f0101208:	e8 eb fd ff ff       	call   f0100ff8 <pgdir_walk>
    if (pte == NULL) { 
f010120d:	83 c4 10             	add    $0x10,%esp
f0101210:	85 c0                	test   %eax,%eax
f0101212:	74 74                	je     f0101288 <page_insert+0x95>
f0101214:	89 c7                	mov    %eax,%edi
        return -E_NO_MEM;
    }  
    if (*pte & PTE_P) { 
f0101216:	8b 00                	mov    (%eax),%eax
f0101218:	a8 01                	test   $0x1,%al
f010121a:	74 3c                	je     f0101258 <page_insert+0x65>
        if (PTE_ADDR(*pte) == page2pa(pp)) { 
f010121c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0101221:	89 da                	mov    %ebx,%edx
f0101223:	2b 15 90 fe 22 f0    	sub    0xf022fe90,%edx
f0101229:	c1 fa 03             	sar    $0x3,%edx
f010122c:	c1 e2 0c             	shl    $0xc,%edx
f010122f:	39 d0                	cmp    %edx,%eax
f0101231:	75 16                	jne    f0101249 <page_insert+0x56>
            tlb_invalidate(pgdir, va); 
f0101233:	83 ec 08             	sub    $0x8,%esp
f0101236:	ff 75 10             	pushl  0x10(%ebp)
f0101239:	56                   	push   %esi
f010123a:	e8 39 ff ff ff       	call   f0101178 <tlb_invalidate>
            pp->pp_ref--;
f010123f:	66 83 6b 04 01       	subw   $0x1,0x4(%ebx)
f0101244:	83 c4 10             	add    $0x10,%esp
f0101247:	eb 0f                	jmp    f0101258 <page_insert+0x65>
        }
        else {
            page_remove(pgdir, va);
f0101249:	83 ec 08             	sub    $0x8,%esp
f010124c:	ff 75 10             	pushl  0x10(%ebp)
f010124f:	56                   	push   %esi
f0101250:	e8 58 ff ff ff       	call   f01011ad <page_remove>
f0101255:	83 c4 10             	add    $0x10,%esp
        }
    }
    *pte = page2pa(pp) | perm | PTE_P;
f0101258:	89 d8                	mov    %ebx,%eax
f010125a:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0101260:	c1 f8 03             	sar    $0x3,%eax
f0101263:	c1 e0 0c             	shl    $0xc,%eax
f0101266:	8b 55 14             	mov    0x14(%ebp),%edx
f0101269:	83 ca 01             	or     $0x1,%edx
f010126c:	09 d0                	or     %edx,%eax
f010126e:	89 07                	mov    %eax,(%edi)
    pp->pp_ref++;
f0101270:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
    pgdir[PDX(va)] |= perm;
f0101275:	8b 45 10             	mov    0x10(%ebp),%eax
f0101278:	c1 e8 16             	shr    $0x16,%eax
f010127b:	8b 4d 14             	mov    0x14(%ebp),%ecx
f010127e:	09 0c 86             	or     %ecx,(%esi,%eax,4)
    return 0;
f0101281:	b8 00 00 00 00       	mov    $0x0,%eax
f0101286:	eb 05                	jmp    f010128d <page_insert+0x9a>
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	// Fill this function in
    pte_t *pte = pgdir_walk(pgdir, va, 1);
    if (pte == NULL) { 
        return -E_NO_MEM;
f0101288:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
    }
    *pte = page2pa(pp) | perm | PTE_P;
    pp->pp_ref++;
    pgdir[PDX(va)] |= perm;
    return 0;
}
f010128d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101290:	5b                   	pop    %ebx
f0101291:	5e                   	pop    %esi
f0101292:	5f                   	pop    %edi
f0101293:	5d                   	pop    %ebp
f0101294:	c3                   	ret    

f0101295 <mmio_map_region>:
// location.  Return the base of the reserved region.  size does *not*
// have to be multiple of PGSIZE.
//
void *
mmio_map_region(physaddr_t pa, size_t size)
{
f0101295:	55                   	push   %ebp
f0101296:	89 e5                	mov    %esp,%ebp
f0101298:	53                   	push   %ebx
f0101299:	83 ec 04             	sub    $0x4,%esp
	// okay to simply panic if this happens).
	//
	// Hint: The staff solution uses boot_map_region.
	//
	// Your code here:
	size_t mmio_size = ROUNDUP(size, PGSIZE); 
f010129c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010129f:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
f01012a5:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	if(base + mmio_size > MMIOLIM)
f01012ab:	8b 15 00 03 12 f0    	mov    0xf0120300,%edx
f01012b1:	8d 04 13             	lea    (%ebx,%edx,1),%eax
f01012b4:	3d 00 00 c0 ef       	cmp    $0xefc00000,%eax
f01012b9:	76 17                	jbe    f01012d2 <mmio_map_region+0x3d>
		panic("no enough memory for MMIO map");
f01012bb:	83 ec 04             	sub    $0x4,%esp
f01012be:	68 69 69 10 f0       	push   $0xf0106969
f01012c3:	68 65 02 00 00       	push   $0x265
f01012c8:	68 72 68 10 f0       	push   $0xf0106872
f01012cd:	e8 6e ed ff ff       	call   f0100040 <_panic>
	boot_map_region(kern_pgdir, base, mmio_size, pa, PTE_PCD|PTE_PWT|PTE_W);
f01012d2:	83 ec 08             	sub    $0x8,%esp
f01012d5:	6a 1a                	push   $0x1a
f01012d7:	ff 75 08             	pushl  0x8(%ebp)
f01012da:	89 d9                	mov    %ebx,%ecx
f01012dc:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f01012e1:	e8 da fd ff ff       	call   f01010c0 <boot_map_region>
	uintptr_t res_base = base; 
f01012e6:	a1 00 03 12 f0       	mov    0xf0120300,%eax
	base += mmio_size;
f01012eb:	01 c3                	add    %eax,%ebx
f01012ed:	89 1d 00 03 12 f0    	mov    %ebx,0xf0120300
	return (void*)res_base;
	//panic("mmio_map_region not implemented");
}
f01012f3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01012f6:	c9                   	leave  
f01012f7:	c3                   	ret    

f01012f8 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01012f8:	55                   	push   %ebp
f01012f9:	89 e5                	mov    %esp,%ebp
f01012fb:	57                   	push   %edi
f01012fc:	56                   	push   %esi
f01012fd:	53                   	push   %ebx
f01012fe:	83 ec 48             	sub    $0x48,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101301:	6a 15                	push   $0x15
f0101303:	e8 9d 22 00 00       	call   f01035a5 <mc146818_read>
f0101308:	89 c3                	mov    %eax,%ebx
f010130a:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f0101311:	e8 8f 22 00 00       	call   f01035a5 <mc146818_read>
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0101316:	c1 e0 08             	shl    $0x8,%eax
f0101319:	09 d8                	or     %ebx,%eax
f010131b:	c1 e0 0a             	shl    $0xa,%eax
f010131e:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101324:	85 c0                	test   %eax,%eax
f0101326:	0f 48 c2             	cmovs  %edx,%eax
f0101329:	c1 f8 0c             	sar    $0xc,%eax
f010132c:	a3 44 f2 22 f0       	mov    %eax,0xf022f244
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101331:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f0101338:	e8 68 22 00 00       	call   f01035a5 <mc146818_read>
f010133d:	89 c3                	mov    %eax,%ebx
f010133f:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f0101346:	e8 5a 22 00 00       	call   f01035a5 <mc146818_read>
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f010134b:	c1 e0 08             	shl    $0x8,%eax
f010134e:	09 d8                	or     %ebx,%eax
f0101350:	c1 e0 0a             	shl    $0xa,%eax
f0101353:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101359:	83 c4 10             	add    $0x10,%esp
f010135c:	85 c0                	test   %eax,%eax
f010135e:	0f 48 c2             	cmovs  %edx,%eax
f0101361:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0101364:	85 c0                	test   %eax,%eax
f0101366:	74 0e                	je     f0101376 <mem_init+0x7e>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0101368:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f010136e:	89 15 88 fe 22 f0    	mov    %edx,0xf022fe88
f0101374:	eb 0c                	jmp    f0101382 <mem_init+0x8a>
	else
		npages = npages_basemem;
f0101376:	8b 15 44 f2 22 f0    	mov    0xf022f244,%edx
f010137c:	89 15 88 fe 22 f0    	mov    %edx,0xf022fe88

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101382:	c1 e0 0c             	shl    $0xc,%eax
f0101385:	c1 e8 0a             	shr    $0xa,%eax
f0101388:	50                   	push   %eax
f0101389:	a1 44 f2 22 f0       	mov    0xf022f244,%eax
f010138e:	c1 e0 0c             	shl    $0xc,%eax
f0101391:	c1 e8 0a             	shr    $0xa,%eax
f0101394:	50                   	push   %eax
f0101395:	a1 88 fe 22 f0       	mov    0xf022fe88,%eax
f010139a:	c1 e0 0c             	shl    $0xc,%eax
f010139d:	c1 e8 0a             	shr    $0xa,%eax
f01013a0:	50                   	push   %eax
f01013a1:	68 ac 6c 10 f0       	push   $0xf0106cac
f01013a6:	e8 79 23 00 00       	call   f0103724 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01013ab:	b8 00 10 00 00       	mov    $0x1000,%eax
f01013b0:	e8 95 f6 ff ff       	call   f0100a4a <boot_alloc>
f01013b5:	a3 8c fe 22 f0       	mov    %eax,0xf022fe8c
	memset(kern_pgdir, 0, PGSIZE);
f01013ba:	83 c4 0c             	add    $0xc,%esp
f01013bd:	68 00 10 00 00       	push   $0x1000
f01013c2:	6a 00                	push   $0x0
f01013c4:	50                   	push   %eax
f01013c5:	e8 5e 42 00 00       	call   f0105628 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01013ca:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01013cf:	83 c4 10             	add    $0x10,%esp
f01013d2:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01013d7:	77 15                	ja     f01013ee <mem_init+0xf6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01013d9:	50                   	push   %eax
f01013da:	68 28 63 10 f0       	push   $0xf0106328
f01013df:	68 98 00 00 00       	push   $0x98
f01013e4:	68 72 68 10 f0       	push   $0xf0106872
f01013e9:	e8 52 ec ff ff       	call   f0100040 <_panic>
f01013ee:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01013f4:	83 ca 05             	or     $0x5,%edx
f01013f7:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	uint32_t PageInfo_Size = sizeof(struct PageInfo) * npages; 
f01013fd:	a1 88 fe 22 f0       	mov    0xf022fe88,%eax
f0101402:	c1 e0 03             	shl    $0x3,%eax
f0101405:	89 c7                	mov    %eax,%edi
f0101407:	89 45 cc             	mov    %eax,-0x34(%ebp)
	pages = (struct PageInfo*)boot_alloc(PageInfo_Size);
f010140a:	e8 3b f6 ff ff       	call   f0100a4a <boot_alloc>
f010140f:	a3 90 fe 22 f0       	mov    %eax,0xf022fe90
	memset(pages, 0, PageInfo_Size); 
f0101414:	83 ec 04             	sub    $0x4,%esp
f0101417:	57                   	push   %edi
f0101418:	6a 00                	push   $0x0
f010141a:	50                   	push   %eax
f010141b:	e8 08 42 00 00       	call   f0105628 <memset>

	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	uint32_t Env_size = sizeof(struct Env) * NENV; 
	envs = (struct Env*)boot_alloc(Env_size); 
f0101420:	b8 00 f0 01 00       	mov    $0x1f000,%eax
f0101425:	e8 20 f6 ff ff       	call   f0100a4a <boot_alloc>
f010142a:	a3 48 f2 22 f0       	mov    %eax,0xf022f248
    	memset(envs, 0, Env_size); 
f010142f:	83 c4 0c             	add    $0xc,%esp
f0101432:	68 00 f0 01 00       	push   $0x1f000
f0101437:	6a 00                	push   $0x0
f0101439:	50                   	push   %eax
f010143a:	e8 e9 41 00 00       	call   f0105628 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f010143f:	e8 c7 f9 ff ff       	call   f0100e0b <page_init>

	check_page_free_list(1);
f0101444:	b8 01 00 00 00       	mov    $0x1,%eax
f0101449:	e8 ce f6 ff ff       	call   f0100b1c <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f010144e:	83 c4 10             	add    $0x10,%esp
f0101451:	83 3d 90 fe 22 f0 00 	cmpl   $0x0,0xf022fe90
f0101458:	75 17                	jne    f0101471 <mem_init+0x179>
		panic("'pages' is a null pointer!");
f010145a:	83 ec 04             	sub    $0x4,%esp
f010145d:	68 87 69 10 f0       	push   $0xf0106987
f0101462:	68 fb 02 00 00       	push   $0x2fb
f0101467:	68 72 68 10 f0       	push   $0xf0106872
f010146c:	e8 cf eb ff ff       	call   f0100040 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101471:	a1 40 f2 22 f0       	mov    0xf022f240,%eax
f0101476:	bb 00 00 00 00       	mov    $0x0,%ebx
f010147b:	eb 05                	jmp    f0101482 <mem_init+0x18a>
		++nfree;
f010147d:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101480:	8b 00                	mov    (%eax),%eax
f0101482:	85 c0                	test   %eax,%eax
f0101484:	75 f7                	jne    f010147d <mem_init+0x185>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101486:	83 ec 0c             	sub    $0xc,%esp
f0101489:	6a 00                	push   $0x0
f010148b:	e8 7b fa ff ff       	call   f0100f0b <page_alloc>
f0101490:	89 c7                	mov    %eax,%edi
f0101492:	83 c4 10             	add    $0x10,%esp
f0101495:	85 c0                	test   %eax,%eax
f0101497:	75 19                	jne    f01014b2 <mem_init+0x1ba>
f0101499:	68 a2 69 10 f0       	push   $0xf01069a2
f010149e:	68 98 68 10 f0       	push   $0xf0106898
f01014a3:	68 03 03 00 00       	push   $0x303
f01014a8:	68 72 68 10 f0       	push   $0xf0106872
f01014ad:	e8 8e eb ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01014b2:	83 ec 0c             	sub    $0xc,%esp
f01014b5:	6a 00                	push   $0x0
f01014b7:	e8 4f fa ff ff       	call   f0100f0b <page_alloc>
f01014bc:	89 c6                	mov    %eax,%esi
f01014be:	83 c4 10             	add    $0x10,%esp
f01014c1:	85 c0                	test   %eax,%eax
f01014c3:	75 19                	jne    f01014de <mem_init+0x1e6>
f01014c5:	68 b8 69 10 f0       	push   $0xf01069b8
f01014ca:	68 98 68 10 f0       	push   $0xf0106898
f01014cf:	68 04 03 00 00       	push   $0x304
f01014d4:	68 72 68 10 f0       	push   $0xf0106872
f01014d9:	e8 62 eb ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01014de:	83 ec 0c             	sub    $0xc,%esp
f01014e1:	6a 00                	push   $0x0
f01014e3:	e8 23 fa ff ff       	call   f0100f0b <page_alloc>
f01014e8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01014eb:	83 c4 10             	add    $0x10,%esp
f01014ee:	85 c0                	test   %eax,%eax
f01014f0:	75 19                	jne    f010150b <mem_init+0x213>
f01014f2:	68 ce 69 10 f0       	push   $0xf01069ce
f01014f7:	68 98 68 10 f0       	push   $0xf0106898
f01014fc:	68 05 03 00 00       	push   $0x305
f0101501:	68 72 68 10 f0       	push   $0xf0106872
f0101506:	e8 35 eb ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010150b:	39 f7                	cmp    %esi,%edi
f010150d:	75 19                	jne    f0101528 <mem_init+0x230>
f010150f:	68 e4 69 10 f0       	push   $0xf01069e4
f0101514:	68 98 68 10 f0       	push   $0xf0106898
f0101519:	68 08 03 00 00       	push   $0x308
f010151e:	68 72 68 10 f0       	push   $0xf0106872
f0101523:	e8 18 eb ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101528:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010152b:	39 c6                	cmp    %eax,%esi
f010152d:	74 04                	je     f0101533 <mem_init+0x23b>
f010152f:	39 c7                	cmp    %eax,%edi
f0101531:	75 19                	jne    f010154c <mem_init+0x254>
f0101533:	68 e8 6c 10 f0       	push   $0xf0106ce8
f0101538:	68 98 68 10 f0       	push   $0xf0106898
f010153d:	68 09 03 00 00       	push   $0x309
f0101542:	68 72 68 10 f0       	push   $0xf0106872
f0101547:	e8 f4 ea ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010154c:	8b 0d 90 fe 22 f0    	mov    0xf022fe90,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101552:	8b 15 88 fe 22 f0    	mov    0xf022fe88,%edx
f0101558:	c1 e2 0c             	shl    $0xc,%edx
f010155b:	89 f8                	mov    %edi,%eax
f010155d:	29 c8                	sub    %ecx,%eax
f010155f:	c1 f8 03             	sar    $0x3,%eax
f0101562:	c1 e0 0c             	shl    $0xc,%eax
f0101565:	39 d0                	cmp    %edx,%eax
f0101567:	72 19                	jb     f0101582 <mem_init+0x28a>
f0101569:	68 f6 69 10 f0       	push   $0xf01069f6
f010156e:	68 98 68 10 f0       	push   $0xf0106898
f0101573:	68 0a 03 00 00       	push   $0x30a
f0101578:	68 72 68 10 f0       	push   $0xf0106872
f010157d:	e8 be ea ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101582:	89 f0                	mov    %esi,%eax
f0101584:	29 c8                	sub    %ecx,%eax
f0101586:	c1 f8 03             	sar    $0x3,%eax
f0101589:	c1 e0 0c             	shl    $0xc,%eax
f010158c:	39 c2                	cmp    %eax,%edx
f010158e:	77 19                	ja     f01015a9 <mem_init+0x2b1>
f0101590:	68 13 6a 10 f0       	push   $0xf0106a13
f0101595:	68 98 68 10 f0       	push   $0xf0106898
f010159a:	68 0b 03 00 00       	push   $0x30b
f010159f:	68 72 68 10 f0       	push   $0xf0106872
f01015a4:	e8 97 ea ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01015a9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01015ac:	29 c8                	sub    %ecx,%eax
f01015ae:	c1 f8 03             	sar    $0x3,%eax
f01015b1:	c1 e0 0c             	shl    $0xc,%eax
f01015b4:	39 c2                	cmp    %eax,%edx
f01015b6:	77 19                	ja     f01015d1 <mem_init+0x2d9>
f01015b8:	68 30 6a 10 f0       	push   $0xf0106a30
f01015bd:	68 98 68 10 f0       	push   $0xf0106898
f01015c2:	68 0c 03 00 00       	push   $0x30c
f01015c7:	68 72 68 10 f0       	push   $0xf0106872
f01015cc:	e8 6f ea ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01015d1:	a1 40 f2 22 f0       	mov    0xf022f240,%eax
f01015d6:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01015d9:	c7 05 40 f2 22 f0 00 	movl   $0x0,0xf022f240
f01015e0:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01015e3:	83 ec 0c             	sub    $0xc,%esp
f01015e6:	6a 00                	push   $0x0
f01015e8:	e8 1e f9 ff ff       	call   f0100f0b <page_alloc>
f01015ed:	83 c4 10             	add    $0x10,%esp
f01015f0:	85 c0                	test   %eax,%eax
f01015f2:	74 19                	je     f010160d <mem_init+0x315>
f01015f4:	68 4d 6a 10 f0       	push   $0xf0106a4d
f01015f9:	68 98 68 10 f0       	push   $0xf0106898
f01015fe:	68 13 03 00 00       	push   $0x313
f0101603:	68 72 68 10 f0       	push   $0xf0106872
f0101608:	e8 33 ea ff ff       	call   f0100040 <_panic>

	// free and re-allocate?
	page_free(pp0);
f010160d:	83 ec 0c             	sub    $0xc,%esp
f0101610:	57                   	push   %edi
f0101611:	e8 65 f9 ff ff       	call   f0100f7b <page_free>
	page_free(pp1);
f0101616:	89 34 24             	mov    %esi,(%esp)
f0101619:	e8 5d f9 ff ff       	call   f0100f7b <page_free>
	page_free(pp2);
f010161e:	83 c4 04             	add    $0x4,%esp
f0101621:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101624:	e8 52 f9 ff ff       	call   f0100f7b <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101629:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101630:	e8 d6 f8 ff ff       	call   f0100f0b <page_alloc>
f0101635:	89 c6                	mov    %eax,%esi
f0101637:	83 c4 10             	add    $0x10,%esp
f010163a:	85 c0                	test   %eax,%eax
f010163c:	75 19                	jne    f0101657 <mem_init+0x35f>
f010163e:	68 a2 69 10 f0       	push   $0xf01069a2
f0101643:	68 98 68 10 f0       	push   $0xf0106898
f0101648:	68 1a 03 00 00       	push   $0x31a
f010164d:	68 72 68 10 f0       	push   $0xf0106872
f0101652:	e8 e9 e9 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101657:	83 ec 0c             	sub    $0xc,%esp
f010165a:	6a 00                	push   $0x0
f010165c:	e8 aa f8 ff ff       	call   f0100f0b <page_alloc>
f0101661:	89 c7                	mov    %eax,%edi
f0101663:	83 c4 10             	add    $0x10,%esp
f0101666:	85 c0                	test   %eax,%eax
f0101668:	75 19                	jne    f0101683 <mem_init+0x38b>
f010166a:	68 b8 69 10 f0       	push   $0xf01069b8
f010166f:	68 98 68 10 f0       	push   $0xf0106898
f0101674:	68 1b 03 00 00       	push   $0x31b
f0101679:	68 72 68 10 f0       	push   $0xf0106872
f010167e:	e8 bd e9 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101683:	83 ec 0c             	sub    $0xc,%esp
f0101686:	6a 00                	push   $0x0
f0101688:	e8 7e f8 ff ff       	call   f0100f0b <page_alloc>
f010168d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101690:	83 c4 10             	add    $0x10,%esp
f0101693:	85 c0                	test   %eax,%eax
f0101695:	75 19                	jne    f01016b0 <mem_init+0x3b8>
f0101697:	68 ce 69 10 f0       	push   $0xf01069ce
f010169c:	68 98 68 10 f0       	push   $0xf0106898
f01016a1:	68 1c 03 00 00       	push   $0x31c
f01016a6:	68 72 68 10 f0       	push   $0xf0106872
f01016ab:	e8 90 e9 ff ff       	call   f0100040 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01016b0:	39 fe                	cmp    %edi,%esi
f01016b2:	75 19                	jne    f01016cd <mem_init+0x3d5>
f01016b4:	68 e4 69 10 f0       	push   $0xf01069e4
f01016b9:	68 98 68 10 f0       	push   $0xf0106898
f01016be:	68 1e 03 00 00       	push   $0x31e
f01016c3:	68 72 68 10 f0       	push   $0xf0106872
f01016c8:	e8 73 e9 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01016cd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01016d0:	39 c7                	cmp    %eax,%edi
f01016d2:	74 04                	je     f01016d8 <mem_init+0x3e0>
f01016d4:	39 c6                	cmp    %eax,%esi
f01016d6:	75 19                	jne    f01016f1 <mem_init+0x3f9>
f01016d8:	68 e8 6c 10 f0       	push   $0xf0106ce8
f01016dd:	68 98 68 10 f0       	push   $0xf0106898
f01016e2:	68 1f 03 00 00       	push   $0x31f
f01016e7:	68 72 68 10 f0       	push   $0xf0106872
f01016ec:	e8 4f e9 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f01016f1:	83 ec 0c             	sub    $0xc,%esp
f01016f4:	6a 00                	push   $0x0
f01016f6:	e8 10 f8 ff ff       	call   f0100f0b <page_alloc>
f01016fb:	83 c4 10             	add    $0x10,%esp
f01016fe:	85 c0                	test   %eax,%eax
f0101700:	74 19                	je     f010171b <mem_init+0x423>
f0101702:	68 4d 6a 10 f0       	push   $0xf0106a4d
f0101707:	68 98 68 10 f0       	push   $0xf0106898
f010170c:	68 20 03 00 00       	push   $0x320
f0101711:	68 72 68 10 f0       	push   $0xf0106872
f0101716:	e8 25 e9 ff ff       	call   f0100040 <_panic>
f010171b:	89 f0                	mov    %esi,%eax
f010171d:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0101723:	c1 f8 03             	sar    $0x3,%eax
f0101726:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101729:	89 c2                	mov    %eax,%edx
f010172b:	c1 ea 0c             	shr    $0xc,%edx
f010172e:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f0101734:	72 12                	jb     f0101748 <mem_init+0x450>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101736:	50                   	push   %eax
f0101737:	68 04 63 10 f0       	push   $0xf0106304
f010173c:	6a 58                	push   $0x58
f010173e:	68 7e 68 10 f0       	push   $0xf010687e
f0101743:	e8 f8 e8 ff ff       	call   f0100040 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101748:	83 ec 04             	sub    $0x4,%esp
f010174b:	68 00 10 00 00       	push   $0x1000
f0101750:	6a 01                	push   $0x1
f0101752:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101757:	50                   	push   %eax
f0101758:	e8 cb 3e 00 00       	call   f0105628 <memset>
	page_free(pp0);
f010175d:	89 34 24             	mov    %esi,(%esp)
f0101760:	e8 16 f8 ff ff       	call   f0100f7b <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101765:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010176c:	e8 9a f7 ff ff       	call   f0100f0b <page_alloc>
f0101771:	83 c4 10             	add    $0x10,%esp
f0101774:	85 c0                	test   %eax,%eax
f0101776:	75 19                	jne    f0101791 <mem_init+0x499>
f0101778:	68 5c 6a 10 f0       	push   $0xf0106a5c
f010177d:	68 98 68 10 f0       	push   $0xf0106898
f0101782:	68 25 03 00 00       	push   $0x325
f0101787:	68 72 68 10 f0       	push   $0xf0106872
f010178c:	e8 af e8 ff ff       	call   f0100040 <_panic>
	assert(pp && pp0 == pp);
f0101791:	39 c6                	cmp    %eax,%esi
f0101793:	74 19                	je     f01017ae <mem_init+0x4b6>
f0101795:	68 7a 6a 10 f0       	push   $0xf0106a7a
f010179a:	68 98 68 10 f0       	push   $0xf0106898
f010179f:	68 26 03 00 00       	push   $0x326
f01017a4:	68 72 68 10 f0       	push   $0xf0106872
f01017a9:	e8 92 e8 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01017ae:	89 f0                	mov    %esi,%eax
f01017b0:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f01017b6:	c1 f8 03             	sar    $0x3,%eax
f01017b9:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01017bc:	89 c2                	mov    %eax,%edx
f01017be:	c1 ea 0c             	shr    $0xc,%edx
f01017c1:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f01017c7:	72 12                	jb     f01017db <mem_init+0x4e3>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01017c9:	50                   	push   %eax
f01017ca:	68 04 63 10 f0       	push   $0xf0106304
f01017cf:	6a 58                	push   $0x58
f01017d1:	68 7e 68 10 f0       	push   $0xf010687e
f01017d6:	e8 65 e8 ff ff       	call   f0100040 <_panic>
f01017db:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01017e1:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01017e7:	80 38 00             	cmpb   $0x0,(%eax)
f01017ea:	74 19                	je     f0101805 <mem_init+0x50d>
f01017ec:	68 8a 6a 10 f0       	push   $0xf0106a8a
f01017f1:	68 98 68 10 f0       	push   $0xf0106898
f01017f6:	68 29 03 00 00       	push   $0x329
f01017fb:	68 72 68 10 f0       	push   $0xf0106872
f0101800:	e8 3b e8 ff ff       	call   f0100040 <_panic>
f0101805:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101808:	39 d0                	cmp    %edx,%eax
f010180a:	75 db                	jne    f01017e7 <mem_init+0x4ef>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f010180c:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010180f:	a3 40 f2 22 f0       	mov    %eax,0xf022f240

	// free the pages we took
	page_free(pp0);
f0101814:	83 ec 0c             	sub    $0xc,%esp
f0101817:	56                   	push   %esi
f0101818:	e8 5e f7 ff ff       	call   f0100f7b <page_free>
	page_free(pp1);
f010181d:	89 3c 24             	mov    %edi,(%esp)
f0101820:	e8 56 f7 ff ff       	call   f0100f7b <page_free>
	page_free(pp2);
f0101825:	83 c4 04             	add    $0x4,%esp
f0101828:	ff 75 d4             	pushl  -0x2c(%ebp)
f010182b:	e8 4b f7 ff ff       	call   f0100f7b <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101830:	a1 40 f2 22 f0       	mov    0xf022f240,%eax
f0101835:	83 c4 10             	add    $0x10,%esp
f0101838:	eb 05                	jmp    f010183f <mem_init+0x547>
		--nfree;
f010183a:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010183d:	8b 00                	mov    (%eax),%eax
f010183f:	85 c0                	test   %eax,%eax
f0101841:	75 f7                	jne    f010183a <mem_init+0x542>
		--nfree;
	assert(nfree == 0);
f0101843:	85 db                	test   %ebx,%ebx
f0101845:	74 19                	je     f0101860 <mem_init+0x568>
f0101847:	68 94 6a 10 f0       	push   $0xf0106a94
f010184c:	68 98 68 10 f0       	push   $0xf0106898
f0101851:	68 36 03 00 00       	push   $0x336
f0101856:	68 72 68 10 f0       	push   $0xf0106872
f010185b:	e8 e0 e7 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101860:	83 ec 0c             	sub    $0xc,%esp
f0101863:	68 08 6d 10 f0       	push   $0xf0106d08
f0101868:	e8 b7 1e 00 00       	call   f0103724 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010186d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101874:	e8 92 f6 ff ff       	call   f0100f0b <page_alloc>
f0101879:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010187c:	83 c4 10             	add    $0x10,%esp
f010187f:	85 c0                	test   %eax,%eax
f0101881:	75 19                	jne    f010189c <mem_init+0x5a4>
f0101883:	68 a2 69 10 f0       	push   $0xf01069a2
f0101888:	68 98 68 10 f0       	push   $0xf0106898
f010188d:	68 9c 03 00 00       	push   $0x39c
f0101892:	68 72 68 10 f0       	push   $0xf0106872
f0101897:	e8 a4 e7 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f010189c:	83 ec 0c             	sub    $0xc,%esp
f010189f:	6a 00                	push   $0x0
f01018a1:	e8 65 f6 ff ff       	call   f0100f0b <page_alloc>
f01018a6:	89 c3                	mov    %eax,%ebx
f01018a8:	83 c4 10             	add    $0x10,%esp
f01018ab:	85 c0                	test   %eax,%eax
f01018ad:	75 19                	jne    f01018c8 <mem_init+0x5d0>
f01018af:	68 b8 69 10 f0       	push   $0xf01069b8
f01018b4:	68 98 68 10 f0       	push   $0xf0106898
f01018b9:	68 9d 03 00 00       	push   $0x39d
f01018be:	68 72 68 10 f0       	push   $0xf0106872
f01018c3:	e8 78 e7 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01018c8:	83 ec 0c             	sub    $0xc,%esp
f01018cb:	6a 00                	push   $0x0
f01018cd:	e8 39 f6 ff ff       	call   f0100f0b <page_alloc>
f01018d2:	89 c6                	mov    %eax,%esi
f01018d4:	83 c4 10             	add    $0x10,%esp
f01018d7:	85 c0                	test   %eax,%eax
f01018d9:	75 19                	jne    f01018f4 <mem_init+0x5fc>
f01018db:	68 ce 69 10 f0       	push   $0xf01069ce
f01018e0:	68 98 68 10 f0       	push   $0xf0106898
f01018e5:	68 9e 03 00 00       	push   $0x39e
f01018ea:	68 72 68 10 f0       	push   $0xf0106872
f01018ef:	e8 4c e7 ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01018f4:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01018f7:	75 19                	jne    f0101912 <mem_init+0x61a>
f01018f9:	68 e4 69 10 f0       	push   $0xf01069e4
f01018fe:	68 98 68 10 f0       	push   $0xf0106898
f0101903:	68 a1 03 00 00       	push   $0x3a1
f0101908:	68 72 68 10 f0       	push   $0xf0106872
f010190d:	e8 2e e7 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101912:	39 c3                	cmp    %eax,%ebx
f0101914:	74 05                	je     f010191b <mem_init+0x623>
f0101916:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101919:	75 19                	jne    f0101934 <mem_init+0x63c>
f010191b:	68 e8 6c 10 f0       	push   $0xf0106ce8
f0101920:	68 98 68 10 f0       	push   $0xf0106898
f0101925:	68 a2 03 00 00       	push   $0x3a2
f010192a:	68 72 68 10 f0       	push   $0xf0106872
f010192f:	e8 0c e7 ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101934:	a1 40 f2 22 f0       	mov    0xf022f240,%eax
f0101939:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010193c:	c7 05 40 f2 22 f0 00 	movl   $0x0,0xf022f240
f0101943:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101946:	83 ec 0c             	sub    $0xc,%esp
f0101949:	6a 00                	push   $0x0
f010194b:	e8 bb f5 ff ff       	call   f0100f0b <page_alloc>
f0101950:	83 c4 10             	add    $0x10,%esp
f0101953:	85 c0                	test   %eax,%eax
f0101955:	74 19                	je     f0101970 <mem_init+0x678>
f0101957:	68 4d 6a 10 f0       	push   $0xf0106a4d
f010195c:	68 98 68 10 f0       	push   $0xf0106898
f0101961:	68 a9 03 00 00       	push   $0x3a9
f0101966:	68 72 68 10 f0       	push   $0xf0106872
f010196b:	e8 d0 e6 ff ff       	call   f0100040 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101970:	83 ec 04             	sub    $0x4,%esp
f0101973:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101976:	50                   	push   %eax
f0101977:	6a 00                	push   $0x0
f0101979:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f010197f:	e8 9a f7 ff ff       	call   f010111e <page_lookup>
f0101984:	83 c4 10             	add    $0x10,%esp
f0101987:	85 c0                	test   %eax,%eax
f0101989:	74 19                	je     f01019a4 <mem_init+0x6ac>
f010198b:	68 28 6d 10 f0       	push   $0xf0106d28
f0101990:	68 98 68 10 f0       	push   $0xf0106898
f0101995:	68 ac 03 00 00       	push   $0x3ac
f010199a:	68 72 68 10 f0       	push   $0xf0106872
f010199f:	e8 9c e6 ff ff       	call   f0100040 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01019a4:	6a 02                	push   $0x2
f01019a6:	6a 00                	push   $0x0
f01019a8:	53                   	push   %ebx
f01019a9:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f01019af:	e8 3f f8 ff ff       	call   f01011f3 <page_insert>
f01019b4:	83 c4 10             	add    $0x10,%esp
f01019b7:	85 c0                	test   %eax,%eax
f01019b9:	78 19                	js     f01019d4 <mem_init+0x6dc>
f01019bb:	68 60 6d 10 f0       	push   $0xf0106d60
f01019c0:	68 98 68 10 f0       	push   $0xf0106898
f01019c5:	68 af 03 00 00       	push   $0x3af
f01019ca:	68 72 68 10 f0       	push   $0xf0106872
f01019cf:	e8 6c e6 ff ff       	call   f0100040 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01019d4:	83 ec 0c             	sub    $0xc,%esp
f01019d7:	ff 75 d4             	pushl  -0x2c(%ebp)
f01019da:	e8 9c f5 ff ff       	call   f0100f7b <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01019df:	6a 02                	push   $0x2
f01019e1:	6a 00                	push   $0x0
f01019e3:	53                   	push   %ebx
f01019e4:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f01019ea:	e8 04 f8 ff ff       	call   f01011f3 <page_insert>
f01019ef:	83 c4 20             	add    $0x20,%esp
f01019f2:	85 c0                	test   %eax,%eax
f01019f4:	74 19                	je     f0101a0f <mem_init+0x717>
f01019f6:	68 90 6d 10 f0       	push   $0xf0106d90
f01019fb:	68 98 68 10 f0       	push   $0xf0106898
f0101a00:	68 b3 03 00 00       	push   $0x3b3
f0101a05:	68 72 68 10 f0       	push   $0xf0106872
f0101a0a:	e8 31 e6 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101a0f:	8b 3d 8c fe 22 f0    	mov    0xf022fe8c,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101a15:	a1 90 fe 22 f0       	mov    0xf022fe90,%eax
f0101a1a:	89 c1                	mov    %eax,%ecx
f0101a1c:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0101a1f:	8b 17                	mov    (%edi),%edx
f0101a21:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101a27:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a2a:	29 c8                	sub    %ecx,%eax
f0101a2c:	c1 f8 03             	sar    $0x3,%eax
f0101a2f:	c1 e0 0c             	shl    $0xc,%eax
f0101a32:	39 c2                	cmp    %eax,%edx
f0101a34:	74 19                	je     f0101a4f <mem_init+0x757>
f0101a36:	68 c0 6d 10 f0       	push   $0xf0106dc0
f0101a3b:	68 98 68 10 f0       	push   $0xf0106898
f0101a40:	68 b4 03 00 00       	push   $0x3b4
f0101a45:	68 72 68 10 f0       	push   $0xf0106872
f0101a4a:	e8 f1 e5 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101a4f:	ba 00 00 00 00       	mov    $0x0,%edx
f0101a54:	89 f8                	mov    %edi,%eax
f0101a56:	e8 5d f0 ff ff       	call   f0100ab8 <check_va2pa>
f0101a5b:	89 da                	mov    %ebx,%edx
f0101a5d:	2b 55 c8             	sub    -0x38(%ebp),%edx
f0101a60:	c1 fa 03             	sar    $0x3,%edx
f0101a63:	c1 e2 0c             	shl    $0xc,%edx
f0101a66:	39 d0                	cmp    %edx,%eax
f0101a68:	74 19                	je     f0101a83 <mem_init+0x78b>
f0101a6a:	68 e8 6d 10 f0       	push   $0xf0106de8
f0101a6f:	68 98 68 10 f0       	push   $0xf0106898
f0101a74:	68 b5 03 00 00       	push   $0x3b5
f0101a79:	68 72 68 10 f0       	push   $0xf0106872
f0101a7e:	e8 bd e5 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0101a83:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101a88:	74 19                	je     f0101aa3 <mem_init+0x7ab>
f0101a8a:	68 9f 6a 10 f0       	push   $0xf0106a9f
f0101a8f:	68 98 68 10 f0       	push   $0xf0106898
f0101a94:	68 b6 03 00 00       	push   $0x3b6
f0101a99:	68 72 68 10 f0       	push   $0xf0106872
f0101a9e:	e8 9d e5 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f0101aa3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101aa6:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101aab:	74 19                	je     f0101ac6 <mem_init+0x7ce>
f0101aad:	68 b0 6a 10 f0       	push   $0xf0106ab0
f0101ab2:	68 98 68 10 f0       	push   $0xf0106898
f0101ab7:	68 b7 03 00 00       	push   $0x3b7
f0101abc:	68 72 68 10 f0       	push   $0xf0106872
f0101ac1:	e8 7a e5 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ac6:	6a 02                	push   $0x2
f0101ac8:	68 00 10 00 00       	push   $0x1000
f0101acd:	56                   	push   %esi
f0101ace:	57                   	push   %edi
f0101acf:	e8 1f f7 ff ff       	call   f01011f3 <page_insert>
f0101ad4:	83 c4 10             	add    $0x10,%esp
f0101ad7:	85 c0                	test   %eax,%eax
f0101ad9:	74 19                	je     f0101af4 <mem_init+0x7fc>
f0101adb:	68 18 6e 10 f0       	push   $0xf0106e18
f0101ae0:	68 98 68 10 f0       	push   $0xf0106898
f0101ae5:	68 ba 03 00 00       	push   $0x3ba
f0101aea:	68 72 68 10 f0       	push   $0xf0106872
f0101aef:	e8 4c e5 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101af4:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101af9:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f0101afe:	e8 b5 ef ff ff       	call   f0100ab8 <check_va2pa>
f0101b03:	89 f2                	mov    %esi,%edx
f0101b05:	2b 15 90 fe 22 f0    	sub    0xf022fe90,%edx
f0101b0b:	c1 fa 03             	sar    $0x3,%edx
f0101b0e:	c1 e2 0c             	shl    $0xc,%edx
f0101b11:	39 d0                	cmp    %edx,%eax
f0101b13:	74 19                	je     f0101b2e <mem_init+0x836>
f0101b15:	68 54 6e 10 f0       	push   $0xf0106e54
f0101b1a:	68 98 68 10 f0       	push   $0xf0106898
f0101b1f:	68 bb 03 00 00       	push   $0x3bb
f0101b24:	68 72 68 10 f0       	push   $0xf0106872
f0101b29:	e8 12 e5 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101b2e:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101b33:	74 19                	je     f0101b4e <mem_init+0x856>
f0101b35:	68 c1 6a 10 f0       	push   $0xf0106ac1
f0101b3a:	68 98 68 10 f0       	push   $0xf0106898
f0101b3f:	68 bc 03 00 00       	push   $0x3bc
f0101b44:	68 72 68 10 f0       	push   $0xf0106872
f0101b49:	e8 f2 e4 ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101b4e:	83 ec 0c             	sub    $0xc,%esp
f0101b51:	6a 00                	push   $0x0
f0101b53:	e8 b3 f3 ff ff       	call   f0100f0b <page_alloc>
f0101b58:	83 c4 10             	add    $0x10,%esp
f0101b5b:	85 c0                	test   %eax,%eax
f0101b5d:	74 19                	je     f0101b78 <mem_init+0x880>
f0101b5f:	68 4d 6a 10 f0       	push   $0xf0106a4d
f0101b64:	68 98 68 10 f0       	push   $0xf0106898
f0101b69:	68 bf 03 00 00       	push   $0x3bf
f0101b6e:	68 72 68 10 f0       	push   $0xf0106872
f0101b73:	e8 c8 e4 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b78:	6a 02                	push   $0x2
f0101b7a:	68 00 10 00 00       	push   $0x1000
f0101b7f:	56                   	push   %esi
f0101b80:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101b86:	e8 68 f6 ff ff       	call   f01011f3 <page_insert>
f0101b8b:	83 c4 10             	add    $0x10,%esp
f0101b8e:	85 c0                	test   %eax,%eax
f0101b90:	74 19                	je     f0101bab <mem_init+0x8b3>
f0101b92:	68 18 6e 10 f0       	push   $0xf0106e18
f0101b97:	68 98 68 10 f0       	push   $0xf0106898
f0101b9c:	68 c2 03 00 00       	push   $0x3c2
f0101ba1:	68 72 68 10 f0       	push   $0xf0106872
f0101ba6:	e8 95 e4 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101bab:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101bb0:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f0101bb5:	e8 fe ee ff ff       	call   f0100ab8 <check_va2pa>
f0101bba:	89 f2                	mov    %esi,%edx
f0101bbc:	2b 15 90 fe 22 f0    	sub    0xf022fe90,%edx
f0101bc2:	c1 fa 03             	sar    $0x3,%edx
f0101bc5:	c1 e2 0c             	shl    $0xc,%edx
f0101bc8:	39 d0                	cmp    %edx,%eax
f0101bca:	74 19                	je     f0101be5 <mem_init+0x8ed>
f0101bcc:	68 54 6e 10 f0       	push   $0xf0106e54
f0101bd1:	68 98 68 10 f0       	push   $0xf0106898
f0101bd6:	68 c3 03 00 00       	push   $0x3c3
f0101bdb:	68 72 68 10 f0       	push   $0xf0106872
f0101be0:	e8 5b e4 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101be5:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101bea:	74 19                	je     f0101c05 <mem_init+0x90d>
f0101bec:	68 c1 6a 10 f0       	push   $0xf0106ac1
f0101bf1:	68 98 68 10 f0       	push   $0xf0106898
f0101bf6:	68 c4 03 00 00       	push   $0x3c4
f0101bfb:	68 72 68 10 f0       	push   $0xf0106872
f0101c00:	e8 3b e4 ff ff       	call   f0100040 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101c05:	83 ec 0c             	sub    $0xc,%esp
f0101c08:	6a 00                	push   $0x0
f0101c0a:	e8 fc f2 ff ff       	call   f0100f0b <page_alloc>
f0101c0f:	83 c4 10             	add    $0x10,%esp
f0101c12:	85 c0                	test   %eax,%eax
f0101c14:	74 19                	je     f0101c2f <mem_init+0x937>
f0101c16:	68 4d 6a 10 f0       	push   $0xf0106a4d
f0101c1b:	68 98 68 10 f0       	push   $0xf0106898
f0101c20:	68 c8 03 00 00       	push   $0x3c8
f0101c25:	68 72 68 10 f0       	push   $0xf0106872
f0101c2a:	e8 11 e4 ff ff       	call   f0100040 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101c2f:	8b 15 8c fe 22 f0    	mov    0xf022fe8c,%edx
f0101c35:	8b 02                	mov    (%edx),%eax
f0101c37:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101c3c:	89 c1                	mov    %eax,%ecx
f0101c3e:	c1 e9 0c             	shr    $0xc,%ecx
f0101c41:	3b 0d 88 fe 22 f0    	cmp    0xf022fe88,%ecx
f0101c47:	72 15                	jb     f0101c5e <mem_init+0x966>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101c49:	50                   	push   %eax
f0101c4a:	68 04 63 10 f0       	push   $0xf0106304
f0101c4f:	68 cb 03 00 00       	push   $0x3cb
f0101c54:	68 72 68 10 f0       	push   $0xf0106872
f0101c59:	e8 e2 e3 ff ff       	call   f0100040 <_panic>
f0101c5e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101c63:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101c66:	83 ec 04             	sub    $0x4,%esp
f0101c69:	6a 00                	push   $0x0
f0101c6b:	68 00 10 00 00       	push   $0x1000
f0101c70:	52                   	push   %edx
f0101c71:	e8 82 f3 ff ff       	call   f0100ff8 <pgdir_walk>
f0101c76:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101c79:	8d 51 04             	lea    0x4(%ecx),%edx
f0101c7c:	83 c4 10             	add    $0x10,%esp
f0101c7f:	39 d0                	cmp    %edx,%eax
f0101c81:	74 19                	je     f0101c9c <mem_init+0x9a4>
f0101c83:	68 84 6e 10 f0       	push   $0xf0106e84
f0101c88:	68 98 68 10 f0       	push   $0xf0106898
f0101c8d:	68 cc 03 00 00       	push   $0x3cc
f0101c92:	68 72 68 10 f0       	push   $0xf0106872
f0101c97:	e8 a4 e3 ff ff       	call   f0100040 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101c9c:	6a 06                	push   $0x6
f0101c9e:	68 00 10 00 00       	push   $0x1000
f0101ca3:	56                   	push   %esi
f0101ca4:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101caa:	e8 44 f5 ff ff       	call   f01011f3 <page_insert>
f0101caf:	83 c4 10             	add    $0x10,%esp
f0101cb2:	85 c0                	test   %eax,%eax
f0101cb4:	74 19                	je     f0101ccf <mem_init+0x9d7>
f0101cb6:	68 c4 6e 10 f0       	push   $0xf0106ec4
f0101cbb:	68 98 68 10 f0       	push   $0xf0106898
f0101cc0:	68 cf 03 00 00       	push   $0x3cf
f0101cc5:	68 72 68 10 f0       	push   $0xf0106872
f0101cca:	e8 71 e3 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101ccf:	8b 3d 8c fe 22 f0    	mov    0xf022fe8c,%edi
f0101cd5:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101cda:	89 f8                	mov    %edi,%eax
f0101cdc:	e8 d7 ed ff ff       	call   f0100ab8 <check_va2pa>
f0101ce1:	89 f2                	mov    %esi,%edx
f0101ce3:	2b 15 90 fe 22 f0    	sub    0xf022fe90,%edx
f0101ce9:	c1 fa 03             	sar    $0x3,%edx
f0101cec:	c1 e2 0c             	shl    $0xc,%edx
f0101cef:	39 d0                	cmp    %edx,%eax
f0101cf1:	74 19                	je     f0101d0c <mem_init+0xa14>
f0101cf3:	68 54 6e 10 f0       	push   $0xf0106e54
f0101cf8:	68 98 68 10 f0       	push   $0xf0106898
f0101cfd:	68 d0 03 00 00       	push   $0x3d0
f0101d02:	68 72 68 10 f0       	push   $0xf0106872
f0101d07:	e8 34 e3 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101d0c:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101d11:	74 19                	je     f0101d2c <mem_init+0xa34>
f0101d13:	68 c1 6a 10 f0       	push   $0xf0106ac1
f0101d18:	68 98 68 10 f0       	push   $0xf0106898
f0101d1d:	68 d1 03 00 00       	push   $0x3d1
f0101d22:	68 72 68 10 f0       	push   $0xf0106872
f0101d27:	e8 14 e3 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101d2c:	83 ec 04             	sub    $0x4,%esp
f0101d2f:	6a 00                	push   $0x0
f0101d31:	68 00 10 00 00       	push   $0x1000
f0101d36:	57                   	push   %edi
f0101d37:	e8 bc f2 ff ff       	call   f0100ff8 <pgdir_walk>
f0101d3c:	83 c4 10             	add    $0x10,%esp
f0101d3f:	f6 00 04             	testb  $0x4,(%eax)
f0101d42:	75 19                	jne    f0101d5d <mem_init+0xa65>
f0101d44:	68 04 6f 10 f0       	push   $0xf0106f04
f0101d49:	68 98 68 10 f0       	push   $0xf0106898
f0101d4e:	68 d2 03 00 00       	push   $0x3d2
f0101d53:	68 72 68 10 f0       	push   $0xf0106872
f0101d58:	e8 e3 e2 ff ff       	call   f0100040 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101d5d:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f0101d62:	f6 00 04             	testb  $0x4,(%eax)
f0101d65:	75 19                	jne    f0101d80 <mem_init+0xa88>
f0101d67:	68 d2 6a 10 f0       	push   $0xf0106ad2
f0101d6c:	68 98 68 10 f0       	push   $0xf0106898
f0101d71:	68 d3 03 00 00       	push   $0x3d3
f0101d76:	68 72 68 10 f0       	push   $0xf0106872
f0101d7b:	e8 c0 e2 ff ff       	call   f0100040 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101d80:	6a 02                	push   $0x2
f0101d82:	68 00 10 00 00       	push   $0x1000
f0101d87:	56                   	push   %esi
f0101d88:	50                   	push   %eax
f0101d89:	e8 65 f4 ff ff       	call   f01011f3 <page_insert>
f0101d8e:	83 c4 10             	add    $0x10,%esp
f0101d91:	85 c0                	test   %eax,%eax
f0101d93:	74 19                	je     f0101dae <mem_init+0xab6>
f0101d95:	68 18 6e 10 f0       	push   $0xf0106e18
f0101d9a:	68 98 68 10 f0       	push   $0xf0106898
f0101d9f:	68 d6 03 00 00       	push   $0x3d6
f0101da4:	68 72 68 10 f0       	push   $0xf0106872
f0101da9:	e8 92 e2 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101dae:	83 ec 04             	sub    $0x4,%esp
f0101db1:	6a 00                	push   $0x0
f0101db3:	68 00 10 00 00       	push   $0x1000
f0101db8:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101dbe:	e8 35 f2 ff ff       	call   f0100ff8 <pgdir_walk>
f0101dc3:	83 c4 10             	add    $0x10,%esp
f0101dc6:	f6 00 02             	testb  $0x2,(%eax)
f0101dc9:	75 19                	jne    f0101de4 <mem_init+0xaec>
f0101dcb:	68 38 6f 10 f0       	push   $0xf0106f38
f0101dd0:	68 98 68 10 f0       	push   $0xf0106898
f0101dd5:	68 d7 03 00 00       	push   $0x3d7
f0101dda:	68 72 68 10 f0       	push   $0xf0106872
f0101ddf:	e8 5c e2 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101de4:	83 ec 04             	sub    $0x4,%esp
f0101de7:	6a 00                	push   $0x0
f0101de9:	68 00 10 00 00       	push   $0x1000
f0101dee:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101df4:	e8 ff f1 ff ff       	call   f0100ff8 <pgdir_walk>
f0101df9:	83 c4 10             	add    $0x10,%esp
f0101dfc:	f6 00 04             	testb  $0x4,(%eax)
f0101dff:	74 19                	je     f0101e1a <mem_init+0xb22>
f0101e01:	68 6c 6f 10 f0       	push   $0xf0106f6c
f0101e06:	68 98 68 10 f0       	push   $0xf0106898
f0101e0b:	68 d8 03 00 00       	push   $0x3d8
f0101e10:	68 72 68 10 f0       	push   $0xf0106872
f0101e15:	e8 26 e2 ff ff       	call   f0100040 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101e1a:	6a 02                	push   $0x2
f0101e1c:	68 00 00 40 00       	push   $0x400000
f0101e21:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101e24:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101e2a:	e8 c4 f3 ff ff       	call   f01011f3 <page_insert>
f0101e2f:	83 c4 10             	add    $0x10,%esp
f0101e32:	85 c0                	test   %eax,%eax
f0101e34:	78 19                	js     f0101e4f <mem_init+0xb57>
f0101e36:	68 a4 6f 10 f0       	push   $0xf0106fa4
f0101e3b:	68 98 68 10 f0       	push   $0xf0106898
f0101e40:	68 db 03 00 00       	push   $0x3db
f0101e45:	68 72 68 10 f0       	push   $0xf0106872
f0101e4a:	e8 f1 e1 ff ff       	call   f0100040 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101e4f:	6a 02                	push   $0x2
f0101e51:	68 00 10 00 00       	push   $0x1000
f0101e56:	53                   	push   %ebx
f0101e57:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101e5d:	e8 91 f3 ff ff       	call   f01011f3 <page_insert>
f0101e62:	83 c4 10             	add    $0x10,%esp
f0101e65:	85 c0                	test   %eax,%eax
f0101e67:	74 19                	je     f0101e82 <mem_init+0xb8a>
f0101e69:	68 dc 6f 10 f0       	push   $0xf0106fdc
f0101e6e:	68 98 68 10 f0       	push   $0xf0106898
f0101e73:	68 de 03 00 00       	push   $0x3de
f0101e78:	68 72 68 10 f0       	push   $0xf0106872
f0101e7d:	e8 be e1 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101e82:	83 ec 04             	sub    $0x4,%esp
f0101e85:	6a 00                	push   $0x0
f0101e87:	68 00 10 00 00       	push   $0x1000
f0101e8c:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101e92:	e8 61 f1 ff ff       	call   f0100ff8 <pgdir_walk>
f0101e97:	83 c4 10             	add    $0x10,%esp
f0101e9a:	f6 00 04             	testb  $0x4,(%eax)
f0101e9d:	74 19                	je     f0101eb8 <mem_init+0xbc0>
f0101e9f:	68 6c 6f 10 f0       	push   $0xf0106f6c
f0101ea4:	68 98 68 10 f0       	push   $0xf0106898
f0101ea9:	68 df 03 00 00       	push   $0x3df
f0101eae:	68 72 68 10 f0       	push   $0xf0106872
f0101eb3:	e8 88 e1 ff ff       	call   f0100040 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101eb8:	8b 3d 8c fe 22 f0    	mov    0xf022fe8c,%edi
f0101ebe:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ec3:	89 f8                	mov    %edi,%eax
f0101ec5:	e8 ee eb ff ff       	call   f0100ab8 <check_va2pa>
f0101eca:	89 c1                	mov    %eax,%ecx
f0101ecc:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0101ecf:	89 d8                	mov    %ebx,%eax
f0101ed1:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0101ed7:	c1 f8 03             	sar    $0x3,%eax
f0101eda:	c1 e0 0c             	shl    $0xc,%eax
f0101edd:	39 c1                	cmp    %eax,%ecx
f0101edf:	74 19                	je     f0101efa <mem_init+0xc02>
f0101ee1:	68 18 70 10 f0       	push   $0xf0107018
f0101ee6:	68 98 68 10 f0       	push   $0xf0106898
f0101eeb:	68 e2 03 00 00       	push   $0x3e2
f0101ef0:	68 72 68 10 f0       	push   $0xf0106872
f0101ef5:	e8 46 e1 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101efa:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101eff:	89 f8                	mov    %edi,%eax
f0101f01:	e8 b2 eb ff ff       	call   f0100ab8 <check_va2pa>
f0101f06:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0101f09:	74 19                	je     f0101f24 <mem_init+0xc2c>
f0101f0b:	68 44 70 10 f0       	push   $0xf0107044
f0101f10:	68 98 68 10 f0       	push   $0xf0106898
f0101f15:	68 e3 03 00 00       	push   $0x3e3
f0101f1a:	68 72 68 10 f0       	push   $0xf0106872
f0101f1f:	e8 1c e1 ff ff       	call   f0100040 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101f24:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101f29:	74 19                	je     f0101f44 <mem_init+0xc4c>
f0101f2b:	68 e8 6a 10 f0       	push   $0xf0106ae8
f0101f30:	68 98 68 10 f0       	push   $0xf0106898
f0101f35:	68 e5 03 00 00       	push   $0x3e5
f0101f3a:	68 72 68 10 f0       	push   $0xf0106872
f0101f3f:	e8 fc e0 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0101f44:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101f49:	74 19                	je     f0101f64 <mem_init+0xc6c>
f0101f4b:	68 f9 6a 10 f0       	push   $0xf0106af9
f0101f50:	68 98 68 10 f0       	push   $0xf0106898
f0101f55:	68 e6 03 00 00       	push   $0x3e6
f0101f5a:	68 72 68 10 f0       	push   $0xf0106872
f0101f5f:	e8 dc e0 ff ff       	call   f0100040 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101f64:	83 ec 0c             	sub    $0xc,%esp
f0101f67:	6a 00                	push   $0x0
f0101f69:	e8 9d ef ff ff       	call   f0100f0b <page_alloc>
f0101f6e:	83 c4 10             	add    $0x10,%esp
f0101f71:	85 c0                	test   %eax,%eax
f0101f73:	74 04                	je     f0101f79 <mem_init+0xc81>
f0101f75:	39 c6                	cmp    %eax,%esi
f0101f77:	74 19                	je     f0101f92 <mem_init+0xc9a>
f0101f79:	68 74 70 10 f0       	push   $0xf0107074
f0101f7e:	68 98 68 10 f0       	push   $0xf0106898
f0101f83:	68 e9 03 00 00       	push   $0x3e9
f0101f88:	68 72 68 10 f0       	push   $0xf0106872
f0101f8d:	e8 ae e0 ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101f92:	83 ec 08             	sub    $0x8,%esp
f0101f95:	6a 00                	push   $0x0
f0101f97:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101f9d:	e8 0b f2 ff ff       	call   f01011ad <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101fa2:	8b 3d 8c fe 22 f0    	mov    0xf022fe8c,%edi
f0101fa8:	ba 00 00 00 00       	mov    $0x0,%edx
f0101fad:	89 f8                	mov    %edi,%eax
f0101faf:	e8 04 eb ff ff       	call   f0100ab8 <check_va2pa>
f0101fb4:	83 c4 10             	add    $0x10,%esp
f0101fb7:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101fba:	74 19                	je     f0101fd5 <mem_init+0xcdd>
f0101fbc:	68 98 70 10 f0       	push   $0xf0107098
f0101fc1:	68 98 68 10 f0       	push   $0xf0106898
f0101fc6:	68 ed 03 00 00       	push   $0x3ed
f0101fcb:	68 72 68 10 f0       	push   $0xf0106872
f0101fd0:	e8 6b e0 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101fd5:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101fda:	89 f8                	mov    %edi,%eax
f0101fdc:	e8 d7 ea ff ff       	call   f0100ab8 <check_va2pa>
f0101fe1:	89 da                	mov    %ebx,%edx
f0101fe3:	2b 15 90 fe 22 f0    	sub    0xf022fe90,%edx
f0101fe9:	c1 fa 03             	sar    $0x3,%edx
f0101fec:	c1 e2 0c             	shl    $0xc,%edx
f0101fef:	39 d0                	cmp    %edx,%eax
f0101ff1:	74 19                	je     f010200c <mem_init+0xd14>
f0101ff3:	68 44 70 10 f0       	push   $0xf0107044
f0101ff8:	68 98 68 10 f0       	push   $0xf0106898
f0101ffd:	68 ee 03 00 00       	push   $0x3ee
f0102002:	68 72 68 10 f0       	push   $0xf0106872
f0102007:	e8 34 e0 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f010200c:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102011:	74 19                	je     f010202c <mem_init+0xd34>
f0102013:	68 9f 6a 10 f0       	push   $0xf0106a9f
f0102018:	68 98 68 10 f0       	push   $0xf0106898
f010201d:	68 ef 03 00 00       	push   $0x3ef
f0102022:	68 72 68 10 f0       	push   $0xf0106872
f0102027:	e8 14 e0 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f010202c:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102031:	74 19                	je     f010204c <mem_init+0xd54>
f0102033:	68 f9 6a 10 f0       	push   $0xf0106af9
f0102038:	68 98 68 10 f0       	push   $0xf0106898
f010203d:	68 f0 03 00 00       	push   $0x3f0
f0102042:	68 72 68 10 f0       	push   $0xf0106872
f0102047:	e8 f4 df ff ff       	call   f0100040 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f010204c:	6a 00                	push   $0x0
f010204e:	68 00 10 00 00       	push   $0x1000
f0102053:	53                   	push   %ebx
f0102054:	57                   	push   %edi
f0102055:	e8 99 f1 ff ff       	call   f01011f3 <page_insert>
f010205a:	83 c4 10             	add    $0x10,%esp
f010205d:	85 c0                	test   %eax,%eax
f010205f:	74 19                	je     f010207a <mem_init+0xd82>
f0102061:	68 bc 70 10 f0       	push   $0xf01070bc
f0102066:	68 98 68 10 f0       	push   $0xf0106898
f010206b:	68 f3 03 00 00       	push   $0x3f3
f0102070:	68 72 68 10 f0       	push   $0xf0106872
f0102075:	e8 c6 df ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref);
f010207a:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010207f:	75 19                	jne    f010209a <mem_init+0xda2>
f0102081:	68 0a 6b 10 f0       	push   $0xf0106b0a
f0102086:	68 98 68 10 f0       	push   $0xf0106898
f010208b:	68 f4 03 00 00       	push   $0x3f4
f0102090:	68 72 68 10 f0       	push   $0xf0106872
f0102095:	e8 a6 df ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_link == NULL);
f010209a:	83 3b 00             	cmpl   $0x0,(%ebx)
f010209d:	74 19                	je     f01020b8 <mem_init+0xdc0>
f010209f:	68 16 6b 10 f0       	push   $0xf0106b16
f01020a4:	68 98 68 10 f0       	push   $0xf0106898
f01020a9:	68 f5 03 00 00       	push   $0x3f5
f01020ae:	68 72 68 10 f0       	push   $0xf0106872
f01020b3:	e8 88 df ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f01020b8:	83 ec 08             	sub    $0x8,%esp
f01020bb:	68 00 10 00 00       	push   $0x1000
f01020c0:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f01020c6:	e8 e2 f0 ff ff       	call   f01011ad <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01020cb:	8b 3d 8c fe 22 f0    	mov    0xf022fe8c,%edi
f01020d1:	ba 00 00 00 00       	mov    $0x0,%edx
f01020d6:	89 f8                	mov    %edi,%eax
f01020d8:	e8 db e9 ff ff       	call   f0100ab8 <check_va2pa>
f01020dd:	83 c4 10             	add    $0x10,%esp
f01020e0:	83 f8 ff             	cmp    $0xffffffff,%eax
f01020e3:	74 19                	je     f01020fe <mem_init+0xe06>
f01020e5:	68 98 70 10 f0       	push   $0xf0107098
f01020ea:	68 98 68 10 f0       	push   $0xf0106898
f01020ef:	68 f9 03 00 00       	push   $0x3f9
f01020f4:	68 72 68 10 f0       	push   $0xf0106872
f01020f9:	e8 42 df ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01020fe:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102103:	89 f8                	mov    %edi,%eax
f0102105:	e8 ae e9 ff ff       	call   f0100ab8 <check_va2pa>
f010210a:	83 f8 ff             	cmp    $0xffffffff,%eax
f010210d:	74 19                	je     f0102128 <mem_init+0xe30>
f010210f:	68 f4 70 10 f0       	push   $0xf01070f4
f0102114:	68 98 68 10 f0       	push   $0xf0106898
f0102119:	68 fa 03 00 00       	push   $0x3fa
f010211e:	68 72 68 10 f0       	push   $0xf0106872
f0102123:	e8 18 df ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102128:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010212d:	74 19                	je     f0102148 <mem_init+0xe50>
f010212f:	68 2b 6b 10 f0       	push   $0xf0106b2b
f0102134:	68 98 68 10 f0       	push   $0xf0106898
f0102139:	68 fb 03 00 00       	push   $0x3fb
f010213e:	68 72 68 10 f0       	push   $0xf0106872
f0102143:	e8 f8 de ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0102148:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010214d:	74 19                	je     f0102168 <mem_init+0xe70>
f010214f:	68 f9 6a 10 f0       	push   $0xf0106af9
f0102154:	68 98 68 10 f0       	push   $0xf0106898
f0102159:	68 fc 03 00 00       	push   $0x3fc
f010215e:	68 72 68 10 f0       	push   $0xf0106872
f0102163:	e8 d8 de ff ff       	call   f0100040 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102168:	83 ec 0c             	sub    $0xc,%esp
f010216b:	6a 00                	push   $0x0
f010216d:	e8 99 ed ff ff       	call   f0100f0b <page_alloc>
f0102172:	83 c4 10             	add    $0x10,%esp
f0102175:	39 c3                	cmp    %eax,%ebx
f0102177:	75 04                	jne    f010217d <mem_init+0xe85>
f0102179:	85 c0                	test   %eax,%eax
f010217b:	75 19                	jne    f0102196 <mem_init+0xe9e>
f010217d:	68 1c 71 10 f0       	push   $0xf010711c
f0102182:	68 98 68 10 f0       	push   $0xf0106898
f0102187:	68 ff 03 00 00       	push   $0x3ff
f010218c:	68 72 68 10 f0       	push   $0xf0106872
f0102191:	e8 aa de ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102196:	83 ec 0c             	sub    $0xc,%esp
f0102199:	6a 00                	push   $0x0
f010219b:	e8 6b ed ff ff       	call   f0100f0b <page_alloc>
f01021a0:	83 c4 10             	add    $0x10,%esp
f01021a3:	85 c0                	test   %eax,%eax
f01021a5:	74 19                	je     f01021c0 <mem_init+0xec8>
f01021a7:	68 4d 6a 10 f0       	push   $0xf0106a4d
f01021ac:	68 98 68 10 f0       	push   $0xf0106898
f01021b1:	68 02 04 00 00       	push   $0x402
f01021b6:	68 72 68 10 f0       	push   $0xf0106872
f01021bb:	e8 80 de ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01021c0:	8b 0d 8c fe 22 f0    	mov    0xf022fe8c,%ecx
f01021c6:	8b 11                	mov    (%ecx),%edx
f01021c8:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01021ce:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021d1:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f01021d7:	c1 f8 03             	sar    $0x3,%eax
f01021da:	c1 e0 0c             	shl    $0xc,%eax
f01021dd:	39 c2                	cmp    %eax,%edx
f01021df:	74 19                	je     f01021fa <mem_init+0xf02>
f01021e1:	68 c0 6d 10 f0       	push   $0xf0106dc0
f01021e6:	68 98 68 10 f0       	push   $0xf0106898
f01021eb:	68 05 04 00 00       	push   $0x405
f01021f0:	68 72 68 10 f0       	push   $0xf0106872
f01021f5:	e8 46 de ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f01021fa:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102200:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102203:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102208:	74 19                	je     f0102223 <mem_init+0xf2b>
f010220a:	68 b0 6a 10 f0       	push   $0xf0106ab0
f010220f:	68 98 68 10 f0       	push   $0xf0106898
f0102214:	68 07 04 00 00       	push   $0x407
f0102219:	68 72 68 10 f0       	push   $0xf0106872
f010221e:	e8 1d de ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f0102223:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102226:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f010222c:	83 ec 0c             	sub    $0xc,%esp
f010222f:	50                   	push   %eax
f0102230:	e8 46 ed ff ff       	call   f0100f7b <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102235:	83 c4 0c             	add    $0xc,%esp
f0102238:	6a 01                	push   $0x1
f010223a:	68 00 10 40 00       	push   $0x401000
f010223f:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0102245:	e8 ae ed ff ff       	call   f0100ff8 <pgdir_walk>
f010224a:	89 45 c8             	mov    %eax,-0x38(%ebp)
f010224d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102250:	8b 0d 8c fe 22 f0    	mov    0xf022fe8c,%ecx
f0102256:	8b 51 04             	mov    0x4(%ecx),%edx
f0102259:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010225f:	8b 3d 88 fe 22 f0    	mov    0xf022fe88,%edi
f0102265:	89 d0                	mov    %edx,%eax
f0102267:	c1 e8 0c             	shr    $0xc,%eax
f010226a:	83 c4 10             	add    $0x10,%esp
f010226d:	39 f8                	cmp    %edi,%eax
f010226f:	72 15                	jb     f0102286 <mem_init+0xf8e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102271:	52                   	push   %edx
f0102272:	68 04 63 10 f0       	push   $0xf0106304
f0102277:	68 0e 04 00 00       	push   $0x40e
f010227c:	68 72 68 10 f0       	push   $0xf0106872
f0102281:	e8 ba dd ff ff       	call   f0100040 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102286:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f010228c:	39 55 c8             	cmp    %edx,-0x38(%ebp)
f010228f:	74 19                	je     f01022aa <mem_init+0xfb2>
f0102291:	68 3c 6b 10 f0       	push   $0xf0106b3c
f0102296:	68 98 68 10 f0       	push   $0xf0106898
f010229b:	68 0f 04 00 00       	push   $0x40f
f01022a0:	68 72 68 10 f0       	push   $0xf0106872
f01022a5:	e8 96 dd ff ff       	call   f0100040 <_panic>
	kern_pgdir[PDX(va)] = 0;
f01022aa:	c7 41 04 00 00 00 00 	movl   $0x0,0x4(%ecx)
	pp0->pp_ref = 0;
f01022b1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01022b4:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01022ba:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f01022c0:	c1 f8 03             	sar    $0x3,%eax
f01022c3:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01022c6:	89 c2                	mov    %eax,%edx
f01022c8:	c1 ea 0c             	shr    $0xc,%edx
f01022cb:	39 d7                	cmp    %edx,%edi
f01022cd:	77 12                	ja     f01022e1 <mem_init+0xfe9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01022cf:	50                   	push   %eax
f01022d0:	68 04 63 10 f0       	push   $0xf0106304
f01022d5:	6a 58                	push   $0x58
f01022d7:	68 7e 68 10 f0       	push   $0xf010687e
f01022dc:	e8 5f dd ff ff       	call   f0100040 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01022e1:	83 ec 04             	sub    $0x4,%esp
f01022e4:	68 00 10 00 00       	push   $0x1000
f01022e9:	68 ff 00 00 00       	push   $0xff
f01022ee:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01022f3:	50                   	push   %eax
f01022f4:	e8 2f 33 00 00       	call   f0105628 <memset>
	page_free(pp0);
f01022f9:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01022fc:	89 3c 24             	mov    %edi,(%esp)
f01022ff:	e8 77 ec ff ff       	call   f0100f7b <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102304:	83 c4 0c             	add    $0xc,%esp
f0102307:	6a 01                	push   $0x1
f0102309:	6a 00                	push   $0x0
f010230b:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0102311:	e8 e2 ec ff ff       	call   f0100ff8 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102316:	89 fa                	mov    %edi,%edx
f0102318:	2b 15 90 fe 22 f0    	sub    0xf022fe90,%edx
f010231e:	c1 fa 03             	sar    $0x3,%edx
f0102321:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102324:	89 d0                	mov    %edx,%eax
f0102326:	c1 e8 0c             	shr    $0xc,%eax
f0102329:	83 c4 10             	add    $0x10,%esp
f010232c:	3b 05 88 fe 22 f0    	cmp    0xf022fe88,%eax
f0102332:	72 12                	jb     f0102346 <mem_init+0x104e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102334:	52                   	push   %edx
f0102335:	68 04 63 10 f0       	push   $0xf0106304
f010233a:	6a 58                	push   $0x58
f010233c:	68 7e 68 10 f0       	push   $0xf010687e
f0102341:	e8 fa dc ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0102346:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f010234c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010234f:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102355:	f6 00 01             	testb  $0x1,(%eax)
f0102358:	74 19                	je     f0102373 <mem_init+0x107b>
f010235a:	68 54 6b 10 f0       	push   $0xf0106b54
f010235f:	68 98 68 10 f0       	push   $0xf0106898
f0102364:	68 19 04 00 00       	push   $0x419
f0102369:	68 72 68 10 f0       	push   $0xf0106872
f010236e:	e8 cd dc ff ff       	call   f0100040 <_panic>
f0102373:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102376:	39 c2                	cmp    %eax,%edx
f0102378:	75 db                	jne    f0102355 <mem_init+0x105d>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f010237a:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f010237f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102385:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102388:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f010238e:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102391:	89 0d 40 f2 22 f0    	mov    %ecx,0xf022f240

	// free the pages we took
	page_free(pp0);
f0102397:	83 ec 0c             	sub    $0xc,%esp
f010239a:	50                   	push   %eax
f010239b:	e8 db eb ff ff       	call   f0100f7b <page_free>
	page_free(pp1);
f01023a0:	89 1c 24             	mov    %ebx,(%esp)
f01023a3:	e8 d3 eb ff ff       	call   f0100f7b <page_free>
	page_free(pp2);
f01023a8:	89 34 24             	mov    %esi,(%esp)
f01023ab:	e8 cb eb ff ff       	call   f0100f7b <page_free>

	// test mmio_map_region
	mm1 = (uintptr_t) mmio_map_region(0, 4097);
f01023b0:	83 c4 08             	add    $0x8,%esp
f01023b3:	68 01 10 00 00       	push   $0x1001
f01023b8:	6a 00                	push   $0x0
f01023ba:	e8 d6 ee ff ff       	call   f0101295 <mmio_map_region>
f01023bf:	89 c3                	mov    %eax,%ebx
	mm2 = (uintptr_t) mmio_map_region(0, 4096);
f01023c1:	83 c4 08             	add    $0x8,%esp
f01023c4:	68 00 10 00 00       	push   $0x1000
f01023c9:	6a 00                	push   $0x0
f01023cb:	e8 c5 ee ff ff       	call   f0101295 <mmio_map_region>
f01023d0:	89 c6                	mov    %eax,%esi
	// check that they're in the right region
	assert(mm1 >= MMIOBASE && mm1 + 8096 < MMIOLIM);
f01023d2:	8d 83 a0 1f 00 00    	lea    0x1fa0(%ebx),%eax
f01023d8:	83 c4 10             	add    $0x10,%esp
f01023db:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f01023e1:	76 07                	jbe    f01023ea <mem_init+0x10f2>
f01023e3:	3d ff ff bf ef       	cmp    $0xefbfffff,%eax
f01023e8:	76 19                	jbe    f0102403 <mem_init+0x110b>
f01023ea:	68 40 71 10 f0       	push   $0xf0107140
f01023ef:	68 98 68 10 f0       	push   $0xf0106898
f01023f4:	68 29 04 00 00       	push   $0x429
f01023f9:	68 72 68 10 f0       	push   $0xf0106872
f01023fe:	e8 3d dc ff ff       	call   f0100040 <_panic>
	assert(mm2 >= MMIOBASE && mm2 + 8096 < MMIOLIM);
f0102403:	8d 96 a0 1f 00 00    	lea    0x1fa0(%esi),%edx
f0102409:	81 fa ff ff bf ef    	cmp    $0xefbfffff,%edx
f010240f:	77 08                	ja     f0102419 <mem_init+0x1121>
f0102411:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102417:	77 19                	ja     f0102432 <mem_init+0x113a>
f0102419:	68 68 71 10 f0       	push   $0xf0107168
f010241e:	68 98 68 10 f0       	push   $0xf0106898
f0102423:	68 2a 04 00 00       	push   $0x42a
f0102428:	68 72 68 10 f0       	push   $0xf0106872
f010242d:	e8 0e dc ff ff       	call   f0100040 <_panic>
	// check that they're page-aligned
	assert(mm1 % PGSIZE == 0 && mm2 % PGSIZE == 0);
f0102432:	89 da                	mov    %ebx,%edx
f0102434:	09 f2                	or     %esi,%edx
f0102436:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f010243c:	74 19                	je     f0102457 <mem_init+0x115f>
f010243e:	68 90 71 10 f0       	push   $0xf0107190
f0102443:	68 98 68 10 f0       	push   $0xf0106898
f0102448:	68 2c 04 00 00       	push   $0x42c
f010244d:	68 72 68 10 f0       	push   $0xf0106872
f0102452:	e8 e9 db ff ff       	call   f0100040 <_panic>
	// check that they don't overlap
	assert(mm1 + 8096 <= mm2);
f0102457:	39 c6                	cmp    %eax,%esi
f0102459:	73 19                	jae    f0102474 <mem_init+0x117c>
f010245b:	68 6b 6b 10 f0       	push   $0xf0106b6b
f0102460:	68 98 68 10 f0       	push   $0xf0106898
f0102465:	68 2e 04 00 00       	push   $0x42e
f010246a:	68 72 68 10 f0       	push   $0xf0106872
f010246f:	e8 cc db ff ff       	call   f0100040 <_panic>
	// check page mappings
	assert(check_va2pa(kern_pgdir, mm1) == 0);
f0102474:	8b 3d 8c fe 22 f0    	mov    0xf022fe8c,%edi
f010247a:	89 da                	mov    %ebx,%edx
f010247c:	89 f8                	mov    %edi,%eax
f010247e:	e8 35 e6 ff ff       	call   f0100ab8 <check_va2pa>
f0102483:	85 c0                	test   %eax,%eax
f0102485:	74 19                	je     f01024a0 <mem_init+0x11a8>
f0102487:	68 b8 71 10 f0       	push   $0xf01071b8
f010248c:	68 98 68 10 f0       	push   $0xf0106898
f0102491:	68 30 04 00 00       	push   $0x430
f0102496:	68 72 68 10 f0       	push   $0xf0106872
f010249b:	e8 a0 db ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm1+PGSIZE) == PGSIZE);
f01024a0:	8d 83 00 10 00 00    	lea    0x1000(%ebx),%eax
f01024a6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01024a9:	89 c2                	mov    %eax,%edx
f01024ab:	89 f8                	mov    %edi,%eax
f01024ad:	e8 06 e6 ff ff       	call   f0100ab8 <check_va2pa>
f01024b2:	3d 00 10 00 00       	cmp    $0x1000,%eax
f01024b7:	74 19                	je     f01024d2 <mem_init+0x11da>
f01024b9:	68 dc 71 10 f0       	push   $0xf01071dc
f01024be:	68 98 68 10 f0       	push   $0xf0106898
f01024c3:	68 31 04 00 00       	push   $0x431
f01024c8:	68 72 68 10 f0       	push   $0xf0106872
f01024cd:	e8 6e db ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2) == 0);
f01024d2:	89 f2                	mov    %esi,%edx
f01024d4:	89 f8                	mov    %edi,%eax
f01024d6:	e8 dd e5 ff ff       	call   f0100ab8 <check_va2pa>
f01024db:	85 c0                	test   %eax,%eax
f01024dd:	74 19                	je     f01024f8 <mem_init+0x1200>
f01024df:	68 0c 72 10 f0       	push   $0xf010720c
f01024e4:	68 98 68 10 f0       	push   $0xf0106898
f01024e9:	68 32 04 00 00       	push   $0x432
f01024ee:	68 72 68 10 f0       	push   $0xf0106872
f01024f3:	e8 48 db ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2+PGSIZE) == ~0);
f01024f8:	8d 96 00 10 00 00    	lea    0x1000(%esi),%edx
f01024fe:	89 f8                	mov    %edi,%eax
f0102500:	e8 b3 e5 ff ff       	call   f0100ab8 <check_va2pa>
f0102505:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102508:	74 19                	je     f0102523 <mem_init+0x122b>
f010250a:	68 30 72 10 f0       	push   $0xf0107230
f010250f:	68 98 68 10 f0       	push   $0xf0106898
f0102514:	68 33 04 00 00       	push   $0x433
f0102519:	68 72 68 10 f0       	push   $0xf0106872
f010251e:	e8 1d db ff ff       	call   f0100040 <_panic>
	// check permissions
	assert(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & (PTE_W|PTE_PWT|PTE_PCD));
f0102523:	83 ec 04             	sub    $0x4,%esp
f0102526:	6a 00                	push   $0x0
f0102528:	53                   	push   %ebx
f0102529:	57                   	push   %edi
f010252a:	e8 c9 ea ff ff       	call   f0100ff8 <pgdir_walk>
f010252f:	83 c4 10             	add    $0x10,%esp
f0102532:	f6 00 1a             	testb  $0x1a,(%eax)
f0102535:	75 19                	jne    f0102550 <mem_init+0x1258>
f0102537:	68 5c 72 10 f0       	push   $0xf010725c
f010253c:	68 98 68 10 f0       	push   $0xf0106898
f0102541:	68 35 04 00 00       	push   $0x435
f0102546:	68 72 68 10 f0       	push   $0xf0106872
f010254b:	e8 f0 da ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & PTE_U));
f0102550:	83 ec 04             	sub    $0x4,%esp
f0102553:	6a 00                	push   $0x0
f0102555:	53                   	push   %ebx
f0102556:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f010255c:	e8 97 ea ff ff       	call   f0100ff8 <pgdir_walk>
f0102561:	8b 00                	mov    (%eax),%eax
f0102563:	83 c4 10             	add    $0x10,%esp
f0102566:	83 e0 04             	and    $0x4,%eax
f0102569:	89 45 c8             	mov    %eax,-0x38(%ebp)
f010256c:	74 19                	je     f0102587 <mem_init+0x128f>
f010256e:	68 a0 72 10 f0       	push   $0xf01072a0
f0102573:	68 98 68 10 f0       	push   $0xf0106898
f0102578:	68 36 04 00 00       	push   $0x436
f010257d:	68 72 68 10 f0       	push   $0xf0106872
f0102582:	e8 b9 da ff ff       	call   f0100040 <_panic>
	// clear the mappings
	*pgdir_walk(kern_pgdir, (void*) mm1, 0) = 0;
f0102587:	83 ec 04             	sub    $0x4,%esp
f010258a:	6a 00                	push   $0x0
f010258c:	53                   	push   %ebx
f010258d:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0102593:	e8 60 ea ff ff       	call   f0100ff8 <pgdir_walk>
f0102598:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm1 + PGSIZE, 0) = 0;
f010259e:	83 c4 0c             	add    $0xc,%esp
f01025a1:	6a 00                	push   $0x0
f01025a3:	ff 75 d4             	pushl  -0x2c(%ebp)
f01025a6:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f01025ac:	e8 47 ea ff ff       	call   f0100ff8 <pgdir_walk>
f01025b1:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm2, 0) = 0;
f01025b7:	83 c4 0c             	add    $0xc,%esp
f01025ba:	6a 00                	push   $0x0
f01025bc:	56                   	push   %esi
f01025bd:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f01025c3:	e8 30 ea ff ff       	call   f0100ff8 <pgdir_walk>
f01025c8:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	cprintf("check_page() succeeded!\n");
f01025ce:	c7 04 24 7d 6b 10 f0 	movl   $0xf0106b7d,(%esp)
f01025d5:	e8 4a 11 00 00       	call   f0103724 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, PageInfo_Size, PADDR(pages), (PTE_U|PTE_P));
f01025da:	a1 90 fe 22 f0       	mov    0xf022fe90,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01025df:	83 c4 10             	add    $0x10,%esp
f01025e2:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01025e7:	77 15                	ja     f01025fe <mem_init+0x1306>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01025e9:	50                   	push   %eax
f01025ea:	68 28 63 10 f0       	push   $0xf0106328
f01025ef:	68 c1 00 00 00       	push   $0xc1
f01025f4:	68 72 68 10 f0       	push   $0xf0106872
f01025f9:	e8 42 da ff ff       	call   f0100040 <_panic>
f01025fe:	83 ec 08             	sub    $0x8,%esp
f0102601:	6a 05                	push   $0x5
f0102603:	05 00 00 00 10       	add    $0x10000000,%eax
f0102608:	50                   	push   %eax
f0102609:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f010260c:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102611:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f0102616:	e8 a5 ea ff ff       	call   f01010c0 <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, PTSIZE, PADDR(envs), PTE_U);
f010261b:	a1 48 f2 22 f0       	mov    0xf022f248,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102620:	83 c4 10             	add    $0x10,%esp
f0102623:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102628:	77 15                	ja     f010263f <mem_init+0x1347>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010262a:	50                   	push   %eax
f010262b:	68 28 63 10 f0       	push   $0xf0106328
f0102630:	68 c9 00 00 00       	push   $0xc9
f0102635:	68 72 68 10 f0       	push   $0xf0106872
f010263a:	e8 01 da ff ff       	call   f0100040 <_panic>
f010263f:	83 ec 08             	sub    $0x8,%esp
f0102642:	6a 04                	push   $0x4
f0102644:	05 00 00 00 10       	add    $0x10000000,%eax
f0102649:	50                   	push   %eax
f010264a:	b9 00 00 40 00       	mov    $0x400000,%ecx
f010264f:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102654:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f0102659:	e8 62 ea ff ff       	call   f01010c0 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010265e:	83 c4 10             	add    $0x10,%esp
f0102661:	b8 00 60 11 f0       	mov    $0xf0116000,%eax
f0102666:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010266b:	77 15                	ja     f0102682 <mem_init+0x138a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010266d:	50                   	push   %eax
f010266e:	68 28 63 10 f0       	push   $0xf0106328
f0102673:	68 d5 00 00 00       	push   $0xd5
f0102678:	68 72 68 10 f0       	push   $0xf0106872
f010267d:	e8 be d9 ff ff       	call   f0100040 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), (PTE_W|PTE_P));
f0102682:	83 ec 08             	sub    $0x8,%esp
f0102685:	6a 03                	push   $0x3
f0102687:	68 00 60 11 00       	push   $0x116000
f010268c:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102691:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102696:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f010269b:	e8 20 ea ff ff       	call   f01010c0 <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KERNBASE, (0xffffffff-KERNBASE), 0, (PTE_W|PTE_P));
f01026a0:	83 c4 08             	add    $0x8,%esp
f01026a3:	6a 03                	push   $0x3
f01026a5:	6a 00                	push   $0x0
f01026a7:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f01026ac:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01026b1:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f01026b6:	e8 05 ea ff ff       	call   f01010c0 <boot_map_region>
f01026bb:	c7 45 c4 00 10 23 f0 	movl   $0xf0231000,-0x3c(%ebp)
f01026c2:	83 c4 10             	add    $0x10,%esp
f01026c5:	bb 00 10 23 f0       	mov    $0xf0231000,%ebx
	//             it will fault rather than overwrite another CPU's stack.
	//             Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	//
	// LAB 4: Your code here:
	uintptr_t kstacktop_i = KSTACKTOP - KSTKSIZE; 
f01026ca:	be 00 80 ff ef       	mov    $0xefff8000,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01026cf:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f01026d5:	77 15                	ja     f01026ec <mem_init+0x13f4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01026d7:	53                   	push   %ebx
f01026d8:	68 28 63 10 f0       	push   $0xf0106328
f01026dd:	68 15 01 00 00       	push   $0x115
f01026e2:	68 72 68 10 f0       	push   $0xf0106872
f01026e7:	e8 54 d9 ff ff       	call   f0100040 <_panic>
	for(int i = 0;i < NCPU;i++)
	{
boot_map_region(kern_pgdir, kstacktop_i, KSTKSIZE, PADDR(percpu_kstacks[i]), PTE_W | PTE_P);
f01026ec:	83 ec 08             	sub    $0x8,%esp
f01026ef:	6a 03                	push   $0x3
f01026f1:	8d 83 00 00 00 10    	lea    0x10000000(%ebx),%eax
f01026f7:	50                   	push   %eax
f01026f8:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01026fd:	89 f2                	mov    %esi,%edx
f01026ff:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f0102704:	e8 b7 e9 ff ff       	call   f01010c0 <boot_map_region>
		kstacktop_i -= (KSTKSIZE + KSTKGAP); 
f0102709:	81 ee 00 00 01 00    	sub    $0x10000,%esi
f010270f:	81 c3 00 80 00 00    	add    $0x8000,%ebx
	//             Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	//
	// LAB 4: Your code here:
	uintptr_t kstacktop_i = KSTACKTOP - KSTKSIZE; 
	for(int i = 0;i < NCPU;i++)
f0102715:	83 c4 10             	add    $0x10,%esp
f0102718:	81 fe 00 80 f7 ef    	cmp    $0xeff78000,%esi
f010271e:	75 af                	jne    f01026cf <mem_init+0x13d7>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102720:	8b 3d 8c fe 22 f0    	mov    0xf022fe8c,%edi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102726:	a1 88 fe 22 f0       	mov    0xf022fe88,%eax
f010272b:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010272e:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102735:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010273a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010273d:	8b 35 90 fe 22 f0    	mov    0xf022fe90,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102743:	89 75 d0             	mov    %esi,-0x30(%ebp)

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102746:	bb 00 00 00 00       	mov    $0x0,%ebx
f010274b:	eb 55                	jmp    f01027a2 <mem_init+0x14aa>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010274d:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f0102753:	89 f8                	mov    %edi,%eax
f0102755:	e8 5e e3 ff ff       	call   f0100ab8 <check_va2pa>
f010275a:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f0102761:	77 15                	ja     f0102778 <mem_init+0x1480>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102763:	56                   	push   %esi
f0102764:	68 28 63 10 f0       	push   $0xf0106328
f0102769:	68 4e 03 00 00       	push   $0x34e
f010276e:	68 72 68 10 f0       	push   $0xf0106872
f0102773:	e8 c8 d8 ff ff       	call   f0100040 <_panic>
f0102778:	8d 94 1e 00 00 00 10 	lea    0x10000000(%esi,%ebx,1),%edx
f010277f:	39 c2                	cmp    %eax,%edx
f0102781:	74 19                	je     f010279c <mem_init+0x14a4>
f0102783:	68 d4 72 10 f0       	push   $0xf01072d4
f0102788:	68 98 68 10 f0       	push   $0xf0106898
f010278d:	68 4e 03 00 00       	push   $0x34e
f0102792:	68 72 68 10 f0       	push   $0xf0106872
f0102797:	e8 a4 d8 ff ff       	call   f0100040 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010279c:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01027a2:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01027a5:	77 a6                	ja     f010274d <mem_init+0x1455>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f01027a7:	8b 35 48 f2 22 f0    	mov    0xf022f248,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01027ad:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f01027b0:	bb 00 00 c0 ee       	mov    $0xeec00000,%ebx
f01027b5:	89 da                	mov    %ebx,%edx
f01027b7:	89 f8                	mov    %edi,%eax
f01027b9:	e8 fa e2 ff ff       	call   f0100ab8 <check_va2pa>
f01027be:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f01027c5:	77 15                	ja     f01027dc <mem_init+0x14e4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01027c7:	56                   	push   %esi
f01027c8:	68 28 63 10 f0       	push   $0xf0106328
f01027cd:	68 53 03 00 00       	push   $0x353
f01027d2:	68 72 68 10 f0       	push   $0xf0106872
f01027d7:	e8 64 d8 ff ff       	call   f0100040 <_panic>
f01027dc:	8d 94 1e 00 00 40 21 	lea    0x21400000(%esi,%ebx,1),%edx
f01027e3:	39 d0                	cmp    %edx,%eax
f01027e5:	74 19                	je     f0102800 <mem_init+0x1508>
f01027e7:	68 08 73 10 f0       	push   $0xf0107308
f01027ec:	68 98 68 10 f0       	push   $0xf0106898
f01027f1:	68 53 03 00 00       	push   $0x353
f01027f6:	68 72 68 10 f0       	push   $0xf0106872
f01027fb:	e8 40 d8 ff ff       	call   f0100040 <_panic>
f0102800:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102806:	81 fb 00 f0 c1 ee    	cmp    $0xeec1f000,%ebx
f010280c:	75 a7                	jne    f01027b5 <mem_init+0x14bd>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010280e:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0102811:	c1 e6 0c             	shl    $0xc,%esi
f0102814:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102819:	eb 30                	jmp    f010284b <mem_init+0x1553>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f010281b:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f0102821:	89 f8                	mov    %edi,%eax
f0102823:	e8 90 e2 ff ff       	call   f0100ab8 <check_va2pa>
f0102828:	39 c3                	cmp    %eax,%ebx
f010282a:	74 19                	je     f0102845 <mem_init+0x154d>
f010282c:	68 3c 73 10 f0       	push   $0xf010733c
f0102831:	68 98 68 10 f0       	push   $0xf0106898
f0102836:	68 57 03 00 00       	push   $0x357
f010283b:	68 72 68 10 f0       	push   $0xf0106872
f0102840:	e8 fb d7 ff ff       	call   f0100040 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102845:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010284b:	39 f3                	cmp    %esi,%ebx
f010284d:	72 cc                	jb     f010281b <mem_init+0x1523>
f010284f:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f0102854:	89 75 cc             	mov    %esi,-0x34(%ebp)
f0102857:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f010285a:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010285d:	8d 88 00 80 00 00    	lea    0x8000(%eax),%ecx
f0102863:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f0102866:	89 c3                	mov    %eax,%ebx
	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f0102868:	8b 45 c8             	mov    -0x38(%ebp),%eax
f010286b:	05 00 80 00 20       	add    $0x20008000,%eax
f0102870:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102873:	89 da                	mov    %ebx,%edx
f0102875:	89 f8                	mov    %edi,%eax
f0102877:	e8 3c e2 ff ff       	call   f0100ab8 <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010287c:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f0102882:	77 15                	ja     f0102899 <mem_init+0x15a1>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102884:	56                   	push   %esi
f0102885:	68 28 63 10 f0       	push   $0xf0106328
f010288a:	68 5f 03 00 00       	push   $0x35f
f010288f:	68 72 68 10 f0       	push   $0xf0106872
f0102894:	e8 a7 d7 ff ff       	call   f0100040 <_panic>
f0102899:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010289c:	8d 94 0b 00 10 23 f0 	lea    -0xfdcf000(%ebx,%ecx,1),%edx
f01028a3:	39 d0                	cmp    %edx,%eax
f01028a5:	74 19                	je     f01028c0 <mem_init+0x15c8>
f01028a7:	68 64 73 10 f0       	push   $0xf0107364
f01028ac:	68 98 68 10 f0       	push   $0xf0106898
f01028b1:	68 5f 03 00 00       	push   $0x35f
f01028b6:	68 72 68 10 f0       	push   $0xf0106872
f01028bb:	e8 80 d7 ff ff       	call   f0100040 <_panic>
f01028c0:	81 c3 00 10 00 00    	add    $0x1000,%ebx

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01028c6:	3b 5d d0             	cmp    -0x30(%ebp),%ebx
f01028c9:	75 a8                	jne    f0102873 <mem_init+0x157b>
f01028cb:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01028ce:	8d 98 00 80 ff ff    	lea    -0x8000(%eax),%ebx
f01028d4:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f01028d7:	89 c6                	mov    %eax,%esi
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
f01028d9:	89 da                	mov    %ebx,%edx
f01028db:	89 f8                	mov    %edi,%eax
f01028dd:	e8 d6 e1 ff ff       	call   f0100ab8 <check_va2pa>
f01028e2:	83 f8 ff             	cmp    $0xffffffff,%eax
f01028e5:	74 19                	je     f0102900 <mem_init+0x1608>
f01028e7:	68 ac 73 10 f0       	push   $0xf01073ac
f01028ec:	68 98 68 10 f0       	push   $0xf0106898
f01028f1:	68 61 03 00 00       	push   $0x361
f01028f6:	68 72 68 10 f0       	push   $0xf0106872
f01028fb:	e8 40 d7 ff ff       	call   f0100040 <_panic>
f0102900:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
f0102906:	39 de                	cmp    %ebx,%esi
f0102908:	75 cf                	jne    f01028d9 <mem_init+0x15e1>
f010290a:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f010290d:	81 6d cc 00 00 01 00 	subl   $0x10000,-0x34(%ebp)
f0102914:	81 45 c8 00 80 01 00 	addl   $0x18000,-0x38(%ebp)
f010291b:	81 c6 00 80 00 00    	add    $0x8000,%esi
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
f0102921:	b8 00 10 27 f0       	mov    $0xf0271000,%eax
f0102926:	39 f0                	cmp    %esi,%eax
f0102928:	0f 85 2c ff ff ff    	jne    f010285a <mem_init+0x1562>
f010292e:	b8 00 00 00 00       	mov    $0x0,%eax
f0102933:	eb 2a                	jmp    f010295f <mem_init+0x1667>
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102935:	8d 90 45 fc ff ff    	lea    -0x3bb(%eax),%edx
f010293b:	83 fa 04             	cmp    $0x4,%edx
f010293e:	77 1f                	ja     f010295f <mem_init+0x1667>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
		case PDX(MMIOBASE):
			assert(pgdir[i] & PTE_P);
f0102940:	f6 04 87 01          	testb  $0x1,(%edi,%eax,4)
f0102944:	75 7e                	jne    f01029c4 <mem_init+0x16cc>
f0102946:	68 96 6b 10 f0       	push   $0xf0106b96
f010294b:	68 98 68 10 f0       	push   $0xf0106898
f0102950:	68 6c 03 00 00       	push   $0x36c
f0102955:	68 72 68 10 f0       	push   $0xf0106872
f010295a:	e8 e1 d6 ff ff       	call   f0100040 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f010295f:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102964:	76 3f                	jbe    f01029a5 <mem_init+0x16ad>
				assert(pgdir[i] & PTE_P);
f0102966:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0102969:	f6 c2 01             	test   $0x1,%dl
f010296c:	75 19                	jne    f0102987 <mem_init+0x168f>
f010296e:	68 96 6b 10 f0       	push   $0xf0106b96
f0102973:	68 98 68 10 f0       	push   $0xf0106898
f0102978:	68 70 03 00 00       	push   $0x370
f010297d:	68 72 68 10 f0       	push   $0xf0106872
f0102982:	e8 b9 d6 ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] & PTE_W);
f0102987:	f6 c2 02             	test   $0x2,%dl
f010298a:	75 38                	jne    f01029c4 <mem_init+0x16cc>
f010298c:	68 a7 6b 10 f0       	push   $0xf0106ba7
f0102991:	68 98 68 10 f0       	push   $0xf0106898
f0102996:	68 71 03 00 00       	push   $0x371
f010299b:	68 72 68 10 f0       	push   $0xf0106872
f01029a0:	e8 9b d6 ff ff       	call   f0100040 <_panic>
			} else
				assert(pgdir[i] == 0);
f01029a5:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f01029a9:	74 19                	je     f01029c4 <mem_init+0x16cc>
f01029ab:	68 b8 6b 10 f0       	push   $0xf0106bb8
f01029b0:	68 98 68 10 f0       	push   $0xf0106898
f01029b5:	68 73 03 00 00       	push   $0x373
f01029ba:	68 72 68 10 f0       	push   $0xf0106872
f01029bf:	e8 7c d6 ff ff       	call   f0100040 <_panic>
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f01029c4:	83 c0 01             	add    $0x1,%eax
f01029c7:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f01029cc:	0f 86 63 ff ff ff    	jbe    f0102935 <mem_init+0x163d>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f01029d2:	83 ec 0c             	sub    $0xc,%esp
f01029d5:	68 d0 73 10 f0       	push   $0xf01073d0
f01029da:	e8 45 0d 00 00       	call   f0103724 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01029df:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01029e4:	83 c4 10             	add    $0x10,%esp
f01029e7:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01029ec:	77 15                	ja     f0102a03 <mem_init+0x170b>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01029ee:	50                   	push   %eax
f01029ef:	68 28 63 10 f0       	push   $0xf0106328
f01029f4:	68 ed 00 00 00       	push   $0xed
f01029f9:	68 72 68 10 f0       	push   $0xf0106872
f01029fe:	e8 3d d6 ff ff       	call   f0100040 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102a03:	05 00 00 00 10       	add    $0x10000000,%eax
f0102a08:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102a0b:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a10:	e8 07 e1 ff ff       	call   f0100b1c <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102a15:	0f 20 c0             	mov    %cr0,%eax
f0102a18:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102a1b:	0d 23 00 05 80       	or     $0x80050023,%eax
f0102a20:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102a23:	83 ec 0c             	sub    $0xc,%esp
f0102a26:	6a 00                	push   $0x0
f0102a28:	e8 de e4 ff ff       	call   f0100f0b <page_alloc>
f0102a2d:	89 c3                	mov    %eax,%ebx
f0102a2f:	83 c4 10             	add    $0x10,%esp
f0102a32:	85 c0                	test   %eax,%eax
f0102a34:	75 19                	jne    f0102a4f <mem_init+0x1757>
f0102a36:	68 a2 69 10 f0       	push   $0xf01069a2
f0102a3b:	68 98 68 10 f0       	push   $0xf0106898
f0102a40:	68 4b 04 00 00       	push   $0x44b
f0102a45:	68 72 68 10 f0       	push   $0xf0106872
f0102a4a:	e8 f1 d5 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0102a4f:	83 ec 0c             	sub    $0xc,%esp
f0102a52:	6a 00                	push   $0x0
f0102a54:	e8 b2 e4 ff ff       	call   f0100f0b <page_alloc>
f0102a59:	89 c7                	mov    %eax,%edi
f0102a5b:	83 c4 10             	add    $0x10,%esp
f0102a5e:	85 c0                	test   %eax,%eax
f0102a60:	75 19                	jne    f0102a7b <mem_init+0x1783>
f0102a62:	68 b8 69 10 f0       	push   $0xf01069b8
f0102a67:	68 98 68 10 f0       	push   $0xf0106898
f0102a6c:	68 4c 04 00 00       	push   $0x44c
f0102a71:	68 72 68 10 f0       	push   $0xf0106872
f0102a76:	e8 c5 d5 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0102a7b:	83 ec 0c             	sub    $0xc,%esp
f0102a7e:	6a 00                	push   $0x0
f0102a80:	e8 86 e4 ff ff       	call   f0100f0b <page_alloc>
f0102a85:	89 c6                	mov    %eax,%esi
f0102a87:	83 c4 10             	add    $0x10,%esp
f0102a8a:	85 c0                	test   %eax,%eax
f0102a8c:	75 19                	jne    f0102aa7 <mem_init+0x17af>
f0102a8e:	68 ce 69 10 f0       	push   $0xf01069ce
f0102a93:	68 98 68 10 f0       	push   $0xf0106898
f0102a98:	68 4d 04 00 00       	push   $0x44d
f0102a9d:	68 72 68 10 f0       	push   $0xf0106872
f0102aa2:	e8 99 d5 ff ff       	call   f0100040 <_panic>
	page_free(pp0);
f0102aa7:	83 ec 0c             	sub    $0xc,%esp
f0102aaa:	53                   	push   %ebx
f0102aab:	e8 cb e4 ff ff       	call   f0100f7b <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102ab0:	89 f8                	mov    %edi,%eax
f0102ab2:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0102ab8:	c1 f8 03             	sar    $0x3,%eax
f0102abb:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102abe:	89 c2                	mov    %eax,%edx
f0102ac0:	c1 ea 0c             	shr    $0xc,%edx
f0102ac3:	83 c4 10             	add    $0x10,%esp
f0102ac6:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f0102acc:	72 12                	jb     f0102ae0 <mem_init+0x17e8>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102ace:	50                   	push   %eax
f0102acf:	68 04 63 10 f0       	push   $0xf0106304
f0102ad4:	6a 58                	push   $0x58
f0102ad6:	68 7e 68 10 f0       	push   $0xf010687e
f0102adb:	e8 60 d5 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102ae0:	83 ec 04             	sub    $0x4,%esp
f0102ae3:	68 00 10 00 00       	push   $0x1000
f0102ae8:	6a 01                	push   $0x1
f0102aea:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102aef:	50                   	push   %eax
f0102af0:	e8 33 2b 00 00       	call   f0105628 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102af5:	89 f0                	mov    %esi,%eax
f0102af7:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0102afd:	c1 f8 03             	sar    $0x3,%eax
f0102b00:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102b03:	89 c2                	mov    %eax,%edx
f0102b05:	c1 ea 0c             	shr    $0xc,%edx
f0102b08:	83 c4 10             	add    $0x10,%esp
f0102b0b:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f0102b11:	72 12                	jb     f0102b25 <mem_init+0x182d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102b13:	50                   	push   %eax
f0102b14:	68 04 63 10 f0       	push   $0xf0106304
f0102b19:	6a 58                	push   $0x58
f0102b1b:	68 7e 68 10 f0       	push   $0xf010687e
f0102b20:	e8 1b d5 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102b25:	83 ec 04             	sub    $0x4,%esp
f0102b28:	68 00 10 00 00       	push   $0x1000
f0102b2d:	6a 02                	push   $0x2
f0102b2f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102b34:	50                   	push   %eax
f0102b35:	e8 ee 2a 00 00       	call   f0105628 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102b3a:	6a 02                	push   $0x2
f0102b3c:	68 00 10 00 00       	push   $0x1000
f0102b41:	57                   	push   %edi
f0102b42:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0102b48:	e8 a6 e6 ff ff       	call   f01011f3 <page_insert>
	assert(pp1->pp_ref == 1);
f0102b4d:	83 c4 20             	add    $0x20,%esp
f0102b50:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102b55:	74 19                	je     f0102b70 <mem_init+0x1878>
f0102b57:	68 9f 6a 10 f0       	push   $0xf0106a9f
f0102b5c:	68 98 68 10 f0       	push   $0xf0106898
f0102b61:	68 52 04 00 00       	push   $0x452
f0102b66:	68 72 68 10 f0       	push   $0xf0106872
f0102b6b:	e8 d0 d4 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102b70:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102b77:	01 01 01 
f0102b7a:	74 19                	je     f0102b95 <mem_init+0x189d>
f0102b7c:	68 f0 73 10 f0       	push   $0xf01073f0
f0102b81:	68 98 68 10 f0       	push   $0xf0106898
f0102b86:	68 53 04 00 00       	push   $0x453
f0102b8b:	68 72 68 10 f0       	push   $0xf0106872
f0102b90:	e8 ab d4 ff ff       	call   f0100040 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102b95:	6a 02                	push   $0x2
f0102b97:	68 00 10 00 00       	push   $0x1000
f0102b9c:	56                   	push   %esi
f0102b9d:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0102ba3:	e8 4b e6 ff ff       	call   f01011f3 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102ba8:	83 c4 10             	add    $0x10,%esp
f0102bab:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102bb2:	02 02 02 
f0102bb5:	74 19                	je     f0102bd0 <mem_init+0x18d8>
f0102bb7:	68 14 74 10 f0       	push   $0xf0107414
f0102bbc:	68 98 68 10 f0       	push   $0xf0106898
f0102bc1:	68 55 04 00 00       	push   $0x455
f0102bc6:	68 72 68 10 f0       	push   $0xf0106872
f0102bcb:	e8 70 d4 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102bd0:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102bd5:	74 19                	je     f0102bf0 <mem_init+0x18f8>
f0102bd7:	68 c1 6a 10 f0       	push   $0xf0106ac1
f0102bdc:	68 98 68 10 f0       	push   $0xf0106898
f0102be1:	68 56 04 00 00       	push   $0x456
f0102be6:	68 72 68 10 f0       	push   $0xf0106872
f0102beb:	e8 50 d4 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102bf0:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102bf5:	74 19                	je     f0102c10 <mem_init+0x1918>
f0102bf7:	68 2b 6b 10 f0       	push   $0xf0106b2b
f0102bfc:	68 98 68 10 f0       	push   $0xf0106898
f0102c01:	68 57 04 00 00       	push   $0x457
f0102c06:	68 72 68 10 f0       	push   $0xf0106872
f0102c0b:	e8 30 d4 ff ff       	call   f0100040 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102c10:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102c17:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102c1a:	89 f0                	mov    %esi,%eax
f0102c1c:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0102c22:	c1 f8 03             	sar    $0x3,%eax
f0102c25:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102c28:	89 c2                	mov    %eax,%edx
f0102c2a:	c1 ea 0c             	shr    $0xc,%edx
f0102c2d:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f0102c33:	72 12                	jb     f0102c47 <mem_init+0x194f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102c35:	50                   	push   %eax
f0102c36:	68 04 63 10 f0       	push   $0xf0106304
f0102c3b:	6a 58                	push   $0x58
f0102c3d:	68 7e 68 10 f0       	push   $0xf010687e
f0102c42:	e8 f9 d3 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102c47:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102c4e:	03 03 03 
f0102c51:	74 19                	je     f0102c6c <mem_init+0x1974>
f0102c53:	68 38 74 10 f0       	push   $0xf0107438
f0102c58:	68 98 68 10 f0       	push   $0xf0106898
f0102c5d:	68 59 04 00 00       	push   $0x459
f0102c62:	68 72 68 10 f0       	push   $0xf0106872
f0102c67:	e8 d4 d3 ff ff       	call   f0100040 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102c6c:	83 ec 08             	sub    $0x8,%esp
f0102c6f:	68 00 10 00 00       	push   $0x1000
f0102c74:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0102c7a:	e8 2e e5 ff ff       	call   f01011ad <page_remove>
	assert(pp2->pp_ref == 0);
f0102c7f:	83 c4 10             	add    $0x10,%esp
f0102c82:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102c87:	74 19                	je     f0102ca2 <mem_init+0x19aa>
f0102c89:	68 f9 6a 10 f0       	push   $0xf0106af9
f0102c8e:	68 98 68 10 f0       	push   $0xf0106898
f0102c93:	68 5b 04 00 00       	push   $0x45b
f0102c98:	68 72 68 10 f0       	push   $0xf0106872
f0102c9d:	e8 9e d3 ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102ca2:	8b 0d 8c fe 22 f0    	mov    0xf022fe8c,%ecx
f0102ca8:	8b 11                	mov    (%ecx),%edx
f0102caa:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102cb0:	89 d8                	mov    %ebx,%eax
f0102cb2:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0102cb8:	c1 f8 03             	sar    $0x3,%eax
f0102cbb:	c1 e0 0c             	shl    $0xc,%eax
f0102cbe:	39 c2                	cmp    %eax,%edx
f0102cc0:	74 19                	je     f0102cdb <mem_init+0x19e3>
f0102cc2:	68 c0 6d 10 f0       	push   $0xf0106dc0
f0102cc7:	68 98 68 10 f0       	push   $0xf0106898
f0102ccc:	68 5e 04 00 00       	push   $0x45e
f0102cd1:	68 72 68 10 f0       	push   $0xf0106872
f0102cd6:	e8 65 d3 ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f0102cdb:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102ce1:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102ce6:	74 19                	je     f0102d01 <mem_init+0x1a09>
f0102ce8:	68 b0 6a 10 f0       	push   $0xf0106ab0
f0102ced:	68 98 68 10 f0       	push   $0xf0106898
f0102cf2:	68 60 04 00 00       	push   $0x460
f0102cf7:	68 72 68 10 f0       	push   $0xf0106872
f0102cfc:	e8 3f d3 ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f0102d01:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102d07:	83 ec 0c             	sub    $0xc,%esp
f0102d0a:	53                   	push   %ebx
f0102d0b:	e8 6b e2 ff ff       	call   f0100f7b <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102d10:	c7 04 24 64 74 10 f0 	movl   $0xf0107464,(%esp)
f0102d17:	e8 08 0a 00 00       	call   f0103724 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102d1c:	83 c4 10             	add    $0x10,%esp
f0102d1f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102d22:	5b                   	pop    %ebx
f0102d23:	5e                   	pop    %esi
f0102d24:	5f                   	pop    %edi
f0102d25:	5d                   	pop    %ebp
f0102d26:	c3                   	ret    

f0102d27 <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0102d27:	55                   	push   %ebp
f0102d28:	89 e5                	mov    %esp,%ebp
f0102d2a:	57                   	push   %edi
f0102d2b:	56                   	push   %esi
f0102d2c:	53                   	push   %ebx
f0102d2d:	83 ec 1c             	sub    $0x1c,%esp
f0102d30:	8b 7d 08             	mov    0x8(%ebp),%edi
f0102d33:	8b 75 14             	mov    0x14(%ebp),%esi
	// LAB 3: Your code here.
	uintptr_t begin = ROUNDDOWN((uintptr_t)va, PGSIZE);
f0102d36:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102d39:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uintptr_t end = ROUNDUP((uintptr_t)va + len, PGSIZE);
f0102d3f:	8b 45 10             	mov    0x10(%ebp),%eax
f0102d42:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102d45:	8d 84 02 ff 0f 00 00 	lea    0xfff(%edx,%eax,1),%eax
f0102d4c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102d51:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(uintptr_t i = begin;i < end;i += PGSIZE)
f0102d54:	eb 50                	jmp    f0102da6 <user_mem_check+0x7f>
	{
		pte_t *pte = pgdir_walk(env->env_pgdir, (void*)i, 0);
f0102d56:	83 ec 04             	sub    $0x4,%esp
f0102d59:	6a 00                	push   $0x0
f0102d5b:	53                   	push   %ebx
f0102d5c:	ff 77 60             	pushl  0x60(%edi)
f0102d5f:	e8 94 e2 ff ff       	call   f0100ff8 <pgdir_walk>
		if(pte == NULL||i >= ULIM||(*pte & PTE_P) == 0||(*pte & perm) != perm)
f0102d64:	83 c4 10             	add    $0x10,%esp
f0102d67:	85 c0                	test   %eax,%eax
f0102d69:	74 14                	je     f0102d7f <user_mem_check+0x58>
f0102d6b:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0102d71:	77 0c                	ja     f0102d7f <user_mem_check+0x58>
f0102d73:	8b 00                	mov    (%eax),%eax
f0102d75:	a8 01                	test   $0x1,%al
f0102d77:	74 06                	je     f0102d7f <user_mem_check+0x58>
f0102d79:	21 f0                	and    %esi,%eax
f0102d7b:	39 c6                	cmp    %eax,%esi
f0102d7d:	74 21                	je     f0102da0 <user_mem_check+0x79>
		{ 
			if(i < (uintptr_t)va)
f0102d7f:	3b 5d 0c             	cmp    0xc(%ebp),%ebx
f0102d82:	73 0f                	jae    f0102d93 <user_mem_check+0x6c>
			{
				user_mem_check_addr = (uintptr_t)va;
f0102d84:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102d87:	a3 3c f2 22 f0       	mov    %eax,0xf022f23c
			}
			else
			{
				user_mem_check_addr = (uintptr_t)i;
			}
			return -E_FAULT;
f0102d8c:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102d91:	eb 1d                	jmp    f0102db0 <user_mem_check+0x89>
			{
				user_mem_check_addr = (uintptr_t)va;
			}
			else
			{
				user_mem_check_addr = (uintptr_t)i;
f0102d93:	89 1d 3c f2 22 f0    	mov    %ebx,0xf022f23c
			}
			return -E_FAULT;
f0102d99:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102d9e:	eb 10                	jmp    f0102db0 <user_mem_check+0x89>
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
	// LAB 3: Your code here.
	uintptr_t begin = ROUNDDOWN((uintptr_t)va, PGSIZE);
	uintptr_t end = ROUNDUP((uintptr_t)va + len, PGSIZE);
	for(uintptr_t i = begin;i < end;i += PGSIZE)
f0102da0:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102da6:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0102da9:	72 ab                	jb     f0102d56 <user_mem_check+0x2f>
				user_mem_check_addr = (uintptr_t)i;
			}
			return -E_FAULT;
		}
	}
	return 0;
f0102dab:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102db0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102db3:	5b                   	pop    %ebx
f0102db4:	5e                   	pop    %esi
f0102db5:	5f                   	pop    %edi
f0102db6:	5d                   	pop    %ebp
f0102db7:	c3                   	ret    

f0102db8 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102db8:	55                   	push   %ebp
f0102db9:	89 e5                	mov    %esp,%ebp
f0102dbb:	53                   	push   %ebx
f0102dbc:	83 ec 04             	sub    $0x4,%esp
f0102dbf:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0102dc2:	8b 45 14             	mov    0x14(%ebp),%eax
f0102dc5:	83 c8 04             	or     $0x4,%eax
f0102dc8:	50                   	push   %eax
f0102dc9:	ff 75 10             	pushl  0x10(%ebp)
f0102dcc:	ff 75 0c             	pushl  0xc(%ebp)
f0102dcf:	53                   	push   %ebx
f0102dd0:	e8 52 ff ff ff       	call   f0102d27 <user_mem_check>
f0102dd5:	83 c4 10             	add    $0x10,%esp
f0102dd8:	85 c0                	test   %eax,%eax
f0102dda:	79 21                	jns    f0102dfd <user_mem_assert+0x45>
		cprintf("[%08x] user_mem_check assertion failure for "
f0102ddc:	83 ec 04             	sub    $0x4,%esp
f0102ddf:	ff 35 3c f2 22 f0    	pushl  0xf022f23c
f0102de5:	ff 73 48             	pushl  0x48(%ebx)
f0102de8:	68 90 74 10 f0       	push   $0xf0107490
f0102ded:	e8 32 09 00 00       	call   f0103724 <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0102df2:	89 1c 24             	mov    %ebx,(%esp)
f0102df5:	e8 3a 06 00 00       	call   f0103434 <env_destroy>
f0102dfa:	83 c4 10             	add    $0x10,%esp
	}
}
f0102dfd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102e00:	c9                   	leave  
f0102e01:	c3                   	ret    

f0102e02 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0102e02:	55                   	push   %ebp
f0102e03:	89 e5                	mov    %esp,%ebp
f0102e05:	57                   	push   %edi
f0102e06:	56                   	push   %esi
f0102e07:	53                   	push   %ebx
f0102e08:	83 ec 0c             	sub    $0xc,%esp
f0102e0b:	89 c7                	mov    %eax,%edi
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	int flag;
	void *begin = ROUNDDOWN(va, PGSIZE);
f0102e0d:	89 d3                	mov    %edx,%ebx
f0102e0f:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	void *end = ROUNDUP(va + len, PGSIZE);
f0102e15:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f0102e1c:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	for(begin; begin < end; begin += PGSIZE)
f0102e22:	eb 58                	jmp    f0102e7c <region_alloc+0x7a>
	{
		struct PageInfo *NewPage = page_alloc(0);
f0102e24:	83 ec 0c             	sub    $0xc,%esp
f0102e27:	6a 00                	push   $0x0
f0102e29:	e8 dd e0 ff ff       	call   f0100f0b <page_alloc>
		if(NewPage == NULL)
f0102e2e:	83 c4 10             	add    $0x10,%esp
f0102e31:	85 c0                	test   %eax,%eax
f0102e33:	75 17                	jne    f0102e4c <region_alloc+0x4a>
		{ 
			panic("can't allocate a new page");
f0102e35:	83 ec 04             	sub    $0x4,%esp
f0102e38:	68 c5 74 10 f0       	push   $0xf01074c5
f0102e3d:	68 2b 01 00 00       	push   $0x12b
f0102e42:	68 df 74 10 f0       	push   $0xf01074df
f0102e47:	e8 f4 d1 ff ff       	call   f0100040 <_panic>
		}
		flag = page_insert(e->env_pgdir, NewPage, begin, PTE_W|PTE_U);
f0102e4c:	6a 06                	push   $0x6
f0102e4e:	53                   	push   %ebx
f0102e4f:	50                   	push   %eax
f0102e50:	ff 77 60             	pushl  0x60(%edi)
f0102e53:	e8 9b e3 ff ff       	call   f01011f3 <page_insert>
		if(flag != 0)
f0102e58:	83 c4 10             	add    $0x10,%esp
f0102e5b:	85 c0                	test   %eax,%eax
f0102e5d:	74 17                	je     f0102e76 <region_alloc+0x74>
		{ 
			panic("map creation failed");
f0102e5f:	83 ec 04             	sub    $0x4,%esp
f0102e62:	68 ea 74 10 f0       	push   $0xf01074ea
f0102e67:	68 30 01 00 00       	push   $0x130
f0102e6c:	68 df 74 10 f0       	push   $0xf01074df
f0102e71:	e8 ca d1 ff ff       	call   f0100040 <_panic>
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	int flag;
	void *begin = ROUNDDOWN(va, PGSIZE);
	void *end = ROUNDUP(va + len, PGSIZE);
	for(begin; begin < end; begin += PGSIZE)
f0102e76:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102e7c:	39 f3                	cmp    %esi,%ebx
f0102e7e:	72 a4                	jb     f0102e24 <region_alloc+0x22>
		if(flag != 0)
		{ 
			panic("map creation failed");
		}
	}
}
f0102e80:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102e83:	5b                   	pop    %ebx
f0102e84:	5e                   	pop    %esi
f0102e85:	5f                   	pop    %edi
f0102e86:	5d                   	pop    %ebp
f0102e87:	c3                   	ret    

f0102e88 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0102e88:	55                   	push   %ebp
f0102e89:	89 e5                	mov    %esp,%ebp
f0102e8b:	56                   	push   %esi
f0102e8c:	53                   	push   %ebx
f0102e8d:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e90:	8b 55 10             	mov    0x10(%ebp),%edx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0102e93:	85 c0                	test   %eax,%eax
f0102e95:	75 1a                	jne    f0102eb1 <envid2env+0x29>
		*env_store = curenv;
f0102e97:	e8 ae 2d 00 00       	call   f0105c4a <cpunum>
f0102e9c:	6b c0 74             	imul   $0x74,%eax,%eax
f0102e9f:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0102ea5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102ea8:	89 01                	mov    %eax,(%ecx)
		return 0;
f0102eaa:	b8 00 00 00 00       	mov    $0x0,%eax
f0102eaf:	eb 70                	jmp    f0102f21 <envid2env+0x99>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0102eb1:	89 c3                	mov    %eax,%ebx
f0102eb3:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f0102eb9:	6b db 7c             	imul   $0x7c,%ebx,%ebx
f0102ebc:	03 1d 48 f2 22 f0    	add    0xf022f248,%ebx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0102ec2:	83 7b 54 00          	cmpl   $0x0,0x54(%ebx)
f0102ec6:	74 05                	je     f0102ecd <envid2env+0x45>
f0102ec8:	3b 43 48             	cmp    0x48(%ebx),%eax
f0102ecb:	74 10                	je     f0102edd <envid2env+0x55>
		*env_store = 0;
f0102ecd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102ed0:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102ed6:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102edb:	eb 44                	jmp    f0102f21 <envid2env+0x99>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0102edd:	84 d2                	test   %dl,%dl
f0102edf:	74 36                	je     f0102f17 <envid2env+0x8f>
f0102ee1:	e8 64 2d 00 00       	call   f0105c4a <cpunum>
f0102ee6:	6b c0 74             	imul   $0x74,%eax,%eax
f0102ee9:	3b 98 28 00 23 f0    	cmp    -0xfdcffd8(%eax),%ebx
f0102eef:	74 26                	je     f0102f17 <envid2env+0x8f>
f0102ef1:	8b 73 4c             	mov    0x4c(%ebx),%esi
f0102ef4:	e8 51 2d 00 00       	call   f0105c4a <cpunum>
f0102ef9:	6b c0 74             	imul   $0x74,%eax,%eax
f0102efc:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0102f02:	3b 70 48             	cmp    0x48(%eax),%esi
f0102f05:	74 10                	je     f0102f17 <envid2env+0x8f>
		*env_store = 0;
f0102f07:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102f0a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102f10:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102f15:	eb 0a                	jmp    f0102f21 <envid2env+0x99>
	}

	*env_store = e;
f0102f17:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102f1a:	89 18                	mov    %ebx,(%eax)
	return 0;
f0102f1c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102f21:	5b                   	pop    %ebx
f0102f22:	5e                   	pop    %esi
f0102f23:	5d                   	pop    %ebp
f0102f24:	c3                   	ret    

f0102f25 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0102f25:	55                   	push   %ebp
f0102f26:	89 e5                	mov    %esp,%ebp
}

static __inline void
lgdt(void *p)
{
	__asm __volatile("lgdt (%0)" : : "r" (p));
f0102f28:	b8 20 03 12 f0       	mov    $0xf0120320,%eax
f0102f2d:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f0102f30:	b8 23 00 00 00       	mov    $0x23,%eax
f0102f35:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f0102f37:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f0102f39:	b8 10 00 00 00       	mov    $0x10,%eax
f0102f3e:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f0102f40:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f0102f42:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f0102f44:	ea 4b 2f 10 f0 08 00 	ljmp   $0x8,$0xf0102f4b
}

static __inline void
lldt(uint16_t sel)
{
	__asm __volatile("lldt %0" : : "r" (sel));
f0102f4b:	b8 00 00 00 00       	mov    $0x0,%eax
f0102f50:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0102f53:	5d                   	pop    %ebp
f0102f54:	c3                   	ret    

f0102f55 <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0102f55:	55                   	push   %ebp
f0102f56:	89 e5                	mov    %esp,%ebp
f0102f58:	56                   	push   %esi
f0102f59:	53                   	push   %ebx
	// Set up envs array
	// LAB 3: Your code here.
	env_free_list = NULL; 
	for(int i = NENV - 1;i >= 0;i--)
	{
		envs[i].env_id = 0;  
f0102f5a:	8b 35 48 f2 22 f0    	mov    0xf022f248,%esi
f0102f60:	8d 86 84 ef 01 00    	lea    0x1ef84(%esi),%eax
f0102f66:	8d 5e 84             	lea    -0x7c(%esi),%ebx
f0102f69:	ba 00 00 00 00       	mov    $0x0,%edx
f0102f6e:	89 c1                	mov    %eax,%ecx
f0102f70:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_link = env_free_list; 
f0102f77:	89 50 44             	mov    %edx,0x44(%eax)
		envs[i].env_status = ENV_FREE; 
f0102f7a:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
f0102f81:	83 e8 7c             	sub    $0x7c,%eax
		env_free_list = &envs[i]; 
f0102f84:	89 ca                	mov    %ecx,%edx
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.
	env_free_list = NULL; 
	for(int i = NENV - 1;i >= 0;i--)
f0102f86:	39 d8                	cmp    %ebx,%eax
f0102f88:	75 e4                	jne    f0102f6e <env_init+0x19>
f0102f8a:	89 35 4c f2 22 f0    	mov    %esi,0xf022f24c
		envs[i].env_link = env_free_list; 
		envs[i].env_status = ENV_FREE; 
		env_free_list = &envs[i]; 
	}
	// Per-CPU part of the initialization
	env_init_percpu();
f0102f90:	e8 90 ff ff ff       	call   f0102f25 <env_init_percpu>
}
f0102f95:	5b                   	pop    %ebx
f0102f96:	5e                   	pop    %esi
f0102f97:	5d                   	pop    %ebp
f0102f98:	c3                   	ret    

f0102f99 <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0102f99:	55                   	push   %ebp
f0102f9a:	89 e5                	mov    %esp,%ebp
f0102f9c:	53                   	push   %ebx
f0102f9d:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0102fa0:	8b 1d 4c f2 22 f0    	mov    0xf022f24c,%ebx
f0102fa6:	85 db                	test   %ebx,%ebx
f0102fa8:	0f 84 69 01 00 00    	je     f0103117 <env_alloc+0x17e>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0102fae:	83 ec 0c             	sub    $0xc,%esp
f0102fb1:	6a 01                	push   $0x1
f0102fb3:	e8 53 df ff ff       	call   f0100f0b <page_alloc>
f0102fb8:	83 c4 10             	add    $0x10,%esp
f0102fbb:	85 c0                	test   %eax,%eax
f0102fbd:	0f 84 5b 01 00 00    	je     f010311e <env_alloc+0x185>
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	p->pp_ref++; 
f0102fc3:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102fc8:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0102fce:	c1 f8 03             	sar    $0x3,%eax
f0102fd1:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102fd4:	89 c2                	mov    %eax,%edx
f0102fd6:	c1 ea 0c             	shr    $0xc,%edx
f0102fd9:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f0102fdf:	72 12                	jb     f0102ff3 <env_alloc+0x5a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102fe1:	50                   	push   %eax
f0102fe2:	68 04 63 10 f0       	push   $0xf0106304
f0102fe7:	6a 58                	push   $0x58
f0102fe9:	68 7e 68 10 f0       	push   $0xf010687e
f0102fee:	e8 4d d0 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0102ff3:	2d 00 00 00 10       	sub    $0x10000000,%eax
	e->env_pgdir = page2kva(p); 
f0102ff8:	89 43 60             	mov    %eax,0x60(%ebx)
	memcpy(e->env_pgdir, kern_pgdir, PGSIZE);
f0102ffb:	83 ec 04             	sub    $0x4,%esp
f0102ffe:	68 00 10 00 00       	push   $0x1000
f0103003:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0103009:	50                   	push   %eax
f010300a:	e8 ce 26 00 00       	call   f01056dd <memcpy>
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f010300f:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103012:	83 c4 10             	add    $0x10,%esp
f0103015:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010301a:	77 15                	ja     f0103031 <env_alloc+0x98>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010301c:	50                   	push   %eax
f010301d:	68 28 63 10 f0       	push   $0xf0106328
f0103022:	68 c5 00 00 00       	push   $0xc5
f0103027:	68 df 74 10 f0       	push   $0xf01074df
f010302c:	e8 0f d0 ff ff       	call   f0100040 <_panic>
f0103031:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0103037:	83 ca 05             	or     $0x5,%edx
f010303a:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0103040:	8b 43 48             	mov    0x48(%ebx),%eax
f0103043:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0103048:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f010304d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0103052:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0103055:	89 da                	mov    %ebx,%edx
f0103057:	2b 15 48 f2 22 f0    	sub    0xf022f248,%edx
f010305d:	c1 fa 02             	sar    $0x2,%edx
f0103060:	69 d2 df 7b ef bd    	imul   $0xbdef7bdf,%edx,%edx
f0103066:	09 d0                	or     %edx,%eax
f0103068:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f010306b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010306e:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0103071:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0103078:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f010307f:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0103086:	83 ec 04             	sub    $0x4,%esp
f0103089:	6a 44                	push   $0x44
f010308b:	6a 00                	push   $0x0
f010308d:	53                   	push   %ebx
f010308e:	e8 95 25 00 00       	call   f0105628 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0103093:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0103099:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f010309f:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f01030a5:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f01030ac:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// Enable interrupts while in user mode.
	// LAB 4: Your code here.
	e->env_tf.tf_eflags |= FL_IF;
f01030b2:	81 4b 38 00 02 00 00 	orl    $0x200,0x38(%ebx)
	// Clear the page fault handler until user installs one.
	e->env_pgfault_upcall = 0;
f01030b9:	c7 43 64 00 00 00 00 	movl   $0x0,0x64(%ebx)

	// Also clear the IPC receiving flag.
	e->env_ipc_recving = 0;
f01030c0:	c6 43 68 00          	movb   $0x0,0x68(%ebx)

	// commit the allocation
	env_free_list = e->env_link;
f01030c4:	8b 43 44             	mov    0x44(%ebx),%eax
f01030c7:	a3 4c f2 22 f0       	mov    %eax,0xf022f24c
	*newenv_store = e;
f01030cc:	8b 45 08             	mov    0x8(%ebp),%eax
f01030cf:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01030d1:	8b 5b 48             	mov    0x48(%ebx),%ebx
f01030d4:	e8 71 2b 00 00       	call   f0105c4a <cpunum>
f01030d9:	6b c0 74             	imul   $0x74,%eax,%eax
f01030dc:	83 c4 10             	add    $0x10,%esp
f01030df:	ba 00 00 00 00       	mov    $0x0,%edx
f01030e4:	83 b8 28 00 23 f0 00 	cmpl   $0x0,-0xfdcffd8(%eax)
f01030eb:	74 11                	je     f01030fe <env_alloc+0x165>
f01030ed:	e8 58 2b 00 00       	call   f0105c4a <cpunum>
f01030f2:	6b c0 74             	imul   $0x74,%eax,%eax
f01030f5:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f01030fb:	8b 50 48             	mov    0x48(%eax),%edx
f01030fe:	83 ec 04             	sub    $0x4,%esp
f0103101:	53                   	push   %ebx
f0103102:	52                   	push   %edx
f0103103:	68 fe 74 10 f0       	push   $0xf01074fe
f0103108:	e8 17 06 00 00       	call   f0103724 <cprintf>
	return 0;
f010310d:	83 c4 10             	add    $0x10,%esp
f0103110:	b8 00 00 00 00       	mov    $0x0,%eax
f0103115:	eb 0c                	jmp    f0103123 <env_alloc+0x18a>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0103117:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f010311c:	eb 05                	jmp    f0103123 <env_alloc+0x18a>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f010311e:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0103123:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103126:	c9                   	leave  
f0103127:	c3                   	ret    

f0103128 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0103128:	55                   	push   %ebp
f0103129:	89 e5                	mov    %esp,%ebp
f010312b:	57                   	push   %edi
f010312c:	56                   	push   %esi
f010312d:	53                   	push   %ebx
f010312e:	83 ec 34             	sub    $0x34,%esp
f0103131:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env *e;
	int flag = env_alloc(&e, 0);
f0103134:	6a 00                	push   $0x0
f0103136:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0103139:	50                   	push   %eax
f010313a:	e8 5a fe ff ff       	call   f0102f99 <env_alloc>
	if(flag != 0) 
f010313f:	83 c4 10             	add    $0x10,%esp
f0103142:	85 c0                	test   %eax,%eax
f0103144:	74 17                	je     f010315d <env_create+0x35>
	{
		panic("create new env failed!");
f0103146:	83 ec 04             	sub    $0x4,%esp
f0103149:	68 13 75 10 f0       	push   $0xf0107513
f010314e:	68 95 01 00 00       	push   $0x195
f0103153:	68 df 74 10 f0       	push   $0xf01074df
f0103158:	e8 e3 ce ff ff       	call   f0100040 <_panic>
	}
	load_icode(e, binary);
f010315d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103160:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	//  What?  (See env_run() and env_pop_tf() below.)

	// LAB 3: Your code here.
	struct Elf *elf_header = (struct Elf*)binary; 
	struct Proghdr *ph, *eph;
	if (elf_header->e_magic != ELF_MAGIC)
f0103163:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f0103169:	74 17                	je     f0103182 <env_create+0x5a>
	{
		panic("binary is not a elf file"); 
f010316b:	83 ec 04             	sub    $0x4,%esp
f010316e:	68 2a 75 10 f0       	push   $0xf010752a
f0103173:	68 6f 01 00 00       	push   $0x16f
f0103178:	68 df 74 10 f0       	push   $0xf01074df
f010317d:	e8 be ce ff ff       	call   f0100040 <_panic>
	}
	ph = (struct Proghdr*) ((uint8_t*)elf_header + elf_header->e_phoff);
f0103182:	89 fb                	mov    %edi,%ebx
f0103184:	03 5f 1c             	add    0x1c(%edi),%ebx
	eph = ph + elf_header->e_phnum;
f0103187:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f010318b:	c1 e6 05             	shl    $0x5,%esi
f010318e:	01 de                	add    %ebx,%esi
	lcr3(PADDR(e->env_pgdir)); 
f0103190:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103193:	8b 40 60             	mov    0x60(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103196:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010319b:	77 15                	ja     f01031b2 <env_create+0x8a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010319d:	50                   	push   %eax
f010319e:	68 28 63 10 f0       	push   $0xf0106328
f01031a3:	68 73 01 00 00       	push   $0x173
f01031a8:	68 df 74 10 f0       	push   $0xf01074df
f01031ad:	e8 8e ce ff ff       	call   f0100040 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01031b2:	05 00 00 00 10       	add    $0x10000000,%eax
f01031b7:	0f 22 d8             	mov    %eax,%cr3
f01031ba:	eb 44                	jmp    f0103200 <env_create+0xd8>
	for (; ph < eph; ph++)
	{
		if(ph->p_type == ELF_PROG_LOAD) 
f01031bc:	83 3b 01             	cmpl   $0x1,(%ebx)
f01031bf:	75 3c                	jne    f01031fd <env_create+0xd5>
		{
			region_alloc(e, (void*)ph->p_va, ph->p_memsz); 
f01031c1:	8b 4b 14             	mov    0x14(%ebx),%ecx
f01031c4:	8b 53 08             	mov    0x8(%ebx),%edx
f01031c7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01031ca:	e8 33 fc ff ff       	call   f0102e02 <region_alloc>
			memmove((void*)ph->p_va, binary + ph->p_offset, ph->p_filesz);
f01031cf:	83 ec 04             	sub    $0x4,%esp
f01031d2:	ff 73 10             	pushl  0x10(%ebx)
f01031d5:	89 f8                	mov    %edi,%eax
f01031d7:	03 43 04             	add    0x4(%ebx),%eax
f01031da:	50                   	push   %eax
f01031db:	ff 73 08             	pushl  0x8(%ebx)
f01031de:	e8 92 24 00 00       	call   f0105675 <memmove>
            		memset((void*)(ph->p_va + ph->p_filesz), 0, ph->p_memsz - ph->p_filesz);
f01031e3:	8b 43 10             	mov    0x10(%ebx),%eax
f01031e6:	83 c4 0c             	add    $0xc,%esp
f01031e9:	8b 53 14             	mov    0x14(%ebx),%edx
f01031ec:	29 c2                	sub    %eax,%edx
f01031ee:	52                   	push   %edx
f01031ef:	6a 00                	push   $0x0
f01031f1:	03 43 08             	add    0x8(%ebx),%eax
f01031f4:	50                   	push   %eax
f01031f5:	e8 2e 24 00 00       	call   f0105628 <memset>
f01031fa:	83 c4 10             	add    $0x10,%esp
		panic("binary is not a elf file"); 
	}
	ph = (struct Proghdr*) ((uint8_t*)elf_header + elf_header->e_phoff);
	eph = ph + elf_header->e_phnum;
	lcr3(PADDR(e->env_pgdir)); 
	for (; ph < eph; ph++)
f01031fd:	83 c3 20             	add    $0x20,%ebx
f0103200:	39 de                	cmp    %ebx,%esi
f0103202:	77 b8                	ja     f01031bc <env_create+0x94>
			region_alloc(e, (void*)ph->p_va, ph->p_memsz); 
			memmove((void*)ph->p_va, binary + ph->p_offset, ph->p_filesz);
            		memset((void*)(ph->p_va + ph->p_filesz), 0, ph->p_memsz - ph->p_filesz);
		}
	}
	e->env_tf.tf_eip = elf_header->e_entry; 
f0103204:	8b 47 18             	mov    0x18(%edi),%eax
f0103207:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010320a:	89 41 30             	mov    %eax,0x30(%ecx)
	lcr3(PADDR(kern_pgdir)); 
f010320d:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103212:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103217:	77 15                	ja     f010322e <env_create+0x106>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103219:	50                   	push   %eax
f010321a:	68 28 63 10 f0       	push   $0xf0106328
f010321f:	68 7e 01 00 00       	push   $0x17e
f0103224:	68 df 74 10 f0       	push   $0xf01074df
f0103229:	e8 12 ce ff ff       	call   f0100040 <_panic>
f010322e:	05 00 00 00 10       	add    $0x10000000,%eax
f0103233:	0f 22 d8             	mov    %eax,%cr3
	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here.
	region_alloc(e, (void*)(USTACKTOP - PGSIZE), PGSIZE);
f0103236:	b9 00 10 00 00       	mov    $0x1000,%ecx
f010323b:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0103240:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103243:	e8 ba fb ff ff       	call   f0102e02 <region_alloc>
	if(flag != 0) 
	{
		panic("create new env failed!");
	}
	load_icode(e, binary);
	e->env_type = type; 
f0103248:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010324b:	8b 55 0c             	mov    0xc(%ebp),%edx
f010324e:	89 50 50             	mov    %edx,0x50(%eax)
}
f0103251:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103254:	5b                   	pop    %ebx
f0103255:	5e                   	pop    %esi
f0103256:	5f                   	pop    %edi
f0103257:	5d                   	pop    %ebp
f0103258:	c3                   	ret    

f0103259 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0103259:	55                   	push   %ebp
f010325a:	89 e5                	mov    %esp,%ebp
f010325c:	57                   	push   %edi
f010325d:	56                   	push   %esi
f010325e:	53                   	push   %ebx
f010325f:	83 ec 1c             	sub    $0x1c,%esp
f0103262:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0103265:	e8 e0 29 00 00       	call   f0105c4a <cpunum>
f010326a:	6b c0 74             	imul   $0x74,%eax,%eax
f010326d:	39 b8 28 00 23 f0    	cmp    %edi,-0xfdcffd8(%eax)
f0103273:	75 29                	jne    f010329e <env_free+0x45>
		lcr3(PADDR(kern_pgdir));
f0103275:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010327a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010327f:	77 15                	ja     f0103296 <env_free+0x3d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103281:	50                   	push   %eax
f0103282:	68 28 63 10 f0       	push   $0xf0106328
f0103287:	68 a9 01 00 00       	push   $0x1a9
f010328c:	68 df 74 10 f0       	push   $0xf01074df
f0103291:	e8 aa cd ff ff       	call   f0100040 <_panic>
f0103296:	05 00 00 00 10       	add    $0x10000000,%eax
f010329b:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f010329e:	8b 5f 48             	mov    0x48(%edi),%ebx
f01032a1:	e8 a4 29 00 00       	call   f0105c4a <cpunum>
f01032a6:	6b c0 74             	imul   $0x74,%eax,%eax
f01032a9:	ba 00 00 00 00       	mov    $0x0,%edx
f01032ae:	83 b8 28 00 23 f0 00 	cmpl   $0x0,-0xfdcffd8(%eax)
f01032b5:	74 11                	je     f01032c8 <env_free+0x6f>
f01032b7:	e8 8e 29 00 00       	call   f0105c4a <cpunum>
f01032bc:	6b c0 74             	imul   $0x74,%eax,%eax
f01032bf:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f01032c5:	8b 50 48             	mov    0x48(%eax),%edx
f01032c8:	83 ec 04             	sub    $0x4,%esp
f01032cb:	53                   	push   %ebx
f01032cc:	52                   	push   %edx
f01032cd:	68 43 75 10 f0       	push   $0xf0107543
f01032d2:	e8 4d 04 00 00       	call   f0103724 <cprintf>
f01032d7:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f01032da:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f01032e1:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01032e4:	89 d0                	mov    %edx,%eax
f01032e6:	c1 e0 02             	shl    $0x2,%eax
f01032e9:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f01032ec:	8b 47 60             	mov    0x60(%edi),%eax
f01032ef:	8b 34 90             	mov    (%eax,%edx,4),%esi
f01032f2:	f7 c6 01 00 00 00    	test   $0x1,%esi
f01032f8:	0f 84 a8 00 00 00    	je     f01033a6 <env_free+0x14d>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f01032fe:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103304:	89 f0                	mov    %esi,%eax
f0103306:	c1 e8 0c             	shr    $0xc,%eax
f0103309:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010330c:	39 05 88 fe 22 f0    	cmp    %eax,0xf022fe88
f0103312:	77 15                	ja     f0103329 <env_free+0xd0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103314:	56                   	push   %esi
f0103315:	68 04 63 10 f0       	push   $0xf0106304
f010331a:	68 b8 01 00 00       	push   $0x1b8
f010331f:	68 df 74 10 f0       	push   $0xf01074df
f0103324:	e8 17 cd ff ff       	call   f0100040 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103329:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010332c:	c1 e0 16             	shl    $0x16,%eax
f010332f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103332:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0103337:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f010333e:	01 
f010333f:	74 17                	je     f0103358 <env_free+0xff>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103341:	83 ec 08             	sub    $0x8,%esp
f0103344:	89 d8                	mov    %ebx,%eax
f0103346:	c1 e0 0c             	shl    $0xc,%eax
f0103349:	0b 45 e4             	or     -0x1c(%ebp),%eax
f010334c:	50                   	push   %eax
f010334d:	ff 77 60             	pushl  0x60(%edi)
f0103350:	e8 58 de ff ff       	call   f01011ad <page_remove>
f0103355:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103358:	83 c3 01             	add    $0x1,%ebx
f010335b:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0103361:	75 d4                	jne    f0103337 <env_free+0xde>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0103363:	8b 47 60             	mov    0x60(%edi),%eax
f0103366:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103369:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103370:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103373:	3b 05 88 fe 22 f0    	cmp    0xf022fe88,%eax
f0103379:	72 14                	jb     f010338f <env_free+0x136>
		panic("pa2page called with invalid pa");
f010337b:	83 ec 04             	sub    $0x4,%esp
f010337e:	68 8c 6c 10 f0       	push   $0xf0106c8c
f0103383:	6a 51                	push   $0x51
f0103385:	68 7e 68 10 f0       	push   $0xf010687e
f010338a:	e8 b1 cc ff ff       	call   f0100040 <_panic>
		page_decref(pa2page(pa));
f010338f:	83 ec 0c             	sub    $0xc,%esp
f0103392:	a1 90 fe 22 f0       	mov    0xf022fe90,%eax
f0103397:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010339a:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f010339d:	50                   	push   %eax
f010339e:	e8 2e dc ff ff       	call   f0100fd1 <page_decref>
f01033a3:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f01033a6:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f01033aa:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01033ad:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f01033b2:	0f 85 29 ff ff ff    	jne    f01032e1 <env_free+0x88>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f01033b8:	8b 47 60             	mov    0x60(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01033bb:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01033c0:	77 15                	ja     f01033d7 <env_free+0x17e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01033c2:	50                   	push   %eax
f01033c3:	68 28 63 10 f0       	push   $0xf0106328
f01033c8:	68 c6 01 00 00       	push   $0x1c6
f01033cd:	68 df 74 10 f0       	push   $0xf01074df
f01033d2:	e8 69 cc ff ff       	call   f0100040 <_panic>
	e->env_pgdir = 0;
f01033d7:	c7 47 60 00 00 00 00 	movl   $0x0,0x60(%edi)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01033de:	05 00 00 00 10       	add    $0x10000000,%eax
f01033e3:	c1 e8 0c             	shr    $0xc,%eax
f01033e6:	3b 05 88 fe 22 f0    	cmp    0xf022fe88,%eax
f01033ec:	72 14                	jb     f0103402 <env_free+0x1a9>
		panic("pa2page called with invalid pa");
f01033ee:	83 ec 04             	sub    $0x4,%esp
f01033f1:	68 8c 6c 10 f0       	push   $0xf0106c8c
f01033f6:	6a 51                	push   $0x51
f01033f8:	68 7e 68 10 f0       	push   $0xf010687e
f01033fd:	e8 3e cc ff ff       	call   f0100040 <_panic>
	page_decref(pa2page(pa));
f0103402:	83 ec 0c             	sub    $0xc,%esp
f0103405:	8b 15 90 fe 22 f0    	mov    0xf022fe90,%edx
f010340b:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f010340e:	50                   	push   %eax
f010340f:	e8 bd db ff ff       	call   f0100fd1 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0103414:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f010341b:	a1 4c f2 22 f0       	mov    0xf022f24c,%eax
f0103420:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0103423:	89 3d 4c f2 22 f0    	mov    %edi,0xf022f24c
}
f0103429:	83 c4 10             	add    $0x10,%esp
f010342c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010342f:	5b                   	pop    %ebx
f0103430:	5e                   	pop    %esi
f0103431:	5f                   	pop    %edi
f0103432:	5d                   	pop    %ebp
f0103433:	c3                   	ret    

f0103434 <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e)
{
f0103434:	55                   	push   %ebp
f0103435:	89 e5                	mov    %esp,%ebp
f0103437:	53                   	push   %ebx
f0103438:	83 ec 04             	sub    $0x4,%esp
f010343b:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// If e is currently running on other CPUs, we change its state to
	// ENV_DYING. A zombie environment will be freed the next time
	// it traps to the kernel.
	if (e->env_status == ENV_RUNNING && curenv != e) {
f010343e:	83 7b 54 03          	cmpl   $0x3,0x54(%ebx)
f0103442:	75 19                	jne    f010345d <env_destroy+0x29>
f0103444:	e8 01 28 00 00       	call   f0105c4a <cpunum>
f0103449:	6b c0 74             	imul   $0x74,%eax,%eax
f010344c:	3b 98 28 00 23 f0    	cmp    -0xfdcffd8(%eax),%ebx
f0103452:	74 09                	je     f010345d <env_destroy+0x29>
		e->env_status = ENV_DYING;
f0103454:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
		return;
f010345b:	eb 33                	jmp    f0103490 <env_destroy+0x5c>
	}

	env_free(e);
f010345d:	83 ec 0c             	sub    $0xc,%esp
f0103460:	53                   	push   %ebx
f0103461:	e8 f3 fd ff ff       	call   f0103259 <env_free>

	if (curenv == e) {
f0103466:	e8 df 27 00 00       	call   f0105c4a <cpunum>
f010346b:	6b c0 74             	imul   $0x74,%eax,%eax
f010346e:	83 c4 10             	add    $0x10,%esp
f0103471:	3b 98 28 00 23 f0    	cmp    -0xfdcffd8(%eax),%ebx
f0103477:	75 17                	jne    f0103490 <env_destroy+0x5c>
		curenv = NULL;
f0103479:	e8 cc 27 00 00       	call   f0105c4a <cpunum>
f010347e:	6b c0 74             	imul   $0x74,%eax,%eax
f0103481:	c7 80 28 00 23 f0 00 	movl   $0x0,-0xfdcffd8(%eax)
f0103488:	00 00 00 
		sched_yield();
f010348b:	e8 67 10 00 00       	call   f01044f7 <sched_yield>
	}
}
f0103490:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103493:	c9                   	leave  
f0103494:	c3                   	ret    

f0103495 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0103495:	55                   	push   %ebp
f0103496:	89 e5                	mov    %esp,%ebp
f0103498:	53                   	push   %ebx
f0103499:	83 ec 04             	sub    $0x4,%esp
	// Record the CPU we are running on for user-space debugging
	curenv->env_cpunum = cpunum();
f010349c:	e8 a9 27 00 00       	call   f0105c4a <cpunum>
f01034a1:	6b c0 74             	imul   $0x74,%eax,%eax
f01034a4:	8b 98 28 00 23 f0    	mov    -0xfdcffd8(%eax),%ebx
f01034aa:	e8 9b 27 00 00       	call   f0105c4a <cpunum>
f01034af:	89 43 5c             	mov    %eax,0x5c(%ebx)

	__asm __volatile("movl %0,%%esp\n"
f01034b2:	8b 65 08             	mov    0x8(%ebp),%esp
f01034b5:	61                   	popa   
f01034b6:	07                   	pop    %es
f01034b7:	1f                   	pop    %ds
f01034b8:	83 c4 08             	add    $0x8,%esp
f01034bb:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f01034bc:	83 ec 04             	sub    $0x4,%esp
f01034bf:	68 59 75 10 f0       	push   $0xf0107559
f01034c4:	68 fc 01 00 00       	push   $0x1fc
f01034c9:	68 df 74 10 f0       	push   $0xf01074df
f01034ce:	e8 6d cb ff ff       	call   f0100040 <_panic>

f01034d3 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f01034d3:	55                   	push   %ebp
f01034d4:	89 e5                	mov    %esp,%ebp
f01034d6:	83 ec 08             	sub    $0x8,%esp
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	if (curenv != NULL && curenv->env_status == ENV_RUNNING) {
f01034d9:	e8 6c 27 00 00       	call   f0105c4a <cpunum>
f01034de:	6b c0 74             	imul   $0x74,%eax,%eax
f01034e1:	83 b8 28 00 23 f0 00 	cmpl   $0x0,-0xfdcffd8(%eax)
f01034e8:	74 29                	je     f0103513 <env_run+0x40>
f01034ea:	e8 5b 27 00 00       	call   f0105c4a <cpunum>
f01034ef:	6b c0 74             	imul   $0x74,%eax,%eax
f01034f2:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f01034f8:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f01034fc:	75 15                	jne    f0103513 <env_run+0x40>
		curenv->env_status = ENV_RUNNABLE;
f01034fe:	e8 47 27 00 00       	call   f0105c4a <cpunum>
f0103503:	6b c0 74             	imul   $0x74,%eax,%eax
f0103506:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f010350c:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	}
	curenv = e;
f0103513:	e8 32 27 00 00       	call   f0105c4a <cpunum>
f0103518:	6b c0 74             	imul   $0x74,%eax,%eax
f010351b:	8b 55 08             	mov    0x8(%ebp),%edx
f010351e:	89 90 28 00 23 f0    	mov    %edx,-0xfdcffd8(%eax)
	curenv->env_status = ENV_RUNNING;
f0103524:	e8 21 27 00 00       	call   f0105c4a <cpunum>
f0103529:	6b c0 74             	imul   $0x74,%eax,%eax
f010352c:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0103532:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv->env_runs++;
f0103539:	e8 0c 27 00 00       	call   f0105c4a <cpunum>
f010353e:	6b c0 74             	imul   $0x74,%eax,%eax
f0103541:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0103547:	83 40 58 01          	addl   $0x1,0x58(%eax)
	lcr3(PADDR(curenv->env_pgdir));
f010354b:	e8 fa 26 00 00       	call   f0105c4a <cpunum>
f0103550:	6b c0 74             	imul   $0x74,%eax,%eax
f0103553:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0103559:	8b 40 60             	mov    0x60(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010355c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103561:	77 15                	ja     f0103578 <env_run+0xa5>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103563:	50                   	push   %eax
f0103564:	68 28 63 10 f0       	push   $0xf0106328
f0103569:	68 20 02 00 00       	push   $0x220
f010356e:	68 df 74 10 f0       	push   $0xf01074df
f0103573:	e8 c8 ca ff ff       	call   f0100040 <_panic>
f0103578:	05 00 00 00 10       	add    $0x10000000,%eax
f010357d:	0f 22 d8             	mov    %eax,%cr3
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f0103580:	83 ec 0c             	sub    $0xc,%esp
f0103583:	68 c0 03 12 f0       	push   $0xf01203c0
f0103588:	e8 c8 29 00 00       	call   f0105f55 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f010358d:	f3 90                	pause  
	unlock_kernel();
	env_pop_tf(&(curenv->env_tf));
f010358f:	e8 b6 26 00 00       	call   f0105c4a <cpunum>
f0103594:	83 c4 04             	add    $0x4,%esp
f0103597:	6b c0 74             	imul   $0x74,%eax,%eax
f010359a:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f01035a0:	e8 f0 fe ff ff       	call   f0103495 <env_pop_tf>

f01035a5 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01035a5:	55                   	push   %ebp
f01035a6:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01035a8:	ba 70 00 00 00       	mov    $0x70,%edx
f01035ad:	8b 45 08             	mov    0x8(%ebp),%eax
f01035b0:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01035b1:	ba 71 00 00 00       	mov    $0x71,%edx
f01035b6:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01035b7:	0f b6 c0             	movzbl %al,%eax
}
f01035ba:	5d                   	pop    %ebp
f01035bb:	c3                   	ret    

f01035bc <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01035bc:	55                   	push   %ebp
f01035bd:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01035bf:	ba 70 00 00 00       	mov    $0x70,%edx
f01035c4:	8b 45 08             	mov    0x8(%ebp),%eax
f01035c7:	ee                   	out    %al,(%dx)
f01035c8:	ba 71 00 00 00       	mov    $0x71,%edx
f01035cd:	8b 45 0c             	mov    0xc(%ebp),%eax
f01035d0:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01035d1:	5d                   	pop    %ebp
f01035d2:	c3                   	ret    

f01035d3 <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f01035d3:	55                   	push   %ebp
f01035d4:	89 e5                	mov    %esp,%ebp
f01035d6:	56                   	push   %esi
f01035d7:	53                   	push   %ebx
f01035d8:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	irq_mask_8259A = mask;
f01035db:	66 a3 a8 03 12 f0    	mov    %ax,0xf01203a8
	if (!didinit)
f01035e1:	80 3d 50 f2 22 f0 00 	cmpb   $0x0,0xf022f250
f01035e8:	74 5a                	je     f0103644 <irq_setmask_8259A+0x71>
f01035ea:	89 c6                	mov    %eax,%esi
f01035ec:	ba 21 00 00 00       	mov    $0x21,%edx
f01035f1:	ee                   	out    %al,(%dx)
f01035f2:	66 c1 e8 08          	shr    $0x8,%ax
f01035f6:	ba a1 00 00 00       	mov    $0xa1,%edx
f01035fb:	ee                   	out    %al,(%dx)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
f01035fc:	83 ec 0c             	sub    $0xc,%esp
f01035ff:	68 65 75 10 f0       	push   $0xf0107565
f0103604:	e8 1b 01 00 00       	call   f0103724 <cprintf>
f0103609:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < 16; i++)
f010360c:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f0103611:	0f b7 f6             	movzwl %si,%esi
f0103614:	f7 d6                	not    %esi
f0103616:	0f a3 de             	bt     %ebx,%esi
f0103619:	73 11                	jae    f010362c <irq_setmask_8259A+0x59>
			cprintf(" %d", i);
f010361b:	83 ec 08             	sub    $0x8,%esp
f010361e:	53                   	push   %ebx
f010361f:	68 3b 7a 10 f0       	push   $0xf0107a3b
f0103624:	e8 fb 00 00 00       	call   f0103724 <cprintf>
f0103629:	83 c4 10             	add    $0x10,%esp
	if (!didinit)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
	for (i = 0; i < 16; i++)
f010362c:	83 c3 01             	add    $0x1,%ebx
f010362f:	83 fb 10             	cmp    $0x10,%ebx
f0103632:	75 e2                	jne    f0103616 <irq_setmask_8259A+0x43>
		if (~mask & (1<<i))
			cprintf(" %d", i);
	cprintf("\n");
f0103634:	83 ec 0c             	sub    $0xc,%esp
f0103637:	68 94 6b 10 f0       	push   $0xf0106b94
f010363c:	e8 e3 00 00 00       	call   f0103724 <cprintf>
f0103641:	83 c4 10             	add    $0x10,%esp
}
f0103644:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103647:	5b                   	pop    %ebx
f0103648:	5e                   	pop    %esi
f0103649:	5d                   	pop    %ebp
f010364a:	c3                   	ret    

f010364b <pic_init>:

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
	didinit = 1;
f010364b:	c6 05 50 f2 22 f0 01 	movb   $0x1,0xf022f250
f0103652:	ba 21 00 00 00       	mov    $0x21,%edx
f0103657:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010365c:	ee                   	out    %al,(%dx)
f010365d:	ba a1 00 00 00       	mov    $0xa1,%edx
f0103662:	ee                   	out    %al,(%dx)
f0103663:	ba 20 00 00 00       	mov    $0x20,%edx
f0103668:	b8 11 00 00 00       	mov    $0x11,%eax
f010366d:	ee                   	out    %al,(%dx)
f010366e:	ba 21 00 00 00       	mov    $0x21,%edx
f0103673:	b8 20 00 00 00       	mov    $0x20,%eax
f0103678:	ee                   	out    %al,(%dx)
f0103679:	b8 04 00 00 00       	mov    $0x4,%eax
f010367e:	ee                   	out    %al,(%dx)
f010367f:	b8 03 00 00 00       	mov    $0x3,%eax
f0103684:	ee                   	out    %al,(%dx)
f0103685:	ba a0 00 00 00       	mov    $0xa0,%edx
f010368a:	b8 11 00 00 00       	mov    $0x11,%eax
f010368f:	ee                   	out    %al,(%dx)
f0103690:	ba a1 00 00 00       	mov    $0xa1,%edx
f0103695:	b8 28 00 00 00       	mov    $0x28,%eax
f010369a:	ee                   	out    %al,(%dx)
f010369b:	b8 02 00 00 00       	mov    $0x2,%eax
f01036a0:	ee                   	out    %al,(%dx)
f01036a1:	b8 01 00 00 00       	mov    $0x1,%eax
f01036a6:	ee                   	out    %al,(%dx)
f01036a7:	ba 20 00 00 00       	mov    $0x20,%edx
f01036ac:	b8 68 00 00 00       	mov    $0x68,%eax
f01036b1:	ee                   	out    %al,(%dx)
f01036b2:	b8 0a 00 00 00       	mov    $0xa,%eax
f01036b7:	ee                   	out    %al,(%dx)
f01036b8:	ba a0 00 00 00       	mov    $0xa0,%edx
f01036bd:	b8 68 00 00 00       	mov    $0x68,%eax
f01036c2:	ee                   	out    %al,(%dx)
f01036c3:	b8 0a 00 00 00       	mov    $0xa,%eax
f01036c8:	ee                   	out    %al,(%dx)
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
f01036c9:	0f b7 05 a8 03 12 f0 	movzwl 0xf01203a8,%eax
f01036d0:	66 83 f8 ff          	cmp    $0xffff,%ax
f01036d4:	74 13                	je     f01036e9 <pic_init+0x9e>
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
f01036d6:	55                   	push   %ebp
f01036d7:	89 e5                	mov    %esp,%ebp
f01036d9:	83 ec 14             	sub    $0x14,%esp

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
		irq_setmask_8259A(irq_mask_8259A);
f01036dc:	0f b7 c0             	movzwl %ax,%eax
f01036df:	50                   	push   %eax
f01036e0:	e8 ee fe ff ff       	call   f01035d3 <irq_setmask_8259A>
f01036e5:	83 c4 10             	add    $0x10,%esp
}
f01036e8:	c9                   	leave  
f01036e9:	f3 c3                	repz ret 

f01036eb <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01036eb:	55                   	push   %ebp
f01036ec:	89 e5                	mov    %esp,%ebp
f01036ee:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f01036f1:	ff 75 08             	pushl  0x8(%ebp)
f01036f4:	e8 5d d0 ff ff       	call   f0100756 <cputchar>
	*cnt++;
}
f01036f9:	83 c4 10             	add    $0x10,%esp
f01036fc:	c9                   	leave  
f01036fd:	c3                   	ret    

f01036fe <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01036fe:	55                   	push   %ebp
f01036ff:	89 e5                	mov    %esp,%ebp
f0103701:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0103704:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010370b:	ff 75 0c             	pushl  0xc(%ebp)
f010370e:	ff 75 08             	pushl  0x8(%ebp)
f0103711:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103714:	50                   	push   %eax
f0103715:	68 eb 36 10 f0       	push   $0xf01036eb
f010371a:	e8 e4 17 00 00       	call   f0104f03 <vprintfmt>
	return cnt;
}
f010371f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103722:	c9                   	leave  
f0103723:	c3                   	ret    

f0103724 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0103724:	55                   	push   %ebp
f0103725:	89 e5                	mov    %esp,%ebp
f0103727:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010372a:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f010372d:	50                   	push   %eax
f010372e:	ff 75 08             	pushl  0x8(%ebp)
f0103731:	e8 c8 ff ff ff       	call   f01036fe <vcprintf>
	va_end(ap);

	return cnt;
}
f0103736:	c9                   	leave  
f0103737:	c3                   	ret    

f0103738 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0103738:	55                   	push   %ebp
f0103739:	89 e5                	mov    %esp,%ebp
f010373b:	57                   	push   %edi
f010373c:	56                   	push   %esi
f010373d:	53                   	push   %ebx
f010373e:	83 ec 0c             	sub    $0xc,%esp
	// get a triple fault.  If you set up an individual CPU's TSS
	// wrong, you may not get a fault until you try to return from
	// user space on that CPU.
	//
	// LAB 4: Your code here:
	int cpuid = thiscpu->cpu_id;
f0103741:	e8 04 25 00 00       	call   f0105c4a <cpunum>
f0103746:	6b c0 74             	imul   $0x74,%eax,%eax
f0103749:	0f b6 98 20 00 23 f0 	movzbl -0xfdcffe0(%eax),%ebx
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	thiscpu->cpu_ts.ts_esp0 = KSTACKTOP - cpuid * (KSTKSIZE + KSTKGAP);
f0103750:	e8 f5 24 00 00       	call   f0105c4a <cpunum>
f0103755:	6b c0 74             	imul   $0x74,%eax,%eax
f0103758:	89 d9                	mov    %ebx,%ecx
f010375a:	c1 e1 10             	shl    $0x10,%ecx
f010375d:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0103762:	29 ca                	sub    %ecx,%edx
f0103764:	89 90 30 00 23 f0    	mov    %edx,-0xfdcffd0(%eax)
	thiscpu->cpu_ts.ts_ss0 = GD_KD;
f010376a:	e8 db 24 00 00       	call   f0105c4a <cpunum>
f010376f:	6b c0 74             	imul   $0x74,%eax,%eax
f0103772:	66 c7 80 34 00 23 f0 	movw   $0x10,-0xfdcffcc(%eax)
f0103779:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[(GD_TSS0 >> 3) + cpuid] = SEG16(STS_T32A, (uint32_t) (&thiscpu->cpu_ts),
f010377b:	83 c3 05             	add    $0x5,%ebx
f010377e:	e8 c7 24 00 00       	call   f0105c4a <cpunum>
f0103783:	89 c7                	mov    %eax,%edi
f0103785:	e8 c0 24 00 00       	call   f0105c4a <cpunum>
f010378a:	89 c6                	mov    %eax,%esi
f010378c:	e8 b9 24 00 00       	call   f0105c4a <cpunum>
f0103791:	66 c7 04 dd 40 03 12 	movw   $0x67,-0xfedfcc0(,%ebx,8)
f0103798:	f0 67 00 
f010379b:	6b ff 74             	imul   $0x74,%edi,%edi
f010379e:	81 c7 2c 00 23 f0    	add    $0xf023002c,%edi
f01037a4:	66 89 3c dd 42 03 12 	mov    %di,-0xfedfcbe(,%ebx,8)
f01037ab:	f0 
f01037ac:	6b d6 74             	imul   $0x74,%esi,%edx
f01037af:	81 c2 2c 00 23 f0    	add    $0xf023002c,%edx
f01037b5:	c1 ea 10             	shr    $0x10,%edx
f01037b8:	88 14 dd 44 03 12 f0 	mov    %dl,-0xfedfcbc(,%ebx,8)
f01037bf:	c6 04 dd 46 03 12 f0 	movb   $0x40,-0xfedfcba(,%ebx,8)
f01037c6:	40 
f01037c7:	6b c0 74             	imul   $0x74,%eax,%eax
f01037ca:	05 2c 00 23 f0       	add    $0xf023002c,%eax
f01037cf:	c1 e8 18             	shr    $0x18,%eax
f01037d2:	88 04 dd 47 03 12 f0 	mov    %al,-0xfedfcb9(,%ebx,8)
					sizeof(struct Taskstate) - 1, 0);
	gdt[(GD_TSS0 >> 3) + cpuid].sd_s = 0;
f01037d9:	c6 04 dd 45 03 12 f0 	movb   $0x89,-0xfedfcbb(,%ebx,8)
f01037e0:	89 
}

static __inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f01037e1:	c1 e3 03             	shl    $0x3,%ebx
f01037e4:	0f 00 db             	ltr    %bx
}

static __inline void
lidt(void *p)
{
	__asm __volatile("lidt (%0)" : : "r" (p));
f01037e7:	b8 ac 03 12 f0       	mov    $0xf01203ac,%eax
f01037ec:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0 + 8*cpuid);

	// Load the IDT
	lidt(&idt_pd);
}
f01037ef:	83 c4 0c             	add    $0xc,%esp
f01037f2:	5b                   	pop    %ebx
f01037f3:	5e                   	pop    %esi
f01037f4:	5f                   	pop    %edi
f01037f5:	5d                   	pop    %ebp
f01037f6:	c3                   	ret    

f01037f7 <trap_init>:
}


void
trap_init(void)
{
f01037f7:	55                   	push   %ebp
f01037f8:	89 e5                	mov    %esp,%ebp
f01037fa:	83 ec 08             	sub    $0x8,%esp
	 void IRQ_11();
	 void IRQ_12();
	 void IRQ_13();
	 void IRQ_14();
	 void IRQ_15();
    SETGATE(idt[T_DIVIDE], 0, GD_KT, t_divide, 0);
f01037fd:	b8 1c 43 10 f0       	mov    $0xf010431c,%eax
f0103802:	66 a3 60 f2 22 f0    	mov    %ax,0xf022f260
f0103808:	66 c7 05 62 f2 22 f0 	movw   $0x8,0xf022f262
f010380f:	08 00 
f0103811:	c6 05 64 f2 22 f0 00 	movb   $0x0,0xf022f264
f0103818:	c6 05 65 f2 22 f0 8e 	movb   $0x8e,0xf022f265
f010381f:	c1 e8 10             	shr    $0x10,%eax
f0103822:	66 a3 66 f2 22 f0    	mov    %ax,0xf022f266
    SETGATE(idt[T_DEBUG], 0, GD_KT, t_debug, 0);
f0103828:	b8 26 43 10 f0       	mov    $0xf0104326,%eax
f010382d:	66 a3 68 f2 22 f0    	mov    %ax,0xf022f268
f0103833:	66 c7 05 6a f2 22 f0 	movw   $0x8,0xf022f26a
f010383a:	08 00 
f010383c:	c6 05 6c f2 22 f0 00 	movb   $0x0,0xf022f26c
f0103843:	c6 05 6d f2 22 f0 8e 	movb   $0x8e,0xf022f26d
f010384a:	c1 e8 10             	shr    $0x10,%eax
f010384d:	66 a3 6e f2 22 f0    	mov    %ax,0xf022f26e
    SETGATE(idt[T_NMI], 0, GD_KT, t_nmi, 0);
f0103853:	b8 30 43 10 f0       	mov    $0xf0104330,%eax
f0103858:	66 a3 70 f2 22 f0    	mov    %ax,0xf022f270
f010385e:	66 c7 05 72 f2 22 f0 	movw   $0x8,0xf022f272
f0103865:	08 00 
f0103867:	c6 05 74 f2 22 f0 00 	movb   $0x0,0xf022f274
f010386e:	c6 05 75 f2 22 f0 8e 	movb   $0x8e,0xf022f275
f0103875:	c1 e8 10             	shr    $0x10,%eax
f0103878:	66 a3 76 f2 22 f0    	mov    %ax,0xf022f276
    SETGATE(idt[T_BRKPT], 1, GD_KT, t_brkpt, 3);
f010387e:	b8 3a 43 10 f0       	mov    $0xf010433a,%eax
f0103883:	66 a3 78 f2 22 f0    	mov    %ax,0xf022f278
f0103889:	66 c7 05 7a f2 22 f0 	movw   $0x8,0xf022f27a
f0103890:	08 00 
f0103892:	c6 05 7c f2 22 f0 00 	movb   $0x0,0xf022f27c
f0103899:	c6 05 7d f2 22 f0 ef 	movb   $0xef,0xf022f27d
f01038a0:	c1 e8 10             	shr    $0x10,%eax
f01038a3:	66 a3 7e f2 22 f0    	mov    %ax,0xf022f27e
    SETGATE(idt[T_OFLOW], 0, GD_KT, t_oflow, 0);
f01038a9:	b8 44 43 10 f0       	mov    $0xf0104344,%eax
f01038ae:	66 a3 80 f2 22 f0    	mov    %ax,0xf022f280
f01038b4:	66 c7 05 82 f2 22 f0 	movw   $0x8,0xf022f282
f01038bb:	08 00 
f01038bd:	c6 05 84 f2 22 f0 00 	movb   $0x0,0xf022f284
f01038c4:	c6 05 85 f2 22 f0 8e 	movb   $0x8e,0xf022f285
f01038cb:	c1 e8 10             	shr    $0x10,%eax
f01038ce:	66 a3 86 f2 22 f0    	mov    %ax,0xf022f286
    SETGATE(idt[T_BOUND], 0, GD_KT, t_bound, 0);
f01038d4:	b8 4e 43 10 f0       	mov    $0xf010434e,%eax
f01038d9:	66 a3 88 f2 22 f0    	mov    %ax,0xf022f288
f01038df:	66 c7 05 8a f2 22 f0 	movw   $0x8,0xf022f28a
f01038e6:	08 00 
f01038e8:	c6 05 8c f2 22 f0 00 	movb   $0x0,0xf022f28c
f01038ef:	c6 05 8d f2 22 f0 8e 	movb   $0x8e,0xf022f28d
f01038f6:	c1 e8 10             	shr    $0x10,%eax
f01038f9:	66 a3 8e f2 22 f0    	mov    %ax,0xf022f28e
    SETGATE(idt[T_ILLOP], 0, GD_KT, t_illop, 0);
f01038ff:	b8 58 43 10 f0       	mov    $0xf0104358,%eax
f0103904:	66 a3 90 f2 22 f0    	mov    %ax,0xf022f290
f010390a:	66 c7 05 92 f2 22 f0 	movw   $0x8,0xf022f292
f0103911:	08 00 
f0103913:	c6 05 94 f2 22 f0 00 	movb   $0x0,0xf022f294
f010391a:	c6 05 95 f2 22 f0 8e 	movb   $0x8e,0xf022f295
f0103921:	c1 e8 10             	shr    $0x10,%eax
f0103924:	66 a3 96 f2 22 f0    	mov    %ax,0xf022f296
    SETGATE(idt[T_DEVICE], 0, GD_KT, t_device, 0);
f010392a:	b8 62 43 10 f0       	mov    $0xf0104362,%eax
f010392f:	66 a3 98 f2 22 f0    	mov    %ax,0xf022f298
f0103935:	66 c7 05 9a f2 22 f0 	movw   $0x8,0xf022f29a
f010393c:	08 00 
f010393e:	c6 05 9c f2 22 f0 00 	movb   $0x0,0xf022f29c
f0103945:	c6 05 9d f2 22 f0 8e 	movb   $0x8e,0xf022f29d
f010394c:	c1 e8 10             	shr    $0x10,%eax
f010394f:	66 a3 9e f2 22 f0    	mov    %ax,0xf022f29e
    SETGATE(idt[T_DBLFLT], 0, GD_KT, t_dblflt, 0);
f0103955:	b8 6c 43 10 f0       	mov    $0xf010436c,%eax
f010395a:	66 a3 a0 f2 22 f0    	mov    %ax,0xf022f2a0
f0103960:	66 c7 05 a2 f2 22 f0 	movw   $0x8,0xf022f2a2
f0103967:	08 00 
f0103969:	c6 05 a4 f2 22 f0 00 	movb   $0x0,0xf022f2a4
f0103970:	c6 05 a5 f2 22 f0 8e 	movb   $0x8e,0xf022f2a5
f0103977:	c1 e8 10             	shr    $0x10,%eax
f010397a:	66 a3 a6 f2 22 f0    	mov    %ax,0xf022f2a6
    SETGATE(idt[T_TSS], 0, GD_KT, t_tss, 0);
f0103980:	b8 74 43 10 f0       	mov    $0xf0104374,%eax
f0103985:	66 a3 b0 f2 22 f0    	mov    %ax,0xf022f2b0
f010398b:	66 c7 05 b2 f2 22 f0 	movw   $0x8,0xf022f2b2
f0103992:	08 00 
f0103994:	c6 05 b4 f2 22 f0 00 	movb   $0x0,0xf022f2b4
f010399b:	c6 05 b5 f2 22 f0 8e 	movb   $0x8e,0xf022f2b5
f01039a2:	c1 e8 10             	shr    $0x10,%eax
f01039a5:	66 a3 b6 f2 22 f0    	mov    %ax,0xf022f2b6
    SETGATE(idt[T_SEGNP], 0, GD_KT, t_segnp, 0);
f01039ab:	b8 7c 43 10 f0       	mov    $0xf010437c,%eax
f01039b0:	66 a3 b8 f2 22 f0    	mov    %ax,0xf022f2b8
f01039b6:	66 c7 05 ba f2 22 f0 	movw   $0x8,0xf022f2ba
f01039bd:	08 00 
f01039bf:	c6 05 bc f2 22 f0 00 	movb   $0x0,0xf022f2bc
f01039c6:	c6 05 bd f2 22 f0 8e 	movb   $0x8e,0xf022f2bd
f01039cd:	c1 e8 10             	shr    $0x10,%eax
f01039d0:	66 a3 be f2 22 f0    	mov    %ax,0xf022f2be
    SETGATE(idt[T_STACK], 0, GD_KT, t_stack, 0);
f01039d6:	b8 84 43 10 f0       	mov    $0xf0104384,%eax
f01039db:	66 a3 c0 f2 22 f0    	mov    %ax,0xf022f2c0
f01039e1:	66 c7 05 c2 f2 22 f0 	movw   $0x8,0xf022f2c2
f01039e8:	08 00 
f01039ea:	c6 05 c4 f2 22 f0 00 	movb   $0x0,0xf022f2c4
f01039f1:	c6 05 c5 f2 22 f0 8e 	movb   $0x8e,0xf022f2c5
f01039f8:	c1 e8 10             	shr    $0x10,%eax
f01039fb:	66 a3 c6 f2 22 f0    	mov    %ax,0xf022f2c6
    SETGATE(idt[T_GPFLT], 0, GD_KT, t_gpflt, 0);
f0103a01:	b8 8c 43 10 f0       	mov    $0xf010438c,%eax
f0103a06:	66 a3 c8 f2 22 f0    	mov    %ax,0xf022f2c8
f0103a0c:	66 c7 05 ca f2 22 f0 	movw   $0x8,0xf022f2ca
f0103a13:	08 00 
f0103a15:	c6 05 cc f2 22 f0 00 	movb   $0x0,0xf022f2cc
f0103a1c:	c6 05 cd f2 22 f0 8e 	movb   $0x8e,0xf022f2cd
f0103a23:	c1 e8 10             	shr    $0x10,%eax
f0103a26:	66 a3 ce f2 22 f0    	mov    %ax,0xf022f2ce
    SETGATE(idt[T_PGFLT], 0, GD_KT, t_pgflt, 0);
f0103a2c:	b8 94 43 10 f0       	mov    $0xf0104394,%eax
f0103a31:	66 a3 d0 f2 22 f0    	mov    %ax,0xf022f2d0
f0103a37:	66 c7 05 d2 f2 22 f0 	movw   $0x8,0xf022f2d2
f0103a3e:	08 00 
f0103a40:	c6 05 d4 f2 22 f0 00 	movb   $0x0,0xf022f2d4
f0103a47:	c6 05 d5 f2 22 f0 8e 	movb   $0x8e,0xf022f2d5
f0103a4e:	c1 e8 10             	shr    $0x10,%eax
f0103a51:	66 a3 d6 f2 22 f0    	mov    %ax,0xf022f2d6
    SETGATE(idt[T_FPERR], 0, GD_KT, t_fperr, 0);
f0103a57:	b8 98 43 10 f0       	mov    $0xf0104398,%eax
f0103a5c:	66 a3 e0 f2 22 f0    	mov    %ax,0xf022f2e0
f0103a62:	66 c7 05 e2 f2 22 f0 	movw   $0x8,0xf022f2e2
f0103a69:	08 00 
f0103a6b:	c6 05 e4 f2 22 f0 00 	movb   $0x0,0xf022f2e4
f0103a72:	c6 05 e5 f2 22 f0 8e 	movb   $0x8e,0xf022f2e5
f0103a79:	c1 e8 10             	shr    $0x10,%eax
f0103a7c:	66 a3 e6 f2 22 f0    	mov    %ax,0xf022f2e6
    SETGATE(idt[T_ALIGN], 0, GD_KT, t_align, 0);
f0103a82:	b8 9e 43 10 f0       	mov    $0xf010439e,%eax
f0103a87:	66 a3 e8 f2 22 f0    	mov    %ax,0xf022f2e8
f0103a8d:	66 c7 05 ea f2 22 f0 	movw   $0x8,0xf022f2ea
f0103a94:	08 00 
f0103a96:	c6 05 ec f2 22 f0 00 	movb   $0x0,0xf022f2ec
f0103a9d:	c6 05 ed f2 22 f0 8e 	movb   $0x8e,0xf022f2ed
f0103aa4:	c1 e8 10             	shr    $0x10,%eax
f0103aa7:	66 a3 ee f2 22 f0    	mov    %ax,0xf022f2ee
    SETGATE(idt[T_MCHK], 0, GD_KT, t_mchk, 0);
f0103aad:	b8 a2 43 10 f0       	mov    $0xf01043a2,%eax
f0103ab2:	66 a3 f0 f2 22 f0    	mov    %ax,0xf022f2f0
f0103ab8:	66 c7 05 f2 f2 22 f0 	movw   $0x8,0xf022f2f2
f0103abf:	08 00 
f0103ac1:	c6 05 f4 f2 22 f0 00 	movb   $0x0,0xf022f2f4
f0103ac8:	c6 05 f5 f2 22 f0 8e 	movb   $0x8e,0xf022f2f5
f0103acf:	c1 e8 10             	shr    $0x10,%eax
f0103ad2:	66 a3 f6 f2 22 f0    	mov    %ax,0xf022f2f6
    SETGATE(idt[T_SIMDERR], 0, GD_KT, t_simderr, 0);
f0103ad8:	b8 a8 43 10 f0       	mov    $0xf01043a8,%eax
f0103add:	66 a3 f8 f2 22 f0    	mov    %ax,0xf022f2f8
f0103ae3:	66 c7 05 fa f2 22 f0 	movw   $0x8,0xf022f2fa
f0103aea:	08 00 
f0103aec:	c6 05 fc f2 22 f0 00 	movb   $0x0,0xf022f2fc
f0103af3:	c6 05 fd f2 22 f0 8e 	movb   $0x8e,0xf022f2fd
f0103afa:	c1 e8 10             	shr    $0x10,%eax
f0103afd:	66 a3 fe f2 22 f0    	mov    %ax,0xf022f2fe
    SETGATE(idt[T_SYSCALL], 0, GD_KT, t_syscall, 3);
f0103b03:	b8 ae 43 10 f0       	mov    $0xf01043ae,%eax
f0103b08:	66 a3 e0 f3 22 f0    	mov    %ax,0xf022f3e0
f0103b0e:	66 c7 05 e2 f3 22 f0 	movw   $0x8,0xf022f3e2
f0103b15:	08 00 
f0103b17:	c6 05 e4 f3 22 f0 00 	movb   $0x0,0xf022f3e4
f0103b1e:	c6 05 e5 f3 22 f0 ee 	movb   $0xee,0xf022f3e5
f0103b25:	c1 e8 10             	shr    $0x10,%eax
f0103b28:	66 a3 e6 f3 22 f0    	mov    %ax,0xf022f3e6
	SETGATE(idt[IRQ_OFFSET + 0], 0, GD_KT, IRQ_0, 0);
f0103b2e:	b8 b4 43 10 f0       	mov    $0xf01043b4,%eax
f0103b33:	66 a3 60 f3 22 f0    	mov    %ax,0xf022f360
f0103b39:	66 c7 05 62 f3 22 f0 	movw   $0x8,0xf022f362
f0103b40:	08 00 
f0103b42:	c6 05 64 f3 22 f0 00 	movb   $0x0,0xf022f364
f0103b49:	c6 05 65 f3 22 f0 8e 	movb   $0x8e,0xf022f365
f0103b50:	c1 e8 10             	shr    $0x10,%eax
f0103b53:	66 a3 66 f3 22 f0    	mov    %ax,0xf022f366
	SETGATE(idt[IRQ_OFFSET + 1], 0, GD_KT, IRQ_1, 0);
f0103b59:	b8 ba 43 10 f0       	mov    $0xf01043ba,%eax
f0103b5e:	66 a3 68 f3 22 f0    	mov    %ax,0xf022f368
f0103b64:	66 c7 05 6a f3 22 f0 	movw   $0x8,0xf022f36a
f0103b6b:	08 00 
f0103b6d:	c6 05 6c f3 22 f0 00 	movb   $0x0,0xf022f36c
f0103b74:	c6 05 6d f3 22 f0 8e 	movb   $0x8e,0xf022f36d
f0103b7b:	c1 e8 10             	shr    $0x10,%eax
f0103b7e:	66 a3 6e f3 22 f0    	mov    %ax,0xf022f36e
	SETGATE(idt[IRQ_OFFSET + 2], 0, GD_KT, IRQ_2, 0);
f0103b84:	b8 c0 43 10 f0       	mov    $0xf01043c0,%eax
f0103b89:	66 a3 70 f3 22 f0    	mov    %ax,0xf022f370
f0103b8f:	66 c7 05 72 f3 22 f0 	movw   $0x8,0xf022f372
f0103b96:	08 00 
f0103b98:	c6 05 74 f3 22 f0 00 	movb   $0x0,0xf022f374
f0103b9f:	c6 05 75 f3 22 f0 8e 	movb   $0x8e,0xf022f375
f0103ba6:	c1 e8 10             	shr    $0x10,%eax
f0103ba9:	66 a3 76 f3 22 f0    	mov    %ax,0xf022f376
	SETGATE(idt[IRQ_OFFSET + 3], 0, GD_KT, IRQ_3, 0);
f0103baf:	b8 c6 43 10 f0       	mov    $0xf01043c6,%eax
f0103bb4:	66 a3 78 f3 22 f0    	mov    %ax,0xf022f378
f0103bba:	66 c7 05 7a f3 22 f0 	movw   $0x8,0xf022f37a
f0103bc1:	08 00 
f0103bc3:	c6 05 7c f3 22 f0 00 	movb   $0x0,0xf022f37c
f0103bca:	c6 05 7d f3 22 f0 8e 	movb   $0x8e,0xf022f37d
f0103bd1:	c1 e8 10             	shr    $0x10,%eax
f0103bd4:	66 a3 7e f3 22 f0    	mov    %ax,0xf022f37e
	SETGATE(idt[IRQ_OFFSET + 4], 0, GD_KT, IRQ_4, 0);
f0103bda:	b8 cc 43 10 f0       	mov    $0xf01043cc,%eax
f0103bdf:	66 a3 80 f3 22 f0    	mov    %ax,0xf022f380
f0103be5:	66 c7 05 82 f3 22 f0 	movw   $0x8,0xf022f382
f0103bec:	08 00 
f0103bee:	c6 05 84 f3 22 f0 00 	movb   $0x0,0xf022f384
f0103bf5:	c6 05 85 f3 22 f0 8e 	movb   $0x8e,0xf022f385
f0103bfc:	c1 e8 10             	shr    $0x10,%eax
f0103bff:	66 a3 86 f3 22 f0    	mov    %ax,0xf022f386
	SETGATE(idt[IRQ_OFFSET + 5], 0, GD_KT, IRQ_5, 0);
f0103c05:	b8 d2 43 10 f0       	mov    $0xf01043d2,%eax
f0103c0a:	66 a3 88 f3 22 f0    	mov    %ax,0xf022f388
f0103c10:	66 c7 05 8a f3 22 f0 	movw   $0x8,0xf022f38a
f0103c17:	08 00 
f0103c19:	c6 05 8c f3 22 f0 00 	movb   $0x0,0xf022f38c
f0103c20:	c6 05 8d f3 22 f0 8e 	movb   $0x8e,0xf022f38d
f0103c27:	c1 e8 10             	shr    $0x10,%eax
f0103c2a:	66 a3 8e f3 22 f0    	mov    %ax,0xf022f38e
	SETGATE(idt[IRQ_OFFSET + 6], 0, GD_KT, IRQ_6, 0);
f0103c30:	b8 d8 43 10 f0       	mov    $0xf01043d8,%eax
f0103c35:	66 a3 90 f3 22 f0    	mov    %ax,0xf022f390
f0103c3b:	66 c7 05 92 f3 22 f0 	movw   $0x8,0xf022f392
f0103c42:	08 00 
f0103c44:	c6 05 94 f3 22 f0 00 	movb   $0x0,0xf022f394
f0103c4b:	c6 05 95 f3 22 f0 8e 	movb   $0x8e,0xf022f395
f0103c52:	c1 e8 10             	shr    $0x10,%eax
f0103c55:	66 a3 96 f3 22 f0    	mov    %ax,0xf022f396
	SETGATE(idt[IRQ_OFFSET + 7], 0, GD_KT, IRQ_7, 0);
f0103c5b:	b8 de 43 10 f0       	mov    $0xf01043de,%eax
f0103c60:	66 a3 98 f3 22 f0    	mov    %ax,0xf022f398
f0103c66:	66 c7 05 9a f3 22 f0 	movw   $0x8,0xf022f39a
f0103c6d:	08 00 
f0103c6f:	c6 05 9c f3 22 f0 00 	movb   $0x0,0xf022f39c
f0103c76:	c6 05 9d f3 22 f0 8e 	movb   $0x8e,0xf022f39d
f0103c7d:	c1 e8 10             	shr    $0x10,%eax
f0103c80:	66 a3 9e f3 22 f0    	mov    %ax,0xf022f39e
	SETGATE(idt[IRQ_OFFSET + 8], 0, GD_KT, IRQ_8, 0);
f0103c86:	b8 e4 43 10 f0       	mov    $0xf01043e4,%eax
f0103c8b:	66 a3 a0 f3 22 f0    	mov    %ax,0xf022f3a0
f0103c91:	66 c7 05 a2 f3 22 f0 	movw   $0x8,0xf022f3a2
f0103c98:	08 00 
f0103c9a:	c6 05 a4 f3 22 f0 00 	movb   $0x0,0xf022f3a4
f0103ca1:	c6 05 a5 f3 22 f0 8e 	movb   $0x8e,0xf022f3a5
f0103ca8:	c1 e8 10             	shr    $0x10,%eax
f0103cab:	66 a3 a6 f3 22 f0    	mov    %ax,0xf022f3a6
	SETGATE(idt[IRQ_OFFSET + 9], 0, GD_KT, IRQ_9, 0);
f0103cb1:	b8 ea 43 10 f0       	mov    $0xf01043ea,%eax
f0103cb6:	66 a3 a8 f3 22 f0    	mov    %ax,0xf022f3a8
f0103cbc:	66 c7 05 aa f3 22 f0 	movw   $0x8,0xf022f3aa
f0103cc3:	08 00 
f0103cc5:	c6 05 ac f3 22 f0 00 	movb   $0x0,0xf022f3ac
f0103ccc:	c6 05 ad f3 22 f0 8e 	movb   $0x8e,0xf022f3ad
f0103cd3:	c1 e8 10             	shr    $0x10,%eax
f0103cd6:	66 a3 ae f3 22 f0    	mov    %ax,0xf022f3ae
	SETGATE(idt[IRQ_OFFSET + 10], 0, GD_KT, IRQ_10, 0);
f0103cdc:	b8 f0 43 10 f0       	mov    $0xf01043f0,%eax
f0103ce1:	66 a3 b0 f3 22 f0    	mov    %ax,0xf022f3b0
f0103ce7:	66 c7 05 b2 f3 22 f0 	movw   $0x8,0xf022f3b2
f0103cee:	08 00 
f0103cf0:	c6 05 b4 f3 22 f0 00 	movb   $0x0,0xf022f3b4
f0103cf7:	c6 05 b5 f3 22 f0 8e 	movb   $0x8e,0xf022f3b5
f0103cfe:	c1 e8 10             	shr    $0x10,%eax
f0103d01:	66 a3 b6 f3 22 f0    	mov    %ax,0xf022f3b6
	SETGATE(idt[IRQ_OFFSET + 11], 0, GD_KT, IRQ_11, 0);
f0103d07:	b8 f6 43 10 f0       	mov    $0xf01043f6,%eax
f0103d0c:	66 a3 b8 f3 22 f0    	mov    %ax,0xf022f3b8
f0103d12:	66 c7 05 ba f3 22 f0 	movw   $0x8,0xf022f3ba
f0103d19:	08 00 
f0103d1b:	c6 05 bc f3 22 f0 00 	movb   $0x0,0xf022f3bc
f0103d22:	c6 05 bd f3 22 f0 8e 	movb   $0x8e,0xf022f3bd
f0103d29:	c1 e8 10             	shr    $0x10,%eax
f0103d2c:	66 a3 be f3 22 f0    	mov    %ax,0xf022f3be
	SETGATE(idt[IRQ_OFFSET + 12], 0, GD_KT, IRQ_12, 0);
f0103d32:	b8 fc 43 10 f0       	mov    $0xf01043fc,%eax
f0103d37:	66 a3 c0 f3 22 f0    	mov    %ax,0xf022f3c0
f0103d3d:	66 c7 05 c2 f3 22 f0 	movw   $0x8,0xf022f3c2
f0103d44:	08 00 
f0103d46:	c6 05 c4 f3 22 f0 00 	movb   $0x0,0xf022f3c4
f0103d4d:	c6 05 c5 f3 22 f0 8e 	movb   $0x8e,0xf022f3c5
f0103d54:	c1 e8 10             	shr    $0x10,%eax
f0103d57:	66 a3 c6 f3 22 f0    	mov    %ax,0xf022f3c6
	SETGATE(idt[IRQ_OFFSET + 13], 0, GD_KT, IRQ_13, 0);
f0103d5d:	b8 02 44 10 f0       	mov    $0xf0104402,%eax
f0103d62:	66 a3 c8 f3 22 f0    	mov    %ax,0xf022f3c8
f0103d68:	66 c7 05 ca f3 22 f0 	movw   $0x8,0xf022f3ca
f0103d6f:	08 00 
f0103d71:	c6 05 cc f3 22 f0 00 	movb   $0x0,0xf022f3cc
f0103d78:	c6 05 cd f3 22 f0 8e 	movb   $0x8e,0xf022f3cd
f0103d7f:	c1 e8 10             	shr    $0x10,%eax
f0103d82:	66 a3 ce f3 22 f0    	mov    %ax,0xf022f3ce
	SETGATE(idt[IRQ_OFFSET + 14], 0, GD_KT, IRQ_14, 0);
f0103d88:	b8 08 44 10 f0       	mov    $0xf0104408,%eax
f0103d8d:	66 a3 d0 f3 22 f0    	mov    %ax,0xf022f3d0
f0103d93:	66 c7 05 d2 f3 22 f0 	movw   $0x8,0xf022f3d2
f0103d9a:	08 00 
f0103d9c:	c6 05 d4 f3 22 f0 00 	movb   $0x0,0xf022f3d4
f0103da3:	c6 05 d5 f3 22 f0 8e 	movb   $0x8e,0xf022f3d5
f0103daa:	c1 e8 10             	shr    $0x10,%eax
f0103dad:	66 a3 d6 f3 22 f0    	mov    %ax,0xf022f3d6
	SETGATE(idt[IRQ_OFFSET + 15], 0, GD_KT, IRQ_15, 0);
f0103db3:	b8 0e 44 10 f0       	mov    $0xf010440e,%eax
f0103db8:	66 a3 d8 f3 22 f0    	mov    %ax,0xf022f3d8
f0103dbe:	66 c7 05 da f3 22 f0 	movw   $0x8,0xf022f3da
f0103dc5:	08 00 
f0103dc7:	c6 05 dc f3 22 f0 00 	movb   $0x0,0xf022f3dc
f0103dce:	c6 05 dd f3 22 f0 8e 	movb   $0x8e,0xf022f3dd
f0103dd5:	c1 e8 10             	shr    $0x10,%eax
f0103dd8:	66 a3 de f3 22 f0    	mov    %ax,0xf022f3de
	// Per-CPU setup 
	trap_init_percpu();
f0103dde:	e8 55 f9 ff ff       	call   f0103738 <trap_init_percpu>
}
f0103de3:	c9                   	leave  
f0103de4:	c3                   	ret    

f0103de5 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0103de5:	55                   	push   %ebp
f0103de6:	89 e5                	mov    %esp,%ebp
f0103de8:	53                   	push   %ebx
f0103de9:	83 ec 0c             	sub    $0xc,%esp
f0103dec:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0103def:	ff 33                	pushl  (%ebx)
f0103df1:	68 79 75 10 f0       	push   $0xf0107579
f0103df6:	e8 29 f9 ff ff       	call   f0103724 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0103dfb:	83 c4 08             	add    $0x8,%esp
f0103dfe:	ff 73 04             	pushl  0x4(%ebx)
f0103e01:	68 88 75 10 f0       	push   $0xf0107588
f0103e06:	e8 19 f9 ff ff       	call   f0103724 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103e0b:	83 c4 08             	add    $0x8,%esp
f0103e0e:	ff 73 08             	pushl  0x8(%ebx)
f0103e11:	68 97 75 10 f0       	push   $0xf0107597
f0103e16:	e8 09 f9 ff ff       	call   f0103724 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103e1b:	83 c4 08             	add    $0x8,%esp
f0103e1e:	ff 73 0c             	pushl  0xc(%ebx)
f0103e21:	68 a6 75 10 f0       	push   $0xf01075a6
f0103e26:	e8 f9 f8 ff ff       	call   f0103724 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103e2b:	83 c4 08             	add    $0x8,%esp
f0103e2e:	ff 73 10             	pushl  0x10(%ebx)
f0103e31:	68 b5 75 10 f0       	push   $0xf01075b5
f0103e36:	e8 e9 f8 ff ff       	call   f0103724 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103e3b:	83 c4 08             	add    $0x8,%esp
f0103e3e:	ff 73 14             	pushl  0x14(%ebx)
f0103e41:	68 c4 75 10 f0       	push   $0xf01075c4
f0103e46:	e8 d9 f8 ff ff       	call   f0103724 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103e4b:	83 c4 08             	add    $0x8,%esp
f0103e4e:	ff 73 18             	pushl  0x18(%ebx)
f0103e51:	68 d3 75 10 f0       	push   $0xf01075d3
f0103e56:	e8 c9 f8 ff ff       	call   f0103724 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103e5b:	83 c4 08             	add    $0x8,%esp
f0103e5e:	ff 73 1c             	pushl  0x1c(%ebx)
f0103e61:	68 e2 75 10 f0       	push   $0xf01075e2
f0103e66:	e8 b9 f8 ff ff       	call   f0103724 <cprintf>
}
f0103e6b:	83 c4 10             	add    $0x10,%esp
f0103e6e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103e71:	c9                   	leave  
f0103e72:	c3                   	ret    

f0103e73 <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0103e73:	55                   	push   %ebp
f0103e74:	89 e5                	mov    %esp,%ebp
f0103e76:	56                   	push   %esi
f0103e77:	53                   	push   %ebx
f0103e78:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
f0103e7b:	e8 ca 1d 00 00       	call   f0105c4a <cpunum>
f0103e80:	83 ec 04             	sub    $0x4,%esp
f0103e83:	50                   	push   %eax
f0103e84:	53                   	push   %ebx
f0103e85:	68 46 76 10 f0       	push   $0xf0107646
f0103e8a:	e8 95 f8 ff ff       	call   f0103724 <cprintf>
	print_regs(&tf->tf_regs);
f0103e8f:	89 1c 24             	mov    %ebx,(%esp)
f0103e92:	e8 4e ff ff ff       	call   f0103de5 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103e97:	83 c4 08             	add    $0x8,%esp
f0103e9a:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103e9e:	50                   	push   %eax
f0103e9f:	68 64 76 10 f0       	push   $0xf0107664
f0103ea4:	e8 7b f8 ff ff       	call   f0103724 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103ea9:	83 c4 08             	add    $0x8,%esp
f0103eac:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103eb0:	50                   	push   %eax
f0103eb1:	68 77 76 10 f0       	push   $0xf0107677
f0103eb6:	e8 69 f8 ff ff       	call   f0103724 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103ebb:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f0103ebe:	83 c4 10             	add    $0x10,%esp
f0103ec1:	83 f8 13             	cmp    $0x13,%eax
f0103ec4:	77 09                	ja     f0103ecf <print_trapframe+0x5c>
		return excnames[trapno];
f0103ec6:	8b 14 85 20 79 10 f0 	mov    -0xfef86e0(,%eax,4),%edx
f0103ecd:	eb 1f                	jmp    f0103eee <print_trapframe+0x7b>
	if (trapno == T_SYSCALL)
f0103ecf:	83 f8 30             	cmp    $0x30,%eax
f0103ed2:	74 15                	je     f0103ee9 <print_trapframe+0x76>
		return "System call";
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
f0103ed4:	8d 50 e0             	lea    -0x20(%eax),%edx
		return "Hardware Interrupt";
	return "(unknown trap)";
f0103ed7:	83 fa 10             	cmp    $0x10,%edx
f0103eda:	b9 10 76 10 f0       	mov    $0xf0107610,%ecx
f0103edf:	ba fd 75 10 f0       	mov    $0xf01075fd,%edx
f0103ee4:	0f 43 d1             	cmovae %ecx,%edx
f0103ee7:	eb 05                	jmp    f0103eee <print_trapframe+0x7b>
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
		return excnames[trapno];
	if (trapno == T_SYSCALL)
		return "System call";
f0103ee9:	ba f1 75 10 f0       	mov    $0xf01075f1,%edx
{
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103eee:	83 ec 04             	sub    $0x4,%esp
f0103ef1:	52                   	push   %edx
f0103ef2:	50                   	push   %eax
f0103ef3:	68 8a 76 10 f0       	push   $0xf010768a
f0103ef8:	e8 27 f8 ff ff       	call   f0103724 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103efd:	83 c4 10             	add    $0x10,%esp
f0103f00:	3b 1d 60 fa 22 f0    	cmp    0xf022fa60,%ebx
f0103f06:	75 1a                	jne    f0103f22 <print_trapframe+0xaf>
f0103f08:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103f0c:	75 14                	jne    f0103f22 <print_trapframe+0xaf>

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0103f0e:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103f11:	83 ec 08             	sub    $0x8,%esp
f0103f14:	50                   	push   %eax
f0103f15:	68 9c 76 10 f0       	push   $0xf010769c
f0103f1a:	e8 05 f8 ff ff       	call   f0103724 <cprintf>
f0103f1f:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f0103f22:	83 ec 08             	sub    $0x8,%esp
f0103f25:	ff 73 2c             	pushl  0x2c(%ebx)
f0103f28:	68 ab 76 10 f0       	push   $0xf01076ab
f0103f2d:	e8 f2 f7 ff ff       	call   f0103724 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103f32:	83 c4 10             	add    $0x10,%esp
f0103f35:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103f39:	75 49                	jne    f0103f84 <print_trapframe+0x111>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0103f3b:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103f3e:	89 c2                	mov    %eax,%edx
f0103f40:	83 e2 01             	and    $0x1,%edx
f0103f43:	ba 2a 76 10 f0       	mov    $0xf010762a,%edx
f0103f48:	b9 1f 76 10 f0       	mov    $0xf010761f,%ecx
f0103f4d:	0f 44 ca             	cmove  %edx,%ecx
f0103f50:	89 c2                	mov    %eax,%edx
f0103f52:	83 e2 02             	and    $0x2,%edx
f0103f55:	ba 3c 76 10 f0       	mov    $0xf010763c,%edx
f0103f5a:	be 36 76 10 f0       	mov    $0xf0107636,%esi
f0103f5f:	0f 45 d6             	cmovne %esi,%edx
f0103f62:	83 e0 04             	and    $0x4,%eax
f0103f65:	be 32 77 10 f0       	mov    $0xf0107732,%esi
f0103f6a:	b8 41 76 10 f0       	mov    $0xf0107641,%eax
f0103f6f:	0f 44 c6             	cmove  %esi,%eax
f0103f72:	51                   	push   %ecx
f0103f73:	52                   	push   %edx
f0103f74:	50                   	push   %eax
f0103f75:	68 b9 76 10 f0       	push   $0xf01076b9
f0103f7a:	e8 a5 f7 ff ff       	call   f0103724 <cprintf>
f0103f7f:	83 c4 10             	add    $0x10,%esp
f0103f82:	eb 10                	jmp    f0103f94 <print_trapframe+0x121>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103f84:	83 ec 0c             	sub    $0xc,%esp
f0103f87:	68 94 6b 10 f0       	push   $0xf0106b94
f0103f8c:	e8 93 f7 ff ff       	call   f0103724 <cprintf>
f0103f91:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103f94:	83 ec 08             	sub    $0x8,%esp
f0103f97:	ff 73 30             	pushl  0x30(%ebx)
f0103f9a:	68 c8 76 10 f0       	push   $0xf01076c8
f0103f9f:	e8 80 f7 ff ff       	call   f0103724 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103fa4:	83 c4 08             	add    $0x8,%esp
f0103fa7:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103fab:	50                   	push   %eax
f0103fac:	68 d7 76 10 f0       	push   $0xf01076d7
f0103fb1:	e8 6e f7 ff ff       	call   f0103724 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103fb6:	83 c4 08             	add    $0x8,%esp
f0103fb9:	ff 73 38             	pushl  0x38(%ebx)
f0103fbc:	68 ea 76 10 f0       	push   $0xf01076ea
f0103fc1:	e8 5e f7 ff ff       	call   f0103724 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103fc6:	83 c4 10             	add    $0x10,%esp
f0103fc9:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103fcd:	74 25                	je     f0103ff4 <print_trapframe+0x181>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103fcf:	83 ec 08             	sub    $0x8,%esp
f0103fd2:	ff 73 3c             	pushl  0x3c(%ebx)
f0103fd5:	68 f9 76 10 f0       	push   $0xf01076f9
f0103fda:	e8 45 f7 ff ff       	call   f0103724 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103fdf:	83 c4 08             	add    $0x8,%esp
f0103fe2:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103fe6:	50                   	push   %eax
f0103fe7:	68 08 77 10 f0       	push   $0xf0107708
f0103fec:	e8 33 f7 ff ff       	call   f0103724 <cprintf>
f0103ff1:	83 c4 10             	add    $0x10,%esp
	}
}
f0103ff4:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103ff7:	5b                   	pop    %ebx
f0103ff8:	5e                   	pop    %esi
f0103ff9:	5d                   	pop    %ebp
f0103ffa:	c3                   	ret    

f0103ffb <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103ffb:	55                   	push   %ebp
f0103ffc:	89 e5                	mov    %esp,%ebp
f0103ffe:	57                   	push   %edi
f0103fff:	56                   	push   %esi
f0104000:	53                   	push   %ebx
f0104001:	83 ec 0c             	sub    $0xc,%esp
f0104004:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0104007:	0f 20 d6             	mov    %cr2,%esi
	fault_va = rcr2();

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
	if((tf->tf_cs & 3) == 0)
f010400a:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f010400e:	75 17                	jne    f0104027 <page_fault_handler+0x2c>
	{
		panic("page fault happened in kernel");
f0104010:	83 ec 04             	sub    $0x4,%esp
f0104013:	68 1b 77 10 f0       	push   $0xf010771b
f0104018:	68 70 01 00 00       	push   $0x170
f010401d:	68 39 77 10 f0       	push   $0xf0107739
f0104022:	e8 19 c0 ff ff       	call   f0100040 <_panic>
	//   To change what the user environment runs, modify 'curenv->env_tf'
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.
	//cprintf("%x\n", curenv->env_pgfault_upcall);
	if (curenv->env_pgfault_upcall == NULL)
f0104027:	e8 1e 1c 00 00       	call   f0105c4a <cpunum>
f010402c:	6b c0 74             	imul   $0x74,%eax,%eax
f010402f:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0104035:	83 78 64 00          	cmpl   $0x0,0x64(%eax)
f0104039:	75 41                	jne    f010407c <page_fault_handler+0x81>
	{
		// Destroy the environment that caused the fault.
		cprintf("[%08x] user fault va %08x ip %08x\n",
f010403b:	8b 7b 30             	mov    0x30(%ebx),%edi
		curenv->env_id, fault_va, tf->tf_eip);
f010403e:	e8 07 1c 00 00       	call   f0105c4a <cpunum>
	// LAB 4: Your code here.
	//cprintf("%x\n", curenv->env_pgfault_upcall);
	if (curenv->env_pgfault_upcall == NULL)
	{
		// Destroy the environment that caused the fault.
		cprintf("[%08x] user fault va %08x ip %08x\n",
f0104043:	57                   	push   %edi
f0104044:	56                   	push   %esi
		curenv->env_id, fault_va, tf->tf_eip);
f0104045:	6b c0 74             	imul   $0x74,%eax,%eax
	// LAB 4: Your code here.
	//cprintf("%x\n", curenv->env_pgfault_upcall);
	if (curenv->env_pgfault_upcall == NULL)
	{
		// Destroy the environment that caused the fault.
		cprintf("[%08x] user fault va %08x ip %08x\n",
f0104048:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f010404e:	ff 70 48             	pushl  0x48(%eax)
f0104051:	68 e0 78 10 f0       	push   $0xf01078e0
f0104056:	e8 c9 f6 ff ff       	call   f0103724 <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
		print_trapframe(tf);
f010405b:	89 1c 24             	mov    %ebx,(%esp)
f010405e:	e8 10 fe ff ff       	call   f0103e73 <print_trapframe>
		env_destroy(curenv);
f0104063:	e8 e2 1b 00 00       	call   f0105c4a <cpunum>
f0104068:	83 c4 04             	add    $0x4,%esp
f010406b:	6b c0 74             	imul   $0x74,%eax,%eax
f010406e:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f0104074:	e8 bb f3 ff ff       	call   f0103434 <env_destroy>
f0104079:	83 c4 10             	add    $0x10,%esp
	}
	struct UTrapframe *utf; 
	uintptr_t utf_addr; 
	if (tf->tf_esp >= UXSTACKTOP - PGSIZE && tf->tf_esp <= UXSTACKTOP - 1)
f010407c:	8b 43 3c             	mov    0x3c(%ebx),%eax
f010407f:	8d 90 00 10 40 11    	lea    0x11401000(%eax),%edx
	{
		utf_addr = tf->tf_esp - sizeof(struct UTrapframe) - 4;
f0104085:	83 e8 38             	sub    $0x38,%eax
f0104088:	81 fa ff 0f 00 00    	cmp    $0xfff,%edx
f010408e:	ba cc ff bf ee       	mov    $0xeebfffcc,%edx
f0104093:	0f 46 d0             	cmovbe %eax,%edx
f0104096:	89 d7                	mov    %edx,%edi
	}
	else
	{ 
		utf_addr = UXSTACKTOP - sizeof(struct UTrapframe);
	}
	user_mem_assert(curenv, (void*)utf_addr, sizeof(struct UTrapframe), PTE_W);
f0104098:	e8 ad 1b 00 00       	call   f0105c4a <cpunum>
f010409d:	6a 02                	push   $0x2
f010409f:	6a 34                	push   $0x34
f01040a1:	57                   	push   %edi
f01040a2:	6b c0 74             	imul   $0x74,%eax,%eax
f01040a5:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f01040ab:	e8 08 ed ff ff       	call   f0102db8 <user_mem_assert>
	utf = (struct UTrapframe*)utf_addr;
	utf->utf_fault_va = fault_va;
f01040b0:	89 fa                	mov    %edi,%edx
f01040b2:	89 37                	mov    %esi,(%edi)
	utf->utf_err = tf->tf_err;
f01040b4:	8b 43 2c             	mov    0x2c(%ebx),%eax
f01040b7:	89 47 04             	mov    %eax,0x4(%edi)
	utf->utf_regs = tf->tf_regs;
f01040ba:	8d 7f 08             	lea    0x8(%edi),%edi
f01040bd:	b9 08 00 00 00       	mov    $0x8,%ecx
f01040c2:	89 de                	mov    %ebx,%esi
f01040c4:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	utf->utf_eip = tf->tf_eip;
f01040c6:	8b 43 30             	mov    0x30(%ebx),%eax
f01040c9:	89 42 28             	mov    %eax,0x28(%edx)
	utf->utf_eflags = tf->tf_eflags;
f01040cc:	8b 43 38             	mov    0x38(%ebx),%eax
f01040cf:	89 d7                	mov    %edx,%edi
f01040d1:	89 42 2c             	mov    %eax,0x2c(%edx)
	utf->utf_esp = tf->tf_esp;
f01040d4:	8b 43 3c             	mov    0x3c(%ebx),%eax
f01040d7:	89 42 30             	mov    %eax,0x30(%edx)
	tf->tf_eip = (uintptr_t)curenv->env_pgfault_upcall;
f01040da:	e8 6b 1b 00 00       	call   f0105c4a <cpunum>
f01040df:	6b c0 74             	imul   $0x74,%eax,%eax
f01040e2:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f01040e8:	8b 40 64             	mov    0x64(%eax),%eax
f01040eb:	89 43 30             	mov    %eax,0x30(%ebx)
    	tf->tf_esp = utf_addr;
f01040ee:	89 7b 3c             	mov    %edi,0x3c(%ebx)
	env_run(curenv); 
f01040f1:	e8 54 1b 00 00       	call   f0105c4a <cpunum>
f01040f6:	83 c4 04             	add    $0x4,%esp
f01040f9:	6b c0 74             	imul   $0x74,%eax,%eax
f01040fc:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f0104102:	e8 cc f3 ff ff       	call   f01034d3 <env_run>

f0104107 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0104107:	55                   	push   %ebp
f0104108:	89 e5                	mov    %esp,%ebp
f010410a:	57                   	push   %edi
f010410b:	56                   	push   %esi
f010410c:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f010410f:	fc                   	cld    

	// Halt the CPU if some other CPU has called panic()
	extern char *panicstr;
	if (panicstr)
f0104110:	83 3d 80 fe 22 f0 00 	cmpl   $0x0,0xf022fe80
f0104117:	74 01                	je     f010411a <trap+0x13>
		asm volatile("hlt");
f0104119:	f4                   	hlt    

	// Re-acqurie the big kernel lock if we were halted in
	// sched_yield()
	if (xchg(&thiscpu->cpu_status, CPU_STARTED) == CPU_HALTED)
f010411a:	e8 2b 1b 00 00       	call   f0105c4a <cpunum>
f010411f:	6b d0 74             	imul   $0x74,%eax,%edx
f0104122:	81 c2 20 00 23 f0    	add    $0xf0230020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0104128:	b8 01 00 00 00       	mov    $0x1,%eax
f010412d:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0104131:	83 f8 02             	cmp    $0x2,%eax
f0104134:	75 10                	jne    f0104146 <trap+0x3f>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f0104136:	83 ec 0c             	sub    $0xc,%esp
f0104139:	68 c0 03 12 f0       	push   $0xf01203c0
f010413e:	e8 75 1d 00 00       	call   f0105eb8 <spin_lock>
f0104143:	83 c4 10             	add    $0x10,%esp

static __inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	__asm __volatile("pushfl; popl %0" : "=r" (eflags));
f0104146:	9c                   	pushf  
f0104147:	58                   	pop    %eax
		lock_kernel();
	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0104148:	f6 c4 02             	test   $0x2,%ah
f010414b:	74 19                	je     f0104166 <trap+0x5f>
f010414d:	68 45 77 10 f0       	push   $0xf0107745
f0104152:	68 98 68 10 f0       	push   $0xf0106898
f0104157:	68 39 01 00 00       	push   $0x139
f010415c:	68 39 77 10 f0       	push   $0xf0107739
f0104161:	e8 da be ff ff       	call   f0100040 <_panic>

	if ((tf->tf_cs & 3) == 3) {
f0104166:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f010416a:	83 e0 03             	and    $0x3,%eax
f010416d:	66 83 f8 03          	cmp    $0x3,%ax
f0104171:	0f 85 a0 00 00 00    	jne    f0104217 <trap+0x110>
f0104177:	83 ec 0c             	sub    $0xc,%esp
f010417a:	68 c0 03 12 f0       	push   $0xf01203c0
f010417f:	e8 34 1d 00 00       	call   f0105eb8 <spin_lock>
		// Trapped from user mode.
		// Acquire the big kernel lock before doing any
		// serious kernel work.
		// LAB 4: Your code here.
		lock_kernel();
		assert(curenv);
f0104184:	e8 c1 1a 00 00       	call   f0105c4a <cpunum>
f0104189:	6b c0 74             	imul   $0x74,%eax,%eax
f010418c:	83 c4 10             	add    $0x10,%esp
f010418f:	83 b8 28 00 23 f0 00 	cmpl   $0x0,-0xfdcffd8(%eax)
f0104196:	75 19                	jne    f01041b1 <trap+0xaa>
f0104198:	68 5e 77 10 f0       	push   $0xf010775e
f010419d:	68 98 68 10 f0       	push   $0xf0106898
f01041a2:	68 41 01 00 00       	push   $0x141
f01041a7:	68 39 77 10 f0       	push   $0xf0107739
f01041ac:	e8 8f be ff ff       	call   f0100040 <_panic>

		// Garbage collect if current enviroment is a zombie
		if (curenv->env_status == ENV_DYING) {
f01041b1:	e8 94 1a 00 00       	call   f0105c4a <cpunum>
f01041b6:	6b c0 74             	imul   $0x74,%eax,%eax
f01041b9:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f01041bf:	83 78 54 01          	cmpl   $0x1,0x54(%eax)
f01041c3:	75 2d                	jne    f01041f2 <trap+0xeb>
			env_free(curenv);
f01041c5:	e8 80 1a 00 00       	call   f0105c4a <cpunum>
f01041ca:	83 ec 0c             	sub    $0xc,%esp
f01041cd:	6b c0 74             	imul   $0x74,%eax,%eax
f01041d0:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f01041d6:	e8 7e f0 ff ff       	call   f0103259 <env_free>
			curenv = NULL;
f01041db:	e8 6a 1a 00 00       	call   f0105c4a <cpunum>
f01041e0:	6b c0 74             	imul   $0x74,%eax,%eax
f01041e3:	c7 80 28 00 23 f0 00 	movl   $0x0,-0xfdcffd8(%eax)
f01041ea:	00 00 00 
			sched_yield();
f01041ed:	e8 05 03 00 00       	call   f01044f7 <sched_yield>
		}

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f01041f2:	e8 53 1a 00 00       	call   f0105c4a <cpunum>
f01041f7:	6b c0 74             	imul   $0x74,%eax,%eax
f01041fa:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0104200:	b9 11 00 00 00       	mov    $0x11,%ecx
f0104205:	89 c7                	mov    %eax,%edi
f0104207:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0104209:	e8 3c 1a 00 00       	call   f0105c4a <cpunum>
f010420e:	6b c0 74             	imul   $0x74,%eax,%eax
f0104211:	8b b0 28 00 23 f0    	mov    -0xfdcffd8(%eax),%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0104217:	89 35 60 fa 22 f0    	mov    %esi,0xf022fa60
static void
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	if (tf->tf_trapno == T_PGFLT) 
f010421d:	8b 46 28             	mov    0x28(%esi),%eax
f0104220:	83 f8 0e             	cmp    $0xe,%eax
f0104223:	75 09                	jne    f010422e <trap+0x127>
	{ 
        page_fault_handler(tf);
f0104225:	83 ec 0c             	sub    $0xc,%esp
f0104228:	56                   	push   %esi
f0104229:	e8 cd fd ff ff       	call   f0103ffb <page_fault_handler>
        return;
   	 }
	if (tf->tf_trapno == T_BRKPT) 
f010422e:	83 f8 03             	cmp    $0x3,%eax
f0104231:	75 11                	jne    f0104244 <trap+0x13d>
	{ 	
        	monitor(tf);
f0104233:	83 ec 0c             	sub    $0xc,%esp
f0104236:	56                   	push   %esi
f0104237:	e8 c6 c6 ff ff       	call   f0100902 <monitor>
f010423c:	83 c4 10             	add    $0x10,%esp
f010423f:	e9 97 00 00 00       	jmp    f01042db <trap+0x1d4>
        	return;
    	}
	if(tf->tf_trapno == T_SYSCALL)
f0104244:	83 f8 30             	cmp    $0x30,%eax
f0104247:	75 21                	jne    f010426a <trap+0x163>
	{   
	tf->tf_regs.reg_eax = syscall(
f0104249:	83 ec 08             	sub    $0x8,%esp
f010424c:	ff 76 04             	pushl  0x4(%esi)
f010424f:	ff 36                	pushl  (%esi)
f0104251:	ff 76 10             	pushl  0x10(%esi)
f0104254:	ff 76 18             	pushl  0x18(%esi)
f0104257:	ff 76 14             	pushl  0x14(%esi)
f010425a:	ff 76 1c             	pushl  0x1c(%esi)
f010425d:	e8 0c 03 00 00       	call   f010456e <syscall>
f0104262:	89 46 1c             	mov    %eax,0x1c(%esi)
f0104265:	83 c4 20             	add    $0x20,%esp
f0104268:	eb 71                	jmp    f01042db <trap+0x1d4>
		return;
	}
	// Handle spurious interrupts
	// The hardware sometimes raises these because of noise on the
	// IRQ line or other reasons. We don't care.
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
f010426a:	83 f8 27             	cmp    $0x27,%eax
f010426d:	75 1a                	jne    f0104289 <trap+0x182>
		cprintf("Spurious interrupt on irq 7\n");
f010426f:	83 ec 0c             	sub    $0xc,%esp
f0104272:	68 65 77 10 f0       	push   $0xf0107765
f0104277:	e8 a8 f4 ff ff       	call   f0103724 <cprintf>
		print_trapframe(tf);
f010427c:	89 34 24             	mov    %esi,(%esp)
f010427f:	e8 ef fb ff ff       	call   f0103e73 <print_trapframe>
f0104284:	83 c4 10             	add    $0x10,%esp
f0104287:	eb 52                	jmp    f01042db <trap+0x1d4>
	}

	// Handle clock interrupts. Don't forget to acknowledge the
	// interrupt using lapic_eoi() before calling the scheduler!
	// LAB 4: Your code here.
	if (tf->tf_trapno == IRQ_OFFSET + 0)
f0104289:	83 f8 20             	cmp    $0x20,%eax
f010428c:	75 0a                	jne    f0104298 <trap+0x191>
	{ 
		lapic_eoi();
f010428e:	e8 02 1b 00 00       	call   f0105d95 <lapic_eoi>
		sched_yield();
f0104293:	e8 5f 02 00 00       	call   f01044f7 <sched_yield>
		return;
	}
	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f0104298:	83 ec 0c             	sub    $0xc,%esp
f010429b:	56                   	push   %esi
f010429c:	e8 d2 fb ff ff       	call   f0103e73 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f01042a1:	83 c4 10             	add    $0x10,%esp
f01042a4:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f01042a9:	75 17                	jne    f01042c2 <trap+0x1bb>
		panic("unhandled trap in kernel");
f01042ab:	83 ec 04             	sub    $0x4,%esp
f01042ae:	68 82 77 10 f0       	push   $0xf0107782
f01042b3:	68 1f 01 00 00       	push   $0x11f
f01042b8:	68 39 77 10 f0       	push   $0xf0107739
f01042bd:	e8 7e bd ff ff       	call   f0100040 <_panic>
	else {
		env_destroy(curenv);
f01042c2:	e8 83 19 00 00       	call   f0105c4a <cpunum>
f01042c7:	83 ec 0c             	sub    $0xc,%esp
f01042ca:	6b c0 74             	imul   $0x74,%eax,%eax
f01042cd:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f01042d3:	e8 5c f1 ff ff       	call   f0103434 <env_destroy>
f01042d8:	83 c4 10             	add    $0x10,%esp
	trap_dispatch(tf);

	// If we made it to this point, then no other environment was
	// scheduled, so we should return to the current environment
	// if doing so makes sense.
	if (curenv && curenv->env_status == ENV_RUNNING)
f01042db:	e8 6a 19 00 00       	call   f0105c4a <cpunum>
f01042e0:	6b c0 74             	imul   $0x74,%eax,%eax
f01042e3:	83 b8 28 00 23 f0 00 	cmpl   $0x0,-0xfdcffd8(%eax)
f01042ea:	74 2a                	je     f0104316 <trap+0x20f>
f01042ec:	e8 59 19 00 00       	call   f0105c4a <cpunum>
f01042f1:	6b c0 74             	imul   $0x74,%eax,%eax
f01042f4:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f01042fa:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f01042fe:	75 16                	jne    f0104316 <trap+0x20f>
		env_run(curenv);
f0104300:	e8 45 19 00 00       	call   f0105c4a <cpunum>
f0104305:	83 ec 0c             	sub    $0xc,%esp
f0104308:	6b c0 74             	imul   $0x74,%eax,%eax
f010430b:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f0104311:	e8 bd f1 ff ff       	call   f01034d3 <env_run>
	else
		sched_yield();
f0104316:	e8 dc 01 00 00       	call   f01044f7 <sched_yield>
f010431b:	90                   	nop

f010431c <t_divide>:
.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
TRAPHANDLER_NOEC(t_divide, T_DIVIDE)   // 0
f010431c:	6a 00                	push   $0x0
f010431e:	6a 00                	push   $0x0
f0104320:	e9 ef 00 00 00       	jmp    f0104414 <_alltraps>
f0104325:	90                   	nop

f0104326 <t_debug>:
TRAPHANDLER_NOEC(t_debug, T_DEBUG)     // 1
f0104326:	6a 00                	push   $0x0
f0104328:	6a 01                	push   $0x1
f010432a:	e9 e5 00 00 00       	jmp    f0104414 <_alltraps>
f010432f:	90                   	nop

f0104330 <t_nmi>:
TRAPHANDLER_NOEC(t_nmi, T_NMI)         // 2
f0104330:	6a 00                	push   $0x0
f0104332:	6a 02                	push   $0x2
f0104334:	e9 db 00 00 00       	jmp    f0104414 <_alltraps>
f0104339:	90                   	nop

f010433a <t_brkpt>:
TRAPHANDLER_NOEC(t_brkpt, T_BRKPT)     // 3
f010433a:	6a 00                	push   $0x0
f010433c:	6a 03                	push   $0x3
f010433e:	e9 d1 00 00 00       	jmp    f0104414 <_alltraps>
f0104343:	90                   	nop

f0104344 <t_oflow>:
TRAPHANDLER_NOEC(t_oflow, T_OFLOW)     // 4
f0104344:	6a 00                	push   $0x0
f0104346:	6a 04                	push   $0x4
f0104348:	e9 c7 00 00 00       	jmp    f0104414 <_alltraps>
f010434d:	90                   	nop

f010434e <t_bound>:
TRAPHANDLER_NOEC(t_bound, T_BOUND)     // 5
f010434e:	6a 00                	push   $0x0
f0104350:	6a 05                	push   $0x5
f0104352:	e9 bd 00 00 00       	jmp    f0104414 <_alltraps>
f0104357:	90                   	nop

f0104358 <t_illop>:
TRAPHANDLER_NOEC(t_illop, T_ILLOP)     // 6
f0104358:	6a 00                	push   $0x0
f010435a:	6a 06                	push   $0x6
f010435c:	e9 b3 00 00 00       	jmp    f0104414 <_alltraps>
f0104361:	90                   	nop

f0104362 <t_device>:
TRAPHANDLER_NOEC(t_device, T_DEVICE)   // 7
f0104362:	6a 00                	push   $0x0
f0104364:	6a 07                	push   $0x7
f0104366:	e9 a9 00 00 00       	jmp    f0104414 <_alltraps>
f010436b:	90                   	nop

f010436c <t_dblflt>:
TRAPHANDLER(t_dblflt, T_DBLFLT)        // 8
f010436c:	6a 08                	push   $0x8
f010436e:	e9 a1 00 00 00       	jmp    f0104414 <_alltraps>
f0104373:	90                   	nop

f0104374 <t_tss>:
                                       // 9
TRAPHANDLER(t_tss, T_TSS)              // 10
f0104374:	6a 0a                	push   $0xa
f0104376:	e9 99 00 00 00       	jmp    f0104414 <_alltraps>
f010437b:	90                   	nop

f010437c <t_segnp>:
TRAPHANDLER(t_segnp, T_SEGNP)          // 11
f010437c:	6a 0b                	push   $0xb
f010437e:	e9 91 00 00 00       	jmp    f0104414 <_alltraps>
f0104383:	90                   	nop

f0104384 <t_stack>:
TRAPHANDLER(t_stack, T_STACK)          // 12
f0104384:	6a 0c                	push   $0xc
f0104386:	e9 89 00 00 00       	jmp    f0104414 <_alltraps>
f010438b:	90                   	nop

f010438c <t_gpflt>:
TRAPHANDLER(t_gpflt, T_GPFLT)          // 13
f010438c:	6a 0d                	push   $0xd
f010438e:	e9 81 00 00 00       	jmp    f0104414 <_alltraps>
f0104393:	90                   	nop

f0104394 <t_pgflt>:
TRAPHANDLER(t_pgflt, T_PGFLT)          // 14
f0104394:	6a 0e                	push   $0xe
f0104396:	eb 7c                	jmp    f0104414 <_alltraps>

f0104398 <t_fperr>:
                                       // 15
TRAPHANDLER_NOEC(t_fperr, T_FPERR)     // 16
f0104398:	6a 00                	push   $0x0
f010439a:	6a 10                	push   $0x10
f010439c:	eb 76                	jmp    f0104414 <_alltraps>

f010439e <t_align>:
TRAPHANDLER(t_align, T_ALIGN)          // 17
f010439e:	6a 11                	push   $0x11
f01043a0:	eb 72                	jmp    f0104414 <_alltraps>

f01043a2 <t_mchk>:
TRAPHANDLER_NOEC(t_mchk, T_MCHK)       // 18
f01043a2:	6a 00                	push   $0x0
f01043a4:	6a 12                	push   $0x12
f01043a6:	eb 6c                	jmp    f0104414 <_alltraps>

f01043a8 <t_simderr>:
TRAPHANDLER_NOEC(t_simderr, T_SIMDERR) // 19
f01043a8:	6a 00                	push   $0x0
f01043aa:	6a 13                	push   $0x13
f01043ac:	eb 66                	jmp    f0104414 <_alltraps>

f01043ae <t_syscall>:
//...
TRAPHANDLER_NOEC(t_syscall, T_SYSCALL) // 48
f01043ae:	6a 00                	push   $0x0
f01043b0:	6a 30                	push   $0x30
f01043b2:	eb 60                	jmp    f0104414 <_alltraps>

f01043b4 <IRQ_0>:
TRAPHANDLER_NOEC(IRQ_0, IRQ_OFFSET + 0)
f01043b4:	6a 00                	push   $0x0
f01043b6:	6a 20                	push   $0x20
f01043b8:	eb 5a                	jmp    f0104414 <_alltraps>

f01043ba <IRQ_1>:
TRAPHANDLER_NOEC(IRQ_1, IRQ_OFFSET + 1)
f01043ba:	6a 00                	push   $0x0
f01043bc:	6a 21                	push   $0x21
f01043be:	eb 54                	jmp    f0104414 <_alltraps>

f01043c0 <IRQ_2>:
TRAPHANDLER_NOEC(IRQ_2, IRQ_OFFSET + 2)
f01043c0:	6a 00                	push   $0x0
f01043c2:	6a 22                	push   $0x22
f01043c4:	eb 4e                	jmp    f0104414 <_alltraps>

f01043c6 <IRQ_3>:
TRAPHANDLER_NOEC(IRQ_3, IRQ_OFFSET + 3)
f01043c6:	6a 00                	push   $0x0
f01043c8:	6a 23                	push   $0x23
f01043ca:	eb 48                	jmp    f0104414 <_alltraps>

f01043cc <IRQ_4>:
TRAPHANDLER_NOEC(IRQ_4, IRQ_OFFSET + 4)
f01043cc:	6a 00                	push   $0x0
f01043ce:	6a 24                	push   $0x24
f01043d0:	eb 42                	jmp    f0104414 <_alltraps>

f01043d2 <IRQ_5>:
TRAPHANDLER_NOEC(IRQ_5, IRQ_OFFSET + 5)
f01043d2:	6a 00                	push   $0x0
f01043d4:	6a 25                	push   $0x25
f01043d6:	eb 3c                	jmp    f0104414 <_alltraps>

f01043d8 <IRQ_6>:
TRAPHANDLER_NOEC(IRQ_6, IRQ_OFFSET + 6)
f01043d8:	6a 00                	push   $0x0
f01043da:	6a 26                	push   $0x26
f01043dc:	eb 36                	jmp    f0104414 <_alltraps>

f01043de <IRQ_7>:
TRAPHANDLER_NOEC(IRQ_7, IRQ_OFFSET + 7)
f01043de:	6a 00                	push   $0x0
f01043e0:	6a 27                	push   $0x27
f01043e2:	eb 30                	jmp    f0104414 <_alltraps>

f01043e4 <IRQ_8>:
TRAPHANDLER_NOEC(IRQ_8, IRQ_OFFSET + 8)
f01043e4:	6a 00                	push   $0x0
f01043e6:	6a 28                	push   $0x28
f01043e8:	eb 2a                	jmp    f0104414 <_alltraps>

f01043ea <IRQ_9>:
TRAPHANDLER_NOEC(IRQ_9, IRQ_OFFSET + 9)
f01043ea:	6a 00                	push   $0x0
f01043ec:	6a 29                	push   $0x29
f01043ee:	eb 24                	jmp    f0104414 <_alltraps>

f01043f0 <IRQ_10>:
TRAPHANDLER_NOEC(IRQ_10, IRQ_OFFSET + 10)
f01043f0:	6a 00                	push   $0x0
f01043f2:	6a 2a                	push   $0x2a
f01043f4:	eb 1e                	jmp    f0104414 <_alltraps>

f01043f6 <IRQ_11>:
TRAPHANDLER_NOEC(IRQ_11, IRQ_OFFSET + 11)
f01043f6:	6a 00                	push   $0x0
f01043f8:	6a 2b                	push   $0x2b
f01043fa:	eb 18                	jmp    f0104414 <_alltraps>

f01043fc <IRQ_12>:
TRAPHANDLER_NOEC(IRQ_12, IRQ_OFFSET + 12)
f01043fc:	6a 00                	push   $0x0
f01043fe:	6a 2c                	push   $0x2c
f0104400:	eb 12                	jmp    f0104414 <_alltraps>

f0104402 <IRQ_13>:
TRAPHANDLER_NOEC(IRQ_13, IRQ_OFFSET + 13)
f0104402:	6a 00                	push   $0x0
f0104404:	6a 2d                	push   $0x2d
f0104406:	eb 0c                	jmp    f0104414 <_alltraps>

f0104408 <IRQ_14>:
TRAPHANDLER_NOEC(IRQ_14, IRQ_OFFSET + 14)
f0104408:	6a 00                	push   $0x0
f010440a:	6a 2e                	push   $0x2e
f010440c:	eb 06                	jmp    f0104414 <_alltraps>

f010440e <IRQ_15>:
TRAPHANDLER_NOEC(IRQ_15, IRQ_OFFSET + 15)
f010440e:	6a 00                	push   $0x0
f0104410:	6a 2f                	push   $0x2f
f0104412:	eb 00                	jmp    f0104414 <_alltraps>

f0104414 <_alltraps>:

/*
 * Lab 3: Your code here for _alltraps
 */
_alltraps:
    pushl %ds
f0104414:	1e                   	push   %ds
    pushl %es
f0104415:	06                   	push   %es
    pushal
f0104416:	60                   	pusha  
    pushl $GD_KD
f0104417:	6a 10                	push   $0x10
    popl %ds
f0104419:	1f                   	pop    %ds
    pushl $GD_KD
f010441a:	6a 10                	push   $0x10
    popl %es
f010441c:	07                   	pop    %es
    pushl %esp 
f010441d:	54                   	push   %esp
    call trap 
f010441e:	e8 e4 fc ff ff       	call   f0104107 <trap>

f0104423 <sched_halt>:
// Halt this CPU when there is nothing to do. Wait until the
// timer interrupt wakes it up. This function never returns.
//
void
sched_halt(void)
{
f0104423:	55                   	push   %ebp
f0104424:	89 e5                	mov    %esp,%ebp
f0104426:	83 ec 08             	sub    $0x8,%esp
f0104429:	a1 48 f2 22 f0       	mov    0xf022f248,%eax
f010442e:	8d 50 54             	lea    0x54(%eax),%edx
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0104431:	b9 00 00 00 00       	mov    $0x0,%ecx
		if ((envs[i].env_status == ENV_RUNNABLE ||
f0104436:	8b 02                	mov    (%edx),%eax
f0104438:	83 e8 01             	sub    $0x1,%eax
f010443b:	83 f8 02             	cmp    $0x2,%eax
f010443e:	76 10                	jbe    f0104450 <sched_halt+0x2d>
{
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0104440:	83 c1 01             	add    $0x1,%ecx
f0104443:	83 c2 7c             	add    $0x7c,%edx
f0104446:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f010444c:	75 e8                	jne    f0104436 <sched_halt+0x13>
f010444e:	eb 08                	jmp    f0104458 <sched_halt+0x35>
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
		     envs[i].env_status == ENV_DYING))
			break;
	}
	if (i == NENV) {
f0104450:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f0104456:	75 1f                	jne    f0104477 <sched_halt+0x54>
		cprintf("No runnable environments in the system!\n");
f0104458:	83 ec 0c             	sub    $0xc,%esp
f010445b:	68 70 79 10 f0       	push   $0xf0107970
f0104460:	e8 bf f2 ff ff       	call   f0103724 <cprintf>
f0104465:	83 c4 10             	add    $0x10,%esp
		while (1)
			monitor(NULL);
f0104468:	83 ec 0c             	sub    $0xc,%esp
f010446b:	6a 00                	push   $0x0
f010446d:	e8 90 c4 ff ff       	call   f0100902 <monitor>
f0104472:	83 c4 10             	add    $0x10,%esp
f0104475:	eb f1                	jmp    f0104468 <sched_halt+0x45>
	}

	// Mark that no environment is running on this CPU
	curenv = NULL;
f0104477:	e8 ce 17 00 00       	call   f0105c4a <cpunum>
f010447c:	6b c0 74             	imul   $0x74,%eax,%eax
f010447f:	c7 80 28 00 23 f0 00 	movl   $0x0,-0xfdcffd8(%eax)
f0104486:	00 00 00 
	lcr3(PADDR(kern_pgdir));
f0104489:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010448e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0104493:	77 12                	ja     f01044a7 <sched_halt+0x84>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0104495:	50                   	push   %eax
f0104496:	68 28 63 10 f0       	push   $0xf0106328
f010449b:	6a 4e                	push   $0x4e
f010449d:	68 99 79 10 f0       	push   $0xf0107999
f01044a2:	e8 99 bb ff ff       	call   f0100040 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01044a7:	05 00 00 00 10       	add    $0x10000000,%eax
f01044ac:	0f 22 d8             	mov    %eax,%cr3

	// Mark that this CPU is in the HALT state, so that when
	// timer interupts come in, we know we should re-acquire the
	// big kernel lock
	xchg(&thiscpu->cpu_status, CPU_HALTED);
f01044af:	e8 96 17 00 00       	call   f0105c4a <cpunum>
f01044b4:	6b d0 74             	imul   $0x74,%eax,%edx
f01044b7:	81 c2 20 00 23 f0    	add    $0xf0230020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f01044bd:	b8 02 00 00 00       	mov    $0x2,%eax
f01044c2:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f01044c6:	83 ec 0c             	sub    $0xc,%esp
f01044c9:	68 c0 03 12 f0       	push   $0xf01203c0
f01044ce:	e8 82 1a 00 00       	call   f0105f55 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f01044d3:	f3 90                	pause  
		"pushl $0\n"
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
f01044d5:	e8 70 17 00 00       	call   f0105c4a <cpunum>
f01044da:	6b c0 74             	imul   $0x74,%eax,%eax

	// Release the big kernel lock as if we were "leaving" the kernel
	unlock_kernel();

	// Reset stack pointer, enable interrupts and then halt.
	asm volatile (
f01044dd:	8b 80 30 00 23 f0    	mov    -0xfdcffd0(%eax),%eax
f01044e3:	bd 00 00 00 00       	mov    $0x0,%ebp
f01044e8:	89 c4                	mov    %eax,%esp
f01044ea:	6a 00                	push   $0x0
f01044ec:	6a 00                	push   $0x0
f01044ee:	fb                   	sti    
f01044ef:	f4                   	hlt    
f01044f0:	eb fd                	jmp    f01044ef <sched_halt+0xcc>
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
}
f01044f2:	83 c4 10             	add    $0x10,%esp
f01044f5:	c9                   	leave  
f01044f6:	c3                   	ret    

f01044f7 <sched_yield>:
void sched_halt(void);

// Choose a user environment to run and run it.
void
sched_yield(void)
{
f01044f7:	55                   	push   %ebp
f01044f8:	89 e5                	mov    %esp,%ebp
f01044fa:	56                   	push   %esi
f01044fb:	53                   	push   %ebx
	// another CPU (env_status == ENV_RUNNING). If there are
	// no runnable environments, simply drop through to the code
	// below to halt the cpu.

	// LAB 4: Your code here.
	struct Env *e = curenv;
f01044fc:	e8 49 17 00 00       	call   f0105c4a <cpunum>
f0104501:	6b c0 74             	imul   $0x74,%eax,%eax
f0104504:	8b b0 28 00 23 f0    	mov    -0xfdcffd8(%eax),%esi
	size_t env_i = 0, index;
	if(e != NULL)
f010450a:	85 f6                	test   %esi,%esi
f010450c:	74 0e                	je     f010451c <sched_yield+0x25>
	{
		env_i = ENVX(e->env_id)+1;	
f010450e:	8b 56 48             	mov    0x48(%esi),%edx
f0104511:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0104517:	83 c2 01             	add    $0x1,%edx
f010451a:	eb 05                	jmp    f0104521 <sched_yield+0x2a>
	// no runnable environments, simply drop through to the code
	// below to halt the cpu.

	// LAB 4: Your code here.
	struct Env *e = curenv;
	size_t env_i = 0, index;
f010451c:	ba 00 00 00 00       	mov    $0x0,%edx
		env_i = ENVX(e->env_id)+1;	
	}
	for(int i = 0;i < NENV;i++)
	{
		index = (env_i + i) % NENV; 
		if(envs[index].env_status == ENV_RUNNABLE)
f0104521:	8b 0d 48 f2 22 f0    	mov    0xf022f248,%ecx
f0104527:	8d 9a 00 04 00 00    	lea    0x400(%edx),%ebx
f010452d:	89 d0                	mov    %edx,%eax
f010452f:	25 ff 03 00 00       	and    $0x3ff,%eax
f0104534:	6b c0 7c             	imul   $0x7c,%eax,%eax
f0104537:	01 c8                	add    %ecx,%eax
f0104539:	83 78 54 02          	cmpl   $0x2,0x54(%eax)
f010453d:	75 09                	jne    f0104548 <sched_yield+0x51>
		{
			env_run(&envs[index]); 
f010453f:	83 ec 0c             	sub    $0xc,%esp
f0104542:	50                   	push   %eax
f0104543:	e8 8b ef ff ff       	call   f01034d3 <env_run>
f0104548:	83 c2 01             	add    $0x1,%edx
	size_t env_i = 0, index;
	if(e != NULL)
	{
		env_i = ENVX(e->env_id)+1;	
	}
	for(int i = 0;i < NENV;i++)
f010454b:	39 da                	cmp    %ebx,%edx
f010454d:	75 de                	jne    f010452d <sched_yield+0x36>
		if(envs[index].env_status == ENV_RUNNABLE)
		{
			env_run(&envs[index]); 
		}
	} 
	if(e != NULL && e->env_status == ENV_RUNNING)
f010454f:	85 f6                	test   %esi,%esi
f0104551:	74 0f                	je     f0104562 <sched_yield+0x6b>
f0104553:	83 7e 54 03          	cmpl   $0x3,0x54(%esi)
f0104557:	75 09                	jne    f0104562 <sched_yield+0x6b>
	{
		env_run(e);
f0104559:	83 ec 0c             	sub    $0xc,%esp
f010455c:	56                   	push   %esi
f010455d:	e8 71 ef ff ff       	call   f01034d3 <env_run>
	}
	// sched_halt never returns
	sched_halt();
f0104562:	e8 bc fe ff ff       	call   f0104423 <sched_halt>
}
f0104567:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010456a:	5b                   	pop    %ebx
f010456b:	5e                   	pop    %esi
f010456c:	5d                   	pop    %ebp
f010456d:	c3                   	ret    

f010456e <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f010456e:	55                   	push   %ebp
f010456f:	89 e5                	mov    %esp,%ebp
f0104571:	57                   	push   %edi
f0104572:	56                   	push   %esi
f0104573:	53                   	push   %ebx
f0104574:	83 ec 1c             	sub    $0x1c,%esp
f0104577:	8b 45 08             	mov    0x8(%ebp),%eax
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.
	int32_t ret = 0;
	switch (syscallno) { 
f010457a:	83 f8 0c             	cmp    $0xc,%eax
f010457d:	0f 87 1b 05 00 00    	ja     f0104a9e <syscall+0x530>
f0104583:	ff 24 85 e0 79 10 f0 	jmp    *-0xfef8620(,%eax,4)
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	user_mem_assert(curenv, s, len, PTE_U);
f010458a:	e8 bb 16 00 00       	call   f0105c4a <cpunum>
f010458f:	6a 04                	push   $0x4
f0104591:	ff 75 10             	pushl  0x10(%ebp)
f0104594:	ff 75 0c             	pushl  0xc(%ebp)
f0104597:	6b c0 74             	imul   $0x74,%eax,%eax
f010459a:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f01045a0:	e8 13 e8 ff ff       	call   f0102db8 <user_mem_assert>
	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f01045a5:	83 c4 0c             	add    $0xc,%esp
f01045a8:	ff 75 0c             	pushl  0xc(%ebp)
f01045ab:	ff 75 10             	pushl  0x10(%ebp)
f01045ae:	68 a6 79 10 f0       	push   $0xf01079a6
f01045b3:	e8 6c f1 ff ff       	call   f0103724 <cprintf>
f01045b8:	83 c4 10             	add    $0x10,%esp
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.
	int32_t ret = 0;
f01045bb:	b8 00 00 00 00       	mov    $0x0,%eax
f01045c0:	e9 e5 04 00 00       	jmp    f0104aaa <syscall+0x53c>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f01045c5:	e8 1d c0 ff ff       	call   f01005e7 <cons_getc>
		case SYS_cputs:
			sys_cputs((const char*)a1, a2);
			break;
		case SYS_cgetc:
			ret = sys_cgetc();
			break;
f01045ca:	e9 db 04 00 00       	jmp    f0104aaa <syscall+0x53c>
static int
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;
	if ((r = envid2env(envid, &e, 1)) < 0)
f01045cf:	83 ec 04             	sub    $0x4,%esp
f01045d2:	6a 01                	push   $0x1
f01045d4:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01045d7:	50                   	push   %eax
f01045d8:	ff 75 0c             	pushl  0xc(%ebp)
f01045db:	e8 a8 e8 ff ff       	call   f0102e88 <envid2env>
f01045e0:	83 c4 10             	add    $0x10,%esp
f01045e3:	85 c0                	test   %eax,%eax
f01045e5:	0f 88 bf 04 00 00    	js     f0104aaa <syscall+0x53c>
	{
		//cprintf("%x\n\n", e->env_id);
		return r;
	}
	if (e == curenv)
f01045eb:	e8 5a 16 00 00       	call   f0105c4a <cpunum>
f01045f0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01045f3:	6b c0 74             	imul   $0x74,%eax,%eax
f01045f6:	39 90 28 00 23 f0    	cmp    %edx,-0xfdcffd8(%eax)
f01045fc:	75 23                	jne    f0104621 <syscall+0xb3>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f01045fe:	e8 47 16 00 00       	call   f0105c4a <cpunum>
f0104603:	83 ec 08             	sub    $0x8,%esp
f0104606:	6b c0 74             	imul   $0x74,%eax,%eax
f0104609:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f010460f:	ff 70 48             	pushl  0x48(%eax)
f0104612:	68 ab 79 10 f0       	push   $0xf01079ab
f0104617:	e8 08 f1 ff ff       	call   f0103724 <cprintf>
f010461c:	83 c4 10             	add    $0x10,%esp
f010461f:	eb 25                	jmp    f0104646 <syscall+0xd8>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f0104621:	8b 5a 48             	mov    0x48(%edx),%ebx
f0104624:	e8 21 16 00 00       	call   f0105c4a <cpunum>
f0104629:	83 ec 04             	sub    $0x4,%esp
f010462c:	53                   	push   %ebx
f010462d:	6b c0 74             	imul   $0x74,%eax,%eax
f0104630:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0104636:	ff 70 48             	pushl  0x48(%eax)
f0104639:	68 c6 79 10 f0       	push   $0xf01079c6
f010463e:	e8 e1 f0 ff ff       	call   f0103724 <cprintf>
f0104643:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f0104646:	83 ec 0c             	sub    $0xc,%esp
f0104649:	ff 75 e4             	pushl  -0x1c(%ebp)
f010464c:	e8 e3 ed ff ff       	call   f0103434 <env_destroy>
f0104651:	83 c4 10             	add    $0x10,%esp
	return 0;
f0104654:	b8 00 00 00 00       	mov    $0x0,%eax
f0104659:	e9 4c 04 00 00       	jmp    f0104aaa <syscall+0x53c>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f010465e:	e8 e7 15 00 00       	call   f0105c4a <cpunum>
f0104663:	6b c0 74             	imul   $0x74,%eax,%eax
f0104666:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f010466c:	8b 40 48             	mov    0x48(%eax),%eax
		case SYS_env_destroy:
			ret = sys_env_destroy(a1);
			break;
		case SYS_getenvid:
			ret = sys_getenvid();
			break;
f010466f:	e9 36 04 00 00       	jmp    f0104aaa <syscall+0x53c>

// Deschedule current environment and pick a different one to run.
static void
sys_yield(void)
{
	sched_yield();
f0104674:	e8 7e fe ff ff       	call   f01044f7 <sched_yield>
	// from the current environment -- but tweaked so sys_exofork
	// will appear to return 0.

	// LAB 4: Your code here.
	struct Env *e;
	int flag = env_alloc(&e, curenv->env_id);
f0104679:	e8 cc 15 00 00       	call   f0105c4a <cpunum>
f010467e:	83 ec 08             	sub    $0x8,%esp
f0104681:	6b c0 74             	imul   $0x74,%eax,%eax
f0104684:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f010468a:	ff 70 48             	pushl  0x48(%eax)
f010468d:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104690:	50                   	push   %eax
f0104691:	e8 03 e9 ff ff       	call   f0102f99 <env_alloc>
	if(flag < 0)
f0104696:	83 c4 10             	add    $0x10,%esp
f0104699:	85 c0                	test   %eax,%eax
f010469b:	0f 88 09 04 00 00    	js     f0104aaa <syscall+0x53c>
	{ //cprintf("error: %x\n\n",flag);
		return flag; 
	}
	e->env_status = ENV_NOT_RUNNABLE; 
f01046a1:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01046a4:	c7 43 54 04 00 00 00 	movl   $0x4,0x54(%ebx)
	e->env_tf = curenv->env_tf;
f01046ab:	e8 9a 15 00 00       	call   f0105c4a <cpunum>
f01046b0:	6b c0 74             	imul   $0x74,%eax,%eax
f01046b3:	8b b0 28 00 23 f0    	mov    -0xfdcffd8(%eax),%esi
f01046b9:	b9 11 00 00 00       	mov    $0x11,%ecx
f01046be:	89 df                	mov    %ebx,%edi
f01046c0:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	e->env_tf.tf_regs.reg_eax = 0;
f01046c2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01046c5:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
	return e->env_id;
f01046cc:	8b 40 48             	mov    0x48(%eax),%eax
f01046cf:	e9 d6 03 00 00       	jmp    f0104aaa <syscall+0x53c>
	// You should set envid2env's third argument to 1, which will
	// check whether the current environment has permission to set
	// envid's status.

	// LAB 4: Your code here.
	if(status != ENV_RUNNABLE && status != ENV_NOT_RUNNABLE)
f01046d4:	8b 45 10             	mov    0x10(%ebp),%eax
f01046d7:	83 e8 02             	sub    $0x2,%eax
f01046da:	a9 fd ff ff ff       	test   $0xfffffffd,%eax
f01046df:	75 2e                	jne    f010470f <syscall+0x1a1>
	{
		return -E_INVAL; 
	}
	struct Env *e;
	int flag = envid2env(envid, &e, 1);
f01046e1:	83 ec 04             	sub    $0x4,%esp
f01046e4:	6a 01                	push   $0x1
f01046e6:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01046e9:	50                   	push   %eax
f01046ea:	ff 75 0c             	pushl  0xc(%ebp)
f01046ed:	e8 96 e7 ff ff       	call   f0102e88 <envid2env>
f01046f2:	89 c2                	mov    %eax,%edx
	if(flag != 0)
f01046f4:	83 c4 10             	add    $0x10,%esp
f01046f7:	85 c0                	test   %eax,%eax
f01046f9:	0f 85 ab 03 00 00    	jne    f0104aaa <syscall+0x53c>
	{
		return flag;
	}
	e->env_status = status;
f01046ff:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104702:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0104705:	89 48 54             	mov    %ecx,0x54(%eax)
	return 0;
f0104708:	89 d0                	mov    %edx,%eax
f010470a:	e9 9b 03 00 00       	jmp    f0104aaa <syscall+0x53c>
	// envid's status.

	// LAB 4: Your code here.
	if(status != ENV_RUNNABLE && status != ENV_NOT_RUNNABLE)
	{
		return -E_INVAL; 
f010470f:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104714:	e9 91 03 00 00       	jmp    f0104aaa <syscall+0x53c>
	//   If page_insert() fails, remember to free the page you
	//   allocated!

	// LAB 4: Your code here.
	struct Env *e;
	int flag = envid2env(envid, &e, 1);
f0104719:	83 ec 04             	sub    $0x4,%esp
f010471c:	6a 01                	push   $0x1
f010471e:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104721:	50                   	push   %eax
f0104722:	ff 75 0c             	pushl  0xc(%ebp)
f0104725:	e8 5e e7 ff ff       	call   f0102e88 <envid2env>
	if(flag != 0)
f010472a:	83 c4 10             	add    $0x10,%esp
f010472d:	85 c0                	test   %eax,%eax
f010472f:	0f 85 75 03 00 00    	jne    f0104aaa <syscall+0x53c>
	{
		return flag; 
	}
	if((va >= (void*)UTOP)||(PGOFF(va) != 0))
f0104735:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f010473c:	77 62                	ja     f01047a0 <syscall+0x232>
f010473e:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f0104745:	75 63                	jne    f01047aa <syscall+0x23c>
	{
		return -E_INVAL; 
	}
	int p = PTE_U|PTE_P;
	if((p & perm) != p)
f0104747:	8b 45 14             	mov    0x14(%ebp),%eax
f010474a:	83 e0 05             	and    $0x5,%eax
f010474d:	83 f8 05             	cmp    $0x5,%eax
f0104750:	75 62                	jne    f01047b4 <syscall+0x246>
	{
		return -E_INVAL;
	}
	if((perm & (~(PTE_U|PTE_P|PTE_AVAIL|PTE_W))) != 0)
f0104752:	f7 45 14 f8 f1 ff ff 	testl  $0xfffff1f8,0x14(%ebp)
f0104759:	75 63                	jne    f01047be <syscall+0x250>
	{
		return -E_INVAL; 
	}
	struct PageInfo *page = page_alloc(ALLOC_ZERO);
f010475b:	83 ec 0c             	sub    $0xc,%esp
f010475e:	6a 01                	push   $0x1
f0104760:	e8 a6 c7 ff ff       	call   f0100f0b <page_alloc>
f0104765:	89 c6                	mov    %eax,%esi
	if(page == NULL)
f0104767:	83 c4 10             	add    $0x10,%esp
f010476a:	85 c0                	test   %eax,%eax
f010476c:	74 5a                	je     f01047c8 <syscall+0x25a>
	{
		return -E_NO_MEM; 
	}
	flag = page_insert(e->env_pgdir, page, va, perm); 
f010476e:	ff 75 14             	pushl  0x14(%ebp)
f0104771:	ff 75 10             	pushl  0x10(%ebp)
f0104774:	50                   	push   %eax
f0104775:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104778:	ff 70 60             	pushl  0x60(%eax)
f010477b:	e8 73 ca ff ff       	call   f01011f3 <page_insert>
f0104780:	89 c3                	mov    %eax,%ebx
	if(flag != 0)
f0104782:	83 c4 10             	add    $0x10,%esp
f0104785:	85 c0                	test   %eax,%eax
f0104787:	0f 84 1d 03 00 00    	je     f0104aaa <syscall+0x53c>
	{
		page_free(page); 
f010478d:	83 ec 0c             	sub    $0xc,%esp
f0104790:	56                   	push   %esi
f0104791:	e8 e5 c7 ff ff       	call   f0100f7b <page_free>
f0104796:	83 c4 10             	add    $0x10,%esp
		return flag;
f0104799:	89 d8                	mov    %ebx,%eax
f010479b:	e9 0a 03 00 00       	jmp    f0104aaa <syscall+0x53c>
	{
		return flag; 
	}
	if((va >= (void*)UTOP)||(PGOFF(va) != 0))
	{
		return -E_INVAL; 
f01047a0:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01047a5:	e9 00 03 00 00       	jmp    f0104aaa <syscall+0x53c>
f01047aa:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01047af:	e9 f6 02 00 00       	jmp    f0104aaa <syscall+0x53c>
	}
	int p = PTE_U|PTE_P;
	if((p & perm) != p)
	{
		return -E_INVAL;
f01047b4:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01047b9:	e9 ec 02 00 00       	jmp    f0104aaa <syscall+0x53c>
	}
	if((perm & (~(PTE_U|PTE_P|PTE_AVAIL|PTE_W))) != 0)
	{
		return -E_INVAL; 
f01047be:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01047c3:	e9 e2 02 00 00       	jmp    f0104aaa <syscall+0x53c>
	}
	struct PageInfo *page = page_alloc(ALLOC_ZERO);
	if(page == NULL)
	{
		return -E_NO_MEM; 
f01047c8:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f01047cd:	e9 d8 02 00 00       	jmp    f0104aaa <syscall+0x53c>
	//   check the current permissions on the page.

	// LAB 4: Your code here.
	struct Env *e1;
	struct Env *e2;
	int flag1 = envid2env(srcenvid, &e1, 1);
f01047d2:	83 ec 04             	sub    $0x4,%esp
f01047d5:	6a 01                	push   $0x1
f01047d7:	8d 45 dc             	lea    -0x24(%ebp),%eax
f01047da:	50                   	push   %eax
f01047db:	ff 75 0c             	pushl  0xc(%ebp)
f01047de:	e8 a5 e6 ff ff       	call   f0102e88 <envid2env>
f01047e3:	89 c3                	mov    %eax,%ebx
	int flag2 = envid2env(dstenvid, &e2, 1);
f01047e5:	83 c4 0c             	add    $0xc,%esp
f01047e8:	6a 01                	push   $0x1
f01047ea:	8d 45 e0             	lea    -0x20(%ebp),%eax
f01047ed:	50                   	push   %eax
f01047ee:	ff 75 14             	pushl  0x14(%ebp)
f01047f1:	e8 92 e6 ff ff       	call   f0102e88 <envid2env>
	if(flag1 != 0 || flag2 != 0)
f01047f6:	83 c4 10             	add    $0x10,%esp
f01047f9:	09 c3                	or     %eax,%ebx
f01047fb:	75 71                	jne    f010486e <syscall+0x300>
	{
		return -E_BAD_ENV; 
	}
	if((srcva >= (void*)UTOP)||(PGOFF(srcva) != 0))
f01047fd:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0104804:	77 72                	ja     f0104878 <syscall+0x30a>
	{
		return -E_INVAL; 
	}
	if((dstva >= (void*)UTOP)||(PGOFF(dstva) != 0))
f0104806:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f010480d:	75 73                	jne    f0104882 <syscall+0x314>
f010480f:	81 7d 18 ff ff bf ee 	cmpl   $0xeebfffff,0x18(%ebp)
f0104816:	77 6a                	ja     f0104882 <syscall+0x314>
f0104818:	f7 45 18 ff 0f 00 00 	testl  $0xfff,0x18(%ebp)
f010481f:	75 6b                	jne    f010488c <syscall+0x31e>
	{
		return -E_INVAL; 
	}
	int p = PTE_U|PTE_P;
	if((p & perm) != p)
f0104821:	8b 45 1c             	mov    0x1c(%ebp),%eax
f0104824:	83 e0 05             	and    $0x5,%eax
f0104827:	83 f8 05             	cmp    $0x5,%eax
f010482a:	75 6a                	jne    f0104896 <syscall+0x328>
	{
		return -E_INVAL; 
	}
	if((perm & (~(PTE_U|PTE_P|PTE_AVAIL|PTE_W))) != 0)
f010482c:	f7 45 1c f8 f1 ff ff 	testl  $0xfffff1f8,0x1c(%ebp)
f0104833:	75 6b                	jne    f01048a0 <syscall+0x332>
	{
		return -E_INVAL;
	}
	pte_t *page_table1;
	struct PageInfo *page = page_lookup(e1->env_pgdir, srcva, &page_table1);
f0104835:	83 ec 04             	sub    $0x4,%esp
f0104838:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010483b:	50                   	push   %eax
f010483c:	ff 75 10             	pushl  0x10(%ebp)
f010483f:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104842:	ff 70 60             	pushl  0x60(%eax)
f0104845:	e8 d4 c8 ff ff       	call   f010111e <page_lookup>
	if ((*page_table1 & PTE_W) == 0 && (perm & PTE_W) == 1) 
	{ 
		return -E_INVAL;
	}
    	if (page_insert(e2->env_pgdir, page, dstva, perm) != 0) 
f010484a:	ff 75 1c             	pushl  0x1c(%ebp)
f010484d:	ff 75 18             	pushl  0x18(%ebp)
f0104850:	50                   	push   %eax
f0104851:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104854:	ff 70 60             	pushl  0x60(%eax)
f0104857:	e8 97 c9 ff ff       	call   f01011f3 <page_insert>
f010485c:	83 c4 20             	add    $0x20,%esp
	{
		return -E_NO_MEM;
f010485f:	85 c0                	test   %eax,%eax
f0104861:	ba fc ff ff ff       	mov    $0xfffffffc,%edx
f0104866:	0f 45 c2             	cmovne %edx,%eax
f0104869:	e9 3c 02 00 00       	jmp    f0104aaa <syscall+0x53c>
	struct Env *e2;
	int flag1 = envid2env(srcenvid, &e1, 1);
	int flag2 = envid2env(dstenvid, &e2, 1);
	if(flag1 != 0 || flag2 != 0)
	{
		return -E_BAD_ENV; 
f010486e:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0104873:	e9 32 02 00 00       	jmp    f0104aaa <syscall+0x53c>
	}
	if((srcva >= (void*)UTOP)||(PGOFF(srcva) != 0))
	{
		return -E_INVAL; 
f0104878:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f010487d:	e9 28 02 00 00       	jmp    f0104aaa <syscall+0x53c>
	}
	if((dstva >= (void*)UTOP)||(PGOFF(dstva) != 0))
	{
		return -E_INVAL; 
f0104882:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104887:	e9 1e 02 00 00       	jmp    f0104aaa <syscall+0x53c>
f010488c:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104891:	e9 14 02 00 00       	jmp    f0104aaa <syscall+0x53c>
	}
	int p = PTE_U|PTE_P;
	if((p & perm) != p)
	{
		return -E_INVAL; 
f0104896:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f010489b:	e9 0a 02 00 00       	jmp    f0104aaa <syscall+0x53c>
	}
	if((perm & (~(PTE_U|PTE_P|PTE_AVAIL|PTE_W))) != 0)
	{
		return -E_INVAL;
f01048a0:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01048a5:	e9 00 02 00 00       	jmp    f0104aaa <syscall+0x53c>
{
	// Hint: This function is a wrapper around page_remove().

	// LAB 4: Your code here.
	struct Env *e;
	int flag = envid2env(envid, &e, 1);
f01048aa:	83 ec 04             	sub    $0x4,%esp
f01048ad:	6a 01                	push   $0x1
f01048af:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01048b2:	50                   	push   %eax
f01048b3:	ff 75 0c             	pushl  0xc(%ebp)
f01048b6:	e8 cd e5 ff ff       	call   f0102e88 <envid2env>
	if(flag < 0)
f01048bb:	83 c4 10             	add    $0x10,%esp
f01048be:	85 c0                	test   %eax,%eax
f01048c0:	78 30                	js     f01048f2 <syscall+0x384>
	{
		return -E_BAD_ENV;
	}
	if((va >= (void*)UTOP)||(PGOFF(va) != 0))
f01048c2:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f01048c9:	77 31                	ja     f01048fc <syscall+0x38e>
f01048cb:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f01048d2:	75 32                	jne    f0104906 <syscall+0x398>
	{
		return -E_INVAL;
	}
	page_remove(e->env_pgdir, va);
f01048d4:	83 ec 08             	sub    $0x8,%esp
f01048d7:	ff 75 10             	pushl  0x10(%ebp)
f01048da:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01048dd:	ff 70 60             	pushl  0x60(%eax)
f01048e0:	e8 c8 c8 ff ff       	call   f01011ad <page_remove>
f01048e5:	83 c4 10             	add    $0x10,%esp
	return 0;
f01048e8:	b8 00 00 00 00       	mov    $0x0,%eax
f01048ed:	e9 b8 01 00 00       	jmp    f0104aaa <syscall+0x53c>
	// LAB 4: Your code here.
	struct Env *e;
	int flag = envid2env(envid, &e, 1);
	if(flag < 0)
	{
		return -E_BAD_ENV;
f01048f2:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01048f7:	e9 ae 01 00 00       	jmp    f0104aaa <syscall+0x53c>
	}
	if((va >= (void*)UTOP)||(PGOFF(va) != 0))
	{
		return -E_INVAL;
f01048fc:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104901:	e9 a4 01 00 00       	jmp    f0104aaa <syscall+0x53c>
f0104906:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
		case SYS_page_alloc:
			return sys_page_alloc((envid_t)a1, (void *)a2, (int)a3);
		case SYS_page_map:
	return sys_page_map((envid_t)a1, (void *)a2, (envid_t)a3, (void *)a4, (int)a5);
		case SYS_page_unmap:
			return sys_page_unmap((envid_t)a1, (void *)a2);
f010490b:	e9 9a 01 00 00       	jmp    f0104aaa <syscall+0x53c>
static int
sys_env_set_pgfault_upcall(envid_t envid, void *func)
{
	// LAB 4: Your code here.
	struct Env *e;  
    	int flag = envid2env(envid, &e, 1);  
f0104910:	83 ec 04             	sub    $0x4,%esp
f0104913:	6a 01                	push   $0x1
f0104915:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104918:	50                   	push   %eax
f0104919:	ff 75 0c             	pushl  0xc(%ebp)
f010491c:	e8 67 e5 ff ff       	call   f0102e88 <envid2env>
    	if(flag != 0)
f0104921:	83 c4 10             	add    $0x10,%esp
f0104924:	85 c0                	test   %eax,%eax
f0104926:	0f 85 7e 01 00 00    	jne    f0104aaa <syscall+0x53c>
	{		
		return flag; 
	}		
    	e->env_pgfault_upcall = func;
f010492c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010492f:	8b 7d 10             	mov    0x10(%ebp),%edi
f0104932:	89 7a 64             	mov    %edi,0x64(%edx)
		case SYS_page_map:
	return sys_page_map((envid_t)a1, (void *)a2, (envid_t)a3, (void *)a4, (int)a5);
		case SYS_page_unmap:
			return sys_page_unmap((envid_t)a1, (void *)a2);
		case SYS_env_set_pgfault_upcall:
			return sys_env_set_pgfault_upcall((envid_t)a1, (void *)a2);
f0104935:	e9 70 01 00 00       	jmp    f0104aaa <syscall+0x53c>
//	-E_INVAL if dstva < UTOP but dstva is not page-aligned.
static int
sys_ipc_recv(void *dstva)
{
	// LAB 4: Your code here.
	if(dstva < (void*)UTOP && PGOFF(dstva)!=0)
f010493a:	81 7d 0c ff ff bf ee 	cmpl   $0xeebfffff,0xc(%ebp)
f0104941:	77 0d                	ja     f0104950 <syscall+0x3e2>
f0104943:	f7 45 0c ff 0f 00 00 	testl  $0xfff,0xc(%ebp)
f010494a:	0f 85 55 01 00 00    	jne    f0104aa5 <syscall+0x537>
	{
		return -E_INVAL;
	}
	curenv->env_ipc_recving = true;
f0104950:	e8 f5 12 00 00       	call   f0105c4a <cpunum>
f0104955:	6b c0 74             	imul   $0x74,%eax,%eax
f0104958:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f010495e:	c6 40 68 01          	movb   $0x1,0x68(%eax)
	curenv->env_status = ENV_NOT_RUNNABLE;
f0104962:	e8 e3 12 00 00       	call   f0105c4a <cpunum>
f0104967:	6b c0 74             	imul   $0x74,%eax,%eax
f010496a:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0104970:	c7 40 54 04 00 00 00 	movl   $0x4,0x54(%eax)
	curenv->env_ipc_dstva = dstva;
f0104977:	e8 ce 12 00 00       	call   f0105c4a <cpunum>
f010497c:	6b c0 74             	imul   $0x74,%eax,%eax
f010497f:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0104985:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0104988:	89 78 6c             	mov    %edi,0x6c(%eax)

// Deschedule current environment and pick a different one to run.
static void
sys_yield(void)
{
	sched_yield();
f010498b:	e8 67 fb ff ff       	call   f01044f7 <sched_yield>
static int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, unsigned perm)
{
	// LAB 4: Your code here.
	struct Env *e; 
	int flag = envid2env(envid, &e, 0);
f0104990:	83 ec 04             	sub    $0x4,%esp
f0104993:	6a 00                	push   $0x0
f0104995:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0104998:	50                   	push   %eax
f0104999:	ff 75 0c             	pushl  0xc(%ebp)
f010499c:	e8 e7 e4 ff ff       	call   f0102e88 <envid2env>
	//cprintf("%x\n\n\n",flag);
	if(flag != 0)
f01049a1:	83 c4 10             	add    $0x10,%esp
f01049a4:	85 c0                	test   %eax,%eax
f01049a6:	0f 85 fe 00 00 00    	jne    f0104aaa <syscall+0x53c>
	{
		return flag; 
	}
	if(!e->env_ipc_recving)
f01049ac:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01049af:	80 78 68 00          	cmpb   $0x0,0x68(%eax)
f01049b3:	0f 84 de 00 00 00    	je     f0104a97 <syscall+0x529>
	{
		return -E_IPC_NOT_RECV;
	}
	if(srcva < (void*)UTOP)
f01049b9:	81 7d 14 ff ff bf ee 	cmpl   $0xeebfffff,0x14(%ebp)
f01049c0:	0f 87 98 00 00 00    	ja     f0104a5e <syscall+0x4f0>
	{
		pte_t *pte; 
		struct PageInfo *pg = page_lookup(curenv->env_pgdir, srcva, &pte);
f01049c6:	e8 7f 12 00 00       	call   f0105c4a <cpunum>
f01049cb:	83 ec 04             	sub    $0x4,%esp
f01049ce:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01049d1:	52                   	push   %edx
f01049d2:	ff 75 14             	pushl  0x14(%ebp)
f01049d5:	6b c0 74             	imul   $0x74,%eax,%eax
f01049d8:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f01049de:	ff 70 60             	pushl  0x60(%eax)
f01049e1:	e8 38 c7 ff ff       	call   f010111e <page_lookup>
f01049e6:	89 c2                	mov    %eax,%edx
		if(!pg)
f01049e8:	83 c4 10             	add    $0x10,%esp
f01049eb:	85 c0                	test   %eax,%eax
f01049ed:	74 68                	je     f0104a57 <syscall+0x4e9>
		{
			return -E_INVAL; 
		}
		if((perm & (~PTE_SYSCALL))||!(perm & PTE_U)||!(perm & PTE_P))
f01049ef:	8b 4d 18             	mov    0x18(%ebp),%ecx
f01049f2:	81 e1 fd f1 ff ff    	and    $0xfffff1fd,%ecx
		{
			return -E_INVAL; 
f01049f8:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
		struct PageInfo *pg = page_lookup(curenv->env_pgdir, srcva, &pte);
		if(!pg)
		{
			return -E_INVAL; 
		}
		if((perm & (~PTE_SYSCALL))||!(perm & PTE_U)||!(perm & PTE_P))
f01049fd:	83 f9 05             	cmp    $0x5,%ecx
f0104a00:	0f 85 a4 00 00 00    	jne    f0104aaa <syscall+0x53c>
		{
			return -E_INVAL; 
		}
		if ((perm & PTE_W) && !(*pte & PTE_W))
f0104a06:	f6 45 18 02          	testb  $0x2,0x18(%ebp)
f0104a0a:	74 0c                	je     f0104a18 <syscall+0x4aa>
f0104a0c:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0104a0f:	f6 01 02             	testb  $0x2,(%ecx)
f0104a12:	0f 84 92 00 00 00    	je     f0104aaa <syscall+0x53c>
		{
			return -E_INVAL; 
		}
		if (PGOFF(srcva)!=0)
		{
			return -E_INVAL; 
f0104a18:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
		}
		if ((perm & PTE_W) && !(*pte & PTE_W))
		{
			return -E_INVAL; 
		}
		if (PGOFF(srcva)!=0)
f0104a1d:	f7 45 14 ff 0f 00 00 	testl  $0xfff,0x14(%ebp)
f0104a24:	0f 85 80 00 00 00    	jne    f0104aaa <syscall+0x53c>
		{
			return -E_INVAL; 
		}
		if (e->env_ipc_dstva < (void*)UTOP) 
f0104a2a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104a2d:	8b 48 6c             	mov    0x6c(%eax),%ecx
f0104a30:	81 f9 ff ff bf ee    	cmp    $0xeebfffff,%ecx
f0104a36:	77 26                	ja     f0104a5e <syscall+0x4f0>
		{
			flag = page_insert(e->env_pgdir, pg, e->env_ipc_dstva, perm);
f0104a38:	ff 75 18             	pushl  0x18(%ebp)
f0104a3b:	51                   	push   %ecx
f0104a3c:	52                   	push   %edx
f0104a3d:	ff 70 60             	pushl  0x60(%eax)
f0104a40:	e8 ae c7 ff ff       	call   f01011f3 <page_insert>
			if (flag != 0)
f0104a45:	83 c4 10             	add    $0x10,%esp
f0104a48:	85 c0                	test   %eax,%eax
f0104a4a:	75 5e                	jne    f0104aaa <syscall+0x53c>
			{
				return flag;
			} 
			e->env_ipc_perm = perm;
f0104a4c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104a4f:	8b 7d 18             	mov    0x18(%ebp),%edi
f0104a52:	89 78 78             	mov    %edi,0x78(%eax)
f0104a55:	eb 07                	jmp    f0104a5e <syscall+0x4f0>
	{
		pte_t *pte; 
		struct PageInfo *pg = page_lookup(curenv->env_pgdir, srcva, &pte);
		if(!pg)
		{
			return -E_INVAL; 
f0104a57:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104a5c:	eb 4c                	jmp    f0104aaa <syscall+0x53c>
				return flag;
			} 
			e->env_ipc_perm = perm;
		}
	}
	e->env_ipc_recving = false;
f0104a5e:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104a61:	c6 43 68 00          	movb   $0x0,0x68(%ebx)
	e->env_ipc_from = curenv->env_id;
f0104a65:	e8 e0 11 00 00       	call   f0105c4a <cpunum>
f0104a6a:	6b c0 74             	imul   $0x74,%eax,%eax
f0104a6d:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0104a73:	8b 40 48             	mov    0x48(%eax),%eax
f0104a76:	89 43 74             	mov    %eax,0x74(%ebx)
	e->env_ipc_value = value; 
f0104a79:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104a7c:	8b 7d 10             	mov    0x10(%ebp),%edi
f0104a7f:	89 78 70             	mov    %edi,0x70(%eax)
	e->env_status = ENV_RUNNABLE;
f0104a82:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	e->env_tf.tf_regs.reg_eax = 0;
f0104a89:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
	return 0;
f0104a90:	b8 00 00 00 00       	mov    $0x0,%eax
f0104a95:	eb 13                	jmp    f0104aaa <syscall+0x53c>
	{
		return flag; 
	}
	if(!e->env_ipc_recving)
	{
		return -E_IPC_NOT_RECV;
f0104a97:	b8 f8 ff ff ff       	mov    $0xfffffff8,%eax
		case SYS_env_set_pgfault_upcall:
			return sys_env_set_pgfault_upcall((envid_t)a1, (void *)a2);
		case SYS_ipc_recv:
			return sys_ipc_recv((void*)a1);
		case SYS_ipc_try_send:
			return sys_ipc_try_send((envid_t)a1, (uint32_t)a2, (void*)a3, a4);
f0104a9c:	eb 0c                	jmp    f0104aaa <syscall+0x53c>
		default:
			return -E_NO_SYS;
f0104a9e:	b8 f9 ff ff ff       	mov    $0xfffffff9,%eax
f0104aa3:	eb 05                	jmp    f0104aaa <syscall+0x53c>
		case SYS_page_unmap:
			return sys_page_unmap((envid_t)a1, (void *)a2);
		case SYS_env_set_pgfault_upcall:
			return sys_env_set_pgfault_upcall((envid_t)a1, (void *)a2);
		case SYS_ipc_recv:
			return sys_ipc_recv((void*)a1);
f0104aa5:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
		default:
			return -E_NO_SYS;
	}
	return ret;
	//panic("syscall not implemented");
}
f0104aaa:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104aad:	5b                   	pop    %ebx
f0104aae:	5e                   	pop    %esi
f0104aaf:	5f                   	pop    %edi
f0104ab0:	5d                   	pop    %ebp
f0104ab1:	c3                   	ret    

f0104ab2 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0104ab2:	55                   	push   %ebp
f0104ab3:	89 e5                	mov    %esp,%ebp
f0104ab5:	57                   	push   %edi
f0104ab6:	56                   	push   %esi
f0104ab7:	53                   	push   %ebx
f0104ab8:	83 ec 14             	sub    $0x14,%esp
f0104abb:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104abe:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0104ac1:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104ac4:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0104ac7:	8b 1a                	mov    (%edx),%ebx
f0104ac9:	8b 01                	mov    (%ecx),%eax
f0104acb:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104ace:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0104ad5:	eb 7f                	jmp    f0104b56 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0104ad7:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0104ada:	01 d8                	add    %ebx,%eax
f0104adc:	89 c6                	mov    %eax,%esi
f0104ade:	c1 ee 1f             	shr    $0x1f,%esi
f0104ae1:	01 c6                	add    %eax,%esi
f0104ae3:	d1 fe                	sar    %esi
f0104ae5:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0104ae8:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0104aeb:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0104aee:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0104af0:	eb 03                	jmp    f0104af5 <stab_binsearch+0x43>
			m--;
f0104af2:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0104af5:	39 c3                	cmp    %eax,%ebx
f0104af7:	7f 0d                	jg     f0104b06 <stab_binsearch+0x54>
f0104af9:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104afd:	83 ea 0c             	sub    $0xc,%edx
f0104b00:	39 f9                	cmp    %edi,%ecx
f0104b02:	75 ee                	jne    f0104af2 <stab_binsearch+0x40>
f0104b04:	eb 05                	jmp    f0104b0b <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0104b06:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0104b09:	eb 4b                	jmp    f0104b56 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0104b0b:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104b0e:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0104b11:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0104b15:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0104b18:	76 11                	jbe    f0104b2b <stab_binsearch+0x79>
			*region_left = m;
f0104b1a:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0104b1d:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0104b1f:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104b22:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104b29:	eb 2b                	jmp    f0104b56 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0104b2b:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0104b2e:	73 14                	jae    f0104b44 <stab_binsearch+0x92>
			*region_right = m - 1;
f0104b30:	83 e8 01             	sub    $0x1,%eax
f0104b33:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104b36:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0104b39:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104b3b:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104b42:	eb 12                	jmp    f0104b56 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0104b44:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104b47:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0104b49:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0104b4d:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104b4f:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0104b56:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0104b59:	0f 8e 78 ff ff ff    	jle    f0104ad7 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0104b5f:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0104b63:	75 0f                	jne    f0104b74 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0104b65:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104b68:	8b 00                	mov    (%eax),%eax
f0104b6a:	83 e8 01             	sub    $0x1,%eax
f0104b6d:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0104b70:	89 06                	mov    %eax,(%esi)
f0104b72:	eb 2c                	jmp    f0104ba0 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104b74:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104b77:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0104b79:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104b7c:	8b 0e                	mov    (%esi),%ecx
f0104b7e:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104b81:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0104b84:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104b87:	eb 03                	jmp    f0104b8c <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0104b89:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104b8c:	39 c8                	cmp    %ecx,%eax
f0104b8e:	7e 0b                	jle    f0104b9b <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0104b90:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0104b94:	83 ea 0c             	sub    $0xc,%edx
f0104b97:	39 df                	cmp    %ebx,%edi
f0104b99:	75 ee                	jne    f0104b89 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0104b9b:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104b9e:	89 06                	mov    %eax,(%esi)
	}
}
f0104ba0:	83 c4 14             	add    $0x14,%esp
f0104ba3:	5b                   	pop    %ebx
f0104ba4:	5e                   	pop    %esi
f0104ba5:	5f                   	pop    %edi
f0104ba6:	5d                   	pop    %ebp
f0104ba7:	c3                   	ret    

f0104ba8 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0104ba8:	55                   	push   %ebp
f0104ba9:	89 e5                	mov    %esp,%ebp
f0104bab:	57                   	push   %edi
f0104bac:	56                   	push   %esi
f0104bad:	53                   	push   %ebx
f0104bae:	83 ec 2c             	sub    $0x2c,%esp
f0104bb1:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104bb4:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0104bb7:	c7 06 14 7a 10 f0    	movl   $0xf0107a14,(%esi)
	info->eip_line = 0;
f0104bbd:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0104bc4:	c7 46 08 14 7a 10 f0 	movl   $0xf0107a14,0x8(%esi)
	info->eip_fn_namelen = 9;
f0104bcb:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0104bd2:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0104bd5:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0104bdc:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0104be2:	0f 87 a3 00 00 00    	ja     f0104c8b <debuginfo_eip+0xe3>
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (void *)usd, sizeof(struct UserStabData), PTE_U) != 0) 
f0104be8:	e8 5d 10 00 00       	call   f0105c4a <cpunum>
f0104bed:	6a 04                	push   $0x4
f0104bef:	6a 10                	push   $0x10
f0104bf1:	68 00 00 20 00       	push   $0x200000
f0104bf6:	6b c0 74             	imul   $0x74,%eax,%eax
f0104bf9:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f0104bff:	e8 23 e1 ff ff       	call   f0102d27 <user_mem_check>
f0104c04:	83 c4 10             	add    $0x10,%esp
f0104c07:	85 c0                	test   %eax,%eax
f0104c09:	0f 85 d4 01 00 00    	jne    f0104de3 <debuginfo_eip+0x23b>
		{
           		return -1;
        	}
		stabs = usd->stabs;
f0104c0f:	a1 00 00 20 00       	mov    0x200000,%eax
f0104c14:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		stab_end = usd->stab_end;
f0104c17:	8b 1d 04 00 20 00    	mov    0x200004,%ebx
		stabstr = usd->stabstr;
f0104c1d:	8b 15 08 00 20 00    	mov    0x200008,%edx
f0104c23:	89 55 cc             	mov    %edx,-0x34(%ebp)
		stabstr_end = usd->stabstr_end;
f0104c26:	a1 0c 00 20 00       	mov    0x20000c,%eax
f0104c2b:	89 45 d0             	mov    %eax,-0x30(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (void *)stabs,stab_end - stabs, PTE_U) != 0) 
f0104c2e:	e8 17 10 00 00       	call   f0105c4a <cpunum>
f0104c33:	6a 04                	push   $0x4
f0104c35:	89 da                	mov    %ebx,%edx
f0104c37:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0104c3a:	29 ca                	sub    %ecx,%edx
f0104c3c:	c1 fa 02             	sar    $0x2,%edx
f0104c3f:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0104c45:	52                   	push   %edx
f0104c46:	51                   	push   %ecx
f0104c47:	6b c0 74             	imul   $0x74,%eax,%eax
f0104c4a:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f0104c50:	e8 d2 e0 ff ff       	call   f0102d27 <user_mem_check>
f0104c55:	83 c4 10             	add    $0x10,%esp
f0104c58:	85 c0                	test   %eax,%eax
f0104c5a:	0f 85 8a 01 00 00    	jne    f0104dea <debuginfo_eip+0x242>
		{
            		return -1;
        	}
		if (user_mem_check(curenv, (void *)stabstr, stabstr_end - stabstr, PTE_U) != 0) 
f0104c60:	e8 e5 0f 00 00       	call   f0105c4a <cpunum>
f0104c65:	6a 04                	push   $0x4
f0104c67:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0104c6a:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0104c6d:	29 ca                	sub    %ecx,%edx
f0104c6f:	52                   	push   %edx
f0104c70:	51                   	push   %ecx
f0104c71:	6b c0 74             	imul   $0x74,%eax,%eax
f0104c74:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f0104c7a:	e8 a8 e0 ff ff       	call   f0102d27 <user_mem_check>
f0104c7f:	83 c4 10             	add    $0x10,%esp
f0104c82:	85 c0                	test   %eax,%eax
f0104c84:	74 1f                	je     f0104ca5 <debuginfo_eip+0xfd>
f0104c86:	e9 66 01 00 00       	jmp    f0104df1 <debuginfo_eip+0x249>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0104c8b:	c7 45 d0 4e 57 11 f0 	movl   $0xf011574e,-0x30(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0104c92:	c7 45 cc b1 20 11 f0 	movl   $0xf01120b1,-0x34(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0104c99:	bb b0 20 11 f0       	mov    $0xf01120b0,%ebx
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0104c9e:	c7 45 d4 f8 7e 10 f0 	movl   $0xf0107ef8,-0x2c(%ebp)
            		return -1;
        	}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0104ca5:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0104ca8:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0104cab:	0f 83 47 01 00 00    	jae    f0104df8 <debuginfo_eip+0x250>
f0104cb1:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0104cb5:	0f 85 44 01 00 00    	jne    f0104dff <debuginfo_eip+0x257>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0104cbb:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0104cc2:	2b 5d d4             	sub    -0x2c(%ebp),%ebx
f0104cc5:	c1 fb 02             	sar    $0x2,%ebx
f0104cc8:	69 c3 ab aa aa aa    	imul   $0xaaaaaaab,%ebx,%eax
f0104cce:	83 e8 01             	sub    $0x1,%eax
f0104cd1:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0104cd4:	83 ec 08             	sub    $0x8,%esp
f0104cd7:	57                   	push   %edi
f0104cd8:	6a 64                	push   $0x64
f0104cda:	8d 55 e0             	lea    -0x20(%ebp),%edx
f0104cdd:	89 d1                	mov    %edx,%ecx
f0104cdf:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0104ce2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0104ce5:	89 d8                	mov    %ebx,%eax
f0104ce7:	e8 c6 fd ff ff       	call   f0104ab2 <stab_binsearch>
	if (lfile == 0)
f0104cec:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104cef:	83 c4 10             	add    $0x10,%esp
f0104cf2:	85 c0                	test   %eax,%eax
f0104cf4:	0f 84 0c 01 00 00    	je     f0104e06 <debuginfo_eip+0x25e>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0104cfa:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0104cfd:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104d00:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0104d03:	83 ec 08             	sub    $0x8,%esp
f0104d06:	57                   	push   %edi
f0104d07:	6a 24                	push   $0x24
f0104d09:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0104d0c:	89 d1                	mov    %edx,%ecx
f0104d0e:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0104d11:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
f0104d14:	89 d8                	mov    %ebx,%eax
f0104d16:	e8 97 fd ff ff       	call   f0104ab2 <stab_binsearch>

	if (lfun <= rfun) {
f0104d1b:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0104d1e:	83 c4 10             	add    $0x10,%esp
f0104d21:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f0104d24:	7f 24                	jg     f0104d4a <debuginfo_eip+0x1a2>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0104d26:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0104d29:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104d2c:	8d 14 87             	lea    (%edi,%eax,4),%edx
f0104d2f:	8b 02                	mov    (%edx),%eax
f0104d31:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0104d34:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0104d37:	29 f9                	sub    %edi,%ecx
f0104d39:	39 c8                	cmp    %ecx,%eax
f0104d3b:	73 05                	jae    f0104d42 <debuginfo_eip+0x19a>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0104d3d:	01 f8                	add    %edi,%eax
f0104d3f:	89 46 08             	mov    %eax,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0104d42:	8b 42 08             	mov    0x8(%edx),%eax
f0104d45:	89 46 10             	mov    %eax,0x10(%esi)
f0104d48:	eb 06                	jmp    f0104d50 <debuginfo_eip+0x1a8>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0104d4a:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0104d4d:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0104d50:	83 ec 08             	sub    $0x8,%esp
f0104d53:	6a 3a                	push   $0x3a
f0104d55:	ff 76 08             	pushl  0x8(%esi)
f0104d58:	e8 af 08 00 00       	call   f010560c <strfind>
f0104d5d:	2b 46 08             	sub    0x8(%esi),%eax
f0104d60:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0104d63:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104d66:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0104d69:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0104d6c:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f0104d6f:	83 c4 10             	add    $0x10,%esp
f0104d72:	eb 06                	jmp    f0104d7a <debuginfo_eip+0x1d2>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0104d74:	83 eb 01             	sub    $0x1,%ebx
f0104d77:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0104d7a:	39 fb                	cmp    %edi,%ebx
f0104d7c:	7c 2d                	jl     f0104dab <debuginfo_eip+0x203>
	       && stabs[lline].n_type != N_SOL
f0104d7e:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f0104d82:	80 fa 84             	cmp    $0x84,%dl
f0104d85:	74 0b                	je     f0104d92 <debuginfo_eip+0x1ea>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0104d87:	80 fa 64             	cmp    $0x64,%dl
f0104d8a:	75 e8                	jne    f0104d74 <debuginfo_eip+0x1cc>
f0104d8c:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0104d90:	74 e2                	je     f0104d74 <debuginfo_eip+0x1cc>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0104d92:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0104d95:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104d98:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0104d9b:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0104d9e:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0104da1:	29 f8                	sub    %edi,%eax
f0104da3:	39 c2                	cmp    %eax,%edx
f0104da5:	73 04                	jae    f0104dab <debuginfo_eip+0x203>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0104da7:	01 fa                	add    %edi,%edx
f0104da9:	89 16                	mov    %edx,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104dab:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0104dae:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104db1:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104db6:	39 cb                	cmp    %ecx,%ebx
f0104db8:	7d 58                	jge    f0104e12 <debuginfo_eip+0x26a>
		for (lline = lfun + 1;
f0104dba:	8d 53 01             	lea    0x1(%ebx),%edx
f0104dbd:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0104dc0:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104dc3:	8d 04 87             	lea    (%edi,%eax,4),%eax
f0104dc6:	eb 07                	jmp    f0104dcf <debuginfo_eip+0x227>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0104dc8:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0104dcc:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0104dcf:	39 ca                	cmp    %ecx,%edx
f0104dd1:	74 3a                	je     f0104e0d <debuginfo_eip+0x265>
f0104dd3:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0104dd6:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f0104dda:	74 ec                	je     f0104dc8 <debuginfo_eip+0x220>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104ddc:	b8 00 00 00 00       	mov    $0x0,%eax
f0104de1:	eb 2f                	jmp    f0104e12 <debuginfo_eip+0x26a>
		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (void *)usd, sizeof(struct UserStabData), PTE_U) != 0) 
		{
           		return -1;
f0104de3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104de8:	eb 28                	jmp    f0104e12 <debuginfo_eip+0x26a>

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (void *)stabs,stab_end - stabs, PTE_U) != 0) 
		{
            		return -1;
f0104dea:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104def:	eb 21                	jmp    f0104e12 <debuginfo_eip+0x26a>
        	}
		if (user_mem_check(curenv, (void *)stabstr, stabstr_end - stabstr, PTE_U) != 0) 
		{
            		return -1;
f0104df1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104df6:	eb 1a                	jmp    f0104e12 <debuginfo_eip+0x26a>
        	}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0104df8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104dfd:	eb 13                	jmp    f0104e12 <debuginfo_eip+0x26a>
f0104dff:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104e04:	eb 0c                	jmp    f0104e12 <debuginfo_eip+0x26a>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0104e06:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104e0b:	eb 05                	jmp    f0104e12 <debuginfo_eip+0x26a>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104e0d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104e12:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104e15:	5b                   	pop    %ebx
f0104e16:	5e                   	pop    %esi
f0104e17:	5f                   	pop    %edi
f0104e18:	5d                   	pop    %ebp
f0104e19:	c3                   	ret    

f0104e1a <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0104e1a:	55                   	push   %ebp
f0104e1b:	89 e5                	mov    %esp,%ebp
f0104e1d:	57                   	push   %edi
f0104e1e:	56                   	push   %esi
f0104e1f:	53                   	push   %ebx
f0104e20:	83 ec 1c             	sub    $0x1c,%esp
f0104e23:	89 c7                	mov    %eax,%edi
f0104e25:	89 d6                	mov    %edx,%esi
f0104e27:	8b 45 08             	mov    0x8(%ebp),%eax
f0104e2a:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104e2d:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104e30:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0104e33:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0104e36:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104e3b:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104e3e:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0104e41:	39 d3                	cmp    %edx,%ebx
f0104e43:	72 05                	jb     f0104e4a <printnum+0x30>
f0104e45:	39 45 10             	cmp    %eax,0x10(%ebp)
f0104e48:	77 45                	ja     f0104e8f <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0104e4a:	83 ec 0c             	sub    $0xc,%esp
f0104e4d:	ff 75 18             	pushl  0x18(%ebp)
f0104e50:	8b 45 14             	mov    0x14(%ebp),%eax
f0104e53:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0104e56:	53                   	push   %ebx
f0104e57:	ff 75 10             	pushl  0x10(%ebp)
f0104e5a:	83 ec 08             	sub    $0x8,%esp
f0104e5d:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104e60:	ff 75 e0             	pushl  -0x20(%ebp)
f0104e63:	ff 75 dc             	pushl  -0x24(%ebp)
f0104e66:	ff 75 d8             	pushl  -0x28(%ebp)
f0104e69:	e8 e2 11 00 00       	call   f0106050 <__udivdi3>
f0104e6e:	83 c4 18             	add    $0x18,%esp
f0104e71:	52                   	push   %edx
f0104e72:	50                   	push   %eax
f0104e73:	89 f2                	mov    %esi,%edx
f0104e75:	89 f8                	mov    %edi,%eax
f0104e77:	e8 9e ff ff ff       	call   f0104e1a <printnum>
f0104e7c:	83 c4 20             	add    $0x20,%esp
f0104e7f:	eb 18                	jmp    f0104e99 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0104e81:	83 ec 08             	sub    $0x8,%esp
f0104e84:	56                   	push   %esi
f0104e85:	ff 75 18             	pushl  0x18(%ebp)
f0104e88:	ff d7                	call   *%edi
f0104e8a:	83 c4 10             	add    $0x10,%esp
f0104e8d:	eb 03                	jmp    f0104e92 <printnum+0x78>
f0104e8f:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0104e92:	83 eb 01             	sub    $0x1,%ebx
f0104e95:	85 db                	test   %ebx,%ebx
f0104e97:	7f e8                	jg     f0104e81 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0104e99:	83 ec 08             	sub    $0x8,%esp
f0104e9c:	56                   	push   %esi
f0104e9d:	83 ec 04             	sub    $0x4,%esp
f0104ea0:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104ea3:	ff 75 e0             	pushl  -0x20(%ebp)
f0104ea6:	ff 75 dc             	pushl  -0x24(%ebp)
f0104ea9:	ff 75 d8             	pushl  -0x28(%ebp)
f0104eac:	e8 cf 12 00 00       	call   f0106180 <__umoddi3>
f0104eb1:	83 c4 14             	add    $0x14,%esp
f0104eb4:	0f be 80 1e 7a 10 f0 	movsbl -0xfef85e2(%eax),%eax
f0104ebb:	50                   	push   %eax
f0104ebc:	ff d7                	call   *%edi
}
f0104ebe:	83 c4 10             	add    $0x10,%esp
f0104ec1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104ec4:	5b                   	pop    %ebx
f0104ec5:	5e                   	pop    %esi
f0104ec6:	5f                   	pop    %edi
f0104ec7:	5d                   	pop    %ebp
f0104ec8:	c3                   	ret    

f0104ec9 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0104ec9:	55                   	push   %ebp
f0104eca:	89 e5                	mov    %esp,%ebp
f0104ecc:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0104ecf:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0104ed3:	8b 10                	mov    (%eax),%edx
f0104ed5:	3b 50 04             	cmp    0x4(%eax),%edx
f0104ed8:	73 0a                	jae    f0104ee4 <sprintputch+0x1b>
		*b->buf++ = ch;
f0104eda:	8d 4a 01             	lea    0x1(%edx),%ecx
f0104edd:	89 08                	mov    %ecx,(%eax)
f0104edf:	8b 45 08             	mov    0x8(%ebp),%eax
f0104ee2:	88 02                	mov    %al,(%edx)
}
f0104ee4:	5d                   	pop    %ebp
f0104ee5:	c3                   	ret    

f0104ee6 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0104ee6:	55                   	push   %ebp
f0104ee7:	89 e5                	mov    %esp,%ebp
f0104ee9:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0104eec:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0104eef:	50                   	push   %eax
f0104ef0:	ff 75 10             	pushl  0x10(%ebp)
f0104ef3:	ff 75 0c             	pushl  0xc(%ebp)
f0104ef6:	ff 75 08             	pushl  0x8(%ebp)
f0104ef9:	e8 05 00 00 00       	call   f0104f03 <vprintfmt>
	va_end(ap);
}
f0104efe:	83 c4 10             	add    $0x10,%esp
f0104f01:	c9                   	leave  
f0104f02:	c3                   	ret    

f0104f03 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0104f03:	55                   	push   %ebp
f0104f04:	89 e5                	mov    %esp,%ebp
f0104f06:	57                   	push   %edi
f0104f07:	56                   	push   %esi
f0104f08:	53                   	push   %ebx
f0104f09:	83 ec 2c             	sub    $0x2c,%esp
f0104f0c:	8b 75 08             	mov    0x8(%ebp),%esi
f0104f0f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104f12:	8b 7d 10             	mov    0x10(%ebp),%edi
f0104f15:	eb 12                	jmp    f0104f29 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0104f17:	85 c0                	test   %eax,%eax
f0104f19:	0f 84 42 04 00 00    	je     f0105361 <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
f0104f1f:	83 ec 08             	sub    $0x8,%esp
f0104f22:	53                   	push   %ebx
f0104f23:	50                   	push   %eax
f0104f24:	ff d6                	call   *%esi
f0104f26:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0104f29:	83 c7 01             	add    $0x1,%edi
f0104f2c:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0104f30:	83 f8 25             	cmp    $0x25,%eax
f0104f33:	75 e2                	jne    f0104f17 <vprintfmt+0x14>
f0104f35:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0104f39:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0104f40:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0104f47:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0104f4e:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104f53:	eb 07                	jmp    f0104f5c <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104f55:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0104f58:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104f5c:	8d 47 01             	lea    0x1(%edi),%eax
f0104f5f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104f62:	0f b6 07             	movzbl (%edi),%eax
f0104f65:	0f b6 d0             	movzbl %al,%edx
f0104f68:	83 e8 23             	sub    $0x23,%eax
f0104f6b:	3c 55                	cmp    $0x55,%al
f0104f6d:	0f 87 d3 03 00 00    	ja     f0105346 <vprintfmt+0x443>
f0104f73:	0f b6 c0             	movzbl %al,%eax
f0104f76:	ff 24 85 e0 7a 10 f0 	jmp    *-0xfef8520(,%eax,4)
f0104f7d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0104f80:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0104f84:	eb d6                	jmp    f0104f5c <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104f86:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104f89:	b8 00 00 00 00       	mov    $0x0,%eax
f0104f8e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0104f91:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0104f94:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0104f98:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0104f9b:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0104f9e:	83 f9 09             	cmp    $0x9,%ecx
f0104fa1:	77 3f                	ja     f0104fe2 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0104fa3:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0104fa6:	eb e9                	jmp    f0104f91 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0104fa8:	8b 45 14             	mov    0x14(%ebp),%eax
f0104fab:	8b 00                	mov    (%eax),%eax
f0104fad:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0104fb0:	8b 45 14             	mov    0x14(%ebp),%eax
f0104fb3:	8d 40 04             	lea    0x4(%eax),%eax
f0104fb6:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104fb9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0104fbc:	eb 2a                	jmp    f0104fe8 <vprintfmt+0xe5>
f0104fbe:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104fc1:	85 c0                	test   %eax,%eax
f0104fc3:	ba 00 00 00 00       	mov    $0x0,%edx
f0104fc8:	0f 49 d0             	cmovns %eax,%edx
f0104fcb:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104fce:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104fd1:	eb 89                	jmp    f0104f5c <vprintfmt+0x59>
f0104fd3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0104fd6:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0104fdd:	e9 7a ff ff ff       	jmp    f0104f5c <vprintfmt+0x59>
f0104fe2:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0104fe5:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0104fe8:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104fec:	0f 89 6a ff ff ff    	jns    f0104f5c <vprintfmt+0x59>
				width = precision, precision = -1;
f0104ff2:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0104ff5:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104ff8:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0104fff:	e9 58 ff ff ff       	jmp    f0104f5c <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0105004:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0105007:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f010500a:	e9 4d ff ff ff       	jmp    f0104f5c <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f010500f:	8b 45 14             	mov    0x14(%ebp),%eax
f0105012:	8d 78 04             	lea    0x4(%eax),%edi
f0105015:	83 ec 08             	sub    $0x8,%esp
f0105018:	53                   	push   %ebx
f0105019:	ff 30                	pushl  (%eax)
f010501b:	ff d6                	call   *%esi
			break;
f010501d:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0105020:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0105023:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0105026:	e9 fe fe ff ff       	jmp    f0104f29 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f010502b:	8b 45 14             	mov    0x14(%ebp),%eax
f010502e:	8d 78 04             	lea    0x4(%eax),%edi
f0105031:	8b 00                	mov    (%eax),%eax
f0105033:	99                   	cltd   
f0105034:	31 d0                	xor    %edx,%eax
f0105036:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0105038:	83 f8 09             	cmp    $0x9,%eax
f010503b:	7f 0b                	jg     f0105048 <vprintfmt+0x145>
f010503d:	8b 14 85 40 7c 10 f0 	mov    -0xfef83c0(,%eax,4),%edx
f0105044:	85 d2                	test   %edx,%edx
f0105046:	75 1b                	jne    f0105063 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
f0105048:	50                   	push   %eax
f0105049:	68 36 7a 10 f0       	push   $0xf0107a36
f010504e:	53                   	push   %ebx
f010504f:	56                   	push   %esi
f0105050:	e8 91 fe ff ff       	call   f0104ee6 <printfmt>
f0105055:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0105058:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010505b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f010505e:	e9 c6 fe ff ff       	jmp    f0104f29 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0105063:	52                   	push   %edx
f0105064:	68 aa 68 10 f0       	push   $0xf01068aa
f0105069:	53                   	push   %ebx
f010506a:	56                   	push   %esi
f010506b:	e8 76 fe ff ff       	call   f0104ee6 <printfmt>
f0105070:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0105073:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0105076:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0105079:	e9 ab fe ff ff       	jmp    f0104f29 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f010507e:	8b 45 14             	mov    0x14(%ebp),%eax
f0105081:	83 c0 04             	add    $0x4,%eax
f0105084:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0105087:	8b 45 14             	mov    0x14(%ebp),%eax
f010508a:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f010508c:	85 ff                	test   %edi,%edi
f010508e:	b8 2f 7a 10 f0       	mov    $0xf0107a2f,%eax
f0105093:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0105096:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f010509a:	0f 8e 94 00 00 00    	jle    f0105134 <vprintfmt+0x231>
f01050a0:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f01050a4:	0f 84 98 00 00 00    	je     f0105142 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
f01050aa:	83 ec 08             	sub    $0x8,%esp
f01050ad:	ff 75 d0             	pushl  -0x30(%ebp)
f01050b0:	57                   	push   %edi
f01050b1:	e8 0c 04 00 00       	call   f01054c2 <strnlen>
f01050b6:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f01050b9:	29 c1                	sub    %eax,%ecx
f01050bb:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f01050be:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f01050c1:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f01050c5:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01050c8:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01050cb:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01050cd:	eb 0f                	jmp    f01050de <vprintfmt+0x1db>
					putch(padc, putdat);
f01050cf:	83 ec 08             	sub    $0x8,%esp
f01050d2:	53                   	push   %ebx
f01050d3:	ff 75 e0             	pushl  -0x20(%ebp)
f01050d6:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01050d8:	83 ef 01             	sub    $0x1,%edi
f01050db:	83 c4 10             	add    $0x10,%esp
f01050de:	85 ff                	test   %edi,%edi
f01050e0:	7f ed                	jg     f01050cf <vprintfmt+0x1cc>
f01050e2:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01050e5:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f01050e8:	85 c9                	test   %ecx,%ecx
f01050ea:	b8 00 00 00 00       	mov    $0x0,%eax
f01050ef:	0f 49 c1             	cmovns %ecx,%eax
f01050f2:	29 c1                	sub    %eax,%ecx
f01050f4:	89 75 08             	mov    %esi,0x8(%ebp)
f01050f7:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01050fa:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01050fd:	89 cb                	mov    %ecx,%ebx
f01050ff:	eb 4d                	jmp    f010514e <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0105101:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0105105:	74 1b                	je     f0105122 <vprintfmt+0x21f>
f0105107:	0f be c0             	movsbl %al,%eax
f010510a:	83 e8 20             	sub    $0x20,%eax
f010510d:	83 f8 5e             	cmp    $0x5e,%eax
f0105110:	76 10                	jbe    f0105122 <vprintfmt+0x21f>
					putch('?', putdat);
f0105112:	83 ec 08             	sub    $0x8,%esp
f0105115:	ff 75 0c             	pushl  0xc(%ebp)
f0105118:	6a 3f                	push   $0x3f
f010511a:	ff 55 08             	call   *0x8(%ebp)
f010511d:	83 c4 10             	add    $0x10,%esp
f0105120:	eb 0d                	jmp    f010512f <vprintfmt+0x22c>
				else
					putch(ch, putdat);
f0105122:	83 ec 08             	sub    $0x8,%esp
f0105125:	ff 75 0c             	pushl  0xc(%ebp)
f0105128:	52                   	push   %edx
f0105129:	ff 55 08             	call   *0x8(%ebp)
f010512c:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010512f:	83 eb 01             	sub    $0x1,%ebx
f0105132:	eb 1a                	jmp    f010514e <vprintfmt+0x24b>
f0105134:	89 75 08             	mov    %esi,0x8(%ebp)
f0105137:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010513a:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010513d:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0105140:	eb 0c                	jmp    f010514e <vprintfmt+0x24b>
f0105142:	89 75 08             	mov    %esi,0x8(%ebp)
f0105145:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0105148:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010514b:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010514e:	83 c7 01             	add    $0x1,%edi
f0105151:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0105155:	0f be d0             	movsbl %al,%edx
f0105158:	85 d2                	test   %edx,%edx
f010515a:	74 23                	je     f010517f <vprintfmt+0x27c>
f010515c:	85 f6                	test   %esi,%esi
f010515e:	78 a1                	js     f0105101 <vprintfmt+0x1fe>
f0105160:	83 ee 01             	sub    $0x1,%esi
f0105163:	79 9c                	jns    f0105101 <vprintfmt+0x1fe>
f0105165:	89 df                	mov    %ebx,%edi
f0105167:	8b 75 08             	mov    0x8(%ebp),%esi
f010516a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010516d:	eb 18                	jmp    f0105187 <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f010516f:	83 ec 08             	sub    $0x8,%esp
f0105172:	53                   	push   %ebx
f0105173:	6a 20                	push   $0x20
f0105175:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0105177:	83 ef 01             	sub    $0x1,%edi
f010517a:	83 c4 10             	add    $0x10,%esp
f010517d:	eb 08                	jmp    f0105187 <vprintfmt+0x284>
f010517f:	89 df                	mov    %ebx,%edi
f0105181:	8b 75 08             	mov    0x8(%ebp),%esi
f0105184:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0105187:	85 ff                	test   %edi,%edi
f0105189:	7f e4                	jg     f010516f <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f010518b:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010518e:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0105191:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0105194:	e9 90 fd ff ff       	jmp    f0104f29 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0105199:	83 f9 01             	cmp    $0x1,%ecx
f010519c:	7e 19                	jle    f01051b7 <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
f010519e:	8b 45 14             	mov    0x14(%ebp),%eax
f01051a1:	8b 50 04             	mov    0x4(%eax),%edx
f01051a4:	8b 00                	mov    (%eax),%eax
f01051a6:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01051a9:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01051ac:	8b 45 14             	mov    0x14(%ebp),%eax
f01051af:	8d 40 08             	lea    0x8(%eax),%eax
f01051b2:	89 45 14             	mov    %eax,0x14(%ebp)
f01051b5:	eb 38                	jmp    f01051ef <vprintfmt+0x2ec>
	else if (lflag)
f01051b7:	85 c9                	test   %ecx,%ecx
f01051b9:	74 1b                	je     f01051d6 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
f01051bb:	8b 45 14             	mov    0x14(%ebp),%eax
f01051be:	8b 00                	mov    (%eax),%eax
f01051c0:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01051c3:	89 c1                	mov    %eax,%ecx
f01051c5:	c1 f9 1f             	sar    $0x1f,%ecx
f01051c8:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01051cb:	8b 45 14             	mov    0x14(%ebp),%eax
f01051ce:	8d 40 04             	lea    0x4(%eax),%eax
f01051d1:	89 45 14             	mov    %eax,0x14(%ebp)
f01051d4:	eb 19                	jmp    f01051ef <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
f01051d6:	8b 45 14             	mov    0x14(%ebp),%eax
f01051d9:	8b 00                	mov    (%eax),%eax
f01051db:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01051de:	89 c1                	mov    %eax,%ecx
f01051e0:	c1 f9 1f             	sar    $0x1f,%ecx
f01051e3:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01051e6:	8b 45 14             	mov    0x14(%ebp),%eax
f01051e9:	8d 40 04             	lea    0x4(%eax),%eax
f01051ec:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01051ef:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01051f2:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01051f5:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01051fa:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01051fe:	0f 89 0e 01 00 00    	jns    f0105312 <vprintfmt+0x40f>
				putch('-', putdat);
f0105204:	83 ec 08             	sub    $0x8,%esp
f0105207:	53                   	push   %ebx
f0105208:	6a 2d                	push   $0x2d
f010520a:	ff d6                	call   *%esi
				num = -(long long) num;
f010520c:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010520f:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0105212:	f7 da                	neg    %edx
f0105214:	83 d1 00             	adc    $0x0,%ecx
f0105217:	f7 d9                	neg    %ecx
f0105219:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f010521c:	b8 0a 00 00 00       	mov    $0xa,%eax
f0105221:	e9 ec 00 00 00       	jmp    f0105312 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0105226:	83 f9 01             	cmp    $0x1,%ecx
f0105229:	7e 18                	jle    f0105243 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
f010522b:	8b 45 14             	mov    0x14(%ebp),%eax
f010522e:	8b 10                	mov    (%eax),%edx
f0105230:	8b 48 04             	mov    0x4(%eax),%ecx
f0105233:	8d 40 08             	lea    0x8(%eax),%eax
f0105236:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0105239:	b8 0a 00 00 00       	mov    $0xa,%eax
f010523e:	e9 cf 00 00 00       	jmp    f0105312 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0105243:	85 c9                	test   %ecx,%ecx
f0105245:	74 1a                	je     f0105261 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
f0105247:	8b 45 14             	mov    0x14(%ebp),%eax
f010524a:	8b 10                	mov    (%eax),%edx
f010524c:	b9 00 00 00 00       	mov    $0x0,%ecx
f0105251:	8d 40 04             	lea    0x4(%eax),%eax
f0105254:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0105257:	b8 0a 00 00 00       	mov    $0xa,%eax
f010525c:	e9 b1 00 00 00       	jmp    f0105312 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0105261:	8b 45 14             	mov    0x14(%ebp),%eax
f0105264:	8b 10                	mov    (%eax),%edx
f0105266:	b9 00 00 00 00       	mov    $0x0,%ecx
f010526b:	8d 40 04             	lea    0x4(%eax),%eax
f010526e:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0105271:	b8 0a 00 00 00       	mov    $0xa,%eax
f0105276:	e9 97 00 00 00       	jmp    f0105312 <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f010527b:	83 ec 08             	sub    $0x8,%esp
f010527e:	53                   	push   %ebx
f010527f:	6a 58                	push   $0x58
f0105281:	ff d6                	call   *%esi
			putch('X', putdat);
f0105283:	83 c4 08             	add    $0x8,%esp
f0105286:	53                   	push   %ebx
f0105287:	6a 58                	push   $0x58
f0105289:	ff d6                	call   *%esi
			putch('X', putdat);
f010528b:	83 c4 08             	add    $0x8,%esp
f010528e:	53                   	push   %ebx
f010528f:	6a 58                	push   $0x58
f0105291:	ff d6                	call   *%esi
			break;
f0105293:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0105296:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f0105299:	e9 8b fc ff ff       	jmp    f0104f29 <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
f010529e:	83 ec 08             	sub    $0x8,%esp
f01052a1:	53                   	push   %ebx
f01052a2:	6a 30                	push   $0x30
f01052a4:	ff d6                	call   *%esi
			putch('x', putdat);
f01052a6:	83 c4 08             	add    $0x8,%esp
f01052a9:	53                   	push   %ebx
f01052aa:	6a 78                	push   $0x78
f01052ac:	ff d6                	call   *%esi
			num = (unsigned long long)
f01052ae:	8b 45 14             	mov    0x14(%ebp),%eax
f01052b1:	8b 10                	mov    (%eax),%edx
f01052b3:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f01052b8:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01052bb:	8d 40 04             	lea    0x4(%eax),%eax
f01052be:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01052c1:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f01052c6:	eb 4a                	jmp    f0105312 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01052c8:	83 f9 01             	cmp    $0x1,%ecx
f01052cb:	7e 15                	jle    f01052e2 <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
f01052cd:	8b 45 14             	mov    0x14(%ebp),%eax
f01052d0:	8b 10                	mov    (%eax),%edx
f01052d2:	8b 48 04             	mov    0x4(%eax),%ecx
f01052d5:	8d 40 08             	lea    0x8(%eax),%eax
f01052d8:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f01052db:	b8 10 00 00 00       	mov    $0x10,%eax
f01052e0:	eb 30                	jmp    f0105312 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f01052e2:	85 c9                	test   %ecx,%ecx
f01052e4:	74 17                	je     f01052fd <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
f01052e6:	8b 45 14             	mov    0x14(%ebp),%eax
f01052e9:	8b 10                	mov    (%eax),%edx
f01052eb:	b9 00 00 00 00       	mov    $0x0,%ecx
f01052f0:	8d 40 04             	lea    0x4(%eax),%eax
f01052f3:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f01052f6:	b8 10 00 00 00       	mov    $0x10,%eax
f01052fb:	eb 15                	jmp    f0105312 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f01052fd:	8b 45 14             	mov    0x14(%ebp),%eax
f0105300:	8b 10                	mov    (%eax),%edx
f0105302:	b9 00 00 00 00       	mov    $0x0,%ecx
f0105307:	8d 40 04             	lea    0x4(%eax),%eax
f010530a:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f010530d:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0105312:	83 ec 0c             	sub    $0xc,%esp
f0105315:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0105319:	57                   	push   %edi
f010531a:	ff 75 e0             	pushl  -0x20(%ebp)
f010531d:	50                   	push   %eax
f010531e:	51                   	push   %ecx
f010531f:	52                   	push   %edx
f0105320:	89 da                	mov    %ebx,%edx
f0105322:	89 f0                	mov    %esi,%eax
f0105324:	e8 f1 fa ff ff       	call   f0104e1a <printnum>
			break;
f0105329:	83 c4 20             	add    $0x20,%esp
f010532c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010532f:	e9 f5 fb ff ff       	jmp    f0104f29 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0105334:	83 ec 08             	sub    $0x8,%esp
f0105337:	53                   	push   %ebx
f0105338:	52                   	push   %edx
f0105339:	ff d6                	call   *%esi
			break;
f010533b:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010533e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0105341:	e9 e3 fb ff ff       	jmp    f0104f29 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0105346:	83 ec 08             	sub    $0x8,%esp
f0105349:	53                   	push   %ebx
f010534a:	6a 25                	push   $0x25
f010534c:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f010534e:	83 c4 10             	add    $0x10,%esp
f0105351:	eb 03                	jmp    f0105356 <vprintfmt+0x453>
f0105353:	83 ef 01             	sub    $0x1,%edi
f0105356:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f010535a:	75 f7                	jne    f0105353 <vprintfmt+0x450>
f010535c:	e9 c8 fb ff ff       	jmp    f0104f29 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0105361:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105364:	5b                   	pop    %ebx
f0105365:	5e                   	pop    %esi
f0105366:	5f                   	pop    %edi
f0105367:	5d                   	pop    %ebp
f0105368:	c3                   	ret    

f0105369 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0105369:	55                   	push   %ebp
f010536a:	89 e5                	mov    %esp,%ebp
f010536c:	83 ec 18             	sub    $0x18,%esp
f010536f:	8b 45 08             	mov    0x8(%ebp),%eax
f0105372:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0105375:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0105378:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010537c:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010537f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0105386:	85 c0                	test   %eax,%eax
f0105388:	74 26                	je     f01053b0 <vsnprintf+0x47>
f010538a:	85 d2                	test   %edx,%edx
f010538c:	7e 22                	jle    f01053b0 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010538e:	ff 75 14             	pushl  0x14(%ebp)
f0105391:	ff 75 10             	pushl  0x10(%ebp)
f0105394:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0105397:	50                   	push   %eax
f0105398:	68 c9 4e 10 f0       	push   $0xf0104ec9
f010539d:	e8 61 fb ff ff       	call   f0104f03 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01053a2:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01053a5:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01053a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01053ab:	83 c4 10             	add    $0x10,%esp
f01053ae:	eb 05                	jmp    f01053b5 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01053b0:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01053b5:	c9                   	leave  
f01053b6:	c3                   	ret    

f01053b7 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01053b7:	55                   	push   %ebp
f01053b8:	89 e5                	mov    %esp,%ebp
f01053ba:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01053bd:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01053c0:	50                   	push   %eax
f01053c1:	ff 75 10             	pushl  0x10(%ebp)
f01053c4:	ff 75 0c             	pushl  0xc(%ebp)
f01053c7:	ff 75 08             	pushl  0x8(%ebp)
f01053ca:	e8 9a ff ff ff       	call   f0105369 <vsnprintf>
	va_end(ap);

	return rc;
}
f01053cf:	c9                   	leave  
f01053d0:	c3                   	ret    

f01053d1 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01053d1:	55                   	push   %ebp
f01053d2:	89 e5                	mov    %esp,%ebp
f01053d4:	57                   	push   %edi
f01053d5:	56                   	push   %esi
f01053d6:	53                   	push   %ebx
f01053d7:	83 ec 0c             	sub    $0xc,%esp
f01053da:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01053dd:	85 c0                	test   %eax,%eax
f01053df:	74 11                	je     f01053f2 <readline+0x21>
		cprintf("%s", prompt);
f01053e1:	83 ec 08             	sub    $0x8,%esp
f01053e4:	50                   	push   %eax
f01053e5:	68 aa 68 10 f0       	push   $0xf01068aa
f01053ea:	e8 35 e3 ff ff       	call   f0103724 <cprintf>
f01053ef:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01053f2:	83 ec 0c             	sub    $0xc,%esp
f01053f5:	6a 00                	push   $0x0
f01053f7:	e8 7b b3 ff ff       	call   f0100777 <iscons>
f01053fc:	89 c7                	mov    %eax,%edi
f01053fe:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0105401:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0105406:	e8 5b b3 ff ff       	call   f0100766 <getchar>
f010540b:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010540d:	85 c0                	test   %eax,%eax
f010540f:	79 18                	jns    f0105429 <readline+0x58>
			cprintf("read error: %e\n", c);
f0105411:	83 ec 08             	sub    $0x8,%esp
f0105414:	50                   	push   %eax
f0105415:	68 68 7c 10 f0       	push   $0xf0107c68
f010541a:	e8 05 e3 ff ff       	call   f0103724 <cprintf>
			return NULL;
f010541f:	83 c4 10             	add    $0x10,%esp
f0105422:	b8 00 00 00 00       	mov    $0x0,%eax
f0105427:	eb 79                	jmp    f01054a2 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0105429:	83 f8 08             	cmp    $0x8,%eax
f010542c:	0f 94 c2             	sete   %dl
f010542f:	83 f8 7f             	cmp    $0x7f,%eax
f0105432:	0f 94 c0             	sete   %al
f0105435:	08 c2                	or     %al,%dl
f0105437:	74 1a                	je     f0105453 <readline+0x82>
f0105439:	85 f6                	test   %esi,%esi
f010543b:	7e 16                	jle    f0105453 <readline+0x82>
			if (echoing)
f010543d:	85 ff                	test   %edi,%edi
f010543f:	74 0d                	je     f010544e <readline+0x7d>
				cputchar('\b');
f0105441:	83 ec 0c             	sub    $0xc,%esp
f0105444:	6a 08                	push   $0x8
f0105446:	e8 0b b3 ff ff       	call   f0100756 <cputchar>
f010544b:	83 c4 10             	add    $0x10,%esp
			i--;
f010544e:	83 ee 01             	sub    $0x1,%esi
f0105451:	eb b3                	jmp    f0105406 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0105453:	83 fb 1f             	cmp    $0x1f,%ebx
f0105456:	7e 23                	jle    f010547b <readline+0xaa>
f0105458:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010545e:	7f 1b                	jg     f010547b <readline+0xaa>
			if (echoing)
f0105460:	85 ff                	test   %edi,%edi
f0105462:	74 0c                	je     f0105470 <readline+0x9f>
				cputchar(c);
f0105464:	83 ec 0c             	sub    $0xc,%esp
f0105467:	53                   	push   %ebx
f0105468:	e8 e9 b2 ff ff       	call   f0100756 <cputchar>
f010546d:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0105470:	88 9e 80 fa 22 f0    	mov    %bl,-0xfdd0580(%esi)
f0105476:	8d 76 01             	lea    0x1(%esi),%esi
f0105479:	eb 8b                	jmp    f0105406 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f010547b:	83 fb 0a             	cmp    $0xa,%ebx
f010547e:	74 05                	je     f0105485 <readline+0xb4>
f0105480:	83 fb 0d             	cmp    $0xd,%ebx
f0105483:	75 81                	jne    f0105406 <readline+0x35>
			if (echoing)
f0105485:	85 ff                	test   %edi,%edi
f0105487:	74 0d                	je     f0105496 <readline+0xc5>
				cputchar('\n');
f0105489:	83 ec 0c             	sub    $0xc,%esp
f010548c:	6a 0a                	push   $0xa
f010548e:	e8 c3 b2 ff ff       	call   f0100756 <cputchar>
f0105493:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0105496:	c6 86 80 fa 22 f0 00 	movb   $0x0,-0xfdd0580(%esi)
			return buf;
f010549d:	b8 80 fa 22 f0       	mov    $0xf022fa80,%eax
		}
	}
}
f01054a2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01054a5:	5b                   	pop    %ebx
f01054a6:	5e                   	pop    %esi
f01054a7:	5f                   	pop    %edi
f01054a8:	5d                   	pop    %ebp
f01054a9:	c3                   	ret    

f01054aa <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01054aa:	55                   	push   %ebp
f01054ab:	89 e5                	mov    %esp,%ebp
f01054ad:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01054b0:	b8 00 00 00 00       	mov    $0x0,%eax
f01054b5:	eb 03                	jmp    f01054ba <strlen+0x10>
		n++;
f01054b7:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01054ba:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01054be:	75 f7                	jne    f01054b7 <strlen+0xd>
		n++;
	return n;
}
f01054c0:	5d                   	pop    %ebp
f01054c1:	c3                   	ret    

f01054c2 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01054c2:	55                   	push   %ebp
f01054c3:	89 e5                	mov    %esp,%ebp
f01054c5:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01054c8:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01054cb:	ba 00 00 00 00       	mov    $0x0,%edx
f01054d0:	eb 03                	jmp    f01054d5 <strnlen+0x13>
		n++;
f01054d2:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01054d5:	39 c2                	cmp    %eax,%edx
f01054d7:	74 08                	je     f01054e1 <strnlen+0x1f>
f01054d9:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f01054dd:	75 f3                	jne    f01054d2 <strnlen+0x10>
f01054df:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f01054e1:	5d                   	pop    %ebp
f01054e2:	c3                   	ret    

f01054e3 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01054e3:	55                   	push   %ebp
f01054e4:	89 e5                	mov    %esp,%ebp
f01054e6:	53                   	push   %ebx
f01054e7:	8b 45 08             	mov    0x8(%ebp),%eax
f01054ea:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01054ed:	89 c2                	mov    %eax,%edx
f01054ef:	83 c2 01             	add    $0x1,%edx
f01054f2:	83 c1 01             	add    $0x1,%ecx
f01054f5:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01054f9:	88 5a ff             	mov    %bl,-0x1(%edx)
f01054fc:	84 db                	test   %bl,%bl
f01054fe:	75 ef                	jne    f01054ef <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0105500:	5b                   	pop    %ebx
f0105501:	5d                   	pop    %ebp
f0105502:	c3                   	ret    

f0105503 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0105503:	55                   	push   %ebp
f0105504:	89 e5                	mov    %esp,%ebp
f0105506:	53                   	push   %ebx
f0105507:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f010550a:	53                   	push   %ebx
f010550b:	e8 9a ff ff ff       	call   f01054aa <strlen>
f0105510:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0105513:	ff 75 0c             	pushl  0xc(%ebp)
f0105516:	01 d8                	add    %ebx,%eax
f0105518:	50                   	push   %eax
f0105519:	e8 c5 ff ff ff       	call   f01054e3 <strcpy>
	return dst;
}
f010551e:	89 d8                	mov    %ebx,%eax
f0105520:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0105523:	c9                   	leave  
f0105524:	c3                   	ret    

f0105525 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0105525:	55                   	push   %ebp
f0105526:	89 e5                	mov    %esp,%ebp
f0105528:	56                   	push   %esi
f0105529:	53                   	push   %ebx
f010552a:	8b 75 08             	mov    0x8(%ebp),%esi
f010552d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0105530:	89 f3                	mov    %esi,%ebx
f0105532:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0105535:	89 f2                	mov    %esi,%edx
f0105537:	eb 0f                	jmp    f0105548 <strncpy+0x23>
		*dst++ = *src;
f0105539:	83 c2 01             	add    $0x1,%edx
f010553c:	0f b6 01             	movzbl (%ecx),%eax
f010553f:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0105542:	80 39 01             	cmpb   $0x1,(%ecx)
f0105545:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0105548:	39 da                	cmp    %ebx,%edx
f010554a:	75 ed                	jne    f0105539 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f010554c:	89 f0                	mov    %esi,%eax
f010554e:	5b                   	pop    %ebx
f010554f:	5e                   	pop    %esi
f0105550:	5d                   	pop    %ebp
f0105551:	c3                   	ret    

f0105552 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0105552:	55                   	push   %ebp
f0105553:	89 e5                	mov    %esp,%ebp
f0105555:	56                   	push   %esi
f0105556:	53                   	push   %ebx
f0105557:	8b 75 08             	mov    0x8(%ebp),%esi
f010555a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010555d:	8b 55 10             	mov    0x10(%ebp),%edx
f0105560:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0105562:	85 d2                	test   %edx,%edx
f0105564:	74 21                	je     f0105587 <strlcpy+0x35>
f0105566:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f010556a:	89 f2                	mov    %esi,%edx
f010556c:	eb 09                	jmp    f0105577 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010556e:	83 c2 01             	add    $0x1,%edx
f0105571:	83 c1 01             	add    $0x1,%ecx
f0105574:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0105577:	39 c2                	cmp    %eax,%edx
f0105579:	74 09                	je     f0105584 <strlcpy+0x32>
f010557b:	0f b6 19             	movzbl (%ecx),%ebx
f010557e:	84 db                	test   %bl,%bl
f0105580:	75 ec                	jne    f010556e <strlcpy+0x1c>
f0105582:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0105584:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0105587:	29 f0                	sub    %esi,%eax
}
f0105589:	5b                   	pop    %ebx
f010558a:	5e                   	pop    %esi
f010558b:	5d                   	pop    %ebp
f010558c:	c3                   	ret    

f010558d <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010558d:	55                   	push   %ebp
f010558e:	89 e5                	mov    %esp,%ebp
f0105590:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105593:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0105596:	eb 06                	jmp    f010559e <strcmp+0x11>
		p++, q++;
f0105598:	83 c1 01             	add    $0x1,%ecx
f010559b:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010559e:	0f b6 01             	movzbl (%ecx),%eax
f01055a1:	84 c0                	test   %al,%al
f01055a3:	74 04                	je     f01055a9 <strcmp+0x1c>
f01055a5:	3a 02                	cmp    (%edx),%al
f01055a7:	74 ef                	je     f0105598 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01055a9:	0f b6 c0             	movzbl %al,%eax
f01055ac:	0f b6 12             	movzbl (%edx),%edx
f01055af:	29 d0                	sub    %edx,%eax
}
f01055b1:	5d                   	pop    %ebp
f01055b2:	c3                   	ret    

f01055b3 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01055b3:	55                   	push   %ebp
f01055b4:	89 e5                	mov    %esp,%ebp
f01055b6:	53                   	push   %ebx
f01055b7:	8b 45 08             	mov    0x8(%ebp),%eax
f01055ba:	8b 55 0c             	mov    0xc(%ebp),%edx
f01055bd:	89 c3                	mov    %eax,%ebx
f01055bf:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01055c2:	eb 06                	jmp    f01055ca <strncmp+0x17>
		n--, p++, q++;
f01055c4:	83 c0 01             	add    $0x1,%eax
f01055c7:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01055ca:	39 d8                	cmp    %ebx,%eax
f01055cc:	74 15                	je     f01055e3 <strncmp+0x30>
f01055ce:	0f b6 08             	movzbl (%eax),%ecx
f01055d1:	84 c9                	test   %cl,%cl
f01055d3:	74 04                	je     f01055d9 <strncmp+0x26>
f01055d5:	3a 0a                	cmp    (%edx),%cl
f01055d7:	74 eb                	je     f01055c4 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01055d9:	0f b6 00             	movzbl (%eax),%eax
f01055dc:	0f b6 12             	movzbl (%edx),%edx
f01055df:	29 d0                	sub    %edx,%eax
f01055e1:	eb 05                	jmp    f01055e8 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01055e3:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01055e8:	5b                   	pop    %ebx
f01055e9:	5d                   	pop    %ebp
f01055ea:	c3                   	ret    

f01055eb <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01055eb:	55                   	push   %ebp
f01055ec:	89 e5                	mov    %esp,%ebp
f01055ee:	8b 45 08             	mov    0x8(%ebp),%eax
f01055f1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01055f5:	eb 07                	jmp    f01055fe <strchr+0x13>
		if (*s == c)
f01055f7:	38 ca                	cmp    %cl,%dl
f01055f9:	74 0f                	je     f010560a <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01055fb:	83 c0 01             	add    $0x1,%eax
f01055fe:	0f b6 10             	movzbl (%eax),%edx
f0105601:	84 d2                	test   %dl,%dl
f0105603:	75 f2                	jne    f01055f7 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0105605:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010560a:	5d                   	pop    %ebp
f010560b:	c3                   	ret    

f010560c <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010560c:	55                   	push   %ebp
f010560d:	89 e5                	mov    %esp,%ebp
f010560f:	8b 45 08             	mov    0x8(%ebp),%eax
f0105612:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105616:	eb 03                	jmp    f010561b <strfind+0xf>
f0105618:	83 c0 01             	add    $0x1,%eax
f010561b:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f010561e:	38 ca                	cmp    %cl,%dl
f0105620:	74 04                	je     f0105626 <strfind+0x1a>
f0105622:	84 d2                	test   %dl,%dl
f0105624:	75 f2                	jne    f0105618 <strfind+0xc>
			break;
	return (char *) s;
}
f0105626:	5d                   	pop    %ebp
f0105627:	c3                   	ret    

f0105628 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0105628:	55                   	push   %ebp
f0105629:	89 e5                	mov    %esp,%ebp
f010562b:	57                   	push   %edi
f010562c:	56                   	push   %esi
f010562d:	53                   	push   %ebx
f010562e:	8b 7d 08             	mov    0x8(%ebp),%edi
f0105631:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0105634:	85 c9                	test   %ecx,%ecx
f0105636:	74 36                	je     f010566e <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0105638:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010563e:	75 28                	jne    f0105668 <memset+0x40>
f0105640:	f6 c1 03             	test   $0x3,%cl
f0105643:	75 23                	jne    f0105668 <memset+0x40>
		c &= 0xFF;
f0105645:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0105649:	89 d3                	mov    %edx,%ebx
f010564b:	c1 e3 08             	shl    $0x8,%ebx
f010564e:	89 d6                	mov    %edx,%esi
f0105650:	c1 e6 18             	shl    $0x18,%esi
f0105653:	89 d0                	mov    %edx,%eax
f0105655:	c1 e0 10             	shl    $0x10,%eax
f0105658:	09 f0                	or     %esi,%eax
f010565a:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f010565c:	89 d8                	mov    %ebx,%eax
f010565e:	09 d0                	or     %edx,%eax
f0105660:	c1 e9 02             	shr    $0x2,%ecx
f0105663:	fc                   	cld    
f0105664:	f3 ab                	rep stos %eax,%es:(%edi)
f0105666:	eb 06                	jmp    f010566e <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0105668:	8b 45 0c             	mov    0xc(%ebp),%eax
f010566b:	fc                   	cld    
f010566c:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010566e:	89 f8                	mov    %edi,%eax
f0105670:	5b                   	pop    %ebx
f0105671:	5e                   	pop    %esi
f0105672:	5f                   	pop    %edi
f0105673:	5d                   	pop    %ebp
f0105674:	c3                   	ret    

f0105675 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0105675:	55                   	push   %ebp
f0105676:	89 e5                	mov    %esp,%ebp
f0105678:	57                   	push   %edi
f0105679:	56                   	push   %esi
f010567a:	8b 45 08             	mov    0x8(%ebp),%eax
f010567d:	8b 75 0c             	mov    0xc(%ebp),%esi
f0105680:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0105683:	39 c6                	cmp    %eax,%esi
f0105685:	73 35                	jae    f01056bc <memmove+0x47>
f0105687:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010568a:	39 d0                	cmp    %edx,%eax
f010568c:	73 2e                	jae    f01056bc <memmove+0x47>
		s += n;
		d += n;
f010568e:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0105691:	89 d6                	mov    %edx,%esi
f0105693:	09 fe                	or     %edi,%esi
f0105695:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010569b:	75 13                	jne    f01056b0 <memmove+0x3b>
f010569d:	f6 c1 03             	test   $0x3,%cl
f01056a0:	75 0e                	jne    f01056b0 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f01056a2:	83 ef 04             	sub    $0x4,%edi
f01056a5:	8d 72 fc             	lea    -0x4(%edx),%esi
f01056a8:	c1 e9 02             	shr    $0x2,%ecx
f01056ab:	fd                   	std    
f01056ac:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01056ae:	eb 09                	jmp    f01056b9 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01056b0:	83 ef 01             	sub    $0x1,%edi
f01056b3:	8d 72 ff             	lea    -0x1(%edx),%esi
f01056b6:	fd                   	std    
f01056b7:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01056b9:	fc                   	cld    
f01056ba:	eb 1d                	jmp    f01056d9 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01056bc:	89 f2                	mov    %esi,%edx
f01056be:	09 c2                	or     %eax,%edx
f01056c0:	f6 c2 03             	test   $0x3,%dl
f01056c3:	75 0f                	jne    f01056d4 <memmove+0x5f>
f01056c5:	f6 c1 03             	test   $0x3,%cl
f01056c8:	75 0a                	jne    f01056d4 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f01056ca:	c1 e9 02             	shr    $0x2,%ecx
f01056cd:	89 c7                	mov    %eax,%edi
f01056cf:	fc                   	cld    
f01056d0:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01056d2:	eb 05                	jmp    f01056d9 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01056d4:	89 c7                	mov    %eax,%edi
f01056d6:	fc                   	cld    
f01056d7:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01056d9:	5e                   	pop    %esi
f01056da:	5f                   	pop    %edi
f01056db:	5d                   	pop    %ebp
f01056dc:	c3                   	ret    

f01056dd <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01056dd:	55                   	push   %ebp
f01056de:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01056e0:	ff 75 10             	pushl  0x10(%ebp)
f01056e3:	ff 75 0c             	pushl  0xc(%ebp)
f01056e6:	ff 75 08             	pushl  0x8(%ebp)
f01056e9:	e8 87 ff ff ff       	call   f0105675 <memmove>
}
f01056ee:	c9                   	leave  
f01056ef:	c3                   	ret    

f01056f0 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01056f0:	55                   	push   %ebp
f01056f1:	89 e5                	mov    %esp,%ebp
f01056f3:	56                   	push   %esi
f01056f4:	53                   	push   %ebx
f01056f5:	8b 45 08             	mov    0x8(%ebp),%eax
f01056f8:	8b 55 0c             	mov    0xc(%ebp),%edx
f01056fb:	89 c6                	mov    %eax,%esi
f01056fd:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0105700:	eb 1a                	jmp    f010571c <memcmp+0x2c>
		if (*s1 != *s2)
f0105702:	0f b6 08             	movzbl (%eax),%ecx
f0105705:	0f b6 1a             	movzbl (%edx),%ebx
f0105708:	38 d9                	cmp    %bl,%cl
f010570a:	74 0a                	je     f0105716 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f010570c:	0f b6 c1             	movzbl %cl,%eax
f010570f:	0f b6 db             	movzbl %bl,%ebx
f0105712:	29 d8                	sub    %ebx,%eax
f0105714:	eb 0f                	jmp    f0105725 <memcmp+0x35>
		s1++, s2++;
f0105716:	83 c0 01             	add    $0x1,%eax
f0105719:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010571c:	39 f0                	cmp    %esi,%eax
f010571e:	75 e2                	jne    f0105702 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0105720:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105725:	5b                   	pop    %ebx
f0105726:	5e                   	pop    %esi
f0105727:	5d                   	pop    %ebp
f0105728:	c3                   	ret    

f0105729 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0105729:	55                   	push   %ebp
f010572a:	89 e5                	mov    %esp,%ebp
f010572c:	53                   	push   %ebx
f010572d:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0105730:	89 c1                	mov    %eax,%ecx
f0105732:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0105735:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0105739:	eb 0a                	jmp    f0105745 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f010573b:	0f b6 10             	movzbl (%eax),%edx
f010573e:	39 da                	cmp    %ebx,%edx
f0105740:	74 07                	je     f0105749 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0105742:	83 c0 01             	add    $0x1,%eax
f0105745:	39 c8                	cmp    %ecx,%eax
f0105747:	72 f2                	jb     f010573b <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0105749:	5b                   	pop    %ebx
f010574a:	5d                   	pop    %ebp
f010574b:	c3                   	ret    

f010574c <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010574c:	55                   	push   %ebp
f010574d:	89 e5                	mov    %esp,%ebp
f010574f:	57                   	push   %edi
f0105750:	56                   	push   %esi
f0105751:	53                   	push   %ebx
f0105752:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105755:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0105758:	eb 03                	jmp    f010575d <strtol+0x11>
		s++;
f010575a:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010575d:	0f b6 01             	movzbl (%ecx),%eax
f0105760:	3c 20                	cmp    $0x20,%al
f0105762:	74 f6                	je     f010575a <strtol+0xe>
f0105764:	3c 09                	cmp    $0x9,%al
f0105766:	74 f2                	je     f010575a <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0105768:	3c 2b                	cmp    $0x2b,%al
f010576a:	75 0a                	jne    f0105776 <strtol+0x2a>
		s++;
f010576c:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f010576f:	bf 00 00 00 00       	mov    $0x0,%edi
f0105774:	eb 11                	jmp    f0105787 <strtol+0x3b>
f0105776:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f010577b:	3c 2d                	cmp    $0x2d,%al
f010577d:	75 08                	jne    f0105787 <strtol+0x3b>
		s++, neg = 1;
f010577f:	83 c1 01             	add    $0x1,%ecx
f0105782:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0105787:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f010578d:	75 15                	jne    f01057a4 <strtol+0x58>
f010578f:	80 39 30             	cmpb   $0x30,(%ecx)
f0105792:	75 10                	jne    f01057a4 <strtol+0x58>
f0105794:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0105798:	75 7c                	jne    f0105816 <strtol+0xca>
		s += 2, base = 16;
f010579a:	83 c1 02             	add    $0x2,%ecx
f010579d:	bb 10 00 00 00       	mov    $0x10,%ebx
f01057a2:	eb 16                	jmp    f01057ba <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f01057a4:	85 db                	test   %ebx,%ebx
f01057a6:	75 12                	jne    f01057ba <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01057a8:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01057ad:	80 39 30             	cmpb   $0x30,(%ecx)
f01057b0:	75 08                	jne    f01057ba <strtol+0x6e>
		s++, base = 8;
f01057b2:	83 c1 01             	add    $0x1,%ecx
f01057b5:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01057ba:	b8 00 00 00 00       	mov    $0x0,%eax
f01057bf:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01057c2:	0f b6 11             	movzbl (%ecx),%edx
f01057c5:	8d 72 d0             	lea    -0x30(%edx),%esi
f01057c8:	89 f3                	mov    %esi,%ebx
f01057ca:	80 fb 09             	cmp    $0x9,%bl
f01057cd:	77 08                	ja     f01057d7 <strtol+0x8b>
			dig = *s - '0';
f01057cf:	0f be d2             	movsbl %dl,%edx
f01057d2:	83 ea 30             	sub    $0x30,%edx
f01057d5:	eb 22                	jmp    f01057f9 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f01057d7:	8d 72 9f             	lea    -0x61(%edx),%esi
f01057da:	89 f3                	mov    %esi,%ebx
f01057dc:	80 fb 19             	cmp    $0x19,%bl
f01057df:	77 08                	ja     f01057e9 <strtol+0x9d>
			dig = *s - 'a' + 10;
f01057e1:	0f be d2             	movsbl %dl,%edx
f01057e4:	83 ea 57             	sub    $0x57,%edx
f01057e7:	eb 10                	jmp    f01057f9 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f01057e9:	8d 72 bf             	lea    -0x41(%edx),%esi
f01057ec:	89 f3                	mov    %esi,%ebx
f01057ee:	80 fb 19             	cmp    $0x19,%bl
f01057f1:	77 16                	ja     f0105809 <strtol+0xbd>
			dig = *s - 'A' + 10;
f01057f3:	0f be d2             	movsbl %dl,%edx
f01057f6:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f01057f9:	3b 55 10             	cmp    0x10(%ebp),%edx
f01057fc:	7d 0b                	jge    f0105809 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f01057fe:	83 c1 01             	add    $0x1,%ecx
f0105801:	0f af 45 10          	imul   0x10(%ebp),%eax
f0105805:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0105807:	eb b9                	jmp    f01057c2 <strtol+0x76>

	if (endptr)
f0105809:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010580d:	74 0d                	je     f010581c <strtol+0xd0>
		*endptr = (char *) s;
f010580f:	8b 75 0c             	mov    0xc(%ebp),%esi
f0105812:	89 0e                	mov    %ecx,(%esi)
f0105814:	eb 06                	jmp    f010581c <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0105816:	85 db                	test   %ebx,%ebx
f0105818:	74 98                	je     f01057b2 <strtol+0x66>
f010581a:	eb 9e                	jmp    f01057ba <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f010581c:	89 c2                	mov    %eax,%edx
f010581e:	f7 da                	neg    %edx
f0105820:	85 ff                	test   %edi,%edi
f0105822:	0f 45 c2             	cmovne %edx,%eax
}
f0105825:	5b                   	pop    %ebx
f0105826:	5e                   	pop    %esi
f0105827:	5f                   	pop    %edi
f0105828:	5d                   	pop    %ebp
f0105829:	c3                   	ret    
f010582a:	66 90                	xchg   %ax,%ax

f010582c <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f010582c:	fa                   	cli    

	xorw    %ax, %ax
f010582d:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f010582f:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0105831:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0105833:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f0105835:	0f 01 16             	lgdtl  (%esi)
f0105838:	74 70                	je     f01058aa <mpsearch1+0x3>
	movl    %cr0, %eax
f010583a:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f010583d:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f0105841:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f0105844:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f010584a:	08 00                	or     %al,(%eax)

f010584c <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f010584c:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f0105850:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0105852:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0105854:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f0105856:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f010585a:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f010585c:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f010585e:	b8 00 e0 11 00       	mov    $0x11e000,%eax
	movl    %eax, %cr3
f0105863:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f0105866:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f0105869:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f010586e:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in boot_aps()
	movl    mpentry_kstack, %esp
f0105871:	8b 25 84 fe 22 f0    	mov    0xf022fe84,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f0105877:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f010587c:	b8 b3 01 10 f0       	mov    $0xf01001b3,%eax
	call    *%eax
f0105881:	ff d0                	call   *%eax

f0105883 <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f0105883:	eb fe                	jmp    f0105883 <spin>
f0105885:	8d 76 00             	lea    0x0(%esi),%esi

f0105888 <gdt>:
	...
f0105890:	ff                   	(bad)  
f0105891:	ff 00                	incl   (%eax)
f0105893:	00 00                	add    %al,(%eax)
f0105895:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f010589c:	00                   	.byte 0x0
f010589d:	92                   	xchg   %eax,%edx
f010589e:	cf                   	iret   
	...

f01058a0 <gdtdesc>:
f01058a0:	17                   	pop    %ss
f01058a1:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f01058a6 <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f01058a6:	90                   	nop

f01058a7 <mpsearch1>:
}

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f01058a7:	55                   	push   %ebp
f01058a8:	89 e5                	mov    %esp,%ebp
f01058aa:	57                   	push   %edi
f01058ab:	56                   	push   %esi
f01058ac:	53                   	push   %ebx
f01058ad:	83 ec 0c             	sub    $0xc,%esp
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01058b0:	8b 0d 88 fe 22 f0    	mov    0xf022fe88,%ecx
f01058b6:	89 c3                	mov    %eax,%ebx
f01058b8:	c1 eb 0c             	shr    $0xc,%ebx
f01058bb:	39 cb                	cmp    %ecx,%ebx
f01058bd:	72 12                	jb     f01058d1 <mpsearch1+0x2a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01058bf:	50                   	push   %eax
f01058c0:	68 04 63 10 f0       	push   $0xf0106304
f01058c5:	6a 57                	push   $0x57
f01058c7:	68 05 7e 10 f0       	push   $0xf0107e05
f01058cc:	e8 6f a7 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01058d1:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
	struct mp *mp = KADDR(a), *end = KADDR(a + len);
f01058d7:	01 d0                	add    %edx,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01058d9:	89 c2                	mov    %eax,%edx
f01058db:	c1 ea 0c             	shr    $0xc,%edx
f01058de:	39 ca                	cmp    %ecx,%edx
f01058e0:	72 12                	jb     f01058f4 <mpsearch1+0x4d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01058e2:	50                   	push   %eax
f01058e3:	68 04 63 10 f0       	push   $0xf0106304
f01058e8:	6a 57                	push   $0x57
f01058ea:	68 05 7e 10 f0       	push   $0xf0107e05
f01058ef:	e8 4c a7 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01058f4:	8d b0 00 00 00 f0    	lea    -0x10000000(%eax),%esi

	for (; mp < end; mp++)
f01058fa:	eb 2f                	jmp    f010592b <mpsearch1+0x84>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f01058fc:	83 ec 04             	sub    $0x4,%esp
f01058ff:	6a 04                	push   $0x4
f0105901:	68 15 7e 10 f0       	push   $0xf0107e15
f0105906:	53                   	push   %ebx
f0105907:	e8 e4 fd ff ff       	call   f01056f0 <memcmp>
f010590c:	83 c4 10             	add    $0x10,%esp
f010590f:	85 c0                	test   %eax,%eax
f0105911:	75 15                	jne    f0105928 <mpsearch1+0x81>
f0105913:	89 da                	mov    %ebx,%edx
f0105915:	8d 7b 10             	lea    0x10(%ebx),%edi
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
		sum += ((uint8_t *)addr)[i];
f0105918:	0f b6 0a             	movzbl (%edx),%ecx
f010591b:	01 c8                	add    %ecx,%eax
f010591d:	83 c2 01             	add    $0x1,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105920:	39 d7                	cmp    %edx,%edi
f0105922:	75 f4                	jne    f0105918 <mpsearch1+0x71>
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0105924:	84 c0                	test   %al,%al
f0105926:	74 0e                	je     f0105936 <mpsearch1+0x8f>
static struct mp *
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
f0105928:	83 c3 10             	add    $0x10,%ebx
f010592b:	39 f3                	cmp    %esi,%ebx
f010592d:	72 cd                	jb     f01058fc <mpsearch1+0x55>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f010592f:	b8 00 00 00 00       	mov    $0x0,%eax
f0105934:	eb 02                	jmp    f0105938 <mpsearch1+0x91>
f0105936:	89 d8                	mov    %ebx,%eax
}
f0105938:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010593b:	5b                   	pop    %ebx
f010593c:	5e                   	pop    %esi
f010593d:	5f                   	pop    %edi
f010593e:	5d                   	pop    %ebp
f010593f:	c3                   	ret    

f0105940 <mp_init>:
	return conf;
}

void
mp_init(void)
{
f0105940:	55                   	push   %ebp
f0105941:	89 e5                	mov    %esp,%ebp
f0105943:	57                   	push   %edi
f0105944:	56                   	push   %esi
f0105945:	53                   	push   %ebx
f0105946:	83 ec 1c             	sub    $0x1c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f0105949:	c7 05 c0 03 23 f0 20 	movl   $0xf0230020,0xf02303c0
f0105950:	00 23 f0 
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105953:	83 3d 88 fe 22 f0 00 	cmpl   $0x0,0xf022fe88
f010595a:	75 16                	jne    f0105972 <mp_init+0x32>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010595c:	68 00 04 00 00       	push   $0x400
f0105961:	68 04 63 10 f0       	push   $0xf0106304
f0105966:	6a 6f                	push   $0x6f
f0105968:	68 05 7e 10 f0       	push   $0xf0107e05
f010596d:	e8 ce a6 ff ff       	call   f0100040 <_panic>
	// The BIOS data area lives in 16-bit segment 0x40.
	bda = (uint8_t *) KADDR(0x40 << 4);

	// [MP 4] The 16-bit segment of the EBDA is in the two bytes
	// starting at byte 0x0E of the BDA.  0 if not present.
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f0105972:	0f b7 05 0e 04 00 f0 	movzwl 0xf000040e,%eax
f0105979:	85 c0                	test   %eax,%eax
f010597b:	74 16                	je     f0105993 <mp_init+0x53>
		p <<= 4;	// Translate from segment to PA
		if ((mp = mpsearch1(p, 1024)))
f010597d:	c1 e0 04             	shl    $0x4,%eax
f0105980:	ba 00 04 00 00       	mov    $0x400,%edx
f0105985:	e8 1d ff ff ff       	call   f01058a7 <mpsearch1>
f010598a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010598d:	85 c0                	test   %eax,%eax
f010598f:	75 3c                	jne    f01059cd <mp_init+0x8d>
f0105991:	eb 20                	jmp    f01059b3 <mp_init+0x73>
			return mp;
	} else {
		// The size of base memory, in KB is in the two bytes
		// starting at 0x13 of the BDA.
		p = *(uint16_t *) (bda + 0x13) * 1024;
		if ((mp = mpsearch1(p - 1024, 1024)))
f0105993:	0f b7 05 13 04 00 f0 	movzwl 0xf0000413,%eax
f010599a:	c1 e0 0a             	shl    $0xa,%eax
f010599d:	2d 00 04 00 00       	sub    $0x400,%eax
f01059a2:	ba 00 04 00 00       	mov    $0x400,%edx
f01059a7:	e8 fb fe ff ff       	call   f01058a7 <mpsearch1>
f01059ac:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01059af:	85 c0                	test   %eax,%eax
f01059b1:	75 1a                	jne    f01059cd <mp_init+0x8d>
			return mp;
	}
	return mpsearch1(0xF0000, 0x10000);
f01059b3:	ba 00 00 01 00       	mov    $0x10000,%edx
f01059b8:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f01059bd:	e8 e5 fe ff ff       	call   f01058a7 <mpsearch1>
f01059c2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
mpconfig(struct mp **pmp)
{
	struct mpconf *conf;
	struct mp *mp;

	if ((mp = mpsearch()) == 0)
f01059c5:	85 c0                	test   %eax,%eax
f01059c7:	0f 84 5d 02 00 00    	je     f0105c2a <mp_init+0x2ea>
		return NULL;
	if (mp->physaddr == 0 || mp->type != 0) {
f01059cd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01059d0:	8b 70 04             	mov    0x4(%eax),%esi
f01059d3:	85 f6                	test   %esi,%esi
f01059d5:	74 06                	je     f01059dd <mp_init+0x9d>
f01059d7:	80 78 0b 00          	cmpb   $0x0,0xb(%eax)
f01059db:	74 15                	je     f01059f2 <mp_init+0xb2>
		cprintf("SMP: Default configurations not implemented\n");
f01059dd:	83 ec 0c             	sub    $0xc,%esp
f01059e0:	68 78 7c 10 f0       	push   $0xf0107c78
f01059e5:	e8 3a dd ff ff       	call   f0103724 <cprintf>
f01059ea:	83 c4 10             	add    $0x10,%esp
f01059ed:	e9 38 02 00 00       	jmp    f0105c2a <mp_init+0x2ea>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01059f2:	89 f0                	mov    %esi,%eax
f01059f4:	c1 e8 0c             	shr    $0xc,%eax
f01059f7:	3b 05 88 fe 22 f0    	cmp    0xf022fe88,%eax
f01059fd:	72 15                	jb     f0105a14 <mp_init+0xd4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01059ff:	56                   	push   %esi
f0105a00:	68 04 63 10 f0       	push   $0xf0106304
f0105a05:	68 90 00 00 00       	push   $0x90
f0105a0a:	68 05 7e 10 f0       	push   $0xf0107e05
f0105a0f:	e8 2c a6 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105a14:	8d 9e 00 00 00 f0    	lea    -0x10000000(%esi),%ebx
		return NULL;
	}
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
f0105a1a:	83 ec 04             	sub    $0x4,%esp
f0105a1d:	6a 04                	push   $0x4
f0105a1f:	68 1a 7e 10 f0       	push   $0xf0107e1a
f0105a24:	53                   	push   %ebx
f0105a25:	e8 c6 fc ff ff       	call   f01056f0 <memcmp>
f0105a2a:	83 c4 10             	add    $0x10,%esp
f0105a2d:	85 c0                	test   %eax,%eax
f0105a2f:	74 15                	je     f0105a46 <mp_init+0x106>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f0105a31:	83 ec 0c             	sub    $0xc,%esp
f0105a34:	68 a8 7c 10 f0       	push   $0xf0107ca8
f0105a39:	e8 e6 dc ff ff       	call   f0103724 <cprintf>
f0105a3e:	83 c4 10             	add    $0x10,%esp
f0105a41:	e9 e4 01 00 00       	jmp    f0105c2a <mp_init+0x2ea>
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f0105a46:	0f b7 43 04          	movzwl 0x4(%ebx),%eax
f0105a4a:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)
f0105a4e:	0f b7 f8             	movzwl %ax,%edi
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f0105a51:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f0105a56:	b8 00 00 00 00       	mov    $0x0,%eax
f0105a5b:	eb 0d                	jmp    f0105a6a <mp_init+0x12a>
		sum += ((uint8_t *)addr)[i];
f0105a5d:	0f b6 8c 30 00 00 00 	movzbl -0x10000000(%eax,%esi,1),%ecx
f0105a64:	f0 
f0105a65:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105a67:	83 c0 01             	add    $0x1,%eax
f0105a6a:	39 c7                	cmp    %eax,%edi
f0105a6c:	75 ef                	jne    f0105a5d <mp_init+0x11d>
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
		cprintf("SMP: Incorrect MP configuration table signature\n");
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f0105a6e:	84 d2                	test   %dl,%dl
f0105a70:	74 15                	je     f0105a87 <mp_init+0x147>
		cprintf("SMP: Bad MP configuration checksum\n");
f0105a72:	83 ec 0c             	sub    $0xc,%esp
f0105a75:	68 dc 7c 10 f0       	push   $0xf0107cdc
f0105a7a:	e8 a5 dc ff ff       	call   f0103724 <cprintf>
f0105a7f:	83 c4 10             	add    $0x10,%esp
f0105a82:	e9 a3 01 00 00       	jmp    f0105c2a <mp_init+0x2ea>
		return NULL;
	}
	if (conf->version != 1 && conf->version != 4) {
f0105a87:	0f b6 43 06          	movzbl 0x6(%ebx),%eax
f0105a8b:	3c 01                	cmp    $0x1,%al
f0105a8d:	74 1d                	je     f0105aac <mp_init+0x16c>
f0105a8f:	3c 04                	cmp    $0x4,%al
f0105a91:	74 19                	je     f0105aac <mp_init+0x16c>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f0105a93:	83 ec 08             	sub    $0x8,%esp
f0105a96:	0f b6 c0             	movzbl %al,%eax
f0105a99:	50                   	push   %eax
f0105a9a:	68 00 7d 10 f0       	push   $0xf0107d00
f0105a9f:	e8 80 dc ff ff       	call   f0103724 <cprintf>
f0105aa4:	83 c4 10             	add    $0x10,%esp
f0105aa7:	e9 7e 01 00 00       	jmp    f0105c2a <mp_init+0x2ea>
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f0105aac:	0f b7 7b 28          	movzwl 0x28(%ebx),%edi
f0105ab0:	0f b7 4d e2          	movzwl -0x1e(%ebp),%ecx
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f0105ab4:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f0105ab9:	b8 00 00 00 00       	mov    $0x0,%eax
		sum += ((uint8_t *)addr)[i];
f0105abe:	01 ce                	add    %ecx,%esi
f0105ac0:	eb 0d                	jmp    f0105acf <mp_init+0x18f>
f0105ac2:	0f b6 8c 06 00 00 00 	movzbl -0x10000000(%esi,%eax,1),%ecx
f0105ac9:	f0 
f0105aca:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105acc:	83 c0 01             	add    $0x1,%eax
f0105acf:	39 c7                	cmp    %eax,%edi
f0105ad1:	75 ef                	jne    f0105ac2 <mp_init+0x182>
	}
	if (conf->version != 1 && conf->version != 4) {
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f0105ad3:	89 d0                	mov    %edx,%eax
f0105ad5:	02 43 2a             	add    0x2a(%ebx),%al
f0105ad8:	74 15                	je     f0105aef <mp_init+0x1af>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f0105ada:	83 ec 0c             	sub    $0xc,%esp
f0105add:	68 20 7d 10 f0       	push   $0xf0107d20
f0105ae2:	e8 3d dc ff ff       	call   f0103724 <cprintf>
f0105ae7:	83 c4 10             	add    $0x10,%esp
f0105aea:	e9 3b 01 00 00       	jmp    f0105c2a <mp_init+0x2ea>
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
	if ((conf = mpconfig(&mp)) == 0)
f0105aef:	85 db                	test   %ebx,%ebx
f0105af1:	0f 84 33 01 00 00    	je     f0105c2a <mp_init+0x2ea>
		return;
	ismp = 1;
f0105af7:	c7 05 00 00 23 f0 01 	movl   $0x1,0xf0230000
f0105afe:	00 00 00 
	lapicaddr = conf->lapicaddr;
f0105b01:	8b 43 24             	mov    0x24(%ebx),%eax
f0105b04:	a3 00 10 27 f0       	mov    %eax,0xf0271000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0105b09:	8d 7b 2c             	lea    0x2c(%ebx),%edi
f0105b0c:	be 00 00 00 00       	mov    $0x0,%esi
f0105b11:	e9 85 00 00 00       	jmp    f0105b9b <mp_init+0x25b>
		switch (*p) {
f0105b16:	0f b6 07             	movzbl (%edi),%eax
f0105b19:	84 c0                	test   %al,%al
f0105b1b:	74 06                	je     f0105b23 <mp_init+0x1e3>
f0105b1d:	3c 04                	cmp    $0x4,%al
f0105b1f:	77 55                	ja     f0105b76 <mp_init+0x236>
f0105b21:	eb 4e                	jmp    f0105b71 <mp_init+0x231>
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f0105b23:	f6 47 03 02          	testb  $0x2,0x3(%edi)
f0105b27:	74 11                	je     f0105b3a <mp_init+0x1fa>
				bootcpu = &cpus[ncpu];
f0105b29:	6b 05 c4 03 23 f0 74 	imul   $0x74,0xf02303c4,%eax
f0105b30:	05 20 00 23 f0       	add    $0xf0230020,%eax
f0105b35:	a3 c0 03 23 f0       	mov    %eax,0xf02303c0
			if (ncpu < NCPU) {
f0105b3a:	a1 c4 03 23 f0       	mov    0xf02303c4,%eax
f0105b3f:	83 f8 07             	cmp    $0x7,%eax
f0105b42:	7f 13                	jg     f0105b57 <mp_init+0x217>
				cpus[ncpu].cpu_id = ncpu;
f0105b44:	6b d0 74             	imul   $0x74,%eax,%edx
f0105b47:	88 82 20 00 23 f0    	mov    %al,-0xfdcffe0(%edx)
				ncpu++;
f0105b4d:	83 c0 01             	add    $0x1,%eax
f0105b50:	a3 c4 03 23 f0       	mov    %eax,0xf02303c4
f0105b55:	eb 15                	jmp    f0105b6c <mp_init+0x22c>
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f0105b57:	83 ec 08             	sub    $0x8,%esp
f0105b5a:	0f b6 47 01          	movzbl 0x1(%edi),%eax
f0105b5e:	50                   	push   %eax
f0105b5f:	68 50 7d 10 f0       	push   $0xf0107d50
f0105b64:	e8 bb db ff ff       	call   f0103724 <cprintf>
f0105b69:	83 c4 10             	add    $0x10,%esp
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f0105b6c:	83 c7 14             	add    $0x14,%edi
			continue;
f0105b6f:	eb 27                	jmp    f0105b98 <mp_init+0x258>
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f0105b71:	83 c7 08             	add    $0x8,%edi
			continue;
f0105b74:	eb 22                	jmp    f0105b98 <mp_init+0x258>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f0105b76:	83 ec 08             	sub    $0x8,%esp
f0105b79:	0f b6 c0             	movzbl %al,%eax
f0105b7c:	50                   	push   %eax
f0105b7d:	68 78 7d 10 f0       	push   $0xf0107d78
f0105b82:	e8 9d db ff ff       	call   f0103724 <cprintf>
			ismp = 0;
f0105b87:	c7 05 00 00 23 f0 00 	movl   $0x0,0xf0230000
f0105b8e:	00 00 00 
			i = conf->entry;
f0105b91:	0f b7 73 22          	movzwl 0x22(%ebx),%esi
f0105b95:	83 c4 10             	add    $0x10,%esp
	if ((conf = mpconfig(&mp)) == 0)
		return;
	ismp = 1;
	lapicaddr = conf->lapicaddr;

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0105b98:	83 c6 01             	add    $0x1,%esi
f0105b9b:	0f b7 43 22          	movzwl 0x22(%ebx),%eax
f0105b9f:	39 c6                	cmp    %eax,%esi
f0105ba1:	0f 82 6f ff ff ff    	jb     f0105b16 <mp_init+0x1d6>
			ismp = 0;
			i = conf->entry;
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f0105ba7:	a1 c0 03 23 f0       	mov    0xf02303c0,%eax
f0105bac:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f0105bb3:	83 3d 00 00 23 f0 00 	cmpl   $0x0,0xf0230000
f0105bba:	75 26                	jne    f0105be2 <mp_init+0x2a2>
		// Didn't like what we found; fall back to no MP.
		ncpu = 1;
f0105bbc:	c7 05 c4 03 23 f0 01 	movl   $0x1,0xf02303c4
f0105bc3:	00 00 00 
		lapicaddr = 0;
f0105bc6:	c7 05 00 10 27 f0 00 	movl   $0x0,0xf0271000
f0105bcd:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f0105bd0:	83 ec 0c             	sub    $0xc,%esp
f0105bd3:	68 98 7d 10 f0       	push   $0xf0107d98
f0105bd8:	e8 47 db ff ff       	call   f0103724 <cprintf>
		return;
f0105bdd:	83 c4 10             	add    $0x10,%esp
f0105be0:	eb 48                	jmp    f0105c2a <mp_init+0x2ea>
	}
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f0105be2:	83 ec 04             	sub    $0x4,%esp
f0105be5:	ff 35 c4 03 23 f0    	pushl  0xf02303c4
f0105beb:	0f b6 00             	movzbl (%eax),%eax
f0105bee:	50                   	push   %eax
f0105bef:	68 1f 7e 10 f0       	push   $0xf0107e1f
f0105bf4:	e8 2b db ff ff       	call   f0103724 <cprintf>

	if (mp->imcrp) {
f0105bf9:	83 c4 10             	add    $0x10,%esp
f0105bfc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105bff:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f0105c03:	74 25                	je     f0105c2a <mp_init+0x2ea>
		// [MP 3.2.6.1] If the hardware implements PIC mode,
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f0105c05:	83 ec 0c             	sub    $0xc,%esp
f0105c08:	68 c4 7d 10 f0       	push   $0xf0107dc4
f0105c0d:	e8 12 db ff ff       	call   f0103724 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0105c12:	ba 22 00 00 00       	mov    $0x22,%edx
f0105c17:	b8 70 00 00 00       	mov    $0x70,%eax
f0105c1c:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0105c1d:	ba 23 00 00 00       	mov    $0x23,%edx
f0105c22:	ec                   	in     (%dx),%al
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0105c23:	83 c8 01             	or     $0x1,%eax
f0105c26:	ee                   	out    %al,(%dx)
f0105c27:	83 c4 10             	add    $0x10,%esp
		outb(0x22, 0x70);   // Select IMCR
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
	}
}
f0105c2a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105c2d:	5b                   	pop    %ebx
f0105c2e:	5e                   	pop    %esi
f0105c2f:	5f                   	pop    %edi
f0105c30:	5d                   	pop    %ebp
f0105c31:	c3                   	ret    

f0105c32 <lapicw>:
physaddr_t lapicaddr;        // Initialized in mpconfig.c
volatile uint32_t *lapic;

static void
lapicw(int index, int value)
{
f0105c32:	55                   	push   %ebp
f0105c33:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
f0105c35:	8b 0d 04 10 27 f0    	mov    0xf0271004,%ecx
f0105c3b:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f0105c3e:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f0105c40:	a1 04 10 27 f0       	mov    0xf0271004,%eax
f0105c45:	8b 40 20             	mov    0x20(%eax),%eax
}
f0105c48:	5d                   	pop    %ebp
f0105c49:	c3                   	ret    

f0105c4a <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f0105c4a:	55                   	push   %ebp
f0105c4b:	89 e5                	mov    %esp,%ebp
	if (lapic)
f0105c4d:	a1 04 10 27 f0       	mov    0xf0271004,%eax
f0105c52:	85 c0                	test   %eax,%eax
f0105c54:	74 08                	je     f0105c5e <cpunum+0x14>
		return lapic[ID] >> 24;
f0105c56:	8b 40 20             	mov    0x20(%eax),%eax
f0105c59:	c1 e8 18             	shr    $0x18,%eax
f0105c5c:	eb 05                	jmp    f0105c63 <cpunum+0x19>
	return 0;
f0105c5e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105c63:	5d                   	pop    %ebp
f0105c64:	c3                   	ret    

f0105c65 <lapic_init>:
}

void
lapic_init(void)
{
	if (!lapicaddr)
f0105c65:	a1 00 10 27 f0       	mov    0xf0271000,%eax
f0105c6a:	85 c0                	test   %eax,%eax
f0105c6c:	0f 84 21 01 00 00    	je     f0105d93 <lapic_init+0x12e>
	lapic[ID];  // wait for write to finish, by reading
}

void
lapic_init(void)
{
f0105c72:	55                   	push   %ebp
f0105c73:	89 e5                	mov    %esp,%ebp
f0105c75:	83 ec 10             	sub    $0x10,%esp
	if (!lapicaddr)
		return;

	// lapicaddr is the physical address of the LAPIC's 4K MMIO
	// region.  Map it in to virtual memory so we can access it.
	lapic = mmio_map_region(lapicaddr, 4096);
f0105c78:	68 00 10 00 00       	push   $0x1000
f0105c7d:	50                   	push   %eax
f0105c7e:	e8 12 b6 ff ff       	call   f0101295 <mmio_map_region>
f0105c83:	a3 04 10 27 f0       	mov    %eax,0xf0271004

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (IRQ_OFFSET + IRQ_SPURIOUS));
f0105c88:	ba 27 01 00 00       	mov    $0x127,%edx
f0105c8d:	b8 3c 00 00 00       	mov    $0x3c,%eax
f0105c92:	e8 9b ff ff ff       	call   f0105c32 <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	// If we cared more about precise timekeeping,
	// TICR would be calibrated using an external time source.
	lapicw(TDCR, X1);
f0105c97:	ba 0b 00 00 00       	mov    $0xb,%edx
f0105c9c:	b8 f8 00 00 00       	mov    $0xf8,%eax
f0105ca1:	e8 8c ff ff ff       	call   f0105c32 <lapicw>
	lapicw(TIMER, PERIODIC | (IRQ_OFFSET + IRQ_TIMER));
f0105ca6:	ba 20 00 02 00       	mov    $0x20020,%edx
f0105cab:	b8 c8 00 00 00       	mov    $0xc8,%eax
f0105cb0:	e8 7d ff ff ff       	call   f0105c32 <lapicw>
	lapicw(TICR, 10000000); 
f0105cb5:	ba 80 96 98 00       	mov    $0x989680,%edx
f0105cba:	b8 e0 00 00 00       	mov    $0xe0,%eax
f0105cbf:	e8 6e ff ff ff       	call   f0105c32 <lapicw>
	//
	// According to Intel MP Specification, the BIOS should initialize
	// BSP's local APIC in Virtual Wire Mode, in which 8259A's
	// INTR is virtually connected to BSP's LINTIN0. In this mode,
	// we do not need to program the IOAPIC.
	if (thiscpu != bootcpu)
f0105cc4:	e8 81 ff ff ff       	call   f0105c4a <cpunum>
f0105cc9:	6b c0 74             	imul   $0x74,%eax,%eax
f0105ccc:	05 20 00 23 f0       	add    $0xf0230020,%eax
f0105cd1:	83 c4 10             	add    $0x10,%esp
f0105cd4:	39 05 c0 03 23 f0    	cmp    %eax,0xf02303c0
f0105cda:	74 0f                	je     f0105ceb <lapic_init+0x86>
		lapicw(LINT0, MASKED);
f0105cdc:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105ce1:	b8 d4 00 00 00       	mov    $0xd4,%eax
f0105ce6:	e8 47 ff ff ff       	call   f0105c32 <lapicw>

	// Disable NMI (LINT1) on all CPUs
	lapicw(LINT1, MASKED);
f0105ceb:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105cf0:	b8 d8 00 00 00       	mov    $0xd8,%eax
f0105cf5:	e8 38 ff ff ff       	call   f0105c32 <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f0105cfa:	a1 04 10 27 f0       	mov    0xf0271004,%eax
f0105cff:	8b 40 30             	mov    0x30(%eax),%eax
f0105d02:	c1 e8 10             	shr    $0x10,%eax
f0105d05:	3c 03                	cmp    $0x3,%al
f0105d07:	76 0f                	jbe    f0105d18 <lapic_init+0xb3>
		lapicw(PCINT, MASKED);
f0105d09:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105d0e:	b8 d0 00 00 00       	mov    $0xd0,%eax
f0105d13:	e8 1a ff ff ff       	call   f0105c32 <lapicw>

	// Map error interrupt to IRQ_ERROR.
	lapicw(ERROR, IRQ_OFFSET + IRQ_ERROR);
f0105d18:	ba 33 00 00 00       	mov    $0x33,%edx
f0105d1d:	b8 dc 00 00 00       	mov    $0xdc,%eax
f0105d22:	e8 0b ff ff ff       	call   f0105c32 <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
f0105d27:	ba 00 00 00 00       	mov    $0x0,%edx
f0105d2c:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0105d31:	e8 fc fe ff ff       	call   f0105c32 <lapicw>
	lapicw(ESR, 0);
f0105d36:	ba 00 00 00 00       	mov    $0x0,%edx
f0105d3b:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0105d40:	e8 ed fe ff ff       	call   f0105c32 <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
f0105d45:	ba 00 00 00 00       	mov    $0x0,%edx
f0105d4a:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0105d4f:	e8 de fe ff ff       	call   f0105c32 <lapicw>

	// Send an Init Level De-Assert to synchronize arbitration ID's.
	lapicw(ICRHI, 0);
f0105d54:	ba 00 00 00 00       	mov    $0x0,%edx
f0105d59:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105d5e:	e8 cf fe ff ff       	call   f0105c32 <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f0105d63:	ba 00 85 08 00       	mov    $0x88500,%edx
f0105d68:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105d6d:	e8 c0 fe ff ff       	call   f0105c32 <lapicw>
	while(lapic[ICRLO] & DELIVS)
f0105d72:	8b 15 04 10 27 f0    	mov    0xf0271004,%edx
f0105d78:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0105d7e:	f6 c4 10             	test   $0x10,%ah
f0105d81:	75 f5                	jne    f0105d78 <lapic_init+0x113>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
f0105d83:	ba 00 00 00 00       	mov    $0x0,%edx
f0105d88:	b8 20 00 00 00       	mov    $0x20,%eax
f0105d8d:	e8 a0 fe ff ff       	call   f0105c32 <lapicw>
}
f0105d92:	c9                   	leave  
f0105d93:	f3 c3                	repz ret 

f0105d95 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
	if (lapic)
f0105d95:	83 3d 04 10 27 f0 00 	cmpl   $0x0,0xf0271004
f0105d9c:	74 13                	je     f0105db1 <lapic_eoi+0x1c>
}

// Acknowledge interrupt.
void
lapic_eoi(void)
{
f0105d9e:	55                   	push   %ebp
f0105d9f:	89 e5                	mov    %esp,%ebp
	if (lapic)
		lapicw(EOI, 0);
f0105da1:	ba 00 00 00 00       	mov    $0x0,%edx
f0105da6:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0105dab:	e8 82 fe ff ff       	call   f0105c32 <lapicw>
}
f0105db0:	5d                   	pop    %ebp
f0105db1:	f3 c3                	repz ret 

f0105db3 <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f0105db3:	55                   	push   %ebp
f0105db4:	89 e5                	mov    %esp,%ebp
f0105db6:	56                   	push   %esi
f0105db7:	53                   	push   %ebx
f0105db8:	8b 75 08             	mov    0x8(%ebp),%esi
f0105dbb:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0105dbe:	ba 70 00 00 00       	mov    $0x70,%edx
f0105dc3:	b8 0f 00 00 00       	mov    $0xf,%eax
f0105dc8:	ee                   	out    %al,(%dx)
f0105dc9:	ba 71 00 00 00       	mov    $0x71,%edx
f0105dce:	b8 0a 00 00 00       	mov    $0xa,%eax
f0105dd3:	ee                   	out    %al,(%dx)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105dd4:	83 3d 88 fe 22 f0 00 	cmpl   $0x0,0xf022fe88
f0105ddb:	75 19                	jne    f0105df6 <lapic_startap+0x43>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105ddd:	68 67 04 00 00       	push   $0x467
f0105de2:	68 04 63 10 f0       	push   $0xf0106304
f0105de7:	68 98 00 00 00       	push   $0x98
f0105dec:	68 3c 7e 10 f0       	push   $0xf0107e3c
f0105df1:	e8 4a a2 ff ff       	call   f0100040 <_panic>
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t *)KADDR((0x40 << 4 | 0x67));  // Warm reset vector
	wrv[0] = 0;
f0105df6:	66 c7 05 67 04 00 f0 	movw   $0x0,0xf0000467
f0105dfd:	00 00 
	wrv[1] = addr >> 4;
f0105dff:	89 d8                	mov    %ebx,%eax
f0105e01:	c1 e8 04             	shr    $0x4,%eax
f0105e04:	66 a3 69 04 00 f0    	mov    %ax,0xf0000469

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f0105e0a:	c1 e6 18             	shl    $0x18,%esi
f0105e0d:	89 f2                	mov    %esi,%edx
f0105e0f:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105e14:	e8 19 fe ff ff       	call   f0105c32 <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f0105e19:	ba 00 c5 00 00       	mov    $0xc500,%edx
f0105e1e:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105e23:	e8 0a fe ff ff       	call   f0105c32 <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f0105e28:	ba 00 85 00 00       	mov    $0x8500,%edx
f0105e2d:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105e32:	e8 fb fd ff ff       	call   f0105c32 <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105e37:	c1 eb 0c             	shr    $0xc,%ebx
f0105e3a:	80 cf 06             	or     $0x6,%bh
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f0105e3d:	89 f2                	mov    %esi,%edx
f0105e3f:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105e44:	e8 e9 fd ff ff       	call   f0105c32 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105e49:	89 da                	mov    %ebx,%edx
f0105e4b:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105e50:	e8 dd fd ff ff       	call   f0105c32 <lapicw>
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f0105e55:	89 f2                	mov    %esi,%edx
f0105e57:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105e5c:	e8 d1 fd ff ff       	call   f0105c32 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105e61:	89 da                	mov    %ebx,%edx
f0105e63:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105e68:	e8 c5 fd ff ff       	call   f0105c32 <lapicw>
		microdelay(200);
	}
}
f0105e6d:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0105e70:	5b                   	pop    %ebx
f0105e71:	5e                   	pop    %esi
f0105e72:	5d                   	pop    %ebp
f0105e73:	c3                   	ret    

f0105e74 <lapic_ipi>:

void
lapic_ipi(int vector)
{
f0105e74:	55                   	push   %ebp
f0105e75:	89 e5                	mov    %esp,%ebp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f0105e77:	8b 55 08             	mov    0x8(%ebp),%edx
f0105e7a:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f0105e80:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105e85:	e8 a8 fd ff ff       	call   f0105c32 <lapicw>
	while (lapic[ICRLO] & DELIVS)
f0105e8a:	8b 15 04 10 27 f0    	mov    0xf0271004,%edx
f0105e90:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0105e96:	f6 c4 10             	test   $0x10,%ah
f0105e99:	75 f5                	jne    f0105e90 <lapic_ipi+0x1c>
		;
}
f0105e9b:	5d                   	pop    %ebp
f0105e9c:	c3                   	ret    

f0105e9d <__spin_initlock>:
}
#endif

void
__spin_initlock(struct spinlock *lk, char *name)
{
f0105e9d:	55                   	push   %ebp
f0105e9e:	89 e5                	mov    %esp,%ebp
f0105ea0:	8b 45 08             	mov    0x8(%ebp),%eax
	lk->locked = 0;
f0105ea3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#ifdef DEBUG_SPINLOCK
	lk->name = name;
f0105ea9:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105eac:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f0105eaf:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
#endif
}
f0105eb6:	5d                   	pop    %ebp
f0105eb7:	c3                   	ret    

f0105eb8 <spin_lock>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
f0105eb8:	55                   	push   %ebp
f0105eb9:	89 e5                	mov    %esp,%ebp
f0105ebb:	56                   	push   %esi
f0105ebc:	53                   	push   %ebx
f0105ebd:	8b 5d 08             	mov    0x8(%ebp),%ebx

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0105ec0:	83 3b 00             	cmpl   $0x0,(%ebx)
f0105ec3:	74 14                	je     f0105ed9 <spin_lock+0x21>
f0105ec5:	8b 73 08             	mov    0x8(%ebx),%esi
f0105ec8:	e8 7d fd ff ff       	call   f0105c4a <cpunum>
f0105ecd:	6b c0 74             	imul   $0x74,%eax,%eax
f0105ed0:	05 20 00 23 f0       	add    $0xf0230020,%eax
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (holding(lk))
f0105ed5:	39 c6                	cmp    %eax,%esi
f0105ed7:	74 07                	je     f0105ee0 <spin_lock+0x28>
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0105ed9:	ba 01 00 00 00       	mov    $0x1,%edx
f0105ede:	eb 20                	jmp    f0105f00 <spin_lock+0x48>
		panic("CPU %d cannot acquire %s: already holding", cpunum(), lk->name);
f0105ee0:	8b 5b 04             	mov    0x4(%ebx),%ebx
f0105ee3:	e8 62 fd ff ff       	call   f0105c4a <cpunum>
f0105ee8:	83 ec 0c             	sub    $0xc,%esp
f0105eeb:	53                   	push   %ebx
f0105eec:	50                   	push   %eax
f0105eed:	68 4c 7e 10 f0       	push   $0xf0107e4c
f0105ef2:	6a 41                	push   $0x41
f0105ef4:	68 b0 7e 10 f0       	push   $0xf0107eb0
f0105ef9:	e8 42 a1 ff ff       	call   f0100040 <_panic>

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
		asm volatile ("pause");
f0105efe:	f3 90                	pause  
f0105f00:	89 d0                	mov    %edx,%eax
f0105f02:	f0 87 03             	lock xchg %eax,(%ebx)
#endif

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
f0105f05:	85 c0                	test   %eax,%eax
f0105f07:	75 f5                	jne    f0105efe <spin_lock+0x46>
		asm volatile ("pause");

	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
f0105f09:	e8 3c fd ff ff       	call   f0105c4a <cpunum>
f0105f0e:	6b c0 74             	imul   $0x74,%eax,%eax
f0105f11:	05 20 00 23 f0       	add    $0xf0230020,%eax
f0105f16:	89 43 08             	mov    %eax,0x8(%ebx)
	get_caller_pcs(lk->pcs);
f0105f19:	83 c3 0c             	add    $0xc,%ebx

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0105f1c:	89 ea                	mov    %ebp,%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f0105f1e:	b8 00 00 00 00       	mov    $0x0,%eax
f0105f23:	eb 0b                	jmp    f0105f30 <spin_lock+0x78>
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
f0105f25:	8b 4a 04             	mov    0x4(%edx),%ecx
f0105f28:	89 0c 83             	mov    %ecx,(%ebx,%eax,4)
		ebp = (uint32_t *)ebp[0]; // saved %ebp
f0105f2b:	8b 12                	mov    (%edx),%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f0105f2d:	83 c0 01             	add    $0x1,%eax
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
f0105f30:	81 fa ff ff 7f ef    	cmp    $0xef7fffff,%edx
f0105f36:	76 11                	jbe    f0105f49 <spin_lock+0x91>
f0105f38:	83 f8 09             	cmp    $0x9,%eax
f0105f3b:	7e e8                	jle    f0105f25 <spin_lock+0x6d>
f0105f3d:	eb 0a                	jmp    f0105f49 <spin_lock+0x91>
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
		pcs[i] = 0;
f0105f3f:	c7 04 83 00 00 00 00 	movl   $0x0,(%ebx,%eax,4)
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
f0105f46:	83 c0 01             	add    $0x1,%eax
f0105f49:	83 f8 09             	cmp    $0x9,%eax
f0105f4c:	7e f1                	jle    f0105f3f <spin_lock+0x87>
	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
	get_caller_pcs(lk->pcs);
#endif
}
f0105f4e:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0105f51:	5b                   	pop    %ebx
f0105f52:	5e                   	pop    %esi
f0105f53:	5d                   	pop    %ebp
f0105f54:	c3                   	ret    

f0105f55 <spin_unlock>:

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
f0105f55:	55                   	push   %ebp
f0105f56:	89 e5                	mov    %esp,%ebp
f0105f58:	57                   	push   %edi
f0105f59:	56                   	push   %esi
f0105f5a:	53                   	push   %ebx
f0105f5b:	83 ec 4c             	sub    $0x4c,%esp
f0105f5e:	8b 75 08             	mov    0x8(%ebp),%esi

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0105f61:	83 3e 00             	cmpl   $0x0,(%esi)
f0105f64:	74 18                	je     f0105f7e <spin_unlock+0x29>
f0105f66:	8b 5e 08             	mov    0x8(%esi),%ebx
f0105f69:	e8 dc fc ff ff       	call   f0105c4a <cpunum>
f0105f6e:	6b c0 74             	imul   $0x74,%eax,%eax
f0105f71:	05 20 00 23 f0       	add    $0xf0230020,%eax
// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (!holding(lk)) {
f0105f76:	39 c3                	cmp    %eax,%ebx
f0105f78:	0f 84 a5 00 00 00    	je     f0106023 <spin_unlock+0xce>
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
f0105f7e:	83 ec 04             	sub    $0x4,%esp
f0105f81:	6a 28                	push   $0x28
f0105f83:	8d 46 0c             	lea    0xc(%esi),%eax
f0105f86:	50                   	push   %eax
f0105f87:	8d 5d c0             	lea    -0x40(%ebp),%ebx
f0105f8a:	53                   	push   %ebx
f0105f8b:	e8 e5 f6 ff ff       	call   f0105675 <memmove>
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
f0105f90:	8b 46 08             	mov    0x8(%esi),%eax
	if (!holding(lk)) {
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
f0105f93:	0f b6 38             	movzbl (%eax),%edi
f0105f96:	8b 76 04             	mov    0x4(%esi),%esi
f0105f99:	e8 ac fc ff ff       	call   f0105c4a <cpunum>
f0105f9e:	57                   	push   %edi
f0105f9f:	56                   	push   %esi
f0105fa0:	50                   	push   %eax
f0105fa1:	68 78 7e 10 f0       	push   $0xf0107e78
f0105fa6:	e8 79 d7 ff ff       	call   f0103724 <cprintf>
f0105fab:	83 c4 20             	add    $0x20,%esp
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
f0105fae:	8d 7d a8             	lea    -0x58(%ebp),%edi
f0105fb1:	eb 54                	jmp    f0106007 <spin_unlock+0xb2>
f0105fb3:	83 ec 08             	sub    $0x8,%esp
f0105fb6:	57                   	push   %edi
f0105fb7:	50                   	push   %eax
f0105fb8:	e8 eb eb ff ff       	call   f0104ba8 <debuginfo_eip>
f0105fbd:	83 c4 10             	add    $0x10,%esp
f0105fc0:	85 c0                	test   %eax,%eax
f0105fc2:	78 27                	js     f0105feb <spin_unlock+0x96>
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
f0105fc4:	8b 06                	mov    (%esi),%eax
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
f0105fc6:	83 ec 04             	sub    $0x4,%esp
f0105fc9:	89 c2                	mov    %eax,%edx
f0105fcb:	2b 55 b8             	sub    -0x48(%ebp),%edx
f0105fce:	52                   	push   %edx
f0105fcf:	ff 75 b0             	pushl  -0x50(%ebp)
f0105fd2:	ff 75 b4             	pushl  -0x4c(%ebp)
f0105fd5:	ff 75 ac             	pushl  -0x54(%ebp)
f0105fd8:	ff 75 a8             	pushl  -0x58(%ebp)
f0105fdb:	50                   	push   %eax
f0105fdc:	68 c0 7e 10 f0       	push   $0xf0107ec0
f0105fe1:	e8 3e d7 ff ff       	call   f0103724 <cprintf>
f0105fe6:	83 c4 20             	add    $0x20,%esp
f0105fe9:	eb 12                	jmp    f0105ffd <spin_unlock+0xa8>
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
f0105feb:	83 ec 08             	sub    $0x8,%esp
f0105fee:	ff 36                	pushl  (%esi)
f0105ff0:	68 d7 7e 10 f0       	push   $0xf0107ed7
f0105ff5:	e8 2a d7 ff ff       	call   f0103724 <cprintf>
f0105ffa:	83 c4 10             	add    $0x10,%esp
f0105ffd:	83 c3 04             	add    $0x4,%ebx
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
f0106000:	8d 45 e8             	lea    -0x18(%ebp),%eax
f0106003:	39 c3                	cmp    %eax,%ebx
f0106005:	74 08                	je     f010600f <spin_unlock+0xba>
f0106007:	89 de                	mov    %ebx,%esi
f0106009:	8b 03                	mov    (%ebx),%eax
f010600b:	85 c0                	test   %eax,%eax
f010600d:	75 a4                	jne    f0105fb3 <spin_unlock+0x5e>
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
		}
		panic("spin_unlock");
f010600f:	83 ec 04             	sub    $0x4,%esp
f0106012:	68 df 7e 10 f0       	push   $0xf0107edf
f0106017:	6a 67                	push   $0x67
f0106019:	68 b0 7e 10 f0       	push   $0xf0107eb0
f010601e:	e8 1d a0 ff ff       	call   f0100040 <_panic>
	}

	lk->pcs[0] = 0;
f0106023:	c7 46 0c 00 00 00 00 	movl   $0x0,0xc(%esi)
	lk->cpu = 0;
f010602a:	c7 46 08 00 00 00 00 	movl   $0x0,0x8(%esi)
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0106031:	b8 00 00 00 00       	mov    $0x0,%eax
f0106036:	f0 87 06             	lock xchg %eax,(%esi)
	// Paper says that Intel 64 and IA-32 will not move a load
	// after a store. So lock->locked = 0 would work here.
	// The xchg being asm volatile ensures gcc emits it after
	// the above assignments (and after the critical section).
	xchg(&lk->locked, 0);
}
f0106039:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010603c:	5b                   	pop    %ebx
f010603d:	5e                   	pop    %esi
f010603e:	5f                   	pop    %edi
f010603f:	5d                   	pop    %ebp
f0106040:	c3                   	ret    
f0106041:	66 90                	xchg   %ax,%ax
f0106043:	66 90                	xchg   %ax,%ax
f0106045:	66 90                	xchg   %ax,%ax
f0106047:	66 90                	xchg   %ax,%ax
f0106049:	66 90                	xchg   %ax,%ax
f010604b:	66 90                	xchg   %ax,%ax
f010604d:	66 90                	xchg   %ax,%ax
f010604f:	90                   	nop

f0106050 <__udivdi3>:
f0106050:	55                   	push   %ebp
f0106051:	57                   	push   %edi
f0106052:	56                   	push   %esi
f0106053:	53                   	push   %ebx
f0106054:	83 ec 1c             	sub    $0x1c,%esp
f0106057:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010605b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010605f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0106063:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0106067:	85 f6                	test   %esi,%esi
f0106069:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010606d:	89 ca                	mov    %ecx,%edx
f010606f:	89 f8                	mov    %edi,%eax
f0106071:	75 3d                	jne    f01060b0 <__udivdi3+0x60>
f0106073:	39 cf                	cmp    %ecx,%edi
f0106075:	0f 87 c5 00 00 00    	ja     f0106140 <__udivdi3+0xf0>
f010607b:	85 ff                	test   %edi,%edi
f010607d:	89 fd                	mov    %edi,%ebp
f010607f:	75 0b                	jne    f010608c <__udivdi3+0x3c>
f0106081:	b8 01 00 00 00       	mov    $0x1,%eax
f0106086:	31 d2                	xor    %edx,%edx
f0106088:	f7 f7                	div    %edi
f010608a:	89 c5                	mov    %eax,%ebp
f010608c:	89 c8                	mov    %ecx,%eax
f010608e:	31 d2                	xor    %edx,%edx
f0106090:	f7 f5                	div    %ebp
f0106092:	89 c1                	mov    %eax,%ecx
f0106094:	89 d8                	mov    %ebx,%eax
f0106096:	89 cf                	mov    %ecx,%edi
f0106098:	f7 f5                	div    %ebp
f010609a:	89 c3                	mov    %eax,%ebx
f010609c:	89 d8                	mov    %ebx,%eax
f010609e:	89 fa                	mov    %edi,%edx
f01060a0:	83 c4 1c             	add    $0x1c,%esp
f01060a3:	5b                   	pop    %ebx
f01060a4:	5e                   	pop    %esi
f01060a5:	5f                   	pop    %edi
f01060a6:	5d                   	pop    %ebp
f01060a7:	c3                   	ret    
f01060a8:	90                   	nop
f01060a9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01060b0:	39 ce                	cmp    %ecx,%esi
f01060b2:	77 74                	ja     f0106128 <__udivdi3+0xd8>
f01060b4:	0f bd fe             	bsr    %esi,%edi
f01060b7:	83 f7 1f             	xor    $0x1f,%edi
f01060ba:	0f 84 98 00 00 00    	je     f0106158 <__udivdi3+0x108>
f01060c0:	bb 20 00 00 00       	mov    $0x20,%ebx
f01060c5:	89 f9                	mov    %edi,%ecx
f01060c7:	89 c5                	mov    %eax,%ebp
f01060c9:	29 fb                	sub    %edi,%ebx
f01060cb:	d3 e6                	shl    %cl,%esi
f01060cd:	89 d9                	mov    %ebx,%ecx
f01060cf:	d3 ed                	shr    %cl,%ebp
f01060d1:	89 f9                	mov    %edi,%ecx
f01060d3:	d3 e0                	shl    %cl,%eax
f01060d5:	09 ee                	or     %ebp,%esi
f01060d7:	89 d9                	mov    %ebx,%ecx
f01060d9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01060dd:	89 d5                	mov    %edx,%ebp
f01060df:	8b 44 24 08          	mov    0x8(%esp),%eax
f01060e3:	d3 ed                	shr    %cl,%ebp
f01060e5:	89 f9                	mov    %edi,%ecx
f01060e7:	d3 e2                	shl    %cl,%edx
f01060e9:	89 d9                	mov    %ebx,%ecx
f01060eb:	d3 e8                	shr    %cl,%eax
f01060ed:	09 c2                	or     %eax,%edx
f01060ef:	89 d0                	mov    %edx,%eax
f01060f1:	89 ea                	mov    %ebp,%edx
f01060f3:	f7 f6                	div    %esi
f01060f5:	89 d5                	mov    %edx,%ebp
f01060f7:	89 c3                	mov    %eax,%ebx
f01060f9:	f7 64 24 0c          	mull   0xc(%esp)
f01060fd:	39 d5                	cmp    %edx,%ebp
f01060ff:	72 10                	jb     f0106111 <__udivdi3+0xc1>
f0106101:	8b 74 24 08          	mov    0x8(%esp),%esi
f0106105:	89 f9                	mov    %edi,%ecx
f0106107:	d3 e6                	shl    %cl,%esi
f0106109:	39 c6                	cmp    %eax,%esi
f010610b:	73 07                	jae    f0106114 <__udivdi3+0xc4>
f010610d:	39 d5                	cmp    %edx,%ebp
f010610f:	75 03                	jne    f0106114 <__udivdi3+0xc4>
f0106111:	83 eb 01             	sub    $0x1,%ebx
f0106114:	31 ff                	xor    %edi,%edi
f0106116:	89 d8                	mov    %ebx,%eax
f0106118:	89 fa                	mov    %edi,%edx
f010611a:	83 c4 1c             	add    $0x1c,%esp
f010611d:	5b                   	pop    %ebx
f010611e:	5e                   	pop    %esi
f010611f:	5f                   	pop    %edi
f0106120:	5d                   	pop    %ebp
f0106121:	c3                   	ret    
f0106122:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0106128:	31 ff                	xor    %edi,%edi
f010612a:	31 db                	xor    %ebx,%ebx
f010612c:	89 d8                	mov    %ebx,%eax
f010612e:	89 fa                	mov    %edi,%edx
f0106130:	83 c4 1c             	add    $0x1c,%esp
f0106133:	5b                   	pop    %ebx
f0106134:	5e                   	pop    %esi
f0106135:	5f                   	pop    %edi
f0106136:	5d                   	pop    %ebp
f0106137:	c3                   	ret    
f0106138:	90                   	nop
f0106139:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0106140:	89 d8                	mov    %ebx,%eax
f0106142:	f7 f7                	div    %edi
f0106144:	31 ff                	xor    %edi,%edi
f0106146:	89 c3                	mov    %eax,%ebx
f0106148:	89 d8                	mov    %ebx,%eax
f010614a:	89 fa                	mov    %edi,%edx
f010614c:	83 c4 1c             	add    $0x1c,%esp
f010614f:	5b                   	pop    %ebx
f0106150:	5e                   	pop    %esi
f0106151:	5f                   	pop    %edi
f0106152:	5d                   	pop    %ebp
f0106153:	c3                   	ret    
f0106154:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0106158:	39 ce                	cmp    %ecx,%esi
f010615a:	72 0c                	jb     f0106168 <__udivdi3+0x118>
f010615c:	31 db                	xor    %ebx,%ebx
f010615e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0106162:	0f 87 34 ff ff ff    	ja     f010609c <__udivdi3+0x4c>
f0106168:	bb 01 00 00 00       	mov    $0x1,%ebx
f010616d:	e9 2a ff ff ff       	jmp    f010609c <__udivdi3+0x4c>
f0106172:	66 90                	xchg   %ax,%ax
f0106174:	66 90                	xchg   %ax,%ax
f0106176:	66 90                	xchg   %ax,%ax
f0106178:	66 90                	xchg   %ax,%ax
f010617a:	66 90                	xchg   %ax,%ax
f010617c:	66 90                	xchg   %ax,%ax
f010617e:	66 90                	xchg   %ax,%ax

f0106180 <__umoddi3>:
f0106180:	55                   	push   %ebp
f0106181:	57                   	push   %edi
f0106182:	56                   	push   %esi
f0106183:	53                   	push   %ebx
f0106184:	83 ec 1c             	sub    $0x1c,%esp
f0106187:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010618b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010618f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0106193:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0106197:	85 d2                	test   %edx,%edx
f0106199:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010619d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01061a1:	89 f3                	mov    %esi,%ebx
f01061a3:	89 3c 24             	mov    %edi,(%esp)
f01061a6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01061aa:	75 1c                	jne    f01061c8 <__umoddi3+0x48>
f01061ac:	39 f7                	cmp    %esi,%edi
f01061ae:	76 50                	jbe    f0106200 <__umoddi3+0x80>
f01061b0:	89 c8                	mov    %ecx,%eax
f01061b2:	89 f2                	mov    %esi,%edx
f01061b4:	f7 f7                	div    %edi
f01061b6:	89 d0                	mov    %edx,%eax
f01061b8:	31 d2                	xor    %edx,%edx
f01061ba:	83 c4 1c             	add    $0x1c,%esp
f01061bd:	5b                   	pop    %ebx
f01061be:	5e                   	pop    %esi
f01061bf:	5f                   	pop    %edi
f01061c0:	5d                   	pop    %ebp
f01061c1:	c3                   	ret    
f01061c2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01061c8:	39 f2                	cmp    %esi,%edx
f01061ca:	89 d0                	mov    %edx,%eax
f01061cc:	77 52                	ja     f0106220 <__umoddi3+0xa0>
f01061ce:	0f bd ea             	bsr    %edx,%ebp
f01061d1:	83 f5 1f             	xor    $0x1f,%ebp
f01061d4:	75 5a                	jne    f0106230 <__umoddi3+0xb0>
f01061d6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f01061da:	0f 82 e0 00 00 00    	jb     f01062c0 <__umoddi3+0x140>
f01061e0:	39 0c 24             	cmp    %ecx,(%esp)
f01061e3:	0f 86 d7 00 00 00    	jbe    f01062c0 <__umoddi3+0x140>
f01061e9:	8b 44 24 08          	mov    0x8(%esp),%eax
f01061ed:	8b 54 24 04          	mov    0x4(%esp),%edx
f01061f1:	83 c4 1c             	add    $0x1c,%esp
f01061f4:	5b                   	pop    %ebx
f01061f5:	5e                   	pop    %esi
f01061f6:	5f                   	pop    %edi
f01061f7:	5d                   	pop    %ebp
f01061f8:	c3                   	ret    
f01061f9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0106200:	85 ff                	test   %edi,%edi
f0106202:	89 fd                	mov    %edi,%ebp
f0106204:	75 0b                	jne    f0106211 <__umoddi3+0x91>
f0106206:	b8 01 00 00 00       	mov    $0x1,%eax
f010620b:	31 d2                	xor    %edx,%edx
f010620d:	f7 f7                	div    %edi
f010620f:	89 c5                	mov    %eax,%ebp
f0106211:	89 f0                	mov    %esi,%eax
f0106213:	31 d2                	xor    %edx,%edx
f0106215:	f7 f5                	div    %ebp
f0106217:	89 c8                	mov    %ecx,%eax
f0106219:	f7 f5                	div    %ebp
f010621b:	89 d0                	mov    %edx,%eax
f010621d:	eb 99                	jmp    f01061b8 <__umoddi3+0x38>
f010621f:	90                   	nop
f0106220:	89 c8                	mov    %ecx,%eax
f0106222:	89 f2                	mov    %esi,%edx
f0106224:	83 c4 1c             	add    $0x1c,%esp
f0106227:	5b                   	pop    %ebx
f0106228:	5e                   	pop    %esi
f0106229:	5f                   	pop    %edi
f010622a:	5d                   	pop    %ebp
f010622b:	c3                   	ret    
f010622c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0106230:	8b 34 24             	mov    (%esp),%esi
f0106233:	bf 20 00 00 00       	mov    $0x20,%edi
f0106238:	89 e9                	mov    %ebp,%ecx
f010623a:	29 ef                	sub    %ebp,%edi
f010623c:	d3 e0                	shl    %cl,%eax
f010623e:	89 f9                	mov    %edi,%ecx
f0106240:	89 f2                	mov    %esi,%edx
f0106242:	d3 ea                	shr    %cl,%edx
f0106244:	89 e9                	mov    %ebp,%ecx
f0106246:	09 c2                	or     %eax,%edx
f0106248:	89 d8                	mov    %ebx,%eax
f010624a:	89 14 24             	mov    %edx,(%esp)
f010624d:	89 f2                	mov    %esi,%edx
f010624f:	d3 e2                	shl    %cl,%edx
f0106251:	89 f9                	mov    %edi,%ecx
f0106253:	89 54 24 04          	mov    %edx,0x4(%esp)
f0106257:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010625b:	d3 e8                	shr    %cl,%eax
f010625d:	89 e9                	mov    %ebp,%ecx
f010625f:	89 c6                	mov    %eax,%esi
f0106261:	d3 e3                	shl    %cl,%ebx
f0106263:	89 f9                	mov    %edi,%ecx
f0106265:	89 d0                	mov    %edx,%eax
f0106267:	d3 e8                	shr    %cl,%eax
f0106269:	89 e9                	mov    %ebp,%ecx
f010626b:	09 d8                	or     %ebx,%eax
f010626d:	89 d3                	mov    %edx,%ebx
f010626f:	89 f2                	mov    %esi,%edx
f0106271:	f7 34 24             	divl   (%esp)
f0106274:	89 d6                	mov    %edx,%esi
f0106276:	d3 e3                	shl    %cl,%ebx
f0106278:	f7 64 24 04          	mull   0x4(%esp)
f010627c:	39 d6                	cmp    %edx,%esi
f010627e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0106282:	89 d1                	mov    %edx,%ecx
f0106284:	89 c3                	mov    %eax,%ebx
f0106286:	72 08                	jb     f0106290 <__umoddi3+0x110>
f0106288:	75 11                	jne    f010629b <__umoddi3+0x11b>
f010628a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010628e:	73 0b                	jae    f010629b <__umoddi3+0x11b>
f0106290:	2b 44 24 04          	sub    0x4(%esp),%eax
f0106294:	1b 14 24             	sbb    (%esp),%edx
f0106297:	89 d1                	mov    %edx,%ecx
f0106299:	89 c3                	mov    %eax,%ebx
f010629b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010629f:	29 da                	sub    %ebx,%edx
f01062a1:	19 ce                	sbb    %ecx,%esi
f01062a3:	89 f9                	mov    %edi,%ecx
f01062a5:	89 f0                	mov    %esi,%eax
f01062a7:	d3 e0                	shl    %cl,%eax
f01062a9:	89 e9                	mov    %ebp,%ecx
f01062ab:	d3 ea                	shr    %cl,%edx
f01062ad:	89 e9                	mov    %ebp,%ecx
f01062af:	d3 ee                	shr    %cl,%esi
f01062b1:	09 d0                	or     %edx,%eax
f01062b3:	89 f2                	mov    %esi,%edx
f01062b5:	83 c4 1c             	add    $0x1c,%esp
f01062b8:	5b                   	pop    %ebx
f01062b9:	5e                   	pop    %esi
f01062ba:	5f                   	pop    %edi
f01062bb:	5d                   	pop    %ebp
f01062bc:	c3                   	ret    
f01062bd:	8d 76 00             	lea    0x0(%esi),%esi
f01062c0:	29 f9                	sub    %edi,%ecx
f01062c2:	19 d6                	sbb    %edx,%esi
f01062c4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01062c8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01062cc:	e9 18 ff ff ff       	jmp    f01061e9 <__umoddi3+0x69>
