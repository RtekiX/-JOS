
obj/user/faultregs：     文件格式 elf32-i386


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
  80002c:	e8 60 05 00 00       	call   800591 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <check_regs>:
static struct regs before, during, after;

static void
check_regs(struct regs* a, const char *an, struct regs* b, const char *bn,
	   const char *testname)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	57                   	push   %edi
  800037:	56                   	push   %esi
  800038:	53                   	push   %ebx
  800039:	83 ec 0c             	sub    $0xc,%esp
  80003c:	89 c6                	mov    %eax,%esi
  80003e:	89 cb                	mov    %ecx,%ebx
	int mismatch = 0;

	cprintf("%-6s %-8s %-8s\n", "", an, bn);
  800040:	ff 75 08             	pushl  0x8(%ebp)
  800043:	52                   	push   %edx
  800044:	68 d1 15 80 00       	push   $0x8015d1
  800049:	68 a0 15 80 00       	push   $0x8015a0
  80004e:	e8 6f 06 00 00       	call   8006c2 <cprintf>
			cprintf("MISMATCH\n");				\
			mismatch = 1;					\
		}							\
	} while (0)

	CHECK(edi, regs.reg_edi);
  800053:	ff 33                	pushl  (%ebx)
  800055:	ff 36                	pushl  (%esi)
  800057:	68 b0 15 80 00       	push   $0x8015b0
  80005c:	68 b4 15 80 00       	push   $0x8015b4
  800061:	e8 5c 06 00 00       	call   8006c2 <cprintf>
  800066:	83 c4 20             	add    $0x20,%esp
  800069:	8b 03                	mov    (%ebx),%eax
  80006b:	39 06                	cmp    %eax,(%esi)
  80006d:	75 17                	jne    800086 <check_regs+0x53>
  80006f:	83 ec 0c             	sub    $0xc,%esp
  800072:	68 c4 15 80 00       	push   $0x8015c4
  800077:	e8 46 06 00 00       	call   8006c2 <cprintf>
  80007c:	83 c4 10             	add    $0x10,%esp

static void
check_regs(struct regs* a, const char *an, struct regs* b, const char *bn,
	   const char *testname)
{
	int mismatch = 0;
  80007f:	bf 00 00 00 00       	mov    $0x0,%edi
  800084:	eb 15                	jmp    80009b <check_regs+0x68>
			cprintf("MISMATCH\n");				\
			mismatch = 1;					\
		}							\
	} while (0)

	CHECK(edi, regs.reg_edi);
  800086:	83 ec 0c             	sub    $0xc,%esp
  800089:	68 c8 15 80 00       	push   $0x8015c8
  80008e:	e8 2f 06 00 00       	call   8006c2 <cprintf>
  800093:	83 c4 10             	add    $0x10,%esp
  800096:	bf 01 00 00 00       	mov    $0x1,%edi
	CHECK(esi, regs.reg_esi);
  80009b:	ff 73 04             	pushl  0x4(%ebx)
  80009e:	ff 76 04             	pushl  0x4(%esi)
  8000a1:	68 d2 15 80 00       	push   $0x8015d2
  8000a6:	68 b4 15 80 00       	push   $0x8015b4
  8000ab:	e8 12 06 00 00       	call   8006c2 <cprintf>
  8000b0:	83 c4 10             	add    $0x10,%esp
  8000b3:	8b 43 04             	mov    0x4(%ebx),%eax
  8000b6:	39 46 04             	cmp    %eax,0x4(%esi)
  8000b9:	75 12                	jne    8000cd <check_regs+0x9a>
  8000bb:	83 ec 0c             	sub    $0xc,%esp
  8000be:	68 c4 15 80 00       	push   $0x8015c4
  8000c3:	e8 fa 05 00 00       	call   8006c2 <cprintf>
  8000c8:	83 c4 10             	add    $0x10,%esp
  8000cb:	eb 15                	jmp    8000e2 <check_regs+0xaf>
  8000cd:	83 ec 0c             	sub    $0xc,%esp
  8000d0:	68 c8 15 80 00       	push   $0x8015c8
  8000d5:	e8 e8 05 00 00       	call   8006c2 <cprintf>
  8000da:	83 c4 10             	add    $0x10,%esp
  8000dd:	bf 01 00 00 00       	mov    $0x1,%edi
	CHECK(ebp, regs.reg_ebp);
  8000e2:	ff 73 08             	pushl  0x8(%ebx)
  8000e5:	ff 76 08             	pushl  0x8(%esi)
  8000e8:	68 d6 15 80 00       	push   $0x8015d6
  8000ed:	68 b4 15 80 00       	push   $0x8015b4
  8000f2:	e8 cb 05 00 00       	call   8006c2 <cprintf>
  8000f7:	83 c4 10             	add    $0x10,%esp
  8000fa:	8b 43 08             	mov    0x8(%ebx),%eax
  8000fd:	39 46 08             	cmp    %eax,0x8(%esi)
  800100:	75 12                	jne    800114 <check_regs+0xe1>
  800102:	83 ec 0c             	sub    $0xc,%esp
  800105:	68 c4 15 80 00       	push   $0x8015c4
  80010a:	e8 b3 05 00 00       	call   8006c2 <cprintf>
  80010f:	83 c4 10             	add    $0x10,%esp
  800112:	eb 15                	jmp    800129 <check_regs+0xf6>
  800114:	83 ec 0c             	sub    $0xc,%esp
  800117:	68 c8 15 80 00       	push   $0x8015c8
  80011c:	e8 a1 05 00 00       	call   8006c2 <cprintf>
  800121:	83 c4 10             	add    $0x10,%esp
  800124:	bf 01 00 00 00       	mov    $0x1,%edi
	CHECK(ebx, regs.reg_ebx);
  800129:	ff 73 10             	pushl  0x10(%ebx)
  80012c:	ff 76 10             	pushl  0x10(%esi)
  80012f:	68 da 15 80 00       	push   $0x8015da
  800134:	68 b4 15 80 00       	push   $0x8015b4
  800139:	e8 84 05 00 00       	call   8006c2 <cprintf>
  80013e:	83 c4 10             	add    $0x10,%esp
  800141:	8b 43 10             	mov    0x10(%ebx),%eax
  800144:	39 46 10             	cmp    %eax,0x10(%esi)
  800147:	75 12                	jne    80015b <check_regs+0x128>
  800149:	83 ec 0c             	sub    $0xc,%esp
  80014c:	68 c4 15 80 00       	push   $0x8015c4
  800151:	e8 6c 05 00 00       	call   8006c2 <cprintf>
  800156:	83 c4 10             	add    $0x10,%esp
  800159:	eb 15                	jmp    800170 <check_regs+0x13d>
  80015b:	83 ec 0c             	sub    $0xc,%esp
  80015e:	68 c8 15 80 00       	push   $0x8015c8
  800163:	e8 5a 05 00 00       	call   8006c2 <cprintf>
  800168:	83 c4 10             	add    $0x10,%esp
  80016b:	bf 01 00 00 00       	mov    $0x1,%edi
	CHECK(edx, regs.reg_edx);
  800170:	ff 73 14             	pushl  0x14(%ebx)
  800173:	ff 76 14             	pushl  0x14(%esi)
  800176:	68 de 15 80 00       	push   $0x8015de
  80017b:	68 b4 15 80 00       	push   $0x8015b4
  800180:	e8 3d 05 00 00       	call   8006c2 <cprintf>
  800185:	83 c4 10             	add    $0x10,%esp
  800188:	8b 43 14             	mov    0x14(%ebx),%eax
  80018b:	39 46 14             	cmp    %eax,0x14(%esi)
  80018e:	75 12                	jne    8001a2 <check_regs+0x16f>
  800190:	83 ec 0c             	sub    $0xc,%esp
  800193:	68 c4 15 80 00       	push   $0x8015c4
  800198:	e8 25 05 00 00       	call   8006c2 <cprintf>
  80019d:	83 c4 10             	add    $0x10,%esp
  8001a0:	eb 15                	jmp    8001b7 <check_regs+0x184>
  8001a2:	83 ec 0c             	sub    $0xc,%esp
  8001a5:	68 c8 15 80 00       	push   $0x8015c8
  8001aa:	e8 13 05 00 00       	call   8006c2 <cprintf>
  8001af:	83 c4 10             	add    $0x10,%esp
  8001b2:	bf 01 00 00 00       	mov    $0x1,%edi
	CHECK(ecx, regs.reg_ecx);
  8001b7:	ff 73 18             	pushl  0x18(%ebx)
  8001ba:	ff 76 18             	pushl  0x18(%esi)
  8001bd:	68 e2 15 80 00       	push   $0x8015e2
  8001c2:	68 b4 15 80 00       	push   $0x8015b4
  8001c7:	e8 f6 04 00 00       	call   8006c2 <cprintf>
  8001cc:	83 c4 10             	add    $0x10,%esp
  8001cf:	8b 43 18             	mov    0x18(%ebx),%eax
  8001d2:	39 46 18             	cmp    %eax,0x18(%esi)
  8001d5:	75 12                	jne    8001e9 <check_regs+0x1b6>
  8001d7:	83 ec 0c             	sub    $0xc,%esp
  8001da:	68 c4 15 80 00       	push   $0x8015c4
  8001df:	e8 de 04 00 00       	call   8006c2 <cprintf>
  8001e4:	83 c4 10             	add    $0x10,%esp
  8001e7:	eb 15                	jmp    8001fe <check_regs+0x1cb>
  8001e9:	83 ec 0c             	sub    $0xc,%esp
  8001ec:	68 c8 15 80 00       	push   $0x8015c8
  8001f1:	e8 cc 04 00 00       	call   8006c2 <cprintf>
  8001f6:	83 c4 10             	add    $0x10,%esp
  8001f9:	bf 01 00 00 00       	mov    $0x1,%edi
	CHECK(eax, regs.reg_eax);
  8001fe:	ff 73 1c             	pushl  0x1c(%ebx)
  800201:	ff 76 1c             	pushl  0x1c(%esi)
  800204:	68 e6 15 80 00       	push   $0x8015e6
  800209:	68 b4 15 80 00       	push   $0x8015b4
  80020e:	e8 af 04 00 00       	call   8006c2 <cprintf>
  800213:	83 c4 10             	add    $0x10,%esp
  800216:	8b 43 1c             	mov    0x1c(%ebx),%eax
  800219:	39 46 1c             	cmp    %eax,0x1c(%esi)
  80021c:	75 12                	jne    800230 <check_regs+0x1fd>
  80021e:	83 ec 0c             	sub    $0xc,%esp
  800221:	68 c4 15 80 00       	push   $0x8015c4
  800226:	e8 97 04 00 00       	call   8006c2 <cprintf>
  80022b:	83 c4 10             	add    $0x10,%esp
  80022e:	eb 15                	jmp    800245 <check_regs+0x212>
  800230:	83 ec 0c             	sub    $0xc,%esp
  800233:	68 c8 15 80 00       	push   $0x8015c8
  800238:	e8 85 04 00 00       	call   8006c2 <cprintf>
  80023d:	83 c4 10             	add    $0x10,%esp
  800240:	bf 01 00 00 00       	mov    $0x1,%edi
	CHECK(eip, eip);
  800245:	ff 73 20             	pushl  0x20(%ebx)
  800248:	ff 76 20             	pushl  0x20(%esi)
  80024b:	68 ea 15 80 00       	push   $0x8015ea
  800250:	68 b4 15 80 00       	push   $0x8015b4
  800255:	e8 68 04 00 00       	call   8006c2 <cprintf>
  80025a:	83 c4 10             	add    $0x10,%esp
  80025d:	8b 43 20             	mov    0x20(%ebx),%eax
  800260:	39 46 20             	cmp    %eax,0x20(%esi)
  800263:	75 12                	jne    800277 <check_regs+0x244>
  800265:	83 ec 0c             	sub    $0xc,%esp
  800268:	68 c4 15 80 00       	push   $0x8015c4
  80026d:	e8 50 04 00 00       	call   8006c2 <cprintf>
  800272:	83 c4 10             	add    $0x10,%esp
  800275:	eb 15                	jmp    80028c <check_regs+0x259>
  800277:	83 ec 0c             	sub    $0xc,%esp
  80027a:	68 c8 15 80 00       	push   $0x8015c8
  80027f:	e8 3e 04 00 00       	call   8006c2 <cprintf>
  800284:	83 c4 10             	add    $0x10,%esp
  800287:	bf 01 00 00 00       	mov    $0x1,%edi
	CHECK(eflags, eflags);
  80028c:	ff 73 24             	pushl  0x24(%ebx)
  80028f:	ff 76 24             	pushl  0x24(%esi)
  800292:	68 ee 15 80 00       	push   $0x8015ee
  800297:	68 b4 15 80 00       	push   $0x8015b4
  80029c:	e8 21 04 00 00       	call   8006c2 <cprintf>
  8002a1:	83 c4 10             	add    $0x10,%esp
  8002a4:	8b 43 24             	mov    0x24(%ebx),%eax
  8002a7:	39 46 24             	cmp    %eax,0x24(%esi)
  8002aa:	75 2f                	jne    8002db <check_regs+0x2a8>
  8002ac:	83 ec 0c             	sub    $0xc,%esp
  8002af:	68 c4 15 80 00       	push   $0x8015c4
  8002b4:	e8 09 04 00 00       	call   8006c2 <cprintf>
	CHECK(esp, esp);
  8002b9:	ff 73 28             	pushl  0x28(%ebx)
  8002bc:	ff 76 28             	pushl  0x28(%esi)
  8002bf:	68 f5 15 80 00       	push   $0x8015f5
  8002c4:	68 b4 15 80 00       	push   $0x8015b4
  8002c9:	e8 f4 03 00 00       	call   8006c2 <cprintf>
  8002ce:	83 c4 20             	add    $0x20,%esp
  8002d1:	8b 43 28             	mov    0x28(%ebx),%eax
  8002d4:	39 46 28             	cmp    %eax,0x28(%esi)
  8002d7:	74 31                	je     80030a <check_regs+0x2d7>
  8002d9:	eb 55                	jmp    800330 <check_regs+0x2fd>
	CHECK(ebx, regs.reg_ebx);
	CHECK(edx, regs.reg_edx);
	CHECK(ecx, regs.reg_ecx);
	CHECK(eax, regs.reg_eax);
	CHECK(eip, eip);
	CHECK(eflags, eflags);
  8002db:	83 ec 0c             	sub    $0xc,%esp
  8002de:	68 c8 15 80 00       	push   $0x8015c8
  8002e3:	e8 da 03 00 00       	call   8006c2 <cprintf>
	CHECK(esp, esp);
  8002e8:	ff 73 28             	pushl  0x28(%ebx)
  8002eb:	ff 76 28             	pushl  0x28(%esi)
  8002ee:	68 f5 15 80 00       	push   $0x8015f5
  8002f3:	68 b4 15 80 00       	push   $0x8015b4
  8002f8:	e8 c5 03 00 00       	call   8006c2 <cprintf>
  8002fd:	83 c4 20             	add    $0x20,%esp
  800300:	8b 43 28             	mov    0x28(%ebx),%eax
  800303:	39 46 28             	cmp    %eax,0x28(%esi)
  800306:	75 28                	jne    800330 <check_regs+0x2fd>
  800308:	eb 6c                	jmp    800376 <check_regs+0x343>
  80030a:	83 ec 0c             	sub    $0xc,%esp
  80030d:	68 c4 15 80 00       	push   $0x8015c4
  800312:	e8 ab 03 00 00       	call   8006c2 <cprintf>

