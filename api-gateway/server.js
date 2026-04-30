const express = require('express');
const cors = require('cors');
const axios = require('axios');
const swaggerUi = require('swagger-ui-express');

const app = express();
const PORT = 3000;
const SERVICO_INTERNO = "http://localhost:3001/interna";

app.use(cors());
app.use(express.json());

function getBaseUrl(req) {
    return `${req.protocol}://${req.get('host')}`;
}

// --- GATEWAY: ROTA COM HATEOAS ---
app.get('/api/estado', async (req, res) => {
    try {
        const response = await axios.get(`${SERVICO_INTERNO}/estado`);
        const sessao = response.data;
        const ator = req.query.ator || 'observador';
        const baseUrl = getBaseUrl(req);

        let links = {
            self: `${baseUrl}/api/estado?ator=${ator}`
        };

        if (ator === 'mestre') {
            links.curar_todos = `${baseUrl}/api/mestre/curar_todos`;
        } else if (['1', '2', '3', '4'].includes(ator)) {
            const idNum = parseInt(ator);
            const p = sessao.jogadores[idNum - 1];

            if (p) {
                if (p.hp > 0) {
                    links.sofrer_dano = `${baseUrl}/api/jogador/${ator}/dano`;
                } else {
                    links.reviver = `${baseUrl}/api/jogador/${ator}/reviver`;
                }
            }
        }

        res.json({ data: sessao, _links: links });

    } catch (error) {
        console.error("Erro em /api/estado:", error.message);
        res.status(500).json({
            error: "O microserviço interno (3001) está fora do ar!",
            details: error.message
        });
    }
});

// --- DANO ---
app.post('/api/jogador/:id/dano', async (req, res) => {
    try {
        const id = req.params.id;
        const idNum = parseInt(id);

        if (!id || isNaN(idNum) || idNum < 1 || idNum > 4) {
            return res.status(400).json({
                error: "ID do jogador inválido (1-4)"
            });
        }

        const estado = await axios.get(`${SERVICO_INTERNO}/estado`);
        const p = estado.data.jogadores[idNum - 1];

        if (!p) {
            return res.status(404).json({
                error: "Jogador não encontrado"
            });
        }

        const hpAnterior = p.hp;
        const novoHp = Math.max(0, p.hp - 2);
        const danoCausado = hpAnterior - novoHp;

        await axios.post(
            `${SERVICO_INTERNO}/jogador/${id}/alterar`,
            { hp: novoHp }
        );

        res.json({
            success: true,
            message: `Dano aplicado com sucesso em ${p.nome}!`,
            jogador: p.nome,
            dano_causado: danoCausado,
            hp_anterior: hpAnterior,
            hp_novo: novoHp,
            hp_maximo: p.max_hp,
            status: novoHp <= 0 ? "MORTO" : "VIVO"
        });

    } catch (error) {
        res.status(500).json({
            error: "Falha ao aplicar dano",
            details: error.message
        });
    }
});

// --- CURAR TODOS ---
app.post('/api/mestre/curar_todos', async (req, res) => {
    try {
        const response = await axios.post(`${SERVICO_INTERNO}/mestre/curar_todos`);
        const jogadores = response.data.jogadores;

        res.json({
            success: true,
            message: "✨ Todos os jogadores foram curados!",
            jogadores_curados: jogadores.length,
            detalhes: jogadores.map(j => ({
                nome: j.nome,
                hp_restaurado: `${j.hp}/${j.max_hp}`
            }))
        });

    } catch (error) {
        res.status(500).json({
            error: "Falha ao curar todos",
            details: error.message
        });
    }
});

// --- EDITAR ---
app.post('/api/jogador/:id/editar', async (req, res) => {
    try {
        const id = req.params.id;
        const idNum = parseInt(id);

        if (!id || isNaN(idNum) || idNum < 1 || idNum > 4) {
            return res.status(400).json({
                error: "ID do jogador inválido (1-4)"
            });
        }

        const { nome, hp, max_hp, fotoUrl } = req.body;

        const response = await axios.post(
            `${SERVICO_INTERNO}/jogador/${id}/alterar`,
            { nome, hp, max_hp, fotoUrl }
        );

        res.json({
            success: true,
            message: "✏️ Ficha atualizada com sucesso!",
            jogador_atualizado: response.data,
            campos_alterados: Object.keys(req.body)
        });

    } catch (error) {
        res.status(500).json({
            error: "Falha ao atualizar ficha",
            details: error.message
        });
    }
});

