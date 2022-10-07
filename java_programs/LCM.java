class LCM {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.print("Enter 2 nos. : ");
    int a = sc.nextInt();
    int b = sc.nextInt();
    int i;
    for (i = a; i <= a * b; i++) if (i % a == 0 && i % b == 0) break;
    System.out.println("LCM = " + i);
    sc.close();
  }
}
