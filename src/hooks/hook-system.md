# Available hooks

| Hook | Description |
| --- | --- |
| `self-updater.hook` | Makes the AppImage self-updatable using appimageupdatetool |
| `fix-namespaces.hook` | Fixes unprivileged user namespace restrictions (Ubuntu 24.04+) |
| `fix-gnome-csd.hook` | Uses host libdecor plugins for window decorations on GNOME Wayland |
| `udev-installer.hook` | Prompts the user to install bundled udev rules when needed |
| `vulkan-check.hook` | Checks and fixes common Vulkan and hardware acceleration issues |
| `x86-64-v3-check.hook` | Warns the user if their CPU does not support x86-64-v3 |
| `x86-64-v4-check.hook` | Warns the user if their CPU does not support x86-64-v4 |
| `host-libjack.hook` | Uses the host JACK library instead of the bundled one |
| `wayland-is-broken.hook` | Forces X11 fallback for applications with known Wayland issues |
| `sdl-soundfonts.hook` | Downloads and installs a SoundFont (FluidR3) when the application needs one |
| `get-yt-dlp.hook` | Downloads `yt-dlp` when the application requires it to play online videos |
| `qt-theme.hook` | Applies a custom Qt stylesheet via `APPIMAGE_QT_THEME` or a `.stylesheet` sidecar file |

Hooks are sourced by the generated `AppRun`. Older `.bg.hook` and `.src.hook` suffixes are only normalized for compatibility, so new examples should use plain `.hook` names.

Additional hooks can be placed in `$APPDIR/bin` and will be used automatically.

---

# The following functions and env variables are always available for hooks to use

## Functions

- `notify`  - Show messages and notifications with various tools like kdialog, yad, zenity, notify-send and more.
    If no tool is available it will finally attempt to use the host terminal emulator to display the message

```shell
    FLAGS:
    -di, --display-info MESSAGE      Display simple message
    -de, --display-error MESSAGE     Display error message
    -dw, --display-warning MESSAGE   Display warning message
    -dq, --display-question MESSAGE  Display yes/no question
    -ni, --notify-info MESSAGE       Send simple notification
    -ne, --notify-error MESSAGE      Send error notification
    -nw, --notify-warning MESSAGE    Send warning notification

    NOTE: If no flag is provided --notify-info behaviour is used instead.
```

- `download` - USAGE: `download </path/to/dst-file> <url>`
   This tool will attempt to use `wget` or `curl` to download, if neither command is available it will return 1 with an error message to stderr.
- `is_cmd` - Checks if the given arguments are a valid command in `PATH`, this function does not print anything to stdout or stderr.
    This function accepts multiple arguments to check. Example: `is_cmd cat grep mkdir`
    If argument is a valid command it returns 0, else returns 1.
    If multiple arguments are given and one is missing, it still returns 1.
    You can pass the `--any` flag as first argument if you want to know if one of many arguments is available.
    Example: `is_cmd --any wget curl` will only return 1 if both `wget` and `curl` are not available.
- `run_gui_sudo` - This function performs the given argument as root using an available tool to ask to elevate rights.
   If the user is already root, it then directly performs the operation without any of the tools it checks for.
   It checks and uses the following commands:

```shell
   pkexec
   lxqt-sudo
   run0
```

   If none of these tools are available, it returns 1 with an error message to stderr.
   You can use `run_gui_sudo --check` to know beforehand if it is possible to run this function, it will return 1 if none of the tools are available and the user is not root.
- `err_msg` - Prints what is given to stderr in red color. Example: `err_msg "Failed to get current time!"`

## Variables

