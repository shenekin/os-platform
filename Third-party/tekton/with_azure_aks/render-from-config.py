#!/usr/bin/env python3
"""Render pipelinerun-auth-service.yaml from config-pipelinerun-auth-service.yaml."""
from __future__ import annotations

import pathlib
import sys

try:
    import yaml
except ImportError:
    print("Install PyYAML: pip install pyyaml", file=sys.stderr)
    sys.exit(1)

DIR = pathlib.Path(__file__).resolve().parent
CFG = DIR / "config-pipelinerun-auth-service.yaml"
OUT = DIR / "pipelinerun-auth-service.yaml"

TEMPLATE = """# Generated from config-pipelinerun-auth-service.yaml — edit that file, then:
#   python3 render-from-config.py
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  name: {name}
  namespace: {namespace}
spec:
  serviceAccountName: {sa}
  pipelineRef:
    name: {pref}
  params:
    - name: git-url
      value: "{url}"
    - name: git-revision
      value: "{rev}"
    - name: acr-login-server
      value: "{server}"
    - name: image-repo
      value: "{repo}"
    - name: image-tag
      value: "{tag}"
  podTemplate:
    securityContext:
      fsGroup: {fsgroup}
  workspaces:
    - name: shared-data
      volumeClaimTemplate:
        spec:
          accessModes:
            - ReadWriteOnce
          resources:
            requests:
              storage: {storage}
    - name: dockerconfig
      secret:
        secretName: {docksec}
"""


def main() -> None:
    raw = yaml.safe_load(CFG.read_text())
    p = raw["parameters"]
    meta = p["metadata"]
    acr = p["acr"]
    ws = p["workspaces"]
    stg = ws["sharedData"]["volumeClaimTemplate"]["storage"]
    text = TEMPLATE.format(
        name=meta["name"],
        namespace=meta["namespace"],
        sa=p["serviceAccountName"],
        pref=p["pipelineRef"]["name"],
        url=p["git"]["url"],
        rev=p["git"]["revision"],
        server=acr["loginServer"],
        repo=acr["imageRepo"],
        tag=acr["imageTag"],
        fsgroup=p["pod"]["fsGroup"],
        storage=stg,
        docksec=ws["dockerconfig"]["secretName"],
    )
    OUT.write_text(text)
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()
