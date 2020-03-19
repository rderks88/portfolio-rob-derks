#!/usr/bin/env bash
set -e

warn() { echo "$@" >&2; }
die() { warn "Fatal: $@"; exit 1; }

configure_user() {
    USERNAME=php
    if [ -z "$SKIP_CHANGING_USER_BECAUSE_I_USE_WINDOWS" ]; then
         HOST_UID=$(stat -c %u docker-compose.yml)
         HOST_GID=$(stat -c %g docker-compose.yml)
    else
         warn 'wAAAH YOU USING WINDOWS !!'
         HOST_UID=$(id -u www-data)
         HOST_GID=$(id -G www-data)
    fi

    groupadd -f -g $HOST_GID $USERNAME || true
    useradd -o --shell /bin/bash -u $HOST_UID -g $HOST_GID -m $USERNAME || true
}

#configure_composer() {
#    if [ -z "$GITLAB_ACCESS_TOKEN" ]; then
#        die 'Environment variable GITLAB_ACCESS_TOKEN is not set'
#    else
#        echo 'Adding Gitlab Access Token to Composer config'
#        sudo -u $USERNAME composer config -g gitlab-token.gitlab.com "$GITLAB_ACCESS_TOKEN"
#    fi
#}

configure_xdebug() {
    echo "XDEBUG - Configuring XDEBUG"
    echo "xdebug.idekey=PHPSTORM" > "$PHP_INI_DIR/conf.d/xdebug.ini"
    echo "xdebug.remote_enable=On" >> "$PHP_INI_DIR/conf.d/xdebug.ini"

    if [ ! -z "$XDEBUG_REMOTE_CONNECT_BACK" ]; then
        echo "XDEBUG - Enabling connect back"
        echo "xdebug.remote_connect_back=On" >> "$PHP_INI_DIR/conf.d/xdebug.ini"
    fi

    if [ ! -z "$XDEBUG_REMOTE_HOST" ]; then
        echo "XDEBUG - Remote host set to '$XDEBUG_REMOTE_HOST'"
        echo "xdebug.remote_host=$XDEBUG_REMOTE_HOST" >> "$PHP_INI_DIR/conf.d/xdebug.ini"
    fi
}

configure_timezone() {
    echo "TIMEZONE - Configuring TIMEZONE"
    echo "date.timezone = \"Europe/Amsterdam\"" > "$PHP_INI_DIR/conf.d/timezone.ini"
}

composer_install() {
    if [ -z "$SKIP_COMPOSER_INSTALL" ]; then
        sudo -u $USERNAME composer install --prefer-dist
    else
         warn 'Composer Install was skipped'
    fi
}

configure_aliases() {
    if [ -e '/home/php/alias_set' ]; then
        warn 'Aliases already set'
    else
        echo "Configuring aliases for php user! Very much handy :)"
        touch /home/php/alias_set
        echo '
alias ..="cd .."
alias ...="cd ../.."

alias h="cd ~"
alias c="clear"
alias pa="php artisan"

alias yrd="yarn run dev"
alias yrw="yarn run watch"
alias yrwp="yarn run watch-poll"
alias yrh="yarn run hot"
alias yrp="yarn run production"' >> /home/php/.bashrc
    fi
}

create_temp_folder() {
    if [ ! -d '/temp' ]; then
        mkdir -m 777 /temp
        echo 'Temp folder created'
    else
        warn 'Temp folder in the root already exists'
    fi
}

#todo for practice, build npm install
#todo for practice, build auto migrate
#https://gitlab.com/techniek-team/dedecaannet-api-monitor/blob/develop/.docker/php/docker-php-entrypoint.sh

configure_user
#configure_composer
configure_xdebug
configure_timezone
configure_aliases
#todo reinstate
#composer_install
create_temp_folder

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
    set -- php-fpm "$@"
fi

echo ">> Running CMD '$@'"
exec "$@"
