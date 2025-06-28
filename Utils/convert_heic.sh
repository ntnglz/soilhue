#!/bin/bash

# Verificar si se proporcionó un directorio
if [ -z "$1" ]; then
    echo "Uso: $0 <directorio> [formato]"
    echo "formato: png (por defecto) o jpeg"
    exit 1
fi

# Directorio a procesar
DIR="$1"

# Formato de salida (png por defecto)
FORMAT="${2:-png}"
if [ "$FORMAT" != "png" ] && [ "$FORMAT" != "jpeg" ]; then
    echo "Error: El formato debe ser 'png' o 'jpeg'"
    exit 1
fi

# Verificar si el directorio existe
if [ ! -d "$DIR" ]; then
    echo "Error: El directorio $DIR no existe"
    exit 1
fi

# Contador de archivos procesados
COUNT=0

# Procesar todos los archivos HEIC en el directorio
find "$DIR" -type f -iname "*.HEIC" | while read file; do
    echo "Procesando: $file"
    
    # Crear el nombre del archivo de salida
    output="${file%.*}.$FORMAT"
    
    # Convertir la imagen
    sips -s format "$FORMAT" "$file" --out "$output" >/dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo "  → Convertido a: $output"
        COUNT=$((COUNT + 1))
    else
        echo "  → Error al convertir $file"
    fi
done

echo "¡Proceso completado! Se convirtieron $COUNT archivos." 