# My Arch packages for systemd-arab-edition and the modified Limine with more SystemD's bootctl features.

A pacman repository, built by CI and published through GitHub Releases.

| Package | Built from | Description |
| --- | --- | --- |
| [`limine-systemd-bootctl`](limine-systemd-bootctl/) | this repository | [Limine](https://github.com/malik05051/Limine-systemd-bootctl) with systemd Boot Loader Interface support, so `bootctl` can see and drive it. Replaces Arch's `limine`. |
| `systemd-arab-edition` and friends | uploaded by hand | [systemd-arab-edition](https://github.com/malik05051/systemd-arab-edition), along with its `-libs`, `-resolvconf`, `-sysvcompat`, `-tests` and `-ukify` packages. |

## Using the repository

Add this to the end of `/etc/pacman.conf`:

```ini
[malik05]
SigLevel = Optional TrustAll
Server = https://github.com/malik05051/malik05-repo/releases/download/repo
```

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

> **`SigLevel = Optional TrustAll` is only correct while the packages are
> unsigned.** It tells pacman to install whatever the release holds without
> checking who produced it. Once signing is switched on (below), change that
> line to `SigLevel = Required` and import the key.

## How packages are built

Every directory holding a `PKGBUILD` is a package.
[`.github/workflows/build.yml`](.github/workflows/build.yml) builds all of
them in an `archlinux:base-devel` container on every push to `main`, weekly,
and on demand, then:

1. runs `makepkg -s` for each package,
2. adds the results to `malik05.db.tar.gz` with `repo-add`, carrying the
   published database forward so packages this run did not build keep their
   entries,
3. uploads the packages and the database to the `repo` release.

`.db` and `.files` are uploaded as copies of their `.tar.gz` counterparts,
because `repo-add` makes them symlinks and a release asset cannot be one.

The PKGBUILDs track git branches rather than tags, which is why the weekly
rebuild exists: it picks up commits made to those branches since the last run.

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

## Signing the packages

Signing is off until the `GPG_PRIVATE_KEY` secret exists; both workflows check
for it and publish unsigned otherwise. To turn it on:

1. Generate a signing key. Give it **no passphrase** — the workflows run
   unattended, and the repository secret is what protects it:

   ```console
   $ gpg --quick-generate-key 'malik05 repository <you@example.com>' \
       default default never
   $ gpg --export-secret-keys --armor <fingerprint>
   ```

2. Put that armoured private key in the repository's
   `GPG_PRIVATE_KEY` secret (Settings -> Secrets and variables -> Actions).

3. Run **Reindex the repository database** from the Actions tab. It signs every
   package that has no signature yet, including any uploaded by hand, signs the
   database, and publishes the public key as `malik05.asc` beside it.

Users then import the key once and tighten `SigLevel`:

```console
$ curl -LO https://github.com/malik05051/malik05-repo/releases/download/repo/malik05.asc
# pacman-key --add malik05.asc
# pacman-key --lsign-key <fingerprint>
```

```ini
[malik05]
SigLevel = Required
Server = https://github.com/malik05051/malik05-repo/releases/download/repo
```

If the key is ever exposed, revoke it, delete the secret, generate a new one
and run the reindex again; every signature in the release is replaced.
