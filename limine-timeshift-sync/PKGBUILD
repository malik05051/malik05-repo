# Maintainer: malik05051 <belhajjimalik1@gmail.com>

pkgname=limine-timeshift-sync
pkgver=1.0.0
pkgrel=1
pkgdesc='Boot Timeshift btrfs snapshots from the Limine menu'
arch=('any')
url='https://github.com/malik05051/malik05-repo'
license=('BSD-2-Clause')
depends=('bash' 'coreutils' 'util-linux' 'gawk' 'findutils' 'grep' 'sed' 'timeshift')
optdepends=('timeshift-autosnap: take a snapshot before every upgrade')
backup=('etc/limine-timeshift-sync.conf')
install=limine-timeshift-sync.install
source=('limine-timeshift-sync'
        'limine-timeshift-sync.conf'
        '06-limine-timeshift-sync-pre.hook'
        '97-limine-timeshift-sync.hook'
        'limine-timeshift-sync.service'
        'limine-timeshift-sync.timer')
sha256sums=('6cfb7f8e46d01340380947f95a562874bc5cd7818f53868de38ad1dfcab93470'
            'c9138bbfcb79148dd377f5a5bd807740f5cae687c3b2787752a68c3dcaaf54f8'
            '60cbad494c2c3495a2e00c10a8c68c79bc7ddffb61bc934bb66ddd74fe0277c7'
            'fffbbb801a9d0518b47634af28d8fbfd9a9eb38bdd1849f22e96ffc4d41f7ffb'
            'f0035ecf2a4ecc20d017d43d1c789a067eef213ba527d6d83c58489f44dc820f'
            'bf061f52db0fb21bb58f18cc84aa9930ff8bc518424e3822560ab5423031c1b8')

package() {
    install -Dm0755 limine-timeshift-sync "${pkgdir}/usr/bin/limine-timeshift-sync"
    install -Dm0644 limine-timeshift-sync.conf "${pkgdir}/etc/limine-timeshift-sync.conf"
    install -Dm0644 06-limine-timeshift-sync-pre.hook "${pkgdir}/usr/share/libalpm/hooks/06-limine-timeshift-sync-pre.hook"
    install -Dm0644 97-limine-timeshift-sync.hook "${pkgdir}/usr/share/libalpm/hooks/97-limine-timeshift-sync.hook"
    install -Dm0644 limine-timeshift-sync.service "${pkgdir}/usr/lib/systemd/system/limine-timeshift-sync.service"
    install -Dm0644 limine-timeshift-sync.timer "${pkgdir}/usr/lib/systemd/system/limine-timeshift-sync.timer"
}
