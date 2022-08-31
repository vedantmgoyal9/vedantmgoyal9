package numbers_logic;
class _OneZeroWithoutIf {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.print("Enter 0 or 1 : ");
    int n = sc.nextInt();
    System.out.print(1 - n);
    sc.close();
  }
}
