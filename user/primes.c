// Concurrent version of prime sieve of Eratosthenes.
// Invented by Doug McIlroy, inventor of Unix pipes.
// See http://swtch.com/~rsc/thread/.
// The picture halfway down the page and the text surrounding it
// explain what's going on here.
//
// Since NENVS is 1024, we can print 1022 primes before running out.
// The remaining two environments are the integer generator at the bottom
// of main and user/idle.

#include <inc/lib.h>

/*bool isprime(int n)
{
	for(int i=2;i<n;i++)
	{
		if(n%i==0)
			return false;
	}
	return true;
}*/

unsigned
primeproc(void)
{
	int i, id, p;
	envid_t *envid=NULL;

	// fetch a prime from our left neighbor
top:
	p = ipc_recv(envid, 0, 0);
	//cprintf("before recv,,,p:%d\n\n",p);
	cprintf("CPU %d: %d ", thisenv->env_cpunum, p);

	// fork a right neighbor to continue the chain
	if ((id = fork()) < 0)
		panic("fork: %e", id);
	if (id==0)
		goto top;
	// filter out multiples of our prime
	while (1) {
		i = ipc_recv(envid, 0, 0);
		if (i%p)
		{	//cprintf("%d:send\n",i);
			//for (i = 3; ; i++)
//cprintf("send from %08x to %08x, i %d: p %d: CPUS:%d\n",sys_getenvid(),id,i,p,thisenv->env_cpunum);
			ipc_send(id, i, 0, 0);
			//while(n) 
				//n--;
		}
	}
}

void
umain(int argc, char **argv)
{
	int i, id;

	// fork the first prime process in the chain
	if ((id = fork()) < 0)
		panic("fork: %e", id);
	if (id == 0)
		primeproc();

	// feed all the integers through
	for (i = 2; ; i++)
	{
		//cprintf("send from %08x to %08x, i %d: CPUS:%d\n",thisenv->env_id,id,i,thisenv->env_cpunum);
		ipc_send(id, i, 0, 0);
	}
}

