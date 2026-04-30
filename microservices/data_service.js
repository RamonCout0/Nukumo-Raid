const express = require('express');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = 3001;
const DATA_FILE = path.join(__dirname, 'sessao.json');

app.use(express.json());

// --- INICIALIZA OS DADOS ---
let sessao = {
    mestre_online: true,
    jogadores: [
        { id: 1, nome: "Jogador 1", hp: 10, max_hp: 10, fotoUrl: "https://api.dicebear.com/7.x/avataaars/png?seed=Jogador1" },
        { id: 2, nome: "Jogador 2", hp: 10, max_hp: 10, fotoUrl: "https://api.dicebear.com/7.x/avataaars/png?seed=Jogador2" },
        { id: 3, nome: "Jogador 3", hp: 10, max_hp: 10, fotoUrl: "https://api.dicebear.com/7.x/avataaars/png?seed=Jogador3" },
        { id: 4, nome: "Jogador 4", hp: 10, max_hp: 10, fotoUrl: "https://api.dicebear.com/7.x/avataaars/png?seed=Jogador4" }
    ]
};

// Carrega dados salvos se existir o arquivo
if (fs.existsSync(DATA_FILE)) {
    try {
        const data = fs.readFileSync(DATA_FILE, 'utf-8');
        sessao = JSON.parse(data);
        console.log('📂 Dados carregados do arquivo sessao.json');
    } catch (err) {
        console.log('⚠️ Erro ao carregar dados, usando padrão:', err.message);
    }
}

// --- SALVA DADOS NO ARQUIVO ---
function salvarDados() {
    try {
        fs.writeFileSync(DATA_FILE, JSON.stringify(sessao, null, 2));
        console.log('💾 Dados salvos em sessao.json');
    } catch (err) {
        console.error('❌ Erro ao salvar dados:', err.message);
    }
}

// --- ROTA INTERNA: BUSCAR ESTADO ---
app.get('/interna/estado', (req, res) => {
    res.json(sessao);
});

// --- ROTA INTERNA: BUSCAR APENAS JOGADORES (compatibilidade) ---
app.get('/interna/jogadores', (req, res) => {
    res.json(sessao.jogadores);
});

// --- ROTA INTERNA: ALTERAR HP/DADOS DE JOGADOR ---
app.post('/interna/jogador/:id/alterar', (req, res) => {
    const id = parseInt(req.params.id);
    
    if (isNaN(id) || id < 1 || id > 4) {
        return res.status(400).json({ error: "ID inválido (1-4)" });
    }
    
    const jogadorIndex = id - 1;
    const jogador = sessao.jogadores[jogadorIndex];
    
    if (!jogador) {
        return res.status(404).json({ error: "Jogador não encontrado" });
    }
    
    // Atualiza os campos enviados
    const { hp, nome, max_hp, fotoUrl } = req.body;
    
    if (hp !== undefined) jogador.hp = hp;
    if (nome !== undefined) jogador.nome = nome;
    if (max_hp !== undefined) jogador.max_hp = max_hp;
    if (fotoUrl !== undefined) jogador.fotoUrl = fotoUrl;
    
    salvarDados();
    
    res.json({ 
        message: "Jogador alterado com sucesso", 
        jogador: jogador 
    });
});

// --- ROTA INTERNA: CURAR TODOS ---
app.post('/interna/mestre/curar_todos', (req, res) => {
    sessao.jogadores.forEach(p => {
        p.hp = p.max_hp;
    });
    
    salvarDados();
    
    res.json({ 
        message: "Todos curados!",
        jogadores: sessao.jogadores
    });
});

// --- ROTA PARA RESET (TESTE) ---
app.post('/interna/reset', (req, res) => {
    sessao = {
        mestre_online: true,
        jogadores: [
            { id: 1, nome: "Jogador 1", hp: 10, max_hp: 10, fotoUrl: "" },
            { id: 2, nome: "Jogador 2", hp: 10, max_hp: 10, fotoUrl: "" },
            { id: 3, nome: "Jogador 3", hp: 10, max_hp: 10, fotoUrl: "" },
            { id: 4, nome: "Jogador 4", hp: 10, max_hp: 10, fotoUrl: "" }
        ]
    };
    
    salvarDados();
    
    res.json({ message: "Sessão resetada!", sessao: sessao });
});

app.listen(PORT, () => {
    console.log(`\n📦 Microserviço de Dados rodando em http://localhost:${PORT}`);
    console.log(`💾 Dados persistidos em: ${DATA_FILE}`);
    console.log(`📊 Estado atual:`, sessao.jogadores.map(j => `${j.nome} (HP: ${j.hp}/${j.max_hp})`).join(', '));
    console.log('');
});
