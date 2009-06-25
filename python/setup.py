from setuptools import setup, find_packages

install_requires = []

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
    version = '0.1.0',  # remember to update callnumber/__init__.py on release!
    url = 'http://code.google.com/p/library-callnumber-lc/',
    author = 'Michael J. Giarlo',
    author_email = 'leftwing@alumni.rutgers.edu',
    license = 'http://www.opensource.org/licenses/mit-license.php',
    packages = find_packages(),
    install_requires = install_requires,
    description = 'normalize Library of Congress call numbers and create ranges of normalized call numbers',
    classifiers = filter(None, classifiers.split('\n')),
    test_suite = 'test',
    )
