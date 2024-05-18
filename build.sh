tmpl=${1:-src/ucsf-vpn.sh}
target=${2:-bin/ucsf-vpn}

echo "Building ${target} from ${tmpl} ..."

## Assert there are source statements
grep -q -F 'source "${incl}/' "${tmpl}"

{
    while IFS= read -r line; do \
        if [[ "${line}" == "source "* ]]; then \
            file=$(sed -E 's/source "[$][{](incl)[}][/]([^.]+[.]sh)"/\1\/\2/' <<< "${line}")
            cat "src/${file}"
            echo
        elif ! grep -q -E "^(# shellcheck source=|this=|incl=)" <<< "${line}"; then
            echo "${line}"
            if [[ "${line}" == "#! /usr/bin/env bash" ]]; then
                 echo "###################################################################"
                 echo "# DON'T EDIT: This file is automatically generated from src/ files"
                 echo "###################################################################"
            fi
        fi
    done < "${tmpl}"
} > "${target}.tmp"
chmod ugo+x "${target}.tmp"
mv "${target}.tmp" "${target}"
ls -l "${target}"

echo "Version built: $(bash "${target}" --version)"

echo "Building ${target} from ${tmpl} ... done"