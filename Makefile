.PHONY: clean-all clean-vars clean-ctools clean-fs clean-src clean-src-binutils \
	clean-src-gcc clean-src-musl clean-src-busybox clean-src-iana clean-src-kernel \
	print-var set-env cross-vars

############################################################
# Variables de entorno #####################################
############################################################
JOBS:=9
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
CLFS_FS=$(CLFS)/targetfs
PATH=$(CLFS_CTOOLS)/bin:/bin/:/usr/bin

CROSS-VARS = \
	$(eval CC:=$(CLFS_TARGET)-gcc) \
	$(eval AR:=$(CLFS_TARGET)-ar) \
	$(eval AS:=$(CLFS_TARGET)-as) \
	$(eval LD:=$(CLFS_TARGET)-ld) \
	$(eval RANLIB:=$(CLFS_TARGET)-ranlib) \
	$(eval READELF:=$(CLFS_TARGET)-readelf) \
	$(eval STRIP:=$(CLFS_TARGET)-strip)

export
print-var : 
	@$(foreach V,$(sort $(.VARIABLES)), \
		$(if $(filter-out environment% default automatic,$(origin $V)),\
			$(warning $V=$($V) ($(value $V)))\
		)\
	)
include file-config.mk
############################################################
# Configuracion del entorno ################################
############################################################
set-env : .bash_profile .bashrc
.bash_profile :
	@echo -e "$(BASH_PROFILE)" | sed -e 's/^[ ]//' > .bash_profile
.bashrc :
	@echo -e "$(BASHRC)" | sed -e 's/^[ ]//' > .bashrc
############################################################
# Cross Compile Tools ######################################
############################################################
.PHONY: cross-tools
cross-tools: .build-gcc-final

.build-dir:
	@mkdir -pv $(CLFS_CTOOLS_TG)
	@ln -sfv . $(CLFS_CTOOLS_TG)/usr
	@touch $@
.build-linux-hdr : .build-dir
	$(MAKE) -C $(CLFS_SRC)/linux mrproper
	$(MAKE) -C $(CLFS_SRC)/linux ARCH=$(CLFS_ARCH) headers_check
	$(MAKE) -C $(CLFS_SRC)/linux ARCH=$(CLFS_ARCH) \
	INSTALL_HDR_PATH=$(CLFS_CTOOLS_TG) headers_install
	cd $(CLFS_CTOOLS_TG) && \
	patch -Nup2 -i ~/src/kernel-headers_libc-compat.patch && \
	patch -Nup2 -i ~/src/kernel-headers_musl.patch
	@touch $@
.build-binutils : .build-linux-hdr
	cd $(CLFS_SRC) && tar xjf binutils-2.24.tar.bz2
	@mkdir -v $(CLFS_SRC)/binutils-build
	cd $(CLFS_SRC)/binutils-build &&\
	../binutils-2.24/configure \
	  --prefix=$(CLFS_CTOOLS) \
	  --target=$(CLFS_TARGET) \
	  --with-sysroot=$(CLFS_CTOOLS_TG) \
	  --disable-nls \
	  --disable-multilib \
	  --disable-werror
	$(MAKE) -C $(CLFS_SRC)/binutils-build configure-host
	$(MAKE) -C $(CLFS_SRC)/binutils-build -j$(JOBS)
	$(MAKE) -C $(CLFS_SRC)/binutils-build install
	rm -Rf $(CLFS_SRC)/binutils-{build,2.24}
	@touch $@
.build-gcc-static : .build-binutils
	cd $(CLFS_SRC) && tar xjf gcc-4.7.3.tar.bz2
	@cd $(CLFS_SRC)/gcc-4.7.3 &&\
	  patch -Np1 -i ../gcc-4.7.3-musl-1.patch &&\
	  tar xjf ../mpfr-3.1.2.tar.bz2 && mv -v mpfr-3.1.2 mpfr &&\
	  tar xjf ../gmp-5.1.2.tar.bz2 && mv -v gmp-5.1.2 gmp &&\
	  tar xzf ../mpc-1.0.1.tar.gz && mv -v mpc-1.0.1 mpc
	@mkdir -v $(CLFS_SRC)/gcc-build
	cd $(CLFS_SRC)/gcc-build &&\
	../gcc-4.7.3/configure \
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
	  --with-mpfr-include=../gcc-4.7.3/mpfr/src \
	  --with-mpfr-lib=mpfr/src/.libs \
	  --with-arch=$(CLFS_ARM_ARCH) \
	  --with-float=$(CLFS_FLOAT) \
	  --with-fpu=$(CLFS_FPU)
	$(MAKE) -C $(CLFS_SRC)/gcc-build all-gcc all-target-libgcc -j$(JOBS)
	$(MAKE) -C $(CLFS_SRC)/gcc-build install-gcc install-target-libgcc
	rm -Rf $(CLFS_SRC)/gcc-{build,4.7.3}
	@touch $@
