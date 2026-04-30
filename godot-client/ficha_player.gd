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
	
	# 3. Foto
	if dados_player.has("fotoUrl") and dados_player["fotoUrl"] != "":
		if dados_player["fotoUrl"] != url_foto_atual:
			url_foto_atual = dados_player["fotoUrl"]
			image_loader.request(url_foto_atual)

func _on_image_loaded(_result, response_code, _headers, body):
	if response_code != 200: return
	var image = Image.new()
	var error = image.load_jpg_from_buffer(body)
	if error != OK:
		error = image.load_png_from_buffer(body)
	if error == OK:
		var texture = ImageTexture.create_from_image(image)
		foto.texture = texture
