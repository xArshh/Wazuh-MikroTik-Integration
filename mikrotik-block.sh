#!/bin/bash

read INPUT_JSON

ACTION=$(echo "$INPUT_JSON" | jq -r '.command')
SRCIP=$(echo "$INPUT_JSON" | jq -r '.parameters.alert.data.srcaddr')
LOGFILE="/var/ossec/logs/active-responses.log"
MIKROTIK_USER="Wazuh"
MIKROTIK_HOST=$(echo "$INPUT_JSON" | jq -r '.parameters.alert.location')
MIKROTIK_PORT="MIKROTIK-SSH-PORT"
ADDRESS_LIST="wazuh-bruteforce"
RULE_COMMENT="Drop-Bruteforce"
RAW_OUTPUT=$($SSH_CMD "/ip firewall filter print count-only where comment=\"$RULE_COMMENT\"" 2>/dev/null)
CHECK_FILTER=$(echo "$RAW_OUTPUT" | sed 's/\x1b\[[0-9;]*m//g' | tr -d '\r\n[:space:]')
SSH_CMD="ssh \
 -i /var/ossec/.ssh/id_ed25519 \
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
