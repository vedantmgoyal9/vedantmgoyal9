public class LongestWord {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.println("Enter a sentence: ");
    String str = sc.nextLine().trim() + " ";
    String longestWord = "";
    for (int i = 0; i < str.length(); i++) {
      if (longestWord.length() <= str.substring(i, str.indexOf(" ", i)).length()) {
        longestWord = str.substring(i, str.indexOf(" ", i));
      }
    }
    System.out.println("Longest word is: " + longestWord);
    sc.close();
  }
}
