#!/bin/bash

#MINING_ADDRESS

context=$1
namespace=$2

miningAddress=`echo $3 | base64`

echo "encrypted miningAddress: ${miningAddress}"

cat ./secrets.yml | sed "s/\X_MINING_ADDRESS_X/$miningAddress/" | kubectl --context=${context} --namespace ${namespace} create -f -


#./create-secrets.sh minikube lightning-kube rcbBivXApy8g2HvSru5VyaWF3mn3Ewwmjr