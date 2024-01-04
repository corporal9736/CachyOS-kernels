# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v3

EAPI="8"
ETYPE="sources"
EXTRAVERSION="-cachyos"
K_EXP_GENPATCHES_NOUSE="1"
K_WANT_GENPATCHES="base extras"
# for this version please check the tag of
# https://anongit.gentoo.org/git/proj/linux-patches.git
K_GENPATCHES_VER="11"

inherit kernel-2 optfeature
detect_version
# COMMIT of CachyOS/linux-cachyos: f6088940c18ad59569a97299d66579c979d10cb3
# This is the commit hash for Cachyos/kernel-patches
EGIT_COMMIT="42315eb3f6a0dbf37e24c6e83f751a932e6c02a0"

DESCRIPTION="CachyOS provides enhanced kernels that offer improved performance and other benefits."
HOMEPAGE="https://github.com/CachyOS/linux-cachyos"
SRC_URI="${KERNEL_URI} ${GENPATCHES_URI}
		https://github.com/CachyOS/kernel-patches/archive/${EGIT_COMMIT}.tar.gz -> ${PF}.tar.gz"

LICENSE="GPL-3"
KEYWORDS="~amd64"
IUSE="+bore-eevdf eevdf bore rt-eevdf rt-bore sched-ext +bcachefs +lrng"
REQUIRED_USE="^^ ( bore-eevdf eevdf bore rt-eevdf rt-bore sched-ext )"

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

	if use bore-eevdf; then
		eapply "${PATCH_DIR}/sched/0001-bore-cachy.patch"
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
		eapply "${PATCH_DIR}/sched/0001-bore-cachy-ext.patch"
		cp "${CONFIG_DIR}/config-cachyos-sched-ext" .config
	fi

	if use bcachefs; then
		eapply "${PATCH_DIR}/misc/0001-bcachefs.patch"
		# here change BCACHEFS_FS from enable to module
		scripts/config -m BCACHEFS_FS \
			-e BCACHEFS_QUOTA \
			-e BCACHEFS_POSIX_ACL
	fi

	if use lrng; then
		eapply "${PATCH_DIR}/misc/0001-lrng.patch"
		scripts/config -d RANDOM_DEFAULT_IMPL \
			-e LRNG \
			-e LRNG_SHA256 \
			-e LRNG_COMMON_DEV_IF \
			-e LRNG_DRNG_ATOMIC \
			-e LRNG_SYSCTL \
			-e LRNG_RANDOM_IF \
			-e LRNG_AIS2031_NTG1_SEEDING_STRATEGY \
			-m LRNG_KCAPI_IF \
			-m LRNG_HWRAND_IF \
			-e LRNG_DEV_IF \
			-e LRNG_RUNTIME_ES_CONFIG \
			-e LRNG_IRQ_DFLT_TIMER_ES \
			-d LRNG_SCHED_DFLT_TIMER_ES \
			-e LRNG_TIMER_COMMON \
			-d LRNG_COLLECTION_SIZE_256 \
			-d LRNG_COLLECTION_SIZE_512 \
			-e LRNG_COLLECTION_SIZE_1024 \
			-d LRNG_COLLECTION_SIZE_2048 \
			-d LRNG_COLLECTION_SIZE_4096 \
			-d LRNG_COLLECTION_SIZE_8192 \
			--set-val LRNG_COLLECTION_SIZE 1024 \
			-e LRNG_HEALTH_TESTS \
			--set-val LRNG_RCT_CUTOFF 31 \
			--set-val LRNG_APT_CUTOFF 325 \
			-e LRNG_IRQ \
			-e LRNG_CONTINUOUS_COMPRESSION_ENABLED \
			-d LRNG_CONTINUOUS_COMPRESSION_DISABLED \
			-e LRNG_ENABLE_CONTINUOUS_COMPRESSION \
			-e LRNG_SWITCHABLE_CONTINUOUS_COMPRESSION \
			--set-val LRNG_IRQ_ENTROPY_RATE 256 \
			-e LRNG_JENT \
			--set-val LRNG_JENT_ENTROPY_RATE 16 \
			-e LRNG_CPU \
			--set-val LRNG_CPU_FULL_ENT_MULTIPLIER 1 \
			--set-val LRNG_CPU_ENTROPY_RATE 8 \
			-e LRNG_SCHED \
			--set-val LRNG_SCHED_ENTROPY_RATE 4294967295 \
			-e LRNG_DRNG_CHACHA20 \
			-m LRNG_DRBG \
			-m LRNG_DRNG_KCAPI \
			-e LRNG_SWITCH \
			-e LRNG_SWITCH_HASH \
			-m LRNG_HASH_KCAPI \
			-e LRNG_SWITCH_DRNG \
			-m LRNG_SWITCH_DRBG \
			-m LRNG_SWITCH_DRNG_KCAPI \
			-e LRNG_DFLT_DRNG_CHACHA20 \
			-d LRNG_DFLT_DRNG_DRBG \
			-d LRNG_DFLT_DRNG_KCAPI \
			-e LRNG_TESTING_MENU \
			-d LRNG_RAW_HIRES_ENTROPY \
			-d LRNG_RAW_JIFFIES_ENTROPY \
			-d LRNG_RAW_IRQ_ENTROPY \
			-d LRNG_RAW_RETIP_ENTROPY \
			-d LRNG_RAW_REGS_ENTROPY \
			-d LRNG_RAW_ARRAY \
			-d LRNG_IRQ_PERF \
			-d LRNG_RAW_SCHED_HIRES_ENTROPY \
			-d LRNG_RAW_SCHED_PID_ENTROPY \
			-d LRNG_RAW_SCHED_START_TIME_ENTROPY \
			-d LRNG_RAW_SCHED_NVCSW_ENTROPY \
			-d LRNG_SCHED_PERF \
			-d LRNG_ACVT_HASH \
			-d LRNG_RUNTIME_MAX_WO_RESEED_CONFIG \
			-d LRNG_TEST_CPU_ES_COMPRESSION \
			-e LRNG_SELFTEST \
			-d LRNG_SELFTEST_PANIC \
			-d LRNG_RUNTIME_FORCE_SEEDING_DISABLE
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
	(use bore-eevdf || use eevdf) && scripts/config -e SCHED_BORE
	use rt-eevdf && scripts/config -e PREEMPT_COUNT -e PREEMPTION \
		-d PREEMPT_VOLUNTARY -d PREEMPT -d PREEMPT_NONE -e PREEMPT_RT \
		-e PREEMPT_AUTO -d PREEMPT_DYNAMIC -e HAVE_PREEMPT_AUTO \
		-d PREEMPT_BUILD
	use rt-bore && scripts/config -e SCHED_BORE -e PREEMPT_COUNT \
		-e PREEMPTION -d PREEMPT_VOLUNTARY -d PREEMPT -d PREEMPT_NONE \
		-e PREEMPT_RT -e PREEMPT_AUTO -d PREEMPT_DYNAMIC \
		-e HAVE_PREEMPT_AUTO -d PREEMPT_BUILD
	use sched-ext && scripts/config -e SCHED_BORE -e SCHED_CLASS_EXT
	# no special set for eevdf

	# Enable kCFI
	scripts/config -e ARCH_SUPPORTS_CFI_CLANG -e CFI_CLANG

	# Set tick rate
	(use rt-eevdf || use rt-bore) && scripts/config -d HZ_300 \
		-e HZ_1000 --set-val HZ 1000
	(use eevdf || use bore-eevdf || use bore || use sched-ext) &&
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
