#!/usr/bin/env bash

# Currently this script ust be ran from the root of cloned repo directory.

################################################################################
# Symlink
################################################################################
if [ ! -h "/usr/local/bin/aem" ]; then
    echo "INFO: Creating Symlink for AWS Env Manager (aem)"
    ln -s "$(pwd)/aem.sh" /usr/local/bin/aem
    echo "INFO: Created AEM Symlink ($(ls -alh /usr/local/bin/aem))"
fi
