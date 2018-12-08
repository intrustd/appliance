#! @runtimeShell@

DIRECTION=switch
ARG0=$0

usage() {
    echo "$ARG0 - Update a kite system"
    echo "Usage: $ARG0 [-h|--help] [--download-only]"
    echo
    echo "Options:"
    echo "   -h, --help        Print this help message"
    echo "   --download-only   Only download the latest update"
    echo "   --boot-only       Only set this as boot"
    echo
    echo "For support, please e-mail hi@flywithkite.com"
}

while (( $# )); do
    case "$1" in
        --download-only ) DIRECTION=download; shift ;;
        --boot-only ) DIRECTION=boot; shift ;;
        -h | --help ) usage; exit 0 ;;
        * ) usage; exit 1 ;;
    esac
done

echo "Checking for updates..."

if [ ! -n "$HYDRA_JOB_URL" ]; then
    HYDRA_JOB_URL=$(cat /etc/kite-update-url)
fi

latest_system=$(@curl@ "$HYDRA_JOB_URL/latest" -H 'Accept: application/json' -Ls | @jq@ -r .buildoutputs.out.path)

echo "Upgrading to $(basename $latest_system)..."

# nix-fetch $latest_system
nix-store --realise $latest_system

case "$DIRECTION" in
    download)
        $latest_system/bin/switch-to-configuration dry-activate
        ;;

    boot)
        echo "Marking $latest_system as boot"
        $latest_system/bin/switch-to-configuration boot
        ;;

    switch)
        echo "Switching to target configuration"
        diff /run/current-system/etc/kite-boot-info $latest_system/etc/kite-boot-info >/dev/null
        if [[ "$?" -neq 0 ]]; then
            echo "WARNING: You will need to reboot your system after switch to this configuration"
        fi
        $latest_system/bin/switch-to-configuration switch
        ;;
esac
