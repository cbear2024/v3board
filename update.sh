#!/bin/bash

if [ ! -d ".git" ]; then
  echo "Please deploy using Git."
  exit 1
fi

if ! command -v git &> /dev/null; then
    echo "Git is not installed! Please install git and try again."
    exit 1
fi

export COMPOSER_ALLOW_SUPERUSER=1

# Laravel 12 需要 PHP 8.2 及以上
if ! php -r 'exit(version_compare(PHP_VERSION, "8.2.0", ">=") ? 0 : 1);'; then
    echo "❌ 当前命令行 PHP 版本为 $(php -r 'echo PHP_VERSION;')，需要 PHP 8.2 或更高版本，请先升级 PHP 再更新。"
    exit 1
fi

git config --global --add safe.directory $(pwd)
git fetch --all && git reset --hard origin/master && git pull origin master
rm -rf composer.lock composer.phar
wget https://github.com/composer/composer/releases/latest/download/composer.phar -O composer.phar

if ! php composer.phar update -vvv; then
    echo "❌ composer update 失败，请查看上方 Problem 开头的报错信息。"
    exit 1
fi

if ! php composer.phar require joanhey/adapterman; then
    echo "⚠️ joanhey/adapterman 安装失败，Webman 加速模式不可用（不影响普通 PHP-FPM 方式运行）。"
else
    if ! php -m | grep -q "pcntl"; then
        echo "Adding pcntl extension to cli-php.ini"
        sed -i '/extension=redis.so/a extension=pcntl.so' cli-php.ini
    fi
    php -c cli-php.ini webman.php stop
    echo "Webman stopped.Please restart it by yourself."
fi

php artisan v2board:update

if [ -f "/etc/init.d/bt" ]; then
  chown -R www $(pwd);
fi
