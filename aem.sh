#!/usr/bin/env bash

# Static Variables
script_version=1.0.0

function help_message () {
helpmessage="Description:
    This script uses set shell environment variables related to AWS.
    Such as, for Test Kitchen and AWS CLI.

YAML Config File Format Example:
    AWS_REGION: 'us-west-2'
    AWS_PROFILE: 'myprofile'
    AWS_PUBLIC_IP: 'false'
    AWS_SSH_KEY_ID: 'account_dev'
    AWS_SSH_KEY_PATH: '$HOME/.ssh/account.pem'
    AWS_VPC_ID: 'vpc-00000000'
    AWS_IAM_INSTANCE_PROFILE_1: 'base-iam-policy'
    AWS_SECURITY_GROUP_1: 'sg-00000000'
    AWS_SECURITY_GROUP_2: 'sg-00000000'
    AWS_SECURITY_GROUP_3: 'sg-00000000'
    AWS_SECURITY_GROUP_4: 'sg-00000000'
    AWS_SUBNET_PUBLIC: 'subnet-00000000'
    AWS_SUBNET_PRIVATE: 'subnet-00000000'

Examples:
    Set Env Vars
    $0 -f $HOME/.aem/uswest2/client1/account1/dev/webapp1.yml

    Show Current Settings
    $0 -s

    Clear Current Settings
    $0 -c

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
usagemessage="Usage: $0 [options] -f ./config_file.yml

Options:
    -f YAML File        :  (Required) YAML Script Config File Full Path
    -c Clear            :  (Flag) Clear All AWS Env variables
    -s Show             :  (Flag) Show Current AWS Env variables
    -d Debug Output     :  Display Additional Output for Debugging
    -h Help             :  Displays Help Information
    -v Version          :  Displays Script Version
"
    version_message
    echo ''
    echo "$usagemessage";
}

while getopts "f:cdhsv" opts; do
    case $opts in
        d ) debug=true;;
        f ) config_file_path=$OPTARG;;
        c ) clear=true;;
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
	    message "** Start AWS Environment Manager v$script_version **"
        message '** PARAMETERS **'
        message "ACTION: $ACTION"
        message "STACK NAME: $yaml_stackname"
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

# Kitchen-EC2
function aws-region(){
	export AWS_DEFAULT_REGION=$1
	export AWS_REGION=$1
}

function aws-clear(){
	# With varying number of SG and IAM Instance Profiles then need to be cleared in-between sets
	unset AWS_SSH_KEY_ID AWS_SSH_KEY_PATH AWS_PROFILE AWS_DEFAULT_REGION AWS_REGION AWS_VPC_ID AWS_SUBNET AWS_PUBLIC_IP
	unset AWS_IAM_INSTANCE_PROFILE_1 AWS_IAM_INSTANCE_PROFILE_2 AWS_IAM_INSTANCE_PROFILE_3 AWS_IAM_INSTANCE_PROFILE_4 AWS_IAM_INSTANCE_PROFILE_5
	unset AWS_SECURITY_GROUP_1 AWS_SECURITY_GROUP_2 AWS_SECURITY_GROUP_3 AWS_SECURITY_GROUP_4 AWS_SECURITY_GROUP_5
}

function aws-show() {
	echo ''
	echo "Configured AWS Environment Variables"
	echo "--------------------------------------"
	echo "AWS_SSH_KEY_ID = $AWS_SSH_KEY_ID"
	echo "AWS_SSH_KEY_PATH = $AWS_SSH_KEY_PATH"
	echo "AWS_PROFILE = $AWS_PROFILE"
	echo "AWS_DEFAULT_REGION = $AWS_DEFAULT_REGION"
	echo "AWS_REGION = $AWS_REGION"
	echo "AWS_VPC_ID = $AWS_VPC_ID"
	echo "AWS_SUBNET = $AWS_SUBNET"
	echo "AWS_PUBLIC_IP = $AWS_PUBLIC_IP"
	echo "AWS_IAM_INSTANCE_PROFILE_1 = $AWS_IAM_INSTANCE_PROFILE_1"
	if [ -n "$AWS_IAM_INSTANCE_PROFILE_2" ]; then	echo "AWS_IAM_INSTANCE_PROFILE_2 = $AWS_IAM_INSTANCE_PROFILE_2"; fi
	if [ -n "$AWS_IAM_INSTANCE_PROFILE_3" ]; then	echo "AWS_IAM_INSTANCE_PROFILE_3 = $AWS_IAM_INSTANCE_PROFILE_3"; fi
	if [ -n "$AWS_IAM_INSTANCE_PROFILE_4" ]; then	echo "AWS_IAM_INSTANCE_PROFILE_4 = $AWS_IAM_INSTANCE_PROFILE_4"; fi
	if [ -n "$AWS_IAM_INSTANCE_PROFILE_5" ]; then	echo "AWS_IAM_INSTANCE_PROFILE_5 = $AWS_IAM_INSTANCE_PROFILE_5"; fi
	echo "AWS_SECURITY_GROUP_1 = $AWS_SECURITY_GROUP_1";
	if [ -n "$AWS_SECURITY_GROUP_2" ]; then	echo "AWS_SECURITY_GROUP_2 = $AWS_SECURITY_GROUP_2"; fi
	if [ -n "$AWS_SECURITY_GROUP_3" ]; then	echo "AWS_SECURITY_GROUP_3 = $AWS_SECURITY_GROUP_3"; fi
	if [ -n "$AWS_SECURITY_GROUP_4" ]; then	echo "AWS_SECURITY_GROUP_4 = $AWS_SECURITY_GROUP_4"; fi
	if [ -n "$AWS_SECURITY_GROUP_5" ]; then	echo "AWS_SECURITY_GROUP_5 = $AWS_SECURITY_GROUP_5"; fi
	echo ''
}