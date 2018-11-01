#!/usr/bin/env bash
set -Eeuo pipefail

declare -A cmd=(
	[apache]='apache2-foreground'
	[fpm]='php-fpm'
)

# https://doc.owncloud.org/server/10.0/admin_manual/installation/system_requirements.html  ("*We strongly encourage you to migrate to PHP 7.2.")
# https://doc.owncloud.org/server/9.0/admin_manual/installation/system_requirements.html ("PHP 7.0")
defaultPhpVersion='7.2'
declare -A phpVersion=(
	[9.1]='7.0'
)

generated_warning() {
	cat <<-EOH
		#
		# NOTE: THIS DOCKERFILE IS GENERATED VIA "update.sh"
		#
		# PLEASE DO NOT EDIT IT DIRECTLY.
		#

	EOH
}

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
		# TODO determine a better way to handle "download.owncloud.org" failures (so that we don't equate the download server having a temporary hiccup the same as the version not being published yet)
		break
	done
	if [ -z "$fullVersion" ]; then
		echo >&2 "warning: cannot find full version for $version"
		continue
	fi

	echo "$version: $fullVersion"

	for variant in apache fpm; do
		{ generated_warning; cat Dockerfile.template; } > "$version/$variant/Dockerfile"
		sed -ri \
			-e 's/%%VARIANT%%/'"${phpVersion[$version]:-$defaultPhpVersion}-$variant"'/' \
			-e 's/%%VERSION%%/'"$fullVersion"'/' \
			-e 's/%%SHA256%%/'"$sha256"'/' \
			-e 's/%%CMD%%/'"${cmd[$variant]}"'/' \
			"$version/$variant/Dockerfile"

		if [ "$variant" = 'fpm' ]; then
			sed -ri -e '/a2enmod/d' "$version/$variant/Dockerfile"
		fi

		if [[ "$version" != 9.* ]]; then
			sed -ri \
				-e '/^RUN ln.*docker-entrypoint.*backwards compat/d' \
				-e '/mcrypt/d' \
				"$version/$variant/Dockerfile"
		fi

		travisEnv='\n  - VERSION='"$version"' VARIANT='"$variant$travisEnv"
	done
done

travis="$(awk -v 'RS=\n\n' '$1 == "env:" { $0 = "env:'"$travisEnv"'" } { printf "%s%s", $0, RS }' .travis.yml)"
echo "$travis" > .travis.yml
