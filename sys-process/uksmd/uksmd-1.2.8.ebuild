# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v3

EAPI=8

inherit linux-info meson systemd

DESCRIPTION="Userspace KSM helper daemon"
HOMEPAGE="https://github.com/CachyOS/uksmd"
SRC_URI="https://github.com/CachyOS/uksmd/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"

DEPEND="sys-libs/libcap-ng
	sys-process/procps:="
RDEPEND="${DEPEND}"

CONFIG_CHECK="~KSM"

src_install() {
	meson_src_install

	newinitd "${FILESDIR}/uksmd.init" uksmd
	systemd_dounit uksmd.service
}
