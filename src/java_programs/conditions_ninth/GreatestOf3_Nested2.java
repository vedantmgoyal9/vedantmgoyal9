package conditions_ninth;
public class GreatestOf3_Nested2 {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.print("Enter 3 numbers : ");
    int a = sc.nextInt(), b = sc.nextInt(), c = sc.nextInt();
    if (a > b) {
      if (a > c) System.out.print("Greatest no. : " + a);
      else System.out.print("Greatest no. : " + c);
    } else {
      if (b > c) System.out.print("Greatest no. : " + b);
      else System.out.print("Greatest no. : " + c);
    }
    sc.close();
  }
}
