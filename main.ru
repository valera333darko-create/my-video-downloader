import os
import uuid
import yt_dlp
from fastapi import FastAPI, BackgroundTasks, HTTPException
from fastapi.responses import FileResponse

app = FastAPI()

# Функция для удаления файла после того, как n8n его скачает
def remove_file(path: str):
    if os.path.exists(path):
        os.remove(path)
        print(f"Файл {path} успешно удален из облака")

@app.get("/")
def read_root():
    return {"status": "API работает. Используйте /download?url=ССЫЛКА"}

@app.get("/download")
def download_video(url: str, background_tasks: BackgroundTasks):
    # Генерируем уникальное имя файла, чтобы видео разных пользователей не пересекались
    file_id = str(uuid.uuid4())
    filename = f"{file_id}.mp4"
    
    # Настройки yt-dlp: качаем лучшее качество в формате mp4
    ydl_opts = {
        'format': 'best[ext=mp4]/best',
        'outtmpl': filename,
        'quiet': True,
        'no_warnings': True
    }
    
    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            ydl.download([url])
        
        if os.path.exists(filename):
            # Добавляем задачу на удаление файла СРАЗУ ПОСЛЕ того, как отправим его в n8n
            background_tasks.add_task(remove_file, filename)
            
            # Отдаем файл прямо в поток n8n
            return FileResponse(path=filename, media_type='video/mp4', filename="video.mp4")
        else:
            raise HTTPException(status_code=500, detail="Ошибка: файл не был сохранен")
            
    except Exception as e:
        # Если что-то пошло не так, подчищаем за собой
        if os.path.exists(filename):
            os.remove(filename)
        raise HTTPException(status_code=500, detail=str(e))
