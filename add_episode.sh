#!/bin/bash

PODCAST_NAME="PODCAST_NAME"
BASE_EPISODE_URL="https://example.com"
RSS_FILE="PATH_TO_YOUR/rss.xml"

downloadPath="./audio"

maxTries=4
countTries=1

while [ $countTries  -lt $maxTries ]; do
        webpage_content=$(wget -q -O - "https://podtail.com/podcast/$PODCAST_NAME/")
        current_episode_link=$(echo "$webpage_content" | grep -o '<a [^>]*href="[^"]*spotify.com/episode[^"]*"[^>]*>' | head -n 1 | sed -n 's/.*href="\([^"]*\)".*/\1/p')

        last_entry=$(sqlite3 ./downloadedPodcasts.db "SELECT filename FROM recent_files ORDER BY ROWID DESC LIMIT 1;")
        if [[ "$last_entry" == "$current_episode_link" ]]; then
          echo "($countTries/$maxTries): No new episode. Trying again..."
          ((countTries++))
          sleep 1m
          continue
        else
          # Update the database with the new file name
          sqlite3 ./downloadedPodcasts.db "INSERT OR REPLACE INTO recent_files (filename) VALUES ('$current_episode_link');"
          break
        fi
done

if [[ $countTries -eq $maxTries ]]; then
    echo "Couldn't find new episode after $maxTries tries"
    exit 1
fi


#current_episode_name=$(echo "$webpage_content" | grep -o '<h3>[^<]*</h3>' | head -n 1 | sed -n 's/<[^>]*>\(.*\)<[^>]*>/\1/p')
current_episode_name=$(echo "$webpage_content" | grep -o '<h3>[^<]*</h3>' | head -n 1 | sed -n 's/<[^>]*>\(.*\)<[^>]*>/\1/p' | sed 's/[&]/\&amp;/g; s/[<]/\&lt;/g; s/[>]/\&gt;/g; s/["]/\&quot;/g; s/'"'"'/\&#39;/g')

current_episode_pub_date=$(echo "$webpage_content" | grep -o '<time[^>]*>[^<]*</time>' | head -n 1 | sed -n 's/<time[^>]*>\(.*\)<\/time>/\1/p')

echo "$current_episode_link"

zotify --root-podcast-path $downloadPath --skip-existing=True --retry-attempts=8 --bulk-wait-time=15 --md-allgenres=True "$current_episode_link"

recent_file=$(find "$downloadPath" -type f -printf "%T@ %p\n" | sort -n | tail -n 1 | cut -f2- -d" ")

# Print the name of the most recently modified file
echo "The most recently downloaded file is: $recent_file"
# Print the name of the most recently modified file
echo "The most recently downloaded file is: $recent_file"
episode_file_name=$(basename -- "$recent_file")
echo "Basename: $episode_file_name"


EPISODE_TITLE="$current_episode_name"
EPISODE_LINK="$BASE_EPISODE_URL/$episode_file_name"
ENCLOSURE_URL="$EPISODE_LINK"
EPISODE_DESCRIPTION=""
ENCLOSURE_TYPE="audio/mpeg"
ENCLOSURE_LENGTH=$(stat -c%s "$recent_file")
GUID="$ENCLOSURE_URL"
PUB_DATE="$current_episode_pub_date"

NEW_EPISODE_XML="<item>
    <title>$EPISODE_TITLE</title>
    <link>$EPISODE_LINK</link>
    <description>$EPISODE_DESCRIPTION</description>
    <pubDate>$PUB_DATE</pubDate>
    <enclosure url=\"$ENCLOSURE_URL\" length=\"$ENCLOSURE_LENGTH\" type=\"$ENCLOSURE_TYPE\"/>
    <guid>$GUID</guid>
</item>"

awk -v n="$NEW_EPISODE_XML" '{
    print;
    if ($0 ~ "</image>" && !inserted) {
        print n;
        inserted=1;
    }
}' $RSS_FILE > temp_file && mv temp_file $RSS_FILE