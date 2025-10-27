#!/usr/bin/env bash

set -e

# create cluster with kind
kind create cluster || true

# install crossplane with helm
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update
helm upgrade --install crossplane \
  --namespace crossplane-system \
  --create-namespace crossplane-stable/crossplane
kubectl wait --for=condition=available --timeout=300s deployment/crossplane -n crossplane-system

# install AWS providers
kubectl apply -f deploy/providers.yaml

kubectl wait --for=condition=healthy --timeout=300s provider/aws-iam
kubectl wait --for=condition=healthy --timeout=300s provider/aws-eks

# create aws secret
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: aws-secret
  namespace: crossplane-system
type: Opaque
stringData:
  creds: |
    [default]
    aws_access_key_id = $AWS_ACCESS_KEY_ID
    aws_secret_access_key = $AWS_SECRET_ACCESS_KEY
EOF

kubectl apply -f deploy/functions.yaml
kubectl wait --for=condition=healthy --timeout=300s function/patch-and-transform

kubectl apply -f deploy/xrd.yaml
kubectl wait --for=condition=established --timeout=300s crd/karpenters.platform.com

kubectl apply -f deploy/composition.yaml
kubectl apply -f deploy/karpenter.yaml

sleep 5

kubectl get -A Policy,Role.iam.aws.m.upbound.io,RolePolicyAttachment,PodIdentityAssociation
