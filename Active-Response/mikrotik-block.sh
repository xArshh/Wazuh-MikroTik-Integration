#!/bin/bash

read INPUT_JSON

SRCIP=$(echo "$INPUT_JSON" | jq -r '.parameters.alert.data.srcaddr')
MIKROTIK_HOST=$(echo "$INPUT_JSON" | jq -r '.parameters.alert.location')
LOGFILE="/var/ossec/logs/active-responses.log"
MIKROTIK_USER="wazuh"
MIKROTIK_PORT="MIKROTIK_SSH_PORT"
ADDRESS_LIST="wazuh-bruteforce"
RULE_COMMENT="Drop-Bruteforce"
SSH_CMD="ssh \
 -i /var/ossec/.ssh/mt_ed25519 \
 -o BatchMode=yes \
 -o StrictHostKeyChecking=no \
 -o UserKnownHostsFile=/dev/null \
 -p $MIKROTIK_PORT \
 ${MIKROTIK_USER}@${MIKROTIK_HOST}"

$SSH_CMD "/ip firewall address-list add list=$ADDRESS_LIST address=$SRCIP comment=Wazuh-Bruteforce timeout=1h" >> "$LOGFILE" 2>&1

if $SSH_CMD "/ip firewall filter print" | grep -q "$RULE_COMMENT"; then
    echo "$(date) - Filter rule found. Skipping." >> "$LOGFILE"
else
    echo "$(date) - Filter rule NOT found. Creating drop rule..." >> "$LOGFILE"
    $SSH_CMD "/ip firewall filter add chain=input src-address-list=$ADDRESS_LIST action=drop comment=\"$RULE_COMMENT\" place-before=0" >> "$LOGFILE" 2>&1
fi