// --- REVIVER ---
app.post('/api/jogador/:id/reviver', async (req, res) => {
    try {
        const id = req.params.id;
        const idNum = parseInt(id);

        if (!id || isNaN(idNum) || idNum < 1 || idNum > 4) {
            return res.status(400).json({
                error: "ID do jogador inválido (1-4)"
            });
        }

        const estado = await axios.get(`${SERVICO_INTERNO}/estado`);
        const p = estado.data.jogadores[idNum - 1];

        if (!p) {
            return res.status(404).json({
                error: "Jogador não encontrado"
            });
        }

        await axios.post(
            `${SERVICO_INTERNO}/jogador/${id}/alterar`,
            { hp: p.max_hp }
        );

        res.json({
            success: true,
            message: `⚡ ${p.nome} foi revivido com sucesso!`,
            jogador: p.nome,
            hp_restaurado: `${p.max_hp}/${p.max_hp}`,
            status: "VIVO"
        });

    } catch (error) {
        res.status(500).json({
            error: "Falha ao reviver",
            details: error.message
        });
    }
});

// ---------------- SWAGGER DINÂMICO ----------------
app.get('/openapi.json', (req, res) => {

    

    const baseUrl = getBaseUrl(req);

    res.setHeader("Cache-Control", "no-store");

    res.json({
        openapi: "3.0.0",

        info: {
            title: "Nukumo Raid API",
            version: Date.now().toString()
        },

        servers: [
            { url: baseUrl }
        ],

        paths: {

            "/api/estado": {
                get: {
                    summary: "Estado"
                }
            },

            "/api/jogador/{id}/editar": {
                post: {
                    summary: "Editar Jogador",

                    parameters: [
                        {
                            name: "id",
                            in: "path",
                            required: true,
                            description: "ID entre 1 e 4",
                            schema: {
                                type: "string",
                                enum: ["1","2","3","4"],
                                default: "1"
                            }
                        }
                    ],

                    requestBody: {
                        required: false,
                        content: {
                            "application/json": {
                                schema: {
                                    type: "object",
                                    properties: {
                                        nome: { type: "string" },
                                        hp: { type: "integer" },
                                        max_hp: { type: "integer" },
                                        fotoUrl: { type: "string" }
                                    }
                                },
                                example: {
                                    nome: "Herói",
                                    hp: 10
                                }
                            }
                        }
                    },

                    responses: {
                        "200": {
                            description: "OK"
                        }
                    }
                }
            },

            "/api/jogador/{id}/dano": {
                post: {
                    summary: "Dano",
                    parameters: [
                        {
                            name: "id",
                            in: "path",
                            required: true,
                            schema: {
                                type: "string",
                                enum: ["1","2","3","4"],
                                default: "1"
                            }
                        }
                    ]
                }
            },

            "/api/jogador/{id}/reviver": {
                post: {
                    summary: "Reviver",
                    parameters: [
                        {
                            name: "id",
                            in: "path",
                            required: true,
                            schema: {
                                type: "string",
                                enum: ["1","2","3","4"],
                                default: "1"
                            }
                        }
                    ]
                }
            },

            "/api/mestre/curar_todos": {
                post: {
                    summary: "Curar Todos"
                }
            }
        }
    });
});

app.use('/docs', swaggerUi.serve, swaggerUi.setup(null, {
    explorer: true,
    swaggerOptions: {
        url: "/openapi.json?v=" + Date.now()
    }
}));

app.get('/', (req, res) => {
    res.redirect('/docs');
});

app.listen(PORT, () => {
    console.log(`🚀 API Gateway rodando em http://localhost:${PORT}`);
    console.log(`📖 Swagger: http://localhost:${PORT}/docs`);
});