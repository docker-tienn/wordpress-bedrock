# Docker image for WP Bedrock
What you will get:
- PHP-FPM on Alpine
- Nginx
- Varnish
- Bedrock + WP

## How to use
Simply run: `docker run -it --name bedrock-wp -p 80:80 --link db:mysql -d tiptopcoder/wordpress-bedrock`

## List of env
- `DB_HOST`: default `db:3306`
- `DB_NAME`: default `wordpress`
- `DB_USER`: default `root`
- `DB_PASSWORD`: not set
- `DB_PREFIX`: default `wp_`
- `WP_HOME`: default `http://localhost`
- `WP_ENV`: default `development`

## Notice
- If you want to define different expose port rather than `80`, define this: `-e WP_HOME="http://localhost:<yourport>"`
- If you want to define different database container name or different database host rather than `db`, define this: `-e DB_HOST="<db_containername>:<db_port>"` or `-e DB_HOST="<db_host>:<db_port>"`

