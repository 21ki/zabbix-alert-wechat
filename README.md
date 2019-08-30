# zabbix-wechat-alert
zabbix alertscripts - WeChat

Send zabbix alert message to wechat work using tag.

# Requirements

* Gnu/wget
* grep with perl regular expression support

# Usage

    Usage:
      WeChatAlert.sh [options]
    
    Send Zabbix Alert Message to WeChat Work.
    
    Options:
      -i, --corpid <corpid>             WeChat corp id, required
      -s, --corpsecret <corpsecret>     WeChat corp secret, required
      -a, --agentid <agentid>           WeChat APP id, required
      -t, --tagid <tagid>               WeChat tag id, required
      -j, --alert-subject <subject>     alert subject, required
      -c, --alert-content <content>     alert content, required
