# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
COMMIT="3dafc3eb667b6ed7024359de78bf961c7248954d"

DESCRIPTION="List of rules used to assign specific nice values to specific processes
			maintained by cachyos teams"
HOMEPAGE="https://github.com/CachyOS/ananicy-rules"
SRC_URI="https://github.com/CachyOS/ananicy-rules/archive/${COMMIT}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/${PN}-${COMMIT}"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"

DEPEND="app-admin/ananicy-cpp"
RDEPEND="${DEPEND}"

src_install() {
	insinto /etc
	mv "${WORKDIR}/ananicy-rules-${COMMIT}" "${WORKDIR}/ananicy.d"
	doins -r "${WORKDIR}/ananicy.d"
}
