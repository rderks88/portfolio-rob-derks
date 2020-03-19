#!/usr/bin/env bash
set -e

red="\e[31m"
green="\e[32m"
reset="\e[39m"

warn() { echo -e "${red}$@${reset}" >&2; }
die() { warn "Fatal: $@"; exit 1; }

DH_PATH='/etc/nginx/external'

CSR_CONF_PATH='/opt/tls/server.csr.cnf'
CSR_PATH='/opt/tls/server.csr'
V3_EXT_PATH='/opt/tls/v3.ext'
CERT_PATH='/etc/nginx/external/cert.pem'
KEY_PATH='/etc/nginx/external/key.pem'
SERIAL_PATH='/opt/tls/serial'

ROOT_CA_KEY_PATH='/opt/tls/rootCA.key'
ROOT_CA_CERT_PATH='/opt/tls/rootCA.crt'
ROOT_CA_CONF_PATH='/opt/tls/rootCA.cnf'

check_dh_file() {
    if [ ! -f "$DH_PATH/dh.pem" ]
        mkdir -p $DH_PATH
    then
        warn "DH param file does not exist yet, creating it for you now!"
        # instead of generating a file we use a predefined DH param file as recommended
        # https://wiki.mozilla.org/Security/Server_Side_TLS#Pre-defined_DHE_groups
        cat << 'END_OF_FILE' > "$DH_PATH/dh.pem"
-----BEGIN DH PARAMETERS-----
MIIBCAKCAQEA//////////+t+FRYortKmq/cViAnPTzx2LnFg84tNpWp4TZBFGQz
+8yTnc4kmz75fS/jY2MMddj2gbICrsRhetPfHtXV/WVhJDP1H18GbtCFY2VVPe0a
87VXE15/V8k1mE8McODmi3fipona8+/och3xWKE2rec1MKzKT0g6eXq8CrGCsyT7
YdEIqUuyyOP7uWrat2DX9GgdT0Kj3jlN9K5W7edjcrsZCwenyO4KbXCeAvzhzffi
7MA0BM0oNC9hkXL+nOmFg/+OTxIy7vKBg8P+OxtMb61zO7X8vC7CIAXFjvGDfRaD
ssbzSibBsu/6iGtCOGEoXJf//////////wIBAg==
-----END DH PARAMETERS-----
END_OF_FILE
    fi
}

check_root_ca() {
    if [[ ! -f "$ROOT_CA_KEY_PATH" ]] || [[ ! -f "$ROOT_CA_CERT_PATH" ]]
    then
        warn "Creating a root CA for you"

        openssl genrsa -out "$ROOT_CA_KEY_PATH" 2048
        openssl req -x509 -new -nodes -key "$ROOT_CA_KEY_PATH" -sha256 -days 1024 -out "$ROOT_CA_CERT_PATH" -config <( cat "$ROOT_CA_CONF_PATH" )
    fi
}

check_self_signed_certificate() {
    if [[ ! -f "$CERT_PATH" ]] || [[ ! -f "$KEY_PATH" ]]
    then
        warn "Certificate not found ($CERT_PATH, $KEY_PATH)"
        warn "Creating a self signed certificate for you"

        check_root_ca

        openssl req -new -sha256 -nodes -out "$CSR_PATH" -newkey rsa:2048 -keyout "$KEY_PATH" -config <( cat "$CSR_CONF_PATH" )
        openssl x509 -req -in "$CSR_PATH" -CA "$ROOT_CA_CERT_PATH" -CAkey "$ROOT_CA_KEY_PATH" -CAcreateserial -CAserial "$SERIAL_PATH" -out "$CERT_PATH" -days 500 -sha256 -extfile "$V3_EXT_PATH"
    fi
}

check_dh_file
check_self_signed_certificate


# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then

    set -- nginx -g "daemon off;" "$@"
fi

echo ">> Running CMD '$@'"
exec "$@"
