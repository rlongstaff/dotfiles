#!/bin/sh

# We may want to symlink or run a different binary
# depending on docker/crictl.
# Thus, we prepend our path to the PATH.
export PATH="$HOME/.docker/bin:$PATH"
