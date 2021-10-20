gw2index - API
===

# Installation

## Requirements

 - `Docker` and `Docker Compose`

## Docker Secrets

We need to generate some secrets to store the passwords :

```Shell
printf "some string that is your secret value" | docker secret create authenticator_password -
printf "some string that is your secret value" | docker secret create postgres_password -
```


```Shell
# Allow "tr" to process non-utf8 byte sequences
export LC_CTYPE=C

# read random bytes and keep only alphanumerics
printf `< /dev/urandom tr -dc A-Za-z0-9 | head -c32` | docker secret create jwt_token -
```