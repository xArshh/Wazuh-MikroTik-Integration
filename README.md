# Wazuh-MikroTik Integration
This repository provides custom Wazuh decoders and security detection rules for parsing, normalizing, and monitoring MikroTik RouterOS logs.
The goal of this project is to give Wazuh clear visibility into critical MikroTik events.

### Tested On
-  MikroTik RouterOS: 7.20.2
-  Wazuh: 4.12 & 4.14

**The following MikroTik events are currently covered by decoders in this repository:**

###  Authentication & User Activity
- Successful user login
- Failed login attempts
- User logout events
- VPN login, logout, and authentication failures
- User password changes
- User add/change operations
- Mikrotik special-login events

###  System & Configuration Changes
- System identity changes
- System time changes
- System Timezone changes
- IP service configuration changes
- DNS configuration changes

###  Firewall Changes
- IPv4 filter rule add/change
- IPv4 filter rule removal
- IPv6 filter rule add/change
- IPv6 filter rule removal

###  Script Activity
- Script creation
- Script removal


## Setup Instructions

Wazuh can receive syslog messages from remote devices like MikroTik.  
If you prefer, you can read the official documentation here:

https://documentation.wazuh.com/current/user-manual/capabilities/log-data-collection/syslog.html

Below is a quick, practical setup to get your Manager listening for syslog:

### Step 1: Configure Wazuh manager to Receive Syslog

Edit `/var/ossec/etc/ossec.conf` in Wazuh manager server and make sure the following block exists (or add/change it if missing):

```
<remote>
  <connection>syslog</connection>
  <port>514</port>
  <protocol>udp</protocol>
  <allowed-ips>YOUR_MIKROTIK_IP</allowed-ips>
  <local_ip>YOUR_WAZUH_SERVER_IP</local_ip>
</remote>
```

❗**Note #1:** Make sure to replace YOUR_WAZUH_MANAGER_IP with the IP address of your Wazuh  manager server

❗**Note #2:** Make sure to replace YOUR_MIKROTIK_IP with the IP address of your MikroTik or use 0.0.0.0 to accept all IPs

You can also use TCP syslog if needed instead of UDP by changing protocol tag like this:

```
<protocol>tcp</protocol>
```

### Step 2: Deploy MikroTik Decoders & Rules

Copy the decoder file to the Wazuh decoders directory:

```
cp /PATH/TO/FOLDER/mikrotik-decoders.xml /var/ossec/etc/decoders/mikrotik-decoders.xml
```

Copy the rules file to the Wazuh rules directory:

```
cp /PATH/TO/FOLDER/mikrotik-rules.xml /var/ossec/etc/rules/mikrotik-rules.xml
```

❗**Note:** Make sure to replace /PATH/TO/FOLDER with the real path



### Step 3: Restart Wazuh Manager

Apply the changes by restarting Wazuh:
```
sudo systemctl restart wazuh-manager
```
### Step 4: Configure MikroTik to Send Logs

Configure MikroTik to forward logs to the Wazuh syslog server:

**From CLI:**

```
/system logging action add name=WazuhTest target=remote remote=YOUR_WAZUH_MANAGER_IP remote-port=514 remote-protocol=udp remote-log-format=syslog syslog-facility=daemon syslog-time-format=bsd-syslog vrf=main
```

```
/system logging add action=WazuhTest topics=info
/system logging add action=WazuhTest topics=ppp
/system logging add action=WazuhTest topics=error
/system logging add action=WazuhTest topics=system
```

❗**Note #1: You can choose any name for the first command, but make sure to use the same name as the action in the second command**

❗**Note #2: You can change port & protocol to anything you want based on your configuration (Default 514/UDP)**

❗**Note #3: Change the vrf value if your MikroTik setup uses a non-default VRF**


**From GUI:**

<img width="1210" height="1030" alt="MT-Redacted" src="https://github.com/user-attachments/assets/69e849b8-e148-4551-bb7b-7c8d9df09725" />


### Contributing
Contributions are welcome.
If you want to:
-	Add new decoders & rules
-	Improve regex accuracy
-	Add rules with proper severity mapping
-	Extend RouterOS coverage

Open a pull request or create an issue.

### ⭐ Support
If this repository helped you:
-	Give it a ⭐️
-	Share feedback
  
That’s how it gets better.
