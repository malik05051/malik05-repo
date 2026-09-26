# My Arch packages for systemd-arab-edition and the modified Limine with more SystemD's bootctl features.

A pacman repository, built by CI and published through GitHub Releases.

| Package | Built from | Description |
| --- | --- | --- |
| [`limine`](limine/) | this repository | [Limine](https://github.com/malik05051/Limine-systemd-bootctl) with systemd Boot Loader Interface support, so `bootctl` can see and drive it. Replaces Arch's `limine` under the same name. |
| [`limine-timeshift-sync`](limine-timeshift-sync/) | this repository | Lists Timeshift's btrfs snapshots in the Limine menu, each bootable with the kernel it was taken with, and restores them with that kernel put back. |
| `systemd-arab-edition` and friends | uploaded by hand | [systemd-arab-edition](https://github.com/malik05051/systemd-arab-edition), along with its `-libs`, `-resolvconf`, `-sysvcompat`, `-tests` and `-ukify` packages. |

## Using the repository

The packages and the database are signed. Import the key once, and tell
pacman you trust it:

```console
$ curl -LO https://github.com/malik05051/malik05-repo/releases/download/repo/malik05.asc
# pacman-key --add malik05.asc
# pacman-key --lsign-key 9EB820E32291639E0E8A8516B6B763F6A4C101F8
```

`--lsign-key` is the step that makes the key trusted; without it pacman
rejects every package as coming from an unknown signer.

Then add this to `/etc/pacman.conf`, **above** `[core]`:

```ini
[malik05]
SigLevel = Required
Server = https://github.com/malik05051/malik05-repo/releases/download/repo
```

Its place matters because pacman takes a package from the first repository
that lists its name, and this repository's `limine` shares its name with
Arch's. Listed below `[extra]`, Arch's would be installed instead, and an
installed copy of this one would never be offered an update. The other
packages here have names of their own and are unaffected by the order.

Arch's shipped `pacman.conf` already sets `SigLevel = Required
DatabaseOptional` globally, so the line can be left out entirely to inherit
that instead. Do not use `Optional` or `TrustAll` here: both tell pacman to
install whatever the release holds without checking who produced it.

Then:

```console
# pacman -Syu limine
```

This package is called `limine`, like Arch's, so it takes the place of Arch's
and every pacman hook written for Arch's package fires for it too: the one
limine-entry-tool uses to deploy the loader, the one the ArchWiki suggests,
and any of your own. Nothing needs setting up beyond what Arch's `limine`
needed.

### Coming from `limine-systemd-bootctl`

This package used to be called `limine-systemd-bootctl`. Move `[malik05]`
above `[core]` as shown above, then `pacman -Syu` offers to replace it with
`limine`. Hooks you added only because of the old name, such as an
`/etc/pacman.d/hooks/9x-limine-systemd-bootctl.hook` running `limine-install`,
or a `Target = limine-systemd-bootctl` line, can go: the hooks targeting
`limine` now cover it.

The release also still carries the older `arab.db`, which indexes the
`systemd-arab-edition` packages alone. It is left in place so that anyone
already pointing pacman at `[arab]` keeps working; `[malik05]` supersedes it
and indexes everything.

## How packages are built

Every directory holding a `PKGBUILD` is a package.
[`.github/workflows/build.yml`](.github/workflows/build.yml) builds all of
them in an `archlinux:base-devel` container on every push to `main` and on
demand, then:

1. runs `makepkg -s` for each package,
2. adds the results to `malik05.db.tar.gz` with `repo-add`, carrying the
   published database forward so packages this run did not build keep their
   entries,
3. uploads the packages and the database to the `repo` release.

`.db` and `.files` are uploaded as copies of their `.tar.gz` counterparts,
because `repo-add` makes them symlinks and a release asset cannot be one.

`limine` builds from a git tag rather than a branch, so the
package is reproducible and the version the loader reports is stable. Shipping
new work therefore means tagging the fork and bumping `_tag` in the PKGBUILD;
commits pushed to `v12.x` alone change nothing here.

Packages uploaded to the release by hand are not indexed by that workflow,
which only sees what it built. Run **Reindex the repository database**
([`.github/workflows/reindex.yml`](.github/workflows/reindex.yml)) from the
Actions tab after such an upload: it rebuilds the database from every package
in the release, keeping the newest version of each.

## Adding a package

Create a directory named after the package with a `PKGBUILD` in it and push to
`main`. Nothing else needs registering.

## Keeping the ESP up to date

`pacman -S` writes `/usr/share/limine/` and nothing else. The binaries the
firmware actually loads are separate copies on the ESP, so an upgrade does not
reach them until something copies them across.

Whatever deploys Arch's `limine` on your machine deploys this one, since the
hooks match it by name. With limine-entry-tool (installed alongside
`limine-snapper-sync`, `limine-mkinitcpio-hook` and `limine-dracut-support`),
every install and upgrade runs `limine-install`, which copies the loader to
`EFI/limine/limine_x64.efi`, refreshes the backup `limine-snapper-sync`
restores, enrols the config and signs the loader if configured, and registers
a UEFI boot entry if there is none. With the ArchWiki's `99-limine.hook`, that
hook copies it.

If nothing does, this package can copy the loader itself, but does nothing
until you configure it:

```console
# cp /usr/share/doc/limine/limine-esp-sync.conf.example /etc/limine-esp-sync.conf
# $EDITOR /etc/limine-esp-sync.conf
```

Set `TARGETS` to the paths on your ESP and `SIGN_COMMAND` to whatever signs an
EFI binary on your machine (empty if you do not use Secure Boot). From then on
every upgrade of the package copies the new loader across.

Each file is signed under a temporary name and renamed into place only once
that has succeeded, so a signing failure leaves the loader you are currently
booting exactly where it was. The hook reports the failure and pacman shows it,
rather than leaving you with an image the firmware will refuse.

Every destination is read back and compared against what was written to it. A
rename that reports success and leaves something else behind is how a machine
ends up booting a loader nobody installed, so the hook checks rather than
assumes, and fails the transaction if the two do not match.

Do not use both on a machine running `limine-snapper-sync`: it restores its own
backup of the loader on every snapshot, and only `limine-install` refreshes
that backup. A loader copied by this hook would be replaced by the older one at
the next snapshot. Leave `TARGETS` empty there, or remove
`/etc/limine-esp-sync.conf`.

## Booting Timeshift snapshots

`limine-timeshift-sync` keeps a `/Timeshift snapshots` entry in `limine.conf`
with one sub-entry per snapshot, newest first. It needs Timeshift in btrfs
mode, which in turn needs the `@` / `@home` subvolume layout.

```console
# pacman -S limine-timeshift-sync
# limine-timeshift-sync --dry-run
# systemctl enable --now limine-timeshift-sync.timer
```

`--dry-run` prints the entry it would write and changes nothing; run it first.
After that, entries are kept current by two pacman hooks and an hourly timer.
`limine-timeshift-sync --remove` takes the entry out again.

**Kernels.** A snapshot captures `/usr/lib/modules` but not the kernel on the
ESP, and booting it with a newer kernel leaves its modules unloadable. Each
snapshot's kernel, initramfs and microcode are therefore copied to
`limine_timeshift/` on the ESP, taken from the `limine.conf` entry that boots
that kernel today, and the command line comes from the same entry with the
root subvolume pointed at the snapshot. The pre-transaction hook runs after
`timeshift-autosnap` and before a kernel upgrade removes the old kernel, so
the snapshot taken just before an upgrade can still be booted after it.

A snapshot taken before this package was installed can only be given an entry
if its kernel is still on the ESP; otherwise it is skipped with a message.

**Secure Boot.** Every path is pinned by its BLAKE2b hash, which Limine
requires once a config hash is enrolled. If the loader is enrolled, the tool
runs `limine-enroll-config` after changing `limine.conf`, then checks that the
loader now accepts the file on disk. If it does not, the previous
`limine.conf` is put back: a mismatch would make Limine refuse to boot at all.
If enrolment is needed but `limine-enroll-config` is missing, nothing is
changed.

**limine-snapper-sync.** Both tools can run on one machine. They take the same
lock before touching the ESP, and each leaves the other's entry alone. Running
Timeshift and snapper on the same filesystem is still not advisable: both
restore by replacing `@`, and neither knows about the other's snapshots.

**Booting a snapshot.** Booting a snapshot entry is only temporary: the next
normal boot is your installed system again. Timeshift's snapshots are
writable, so booting one also changes it. Only `@` comes from the snapshot;
`/home` is always the current one.

**Snapshot detected!** Log in to a desktop while booted into a snapshot and a
notification says so, with a **Restore now** button. It needs `libnotify`, and
`polkit` to ask for the password graphically.

**Restoring.** `limine-timeshift-restore` restores the snapshot you are booted
into, or asks which one if you are not (it is also in the application menu as
*Restore Timeshift snapshot*):

```console
$ limine-timeshift-restore
$ limine-timeshift-restore 2026-09-26_12-24-42
```

It shows the snapshot's date, tags, comment and kernels, and whether
Timeshift will replace `/home` too (`include_btrfs_home_for_restore` in
Timeshift's settings). Then it asks for confirmation, runs
`timeshift --restore --skip-grub`, and offers to reboot. Timeshift does the
restore itself, keeping the system it replaces as a new snapshot. Restoring
from Timeshift's own window works the same way.

**Kernels after a restore.** A restored system has the kernel modules it was
snapshotted with, but the ESP holds whatever kernel was installed last.
Booting that newer kernel against older modules leaves drivers unloadable.
Timeshift runs `/etc/timeshift/restore-hooks.d/limine-timeshift-sync` after
every restore. That hook puts the kernel and initramfs the snapshot was taken
with back into the `limine.conf` entries they came from, updates their hashes,
and re-enrols the config. If the loader would refuse the result, the old
files and config go back. The kernels being replaced are kept first, so the
snapshot Timeshift took before restoring stays bootable from the menu. A
kernel that was never kept on the ESP cannot be put back; the hook says so,
and reinstalling the kernel package after the reboot fixes it.

## Multi-profile UKIs

A multi-profile UKI holds several command lines (normal boot, emergency
shell, ...) under one signature. Limine can list each profile after `@0` as a
menu entry of its own, but only for entries that opt in with
`uki_profiles: yes`. This repository's `limine` ships `limine-uki-profiles` to
set that option safely:

```console
# limine-uki-profiles check "Arch Linux (UKI)"
# limine-uki-profiles enable "Arch Linux (UKI)"
# limine-uki-profiles disable "Arch Linux (UKI)"
```

`check` lists the entries that would be added and what could go wrong;
`enable` runs the same checks and asks you to type `yes` before touching
`limine.conf`. It refuses outright when the entry would not boot or the option
would do nothing: not a `protocol: efi` entry, a file that is missing, not a
multi-profile UKI, or not matching the hash in its path, a command line
already pinned to a profile (`@N`), an unsigned UKI with Secure Boot on, or an
enrolled config with no `limine-enroll-config` to re-enrol it. It warns, and
still asks, when:

- the Limine on the ESP predates `uki_profiles` and will ignore it;
- `default_entry` is an index, which the added entries shift;
- an added entry's title matches an existing one;
- Secure Boot is on and the UKI has a built-in command line, so the entry's
  own `cmdline` is ignored;
- `limine-snapper-sync` is installed: its snapshot entries may copy the
  option, and with Secure Boot on and a built-in command line they boot the
  live system rather than the snapshot;
- `limine-timeshift-sync` is installed: it makes no snapshot entries for UKIs.

An enrolled config is re-enrolled afterwards and checked against the loader;
if the loader does not accept the new file, the old one is put back.

## Signing the packages

Every package and the database are signed by
`9EB820E32291639E0E8A8516B6B763F6A4C101F8`, whose armoured private key lives in
the repository's `GPG_PRIVATE_KEY` secret. The key carries no passphrase,
because the workflows run unattended; the secret is what protects it.

Both workflows check for that secret and publish unsigned if it is missing, so
signing fails open rather than breaking a build. A green run therefore does not
prove anything was signed; the release itself does:

```console
$ gpg --verify malik05.db.sig malik05.db
```

**Reindex the repository database** signs every package that has no signature
yet, including any uploaded by hand, signs the database, and publishes the
public key as `malik05.asc` beside it. Run it from the Actions tab after
uploading a package by hand, or after replacing the key.

`repo-add` no longer records package signatures inside the database, so pacman
fetches `<package>.sig` from the release. Both are published for every package;
neither is any use without the other.

To replace the key, generate a new one, put the armoured private key in
`GPG_PRIVATE_KEY`, delete the old `.sig` assets from the release, and run the
reindex; it re-signs everything that is missing a signature. Users then need to
`pacman-key --add` and `--lsign-key` the new one.
