FROM pauletaylor/glibc-builder:latest as alpine-glibc-builder

ARG GLIBC_VER=2.32

RUN /builder ${GLIBC_VER} /usr/glibc-compat -j || true

FROM alpine:latest as alpine-glibc-packager

RUN apk --no-cache add alpine-sdk sudo

ARG GLIBC_VER=2.32

WORKDIR /home/builder/package

ENV REPODEST /alpine-glibc-packages

RUN mkdir -p "$REPODEST" \
 && adduser -D builder -G abuild root \
 && chown -R builder:abuild "$REPODEST" /home/builder/package \
 && echo builder:builder | chpasswd && echo "builder ALL=(ALL) ALL" >> /etc/sudoers.d/builder \
 && su builder -c 'echo "builder" | sudo -S echo "generating APK keys" && abuild-keygen -ain'

COPY --chown=builder:abuild glibc-bin.trigger nsswitch.conf ld.so.conf /home/builder/package/
COPY --chown=builder:abuild --from=alpine-glibc-builder /glibc-bin-${GLIBC_VER}.tar.gz /home/builder/package/

RUN ARCH="$(apk --print-arch)" \
 && echo -e "\
pkgname=\"glibc\"\n\
pkgver=\"${GLIBC_VER}\"\n\
pkgrel=\"0\"\n\
pkgdesc=\"GNU C Library compatibility layer\"\n\
arch=\"${ARCH}\"\n\
url=\"https://github.com/trxcllnt/alpine-glibc-packager\"\n\
license=\"LGPL\"\n\
source=\"\n\
glibc-bin-${GLIBC_VER}.tar.gz\n\
nsswitch.conf\n\
ld.so.conf\"\n\
options=\"!check\"\n\
subpackages=\"\$pkgname-bin \$pkgname-dev \$pkgname-i18n\"\n\
triggers=\"\$pkgname-bin.trigger=/lib:/usr/lib:/usr/local/lib:/usr/glibc-compat/lib\"\n\
\n\
package() {\n\
  mkdir -p \"\$pkgdir/lib\" \"\$pkgdir/usr/glibc-compat/lib/locale\"  \"\$pkgdir/usr/glibc-compat/lib\" \"\$pkgdir/etc\"\n\
  cp -a \"\$srcdir/usr\" \"\$pkgdir\"\n\
  cp \"\$srcdir/ld.so.conf\" \"\$pkgdir/usr/glibc-compat/etc/ld.so.conf\"\n\
  cp \"\$srcdir/nsswitch.conf\" \"\$pkgdir/etc/nsswitch.conf\"\n\
  rm \"\$pkgdir/usr/glibc-compat/etc/rpc\"\n\
  rm -rf \"\$pkgdir/usr/glibc-compat/bin\"\n\
  rm -rf \"\$pkgdir/usr/glibc-compat/sbin\"\n\
  rm -rf \"\$pkgdir/usr/glibc-compat/lib/gconv\"\n\
  rm -rf \"\$pkgdir/usr/glibc-compat/lib/getconf\"\n\
  rm -rf \"\$pkgdir/usr/glibc-compat/lib/audit\"\n\
  rm -rf \"\$pkgdir/usr/glibc-compat/share\"\n\
  rm -rf \"\$pkgdir/usr/glibc-compat/var\"\n\
  case \"${ARCH}\" in\n\
    armhf|armv7l|aarch64|arm64) \n\
      ln -s \"/usr/glibc-compat/etc/ld.so.cache\" \"\$pkgdir/etc/ld-musl-${ARCH}.path\";\n\
      ;;\n\
    *)\n\
      ln -s \"/usr/glibc-compat/etc/ld.so.cache\" \"\$pkgdir/etc/ld.so.cache\";\n\
      ;;\n\
  esac\n\
  for x in \"\" \".0\" \".1\" \".2\" \".3\"; do\n\
    if [ -f \"/usr/glibc-compat/lib/ld-linux-${ARCH}.so\$x\" ]; then\n\
        if [ -d \"\$pkgdir/lib\" ]; then\n\
            ln -s \"/usr/glibc-compat/lib/ld-linux-${ARCH}.so\$x\" \"\$pkgdir/lib/ld-linux-${ARCH}.so\$x\"\n\
        fi\n\
        if [ -d \"\$pkgdir/lib64\" ]; then\n\
            ln -s \"/usr/glibc-compat/lib/ld-linux-${ARCH}.so\$x\" \"\$pkgdir/lib64/ld-linux-${ARCH}.so\$x\"\n\
        fi\n\
    fi\n\
  done;\n\
}\n\
\n\
bin() {\n\
  depends=\"\$pkgname libgcc\"\n\
  mkdir -p \"\$subpkgdir/usr/glibc-compat\"\n\
  cp -a \"\$srcdir/usr/glibc-compat/bin\" \"\$subpkgdir/usr/glibc-compat\"\n\
  cp -a \"\$srcdir/usr/glibc-compat/sbin\" \"\$subpkgdir/usr/glibc-compat\"\n\
}\n\
\n\
i18n() {\n\
  depends=\"\$pkgname-bin\"\n\
  arch=\"noarch\"\n\
  mkdir -p \"\$subpkgdir/usr/glibc-compat\"\n\
  cp -a \"\$srcdir/usr/glibc-compat/share\" \"\$subpkgdir/usr/glibc-compat\"\n\
}\n\
\n\
sha512sums=\"\
$(sha512sum glibc-bin-${GLIBC_VER}.tar.gz)\n\
$(sha512sum nsswitch.conf)\n\
$(sha512sum ld.so.conf)\"\n\
" > /home/builder/package/APKBUILD

USER builder

CMD ["abuild -r"]
