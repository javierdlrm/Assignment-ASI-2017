#!/bin/bash
if [ $# -ne 1 ]
then
	echo "$0: Error de uso. Se necesita fichero_configuracion unicamente"
	exit 1
fi

printf "\n Comenzando la configuración del cluster \n"
nL=0
while IFS='\n' read -r line || [[ -n "$line" ]]; do
	nL=$((nL+1))
    if [ -z ${line:0:1} ]; then
		#echo "-Línea en blanco"
		continue
    elif [ ${line:0:1} = "#" ]; then
		#echo "-Comentario"
		continue
	fi
	IFS=' ' read maquina comando config error <<< "$line"
	if [ ! -z $error ] ; then
		echo "Error linea $nL, Formato incorrecto, demasiados parámetros: $maquina $comando $config $error"
		exit 1
    fi
    if [ -z $config ]; then
		echo "Error linea $nL, Formato incorrecto, faltan parámetros: $maquina $comando $config $error"
		exit 1
    fi

    #La linea de abajo me sobra .. 
    #echo "Linea $nL correcta: $maquina $comando $config $error"
    echo "Realizando conexión con $maquina para enviar los archivos"
    pwd=$(pwd)
    dest="/home/practicas/Escritorio/destino"
    scp -o "StrictHostKeyChecking no" $pwd/$comando.sh root@$maquina:$dest
    scp -o "StrictHostKeyChecking no" $config root@$maquina:$dest
    echo "Realizando conexión con $maquina para realizar el ssh"
    ssh -n -o "StrictHostKeyChecking no" root@$maquina "$dest/$comando.sh $dest/$config; rm $dest/$comando.sh; rm $dest/$config"
	#ssh -n -o "StrictHostKeyChecking no" $maquina rm -rf /home/practicas/Escritorio/funciona
    #Lineas para comprobar que se conecta
    #sudo scp -o "StrictHostKeyChecking no" $comando.sh $maquina:/home/practicas/Escritorio/pruebas
    #sudo scp -o "StrictHostKeyChecking no" $config $maquina:/home/practicas/Escritorio/prueba
    #sudo ssh -o "StrictHostKeyChecking no" $maquina mkdir /home/practicas/Escritorio/prueba/funciona
    #Lineas para comprobar que se conecta$
done < "$1"
printf "\n Fin del programa \n"
exit 0