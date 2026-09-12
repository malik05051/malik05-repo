# My Arch packages for systemd-arab-edition and the modified Limine with more SystemD's bootctl features.

A pacman repository, built by CI and published through GitHub Releases.

| Package | Built from | Description |
| --- | --- | --- |
| [`limine-systemd-bootctl`](limine-systemd-bootctl/) | this repository | [Limine](https://github.com/malik05051/Limine-systemd-bootctl) with systemd Boot Loader Interface support, so `bootctl` can see and drive it. Replaces Arch's `limine`. |
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

Then add this to the end of `/etc/pacman.conf`:

```ini
[malik05]
SigLevel = Required
Server = https://github.com/malik05051/malik05-repo/releases/download/repo
```

Arch's shipped `pacman.conf` already sets `SigLevel = Required
DatabaseOptional` globally, so the line can be left out entirely to inherit
that instead. Do not use `Optional` or `TrustAll` here: both tell pacman to
install whatever the release holds without checking who produced it.

Then:

```console
# pacman -Sy limine-systemd-bootctl
```

`limine-systemd-bootctl` sets `conflicts=('limine')`, so pacman will offer to
replace Arch's `limine` if it is installed. Both ship the same paths
(`/usr/bin/limine`, `/usr/share/limine/`), so nothing else needs changing.

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

`limine-systemd-bootctl` builds from a git tag rather than a branch, so the
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

`limine-systemd-bootctl` ships a pacman hook that will do it, and does nothing
at all until you configure it:

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
