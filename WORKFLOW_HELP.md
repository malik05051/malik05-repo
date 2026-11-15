# Updating and publishing packages by hand

Every package here is published the same way: change its `PKGBUILD` in this
repository and push to `main`. The push runs **Build and publish packages**,
which builds every package, signs them, and updates the `malik05` database.
Nothing reaches `pacman` until that run has finished and is green.

The commands below work in bash and fish.

## 1. Update the Limine fork from upstream

The fork is [Limine-extra](https://github.com/malik05051/Limine-extra). Its
working branch is `v12.x`.

### One-time setup

```console
git clone https://github.com/malik05051/Limine-extra
cd Limine-extra
git remote add upstream https://github.com/Limine-Bootloader/Limine.git
```

### Merge the new upstream release

```console
git switch v12.x
git pull
git fetch upstream
git merge upstream/v12.x
```

- **No conflicts:** git opens an editor for the merge message; save and close
  it.
- **Conflicts:** `git status` lists the files. In each one, keep both sides'
  changes and delete the `<<<<<<<`, `=======` and `>>>>>>>` lines. Then:

  ```console
  git add <file>
  git commit
  ```

- **Shortcut:** when GitHub says the fork has no conflicts, the **Sync fork**
  button on the repository page does the same merge. Then run `git pull` and
  carry on.

### Check that it builds

```console
./bootstrap
./configure --enable-werror --enable-uefi-x86-64 --enable-bios
make
```

`./bootstrap` needs network access, because it downloads Limine's
dependencies. A failure here usually means upstream renamed something our
extra code uses. Fix it before going further: the package build in step 3
would fail the same way.

### Push it

```console
git push origin v12.x
```

## 2. Tag the release

Use upstream's version number with `-extra` on the end:

| Situation | Tag | Package version |
| --- | --- | --- |
| New upstream release 12.9.7 | `v12.9.7-extra` | `2:12.9.7.extra-1` |
| A second release on the same upstream number | `v12.9.7-extra.2` | `2:12.9.7.extra-2` |
| A third | `v12.9.7-extra.3` | `2:12.9.7.extra-3` |

The second form uses a dot, not a hyphen (`-extra.2`, not `-extra-2`): the
release workflow rejects a second hyphen.

```console
git tag v12.9.7-extra
git push origin v12.9.7-extra
```

Add `-s` (`git tag -s`) if you sign your tags. Pushing the tag starts
Limine-extra's own release workflow, which builds the binary release. Its
**Actions** tab shows whether that worked. The pacman package does not depend
on it: it builds the source from the tag itself.

## 3. Publish to the pacman repository

In this repository, change one line in
[`limine-extra/PKGBUILD`](limine-extra/PKGBUILD) to the tag you just pushed:

```
_tag=v12.9.7-extra
```

Leave `pkgrel` and `epoch` alone: the version comes from the tag.

Then commit and push, either in GitHub's web editor (the pencil icon on the
file, then **Commit changes**) or with git:

```console
git clone https://github.com/malik05051/malik05-repo
cd malik05-repo
# edit limine-extra/PKGBUILD
git commit -am "limine-extra: Update to v12.9.7-extra"
git push
```

## 4. Wait for the build, then update

1. Open **Actions -> Build and publish packages** in this repository and wait
   until the run for your commit is green. It rebuilds every package, so it
   takes several minutes.
2. Check what the repository now offers:

   ```console
   sudo pacman -Sy
   pacman -Si limine-extra
   ```

3. Update:

   ```console
   sudo pacman -Syu
   ```

If limine-entry-tool (or limine-mkinitcpio-hook) is installed, its hook then
copies the new loader to the ESP and runs the signing your setup is configured
for. Without it, copy `/usr/share/limine/BOOTX64.EFI` to the ESP yourself. With Secure Boot on,
run `sudo sbctl verify` before rebooting. After the reboot,
`bootctl status` shows the new version.

## Other packages

All of them follow step 3: edit the `PKGBUILD`, push, wait for the green run.

| Package | Where the code lives | What to change in its `PKGBUILD` |
| --- | --- | --- |
| `limine-extra` | Limine-extra (tag) | `_tag=` |
| `limine-timeshift-sync` | [limine-timeshift-sync](https://github.com/malik05051/limine-timeshift-sync) (tag) | Push a new tag such as `v1.2.0` there first, then set `_tag=v1.2.0` and `pkgrel=1` |
| `neuralscreen` | [DLSS5-NeuralScreen-Linux](https://github.com/malik05051/DLSS5-NeuralScreen-Linux) (commit) | `_commit=` (the full hash) and `pkgver=1.8.2.r<count>.g<short hash>`, from `git rev-list --count <commit>` and `git rev-parse --short=7 <commit>` |
| `limine-entry-tool`, `limine-mkinitcpio-hook`, `limine-dracut-support` | Copies of the AUR packages | Replace all three `PKGBUILD`s with the new AUR ones together: they build from the same tag. Keep the comment at the top of each. |
| `m-alert` | [M-Alert](https://github.com/malik05051/M-Alert) (tag `v<pkgver>`) | Push the tag there first, then set `pkgver=`, `pkgrel=1`, and the first `sha256sums` entry (`makepkg -g` prints it) |

To rebuild a package without a code change (for example after a packaging
fix), raise its `pkgrel` by one. Otherwise pacman sees the same version and
does not update.

### Packages built somewhere else (`systemd-arab-edition`)

1. Open the
   [`repo` release](https://github.com/malik05051/malik05-repo/releases/tag/repo),
   edit it, and drop the `.pkg.tar.zst` files in.
2. Run **Actions -> Reindex the repository database -> Run workflow**.
   Unsigned files are signed during the reindex.

### Removing a package or going back a version

- **Remove:** run **Actions -> Remove a package** with its name. If it is built
  here, also delete its directory, or the next push brings it back.
- **Roll back:** delete the newer files from the `repo` release, then run
  **Reindex the repository database**.

## When the update does not show up

| Symptom | Cause | Fix |
| --- | --- | --- |
| Tag pushed, nothing changes | The package builds from `_tag` in the `PKGBUILD`, not from the newest tag | Step 3 |
| `PKGBUILD` pushed, still the old version | The build has not finished yet | Wait for the green run, then `sudo pacman -Syu` |
| Build run is red | The tag does not exist, or the source no longer builds | Open the failed run's log; check `git ls-remote --tags` for the tag |
| pacman still says "there is nothing to do" | Local database copy is stale | `sudo pacman -Syyu` |
| Version did not go up | `pkgrel` or the tag was not raised | Raise one of them and push again |
| "invalid or corrupted package (PGP signature)" | The repository key is not trusted | See "Using the repository" in [README.md](README.md) |
