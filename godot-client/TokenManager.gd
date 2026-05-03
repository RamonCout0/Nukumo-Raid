extends Node2D

const TOKEN_SCENE = preload("res://Token.tscn")

@export var spawnar_ao_iniciar: bool = false  # DESLIGADO: tokens são criados pelo server.gd

# Dicionário: token_id -> token node (para preservar posições)
var tokens: Dictionary = {}

func _ready():
	pass  # Não spawna nada sozinho

# Limpa apenas tokens que não existem mais na nova lista
func atualizar_tokens(jogadores: Array, incluir_mestre: bool = true, fotos: Array = [], mestre: Dictionary = {}):
	# Monta lista de IDs que devem existir
	var ids_esperados: Array = []
	for i in range(jogadores.size()):
		ids_esperados.append("player_%d" % (i + 1))
	if incluir_mestre:
		ids_esperados.append("mestre")

	# Remove tokens que não fazem mais parte da lista
	var ids_atuais = tokens.keys()
	for id in ids_atuais:
		if id not in ids_esperados:
			tokens[id].queue_free()
			tokens.erase(id)

	# Atualiza ou cria tokens dos jogadores
	for i in range(jogadores.size()):
		var tid = "player_%d" % (i + 1)
		var token = _obter_ou_criar(tid)
		token.configurar(tid, "player", "player")

		# Foto: prioridade = textura já carregada na ficha
		if i < fotos.size() and fotos[i] != null:
			token.definir_textura_com_textura(fotos[i])
		elif jogadores[i].has("fotoUrl"):
			var url = str(jogadores[i]["fotoUrl"]).strip_edges()
			if url.begins_with("http://") or url.begins_with("https://"):
				token.definir_textura_url(url)

	# Token do mestre
	if incluir_mestre:
		var mestre_token = _obter_ou_criar("mestre")
		mestre_token.configurar("mestre", "mestre", "mestre")
		if mestre.has("fotoUrl"):
			var url = str(mestre["fotoUrl"]).strip_edges()
			if url.begins_with("http://") or url.begins_with("https://"):
				mestre_token.definir_textura_url(url)
			else:
				mestre_token.definir_textura("res://token_1.png")
		else:
			mestre_token.definir_textura("res://token_1.png")

# Retorna token existente (preservando posição) ou cria novo
func _obter_ou_criar(tid: String) -> Node2D:
	if tokens.has(tid):
		return tokens[tid]
	var token = TOKEN_SCENE.instantiate()
	add_child(token)
	# Posição inicial espalhada para não ficarem sobrepostos
	var idx = tokens.size()
	token.position = Vector2(300 + idx * 80, 300)
	tokens[tid] = token
	return token

# Remove token específico
func remover_token(tid: String):
	if tokens.has(tid):
		tokens[tid].queue_free()
		tokens.erase(tid)

# Adiciona NPC avulso
func adicionar_npc(textura_path: String, tipo_token: String = "npc", dono: String = "mestre") -> Node2D:
	var tid = "npc_%d" % tokens.size()
	var token = _obter_ou_criar(tid)
	token.configurar(tid, dono, tipo_token)
	token.definir_textura(textura_path)
	return token
