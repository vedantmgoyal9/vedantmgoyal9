import java.util.Scanner;
public class Mixed_Ops {
    private final Scanner sc = new Scanner(System.in);

    private String whatIsThisCharacter(String str) {
        char ch = str.charAt(0);
        if (ch >= 'a' && ch <= 'z') return "a Small Letter";
        else if (ch > 47 && ch < 58) return "a Digit";
        else if (ch >= 'A' && ch <= 'Z') return "a Capitalised Letter";
        else return "a Symbol";
    }



}
