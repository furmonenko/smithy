shader_type canvas_item;

// Режими роботи шейдера
uniform int shader_mode = 0; // 0 = кування, 1 = загартовування, 2 = полірування

// ==== ЗАГАЛЬНІ ПАРАМЕТРИ ====
uniform sampler2D displacement_noise; // Шум для деформацій та дефектів

// ==== ПАРАМЕТРИ КУВАННЯ (FORGE) ====
// Основні параметри
uniform float forge_progress : hint_range(0.0, 1.0) = 0.0; // Прогрес кування
uniform vec2 initial_deform = vec2(3.0, 3.0); // Початкова деформація
uniform vec2 forge_center = vec2(0.5, 0.5); // Центр кування (точка удару молотом)
uniform float impact_radius : hint_range(0.1, 1.0) = 0.5; // Радіус впливу удару
uniform float bulge_strength : hint_range(0.0, 1.0) = 0.15; // Сила випучування по краях
uniform float noise_influence : hint_range(0.0, 1.0) = 0.05; // Вплив шуму на деформацію
uniform sampler2D billet_texture : hint_default_white; // Текстура початкової заготовки

// Додаткові ефекти нагріву
uniform float heat_amount : hint_range(0.0, 1.0) = 0.0; // Кількість нагріву (0.0 - холодний, 1.0 - максимально гарячий)
uniform bool heat_at_top = true; // Чи має тепло бути сконцентроване вгорі (true) чи внизу (false)
uniform float heat_spread : hint_range(0.5, 5.0) = 2.0; // Наскільки широко розповсюджується тепло від епіцентру

// Параметри налаштування градієнта тепла
uniform float heat_min_level : hint_range(0.0, 0.5) = 0.2; // Мінімальний рівень тепла для холодних частин
uniform float heat_gradient_power : hint_range(0.1, 3.0) = 0.8; // Контроль крутизни градієнта (менше = плавніше)
uniform float heat_gradient_smooth : hint_range(0.1, 1.0) = 0.7; // Контроль згасання градієнта

// Параметри ефекту світіння
uniform float heat_glow_threshold : hint_range(0.0, 0.9) = 0.3; // Поріг початку світіння
uniform float heat_glow_intensity : hint_range(0.1, 1.0) = 0.6; // Інтенсивність світіння
uniform float heat_color_intensity : hint_range(0.1, 1.0) = 0.85; // Інтенсивність змішування з кольором нагріву

// Параметри імпакту від ударів
uniform float impact_intensity : hint_range(0.0, 1.0) = 0.0; // Інтенсивність поточного імпакту
uniform float impact_band_width : hint_range(0.01, 0.3) = 0.1; // Ширина смуги імпакту
uniform vec4 impact_color : source_color = vec4(1.0, 0.8, 0.2, 1.0); // Колір імпакту
uniform bool flip_done = false; // Чи був виконаний переворот заготовки
uniform float impact_y_position : hint_range(0.0, 1.0) = 0.5; // Позиція імпакту по вертикалі

// ==== ПАРАМЕТРИ ПОЛІРУВАННЯ (POLISH) ====
uniform int total_regions = 5; // Загальна кількість смуг для полірування
uniform int current_region = 0; // Поточна активна смуга (0-based)
uniform float cloth_position = 0.5; // Позиція полірувальної тряпки
uniform int polish_direction = 0; // Напрямок руху тряпки (0 = немає, 1 = ліворуч, 2 = праворуч)
uniform sampler2D region_polish_texture; // Текстура з прогресом полірування для кожної смуги

// Параметри налаштування дефектів
uniform float rust_intensity : hint_range(0.0, 1.0) = 0.7; // Інтенсивність іржі
uniform float scratch_intensity : hint_range(0.0, 1.0) = 0.5; // Інтенсивність подряпин
uniform float tarnish_intensity : hint_range(0.0, 1.0) = 0.6; // Інтенсивність потемніння

// Кольори дефектів
uniform vec4 rust_color : source_color = vec4(0.6, 0.2, 0.0, 1.0); // Колір іржі (коричневий)
uniform vec4 tarnish_color : source_color = vec4(0.3, 0.3, 0.35, 1.0); // Колір потемніння (темно-сірий)
uniform vec4 polish_highlight_color : source_color = vec4(1.0, 0.95, 0.8, 1.0); // Колір блиску при поліруванні

// ==== ФУНКЦІЇ ДЛЯ РЕЖИМУ КУВАННЯ ====

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

