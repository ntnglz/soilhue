#!/bin/bash

# Directorios base
BASE_DIR="AppStore/Resources/Screenshots/iPhone"
LANGUAGES=("en" "es")

# Función para editar una imagen
edit_image() {
    local img="$1"
    echo "Editando: $img"
    
    # Obtener dimensiones de la imagen
    width=$(sips -g pixelWidth "$img" | grep pixelWidth | awk '{print $2}')
    height=$(sips -g pixelHeight "$img" | grep pixelHeight | awk '{print $2}')
    
    # Calcular posiciones para los rectángulos blancos
    # Las coordenadas están aproximadamente a 1/3 de la altura de la imagen
    lat_y=$((height * 33 / 100))  # Posición Y para latitud
    lon_y=$((height * 33 / 100))  # Posición Y para longitud
    rect_height=$((height / 25))   # Altura del rectángulo
    
    # Crear una imagen temporal con los rectángulos blancos
    convert "$img" \
        -fill white -draw "rectangle $((width/2-150)),$lat_y,$((width/2-20)),$((lat_y+rect_height))" \
        -fill white -draw "rectangle $((width/2+20)),$lon_y,$((width/2+150)),$((lon_y+rect_height))" \
        "$img"
}

# Procesar todas las versiones de 02_analysis_result
for lang in "${LANGUAGES[@]}"; do
    # Imagen original
    img="$BASE_DIR/$lang/2/02_analysis_result.png"
    if [ -f "$img" ]; then
        edit_image "$img"
    fi
    
    # Imagen 6.9"
    img="$BASE_DIR/$lang/6.9_inch/2/02_analysis_result.png"
    if [ -f "$img" ]; then
        edit_image "$img"
    fi
    
    # Imagen 6.5"
    img="$BASE_DIR/$lang/6.5_inch/2/02_analysis_result.png"
    if [ -f "$img" ]; then
        edit_image "$img"
    fi
done

echo "¡Proceso completado! Las coordenadas han sido ocultadas en todas las imágenes." 