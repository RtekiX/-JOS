
obj/user/faultnostack：     文件格式 elf32-i386


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
  80002c:	e8 23 00 00 00       	call   800054 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

void _pgfault_upcall();

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 10             	sub    $0x10,%esp
	sys_env_set_pgfault_upcall(0, (void*) _pgfault_upcall);
  800039:	68 17 03 80 00       	push   $0x800317
  80003e:	6a 00                	push   $0x0
  800040:	e8 2c 02 00 00       	call   800271 <sys_env_set_pgfault_upcall>
	*(int*)0 = 0;
  800045:	c7 05 00 00 00 00 00 	movl   $0x0,0x0
  80004c:	00 00 00 
}
  80004f:	83 c4 10             	add    $0x10,%esp
  800052:	c9                   	leave  
  800053:	c3                   	ret    

00800054 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800054:	55                   	push   %ebp
  800055:	89 e5                	mov    %esp,%ebp
  800057:	56                   	push   %esi
  800058:	53                   	push   %ebx
  800059:	8b 5d 08             	mov    0x8(%ebp),%ebx
  80005c:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = &envs[ENVX(sys_getenvid())];
  80005f:	e8 c6 00 00 00       	call   80012a <sys_getenvid>
  800064:	25 ff 03 00 00       	and    $0x3ff,%eax
  800069:	6b c0 7c             	imul   $0x7c,%eax,%eax
  80006c:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  800071:	a3 04 20 80 00       	mov    %eax,0x802004
	// save the name of the program so that panic() can use it
	if (argc > 0)
  800076:	85 db                	test   %ebx,%ebx
  800078:	7e 07                	jle    800081 <libmain+0x2d>
		binaryname = argv[0];
  80007a:	8b 06                	mov    (%esi),%eax
  80007c:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  800081:	83 ec 08             	sub    $0x8,%esp
  800084:	56                   	push   %esi
  800085:	53                   	push   %ebx
  800086:	e8 a8 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  80008b:	e8 0a 00 00 00       	call   80009a <exit>
}
  800090:	83 c4 10             	add    $0x10,%esp
  800093:	8d 65 f8             	lea    -0x8(%ebp),%esp
  800096:	5b                   	pop    %ebx
  800097:	5e                   	pop    %esi
  800098:	5d                   	pop    %ebp
  800099:	c3                   	ret    

0080009a <exit>:

#include <inc/lib.h>

void
exit(void)
{
  80009a:	55                   	push   %ebp
  80009b:	89 e5                	mov    %esp,%ebp
  80009d:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  8000a0:	6a 00                	push   $0x0
  8000a2:	e8 42 00 00 00       	call   8000e9 <sys_env_destroy>
}
  8000a7:	83 c4 10             	add    $0x10,%esp
  8000aa:	c9                   	leave  
  8000ab:	c3                   	ret    

008000ac <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  8000ac:	55                   	push   %ebp
  8000ad:	89 e5                	mov    %esp,%ebp
  8000af:	57                   	push   %edi
  8000b0:	56                   	push   %esi
  8000b1:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000b2:	b8 00 00 00 00       	mov    $0x0,%eax
  8000b7:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8000ba:	8b 55 08             	mov    0x8(%ebp),%edx
  8000bd:	89 c3                	mov    %eax,%ebx
  8000bf:	89 c7                	mov    %eax,%edi
  8000c1:	89 c6                	mov    %eax,%esi
  8000c3:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  8000c5:	5b                   	pop    %ebx
  8000c6:	5e                   	pop    %esi
  8000c7:	5f                   	pop    %edi
  8000c8:	5d                   	pop    %ebp
  8000c9:	c3                   	ret    

008000ca <sys_cgetc>:

int
sys_cgetc(void)
{
  8000ca:	55                   	push   %ebp
  8000cb:	89 e5                	mov    %esp,%ebp
  8000cd:	57                   	push   %edi
  8000ce:	56                   	push   %esi
  8000cf:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000d0:	ba 00 00 00 00       	mov    $0x0,%edx
  8000d5:	b8 01 00 00 00       	mov    $0x1,%eax
  8000da:	89 d1                	mov    %edx,%ecx
  8000dc:	89 d3                	mov    %edx,%ebx
  8000de:	89 d7                	mov    %edx,%edi
  8000e0:	89 d6                	mov    %edx,%esi
  8000e2:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  8000e4:	5b                   	pop    %ebx
  8000e5:	5e                   	pop    %esi
  8000e6:	5f                   	pop    %edi
  8000e7:	5d                   	pop    %ebp
  8000e8:	c3                   	ret    

008000e9 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  8000e9:	55                   	push   %ebp
  8000ea:	89 e5                	mov    %esp,%ebp
  8000ec:	57                   	push   %edi
  8000ed:	56                   	push   %esi
  8000ee:	53                   	push   %ebx
  8000ef:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000f2:	b9 00 00 00 00       	mov    $0x0,%ecx
  8000f7:	b8 03 00 00 00       	mov    $0x3,%eax
  8000fc:	8b 55 08             	mov    0x8(%ebp),%edx
  8000ff:	89 cb                	mov    %ecx,%ebx
  800101:	89 cf                	mov    %ecx,%edi
  800103:	89 ce                	mov    %ecx,%esi
  800105:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800107:	85 c0                	test   %eax,%eax
  800109:	7e 17                	jle    800122 <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  80010b:	83 ec 0c             	sub    $0xc,%esp
  80010e:	50                   	push   %eax
  80010f:	6a 03                	push   $0x3
  800111:	68 6a 10 80 00       	push   $0x80106a
  800116:	6a 23                	push   $0x23
  800118:	68 87 10 80 00       	push   $0x801087
  80011d:	e8 19 02 00 00       	call   80033b <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800122:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800125:	5b                   	pop    %ebx
  800126:	5e                   	pop    %esi
  800127:	5f                   	pop    %edi
  800128:	5d                   	pop    %ebp
  800129:	c3                   	ret    

0080012a <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  80012a:	55                   	push   %ebp
  80012b:	89 e5                	mov    %esp,%ebp
  80012d:	57                   	push   %edi
  80012e:	56                   	push   %esi
  80012f:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800130:	ba 00 00 00 00       	mov    $0x0,%edx
  800135:	b8 02 00 00 00       	mov    $0x2,%eax
  80013a:	89 d1                	mov    %edx,%ecx
  80013c:	89 d3                	mov    %edx,%ebx
  80013e:	89 d7                	mov    %edx,%edi
  800140:	89 d6                	mov    %edx,%esi
  800142:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800144:	5b                   	pop    %ebx
  800145:	5e                   	pop    %esi
  800146:	5f                   	pop    %edi
  800147:	5d                   	pop    %ebp
  800148:	c3                   	ret    

00800149 <sys_yield>:

void
sys_yield(void)
{
  800149:	55                   	push   %ebp
  80014a:	89 e5                	mov    %esp,%ebp
  80014c:	57                   	push   %edi
  80014d:	56                   	push   %esi
  80014e:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80014f:	ba 00 00 00 00       	mov    $0x0,%edx
  800154:	b8 0a 00 00 00       	mov    $0xa,%eax
  800159:	89 d1                	mov    %edx,%ecx
  80015b:	89 d3                	mov    %edx,%ebx
  80015d:	89 d7                	mov    %edx,%edi
  80015f:	89 d6                	mov    %edx,%esi
  800161:	cd 30                	int    $0x30

void
sys_yield(void)
{
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
}
  800163:	5b                   	pop    %ebx
  800164:	5e                   	pop    %esi
  800165:	5f                   	pop    %edi
  800166:	5d                   	pop    %ebp
  800167:	c3                   	ret    

00800168 <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  800168:	55                   	push   %ebp
  800169:	89 e5                	mov    %esp,%ebp
  80016b:	57                   	push   %edi
  80016c:	56                   	push   %esi
  80016d:	53                   	push   %ebx
  80016e:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800171:	be 00 00 00 00       	mov    $0x0,%esi
  800176:	b8 04 00 00 00       	mov    $0x4,%eax
  80017b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80017e:	8b 55 08             	mov    0x8(%ebp),%edx
  800181:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800184:	89 f7                	mov    %esi,%edi
  800186:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800188:	85 c0                	test   %eax,%eax
  80018a:	7e 17                	jle    8001a3 <sys_page_alloc+0x3b>
		panic("syscall %d returned %d (> 0)", num, ret);
  80018c:	83 ec 0c             	sub    $0xc,%esp
  80018f:	50                   	push   %eax
  800190:	6a 04                	push   $0x4
  800192:	68 6a 10 80 00       	push   $0x80106a
  800197:	6a 23                	push   $0x23
  800199:	68 87 10 80 00       	push   $0x801087
  80019e:	e8 98 01 00 00       	call   80033b <_panic>

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
}
  8001a3:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8001a6:	5b                   	pop    %ebx
  8001a7:	5e                   	pop    %esi
  8001a8:	5f                   	pop    %edi
  8001a9:	5d                   	pop    %ebp
  8001aa:	c3                   	ret    

008001ab <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  8001ab:	55                   	push   %ebp
  8001ac:	89 e5                	mov    %esp,%ebp
  8001ae:	57                   	push   %edi
  8001af:	56                   	push   %esi
  8001b0:	53                   	push   %ebx
  8001b1:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8001b4:	b8 05 00 00 00       	mov    $0x5,%eax
  8001b9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8001bc:	8b 55 08             	mov    0x8(%ebp),%edx
  8001bf:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8001c2:	8b 7d 14             	mov    0x14(%ebp),%edi
  8001c5:	8b 75 18             	mov    0x18(%ebp),%esi
  8001c8:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  8001ca:	85 c0                	test   %eax,%eax
  8001cc:	7e 17                	jle    8001e5 <sys_page_map+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  8001ce:	83 ec 0c             	sub    $0xc,%esp
  8001d1:	50                   	push   %eax
  8001d2:	6a 05                	push   $0x5
  8001d4:	68 6a 10 80 00       	push   $0x80106a
  8001d9:	6a 23                	push   $0x23
  8001db:	68 87 10 80 00       	push   $0x801087
  8001e0:	e8 56 01 00 00       	call   80033b <_panic>

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
}
  8001e5:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8001e8:	5b                   	pop    %ebx
  8001e9:	5e                   	pop    %esi
  8001ea:	5f                   	pop    %edi
  8001eb:	5d                   	pop    %ebp
  8001ec:	c3                   	ret    

008001ed <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  8001ed:	55                   	push   %ebp
  8001ee:	89 e5                	mov    %esp,%ebp
  8001f0:	57                   	push   %edi
  8001f1:	56                   	push   %esi
  8001f2:	53                   	push   %ebx
  8001f3:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8001f6:	bb 00 00 00 00       	mov    $0x0,%ebx
  8001fb:	b8 06 00 00 00       	mov    $0x6,%eax
  800200:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800203:	8b 55 08             	mov    0x8(%ebp),%edx
  800206:	89 df                	mov    %ebx,%edi
  800208:	89 de                	mov    %ebx,%esi
  80020a:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  80020c:	85 c0                	test   %eax,%eax
  80020e:	7e 17                	jle    800227 <sys_page_unmap+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800210:	83 ec 0c             	sub    $0xc,%esp
  800213:	50                   	push   %eax
  800214:	6a 06                	push   $0x6
  800216:	68 6a 10 80 00       	push   $0x80106a
  80021b:	6a 23                	push   $0x23
  80021d:	68 87 10 80 00       	push   $0x801087
  800222:	e8 14 01 00 00       	call   80033b <_panic>

