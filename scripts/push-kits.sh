#!/usr/bin/env bash
set -euo pipefail

# Publish the nanoclaw kit as an OCI artifact to Docker Hub.
#
# nanoclaw is a single kit (no per-provider variants), so this stages the
# spec.yaml + README + LICENSE and pushes one tag. Mirrors the publish flow of
# the sibling sbx-kits-mem0 repo.

namespace="${DOCKERHUB_NAMESPACE:-${DOCKER_NAMESPACE:-ajeetraina777}}"
tag="${TAG:-latest}"
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
image="docker.io/$namespace/sbx-nanoclaw-kits"

# publish IMAGE_TAG — stage the kit (spec.yaml + README + LICENSE), validate, push one tag.
publish() {
  local image_tag="$1"
  local stage
  stage="$(mktemp -d /tmp/nanoclaw-kit-push.XXXXXX)"
  mkdir -p "$stage/nanoclaw"
  cp "$repo_root/spec.yaml" "$stage/nanoclaw/spec.yaml"
  cp "$repo_root/README.md" "$stage/nanoclaw/README.md"
  cp "$repo_root/LICENSE"   "$stage/nanoclaw/LICENSE"
  sbx kit validate "$stage/nanoclaw"
  sbx kit push "$stage/nanoclaw" "$image:$image_tag"
  rm -rf "$stage"
  echo "Pushed $image:$image_tag"
}

publish "$tag"
