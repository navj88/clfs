############################################################
# Variables de entorno #####################################
############################################################
JOBS:=$(shell grep cores /proc/cpuinfo | wc -l)
CLFS_NAME:=rpi
CLFS_FLOAT:=hard
CLFS_FPU:=vfp
CLFS_HOST:=$(shell echo $$MACHTYPE | sed 's/-[^-]*/-cross/')
CLFS_TARGET:=arm-linux-musleabihf
CLFS_ARCH:=arm
CLFS_ARM_ARCH:=armv6
CLFS:=$(shell pwd)
CLFS_SRC:=$(CLFS)/src
CLFS_CTOOLS:=$(CLFS)/cross-tools
CLFS_CTOOLS_TG:=$(CLFS_CTOOLS)/$(CLFS_TARGET)
CLFS_FS:=$(CLFS)/targetfs
PATH:=$(CLFS_CTOOLS)/bin:/bin/:/usr/bin
CROSS-VARS = \
	$(eval CC:=$(CLFS_TARGET)-gcc) \
	$(eval AR:=$(CLFS_TARGET)-ar) \
	$(eval AS:=$(CLFS_TARGET)-as) \
	$(eval LD:=$(CLFS_TARGET)-ld) \
	$(eval RANLIB:=$(CLFS_TARGET)-ranlib) \
	$(eval READELF:=$(CLFS_TARGET)-readelf) \
	$(eval STRIP:=$(CLFS_TARGET)-strip)
KERNEL_CONFIG =
BUSYBOX_CONFIG =
export
############################################################
# Paquetes y Versiones #####################################
############################################################
.PHONY: get-src $(CLEAN_TARBALLS) $(CLEAN_GITREPOS) print-var
TARBALLS:= BINUTILS BUSYBOX GCC GMP IANA IPTABLES LZO MPC MPFR \
	MUSL OPENSSL OPENVPN ZLIB
GITREPOS := FIRMWARE LINUX TOOLS
PROGRAMS := $(TARBALLS) $(GITREPOS)
BINUTILS := binutils-2.24.tar.bz2
BUSYBOX  := busybox-1.22.1.tar.bz2
FIRMWARE := firmware
GCC      := gcc-4.7.3.tar.bz2
GMP      := gmp-5.1.2.tar.bz2
IANA     := iana-etc-2.30.tar.bz2
IPTABLES := iptables-1.4.21.tar.bz2
LINUX    := linux
LZO      := lzo-2.08.tar.gz
MPC      := mpc-1.0.1.tar.gz
MPFR     := mpfr-3.1.2.tar.bz2
MUSL     := musl-1.0.3.tar.gz
OPENSSL  := openssl-1.0.1j.tar.gz
OPENVPN  := openvpn-2.3.5.tar.gz
TOOLS    := tools
ZLIB     := zlib-1.2.8.tar.gz
$(foreach V, $(PROGRAMS), $(eval $(V)_BASE:=$(basename $(basename $($(V))))))
$(foreach V, $(PROGRAMS), $(eval $(V)_BASE_SRC:=$(CLFS_SRC)/$($(V)_BASE)))
$(foreach V, $(PROGRAMS), $(eval $(V)_SRC:=$(CLFS_SRC)/$($(V))))
SOURCES:=$(foreach V, $(PROGRAMS), $($(V)_SRC))
CLEAN_TARBALLS:=$(foreach V, $(TARBALLS), $(CLFS_SRC)/$($(V)_BASE).clean)
CLEAN_GITREPOS:=$(foreach V, $(GITREPOS), $(CLFS_SRC)/$($(V)_BASE).clean)
get-src: $(SOURCES)
$(BINUTILS_SRC) :
	@wget -P $(CLFS_SRC) http://ftp.gnu.org/gnu/binutils/$(BINUTILS)
$(BUSYBOX_SRC) :
	@wget -P $(CLFS_SRC) http://busybox.net/downloads/$(BUSYBOX)
$(FIRMWARE_SRC) :
	@git clone --depth 1 https://github.com/raspberrypi/$(FIRMWARE) $(FIRMWARE_SRC)
$(GCC_SRC) :
	@wget -P $(CLFS_SRC) http://ftp.gnu.org/gnu/gcc/$(GCC_BASE)/$(GCC)
$(GMP_SRC) :
	@wget -P $(CLFS_SRC) http://ftp.gnu.org/gnu/gmp/$(GMP)
