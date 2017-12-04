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
if grep $nombre_dispos /etc/fstab > /dev/null; then 
	echo "Ya está en el archivo"
	else 
	echo "No está!"
	linea="$nombre_dispos	$pto_montaje	auto	auto	0	0"
	echo "Añadiendolo..."
	echo "$linea" >> /etc/fstab
fi
#TODO: Hacer el mount en si
echo "Realizando el mount"
mount -a 
printf "\n Fin del script $1\n"
exit 0 