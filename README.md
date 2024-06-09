## Spotify orginal Podcast to own RSS feed

You like a Spotify orginal Podcast but you want to listen to it in your own podcast app? This script will help you to create a RSS feed for the Spotify orginal Podcast.

#### Important
This script is only for personal use. Do not share the RSS feed with others, respect Copyrights. The Spotify orginal Podcasts are only available on Spotify. This script is only a workaround to listen to the Podcast in your own podcast app.

This is against the Spotify Terms of Service, but not Illegal. Use at your own risk. No need for a Spotify premium account, so create a free burner account for this.

Also please don't open any issues or pull requests. I will not maintain this script. It's just a workaround for me and I want to share it with you.

### How to use

**Requirements**
- Linux or MacOS on a server
- sqlite3
- [zotify](https://zotify.xyz/)
- nginx or an other webserver
- The podcast musst be available on [Podtail](https://podtail.com/)
*Poditail is only used to get the URL from Spotify for an episode*

**Setup**
1. Clone the repository
2. Take the name of the podcast in the format of the Podtail URL set the name in the `podcast_name` variable.
3. Set the `BASE_EPISODE_URL` variable to the URL where the Audio files will be avilable at. For example: `https://example.com/podcast/`
4. Change everything in `rss.xml` to your needs.

**My nginx config**
```nginx
server {
    server_name YOUR_DOMAIN;

    location / {
        auth_basic "Restricted Content";
        auth_basic_user_file /etc/nginx/.htpasswd; # make the files not public to avoid legal issues
        root PATH_TO_REPO;
        try_files /rss.xml =404;
    }

    location /audio {
        alias PATH_TO_REPO/audio;
        autoindex on;  # Optional: Enables directory listing
    }
}
```

I recogment to use Certbot to get a free SSL certificate.

### Usage

run `./add_episodes.sh` to add new episodes to the RSS feed.

Unfortunately, you have to run this script manually every time a new episode is released. The tool to download the episodes does not return an error code when the Download fails - what happens sometimes. So you have to check the output of the script.

A sqlite database is used to store the names of downloaded episodes to not download them again. If you want to download an episode again, you have to delete the entry in the database.