$(IANA_SRC) :
	@wget -P $(CLFS_SRC) http://sethwklein.net/$(IANA)
$(IPTABLES_SRC) :
	@wget -P $(CLFS_SRC) http://www.netfilter.org/projects/iptables/files/$(IPTABLES)
$(LINUX_SRC) :
	@git clone --depth 1 https://github.com/raspberrypi/$(LINUX) $(LINUX_SRC)
$(LZO_SRC) :
	@wget -P $(CLFS_SRC) http://www.oberhumer.com/opensource/lzo/download/$(LZO)
$(MPC_SRC) :
	@wget -P $(CLFS_SRC) http://www.multiprecision.org/mpc/download/$(MPC)
$(MPFR_SRC) :
	@wget -P $(CLFS_SRC) http://gforge.inria.fr/frs/download.php/32210/$(MPFR)
$(MUSL_SRC) :
	@wget -P $(CLFS_SRC) http://www.musl-libc.org/releases/$(MUSL)
$(OPENSSL_SRC) :
	@wget -P $(CLFS_SRC) http://www.openssl.org/source/$(OPENSSL)
$(OPENVPN_SRC) :
	@wget -P $(CLFS_SRC) http://swupdate.openvpn.org/community/releases/$(OPENVPN)
$(TOOLS_SRC) :
	@git clone --depth 1 https://github.com/raspberrypi/$(TOOLS) $(TOOLS_SRC)
$(ZLIB_SRC) :
	@wget -P $(CLFS_SRC) http://zlib.net/$(ZLIB)
version-check :
	@bash --version | head -n1 | cut -d" " -f2-4
	@echo -n "binutils, "; ld --version | head -n1 | cut -d" " -f3-
	@bzip2 --version 2>&1 < /dev/null | head -n1 | cut -d" " -f1,6-
	@echo -n "coreutils, "; chown --version | head -n1 | cut -d")" -f2
	@diff --version | head -n1
	@find --version | head -n1
	@gawk --version | head -n1
	@gcc  --version | head -n1
	@ldd $(shell which $(SHELL))| grep libc.so | cut -d" " -f3 |\
	$(SHELL)| head -n1 | cut -d" " -f1-9
	@grep --version | head -n1
	@gzip --version | head -n1
	@make --version | head -n1
	@patch --version | head -n1
	@sed   --version | head -n1
	@sudo  -V | head -n1
	@tar  --version | head -n1
	@makeinfo --version | head -n1
	@rsync --version | head -n1 | cut -d" " -f1-4
print-var :
	@$(foreach V,$(sort $(.VARIABLES)), \
		$(if $(filter-out environment% default automatic,$(origin $V)),\
			$(warning $V=$($V) ($(value $V)))\
		)\
	)
############################################################
# Configuracion del entorno ################################
############################################################
.PHONY: set-env set-cross-env
BASH_PROFILE=\
exec env -i HOME=$${HOME} TERM=$${TERM} PS1="\u:\w\$$ " /bin/bash
BASHRC=\
set +h\n\
umask 022\n\
CLFS=$(CLFS)\n\
LC_ALL=POSIX\n\
PATH=$(CLFS_CTOOLS)/bin:/bin:/usr/bin\n\
export CLFS LC_ALL PATH\n\
unset CFLAGS\n\n\
export CLFS_FLOAT=$(CLFS_FLOAT)\n\
export CLFS_FPU=$(CLFS_FPU)\n\
export CLFS_HOST=$(CLFS_HOST)\n\
export CLFS_TARGET=$(CLFS_TARGET)\n\
export CLFS_ARCH=$(CLFS_ARCH)\n\
export CLFS_ARM_ARCH=$(CLFS_ARM_ARCH)
BASHRC_CROSS=\
export CC=$(CLFS_TARGET)-gcc\n\
export AR=$(CLFS_TARGET)-ar\n\
export AS=$(CLFS_TARGET)-as\n\
export LD=$(CLFS_TARGET)-ld\n\
export RANLIB=$(CLFS_TARGET)-ranlib\n\
export READELF=$(CLFS_TARGET)-readelf\n\
export STRIP=$(CLFS_TARGET)-strip
set-env :
	@echo -e "$(BASH_PROFILE)" | sed -e 's/^[ ]//' > $(HOME)/.bash_profile
	@echo -e "$(BASHRC)" | sed -e 's/^[ ]//' > $(HOME)/.bashrc
