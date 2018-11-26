#! @runtimeShell@

echo "Checking for updates..."

if [ ! -n "$HYDRA_JOB_URL" ]; then
    HYDRA_JOB_URL=$(cat /etc/kite-update-url)
fi

latest_system=$(@curl@ "$HYDRA_JOB_URL/latest" -H 'Accept: application/json' -Ls | @jq@ -r .buildoutputs.out.path)

echo "Upgrading to $(basename $latest_system)..."

nix-store --realise $latest_system

$latest_system/bin/switch-to-configuration dry-activate
