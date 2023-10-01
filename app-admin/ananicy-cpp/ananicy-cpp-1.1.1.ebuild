# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v3

EAPI=8
inherit cmake

DESCRIPTION="Ananicy rewritten in C++ for much lower CPU and memory usage (powered by CachyOS rules)"
HOMEPAGE="https://gitlab.com/ananicy-cpp/ananicy-cpp"
SRC_URI="https://gitlab.com/ananicy-cpp/ananicy-cpp/-/archive/v${PV}/${PN}-v${PV}.tar.bz2"
S="${WORKDIR}/${PN}-v${PV}"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"
IUSE="systemd"

RDEPEND="
	dev-cpp/nlohmann_json
	dev-libs/libfmt
	dev-libs/spdlog
	systemd? ( sys-apps/systemd )
"
DEPEND="
	${RDEPEND}
	sys-auth/rtkit
"
PDEPEND="
	app-admin/ananicy-rules
"

src_configure() {
	local mycmakeargs=(
		-DENABLE_SYSTEMD=$(usex systemd)
		-DUSE_EXTERNAL_FMTLIB=ON
		-DUSE_EXTERNAL_JSON=ON
		-DUSE_EXTERNAL_SPDLOG=ON
	)
	cmake_src_configure
}

src_install() {
	doinitd "${FILESDIR}/${PN}.initd"
	cmake_src_install
}
