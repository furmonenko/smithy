// temperature_indicator_shader.gdshader
shader_type canvas_item;

// Колір виділення - яскравіший жовтий з більшою непрозорістю
uniform vec4 highlight_color : source_color = vec4(1.0, 0.9, 0.1, 0.9);
uniform float highlight_position : hint_range(0.0, 1.0) = 1.0; // 0.0 = верх, 1.0 = низ
uniform float highlight_size : hint_range(0.0, 1.0) = 1; // Збільшений розмір
uniform bool highlight_active = true; // Чи показувати виділення
uniform bool flip_done = false; // Чи було виконано переворот

void fragment() {
    // Отримуємо базовий колір з об'єкта
    vec4 base_color = COLOR;

    // Використовуємо Y-координату (UV.y) напряму
    float v_pos = UV.y;

    // Обчислюємо відстань від поточної точки до центру виділення
    float distance_to_highlight = abs(v_pos - highlight_position);

    // Чіткіше виділення з меншим градієнтом
    if (highlight_active && distance_to_highlight < highlight_size / 2.0) {
        // Більш різкий градієнт
        float gradient = pow(1.0 - (distance_to_highlight / (highlight_size / 2.0)), 2.0);

        // Яскравіше змішування кольорів
        COLOR = mix(base_color, highlight_color, gradient);
    } else {
        COLOR = base_color;
    }
}