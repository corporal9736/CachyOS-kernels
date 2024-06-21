# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v3

EAPI="8"
ETYPE="sources"
EXTRAVERSION="-cachyos"
K_EXP_GENPATCHES_NOUSE="1"
K_WANT_GENPATCHES="base extras"
# for this version please check the tag of
# https://gitweb.gentoo.org/proj/linux-patches.git
K_GENPATCHES_VER="5"

inherit kernel-2 optfeature
detect_version
# COMMIT of CachyOS/linux-cachyos: 7e32dd7248b977571499db2bee00192093160654
# This is the commit hash for Cachyos/kernel-patches
EGIT_COMMIT="50ecd23bb25a8144540815d800ddebced563ffda"

DESCRIPTION="CachyOS provides enhanced kernels that offer improved performance and other benefits."
HOMEPAGE="https://github.com/CachyOS/linux-cachyos"
SRC_URI="${KERNEL_URI} ${GENPATCHES_URI}
		https://github.com/CachyOS/kernel-patches/archive/${EGIT_COMMIT}.tar.gz -> ${PF}.tar.gz"

LICENSE="GPL-3"
KEYWORDS="~amd64"
IUSE="+bore-sched-ext eevdf bore rt-eevdf rt-bore sched-ext echo"
REQUIRED_USE="^^ ( bore-sched-ext eevdf bore rt-eevdf rt-bore sched-ext echo )"

PATCH_DIR="${WORKDIR}/patches"
CONFIG_DIR="${FILESDIR}/${KV_MAJOR}.${KV_MINOR}"

src_unpack() {
	# here kernel-2_src_unpack doesn't handle unpacking the cachyos patches.
	# manually unpack and move to $PATCH_PATH
	kernel-2_src_unpack
	unpack ${PF}.tar.gz
	mv kernel-patches-${EGIT_COMMIT}/${KV_MAJOR}.${KV_MINOR} ${PATCH_DIR}
	rm -r "kernel-patches-${EGIT_COMMIT}"
}

