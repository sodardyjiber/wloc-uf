#!/bin/sh
set -eu

# Configure all generated module links for the repository and Worker that you own.
repo_url=${1:-}
worker_url=${2:-}
branch=${3:-main}

if [ -z "$repo_url" ] || [ -z "$worker_url" ]; then
  printf '%s\n' 'Usage: ./scripts/configure-self-host.sh <github-repo-url> <worker-url> [branch]' >&2
  printf '%s\n' 'Example: ./scripts/configure-self-host.sh https://github.com/me/wloc-spoofer https://wloc-spoofer.me.workers.dev' >&2
  exit 2
fi

case "$repo_url" in
  https://github.com/*/*|http://github.com/*/*) ;;
  *) printf '%s\n' 'Repository URL must be a GitHub URL such as https://github.com/user/repository' >&2; exit 2 ;;
esac

repo_url=${repo_url%.git}
worker_url=${worker_url%/}
worker_host=${worker_url#https://}
worker_host=${worker_host#http://}
worker_url=https://${worker_host}
raw_base=${repo_url/github.com/raw.githubusercontent.com}/$branch

find modules -maxdepth 1 -type f -print0 | xargs -0 sed -i.bak \
  -e "s#https://raw.githubusercontent.com/YOUR_GITHUB_USERNAME/YOUR_REPOSITORY/main#${raw_base}#g" \
  -e "s#https://github.com/YOUR_GITHUB_USERNAME/YOUR_REPOSITORY#${repo_url}#g" \
  -e "s#YOUR_WORKER_URL#${worker_url}#g" \
  -e "s#YOUR_WORKER_DOMAIN#${worker_url}#g"

# Keep setup instructions and subscription examples in sync with the configured modules.
find README.md README.en.md docs -type f -print0 | xargs -0 sed -i.bak \
  -e "s#https://raw.githubusercontent.com/YOUR_GITHUB_USERNAME/YOUR_REPOSITORY/main#${raw_base}#g" \
  -e "s#https://github.com/YOUR_GITHUB_USERNAME/YOUR_REPOSITORY#${repo_url}#g" \
  -e "s#YOUR_WORKER_URL#${worker_url}#g" \
  -e "s#YOUR_WORKER_DOMAIN#${worker_url}#g"
find modules README.md README.en.md docs -name '*.bak' -delete

printf 'Configured modules for %s\nWorker picker: %s\n' "$repo_url" "$worker_url"
