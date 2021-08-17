"""Base library for configuring the CUDA toolchain."""

def auto_configure_fail(msg):
    """Output failure message when auto configuration fails."""
    red = "\033[0;31m"
    no_color = "\033[0m"
    fail("\n%sAuto-Configuration Error:%s %s\n" % (red, no_color, msg))

def auto_configure_warning(msg):
    """Output warning message during auto configuration."""
    yellow = "\033[1;33m"
    no_color = "\033[0m"

    # buildifier: disable=print
    print("\n%sAuto-Configuration Warning:%s %s\n" % (yellow, no_color, msg))

def get_env_var(repository_ctx, name, default = None, enable_warning = True):
    """
    Find an environment variable in system path. Doesn't %-escape the value!

    Args:
      repository_ctx: The repository context.
      name: Name of the environment variable.
      default: Default value to be used when such environment variable is not present.
      enable_warning: Show warning if the variable is not present.
    Returns:
      value of the environment variable or default.
    """

    if name in repository_ctx.os.environ:
        return repository_ctx.os.environ[name]
    if default != None:
        if enable_warning:
            auto_configure_warning("'%s' environment variable is not set, using '%s' as default" % (name, default))
        return default
    return auto_configure_fail("'%s' environment variable is not set" % name)

def which(repository_ctx, cmd, default = None):
    """
    A wrapper around repository_ctx.which() to provide a fallback value. Doesn't %-escape the value!

    Args:
      repository_ctx: The repository context.
      cmd: name of the executable to resolve.
      default: Value to be returned when such executable couldn't be found.
    Returns:
      absolute path to the cmd or default when not found.
    """
    result = repository_ctx.which(cmd)
    return default if result == None else str(result)

def which_cmd(repository_ctx, cmd, default = None):
    """
    Find cmd in PATH using repository_ctx.which() and fail if cannot find it. Doesn't %-escape the cmd!

    Args:
      repository_ctx: The repository context.
      cmd: name of the executable to resolve.
      default: Value to be returned when such executable couldn't be found.
    Returns:
      absolute path to the cmd or default when not found.
    """
    result = repository_ctx.which(cmd)
    if result != None:
        return str(result)
    path = get_env_var(repository_ctx, "PATH")
    if default != None:
        auto_configure_warning("Cannot find %s in PATH, using '%s' as default.\nPATH=%s" % (cmd, default, path))
        return default
    auto_configure_fail("Cannot find %s in PATH, please make sure %s is installed and add its directory in PATH.\nPATH=%s" % (cmd, cmd, path))
    return str(result)

def execute(
        repository_ctx,
        command,
        environment = None,
        expect_failure = False):
    """
    Execute a command, return stdout if succeed and throw an error if it fails. Doesn't %-escape the result!

    Args:
      repository_ctx: The repository context.
      command: command to execute.
      environment: dictionary with environment variables to set for the command.
      expect_failure: True if the command is expected to fail.
    Returns:
      stdout of the executed command.
    """
    if environment:
        result = repository_ctx.execute(command, environment = environment)
    else:
        result = repository_ctx.execute(command)
    if expect_failure != (result.return_code != 0):
        if expect_failure:
            auto_configure_fail(
                "expected failure, command %s, stderr: (%s)" % (
                    command,
                    result.stderr,
                ),
            )
        else:
            auto_configure_fail(
                "non-zero exit code: %d, command %s, stderr: (%s)" % (
                    result.return_code,
                    command,
                    result.stderr,
                ),
            )
    stripped_stdout = result.stdout.strip()
    if not stripped_stdout:
        auto_configure_fail(
            "empty output from command %s, stderr: (%s)" % (command, result.stderr),
        )
    return stripped_stdout

def get_cpu_value(repository_ctx):
    """
    Compute the cpu_value based on the OS name. Doesn't %-escape the result!

    Args:
      repository_ctx: The repository context.
    Returns:
      One of (darwin, freebsd, x64_windows, ppc, s390x, arm, aarch64, k8, piii)
    """
    os_name = repository_ctx.os.name.lower()
    if os_name.startswith("mac os"):
        return "darwin"
    if os_name.find("freebsd") != -1:
        return "freebsd"
    if os_name.find("windows") != -1:
        return "x64_windows"

    # Use uname to figure out whether we are on x86_32 or x86_64
    result = repository_ctx.execute(["uname", "-m"])
    if result.stdout.strip() in ["power", "ppc64le", "ppc", "ppc64"]:
        return "ppc"
    if result.stdout.strip() in ["s390x"]:
        return "s390x"
    if result.stdout.strip() in ["arm", "armv7l"]:
        return "arm"
    if result.stdout.strip() in ["aarch64"]:
        return "aarch64"
    return "k8" if result.stdout.strip() in ["amd64", "x86_64", "x64"] else "piii"