int
sys_page_unmap(envid_t envid, void *va)
{
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
}
  800227:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80022a:	5b                   	pop    %ebx
  80022b:	5e                   	pop    %esi
  80022c:	5f                   	pop    %edi
  80022d:	5d                   	pop    %ebp
  80022e:	c3                   	ret    

0080022f <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  80022f:	55                   	push   %ebp
  800230:	89 e5                	mov    %esp,%ebp
  800232:	57                   	push   %edi
  800233:	56                   	push   %esi
  800234:	53                   	push   %ebx
  800235:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800238:	bb 00 00 00 00       	mov    $0x0,%ebx
  80023d:	b8 08 00 00 00       	mov    $0x8,%eax
  800242:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800245:	8b 55 08             	mov    0x8(%ebp),%edx
  800248:	89 df                	mov    %ebx,%edi
  80024a:	89 de                	mov    %ebx,%esi
  80024c:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  80024e:	85 c0                	test   %eax,%eax
  800250:	7e 17                	jle    800269 <sys_env_set_status+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800252:	83 ec 0c             	sub    $0xc,%esp
  800255:	50                   	push   %eax
  800256:	6a 08                	push   $0x8
  800258:	68 6a 10 80 00       	push   $0x80106a
  80025d:	6a 23                	push   $0x23
  80025f:	68 87 10 80 00       	push   $0x801087
  800264:	e8 d2 00 00 00       	call   80033b <_panic>

int
sys_env_set_status(envid_t envid, int status)
{
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
}
  800269:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80026c:	5b                   	pop    %ebx
  80026d:	5e                   	pop    %esi
  80026e:	5f                   	pop    %edi
  80026f:	5d                   	pop    %ebp
  800270:	c3                   	ret    

00800271 <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  800271:	55                   	push   %ebp
  800272:	89 e5                	mov    %esp,%ebp
  800274:	57                   	push   %edi
  800275:	56                   	push   %esi
  800276:	53                   	push   %ebx
  800277:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80027a:	bb 00 00 00 00       	mov    $0x0,%ebx
  80027f:	b8 09 00 00 00       	mov    $0x9,%eax
  800284:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800287:	8b 55 08             	mov    0x8(%ebp),%edx
  80028a:	89 df                	mov    %ebx,%edi
  80028c:	89 de                	mov    %ebx,%esi
  80028e:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800290:	85 c0                	test   %eax,%eax
  800292:	7e 17                	jle    8002ab <sys_env_set_pgfault_upcall+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800294:	83 ec 0c             	sub    $0xc,%esp
  800297:	50                   	push   %eax
  800298:	6a 09                	push   $0x9
  80029a:	68 6a 10 80 00       	push   $0x80106a
  80029f:	6a 23                	push   $0x23
  8002a1:	68 87 10 80 00       	push   $0x801087
  8002a6:	e8 90 00 00 00       	call   80033b <_panic>

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
}
  8002ab:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8002ae:	5b                   	pop    %ebx
  8002af:	5e                   	pop    %esi
  8002b0:	5f                   	pop    %edi
  8002b1:	5d                   	pop    %ebp
  8002b2:	c3                   	ret    

008002b3 <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  8002b3:	55                   	push   %ebp
  8002b4:	89 e5                	mov    %esp,%ebp
  8002b6:	57                   	push   %edi
  8002b7:	56                   	push   %esi
  8002b8:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8002b9:	be 00 00 00 00       	mov    $0x0,%esi
  8002be:	b8 0b 00 00 00       	mov    $0xb,%eax
  8002c3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8002c6:	8b 55 08             	mov    0x8(%ebp),%edx
  8002c9:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8002cc:	8b 7d 14             	mov    0x14(%ebp),%edi
  8002cf:	cd 30                	int    $0x30

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
}
  8002d1:	5b                   	pop    %ebx
  8002d2:	5e                   	pop    %esi
  8002d3:	5f                   	pop    %edi
  8002d4:	5d                   	pop    %ebp
  8002d5:	c3                   	ret    

008002d6 <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  8002d6:	55                   	push   %ebp
  8002d7:	89 e5                	mov    %esp,%ebp
  8002d9:	57                   	push   %edi
  8002da:	56                   	push   %esi
  8002db:	53                   	push   %ebx
  8002dc:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8002df:	b9 00 00 00 00       	mov    $0x0,%ecx
  8002e4:	b8 0c 00 00 00       	mov    $0xc,%eax
  8002e9:	8b 55 08             	mov    0x8(%ebp),%edx
  8002ec:	89 cb                	mov    %ecx,%ebx
  8002ee:	89 cf                	mov    %ecx,%edi
  8002f0:	89 ce                	mov    %ecx,%esi
  8002f2:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  8002f4:	85 c0                	test   %eax,%eax
  8002f6:	7e 17                	jle    80030f <sys_ipc_recv+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  8002f8:	83 ec 0c             	sub    $0xc,%esp
  8002fb:	50                   	push   %eax
  8002fc:	6a 0c                	push   $0xc
  8002fe:	68 6a 10 80 00       	push   $0x80106a
  800303:	6a 23                	push   $0x23
  800305:	68 87 10 80 00       	push   $0x801087
  80030a:	e8 2c 00 00 00       	call   80033b <_panic>

int
sys_ipc_recv(void *dstva)
{
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
}
  80030f:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800312:	5b                   	pop    %ebx
  800313:	5e                   	pop    %esi
  800314:	5f                   	pop    %edi
  800315:	5d                   	pop    %ebp
  800316:	c3                   	ret    

00800317 <_pgfault_upcall>:

.text
.globl _pgfault_upcall
_pgfault_upcall:
	// Call the C page fault handler.
	pushl %esp			// function argument: pointer to UTF
  800317:	54                   	push   %esp
	movl _pgfault_handler, %eax
  800318:	a1 08 20 80 00       	mov    0x802008,%eax
	call *%eax
  80031d:	ff d0                	call   *%eax
	addl $4, %esp			// pop function argument
  80031f:	83 c4 04             	add    $0x4,%esp
	// registers are available for intermediate calculations.  You
	// may find that you have to rearrange your code in non-obvious
	// ways as registers become unavailable as scratch space.
	//
	// LAB 4: Your code here.
	movl 0x28(%esp), %eax
  800322:	8b 44 24 28          	mov    0x28(%esp),%eax
    	subl $0x4, 0x30(%esp)
  800326:	83 6c 24 30 04       	subl   $0x4,0x30(%esp)
   	movl 0x30(%esp), %ebp
  80032b:	8b 6c 24 30          	mov    0x30(%esp),%ebp
    	movl %eax, (%ebp)
  80032f:	89 45 00             	mov    %eax,0x0(%ebp)
    	// pop fault_va, err
    	popl %eax
  800332:	58                   	pop    %eax
    	popl %eax
  800333:	58                   	pop    %eax
	// Restore the trap-time registers.  After you do this, you
	// can no longer modify any general-purpose registers.
	// LAB 4: Your code here.
	popal
  800334:	61                   	popa   
	// Restore eflags from the stack.  After you do this, you can
	// no longer use arithmetic operations or anything else that
	// modifies eflags.
	// LAB 4: Your code here.
	addl $0x4, %esp
  800335:	83 c4 04             	add    $0x4,%esp
	popfl
  800338:	9d                   	popf   
	// Switch back to the adjusted trap-time stack.
	// LAB 4: Your code here.
	popl %esp
  800339:	5c                   	pop    %esp
	// Return to re-execute the instruction that faulted.
	// LAB 4: Your code here.
	ret
  80033a:	c3                   	ret    

0080033b <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  80033b:	55                   	push   %ebp
  80033c:	89 e5                	mov    %esp,%ebp
  80033e:	56                   	push   %esi
  80033f:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800340:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800343:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800349:	e8 dc fd ff ff       	call   80012a <sys_getenvid>
  80034e:	83 ec 0c             	sub    $0xc,%esp
  800351:	ff 75 0c             	pushl  0xc(%ebp)
  800354:	ff 75 08             	pushl  0x8(%ebp)
  800357:	56                   	push   %esi
  800358:	50                   	push   %eax
  800359:	68 98 10 80 00       	push   $0x801098
  80035e:	e8 b1 00 00 00       	call   800414 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800363:	83 c4 18             	add    $0x18,%esp
  800366:	53                   	push   %ebx
  800367:	ff 75 10             	pushl  0x10(%ebp)
  80036a:	e8 54 00 00 00       	call   8003c3 <vcprintf>
	cprintf("\n");
  80036f:	c7 04 24 bb 10 80 00 	movl   $0x8010bb,(%esp)
  800376:	e8 99 00 00 00       	call   800414 <cprintf>
  80037b:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  80037e:	cc                   	int3   
  80037f:	eb fd                	jmp    80037e <_panic+0x43>

00800381 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800381:	55                   	push   %ebp
  800382:	89 e5                	mov    %esp,%ebp
  800384:	53                   	push   %ebx
  800385:	83 ec 04             	sub    $0x4,%esp
  800388:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  80038b:	8b 13                	mov    (%ebx),%edx
  80038d:	8d 42 01             	lea    0x1(%edx),%eax
  800390:	89 03                	mov    %eax,(%ebx)
  800392:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800395:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  800399:	3d ff 00 00 00       	cmp    $0xff,%eax
  80039e:	75 1a                	jne    8003ba <putch+0x39>
		sys_cputs(b->buf, b->idx);
  8003a0:	83 ec 08             	sub    $0x8,%esp
  8003a3:	68 ff 00 00 00       	push   $0xff
  8003a8:	8d 43 08             	lea    0x8(%ebx),%eax
  8003ab:	50                   	push   %eax
  8003ac:	e8 fb fc ff ff       	call   8000ac <sys_cputs>
		b->idx = 0;
  8003b1:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8003b7:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8003ba:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8003be:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8003c1:	c9                   	leave  
  8003c2:	c3                   	ret    

008003c3 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8003c3:	55                   	push   %ebp
  8003c4:	89 e5                	mov    %esp,%ebp
  8003c6:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8003cc:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8003d3:	00 00 00 
	b.cnt = 0;
  8003d6:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8003dd:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8003e0:	ff 75 0c             	pushl  0xc(%ebp)
  8003e3:	ff 75 08             	pushl  0x8(%ebp)
  8003e6:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  8003ec:	50                   	push   %eax
  8003ed:	68 81 03 80 00       	push   $0x800381
  8003f2:	e8 1a 01 00 00       	call   800511 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  8003f7:	83 c4 08             	add    $0x8,%esp
  8003fa:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  800400:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800406:	50                   	push   %eax
  800407:	e8 a0 fc ff ff       	call   8000ac <sys_cputs>

	return b.cnt;
}
  80040c:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800412:	c9                   	leave  
  800413:	c3                   	ret    

