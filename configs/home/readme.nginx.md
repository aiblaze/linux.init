# Nginx Boilerplate

https://github.com/h5bp/server-configs-nginx

## Manage sites

```bash
cd /etc/nginx/conf.d
```

* Creating a new site

  ```bash
  cp templates/example.com.conf .actual-hostname.conf
  sed -i 's/example.com/actual-hostname/g' .actual-hostname.conf
  ```

* Enabling a site

  ```bash
  mv .actual-hostname.conf actual-hostname.conf
  ```

* Disabling a site

  ```bash
  mv actual-hostname.conf .actual-hostname.conf
  ```

```bash
nginx -s reload
```

# Sites location

/var/www/

# SSL with Aliyun

https://github.com/mamboer/certbot-dns-aliyun