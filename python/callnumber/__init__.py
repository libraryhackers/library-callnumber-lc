import re

__version__ = '0.1.0'

lcregex = re.compile(r"""^
        \s*
        (?:VIDEO-D)? # for video stuff
        (?:DVD-ROM)? # DVDs, obviously
        (?:CD-ROM)?  # CDs
        (?:TAPE-C)?  # Tapes
        \s*
        ([A-Z]{1,3})  # alpha
        \s*
        (?:         # optional numbers with optional decimal point
          (\d+)
          (?:\s*?\.\s*?(\d+))? 
        )?
        \s*
        (?:               # optional cutter
          \.? \s*     
          ([A-Z])      # cutter letter
          \s*
          (\d+ | \Z)?        # cutter numbers
        )?
        \s*
        (?:               # optional cutter
          \.? \s*     
          ([A-Z])      # cutter letter
          \s*
          (\d+ | \Z)?        # cutter numbers
        )?
        \s*
        (?:               # optional cutter
          \.? \s*     
          ([A-Z])      # cutter letter
          \s*
          (\d+ | \Z)?        # cutter numbers
        )?
        (\s+.+?)?        # everthing else
        \s*$ """, re.VERBOSE)

weird = re.compile(r"""
  ^
  \s*[A-Z]+\s*\d+\.\d+\.\d+ """, re.VERBOSE)

# Change to make more readable/ more compact
joiner = ''
topspace = ' ' # must sort before 'A'
bottomspace = '~' # must sort after 'Z' and '9'
topdigit = '0'    # should be zero
bottomdigit = '9' # should be 9


class LC(object):
    def __init__(self, callno=''):
        self.callno = callno.upper()

    def components(self, returnAll=False):
        if re.match(weird, self.callno):
            return None

        m = re.match(lcregex, self.callno)
        if not m:
            return None

        (alpha, num, dec, c1alpha, c1num, c2alpha, c2num, c3alpha, c3num, extra) = m.groups('')

        if dec:
          num += '.%s' % dec

        c1 = ''.join((c1alpha, c1num))
        c2 = ''.join((c2alpha, c2num))
        c3 = ''.join((c3alpha, c3num))

        if re.search(r'\S', c1):
            c1 = '.%s' % c1

        comps = []
        for comp in (alpha, num, c1, c2, c3, extra):
            if not re.search(r'\S', comp) or not returnAll:
                continue    
            comp = re.match(r'^\s*(.*?)\s*$', comp).groups(1)
            comps.append(comp)
        return comps

    def _normalize(self, lc='', bottom=False):
        lc = lc.upper()
        bottomout = bottom

        if re.match(weird, lc):
            return None

        m = re.match(lcregex, lc)
        if not m:
            return None

        origs = m.groups('')
        (alpha, num, dec, c1alpha, c1num, c2alpha, c2num, c3alpha, c3num, extra) = origs

        if (len(dec) > 2):
            return None

        if alpha and not (num or dec or c1alpha or c1num or c2alpha or c2num or c3alpha or c3num):
            if extra:
                return None
            if bottomout:
                return alpha + bottomspace * (3 - len(alpha))
            return alpha

        enorm = re.sub(r'[^A-Z0-9]', '', extra)
        num = '%04d' % num

        topnorm = [
            alpha + topspace * (3 - len(alpha)),
            num + topdigit * (4 - len(num)),
            dec + topdigit * (2 - len(dec)),
            c1alpha if c1alpha else topspace,
            c1num + topdigit * (3 - len(c1num)),
            c2alpha if c2alpha else topspace,
            c2num + topdigit * (3 - len(c2num)),
            c3alpha if c3alpha else topspace,
            c3num + topdigit * (3 - len(c3num)),
            ' ' + enorm,
        ]

        bottomnorm = [
            alpha + bottomspace * (3 - len(alpha)),
            num + bottomdigit * (4 - len(num)),
            dec + bottomdigit * (2 - len(dec)),
            c1alpha if c1alpha else bottomspace,
            c1num + bottomdigit * (3 - len(c1num)),
            c2alpha if c2alpha else bottomspace,
            c2num + bottomdigit * (3 - len(c2num)),
            c3alpha if c3alpha else bottomspace,
            c3num + bottomdigit * (3 - len(c3num)),
            ' ' + enorm,
        ]

        if extra:
          return joiner.join(topnorm)

        topnorm.pop()
        bottomnorm.pop()

        inds = range(1, 9)
        inds.reverse()
        for i in inds:
            end = topnorm.pop()
            if origs[i]:
                if bottomout:
                    end = joiner.join(bottomnorm[i:]
                return joiner.join(topnorm) + joiner + end

    def normalize(self, lc=''):
        lc = lc.upper() if lc else self.callno
        return self._normalize(lc, False)

    def start_of_range(self, **kwargs):
        return self.normalize(kwargs)  

    def end_of_range(self, lc=''):
        lc = lc.upper() if lc else self.callno
        return self._normalize(lc, True)