00800414 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800414:	55                   	push   %ebp
  800415:	89 e5                	mov    %esp,%ebp
  800417:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  80041a:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  80041d:	50                   	push   %eax
  80041e:	ff 75 08             	pushl  0x8(%ebp)
  800421:	e8 9d ff ff ff       	call   8003c3 <vcprintf>
	va_end(ap);

	return cnt;
}
  800426:	c9                   	leave  
  800427:	c3                   	ret    

00800428 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800428:	55                   	push   %ebp
  800429:	89 e5                	mov    %esp,%ebp
  80042b:	57                   	push   %edi
  80042c:	56                   	push   %esi
  80042d:	53                   	push   %ebx
  80042e:	83 ec 1c             	sub    $0x1c,%esp
  800431:	89 c7                	mov    %eax,%edi
  800433:	89 d6                	mov    %edx,%esi
  800435:	8b 45 08             	mov    0x8(%ebp),%eax
  800438:	8b 55 0c             	mov    0xc(%ebp),%edx
  80043b:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80043e:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800441:	8b 4d 10             	mov    0x10(%ebp),%ecx
  800444:	bb 00 00 00 00       	mov    $0x0,%ebx
  800449:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  80044c:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  80044f:	39 d3                	cmp    %edx,%ebx
  800451:	72 05                	jb     800458 <printnum+0x30>
  800453:	39 45 10             	cmp    %eax,0x10(%ebp)
  800456:	77 45                	ja     80049d <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800458:	83 ec 0c             	sub    $0xc,%esp
  80045b:	ff 75 18             	pushl  0x18(%ebp)
  80045e:	8b 45 14             	mov    0x14(%ebp),%eax
  800461:	8d 58 ff             	lea    -0x1(%eax),%ebx
  800464:	53                   	push   %ebx
  800465:	ff 75 10             	pushl  0x10(%ebp)
  800468:	83 ec 08             	sub    $0x8,%esp
  80046b:	ff 75 e4             	pushl  -0x1c(%ebp)
  80046e:	ff 75 e0             	pushl  -0x20(%ebp)
  800471:	ff 75 dc             	pushl  -0x24(%ebp)
  800474:	ff 75 d8             	pushl  -0x28(%ebp)
  800477:	e8 54 09 00 00       	call   800dd0 <__udivdi3>
  80047c:	83 c4 18             	add    $0x18,%esp
  80047f:	52                   	push   %edx
  800480:	50                   	push   %eax
  800481:	89 f2                	mov    %esi,%edx
  800483:	89 f8                	mov    %edi,%eax
  800485:	e8 9e ff ff ff       	call   800428 <printnum>
  80048a:	83 c4 20             	add    $0x20,%esp
  80048d:	eb 18                	jmp    8004a7 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  80048f:	83 ec 08             	sub    $0x8,%esp
  800492:	56                   	push   %esi
  800493:	ff 75 18             	pushl  0x18(%ebp)
  800496:	ff d7                	call   *%edi
  800498:	83 c4 10             	add    $0x10,%esp
  80049b:	eb 03                	jmp    8004a0 <printnum+0x78>
  80049d:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8004a0:	83 eb 01             	sub    $0x1,%ebx
  8004a3:	85 db                	test   %ebx,%ebx
  8004a5:	7f e8                	jg     80048f <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8004a7:	83 ec 08             	sub    $0x8,%esp
  8004aa:	56                   	push   %esi
  8004ab:	83 ec 04             	sub    $0x4,%esp
  8004ae:	ff 75 e4             	pushl  -0x1c(%ebp)
  8004b1:	ff 75 e0             	pushl  -0x20(%ebp)
  8004b4:	ff 75 dc             	pushl  -0x24(%ebp)
  8004b7:	ff 75 d8             	pushl  -0x28(%ebp)
  8004ba:	e8 41 0a 00 00       	call   800f00 <__umoddi3>
  8004bf:	83 c4 14             	add    $0x14,%esp
  8004c2:	0f be 80 bd 10 80 00 	movsbl 0x8010bd(%eax),%eax
  8004c9:	50                   	push   %eax
  8004ca:	ff d7                	call   *%edi
}
  8004cc:	83 c4 10             	add    $0x10,%esp
  8004cf:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8004d2:	5b                   	pop    %ebx
  8004d3:	5e                   	pop    %esi
  8004d4:	5f                   	pop    %edi
  8004d5:	5d                   	pop    %ebp
  8004d6:	c3                   	ret    

008004d7 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8004d7:	55                   	push   %ebp
  8004d8:	89 e5                	mov    %esp,%ebp
  8004da:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8004dd:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8004e1:	8b 10                	mov    (%eax),%edx
  8004e3:	3b 50 04             	cmp    0x4(%eax),%edx
  8004e6:	73 0a                	jae    8004f2 <sprintputch+0x1b>
		*b->buf++ = ch;
  8004e8:	8d 4a 01             	lea    0x1(%edx),%ecx
  8004eb:	89 08                	mov    %ecx,(%eax)
  8004ed:	8b 45 08             	mov    0x8(%ebp),%eax
  8004f0:	88 02                	mov    %al,(%edx)
}
  8004f2:	5d                   	pop    %ebp
  8004f3:	c3                   	ret    

008004f4 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8004f4:	55                   	push   %ebp
  8004f5:	89 e5                	mov    %esp,%ebp
  8004f7:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  8004fa:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8004fd:	50                   	push   %eax
  8004fe:	ff 75 10             	pushl  0x10(%ebp)
  800501:	ff 75 0c             	pushl  0xc(%ebp)
  800504:	ff 75 08             	pushl  0x8(%ebp)
  800507:	e8 05 00 00 00       	call   800511 <vprintfmt>
	va_end(ap);
}
  80050c:	83 c4 10             	add    $0x10,%esp
  80050f:	c9                   	leave  
  800510:	c3                   	ret    

