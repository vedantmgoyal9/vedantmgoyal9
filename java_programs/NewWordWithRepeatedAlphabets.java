public class NewWordWithRepeatedAlphabets {
  public static void main(String[] args) throws Exception {
    java.util.Scanner sc = new java.util.Scanner(System.in);
    System.out.print("Enter a sentence : ");
    String str = sc.nextLine(); // "all students will get their success"
    String rw = "";
    String temp = "";
    String result = "";
    boolean condition;
    for (int i = 0; i < str.length(); i++) {
      char ch = str.charAt(i);
      try {
        condition = rw.indexOf(ch) == -1;
      } catch (Exception e) {
        condition = false;
      }
      if (condition) {
        temp = str.substring(i, str.indexOf(' '));
        if (temp.indexOf(ch) != -1) {
          result += ch;
          rw += ch + "";
        }
      } else if (ch == ' ') {
        rw = null;
        result += " ";
        str = str.substring(i, str.length());
      }
    }
    System.out.println(rw);
    System.out.println(str);
    System.out.println(result);
    sc.close();
  }
}
