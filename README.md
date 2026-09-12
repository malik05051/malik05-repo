# My Arch packages for systemd-arab-edition and the modified Limine with more SystemD's bootctl features.

A pacman repository, built by CI and published through GitHub Releases.

| Package | Description |
| --- | --- |
| [`limine-systemd-bootctl`](limine-systemd-bootctl/) | [Limine](https://github.com/malik05051/Limine-systemd-bootctl) with systemd Boot Loader Interface support, so `bootctl` can see and drive it. Replaces Arch's `limine`. |

## Using the repository

Add this to the end of `/etc/pacman.conf`:

```ini
[malik05]
SigLevel = Optional TrustAll
Server = https://github.com/malik05051/pacman-repo/releases/download/repo
```

Then:

```console
# pacman -Sy limine-systemd-bootctl
```

`limine-systemd-bootctl` sets `conflicts=('limine')`, so pacman will offer to
replace Arch's `limine` if it is installed. Both ship the same paths
(`/usr/bin/limine`, `/usr/share/limine/`), so nothing else needs changing.

> **The packages are not signed.** `SigLevel = Optional TrustAll` tells pacman
> to install them anyway. Transport is HTTPS, so this is not about
> eavesdropping; it means you are trusting that whatever the release holds was
> put there by this repository's CI and not by someone who got at the account.
> For a bootloader that is worth weighing. Signing is the fix, and the
> workflow has a place for it; see below.

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

## Adding a package

Create a directory named after the package with a `PKGBUILD` in it and push to
`main`. Nothing else needs registering.

## Signing the packages

The workflow does not sign anything yet. To change that: generate a signing
key, add its private half as a repository secret, have the build step pass
`--sign` to `makepkg` and `repo-add`, publish the public key, and have users
`pacman-key --add` it and switch the `SigLevel` above to `Required`.
