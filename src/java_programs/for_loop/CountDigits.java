package for_loop;
class CountDigits {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.print("Enter no. : ");
    int n = sc.nextInt();
    int i, c = 0;
    for (i = n; i != 0; i = i / 10) c++;
    System.out.print("DIGITS = " + c);
    sc.close();
  }
}
