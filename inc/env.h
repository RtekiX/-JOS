/* See COPYRIGHT for copyright information. */
//用户模式进程的公用定义
#ifndef JOS_INC_ENV_H
#define JOS_INC_ENV_H

#include <inc/types.h>
#include <inc/trap.h>
#include <inc/memlayout.h>

typedef int32_t envid_t;

// An environment ID 'envid_t' has three parts:
// 所有的environment ID都大于0，因此符号位为0
// +1+---------------21-----------------+--------10--------+
// |0|          Uniqueifier             |   Environment    |
// | |        //唯一区分符号            |      Index       |
// +------------------------------------+------------------+
//                                       \--- ENVX(eid) --/在envs[]数组中的偏移量
//
// The environment index ENVX(eid) equals the environment's offset in the
// 'envs[]' array.  The uniqueifier distinguishes environments that were
// created at different times, but share the same environment index.
//
// All real environments are greater than 0 (so the sign bit is zero).
// envid_ts less than 0 signify errors.  The envid_t == 0 is special, and
// stands for the current environment.

#define LOG2NENV		10 //
#define NENV			(1 << LOG2NENV)
#define ENVX(envid)		((envid) & (NENV - 1))//取得envid_t的低10位，即index值

// Values of env_status in struct Env
enum { //在进程结构体中进程状态的可取值
	ENV_FREE = 0, //进程空闲
	ENV_DYING, //进程死亡
	ENV_RUNNABLE, //目前已经激活的进程，但是还没有准备好运行
	ENV_RUNNING,  //进程正在运行
	ENV_NOT_RUNNABLE //进程未在运行
};

// Special environment types
enum EnvType {
	ENV_TYPE_USER = 0,
};

struct Env { //进程的结构体
//Trapframe定义于/inc/trap.h，存储当进程没有在运行时被保存下来的寄存器的值
//比如内核切换模式的时候，就将上一个寄存器的值保存在此以便以后恢复进程的运行
	struct Trapframe env_tf;	// Saved registers 保存寄存器
	struct Env *env_link;		// Next free Env 连接下一个空闲的进程
	envid_t env_id;			// Unique environment identifier 进程的id
	envid_t env_parent_id;		// env_id of this env's parent 进程的父进程id，如果没有父进程则为0
	enum EnvType env_type;		// Indicates special system environments 标注用户进程和系统进程
	unsigned env_status;		// Status of the environment 进程状态
	uint32_t env_runs;		// Number of times environment has run 进程运行的次数

	// Address space
	pde_t *env_pgdir;		// Kernel virtual address of page dir内核页目录的虚拟地址
};

#endif // !JOS_INC_ENV_H
