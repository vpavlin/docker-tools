```
docker run -it --rm -v /sys/fs/cgroup:/sys/fs/cgroup -v /var/log/journal:/var/log/journal -p 80:80 --name wordpress --link mariadb:mariadb vpavlin/wordpress
```
