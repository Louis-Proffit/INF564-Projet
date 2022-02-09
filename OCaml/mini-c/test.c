// un exemple de fichier mini-C
// à modifier au fur et à mesure des tests
//
// la commande 'make' recompile mini-c (si nécessaire)
// et le lance sur ce fichier

int f(int x, int y){
    int z;
    if (z){
        return z;
    } else {
        z = 2;
    }
}

int main() {
  int x;
  x = 42;
  {
    int y;
    int x;
    {
        int z;
        z = 3 + 2;
        {
            int z2;
        }
    }
  }
}
