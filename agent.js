const WebSocket = require('ws');
const http = require('http');

const VPS_IP = process.env.VPS_IP;
if (!VPS_IP) { console.error("VPS_IP required"); process.exit(1); }

const ws = new WebSocket(`ws://${VPS_IP}:8001`);
ws.on('open', () => console.log('Connected to VPS'));

ws.on('message', (data) => {
    const requestPacket = JSON.parse(data);
    const localReq = http.request({
        hostname: '127.0.0.1',
        port: 11434,
        path: requestPacket.url,
        method: requestPacket.method,
        headers: requestPacket.headers
    }, (localRes) => {
        let resChunks = [];
        localRes.on('data', chunk => resChunks.push(chunk));
        localRes.on('end', () => {
            ws.send(JSON.stringify({
                requestId: requestPacket.requestId,
                statusCode: localRes.statusCode,
                headers: localRes.headers,
                body: Buffer.concat(resChunks).toString('base64')
            }));
        });
    });
    if (requestPacket.body) localReq.write(Buffer.from(requestPacket.body, 'base64'));
    localReq.end();
});
