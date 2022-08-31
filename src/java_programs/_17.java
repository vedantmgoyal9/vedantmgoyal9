public class _17 {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.println("Enter a sentence: ");
    String str = sc.nextLine().toLowerCase();
    for (int i = 0; i < str.length() - 1; i++)
      if (str.charAt(i) + 1 == str.charAt(i + 1) || str.charAt(i) - 1 == str.charAt(i + 1))
        System.out.println(str.charAt(i) + "" + str.charAt(i + 1));
    sc.close();
  }
}
