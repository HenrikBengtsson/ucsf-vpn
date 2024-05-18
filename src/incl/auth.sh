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

function type_of_token() {
    local token

    token=$1

    ## Hardcoded methods
    if [[ ${token} =~ ^phone[1-9]*$ ]]; then
        ## Tested with 'phone' and 'phone2', but for some reason
        ## the same phone number is called although I've got two
        ## different registered.  Also 'phone1' and 'phone3' gives
        ## an error.
        mdebug "Will authenticate via a call to a registered phone number"
        echo "phone call"
        return
    elif [[ ${token} == "push" ]]; then
        mdebug "Will authenticate via push (approve and confirm in Duo app)"
        echo "push"
        return
    elif [[ ${token} =~ ^(sms|text)[1-9]*$ ]]; then
        mdebug "Will send token via SMS"
        echo "SMS token"
        return
    elif [[ ${token} == "false" ]]; then
        mdebug "Will not use token (in the form)"
        echo "none"
        return
    fi

    ## YubiKey token (44 lower-case letters)
    if [[ ${#token} -eq 44 ]] && [[ ${token} =~ ^[a-z]+$ ]]; then
        mdebug "YubiKey token detected"
        echo "YubiKey token"
        return
    fi

    ## Digital token
    if [[ ${token} =~ ^[0-9]+$ ]]; then
        if [[ ${#token} -eq 6 ]]; then
            mdebug "Six-digit token detected"
            echo "six-digit token"
            return
        elif [[ ${#token} -eq 7 ]]; then
            mdebug "Seven-digit token detected"
            echo "seven-digit token"
            return
        fi
    fi

    echo "unknown"
}

function prompt_token() {
    local type

    token=$1
    if [[ ${token} == "prompt" || ${token} == "true" ]]; then token=; fi
    if [[ -n "${token}" ]]; then return; fi

    mdebug "PROMPT: Asking user to enter one-time token:"
    type="unknown token"
    while [ -z "${token}" ]; do
        {
            _tput setaf 11  ## bright yellow
            printf "Enter 'push' (default), 'phone', 'sms', a 6 or 7 digit token, or press your YubiKey: "
            _tput setaf 15  ## bright white
            read -r -s token
            _tput sgr0      ## reset
            ## Default?
            if [[ -z $token ]]; then
                token="push"
            fi
        } 1>&2
        token=${token/ /}
        type=$(type_of_token "$token")
        if [[ $type == "unknown token" ]]; then
            {
                _tput setaf 1 ## red
                printf "\\nERROR: Not a valid token ('push', 'phone', 'sms', 6 or 7 digits, or 44-letter YubiKey sequence)\\n"
                _tput sgr0      ## reset
            } 1>&2
            token=
        fi
    done
    mecho "<$type>"

    if [[ -z "${token}" ]]; then
        mdebug "- token=<missing>"
    else
        mdebug "- token=<hidden>"
    fi
}
