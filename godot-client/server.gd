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

func _ready():
	api.request_completed.connect(_on_api_response)
	btn_salvar.pressed.connect(_ao_salvar_ficha)
	
	# Conecta o seletor para atualizar a visão (Mestre/Player)
	seletor_ator.item_selected.connect(func(_idx): atualizar_tudo())
	
	atualizar_tudo()

func atualizar_tudo():
	# TRAVA DE SEGURANÇA: Se não tiver nada selecionado, assume Mestre e sai
	if seletor_ator.selected == -1:
		fazer_chamada_api("http://localhost:3000/api/estado?ator=mestre", HTTPClient.METHOD_GET)
		return

	var texto = seletor_ator.get_item_text(seletor_ator.selected).to_lower()
	var ator = "mestre"
	
	if "mestre" in texto:
		ator = "mestre"
	else:
		# Extrai números (ex: "player 1" -> "1")
		var apenas_numeros = ""
		for b in texto.to_ascii_buffer():
			var c = char(b)
			if c in "0123456789":
				apenas_numeros += c
		ator = apenas_numeros if apenas_numeros != "" else "1"

	var url = "http://localhost:3000/api/estado?ator=" + ator
	fazer_chamada_api(url, HTTPClient.METHOD_GET)

func fazer_chamada_api(url: String, metodo = -1, body = ""):
	var headers = ["Content-Type: application/json"]
	var m = metodo
	if m == -1:
		m = HTTPClient.METHOD_POST if ("dano" in url or "reviver" in url or "curar" in url) else HTTPClient.METHOD_GET
	api.request(url, headers, m, body)

func _ao_salvar_ficha():
	var id_para_editar = seletor_jogador.selected + 1
	var url = "http://localhost:3000/api/jogador/%d/editar" % id_para_editar
	
	var dados = {}
	if input_nome.text != "": dados["nome"] = input_nome.text
	if input_hp.text != "": 
		dados["hp"] = int(input_hp.text)
		dados["max_hp"] = int(input_hp.text)
	if input_foto_url.text != "": dados["fotoUrl"] = input_foto_url.text
		
	fazer_chamada_api(url, HTTPClient.METHOD_POST, JSON.stringify(dados))
	
	for i in [input_nome, input_hp, input_foto_url]: i.text = ""

func _on_api_response(_result, response_code, _headers, body):
	if response_code != 200: return
	var json = JSON.parse_string(body.get_string_from_utf8())
	
	if json.has("_links"):
		renderizar_interface(json)
	else:
		# Ações (POST) pedem atualização dos dados
		atualizar_tudo()

func renderizar_interface(json):
	var jogadores = json["data"]["jogadores"]
	
	# Atualiza as 4 fichas rúnicas
	for i in range(4):
		if i < fichas.size():
			fichas[i].atualizar_dados(jogadores[i])
	
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
		
		# Conecta o botão de forma que ele sempre saiba quem é o alvo
		btn.pressed.connect(func():
			var url_final = links[acao]
			var acao_string = acao.to_lower()
			
			# Se a ação for de dano ou reviver, redireciona para o ID selecionado no editor
			if "dano" in acao_string or "reviver" in acao_string:
				var id_alvo = seletor_jogador.selected + 1
				url_final = "http://localhost:3000/api/jogador/%d/%s" % [id_alvo, acao_string.replace("sofrer_", "")]
			
			print("Chamando API: ", url_final) # Debug para você ver no console
			fazer_chamada_api(url_final)
		)
		menu_acoes.add_child(btn)