// Покращена функція деформації для плавного прогресування форми
vec2 deform_point(in vec2 uv, in float strength) {
    // Відстань від центру кування
    float dist_from_center = distance(uv, forge_center);

    // Коефіцієнт впливу залежно від відстані (плавне згасання)
    float impact_factor = smoothstep(impact_radius, 0.0, dist_from_center);

    // Центруємо координати відносно середини
    vec2 centered_uv = uv - vec2(0.5);

    // Розрахунок деформації з плавним переходом
    // Використовуємо strength з більшою точністю та плавнішим ефектом
    float deform_factor = max(0.0, 1.0 - strength); // Інвертуємо strength для правильного ефекту

    // Базова деформація - стискання/розтягнення залежно від initial_deform
    vec2 base_deform = centered_uv * (vec2(1.0) / mix(vec2(1.0), initial_deform, deform_factor));

    // Застосовуємо шум до форми
    if (noise_influence > 0.0 && deform_factor > 0.0) {
        // Масштабуємо шум для більш плавних переходів
        vec2 scaled_uv = uv * 0.5; // Більший масштаб для плавніших хвиль

        // Зчитуємо шум один раз і використовуємо його як коефіцієнт масштабування
        float noise_val = (texture(displacement_noise, scaled_uv).r * 2.0 - 1.0);

        // Застосовуємо шум як додаткове стискання/розтягування
        float noise_factor = 1.0 + noise_val * noise_influence * deform_factor * 0.5;
        base_deform *= noise_factor;
    }

    // Повертаємо координати назад
    vec2 deformed_uv = base_deform + vec2(0.5);

    // Додаємо випучування для реалістичності
    if (bulge_strength > 0.0 && deform_factor > 0.0) {
        float edge_factor = smoothstep(0.0, impact_radius, dist_from_center) *
                          smoothstep(1.0, impact_radius * 0.9, dist_from_center);
        vec2 dir = normalize(uv - forge_center + vec2(0.0001)); // уникаємо ділення на нуль
        deformed_uv += dir * edge_factor * bulge_strength * deform_factor * 0.3;
    }

    return deformed_uv;
}

// Функція для розрахунку теплового градієнту з налаштованими параметрами
float calculate_heat_gradient(vec2 uv) {
    // Використовуємо Y-координату для створення вертикального градієнту
    float y_pos = heat_at_top ? 1.0 - uv.y : uv.y; // Інвертуємо координату, якщо тепло має бути вгорі

    // Використовуємо налаштований степінь для градієнту
    float gradient = pow(y_pos, heat_gradient_power);

    // Масштабуємо градієнт, щоб він повільніше спадав і охоплював більшу площу
    gradient = smoothstep(0.0, heat_gradient_smooth, gradient);

    // Піднімаємо мінімальний рівень тепла, щоб навіть холодніші частини трохи світились
    return mix(heat_min_level, 1.0, gradient);
}

// Функція для розрахунку горизонтальної смуги імпакту
float calculate_horizontal_band_impact(vec2 uv) {
    // Обчислюємо відстань від позиції імпакту по вертикалі
    float distance_from_impact = abs(uv.y - impact_y_position);

    // Створюємо горизонтальну смугу відповідно до ширини
    float band_effect = smoothstep(impact_band_width, 0.0, distance_from_impact);

    // Додаємо хвилі вздовж смуги для ефекту вібрації
    float wave_effect = sin(uv.x * 30.0 + TIME * 15.0) * 0.5 + 0.5;

    // Комбінуємо ефекти
    float combined_effect = band_effect * (0.7 + wave_effect * 0.3);

    // Масштабуємо згідно з інтенсивністю імпакту
    return combined_effect * impact_intensity;
}

// ==== ФУНКЦІЇ ДЛЯ РЕЖИМУ ПОЛІРУВАННЯ ====

// Функція для визначення, чи належить пікселя до поточної смуги
bool is_in_current_region(float v_coord) {
    float region_height = 1.0 / float(total_regions);
    float region_start = region_height * float(current_region);
    float region_end = region_start + region_height;
    
    return (v_coord >= region_start && v_coord < region_end);
}

// Функція для визначення номера смуги для пікселя
int get_region_index(float v_coord) {
    float region_height = 1.0 / float(total_regions);
    return int(v_coord / region_height);
}

// Функція для отримання прогресу полірування для конкретної смуги
float get_polish_progress_for_region(int region_idx) {
    if (region_idx < 0 || region_idx >= total_regions) {
        return 0.0;
    }
    
    // Використовуємо текстуру 1D для зберігання прогресу (R-канал)
    // Нормалізовані координати для текстури 1D
    float u_coord = (float(region_idx) + 0.5) / float(total_regions);
    return texture(region_polish_texture, vec2(u_coord, 0.5)).r;
}

