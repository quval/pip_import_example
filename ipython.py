import os
import sys

import IPython

if __name__ == '__main__':
    # Python automatically adds the directory of the current script as
    # sys.path[0]. This breaks out of the sandbox by resolving the symlink,
    # and can cause import issues.
    # TODO: Remove when using Python 3.11, which has support for disabling this
    # behaviour (-P or PYTHONSAFEPATH=1).
    del sys.path[0]

    base_dir = os.environ.get('BUILD_WORKING_DIRECTORY', '.')
    os.chdir(base_dir)
    IPython.start_ipython()
