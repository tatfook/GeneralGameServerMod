#!/bind/bash

# Android
ANDROID_DIRECTORY=`pwd`;
ANDROID_PROJECT_DIRECTORY=${ANDROID_DIRECTORY}/AndroidStudioProjects
ANDROID_SDK_DIRECTORY=${ANDROID_DIRECTORY}/sdk

# Paracraft
PARACRAFT_PROJECT_NAME=AndroidNPLRuntime
PARACRAFT_PROJECT_DIRECTORY=${ANDROID_PROJECT_DIRECTORY}/${PARACRAFT_PROJECT_NAME}

#cd ${ANDROID_PROJECT_DIRECTORY}
#git clone https://gitee.com/__xiaoyao__/NPLRuntime.git ${PARACRAFT_PROJECT_NAME}
#
## 切换分支
#cd ${PARACRAFT_PROJECT_NAME}
##git fetch -p
##git checkout -b cp_old origin/cp_old
#
## 下载资源文件
#cd NPLRuntime/Platform/AndroidStudio/app
#git clone https://gitee.com/__xiaoyao__/ParacraftAssets assets
## TODO 拷贝正式环境PC版根目下的*.pkg,assets_manifest.txt 文件到assets目录内
#
## 下载交叉编译ndk
#mkdir -p ${ANDROID_SDK_DIRECTORY}/ndk
#cd ${ANDROID_SDK_DIRECTORY}/ndk
#wget "https://dl.google.com/android/repository/android-ndk-r14b-linux-x86_64.zip" -O android-ndk-r14b-linux-x86_64.zip
#unzip android-ndk-r14b-linux-x86_64.zip
## 导出NDK环境变量
#export ANDROID_NDK=${ANDROID_SDK_DIRECTORY}/ndk/android-ndk-r14b
#
## 准备编译boost
#
## 安装jdk
#apt install -y openjdk-11-jdk
## 安装ninja https://github.com/ninja-build/ninja/releases
#apt install -y ninja-build
## 安装cmake-3.14.5
#CMAKE_DIRECTORY=${ANDROID_SDK_DIRECTORY}/cmake
#mkdir -p ${CMAKE_DIRECTORY}
#cd ${CMAKE_DIRECTORY}
#wget https://cmake.org/files/v3.14/cmake-3.14.5.tar.gz
#tar -xvf cmake-3.14.5.tar.gz
#mv cmake-3.14.5 3.14.5
#cd cmake-3.14.5
#./configure --prefix=`pwd`
#make
#make install
## 编译boost
#cd ${PARACRAFT_PROJECT_DIRECTORY}/NPLRuntime/externals/boost
#mkdir -p prebuild/src
#bash -x build_android.sh
#cd prebuild/src/boost_1_73_0
#./bootstrap.sh --with-libraries="thread,date_time,filesystem,system,chrono,serialization,iostreams,regex" 
#./b2 link=static threading=multi variant=release
#./b2 install

## 编译打包APK
cd ${PARACRAFT_PROJECT_DIRECTORY}/NPLRuntime/Platform/AndroidStudio
echo sdk.dir=${ANDROID_SDK_DIRECTORY} > local.properties
echo ndk.dir=${ANDROID_SDK_DIRECTORY}/ndk/android-ndk-r14b >> local.properties
echo cmake.dir=${ANDROID_SDK_DIRECTORY}/cmake/3.14.5 >> local.properties
#
## 禁用CAD部分
#sed -i 's/-DNPLRUNTIME_OCE=TRUE/-DNPLRUNTIME_OCE=FALSE/' app/build.gradle 

## 安装 android 相关工具
#cd ${ANDROID_DIRECTORY}
#wget https://dl.google.com/android/repository/commandlinetools-linux-6858069_latest.zip -O commandlinetools-linux.zip
#unzip commandlinetools-linux.zip
#cd cmdline-tools/bin
#echo y | ./sdkmanager "build-tools;30.0.3" --sdk_root=${ANDROID_SDK_DIRECTORY}
#./sdkmanager "platform-tools" --sdk_root=${ANDROID_SDK_DIRECTORY}
#./sdkmanager "sources;android-30" --sdk_root=${ANDROID_SDK_DIRECTORY}

## jdk 安装
#mkdir /usr/lib/jvm
#cd /usr/lib/jvm
#wget https://download.oracle.com/otn-pub/java/jdk/16+36/7863447f0ab643c585b9bdebf67c69db/jdk-16_linux-x64_bin.tar.gz?AuthParam=1618205506_00c3c8d9a00b366c60ea77da490dd4d7 -O jdk-16_linux-x64_bin.tar.gz
#tar -xvf jdk-16_linux-x64_bin.tar.gz
# jdk 版本高了 grade也需要高版本支持 否则报 Could not initialize class org.codehaus.groovy.runtime.InvokerHelper
#sed -i 's/gradle-6.1.1-all.zip/gradle-6.4.1-all.zip/' gradle/wrapper/gradle-wrapper.properties 

# 打包apk
#bash gradlew assembleDebug