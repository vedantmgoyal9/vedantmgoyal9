package conditions_ninth;

class GreatestOf3_Ternary {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.print("Enter 3 numbers : ");
    int a = sc.nextInt(), b = sc.nextInt(), c = sc.nextInt();
    System.out.print("Greatest No. : " + (a > b && a > c ? a : (b > c ? b : c)));
    sc.close();
  }
}
