#!/usr/bin/env python

import subprocess
from subprocess import check_call, check_output, Popen, PIPE
import argparse
import os

parser = argparse.ArgumentParser()
parser.add_argument('--dest', default='/opt/ghc')
parser.add_argument('--version', required=True)
args = parser.parse_args()
flavor="i386-unknown-linux-deb7"

dest = os.path.join(args.dest, args.version)
check_call(['sudo', 'mkdir', '-p', args.dest])
user = check_output(['whoami']).strip()
check_call(['sudo', 'chown', user, args.dest])

url = "https://www.haskell.org/ghc/dist/{ver}/ghc-{ver}-{flavor}.tar.xz".format(ver=args.version, flavor=flavor)

download = Popen(['curl', '-L', url], stdout=subprocess.PIPE)
untar = Popen(['tar', '-Jx'], stdin=download.stdout)
untar.wait()

os.chdir('ghc-'+args.version)
check_call(['./configure', '--prefix={dest}/{ver}'.format(dest=dest, ver=args.version)])
check_call(['make', 'install'])

with open(os.path.join(dest, args.version, 'env.sh'), 'w') as f:
    f.write("""PATH={dest}/bin:$PATH
LD_LIBRARY_PATH={dest}/lib:$LD_LIBRARY_PATH
echo "Using GHC {ver}"
""".format(dest=dest, ver=args.version))
