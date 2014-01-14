set -e
export ANDROID_NDK_ROOT=$PWD/../android-ndk-r9c
if [ ! -e ndk-arm ] ; then
	$ANDROID_NDK_ROOT/build/tools/make-standalone-toolchain.sh --install-dir=ndk-arm --platform=android-14
fi
export BUILDROOT=$PWD
export PATH=${BUILDROOT}/ndk-arm/bin:$PATH
export PREFIX=${BUILDROOT}/ndk-arm/sysroot/usr
export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig

# Fetch external repos
git submodule init
git submodule update
#git submodule foreach --recursive git checkout android

if [ ! -e libusb-1.0.9.tar.bz2 ] ; then
	wget http://sourceforge.net/projects/libusb/files/libusb-1.0/libusb-1.0.9/libusb-1.0.9.tar.bz2
fi
if [ ! -e libusb-1.0.9 ] ; then
	tar -jxf libusb-1.0.9.tar.bz2
fi
if ! grep -q __ANDROID__ libusb-1.0.9/libusb/io.c ; then
	# patch libusb to build with android-ndk
	patch -p1 < libusb-1.0.9-android.patch  libusb-1.0.9/libusb/io.c
fi
if [ ! -e $PKG_CONFIG_PATH/libusb-1.0.pc ] ; then
	mkdir -p libusb-build
	pushd libusb-build
	../libusb-1.0.9/configure --host=arm-linux-androideabi --prefix=${PREFIX}
	make
	make install
	popd
fi

if [ ! -e libdivecomputer/configure ] ; then
	pushd libdivecomputer
	autoreconf -i
	popd
fi

if [ ! -e $PKG_CONFIG_PATH/libdivecomputer.pc ] ; then
	mkdir -p libdivecomputer-build
	pushd libdivecomputer-build
	../libdivecomputer/configure --host=arm-linux-androideabi --prefix=${PREFIX}
	make
	make install
	popd
fi
