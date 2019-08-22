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

CORP_ID="$1"
CORP_SECRET="$2"
AGENTID="$3"
TAGID="$4"

MESSAGE="$5\n\n$6\n"

TOKEN_CACHE_FILE=/var/lib/zabbix/wechat_token

# ======================================
# Get access_token
# $1: corpid
# $2: corpsecret
# return: access_token
function getAccessToken() {
    GET_URL="https://qyapi.weixin.qq.com/cgi-bin/gettoken?corpid=${CORP_ID}&corpsecret=${CORP_SECRET}"

    printf $(wget -q -O - "${GET_URL}" | grep -o -P '(?<=access_token":")[^"]+')
}

# ======================================
# Send msg
# $1: access_token
# $2: totag
# $3: agentid
# $4: msg content
# return: errcode

# msg body sample
# {
#  "totag" : "abelzhu|ZhuShengben",
#  "msgtype" : "text",
#  "agentid" : 1000002,
#  "text" : {
#      "content" : "test msg"
#  },
#  "safe":0
# }

#POST_URL="https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token=$1"
function sendMsg() {
    POST_URL="https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token=$1"

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
    printf $(wget -q -O - --post-data="${POST_DATA}" ${POST_URL} | grep -o -P '(?<=errcode":)\d+')
}

# alert

if [ -f "${TOKEN_CACHE_FILE}" ] && read ACCESS_TOKEN < "${TOKEN_CACHE_FILE}"; then
    # access_token cache exist, send msg
    ERR_CODE=$(sendMsg "${ACCESS_TOKEN}")

    # if send msg error(access_token cache expired), get new access_token and re-send msg
    if [[ "${ERR_CODE}" -ne 0 ]]; then
        # get online and write to cache
        ACCESS_TOKEN="$(getAccessToken)"
        echo -n "${ACCESS_TOKEN}" > "${TOKEN_CACHE_FILE}"

        # send msg
        ERR_CODE=$(sendMsg "${ACCESS_TOKEN}")
    fi
    # if access_token cache expired, get new one and sender msg again
else
    # access_token cache not exist, get online and write to cache
    ACCESS_TOKEN="$(getAccessToken)"
    echo -n "${ACCESS_TOKEN}" > "${TOKEN_CACHE_FILE}"

    # send msg
    ERR_CODE=$(sendMsg "${ACCESS_TOKEN}")
fi

exit ${ERR_CODE}
