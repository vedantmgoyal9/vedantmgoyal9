package numbers_logic;

class ReverseUpperLowerNestedLoopWithZero2 {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.println("Enter upper & lower limits ");
    int u = sc.nextInt(), l = sc.nextInt(), i, t;
    for (i = l; i <= u; i++) {
      t = i;
      System.out.print("Reverse of " + i + " = ");
      while (t != 0) {
        System.out.print(t % 10);
        t = t / 10;
      }
      System.out.println();
    }
    sc.close();
  }
}
