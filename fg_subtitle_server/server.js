const WebSocket = require('ws');

const wss = new WebSocket.Server({ port: 3001 });

console.log("🔥 Subtitle server running on ws://localhost:3001");

wss.on('connection', function connection(ws) {
  console.log("Client connected");

  let index = 0;

  const subtitles = [
    "Ministè Sante Liban anonse plizyè viktim apre atak yo.",
    "Sitiyasyon an rete trè tansyon dapre repòtè a.",
    "FG NEWS LIVE ap teste tradiksyon an dirèk.",
  ];

  setInterval(() => {
    ws.send(JSON.stringify({
      text: subtitles[index]
    }));

    index = (index + 1) % subtitles.length;
  }, 4000);
});