#undef CHECK

	cprintf("Registers %s ", testname);
  800317:	83 c4 08             	add    $0x8,%esp
  80031a:	ff 75 0c             	pushl  0xc(%ebp)
  80031d:	68 f9 15 80 00       	push   $0x8015f9
  800322:	e8 9b 03 00 00       	call   8006c2 <cprintf>
	if (!mismatch)
  800327:	83 c4 10             	add    $0x10,%esp
  80032a:	85 ff                	test   %edi,%edi
  80032c:	74 24                	je     800352 <check_regs+0x31f>
  80032e:	eb 34                	jmp    800364 <check_regs+0x331>
	CHECK(edx, regs.reg_edx);
	CHECK(ecx, regs.reg_ecx);
	CHECK(eax, regs.reg_eax);
	CHECK(eip, eip);
	CHECK(eflags, eflags);
	CHECK(esp, esp);
  800330:	83 ec 0c             	sub    $0xc,%esp
  800333:	68 c8 15 80 00       	push   $0x8015c8
  800338:	e8 85 03 00 00       	call   8006c2 <cprintf>

#undef CHECK

	cprintf("Registers %s ", testname);
  80033d:	83 c4 08             	add    $0x8,%esp
  800340:	ff 75 0c             	pushl  0xc(%ebp)
  800343:	68 f9 15 80 00       	push   $0x8015f9
  800348:	e8 75 03 00 00       	call   8006c2 <cprintf>
  80034d:	83 c4 10             	add    $0x10,%esp
  800350:	eb 12                	jmp    800364 <check_regs+0x331>
	if (!mismatch)
		cprintf("OK\n");
  800352:	83 ec 0c             	sub    $0xc,%esp
  800355:	68 c4 15 80 00       	push   $0x8015c4
  80035a:	e8 63 03 00 00       	call   8006c2 <cprintf>
  80035f:	83 c4 10             	add    $0x10,%esp
  800362:	eb 34                	jmp    800398 <check_regs+0x365>
	else
		cprintf("MISMATCH\n");
  800364:	83 ec 0c             	sub    $0xc,%esp
  800367:	68 c8 15 80 00       	push   $0x8015c8
  80036c:	e8 51 03 00 00       	call   8006c2 <cprintf>
  800371:	83 c4 10             	add    $0x10,%esp
}
  800374:	eb 22                	jmp    800398 <check_regs+0x365>
	CHECK(edx, regs.reg_edx);
	CHECK(ecx, regs.reg_ecx);
	CHECK(eax, regs.reg_eax);
	CHECK(eip, eip);
	CHECK(eflags, eflags);
	CHECK(esp, esp);
  800376:	83 ec 0c             	sub    $0xc,%esp
  800379:	68 c4 15 80 00       	push   $0x8015c4
  80037e:	e8 3f 03 00 00       	call   8006c2 <cprintf>

#undef CHECK

	cprintf("Registers %s ", testname);
  800383:	83 c4 08             	add    $0x8,%esp
  800386:	ff 75 0c             	pushl  0xc(%ebp)
  800389:	68 f9 15 80 00       	push   $0x8015f9
  80038e:	e8 2f 03 00 00       	call   8006c2 <cprintf>
  800393:	83 c4 10             	add    $0x10,%esp
  800396:	eb cc                	jmp    800364 <check_regs+0x331>
	if (!mismatch)
		cprintf("OK\n");
	else
		cprintf("MISMATCH\n");
}
  800398:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80039b:	5b                   	pop    %ebx
  80039c:	5e                   	pop    %esi
  80039d:	5f                   	pop    %edi
  80039e:	5d                   	pop    %ebp
  80039f:	c3                   	ret    

008003a0 <pgfault>:

static void
pgfault(struct UTrapframe *utf)
{
  8003a0:	55                   	push   %ebp
  8003a1:	89 e5                	mov    %esp,%ebp
  8003a3:	83 ec 08             	sub    $0x8,%esp
  8003a6:	8b 45 08             	mov    0x8(%ebp),%eax
	int r;

	if (utf->utf_fault_va != (uint32_t)UTEMP)
  8003a9:	8b 10                	mov    (%eax),%edx
  8003ab:	81 fa 00 00 40 00    	cmp    $0x400000,%edx
  8003b1:	74 18                	je     8003cb <pgfault+0x2b>
		panic("pgfault expected at UTEMP, got 0x%08x (eip %08x)",
  8003b3:	83 ec 0c             	sub    $0xc,%esp
  8003b6:	ff 70 28             	pushl  0x28(%eax)
  8003b9:	52                   	push   %edx
  8003ba:	68 60 16 80 00       	push   $0x801660
  8003bf:	6a 51                	push   $0x51
  8003c1:	68 07 16 80 00       	push   $0x801607
  8003c6:	e8 1e 02 00 00       	call   8005e9 <_panic>
		      utf->utf_fault_va, utf->utf_eip);

	// Check registers in UTrapframe
	during.regs = utf->utf_regs;
  8003cb:	8b 50 08             	mov    0x8(%eax),%edx
  8003ce:	89 15 60 20 80 00    	mov    %edx,0x802060
  8003d4:	8b 50 0c             	mov    0xc(%eax),%edx
  8003d7:	89 15 64 20 80 00    	mov    %edx,0x802064
  8003dd:	8b 50 10             	mov    0x10(%eax),%edx
  8003e0:	89 15 68 20 80 00    	mov    %edx,0x802068
  8003e6:	8b 50 14             	mov    0x14(%eax),%edx
  8003e9:	89 15 6c 20 80 00    	mov    %edx,0x80206c
  8003ef:	8b 50 18             	mov    0x18(%eax),%edx
  8003f2:	89 15 70 20 80 00    	mov    %edx,0x802070
  8003f8:	8b 50 1c             	mov    0x1c(%eax),%edx
  8003fb:	89 15 74 20 80 00    	mov    %edx,0x802074
  800401:	8b 50 20             	mov    0x20(%eax),%edx
  800404:	89 15 78 20 80 00    	mov    %edx,0x802078
  80040a:	8b 50 24             	mov    0x24(%eax),%edx
  80040d:	89 15 7c 20 80 00    	mov    %edx,0x80207c
	during.eip = utf->utf_eip;
  800413:	8b 50 28             	mov    0x28(%eax),%edx
  800416:	89 15 80 20 80 00    	mov    %edx,0x802080
	during.eflags = utf->utf_eflags;
  80041c:	8b 50 2c             	mov    0x2c(%eax),%edx
  80041f:	89 15 84 20 80 00    	mov    %edx,0x802084
	during.esp = utf->utf_esp;
  800425:	8b 40 30             	mov    0x30(%eax),%eax
  800428:	a3 88 20 80 00       	mov    %eax,0x802088
	check_regs(&before, "before", &during, "during", "in UTrapframe");
  80042d:	83 ec 08             	sub    $0x8,%esp
  800430:	68 1f 16 80 00       	push   $0x80161f
  800435:	68 2d 16 80 00       	push   $0x80162d
  80043a:	b9 60 20 80 00       	mov    $0x802060,%ecx
  80043f:	ba 18 16 80 00       	mov    $0x801618,%edx
  800444:	b8 a0 20 80 00       	mov    $0x8020a0,%eax
  800449:	e8 e5 fb ff ff       	call   800033 <check_regs>

	// Map UTEMP so the write succeeds
	if ((r = sys_page_alloc(0, UTEMP, PTE_U|PTE_P|PTE_W)) < 0)
  80044e:	83 c4 0c             	add    $0xc,%esp
  800451:	6a 07                	push   $0x7
  800453:	68 00 00 40 00       	push   $0x400000
  800458:	6a 00                	push   $0x0
  80045a:	e8 6a 0c 00 00       	call   8010c9 <sys_page_alloc>
  80045f:	83 c4 10             	add    $0x10,%esp
  800462:	85 c0                	test   %eax,%eax
  800464:	79 12                	jns    800478 <pgfault+0xd8>
		panic("sys_page_alloc: %e", r);
  800466:	50                   	push   %eax
  800467:	68 34 16 80 00       	push   $0x801634
  80046c:	6a 5c                	push   $0x5c
  80046e:	68 07 16 80 00       	push   $0x801607
  800473:	e8 71 01 00 00       	call   8005e9 <_panic>
}
  800478:	c9                   	leave  
  800479:	c3                   	ret    

0080047a <umain>:

void
umain(int argc, char **argv)
{
  80047a:	55                   	push   %ebp
  80047b:	89 e5                	mov    %esp,%ebp
  80047d:	83 ec 14             	sub    $0x14,%esp
	set_pgfault_handler(pgfault);
  800480:	68 a0 03 80 00       	push   $0x8003a0
  800485:	e8 ee 0d 00 00       	call   801278 <set_pgfault_handler>

	__asm __volatile(
  80048a:	50                   	push   %eax
  80048b:	9c                   	pushf  
  80048c:	58                   	pop    %eax
  80048d:	0d d5 08 00 00       	or     $0x8d5,%eax
  800492:	50                   	push   %eax
  800493:	9d                   	popf   
  800494:	a3 c4 20 80 00       	mov    %eax,0x8020c4
  800499:	8d 05 d4 04 80 00    	lea    0x8004d4,%eax
  80049f:	a3 c0 20 80 00       	mov    %eax,0x8020c0
  8004a4:	58                   	pop    %eax
  8004a5:	89 3d a0 20 80 00    	mov    %edi,0x8020a0
  8004ab:	89 35 a4 20 80 00    	mov    %esi,0x8020a4
  8004b1:	89 2d a8 20 80 00    	mov    %ebp,0x8020a8
  8004b7:	89 1d b0 20 80 00    	mov    %ebx,0x8020b0
  8004bd:	89 15 b4 20 80 00    	mov    %edx,0x8020b4
  8004c3:	89 0d b8 20 80 00    	mov    %ecx,0x8020b8
  8004c9:	a3 bc 20 80 00       	mov    %eax,0x8020bc
  8004ce:	89 25 c8 20 80 00    	mov    %esp,0x8020c8
  8004d4:	c7 05 00 00 40 00 2a 	movl   $0x2a,0x400000
  8004db:	00 00 00 
  8004de:	89 3d 20 20 80 00    	mov    %edi,0x802020
  8004e4:	89 35 24 20 80 00    	mov    %esi,0x802024
  8004ea:	89 2d 28 20 80 00    	mov    %ebp,0x802028
  8004f0:	89 1d 30 20 80 00    	mov    %ebx,0x802030
  8004f6:	89 15 34 20 80 00    	mov    %edx,0x802034
  8004fc:	89 0d 38 20 80 00    	mov    %ecx,0x802038
  800502:	a3 3c 20 80 00       	mov    %eax,0x80203c
  800507:	89 25 48 20 80 00    	mov    %esp,0x802048
  80050d:	8b 3d a0 20 80 00    	mov    0x8020a0,%edi
  800513:	8b 35 a4 20 80 00    	mov    0x8020a4,%esi
  800519:	8b 2d a8 20 80 00    	mov    0x8020a8,%ebp
  80051f:	8b 1d b0 20 80 00    	mov    0x8020b0,%ebx
  800525:	8b 15 b4 20 80 00    	mov    0x8020b4,%edx
  80052b:	8b 0d b8 20 80 00    	mov    0x8020b8,%ecx
  800531:	a1 bc 20 80 00       	mov    0x8020bc,%eax
  800536:	8b 25 c8 20 80 00    	mov    0x8020c8,%esp
  80053c:	50                   	push   %eax
  80053d:	9c                   	pushf  
  80053e:	58                   	pop    %eax
  80053f:	a3 44 20 80 00       	mov    %eax,0x802044
  800544:	58                   	pop    %eax
		: : "m" (before), "m" (after) : "memory", "cc");

	// Check UTEMP to roughly determine that EIP was restored
	// correctly (of course, we probably wouldn't get this far if
	// it weren't)
	if (*(int*)UTEMP != 42)
  800545:	83 c4 10             	add    $0x10,%esp
  800548:	83 3d 00 00 40 00 2a 	cmpl   $0x2a,0x400000
  80054f:	74 10                	je     800561 <umain+0xe7>
		cprintf("EIP after page-fault MISMATCH\n");
  800551:	83 ec 0c             	sub    $0xc,%esp
  800554:	68 94 16 80 00       	push   $0x801694
  800559:	e8 64 01 00 00       	call   8006c2 <cprintf>
  80055e:	83 c4 10             	add    $0x10,%esp
	after.eip = before.eip;
  800561:	a1 c0 20 80 00       	mov    0x8020c0,%eax
  800566:	a3 40 20 80 00       	mov    %eax,0x802040

	check_regs(&before, "before", &after, "after", "after page-fault");
  80056b:	83 ec 08             	sub    $0x8,%esp
  80056e:	68 47 16 80 00       	push   $0x801647
  800573:	68 58 16 80 00       	push   $0x801658
  800578:	b9 20 20 80 00       	mov    $0x802020,%ecx
  80057d:	ba 18 16 80 00       	mov    $0x801618,%edx
  800582:	b8 a0 20 80 00       	mov    $0x8020a0,%eax
  800587:	e8 a7 fa ff ff       	call   800033 <check_regs>
}
  80058c:	83 c4 10             	add    $0x10,%esp
  80058f:	c9                   	leave  
  800590:	c3                   	ret    

