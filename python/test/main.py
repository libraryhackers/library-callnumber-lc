import unittest
import callnumber


lccns = {
    'HE8700.7 .P6T44 1983': ['HE', '8700.7', '.P6', 'T44', '1983'],
    'BS2545.E8 H39 1996': ['BS', '2545', '.E8', 'H39', '1996'],
    'NX512.S85 A4 2006': ['NX', '512', '.S85', 'A4', '2006'],
}

lccns_with_blanks = {
    'HE8700.7 .P6T44 1983': ['HE', '8700.7', '.P6', 'T44', '', '1983'],
    'BS2545.E8 1996': ['BS', '2545', '.E8', '', '', '1996'],
    'NX512.S85 A4': ['NX', '512', '.S85', 'A4', '', ''],
}


class CallNumberTest(unittest.TestCase):

    def test_00_simple_normalization(self):
        lccn = callnumber.LC('A')
        self.assertTrue(lccn.denormalized, 'A')
        self.assertTrue(lccn.normalized, 'A')

    def test_01_compound_normalization(self):
        lccn = callnumber.LC('A11.1')
        self.assertTrue(lccn.denormalized, 'A11.1')
        self.assertTrue(lccn.normalized, 'A  001110')

    def test_02_normalize_module_method(self):
        self.assertTrue(callnumber.normalize('B11'), 'B  0011')

    def test_03_module_method_with_cutters(self):
        self.assertTrue(callnumber.normalize('A 123.4 .c11'), 'A  012340C110')
        self.assertTrue(callnumber.normalize('B11 .c13 .d11'),
                        'B  001100C130D110')
        self.assertTrue(callnumber.normalize('B11 .c13 .d11'),
                        'B  001100C130D119~999')

    def test_04_simple_range(self):
        lccn = callnumber.LC('A')
        self.assertTrue(lccn.range_start, 'A')
        self.assertTrue(lccn.range_end, 'A~~')

    def test_05_compound_range(self):
        lccn = callnumber.LC('A11.1')
        self.assertTrue(lccn.range_start, 'A  001110')
        self.assertTrue(lccn.range_end, 'A  001119~999~999~999')

    def test_06_start_of_range_equivalence(self):
        for lccn in lccns:
            lccn = callnumber.LC(lccn)
            self.assertTrue(lccn.normalized, lccn.range_start)

    def test_07_components_no_blanks(self):
        for lccn in lccns:
            expected = lccns[lccn]
            comps = callnumber.LC(lccn).components()
            self.assertTrue(lccn)
            self.assertEqual(len(expected), len(comps))
            self.assertEqual(expected, comps)

    def test_08_components_no_blanks(self):
        for lccn in lccns_with_blanks:
            expected = lccns_with_blanks[lccn]
            comps = callnumber.LC(lccn).components(include_blanks=True)
            self.assertTrue(lccn)
            self.assertEqual(len(expected), len(comps))
            self.assertEqual(expected, comps)


def suite():
    test_suite = unittest.makeSuite(CallNumberTest, 'test')
    return test_suite

if __name__ == '__main__':
    unittest.main()
