{
   qemu-x86_64 = {
     config = "x86_64-unknown-linux-musl";
   };

#   qemu-arm = {
#     config = "armv7l-unknown-linux-musleabihf";
#     platform = {
#       name = "arm7l-hf-multiplatform";
#       kernelMajor = "2.6";
#       kernelBaseConfig = "vexpress_defconfig";
#       kernelArch = "arm";
#       kernelDTB = true;
#       kernelAutoModules = true;
#       kernelPreferBuiltin = true;
#       kernelTarget = "uImage";
#     };
#
#     gcc = {
#       arch = "armv7-a";
#       fpu = "neon-vfpv4";
#     };
#   };

   odroid-hc2 = {
     config = "armv7l-unknown-linux-musleabihf";
     platform = {
       name = "arm7l-hf-multiplatform";
       kernelMajor = "2.6";
       kernelBaseConfig = "exynos_defconfig";
       kernelArch = "arm";
       kernelDTB = true;
       kernelAutoModules = true;
       kernelPreferBuiltin = true;
       kernelTarget = "uImage";
       kernelExtraConfig = ''
         # For ODROID-XU4
         ARM_BIG_LITTLE_CPUIDLE n

         OABI_COMPAT n
         IP_SCTP y

         BT n
         NFC n # No NFC drivers
         SOUND n # No sound output on HC2
         LOGO n # No display on HC2
         FRAMEBUFFER_CONSOLE n # No display on HC2
         HID n # No HID drivers
         INPUT n # No input drivers
         CAN n # No CAN bus
         VIDEO_V4L2 n
         IRLAN n
         IRCOMM n
         IRDA_ULTRA n
         IRTTY_SIR n
         FB n # No graphics
         DVB_CORE n
         DVB_NET n

         DRM_VIRTIO_GPU n
         DRM_ARCPGU n
         DRM_ARMADA n
         DRM_ATMEL_HLCDC n
         DRM_BRIDGE n
         DRM_FSL_DCU n
         DRM_NOUVEAU n
         DRM_OMAP n
         DRM_PANEL n
         DRM_STI n
         DRM_STM n
         DRM_TILCDC n
         DRM_TINYDRM n
         DRM_TTM n
         DRM_UDL n
         IMX_IPUV3_CORE n

         # Networks
         CAIF n
         DECNET n
         NET_DSA n
         HSR n
         IEEE802154 n
         NET_IFE n
         LAPB n
         LLC2 n
         PHONET n
         AF_RXRPC n
         TIPC n
         VSOCKETS n
         WIMAX n
         X25 n

         # Filesystems
         REISERFS_FS n
         UFS_FS n
         UBIFS_FS n
         SYSV_FS n
         QNX4FS_FS n
         PSTORE n
         ORANGEFS_FS n
         OMFS_FS n
         OCFS2_FS n
         NILFS2_FS n
         NFSD n
         MINIX_FS n
         JFS_FS n
         JFFS2_FS n
         HPFS_FS n
         HFSPLUS_FS n
         HFS_FS n
         GFS2_FS n
         VXFS_FS n
         F2FS_FS n
         EFS_FS n
         CEPH_FS n
         BEFS_FS n
         AUTOFS_FS n
         AFS_FS n
         AFFS_FS n
         ADFS_FS n
         9P_FS n

         # Misc drivers
         BCMA_POSSIBLE n
         PCCARD n
         XILLYBUS n
         FPGA n
         COMEDI n
         FB_TFT n
         LTE_GDM724X n
         GREYBUS n
         GS_FPGABOOT n
         KS7010 n
         MOST n
         MTD_SPINAND_MT29F n
         PI433 n
         R8188EU n
         R8712U n
         RTL8723BS n
         SPEAKUP n
         VT6656 n
         WILC1000 n
         PRISM2_USB n
         USB_GADGET n
         UWB n

         # IIO not necessary
         # IIO n
       '';
       kernelMakeFlags = [ "LOADADDR=0x40008000" ];

       gcc = {
         arch = "armv7-a";
         fpu = "neon-vfpv4";
       };
     };
  };
}
