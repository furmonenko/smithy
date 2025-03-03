shader_type canvas_item;

// Основні параметри шейдера
uniform float forge_progress : hint_range(0.0, 1.0) = 0.0; // Прогрес кування (0 - початок/деформований, 1 - кінець/готовий меч)
uniform vec2 initial_deform = vec2(3.0, 3.0); // Початкова деформація
uniform vec2 forge_center = vec2(0.5, 0.5); // Центр кування (точка удару молотом)
uniform float impact_radius : hint_range(0.1, 1.0) = 0.5; // Радіус впливу удару
uniform float bulge_strength : hint_range(0.0, 1.0) = 0.15; // Сила випучування по краях
uniform sampler2D displacement_noise; // Шум для нерівномірної деформації
uniform float noise_influence : hint_range(0.0, 1.0) = 0.05; // Вплив шуму на деформацію
uniform sampler2D billet_texture; // Текстура початкової заготовки

// Додаткові ефекти нагріву
uniform float heat_amount : hint_range(0.0, 1.0) = 0.0; // Кількість нагріву (0.0 - холодний, 1.0 - максимально гарячий)

// Функція для отримання кольору нагріву на основі температури
vec3 get_heat_color(float heat_level) {
    // Визначаємо кольори для різних температур металу
    vec3 cold_color = vec3(0.5, 0.5, 0.5);      // Сірий (холодний)
    vec3 dull_red = vec3(0.5, 0.09, 0.09);      // Тьмяний червоний
    vec3 red_color = vec3(0.9, 0.1, 0.1);       // Червоний
    vec3 orange_color = vec3(0.9, 0.4, 0.0);    // Помаранчевий
    vec3 yellow_color = vec3(1.0, 0.8, 0.2);    // Жовтий (найгарячіший)
    vec3 white_hot = vec3(1.0, 0.95, 0.8);      // Біло-жовтий (надзвичайно гарячий)
    
    // Визначаємо порогові значення для переходу між кольорами
    if (heat_level < 0.1) {
        return cold_color; // Сірий, коли метал холодний
    } else if (heat_level < 0.3) {
        // Перехід від сірого до тьмяно-червоного
        float t = (heat_level - 0.1) / 0.2;
        return mix(cold_color, dull_red, t);
    } else if (heat_level < 0.5) {
        // Перехід від тьмяно-червоного до яскраво-червоного
        float t = (heat_level - 0.3) / 0.2;
        return mix(dull_red, red_color, t);
    } else if (heat_level < 0.7) {
        // Перехід від червоного до помаранчевого
        float t = (heat_level - 0.5) / 0.2;
        return mix(red_color, orange_color, t);
    } else if (heat_level < 0.9) {
        // Перехід від помаранчевого до жовтого
        float t = (heat_level - 0.7) / 0.2;
        return mix(orange_color, yellow_color, t);
    } else {
        // Перехід від жовтого до біло-жовтого (граничне значення)
        float t = (heat_level - 0.9) / 0.1;
        return mix(yellow_color, white_hot, t);
    }
}

// Спрощена версія функції деформації для запобігання появи дірок
vec2 deform_point(in vec2 uv, in float strength) {
    // Відстань від центру кування
    float dist_from_center = distance(uv, forge_center);
    
    // Коефіцієнт впливу залежно від відстані (плавне згасання)
    float impact_factor = smoothstep(impact_radius, 0.0, dist_from_center);
    
    // Центруємо координати відносно середини
    vec2 centered_uv = uv - vec2(0.5);
    
    // Базова деформація - стискання/розтягнення залежно від initial_deform
    vec2 base_deform = centered_uv * (vec2(1.0) / mix(vec2(1.0), initial_deform, 1.0 - strength));
    
    // Застосовуємо шум до форми, а не до окремих пікселів
    if (noise_influence > 0.0 && strength < 1.0) {
        // Масштабуємо шум для більш плавних переходів
        vec2 scaled_uv = uv * 0.5; // Більший масштаб для плавніших хвиль
        
        // Зчитуємо шум один раз і використовуємо його як коефіцієнт масштабування
        float noise_val = (texture(displacement_noise, scaled_uv).r * 2.0 - 1.0);
        
        // Застосовуємо шум як додаткове стискання/розтягування
        float noise_factor = 1.0 + noise_val * noise_influence * (1.0 - strength) * 0.5;
        base_deform *= noise_factor;
    }
    
    // Повертаємо координати назад
    vec2 deformed_uv = base_deform + vec2(0.5);
    
    // Додаємо випучування для реалістичності
    if (bulge_strength > 0.0 && strength < 1.0) {
        float edge_factor = smoothstep(0.0, impact_radius, dist_from_center) * 
                          smoothstep(1.0, impact_radius * 0.9, dist_from_center);
        vec2 dir = normalize(uv - forge_center + vec2(0.0001)); // уникаємо ділення на нуль
        deformed_uv += dir * edge_factor * bulge_strength * (1.0 - strength) * 0.3;
    }
    
    return deformed_uv;
}

void fragment() {
    // Отримуємо базові UV координати
    vec2 uv = UV;
    
    // Застосовуємо деформацію
    vec2 deformed_uv = deform_point(uv, forge_progress);
    
    // Перевіряємо границі і обмежуємо deformed_uv, щоб завжди залишатися в межах текстури
    deformed_uv = clamp(deformed_uv, vec2(0.0), vec2(1.0));
    
    // Отримуємо колір з текстури заготовки та фінального меча
    vec4 billet_color = texture(billet_texture, deformed_uv);
    vec4 final_color = texture(TEXTURE, deformed_uv);
    
    // Змішуємо текстури заготовки та фінального меча в залежності від прогресу кування
    COLOR = mix(billet_color, final_color, forge_progress);
    
    // Додаємо ефект нагріву з реалістичними температурними кольорами
    if (heat_amount > 0.0) {
        // Обчислюємо інтенсивність світіння залежно від відстані до центру кування
        float heat_intensity = smoothstep(impact_radius, 0.0, distance(uv, forge_center)) * heat_amount;
        
        // Отримуємо колір нагріву відповідно до рівня температури
        vec3 metal_heat_color = get_heat_color(heat_amount);
        
        // Змішуємо основний колір з кольором нагріву
        COLOR.rgb = mix(COLOR.rgb, metal_heat_color, heat_intensity * 0.7);
        
        // Додаємо світіння (більш виражене при вищих температурах)
        if (heat_amount > 0.5) {
            float glow_intensity = (heat_amount - 0.5) * 2.0; // Нормалізуємо до 0-1
            COLOR.rgb += metal_heat_color * heat_intensity * glow_intensity * 0.4;
        }
    }
}