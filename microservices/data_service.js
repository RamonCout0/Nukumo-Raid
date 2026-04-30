const express = require('express');
const app = express();
app.use(express.json());

// Porta 3001 para não conflitar com o Gateway
const PORT = 3001;

let jogadores = [
    { id: 1, nome: "Crodosvaldo", hp: 10, max_hp: 10, fotoUrl: "" },
    { id: 2, nome: "Jogador 2", hp: 20, max_hp: 20, fotoUrl: "" },
    { id: 3, nome: "Jogador 3", hp: 15, max_hp: 15, fotoUrl: "" },
    { id: 4, nome: "Jogador 4", hp: 30, max_hp: 30, fotoUrl: "" }
];

// Rota interna que o Gateway vai chamar
app.get('/interna/jogadores', (req, res) => res.json(jogadores));

app.post('/interna/jogador/:id/alterar', (req, res) => {
    const id = parseInt(req.params.id) - 1;
    if (jogadores[id]) {
        Object.assign(jogadores[id], req.body);
        return res.json(jogadores[id]);
    }
    res.status(404).send("Jogador não encontrado");
});

app.listen(PORT, () => {
    console.log(`[Serviço de Dados] Rodando na porta ${PORT}`);
});