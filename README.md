# 360T7: 官方 OpenWrt 25.12.5 + mt76 + hanwckf U-Boot

此分支只放“叠加层”(overlay)和工作流, 编译时现场拉取 `openwrt/openwrt@v25.12.5`:

- `overlay/dts/mt7981b-qihoo-360t7-mtkuboot.dts` — 在官方 `qihoo,360t7` 之上加 NMBM, 并去掉 `fit` 卷/`root=/dev/fit0`
- `overlay/device_block.mk` — 新设备 `qihoo_360t7-mtkuboot`, 输出 UBI `factory.bin`(kernel + rootfs 卷)和 `sysupgrade.bin`
- `overlay/files/` — 默认 LAN 192.168.10.1、WAN/LAN 网段冲突自动迁移、HomeProxy 离线规则集
- `scripts/apply_overlay.py` — 把以上改动打进官方源码树
- `.github/workflows/build-t7-official-mt76.yml` — 手动触发编译

HomeProxy 的 LuCI 来自 immortalwrt/luci(官方没有), sing-box 用 ImmortalWrt 的 1.12.25(官方是 1.13.x, HomeProxy 尚未适配)。
