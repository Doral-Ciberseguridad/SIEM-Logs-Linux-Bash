#!/bin/bash




# Imprimo el titulo de mi programa.
echo ""
echo "########## ANALIZADOR DE LOGS (BASH LINUX) ##########"




# Muestro al usuario las opciones disponibles que tiene este programa.
echo ""
echo "Opciones:"
echo "1.Ver eventos en tiempo real."
echo "2.Elegir que eventos críticos se van a alertar."
echo "3.Configurar el envio por correo electrónico de los eventos críticos."

# Le pido al usuario que elija una de las opciones y guardo su elección en una variable.
echo ""
read -p "Elige una opción (1-3) --> " opcion_usuario
echo ""




case $opcion_usuario in

    1)
        echo "1 /var/log/auth.log --> Registra inicios de sesión (exitosos y no exitosos), comandos sudo, uso de PAM y creación de usuarios."
        echo "2 /var/log/syslog --> Diagnostica errores, monitorea el estado de daemons y procesos y eventos del sistema." 
        echo "3 /var/log/kern.log --> Registra los eventos generados por el propio núcleo de Linux, muestra avisos o errores relacionados con el hardware y monitoriza eventos del firewall."
        echo ""
        read -p "Elige que log quieres ver en tiempo real (1-3) --> " elegir_log
        echo ""
        echo "Recuerda presionar Ctrl+C para salir"
        echo ""

        case $elegir_log in 
            1)
            tail -f /var/log/auth.log
            ;;
            2)
            tail -f /var/log/syslog
            ;;
            3)
            tail -f /var/log/kern.log
        esac
        ;;



    2)
        echo "# auth.log"
        echo "# 1. Accesos SSH"
        echo "# 2. Accesos SSH fallidos"
        echo "# 3. Uso de privilegios elevados sudo"
        echo "# 4. Cambios de contraseña"
        echo "# 5. Apertura y cierre de sesiones"
        echo "# 6. Intentos de fuerza bruta"
        echo ""
        echo "# kern.log"
        echo "# 7. Agotar memoria RAM del sistema Out of memory"
        echo "# 8. Kernel panic"
        echo "# 9. Fallo de hardware o controlador"
        echo "# 10. Error de lectura/escritura en disco o partición"
        echo ""
        echo "# syslog"
        echo "# 11. Apagado del sistema"
        echo "# 12. Ejecución de tareas programadas"
        echo "# 13. Inicio de sesión de usuario:"
        echo "# 14. Uso de privilegios administrativos"

        read -p "Elige que eventos quieres monitorizar y enviar a /var/log/eventos_monitored.log (Ej: 1,5,9,12) --> " seleccion

        # Procesamos la selección del usuario para mapearla a los patrones correctos
        IFS=',' read -ra ADDR <<< "$seleccion"
        for i in "${ADDR[@]}"; do
            i=$(echo "$i" | xargs) # Limpiar espacios
            patron=""
            log_target=""
            
            case "$i" in
                1) patron="Accepted password"; log_target="/var/log/auth.log" ;;
                2|6) patron="Failed password"; log_target="/var/log/auth.log" ;;
                3) patron="sudo"; log_target="/var/log/auth.log" ;;
                4) patron="password changed"; log_target="/var/log/auth.log" ;;
                5|13) patron="session opened"; log_target="/var/log/auth.log" ;; 
                7) patron="Out of memory: Kill process"; log_target="/var/log/kern.log" ;;
                8) patron="Kernel panic"; log_target="/var/log/kern.log" ;;
                9) patron="hardware error"; log_target="/var/log/kern.log" ;;
                10) patron="I/O error"; log_target="/var/log/kern.log" ;;
                11) patron="The system will power off now!"; log_target="/var/log/syslog" ;;
                12) patron="CRON"; log_target="/var/log/syslog" ;;
                14) patron="sudo"; log_target="/var/log/syslog" ;;
            esac

            if [ -n "$patron" ]; then
                # Añadir al crontab el comando dinámico con el patrón seleccionado incluyendo --line-buffered
                echo "@reboot nohup tail -F $log_target | grep --line-buffered -i \"$patron\" >> /var/log/eventos_monitored.log 2>&1 &" >> /etc/crontab
            fi
        done

        cat /etc/crontab

    ;;



    3)
        echo ""
        echo "Instalando dependencias necesarias (mailutils)..."
        echo ""
        sudo apt -qq update 2>/dev/null
        sudo apt -qq install -y mailutils 2>/dev/null

        read -p "Introduce la dirección de correo electrónico de destino: " correo_destino
        
        # Validación básica para asegurarse de que introduce algo
        if [ -z "$correo_destino" ]; then
            echo "Error: El correo no puede estar vacío."
            exit 1
        fi

        # Definimos la ruta del script actual o un comando directo para el cron diario
        # Por ejemplo, programar un cron a las 08:00 AM todos los días para enviar el log
        cron_diario="0 8 * * * mail -s 'Reporte Diario - SIEM Events' $ecos $correo_destino -A /var/log/eventos_monitored.log 2>/dev/null"
        
        # O una forma más limpia usando echo directo al cuerpo con mail:
        cron_diario_body="0 8 * * * root mail -s 'Alerta SIEM: Resumen Diario de Eventos' $correo_destino < /var/log/eventos_monitored.log"

        # Añadir la tarea al crontab del sistema de forma limpia (evitando duplicados exactos)
        if ! grep -q "eventos_monitored.log" /etc/crontab; then
            echo "$cron_diario_body" >> /etc/crontab
            echo ""
            echo "¡Configuración completada! Se ha añadido una tarea a /etc/crontab para enviar el reporte todos los días a las 08:00 AM."
        else
            echo ""
            echo "Ya existía una tarea programada para el archivo de eventos en el crontab."
        fi

        echo ""
        echo "Contenido actual de /etc/crontab:"
        cat /etc/crontab
    ;;



esac




echo ""
