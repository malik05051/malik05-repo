# Maintainer: malik05051 <belhajjimalik1@gmail.com>

pkgname=limine-timeshift-sync
pkgver=1.1.0
pkgrel=1
pkgdesc='Boot Timeshift btrfs snapshots from the Limine menu'
arch=('any')
url='https://github.com/malik05051/malik05-repo'
license=('BSD-2-Clause')
depends=('bash' 'coreutils' 'util-linux' 'gawk' 'findutils' 'grep' 'sed' 'timeshift')
optdepends=('timeshift-autosnap: take a snapshot before every upgrade'
            'libnotify: the notification when booted into a snapshot'
            'polkit: asking for the password graphically when restoring')
backup=('etc/limine-timeshift-sync.conf')
install=limine-timeshift-sync.install
source=('limine-timeshift-sync'
        'limine-timeshift-sync.conf'
        '06-limine-timeshift-sync-pre.hook'
        '97-limine-timeshift-sync.hook'
        'limine-timeshift-sync.service'
        'limine-timeshift-sync.timer'
        'limine-timeshift-restore'
        'timeshift-restore-hook'
        'limine-timeshift-restore.desktop'
        'limine-timeshift-restore-notify.desktop')
sha256sums=('013a7de9edf690d746cc389080bd60ee78bfca12516a515b156c12b6c0554078'
            'c9138bbfcb79148dd377f5a5bd807740f5cae687c3b2787752a68c3dcaaf54f8'
            '60cbad494c2c3495a2e00c10a8c68c79bc7ddffb61bc934bb66ddd74fe0277c7'
            'fffbbb801a9d0518b47634af28d8fbfd9a9eb38bdd1849f22e96ffc4d41f7ffb'
            'f0035ecf2a4ecc20d017d43d1c789a067eef213ba527d6d83c58489f44dc820f'
            'bf061f52db0fb21bb58f18cc84aa9930ff8bc518424e3822560ab5423031c1b8'
            'c391ad477e7b5e1333db4c45f2a1e613044d06114516c798e44d75b0bd323e35'
            'b78ae4d1568d46bd2aad2331e017e094e4ab57afc12eda9aa9b9644ffa0d18ae'
            'b64b547f3d14f120fde20885d65782a0585daab4cf208cff1442995ed5bd9bb8'
            '956818de0c93a31648dae3bc1d8df547f372d351059ea7626ffb022d9cd9b02c')

package() {
    install -Dm0755 limine-timeshift-sync "${pkgdir}/usr/bin/limine-timeshift-sync"
    install -Dm0644 limine-timeshift-sync.conf "${pkgdir}/etc/limine-timeshift-sync.conf"
    install -Dm0644 06-limine-timeshift-sync-pre.hook "${pkgdir}/usr/share/libalpm/hooks/06-limine-timeshift-sync-pre.hook"
    install -Dm0644 97-limine-timeshift-sync.hook "${pkgdir}/usr/share/libalpm/hooks/97-limine-timeshift-sync.hook"
    install -Dm0644 limine-timeshift-sync.service "${pkgdir}/usr/lib/systemd/system/limine-timeshift-sync.service"
    install -Dm0644 limine-timeshift-sync.timer "${pkgdir}/usr/lib/systemd/system/limine-timeshift-sync.timer"
    install -Dm0755 limine-timeshift-restore "${pkgdir}/usr/bin/limine-timeshift-restore"
    # Timeshift only looks for restore hooks here.
    install -Dm0755 timeshift-restore-hook "${pkgdir}/etc/timeshift/restore-hooks.d/limine-timeshift-sync"
    install -Dm0644 limine-timeshift-restore.desktop "${pkgdir}/usr/share/applications/limine-timeshift-restore.desktop"
    install -Dm0644 limine-timeshift-restore-notify.desktop "${pkgdir}/etc/xdg/autostart/limine-timeshift-restore-notify.desktop"
}
