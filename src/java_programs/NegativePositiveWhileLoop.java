class NegativePositiveWhileLoop {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.print("Enter number of numbers : ");
    int n = sc.nextInt(), v, i = 1, cn = 0, cp = 0;
    while (i <= n) {
      System.out.print("Enter a number : ");
      v = sc.nextInt();
      if (v < 0) cn++;
      else if (v > 0) cp++;
      i++;
    }
    System.out.println("Negative numbers : " + cn);
    System.out.println("Positive numbers : " + cp);
    System.out.println("Zero : " + (n - cp - cn));
    sc.close();
  }
}
