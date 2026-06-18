from fastapi import FastAPI, Query
from fastapi.responses import FileResponse
import yt_dlp
import os

app = FastAPI()

@app.get("/download")
async def download_video(url: str = Query(...)):
    ydl_opts = {
        'format': 'mp4',
        'outtmpl': 'video.%(ext)s',
        'quiet': True,
    }
    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        info = ydl.extract_info(url, download=True)
        filename = ydl.prepare_filename(info, ext='mp4')
        return FileResponse(filename, media_type='video/mp4', filename='video.mp4')
