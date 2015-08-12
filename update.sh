#!/bin/bash
set -e

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"
#Supported Versions found from Production Channel https://owncloud.org/release-channels/
versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
	versions=( */ )
fi
versions=( "${versions[@]%/}" )


travisEnv=
for version in "${versions[@]}"; do
	latest=$(curl -sSL 'https://owncloud.org/changelog/' |tac|tac| grep -o -m 1 "\(Version\|Release\) ${version}.[[:digit:]]\+" | sed -rn 's/(Version|Release) (.*)/\2/p')
	sed -ri -e 's/^(ENV OWNCLOUD_VERSION) .*/\1 '"$latest"'/' "$version/Dockerfile"
	
	travisEnv='\n  - VERSION='"$version$travisEnv"
done

travis="$(awk -v 'RS=\n\n' '$1 == "env:" { $0 = "env:'"$travisEnv"'" } { printf "%s%s", $0, RS }' .travis.yml)"
echo "$travis" > .travis.yml
