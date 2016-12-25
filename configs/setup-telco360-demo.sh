#!/bin/bash
##############
# Demo Setup #
##############
echo "Beginning demo setup..."

# Setup ssh key.
SSH_KEY=$CDEP_HOME/data/id_rsa
chmod 700 $SSH_KEY

# Set user to ssh as. (CloudCat ssh user is "root".)
SSH_USER="root"

# Set host to connect to. 
# (Remember, if only 1 host has been created then there is not 
# a number in the hostname, so it is just "$DEMOCLUSTERNAME.$DOMAIN". 
# Otherwise, pick a host from "$DEMOCLUSTERNAME-{1..$HOSTCOUNT}.$DOMAIN".)
SSH_HOST="$DEMOCLUSTERNAME.$DOMAIN"

# Build ssh command.
SSH_CMD=
SSH_CMD="$SSH_CMD groupadd supergroup;"
SSH_CMD="$SSH_CMD useradd -G supergroup admin;"
SSH_CMD="$SSH_CMD cd /home/admin;"
SSH_CMD="$SSH_CMD sudo -u admin git clone http://github.mtv.cloudera.com/foe/Telco360GoldenTicketDemo.git;" 
SSH_CMD="$SSH_CMD sudo -u admin Telco360GoldenTicketDemo/demo/bin/setup.sh;"  
SSH_CMD="$SSH_CMD sudo -u admin git clone http://github.mtv.cloudera.com/foe/CDR.git;"
SSH_CMD="$SSH_CMD impala-shell -q 'invalidate metadata;';"

# Run ssh command.
ssh -i $SSH_KEY -o StrictHostKeyChecking=no $SSH_USER@$SSH_HOST "$SSH_CMD"
