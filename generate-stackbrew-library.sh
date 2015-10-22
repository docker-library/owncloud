#!/bin/bash
set -e

declare -A aliases
aliases=(
	[8.2]='8 latest'
	[7.0]='7'
	[6.0]='6'
)

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( */ )
versions=( "${versions[@]%/}" )
url='git://github.com/docker-library/owncloud'

echo '# maintainer: InfoSiftr <github@infosiftr.com> (@infosiftr)'

echo
echo '# https://github.com/owncloud/core/wiki/Maintenance-and-Release-Schedule'

for version in "${versions[@]}"; do
	for variant in apache fpm; do
		commit="$(cd "$version/$variant" && git log -1 --format='format:%H' -- Dockerfile $(awk 'toupper($1) == "COPY" { for (i = 2; i < NF; i++) { print $i } }' Dockerfile))"
		fullVersion="$(grep -m1 'ENV OWNCLOUD_VERSION ' "$version/$variant/Dockerfile" | cut -d' ' -f3)"

		versionAliases=()
		while [ "$fullVersion" != "$version" -a "${fullVersion%[.-]*}" != "$fullVersion" ]; do
			versionAliases+=( $fullVersion )
			fullVersion="${fullVersion%[.-]*}"
		done
		versionAliases+=( $version ${aliases[$version]} )

		echo
		for va in "${versionAliases[@]}"; do
			if [ "$va" = 'latest' ]; then
				echo "$variant: ${url}@${commit} $version/$variant"
			else
				echo "$va-$variant: ${url}@${commit} $version/$variant"
			fi
			if [ "$variant" = 'apache' ]; then
				echo "$va: ${url}@${commit} $version/$variant"
			fi
		done
	done
done
