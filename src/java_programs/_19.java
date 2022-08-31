public class _19 {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.println("Enter a string: ");
    String str = " " + sc.nextLine().trim(), temp = "";
    for (int i = str.length() - 1; i >= 0; i--) {
      if (str.charAt(i) != ' ') {
        temp = str.charAt(i) + temp;
      } else {
        System.out.print(temp + " ");
        temp = "";
      }
    }
    sc.close();
  }
}
