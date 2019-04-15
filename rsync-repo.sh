#!/bin/bash
# by 1057 (pysense@gmail.com)

SCRIPTDIR=$(dirname $(readlink -f ${BASH_SOURCE[0]}))
[[ -f $SCRIPTDIR/rsync-repo.cfg ]] && source $SCRIPTDIR/rsync-repo.cfg
repo_dir=${repo_dir:-/data/mirrors}
rsync_server=${rsync_server:-"rsync://rsync.mirrors.ustc.edu.cn/repo"}
rsync_opt_bwlimit=${rsync_opt_bwlimit:-1024}
#rsync_repo_pidfile=$SCRIPTDIR/rsync-repo.pid

rsync_repo() {
    repo_name=${1:-}; shift
    repo_name=${repo_name%/}
    if [[ $arg_repo_name == $repo_name ]]; then
        repo_args="$arg_repo_args $@"
    else
        repo_args="$arg_repo_args"
    fi
    #echo "$arg_repo_action, $arg_repo_name, $repo_args"
    case $arg_repo_action in
        start)
            check_running | grep -v not && exit
            nohup rsync -avi --delete --delete-excluded --bwlimit=$rsync_opt_bwlimit \
                --log-file=$SCRIPTDIR/rsync-repo-${arg_repo_name}.log \
                $rsync_server/$arg_repo_name $repo_dir $repo_args &> /dev/null &
            if [[ $? == 0 ]]; then
                echo "Starting rsync-repo ($arg_repo_name) with pid $!"
            fi
            ;;
        stop)
            rsync_repo_pid=$(get_rsync_repo_pid)
            if [[ -n $rsync_repo_pid ]]; then
                echo "Killing rsync-repo ($arg_repo_name) with pid $rsync_repo_pid"
                kill $rsync_repo_pid
            else
                echo "rsync-repo ($arg_repo_name) not running"
            fi
            ;;
        status)
            if [[ -n $arg_repo_name ]]; then
                check_running
            else
                repo_names=$(ps aux | grep -v grep | grep "$rsync_server/" | sed "s#.*rsync://.*/repo/\([a-z.-]*\).*#\1#" | sort | uniq)
                for arg_repo_name in $repo_names; do
                    check_running
                done
            fi
            ;;
        log)
            tailf $SCRIPTDIR/rsync-repo-${arg_repo_name}.log
            ;;
    esac
}

get_rsync_repo_pid() {
    ps aux | grep -v grep | grep "$rsync_server/$arg_repo_name" | awk '{print$2}' | tail -1
}

check_running() {
    rsync_repo_pid=$(get_rsync_repo_pid)
    if [[ -n $rsync_repo_pid ]]; then
        echo "rsync-repo ($arg_repo_name) already running with pid $rsync_repo_pid"
    else
        echo "rsync-repo ($arg_repo_name) not running"
        return 1
    fi
}

usage() {
    cat << EOF
使用 rsync 协议同步指定镜像源上数据。

$0 [command] <args>

  command:

    start <name> [args]     #启动同步
    stop <name>             #停止同步
    status [name]           #查看状态
    log <name>              #查看日志
    help                    #查看帮助

  name 可以为以下的，或者根据指定的镜像源设置：

    - centos
    - ubuntu
    - debian
    - opensuse

  更多请参考：https://mirrors.ustc.edu.cn/status
EOF
}

[[ $# == 0 ]] && { usage; exit; }

case "$1" in
    start|stop|log)
        [[ $# < 2 ]] && { usage; exit; }
        arg_repo_action=$1; shift   #指定动作
        arg_repo_name=$1; shift     #同步项目
        arg_repo_args="$@"          #附件参数
        ;;
    status)
        arg_repo_action=$1; shift   #指定动作
        arg_repo_name=$1; shift     #同步项目
        ;;
    help)
        usage; exit
        ;;
esac

case $arg_repo_name in
    centos) rsync_repo centos --exclude=*.iso;;
    epel) rsync_repo epel;;
    ubuntu) rsync_repo ubuntu --exclude="*-proposed" --exclude="*.iso" -n;;
    *) rsync_repo;;
esac
