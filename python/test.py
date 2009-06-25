import unittest
from test import basics

def suite():
    test_suite = unittest.TestSuite()
    test_suite.addTest(basics.suite())
    return test_suite

runner = unittest.TextTestRunner()
runner.run(suite())
