import java.io.*;
public class DetailUsingBufferedReader {
  public static void main(String[] args) throws IOException {
    BufferedReader br = new BufferedReader(new InputStreamReader(System.in));
    String name;
    int std;
    long ph;
    char sec;
    System.out.print("Enter name, class, section & phone no. : ");
    name = br.readLine();
    std = Integer.parseInt(br.readLine());
    sec = br.readLine().charAt(0);
    ph = Long.parseLong(br.readLine());
    System.out.println("Name\t= " + name);
    System.out.println("Class\t= " + std);
    System.out.println("Section\t= " + sec);
    System.out.println("Phone\t= " + ph);
  }
}
