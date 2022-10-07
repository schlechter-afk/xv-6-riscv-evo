#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"

uint64 sys_exit(void)
{
  int n;
  argint(0, &n);
  exit(n);
  return 0; // not reached
}

uint64 sys_getpid(void)
{
  return myproc()->pid;
}

uint64 sys_fork(void)
{
  return fork();
}

uint64 sys_wait(void)
{
  uint64 p;
  argaddr(0, &p);
  return wait(p);
}

uint64 sys_sbrk(void)
{
  uint64 addr;
  int n;

  argint(0, &n);
  addr = myproc()->sz;
  if (growproc(n) < 0)
    return -1;
  return addr;
}

uint64 sys_sleep(void)
{
  int n;
  uint ticks0;

  argint(0, &n);
  acquire(&tickslock);
  ticks0 = ticks;
  while (ticks - ticks0 < n)
  {
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}

uint64 sys_kill(void)
{
  int pid;

  argint(0, &pid);
  return kill(pid);
}

uint64 sys_uptime(void)
{
  uint xticks;

  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}

uint64 sys_trace(void)
{
  int arg;
  argint(0, &arg);
  myproc()->tracy = arg;
  return 0;
}

uint64 sys_sigreturn(void)
{
  struct proc *p = myproc();
  memmove(p->trapframe, p->cpy_trapframe, sizeof(*(p->trapframe)));
  p->completed_clockval = 0;
  p->is_sigalarm = 0;

  // printf("* handler is %d\n", handler)
  // printf("~ clockval is %d\n", curr_clockval);
  
  usertrapret();
  return 0;
}

uint64 sys_sigalarm(void)
{
  struct proc *p = myproc();
  int curr_clockval;
  argint(0, &curr_clockval);

  uint64 curr_handler;
  argaddr(1, &curr_handler);

  // printf("* handler is %d\n", handler)
  // printf("~ clockval is %d\n", curr_clockval);

  p->is_sigalarm = 0;
  p->completed_clockval = 0;

  p->clockval = curr_clockval;
  p->handler = curr_handler; // to store the handler function address
  return 0;
}