public class _13 {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.println("Enter your name: ");
    String name = " " + sc.nextLine().trim();
    for (int i = 0; i < name.lastIndexOf(' '); i++) {
      if (name.charAt(i) == ' ') System.out.print(Character.toUpperCase(name.charAt(i + 1)) + ". ");
    }
    System.out.print(
        Character.toUpperCase(name.charAt(name.lastIndexOf(' ') + 1))
            + name.substring(name.lastIndexOf(' ') + 2));
    sc.close();
  }
}
