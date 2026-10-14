#include <stdio.h>
#include <stdint.h>
#include <unistd.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/syscall.h>
#include <linux/perf_event.h>
static long pe_open(struct perf_event_attr *a){ return syscall(__NR_perf_event_open,a,0,-1,-1,0); }
static long long measure(unsigned cfg){
  struct perf_event_attr pe; memset(&pe,0,sizeof(pe));
  pe.type=PERF_TYPE_HARDWARE; pe.size=sizeof(pe); pe.config=cfg;
  pe.disabled=1; pe.exclude_kernel=0; pe.exclude_hv=1;
  long fd=pe_open(&pe);
  if(fd<0){ perror("perf_event_open"); return -1; }
  ioctl(fd,PERF_EVENT_IOC_RESET,0); ioctl(fd,PERF_EVENT_IOC_ENABLE,0);
  volatile unsigned long x=0; for(unsigned long i=0;i<200000000UL;i++) x+=i;
  ioctl(fd,PERF_EVENT_IOC_DISABLE,0);
  long long c=0; if(read(fd,&c,sizeof(c))!=sizeof(c)) c=-2; close(fd); return c;
}
int main(){
  printf("HW cycles       = %lld\n", measure(PERF_COUNT_HW_CPU_CYCLES));
  printf("HW instructions = %lld\n", measure(PERF_COUNT_HW_INSTRUCTIONS));
  printf("HW branches     = %lld\n", measure(PERF_COUNT_HW_BRANCH_INSTRUCTIONS));
  return 0;
}
