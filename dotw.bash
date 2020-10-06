#!/bin/zsh
# dotw.bash
# Import Twitter posts into Day One.
# by Susan Pitman
# 11/14/14 Script created.
# 2/15/2019 Updated for dayone2. Added photo and tagging feature.
# Changes by Tanja Orme:
## 2020-10-06 changed date to international format 
## changed a few things with how the photos are found
## made adjustments for twitters current folder structure (data/tweet_media  and data/tweet.js)

# Notes:
# 1. Change the twitter downloaded stuff directory name to "twitter."
# 2. Set your twitter username variable below. (Feel free to fix this; I was being lazy.)
# 3. Set your timezone variable below.

#set -x

thisDir=`pwd`
twitterUsername="[username]"
timeZone="GMT+1:00"

makePostFiles () {
    if ls -ld ${thisDir}/dotwPosts 2> /dev/null ; then
      printf "The posts directory already exists.\n"
     else
      mkdir ${thisDir}/dotwPosts
    fi
    fileNum="0"
    echo "" > "${thisDir}/dotwPosts/post.0"
      printf "Processing tweet.js file..."
      # Each line in the monthly download file...
      while read thisLine ; do
      if echo ${thisLine} | grep "\"source\" :" > /dev/null ; then
        printf "."
        ((fileNum++))
        fileNumPadded=`printf %06d $fileNum`
        # Make a new file for each individual post.
        echo ${thisLine} > ${thisDir}/dotwPosts/post.${fileNumPadded}
       else
        echo ${thisLine} >> ${thisDir}/dotwPosts/post.${fileNumPadded}
      fi
  done < ${thisDir}/data/tweet.js
  printf "\n"
}

postPopper () {
  rm "${thisDir}/dotwPosts/post." "${thisDir}/dotwPosts/post.0" 2> /dev/null #Garbage file
  for fileName in `ls ${thisDir}/dotwPosts/p*` ; do
    postMedia=""
    postMediaUrl=""
    postMediaFilename=""
    postTags=""
    postDT=`grep "created_at" ${fileName} | cut -d"\"" -f4`
    postYear=`echo ${postDT} | cut -d" " -f6`
    postMonthWord=`echo ${postDT} | cut -d" " -f2`
    postMonth=`date -j -v${postMonthWord}m '+%m'`
    postDay=`echo ${postDT} | cut -d" " -f3`
    postTime=`echo ${postDT} | cut -d" " -f4`
    postHourGmt=`echo ${postDT} | cut -d" " -f4 | cut -d":" -f1`
    postMinute=`echo "${postDT}" | cut -d" " -f4 | cut -d":" -f2`
    postSecond=`echo "${postDT}" | cut -d" " -f4 | cut -d":" -f3`
    #TZ=US/Chicago date -jf "%Y-%m-%d %H:%M:%S %z" "2011-11-13 08:11:02 +0000" +"%Y_%m_%d__%H_%M_%S"
    postYear=`TZ="${timeZone}" date -jf "%Y-%m-%d %H:%M:%S %z" "${postYear}-${postMonth}-${postDay} ${postHourGmt}:${postMinute}:${postSecond} +0000" +%Y`
    postMonth=`TZ="${timeZone}" date -jf "%Y-%m-%d %H:%M:%S %z" "${postYear}-${postMonth}-${postDay} ${postHourGmt}:${postMinute}:${postSecond} +0000" +%m`
    postDay=`TZ="${timeZone}" date -jf "%Y-%m-%d %H:%M:%S %z" "${postYear}-${postMonth}-${postDay} ${postHourGmt}:${postMinute}:${postSecond} +0000" +%d`
    postHour=`TZ="${timeZone}" date -jf "%Y-%m-%d %H:%M:%S %z" "${postYear}-${postMonth}-${postDay} ${postHourGmt}:${postMinute}:${postSecond} +0000" +%H`
    postMinute=`TZ="${timeZone}" date -jf "%Y-%m-%d %H:%M:%S %z" "${postYear}-${postMonth}-${postDay} ${postHourGmt}:${postMinute}:${postSecond} +0000" +%M`

#    if [ ${postHour} -gt "12" ] ; then
#      postHour=`expr ${postHour} - 12`
#      postAMPM="PM"
#     else
#      postAMPM="AM"
#    fi
#    if [ ${postHour} = "00" ] ; then
#      postTitle="Twitter Post"
#     else
### I gave up fighting with this.
### If someone wants to figure out the time conversion, be my guest to clean up my mess...
#      postTitle="Twitter Post \@ ${postHour}\:${postMinute} ${postAMPM}"
      #postTitle="Twitter Post \@ ${postHour}\:${postMinute}"
#    fi

    postId=`cat ${fileName} | sed -n '/favorite_/,$p' | sed -n "/favorited\"/q;p" | grep "id\"" | tail -2 | head -1 | cut -d"\"" -f4`
    postUrl="https://twitter.com/${twitterUsername}/status/${postId}"
    postFullText=`grep "\"full_text\"" ${fileName} | cut -d"\"" -f4 | sed 's/\"\,$//'`
    postTextComplete="${postTitle}\n\n${postFullText}\n${postText}\n\n<${postUrl}>\n"
    postDateTimeForDayOne="${postYear}-${postMonth}-${postDay} ${postHour}:${postMinute}"
    printf "\nFilename: ${fileName}\n"
    postMediaUrl=`grep "expanded_url\" : \"https://twitter.com/.*/status/.*/photo" ${fileName} | head -1 | cut -d"\"" -f4 | sed 's|.*status/||'| sed 's|/photo.*||'`
    printf "\nMediaUrl: ${postMediaUrl}"

    if [ "${postMediaUrl}" != "" ] ; then
      #postMedia=`basename ${postMediaUrl}`
      postMediaFilename=`find ${thisDir}/data/tweet_media -name "${postMediaUrl}*" | egrep "jpg|png|gif"`
    fi
    printf "\n${postMediaFilename}"

    postTags=`grep "\"text\"" ${fileName} | cut -d":" -f2 | cut -d"\"" -f2 | sed 's/$/ /' | tr -d '\n' | sed 's/$/\ /'`
    printf "\nPost Date: ${postDateTimeForDayOne}\n"
    if [ "${postMediaFilename}" != "" ] ; then
      if [ "${postTags}" != "" ] ; then
        printf "${postTextComplete}" | /usr/local/bin/dayone2 new -t twitter ${postTags} -p ${postMediaFilename} -d="${postDateTimeForDayOne}"
       else
        printf "${postTextComplete}" | /usr/local/bin/dayone2 new -p ${postMediaFilename} -t twitter -d="${postDateTimeForDayOne}"
      fi
     else
      if [ "${postTags}" != "" ] ; then
        printf "${postTextComplete}" | /usr/local/bin/dayone2 -t twitter ${postTags} -d="${postDateTimeForDayOne}" new
       else
        printf "${postTextComplete}" | /usr/local/bin/dayone2 -t twitter -d="${postDateTimeForDayOne}" new
      fi
    fi
    shortName=`echo ${fileName} | tr '/' '\n' | tail -1`
    mv ${fileName} ${thisDir}/dotwPosts/done.${shortName}
    printf "`ls ${thisDir}/dotwPosts/p* | wc -l` posts left to import.\n"
    sleep 5
#    printf "Hit Enter for the next one... " ; read m
#    uncomment the above line if you want to press enter in between posts, usefull if you're still testing
  done
}

## MAIN ##
makePostFiles
# comment out the above line if you interrupt the making of the posts so it doesn't process tweet.js again

echo "Make Post Files"
postPopper
## END OF SCRIPT ##
