#!/bin/bash

#set -exuo pipefail
set -euo pipefail


green=$(tput setaf 2)
cyan=$(tput setaf 6)
normal=$(tput sgr0)

CONJUR_SERVER_DNS=dapmaster.conjur.dev
conjur_host=azure-apps
#secret_id=test-variable

function main() {

    system_assigned_identity_token_endpoint="http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fmanagement.azure.com%2F"
    system_assigned_identity_host_name="az-tools"

    # use Azure system-assigned-identity to get Conjur access token
    getConjurTokenWithAzureIdentity $system_assigned_identity_token_endpoint $system_assigned_identity_host_name

    #getConjurSecret $conjur_access_token
}

function getConjurTokenWithAzureIdentity() {
    azure_token_endpoint="$1"
    conjur_role="$2"

    getAzureAccessToken $azure_token_endpoint $conjur_role

    getConjurToken $azure_access_token
}

function getAzureAccessToken(){

    # Get an Azure access token
    azure_access_token=$(curl -s\
      "$azure_token_endpoint" \
      -H Metadata:true -s | jq -r '.access_token')

}

function getConjurToken() {
    # Get a Conjur access token for host azure-apps/system-assigned-identity-app or user-assigned-identity-app using the Azure token details

    authn_azure_response=$(curl -sk -X POST \
      -H "Content-Type: application/x-www-form-urlencoded" \
      --data "jwt=$azure_access_token" \
      https://dapmaster.conjur.dev:443/authn-azure/dev/cyberark/host%2F$conjur_host/authenticate)

    conjur_access_token=$(echo -n "$authn_azure_response" | base64 | tr -d '\r\n')
}

function getConjurSecret(){

    # Retrieve a Conjur secret using the authn-azure Conjur access token
    secret=$(curl -sk -H "Authorization: Token token=\"$conjur_access_token\"" \
      "https://dapmaster.conjur.dev:443/secrets/cyberark/variable/$secret_id")

    printf "%s%s%s\n\n" "${normal}Retrieved secret " "${green}${secret} " "${normal}from Conjur."
}

main