00800591 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800591:	55                   	push   %ebp
  800592:	89 e5                	mov    %esp,%ebp
  800594:	56                   	push   %esi
  800595:	53                   	push   %ebx
  800596:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800599:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = &envs[ENVX(sys_getenvid())];
  80059c:	e8 ea 0a 00 00       	call   80108b <sys_getenvid>
  8005a1:	25 ff 03 00 00       	and    $0x3ff,%eax
  8005a6:	6b c0 7c             	imul   $0x7c,%eax,%eax
  8005a9:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  8005ae:	a3 cc 20 80 00       	mov    %eax,0x8020cc
	// save the name of the program so that panic() can use it
	if (argc > 0)
  8005b3:	85 db                	test   %ebx,%ebx
  8005b5:	7e 07                	jle    8005be <libmain+0x2d>
		binaryname = argv[0];
  8005b7:	8b 06                	mov    (%esi),%eax
  8005b9:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  8005be:	83 ec 08             	sub    $0x8,%esp
  8005c1:	56                   	push   %esi
  8005c2:	53                   	push   %ebx
  8005c3:	e8 b2 fe ff ff       	call   80047a <umain>

	// exit gracefully
	exit();
  8005c8:	e8 0a 00 00 00       	call   8005d7 <exit>
}
  8005cd:	83 c4 10             	add    $0x10,%esp
  8005d0:	8d 65 f8             	lea    -0x8(%ebp),%esp
  8005d3:	5b                   	pop    %ebx
  8005d4:	5e                   	pop    %esi
  8005d5:	5d                   	pop    %ebp
  8005d6:	c3                   	ret    

008005d7 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  8005d7:	55                   	push   %ebp
  8005d8:	89 e5                	mov    %esp,%ebp
  8005da:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  8005dd:	6a 00                	push   $0x0
  8005df:	e8 66 0a 00 00       	call   80104a <sys_env_destroy>
}
  8005e4:	83 c4 10             	add    $0x10,%esp
  8005e7:	c9                   	leave  
  8005e8:	c3                   	ret    

008005e9 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  8005e9:	55                   	push   %ebp
  8005ea:	89 e5                	mov    %esp,%ebp
  8005ec:	56                   	push   %esi
  8005ed:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  8005ee:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  8005f1:	8b 35 00 20 80 00    	mov    0x802000,%esi
  8005f7:	e8 8f 0a 00 00       	call   80108b <sys_getenvid>
  8005fc:	83 ec 0c             	sub    $0xc,%esp
  8005ff:	ff 75 0c             	pushl  0xc(%ebp)
  800602:	ff 75 08             	pushl  0x8(%ebp)
  800605:	56                   	push   %esi
  800606:	50                   	push   %eax
  800607:	68 c0 16 80 00       	push   $0x8016c0
  80060c:	e8 b1 00 00 00       	call   8006c2 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800611:	83 c4 18             	add    $0x18,%esp
  800614:	53                   	push   %ebx
  800615:	ff 75 10             	pushl  0x10(%ebp)
  800618:	e8 54 00 00 00       	call   800671 <vcprintf>
	cprintf("\n");
  80061d:	c7 04 24 d0 15 80 00 	movl   $0x8015d0,(%esp)
  800624:	e8 99 00 00 00       	call   8006c2 <cprintf>
  800629:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  80062c:	cc                   	int3   
  80062d:	eb fd                	jmp    80062c <_panic+0x43>

0080062f <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  80062f:	55                   	push   %ebp
  800630:	89 e5                	mov    %esp,%ebp
  800632:	53                   	push   %ebx
  800633:	83 ec 04             	sub    $0x4,%esp
  800636:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  800639:	8b 13                	mov    (%ebx),%edx
  80063b:	8d 42 01             	lea    0x1(%edx),%eax
  80063e:	89 03                	mov    %eax,(%ebx)
  800640:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800643:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  800647:	3d ff 00 00 00       	cmp    $0xff,%eax
  80064c:	75 1a                	jne    800668 <putch+0x39>
		sys_cputs(b->buf, b->idx);
  80064e:	83 ec 08             	sub    $0x8,%esp
  800651:	68 ff 00 00 00       	push   $0xff
  800656:	8d 43 08             	lea    0x8(%ebx),%eax
  800659:	50                   	push   %eax
  80065a:	e8 ae 09 00 00       	call   80100d <sys_cputs>
		b->idx = 0;
  80065f:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  800665:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  800668:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  80066c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  80066f:	c9                   	leave  
  800670:	c3                   	ret    

00800671 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  800671:	55                   	push   %ebp
  800672:	89 e5                	mov    %esp,%ebp
  800674:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  80067a:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  800681:	00 00 00 
	b.cnt = 0;
  800684:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  80068b:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  80068e:	ff 75 0c             	pushl  0xc(%ebp)
  800691:	ff 75 08             	pushl  0x8(%ebp)
  800694:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  80069a:	50                   	push   %eax
  80069b:	68 2f 06 80 00       	push   $0x80062f
  8006a0:	e8 1a 01 00 00       	call   8007bf <vprintfmt>
	sys_cputs(b.buf, b.idx);
  8006a5:	83 c4 08             	add    $0x8,%esp
  8006a8:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  8006ae:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  8006b4:	50                   	push   %eax
  8006b5:	e8 53 09 00 00       	call   80100d <sys_cputs>

	return b.cnt;
}
  8006ba:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  8006c0:	c9                   	leave  
  8006c1:	c3                   	ret    

008006c2 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  8006c2:	55                   	push   %ebp
  8006c3:	89 e5                	mov    %esp,%ebp
  8006c5:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  8006c8:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  8006cb:	50                   	push   %eax
  8006cc:	ff 75 08             	pushl  0x8(%ebp)
  8006cf:	e8 9d ff ff ff       	call   800671 <vcprintf>
	va_end(ap);

	return cnt;
}
  8006d4:	c9                   	leave  
  8006d5:	c3                   	ret    

008006d6 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  8006d6:	55                   	push   %ebp
  8006d7:	89 e5                	mov    %esp,%ebp
  8006d9:	57                   	push   %edi
  8006da:	56                   	push   %esi
  8006db:	53                   	push   %ebx
  8006dc:	83 ec 1c             	sub    $0x1c,%esp
  8006df:	89 c7                	mov    %eax,%edi
  8006e1:	89 d6                	mov    %edx,%esi
  8006e3:	8b 45 08             	mov    0x8(%ebp),%eax
  8006e6:	8b 55 0c             	mov    0xc(%ebp),%edx
  8006e9:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8006ec:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  8006ef:	8b 4d 10             	mov    0x10(%ebp),%ecx
  8006f2:	bb 00 00 00 00       	mov    $0x0,%ebx
  8006f7:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  8006fa:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  8006fd:	39 d3                	cmp    %edx,%ebx
  8006ff:	72 05                	jb     800706 <printnum+0x30>
  800701:	39 45 10             	cmp    %eax,0x10(%ebp)
  800704:	77 45                	ja     80074b <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800706:	83 ec 0c             	sub    $0xc,%esp
  800709:	ff 75 18             	pushl  0x18(%ebp)
  80070c:	8b 45 14             	mov    0x14(%ebp),%eax
  80070f:	8d 58 ff             	lea    -0x1(%eax),%ebx
  800712:	53                   	push   %ebx
  800713:	ff 75 10             	pushl  0x10(%ebp)
  800716:	83 ec 08             	sub    $0x8,%esp
  800719:	ff 75 e4             	pushl  -0x1c(%ebp)
  80071c:	ff 75 e0             	pushl  -0x20(%ebp)
  80071f:	ff 75 dc             	pushl  -0x24(%ebp)
  800722:	ff 75 d8             	pushl  -0x28(%ebp)
  800725:	e8 e6 0b 00 00       	call   801310 <__udivdi3>
  80072a:	83 c4 18             	add    $0x18,%esp
  80072d:	52                   	push   %edx
  80072e:	50                   	push   %eax
  80072f:	89 f2                	mov    %esi,%edx
  800731:	89 f8                	mov    %edi,%eax
  800733:	e8 9e ff ff ff       	call   8006d6 <printnum>
  800738:	83 c4 20             	add    $0x20,%esp
  80073b:	eb 18                	jmp    800755 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  80073d:	83 ec 08             	sub    $0x8,%esp
  800740:	56                   	push   %esi
  800741:	ff 75 18             	pushl  0x18(%ebp)
  800744:	ff d7                	call   *%edi
  800746:	83 c4 10             	add    $0x10,%esp
  800749:	eb 03                	jmp    80074e <printnum+0x78>
  80074b:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  80074e:	83 eb 01             	sub    $0x1,%ebx
  800751:	85 db                	test   %ebx,%ebx
  800753:	7f e8                	jg     80073d <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  800755:	83 ec 08             	sub    $0x8,%esp
  800758:	56                   	push   %esi
  800759:	83 ec 04             	sub    $0x4,%esp
  80075c:	ff 75 e4             	pushl  -0x1c(%ebp)
  80075f:	ff 75 e0             	pushl  -0x20(%ebp)
  800762:	ff 75 dc             	pushl  -0x24(%ebp)
  800765:	ff 75 d8             	pushl  -0x28(%ebp)
  800768:	e8 d3 0c 00 00       	call   801440 <__umoddi3>
  80076d:	83 c4 14             	add    $0x14,%esp
  800770:	0f be 80 e3 16 80 00 	movsbl 0x8016e3(%eax),%eax
  800777:	50                   	push   %eax
  800778:	ff d7                	call   *%edi
}
  80077a:	83 c4 10             	add    $0x10,%esp
  80077d:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800780:	5b                   	pop    %ebx
  800781:	5e                   	pop    %esi
  800782:	5f                   	pop    %edi
  800783:	5d                   	pop    %ebp
  800784:	c3                   	ret    

00800785 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  800785:	55                   	push   %ebp
  800786:	89 e5                	mov    %esp,%ebp
  800788:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  80078b:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  80078f:	8b 10                	mov    (%eax),%edx
  800791:	3b 50 04             	cmp    0x4(%eax),%edx
  800794:	73 0a                	jae    8007a0 <sprintputch+0x1b>
		*b->buf++ = ch;
  800796:	8d 4a 01             	lea    0x1(%edx),%ecx
  800799:	89 08                	mov    %ecx,(%eax)
  80079b:	8b 45 08             	mov    0x8(%ebp),%eax
  80079e:	88 02                	mov    %al,(%edx)
}
  8007a0:	5d                   	pop    %ebp
  8007a1:	c3                   	ret    

008007a2 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8007a2:	55                   	push   %ebp
  8007a3:	89 e5                	mov    %esp,%ebp
  8007a5:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  8007a8:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8007ab:	50                   	push   %eax
  8007ac:	ff 75 10             	pushl  0x10(%ebp)
  8007af:	ff 75 0c             	pushl  0xc(%ebp)
  8007b2:	ff 75 08             	pushl  0x8(%ebp)
  8007b5:	e8 05 00 00 00       	call   8007bf <vprintfmt>
	va_end(ap);
}
  8007ba:	83 c4 10             	add    $0x10,%esp
  8007bd:	c9                   	leave  
  8007be:	c3                   	ret    

