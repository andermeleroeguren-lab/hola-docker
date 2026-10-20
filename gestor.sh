#!/bin/bash

# Variables principales
PROJECT_NAME="hola-docker"
DOCKER_IMAGE="hola-docker-image"
CONTAINER_NAME="hola-docker-container"
JAR_PATH="target/hola-docker-0.0.1-SNAPSHOT.jar"

# Verifica que Java, Docker y Maven/Maven Wrapper estén disponibles
verificar_prerrequisitos() {
    echo ""
    echo "======================================"
    echo " Verificación de prerrequisitos"
    echo "======================================"

    for comando in java docker
    do
        if command -v "$comando" > /dev/null 2>&1; then
            echo "[OK] $comando está disponible."
        else
            echo "[ERROR] $comando no está disponible."
        fi
    done

    if command -v mvn > /dev/null 2>&1; then
        echo "[OK] Maven está instalado."
    elif [ -f "./mvnw" ]; then
        echo "[OK] Maven Wrapper está disponible."
    else
        echo "[ERROR] Maven no está disponible."
    fi

    echo ""
}

# Compila la aplicación y genera el archivo JAR ejecutable
compilar_aplicacion() {
    echo ""
    echo "======================================"
    echo " Compilando $PROJECT_NAME"
    echo "======================================"

    ./mvnw clean package -DskipTests

    if [ -f "$JAR_PATH" ]; then
        echo ""
        echo "[OK] El archivo JAR se ha generado correctamente:"
        echo "$JAR_PATH"
    else
        echo ""
        echo "[ERROR] No se ha generado el archivo JAR."
    fi

    echo ""
}

# Construye la imagen Docker a partir del Dockerfile
construir_imagen() {
    echo ""
    echo "======================================"
    echo " Construcción de imagen Docker"
    echo "======================================"

    if [ -f "$JAR_PATH" ]; then

        docker build -t "$DOCKER_IMAGE" .

        if docker image inspect "$DOCKER_IMAGE" > /dev/null 2>&1; then
            echo ""
            echo "[OK] Imagen Docker creada correctamente."
        else
            echo ""
            echo "[ERROR] No se pudo crear la imagen Docker."
        fi

    else
        echo "[ERROR] No existe el archivo JAR."
        echo "Primero debes compilar la aplicación."
    fi

    echo ""
}

# Ejecuta el contenedor y gestiona uno existente con el mismo nombre
ejecutar_contenedor() {
    echo ""
    echo "======================================"
    echo " Ejecución del contenedor"
    echo "======================================"

    # Comprobar que la imagen Docker existe
    if ! docker image inspect "$DOCKER_IMAGE" > /dev/null 2>&1; then
        echo "[ERROR] La imagen Docker no existe."
        echo "Primero debes construirla."
        echo ""
        return
    fi

    # Comprobar si ya existe un contenedor con ese nombre
    EXISTING_CONTAINER=$(docker ps -a \
        --filter "name=^/${CONTAINER_NAME}$" \
        --format "{{.Names}}")

    if [ -n "$EXISTING_CONTAINER" ]; then
        echo "Ya existe un contenedor llamado $CONTAINER_NAME."
        read -p "¿Quieres detenerlo y eliminarlo? (s/n): " respuesta

        if [ "$respuesta" = "s" ] || [ "$respuesta" = "S" ]; then
            docker stop "$CONTAINER_NAME" > /dev/null 2>&1
            docker rm "$CONTAINER_NAME" > /dev/null 2>&1
            echo "[OK] Contenedor anterior eliminado."
        else
            echo "Operación cancelada."
            echo ""
            return
        fi
    fi

    docker run -d \
        --name "$CONTAINER_NAME" \
        -p 8080:8080 \
        "$DOCKER_IMAGE"

    if [ $? -eq 0 ]; then
        echo ""
        echo "[OK] Contenedor iniciado correctamente."
        echo "Aplicación disponible en:"
        echo "http://localhost:8080/hello"
    else
        echo ""
        echo "[ERROR] No se pudo iniciar el contenedor."
    fi

    echo ""
}

# Muestra el estado del JAR, la imagen Docker y el contenedor
mostrar_estado() {
    echo ""
    echo "======================================"
    echo " Estado de $PROJECT_NAME"
    echo "======================================"

    echo ""
    echo "--- Archivo JAR ---"

    if [ -f "$JAR_PATH" ]; then
        echo "[OK] El JAR existe:"
        ls -lh "$JAR_PATH"
    else
        echo "[NO] El JAR no existe."
    fi

    echo ""
    echo "--- Imagen Docker ---"

    if docker image inspect "$DOCKER_IMAGE" > /dev/null 2>&1; then
        echo "[OK] La imagen Docker existe."

        docker images "$DOCKER_IMAGE" \
            --format "Nombre: {{.Repository}}
Tag: {{.Tag}}
Tamaño: {{.Size}}
Creada: {{.CreatedSince}}"
    else
        echo "[NO] La imagen Docker no existe."
    fi

    echo ""
    echo "--- Contenedor ---"

    RUNNING_CONTAINER=$(docker ps \
        --filter "name=^/${CONTAINER_NAME}$" \
        --format "{{.Names}}")

    if [ -n "$RUNNING_CONTAINER" ]; then
        echo "[OK] El contenedor está ejecutándose."

        docker ps \
            --filter "name=^/${CONTAINER_NAME}$"
    else
        echo "[NO] El contenedor no está ejecutándose."
    fi

    echo ""
}

# Menú principal: se repite hasta que el usuario elige salir
while true
do
    echo ""
    echo "======================================"
    echo " Gestor de $PROJECT_NAME"
    echo "======================================"
    echo "1. Verificar prerrequisitos"
    echo "2. Compilar y empaquetar aplicación"
    echo "3. Construir imagen Docker"
    echo "4. Ejecutar contenedor Docker"
    echo "5. Mostrar estado actual"
    echo "6. Salir"
    echo "======================================"

    read -p "Selecciona una opción [1-6]: " opcion

    if [ "$opcion" = "1" ]; then
        verificar_prerrequisitos
    elif [ "$opcion" = "2" ]; then
        compilar_aplicacion
    elif [ "$opcion" = "3" ]; then
        construir_imagen
    elif [ "$opcion" = "4" ]; then
        ejecutar_contenedor
    elif [ "$opcion" = "5" ]; then
        mostrar_estado
    elif [ "$opcion" = "6" ]; then
        echo ""
        echo "Saliendo..."
        break
    else
        echo ""
        echo "Opción no válida"
    fi
done