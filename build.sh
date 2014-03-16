set -e
export ANDROID_NDK_ROOT=$PWD/../android-ndk-r9c
export ANDROID_SDK_ROOT=$PWD/../android-sdk-linux
export QT5_ANDROID_BIN=$PWD/../Qt5.2.0/5.2.0/android_armv7/bin
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

if [ ! -e sqlite-autoconf-3080200.tar.gz ] ; then
	wget http://www.sqlite.org/2013/sqlite-autoconf-3080200.tar.gz
fi
if [ ! -e sqlite-autoconf-3080200 ] ; then
	tar -zxf sqlite-autoconf-3080200.tar.gz
fi
if [ ! -e $PKG_CONFIG_PATH/sqlite3.pc ] ; then
	mkdir -p sqlite-build
	pushd sqlite-build
	../sqlite-autoconf-3080200/configure --host=arm-linux-androideabi --prefix=${PREFIX}
	make -j4
	make install
	popd
fi

if [ ! -e libxml2-2.9.1.tar.gz ] ; then
	wget ftp://xmlsoft.org/libxml2/libxml2-2.9.1.tar.gz
fi
if [ ! -e libxml2-2.9.1 ] ; then
	tar -zxf libxml2-2.9.1.tar.gz
fi
if [ ! -e $PKG_CONFIG_PATH/libxml-2.0.pc ] ; then
	mkdir -p libxml2-build
	pushd libxml2-build
	../libxml2-2.9.1/configure --host=arm-linux-androideabi --prefix=${PREFIX} --without-python
	perl -pi -e 's/runtest\$\(EXEEXT\)//' Makefile
	perl -pi -e 's/testrecurse\$\(EXEEXT\)//' Makefile
	make -j4
	make install
	popd
fi

if [ ! -e libxslt-1.1.28.tar.gz ] ; then
	wget ftp://xmlsoft.org/libxml2/libxslt-1.1.28.tar.gz
fi
if [ ! -e libxslt-1.1.28 ] ; then
	tar -zxf libxslt-1.1.28.tar.gz
	cp libxml2-2.9.1/config.sub libxslt-1.1.28
fi
if [ ! -e $PKG_CONFIG_PATH/libxslt.pc ] ; then
	mkdir -p libxslt-build
	pushd libxslt-build
	../libxslt-1.1.28/configure --host=arm-linux-androideabi --prefix=${PREFIX} --with-libxml-prefix=${PREFIX} --without-python
	make
	make install
	popd
fi

if [ ! -e libzip-0.11.2.tar.gz ] ; then
	wget http://www.nih.at/libzip/libzip-0.11.2.tar.gz
fi
if [ ! -e libzip-0.11.2 ] ; then
	tar -zxf libzip-0.11.2.tar.gz
fi
if [ ! -e $PKG_CONFIG_PATH/libzip.pc ] ; then
	mkdir -p libzip-build
	pushd libzip-build
	../libzip-0.11.2/configure --host=arm-linux-androideabi --prefix=${PREFIX}
	make
	make install
	popd
fi

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

# fooling qmake into linking staticly
our_ANDROID_EXTRA_LIBS="libdivecomputer.so libsqlite3.so libxml2.so libxslt.so libzip.so libusb-1.0.so"
pushd $PREFIX/lib
for lib in $our_ANDROID_EXTRA_LIBS ; do
	rm -f $lib*
done
popd

mkdir -p subsurface-build
cd subsurface-build
$QT5_ANDROID_BIN/qmake V=1 QT_CONFIG=+pkg-config -d ../subsurface
make -j4
make install INSTALL_ROOT=android_build
# bug in androiddeployqt?
ln -s android-libsubsurface.so-deployment-settings.json android-libsubsurface-build.so-deployment-settings.json
$QT5_ANDROID_BIN/androiddeployqt --output android_build #--install