008007bf <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8007bf:	55                   	push   %ebp
  8007c0:	89 e5                	mov    %esp,%ebp
  8007c2:	57                   	push   %edi
  8007c3:	56                   	push   %esi
  8007c4:	53                   	push   %ebx
  8007c5:	83 ec 2c             	sub    $0x2c,%esp
  8007c8:	8b 75 08             	mov    0x8(%ebp),%esi
  8007cb:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8007ce:	8b 7d 10             	mov    0x10(%ebp),%edi
  8007d1:	eb 12                	jmp    8007e5 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  8007d3:	85 c0                	test   %eax,%eax
  8007d5:	0f 84 42 04 00 00    	je     800c1d <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
  8007db:	83 ec 08             	sub    $0x8,%esp
  8007de:	53                   	push   %ebx
  8007df:	50                   	push   %eax
  8007e0:	ff d6                	call   *%esi
  8007e2:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  8007e5:	83 c7 01             	add    $0x1,%edi
  8007e8:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8007ec:	83 f8 25             	cmp    $0x25,%eax
  8007ef:	75 e2                	jne    8007d3 <vprintfmt+0x14>
  8007f1:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  8007f5:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  8007fc:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800803:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  80080a:	b9 00 00 00 00       	mov    $0x0,%ecx
  80080f:	eb 07                	jmp    800818 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800811:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  800814:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800818:	8d 47 01             	lea    0x1(%edi),%eax
  80081b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  80081e:	0f b6 07             	movzbl (%edi),%eax
  800821:	0f b6 d0             	movzbl %al,%edx
  800824:	83 e8 23             	sub    $0x23,%eax
  800827:	3c 55                	cmp    $0x55,%al
  800829:	0f 87 d3 03 00 00    	ja     800c02 <vprintfmt+0x443>
  80082f:	0f b6 c0             	movzbl %al,%eax
  800832:	ff 24 85 a0 17 80 00 	jmp    *0x8017a0(,%eax,4)
  800839:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  80083c:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  800840:	eb d6                	jmp    800818 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800842:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800845:	b8 00 00 00 00       	mov    $0x0,%eax
  80084a:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  80084d:	8d 04 80             	lea    (%eax,%eax,4),%eax
  800850:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
  800854:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
  800857:	8d 4a d0             	lea    -0x30(%edx),%ecx
  80085a:	83 f9 09             	cmp    $0x9,%ecx
  80085d:	77 3f                	ja     80089e <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  80085f:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  800862:	eb e9                	jmp    80084d <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  800864:	8b 45 14             	mov    0x14(%ebp),%eax
  800867:	8b 00                	mov    (%eax),%eax
  800869:	89 45 d0             	mov    %eax,-0x30(%ebp)
  80086c:	8b 45 14             	mov    0x14(%ebp),%eax
  80086f:	8d 40 04             	lea    0x4(%eax),%eax
  800872:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800875:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  800878:	eb 2a                	jmp    8008a4 <vprintfmt+0xe5>
  80087a:	8b 45 e0             	mov    -0x20(%ebp),%eax
  80087d:	85 c0                	test   %eax,%eax
  80087f:	ba 00 00 00 00       	mov    $0x0,%edx
  800884:	0f 49 d0             	cmovns %eax,%edx
  800887:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80088a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80088d:	eb 89                	jmp    800818 <vprintfmt+0x59>
  80088f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  800892:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  800899:	e9 7a ff ff ff       	jmp    800818 <vprintfmt+0x59>
  80089e:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  8008a1:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  8008a4:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8008a8:	0f 89 6a ff ff ff    	jns    800818 <vprintfmt+0x59>
				width = precision, precision = -1;
  8008ae:	8b 45 d0             	mov    -0x30(%ebp),%eax
  8008b1:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8008b4:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8008bb:	e9 58 ff ff ff       	jmp    800818 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  8008c0:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8008c3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  8008c6:	e9 4d ff ff ff       	jmp    800818 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  8008cb:	8b 45 14             	mov    0x14(%ebp),%eax
  8008ce:	8d 78 04             	lea    0x4(%eax),%edi
  8008d1:	83 ec 08             	sub    $0x8,%esp
  8008d4:	53                   	push   %ebx
  8008d5:	ff 30                	pushl  (%eax)
  8008d7:	ff d6                	call   *%esi
			break;
  8008d9:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  8008dc:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8008df:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  8008e2:	e9 fe fe ff ff       	jmp    8007e5 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  8008e7:	8b 45 14             	mov    0x14(%ebp),%eax
  8008ea:	8d 78 04             	lea    0x4(%eax),%edi
  8008ed:	8b 00                	mov    (%eax),%eax
  8008ef:	99                   	cltd   
  8008f0:	31 d0                	xor    %edx,%eax
  8008f2:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  8008f4:	83 f8 09             	cmp    $0x9,%eax
  8008f7:	7f 0b                	jg     800904 <vprintfmt+0x145>
  8008f9:	8b 14 85 00 19 80 00 	mov    0x801900(,%eax,4),%edx
  800900:	85 d2                	test   %edx,%edx
  800902:	75 1b                	jne    80091f <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
  800904:	50                   	push   %eax
  800905:	68 fb 16 80 00       	push   $0x8016fb
  80090a:	53                   	push   %ebx
  80090b:	56                   	push   %esi
  80090c:	e8 91 fe ff ff       	call   8007a2 <printfmt>
  800911:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  800914:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800917:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  80091a:	e9 c6 fe ff ff       	jmp    8007e5 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  80091f:	52                   	push   %edx
  800920:	68 04 17 80 00       	push   $0x801704
  800925:	53                   	push   %ebx
  800926:	56                   	push   %esi
  800927:	e8 76 fe ff ff       	call   8007a2 <printfmt>
  80092c:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  80092f:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800932:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800935:	e9 ab fe ff ff       	jmp    8007e5 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  80093a:	8b 45 14             	mov    0x14(%ebp),%eax
  80093d:	83 c0 04             	add    $0x4,%eax
  800940:	89 45 cc             	mov    %eax,-0x34(%ebp)
  800943:	8b 45 14             	mov    0x14(%ebp),%eax
  800946:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  800948:	85 ff                	test   %edi,%edi
  80094a:	b8 f4 16 80 00       	mov    $0x8016f4,%eax
  80094f:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  800952:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800956:	0f 8e 94 00 00 00    	jle    8009f0 <vprintfmt+0x231>
  80095c:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  800960:	0f 84 98 00 00 00    	je     8009fe <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
  800966:	83 ec 08             	sub    $0x8,%esp
  800969:	ff 75 d0             	pushl  -0x30(%ebp)
  80096c:	57                   	push   %edi
  80096d:	e8 33 03 00 00       	call   800ca5 <strnlen>
  800972:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  800975:	29 c1                	sub    %eax,%ecx
  800977:	89 4d c8             	mov    %ecx,-0x38(%ebp)
  80097a:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  80097d:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  800981:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800984:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  800987:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800989:	eb 0f                	jmp    80099a <vprintfmt+0x1db>
					putch(padc, putdat);
  80098b:	83 ec 08             	sub    $0x8,%esp
  80098e:	53                   	push   %ebx
  80098f:	ff 75 e0             	pushl  -0x20(%ebp)
  800992:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800994:	83 ef 01             	sub    $0x1,%edi
  800997:	83 c4 10             	add    $0x10,%esp
  80099a:	85 ff                	test   %edi,%edi
  80099c:	7f ed                	jg     80098b <vprintfmt+0x1cc>
  80099e:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  8009a1:	8b 4d c8             	mov    -0x38(%ebp),%ecx
  8009a4:	85 c9                	test   %ecx,%ecx
  8009a6:	b8 00 00 00 00       	mov    $0x0,%eax
  8009ab:	0f 49 c1             	cmovns %ecx,%eax
  8009ae:	29 c1                	sub    %eax,%ecx
  8009b0:	89 75 08             	mov    %esi,0x8(%ebp)
  8009b3:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8009b6:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8009b9:	89 cb                	mov    %ecx,%ebx
  8009bb:	eb 4d                	jmp    800a0a <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  8009bd:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8009c1:	74 1b                	je     8009de <vprintfmt+0x21f>
  8009c3:	0f be c0             	movsbl %al,%eax
  8009c6:	83 e8 20             	sub    $0x20,%eax
  8009c9:	83 f8 5e             	cmp    $0x5e,%eax
  8009cc:	76 10                	jbe    8009de <vprintfmt+0x21f>
					putch('?', putdat);
  8009ce:	83 ec 08             	sub    $0x8,%esp
  8009d1:	ff 75 0c             	pushl  0xc(%ebp)
  8009d4:	6a 3f                	push   $0x3f
  8009d6:	ff 55 08             	call   *0x8(%ebp)
  8009d9:	83 c4 10             	add    $0x10,%esp
  8009dc:	eb 0d                	jmp    8009eb <vprintfmt+0x22c>
				else
					putch(ch, putdat);
  8009de:	83 ec 08             	sub    $0x8,%esp
  8009e1:	ff 75 0c             	pushl  0xc(%ebp)
  8009e4:	52                   	push   %edx
  8009e5:	ff 55 08             	call   *0x8(%ebp)
  8009e8:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8009eb:	83 eb 01             	sub    $0x1,%ebx
  8009ee:	eb 1a                	jmp    800a0a <vprintfmt+0x24b>
  8009f0:	89 75 08             	mov    %esi,0x8(%ebp)
  8009f3:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8009f6:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8009f9:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8009fc:	eb 0c                	jmp    800a0a <vprintfmt+0x24b>
  8009fe:	89 75 08             	mov    %esi,0x8(%ebp)
  800a01:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800a04:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800a07:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800a0a:	83 c7 01             	add    $0x1,%edi
  800a0d:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800a11:	0f be d0             	movsbl %al,%edx
  800a14:	85 d2                	test   %edx,%edx
  800a16:	74 23                	je     800a3b <vprintfmt+0x27c>
  800a18:	85 f6                	test   %esi,%esi
  800a1a:	78 a1                	js     8009bd <vprintfmt+0x1fe>
  800a1c:	83 ee 01             	sub    $0x1,%esi
  800a1f:	79 9c                	jns    8009bd <vprintfmt+0x1fe>
  800a21:	89 df                	mov    %ebx,%edi
  800a23:	8b 75 08             	mov    0x8(%ebp),%esi
  800a26:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800a29:	eb 18                	jmp    800a43 <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800a2b:	83 ec 08             	sub    $0x8,%esp
  800a2e:	53                   	push   %ebx
  800a2f:	6a 20                	push   $0x20
  800a31:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800a33:	83 ef 01             	sub    $0x1,%edi
  800a36:	83 c4 10             	add    $0x10,%esp
  800a39:	eb 08                	jmp    800a43 <vprintfmt+0x284>
  800a3b:	89 df                	mov    %ebx,%edi
  800a3d:	8b 75 08             	mov    0x8(%ebp),%esi
  800a40:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800a43:	85 ff                	test   %edi,%edi
  800a45:	7f e4                	jg     800a2b <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800a47:	8b 45 cc             	mov    -0x34(%ebp),%eax
  800a4a:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800a4d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800a50:	e9 90 fd ff ff       	jmp    8007e5 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800a55:	83 f9 01             	cmp    $0x1,%ecx
  800a58:	7e 19                	jle    800a73 <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
  800a5a:	8b 45 14             	mov    0x14(%ebp),%eax
  800a5d:	8b 50 04             	mov    0x4(%eax),%edx
  800a60:	8b 00                	mov    (%eax),%eax
  800a62:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800a65:	89 55 dc             	mov    %edx,-0x24(%ebp)
  800a68:	8b 45 14             	mov    0x14(%ebp),%eax
  800a6b:	8d 40 08             	lea    0x8(%eax),%eax
  800a6e:	89 45 14             	mov    %eax,0x14(%ebp)
  800a71:	eb 38                	jmp    800aab <vprintfmt+0x2ec>
	else if (lflag)
  800a73:	85 c9                	test   %ecx,%ecx
  800a75:	74 1b                	je     800a92 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
  800a77:	8b 45 14             	mov    0x14(%ebp),%eax
  800a7a:	8b 00                	mov    (%eax),%eax
  800a7c:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800a7f:	89 c1                	mov    %eax,%ecx
  800a81:	c1 f9 1f             	sar    $0x1f,%ecx
  800a84:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  800a87:	8b 45 14             	mov    0x14(%ebp),%eax
  800a8a:	8d 40 04             	lea    0x4(%eax),%eax
  800a8d:	89 45 14             	mov    %eax,0x14(%ebp)
  800a90:	eb 19                	jmp    800aab <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
  800a92:	8b 45 14             	mov    0x14(%ebp),%eax
  800a95:	8b 00                	mov    (%eax),%eax
  800a97:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800a9a:	89 c1                	mov    %eax,%ecx
  800a9c:	c1 f9 1f             	sar    $0x1f,%ecx
  800a9f:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  800aa2:	8b 45 14             	mov    0x14(%ebp),%eax
  800aa5:	8d 40 04             	lea    0x4(%eax),%eax
  800aa8:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800aab:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800aae:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800ab1:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800ab6:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800aba:	0f 89 0e 01 00 00    	jns    800bce <vprintfmt+0x40f>
				putch('-', putdat);
  800ac0:	83 ec 08             	sub    $0x8,%esp
  800ac3:	53                   	push   %ebx
  800ac4:	6a 2d                	push   $0x2d
  800ac6:	ff d6                	call   *%esi
				num = -(long long) num;
  800ac8:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800acb:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800ace:	f7 da                	neg    %edx
  800ad0:	83 d1 00             	adc    $0x0,%ecx
  800ad3:	f7 d9                	neg    %ecx
  800ad5:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  800ad8:	b8 0a 00 00 00       	mov    $0xa,%eax
  800add:	e9 ec 00 00 00       	jmp    800bce <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800ae2:	83 f9 01             	cmp    $0x1,%ecx
  800ae5:	7e 18                	jle    800aff <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
  800ae7:	8b 45 14             	mov    0x14(%ebp),%eax
  800aea:	8b 10                	mov    (%eax),%edx
  800aec:	8b 48 04             	mov    0x4(%eax),%ecx
  800aef:	8d 40 08             	lea    0x8(%eax),%eax
  800af2:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800af5:	b8 0a 00 00 00       	mov    $0xa,%eax
  800afa:	e9 cf 00 00 00       	jmp    800bce <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  800aff:	85 c9                	test   %ecx,%ecx
  800b01:	74 1a                	je     800b1d <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
  800b03:	8b 45 14             	mov    0x14(%ebp),%eax
  800b06:	8b 10                	mov    (%eax),%edx
  800b08:	b9 00 00 00 00       	mov    $0x0,%ecx
  800b0d:	8d 40 04             	lea    0x4(%eax),%eax
  800b10:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800b13:	b8 0a 00 00 00       	mov    $0xa,%eax
  800b18:	e9 b1 00 00 00       	jmp    800bce <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  800b1d:	8b 45 14             	mov    0x14(%ebp),%eax
  800b20:	8b 10                	mov    (%eax),%edx
  800b22:	b9 00 00 00 00       	mov    $0x0,%ecx
  800b27:	8d 40 04             	lea    0x4(%eax),%eax
  800b2a:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800b2d:	b8 0a 00 00 00       	mov    $0xa,%eax
  800b32:	e9 97 00 00 00       	jmp    800bce <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
  800b37:	83 ec 08             	sub    $0x8,%esp
  800b3a:	53                   	push   %ebx
  800b3b:	6a 58                	push   $0x58
  800b3d:	ff d6                	call   *%esi
			putch('X', putdat);
  800b3f:	83 c4 08             	add    $0x8,%esp
  800b42:	53                   	push   %ebx
  800b43:	6a 58                	push   $0x58
  800b45:	ff d6                	call   *%esi
			putch('X', putdat);
  800b47:	83 c4 08             	add    $0x8,%esp
  800b4a:	53                   	push   %ebx
  800b4b:	6a 58                	push   $0x58
  800b4d:	ff d6                	call   *%esi
			break;
  800b4f:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800b52:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
  800b55:	e9 8b fc ff ff       	jmp    8007e5 <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
  800b5a:	83 ec 08             	sub    $0x8,%esp
  800b5d:	53                   	push   %ebx
  800b5e:	6a 30                	push   $0x30
  800b60:	ff d6                	call   *%esi
			putch('x', putdat);
  800b62:	83 c4 08             	add    $0x8,%esp
  800b65:	53                   	push   %ebx
  800b66:	6a 78                	push   $0x78
  800b68:	ff d6                	call   *%esi
			num = (unsigned long long)
  800b6a:	8b 45 14             	mov    0x14(%ebp),%eax
  800b6d:	8b 10                	mov    (%eax),%edx
  800b6f:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  800b74:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  800b77:	8d 40 04             	lea    0x4(%eax),%eax
  800b7a:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  800b7d:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
  800b82:	eb 4a                	jmp    800bce <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800b84:	83 f9 01             	cmp    $0x1,%ecx
  800b87:	7e 15                	jle    800b9e <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
  800b89:	8b 45 14             	mov    0x14(%ebp),%eax
  800b8c:	8b 10                	mov    (%eax),%edx
  800b8e:	8b 48 04             	mov    0x4(%eax),%ecx
  800b91:	8d 40 08             	lea    0x8(%eax),%eax
  800b94:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800b97:	b8 10 00 00 00       	mov    $0x10,%eax
  800b9c:	eb 30                	jmp    800bce <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  800b9e:	85 c9                	test   %ecx,%ecx
  800ba0:	74 17                	je     800bb9 <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
  800ba2:	8b 45 14             	mov    0x14(%ebp),%eax
  800ba5:	8b 10                	mov    (%eax),%edx
  800ba7:	b9 00 00 00 00       	mov    $0x0,%ecx
  800bac:	8d 40 04             	lea    0x4(%eax),%eax
  800baf:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800bb2:	b8 10 00 00 00       	mov    $0x10,%eax
  800bb7:	eb 15                	jmp    800bce <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  800bb9:	8b 45 14             	mov    0x14(%ebp),%eax
  800bbc:	8b 10                	mov    (%eax),%edx
  800bbe:	b9 00 00 00 00       	mov    $0x0,%ecx
  800bc3:	8d 40 04             	lea    0x4(%eax),%eax
  800bc6:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800bc9:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
  800bce:	83 ec 0c             	sub    $0xc,%esp
  800bd1:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  800bd5:	57                   	push   %edi
  800bd6:	ff 75 e0             	pushl  -0x20(%ebp)
  800bd9:	50                   	push   %eax
  800bda:	51                   	push   %ecx
  800bdb:	52                   	push   %edx
  800bdc:	89 da                	mov    %ebx,%edx
  800bde:	89 f0                	mov    %esi,%eax
  800be0:	e8 f1 fa ff ff       	call   8006d6 <printnum>
			break;
  800be5:	83 c4 20             	add    $0x20,%esp
  800be8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800beb:	e9 f5 fb ff ff       	jmp    8007e5 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  800bf0:	83 ec 08             	sub    $0x8,%esp
  800bf3:	53                   	push   %ebx
  800bf4:	52                   	push   %edx
  800bf5:	ff d6                	call   *%esi
			break;
  800bf7:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800bfa:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  800bfd:	e9 e3 fb ff ff       	jmp    8007e5 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  800c02:	83 ec 08             	sub    $0x8,%esp
  800c05:	53                   	push   %ebx
  800c06:	6a 25                	push   $0x25
  800c08:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800c0a:	83 c4 10             	add    $0x10,%esp
  800c0d:	eb 03                	jmp    800c12 <vprintfmt+0x453>
  800c0f:	83 ef 01             	sub    $0x1,%edi
  800c12:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800c16:	75 f7                	jne    800c0f <vprintfmt+0x450>
  800c18:	e9 c8 fb ff ff       	jmp    8007e5 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  800c1d:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800c20:	5b                   	pop    %ebx
  800c21:	5e                   	pop    %esi
  800c22:	5f                   	pop    %edi
  800c23:	5d                   	pop    %ebp
  800c24:	c3                   	ret    

