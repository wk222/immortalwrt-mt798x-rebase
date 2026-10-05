
define Device/qihoo_360t7-mtkuboot
  DEVICE_VENDOR := Qihoo
  DEVICE_MODEL := 360T7
  DEVICE_VARIANT := (MTK U-Boot layout)
  DEVICE_DTS := mt7981b-qihoo-360t7-mtkuboot
  DEVICE_DTS_DIR := ../dts
  DEVICE_PACKAGES := kmod-mt7915e kmod-mt7981-firmware mt7981-wo-firmware
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  IMAGE_SIZE := 98304k
  KERNEL_IN_UBI := 1
  IMAGES += factory.bin
  IMAGE/factory.bin := append-ubi | check-size $$$$(IMAGE_SIZE)
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  KERNEL := kernel-bin | lzma | fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb
endef
TARGET_DEVICES += qihoo_360t7-mtkuboot