set-cross-env :
	@echo -e "$(BASHRC)" "$(BASHRC_CROSS)" | sed -e 's/^[ ]//' > ~/.bashrc
############################################################
# Compilador Cruzado  ######################################
############################################################
.PHONY: cross-tools
cross-tools: .build-gcc-final
.build-dir:
	@mkdir -pv $(CLFS_CTOOLS_TG)
	@ln -sfv . $(CLFS_CTOOLS_TG)/usr
	@touch $@
.build-linux-hdr : .build-dir
	$(MAKE) -C $(LINUX_SRC) mrproper
	$(MAKE) -C $(LINUX_SRC) ARCH=$(CLFS_ARCH) headers_check
	$(MAKE) -C $(LINUX_SRC) ARCH=$(CLFS_ARCH) \
	INSTALL_HDR_PATH=$(CLFS_CTOOLS_TG) headers_install
	cd $(CLFS_CTOOLS_TG) && \
	patch -Nup2 -i $(CLFS_SRC)/kernel-headers_libc-compat.patch && \
	patch -Nup2 -i $(CLFS_SRC)/kernel-headers_musl.patch
	@touch $@
.build-binutils : .build-linux-hdr $(BINUTILS_SRC)
	cd $(CLFS_SRC) && tar xjf $(BINUTILS)
	@mkdir -v $(BINUTILS_BASE_SRC)-build
	cd $(BINUTILS_BASE_SRC)-build &&\
	../$(BINUTILS_BASE)/configure \
	  --prefix=$(CLFS_CTOOLS) \
	  --target=$(CLFS_TARGET) \
	  --with-sysroot=$(CLFS_CTOOLS_TG) \
	  --disable-nls \
	  --disable-multilib \
	  --disable-werror
	$(MAKE) -C $(BINUTILS_BASE_SRC)-build configure-host
	$(MAKE) -C $(BINUTILS_BASE_SRC)-build -j$(JOBS)
	$(MAKE) -C $(BINUTILS_BASE_SRC)-build install
	rm -Rf $(BINUTILS_BASE_SRC)-build
	rm -Rf $(BINUTILS_BASE_SRC)-build
	@touch $@
.build-gcc-static : .build-binutils $(GCC_SRC) $(MPFR_SRC) $(MPC_SRC) $(GMP_SRC)
	cd $(CLFS_SRC) && tar xjf $(GCC)
	@cd $(GCC_BASE_SRC) &&\
	  patch -Np1 -i ../gcc-4.7.3-musl-1.patch &&\
	  tar xjf ../$(MPFR) && mv -v $(MPFR_BASE) mpfr &&\
	  tar xjf ../$(GMP)  && mv -v $(GMP_BASE)  gmp  &&\
	  tar xzf ../$(MPC)  && mv -v $(MPC_BASE)  mpc
	@mkdir -v $(GCC_BASE_SRC)-build
	cd $(GCC_BASE_SRC)-build &&\
	../$(GCC_BASE)/configure \
	  --prefix=$(CLFS_CTOOLS) \
	  --build=$(CLFS_HOST) \
	  --host=$(CLFS_HOST) \
	  --target=$(CLFS_TARGET) \
	  --with-sysroot=$(CLFS_CTOOLS_TG) \
	  --disable-nls \
	  --disable-shared \
	  --without-headers \
	  --with-newlib \
	  --disable-decimal-float \
	  --disable-libgomp \
	  --disable-libmudflap \
	  --disable-libssp \
	  --disable-libatomic \
	  --disable-libquadmath \
	  --disable-threads \
	  --enable-languages=c \
	  --disable-multilib \
	  --with-mpfr-include=../$(GCC_BASE)/mpfr/src \
	  --with-mpfr-lib=mpfr/src/.libs \
	  --with-arch=$(CLFS_ARM_ARCH) \
	  --with-float=$(CLFS_FLOAT) \
	  --with-fpu=$(CLFS_FPU)
	$(MAKE) -C $(GCC_BASE_SRC)-build all-gcc all-target-libgcc -j$(JOBS)
	$(MAKE) -C $(GCC_BASE_SRC)-build install-gcc install-target-libgcc
	rm -rf $(GCC_BASE_SRC)
	rm -rf $(GCC_BASE_SRC)-build
	@touch $@
