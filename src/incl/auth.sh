# -------------------------------------------------------------------------
# Credentials, e.g. .netrc, prompting for password, etc.
# -------------------------------------------------------------------------
function source_netrc() {
    local rcfile pattern found bfr home

    if [[ -z ${NETRC} ]]; then
        if [[ ${EUID} -eq 0 ]]; then
            ## Identify the HOME folder of the logged in user, even when
            ## 'ucsf-vpn' is called via sudo
            home=$(getent passwd "$(logname)" | cut -d ":" -f 6)
            ## Fall back to HOME, if the above failed
            if [[ ! -d "${home}" ]]; then
                home=${HOME}
            fi
        else
            home=${HOME}
        fi
        rcfile=${home}/.netrc
    else
        rcfile=${NETRC}
    fi

    ## No such file?
    if [[ ! -f "${rcfile}" ]]; then
        mdebug "No .netrc file: $rcfile"
        return
    fi
    mdebug "Detected .netrc file: $rcfile"

    ## Nothing to do?
    if [[ -n "$user" && -n "$pwd" ]]; then
        mdebug "Both 'user' and 'pwd' already set. Skipping .netrc file"
        return
    fi
    
    ## Force file to be accessible only by user
    chmod go-rwx "${rcfile}"

    mdebug "- search: ${netrc_machines[*]}"
    found=false
    for machine in "${netrc_machines[@]}"; do
        pattern="^[ \\t]*machine[ \\t]+${machine}([ \\t]+|$)"
        mdebug "- search pattern: ${pattern}"

        ## No such machine?
        grep -q -E "${pattern}" "${rcfile}"

        # shellcheck disable=SC2181
        if [[ $? -eq 0 ]]; then
            mdebug "- found: ${machine}"
            found=true
            break
        fi
    done

    if ! $found; then
        mdebug "- no such machine: $machine"
        return 0
    fi

    bfr=$(awk "/${pattern}/{print; flag=1; next}/machine[ \\t]/{flag=0} flag;" "${rcfile}")
    [[ -z $bfr ]] && merror "Internal error - failed to extract ${server} credentials from ${rcfile} searching for ${netrc_machines}"

    if [[ -z "$user" ]]; then
        user=$(echo "${bfr}" | grep -F "login" | sed -E 's/.*login[[:space:]]+([^[:space:]]+).*/\1/g')
    fi
    
    if [[ -z "$pwd" ]]; then
        pwd=$(echo "${bfr}" | grep -F "password" | sed -E 's/.*password[[:space:]]+([^[:space:]]+).*/\1/g')
    fi

    mdebug "- user=${user}"
    if [[ -z "${pwd}" ]]; then
        mdebug "- pwd=<missing>"
    else
        mdebug "- pwd=<hidden>"
     fi
}

function prompt_user() {
    user=$1
    if [[ -n "${user}" ]]; then return; fi
    mdebug "PROMPT: Asking user to enter username:"
    while [ -z "${user}" ]; do
        {
            _tput setaf 11  ## bright yellow
            printf "Enter your UCSF Active Directory username: "
            _tput setaf 15  ## bright white
            read -r user
            _tput sgr0      ## reset
        } 1>&2
        user=${user/ /}
    done
    mdebug "- user=${user}"
}

function prompt_pwd() {
    pwd=$1
    if [[ -n "${pwd}" ]]; then return; fi
    mdebug "PROMPT: Asking user to enter password:"
    while [ -z "${pwd}" ]; do
        {
            _tput setaf 11  ## bright yellow
            printf "Enter your UCSF Active Directory password: "
            _tput setaf 15  ## bright white
            read -r -s pwd
            _tput sgr0      ## reset
        } 1>&2
        pwd=${pwd/ /}
    done
    mecho "<password>"

    if [[ -z "${pwd}" ]]; then
        mdebug "- pwd=<missing>"
    else
        mdebug "- pwd=<hidden>"
    fi
}
