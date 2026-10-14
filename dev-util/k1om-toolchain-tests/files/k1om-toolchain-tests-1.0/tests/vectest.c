/* KNC vector/mask context-switch save-restore validator.
 * Forks many procs pinned to few CPUs so the scheduler switches them constantly.
 * Each proc loads unique values into mask regs k0-k7 and vector reg zmm3, then
 * repeatedly yields and re-reads them; any mismatch => kernel mis-saved/restored
 * vector state across a context switch. Exit 0 = PASS.
 */
#define _GNU_SOURCE
#include <stdint.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <sched.h>
#include <sys/wait.h>

#define NPROC 24
#define ITERS 20000
#define PIN_BASE 8     /* pin onto CPUs PIN_BASE..PIN_BASE+PIN_CPUS-1 (away from cpu0/SCIF) */
#define PIN_CPUS 6

static inline long sys_yield(void){ long r; __asm__ volatile("syscall":"=a"(r):"a"(24):"rcx","r11","memory"); return r; }

static inline void wr_masks(const uint32_t v[8]){
  __asm__ volatile("kmov %0,%%k0"::"r"(v[0])); __asm__ volatile("kmov %0,%%k1"::"r"(v[1]));
  __asm__ volatile("kmov %0,%%k2"::"r"(v[2])); __asm__ volatile("kmov %0,%%k3"::"r"(v[3]));
  __asm__ volatile("kmov %0,%%k4"::"r"(v[4])); __asm__ volatile("kmov %0,%%k5"::"r"(v[5]));
  __asm__ volatile("kmov %0,%%k6"::"r"(v[6])); __asm__ volatile("kmov %0,%%k7"::"r"(v[7]));
}
static inline void rd_masks(uint32_t v[8]){
  __asm__ volatile("kmov %%k0,%0":"=r"(v[0])); __asm__ volatile("kmov %%k1,%0":"=r"(v[1]));
  __asm__ volatile("kmov %%k2,%0":"=r"(v[2])); __asm__ volatile("kmov %%k3,%0":"=r"(v[3]));
  __asm__ volatile("kmov %%k4,%0":"=r"(v[4])); __asm__ volatile("kmov %%k5,%0":"=r"(v[5]));
  __asm__ volatile("kmov %%k6,%0":"=r"(v[6])); __asm__ volatile("kmov %%k7,%0":"=r"(v[7]));
}
static inline void wr_zmm(const void*p){ __asm__ volatile("vmovaps (%0),%%zmm3"::"r"(p):"memory"); }
static inline void rd_zmm(void*p){ __asm__ volatile("vmovaps %%zmm3,(%0)"::"r"(p):"memory"); }

static int child(int idx){
  cpu_set_t set; CPU_ZERO(&set);
  for (int c=0;c<PIN_CPUS;c++) CPU_SET(PIN_BASE+c,&set);
  sched_setaffinity(0,sizeof(set),&set);

  uint32_t em[8]; uint32_t exp_z[16] __attribute__((aligned(64)));
  for (int i=0;i<8;i++) em[i]=((idx*131+i*17+1)&0xFFFF);           /* 16-bit mask values */
  for (int i=0;i<16;i++) exp_z[i]=(uint32_t)(idx*2654435761u + i*40503u + 1);
  wr_masks(em); wr_zmm(exp_z);

  uint32_t gm[8]; uint32_t gz[16] __attribute__((aligned(64)));
  for (long it=0; it<ITERS; it++){
    sys_yield();
    rd_masks(gm); rd_zmm(gz);
    for (int i=1;i<8;i++) if (gm[i]!=em[i]){ fprintf(stderr,"FAIL idx=%d iter=%ld mask k%d: got %x exp %x\n",idx,it,i,gm[i],em[i]); return 2; }
    for (int i=0;i<16;i++) if (gz[i]!=exp_z[i]){ fprintf(stderr,"FAIL idx=%d iter=%ld zmm3[%d]: got %x exp %x\n",idx,it,i,gz[i],exp_z[i]); return 3; }
  }
  return 0;
}

int main(void){
  pid_t pids[NPROC];
  for (int i=0;i<NPROC;i++){ pid_t p=fork(); if(p==0) _exit(child(i)); pids[i]=p; }
  int fails=0;
  for (int i=0;i<NPROC;i++){ int st; waitpid(pids[i],&st,0); if(!WIFEXITED(st)||WEXITSTATUS(st)!=0) fails++; }
  if (fails==0) printf("VECTORTEST PASS (%d procs x %d iters, mask k0-7 + zmm3)\n",NPROC,ITERS);
  else          printf("VECTORTEST FAIL (%d/%d procs mismatched)\n",fails,NPROC);
  return fails?1:0;
}
