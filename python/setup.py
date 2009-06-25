from setuptools import setup

classifiers = """
    Intended Audience :: Developers
    Intended Audience :: Information Technology
    License :: OSI Approved :: MIT License
    Programming Language :: Python
    Development Status :: 4 - Beta
    Topic :: Text Processing :: General
    Topic :: Utilities
"""

setup(
    name = 'callnumber',
    description = 'normalize Library of Congress call numbers and create ranges of normalized call numbers',
    version = '0.1.0',  # remember to update callnumber/__init__.py on release!
    url = 'http://code.google.com/p/library-callnumber-lc/',
    author = 'Michael J. Giarlo',
    author_email = 'leftwing@alumni.rutgers.edu',
    license = 'http://www.opensource.org/licenses/mit-license.php',
    packages = ['callnumber'],
    test_suite = 'test',
    classifiers = [c.strip() for c in classifiers.splitlines() if c],
)
