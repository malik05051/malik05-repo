# My repo that hosts my packages for Arch Linux

This repository's `repo` release holds only the pacman database. Each package
is published in the `pacman` release of its own project, as
[`releases.conf`](releases.conf) maps it.

| Package | Description |
| --- | --- |
| [`limine-extra`](limine-extra/) | [Limine](https://github.com/malik05051/Limine-extra) with systemd Boot Loader Interface support, so `bootctl` can see and drive it. Replaces Arch's `limine`. |
| [`limine-timeshift-sync`](limine-timeshift-sync/) | [limine-timeshift-sync](https://github.com/malik05051/limine-timeshift-sync): lists Timeshift's btrfs snapshots in the Limine menu, each bootable with the kernel it was taken with, and restores them with that kernel put back. |
| [`neuralscreen`](neuralscreen/) | [DLSS5-NeuralScreen-Linux](https://github.com/malik05051/DLSS5-NeuralScreen-Linux): NVIDIA's DLSS 5 neural renderer applied to the whole Wayland desktop. Its debug symbols are in `neuralscreen-debug`. |
| `systemd-arab-edition` and friends | [systemd-arab-edition](https://github.com/malik05051/systemd-arab-edition), along with its `-libs`, `-resolvconf`, `-sysvcompat`, `-tests` and `-ukify` packages. |

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
CacheServer = https://github.com/malik05051/Limine-extra/releases/download/pacman
CacheServer = https://github.com/malik05051/limine-timeshift-sync/releases/download/pacman
CacheServer = https://github.com/malik05051/DLSS5-NeuralScreen-Linux/releases/download/pacman
CacheServer = https://github.com/malik05051/systemd-arab-edition/releases/download/pacman
```

`Server` is where the database is; pacman looks for the packages in the
`CacheServer` releases, and does not report the ones that lack a package. This
needs pacman 6.1 or newer.

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
2. uploads each package to the `pacman` release of the project
   `releases.conf` names for it,
3. adds the results to `malik05.db.tar.gz` with `repo-add`, carrying the
   published database forward so packages this run did not build keep their
   entries,
4. uploads the database to the `repo` release.

`.db` and `.files` are uploaded as copies of their `.tar.gz` counterparts,
because `repo-add` makes them symlinks and a release asset cannot be one.

Packages uploaded by hand, such as `systemd-arab-edition`, go in their
project's `pacman` release, and are not indexed by that workflow, which only
sees what it built. Run **Reindex the repository database**
([`.github/workflows/reindex.yml`](.github/workflows/reindex.yml)) from the
Actions tab after such an upload: it rebuilds the database from every package
in the projects' releases, keeping the newest version of each. Packages still
in this repository's release are moved to their projects' releases and
deleted here.

Writing to the projects' releases needs a
[fine-grained token](https://github.com/settings/personal-access-tokens/new)
with **Contents: Read and write** on every repository in `releases.conf`,
stored as the `RELEASES_TOKEN` Actions secret. A new package also needs a line
in `releases.conf`.

## Managing packages

Everything is done from GitHub: pushes to this repository, the project
releases' pages, and the Actions tab.

- **Update a package built here**: edit its `PKGBUILD` (a new `pkgver`,
  `_tag` or `pkgrel`) and push. The build publishes it and updates the
  database.
- **Add a package built here**: add a directory with a `PKGBUILD` and a line
  in [`releases.conf`](releases.conf), then push.
- **Publish or update a package built elsewhere**, like `systemd-arab-edition`:
  upload the `.pkg.tar.zst` files to its project's `pacman` release (edit the
  release and drop them in), then run **Reindex the repository database**.
  Unsigned uploads get signed.
- **Remove a package**: run **Remove a package** with its name. It is taken
  out of the database and, unless you untick it, its files are deleted from
  its project's release. For a package built here, also delete its directory,
  or the next push brings it back.
- **Roll back to an older version**: delete the newer files from the
  project's release and run **Reindex the repository database**. It indexes
  the newest version left.

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
