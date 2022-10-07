package numbers_logic;

public class RemoveZeroAndDouble {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.print("Enter no. : ");
    int n = sc.nextInt(), i, r = 0;
    for (i = n; i != 0; i = i / 10) r = i % 10 != 0 ? r * 10 + i % 10 : r;
    for (i = r, r = 0; i != 0; i = i / 10) r = r * 10 + i % 10;
    System.out.print("Double of the no. after removing zero(s): " + r * 2);
    sc.close();
  }
}
