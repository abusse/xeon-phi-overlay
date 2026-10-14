#!/bin/sh
# run every test program in this directory, print its output and exit status
cd "$(dirname "$0")"
export LD_LIBRARY_PATH=$PWD OMP_NUM_THREADS=16
L="./glibc/ld-linux-k1om.so.2 --library-path $PWD:$PWD/glibc"
for l in libstdc++ libgcc_s libgomp; do
	{ LD_TRACE_LOADED_OBJECTS=1 $L ./omp-O2 | grep -q "$l.*$PWD" ||
	  LD_TRACE_LOADED_OBJECTS=1 $L ./cxx-O2 2>/dev/null | grep -q "$l.*$PWD"; } &&
		echo "runtime $l local" || echo "runtime $l NOT LOCAL"
done
for t in $(ls | grep -v '\.so\|\.sh$\|\.err$\|\.out$' | sort); do
	[ -f "$t" ] && [ -x "$t" ] || continue
	echo "== $t"
	case $t in
	hw-perftest) timeout 300 $L ./$t 2>&1 | sed 's/[0-9][0-9]*/N/g'; echo "rc=$?" ;;
	*) timeout 300 $L ./$t 2>&1; echo "rc=$?" ;;
	esac
done
