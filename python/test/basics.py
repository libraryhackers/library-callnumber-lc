import unittest
import callnumber

class BasicsTest(unittest.TestCase):
    def test_basics(self):
        a = callnumber.LC('A')

        self.assertTrue(a.normalize(), 'A')
        self.assertTrue(a.normalize(), a.start_of_range())
        self.assertTrue(a.end_of_range(), 'A~~')

        a = callnumber.LC('A11.1')

        self.assertTrue(a.normalize(), 'A  001110')
        self.assertTrue(a.end_of_range(), 'A  001119~999~999~999')

        self.assertTrue(a.normalize('B11'), 'B  0011')

        self.assertTrue(a.normalize('A 123.4 .c11'), 'A  012340C110')
        self.assertTrue(a.normalize('B11 .c13 .d11'), 'B  001100C130D110')
        self.assertTrue(a.normalize('B11 .c13 .d11'), 'B  001100C130D119~999')

    def test_lccns(self):
        lccns = {
            'HE8700.7 .P6T44 1983': ['HE', '8700.7', '.P6', 'T44', '1983'],
            'BS2545.E8 H39 1996': ['BS', '2545', '.E8', 'H39', '1996'],
            'NX512.S85 A4 2006': ['NX', '512', '.S85', 'A4', '2006'],
            }

        for lccn in lccns:
            expected = lccns[lccn]
            parts = callnumber.LC(lccn).components()
            self.assertTrue(lccn, "lccn: %s (%s)" % (lccn, " | ".join(parts)))
            self.assertTrue(len(expected), len(parts))
            i = 0
            for unit in expected:
                self.assertTrue(parts[i], unit)
                i += 1


def suite():
    test_suite = unittest.makeSuite(BasicsTest, 'test')
    return test_suite

if __name__ == '__main__':
    unittest.main()
