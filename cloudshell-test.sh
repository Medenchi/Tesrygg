#!/bin/bash
# OpenBoard МОС — проверка дома через Google Cloud Shell + ТВ-приставка (браузер).
# Не нужна ни Linux-машина, ни права администратора. Только Gmail-аккаунт.
set -e

echo "== 1/5 Ставим виртуальный экран и noVNC =="
sudo apt-get update -qq
sudo apt-get install -y -qq --no-install-recommends \
  xvfb x11vnc novnc websockify curl ca-certificates \
  libgl1 libegl1 libfontconfig1 libdbus-1-3 libxkbcommon0 \
  libxcb1 libxcb-glx0 libxcb-icccm4 libxcb-image0 libxcb-keysyms1 \
  libxcb-randr0 libxcb-render-util0 libxcb-shape0 libxcb-xfixes0 \
  libxcb-sync1 libxcb-shm0 libxcb-util1 libxcb-cursor0 libxcb-xkb1 \
  libx11-xcb1 libglib2.0-0 libnss3 libasound2 || true

echo "== 2/5 Скачиваем AppImage (232 МБ, сервер-сервер) =="
mkdir -p ~/ob && cd ~/ob
if [ ! -d squashfs-root ]; then
  curl -sL -X POST -o ob.AppImage https://temp.sh/QYcrw/OpenBoard-MOS-1.8.0-x86_64.AppImage
  echo "   SHA-256 (ожидаем 8dd461df3b1e2f5434cf43e508737503d30df5c22a652cfef15c2e4a5426b809):"
  sha256sum ob.AppImage
  chmod +x ob.AppImage
  ./ob.AppImage --appimage-extract >/dev/null && rm ob.AppImage
fi

echo "== 3/5 Виртуальный экран 1600x900 =="
nohup Xvfb :99 -screen 0 1600x900x24 >/tmp/xvfb.log 2>&1 &
sleep 2

echo "== 4/5 Запускаем OpenBoard МОС =="
DISPLAY=:99 nohup ./squashfs-root/AppRun >/tmp/ob.log 2>&1 &
sleep 6

echo "== 5/5 Раздаём экран по VNC+Web (порт 8080) =="
nohup x11vnc -display :99 -nopw -forever -shared -rfbport 5900 >/tmp/x11vnc.log 2>&1 &
nohup websockify --web=/usr/share/novnc 8080 localhost:5900 >/tmp/websockify.log 2>&1 &

echo
echo "ГОТОВО."
echo "Как открыть:"
echo "  - Cloud Shell: кнопка 'Web Preview' (значок глаза, вверху справа) -> порт 8080"
echo "  - Codespaces: вкладка 'PORTS' внизу -> порт 8080 -> значок глобуса -> откроется браузер"
echo "В адресе может понадобиться дописать /vnc.html?autoconnect=true&resize=scale"