.build-musl : .build-gcc-static $(MUSL_SRC)
	cd $(CLFS_SRC) && tar xzf $(MUSL)
	cd $(MUSL_BASE_SRC) &&\
	CC=$(CLFS_TARGET)-gcc ./configure \
	  --prefix=/ \
	  --target=$(CLFS_TARGET)
	$(MAKE) -C $(MUSL_BASE_SRC) CC=$(CLFS_TARGET)-gcc
	$(MAKE) -C $(MUSL_BASE_SRC) DESTDIR=$(CLFS_CTOOLS_TG) install
	rm -Rf $(MUSL_BASE_SRC)
	@touch $@
.build-gcc-final : .build-musl $(GCC_SRC) $(MPFR_SRC) $(MPC_SRC) $(GMP_SRC)
	cd $(CLFS_SRC) && tar xjf $(GCC)
	@cd $(GCC_BASE_SRC) &&\
	  patch -Np1 -i ../gcc-4.7.3-musl-1.patch &&\
	  tar xjf ../$(MPFR) && mv -v $(MPFR_BASE) mpfr &&\
	  tar xjf ../$(GMP)  && mv -v $(GMP_BASE)  gmp  &&\
	  tar xzf ../$(MPC)  && mv -v $(MPC_BASE)  mpc
	@mkdir -v $(GCC_BASE_SRC)-build
	cd $(GCC_BASE_SRC)-build &&\
	../$(GCC_BASE)/configure \
	  --prefix=$(CLFS_CTOOLS) \
	  --build=$(CLFS_HOST) \
	  --host=$(CLFS_HOST) \
	  --target=$(CLFS_TARGET) \
	  --with-sysroot=$(CLFS_CTOOLS_TG) \
	  --disable-nls \
	  --disable-libmudflap \
	  --disable-multilib \
	  --enable-languages=c \
	  --enable-c99 \
	  --enable-long-long \
	  --with-mpfr-include=../$(GCC_BASE)/mpfr/src \
	  --with-mpfr-lib=mpfr/src/.libs \
	  --with-arch=$(CLFS_ARM_ARCH) \
	  --with-float=$(CLFS_FLOAT) \
	  --with-fpu=$(CLFS_FPU)
	$(MAKE) -C $(GCC_BASE_SRC)-build -j$(JOBS)
	$(MAKE) -C $(GCC_BASE_SRC)-build install
	rm -rf $(GCC_BASE_SRC)
	rm -rf $(GCC_BASE_SRC)-build
	@touch $@
############################################################
# Sistema Base #############################################
############################################################
.PHONY: base
base :  cross-tools .install-busybox .install-iana-etc .install-kernel \
	.install-boot .install-config-kernel
.install-dir :
	@mkdir -pv $(CLFS_FS)/{bin,boot,dev,\
	etc/network/if-{post-{up,down},pre-{up,down},up,down}.d,home,\
	lib/{firmware,modules},mnt,opt,proc,sbin,srv,sys,\
	var/{cache,lib,local,lock,log,opt,run,spool},\
	usr/{,local/}{bin,include,lib,sbin,share,src}}
	@install -dv -m 0750 $(CLFS_FS)/root
	@install -dv -m 1777 $(CLFS_FS)/tmp
	@touch $@
.install-busybox : .install-dir $(BUSYBOX_SRC)
	$(CROSS-VARS)
	cd $(CLFS_SRC) && tar xjf $(BUSYBOX)
	cd $(BUSYBOX_BASE_SRC) && \
	patch -Np1 -i ../busybox-musl-ifplugd.patch
	$(MAKE) -C $(BUSYBOX_BASE_SRC) distclean
	$(MAKE) -C $(BUSYBOX_BASE_SRC) ARCH=$(CLFS_ARCH) defconfig
	sed -i 's/\(CONFIG_\)\(FEATURE_\)*\(INETD\)\(.*\)=y/\1\2\3\4=n/g' \
	$(BUSYBOX_BASE_SRC)/.config
	sed -i 's/\(CONFIG_FEATURE_SYSTEMD\)=y/# \1 is not set/' \
	$(BUSYBOX_BASE_SRC)/.config
	sed -i 's/\(CONFIG_FEATURE_HAVE_RPC\)=y/# \1 is not set/' \
	$(BUSYBOX_BASE_SRC)/.config
