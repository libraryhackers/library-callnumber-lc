package edu.umich.lib.normalizers;
import java.util.regex.*;
import java.lang.StringBuffer;
import java.util.ArrayList;
import java.util.List;
import java.util.ListIterator;

public class LCCallNumberNormalizer
{
  public static final String JOIN = "";

  public static final String TOPSPACES = "                 ";
  public static final String TOPSPACE = " ";
  public static final String TOPDIGIT = "0";
  public static final String TOPDIGITS = "0000000000000000";
  // public static final String TOPSPACES = "****************** ";
  // public static final String TOPSPACE = "*";
  // public static final String TOPDIGIT = "!";
  // public static final String TOPDIGITS = "!!!!!!!!!!!!!!!!";

  public static final String BOTTOMSPACES = "~~~~~~~~~~~~~~";
  public static final String BOTTOMSPACE = "~";
  public static final String BOTTOMDIGIT = "9";
  public static final String BOTTOMDIGITS = "999999999999999999999";
    
  private static Pattern lcpattern = Pattern.compile(
   "^ \\s* (?:VIDEO-D)? (?:DVD-ROM)? (?:CD-ROM)? (?:TAPE-C)? \\s* ([A-Z]{1,3}) \\s* (?: (\\d+) (?:\\s*?\\.\\s*?(\\d+))? )? \\s* (?: \\.? \\s* ([A-Z]) \\s* (\\d+ | \\Z)? )? \\s* (?: \\.? \\s* ([A-Z]) \\s* (\\d+ | \\Z)? )? \\s* (?: \\.? \\s* ([A-Z]) \\s* (\\d+ | \\Z)? )? (\\s\\s*.+?)? \\s*$",
    Pattern.COMMENTS
  );
  
  public static String join(List<String> s, String d)
  {
    StringBuffer rv = new StringBuffer("");
    ListIterator i = s.listIterator();
    while (i.hasNext()) {
      rv.append(i.next());
      rv.append(d);
    }
    return rv.toString();
  }
  
  public static String normalize(String s) 
  {
    return normalize(s, false);
  }
  
  public static String rangeStart(String s) 
  {
    return normalize(s, false);
  }
  
  public static String rangeEnd(String s)
  {
    return normalize(s, true);
  }
  
  public static String normalize(String s, Boolean rangeEnd)
  {
    s = s.toUpperCase();
    Matcher m = lcpattern.matcher(s);
    if (!m.matches()) {
      System.out.print("No match\n");
      return "";
    }
      
    String alpha   = m.group(1);
    String num     = m.group(2);
    String dec     = m.group(3);
    String c1alpha = m.group(4);
    String c1num   = m.group(5);
    String c2alpha = m.group(6);
    String c2num   = m.group(7);
    String c3alpha = m.group(8);
    String c3num   = m.group(9);
    String extra   = m.group(10);
    
    // Record the originals
    ArrayList<String> origs = new ArrayList<String>(10);
    for (int i = 1; i <=10; i++) {
      origs.add(m.group(i));
    }
    
    //We have some records that aren't LoC Call Numbers, but start like them, 
    //only with three digits in the decimal. Ditch them

    if (dec != null && dec.length() > 2) {
      // throw an error
      return "";
    }

    // If we've got an alpha and nothing else, return it.
    // If we've got an alpha and nothing else but an 'extra', it's probably malformed.
    boolean hasAlpha = alpha != null;
    boolean hasExtra = extra != null;
    boolean hasOther = false;
    for (int i = 2; i <= 9; i++) {
      if (m.group(i) != null) {
        hasOther = true;
      }
    }
    
    if (hasAlpha && !hasOther) {
      if (hasExtra) {
        // throw an error
        return "";
      }
      if (rangeEnd) {
        return alpha + BOTTOMSPACES.substring(0, 3 - alpha.length());
      }
      return alpha;
    }

    // Normalize each part and push them onto a stack

    // my $enorm = $extra;
    String enorm = extra == null? "" : extra;
    enorm.replaceAll("[^A-Z0-9]", "");
    
    // Pad the number out to four digits    
    num = num == ""? "0000" : num.format("%04d", Integer.parseInt(num));
    
    ArrayList<String> topnorm = new ArrayList<String>(10);
    topnorm.add(alpha + TOPSPACES.substring(0,3 - alpha.length()));
    topnorm.add(num);
    topnorm.add(dec == null? "00"   : dec + TOPDIGITS.substring(0, 2 - dec.length()));
    topnorm.add(c1alpha == null? TOPSPACE : c1alpha);
    topnorm.add(c1num   == null? "000"    : c1num + TOPDIGITS.substring(0, 3 - c1num.length()));
    topnorm.add(c2alpha == null? TOPSPACE : c2alpha);
    topnorm.add(c2num   == null? "000"    : c2num + TOPDIGITS.substring(0, 3 - c2num.length()));
    topnorm.add(c3alpha == null? TOPSPACE : c3alpha);
    topnorm.add(c3num   == null? "000"    : c3num + TOPDIGITS.substring(0, 3 - c3num.length()));
    topnorm.add(enorm);
    
    ArrayList<String> bottomnorm = new ArrayList<String>(10);
    if (rangeEnd) {
      bottomnorm.add(alpha + BOTTOMSPACES.substring(0,3 - alpha.length()));
      bottomnorm.add(num);
      bottomnorm.add(dec == null?     "99"        : dec + BOTTOMDIGITS.substring(0, 2 - dec.length()));
      bottomnorm.add(c1alpha == null? BOTTOMSPACE : c1alpha);
      bottomnorm.add(c1num   == null? "999"       : c1num + BOTTOMDIGITS.substring(0, 3 - c1num.length()));
      bottomnorm.add(c2alpha == null? BOTTOMSPACE : c2alpha);
      bottomnorm.add(c2num   == null? "999"       : c2num + BOTTOMDIGITS.substring(0, 3 - c2num.length()));
      bottomnorm.add(c3alpha == null? BOTTOMSPACE : c3alpha);
      bottomnorm.add(c3num   == null? "999"       : c3num + BOTTOMDIGITS.substring(0, 3 - c3num.length()));
      bottomnorm.add(enorm);
    }
    
    if (extra != null) {
      return join(topnorm, "");
    }
    
    // Remove 'extra'
    topnorm.remove(9);
    if (rangeEnd) {
      bottomnorm.remove(9);
    }

    for (int i = 8; i >= 1; i--) {
      String end = topnorm.remove(i).toString(); // pop it off
      if (origs.get(i) != null) {
        if (rangeEnd) {
          end = join(bottomnorm.subList(i, 8), JOIN);
        }
        return join(topnorm, JOIN) + JOIN + end;
      }
    }    
    return "Something went horribly wrong\n";
  }
}











































