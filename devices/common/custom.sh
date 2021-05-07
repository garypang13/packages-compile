#!/bin/bash

shopt -s extglob

sed -i '/	refresh_config();/d' scripts/feeds

rm -rf feeds/custom/{frp,xray-core,oaf,luci-app-{turboacc,mtwifi},naiveproxy,aria2,MentoHUST*}
rm -rf feeds/packages/libs/!(ncurses)
rm -Rf feeds/luci/{applications,collections,protocols,themes,libs}
rm -Rf feeds/luci/modules/!(luci-base)

rm -Rf feeds/packages/!(lang|libs|devel|utils|net)
rm -Rf feeds/packages/utils/!(pcsc-lite|xz)
rm -Rf feeds/packages/net/!(mosquitto|curl)
rm -Rf feeds/packages/lang/!(python)
rm -Rf feeds/base/package/{kernel,firmware}
rm -Rf feeds/base/package/network/!(services)
rm -Rf feeds/base/package/network/services/!(ppp)
rm -Rf feeds/base/package/utils/!(util-linux|lua)
rm -Rf feeds/base/package/system/!(opkg|uci|ubus)
rm -Rf feeds/custom/luci-app-*/po/!(zh_Hans)

svn co https://github.com/immortalwrt/packages/trunk/lang/golang feeds/packages/lang/golang

./scripts/feeds update -a
./scripts/feeds install -a

sed -i 's/Os/O2/g' include/target.mk
rm -rf ./feeds/packages/lang/golang
svn co https://github.com/immortalwrt/packages/trunk/lang/golang feeds/packages/lang/golang
sed -i "s/+nginx\( \|$\)/+nginx-ssl\1/g"  package/feeds/custom/*/Makefile
sed -i 's/+python\( \|$\)/+python3/g' package/feeds/custom/*/Makefile
sed -i 's?../../lang?$(TOPDIR)/feeds/packages/lang?g' package/feeds/custom/*/Makefile
for ipk in $(find package/feeds/custom/* -maxdepth 0); do	
	if [[ ! -d "$ipk/patches" && ! "$(grep "codeload.github.com" $ipk/Makefile)" ]]; then
		find $ipk/ -maxdepth 1 -name "Makefile" ! -path *tcping* \
		| xargs -i sed -i "s/PKG_SOURCE_VERSION:=[0-9a-z]\{15,\}/PKG_SOURCE_VERSION:=HEAD/g" {}
	fi
done
sed -i 's/$(VERSION) &&/$(VERSION) ;/g' include/download.mk

for ipk in $(ls package/feeds/custom | grep "luci-"); do		
    echo "$ipk" >> ipk
done

echo '
sub-web
ddns-scripts-aliyun
ddns-scripts-dnspod
mwan3
cdnspeedtest
qBittorrent
bpytop
pandownload-fake-server
' >> ipk

mv feeds/base feeds/base.bak
mv feeds/packages feeds/packages.bak
make defconfig
rm -Rf tmp
mv feeds/base.bak feeds/base
mv feeds/packages.bak feeds/packages
sed -i 's/CONFIG_ALL=y/CONFIG_ALL=n/' .config

sed -i 's,$(STAGING_DIR_HOST)/bin/upx,upx,' package/feeds/custom/*/Makefile

sed -i "/mediaurlbase/d" package/*/*/luci-theme*/root/etc/uci-defaults/*

sed -i '/WARNING: Makefile/d' scripts/package-metadata.pl

