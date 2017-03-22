#!/usr/bin/env bash

# Static Variables
script_version=1.0.0

function help_message () {
helpmessage="Description:
    This script uses the AWS CLI and BASH to create, update, delete or get
    status of a CloudFormation Stack. It uses the AWS CLI to push the
    CloudFormation Template to AWS. Then loops over and over checking
    status of the stack.

YAML Config File Format Example:
    stackname: stack1
    profilename: awsaccount
    templateurl: https://s3.amazonaws.com/bucket/webapp1.yml # Or .json
    templatelocal: /path/to/cfn/templates/webapp1.yml # Unless using URL
    parametersfilepath: $HOME/.cfnl/uswest2/client1/account1/dev/webapp1.json
    capabilityiam: false
    capabilitynamediam: false
    deletecreatefailures: true
    uses3template: true
    nolog: false
    logfile: $HOME/.cfnl/logs/uswest2/client1/account1/dev/webapp1.log
    verbose: true
    waittime: 5
    maxwaits: 180

Examples:
    Create Stack
    $0 -f $HOME/.cfnl/uswest2/client1/account1/dev/webapp1.yml

    Update Stack
    $0 -u -f $HOME/.cfnl/uswest2/client1/account1/dev/webapp1.yml

    Delete Stack
    $0 -d -f $HOME/.cfnl/uswest2/client1/account1/dev/webapp1.yml

    Stack Status
    $0 -s -f $HOME/.cfnl/uswest2/client1/account1/dev/webapp1.yml

Author:
    Levon Becker
    https://github.com/LevonBecker
    https://www.bonusbits.com
"
    usage
    echo "$helpmessage";
}

function version_message() {
versionmessage="AWS Environment Manager v$script_version"
    echo "$versionmessage";
}

function usage() {
usagemessage="Usage: $0 [-u | -d | -s] -c ./config_file.yml

Options:
    -c Config YAML      :  (Required) YAML Script Config File Full Path
    -s Show             :  (Action Flag) Sets Action to Get Stack Status
    -d Debug Output     :  Display Additional Output for Debugging
    -h Help             :  Displays Help Information
    -v Version          :  Displays Script Version
"
    version_message
    echo ''
    echo "$usagemessage";
}

while getopts "c:dhsv" opts; do
    case $opts in
        d ) debug=true;;
        c ) config_file_path=$OPTARG;;
        s ) show=true;;
        h ) help_message; exit 0;;
        v ) version_message; exit 0;;
    esac
done

if [ "$config_file_path" == "" ]; then
usage
echo 'ERROR: A YAML Config File is Required!'
exit 1
fi

# Set Task Type
if [ "$update" == "true" ]; then
    task_type=update-stack
else
    task_type=create-stack
fi

function parse_yaml() {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

function message() {
    DATETIME=$(date +%Y-%m-%d_%H:%M:%S)
    if [ "$yaml_nolog" == "true" ]; then
        echo "[$DATETIME] $*"
    else
        echo "[$DATETIME] $*" | tee -a ${yaml_logfile}
    fi
}

function show_header {
    if [ "$yaml_uses3template" == "true" ]; then
        TEMPLATE=${yaml_templateurl}
    else
        TEMPLATE=${yaml_templatelocal}
    fi

	if [ "$debug" == "true" ]; then
	    message "** Start CloudFormation Launcher v$script_version **"
        message '** PARAMETERS **'
        message "ACTION: $ACTION"
        message "STACK NAME: $yaml_stackname"
        message "PROFILE: $yaml_profilename"
        message "TEMPLATE: $TEMPLATE"
        message "PARAMETERS FILE: $yaml_parametersfilepath"
        message "CAPABILITY IAM: $yaml_capabilityiam"
        message "CAPABILITY NAMED IAM: $yaml_capabilitynamediam"
        message "NO LOG: $yaml_nolog"
        message "LOG FILE: $yaml_logfile"
        message "VERBOSE: $yaml_verbose"
        message "LAUNCHER CONFIG: $config_file_path"
        message "DELETE ON FAILURE: $yaml_deletecreatefailures"
        message "WAIT TIME (Sec): $yaml_waittime"
        message "MAX WAITS (Loops): $yaml_maxwaits"
	else
	    message "** Start CloudFormation Launcher v$script_version **"
        message "ACTION: $ACTION"
	fi
}

function exit_check {
    if [ "$triggered_delete" == "true" ]; then
        if [[ $1 -eq 0 || $1 -eq 255 ]]; then
            message "REPORT: Successfully $2"
        else
            message "ERROR:  Exit Code $1 for $2"
            exit $1
        fi
    else
        if [ $1 -eq 0 ]; then
            message "REPORT: Successfully $2"
        else
            message "ERROR:  Exit Code $1 for $2"
            exit $1
        fi
    fi
}