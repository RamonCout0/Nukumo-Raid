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

func get_foto_texture() -> Texture2D:
	return foto.texture

func _url_valida(url: String) -> bool:
	var u = url.strip_edges()
	return u.begins_with("http://") or u.begins_with("https://")

func atualizar_dados(dados_player: Dictionary):
	# 1. Nome (limitado a 14)
	nome_label.text = str(dados_player["nome"]).left(14)
	barra_hp.max_value = dados_player["max_hp"]
	barra_hp.value = dados_player["hp"]
	
	# Texto do HP
	$TextureProgressBar/ValorHP.text = "%d / %d" % [dados_player["hp"], dados_player["max_hp"]]
	
	# 3. Foto - com validação de URL
	if dados_player.has("fotoUrl"):
		var nova_url = str(dados_player["fotoUrl"]).strip_edges()
		if nova_url == "" or not _url_valida(nova_url):
			# URL vazia ou inválida: limpa a foto sem tentar carregar
			if nova_url != "" and nova_url != url_foto_atual:
				print("[Ficha] URL inválida ignorada: '%s'" % nova_url)
			foto.texture = null
			url_foto_atual = ""
		elif nova_url != url_foto_atual:
			url_foto_atual = nova_url
			print("[Ficha] Carregando foto: ", url_foto_atual)
			image_loader.request(url_foto_atual)

func _on_image_loaded(_result, response_code, _headers, body):
	print("[Ficha] Resposta da imagem - Code: ", response_code)
	
	if response_code != 200:
		print("[Ficha] ❌ Erro ao carregar imagem: HTTP ", response_code)
		return
	
	if body.size() == 0:
		print("[Ficha] ❌ Body vazio")
		return
	
	var image = Image.new()
	var error = OK
	
	var formato_detectado = _detectar_formato_imagem(body)
	
	match formato_detectado:
		"PNG":
			error = image.load_png_from_buffer(body)
		"JPG":
			error = image.load_jpg_from_buffer(body)
		"WEBP":
			error = image.load_webp_from_buffer(body)
		"BMP":
			error = image.load_bmp_from_buffer(body)
		_:
			print("[Ficha] ❌ Formato de imagem não reconhecido")
			return
	
	if error == OK:
		var texture = ImageTexture.create_from_image(image)
		foto.texture = texture
		print("[Ficha] ✅ Foto carregada (", formato_detectado, ")")
	else:
		print("[Ficha] ❌ Erro ao carregar imagem. Error code: ", error)

func _detectar_formato_imagem(buffer: PackedByteArray) -> String:
	if buffer.size() < 4:
		return "UNKNOWN"
	
	if buffer[0] == 0x89 and buffer[1] == 0x50 and buffer[2] == 0x4E and buffer[3] == 0x47:
		return "PNG"
	
	if buffer[0] == 0xFF and buffer[1] == 0xD8 and buffer[2] == 0xFF:
		return "JPG"
	
	if buffer.size() >= 12:
		if buffer[0] == 0x52 and buffer[1] == 0x49 and buffer[2] == 0x46 and buffer[3] == 0x46:
			if buffer[8] == 0x57 and buffer[9] == 0x45 and buffer[10] == 0x42 and buffer[11] == 0x50:
				return "WEBP"
	
	if buffer[0] == 0x42 and buffer[1] == 0x4D:
		return "BMP"
	
	return "UNKNOWN"
