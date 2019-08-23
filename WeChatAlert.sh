#!/bin/bash

# Filename:    WeChatAlert.sh
# Revision:    1.0
# Date:        2019/08/21
# Author:      aeternus <aeternus@aliyun.com>
# Description: Zabbix Alert Script - WeChat

# $1: corpid
# $2: corpsecret
# $3: agentid
# $4: tagid
# $5: message subject
# $6: message body

CORP_ID="$1"                            # wechat: corpid
CORP_SECRET="$2"                        # wechat: corpsecret
AGENTID="$3"                            # wechat: agentid
TAGID="$4"                              # wechat: tagid

ACCESS_TOKEN=""                         # wechat: access_token
MESSAGE="$5\n\n$6\n"                    # content to send
ERR_CODE=""                             # errcode for send message

# url to get access_key
GET_URL="https://qyapi.weixin.qq.com/cgi-bin/gettoken?corpid=${CORP_ID}&corpsecret=${CORP_SECRET}"

# file cached access_key
TOKEN_CACHE_FILE=/var/lib/zabbix/wechat_token

# ======================================
# Get access_token
# set: ACCESS_TOKEN

function getAccessToken() {
     ACCESS_TOKEN=$(wget -q -O - "${GET_URL}" | grep -o -P '(?<=access_token":")[^"]+')
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
        \"content\" : \"${MESSAGE}\"\
      },\
      \"safe\" : 0
    }"

    # send msg, return errcode
    ERR_CODE=$(wget -q -O - --post-data="${POST_DATA}" ${POST_URL} | grep -o -P '(?<=errcode":)\d+')
}

# ======================================
# alert

if [ -f "${TOKEN_CACHE_FILE}" ] && read ACCESS_TOKEN < "${TOKEN_CACHE_FILE}"; then
    # access_token cache exist, send msg
    sendMsg

    # if send msg error(access_token cache expired), get new access_token and re-send msg
    if [[ "${ERR_CODE}" -ne 0 ]]; then
        # get online and write to cache
        getAccessToken
        echo -n "${ACCESS_TOKEN}" > "${TOKEN_CACHE_FILE}"

        # send msg
        sendMsg
    fi
    # if access_token cache expired, get new one and sender msg again
else
    # access_token cache not exist, get online and write to cache
    getAccessToken
    echo -n "${ACCESS_TOKEN}" > "${TOKEN_CACHE_FILE}"

    # send msg
    sendMsg
fi

exit ${ERR_CODE}