.build-musl : .build-gcc-static
	cd $(CLFS_SRC) && tar xzf musl-1.0.3.tar.gz
	cd $(CLFS_SRC)/musl-1.0.3 &&\
	CC=$(CLFS_TARGET)-gcc ./configure \
	  --prefix=/ \
	  --target=$(CLFS_TARGET)
	$(MAKE) -C $(CLFS_SRC)/musl-1.0.3 CC=$(CLFS_TARGET)-gcc 
	$(MAKE) -C $(CLFS_SRC)/musl-1.0.3 DESTDIR=$(CLFS_CTOOLS_TG) install
	rm -Rf $(CLFS_SRC)/musl-1.0.3
	@touch $@
.build-gcc-final : .build-musl
	cd $(CLFS_SRC) && tar xjf gcc-4.7.3.tar.bz2
	@cd $(CLFS_SRC)/gcc-4.7.3 &&\
	  patch -Np1 -i ../gcc-4.7.3-musl-1.patch &&\
	  tar xjf ../mpfr-3.1.2.tar.bz2 && mv -v mpfr-3.1.2 mpfr &&\
	  tar xjf ../gmp-5.1.2.tar.bz2 && mv -v gmp-5.1.2 gmp &&\
	  tar xzf ../mpc-1.0.1.tar.gz && mv -v mpc-1.0.1 mpc
	@mkdir -v $(CLFS_SRC)/gcc-build
	cd $(CLFS_SRC)/gcc-build; \
	../gcc-4.7.3/configure \
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
	  --with-mpfr-include=../gcc-4.7.3/mpfr/src \
	  --with-mpfr-lib=mpfr/src/.libs \
	  --with-arch=$(CLFS_ARM_ARCH) \
	  --with-float=$(CLFS_FLOAT) \
	  --with-fpu=$(CLFS_FPU)
	$(MAKE) -C $(CLFS_SRC)/gcc-build -j$(JOBS)
	$(MAKE) -C $(CLFS_SRC)/gcc-build install
	rm -Rf $(CLFS_SRC)/gcc-{build,4.7.3}
	@touch $@
.cross-vars :
	@echo -e "$(BASHRC)" "$(BASHRC_CROSS)" | sed -e 's/^[ ]//' > .bashrc
	@touch $@
############################################################

# Installing Basic System ##################################
############################################################
.PHONY: system
system: cross-tools .install-busybox .install-iana-etc .install-kernel\
	.install-bootscripts .install-boot .install-lib
.install-dir :
	@mkdir -pv $(CLFS_FS)/{bin,boot,dev,\
	etc/network/if-{post-{up,down},pre-{up,down},up,down}.d,home,\
	lib/{firmware,modules},mnt,opt,proc,sbin,srv,sys,\
	var/{cache,lib,local,lock,log,opt,run,spool},\
	usr/{,local/}{bin,include,lib,sbin,share,src}}
	@install -dv -m 0750 $(CLFS_FS)/root
	@install -dv -m 1777 $(CLFS_FS)/tmp
	@touch $@
.install-busybox : .install-dir 
	$(CROSS-VARS)
	cd $(CLFS_SRC) && tar xjf busybox-1.22.1.tar.bz2
	cd $(CLFS_SRC)/busybox-1.22.1 && \
	patch -Np1 -i ../busybox-musl-ifplugd.patch
	$(MAKE) -C $(CLFS_SRC)/busybox-1.22.1 distclean
	$(MAKE) -C $(CLFS_SRC)/busybox-1.22.1 ARCH=$(CLFS_ARCH) defconfig
	sed -i 's/\(CONFIG_\)\(FEATURE_\)*\(INETD\)\(.*\)=y/\1\2\3\4=n/g' \
	$(CLFS_SRC)/busybox-1.22.1/.config
	sed -i 's/\(CONFIG_FEATURE_SYSTEMD\)=y/# \1 is not set/' \
	$(CLFS_SRC)/busybox-1.22.1/.config
	sed -i 's/\(CONFIG_FEATURE_HAVE_RPC\)=y/# \1 is not set/' \
	$(CLFS_SRC)/busybox-1.22.1/.config
	$(MAKE) -j$(JOBS) -C $(CLFS_SRC)/busybox-1.22.1 ARCH=$(CLFS_ARCH) \
	CROSS_COMPILE=$(CLFS_TARGET)- 
	$(MAKE) -C $(CLFS_SRC)/busybox-1.22.1 ARCH=$(CLFS_ARCH) \
	CROSS_COMPILE=$(CLFS_TARGET)- CONFIG_PREFIX="$(CLFS_FS)" install
	cp -v $(CLFS_SRC)/busybox-1.22.1/examples/depmod.pl $(CLFS_CTOOLS)/bin
	chmod 755 $(CLFS_CTOOLS)/bin/depmod.pl
	rm -Rf $(CLFS_SRC)/busybox-1.22.1
	@touch $@