00800c25 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800c25:	55                   	push   %ebp
  800c26:	89 e5                	mov    %esp,%ebp
  800c28:	83 ec 18             	sub    $0x18,%esp
  800c2b:	8b 45 08             	mov    0x8(%ebp),%eax
  800c2e:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800c31:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800c34:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800c38:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800c3b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800c42:	85 c0                	test   %eax,%eax
  800c44:	74 26                	je     800c6c <vsnprintf+0x47>
  800c46:	85 d2                	test   %edx,%edx
  800c48:	7e 22                	jle    800c6c <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800c4a:	ff 75 14             	pushl  0x14(%ebp)
  800c4d:	ff 75 10             	pushl  0x10(%ebp)
  800c50:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800c53:	50                   	push   %eax
  800c54:	68 85 07 80 00       	push   $0x800785
  800c59:	e8 61 fb ff ff       	call   8007bf <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800c5e:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800c61:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800c64:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800c67:	83 c4 10             	add    $0x10,%esp
  800c6a:	eb 05                	jmp    800c71 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800c6c:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800c71:	c9                   	leave  
  800c72:	c3                   	ret    

00800c73 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800c73:	55                   	push   %ebp
  800c74:	89 e5                	mov    %esp,%ebp
  800c76:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800c79:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800c7c:	50                   	push   %eax
  800c7d:	ff 75 10             	pushl  0x10(%ebp)
  800c80:	ff 75 0c             	pushl  0xc(%ebp)
  800c83:	ff 75 08             	pushl  0x8(%ebp)
  800c86:	e8 9a ff ff ff       	call   800c25 <vsnprintf>
	va_end(ap);

	return rc;
}
  800c8b:	c9                   	leave  
  800c8c:	c3                   	ret    

00800c8d <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800c8d:	55                   	push   %ebp
  800c8e:	89 e5                	mov    %esp,%ebp
  800c90:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800c93:	b8 00 00 00 00       	mov    $0x0,%eax
  800c98:	eb 03                	jmp    800c9d <strlen+0x10>
		n++;
  800c9a:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800c9d:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800ca1:	75 f7                	jne    800c9a <strlen+0xd>
		n++;
	return n;
}
  800ca3:	5d                   	pop    %ebp
  800ca4:	c3                   	ret    

00800ca5 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800ca5:	55                   	push   %ebp
  800ca6:	89 e5                	mov    %esp,%ebp
  800ca8:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800cab:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800cae:	ba 00 00 00 00       	mov    $0x0,%edx
  800cb3:	eb 03                	jmp    800cb8 <strnlen+0x13>
		n++;
  800cb5:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800cb8:	39 c2                	cmp    %eax,%edx
  800cba:	74 08                	je     800cc4 <strnlen+0x1f>
  800cbc:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  800cc0:	75 f3                	jne    800cb5 <strnlen+0x10>
  800cc2:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  800cc4:	5d                   	pop    %ebp
  800cc5:	c3                   	ret    

00800cc6 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800cc6:	55                   	push   %ebp
  800cc7:	89 e5                	mov    %esp,%ebp
  800cc9:	53                   	push   %ebx
  800cca:	8b 45 08             	mov    0x8(%ebp),%eax
  800ccd:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800cd0:	89 c2                	mov    %eax,%edx
  800cd2:	83 c2 01             	add    $0x1,%edx
  800cd5:	83 c1 01             	add    $0x1,%ecx
  800cd8:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  800cdc:	88 5a ff             	mov    %bl,-0x1(%edx)
  800cdf:	84 db                	test   %bl,%bl
  800ce1:	75 ef                	jne    800cd2 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800ce3:	5b                   	pop    %ebx
  800ce4:	5d                   	pop    %ebp
  800ce5:	c3                   	ret    

00800ce6 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800ce6:	55                   	push   %ebp
  800ce7:	89 e5                	mov    %esp,%ebp
  800ce9:	53                   	push   %ebx
  800cea:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800ced:	53                   	push   %ebx
  800cee:	e8 9a ff ff ff       	call   800c8d <strlen>
  800cf3:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  800cf6:	ff 75 0c             	pushl  0xc(%ebp)
  800cf9:	01 d8                	add    %ebx,%eax
  800cfb:	50                   	push   %eax
  800cfc:	e8 c5 ff ff ff       	call   800cc6 <strcpy>
	return dst;
}
  800d01:	89 d8                	mov    %ebx,%eax
  800d03:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800d06:	c9                   	leave  
  800d07:	c3                   	ret    

00800d08 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800d08:	55                   	push   %ebp
  800d09:	89 e5                	mov    %esp,%ebp
  800d0b:	56                   	push   %esi
  800d0c:	53                   	push   %ebx
  800d0d:	8b 75 08             	mov    0x8(%ebp),%esi
  800d10:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800d13:	89 f3                	mov    %esi,%ebx
  800d15:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800d18:	89 f2                	mov    %esi,%edx
  800d1a:	eb 0f                	jmp    800d2b <strncpy+0x23>
		*dst++ = *src;
  800d1c:	83 c2 01             	add    $0x1,%edx
  800d1f:	0f b6 01             	movzbl (%ecx),%eax
  800d22:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800d25:	80 39 01             	cmpb   $0x1,(%ecx)
  800d28:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800d2b:	39 da                	cmp    %ebx,%edx
  800d2d:	75 ed                	jne    800d1c <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800d2f:	89 f0                	mov    %esi,%eax
  800d31:	5b                   	pop    %ebx
  800d32:	5e                   	pop    %esi
  800d33:	5d                   	pop    %ebp
  800d34:	c3                   	ret    

00800d35 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800d35:	55                   	push   %ebp
  800d36:	89 e5                	mov    %esp,%ebp
  800d38:	56                   	push   %esi
  800d39:	53                   	push   %ebx
  800d3a:	8b 75 08             	mov    0x8(%ebp),%esi
  800d3d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800d40:	8b 55 10             	mov    0x10(%ebp),%edx
  800d43:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800d45:	85 d2                	test   %edx,%edx
  800d47:	74 21                	je     800d6a <strlcpy+0x35>
  800d49:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  800d4d:	89 f2                	mov    %esi,%edx
  800d4f:	eb 09                	jmp    800d5a <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800d51:	83 c2 01             	add    $0x1,%edx
  800d54:	83 c1 01             	add    $0x1,%ecx
  800d57:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800d5a:	39 c2                	cmp    %eax,%edx
  800d5c:	74 09                	je     800d67 <strlcpy+0x32>
  800d5e:	0f b6 19             	movzbl (%ecx),%ebx
  800d61:	84 db                	test   %bl,%bl
  800d63:	75 ec                	jne    800d51 <strlcpy+0x1c>
  800d65:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  800d67:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800d6a:	29 f0                	sub    %esi,%eax
}
  800d6c:	5b                   	pop    %ebx
  800d6d:	5e                   	pop    %esi
  800d6e:	5d                   	pop    %ebp
  800d6f:	c3                   	ret    

00800d70 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800d70:	55                   	push   %ebp
  800d71:	89 e5                	mov    %esp,%ebp
  800d73:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800d76:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800d79:	eb 06                	jmp    800d81 <strcmp+0x11>
		p++, q++;
  800d7b:	83 c1 01             	add    $0x1,%ecx
  800d7e:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800d81:	0f b6 01             	movzbl (%ecx),%eax
  800d84:	84 c0                	test   %al,%al
  800d86:	74 04                	je     800d8c <strcmp+0x1c>
  800d88:	3a 02                	cmp    (%edx),%al
  800d8a:	74 ef                	je     800d7b <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800d8c:	0f b6 c0             	movzbl %al,%eax
  800d8f:	0f b6 12             	movzbl (%edx),%edx
  800d92:	29 d0                	sub    %edx,%eax
}
  800d94:	5d                   	pop    %ebp
  800d95:	c3                   	ret    

00800d96 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800d96:	55                   	push   %ebp
  800d97:	89 e5                	mov    %esp,%ebp
  800d99:	53                   	push   %ebx
  800d9a:	8b 45 08             	mov    0x8(%ebp),%eax
  800d9d:	8b 55 0c             	mov    0xc(%ebp),%edx
  800da0:	89 c3                	mov    %eax,%ebx
  800da2:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800da5:	eb 06                	jmp    800dad <strncmp+0x17>
		n--, p++, q++;
  800da7:	83 c0 01             	add    $0x1,%eax
  800daa:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800dad:	39 d8                	cmp    %ebx,%eax
  800daf:	74 15                	je     800dc6 <strncmp+0x30>
  800db1:	0f b6 08             	movzbl (%eax),%ecx
  800db4:	84 c9                	test   %cl,%cl
  800db6:	74 04                	je     800dbc <strncmp+0x26>
  800db8:	3a 0a                	cmp    (%edx),%cl
  800dba:	74 eb                	je     800da7 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800dbc:	0f b6 00             	movzbl (%eax),%eax
  800dbf:	0f b6 12             	movzbl (%edx),%edx
  800dc2:	29 d0                	sub    %edx,%eax
  800dc4:	eb 05                	jmp    800dcb <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800dc6:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800dcb:	5b                   	pop    %ebx
  800dcc:	5d                   	pop    %ebp
  800dcd:	c3                   	ret    

00800dce <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800dce:	55                   	push   %ebp
  800dcf:	89 e5                	mov    %esp,%ebp
  800dd1:	8b 45 08             	mov    0x8(%ebp),%eax
  800dd4:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800dd8:	eb 07                	jmp    800de1 <strchr+0x13>
		if (*s == c)
  800dda:	38 ca                	cmp    %cl,%dl
  800ddc:	74 0f                	je     800ded <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800dde:	83 c0 01             	add    $0x1,%eax
  800de1:	0f b6 10             	movzbl (%eax),%edx
  800de4:	84 d2                	test   %dl,%dl
  800de6:	75 f2                	jne    800dda <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800de8:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800ded:	5d                   	pop    %ebp
  800dee:	c3                   	ret    

00800def <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800def:	55                   	push   %ebp
  800df0:	89 e5                	mov    %esp,%ebp
  800df2:	8b 45 08             	mov    0x8(%ebp),%eax
  800df5:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800df9:	eb 03                	jmp    800dfe <strfind+0xf>
  800dfb:	83 c0 01             	add    $0x1,%eax
  800dfe:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  800e01:	38 ca                	cmp    %cl,%dl
  800e03:	74 04                	je     800e09 <strfind+0x1a>
  800e05:	84 d2                	test   %dl,%dl
  800e07:	75 f2                	jne    800dfb <strfind+0xc>
			break;
	return (char *) s;
}
  800e09:	5d                   	pop    %ebp
  800e0a:	c3                   	ret    

00800e0b <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800e0b:	55                   	push   %ebp
  800e0c:	89 e5                	mov    %esp,%ebp
  800e0e:	57                   	push   %edi
  800e0f:	56                   	push   %esi
  800e10:	53                   	push   %ebx
  800e11:	8b 7d 08             	mov    0x8(%ebp),%edi
  800e14:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800e17:	85 c9                	test   %ecx,%ecx
  800e19:	74 36                	je     800e51 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800e1b:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800e21:	75 28                	jne    800e4b <memset+0x40>
  800e23:	f6 c1 03             	test   $0x3,%cl
  800e26:	75 23                	jne    800e4b <memset+0x40>
		c &= 0xFF;
  800e28:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800e2c:	89 d3                	mov    %edx,%ebx
  800e2e:	c1 e3 08             	shl    $0x8,%ebx
  800e31:	89 d6                	mov    %edx,%esi
  800e33:	c1 e6 18             	shl    $0x18,%esi
  800e36:	89 d0                	mov    %edx,%eax
  800e38:	c1 e0 10             	shl    $0x10,%eax
  800e3b:	09 f0                	or     %esi,%eax
  800e3d:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  800e3f:	89 d8                	mov    %ebx,%eax
  800e41:	09 d0                	or     %edx,%eax
  800e43:	c1 e9 02             	shr    $0x2,%ecx
  800e46:	fc                   	cld    
  800e47:	f3 ab                	rep stos %eax,%es:(%edi)
  800e49:	eb 06                	jmp    800e51 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800e4b:	8b 45 0c             	mov    0xc(%ebp),%eax
  800e4e:	fc                   	cld    
  800e4f:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800e51:	89 f8                	mov    %edi,%eax
  800e53:	5b                   	pop    %ebx
  800e54:	5e                   	pop    %esi
  800e55:	5f                   	pop    %edi
  800e56:	5d                   	pop    %ebp
  800e57:	c3                   	ret    

