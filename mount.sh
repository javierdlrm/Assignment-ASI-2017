#!/bin/bash

if [ $# -ne 1 ]
then
	echo "$0: Error de uso. Se necesita fichero_configuracion unicamente"
	exit 1
fi

printf "\n Comenzando el mount \n"
#sed 'NUMq;d' file
nombre_dispos=`sed "1q;d" $1`
pto_montaje=`sed "2q;d" $1`
echo "$nombre_dispos en $pto_montaje"
if [ -z $nombre_dispos ] || [ -z $pto_montaje ]; then 
	echo "Error en el archivo $1"
	exit 1
fi
#TODO: Comprobar si está montado
#TODO: Añadir en el fstab si no está	
#TODO: Hacer el mount en si
printf "\n Fin del programa \n"
exit 0 