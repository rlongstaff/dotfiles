
# Using OpenJDK installed via Homebrew

export PATH="/usr/local/opt/openjdk/bin:$PATH"

# For the system Java wrappers to find this JDK, symlink it with
#   sudo ln -sfn /usr/local/opt/openjdk/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk.jdk

# For compilers to find openjdk you may need to set:
export CPPFLAGS="-I/usr/local/opt/openjdk/include"
