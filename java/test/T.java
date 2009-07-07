import edu.umich.lib.normalizers.*;

class T
{
public static void main(String[] args) {
  LCCallNumberNormalizer LC = new LCCallNumberNormalizer();
  String[] test = {"A", "A1", "A1.2", "A1C3", "A1.22C33", "A1 .C3 D44", "AA11.22 C333", "AA1.22.C3D444", "AA1.22.C3 D444 1990"};
  for (String t : test) {
    System.out.print(t + " / " + LC.normalize(t) + " / " + LC.normalize(t, true) + "\n");
  }
}
}