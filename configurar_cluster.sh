#!/bin/bash

if [ $# -ne 1 ]
then
	echo "$0: Error de uso. Se necesita fichero_configuracion unicamente"
	exit 1
fi

nL=0
while IFS='\n' read -r line || [[ -n "$line" ]]; do
	nL=$((nL+1))
    if [ -z ${line:0:1} ]; then
		echo "-Línea en blanco"
		continue
    elif [ ${line:0:1} = "#" ]; then
		echo "-Comentario"
		continue
	fi
	IFS=' ' read maquina comando config error <<< "$line"
	if [ ! -z $error ] || [ -z $config ]; then
		echo "Error linea $nL: Formato maquina-destino nombre-del-servicio fichero-de-perfil-de-servicio"
		continue #Aqui o mejor terminar o continuar ?
    fi

    #Lineas para comprobar que se conecta
    #sudo scp -o "StrictHostKeyChecking no" $comando.sh $maquina:/home/practicas/Escritorio/prueba
    #sudo scp -o "StrictHostKeyChecking no" $config $maquina:/home/practicas/Escritorio/prueba
    #sudo ssh -o "StrictHostKeyChecking no" $maquina mkdir /home/practicas/Escritorio/prueba/funciona
    #Lineas para comprobar que se conecta
done < "$1"

