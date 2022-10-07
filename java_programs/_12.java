public class _12 {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.println("Enter your name: ");
    String name = " " + sc.nextLine().toUpperCase().trim().replaceAll("\\s+", " ");
    for (int i = 0; i < name.length(); i++) {
      if (name.charAt(i) == ' ') {
        System.out.print(Character.toUpperCase(name.charAt(i + 1)) + ". ");
      }
    }
    sc.close();
  }
}
