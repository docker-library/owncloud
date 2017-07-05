#!/bin/bash
set -e

declare -A cmd=(
	[apache]='apache2-foreground'
	[fpm]='php-fpm'
)

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

	for variant in apache fpm; do
		cp Dockerfile.template "$version/$variant/Dockerfile"

		sed -ri \
			-e 's/%%VARIANT%%/'"$variant"'/' \
			-e 's/%%VERSION%%/'"$latest"'/' \
			-e 's/%%CMD%%/'"${cmd[$variant]}"'/' \
			"$version/$variant/Dockerfile"

		if [ "$variant" = 'fpm' ]; then
			sed -ri -e '/a2enmod/d' "$version/$variant/Dockerfile"
		fi

		if [[ "$version" != 9.* ]]; then
			sed -ri -e '/^RUN ln.*docker-entrypoint.*backwards compat/d' "$version/$variant/Dockerfile"
		fi

		travisEnv='\n  - VERSION='"$version"' VARIANT='"$variant$travisEnv"
	done
done

travis="$(awk -v 'RS=\n\n' '$1 == "env:" { $0 = "env:'"$travisEnv"'" } { printf "%s%s", $0, RS }' .travis.yml)"
echo "$travis" > .travis.yml
