import org.junit.* ;
import static org.junit.Assert.* ;
import edu.umich.lib.normalizers.*;

public class BasicsTest
{
  @Test
  public void test_singleLetter()
  {
    System.out.println("Testing 'A'");
    LCCallNumberNormalizer LC = new LCCallNumberNormalizer();
  }
}