00800511 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800511:	55                   	push   %ebp
  800512:	89 e5                	mov    %esp,%ebp
  800514:	57                   	push   %edi
  800515:	56                   	push   %esi
  800516:	53                   	push   %ebx
  800517:	83 ec 2c             	sub    $0x2c,%esp
  80051a:	8b 75 08             	mov    0x8(%ebp),%esi
  80051d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800520:	8b 7d 10             	mov    0x10(%ebp),%edi
  800523:	eb 12                	jmp    800537 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800525:	85 c0                	test   %eax,%eax
  800527:	0f 84 42 04 00 00    	je     80096f <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
  80052d:	83 ec 08             	sub    $0x8,%esp
  800530:	53                   	push   %ebx
  800531:	50                   	push   %eax
  800532:	ff d6                	call   *%esi
  800534:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800537:	83 c7 01             	add    $0x1,%edi
  80053a:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  80053e:	83 f8 25             	cmp    $0x25,%eax
  800541:	75 e2                	jne    800525 <vprintfmt+0x14>
  800543:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  800547:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  80054e:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800555:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  80055c:	b9 00 00 00 00       	mov    $0x0,%ecx
  800561:	eb 07                	jmp    80056a <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800563:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  800566:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80056a:	8d 47 01             	lea    0x1(%edi),%eax
  80056d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800570:	0f b6 07             	movzbl (%edi),%eax
  800573:	0f b6 d0             	movzbl %al,%edx
  800576:	83 e8 23             	sub    $0x23,%eax
  800579:	3c 55                	cmp    $0x55,%al
  80057b:	0f 87 d3 03 00 00    	ja     800954 <vprintfmt+0x443>
  800581:	0f b6 c0             	movzbl %al,%eax
  800584:	ff 24 85 80 11 80 00 	jmp    *0x801180(,%eax,4)
  80058b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  80058e:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  800592:	eb d6                	jmp    80056a <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800594:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800597:	b8 00 00 00 00       	mov    $0x0,%eax
  80059c:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  80059f:	8d 04 80             	lea    (%eax,%eax,4),%eax
  8005a2:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
  8005a6:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
  8005a9:	8d 4a d0             	lea    -0x30(%edx),%ecx
  8005ac:	83 f9 09             	cmp    $0x9,%ecx
  8005af:	77 3f                	ja     8005f0 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8005b1:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8005b4:	eb e9                	jmp    80059f <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8005b6:	8b 45 14             	mov    0x14(%ebp),%eax
  8005b9:	8b 00                	mov    (%eax),%eax
  8005bb:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8005be:	8b 45 14             	mov    0x14(%ebp),%eax
  8005c1:	8d 40 04             	lea    0x4(%eax),%eax
  8005c4:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005c7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8005ca:	eb 2a                	jmp    8005f6 <vprintfmt+0xe5>
  8005cc:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8005cf:	85 c0                	test   %eax,%eax
  8005d1:	ba 00 00 00 00       	mov    $0x0,%edx
  8005d6:	0f 49 d0             	cmovns %eax,%edx
  8005d9:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005dc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8005df:	eb 89                	jmp    80056a <vprintfmt+0x59>
  8005e1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8005e4:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  8005eb:	e9 7a ff ff ff       	jmp    80056a <vprintfmt+0x59>
  8005f0:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  8005f3:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  8005f6:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8005fa:	0f 89 6a ff ff ff    	jns    80056a <vprintfmt+0x59>
				width = precision, precision = -1;
  800600:	8b 45 d0             	mov    -0x30(%ebp),%eax
  800603:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800606:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  80060d:	e9 58 ff ff ff       	jmp    80056a <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800612:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800615:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  800618:	e9 4d ff ff ff       	jmp    80056a <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  80061d:	8b 45 14             	mov    0x14(%ebp),%eax
  800620:	8d 78 04             	lea    0x4(%eax),%edi
  800623:	83 ec 08             	sub    $0x8,%esp
  800626:	53                   	push   %ebx
  800627:	ff 30                	pushl  (%eax)
  800629:	ff d6                	call   *%esi
			break;
  80062b:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  80062e:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800631:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  800634:	e9 fe fe ff ff       	jmp    800537 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800639:	8b 45 14             	mov    0x14(%ebp),%eax
  80063c:	8d 78 04             	lea    0x4(%eax),%edi
  80063f:	8b 00                	mov    (%eax),%eax
  800641:	99                   	cltd   
  800642:	31 d0                	xor    %edx,%eax
  800644:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800646:	83 f8 09             	cmp    $0x9,%eax
  800649:	7f 0b                	jg     800656 <vprintfmt+0x145>
  80064b:	8b 14 85 e0 12 80 00 	mov    0x8012e0(,%eax,4),%edx
  800652:	85 d2                	test   %edx,%edx
  800654:	75 1b                	jne    800671 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
  800656:	50                   	push   %eax
  800657:	68 d5 10 80 00       	push   $0x8010d5
  80065c:	53                   	push   %ebx
  80065d:	56                   	push   %esi
  80065e:	e8 91 fe ff ff       	call   8004f4 <printfmt>
  800663:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  800666:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800669:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  80066c:	e9 c6 fe ff ff       	jmp    800537 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  800671:	52                   	push   %edx
  800672:	68 de 10 80 00       	push   $0x8010de
  800677:	53                   	push   %ebx
  800678:	56                   	push   %esi
  800679:	e8 76 fe ff ff       	call   8004f4 <printfmt>
  80067e:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  800681:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800684:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800687:	e9 ab fe ff ff       	jmp    800537 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  80068c:	8b 45 14             	mov    0x14(%ebp),%eax
  80068f:	83 c0 04             	add    $0x4,%eax
  800692:	89 45 cc             	mov    %eax,-0x34(%ebp)
  800695:	8b 45 14             	mov    0x14(%ebp),%eax
  800698:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  80069a:	85 ff                	test   %edi,%edi
  80069c:	b8 ce 10 80 00       	mov    $0x8010ce,%eax
  8006a1:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  8006a4:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8006a8:	0f 8e 94 00 00 00    	jle    800742 <vprintfmt+0x231>
  8006ae:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  8006b2:	0f 84 98 00 00 00    	je     800750 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
  8006b8:	83 ec 08             	sub    $0x8,%esp
  8006bb:	ff 75 d0             	pushl  -0x30(%ebp)
  8006be:	57                   	push   %edi
  8006bf:	e8 33 03 00 00       	call   8009f7 <strnlen>
  8006c4:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8006c7:	29 c1                	sub    %eax,%ecx
  8006c9:	89 4d c8             	mov    %ecx,-0x38(%ebp)
  8006cc:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  8006cf:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  8006d3:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8006d6:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  8006d9:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8006db:	eb 0f                	jmp    8006ec <vprintfmt+0x1db>
					putch(padc, putdat);
  8006dd:	83 ec 08             	sub    $0x8,%esp
  8006e0:	53                   	push   %ebx
  8006e1:	ff 75 e0             	pushl  -0x20(%ebp)
  8006e4:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8006e6:	83 ef 01             	sub    $0x1,%edi
  8006e9:	83 c4 10             	add    $0x10,%esp
  8006ec:	85 ff                	test   %edi,%edi
  8006ee:	7f ed                	jg     8006dd <vprintfmt+0x1cc>
  8006f0:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  8006f3:	8b 4d c8             	mov    -0x38(%ebp),%ecx
  8006f6:	85 c9                	test   %ecx,%ecx
  8006f8:	b8 00 00 00 00       	mov    $0x0,%eax
  8006fd:	0f 49 c1             	cmovns %ecx,%eax
  800700:	29 c1                	sub    %eax,%ecx
  800702:	89 75 08             	mov    %esi,0x8(%ebp)
  800705:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800708:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80070b:	89 cb                	mov    %ecx,%ebx
  80070d:	eb 4d                	jmp    80075c <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  80070f:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800713:	74 1b                	je     800730 <vprintfmt+0x21f>
  800715:	0f be c0             	movsbl %al,%eax
  800718:	83 e8 20             	sub    $0x20,%eax
  80071b:	83 f8 5e             	cmp    $0x5e,%eax
  80071e:	76 10                	jbe    800730 <vprintfmt+0x21f>
					putch('?', putdat);
  800720:	83 ec 08             	sub    $0x8,%esp
  800723:	ff 75 0c             	pushl  0xc(%ebp)
  800726:	6a 3f                	push   $0x3f
  800728:	ff 55 08             	call   *0x8(%ebp)
  80072b:	83 c4 10             	add    $0x10,%esp
  80072e:	eb 0d                	jmp    80073d <vprintfmt+0x22c>
				else
					putch(ch, putdat);
  800730:	83 ec 08             	sub    $0x8,%esp
  800733:	ff 75 0c             	pushl  0xc(%ebp)
  800736:	52                   	push   %edx
  800737:	ff 55 08             	call   *0x8(%ebp)
  80073a:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  80073d:	83 eb 01             	sub    $0x1,%ebx
  800740:	eb 1a                	jmp    80075c <vprintfmt+0x24b>
  800742:	89 75 08             	mov    %esi,0x8(%ebp)
  800745:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800748:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80074b:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  80074e:	eb 0c                	jmp    80075c <vprintfmt+0x24b>
  800750:	89 75 08             	mov    %esi,0x8(%ebp)
  800753:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800756:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800759:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  80075c:	83 c7 01             	add    $0x1,%edi
  80075f:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800763:	0f be d0             	movsbl %al,%edx
  800766:	85 d2                	test   %edx,%edx
  800768:	74 23                	je     80078d <vprintfmt+0x27c>
  80076a:	85 f6                	test   %esi,%esi
  80076c:	78 a1                	js     80070f <vprintfmt+0x1fe>
  80076e:	83 ee 01             	sub    $0x1,%esi
  800771:	79 9c                	jns    80070f <vprintfmt+0x1fe>
  800773:	89 df                	mov    %ebx,%edi
  800775:	8b 75 08             	mov    0x8(%ebp),%esi
  800778:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80077b:	eb 18                	jmp    800795 <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  80077d:	83 ec 08             	sub    $0x8,%esp
  800780:	53                   	push   %ebx
  800781:	6a 20                	push   $0x20
  800783:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800785:	83 ef 01             	sub    $0x1,%edi
  800788:	83 c4 10             	add    $0x10,%esp
  80078b:	eb 08                	jmp    800795 <vprintfmt+0x284>
  80078d:	89 df                	mov    %ebx,%edi
  80078f:	8b 75 08             	mov    0x8(%ebp),%esi
  800792:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800795:	85 ff                	test   %edi,%edi
  800797:	7f e4                	jg     80077d <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800799:	8b 45 cc             	mov    -0x34(%ebp),%eax
  80079c:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80079f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8007a2:	e9 90 fd ff ff       	jmp    800537 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8007a7:	83 f9 01             	cmp    $0x1,%ecx
  8007aa:	7e 19                	jle    8007c5 <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
  8007ac:	8b 45 14             	mov    0x14(%ebp),%eax
  8007af:	8b 50 04             	mov    0x4(%eax),%edx
  8007b2:	8b 00                	mov    (%eax),%eax
  8007b4:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8007b7:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8007ba:	8b 45 14             	mov    0x14(%ebp),%eax
  8007bd:	8d 40 08             	lea    0x8(%eax),%eax
  8007c0:	89 45 14             	mov    %eax,0x14(%ebp)
  8007c3:	eb 38                	jmp    8007fd <vprintfmt+0x2ec>
	else if (lflag)
  8007c5:	85 c9                	test   %ecx,%ecx
  8007c7:	74 1b                	je     8007e4 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
  8007c9:	8b 45 14             	mov    0x14(%ebp),%eax
  8007cc:	8b 00                	mov    (%eax),%eax
  8007ce:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8007d1:	89 c1                	mov    %eax,%ecx
  8007d3:	c1 f9 1f             	sar    $0x1f,%ecx
  8007d6:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8007d9:	8b 45 14             	mov    0x14(%ebp),%eax
  8007dc:	8d 40 04             	lea    0x4(%eax),%eax
  8007df:	89 45 14             	mov    %eax,0x14(%ebp)
  8007e2:	eb 19                	jmp    8007fd <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
  8007e4:	8b 45 14             	mov    0x14(%ebp),%eax
  8007e7:	8b 00                	mov    (%eax),%eax
  8007e9:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8007ec:	89 c1                	mov    %eax,%ecx
  8007ee:	c1 f9 1f             	sar    $0x1f,%ecx
  8007f1:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8007f4:	8b 45 14             	mov    0x14(%ebp),%eax
  8007f7:	8d 40 04             	lea    0x4(%eax),%eax
  8007fa:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  8007fd:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800800:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800803:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800808:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  80080c:	0f 89 0e 01 00 00    	jns    800920 <vprintfmt+0x40f>
				putch('-', putdat);
  800812:	83 ec 08             	sub    $0x8,%esp
  800815:	53                   	push   %ebx
  800816:	6a 2d                	push   $0x2d
  800818:	ff d6                	call   *%esi
				num = -(long long) num;
  80081a:	8b 55 d8             	mov    -0x28(%ebp),%edx
  80081d:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800820:	f7 da                	neg    %edx
  800822:	83 d1 00             	adc    $0x0,%ecx
  800825:	f7 d9                	neg    %ecx
  800827:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  80082a:	b8 0a 00 00 00       	mov    $0xa,%eax
  80082f:	e9 ec 00 00 00       	jmp    800920 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800834:	83 f9 01             	cmp    $0x1,%ecx
  800837:	7e 18                	jle    800851 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
  800839:	8b 45 14             	mov    0x14(%ebp),%eax
  80083c:	8b 10                	mov    (%eax),%edx
  80083e:	8b 48 04             	mov    0x4(%eax),%ecx
  800841:	8d 40 08             	lea    0x8(%eax),%eax
  800844:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800847:	b8 0a 00 00 00       	mov    $0xa,%eax
  80084c:	e9 cf 00 00 00       	jmp    800920 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  800851:	85 c9                	test   %ecx,%ecx
  800853:	74 1a                	je     80086f <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
  800855:	8b 45 14             	mov    0x14(%ebp),%eax
  800858:	8b 10                	mov    (%eax),%edx
  80085a:	b9 00 00 00 00       	mov    $0x0,%ecx
  80085f:	8d 40 04             	lea    0x4(%eax),%eax
  800862:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800865:	b8 0a 00 00 00       	mov    $0xa,%eax
  80086a:	e9 b1 00 00 00       	jmp    800920 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  80086f:	8b 45 14             	mov    0x14(%ebp),%eax
  800872:	8b 10                	mov    (%eax),%edx
  800874:	b9 00 00 00 00       	mov    $0x0,%ecx
  800879:	8d 40 04             	lea    0x4(%eax),%eax
  80087c:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  80087f:	b8 0a 00 00 00       	mov    $0xa,%eax
  800884:	e9 97 00 00 00       	jmp    800920 <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
  800889:	83 ec 08             	sub    $0x8,%esp
  80088c:	53                   	push   %ebx
  80088d:	6a 58                	push   $0x58
  80088f:	ff d6                	call   *%esi
			putch('X', putdat);
  800891:	83 c4 08             	add    $0x8,%esp
  800894:	53                   	push   %ebx
  800895:	6a 58                	push   $0x58
  800897:	ff d6                	call   *%esi
			putch('X', putdat);
  800899:	83 c4 08             	add    $0x8,%esp
  80089c:	53                   	push   %ebx
  80089d:	6a 58                	push   $0x58
  80089f:	ff d6                	call   *%esi
			break;
  8008a1:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8008a4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
  8008a7:	e9 8b fc ff ff       	jmp    800537 <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
  8008ac:	83 ec 08             	sub    $0x8,%esp
  8008af:	53                   	push   %ebx
  8008b0:	6a 30                	push   $0x30
  8008b2:	ff d6                	call   *%esi
			putch('x', putdat);
  8008b4:	83 c4 08             	add    $0x8,%esp
  8008b7:	53                   	push   %ebx
  8008b8:	6a 78                	push   $0x78
  8008ba:	ff d6                	call   *%esi
			num = (unsigned long long)
  8008bc:	8b 45 14             	mov    0x14(%ebp),%eax
  8008bf:	8b 10                	mov    (%eax),%edx
  8008c1:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  8008c6:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  8008c9:	8d 40 04             	lea    0x4(%eax),%eax
  8008cc:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  8008cf:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
  8008d4:	eb 4a                	jmp    800920 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8008d6:	83 f9 01             	cmp    $0x1,%ecx
  8008d9:	7e 15                	jle    8008f0 <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
  8008db:	8b 45 14             	mov    0x14(%ebp),%eax
  8008de:	8b 10                	mov    (%eax),%edx
  8008e0:	8b 48 04             	mov    0x4(%eax),%ecx
  8008e3:	8d 40 08             	lea    0x8(%eax),%eax
  8008e6:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  8008e9:	b8 10 00 00 00       	mov    $0x10,%eax
  8008ee:	eb 30                	jmp    800920 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  8008f0:	85 c9                	test   %ecx,%ecx
  8008f2:	74 17                	je     80090b <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
  8008f4:	8b 45 14             	mov    0x14(%ebp),%eax
  8008f7:	8b 10                	mov    (%eax),%edx
  8008f9:	b9 00 00 00 00       	mov    $0x0,%ecx
  8008fe:	8d 40 04             	lea    0x4(%eax),%eax
  800901:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800904:	b8 10 00 00 00       	mov    $0x10,%eax
  800909:	eb 15                	jmp    800920 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  80090b:	8b 45 14             	mov    0x14(%ebp),%eax
  80090e:	8b 10                	mov    (%eax),%edx
  800910:	b9 00 00 00 00       	mov    $0x0,%ecx
  800915:	8d 40 04             	lea    0x4(%eax),%eax
  800918:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  80091b:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
  800920:	83 ec 0c             	sub    $0xc,%esp
  800923:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  800927:	57                   	push   %edi
  800928:	ff 75 e0             	pushl  -0x20(%ebp)
  80092b:	50                   	push   %eax
  80092c:	51                   	push   %ecx
  80092d:	52                   	push   %edx
  80092e:	89 da                	mov    %ebx,%edx
  800930:	89 f0                	mov    %esi,%eax
  800932:	e8 f1 fa ff ff       	call   800428 <printnum>
			break;
  800937:	83 c4 20             	add    $0x20,%esp
  80093a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80093d:	e9 f5 fb ff ff       	jmp    800537 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  800942:	83 ec 08             	sub    $0x8,%esp
  800945:	53                   	push   %ebx
  800946:	52                   	push   %edx
  800947:	ff d6                	call   *%esi
			break;
  800949:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80094c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  80094f:	e9 e3 fb ff ff       	jmp    800537 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  800954:	83 ec 08             	sub    $0x8,%esp
  800957:	53                   	push   %ebx
  800958:	6a 25                	push   $0x25
  80095a:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  80095c:	83 c4 10             	add    $0x10,%esp
  80095f:	eb 03                	jmp    800964 <vprintfmt+0x453>
  800961:	83 ef 01             	sub    $0x1,%edi
  800964:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800968:	75 f7                	jne    800961 <vprintfmt+0x450>
  80096a:	e9 c8 fb ff ff       	jmp    800537 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  80096f:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800972:	5b                   	pop    %ebx
  800973:	5e                   	pop    %esi
  800974:	5f                   	pop    %edi
  800975:	5d                   	pop    %ebp
  800976:	c3                   	ret    

