#!/bin/bash

# Directorios base
BASE_DIR="AppStore/Resources/Screenshots/iPhone"
LANGUAGES=("en" "es")

# Tamaños objetivo
SIZE_69="1290x2796"
SIZE_65="1284x2778"

echo "Limpiando directorios anteriores..."
# Limpiar directorios anteriores
for lang in "${LANGUAGES[@]}"; do
    rm -rf "$BASE_DIR/$lang/6.9_inch"
    rm -rf "$BASE_DIR/$lang/6.5_inch"
done

echo "Creando nuevos directorios..."
# Crear directorios para los nuevos tamaños
for lang in "${LANGUAGES[@]}"; do
    mkdir -p "$BASE_DIR/$lang/6.9_inch"
    mkdir -p "$BASE_DIR/$lang/6.5_inch"
    for i in {1..6}; do
        mkdir -p "$BASE_DIR/$lang/6.9_inch/$i"
        mkdir -p "$BASE_DIR/$lang/6.5_inch/$i"
    done
done

# Función para redimensionar una imagen
resize_image() {
    local src="$1"
    local dst="$2"
    local size="$3"
    local width="${size%x*}"
    local height="${size#*x}"
    
    echo "Procesando: $src"
    echo "  → $dst ($width x $height)"
    
    # Copiar y redimensionar
    cp "$src" "$dst"
    sips -z "$height" "$width" "$dst" >/dev/null 2>&1
}

echo "Procesando imágenes..."
# Procesar todas las imágenes
for lang in "${LANGUAGES[@]}"; do
    echo "Idioma: $lang"
    for i in {1..6}; do
        echo "Carpeta: $i"
        # Encontrar todas las imágenes PNG/png en el directorio fuente
        for src in "$BASE_DIR/$lang/$i"/*.{PNG,png}; do
            if [ -f "$src" ]; then
                filename=$(basename "$src")
                echo "Encontrada imagen: $filename"
                
                # 6.9 inch
                dst="$BASE_DIR/$lang/6.9_inch/$i/$filename"
                resize_image "$src" "$dst" "$SIZE_69"
                
                # 6.5 inch
                dst="$BASE_DIR/$lang/6.5_inch/$i/$filename"
                resize_image "$src" "$dst" "$SIZE_65"
            fi
        done
    done
done

echo "Verificando tamaños finales..."
# Verificar los tamaños de las imágenes generadas
for lang in "${LANGUAGES[@]}"; do
    echo "=== Imágenes 6.9\" ($lang) ==="
    find "$BASE_DIR/$lang/6.9_inch" -type f -name "*.PNG" -o -name "*.png" | while read img; do
        sips -g pixelHeight -g pixelWidth "$img"
    done
    
    echo "=== Imágenes 6.5\" ($lang) ==="
    find "$BASE_DIR/$lang/6.5_inch" -type f -name "*.PNG" -o -name "*.png" | while read img; do
        sips -g pixelHeight -g pixelWidth "$img"
    done
done

echo "¡Proceso completado! Las imágenes han sido redimensionadas para todos los tamaños requeridos." 