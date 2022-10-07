public class SentenceCase {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.println("Enter a string: ");
    String str = " " + sc.nextLine().toLowerCase().trim().replaceAll("\\s+", " ");
    for (int i = 0; i < str.length() - 1; i++) {
      if (str.charAt(i) == ' ') {
        System.out.print(Character.toUpperCase(str.charAt(i + 1)));
      } else {
        System.out.print(str.charAt(i + 1));
      }
    }
    sc.close();
  }
}
