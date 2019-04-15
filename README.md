# 自建软件源

## 从上游镜像站获取文件

可以从中科大镜像源获取文件，参考中科大官方文档：

- [科大源同步方法与注意事项 — USTC Mirror Help 文档](https://mirrors.ustc.edu.cn/help/rsync-guide.html)

镜像的状态及需要同步的数据量可以从 [USTC Mirrors Status](https://mirrors.ustc.edu.cn/status/) 查看。

中科大主要有几个 IP，如果需要开通外网 IP 访问权限，可以将以下 IP 加入白名单，同步的端口为默认的 873。

```
218.104.71.170
202.141.176.110
202.38.95.110
```

安装 `rsync`，执行下面的命令测试连通情况，能显示中科大 MOTD 信息表示访问正常，否则检查网络是否开放。

```
# rsync rsync://rsync.mirrors.ustc.edu.cn/repo/centos/TIME
 _______________________________________________________________
|         University of Science and Technology of China         |
|           Open Source Mirror  (mirrors.ustc.edu.cn)           |
|===============================================================|
|                                                               |
|    We mirror a great many OSS projects & Linux distros.       |
|                                                               |
| Currently we don't limit speed. To prevent overload, Each IP  |
| is only allowed to start upto 2 concurrent rsync connections. |
|                                                               |
| This site also provides http/https/ftp access.                |
|                                                               |
| Supported by USTC Network Information Center                  |
|          and USTC Linux User Group (http://lug.ustc.edu.cn/). |
|                                                               |
|    Sync Status:  https://mirrors.ustc.edu.cn/status/          |
|           News:  https://servers.ustclug.org/                 |
|        Contact:  lug@ustc.edu.cn                              |
|                                                               |
|_______________________________________________________________|


-rw-rw-r--             11 2019/03/22 11:09:01 TIME
```

## 安装 rsync-repo

```
mkdir -p /data/scripts
git clone https://github.com/pysense/rsync-repo /data/scripts/rsync-repo
```

配置文件

```
cp rsync-repo-sample.cfg rsync-repo.cfg
```

根据自己的情况设置，中科大对同步速率中科大对同步速率有限制，脚本默认限制为 1024KB/s，
建议不要修改这个数值，否则可能被中科大禁止访问，如果是使用自己的上游服务器，可以根据情况修改。

```
# 存放同步数据的目录
repo_dir=/data/mirrors

# 定义同步源，如果未设置，默认将使用中科大镜像源
rsync_server=rsync://rsync.mirrors.ustc.edu.cn/repo

# 同步速率，单位为 KB/s
rsync_opt_bwlimit=1024
```

创建存放数据的目录

```
mkdir -p /data/mirrors
```

启动同步

```
./rsync-repo.sh start centos
```

可以通过 `./rsync-repo.sh help` 查看帮助。

添加定时任务

```
# crontab -e
5 * * * * /data/scripts/rsync-repo/rsync-repo.sh start centos &> /dev/null
```
