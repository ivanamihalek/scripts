#!/usr/bin/env python

from sys import argv
from os import rename

tmpfile = argv[1] + ".tmp"

with open('/home/ivana/pyscr/license.txt', 'r') as file:
    license = file.read()

license_printed = False
with open(tmpfile, "w") as outf:
    with open(argv[1]) as inf:
    
        for line in inf:
            if not license_printed:
                if line[:2] == "#!":
                    print(line, file=outf, end="")
                    print(license,  file=outf, end="")

                else:
                    print(license,  file=outf, end="")
                    print(line, file=outf, end="")

                license_printed = True
            else:
                print(line, file=outf, end="")

rename(tmpfile, argv[1])

