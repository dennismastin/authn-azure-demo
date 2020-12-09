#!/bin/bash

#set -exuo pipefail
set -euo pipefail

green=$(tput setaf 2)
cyan=$(tput setaf 6)
normal=$(tput sgr0)

secret_id=test-variable
dap_uri=https://dapmaster.conjur.dev:443/secrets
dap_account=cyberark

secret=$(curl -sk -H "Authorization: Token token=\"$(./azure-authn-token)\"" \
      "$dap_uri/$dap_account/variable/$secret_id")

printf "%s%s%s\n\n" "${normal}Retrieved secret " "${green}${secret} " "${normal}from Conjur."