.install-iana-etc : .install-dir
	$(CROSS-VARS)
	cd $(CLFS_SRC) && tar xjf iana-etc-2.30.tar.bz2
	cd $(CLFS_SRC)/iana-etc-2.30 &&\
	patch -Np1 -i ../iana-etc-2.30-update-2.patch
	$(MAKE) -C $(CLFS_SRC)/iana-etc-2.30 get 
	$(MAKE) -C $(CLFS_SRC)/iana-etc-2.30 STRIP=yes
	$(MAKE) -C $(CLFS_SRC)/iana-etc-2.30 DESTDIR=$(CLFS_FS) install
	rm -Rf $(CLFS_SRC)/iana-etc-2.30
	@touch $@
.install-kernel : .install-dir
	$(CROSS-VARS)
	$(MAKE) -C $(CLFS_SRC)/linux mrproper
	$(MAKE) -C $(CLFS_SRC)/linux ARCH=$(CLFS_ARCH) \
	CROSS_COMPILE=$(CLFS_TARGET)- bcmrpi_defconfig
	$(MAKE) -C $(CLFS_SRC)/linux ARCH=$(CLFS_ARCH) \
	CROSS_COMPILE=$(CLFS_TARGET)-  -j$(JOBS)
	$(MAKE) -C $(CLFS_SRC)/linux ARCH=$(CLFS_ARCH) \
	CROSS_COMPILE=$(CLFS_TARGET)- \
	INSTALL_MOD_PATH=$(CLFS_FS) modules_install
	@touch $@
.install-boot : .install-kernel
	$(CROSS-VARS)
	cd $(CLFS_SRC)/tools/mkimage &&\
	./imagetool-uncompressed.py $(CLFS_SRC)/linux/arch/arm/boot/zImage &&\
	mv -vf kernel.img $(CLFS_FS)/boot
	@cp -vf $(CLFS_SRC)/firmware/boot/{bootcode.bin,fixup.dat,start.elf} $(CLFS_FS)/boot
	@echo -e "$(CMDLINE)" | sed -e 's/^[ ]//' > $(CLFS_FS)/boot/cmdline.txt
	@touch $@
.install-bootscripts: .install-dir
	$(CROSS-VARS)
	@cp -purv $(CLFS_SRC)/scripts/* $(CLFS_FS)
	@touch $@
.install-lib: .install-dir
	@cp -vP $(CLFS_CTOOLS_TG)/lib/*.so* $(CLFS_FS)/lib
	@touch $@
############################################################

# Installing Final System ##################################
############################################################
.final:
	@chown -Rv root:root $(CLFS_FS)



clean-all : clean-ctools clean-fs clean-src

clean-env :
	rm -f ~/.bash*
clean-ctools:
	rm -Rf $(CLFS_CTOOLS)
	rm -f $(CLFS)/.buil*
clean-fs :
	rm -Rf $(CLFS_FS)
	rm -f $(CLFS)/.install*
clean-src : clean-src-binutils clean-src-gcc clean-src-musl clean-src-busybox\
	clean-src-iana clean-src-kernel

clean-src-binutils :
	rm -Rf $(CLFS_SRC)/binutils-2.24
	rm -Rf $(CLFS_SRC)/binutils-build
clean-src-gcc :
	rm -Rf $(CLFS_SRC)/gcc-4.7.3
	rm -Rf $(CLFS_SRC)/gcc-build
clean-src-musl :
	rm -Rf $(CLFS_SRC)/musl-1.0.3
clean-src-busybox :
	rm -Rf $(CLFS_SRC)/busybox-1.22.1
clean-src-iana :
	rm -Rf $(CLFS_SRC)/iana-etc-2.30
clean-src-kernel :
	cd $(CLFS_SRC)/linux && git clean -Xf
