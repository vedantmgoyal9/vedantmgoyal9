// program to replace a vowel with the next vowel in alphabet
public class NextVowel {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.println("Enter a string: ");
    String s = sc.nextLine();
    for (int i = s.length(); i > 0; i--) {
      for (int j = 0; j < i; j++) System.out.print(s.charAt(j));
      System.out.println();
    }
    for (int i = s.length(); i > 0; i--) {
      System.out.println(s.substring(0, i));
    }
    sc.close();
  }
}
