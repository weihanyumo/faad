#!/bin/sh

CONFIGURE_FLAGS="--enable-static --with-pic"

ARCHS="arm64 armv7s armv7 x86_64 i386"

# directories
SOURCE="faad2-2.7"
FAT="fat-faad"
SCRATCH="scratch-faad"
THIN=`pwd`/"thin-faad"

#compile lipo
COMPILE="y"
LIPO="y"


if [ "$COMPILE" ]
then
    CWD=`pwd`
    for ARCH in $ARCHS
    do
        echo "building $ARCH..."
        mkdir -p "$SCRATCH/$ARCH"
        cd "$SCRATCH/$ARCH"

        if [ "$ARCH" = "i386" -o "$ARCH" = "x86_64" ]
        then
            PLATFORM="iPhoneSimulator"
            CPU=
            if [ "$ARCH" = "x86_64" ]
            then
                SIMULATOR="-mios-simulator-version-min=7.0"
                HOST="--host=x86_64-apple-darwin"
            else
                SIMULATOR="-mios-simulator-version-min=5.0"
                HOST="--host=i386-apple-darwin"
            fi
        else
            PLATFORM="iPhoneOS"
            if [ $ARCH = "armv7s" ]
            then
                CPU="--cpu=swift"
            else
                CPU=
            fi
            SIMULATOR=
            HOST="--host=arm-apple-darwin"
        fi

        XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
        CC="xcrun -sdk $XCRUN_SDK clang -Wno-error=unused-command-line-argument-hard-error-in-future"
        AS="$CWD/$SOURCE/extras/gas-preprocessor.pl $CC"
        CFLAGS="-arch $ARCH $SIMULATOR"
        if ! xcodebuild -version | grep "Xcode [1-6]\."
        then
        CFLAGS="$CFLAGS -fembed-bitcode"
        fi
        CXXFLAGS="$CFLAGS"
        LDFLAGS="$CFLAGS"

        CC=$CC CFLAGS=$CXXFLAGS LDFLAGS=$LDFLAGS CPPFLAGS=$CXXFLAGS CXX=$CC CXXFLAGS=$CXXFLAGS  $CWD/$SOURCE/configure \
        $CONFIGURE_FLAGS \
        $HOST \
        --prefix="$THIN/$ARCH" \
        --disable-shared \
        --without-mp4v2

        make clean && make && make install-strip
        cd $CWD
    done
fi

if [ "$LIPO" ]
then
    echo "building fat binaries..."
    mkdir -p $FAT/lib
    set - $ARCHS
    CWD=`pwd`
    cd $THIN/$1/lib
    for LIB in *.a
    do
        cd $CWD
        lipo -create `find $THIN -name $LIB` -output $FAT/lib/$LIB
    done

    cd $CWD
    cp -rf $THIN/$1/include $FAT
fi

rm -r $THIN
rm -r $SCRATCH