00800e58 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800e58:	55                   	push   %ebp
  800e59:	89 e5                	mov    %esp,%ebp
  800e5b:	57                   	push   %edi
  800e5c:	56                   	push   %esi
  800e5d:	8b 45 08             	mov    0x8(%ebp),%eax
  800e60:	8b 75 0c             	mov    0xc(%ebp),%esi
  800e63:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800e66:	39 c6                	cmp    %eax,%esi
  800e68:	73 35                	jae    800e9f <memmove+0x47>
  800e6a:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800e6d:	39 d0                	cmp    %edx,%eax
  800e6f:	73 2e                	jae    800e9f <memmove+0x47>
		s += n;
		d += n;
  800e71:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800e74:	89 d6                	mov    %edx,%esi
  800e76:	09 fe                	or     %edi,%esi
  800e78:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800e7e:	75 13                	jne    800e93 <memmove+0x3b>
  800e80:	f6 c1 03             	test   $0x3,%cl
  800e83:	75 0e                	jne    800e93 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  800e85:	83 ef 04             	sub    $0x4,%edi
  800e88:	8d 72 fc             	lea    -0x4(%edx),%esi
  800e8b:	c1 e9 02             	shr    $0x2,%ecx
  800e8e:	fd                   	std    
  800e8f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800e91:	eb 09                	jmp    800e9c <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800e93:	83 ef 01             	sub    $0x1,%edi
  800e96:	8d 72 ff             	lea    -0x1(%edx),%esi
  800e99:	fd                   	std    
  800e9a:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800e9c:	fc                   	cld    
  800e9d:	eb 1d                	jmp    800ebc <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800e9f:	89 f2                	mov    %esi,%edx
  800ea1:	09 c2                	or     %eax,%edx
  800ea3:	f6 c2 03             	test   $0x3,%dl
  800ea6:	75 0f                	jne    800eb7 <memmove+0x5f>
  800ea8:	f6 c1 03             	test   $0x3,%cl
  800eab:	75 0a                	jne    800eb7 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800ead:	c1 e9 02             	shr    $0x2,%ecx
  800eb0:	89 c7                	mov    %eax,%edi
  800eb2:	fc                   	cld    
  800eb3:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800eb5:	eb 05                	jmp    800ebc <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800eb7:	89 c7                	mov    %eax,%edi
  800eb9:	fc                   	cld    
  800eba:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800ebc:	5e                   	pop    %esi
  800ebd:	5f                   	pop    %edi
  800ebe:	5d                   	pop    %ebp
  800ebf:	c3                   	ret    

00800ec0 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800ec0:	55                   	push   %ebp
  800ec1:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  800ec3:	ff 75 10             	pushl  0x10(%ebp)
  800ec6:	ff 75 0c             	pushl  0xc(%ebp)
  800ec9:	ff 75 08             	pushl  0x8(%ebp)
  800ecc:	e8 87 ff ff ff       	call   800e58 <memmove>
}
  800ed1:	c9                   	leave  
  800ed2:	c3                   	ret    

00800ed3 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800ed3:	55                   	push   %ebp
  800ed4:	89 e5                	mov    %esp,%ebp
  800ed6:	56                   	push   %esi
  800ed7:	53                   	push   %ebx
  800ed8:	8b 45 08             	mov    0x8(%ebp),%eax
  800edb:	8b 55 0c             	mov    0xc(%ebp),%edx
  800ede:	89 c6                	mov    %eax,%esi
  800ee0:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800ee3:	eb 1a                	jmp    800eff <memcmp+0x2c>
		if (*s1 != *s2)
  800ee5:	0f b6 08             	movzbl (%eax),%ecx
  800ee8:	0f b6 1a             	movzbl (%edx),%ebx
  800eeb:	38 d9                	cmp    %bl,%cl
  800eed:	74 0a                	je     800ef9 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800eef:	0f b6 c1             	movzbl %cl,%eax
  800ef2:	0f b6 db             	movzbl %bl,%ebx
  800ef5:	29 d8                	sub    %ebx,%eax
  800ef7:	eb 0f                	jmp    800f08 <memcmp+0x35>
		s1++, s2++;
  800ef9:	83 c0 01             	add    $0x1,%eax
  800efc:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800eff:	39 f0                	cmp    %esi,%eax
  800f01:	75 e2                	jne    800ee5 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800f03:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800f08:	5b                   	pop    %ebx
  800f09:	5e                   	pop    %esi
  800f0a:	5d                   	pop    %ebp
  800f0b:	c3                   	ret    

00800f0c <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800f0c:	55                   	push   %ebp
  800f0d:	89 e5                	mov    %esp,%ebp
  800f0f:	53                   	push   %ebx
  800f10:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  800f13:	89 c1                	mov    %eax,%ecx
  800f15:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  800f18:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800f1c:	eb 0a                	jmp    800f28 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  800f1e:	0f b6 10             	movzbl (%eax),%edx
  800f21:	39 da                	cmp    %ebx,%edx
  800f23:	74 07                	je     800f2c <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800f25:	83 c0 01             	add    $0x1,%eax
  800f28:	39 c8                	cmp    %ecx,%eax
  800f2a:	72 f2                	jb     800f1e <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800f2c:	5b                   	pop    %ebx
  800f2d:	5d                   	pop    %ebp
  800f2e:	c3                   	ret    

00800f2f <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800f2f:	55                   	push   %ebp
  800f30:	89 e5                	mov    %esp,%ebp
  800f32:	57                   	push   %edi
  800f33:	56                   	push   %esi
  800f34:	53                   	push   %ebx
  800f35:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800f38:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800f3b:	eb 03                	jmp    800f40 <strtol+0x11>
		s++;
  800f3d:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800f40:	0f b6 01             	movzbl (%ecx),%eax
  800f43:	3c 20                	cmp    $0x20,%al
  800f45:	74 f6                	je     800f3d <strtol+0xe>
  800f47:	3c 09                	cmp    $0x9,%al
  800f49:	74 f2                	je     800f3d <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800f4b:	3c 2b                	cmp    $0x2b,%al
  800f4d:	75 0a                	jne    800f59 <strtol+0x2a>
		s++;
  800f4f:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800f52:	bf 00 00 00 00       	mov    $0x0,%edi
  800f57:	eb 11                	jmp    800f6a <strtol+0x3b>
  800f59:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800f5e:	3c 2d                	cmp    $0x2d,%al
  800f60:	75 08                	jne    800f6a <strtol+0x3b>
		s++, neg = 1;
  800f62:	83 c1 01             	add    $0x1,%ecx
  800f65:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800f6a:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800f70:	75 15                	jne    800f87 <strtol+0x58>
  800f72:	80 39 30             	cmpb   $0x30,(%ecx)
  800f75:	75 10                	jne    800f87 <strtol+0x58>
  800f77:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800f7b:	75 7c                	jne    800ff9 <strtol+0xca>
		s += 2, base = 16;
  800f7d:	83 c1 02             	add    $0x2,%ecx
  800f80:	bb 10 00 00 00       	mov    $0x10,%ebx
  800f85:	eb 16                	jmp    800f9d <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800f87:	85 db                	test   %ebx,%ebx
  800f89:	75 12                	jne    800f9d <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800f8b:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800f90:	80 39 30             	cmpb   $0x30,(%ecx)
  800f93:	75 08                	jne    800f9d <strtol+0x6e>
		s++, base = 8;
  800f95:	83 c1 01             	add    $0x1,%ecx
  800f98:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800f9d:	b8 00 00 00 00       	mov    $0x0,%eax
  800fa2:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800fa5:	0f b6 11             	movzbl (%ecx),%edx
  800fa8:	8d 72 d0             	lea    -0x30(%edx),%esi
  800fab:	89 f3                	mov    %esi,%ebx
  800fad:	80 fb 09             	cmp    $0x9,%bl
  800fb0:	77 08                	ja     800fba <strtol+0x8b>
			dig = *s - '0';
  800fb2:	0f be d2             	movsbl %dl,%edx
  800fb5:	83 ea 30             	sub    $0x30,%edx
  800fb8:	eb 22                	jmp    800fdc <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800fba:	8d 72 9f             	lea    -0x61(%edx),%esi
  800fbd:	89 f3                	mov    %esi,%ebx
  800fbf:	80 fb 19             	cmp    $0x19,%bl
  800fc2:	77 08                	ja     800fcc <strtol+0x9d>
			dig = *s - 'a' + 10;
  800fc4:	0f be d2             	movsbl %dl,%edx
  800fc7:	83 ea 57             	sub    $0x57,%edx
  800fca:	eb 10                	jmp    800fdc <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800fcc:	8d 72 bf             	lea    -0x41(%edx),%esi
  800fcf:	89 f3                	mov    %esi,%ebx
  800fd1:	80 fb 19             	cmp    $0x19,%bl
  800fd4:	77 16                	ja     800fec <strtol+0xbd>
			dig = *s - 'A' + 10;
  800fd6:	0f be d2             	movsbl %dl,%edx
  800fd9:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800fdc:	3b 55 10             	cmp    0x10(%ebp),%edx
  800fdf:	7d 0b                	jge    800fec <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800fe1:	83 c1 01             	add    $0x1,%ecx
  800fe4:	0f af 45 10          	imul   0x10(%ebp),%eax
  800fe8:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800fea:	eb b9                	jmp    800fa5 <strtol+0x76>

	if (endptr)
  800fec:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800ff0:	74 0d                	je     800fff <strtol+0xd0>
		*endptr = (char *) s;
  800ff2:	8b 75 0c             	mov    0xc(%ebp),%esi
  800ff5:	89 0e                	mov    %ecx,(%esi)
  800ff7:	eb 06                	jmp    800fff <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800ff9:	85 db                	test   %ebx,%ebx
  800ffb:	74 98                	je     800f95 <strtol+0x66>
  800ffd:	eb 9e                	jmp    800f9d <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800fff:	89 c2                	mov    %eax,%edx
  801001:	f7 da                	neg    %edx
  801003:	85 ff                	test   %edi,%edi
  801005:	0f 45 c2             	cmovne %edx,%eax
}
  801008:	5b                   	pop    %ebx
  801009:	5e                   	pop    %esi
  80100a:	5f                   	pop    %edi
  80100b:	5d                   	pop    %ebp
  80100c:	c3                   	ret    

0080100d <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  80100d:	55                   	push   %ebp
  80100e:	89 e5                	mov    %esp,%ebp
  801010:	57                   	push   %edi
  801011:	56                   	push   %esi
  801012:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  801013:	b8 00 00 00 00       	mov    $0x0,%eax
  801018:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80101b:	8b 55 08             	mov    0x8(%ebp),%edx
  80101e:	89 c3                	mov    %eax,%ebx
  801020:	89 c7                	mov    %eax,%edi
  801022:	89 c6                	mov    %eax,%esi
  801024:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  801026:	5b                   	pop    %ebx
  801027:	5e                   	pop    %esi
  801028:	5f                   	pop    %edi
  801029:	5d                   	pop    %ebp
  80102a:	c3                   	ret    

0080102b <sys_cgetc>:

int
sys_cgetc(void)
{
  80102b:	55                   	push   %ebp
  80102c:	89 e5                	mov    %esp,%ebp
  80102e:	57                   	push   %edi
  80102f:	56                   	push   %esi
  801030:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  801031:	ba 00 00 00 00       	mov    $0x0,%edx
  801036:	b8 01 00 00 00       	mov    $0x1,%eax
  80103b:	89 d1                	mov    %edx,%ecx
  80103d:	89 d3                	mov    %edx,%ebx
  80103f:	89 d7                	mov    %edx,%edi
  801041:	89 d6                	mov    %edx,%esi
  801043:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  801045:	5b                   	pop    %ebx
  801046:	5e                   	pop    %esi
  801047:	5f                   	pop    %edi
  801048:	5d                   	pop    %ebp
  801049:	c3                   	ret    

0080104a <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  80104a:	55                   	push   %ebp
  80104b:	89 e5                	mov    %esp,%ebp
  80104d:	57                   	push   %edi
  80104e:	56                   	push   %esi
  80104f:	53                   	push   %ebx
  801050:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  801053:	b9 00 00 00 00       	mov    $0x0,%ecx
  801058:	b8 03 00 00 00       	mov    $0x3,%eax
  80105d:	8b 55 08             	mov    0x8(%ebp),%edx
  801060:	89 cb                	mov    %ecx,%ebx
  801062:	89 cf                	mov    %ecx,%edi
  801064:	89 ce                	mov    %ecx,%esi
  801066:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  801068:	85 c0                	test   %eax,%eax
  80106a:	7e 17                	jle    801083 <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  80106c:	83 ec 0c             	sub    $0xc,%esp
  80106f:	50                   	push   %eax
  801070:	6a 03                	push   $0x3
  801072:	68 28 19 80 00       	push   $0x801928
  801077:	6a 23                	push   $0x23
  801079:	68 45 19 80 00       	push   $0x801945
  80107e:	e8 66 f5 ff ff       	call   8005e9 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  801083:	8d 65 f4             	lea    -0xc(%ebp),%esp
  801086:	5b                   	pop    %ebx
  801087:	5e                   	pop    %esi
  801088:	5f                   	pop    %edi
  801089:	5d                   	pop    %ebp
  80108a:	c3                   	ret    

0080108b <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  80108b:	55                   	push   %ebp
  80108c:	89 e5                	mov    %esp,%ebp
  80108e:	57                   	push   %edi
  80108f:	56                   	push   %esi
  801090:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  801091:	ba 00 00 00 00       	mov    $0x0,%edx
  801096:	b8 02 00 00 00       	mov    $0x2,%eax
  80109b:	89 d1                	mov    %edx,%ecx
  80109d:	89 d3                	mov    %edx,%ebx
  80109f:	89 d7                	mov    %edx,%edi
  8010a1:	89 d6                	mov    %edx,%esi
  8010a3:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  8010a5:	5b                   	pop    %ebx
  8010a6:	5e                   	pop    %esi
  8010a7:	5f                   	pop    %edi
  8010a8:	5d                   	pop    %ebp
  8010a9:	c3                   	ret    

008010aa <sys_yield>:

void
sys_yield(void)
{
  8010aa:	55                   	push   %ebp
  8010ab:	89 e5                	mov    %esp,%ebp
  8010ad:	57                   	push   %edi
  8010ae:	56                   	push   %esi
  8010af:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8010b0:	ba 00 00 00 00       	mov    $0x0,%edx
  8010b5:	b8 0a 00 00 00       	mov    $0xa,%eax
  8010ba:	89 d1                	mov    %edx,%ecx
  8010bc:	89 d3                	mov    %edx,%ebx
  8010be:	89 d7                	mov    %edx,%edi
  8010c0:	89 d6                	mov    %edx,%esi
  8010c2:	cd 30                	int    $0x30

void
sys_yield(void)
{
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
}
  8010c4:	5b                   	pop    %ebx
  8010c5:	5e                   	pop    %esi
  8010c6:	5f                   	pop    %edi
  8010c7:	5d                   	pop    %ebp
  8010c8:	c3                   	ret    

008010c9 <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  8010c9:	55                   	push   %ebp
  8010ca:	89 e5                	mov    %esp,%ebp
  8010cc:	57                   	push   %edi
  8010cd:	56                   	push   %esi
  8010ce:	53                   	push   %ebx
  8010cf:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8010d2:	be 00 00 00 00       	mov    $0x0,%esi
  8010d7:	b8 04 00 00 00       	mov    $0x4,%eax
  8010dc:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8010df:	8b 55 08             	mov    0x8(%ebp),%edx
  8010e2:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8010e5:	89 f7                	mov    %esi,%edi
  8010e7:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  8010e9:	85 c0                	test   %eax,%eax
  8010eb:	7e 17                	jle    801104 <sys_page_alloc+0x3b>
		panic("syscall %d returned %d (> 0)", num, ret);
  8010ed:	83 ec 0c             	sub    $0xc,%esp
  8010f0:	50                   	push   %eax
  8010f1:	6a 04                	push   $0x4
  8010f3:	68 28 19 80 00       	push   $0x801928
  8010f8:	6a 23                	push   $0x23
  8010fa:	68 45 19 80 00       	push   $0x801945
  8010ff:	e8 e5 f4 ff ff       	call   8005e9 <_panic>

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
}
  801104:	8d 65 f4             	lea    -0xc(%ebp),%esp
  801107:	5b                   	pop    %ebx
  801108:	5e                   	pop    %esi
  801109:	5f                   	pop    %edi
  80110a:	5d                   	pop    %ebp
  80110b:	c3                   	ret    

0080110c <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  80110c:	55                   	push   %ebp
  80110d:	89 e5                	mov    %esp,%ebp
  80110f:	57                   	push   %edi
  801110:	56                   	push   %esi
  801111:	53                   	push   %ebx
  801112:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  801115:	b8 05 00 00 00       	mov    $0x5,%eax
  80111a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80111d:	8b 55 08             	mov    0x8(%ebp),%edx
  801120:	8b 5d 10             	mov    0x10(%ebp),%ebx
  801123:	8b 7d 14             	mov    0x14(%ebp),%edi
  801126:	8b 75 18             	mov    0x18(%ebp),%esi
  801129:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  80112b:	85 c0                	test   %eax,%eax
  80112d:	7e 17                	jle    801146 <sys_page_map+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  80112f:	83 ec 0c             	sub    $0xc,%esp
  801132:	50                   	push   %eax
  801133:	6a 05                	push   $0x5
  801135:	68 28 19 80 00       	push   $0x801928
  80113a:	6a 23                	push   $0x23
  80113c:	68 45 19 80 00       	push   $0x801945
  801141:	e8 a3 f4 ff ff       	call   8005e9 <_panic>

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
}
  801146:	8d 65 f4             	lea    -0xc(%ebp),%esp
  801149:	5b                   	pop    %ebx
  80114a:	5e                   	pop    %esi
  80114b:	5f                   	pop    %edi
  80114c:	5d                   	pop    %ebp
  80114d:	c3                   	ret    

