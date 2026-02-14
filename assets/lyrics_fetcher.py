#!/usr/bin/env python3
"""Fetch lyrics from NetEase Cloud Music API by track ID."""
import sys
import json
import urllib.request
import urllib.error

def fetch_lyrics(track_id):
    url = f"https://music.163.com/api/song/lyric?id={track_id}&lv=-1"
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=5) as resp:
            data = json.loads(resp.read().decode())
            lrc = data.get("lrc", {}).get("lyric", "")
            if lrc:
                print(lrc, end="")
            else:
                print("")
    except Exception:
        print("")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        fetch_lyrics(sys.argv[1])
    else:
        print("")