ifdef BUSYBOX_CONFIG
	$(MAKE) -C $(BUSYBOX_BASE_SRC) ARCH=$(CLFS_ARCH) menuconfig
endif
	$(MAKE) -j$(JOBS) -C $(BUSYBOX_BASE_SRC) ARCH=$(CLFS_ARCH) \
	CROSS_COMPILE=$(CLFS_TARGET)-
	$(MAKE) -C $(BUSYBOX_BASE_SRC) ARCH=$(CLFS_ARCH) \
	CROSS_COMPILE=$(CLFS_TARGET)- CONFIG_PREFIX="$(CLFS_FS)" install
	cp -v $(BUSYBOX_BASE_SRC)/examples/depmod.pl $(CLFS_CTOOLS)/bin
	chmod 755 $(CLFS_CTOOLS)/bin/depmod.pl
	rm -rf $(BUSYBOX_BASE_SRC)
	@touch $@
.install-iana-etc : .install-dir $(IANA_SRC)
	$(CROSS-VARS)
	cd $(CLFS_SRC) && tar xjf $(IANA)
	cd $(IANA_BASE_SRC) &&\
	patch -Np1 -i ../iana-etc-2.30-update-2.patch
	$(MAKE) -C $(IANA_BASE_SRC) get
	$(MAKE) -C $(IANA_BASE_SRC) STRIP=yes
	$(MAKE) -C $(IANA_BASE_SRC) DESTDIR=$(CLFS_FS) install
	rm -rf $(IANA_BASE_SRC)
	@touch $@
.install-config-kernel:
	$(CROSS-VARS)
	$(MAKE) -C $(LINUX_BASE_SRC) mrproper
	@cp $(CLFS_SRC)/kernel_rpi_navj.config $(LINUX_BASE_SRC)/.config
	$(MAKE) -C $(LINUX_BASE_SRC) ARCH=$(CLFS_ARCH) \
	CROSS_COMPILE=$(CLFS_TARGET)- oldconfig
ifdef KERNEL_CONFIG
	$(MAKE) -C $(LINUX_BASE_SRC) ARCH=$(CLFS_ARCH) \
	CROSS_COMPILE=$(CLFS_TARGET)- menuconfig
endif
	@touch $@
.install-kernel : .install-dir .install-config-kernel .install-busybox
	$(CROSS-VARS)
	-cd $(LINUX_BASE_SRC) && \
	patch -Np1 -i ../dm9601-bug.patch
	$(MAKE) -C $(LINUX_BASE_SRC) ARCH=$(CLFS_ARCH) \
	CROSS_COMPILE=$(CLFS_TARGET)-  -j$(JOBS)
	$(MAKE) -C $(LINUX_BASE_SRC) ARCH=$(CLFS_ARCH) \
	CROSS_COMPILE=$(CLFS_TARGET)- \
	INSTALL_MOD_PATH=$(CLFS_FS) modules_install
	@touch $@
.install-boot : .install-kernel
	$(CROSS-VARS)
	cd $(TOOLS_BASE_SRC)/mkimage &&\
	./imagetool-uncompressed.py $(LINUX_BASE_SRC)/arch/arm/boot/zImage &&\
	mv -vf kernel.img $(CLFS_FS)/boot
	@cp -vf $(FIRMWARE_BASE_SRC)/boot/{bootcode.bin,fixup.dat,start.elf} $(CLFS_FS)/boot
	@touch $@
############################################################
# Programas y Bibliotecas Adicionales ######################
############################################################
.PHONY: extra
extra : .install-openvpn .install-iptables
.build-lzo : .build-gcc-final $(LZO_SRC)
	$(CROSS-VARS)
	@cd $(CLFS_SRC) && tar xzf $(LZO)
	cd $(LZO_BASE_SRC) && \
	./configure \
	  --host=$(CLFS_TARGET) \
	  --prefix=$(CLFS_CTOOLS_TG) \
	  --enable-shared
	$(MAKE) -C $(LZO_BASE_SRC) -j$(JOBS)
	$(MAKE) -C $(LZO_BASE_SRC) install
	@rm -rf $(LZO_BASE_SRC)
	@touch $@
