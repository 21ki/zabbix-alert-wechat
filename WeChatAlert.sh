#!/bin/bash

# Filename:    WeChatAlert.sh
# Revision:    1.1
# Date:        2019/08/30
# Author:      aeternus <aeternus@aliyun.com>
# Description: Zabbix Alert Script - WeChat
# Requirements:
#   - Gnu/wget
#   - grep with perl regular expression support

# ======================================
# Print usage info

function usage() {
    printf "Usage:\n"
    printf "  WeChatAlert.sh [options]\n\n"

    printf "Send Zabbix Alert Message to WeChat Work.\n\n"

    printf "Options:\n"
    printf "  -i, --corpid <corpid>             WeChat corp id, required\n"
    printf "  -s, --corpsecret <corpsecret>     WeChat corp secret, required\n"
    printf "  -a, --agentid <agentid>           WeChat APP id, required\n"
    printf "  -t, --tagid <tagid>               WeChat tag id, required\n"
    printf "  -j, --alert-subject <subject>     alert subject, required\n"
    printf "  -c, --alert-content <content>     alert content, required\n"
}

# ======================================
# Get access_token
# set: ACCESS_TOKEN

function getAccessToken() {
     ACCESS_TOKEN=$(wget -q -O - "${GET_URL}" | grep -o -P '(?<=access_token":")[^"]+' 2>/dev/null)
}

# ======================================
# Send msg
# set: ERR_CODE

function sendMsg() {
    POST_URL="https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token=${ACCESS_TOKEN}"

    # data to post
    POST_DATA="{\
      \"totag\" : ${TAGID},\
      \"msgtype\" : \"text\",\
      \"agentid\" : ${AGENTID},\
      \"text\" : {\
        \"content\" : \"${ALERT}\"\
      },\
      \"safe\" : 0\
    }"

    # send msg, get errcode
    ERR_CODE=$(wget -q -O - --post-data="${POST_DATA}" ${POST_URL} | grep -o -P '(?<=errcode":)\d+' 2>/dev/null)
}

# read the options
TEMP=$(getopt -o i:s:a:t:j:c: -l corpid:,corpsecret:,agentid:,tagid:,alert-subject:,alert-content: -- "$@")
if [ $? != 0 ]; then printf "Invalid argument!\n\n"; usage; exit 1; fi
eval set -- "$TEMP"

# extract options and their arguments into variables.
while true; do
  case "$1" in
    -i|--corpid)              CORP_ID=$2; shift 2 ;;
    -s|--corpsecret)          CORP_SECRET=$2; shift 2 ;;
    -a|--agentid)             AGENTID=$2; shift 2 ;;
    -t|--tagid)               TAGID=$2; shift 2 ;;
    -j|--alert-subject)       ALERT_SUBJECT="$2"; shift 2 ;;
    -c|--alert-content)       ALERT_CONTENT="$2"; shift 2 ;;
    --)                       shift; break ;;
    *)                        printf "Internal error!\n\n"; usage; exit 1 ;;
  esac
done

# check arguments
if [ -z "$CORP_ID" ] || [ -z "$CORP_SECRET" ] || [ -z "$AGENTID" ] \
  || [ -z "$TAGID" ] || [ -z "$ALERT_SUBJECT" ] || [ -z "$ALERT_CONTENT" ]; then
  printf "Missing some arguments!\n\n"
  usage
  exit 1
fi

ALERT="${ALERT_SUBJECT}\n\n${ALERT_CONTENT}"                    # whcaht: content to send

ACCESS_TOKEN=""                         # wechat: access_token
ERR_CODE=""                             # result.errcode after send message

# url to get access_key
GET_URL="https://qyapi.weixin.qq.com/cgi-bin/gettoken?corpid=${CORP_ID}&corpsecret=${CORP_SECRET}"

# file cached access_key
TOKEN_CACHE_FILE=/var/lib/zabbix/wechat_token

# ======================================
# alert

if [ -f "${TOKEN_CACHE_FILE}" ] && read ACCESS_TOKEN < "${TOKEN_CACHE_FILE}"; then
    # access_token cache exist, send msg
    sendMsg

    # if send msg error(access_token cache expired), get new access_token and re-send msg
    if [[ "${ERR_CODE}" -ne 0 ]]; then
        # get access_token and save to cache file
        getAccessToken
        echo -n "${ACCESS_TOKEN}" > "${TOKEN_CACHE_FILE}"

        # send msg
        sendMsg
    fi
    # if access_token cache expired, get new one and send msg again
else
    # access_token cache not exist, get from wechat and save to cache file
    getAccessToken
    echo -n "${ACCESS_TOKEN}" > "${TOKEN_CACHE_FILE}"

    # send msg
    sendMsg
fi

exit ${ERR_CODE}
