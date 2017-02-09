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
        -n                  Wait until the named container exit, and return its exit code
        -t                  Timeout, default is not to wait at all (just check and exit)
        -s|--strict         Only execute subcommand if the test succeeds
        -h|--help           Show this message
        -- COMMAND ARGS     Execute command with args after the test finishes
USAGE
    exit 1
}

wait_for()
{
    if [[ $TIMEOUT -gt 0 ]]; then
        echoerr "$cmdname: waiting $TIMEOUT seconds for container $NAME"
    fi    

    start_ts=$(date +%s)
    while :
    do
        STATUS=$(docker inspect $(docker-compose ps -q "$NAME" 2>/dev/null) 2>/dev/null | jq -r .[0].State.Status)
        end_ts=$(date +%s)
        if [[ "$STATUS" == "exited" ]]; then
            RESULT=$(docker inspect $(docker-compose ps -q "$NAME" 2>/dev/null) 2>/dev/null | jq -r .[0].State.ExitCode)
            if [[ $TIMEOUT -gt -1 ]]; then
                echoerr "$cmdname: container $NAME exited after $((end_ts - start_ts)) seconds with exit code: $RESULT"
            else
                echoerr "$cmdname: container $NAME exit code: $RESULT"
            fi
            return $RESULT
        else
            if [[ $TIMEOUT -eq -1 ]]; then
                if [ -z "$STATUS" ]; then
                    echoerr "$cmdname: container $NAME not running"
                else
                    echoerr "$cmdname: container $NAME status: $STATUS"
                fi
                return 1
            fi
            if [[ $TIMEOUT -gt 0 ]] && [[ $((end_ts - start_ts)) -gt $TIMEOUT ]]; then
                echoerr "$cmdname: timeout occurred after waiting $TIMEOUT seconds for container $NAME"
                if [ -z "$STATUS" ]; then
                    echoerr "$cmdname: container $NAME not running"
                else
                    echoerr "$cmdname: container $NAME status: $STATUS"
                fi
                return 1
            fi
        fi
        sleep 1
    done
}

STRICT=0
TIMEOUT=-1
NAME=
CLI=

# process arguments
while [[ $# -gt 0 ]]
do
    case "$1" in
        -n)
            NAME="$2"
            shift 2
            ;;
        -s|--strict)
            STRICT=1
            shift 1
            ;;
        -t)
            TIMEOUT="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        --)
            shift
            CLI="$@"
            break
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
RESULT=$?

if [[ $CLI != "" ]]; then
    if [[ $RESULT -ne 0 && $STRICT -eq 1 ]]; then
        echoerr "$cmdname: strict mode, refusing to execute subprocess"
        exit $RESULT
    fi
    exec $CLI
else
    exit $RESULT
fi