00800977 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800977:	55                   	push   %ebp
  800978:	89 e5                	mov    %esp,%ebp
  80097a:	83 ec 18             	sub    $0x18,%esp
  80097d:	8b 45 08             	mov    0x8(%ebp),%eax
  800980:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800983:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800986:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  80098a:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  80098d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800994:	85 c0                	test   %eax,%eax
  800996:	74 26                	je     8009be <vsnprintf+0x47>
  800998:	85 d2                	test   %edx,%edx
  80099a:	7e 22                	jle    8009be <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  80099c:	ff 75 14             	pushl  0x14(%ebp)
  80099f:	ff 75 10             	pushl  0x10(%ebp)
  8009a2:	8d 45 ec             	lea    -0x14(%ebp),%eax
  8009a5:	50                   	push   %eax
  8009a6:	68 d7 04 80 00       	push   $0x8004d7
  8009ab:	e8 61 fb ff ff       	call   800511 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  8009b0:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8009b3:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  8009b6:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8009b9:	83 c4 10             	add    $0x10,%esp
  8009bc:	eb 05                	jmp    8009c3 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  8009be:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  8009c3:	c9                   	leave  
  8009c4:	c3                   	ret    

008009c5 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  8009c5:	55                   	push   %ebp
  8009c6:	89 e5                	mov    %esp,%ebp
  8009c8:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  8009cb:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  8009ce:	50                   	push   %eax
  8009cf:	ff 75 10             	pushl  0x10(%ebp)
  8009d2:	ff 75 0c             	pushl  0xc(%ebp)
  8009d5:	ff 75 08             	pushl  0x8(%ebp)
  8009d8:	e8 9a ff ff ff       	call   800977 <vsnprintf>
	va_end(ap);

	return rc;
}
  8009dd:	c9                   	leave  
  8009de:	c3                   	ret    

008009df <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  8009df:	55                   	push   %ebp
  8009e0:	89 e5                	mov    %esp,%ebp
  8009e2:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  8009e5:	b8 00 00 00 00       	mov    $0x0,%eax
  8009ea:	eb 03                	jmp    8009ef <strlen+0x10>
		n++;
  8009ec:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  8009ef:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  8009f3:	75 f7                	jne    8009ec <strlen+0xd>
		n++;
	return n;
}
  8009f5:	5d                   	pop    %ebp
  8009f6:	c3                   	ret    

008009f7 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  8009f7:	55                   	push   %ebp
  8009f8:	89 e5                	mov    %esp,%ebp
  8009fa:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8009fd:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800a00:	ba 00 00 00 00       	mov    $0x0,%edx
  800a05:	eb 03                	jmp    800a0a <strnlen+0x13>
		n++;
  800a07:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800a0a:	39 c2                	cmp    %eax,%edx
  800a0c:	74 08                	je     800a16 <strnlen+0x1f>
  800a0e:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  800a12:	75 f3                	jne    800a07 <strnlen+0x10>
  800a14:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  800a16:	5d                   	pop    %ebp
  800a17:	c3                   	ret    

00800a18 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800a18:	55                   	push   %ebp
  800a19:	89 e5                	mov    %esp,%ebp
  800a1b:	53                   	push   %ebx
  800a1c:	8b 45 08             	mov    0x8(%ebp),%eax
  800a1f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800a22:	89 c2                	mov    %eax,%edx
  800a24:	83 c2 01             	add    $0x1,%edx
  800a27:	83 c1 01             	add    $0x1,%ecx
  800a2a:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  800a2e:	88 5a ff             	mov    %bl,-0x1(%edx)
  800a31:	84 db                	test   %bl,%bl
  800a33:	75 ef                	jne    800a24 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800a35:	5b                   	pop    %ebx
  800a36:	5d                   	pop    %ebp
  800a37:	c3                   	ret    

00800a38 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800a38:	55                   	push   %ebp
  800a39:	89 e5                	mov    %esp,%ebp
  800a3b:	53                   	push   %ebx
  800a3c:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800a3f:	53                   	push   %ebx
  800a40:	e8 9a ff ff ff       	call   8009df <strlen>
  800a45:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  800a48:	ff 75 0c             	pushl  0xc(%ebp)
  800a4b:	01 d8                	add    %ebx,%eax
  800a4d:	50                   	push   %eax
  800a4e:	e8 c5 ff ff ff       	call   800a18 <strcpy>
	return dst;
}
  800a53:	89 d8                	mov    %ebx,%eax
  800a55:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800a58:	c9                   	leave  
  800a59:	c3                   	ret    

00800a5a <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800a5a:	55                   	push   %ebp
  800a5b:	89 e5                	mov    %esp,%ebp
  800a5d:	56                   	push   %esi
  800a5e:	53                   	push   %ebx
  800a5f:	8b 75 08             	mov    0x8(%ebp),%esi
  800a62:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800a65:	89 f3                	mov    %esi,%ebx
  800a67:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800a6a:	89 f2                	mov    %esi,%edx
  800a6c:	eb 0f                	jmp    800a7d <strncpy+0x23>
		*dst++ = *src;
  800a6e:	83 c2 01             	add    $0x1,%edx
  800a71:	0f b6 01             	movzbl (%ecx),%eax
  800a74:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800a77:	80 39 01             	cmpb   $0x1,(%ecx)
  800a7a:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800a7d:	39 da                	cmp    %ebx,%edx
  800a7f:	75 ed                	jne    800a6e <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800a81:	89 f0                	mov    %esi,%eax
  800a83:	5b                   	pop    %ebx
  800a84:	5e                   	pop    %esi
  800a85:	5d                   	pop    %ebp
  800a86:	c3                   	ret    

00800a87 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800a87:	55                   	push   %ebp
  800a88:	89 e5                	mov    %esp,%ebp
  800a8a:	56                   	push   %esi
  800a8b:	53                   	push   %ebx
  800a8c:	8b 75 08             	mov    0x8(%ebp),%esi
  800a8f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800a92:	8b 55 10             	mov    0x10(%ebp),%edx
  800a95:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800a97:	85 d2                	test   %edx,%edx
  800a99:	74 21                	je     800abc <strlcpy+0x35>
  800a9b:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  800a9f:	89 f2                	mov    %esi,%edx
  800aa1:	eb 09                	jmp    800aac <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800aa3:	83 c2 01             	add    $0x1,%edx
  800aa6:	83 c1 01             	add    $0x1,%ecx
  800aa9:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800aac:	39 c2                	cmp    %eax,%edx
  800aae:	74 09                	je     800ab9 <strlcpy+0x32>
  800ab0:	0f b6 19             	movzbl (%ecx),%ebx
  800ab3:	84 db                	test   %bl,%bl
  800ab5:	75 ec                	jne    800aa3 <strlcpy+0x1c>
  800ab7:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  800ab9:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800abc:	29 f0                	sub    %esi,%eax
}
  800abe:	5b                   	pop    %ebx
  800abf:	5e                   	pop    %esi
  800ac0:	5d                   	pop    %ebp
  800ac1:	c3                   	ret    

00800ac2 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800ac2:	55                   	push   %ebp
  800ac3:	89 e5                	mov    %esp,%ebp
  800ac5:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800ac8:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800acb:	eb 06                	jmp    800ad3 <strcmp+0x11>
		p++, q++;
  800acd:	83 c1 01             	add    $0x1,%ecx
  800ad0:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800ad3:	0f b6 01             	movzbl (%ecx),%eax
  800ad6:	84 c0                	test   %al,%al
  800ad8:	74 04                	je     800ade <strcmp+0x1c>
  800ada:	3a 02                	cmp    (%edx),%al
  800adc:	74 ef                	je     800acd <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800ade:	0f b6 c0             	movzbl %al,%eax
  800ae1:	0f b6 12             	movzbl (%edx),%edx
  800ae4:	29 d0                	sub    %edx,%eax
}
  800ae6:	5d                   	pop    %ebp
  800ae7:	c3                   	ret    