// Функція для генерації іржавих плям
float generate_rust(vec2 uv, float seed) {
    // Зчитуємо шум для створення органічних плям
    vec2 scaled_uv = uv * vec2(3.0, 1.5) + vec2(seed * 7.89, seed * 2.45);
    float noise_val = texture(displacement_noise, scaled_uv).r;
    
    // Додаємо другий шар шуму для більш цікавих форм
    vec2 scaled_uv2 = uv * vec2(5.0, 2.5) + vec2(seed * 3.21, seed * 1.78);
    float noise_val2 = texture(displacement_noise, scaled_uv2).r;
    
    // Змішуємо два шари шуму
    float combined_noise = mix(noise_val, noise_val2, 0.4);
    
    // Застосовуємо пороговий ефект для створення плям
    float rust_threshold = 0.6 + seed * 0.2; // Поріг з варіацією по seed
    return smoothstep(rust_threshold, rust_threshold + 0.1, combined_noise);
}

// Функція для генерації подряпин
float generate_scratches(vec2 uv, float seed) {
    // Різні шари подряпин
    float scratch1 = texture(displacement_noise, uv * vec2(20.0, 0.5) + vec2(0.0, seed * 8.67)).r;
    float scratch2 = texture(displacement_noise, uv * vec2(15.0, 0.3) + vec2(0.0, seed * 4.32)).r;
    float scratch3 = texture(displacement_noise, uv * vec2(25.0, 0.7) + vec2(0.0, seed * 2.18)).r;
    
    // Комбінуємо різні шари подряпин
    float scratches = max(scratch1, max(scratch2, scratch3));
    
    // Застосовуємо поріг для тонших ліній
    return step(0.75, scratches);
}

// Функція для генерації потемніння металу
float generate_tarnish(vec2 uv, float seed) {
    // Зчитуємо шум для створення патерну потемніння
    vec2 scaled_uv = uv * vec2(2.0, 3.0) + vec2(seed * 3.45, seed * 5.67);
    float noise_val = texture(displacement_noise, scaled_uv).r;
    
    // Робимо плавний перехід для природного вигляду
    return smoothstep(0.4, 0.6, noise_val);
}

// Функція для створення ефекту "блиску" при проходженні тряпки
float generate_polish_highlight(vec2 uv) {
    // Відстань від позиції тряпки по горизонталі
    float distance_from_cloth = abs(uv.x - cloth_position);
    
    // Ширина ефекту блиску
    float highlight_width = 0.05;
    
    // Створюємо ефект блиску лише при активному русі і лише в поточній смузі
    if (polish_direction != 0 && is_in_current_region(uv.y)) {
        // Визначаємо силу блиску з урахуванням відстані від тряпки
        float highlight = smoothstep(highlight_width, 0.0, distance_from_cloth);
        
        // Додаємо "хвилю" блиску для більш динамічного ефекту
        float wave = sin(uv.x * 50.0 + TIME * 15.0) * 0.5 + 0.5;
        
        // Зменшуємо інтенсивність, щоб не засліплювати
        return highlight * wave * 0.4;
    }
    
    return 0.0;
}

