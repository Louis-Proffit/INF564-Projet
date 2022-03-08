
int zero() { return 0; }
int false() { return zero(); }
int true() { return !zero(); }

int main() {
  // &&
  putchar('A');
  putchar('A' + true());
  putchar(10);
  return 0;
}
