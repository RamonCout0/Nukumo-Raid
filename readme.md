# 🎲 Nukumo Raid VTT
> **Sistema de RPG Distribuído** — Gerenciador de fichas e estados em tempo real utilizando arquitetura de microserviços e princípios RESTful avançados.

Este projeto foi desenvolvido para a disciplina de **Sistemas Distribuídos**. O objetivo é demonstrar a orquestração de serviços, desacoplamento de persistência e a implementação de hipermídia como motor de estado da aplicação (HATEOAS).

---

## 🏗️ Arquitetura do Sistema

O sistema utiliza uma abordagem de **Microserviços** para separar as responsabilidades de roteamento, lógica de negócio e persistência de dados.

* **API Gateway (Porta 3000):** Atua como o ponto de entrada único (*Single Entry Point*). Gere a segurança, o roteamento de pedidos e a implementação de **HATEOAS**, injetando links dinâmicos nas respostas com base no papel (ator) do utilizador.

* **Microserviço de Dados (Porta 3001):** Responsável pela persistência do estado da sessão e manipulação direta dos dados dos jogadores, garantindo que o Gateway permaneça *stateless*.

* **Frontend (Godot 4.x):** Cliente rico que consome a API de forma reativa, construindo a interface dinamicamente a partir dos links fornecidos pelo servidor.

---

## 🚀 Tecnologias Utilizadas

| Camada | Tecnologia |
| :--- | :--- |
| **Frontend** | Godot Engine 4 (Exportação HTML5/Web) |
| **Backend** | Node.js com Express |
| **Comunicação** | Axios (Inter-serviços) |
| **Documentação** | Swagger UI / OpenAPI 3.0 |
| **Processamento Visual** | Godot Shaders (GLSL) |

---

## 🔗 HATEOAS e Dinâmica de Atores

A grande força deste projeto é o uso de **Hypermedia as the Engine of Application State**. O cliente não possui lógica fixa sobre o que o utilizador pode fazer; ele descobre as ações através da API.

Ao consultar o endpoint `/api/estado?ator={tipo}`, o Gateway injeta links de ações permitidas:

* **Se Ator = Mestre:** A resposta inclui hiperlinks para `curar_todos`, `resetar_hp` ou `adicionar_xp`.
* **Se Ator = Jogador:** A resposta inclui links específicos apenas para o seu ID, como `sofrer_dano` ou `usar_item`.

> **Vantagem:** O cliente Godot constrói os botões da interface dinamicamente. Se uma nova regra de negócio for adicionada ao servidor, o cliente exibe a nova opção automaticamente sem necessidade de recompilar o código do jogo.

> **O que foi implementado:** por enquanto só existe a opção de `curar_todos` e `sofrer_dano`, outros atributos serão disponíveis nas autalizações seguintes.
---

## 🛠️ Como Executar o Projeto

### Pré-requisitos
* [Node.js](https://nodejs.org/) instalado.
* Navegador moderno para correr o Cliente Web.

### Instalação e Execução

1.  **Clonar o Repositório:**
    ```bash
    git clone https://github.com/RamonCout0/Nukumo-Raid.git
    cd nukumo-raid-vtt
    ```

2.  **Iniciar o Microserviço de Dados:**
    ```bash
    cd microservices
    # npm install (se necessário)
    node data_service.js
    ```

3.  **Iniciar o API Gateway:**
    ```bash
    cd ../api-gateway
    npm install
    node server.js
    obs:caso queira iniciar o gateway e microserviços, execute apenas iniciar.js para ambos iniciar o processo.
    ```

4.  **Acessar o Cliente:**
    Abra o ficheiro `index.html` na pasta do cliente ou corra o projeto diretamente através do editor **Godot 4**.




---

## 📖 Documentação da API

A documentação completa e interativa, que permite testar os endpoints e visualizar a estrutura dos microserviços, está disponível via Swagger:

🔗 **URL:** [http://localhost:3000/docs](http://localhost:3000/docs)

---

## 📝 Regras de Negócio Implementadas

* **CRUD de Personagens:** Edição de atributos (Nome, HP, Foto) centralizada no Gateway.
* **Sistema de Combate:** Lógica de dano e cura processada no lado do servidor para evitar batotas (*cheating*).
* **Controlo de Acesso (ACL):** O conteúdo visível e as interações mudam conforme o papel selecionado no sistema.

---