const { spawn } = require('child_process');
const path = require('path');

function abrir(nome, arquivo, pasta) {

    const processo = spawn(
        'node',
        [arquivo],
        {
            cwd: path.join(__dirname, pasta),
            shell: true,
            stdio: 'inherit'
        }
    );

    processo.on('close', code => {
        console.log(`${nome} finalizado (${code})`);
    });
}

// microservice
abrir(
    "MICROSERVICE",
    "data_service.js",
    "microservices"
);

// gateway
abrir(
    "GATEWAY",
    "server.js",
    "api-gateway"
);