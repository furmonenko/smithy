shader_type canvas_item;

// Основні параметри
uniform float target_size : hint_range(0.0, 1.0) = 0.28; // Розмір ідеальної цільової зони
uniform float good_zone_outer : hint_range(0.0, 1.0) = 0.34; // Зовнішній край "доброї" зони
uniform float satisfactory_zone_outer : hint_range(0.0, 1.0) = 0.4; // Зовнішній край "задовільної" зони
uniform float current_size : hint_range(0.0, 1.0) = 0.5; // Поточний розмір рухомого кола
uniform float ring_thickness : hint_range(0.01, 0.2) = 0.01; // Товщина кільця

// Кольори
uniform vec4 perfect_color : source_color = vec4(0.0, 1.0, 0.0, 1.0);       // Зелений для ідеальної зони
uniform vec4 good_color : source_color = vec4(0.5, 1.0, 0.0, 1.0);          // Салатовий для хорошої зони
uniform vec4 satisfactory_color : source_color = vec4(1.0, 1.0, 0.0, 1.0);  // Жовтий для задовільної зони
uniform vec4 moving_color : source_color = vec4(0.8, 0.8, 0.8, 1.0);        // Сірий для рухомого кола

// Режими відображення
uniform bool show_result_only = false;  // Режим відображення тільки результату
uniform int result_quality = 0;         // Якість удару (0 = промах, 1 = задовільно, 2 = добре, 3 = ідеально)
uniform float flash_intensity = 1.0;    // Інтенсивність блимання результату

void fragment() {
    // Координати відносно центру (перетворюємо 0-1 на -1 до 1)
    vec2 uv = UV * 2.0 - 1.0;
    float dist = length(uv); // Відстань від центру

    // Початковий колір - прозорий
    vec4 final_color = vec4(0.0, 0.0, 0.0, 0.0);

    // Якщо активний режим відображення результату
    if (show_result_only) {
        // Визначаємо колір результату
        vec4 result_color;

        switch (result_quality) {
            case 3: // Ідеально
                result_color = perfect_color;
                break;
            case 2: // Добре
                result_color = good_color;
                break;
            case 1: // Задовільно
                result_color = satisfactory_color;
                break;
            default: // Промах
                result_color = vec4(1.0, 0.0, 0.0, 1.0); // Червоний
                break;
        }

        // Повне коло для результату
        float full_circle_radius = target_size * 1.5; // Більший радіус для кращої видимості
        float result_ring = smoothstep(full_circle_radius - ring_thickness - 0.01,
                                      full_circle_radius - ring_thickness, dist) *
                           (1.0 - smoothstep(full_circle_radius,
                                             full_circle_radius + 0.01, dist));

        if (result_ring > 0.0) {
            result_color.a = result_color.a * result_ring * flash_intensity;
            final_color = mix(final_color, result_color, result_color.a);
        }
    }
    // Звичайний режим гри
    else {
        // Визначаємо межі ідеальної зони (зелене коло)
        float perfect_inner = target_size - ring_thickness/2.0;
        float perfect_outer = target_size + ring_thickness/2.0;

        // Визначаємо межі "хорошої" зони (салатове коло)
        float good_inner = perfect_outer;
        float good_outer = good_zone_outer;

        // Визначаємо межі "задовільної" зони (жовте коло)
        float satisfactory_inner = good_outer;
        float satisfactory_outer = satisfactory_zone_outer;

        // Малюємо ідеальну (зелену) зону
        float perfect_ring = smoothstep(perfect_inner - 0.01, perfect_inner, dist) *
                            (1.0 - smoothstep(perfect_outer, perfect_outer + 0.01, dist));

        if (perfect_ring > 0.0) {
            vec4 color = perfect_color;
            color.a = color.a * perfect_ring;
            final_color = mix(final_color, color, color.a);
        }

        // Малюємо хорошу (салатову) зону
        float good_ring = smoothstep(good_inner - 0.01, good_inner, dist) *
                         (1.0 - smoothstep(good_outer, good_outer + 0.01, dist));

        if (good_ring > 0.0) {
            vec4 color = good_color;
            color.a = color.a * good_ring;
            final_color = mix(final_color, color, color.a);
        }

        // Малюємо задовільну (жовту) зону
        float satisfactory_ring = smoothstep(satisfactory_inner - 0.01, satisfactory_inner, dist) *
                                 (1.0 - smoothstep(satisfactory_outer, satisfactory_outer + 0.01, dist));

        if (satisfactory_ring > 0.0) {
            vec4 color = satisfactory_color;
            color.a = color.a * satisfactory_ring;
            final_color = mix(final_color, color, color.a);
        }

        // Малюємо рухоме сіре коло
        float moving_inner = current_size - ring_thickness/2.0;
        float moving_outer = current_size + ring_thickness/2.0;

        float moving_ring = smoothstep(moving_inner - 0.01, moving_inner, dist) *
                           (1.0 - smoothstep(moving_outer, moving_outer + 0.01, dist));

        if (moving_ring > 0.0) {
            vec4 color = moving_color;
            color.a = color.a * moving_ring;
            final_color = mix(final_color, color, color.a);
        }
    }

    COLOR = final_color;
}