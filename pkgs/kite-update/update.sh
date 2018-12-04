#! @runtimeShell@

SWITCH=1
ARG0=$0

usage() {
    echo "$ARG0 - Update a kite system"
    echo "Usage: $ARG0 [-h|--help] [--download-only]"
    echo
    echo "Options:"
    echo "   -h, --help        Print this help message"
    echo "   --download-only   Only download the latest update"
    echo
    echo "For support, please e-mail hi@flywithkite.com"
}

while (( $# )); do
    case "$1" in
        --download-only ) SWITCH=0; shift ;;
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

if [[ "$SWITCH" -eq 0 ]]; then
    $latest_system/bin/switch-to-configuration dry-activate
else
    echo "Switching to target configuration..."
    $latest_system/activate
    $latest_system/bin/switch-to-configuration switch
fi
