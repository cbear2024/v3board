#!/bin/bash

export COMPOSER_ALLOW_SUPERUSER=1

# Laravel 12 需要 PHP 8.2 及以上
if ! php -r 'exit(version_compare(PHP_VERSION, "8.2.0", ">=") ? 0 : 1);'; then
    echo "❌ 当前命令行 PHP 版本为 $(php -r 'echo PHP_VERSION;')，需要 PHP 8.2 或更高版本。"
    echo "   宝塔用户可用全路径执行，例如：/www/server/php/82/bin/php"
    exit 1
fi

rm -rf composer.phar
wget https://github.com/composer/composer/releases/latest/download/composer.phar -O composer.phar

if ! php composer.phar install -vvv; then
    echo "❌ composer install 失败，请查看上方 Problem 开头的报错信息。"
    exit 1
fi

if [ ! -f "vendor/autoload.php" ]; then
    echo "❌ 依赖未安装成功（vendor/autoload.php 不存在），已停止安装。"
    exit 1
fi

if ! php composer.phar require joanhey/adapterman; then
    echo "⚠️ joanhey/adapterman 安装失败，Webman 加速模式不可用（不影响普通 PHP-FPM 方式运行）。"
    echo "   通常是缺少 pcntl / posix 扩展，或 putenv、proc_open、pcntl_* 函数被禁用。"
fi

php artisan v2board:install

if [ -f "/etc/init.d/bt" ]; then
  chown -R www $(pwd);
fi
