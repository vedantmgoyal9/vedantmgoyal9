public class Pattern3 {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.print("Enter a word :- ");
    String w = sc.next();
    int b = w.length() + 1, e = w.length() / 2 + 1;
    String s = " ";
    System.out.println(w);
    for (int i = 0; i < w.length() / 2; i++) {
      System.out.println(w.substring(0, e) + s + w.substring(b));
      s += "  ";
      e--;
      b++;
    }
    sc.close();
  }
}