- `APPIMAGE_ARCH` - Architecture of the running AppImage, equivalent to the output of `uname -m`, example: `x86_64`.
- `HOSTPATH`      - The original value of `PATH` before `$APPDIR/bin` is added to `PATH`.
- `APPDIR`        - The directory where the `AppRun` is located. **We guarantee this variable to be set even when the AppImage is extracted.**
- `ARG0`          - Equivalent to `ARGV0` in the [AppImage runtime](https://docs.appimage.org/packaging-guide/environment-variables.html#id2). We always unset `ARGV0` because **it causes a ton of issues** [^1][^2].

- `BINDIR`    - Value of `XDG_BIN_HOME` or if not set; `~/.local/bin`.
- `DATADIR`   - Value of `XDG_DATA_HOME` or if not set; `~/.local/share`.
- `CONFIGDIR` - Value of `XDG_CONFIG_HOME` or if not set; `~/.config`.
- `CACHEDIR`  - Value of `XDG_CACHE_HOME` or if not set; `~/.cache`.
- `STATEDIR`  - Value of `XDG_STATE_HOME` or if not set; `~/.local/state`.

- `HOST_HOME`            - Original value of `HOME` ignoring AppImage portable home mode.
- `HOST_XDG_CONFIG_HOME` - Original value of `XDG_CONFIG_HOME` ignoring AppImage portable config.
- `HOST_XDG_DATA_HOME`   - Original value of `XDG_DATA_HOME` ignoring AppImage portable data.
- `HOST_XDG_CACHE_HOME`  - Original value of `XDG_CACHE_HOME` ignoring AppImage portable cache.
- `HOST_XDG_STATE_HOME`  - (Do not rely on this variable since the uruntime does provide AppImage portable state).

## Fix namespace

**Originally from <https://github.com/Samueru-sama/fix-ubuntu-nonsense>**

Have your application quickly remove ubuntu namespaces restriction using polkit in a user friendly way.

This is a simple POSIX shell script that will do some basic checks before informing the user about the situation using `zenity` or `kdialog`, then uses `pkexec` to run:

```shell
echo 'kernel.apparmor_restrict_unprivileged_userns = 0' | tee /etc/sysctl.d/20-fix-namespaces.conf
sysctl -w kernel.apparmor_restrict_unprivileged_userns=0
```

Which removes the restriction fully.

If the user decides to NOT disable the restriction, the script will ask if they do not want to see the prompt ever again and make a lockfile so that it never happens again.

### Usage

To use simply download `fix-namespaces.hook` and execute it before starting your application.

The script has several checks to prevent false positives, but if they happen please open an issue and it will be fixed as soon as possible.

### Why

Starting with Ubuntu 24.04 they decided to limit the usage of namespaces.

Namespaces are a very important feature of the kernel that allows us to make a "fakeroot" where we then bind/remove access to the real root. Essentially this allows us to isolate an application to its own little environment.

Before their common usage what was done to isolate applications was using SUID binaries like firejail, this has the downside that if there is an exploit in the binary it can be used for privilege escalation, something that firejail had many issues with.

Today pretty much all applications use namespaces for their own sandboxing or for sandboxing other apps, more importantly it is used by both chrome/firefox and all electron apps for their internal sandbox.

Even if you think what ubuntu is doing here is right in some way, the current restriction is insanely flawed and can be exploited easily, not to mention that any possible exploit would require local access to the machine, **which is already very bad** since at that point any malware can do anything that the regular user of the system can, including deleting all of `HOME` contents or sending them to a random sever.

For more details see:

- <https://ubuntu.com/blog/ubuntu-23-10-restricted-unprivileged-user-namespaces>
- <https://seclists.org/oss-sec/2025/q1/253>
- <https://github.com/containers/bubblewrap/issues/505#issuecomment-2093203129>
- <https://github.com/linuxmint/mint22-beta/issues/82#issuecomment-2232827173>
- <https://github.com/ivan-hc/AM/blob/main/docs/troubleshooting.md#ubuntu-mess>
- <https://github.com/probonopd/go-appimage/issues/39#issuecomment-2849803316>

- [^1]: <https://github.com/AppImage/AppImageKit/issues/852>
- [^2]: <https://github.com/pkgforge-dev/ghostty-appimage/issues/20>