00800ae8 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800ae8:	55                   	push   %ebp
  800ae9:	89 e5                	mov    %esp,%ebp
  800aeb:	53                   	push   %ebx
  800aec:	8b 45 08             	mov    0x8(%ebp),%eax
  800aef:	8b 55 0c             	mov    0xc(%ebp),%edx
  800af2:	89 c3                	mov    %eax,%ebx
  800af4:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800af7:	eb 06                	jmp    800aff <strncmp+0x17>
		n--, p++, q++;
  800af9:	83 c0 01             	add    $0x1,%eax
  800afc:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800aff:	39 d8                	cmp    %ebx,%eax
  800b01:	74 15                	je     800b18 <strncmp+0x30>
  800b03:	0f b6 08             	movzbl (%eax),%ecx
  800b06:	84 c9                	test   %cl,%cl
  800b08:	74 04                	je     800b0e <strncmp+0x26>
  800b0a:	3a 0a                	cmp    (%edx),%cl
  800b0c:	74 eb                	je     800af9 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800b0e:	0f b6 00             	movzbl (%eax),%eax
  800b11:	0f b6 12             	movzbl (%edx),%edx
  800b14:	29 d0                	sub    %edx,%eax
  800b16:	eb 05                	jmp    800b1d <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800b18:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800b1d:	5b                   	pop    %ebx
  800b1e:	5d                   	pop    %ebp
  800b1f:	c3                   	ret    

00800b20 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800b20:	55                   	push   %ebp
  800b21:	89 e5                	mov    %esp,%ebp
  800b23:	8b 45 08             	mov    0x8(%ebp),%eax
  800b26:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800b2a:	eb 07                	jmp    800b33 <strchr+0x13>
		if (*s == c)
  800b2c:	38 ca                	cmp    %cl,%dl
  800b2e:	74 0f                	je     800b3f <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800b30:	83 c0 01             	add    $0x1,%eax
  800b33:	0f b6 10             	movzbl (%eax),%edx
  800b36:	84 d2                	test   %dl,%dl
  800b38:	75 f2                	jne    800b2c <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800b3a:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800b3f:	5d                   	pop    %ebp
  800b40:	c3                   	ret    

00800b41 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800b41:	55                   	push   %ebp
  800b42:	89 e5                	mov    %esp,%ebp
  800b44:	8b 45 08             	mov    0x8(%ebp),%eax
  800b47:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800b4b:	eb 03                	jmp    800b50 <strfind+0xf>
  800b4d:	83 c0 01             	add    $0x1,%eax
  800b50:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  800b53:	38 ca                	cmp    %cl,%dl
  800b55:	74 04                	je     800b5b <strfind+0x1a>
  800b57:	84 d2                	test   %dl,%dl
  800b59:	75 f2                	jne    800b4d <strfind+0xc>
			break;
	return (char *) s;
}
  800b5b:	5d                   	pop    %ebp
  800b5c:	c3                   	ret    

00800b5d <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800b5d:	55                   	push   %ebp
  800b5e:	89 e5                	mov    %esp,%ebp
  800b60:	57                   	push   %edi
  800b61:	56                   	push   %esi
  800b62:	53                   	push   %ebx
  800b63:	8b 7d 08             	mov    0x8(%ebp),%edi
  800b66:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800b69:	85 c9                	test   %ecx,%ecx
  800b6b:	74 36                	je     800ba3 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800b6d:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800b73:	75 28                	jne    800b9d <memset+0x40>
  800b75:	f6 c1 03             	test   $0x3,%cl
  800b78:	75 23                	jne    800b9d <memset+0x40>
		c &= 0xFF;
  800b7a:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800b7e:	89 d3                	mov    %edx,%ebx
  800b80:	c1 e3 08             	shl    $0x8,%ebx
  800b83:	89 d6                	mov    %edx,%esi
  800b85:	c1 e6 18             	shl    $0x18,%esi
  800b88:	89 d0                	mov    %edx,%eax
  800b8a:	c1 e0 10             	shl    $0x10,%eax
  800b8d:	09 f0                	or     %esi,%eax
  800b8f:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  800b91:	89 d8                	mov    %ebx,%eax
  800b93:	09 d0                	or     %edx,%eax
  800b95:	c1 e9 02             	shr    $0x2,%ecx
  800b98:	fc                   	cld    
  800b99:	f3 ab                	rep stos %eax,%es:(%edi)
  800b9b:	eb 06                	jmp    800ba3 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800b9d:	8b 45 0c             	mov    0xc(%ebp),%eax
  800ba0:	fc                   	cld    
  800ba1:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800ba3:	89 f8                	mov    %edi,%eax
  800ba5:	5b                   	pop    %ebx
  800ba6:	5e                   	pop    %esi
  800ba7:	5f                   	pop    %edi
  800ba8:	5d                   	pop    %ebp
  800ba9:	c3                   	ret    

00800baa <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800baa:	55                   	push   %ebp
  800bab:	89 e5                	mov    %esp,%ebp
  800bad:	57                   	push   %edi
  800bae:	56                   	push   %esi
  800baf:	8b 45 08             	mov    0x8(%ebp),%eax
  800bb2:	8b 75 0c             	mov    0xc(%ebp),%esi
  800bb5:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800bb8:	39 c6                	cmp    %eax,%esi
  800bba:	73 35                	jae    800bf1 <memmove+0x47>
  800bbc:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800bbf:	39 d0                	cmp    %edx,%eax
  800bc1:	73 2e                	jae    800bf1 <memmove+0x47>
		s += n;
		d += n;
  800bc3:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800bc6:	89 d6                	mov    %edx,%esi
  800bc8:	09 fe                	or     %edi,%esi
  800bca:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800bd0:	75 13                	jne    800be5 <memmove+0x3b>
  800bd2:	f6 c1 03             	test   $0x3,%cl
  800bd5:	75 0e                	jne    800be5 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  800bd7:	83 ef 04             	sub    $0x4,%edi
  800bda:	8d 72 fc             	lea    -0x4(%edx),%esi
  800bdd:	c1 e9 02             	shr    $0x2,%ecx
  800be0:	fd                   	std    
  800be1:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800be3:	eb 09                	jmp    800bee <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800be5:	83 ef 01             	sub    $0x1,%edi
  800be8:	8d 72 ff             	lea    -0x1(%edx),%esi
  800beb:	fd                   	std    
  800bec:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800bee:	fc                   	cld    
  800bef:	eb 1d                	jmp    800c0e <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800bf1:	89 f2                	mov    %esi,%edx
  800bf3:	09 c2                	or     %eax,%edx
  800bf5:	f6 c2 03             	test   $0x3,%dl
  800bf8:	75 0f                	jne    800c09 <memmove+0x5f>
  800bfa:	f6 c1 03             	test   $0x3,%cl
  800bfd:	75 0a                	jne    800c09 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800bff:	c1 e9 02             	shr    $0x2,%ecx
  800c02:	89 c7                	mov    %eax,%edi
  800c04:	fc                   	cld    
  800c05:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800c07:	eb 05                	jmp    800c0e <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800c09:	89 c7                	mov    %eax,%edi
  800c0b:	fc                   	cld    
  800c0c:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800c0e:	5e                   	pop    %esi
  800c0f:	5f                   	pop    %edi
  800c10:	5d                   	pop    %ebp
  800c11:	c3                   	ret    

00800c12 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800c12:	55                   	push   %ebp
  800c13:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  800c15:	ff 75 10             	pushl  0x10(%ebp)
  800c18:	ff 75 0c             	pushl  0xc(%ebp)
  800c1b:	ff 75 08             	pushl  0x8(%ebp)
  800c1e:	e8 87 ff ff ff       	call   800baa <memmove>
}
  800c23:	c9                   	leave  
  800c24:	c3                   	ret    

00800c25 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800c25:	55                   	push   %ebp
  800c26:	89 e5                	mov    %esp,%ebp
  800c28:	56                   	push   %esi
  800c29:	53                   	push   %ebx
  800c2a:	8b 45 08             	mov    0x8(%ebp),%eax
  800c2d:	8b 55 0c             	mov    0xc(%ebp),%edx
  800c30:	89 c6                	mov    %eax,%esi
  800c32:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800c35:	eb 1a                	jmp    800c51 <memcmp+0x2c>
		if (*s1 != *s2)
  800c37:	0f b6 08             	movzbl (%eax),%ecx
  800c3a:	0f b6 1a             	movzbl (%edx),%ebx
  800c3d:	38 d9                	cmp    %bl,%cl
  800c3f:	74 0a                	je     800c4b <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800c41:	0f b6 c1             	movzbl %cl,%eax
  800c44:	0f b6 db             	movzbl %bl,%ebx
  800c47:	29 d8                	sub    %ebx,%eax
  800c49:	eb 0f                	jmp    800c5a <memcmp+0x35>
		s1++, s2++;
  800c4b:	83 c0 01             	add    $0x1,%eax
  800c4e:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800c51:	39 f0                	cmp    %esi,%eax
  800c53:	75 e2                	jne    800c37 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800c55:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800c5a:	5b                   	pop    %ebx
  800c5b:	5e                   	pop    %esi
  800c5c:	5d                   	pop    %ebp
  800c5d:	c3                   	ret    

00800c5e <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800c5e:	55                   	push   %ebp
  800c5f:	89 e5                	mov    %esp,%ebp
  800c61:	53                   	push   %ebx
  800c62:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  800c65:	89 c1                	mov    %eax,%ecx
  800c67:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  800c6a:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800c6e:	eb 0a                	jmp    800c7a <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  800c70:	0f b6 10             	movzbl (%eax),%edx
  800c73:	39 da                	cmp    %ebx,%edx
  800c75:	74 07                	je     800c7e <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800c77:	83 c0 01             	add    $0x1,%eax
  800c7a:	39 c8                	cmp    %ecx,%eax
  800c7c:	72 f2                	jb     800c70 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800c7e:	5b                   	pop    %ebx
  800c7f:	5d                   	pop    %ebp
  800c80:	c3                   	ret    

