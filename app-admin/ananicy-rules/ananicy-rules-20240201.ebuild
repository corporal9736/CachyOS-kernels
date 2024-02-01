# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
COMMIT="03069296da72c511b55cc5fdb96a1035c7701dbf"

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
