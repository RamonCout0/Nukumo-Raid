extends Control

# --- REFERÊNCIAS ---
@onready var api = $API
@onready var menu_acoes = $MenuAcoes
@onready var seletor_jogador = $SeletorJogador
@onready var seletor_ator = $SeletorAtor

@onready var fichas = [$Ficha1, $Ficha2, $Ficha3, $Ficha4]

@onready var input_nome = $InputNome
@onready var input_hp = $InputHP
@onready var input_foto_url = $InputFotoUrl
@onready var btn_salvar = $BtnSalvar
@onready var token_manager = $TokenManager

# --- FILA DE REQUESTS ---
# Evita o problema de "clicar duas vezes": guarda o próximo request
# enquanto o atual ainda está em andamento.
var _aguardando_resposta: bool = false
var _request_pendente: Dictionary = {}  # {url, metodo, body}

func _ready():
	api.request_completed.connect(_on_api_response)
	btn_salvar.pressed.connect(_ao_salvar_ficha)
	seletor_ator.item_selected.connect(func(_idx): atualizar_tudo())

	# Garante que o SeletorJogador tenha a opção "Mestre"
	_garantir_opcao_mestre_no_seletor()

	atualizar_tudo()

func _garantir_opcao_mestre_no_seletor():
	# Verifica se já tem "Mestre" no seletor de edição
	var tem_mestre = false
	for i in range(seletor_jogador.item_count):
		if "mestre" in seletor_jogador.get_item_text(i).to_lower():
			tem_mestre = true
			break
	if not tem_mestre:
		seletor_jogador.add_item("Mestre", 99)

func atualizar_tudo():
	if seletor_ator.selected == -1:
		_fazer_request("http://localhost:3000/api/estado?ator=mestre", HTTPClient.METHOD_GET)
		return

	var texto = seletor_ator.get_item_text(seletor_ator.selected).to_lower()
	var ator = "mestre"

	if "mestre" not in texto:
		var apenas_numeros = ""
		for b in texto.to_ascii_buffer():
			var c = char(b)
			if c in "0123456789":
				apenas_numeros += c
		ator = apenas_numeros if apenas_numeros != "" else "1"

	_fazer_request("http://localhost:3000/api/estado?ator=" + ator, HTTPClient.METHOD_GET)

# --- SISTEMA DE FILA ---
func _fazer_request(url: String, metodo: int, body: String = ""):
	if _aguardando_resposta:
		# Guarda para executar assim que o atual terminar
		_request_pendente = {"url": url, "metodo": metodo, "body": body}
		return
	_executar_request(url, metodo, body)

func _executar_request(url: String, metodo: int, body: String = ""):
	_aguardando_resposta = true
	_request_pendente = {}
	var headers = ["Content-Type: application/json"]
	api.request(url, headers, metodo, body)

func _on_api_response(_result, response_code, _headers, body):
	_aguardando_resposta = false

	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json != null:
			if json.has("_links"):
				renderizar_interface(json)
			else:
				# Foi um POST (salvar/ação) — agora busca o estado atualizado
				atualizar_tudo()

	# Executa request pendente se houver
	if not _request_pendente.is_empty():
		_executar_request(
			_request_pendente["url"],
			_request_pendente["metodo"],
			_request_pendente.get("body", "")
		)

func _ao_salvar_ficha():
	var id_selecionado = seletor_jogador.selected
	var texto_selecionado = seletor_jogador.get_item_text(id_selecionado).to_lower()

	var dados = {}
	if input_nome.text != "": dados["nome"] = input_nome.text
	if input_hp.text != "":
		dados["hp"] = int(input_hp.text)
		dados["max_hp"] = int(input_hp.text)
	if input_foto_url.text != "": dados["fotoUrl"] = input_foto_url.text

	if dados.is_empty():
		return

	var url: String
	if "mestre" in texto_selecionado:
		url = "http://localhost:3000/api/mestre/editar"
	else:
		var id_para_editar = id_selecionado + 1
		url = "http://localhost:3000/api/jogador/%d/editar" % id_para_editar

	_fazer_request(url, HTTPClient.METHOD_POST, JSON.stringify(dados))

	for i in [input_nome, input_hp, input_foto_url]: i.text = ""

func renderizar_interface(json):
	var jogadores = json["data"]["jogadores"]

	var fotos = []
	for i in range(4):
		if i < fichas.size():
			fichas[i].atualizar_dados(jogadores[i])
			fotos.append(fichas[i].get_foto_texture())

	# Passa também os dados do mestre se existirem
	var mestre = json["data"].get("mestre", {})
	token_manager.atualizar_tokens(jogadores, true, fotos, mestre)

	# Limpa botões antigos
	for n in menu_acoes.get_children():
		n.queue_free()

	var links = json["_links"]
	var dist_y = 0

	for acao in links.keys():
		if acao == "self": continue

		var btn = Button.new()
		btn.text = acao.to_upper().replace("_", " ")
		btn.size = Vector2(150, 40)
		btn.position = Vector2(0, dist_y)
		dist_y += 50

		btn.pressed.connect(func():
			var url_final = links[acao]
			var acao_string = acao.to_lower()
			if "dano" in acao_string or "reviver" in acao_string:
				var id_alvo = seletor_jogador.selected + 1
				url_final = "http://localhost:3000/api/jogador/%d/%s" % [id_alvo, acao_string.replace("sofrer_", "")]
			_fazer_request(url_final, HTTPClient.METHOD_POST)
		)
		menu_acoes.add_child(btn)
