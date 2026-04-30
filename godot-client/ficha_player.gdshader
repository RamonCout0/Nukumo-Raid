shader_type canvas_item;

// Esses 'uniforms' aparecerão no Inspetor para você editar!
uniform float raio : hint_range(0.0, 1.0) = 0.5;
uniform float suavidade : hint_range(0.0, 0.1) = 0.005;
uniform vec2 centro = vec2(0.5, 0.5);

void fragment() {
    float dist = distance(UV, centro);
    vec4 tex = texture(TEXTURE, UV);
    
    // Cria o círculo usando a suavidade para não ficar serrilhado
    float mascara = smoothstep(raio, raio - suavidade, dist);
    
    tex.a *= mascara;
    COLOR = tex;
}