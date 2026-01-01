This document explains how to extend the Wazuh–MikroTik integration with an Active Response mechanism.

**Prerequisites**

- Existing MikroTik decoders & rules already deployed and working

### Step 1 – Create a Dedicated Wazuh User on MikroTik

Never let automation run as admin.

Create a group with only required access permissions & Create the user
```
/user group add name=wazuh-ar policy=read,write,policy,test,ssh
```
```
/user add name=wazuh group=wazuh-ar password=STRONG_PASSWORD address=WAZUH_MANAGER_IP
```
❗Note:
- Replace STRONG_PASSWORD with a strong password
- Replace WAZUH_MANAGER_IP with the IP address of your Wazuh manager to Restrict SSH access to the Wazuh manager IP only

### Step 2 – Configure SSH Key-Based Authentication

**On the Wazuh Server**

Create the SSH directory if it does not exist:
```
mkdir -p /var/ossec/.ssh
```
Generate a dedicated SSH key:
```
ssh-keygen -t ed25519 -f /var/ossec/.ssh/mt_ed25519
```
Set correct permissions:
```
chown wazuh:wazuh /var/ossec/.ssh
chmod 700 /var/ossec/.ssh
chmod 600 /var/ossec/.ssh/mt_ed25519
chmod 644 /var/ossec/.ssh/mt_ed25519.pub
```
You can download the key file or copy the public key content (save it for the next step):
```
cat /var/ossec/.ssh/mt_ed25519.pub
```
The key must start with ssh-ed25519 AAA and end with USER@WAZUH-SERVER-HOSTNAME.

**Copy Public Key to MikroTik**

If you uploaded the key file to MikroTik
```
/user ssh-keys import public-key-file=mt_ed25519.pub user=wazuh
```
If you copied the key content manually
```
/user ssh-keys add user=wazuh key="ENTIRE_KEY_FILE_CONTENT"
```
**Verify SSH Access**
```
ssh -i /var/ossec/.ssh/mt_ed25519 wazuh@MIKROTIK_IP -p MIKROTIK_SSH_PORT
```
You must be able to connect to MikroTik without a password. If this step fails, Active Response will fail silently. This test is mandatory.



### Step 3 – Active Response Script

The script logic is intentionally conservative:
- Extract source IP from the alert
- Check if a firewall rule already exists
- If not, add a drop rule
- Never delete rules (timeouts handle cleanup)


Copy the script to the Active Response directory:
```
cp PATH/TO/FOLDER/mikrotik-block.sh /var/ossec/active-response/bin/mikrotik-block.sh
```
Set permissions:
```
chmod 750 /var/ossec/active-response/bin/mikrotik-block.sh
```
```
chown root:wazuh /var/ossec/active-response/bin/mikrotik-block.sh
```

If you used different values, update the following variables inside the script:

- MIKROTIK_USER="wazuh"
- MIKROTIK_PORT="MIKROTIK_SSH_PORT"


### Step 4 – Register Active Response in ossec.conf
Add the following configuration under <ossec_config> after the last <command> entry:
```
<!-- MikroTik brute force block -->
<command>
  <name>mikrotik-bruteforce-block</name>
  <executable>mikrotik-block.sh</executable>
  <timeout_allowed>yes</timeout_allowed>
</command>

<active-response>
  <command>mikrotik-bruteforce-block</command>
  <location>server</location>
  <rules_id>201007</rules_id>
  <timeout>3600</timeout>
</active-response>
```
Restart Wazuh Manager:
systemctl restart wazuh-manager


### Step 5 – Rule Threshold Example (Proof of Concept)
Example logic:
- 10 failed login attempts
- Same source IP
- Within a defined time window
When triggered, the source IP is added to a dynamic address list and blocked immediately.

This completes the Active Response setup for automatic brute-force mitigation on MikroTik devices using Wazuh

