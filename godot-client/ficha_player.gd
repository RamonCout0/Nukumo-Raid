extends Control

# Referências exatas da sua árvore
@onready var foto = $FotoDoJogador
@onready var nome_label = $NomeLabel
@onready var barra_hp = $TextureProgressBar
@onready var image_loader = $ImageLoader

var url_foto_atual = ""

func _ready():
	# Conecta o sinal do loader
	image_loader.request_completed.connect(_on_image_loaded)

func atualizar_dados(dados_player: Dictionary):
	# 1. Nome (limitado a 14)
	nome_label.text = str(dados_player["nome"]).left(14)
	barra_hp.max_value = dados_player["max_hp"]
	barra_hp.value = dados_player["hp"]
	
	# Nova linha para mostrar o texto do HP
	$TextureProgressBar/ValorHP.text = "%d / %d" % [dados_player["hp"], dados_player["max_hp"]]
	barra_hp.value = dados_player["hp"]
	
	# 3. Foto - com validação melhorada
	if dados_player.has("fotoUrl") and dados_player["fotoUrl"] != "":
		var nova_url = dados_player["fotoUrl"].strip_edges()
		if nova_url != "" and nova_url != url_foto_atual:
			url_foto_atual = nova_url
			print("[Ficha] Carregando foto: ", url_foto_atual)
			image_loader.request(url_foto_atual)
	elif dados_player.has("fotoUrl") and dados_player["fotoUrl"] == "":
		# Se a URL for vazia, limpa a foto
		foto.texture = null

func _on_image_loaded(result, response_code, headers, body):
	print("[Ficha] Resposta da imagem - Code: ", response_code, " Result: ", result)
	
	if response_code != 200:
		print("[Ficha] ❌ Erro ao carregar imagem: HTTP ", response_code)
		return
	
	if body.size() == 0:
		print("[Ficha] ❌ Body vazio")
		return
	
	var image = Image.new()
	var error = OK
	
	# Tenta detectar o formato automaticamente
	# Ordem: PNG, JPG, WebP, BMP
	error = image.load_png_from_buffer(body)
	if error != OK:
		error = image.load_jpg_from_buffer(body)
	if error != OK:
		error = image.load_webp_from_buffer(body)
	if error != OK:
		error = image.load_bmp_from_buffer(body)
	
	if error == OK:
		var texture = ImageTexture.create_from_image(image)
		foto.texture = texture
		print("[Ficha] ✅ Foto carregada com sucesso!")
	else:
		print("[Ficha] ❌ Formato de imagem não suportado ou corrompido. Error code: ", error)