void fragment() {
    // Отримуємо базові UV координати
    vec2 uv = UV;
    vec4 final_color;
    
    // Обробка в залежності від режиму шейдера
    if (shader_mode == 0) {
        // ==== РЕЖИМ КУВАННЯ ====
        
        // Застосовуємо деформацію з більш плавним прогресом
        vec2 deformed_uv = deform_point(uv, forge_progress);

        // Перевіряємо границі і обмежуємо deformed_uv, щоб завжди залишатися в межах текстури
        deformed_uv = clamp(deformed_uv, vec2(0.0), vec2(1.0));

        // Отримуємо колір з текстури заготовки та фінального меча
        vec4 billet_color = texture(billet_texture, deformed_uv);
        vec4 final_texture_color = texture(TEXTURE, deformed_uv);

        // Змішуємо текстури заготовки та фінального меча в залежності від прогресу кування
        final_color = mix(billet_color, final_texture_color, forge_progress);

        // Додаємо ефект нагріву з реалістичними температурними кольорами
        if (heat_amount > 0.0) {
            // Обчислюємо тепловий градієнт на основі вертикального положення
            float heat_gradient = calculate_heat_gradient(uv);

            // Додаємо вплив центру кування для реалістичності, але із збільшеним радіусом
            float expanded_radius = impact_radius * heat_spread; // Збільшуємо радіус впливу тепла
            float forge_effect = smoothstep(expanded_radius, 0.0, distance(uv, forge_center)) * 0.4;

            // Посилюємо ефект вертикального градієнту та комбінуємо з центром кування
            float combined_heat = max(heat_gradient, forge_effect);

            // Масштабуємо комбінований тепловий ефект загальним значенням нагріву
            float effective_heat = heat_amount * combined_heat;

            // Отримуємо колір нагріву відповідно до ефективного рівня температури
            vec3 metal_heat_color = get_heat_color(effective_heat);

            // Змішуємо основний колір з кольором нагріву з налаштованою інтенсивністю
            final_color.rgb = mix(final_color.rgb, metal_heat_color, effective_heat * heat_color_intensity);

            // Додаємо світіння (більш виражене при вищих температурах)
            // Використовуємо налаштований поріг для початку світіння та інтенсивність
            if (effective_heat > heat_glow_threshold) {
                float glow_intensity = (effective_heat - heat_glow_threshold) / (1.0 - heat_glow_threshold);
                glow_intensity = min(glow_intensity, 1.0); // Обмежуємо максимальну інтенсивність
                final_color.rgb += metal_heat_color * glow_intensity * heat_glow_intensity;
            }
        }

        // Додаємо ефект імпакту від ударів молотом (горизонтальна смуга)
        if (impact_intensity > 0.0) {
            float impact_effect = calculate_horizontal_band_impact(uv);

            // Додаємо світіння на місці удару
            final_color.rgb = mix(final_color.rgb, impact_color.rgb, impact_effect);

            // Додаємо додаткове світіння для кращої видимості
            final_color.rgb += impact_color.rgb * impact_effect * 0.6;
        }
    }
    else if (shader_mode == 2) {
        // ==== РЕЖИМ ПОЛІРУВАННЯ ====
        
        // Базовий колір з текстури
        final_color = texture(TEXTURE, uv);
        
        // Визначаємо до якої смуги належить поточний піксель
        int region_idx = get_region_index(uv.y);
        
        // Отримуємо прогрес полірування для цієї смуги
        float polish_progress = get_polish_progress_for_region(region_idx);
        
        // Створюємо колір дефектів для поточного пікселя
        vec4 defect_color = final_color;
        
        // Унікальне значення seed для різних типів дефектів
        float rust_seed = uv.x * 12.34 + uv.y * 56.78;
        float scratch_seed = uv.x * 90.12 + uv.y * 34.56;
        float tarnish_seed = uv.x * 78.90 + uv.y * 12.34;
        
        // Створюємо різні типи дефектів і застосовуємо їх з поступовим зникненням залежно від прогресу полірування
        float rust = generate_rust(uv, rust_seed) * rust_intensity * (1.0 - polish_progress);
        float scratches = generate_scratches(uv, scratch_seed) * scratch_intensity * (1.0 - polish_progress);
        float tarnish = generate_tarnish(uv, tarnish_seed) * tarnish_intensity * (1.0 - polish_progress);
        
        // Комбінуємо різні дефекти
        defect_color.rgb = mix(defect_color.rgb, rust_color.rgb, rust);
        defect_color.rgb = mix(defect_color.rgb, vec3(0.5, 0.5, 0.5), scratches * 0.3);
        defect_color.rgb = mix(defect_color.rgb, tarnish_color.rgb, tarnish);
        
        // Додаємо блиск там, де тряпка проходить
        float highlight = generate_polish_highlight(uv);
        
        // Змішуємо з фінальним кольором
        final_color = defect_color;
        
        // Додаємо ефект блиску при поліруванні
        if (highlight > 0.0) {
            final_color.rgb = mix(final_color.rgb, polish_highlight_color.rgb, highlight);
        }
        
        // Додаємо ефект "виділення поточної активної смуги"
        if (is_in_current_region(uv.y)) {
            // Пульсуюча рамка для активної смуги
            float region_height = 1.0 / float(total_regions);
            float region_start = region_height * float(current_region);
            float region_end = region_start + region_height;
            
            // Ефект рамки (верх і низ смуги)
            float border_width = 0.005;
            float top_border = smoothstep(region_start, region_start + border_width, uv.y);
            float bottom_border = smoothstep(region_end - border_width, region_end, uv.y);
            float border = min(top_border, 1.0 - bottom_border);
            
            // Пульсація рамки
            float pulse = sin(TIME * 5.0) * 0.5 + 0.5;
            
            // Додаємо підсвітку рамки для активної смуги
            if (border < 0.9) {
                vec3 highlight_color = vec3(1.0, 0.8, 0.2);
                final_color.rgb = mix(final_color.rgb, highlight_color, (1.0 - border) * 0.5 * pulse);
            }
        }
    }
    else {
        // Режим загартовування або інші режими
        // Можна буде додати логіку для режиму загартовування пізніше
        final_color = texture(TEXTURE, uv);
    }
    
    COLOR = final_color;
}