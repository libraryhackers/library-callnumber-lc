import unittest
from test import main

def suite():
    test_suite = unittest.TestSuite()
    test_suite.addTest(main.suite())
    return test_suite

runner = unittest.TextTestRunner()
runner.run(suite())
