class HCF {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.print("Enter 2 nos. : ");
    int a = sc.nextInt();
    int b = sc.nextInt();
    int i;
    for (i = a; i >= 1; i--) if (a % i == 0 && b % i == 0) break;
    System.out.println("HCF = " + i);
    sc.close();
  }
}
