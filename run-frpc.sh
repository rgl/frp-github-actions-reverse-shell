#!/bin/bash
exec 2>&1
set -euxo pipefail

# when running in CI override the frpc tls files.
if [ -v FRPC_TLS_CA_CERTIFICATE ]; then
    cat >ca/github-key.pem <<<"$FRPC_TLS_KEY"
    cat >ca/github.pem <<<"$FRPC_TLS_CERTIFICATE"
    cat >ca/ca.pem <<<"$FRPC_TLS_CA_CERTIFICATE"
    openssl x509 -noout -text -in ca/ca.pem
    openssl x509 -noout -text -in ca/github.pem
fi

if [ -v SSH_PUBLIC_KEY ]; then
    if [ ! -d ~/.ssh ]; then
        install -d -m 700 ~/.ssh
    fi
    if [ ! -f ~/.ssh/authorized_keys ]; then
        install -m 600 /dev/null ~/.ssh/authorized_keys
    fi
    cat >>~/.ssh/authorized_keys <<<"$SSH_PUBLIC_KEY"
    # make sure the home directory has the correct permissions.
    # NB if you do not do this, sshd will not allow you to login
    #    with an ssh public key.
    chmod 775 ~
fi

# uncomment the next block if the ssh public key login is not
# working. it unlocks the user account and sets a password.
# sudo bash <<EOF
# usermod -U $USER
# echo "$USER:abracadabra" | chpasswd
# EOF

./frp/frpc -c ./frpc.ini 2>&1 | sed -E 's,[0-9\.]+:6969,***:6969,ig' || true
