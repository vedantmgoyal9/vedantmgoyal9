package numbers_logic;
// ICSE 2018
public class PronicNo {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.println("Enter a number: ");
    int n = sc.nextInt(), i = 1;
    boolean isPronic = false;
    do {
      if (i * (i + 1) == n) {
        isPronic = true;
        break;
      }
      i++;
    } while (i * (i + 1) <= n);
    System.out.println(isPronic ? "Pronic Number" : "Not a Pronic Number");
    sc.close();
  }
}
