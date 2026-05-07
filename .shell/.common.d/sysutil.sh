
REPO_USER=rlongstaff
SYSUTIL_BASE=${HOME}/prj/github.com/${REPO_USER}/sysutil
LOCAL_OS=$(uname -s)
LOCAL_ARCH=$(uname -m)

export PATH=$PATH:${SYSUTIL_BASE}/bin:${SYSUTIL_BASE}/bin/${LOCAL_OS}/${LOCAL_ARCH}
