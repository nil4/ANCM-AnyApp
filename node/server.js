const
    process = require('process'),
    http = require('http'),
    pairingToken = process.env.ASPNETCORE_TOKEN;

const app = function(request, response) {
    if (pairingToken !== request.headers['ms-aspnetcore-token']) {
        response.writeHead(500, {'Content-Type': 'text/plain'});
        response.end('Invalid request: ANCM token mismatch');
        return;
    }

    response.writeHead(200, {'Content-Type': 'text/plain'});

    const iisUser = request.headers['ms-aspnetcore-user'];
    if (iisUser) response.write('Hello from NodeJS, ' + iisUser + '!\r\n\r\n');

    response.end(JSON.stringify(request.headers, null, '  '));
}

http.createServer(app).listen(process.env.ASPNETCORE_PORT);