#! /bin/sh
set -e pipefail

flux reconcile source git flux-system
flux reconcile kustomization flux-system
flux reconcile kustomization core
flux reconcile kustomization apps