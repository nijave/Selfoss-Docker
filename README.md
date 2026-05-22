https://github.com/nijave/Selfoss-Docker/pkgs/container/selfoss

```
docker volume create selfoss
docker run -d \
    --restart unless-stopped \
    -v selfoss:/var/www/html/data \
    -v ./selfoss.ini:/var/www/html/config.ini:ro \
    --name=selfoss \
    ghcr.io/nijave/selfoss
```

apache2 listens on port 8080

adjust cookie age (environment variables)
```
PHP_COOKIE_LIFETIME
PHP_GC_MAXLIFETIME
```