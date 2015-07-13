#!/bin/bash
set -e

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"
#Supported Versions found from Production Channel https://owncloud.org/release-channels/
versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
	versions=( */ )
fi
versions=( "${versions[@]%/}" )

for version in "${versions[@]}"; do
	latest=$(curl -sSL 'https://owncloud.org/changelog/' |tac|tac| grep -o -m 1 "Version ${version}.[[:digit:]]\+" | sed -rn 's/Version (.*)/\1/p')
	sed -ri -e 's/^(ENV OWNCLOUD_VERSION) .*/\1 '"$latest"'/' "$version/Dockerfile"
done