0080114e <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  80114e:	55                   	push   %ebp
  80114f:	89 e5                	mov    %esp,%ebp
  801151:	57                   	push   %edi
  801152:	56                   	push   %esi
  801153:	53                   	push   %ebx
  801154:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  801157:	bb 00 00 00 00       	mov    $0x0,%ebx
  80115c:	b8 06 00 00 00       	mov    $0x6,%eax
  801161:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  801164:	8b 55 08             	mov    0x8(%ebp),%edx
  801167:	89 df                	mov    %ebx,%edi
  801169:	89 de                	mov    %ebx,%esi
  80116b:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  80116d:	85 c0                	test   %eax,%eax
  80116f:	7e 17                	jle    801188 <sys_page_unmap+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  801171:	83 ec 0c             	sub    $0xc,%esp
  801174:	50                   	push   %eax
  801175:	6a 06                	push   $0x6
  801177:	68 28 19 80 00       	push   $0x801928
  80117c:	6a 23                	push   $0x23
  80117e:	68 45 19 80 00       	push   $0x801945
  801183:	e8 61 f4 ff ff       	call   8005e9 <_panic>

int
sys_page_unmap(envid_t envid, void *va)
{
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
}
  801188:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80118b:	5b                   	pop    %ebx
  80118c:	5e                   	pop    %esi
  80118d:	5f                   	pop    %edi
  80118e:	5d                   	pop    %ebp
  80118f:	c3                   	ret    

00801190 <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  801190:	55                   	push   %ebp
  801191:	89 e5                	mov    %esp,%ebp
  801193:	57                   	push   %edi
  801194:	56                   	push   %esi
  801195:	53                   	push   %ebx
  801196:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  801199:	bb 00 00 00 00       	mov    $0x0,%ebx
  80119e:	b8 08 00 00 00       	mov    $0x8,%eax
  8011a3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8011a6:	8b 55 08             	mov    0x8(%ebp),%edx
  8011a9:	89 df                	mov    %ebx,%edi
  8011ab:	89 de                	mov    %ebx,%esi
  8011ad:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  8011af:	85 c0                	test   %eax,%eax
  8011b1:	7e 17                	jle    8011ca <sys_env_set_status+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  8011b3:	83 ec 0c             	sub    $0xc,%esp
  8011b6:	50                   	push   %eax
  8011b7:	6a 08                	push   $0x8
  8011b9:	68 28 19 80 00       	push   $0x801928
  8011be:	6a 23                	push   $0x23
  8011c0:	68 45 19 80 00       	push   $0x801945
  8011c5:	e8 1f f4 ff ff       	call   8005e9 <_panic>

int
sys_env_set_status(envid_t envid, int status)
{
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
}
  8011ca:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8011cd:	5b                   	pop    %ebx
  8011ce:	5e                   	pop    %esi
  8011cf:	5f                   	pop    %edi
  8011d0:	5d                   	pop    %ebp
  8011d1:	c3                   	ret    

008011d2 <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  8011d2:	55                   	push   %ebp
  8011d3:	89 e5                	mov    %esp,%ebp
  8011d5:	57                   	push   %edi
  8011d6:	56                   	push   %esi
  8011d7:	53                   	push   %ebx
  8011d8:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8011db:	bb 00 00 00 00       	mov    $0x0,%ebx
  8011e0:	b8 09 00 00 00       	mov    $0x9,%eax
  8011e5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8011e8:	8b 55 08             	mov    0x8(%ebp),%edx
  8011eb:	89 df                	mov    %ebx,%edi
  8011ed:	89 de                	mov    %ebx,%esi
  8011ef:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  8011f1:	85 c0                	test   %eax,%eax
  8011f3:	7e 17                	jle    80120c <sys_env_set_pgfault_upcall+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  8011f5:	83 ec 0c             	sub    $0xc,%esp
  8011f8:	50                   	push   %eax
  8011f9:	6a 09                	push   $0x9
  8011fb:	68 28 19 80 00       	push   $0x801928
  801200:	6a 23                	push   $0x23
  801202:	68 45 19 80 00       	push   $0x801945
  801207:	e8 dd f3 ff ff       	call   8005e9 <_panic>

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
}
  80120c:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80120f:	5b                   	pop    %ebx
  801210:	5e                   	pop    %esi
  801211:	5f                   	pop    %edi
  801212:	5d                   	pop    %ebp
  801213:	c3                   	ret    

00801214 <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  801214:	55                   	push   %ebp
  801215:	89 e5                	mov    %esp,%ebp
  801217:	57                   	push   %edi
  801218:	56                   	push   %esi
  801219:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80121a:	be 00 00 00 00       	mov    $0x0,%esi
  80121f:	b8 0b 00 00 00       	mov    $0xb,%eax
  801224:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  801227:	8b 55 08             	mov    0x8(%ebp),%edx
  80122a:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80122d:	8b 7d 14             	mov    0x14(%ebp),%edi
  801230:	cd 30                	int    $0x30

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
}
  801232:	5b                   	pop    %ebx
  801233:	5e                   	pop    %esi
  801234:	5f                   	pop    %edi
  801235:	5d                   	pop    %ebp
  801236:	c3                   	ret    

00801237 <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  801237:	55                   	push   %ebp
  801238:	89 e5                	mov    %esp,%ebp
  80123a:	57                   	push   %edi
  80123b:	56                   	push   %esi
  80123c:	53                   	push   %ebx
  80123d:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  801240:	b9 00 00 00 00       	mov    $0x0,%ecx
  801245:	b8 0c 00 00 00       	mov    $0xc,%eax
  80124a:	8b 55 08             	mov    0x8(%ebp),%edx
  80124d:	89 cb                	mov    %ecx,%ebx
  80124f:	89 cf                	mov    %ecx,%edi
  801251:	89 ce                	mov    %ecx,%esi
  801253:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  801255:	85 c0                	test   %eax,%eax
  801257:	7e 17                	jle    801270 <sys_ipc_recv+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  801259:	83 ec 0c             	sub    $0xc,%esp
  80125c:	50                   	push   %eax
  80125d:	6a 0c                	push   $0xc
  80125f:	68 28 19 80 00       	push   $0x801928
  801264:	6a 23                	push   $0x23
  801266:	68 45 19 80 00       	push   $0x801945
  80126b:	e8 79 f3 ff ff       	call   8005e9 <_panic>

int
sys_ipc_recv(void *dstva)
{
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
}
  801270:	8d 65 f4             	lea    -0xc(%ebp),%esp
  801273:	5b                   	pop    %ebx
  801274:	5e                   	pop    %esi
  801275:	5f                   	pop    %edi
  801276:	5d                   	pop    %ebp
  801277:	c3                   	ret    

00801278 <set_pgfault_handler>:
// at UXSTACKTOP), and tell the kernel to call the assembly-language
// _pgfault_upcall routine when a page fault occurs.
//
void
set_pgfault_handler(void (*handler)(struct UTrapframe *utf))
{
  801278:	55                   	push   %ebp
  801279:	89 e5                	mov    %esp,%ebp
  80127b:	83 ec 08             	sub    $0x8,%esp
	int r;

	if (_pgfault_handler == 0) {
  80127e:	83 3d d0 20 80 00 00 	cmpl   $0x0,0x8020d0
  801285:	75 56                	jne    8012dd <set_pgfault_handler+0x65>
		// First time through!
		// LAB 4: Your code here.
		r = sys_page_alloc(0, (void*)UXSTACKTOP-PGSIZE, PTE_U|PTE_W|PTE_P);
  801287:	83 ec 04             	sub    $0x4,%esp
  80128a:	6a 07                	push   $0x7
  80128c:	68 00 f0 bf ee       	push   $0xeebff000
  801291:	6a 00                	push   $0x0
  801293:	e8 31 fe ff ff       	call   8010c9 <sys_page_alloc>
		//cprintf("%x", r);
		if(r != 0)
  801298:	83 c4 10             	add    $0x10,%esp
  80129b:	85 c0                	test   %eax,%eax
  80129d:	74 14                	je     8012b3 <set_pgfault_handler+0x3b>
		{
			panic("sys_page_alloc failed");
  80129f:	83 ec 04             	sub    $0x4,%esp
  8012a2:	68 53 19 80 00       	push   $0x801953
  8012a7:	6a 24                	push   $0x24
  8012a9:	68 69 19 80 00       	push   $0x801969
  8012ae:	e8 36 f3 ff ff       	call   8005e9 <_panic>
		}
		r = sys_env_set_pgfault_upcall(0, (void*)_pgfault_upcall); 
  8012b3:	83 ec 08             	sub    $0x8,%esp
  8012b6:	68 e7 12 80 00       	push   $0x8012e7
  8012bb:	6a 00                	push   $0x0
  8012bd:	e8 10 ff ff ff       	call   8011d2 <sys_env_set_pgfault_upcall>
		//cprintf("%x\n", _pgfault_upcall);//fixed bug:_pgfault_upcall-->_pgfault_handler
		if(r != 0)
  8012c2:	83 c4 10             	add    $0x10,%esp
  8012c5:	85 c0                	test   %eax,%eax
  8012c7:	74 14                	je     8012dd <set_pgfault_handler+0x65>
		{
			panic("sys_env_set_pgfault_upcall failed");
  8012c9:	83 ec 04             	sub    $0x4,%esp
  8012cc:	68 78 19 80 00       	push   $0x801978
  8012d1:	6a 2a                	push   $0x2a
  8012d3:	68 69 19 80 00       	push   $0x801969
  8012d8:	e8 0c f3 ff ff       	call   8005e9 <_panic>
		}
		//panic("set_pgfault_handler not implemented");
	}

	// Save handler pointer for assembly to call.
	_pgfault_handler = handler;
  8012dd:	8b 45 08             	mov    0x8(%ebp),%eax
  8012e0:	a3 d0 20 80 00       	mov    %eax,0x8020d0
}
  8012e5:	c9                   	leave  
  8012e6:	c3                   	ret    

008012e7 <_pgfault_upcall>:

.text
.globl _pgfault_upcall
_pgfault_upcall:
	// Call the C page fault handler.
	pushl %esp			// function argument: pointer to UTF
  8012e7:	54                   	push   %esp
	movl _pgfault_handler, %eax
  8012e8:	a1 d0 20 80 00       	mov    0x8020d0,%eax
	call *%eax
  8012ed:	ff d0                	call   *%eax
	addl $4, %esp			// pop function argument
  8012ef:	83 c4 04             	add    $0x4,%esp
	// registers are available for intermediate calculations.  You
	// may find that you have to rearrange your code in non-obvious
	// ways as registers become unavailable as scratch space.
	//
	// LAB 4: Your code here.
	movl 0x28(%esp), %eax
  8012f2:	8b 44 24 28          	mov    0x28(%esp),%eax
    	subl $0x4, 0x30(%esp)
  8012f6:	83 6c 24 30 04       	subl   $0x4,0x30(%esp)
   	movl 0x30(%esp), %ebp
  8012fb:	8b 6c 24 30          	mov    0x30(%esp),%ebp
    	movl %eax, (%ebp)
  8012ff:	89 45 00             	mov    %eax,0x0(%ebp)
    	// pop fault_va, err
    	popl %eax
  801302:	58                   	pop    %eax
    	popl %eax
  801303:	58                   	pop    %eax
	// Restore the trap-time registers.  After you do this, you
	// can no longer modify any general-purpose registers.
	// LAB 4: Your code here.
	popal
  801304:	61                   	popa   
	// Restore eflags from the stack.  After you do this, you can
	// no longer use arithmetic operations or anything else that
	// modifies eflags.
	// LAB 4: Your code here.
	addl $0x4, %esp
  801305:	83 c4 04             	add    $0x4,%esp
	popfl
  801308:	9d                   	popf   
	// Switch back to the adjusted trap-time stack.
	// LAB 4: Your code here.
	popl %esp
  801309:	5c                   	pop    %esp
	// Return to re-execute the instruction that faulted.
	// LAB 4: Your code here.
	ret
  80130a:	c3                   	ret    
  80130b:	66 90                	xchg   %ax,%ax
  80130d:	66 90                	xchg   %ax,%ax
  80130f:	90                   	nop

