class LCMTimeDelay {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.print("Enter 2 nos. : ");
    int a = sc.nextInt(), b = sc.nextInt(), i;
    for (i = a; i % b != 0; i += a)
      ;
    System.out.println("LCM = " + i);
    sc.close();
  }
}