src_prepare() {
	eapply "${PATCH_DIR}/all/0001-cachyos-base-all.patch"

	if use bore-sched-ext; then
		eapply "${PATCH_DIR}/sched/0001-sched-ext.patch"
		eapply "${PATCH_DIR}/sched/0001-bore-cachy-ext.patch"
		cp "${CONFIG_DIR}/config-cachyos" .config
	fi

	if use eevdf; then
		cp "${CONFIG_DIR}/config-cachyos-eevdf" .config
	fi

	if use bore; then
		eapply "${PATCH_DIR}/sched/0001-bore-cachy.patch"
		cp "${CONFIG_DIR}/config-cachyos-bore" .config
	fi

	if use rt-eevdf; then
		eapply "${PATCH_DIR}/misc/0001-rt.patch"
		cp "${CONFIG_DIR}/config-cachyos-rt" .config
	fi

	if use rt-bore; then
		eapply "${PATCH_DIR}/misc/0001-rt.patch"
		eapply "${PATCH_DIR}/sched/0001-bore-cachy-rt.patch"
		cp "${CONFIG_DIR}/config-cachyos-rt-bore" .config
	fi

	if use sched-ext; then
		eapply "${PATCH_DIR}/sched/0001-sched-ext.patch"
		cp "${CONFIG_DIR}/config-cachyos-sched-ext" .config
	fi

	if use echo; then
		eapply "${PATCH_DIR}/sched/0001-echo-cachy.patch"
		cp "${CONFIG_DIR}/config-cachyos-echo" .config
	fi

	eapply_user

	sh "${FILESDIR}/${KV_MAJOR}.${KV_MINOR}/auto-cpu-optimization.sh"

	# The following config options are from https://github.com/CachyOS/linux-cachyos
	# You can change any of them using `make menuconfig`. These are defaults.
	# No use flag will be added to control these options. Just change by yourself.

	# Enable CachyOS tweaks
	scripts/config -e CACHY

	# Remove CachyOS's localversion
	find . -name "localversion*" -delete
	scripts/config -u LOCALVERSION

	# Set cpu scheduler
	use bore-sched-ext && scripts/config -e SCHED_CLASS_EXT -e SCHED_BORE
	use bore && scripts/config -e SCHED_BORE
	use rt-eevdf && scripts/config -e PREEMPT_COUNT -e PREEMPTION \
		-d PREEMPT_VOLUNTARY -d PREEMPT -d PREEMPT_NONE -e PREEMPT_RT \
		-e PREEMPT_AUTO -d PREEMPT_DYNAMIC -e HAVE_PREEMPT_AUTO \
		-d PREEMPT_BUILD
	use rt-bore && scripts/config -e SCHED_BORE -e PREEMPT_COUNT \
		-e PREEMPTION -d PREEMPT_VOLUNTARY -d PREEMPT -d PREEMPT_NONE \
		-e PREEMPT_RT -e PREEMPT_AUTO -d PREEMPT_DYNAMIC \
		-e HAVE_PREEMPT_AUTO -d PREEMPT_BUILD
	use sched-ext && scripts/config -e SCHED_CLASS_EXT
	use echo && scripts/config -e ECHO_SCHED
	# no special set for eevdf

	# kCFI is only available in llvm 16
	# Enable kCFI
	# scripts/config -e ARCH_SUPPORTS_CFI_CLANG -e CFI_CLANG

	# Set tick rate
	(! use echo) &&
		scripts/config -d HZ_300 -e HZ_1000 --set-val HZ 1000
	(use echo) &&
		scripts/config -d HZ_300 -e HZ_625 --set-val HZ 625

	# Disable NUMA
	scripts/config -d NUMA \
		-d AMD_NUMA \
		-d X86_64_ACPI_NUMA \
		-d NODES_SPAN_OTHER_NODES \
		-d NUMA_EMU \
		-d USE_PERCPU_NUMA_NODE_ID \
		-d ACPI_NUMA \
		-d ARCH_SUPPORTS_NUMA_BALANCING \
		-d NODES_SHIFT \
		-u NODES_SHIFT \
		-d NEED_MULTIPLE_NODES \
		-d NUMA_BALANCING \
		-d NUMA_BALANCING_DEFAULT_ENABLED

	# Set NR_CPUS
	scripts/config --set-val NR_CPUS 320

	# Set cpufreq governor to performance
	scripts/config -d CPU_FREQ_DEFAULT_GOV_SCHEDUTIL \
		-e CPU_FREQ_DEFAULT_GOV_PERFORMANCE

	# Set tick type
	use rt-eevdf && scripts/config -d HZ_PERIODIC \
		-d NO_HZ_FULL \
		-e NO_HZ_IDLE \
		-e NO_HZ \
		-e NO_HZ_COMMON
	(! use rt-eevdf) && scripts/config -d HZ_PERIODIC \
		-d NO_HZ_IDLE \
		-d CONTEXT_TRACKING_FORCE \
		-e NO_HZ_FULL_NODEF \
		-e NO_HZ_FULL \
		-e NO_HZ \
		-e NO_HZ_COMMON \
		-e CONTEXT_TRACKING

	# Enable O3 optimization
	scripts/config -d CC_OPTIMIZE_FOR_PERFORMANCE \
		-e CONFIG_CC_OPTIMIZE_FOR_SIZE

	# Disable CUBIC and enable bbr3
	scripts/config -m TCP_CONG_CUBIC \
		-d DEFAULT_CUBIC \
		-e TCP_CONG_BBR \
		-e DEFAULT_BBR \
		--set-str DEFAULT_TCP_CONG bbr

	# Set hugepage
	scripts/config -d TRANSPARENT_HUGEPAGE_MADVISE -e TRANSPARENT_HUGEPAGE_ALWAYS

	# Enable DAMON
	scripts/config -e DAMON \
		-e DAMON_VADDR \
		-e DAMON_DBGFS \
		-e DAMON_SYSFS \
		-e DAMON_PADDR \
		-e DAMON_RECLAIM \
		-e DAMON_LRU_SORT

	# Enable USER_NS_UNPRIVILEGED
	scripts/config -e USER_NS

	# These are gentoo specific configs
	scripts/config --set-str DEFAULT_HOSTNAME "gentoo"
	scripts/config -e GENTOO_LINUX
	scripts/config -e GENTOO_LINUX_INIT_SYSTEMD

	# Miscellaneous
	scripts/config -d DRM_SIMPLEDRM
	scripts/config --set-str CONFIG_LSM "lockdown,yama,integrity,selinux,apparmor,bpf,landlock"
}

pkg_postinst() {
	kernel-2_pkg_postinst

	optfeature "userspace KSM helper" sys-process/uksmd
	optfeature "auto nice daemon" app-admin/ananicy-cpp
}

pkg_postrm() {
	kernel-2_pkg_postrm
}
