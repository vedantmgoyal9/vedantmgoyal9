class Fibonacci {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.println("Enter number of terms : ");
    int n = sc.nextInt(), i, a = 0, b = 1, c;
    for (i = 1; i <= n; i++) {
      System.out.println(a);
      c = a + b;
      a = b;
      b = c;
    }
    sc.close();
  }
}
