extends Node2D

# Identificação
var token_id: String = ""
var jogador_dono: String = ""
var tipo: String = "player"

@onready var anel: Sprite2D = $Anel
@onready var foto: Sprite2D = $Foto

var arrastando: bool = false
var offset_mouse: Vector2 = Vector2.ZERO
var http_request: HTTPRequest = null

const TAMANHO: float = 64.0

func _ready():
	if token_id == "":
		token_id = str(randi())

	# Escala o anel para TAMANHO px
	if anel and anel.texture:
		var tam = anel.texture.get_size()
		if tam.x > 0:
			anel.scale = Vector2(TAMANHO / tam.x, TAMANHO / tam.y)

	# Aplica o shader circular na foto
	_aplicar_shader_circular()

	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_foto_carregada)

func _aplicar_shader_circular():
	if foto == null:
		return
	var shader = load("res://token_foto.gdshader") as Shader
	if shader == null:
		push_warning("[Token] Shader 'token_foto.gdshader' não encontrado!")
		return
	var mat = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("raio", 0.47)
	mat.set_shader_parameter("suavidade", 0.01)
	mat.set_shader_parameter("centro", Vector2(0.5, 0.5))
	foto.material = mat

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var mouse_pos = get_global_mouse_position()
				var half = TAMANHO / 2.0
				var rect = Rect2(global_position - Vector2(half, half), Vector2(TAMANHO, TAMANHO))
				if rect.has_point(mouse_pos):
					arrastando = true
					offset_mouse = global_position - mouse_pos
					get_viewport().set_input_as_handled()
			else:
				if arrastando:
					arrastando = false
					print("Token %s movido para: %s" % [token_id, str(global_position)])
	elif event is InputEventMouseMotion and arrastando:
		global_position = get_global_mouse_position() + offset_mouse
		get_viewport().set_input_as_handled()

func configurar(id: String, dono: String, tipo_token: String = "player"):
	token_id = id
	jogador_dono = dono
	tipo = tipo_token

func definir_textura(caminho: String):
	var tex = load(caminho) as Texture2D
	if tex:
		_aplicar_foto(tex)

func definir_textura_com_textura(tex: Texture2D):
	if tex:
		_aplicar_foto(tex)

func definir_textura_url(url: String):
	var u = url.strip_edges()
	if u == "" or not (u.begins_with("http://") or u.begins_with("https://")):
		return
	if http_request:
		http_request.request(u)

func _aplicar_foto(tex: Texture2D):
	if foto == null:
		return
	foto.texture = tex
	# Foto ocupa ~90% do token, centralizada
	var foto_tamanho = TAMANHO * 0.8
	var tam = tex.get_size()
	if tam.x > 0 and tam.y > 0:
		foto.scale = Vector2(foto_tamanho / tam.x, foto_tamanho / tam.y)
	foto.position = Vector2.ZERO

func _on_foto_carregada(_result, response_code, _headers, body):
	if response_code != 200 or body.size() == 0:
		return
	var image = Image.new()
	var formato = _detectar_formato(body)
	var error = ERR_CANT_OPEN
	match formato:
		"PNG":  error = image.load_png_from_buffer(body)
		"JPG":  error = image.load_jpg_from_buffer(body)
		"WEBP": error = image.load_webp_from_buffer(body)
		"BMP":  error = image.load_bmp_from_buffer(body)
		_: return
	if error == OK:
		_aplicar_foto(ImageTexture.create_from_image(image))

func _detectar_formato(buffer: PackedByteArray) -> String:
	if buffer.size() < 4:
		return "UNKNOWN"
	if buffer[0] == 0x89 and buffer[1] == 0x50 and buffer[2] == 0x4E and buffer[3] == 0x47:
		return "PNG"
	if buffer[0] == 0xFF and buffer[1] == 0xD8 and buffer[2] == 0xFF:
		return "JPG"
	if buffer.size() >= 12 and buffer[0] == 0x52 and buffer[1] == 0x49 \
		and buffer[2] == 0x46 and buffer[3] == 0x46 \
		and buffer[8] == 0x57 and buffer[9] == 0x45 \
		and buffer[10] == 0x42 and buffer[11] == 0x50:
		return "WEBP"
	if buffer[0] == 0x42 and buffer[1] == 0x4D:
		return "BMP"
	return "UNKNOWN"
