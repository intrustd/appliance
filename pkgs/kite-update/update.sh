#! @runtimeShell@

DIRECTION=switch
RESTART=0
NEEDS_RESTART=0
ARG0=$0

usage() {
    echo "$ARG0 - Update a kite system"
    echo "Usage: $ARG0 [-h|--help] [--download-only]"
    echo
    echo "Options:"
    echo "   -h, --help        Print this help message"
    echo "   --download-only   Only download the latest update"
    echo "   --boot-only       Only set this as boot"
    echo "   --restart         Restart the system if the update requires"
    echo
    echo "For support, please e-mail hi@flywithkite.com"
}

while (( $# )); do
    case "$1" in
        --download-only ) DIRECTION=download; shift ;;
        --boot-only ) DIRECTION=boot; shift ;;
        --restart ) RESTART=1; shift ;;
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

diff /run/current-system/etc/kite-boot-info $latest_system/etc/kite-boot-info >/dev/null
NEEDS_RESTART="$?"

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
        $latest_system/bin/switch-to-configuration switch
        ;;
esac

if [[ "$NEEDS_RESTART" -ne 0 ]]; then
case "$DIRECTION" in
    download|boot)
        if [[ "$RESTART" -eq 1 ]]; then
            echo "Not restarting because of --download-only or --boot-only"
        fi
        ;;

    switch)
        if [[ "$RESTART" -eq 1 ]]; then
            echo "Restart requested. Restarting in 5 seconds (press Ctrl-C to interrupt)"
            sleep 5
            runit-init 6
        else
            echo "WARNING: A restart is required to switch to this configuration"
        fi
        ;;
esac
