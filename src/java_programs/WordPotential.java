// Write a program to input a word and display its potential.
// For example, if the word is hello then its potential is 8+5+12+12+15=52
public class WordPotential {
  public static void main(String[] args) {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.println("Enter a word: ");
    String word = sc.next().toLowerCase();
    // when using .toLowerCase(), subtract 96
    // when using .toUpperCase(), subtract 64
    int potential = 0;
    for (int i = 0; i < word.length(); i++) {
      potential += (int) word.charAt(i) - 96;
    }
    System.out.println("Potential of the word: " + potential);
    sc.close();
  }
}
