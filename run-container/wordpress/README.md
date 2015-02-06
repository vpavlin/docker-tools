```
docker run -it --rm -v /sys/fs/cgroup:/sys/fs/cgroup -v /var/log/journal:/var/log/journal -p 80:80 --name wordpress --link mysql:mysql rhel7/wordpress
```
