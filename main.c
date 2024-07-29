#include <stdio.h>

void printKey() {
    const char *key = "secret_key_123";
    printf("Key: %s\n", key);
}

int main() {
    printKey();
    return 0;
}
