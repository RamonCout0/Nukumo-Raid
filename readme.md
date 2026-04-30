🎲 Nukumo Raid VTT - Sistema de RPG Distribuído
Este projeto é um Gerenciador de Fichas para RPG (Virtual Tabletop) desenvolvido para a disciplina de Sistemas Distribuídos. O sistema utiliza uma arquitetura de microserviços com um API Gateway centralizador, documentação via Swagger e implementação de HATEOAS.

🚀 Tecnologias Utilizadas
Frontend: Godot Engine 4.6 (Exportado para HTML5/Web).

Backend: Node.js com Express.

Comunicação: Axios (Comunicação inter-serviços).

Documentação: Swagger UI / OpenAPI 3.0.

🏗️ Arquitetura do Sistema
O sistema foi dividido em dois serviços principais para simular um ambiente distribuído real:

API Gateway (Porta 3000): O ponto de entrada único. Ele gerencia a segurança, o roteamento e implementa o HATEOAS, gerando links dinâmicos dependendo do ator (Mestre ou Jogador).

Microserviço de Dados (Porta 3001): Responsável pela persistência do estado da sessão e manipulação direta dos dados dos jogadores.

🛠️ Como Rodar o Projeto
Pré-requisitos
Node.js instalado.

Navegador moderno para o Cliente Web.

1. Iniciar o Microserviço de Dados
Bash
cd microservices
node data_service.js
2. Iniciar o API Gateway
Bash
cd api-gateway
npm install
node server.js
3. Acessar o Cliente
Abra o arquivo index.html na pasta do cliente ou rode o projeto diretamente pelo Godot.

🔗 HATEOAS e Dinâmica de Atores
A grande força deste projeto é o uso de Hypermedia as the Engine of Application State.
Ao consultar o estado (/api/estado?ator=X), o Gateway injeta links de ações permitidas:

Se Ator = Mestre: O JSON de resposta inclui o link para curar_todos.

Se Ator = Jogador: O JSON inclui links específicos para sofrer_dano ou reviver apenas para aquele ID.

Isso permite que o cliente Godot construa a interface (botões) dinamicamente com base no que o servidor diz que é possível fazer.

📖 Documentação da API
A documentação completa, com testes integrados, está disponível através do Swagger:
🔗 http://localhost:3000/docs

📝 Regras de Negócio Implementadas
CRUD de Personagens: Edição de nome, HP e foto via Gateway.

Sistema de Combate: Aplicação de dano e cura em tempo real.

Filtro de Visão: O conteúdo da tela muda conforme o papel selecionado no sistema.

Shader de Interface: Processamento visual das fotos via GPU (Godot Shaders).