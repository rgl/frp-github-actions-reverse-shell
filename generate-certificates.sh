#!/bin/bash
exec 2>&1
set -euxo pipefail

mkdir -p ca
pushd ca

if [ ! -x cfssl ]; then
    wget -qOcfssl https://github.com/cloudflare/cfssl/releases/download/v1.5.0/cfssl_1.5.0_linux_amd64
    chmod +x cfssl
fi
if [ ! -x cfssljson ]; then
    wget -qOcfssljson https://github.com/cloudflare/cfssl/releases/download/v1.5.0/cfssljson_1.5.0_linux_amd64
    chmod +x cfssl cfssljson
fi

if [ ! -f ca.pem ]; then
    ./cfssl print-defaults config
    ./cfssl print-defaults csr
    cat >ca-config.json <<'EOF'
{
    "signing": {
        "profiles": {
            "server": {
                "expiry": "8760h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "server auth"
                ]
            },
            "client": {
                "expiry": "8760h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "client auth"
                ]
            }
        }
    }
}
EOF
    cat >ca-csr.json <<'EOF'
{
    "key": {
        "algo": "ecdsa",
        "size": 256
    }
}
EOF
    cat >ca.json <<EOF
{
    "CN": "$FRPS_DOMAIN CA"
}
EOF
    ./cfssl gencert -initca -config=ca-config.json ca.json | ./cfssljson -bare ca -
fi

if [ ! -f $FRPS_DOMAIN.pem ]; then
    cat >$FRPS_DOMAIN.json <<EOF
{
    "CN": "$FRPS_DOMAIN",
    "hosts": [
        "$FRPS_DOMAIN"
    ]
}
EOF
    ./cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server $FRPS_DOMAIN.json | ./cfssljson -bare $FRPS_DOMAIN
fi

if [ ! -f github.pem ]; then
    cat >github.json <<'EOF'
{
    "CN": "github client",
    "hosts": [
        "github.com"
    ]
}
EOF
    ./cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client github.json | ./cfssljson -bare github
fi

openssl x509 -noout -text -in ca.pem
openssl x509 -noout -text -in $FRPS_DOMAIN.pem
openssl x509 -noout -text -in github.pem
popd