00800c81 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800c81:	55                   	push   %ebp
  800c82:	89 e5                	mov    %esp,%ebp
  800c84:	57                   	push   %edi
  800c85:	56                   	push   %esi
  800c86:	53                   	push   %ebx
  800c87:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800c8a:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800c8d:	eb 03                	jmp    800c92 <strtol+0x11>
		s++;
  800c8f:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800c92:	0f b6 01             	movzbl (%ecx),%eax
  800c95:	3c 20                	cmp    $0x20,%al
  800c97:	74 f6                	je     800c8f <strtol+0xe>
  800c99:	3c 09                	cmp    $0x9,%al
  800c9b:	74 f2                	je     800c8f <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800c9d:	3c 2b                	cmp    $0x2b,%al
  800c9f:	75 0a                	jne    800cab <strtol+0x2a>
		s++;
  800ca1:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800ca4:	bf 00 00 00 00       	mov    $0x0,%edi
  800ca9:	eb 11                	jmp    800cbc <strtol+0x3b>
  800cab:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800cb0:	3c 2d                	cmp    $0x2d,%al
  800cb2:	75 08                	jne    800cbc <strtol+0x3b>
		s++, neg = 1;
  800cb4:	83 c1 01             	add    $0x1,%ecx
  800cb7:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800cbc:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800cc2:	75 15                	jne    800cd9 <strtol+0x58>
  800cc4:	80 39 30             	cmpb   $0x30,(%ecx)
  800cc7:	75 10                	jne    800cd9 <strtol+0x58>
  800cc9:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800ccd:	75 7c                	jne    800d4b <strtol+0xca>
		s += 2, base = 16;
  800ccf:	83 c1 02             	add    $0x2,%ecx
  800cd2:	bb 10 00 00 00       	mov    $0x10,%ebx
  800cd7:	eb 16                	jmp    800cef <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800cd9:	85 db                	test   %ebx,%ebx
  800cdb:	75 12                	jne    800cef <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800cdd:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800ce2:	80 39 30             	cmpb   $0x30,(%ecx)
  800ce5:	75 08                	jne    800cef <strtol+0x6e>
		s++, base = 8;
  800ce7:	83 c1 01             	add    $0x1,%ecx
  800cea:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800cef:	b8 00 00 00 00       	mov    $0x0,%eax
  800cf4:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800cf7:	0f b6 11             	movzbl (%ecx),%edx
  800cfa:	8d 72 d0             	lea    -0x30(%edx),%esi
  800cfd:	89 f3                	mov    %esi,%ebx
  800cff:	80 fb 09             	cmp    $0x9,%bl
  800d02:	77 08                	ja     800d0c <strtol+0x8b>
			dig = *s - '0';
  800d04:	0f be d2             	movsbl %dl,%edx
  800d07:	83 ea 30             	sub    $0x30,%edx
  800d0a:	eb 22                	jmp    800d2e <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800d0c:	8d 72 9f             	lea    -0x61(%edx),%esi
  800d0f:	89 f3                	mov    %esi,%ebx
  800d11:	80 fb 19             	cmp    $0x19,%bl
  800d14:	77 08                	ja     800d1e <strtol+0x9d>
			dig = *s - 'a' + 10;
  800d16:	0f be d2             	movsbl %dl,%edx
  800d19:	83 ea 57             	sub    $0x57,%edx
  800d1c:	eb 10                	jmp    800d2e <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800d1e:	8d 72 bf             	lea    -0x41(%edx),%esi
  800d21:	89 f3                	mov    %esi,%ebx
  800d23:	80 fb 19             	cmp    $0x19,%bl
  800d26:	77 16                	ja     800d3e <strtol+0xbd>
			dig = *s - 'A' + 10;
  800d28:	0f be d2             	movsbl %dl,%edx
  800d2b:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800d2e:	3b 55 10             	cmp    0x10(%ebp),%edx
  800d31:	7d 0b                	jge    800d3e <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800d33:	83 c1 01             	add    $0x1,%ecx
  800d36:	0f af 45 10          	imul   0x10(%ebp),%eax
  800d3a:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800d3c:	eb b9                	jmp    800cf7 <strtol+0x76>

	if (endptr)
  800d3e:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800d42:	74 0d                	je     800d51 <strtol+0xd0>
		*endptr = (char *) s;
  800d44:	8b 75 0c             	mov    0xc(%ebp),%esi
  800d47:	89 0e                	mov    %ecx,(%esi)
  800d49:	eb 06                	jmp    800d51 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800d4b:	85 db                	test   %ebx,%ebx
  800d4d:	74 98                	je     800ce7 <strtol+0x66>
  800d4f:	eb 9e                	jmp    800cef <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800d51:	89 c2                	mov    %eax,%edx
  800d53:	f7 da                	neg    %edx
  800d55:	85 ff                	test   %edi,%edi
  800d57:	0f 45 c2             	cmovne %edx,%eax
}
  800d5a:	5b                   	pop    %ebx
  800d5b:	5e                   	pop    %esi
  800d5c:	5f                   	pop    %edi
  800d5d:	5d                   	pop    %ebp
  800d5e:	c3                   	ret    

00800d5f <set_pgfault_handler>:
// at UXSTACKTOP), and tell the kernel to call the assembly-language
// _pgfault_upcall routine when a page fault occurs.
//
void
set_pgfault_handler(void (*handler)(struct UTrapframe *utf))
{
  800d5f:	55                   	push   %ebp
  800d60:	89 e5                	mov    %esp,%ebp
  800d62:	83 ec 08             	sub    $0x8,%esp
	int r;

	if (_pgfault_handler == 0) {
  800d65:	83 3d 08 20 80 00 00 	cmpl   $0x0,0x802008
  800d6c:	75 56                	jne    800dc4 <set_pgfault_handler+0x65>
		// First time through!
		// LAB 4: Your code here.
		r = sys_page_alloc(0, (void*)UXSTACKTOP-PGSIZE, PTE_U|PTE_W|PTE_P);
  800d6e:	83 ec 04             	sub    $0x4,%esp
  800d71:	6a 07                	push   $0x7
  800d73:	68 00 f0 bf ee       	push   $0xeebff000
  800d78:	6a 00                	push   $0x0
  800d7a:	e8 e9 f3 ff ff       	call   800168 <sys_page_alloc>
		//cprintf("%x", r);
		if(r != 0)
  800d7f:	83 c4 10             	add    $0x10,%esp
  800d82:	85 c0                	test   %eax,%eax
  800d84:	74 14                	je     800d9a <set_pgfault_handler+0x3b>
		{
			panic("sys_page_alloc failed");
  800d86:	83 ec 04             	sub    $0x4,%esp
  800d89:	68 08 13 80 00       	push   $0x801308
  800d8e:	6a 24                	push   $0x24
  800d90:	68 1e 13 80 00       	push   $0x80131e
  800d95:	e8 a1 f5 ff ff       	call   80033b <_panic>
		}
		r = sys_env_set_pgfault_upcall(0, (void*)_pgfault_upcall); 
  800d9a:	83 ec 08             	sub    $0x8,%esp
  800d9d:	68 17 03 80 00       	push   $0x800317
  800da2:	6a 00                	push   $0x0
  800da4:	e8 c8 f4 ff ff       	call   800271 <sys_env_set_pgfault_upcall>
		//cprintf("%x\n", _pgfault_upcall);//fixed bug:_pgfault_upcall-->_pgfault_handler
		if(r != 0)
  800da9:	83 c4 10             	add    $0x10,%esp
  800dac:	85 c0                	test   %eax,%eax
  800dae:	74 14                	je     800dc4 <set_pgfault_handler+0x65>
		{
			panic("sys_env_set_pgfault_upcall failed");
  800db0:	83 ec 04             	sub    $0x4,%esp
  800db3:	68 2c 13 80 00       	push   $0x80132c
  800db8:	6a 2a                	push   $0x2a
  800dba:	68 1e 13 80 00       	push   $0x80131e
  800dbf:	e8 77 f5 ff ff       	call   80033b <_panic>
		}
		//panic("set_pgfault_handler not implemented");
	}

	// Save handler pointer for assembly to call.
	_pgfault_handler = handler;
  800dc4:	8b 45 08             	mov    0x8(%ebp),%eax
  800dc7:	a3 08 20 80 00       	mov    %eax,0x802008
}
  800dcc:	c9                   	leave  
  800dcd:	c3                   	ret    
  800dce:	66 90                	xchg   %ax,%ax

00800dd0 <__udivdi3>:
  800dd0:	55                   	push   %ebp
  800dd1:	57                   	push   %edi
  800dd2:	56                   	push   %esi
  800dd3:	53                   	push   %ebx
  800dd4:	83 ec 1c             	sub    $0x1c,%esp
  800dd7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  800ddb:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  800ddf:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  800de3:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800de7:	85 f6                	test   %esi,%esi
  800de9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800ded:	89 ca                	mov    %ecx,%edx
  800def:	89 f8                	mov    %edi,%eax
  800df1:	75 3d                	jne    800e30 <__udivdi3+0x60>
  800df3:	39 cf                	cmp    %ecx,%edi
  800df5:	0f 87 c5 00 00 00    	ja     800ec0 <__udivdi3+0xf0>
  800dfb:	85 ff                	test   %edi,%edi
  800dfd:	89 fd                	mov    %edi,%ebp
  800dff:	75 0b                	jne    800e0c <__udivdi3+0x3c>
  800e01:	b8 01 00 00 00       	mov    $0x1,%eax
  800e06:	31 d2                	xor    %edx,%edx
  800e08:	f7 f7                	div    %edi
  800e0a:	89 c5                	mov    %eax,%ebp
  800e0c:	89 c8                	mov    %ecx,%eax
  800e0e:	31 d2                	xor    %edx,%edx
  800e10:	f7 f5                	div    %ebp
  800e12:	89 c1                	mov    %eax,%ecx
  800e14:	89 d8                	mov    %ebx,%eax
  800e16:	89 cf                	mov    %ecx,%edi
  800e18:	f7 f5                	div    %ebp
  800e1a:	89 c3                	mov    %eax,%ebx
  800e1c:	89 d8                	mov    %ebx,%eax
  800e1e:	89 fa                	mov    %edi,%edx
  800e20:	83 c4 1c             	add    $0x1c,%esp
  800e23:	5b                   	pop    %ebx
  800e24:	5e                   	pop    %esi
  800e25:	5f                   	pop    %edi
  800e26:	5d                   	pop    %ebp
  800e27:	c3                   	ret    
  800e28:	90                   	nop
  800e29:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800e30:	39 ce                	cmp    %ecx,%esi
  800e32:	77 74                	ja     800ea8 <__udivdi3+0xd8>
  800e34:	0f bd fe             	bsr    %esi,%edi
  800e37:	83 f7 1f             	xor    $0x1f,%edi
  800e3a:	0f 84 98 00 00 00    	je     800ed8 <__udivdi3+0x108>
  800e40:	bb 20 00 00 00       	mov    $0x20,%ebx
  800e45:	89 f9                	mov    %edi,%ecx
  800e47:	89 c5                	mov    %eax,%ebp
  800e49:	29 fb                	sub    %edi,%ebx
  800e4b:	d3 e6                	shl    %cl,%esi
  800e4d:	89 d9                	mov    %ebx,%ecx
  800e4f:	d3 ed                	shr    %cl,%ebp
  800e51:	89 f9                	mov    %edi,%ecx
  800e53:	d3 e0                	shl    %cl,%eax
  800e55:	09 ee                	or     %ebp,%esi
  800e57:	89 d9                	mov    %ebx,%ecx
  800e59:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800e5d:	89 d5                	mov    %edx,%ebp
  800e5f:	8b 44 24 08          	mov    0x8(%esp),%eax
  800e63:	d3 ed                	shr    %cl,%ebp
  800e65:	89 f9                	mov    %edi,%ecx
  800e67:	d3 e2                	shl    %cl,%edx
  800e69:	89 d9                	mov    %ebx,%ecx
  800e6b:	d3 e8                	shr    %cl,%eax
  800e6d:	09 c2                	or     %eax,%edx
  800e6f:	89 d0                	mov    %edx,%eax
  800e71:	89 ea                	mov    %ebp,%edx
  800e73:	f7 f6                	div    %esi
  800e75:	89 d5                	mov    %edx,%ebp
  800e77:	89 c3                	mov    %eax,%ebx
  800e79:	f7 64 24 0c          	mull   0xc(%esp)
  800e7d:	39 d5                	cmp    %edx,%ebp
  800e7f:	72 10                	jb     800e91 <__udivdi3+0xc1>
  800e81:	8b 74 24 08          	mov    0x8(%esp),%esi
  800e85:	89 f9                	mov    %edi,%ecx
  800e87:	d3 e6                	shl    %cl,%esi
  800e89:	39 c6                	cmp    %eax,%esi
  800e8b:	73 07                	jae    800e94 <__udivdi3+0xc4>
  800e8d:	39 d5                	cmp    %edx,%ebp
  800e8f:	75 03                	jne    800e94 <__udivdi3+0xc4>
  800e91:	83 eb 01             	sub    $0x1,%ebx
  800e94:	31 ff                	xor    %edi,%edi
  800e96:	89 d8                	mov    %ebx,%eax
  800e98:	89 fa                	mov    %edi,%edx
  800e9a:	83 c4 1c             	add    $0x1c,%esp
  800e9d:	5b                   	pop    %ebx
  800e9e:	5e                   	pop    %esi
  800e9f:	5f                   	pop    %edi
  800ea0:	5d                   	pop    %ebp
  800ea1:	c3                   	ret    
  800ea2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800ea8:	31 ff                	xor    %edi,%edi
  800eaa:	31 db                	xor    %ebx,%ebx
  800eac:	89 d8                	mov    %ebx,%eax
  800eae:	89 fa                	mov    %edi,%edx
  800eb0:	83 c4 1c             	add    $0x1c,%esp
  800eb3:	5b                   	pop    %ebx
  800eb4:	5e                   	pop    %esi
  800eb5:	5f                   	pop    %edi
  800eb6:	5d                   	pop    %ebp
  800eb7:	c3                   	ret    
  800eb8:	90                   	nop
  800eb9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800ec0:	89 d8                	mov    %ebx,%eax
  800ec2:	f7 f7                	div    %edi
  800ec4:	31 ff                	xor    %edi,%edi
  800ec6:	89 c3                	mov    %eax,%ebx
  800ec8:	89 d8                	mov    %ebx,%eax
  800eca:	89 fa                	mov    %edi,%edx
  800ecc:	83 c4 1c             	add    $0x1c,%esp
  800ecf:	5b                   	pop    %ebx
  800ed0:	5e                   	pop    %esi
  800ed1:	5f                   	pop    %edi
  800ed2:	5d                   	pop    %ebp
  800ed3:	c3                   	ret    
  800ed4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800ed8:	39 ce                	cmp    %ecx,%esi
  800eda:	72 0c                	jb     800ee8 <__udivdi3+0x118>
  800edc:	31 db                	xor    %ebx,%ebx
  800ede:	3b 44 24 08          	cmp    0x8(%esp),%eax
  800ee2:	0f 87 34 ff ff ff    	ja     800e1c <__udivdi3+0x4c>
  800ee8:	bb 01 00 00 00       	mov    $0x1,%ebx
  800eed:	e9 2a ff ff ff       	jmp    800e1c <__udivdi3+0x4c>
  800ef2:	66 90                	xchg   %ax,%ax
  800ef4:	66 90                	xchg   %ax,%ax
  800ef6:	66 90                	xchg   %ax,%ax
  800ef8:	66 90                	xchg   %ax,%ax
  800efa:	66 90                	xchg   %ax,%ax
  800efc:	66 90                	xchg   %ax,%ax
  800efe:	66 90                	xchg   %ax,%ax

