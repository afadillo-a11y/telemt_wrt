include $(TOPDIR)/rules.mk

PKG_NAME        := telemt
PKG_VERSION     := 3.3.29
PKG_RELEASE     := 1

PKG_SOURCE_PROTO   := git
PKG_SOURCE_URL     := https://github.com/telemt/telemt.git
PKG_SOURCE_VERSION := $(PKG_VERSION)
PKG_SOURCE_DATE    := $(PKG_VERSION)
PKG_MIRROR_HASH    := skip

PKG_BUILD_DIR      := $(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

PKG_MAINTAINER  := afadillo-a11y
PKG_LICENSE     := GPL-2.0-only

PKG_BUILD_DEPENDS := rust/host
PKG_BUILD_PARALLEL := 1


include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/rust/rust-package.mk

CARGO_PROFILE_ENV := \
	CARGO_PROFILE_RELEASE_OPT_LEVEL=z \
	CARGO_PROFILE_RELEASE_LTO=true \
	CARGO_PROFILE_RELEASE_CODEGEN_UNITS=1 \
	CARGO_PROFILE_RELEASE_PANIC=abort \
	CARGO_PROFILE_RELEASE_STRIP=true

define Package/telemt
  SECTION   := net
  CATEGORY  := Network
  TITLE     := Telemt — Telegram MTProxy daemon (Rust, musl)
  URL       := https://github.com/afadillo-a11y/telemt_wrt
  DEPENDS   := $(RUST_ARCH_DEPENDS) @(aarch64||arm||x86_64||i386||mipsel||mips||mips64el||riscv64)
endef

define Package/telemt/description
  Lightweight headless Telegram MTProxy daemon written in Rust + Tokio.
endef

define Package/telemt/conffiles
/etc/config/telemt
endef

define Build/Prepare
	$(call Build/Prepare/Default)
	# CRITICAL: нормализация CRLF в OpenWrt-скриптах.
	# (повторяет шаг "Fix CRLF line endings in scripts" из workflow)
	sed -i 's/\r//;1s/^\xef\xbb\xbf//' $(CURDIR)/files/telemt.init
	sed -i 's/\r//;1s/^\xef\xbb\xbf//' $(CURDIR)/files/telemt.config
endef

define Build/Configure
	# Rust-проекты не требуют autoconf/cmake
	@echo "telemt: target arch=$(ARCH), Rust triple=$(RUST_TARGET)"
endef

define Package/telemt/install
	$(INSTALL_DIR)  $(1)/usr/bin
	$(INSTALL_BIN)  $(PKG_INSTALL_DIR)/bin/telemt $(1)/usr/bin/telemt

	$(INSTALL_DIR)  $(1)/etc/init.d
	$(INSTALL_BIN)  $(CURDIR)/files/telemt.init   $(1)/etc/init.d/telemt

	$(INSTALL_DIR)  $(1)/etc/config
	$(INSTALL_CONF) $(CURDIR)/files/telemt.config $(1)/etc/config/telemt
endef

define Package/telemt/postinst
#!/bin/sh
if pidof telemt >/dev/null 2>&1; then
    killall -9 telemt 2>/dev/null || true
fi

if [ -d "/etc/telemt" ]; then
    mv /etc/telemt /etc/telemt.disabled_by_luci 2>/dev/null || true
fi

old_metrics=$$(uci -q get telemt.general.metrics_port 2>/dev/null)
if [ "$$old_metrics" = "9091" ] || [ "$$old_metrics" = "9090" ]; then
    uci set telemt.general.metrics_port='9092'
    uci set telemt.general.api_port='9091'
    uci commit telemt 2>/dev/null || true
fi

[ -x /etc/init.d/telemt ] && /etc/init.d/telemt enable 2>/dev/null || true
exit 0
endef

define Package/telemt/prerm
#!/bin/sh
[ -x /etc/init.d/telemt ] && /etc/init.d/telemt disable 2>/dev/null || true
[ -x /etc/init.d/telemt ] && /etc/init.d/telemt stop   2>/dev/null || true
exit 0
endef

define Package/telemt/postrm
#!/bin/sh
rm -f /var/etc/telemt.toml
rm -f /var/etc/telemt.version
rm -f /tmp/telemt_stats.txt
exit 0
endef

$(eval $(call RustBinPackage,telemt))
$(eval $(call BuildPackage,telemt))
