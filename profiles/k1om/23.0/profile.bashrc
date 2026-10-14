# Autoconf cache answers for k1om. Configure scripts key on host_cpu (unknown "k1om"), and inline-asm
# probes for SSE/AVX/PCLMUL succeed although KNC has none of them, so CPU-feature probes are answered "no".

# gnulib: host-cpu-c-abi, sigsegv stack direction
export gl_cv_host_cpu_c_abi=x86_64 gl_cv_host_cpu_c_abi_32bit=no
export sv_cv_stack_direction=-1 sv_cv_stack_direction_msg="grows down"

# gnulib crc / coreutils cksum, wc, base64
export gl_cv_crc_pclmul=no
export utils_cv_pclmul_intrinsic_exists=no utils_cv_avx2_intrinsic_exists=no
export utils_cv_avx2_pclmul_intrinsic_exists=no utils_cv_avx512_intrinsic_exists=no
export utils_cv_avx512_pclmul_intrinsic_exists=no

# libgcrypt
export gcry_cv_gcc_inline_asm_ssse3=no gcry_cv_gcc_inline_asm_pclmul=no gcry_cv_gcc_inline_asm_sse41=no
export gcry_cv_gcc_inline_asm_avx=no gcry_cv_gcc_inline_asm_avx2=no gcry_cv_gcc_inline_asm_avx512=no
export gcry_cv_gcc_inline_asm_vaes_vpclmul=no gcry_cv_cc_x86_avx512_intrinsics=no

# Python HACL* SIMD128/256
export ax_cv_check_cflags__Werror__msse__msse2__msse3__msse4_1__msse4_2=no
export ax_cv_check_cflags__Werror__mavx2=no

k1om_append() {
	local v=$1 f
	shift
	for f; do
		[[ " ${!v} " == *" ${f} "* ]] || export ${v}="${!v:+${!v} }${f}"
	done
}

case ${CATEGORY}/${PN} in
	# SSE/AES-NI/PCLMUL assembly
	net-libs/gnutls) EXTRA_ECONF="--disable-hardware-acceleration" ;;
	# CLMUL CRC; the x86-64 inline-asm range decoder uses cmov
	app-arch/xz-utils)
		EXTRA_ECONF="--disable-clmul-crc"
		k1om_append CPPFLAGS -DLZMA_RANGE_DECODER_CONFIG=0
		;;
	# BMI2 dispatch (shlx/shrx) and the x86-64 huf asm
	app-arch/zstd) k1om_append CPPFLAGS -DDYNAMIC_BMI2=0 -DZSTD_DISABLE_ASM ;;
esac
