// based on https://github.com/ali1234/vcpoke/
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include "mailbox.h"

#define BUS_TO_PHYS(x) ((x) & ~0xC0000000)

typedef int16_t q4_12s; // signed 4.12 fixed-point number
float mask = 1 << 12;

q4_12s fixedp(float n) { return (q4_12s)(mask * n); }
q4_12s floatingp(q4_12s n) { return ((float)n) / mask; }

// i'm keeping the data just after the loaded program, because for some reason it doesn't like two allocations
const uint32_t data_size = 256; 

int main(int argc, char *argv[]) {
  FILE *f = fopen("build/test", "rb");
  fseek(f, 0, SEEK_END);
  uint32_t file_size = ftell(f);
  rewind(f);

  int mbox_fd = mbox_open();
  int mbox_handle = mem_alloc(mbox_fd, file_size + data_size, 8, 4);
  uint32_t program_vpu = mem_lock(mbox_fd, mbox_handle);
  uint8_t *program_arm = mapmem(BUS_TO_PHYS(program_vpu), file_size + data_size);

  fread(program_arm, 1, file_size, f);

  volatile q4_12s *data = (q4_12s*)(program_arm + file_size);
  for (int j = 0; j < 16; j++) { data[0 + j] = fixedp(0); data[16 + j] = fixedp(1.1); }
  printf("starting vpu\n");
  printf("r0 = 0x%08x\n", execute_code(mbox_fd, program_vpu, program_vpu + file_size, 0, 0, 0, 0, 0)); // returned r0 = number of iterations total
  for (int i = 0; i < 16; i++) printf("%d ", data[i]); // number of iterations for each point
  printf("\n");

  unmapmem(program_arm, file_size);
  mem_unlock(mbox_fd, mbox_handle);
  mem_free(mbox_fd, mbox_handle);
  mbox_close(mbox_fd);
  return 0;
}
