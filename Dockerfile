# THIS DOCKERFILE TRIES TO COMPILE OPENSSL FOR ANDROID
FROM ubuntu

MAINTAINER Evan Lin "evanslin@gmail.com"

# Install compilation tools
RUN echo "nameserver 8.8.8.8" >> /etc/resolv.conf

RUN apt-get update && apt-get install -y \
    automake \
    build-essential \
    wget \
    p7zip-full \
    bash \
    curl


# Download SDK / NDK

RUN mkdir /Android && cd Android && mkdir output
WORKDIR /Android

RUN wget http://dl.google.com/android/android-sdk_r24.3.3-linux.tgz
RUN wget http://dl.google.com/android/ndk/android-ndk-r10e-linux-x86_64.bin

# Extracting ndk/sdk

RUN tar -xvzf android-sdk_r24.3.3-linux.tgz && \
	chmod a+x android-ndk-r10e-linux-x86_64.bin && \
	7z x android-ndk-r10e-linux-x86_64.bin


# Set ENV variables

ENV ANDROID_HOME /Android/android-sdk-linux
ENV NDK_ROOT /Android/android-ndk-r10e
ENV PATH $PATH:$ANDROID_HOME/tools
ENV PATH $PATH:$ANDROID_HOME/platform-tools

# Make stand alone toolchain (Modify platform / arch here)

RUN mkdir=toolchain-arm && bash $NDK_ROOT/build/tools/make-standalone-toolchain.sh --verbose --platform=android-19 --install-dir=toolchain-arm --arch=arm --toolchain=arm-linux-androideabi-clang3.6 --llvm-version=3.6 --system=linux-x86_64 --stl=libc++

ENV TOOLCHAIN /Android/toolchain-arm
ENV SYSROOT $TOOLCHAIN/sysroot
ENV PATH $PATH:$TOOLCHAIN/bin:$SYSROOT/usr/local/bin

# Configure toolchain path

ENV ARCH armv7

#ENV CROSS_COMPILE arm-linux-androideabi
ENV CC arm-linux-androideabi-clang
ENV CXX arm-linux-androideabi-clang++
ENV AR arm-linux-androideabi-ar
ENV AS arm-linux-androideabi-as
ENV LD arm-linux-androideabi-ld
ENV RANLIB arm-linux-androideabi-ranlib
ENV NM arm-linux-androideabi-nm
ENV STRIP arm-linux-androideabi-strip
ENV CHOST arm-linux-androideabi

ENV CXXFLAGS -std=c++14 -Wno-error=unused-command-line-argument

# download, configure and make Zlib

RUN curl -O http://zlib.net/zlib-1.2.8.tar.gz && \
	tar -xzf zlib-1.2.8.tar.gz && \
	mv zlib-1.2.8 zlib
RUN cd zlib && ./configure --static && \
	make && \
	ls -hs . && \
	cp libz.a /Android/output

# open ssl


ENV CPPFLAGS -mthumb -mfloat-abi=softfp -mfpu=vfp -march=$ARCH  -DANDROID

RUN curl -O https://www.openssl.org/source/openssl-1.0.2d.tar.gz && \
	tar -xzf openssl-1.0.2d.tar.gz


# Build armv7
RUN ls && cd openssl-1.0.2d && ./Configure android-armv7 no-asm no-shared --static --with-zlib-include=/Android/zlib/include --with-zlib-lib=/Android/zlib/lib && \
	make build_crypto build_ssl -j 4 && ls && cp libcrypto.a /Android/output/libcrypto_armv7.a && cp libssl.a /Android/output/libssl_armv7.a && make clean
RUN cp -r openssl-1.0.2d /Android/output/openssl-armv7

# Build android-x86
RUN ls && cd openssl-1.0.2d && ./Configure android-x86 no-asm no-shared --static --with-zlib-include=/Android/zlib/include --with-zlib-lib=/Android/zlib/lib && \
	make build_crypto build_ssl -j 4 && ls && cp libcrypto.a /Android/output/libcrypto_x86.a && cp libssl.a /Android/output/libssl_x86.a && make clean
RUN cp -r openssl-1.0.2d /Android/output/openssl-x86

# Build android-mips
RUN ls && cd openssl-1.0.2d && ./Configure android-mips no-asm no-shared --static --with-zlib-include=/Android/zlib/include --with-zlib-lib=/Android/zlib/lib && \
	make build_crypto build_ssl -j 4 && ls && cp libcrypto.a /Android/output/libcrypto_mips.a && cp libssl.a /Android/output/libssl_mips.a && make clean
RUN cp -r openssl-1.0.2d /Android/output/openssl-mips

# To get the results run container with output folder
# Example: docker run -v HOSTFOLDER:/output --rm=true IMAGENAME 
ENTRYPOINT cp -r /Android/output/* /output