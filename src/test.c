#include <stdio.h>

int main(void) {

  FILE *fp = fopen("test.txt", "w+");
  if (!fp) {
    fprintf(stderr, "Could not open test.txt.\n");
    return 1;
  }

  fprintf(fp, "text for testing");

  return 0;
}
