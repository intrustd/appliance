#! @runtimeShell@

HYDRA_JOB_URL=$(cat /etc/intrustd-update-url)

print_latest() {
    @curl@ "$HYDRA_JOB_URL/latest" -H 'Accept: application/json' -Ls | @jq@ -r .buildoutputs.out.path
}

parse_nix_fetch_output() {
    MIN=$1
    MAX=$2
    MAX_RANGE=$3
    RANGE=$(($MAX-$MIN))

    while read -r progress; do
        KIND=${progress%% *}
        if [ "$KIND" == "error" ]; then
            MSG=${KIND# *}
            echo "500 $MSG"
        else
            REST=${progress#* }
            TOTAL=${REST%% *}
            MSG=${REST#* }
            echo "201 $(( ($KIND/$TOTAL)*$RANGE + $MIN )) $MAX_RANGE $MSG"
        fi
    done
}

while read -r line; do
    case "$line" in
        current)
            echo "200 $(readlink -f /run/current-system)"
            ;;

        latest)
            echo -n "200 "
            print_latest
            ;;

        update)
            UPDATE_INFO=$(read -r line)
            DOWNLOAD_ONLY=$(echo "$UPDATE_INFO" | @jq@ -r .download_only)
            if [ "$DOWNLOAD_ONLY" == "true" ]; then
                DOWNLOAD_ONLY=1
            else
                unset DOWNLOAD_ONLY
            fi

            LOG=$(echo "$UPDATE_INFO" | @jq@ -r .log)

            (
                @flock@ -x 200
                echo "201 0 1000 Getting latest system"
                LATEST_SYSTEM=$(print_latest)
                echo "201 100 1000 Downloading"
                @nixFetch@ --add-indirect-root /run/downloaded-system $LATEST_SYSTEM 2>&1 | tee $LOG | parse_nix_fetch_output 100 850 1000
                if "$DOWNLOAD_ONLY"; then
                    echo "201 1000 1000 Done"
                    echo "Downloading only" >> $LOG
                    echo "200 Done"
                else
                    echo "201 860 1000 Activating system..."
                    echo "Activating..." >> $LOG
                    echo "201 990 1000 Cleaning up"
                    echo "201 1000 1000 Done"
                    echo "200 Done"
                fi
            ) 200>@intrustdDir@/intrustd-system-update.lock
            ;;

        reboot)
            @runitInit@ 6
            ;;

        *)
            echo "400 Unknown command"
            ;;
    esac
done
