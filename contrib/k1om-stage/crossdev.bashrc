# Add to /etc/portage/bashrc on the build host before running crossdev for k1om.
# K1OM follows the x86_64 layout (/lib64/ld-linux-k1om.so.2, gcc multilib lib64), but crossdev
# sets LIBDIR_default=lib for the unknown k1om ABI.  The crossdev env files are sourced after
# this file, so override in the phase hooks, which run later.
if [[ ${CATEGORY} == cross-k1om-* ]] ; then
	__k1om_lib64() { LIBDIR_default=lib64; }
	for __p in pkg_pretend pkg_setup src_unpack src_prepare src_configure src_compile src_test \
		src_install pkg_preinst pkg_postinst ; do
		eval "pre_${__p}() { __k1om_lib64; }"
	done
	unset __p
fi
