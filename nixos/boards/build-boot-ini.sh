#! @bash@/bin/sh -e

shopt -s nullglob

export PATH=/empty
for i in @path@; do PATH=$PATH:$i/bin; done

target=${target:-/boot}
newSystem="$1"

echo "Marking $newSystem as boot"

# Convert a path to a file in the Nix store such as
# /nix/store/<hash>-<name>/file to <hash>-<name>-<file>.
cleanName() {
    local path="$1"
    echo "$path" | sed 's|^/nix/store/||' | sed 's|/|-|g'
}

echo "Copy kernel..."
kernelImage=`readlink "$newSystem/kernel"`
kernelDest="/nixos/$(cleanName $kernelImage)"

mkdir -p "$target/nixos"

cp $kernelImage "$target/$kernelDest"

echo "Copy initrd..."
initrdImage="$newSystem/initrd"
initrdDest="/nixos/$(cleanName $initrdImage)"

cp $initrdImage "$target/$initrdDest"

echo "Copy device tree..."
dtbs=`readlink "$newSystem/dtbs"`
dtbsDest="/nixos/$(cleanName $dtbs)"

cp -r $dtbs "$target/$dtbsDest"

echo "Create boot.ini..."

cat >$target/boot.ini <<EOF
ODROIDXU-UBOOT-CONFIG

setenv initrd_high "0xffffffff"
setenv fdt_high "0xffffffff"

setenv ddr_freq 825

setenv bootrootfs "console=tty1 console=ttySAC2,115200n8 root=/dev/mmcblk1p2 rootwait rw systemConfig=$newSystem init=$newSystem/init"

fatload mmc 0:1 0x40008000 $kernelDest
fatload mmc 0:1 0x42000000 $initrdDest
fatload mmc 0:1 0x44000000 $dtbsDest/@board@.dtb
fdt addr 0x44000000
EOF

cat >>$target/boot.ini <<'EOF'
dmc ${ddr_freq}

setenv bootargs "${bootrootfs} s5p_mfc.mem=16M @kernelParams@"

bootm 0x40008000 0x42000000 0x44000000 ${bootargs}
EOF

