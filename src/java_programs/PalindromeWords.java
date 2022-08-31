public class PalindromeWords {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.println("Enter a string: ");
    String str = sc.nextLine().trim() + " ", word = "", rword = "";
    for (int i = 0; i < str.length(); i++) {
      if (str.charAt(i) != ' ') {
        word += str.charAt(i);
        rword = str.charAt(i) + rword;
      } else {
        if (word.equalsIgnoreCase(rword) && !word.equals("")) System.out.println(word);
        word = rword = "";
      }
    }
    sc.close();
  }
}