00800f00 <__umoddi3>:
  800f00:	55                   	push   %ebp
  800f01:	57                   	push   %edi
  800f02:	56                   	push   %esi
  800f03:	53                   	push   %ebx
  800f04:	83 ec 1c             	sub    $0x1c,%esp
  800f07:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  800f0b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  800f0f:	8b 74 24 34          	mov    0x34(%esp),%esi
  800f13:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800f17:	85 d2                	test   %edx,%edx
  800f19:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800f1d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800f21:	89 f3                	mov    %esi,%ebx
  800f23:	89 3c 24             	mov    %edi,(%esp)
  800f26:	89 74 24 04          	mov    %esi,0x4(%esp)
  800f2a:	75 1c                	jne    800f48 <__umoddi3+0x48>
  800f2c:	39 f7                	cmp    %esi,%edi
  800f2e:	76 50                	jbe    800f80 <__umoddi3+0x80>
  800f30:	89 c8                	mov    %ecx,%eax
  800f32:	89 f2                	mov    %esi,%edx
  800f34:	f7 f7                	div    %edi
  800f36:	89 d0                	mov    %edx,%eax
  800f38:	31 d2                	xor    %edx,%edx
  800f3a:	83 c4 1c             	add    $0x1c,%esp
  800f3d:	5b                   	pop    %ebx
  800f3e:	5e                   	pop    %esi
  800f3f:	5f                   	pop    %edi
  800f40:	5d                   	pop    %ebp
  800f41:	c3                   	ret    
  800f42:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800f48:	39 f2                	cmp    %esi,%edx
  800f4a:	89 d0                	mov    %edx,%eax
  800f4c:	77 52                	ja     800fa0 <__umoddi3+0xa0>
  800f4e:	0f bd ea             	bsr    %edx,%ebp
  800f51:	83 f5 1f             	xor    $0x1f,%ebp
  800f54:	75 5a                	jne    800fb0 <__umoddi3+0xb0>
  800f56:	3b 54 24 04          	cmp    0x4(%esp),%edx
  800f5a:	0f 82 e0 00 00 00    	jb     801040 <__umoddi3+0x140>
  800f60:	39 0c 24             	cmp    %ecx,(%esp)
  800f63:	0f 86 d7 00 00 00    	jbe    801040 <__umoddi3+0x140>
  800f69:	8b 44 24 08          	mov    0x8(%esp),%eax
  800f6d:	8b 54 24 04          	mov    0x4(%esp),%edx
  800f71:	83 c4 1c             	add    $0x1c,%esp
  800f74:	5b                   	pop    %ebx
  800f75:	5e                   	pop    %esi
  800f76:	5f                   	pop    %edi
  800f77:	5d                   	pop    %ebp
  800f78:	c3                   	ret    
  800f79:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800f80:	85 ff                	test   %edi,%edi
  800f82:	89 fd                	mov    %edi,%ebp
  800f84:	75 0b                	jne    800f91 <__umoddi3+0x91>
  800f86:	b8 01 00 00 00       	mov    $0x1,%eax
  800f8b:	31 d2                	xor    %edx,%edx
  800f8d:	f7 f7                	div    %edi
  800f8f:	89 c5                	mov    %eax,%ebp
  800f91:	89 f0                	mov    %esi,%eax
  800f93:	31 d2                	xor    %edx,%edx
  800f95:	f7 f5                	div    %ebp
  800f97:	89 c8                	mov    %ecx,%eax
  800f99:	f7 f5                	div    %ebp
  800f9b:	89 d0                	mov    %edx,%eax
  800f9d:	eb 99                	jmp    800f38 <__umoddi3+0x38>
  800f9f:	90                   	nop
  800fa0:	89 c8                	mov    %ecx,%eax
  800fa2:	89 f2                	mov    %esi,%edx
  800fa4:	83 c4 1c             	add    $0x1c,%esp
  800fa7:	5b                   	pop    %ebx
  800fa8:	5e                   	pop    %esi
  800fa9:	5f                   	pop    %edi
  800faa:	5d                   	pop    %ebp
  800fab:	c3                   	ret    
  800fac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800fb0:	8b 34 24             	mov    (%esp),%esi
  800fb3:	bf 20 00 00 00       	mov    $0x20,%edi
  800fb8:	89 e9                	mov    %ebp,%ecx
  800fba:	29 ef                	sub    %ebp,%edi
  800fbc:	d3 e0                	shl    %cl,%eax
  800fbe:	89 f9                	mov    %edi,%ecx
  800fc0:	89 f2                	mov    %esi,%edx
  800fc2:	d3 ea                	shr    %cl,%edx
  800fc4:	89 e9                	mov    %ebp,%ecx
  800fc6:	09 c2                	or     %eax,%edx
  800fc8:	89 d8                	mov    %ebx,%eax
  800fca:	89 14 24             	mov    %edx,(%esp)
  800fcd:	89 f2                	mov    %esi,%edx
  800fcf:	d3 e2                	shl    %cl,%edx
  800fd1:	89 f9                	mov    %edi,%ecx
  800fd3:	89 54 24 04          	mov    %edx,0x4(%esp)
  800fd7:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800fdb:	d3 e8                	shr    %cl,%eax
  800fdd:	89 e9                	mov    %ebp,%ecx
  800fdf:	89 c6                	mov    %eax,%esi
  800fe1:	d3 e3                	shl    %cl,%ebx
  800fe3:	89 f9                	mov    %edi,%ecx
  800fe5:	89 d0                	mov    %edx,%eax
  800fe7:	d3 e8                	shr    %cl,%eax
  800fe9:	89 e9                	mov    %ebp,%ecx
  800feb:	09 d8                	or     %ebx,%eax
  800fed:	89 d3                	mov    %edx,%ebx
  800fef:	89 f2                	mov    %esi,%edx
  800ff1:	f7 34 24             	divl   (%esp)
  800ff4:	89 d6                	mov    %edx,%esi
  800ff6:	d3 e3                	shl    %cl,%ebx
  800ff8:	f7 64 24 04          	mull   0x4(%esp)
  800ffc:	39 d6                	cmp    %edx,%esi
  800ffe:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  801002:	89 d1                	mov    %edx,%ecx
  801004:	89 c3                	mov    %eax,%ebx
  801006:	72 08                	jb     801010 <__umoddi3+0x110>
  801008:	75 11                	jne    80101b <__umoddi3+0x11b>
  80100a:	39 44 24 08          	cmp    %eax,0x8(%esp)
  80100e:	73 0b                	jae    80101b <__umoddi3+0x11b>
  801010:	2b 44 24 04          	sub    0x4(%esp),%eax
  801014:	1b 14 24             	sbb    (%esp),%edx
  801017:	89 d1                	mov    %edx,%ecx
  801019:	89 c3                	mov    %eax,%ebx
  80101b:	8b 54 24 08          	mov    0x8(%esp),%edx
  80101f:	29 da                	sub    %ebx,%edx
  801021:	19 ce                	sbb    %ecx,%esi
  801023:	89 f9                	mov    %edi,%ecx
  801025:	89 f0                	mov    %esi,%eax
  801027:	d3 e0                	shl    %cl,%eax
  801029:	89 e9                	mov    %ebp,%ecx
  80102b:	d3 ea                	shr    %cl,%edx
  80102d:	89 e9                	mov    %ebp,%ecx
  80102f:	d3 ee                	shr    %cl,%esi
  801031:	09 d0                	or     %edx,%eax
  801033:	89 f2                	mov    %esi,%edx
  801035:	83 c4 1c             	add    $0x1c,%esp
  801038:	5b                   	pop    %ebx
  801039:	5e                   	pop    %esi
  80103a:	5f                   	pop    %edi
  80103b:	5d                   	pop    %ebp
  80103c:	c3                   	ret    
  80103d:	8d 76 00             	lea    0x0(%esi),%esi
  801040:	29 f9                	sub    %edi,%ecx
  801042:	19 d6                	sbb    %edx,%esi
  801044:	89 74 24 04          	mov    %esi,0x4(%esp)
  801048:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  80104c:	e9 18 ff ff ff       	jmp    800f69 <__umoddi3+0x69>
