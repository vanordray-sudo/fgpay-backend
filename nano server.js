const WebSocket = require("ws");

const wss = new WebSocket.Server({ port: 7070 });

const subtitles = [
  "Ministè Sante Liban anonse plizyè viktim apre atak yo.",
  "Repòtè a eksplike sitiyasyon an toujou trè tansyon.",
  "FG NEWS LIVE ap teste tradiksyon an dirèk.",
];

let index = 0;

wss.on("connection", (ws) => {
  console.log("Client connecté au serveur subtitle");

  ws.send(JSON.stringify({
    text: "Connexion subtitle FG NEWS OK",
    lang: "ht",
  }));
});

setInterval(() => {
  const message = JSON.stringify({
    text: subtitles[index],
    lang: "ht",
  });

  wss.clients.forEach((client) => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(message);
    }
  });

  index = (index + 1) % subtitles.length;
}, 5000);

console.log("FG Subtitle Server running on ws://localhost:7070");