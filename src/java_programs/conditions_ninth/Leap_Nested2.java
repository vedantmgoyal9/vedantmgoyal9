package conditions_ninth;

class Leap_Nested2 {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.print("Enter a year : ");
    int y = sc.nextInt();
    if (y % 100 == 0) {
      if (y % 400 == 0) System.out.print("Leap");
      else System.out.print("Not Leap");
    } else {
      if (y % 4 == 0) System.out.print("Leap");
      else System.out.print("Not Leap");
    }
    sc.close();
  }
}
