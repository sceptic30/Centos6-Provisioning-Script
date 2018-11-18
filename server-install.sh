#!/bin/sh
yum -y update
yum groupinstall -y 'Development Tools'
yum install -y yum-utils wget
yum -y update
yum-config-manager --add-repo http://people.centos.org/tru/devtools-2/devtools-2.repo
yum-config-manager --enable devtools-2
yum install -y devtoolset-2-gcc.x86_64 devtoolset-2-gcc-c++.x86_64 binutils.x86_64 devtoolset-2-binutils.x86_64 devtoolset-2-binutils-devel.x86_64
yum -y update
ln -s /opt/rh/devtoolset-2/root/usr/bin/* /usr/local/bin/
hash -r
gcc --version
#
echo -e "Installing fedoraproject remi and epel repo..!!"
#
rpm --import https://fedoraproject.org/static/0608B895.txt 
rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
rpm --import http://rpms.famillecollet.com/RPM-GPG-KEY-remi
rpm -ivh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
rpm -ivh https://dl.iuscommunity.org/pub/ius/stable/CentOS/6/x86_64/ius-release-1.0-14.ius.centos6.noarch.rpm
yum localinstall -y --nogpgcheck http://download1.rpmfusion.org/free/el/updates/6/x86_64/rpmfusion-free-release-6-1.noarch.rpm
yum localinstall -y --nogpgcheck ftp://ftp.pbone.net/mirror/ftp5.gwdg.de/pub/opensuse/repositories/home:/sawaa/CentOS_CentOS-6/x86_64/checkinstall-1.6.2-3.el6.1.x86_64.rpm
cd
#
echo -e "gcc is installed....!"
wget http://dl.iuscommunity.org/pub/ius/stable/CentOS/6/x86_64/ius-release-1.0-14.ius.centos6.noarch.rpm
yum-config-manager --enable epel remi remi-php56 rpmfusion-free-updates rpmfusion-free-release ius
echo -e "Finished repos installation"
#
yum -y update
echo -e "Starting server libraries installation....."
yum install -y pcre.x86_64 pcre-devel.x86_64 zlib zlib-devel make unzip libtool binutils gedit.x86_64 openssl-devel
yum install -y php-pecl-geoip.x86_64 GeoIP-devel.x86_64 GeoIP.x86_64 perl-Geo-IP.x86_64
yum install -y ghc-zlib.x86_64 perl-Compress-Zlib.x86_64 zlib-devel.x86_64 zlib-static.x86_64 zlibrary-devel.x86_64 ghc-zlib-devel.x86_64 zlibrary.x86_64 libcap-devel
yum install -y haproxy monit vsftpd ftp v4l-utils
echo -e "Installing Google pagespeed module...."
#
mkdir /build
cd /build

NPS_VERSION=1.13.35.1-beta
wget https://github.com/pagespeed/ngx_pagespeed/archive/release-${NPS_VERSION}-beta.zip -O release-${NPS_VERSION}-beta.zip
unzip release-${NPS_VERSION}-beta.zip
cd ngx_pagespeed-release-${NPS_VERSION}-beta/
wget https://dl.google.com/dl/page-speed/psol/${NPS_VERSION}.tar.gz
tar -xzvf ${NPS_VERSION}.tar.gz

echo -e "Installing Nginx Server....."
cd /build
NGINX_VERSION=1.14.1
PS_NGX_EXTRA_FLAGS="--with-cc=/opt/rh/devtoolset-2/root/usr/bin/gcc"
git clone https://github.com/FRiCKLE/ngx_cache_purge.git
git clone https://github.com/sceptic30/nginx-rtmp-module.git
wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
tar -xvzf nginx-${NGINX_VERSION}.tar.gz
cd nginx-${NGINX_VERSION}
./configure --prefix=/opt/nginx --add-module=/build/nginx-rtmp-module --add-module=/build/ngx_cache_purge --add-module=/build/ngx_pagespeed-release-${NPS_VERSION}-beta ${PS_NGX_EXTRA_FLAGS} --with-http_geoip_module --with-http_v2_module --with-http_realip_module --with-http_gzip_static_module --with-http_stub_status_module --with-http_ssl_module --with-http_addition_module --with-http_sub_module --with-http_dav_module --with-http_gunzip_module --with-http_random_index_module --with-http_secure_link_module --with-http_auth_request_module --with-mail --with-mail_ssl_module --with-file-aio --with-ipv6
make
make install
make distclean
#
echo -e "Installing php and mysql-server...."
yum install -y php php-fpm php-cli php-mysql php-gd php-imap php-ldap php-odbc php-pear php-xml php-xmlrpc php-magickwand php-magpierss php-mbstring php-mcrypt php-mssql php-shout php-snmp php-soap php-tidy mysql mysql-server phpmyadmin php-pear-Net-SMTP php-pear-Auth-SASL php-pear-Net-Socket php-pear-Net-IDNA2 php-pear-Mail-Mime php-pear-Mail-mimeDecode opendkim libopendkim-devel libopendkim
chown root:root -R /var/lib/php/session
chmod 1733 -R /var/lib/php/session
chkconfig php-fpm on
chkconfig mysqld on
#
echo '#!/bin/sh
#
# nginx - this script starts and stops the nginx deamon
#
# chkconfig:   - 85 15 
# description:  Nginx is an HTTP(S) server, HTTP(S) reverse \
#               proxy and IMAP/POP3 proxy server
# processname: nginx
# config:      /opt/nginx/conf/nginx.conf
# pidfile:     /opt/nginx/logs/nginx.pid

# Source function library.
. /etc/rc.d/init.d/functions

# Source networking configuration.
. /etc/sysconfig/network

# Check that networking is up.
[ "$NETWORKING" = "no" ] && exit 0

nginx="/opt/nginx/sbin/nginx"
prog=$(basename $nginx)

NGINX_CONF_FILE="/opt/nginx/conf/nginx.conf"

lockfile=/var/lock/subsys/nginx

start() {
    [ -x $nginx ] || exit 5
    [ -f $NGINX_CONF_FILE ] || exit 6
    echo -n $"Starting $prog: "
    daemon $nginx -c $NGINX_CONF_FILE
    retval=$?
    echo
    [ $retval -eq 0 ] && touch $lockfile
    return $retval
}

stop() {
    echo -n $"Stopping $prog: "
    killproc $prog -QUIT
    retval=$?
    echo
    [ $retval -eq 0 ] && rm -f $lockfile
    return $retval
}

restart() {
    configtest || return $?
    stop
    start
}

reload() {
    configtest || return $?
    echo -n $"Reloading $prog: "
    killproc $nginx -HUP
    RETVAL=$?
    echo
}

force_reload() {
    restart
}

configtest() {
  $nginx -t -c $NGINX_CONF_FILE
}

rh_status() {
    status $prog
}

rh_status_q() {
    rh_status >/dev/null 2>&1
}

case "$1" in
    start)
        rh_status_q && exit 0
        $1
        ;;
    stop)
        rh_status_q || exit 0
        $1
        ;;
    restart|configtest)
        $1
        ;;
    reload)
        rh_status_q || exit 7
        $1
        ;;
    force-reload)
        force_reload
        ;;
    status)
        rh_status
        ;;
    condrestart|try-restart)
        rh_status_q || exit 0
            ;;
    *)
        echo $"Usage: $0 {start|stop|status|restart|condrestart|try-restart|reload|force-reload|configtest}"
        exit 2
esac' >> /etc/init.d/nginx
#
chmod +x /etc/init.d/nginx
chkconfig nginx on
#
echo 'pathmunge /opt/nginx/sbin' > /etc/profile.d/nginx.sh
chmod +x /etc/profile.d/nginx.sh
ldconfig
cd
useradd nicolas
mkdir /home/nicolas/html_public/
chown nicolas:nicolas -R /home/nicolas/html_public/
chmod 755 -R /home/nicolas/html_public/
#
yum install -y glibc hg autoconf automake git make nasm pkgconfig SDL-devel a52dec a52dec-devel alsa-lib-devel faad2-libs faad2 faad2-devel freetype-devel giflib gsm gsm-devel imlib2 imlib2-devel lame lame-devel libICE-devel libSM-devel libX11-devel libXau-devel libXdmcp-devel libXext-devel libXrandr-devel libXrender-devel libXt-devel libogg libvorbis vorbis-tools mesa-libGL-devel mesa-libGLU-devel xorg-x11-proto-devel zlib-devel libtheora theora-tools ncurses-devel libdc1394 libdc1394-devel opencore-amr opencore-amr-devel vo-amrwbenc libvpx-devel.x86_64 libvpx.x86_64 libvpx-utils.x86_64 speex-devel cmake rpmdevtools
#rpmdev-setuptree
cd /build
mkdir ffmpeg_sources
#
cd ffmpeg_sources
git clone --depth 1 git://github.com/yasm/yasm.git
cd yasm
autoreconf -fiv
./configure --prefix="/opt/ffmpeg" --bindir="/opt/ffmpeg/bin"
make
make install
ln -s /opt/ffmpeg/bin/* /usr/local/bin/
hash -r
yasm -version
echo -e "System Configured To Use yasm version"
#
cd /build/ffmpeg_sources
git clone http://git.videolan.org/git/x264.git
cd x264
./configure --prefix="/opt/ffmpeg" --enable-static
make
make install
make distclean
#
cd /build/ffmpeg_sources
hg clone http://hg.videolan.org/x265
cd x265/build/linux
cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="/opt/ffmpeg" -DENABLE_SHARED:bool=off ../../source
make -j4
make install

#
cd /build/ffmpeg_sources
git clone --depth 1 git://github.com/mstorsjo/fdk-aac.git
cd fdk-aac
autoreconf -fiv
./configure --prefix="/opt/ffmpeg" --disable-shared
make
make install
make distclean
#
cd /build/ffmpeg_sources
curl -L -O http://downloads.sourceforge.net/project/lame/lame/3.99/lame-3.99.5.tar.gz
tar xzvf lame-3.99.5.tar.gz
cd lame-3.99.5
./configure --prefix="/opt/ffmpeg" --disable-shared --enable-nasm
make
make install
make distclean
#
cd /build/ffmpeg_sources
curl -O http://downloads.xiph.org/releases/opus/opus-1.0.3.tar.gz
tar xzvf opus-1.0.3.tar.gz
cd opus-1.0.3
./configure --prefix="/opt/ffmpeg" --disable-shared
make
make install
make distclean
#
cd /build/ffmpeg_sources
curl -O http://downloads.xiph.org/releases/ogg/libogg-1.3.2.tar.gz
tar xzvf libogg-1.3.2.tar.gz
cd libogg-1.3.2
./configure --prefix="/opt/ffmpeg" --disable-shared
make
make install
make distclean
#
cd /build/ffmpeg_sources
curl -O http://downloads.xiph.org/releases/vorbis/libvorbis-1.3.5.tar.gz
tar xzvf libvorbis-1.3.5.tar.gz
cd libvorbis-1.3.5
./configure --prefix="/opt/ffmpeg" --with-ogg="/opt/ffmpeg" --disable-shared
make
make install
make distclean
#
cd /build/ffmpeg_sources
git clone --depth 1 http://git.chromium.org/webm/libvpx.git
cd libvpx
./configure --prefix="/opt/ffmpeg" --disable-examples
make
make install
make distclean
#
cd /build/ffmpeg_sources
curl -O http://downloads.xiph.org/releases/theora/libtheora-1.1.1.tar.gz
tar xzvf libtheora-1.1.1.tar.gz
cd libtheora-1.1.1
./configure --prefix="/opt/ffmpeg" --with-ogg="/opt/ffmpeg" --disable-examples --disable-shared --disable-sdltest --disable-vorbistest
make
make install
make distclean
#
cd /build/ffmpeg_sources
git clone git://git.ffmpeg.org/rtmpdump
cd rtmpdump
make
make install
LD_LIBRARY_PATH=/usr/local/lib
export LD_LIBRARY_PATH
ln -s /usr/local/lib/pkgconfig/librtmp.pc /opt/ffmpeg/lib/pkgconfig
#
cd /build/ffmpeg_sources
git clone https://github.com/FFmpeg/FFmpeg.git
cd FFmpeg
PKG_CONFIG_PATH=/opt/ffmpeg/lib/pkgconfig
export PKG_CONFIG_PATH
./configure --prefix=/opt/ffmpeg --extra-cflags="-I/opt/ffmpeg/include" --extra-ldflags="-L/opt/ffmpeg/lib" --pkg-config-flags="--static" --extra-libs="-ldl" --enable-gpl --enable-nonfree --enable-libfdk_aac --enable-libmp3lame --enable-libopus --enable-libvorbis --enable-libvpx --enable-libx264 --enable-libx265 --enable-libfreetype --enable-libspeex --enable-libtheora --enable-librtmp
make
make install
make distclean
#
echo 'pathmunge /opt/ffmpeg/bin' > /etc/profile.d/ffmpeg.sh
chmod +x /etc/profile.d/ffmpeg.sh
#
echo '/opt/ffmpeg/lib 
/usr/local/lib/' >> /etc/ld.so.conf.d/ffmpeg.conf
ldconfig
echo -e "FFmpeg installation is complete!"
#
cd
yum install -y redis php-pecl-redis
cd /build
NODE_VERSION=10.13.0
wget https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}.tar.gz
tar -xvzf node-v${NODE_VERSION}.tar.gz
cd node-v${NODE_VERSION}
./configure --prefix=/opt/node
make
make install
make distclean
echo 'pathmunge /opt/node/bin' > /etc/profile.d/node.sh
chmod +x /etc/profile.d/node.sh
ldconfig
#
cd
echo -e "NodeJS installation is complete!"
echo -e "Creating directories needed for Video Application and applying permissions..."
cd /tmp
mkdir HLS
mkdir rtmp-sockets
cd HLS
mkdir mobile
cd
chown nicolas:nicolas -R /tmp/rtmp-sockets #change the username to your preferred one. The same user your application runs usually on.
chown nicolas:nicolas -R /tmp/HLS
echo -e "Completed installing server components...!"
echo -e "Downloading Sublime Text 3....." # this block can be deleted if you wish, it installs sublime text 3
wget https://download.sublimetext.com/sublime_text_3_build_3103_x64.tar.bz2
tar vxjf sublime_text_3_build_3103_x64.tar.bz2 -C /opt
ln -s /opt/sublime_text_3/sublime_text /usr/bin/sublime
sublime /usr/share/applications/sublime.desktop
