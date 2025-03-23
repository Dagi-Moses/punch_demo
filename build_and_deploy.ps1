flutter build web --release `
  --dart-define="SERVER_URL=https://punch-server-demo.onrender.com" `
  --dart-define="WEBSOCKET_URL=wss://punch-server-demo.onrender.com?channel="

cd build/web
vercel --prod
