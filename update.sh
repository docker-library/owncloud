#!/usr/bin/env bash
set -Eeuo pipefail

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
	changelog='https://owncloud.org/changelog/server/'
	case "$version" in
		9.*) changelog='https://owncloud.org/changelog/server/v9/' ;;
	esac

	latest="$(
		curl -fsSL "$changelog" \
			| tac|tac \
			| grep -Eom 1 "(<h2>|Version )${version}.[0-9.]+[ ]" \
			| sed -rn 's/(<h2>|Version )(.+)[ ]/\2/p'
	)"
	echo "$version: $latest"

	for variant in apache fpm; do
		sed -r \
			-e 's/%%VARIANT%%/'"$variant"'/' \
			-e 's/%%VERSION%%/'"$latest"'/' \
			-e 's/%%CMD%%/'"${cmd[$variant]}"'/' \
			Dockerfile.template \
			> "$version/$variant/Dockerfile"

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