.build-zlib : .build-gcc-final $(ZLIB_SRC)
	$(CROSS-VARS)
	@cd $(CLFS_SRC) && tar xzf $(ZLIB)
	cd $(ZLIB_BASE_SRC) && \
	CFLAGS=-Os ./configure \
	  --shared
	$(MAKE) -C $(ZLIB_BASE_SRC) -j$(JOBS)
	$(MAKE) -C $(ZLIB_BASE_SRC) prefix=$(CLFS_CTOOLS_TG) install
	@rm -Rf $(ZLIB_BASE_SRC)
	@touch $@
.build-openssl : .build-gcc-final .build-zlib $(OPENSSL_SRC)
	$(CROSS-VARS)
	@cd $(CLFS_SRC) && tar xzf $(OPENSSL)
	cd $(OPENSSL_BASE_SRC) $$ \
	patch -Np1 -i ../openssl-001-do-not-build-docs.patch && \
	patch -Np1 -i ../openssl-004-musl-termios.patch && \
	./Configure linux-armv4 shared zlib-dynamic --prefix=/usr
	$(MAKE) -C $(OPENSSL_BASE_SRC)
	$(MAKE) -C $(OPENSSL_BASE_SRC) INSTALL_PREFIX=$(CLFS_CTOOLS_TG) install
	@rm -Rf $(CLFS_SRC)/openssl-1.0.1j
	@touch $@
.install-openvpn : .install-dir .build-lzo .build-openssl .build-zlib $(OPENVPN_SRC)
	$(CROSS-VARS)
	cd $(CLFS_SRC) && tar xzf $(OPENVPN)
	cd $(OPENVPN_BASE_SRC) && \
	./configure \
	  IPROUTE=/sbin/ip \
	  --host=$(CLFS_TARGET) \
	  --prefix=/usr \
	  --enable-shared \
	  --disable-plugins \
	  --disable-debug \
	  --enable-iproute2
	$(MAKE) -C $(OPENVPN_BASE_SRC) -j$(JOBS)
	$(MAKE) -C $(OPENVPN_BASE_SRC) DESTDIR=$(CLFS_FS) install
	rm -Rf $(OPENVPN_BASE_SRC)
	@touch $@
.install-iptables : .install-dir $(IPTABLES_SRC)
	$(CROSS-VARS)
	cd $(CLFS_SRC) && tar xjf $(IPTABLES_SRC)
	cd $(IPTABLES_BASE_SRC) && \
	patch -Np1 -i ../iptables-1.4.14-musl-fixes.patch && \
	./configure \
	  --host=$(CLFS_ARCH) \
	  --prefix=/usr \
	  --disable-ipv6 \
	  --disable-largefile
	$(MAKE) -C $(IPTABLES_BASE_SRC) -j$(JOBS)
	$(MAKE) -C $(IPTABLES_BASE_SRC) DESTDIR=$(CLFS_FS) install
	rm -Rf $(IPTABLES_BASE_SRC)
	@touch $@
############################################################
# Rutinas Finales ##########################################
############################################################
.PHONY: system install
system : base extra .install-lib .install-bootscripts
.install-lib : .install-dir .build-gcc-final
	$(CROSS_VARS)
	-@cp -vP $(CLFS_CTOOLS_TG)/lib/*.so* $(CLFS_FS)/lib
	@touch $@
.install-bootscripts: .install-dir
	$(CROSS-VARS)
	@cp -purv $(CLFS_SRC)/scripts/* $(CLFS_FS)
	@touch $@
install :
	$(eval DESTDIR=$(CLFS)/sd)
	mkdir -p $(DESTDIR)
	rsync \
	  -rlptu \
	  --chown=root:root \
	  --exclude 'doc' \
	  --exclude '*man' \
	$(CLFS_FS)/ $(DESTDIR)/
############################################################
# Rutinas de Limpieza ######################################
############################################################
.PHONY: clean-all clean-env clean-ctools clean-fs clean-src
clean-all : clean-ctools clean-fs clean-src
clean-env :
	rm -f $(HOME)/.bash*
clean-ctools :
	rm -rf $(CLFS_CTOOLS)
	rm -f $(CLFS)/.buil*
clean-fs :
	rm -rf $(CLFS_FS)
	rm -f $(CLFS)/.install*
clean-src: $(CLEAN_TARBALLS) $(CLEAN_GITREPOS)
$(CLEAN_TARBALLS):
	rm -rf $(basename $@)
	rm -rf $(basename $@)-build
$(CLEAN_GITREPOS):
	cd $(basename $@); \
	git clean -xf; \
	git clean -Xf; \
	git checkout -- .