00801310 <__udivdi3>:
  801310:	55                   	push   %ebp
  801311:	57                   	push   %edi
  801312:	56                   	push   %esi
  801313:	53                   	push   %ebx
  801314:	83 ec 1c             	sub    $0x1c,%esp
  801317:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  80131b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  80131f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  801323:	8b 7c 24 38          	mov    0x38(%esp),%edi
  801327:	85 f6                	test   %esi,%esi
  801329:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  80132d:	89 ca                	mov    %ecx,%edx
  80132f:	89 f8                	mov    %edi,%eax
  801331:	75 3d                	jne    801370 <__udivdi3+0x60>
  801333:	39 cf                	cmp    %ecx,%edi
  801335:	0f 87 c5 00 00 00    	ja     801400 <__udivdi3+0xf0>
  80133b:	85 ff                	test   %edi,%edi
  80133d:	89 fd                	mov    %edi,%ebp
  80133f:	75 0b                	jne    80134c <__udivdi3+0x3c>
  801341:	b8 01 00 00 00       	mov    $0x1,%eax
  801346:	31 d2                	xor    %edx,%edx
  801348:	f7 f7                	div    %edi
  80134a:	89 c5                	mov    %eax,%ebp
  80134c:	89 c8                	mov    %ecx,%eax
  80134e:	31 d2                	xor    %edx,%edx
  801350:	f7 f5                	div    %ebp
  801352:	89 c1                	mov    %eax,%ecx
  801354:	89 d8                	mov    %ebx,%eax
  801356:	89 cf                	mov    %ecx,%edi
  801358:	f7 f5                	div    %ebp
  80135a:	89 c3                	mov    %eax,%ebx
  80135c:	89 d8                	mov    %ebx,%eax
  80135e:	89 fa                	mov    %edi,%edx
  801360:	83 c4 1c             	add    $0x1c,%esp
  801363:	5b                   	pop    %ebx
  801364:	5e                   	pop    %esi
  801365:	5f                   	pop    %edi
  801366:	5d                   	pop    %ebp
  801367:	c3                   	ret    
  801368:	90                   	nop
  801369:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  801370:	39 ce                	cmp    %ecx,%esi
  801372:	77 74                	ja     8013e8 <__udivdi3+0xd8>
  801374:	0f bd fe             	bsr    %esi,%edi
  801377:	83 f7 1f             	xor    $0x1f,%edi
  80137a:	0f 84 98 00 00 00    	je     801418 <__udivdi3+0x108>
  801380:	bb 20 00 00 00       	mov    $0x20,%ebx
  801385:	89 f9                	mov    %edi,%ecx
  801387:	89 c5                	mov    %eax,%ebp
  801389:	29 fb                	sub    %edi,%ebx
  80138b:	d3 e6                	shl    %cl,%esi
  80138d:	89 d9                	mov    %ebx,%ecx
  80138f:	d3 ed                	shr    %cl,%ebp
  801391:	89 f9                	mov    %edi,%ecx
  801393:	d3 e0                	shl    %cl,%eax
  801395:	09 ee                	or     %ebp,%esi
  801397:	89 d9                	mov    %ebx,%ecx
  801399:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80139d:	89 d5                	mov    %edx,%ebp
  80139f:	8b 44 24 08          	mov    0x8(%esp),%eax
  8013a3:	d3 ed                	shr    %cl,%ebp
  8013a5:	89 f9                	mov    %edi,%ecx
  8013a7:	d3 e2                	shl    %cl,%edx
  8013a9:	89 d9                	mov    %ebx,%ecx
  8013ab:	d3 e8                	shr    %cl,%eax
  8013ad:	09 c2                	or     %eax,%edx
  8013af:	89 d0                	mov    %edx,%eax
  8013b1:	89 ea                	mov    %ebp,%edx
  8013b3:	f7 f6                	div    %esi
  8013b5:	89 d5                	mov    %edx,%ebp
  8013b7:	89 c3                	mov    %eax,%ebx
  8013b9:	f7 64 24 0c          	mull   0xc(%esp)
  8013bd:	39 d5                	cmp    %edx,%ebp
  8013bf:	72 10                	jb     8013d1 <__udivdi3+0xc1>
  8013c1:	8b 74 24 08          	mov    0x8(%esp),%esi
  8013c5:	89 f9                	mov    %edi,%ecx
  8013c7:	d3 e6                	shl    %cl,%esi
  8013c9:	39 c6                	cmp    %eax,%esi
  8013cb:	73 07                	jae    8013d4 <__udivdi3+0xc4>
  8013cd:	39 d5                	cmp    %edx,%ebp
  8013cf:	75 03                	jne    8013d4 <__udivdi3+0xc4>
  8013d1:	83 eb 01             	sub    $0x1,%ebx
  8013d4:	31 ff                	xor    %edi,%edi
  8013d6:	89 d8                	mov    %ebx,%eax
  8013d8:	89 fa                	mov    %edi,%edx
  8013da:	83 c4 1c             	add    $0x1c,%esp
  8013dd:	5b                   	pop    %ebx
  8013de:	5e                   	pop    %esi
  8013df:	5f                   	pop    %edi
  8013e0:	5d                   	pop    %ebp
  8013e1:	c3                   	ret    
  8013e2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  8013e8:	31 ff                	xor    %edi,%edi
  8013ea:	31 db                	xor    %ebx,%ebx
  8013ec:	89 d8                	mov    %ebx,%eax
  8013ee:	89 fa                	mov    %edi,%edx
  8013f0:	83 c4 1c             	add    $0x1c,%esp
  8013f3:	5b                   	pop    %ebx
  8013f4:	5e                   	pop    %esi
  8013f5:	5f                   	pop    %edi
  8013f6:	5d                   	pop    %ebp
  8013f7:	c3                   	ret    
  8013f8:	90                   	nop
  8013f9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  801400:	89 d8                	mov    %ebx,%eax
  801402:	f7 f7                	div    %edi
  801404:	31 ff                	xor    %edi,%edi
  801406:	89 c3                	mov    %eax,%ebx
  801408:	89 d8                	mov    %ebx,%eax
  80140a:	89 fa                	mov    %edi,%edx
  80140c:	83 c4 1c             	add    $0x1c,%esp
  80140f:	5b                   	pop    %ebx
  801410:	5e                   	pop    %esi
  801411:	5f                   	pop    %edi
  801412:	5d                   	pop    %ebp
  801413:	c3                   	ret    
  801414:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801418:	39 ce                	cmp    %ecx,%esi
  80141a:	72 0c                	jb     801428 <__udivdi3+0x118>
  80141c:	31 db                	xor    %ebx,%ebx
  80141e:	3b 44 24 08          	cmp    0x8(%esp),%eax
  801422:	0f 87 34 ff ff ff    	ja     80135c <__udivdi3+0x4c>
  801428:	bb 01 00 00 00       	mov    $0x1,%ebx
  80142d:	e9 2a ff ff ff       	jmp    80135c <__udivdi3+0x4c>
  801432:	66 90                	xchg   %ax,%ax
  801434:	66 90                	xchg   %ax,%ax
  801436:	66 90                	xchg   %ax,%ax
  801438:	66 90                	xchg   %ax,%ax
  80143a:	66 90                	xchg   %ax,%ax
  80143c:	66 90                	xchg   %ax,%ax
  80143e:	66 90                	xchg   %ax,%ax

00801440 <__umoddi3>:
  801440:	55                   	push   %ebp
  801441:	57                   	push   %edi
  801442:	56                   	push   %esi
  801443:	53                   	push   %ebx
  801444:	83 ec 1c             	sub    $0x1c,%esp
  801447:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  80144b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  80144f:	8b 74 24 34          	mov    0x34(%esp),%esi
  801453:	8b 7c 24 38          	mov    0x38(%esp),%edi
  801457:	85 d2                	test   %edx,%edx
  801459:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  80145d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  801461:	89 f3                	mov    %esi,%ebx
  801463:	89 3c 24             	mov    %edi,(%esp)
  801466:	89 74 24 04          	mov    %esi,0x4(%esp)
  80146a:	75 1c                	jne    801488 <__umoddi3+0x48>
  80146c:	39 f7                	cmp    %esi,%edi
  80146e:	76 50                	jbe    8014c0 <__umoddi3+0x80>
  801470:	89 c8                	mov    %ecx,%eax
  801472:	89 f2                	mov    %esi,%edx
  801474:	f7 f7                	div    %edi
  801476:	89 d0                	mov    %edx,%eax
  801478:	31 d2                	xor    %edx,%edx
  80147a:	83 c4 1c             	add    $0x1c,%esp
  80147d:	5b                   	pop    %ebx
  80147e:	5e                   	pop    %esi
  80147f:	5f                   	pop    %edi
  801480:	5d                   	pop    %ebp
  801481:	c3                   	ret    
  801482:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  801488:	39 f2                	cmp    %esi,%edx
  80148a:	89 d0                	mov    %edx,%eax
  80148c:	77 52                	ja     8014e0 <__umoddi3+0xa0>
  80148e:	0f bd ea             	bsr    %edx,%ebp
  801491:	83 f5 1f             	xor    $0x1f,%ebp
  801494:	75 5a                	jne    8014f0 <__umoddi3+0xb0>
  801496:	3b 54 24 04          	cmp    0x4(%esp),%edx
  80149a:	0f 82 e0 00 00 00    	jb     801580 <__umoddi3+0x140>
  8014a0:	39 0c 24             	cmp    %ecx,(%esp)
  8014a3:	0f 86 d7 00 00 00    	jbe    801580 <__umoddi3+0x140>
  8014a9:	8b 44 24 08          	mov    0x8(%esp),%eax
  8014ad:	8b 54 24 04          	mov    0x4(%esp),%edx
  8014b1:	83 c4 1c             	add    $0x1c,%esp
  8014b4:	5b                   	pop    %ebx
  8014b5:	5e                   	pop    %esi
  8014b6:	5f                   	pop    %edi
  8014b7:	5d                   	pop    %ebp
  8014b8:	c3                   	ret    
  8014b9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  8014c0:	85 ff                	test   %edi,%edi
  8014c2:	89 fd                	mov    %edi,%ebp
  8014c4:	75 0b                	jne    8014d1 <__umoddi3+0x91>
  8014c6:	b8 01 00 00 00       	mov    $0x1,%eax
  8014cb:	31 d2                	xor    %edx,%edx
  8014cd:	f7 f7                	div    %edi
  8014cf:	89 c5                	mov    %eax,%ebp
  8014d1:	89 f0                	mov    %esi,%eax
  8014d3:	31 d2                	xor    %edx,%edx
  8014d5:	f7 f5                	div    %ebp
  8014d7:	89 c8                	mov    %ecx,%eax
  8014d9:	f7 f5                	div    %ebp
  8014db:	89 d0                	mov    %edx,%eax
  8014dd:	eb 99                	jmp    801478 <__umoddi3+0x38>
  8014df:	90                   	nop
  8014e0:	89 c8                	mov    %ecx,%eax
  8014e2:	89 f2                	mov    %esi,%edx
  8014e4:	83 c4 1c             	add    $0x1c,%esp
  8014e7:	5b                   	pop    %ebx
  8014e8:	5e                   	pop    %esi
  8014e9:	5f                   	pop    %edi
  8014ea:	5d                   	pop    %ebp
  8014eb:	c3                   	ret    
  8014ec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  8014f0:	8b 34 24             	mov    (%esp),%esi
  8014f3:	bf 20 00 00 00       	mov    $0x20,%edi
  8014f8:	89 e9                	mov    %ebp,%ecx
  8014fa:	29 ef                	sub    %ebp,%edi
  8014fc:	d3 e0                	shl    %cl,%eax
  8014fe:	89 f9                	mov    %edi,%ecx
  801500:	89 f2                	mov    %esi,%edx
  801502:	d3 ea                	shr    %cl,%edx
  801504:	89 e9                	mov    %ebp,%ecx
  801506:	09 c2                	or     %eax,%edx
  801508:	89 d8                	mov    %ebx,%eax
  80150a:	89 14 24             	mov    %edx,(%esp)
  80150d:	89 f2                	mov    %esi,%edx
  80150f:	d3 e2                	shl    %cl,%edx
  801511:	89 f9                	mov    %edi,%ecx
  801513:	89 54 24 04          	mov    %edx,0x4(%esp)
  801517:	8b 54 24 0c          	mov    0xc(%esp),%edx
  80151b:	d3 e8                	shr    %cl,%eax
  80151d:	89 e9                	mov    %ebp,%ecx
  80151f:	89 c6                	mov    %eax,%esi
  801521:	d3 e3                	shl    %cl,%ebx
  801523:	89 f9                	mov    %edi,%ecx
  801525:	89 d0                	mov    %edx,%eax
  801527:	d3 e8                	shr    %cl,%eax
  801529:	89 e9                	mov    %ebp,%ecx
  80152b:	09 d8                	or     %ebx,%eax
  80152d:	89 d3                	mov    %edx,%ebx
  80152f:	89 f2                	mov    %esi,%edx
  801531:	f7 34 24             	divl   (%esp)
  801534:	89 d6                	mov    %edx,%esi
  801536:	d3 e3                	shl    %cl,%ebx
  801538:	f7 64 24 04          	mull   0x4(%esp)
  80153c:	39 d6                	cmp    %edx,%esi
  80153e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  801542:	89 d1                	mov    %edx,%ecx
  801544:	89 c3                	mov    %eax,%ebx
  801546:	72 08                	jb     801550 <__umoddi3+0x110>
  801548:	75 11                	jne    80155b <__umoddi3+0x11b>
  80154a:	39 44 24 08          	cmp    %eax,0x8(%esp)
  80154e:	73 0b                	jae    80155b <__umoddi3+0x11b>
  801550:	2b 44 24 04          	sub    0x4(%esp),%eax
  801554:	1b 14 24             	sbb    (%esp),%edx
  801557:	89 d1                	mov    %edx,%ecx
  801559:	89 c3                	mov    %eax,%ebx
  80155b:	8b 54 24 08          	mov    0x8(%esp),%edx
  80155f:	29 da                	sub    %ebx,%edx
  801561:	19 ce                	sbb    %ecx,%esi
  801563:	89 f9                	mov    %edi,%ecx
  801565:	89 f0                	mov    %esi,%eax
  801567:	d3 e0                	shl    %cl,%eax
  801569:	89 e9                	mov    %ebp,%ecx
  80156b:	d3 ea                	shr    %cl,%edx
  80156d:	89 e9                	mov    %ebp,%ecx
  80156f:	d3 ee                	shr    %cl,%esi
  801571:	09 d0                	or     %edx,%eax
  801573:	89 f2                	mov    %esi,%edx
  801575:	83 c4 1c             	add    $0x1c,%esp
  801578:	5b                   	pop    %ebx
  801579:	5e                   	pop    %esi
  80157a:	5f                   	pop    %edi
  80157b:	5d                   	pop    %ebp
  80157c:	c3                   	ret    
  80157d:	8d 76 00             	lea    0x0(%esi),%esi
  801580:	29 f9                	sub    %edi,%ecx
  801582:	19 d6                	sbb    %edx,%esi
  801584:	89 74 24 04          	mov    %esi,0x4(%esp)
  801588:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  80158c:	e9 18 ff ff ff       	jmp    8014a9 <__umoddi3+0x69>
