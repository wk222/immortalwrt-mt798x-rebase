#!/usr/bin/env python3
"""Apply the 360T7 hanwckf-U-Boot overlay onto an official OpenWrt tree.

usage: apply_overlay.py <openwrt_dir> <overlay_dir>
"""
import re
import shutil
import sys
from pathlib import Path

ow = Path(sys.argv[1])
ov = Path(sys.argv[2])

# 1. DTS
dts_dst = ow / "target/linux/mediatek/dts/mt7981b-qihoo-360t7-mtkuboot.dts"
shutil.copyfile(ov / "dts/mt7981b-qihoo-360t7-mtkuboot.dts", dts_dst)

# 2. device definition (insert right after the upstream 360t7-ubi device)
mk = ow / "target/linux/mediatek/image/filogic.mk"
text = mk.read_text(encoding="utf-8")
if "qihoo_360t7-mtkuboot" in text:
    print("filogic.mk already patched")
else:
    marker = "TARGET_DEVICES += qihoo_360t7-ubi\n"
    assert marker in text, "marker not found in filogic.mk"
    block = (ov / "device_block.mk").read_text(encoding="utf-8")
    text = text.replace(marker, marker + block, 1)
    mk.write_text(text, encoding="utf-8")
    print("filogic.mk patched")

# 3. board.d/02_network : lan/wan ports + MAC derivation (same as qihoo,360t7)
net = ow / "target/linux/mediatek/filogic/base-files/etc/board.d/02_network"
t = net.read_text(encoding="utf-8")
if "qihoo,360t7-mtkuboot" not in t:
    n_before = t.count("\tqihoo,360t7-ubi|\\\n")
    assert n_before == 1, f"unexpected 02_network layout ({n_before})"
    t = t.replace("\tqihoo,360t7-ubi|\\\n", "\tqihoo,360t7-ubi|\\\n\tqihoo,360t7-mtkuboot|\\\n", 1)
    new_case = "\tqihoo,360t7|\\\n\tqihoo,360t7-mtkuboot)\n"
    t, n = re.subn(r"\tqihoo,360t7\)\n", lambda m: new_case, t, count=1)
    assert n == 1, "MAC case for qihoo,360t7 not found"
    net.write_text(t, encoding="utf-8")
    print("02_network patched")

# 4. copy rootfs overlay files
files_src = ov / "files"
files_dst = ow / "files"
if files_src.exists():
    shutil.copytree(files_src, files_dst, dirs_exist_ok=True)
    print("files/ copied")

# 5. HomeProxy: offline SRS + ujail resources + do not kill client when server config fails
hp_init = ow / "package/feeds/immortalluci/luci-app-homeproxy/root/etc/init.d/homeproxy"
if hp_init.is_file():
    t = hp_init.read_text(encoding="utf-8")
    gen = 'ucode -S "$HP_DIR/scripts/generate_client.uc" 2>>"$LOG_PATH"'
    if "patch_local_srs.uc" not in t and gen in t:
        t = t.replace(
            gen,
            gen + '\n\t\tucode -S "$HP_DIR/scripts/patch_local_srs.uc" 2>>"$LOG_PATH"',
            1,
        )
    jail_certs = '\t\t\tprocd_add_jail_mount "$HP_DIR/certs/"'
    jail_res = '\t\t\tprocd_add_jail_mount "$HP_DIR/resources/"'
    if jail_res not in t and jail_certs in t:
        t = t.replace(jail_certs, jail_res + "\n" + jail_certs, 1)
    old_srv = (
        '\t\tif [ ! -e "$RUN_DIR/sing-box-s.json" ]; then\n'
        '\t\t\tlog "Error: failed to generate server configuration."\n'
        "\t\t\treturn 1\n"
    )
    new_srv = (
        '\t\tif [ ! -e "$RUN_DIR/sing-box-s.json" ]; then\n'
        '\t\t\tlog "Warning: failed to generate server configuration, skip server."\n'
        "\t\t\tserver_enabled=0\n"
    )
    if old_srv in t:
        t = t.replace(old_srv, new_srv, 1)
    hp_init.write_text(t, encoding="utf-8")
    print("homeproxy init patched")
else:
    print("WARN: homeproxy init not found (feeds install order?)")
