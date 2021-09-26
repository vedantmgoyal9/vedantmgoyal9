public class str_rev_palindrome {
    public static void main(String[] args) {
        java.util.Scanner sc = new java.util.Scanner(System.in);
        String str = sc.nextLine().trim();
        String[] words = str.split("\\s+");
        for (int i = 0; i < words.length; i++) {
            if (words[i].equalsIgnoreCase("quit")) {
                System.out.println("Quitting...");
                break;
            }
            String newWord = words[i].substring(1, words[i].length()).concat(words[i].charAt(0) + "");
            String reverse = "";
            for (int j = newWord.length() - 1; j >= 0 ; j--) {
                reverse += newWord.charAt(j) + "";
            }
            if (reverse.equals(words[i])) {
                System.out.println(words[i]);
            }
        }
        sc.close();
    }
}
