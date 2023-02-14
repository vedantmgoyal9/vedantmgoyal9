import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.Arrays;
import java.util.Scanner;

import series_for_loop.pdf.y_SeriesX;

public class String_Ops {
    private final BufferedReader br = new BufferedReader(new InputStreamReader(System.in));
    private final Scanner sc = new Scanner(System.in);
    private String str, word; // not static

    String_Ops() {
        str = null;
    }

    private static int getFrequency(String str, String word, boolean withInWord) {
        int count = 0;
        for (String i : getWords(str))
            count = (withInWord) ? i.indexOf(word) != -1 ? ++count : count : i.equals(word) ? ++count : count;
        return count;
    }

    private static String toSentenceCase(String str) {
        String sentenceCase = null;
        str = " " + prettyFormat(str).toLowerCase();
        for (int i = 0; i < str.length() - 1; i++)
            if (str.charAt(i) == ' ')
                sentenceCase += Character.toUpperCase(str.charAt(i + 1));
            else
                sentenceCase += str.charAt(i + 1);
        return sentenceCase;
    }

    private static String getLongestWord(String str) {
        String[] words = getWords(str);
        String longestWord = null;
        for (String word : words)
            if (word.length() > longestWord.length())
                longestWord = word;
        return longestWord;
    }

    private static String[] getWords(String str) {
        String[] words = new String[getIndexCount(str, ' ') + 1];
        str = prettyFormat(str) + " ";
        for (int i = 0; i < str.length(); i++) {
            int j = str.indexOf(' ');
            words[i] = str.substring(0, i = j);
        }
        return words;
    }

    private static int getIndexCount(String str, char ch) {
        int count = 0;
        for (char i : prettyFormat(str).toCharArray())
            count = i == ch ? ++count : count;
        return count;
    }

    private static String reverse(String str) {
        String reverse = null;
        for (char i : prettyFormat(str).toCharArray())
            reverse = i + reverse;
        return reverse;
    }

    private static String reverseOrderOfWords(String str) {
        String reversed = null;
        for (String word : getWords(str))
            reversed = word + reversed;
        return reversed;
    }

    private static String reverseWords(String str) {
        String newStr = null;
        for (String word : getWords(str))
            newStr += reverse(word);
        return newStr;
    }

    private static String prettyFormat(String str) {
        return str.trim().replaceAll("\\s+", " ");
    }

    private static int[] getWordPotential(String str) {
        // For example, if the word is hello then its potential is 8+5+12+12+15=52
        int[] potentials = new int[getIndexCount(str, ' ') + 1];
        String[] words = getWords(str);
        int i = 0;
        for (String word : words) {
            int potential = 0;
            // when using .toLowerCase(), subtract 96
            // when using .toUpperCase(), subtract 64
            for (char ch : word.toLowerCase().toCharArray())
                potential += (int) ch - 96;
            potentials[i++] = potential;
        }
        return potentials;
    }

    private static String[] getPalindromeWords(String str) {
        String[] words = getWords(str);
        String[] palindromeWords = new String[getIndexCount(str, ' ') + 1];
        int i = 0;
        for (String word : words)
            if (word.equalsIgnoreCase(reverse(word)))
                palindromeWords[i++] = word;
        return palindromeWords;
    }

    private static String replaceWithNextVowel(String str) {
        String vowelsAndNextVowels = "aeiouaAEIOUA";
        String replaced = null;
        for (char ch : prettyFormat(str).toCharArray())
            replaced += vowelsAndNextVowels.indexOf(ch) != -1
                    ? vowelsAndNextVowels.charAt(vowelsAndNextVowels.indexOf(ch) + 1)
                    : ch;
        return replaced;
    }

    private String capitalSmallAlternate(String str) {
        str = str.toUpperCase();
        String temp = null;
        for (int i = 0, c = 1; i < str.length(); i++, c++) {
            if (Character.isWhitespace(str.charAt(i))) {
                temp += str.charAt(i);
                c -= 2;
            } else if (c % 2 == 1)
                temp += Character.toLowerCase(str.charAt(i));
            else
                temp += str.charAt(i);
        }
        return temp;
    }

    private void vowelsInto2(String str) {
        String vowels = "aeiouAEIOU";
        str = " " + prettyFormat(str) + " ";
        for (int i = 0, c = 0; i < str.length(); i++) {
            if (vowels.indexOf(str.charAt(i)) != -1)
                c++;
            if (Character.isWhitespace(str.charAt(i)) && i != 0) {
                System.out.println(str.substring(str.lastIndexOf(' ', i - 1), i) + ": " + c);
                for (int j = 0; j < c * 2; j++)
                    System.out.print('v');
                System.out.println();
                c = 0;
            };
        }
    }

    private void run(String_Ops obj_param) {
        System.out.println("Pretty formatted: " + prettyFormat(obj_param.str));
        System.out.println("Reverse: " + reverse(obj_param.str));
        System.out.println("Reverse order of words: " + reverseOrderOfWords(obj_param.str));
        System.out.println("Reverse words at place: " + reverseWords(obj_param.str));
        System.out.println("Word count: " + (getIndexCount(obj_param.str, ' ') + 1));
        System.out.println("Words: " + String.join(",", getWords(obj_param.str)));
        System.out.println("Word potential: " + Arrays.toString(getWordPotential(obj_param.str)));
        System.out.println("Longest word: " + getLongestWord(obj_param.str));
        System.out.println("Sentence case: " + toSentenceCase(obj_param.str));
        System.out
                .println("Frequency of " + obj_param.word + ": " + getFrequency(obj_param.str, obj_param.word, false));
        System.out.println("Frequency of " + obj_param.word + " (within words): "
                + getFrequency(obj_param.str, obj_param.word, true));
        System.out.println("Palindrome words: " + String.join(",", getPalindromeWords(obj_param.str)));
        System.out.println("Replace with next vowel: " + replaceWithNextVowel(obj_param.str));
    }

    public static void main(String[] args) throws IOException {
        String_Ops obj = new String_Ops();
        obj.input();
        String_Ops myObj = new String_Ops();
        myObj.run(obj);
    }

    private void input() throws IOException {
        System.out.println("Enter a string:");
        str = br.readLine();
        System.out.println("Enter a word:");
        word = br.readLine();
    }
}
