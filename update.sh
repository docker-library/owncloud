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

allVersions="$(
	git ls-remote --tags https://github.com/owncloud/core.git \
		| cut -d/ -f3- \
		| cut -d^ -f1 \
		| grep -E '^v[0-9]' \
		| cut -dv -f2- \
		| sort -ruV
)"

travisEnv=
for version in "${versions[@]}"; do
	fullVersion=
	sha256=
	for tryVersion in $(
		grep -E '^'"$version"'[.]' <<<"$allVersions" \
			| grep -viE 'alpha|beta|rc'
	); do
		if sha256="$(wget -qO- --timeout=1 "https://download.owncloud.org/community/owncloud-${tryVersion}.tar.bz2.sha256")" && [ -n "$sha256" ]; then
			sha256="${sha256%% *}"
			fullVersion="$tryVersion"
			break
		fi
	done
	if [ -z "$fullVersion" ]; then
		echo >&2 "warning: cannot find full version for $version"
		continue
	fi

	echo "$version: $fullVersion"

	for variant in apache fpm; do
		sed -r \
			-e 's/%%VARIANT%%/'"$variant"'/' \
			-e 's/%%VERSION%%/'"$fullVersion"'/' \
			-e 's/%%SHA256%%/'"$sha256"'/' \
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
