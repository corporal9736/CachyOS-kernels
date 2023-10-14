# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v3

EAPI="8"
ETYPE="sources"
EXTRAVERSION="-cachyos"
K_EXP_GENPATCHES_NOUSE="1"
K_WANT_GENPATCHES="base extras"
# for this version please check the tag of
# https://anongit.gentoo.org/git/proj/linux-patches.git
K_GENPATCHES_VER="8"

inherit kernel-2 optfeature
detect_version
EGIT_COMMIT="7a9c5136fd51af000b4a994389ff3ef66f30d44c"

DESCRIPTION="CachyOS provides enhanced kernels that offer improved performance and other benefits."
HOMEPAGE="https://github.com/CachyOS/linux-cachyos"
SRC_URI="${KERNEL_URI} ${GENPATCHES_URI}
		https://github.com/CachyOS/kernel-patches/archive/${EGIT_COMMIT}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3"
KEYWORDS="~amd64"
IUSE="+bore-eevdf eevdf pds bmq tt bore cfs cfs-rt bore-hardened"
REQUIRED_USE="^^ ( bore-eevdf eevdf pds bmq tt bore cfs cfs-rt bore-hardened )"

PATCH_DIR="${WORKDIR}/patches"

src_unpack() {
	# here kernel-2_src_unpack doesn't handle unpacking the cachyos patches.
	# manually unpack and move to $PATCH_PATH
	kernel-2_src_unpack
	unpack ${P}.tar.gz
	mv kernel-patches-${EGIT_COMMIT}/${KV_MAJOR}.${KV_MINOR} ${PATCH_DIR}
	rm -r "kernel-patches-${EGIT_COMMIT}"
}

src_prepare() {
	eapply "${PATCH_DIR}/all/0001-cachyos-base-all.patch"

	if use bore-eevdf; then
		eapply "${PATCH_DIR}/sched/0001-EEVDF-cachy.patch"
		eapply "${PATCH_DIR}/sched/0001-bore-eevdf.patch"
		cp "${FILESDIR}/${KV_MAJOR}.${KV_MINOR}/config-cachyos" .config
	fi

	if use eevdf; then
		eapply "${PATCH_DIR}/sched/0001-EEVDF-cachy.patch"
		cp "${FILESDIR}/${KV_MAJOR}.${KV_MINOR}/config-cachyos-eevdf" .config
	fi

	if use pds; then
		eapply "${PATCH_DIR}/sched/0001-prjc-cachy.patch"
		cp "${FILESDIR}/${KV_MAJOR}.${KV_MINOR}/config-cachyos-pds" .config

	fi

	if use bmq; then
		eapply "${PATCH_DIR}/sched/0001-prjc-cachy.patch"
		cp "${FILESDIR}/${KV_MAJOR}.${KV_MINOR}/config-cachyos-bmq" .config
	fi

	if use tt; then
		eapply "${PATCH_DIR}/sched/0001-tt-cachy.patch"
		cp "${FILESDIR}/${KV_MAJOR}.${KV_MINOR}/config-cachyos-tt" .config

	fi

	if use bore; then
		eapply "${PATCH_DIR}/sched/0001-bore-cachy.patch"
		eapply "${PATCH_DIR}/misc/0001-bore-tuning-sysctl.patch"
		cp "${FILESDIR}/${KV_MAJOR}.${KV_MINOR}/config-cachyos-bore" .config
	fi

	if use cfs; then
		cp "${FILESDIR}/${KV_MAJOR}.${KV_MINOR}/config-cachyos-cfs" .config
	fi

	if use cfs-rt; then
		eapply "${PATCH_DIR}/sched/0001-rt.patch"
		cp "${FILESDIR}/${KV_MAJOR}.${KV_MINOR}/config-cachyos-rt" .config
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
	(use bore-eevdf || use eevdf || use bore-hardened) && scripts/config -e SCHED_BORE
	use pds && scripts/config -e SCHED_ALT -d SCHED_BMQ -e SCHED_PDS \
		-e PSI_DEFAULT_DISABLED
	use bmq && scripts/config -e SCHED_ALT -e SCHED_BMQ -d SCHED_PDS \
		-e PSI_DEFAULT_DISABLED
	use tt && scripts/config -e TT_SCHED -e TT_ACCOUNTING_STATS
	use cfs-rt && scripts/config -e PREEMPT_COUNT -e PREEMPTION \
		-d PREEMPT_VOLUNTARY -d PREEMPT -d PREEMPT_NONE -e PREEMPT_RT \
		-e PREEMPT_LAZY -d PREEMPT_DYNAMIC -e HAVE_PREEMPT_LAZY \
		-d PREEMPT_BUILD
	# no special set for cfs and eevdf

	# Enable kCFI
	scripts/config -e ARCH_SUPPORTS_CFI_CLANG -e CFI_CLANG

	# Set tick rate
	(use tt || use cfs-rt || use pds || use bmq) && scripts/config -d HZ_300 \
		-e HZ_1000 --set-val HZ 1000
	(use eevdf || use bore-eevdf || use bore-hardened || use bore || use cfs) &&
		scripts/config -d HZ_300 -e HZ_500 --set-val HZ 500

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
	use cfs-rt && scripts/config -d HZ_PERIODIC \
		-d NO_HZ_FULL \
		-e NO_HZ_IDLE \
		-e NO_HZ \
		-e NO_HZ_COMMON
	(! use cfs-rt) && scripts/config -d HZ_PERIODIC \
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

	# BBR3 doesn't work properly with FQ_CODEL
	scripts/config -m NET_SCH_FQ_CODEL \
		-e NET_SCH_FQ \
		-d DEFAULT_FQ_CODEL \
		-e DEFAULT_FQ \
		--set-str DEFAULT_NET_SCH fq

	# Set LRU
	scripts/config -e LRU_GEN -e LRU_GEN_ENABLED -d LRU_GEN_STATS

	# Set VMA
	scripts/config -e PER_VMA_LOCK -d PER_VMA_LOCK_STATS

	# Set hugepage
	scripts/config -d TRANSPARENT_HUGEPAGE_MADVISE -e TRANSPARENT_HUGEPAGE_ALWAYS

	# Disable debug
	scripts/config -d DEBUG_INFO \
		-d DEBUG_INFO_BTF \
		-d DEBUG_INFO_DWARF4 \
		-d DEBUG_INFO_DWARF5 \
		-d PAHOLE_HAS_SPLIT_BTF \
		-d DEBUG_INFO_BTF_MODULES \
		-d SLUB_DEBUG \
		-d PM_DEBUG \
		-d PM_ADVANCED_DEBUG \
		-d PM_SLEEP_DEBUG \
		-d ACPI_DEBUG \
		-d SCHED_DEBUG \
		-d LATENCYTOP \
		-d DEBUG_PREEMPT

	# Enable USER_NS_UNPRIVILEGED
	scripts/config -e USER_NS

	# These are gentoo specific configs
	scripts/config --set-str DEFAULT_HOSTNAME "gentoo"
	scripts/config -e GENTOO_LINUX
	scripts/config -e GENTOO_LINUX_INIT_SYSTEMD

	# Miscellaneous
	scripts/config -d DRM_SIMPLEDRM
	scripts/config --set-str CONFIG_LSM “lockdown,yama,integrity,selinux,apparmor,bpf,landlock”
}

pkg_postinst() {
	kernel-2_pkg_postinst

	optfeature "userspace KSM helper" sys-process/uksmd
	optfeature "auto nice daemon" app-admin/ananicy-cpp
}

pkg_postrm() {
	kernel-2_pkg_postrm
}
