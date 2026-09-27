# My repo that hosts my packages for Arch Linux

| Package | Built from | Description |
| --- | --- | --- |
| [`limine-extra`](limine-extra/) | this repository | [Limine](https://github.com/malik05051/Limine-systemd-bootctl) with systemd Boot Loader Interface support, so `bootctl` can see and drive it. Replaces Arch's `limine`. |
| [`limine-timeshift-sync`](limine-timeshift-sync/) | this repository | Lists Timeshift's btrfs snapshots in the Limine menu, each bootable with the kernel it was taken with, and restores them with that kernel put back. |
| `systemd-arab-edition` and friends | uploaded by hand | [systemd-arab-edition](https://github.com/malik05051/systemd-arab-edition), along with its `-libs`, `-resolvconf`, `-sysvcompat`, `-tests` and `-ukify` packages. |

## Using the repository

The packages and the database are signed. Import the key here :

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

Then:

```console
# pacman -Syu <package>
```

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

Packages uploaded to the release by hand are not indexed by that workflow,
which only sees what it built. Run **Reindex the repository database**
([`.github/workflows/reindex.yml`](.github/workflows/reindex.yml)) from the
Actions tab after such an upload: it rebuilds the database from every package
in the release, keeping the newest version of each.

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

To replace the key, generate a new one, put the armoured private key in
`GPG_PRIVATE_KEY`, delete the old `.sig` assets from the release, and run the
reindex; it re-signs everything that is missing a signature. Users then need to
`pacman-key --add` and `--lsign-key` the new one.
