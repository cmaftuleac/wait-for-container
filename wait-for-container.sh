#!/usr/bin/env bash

# Wait for a named container to exit and return its exit code
# uses docker-compose and docker scripts

cmdname=$(basename $0)

echoerr() { if [[ $QUIET -ne 1 ]]; then echo "$@" 1>&2; fi }

usage()
{
    cat << USAGE >&2
Usage:
    $cmdname 
        -n            Wait until the named container exit, and return its exit code
        -t            Timeout, default unlimited
        -h|--help     Show this message
USAGE
    exit 1
}

wait_for()
{
    if [[ $TIMEOUT -gt 0 ]]; then
        echoerr "$cmdname: waiting $TIMEOUT seconds for container $NAME"
    else
        echoerr "$cmdname: waiting for container $NAME without a timeout"
    fi
    

    start_ts=$(date +%s)
    while :
    do
        STATUS=$(docker inspect $(docker-compose ps -q schema 2>/dev/null) 2>/dev/null | jq -r .[0].State.Status)
        end_ts=$(date +%s)
        if [[ "$STATUS" == "exited" ]]; then
            echoerr "$cmdname: container $NAME exited after $((end_ts - start_ts)) seconds"
            break
        else
            if [[ $TIMEOUT -gt 0 ]] && [[ $((end_ts - start_ts)) -gt $TIMEOUT ]]; then
                echoerr "$cmdname: timeout occurred after waiting $TIMEOUT seconds for container $NAME"
                break
            fi
        fi
        sleep 1
    done
    return $result
}

TIMEOUT=0
NAME=

# process arguments
while [[ $# -gt 0 ]]
do
    case "$1" in
        -n)
            NAME="$2"
            shift 2
            ;;
        -t)
            TIMEOUT="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echoerr "Unknown argument: $1"
            usage
            ;;
    esac
done

if [[ "$NAME" == "" ]]; then
    echoerr "Error: you need to provide a container name"
    usage
fi

wait_for
exit $?
