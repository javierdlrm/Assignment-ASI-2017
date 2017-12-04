#!/bin/bash
#Ayuda de: https://www.youtube.com/watch?v=mIcxxQlPBoc
if [ $# -ne 1 ]
then
	echo "$0: Error de uso. Se necesita fichero_configuracion unicamente"
	exit 1
fi

#sed 'NUMq;d' file
nombre_grupo=`sed "1q;d" $1`
dispositivos=`sed "2q;d" $1`
aux=`awk 'NR>2' $1`

if [ -z $nombre_grupo ] || [ -z $dispositivos ] || [ -z ${dispositivos:0:1} ]; then 
	echo "Error en el archivo $1"
	exit 1
fi

#instalar lvm si necesario
if dpkg -s "lvm2" > /dev/null 2>&1; then
	echo "lvm ya está instalado"
else
	echo "lvm no está instalado" 
	apt-get -qq -y install lvm2 #2>/dev/null
fi

echo "Inicializamos los volumnes fısicos"
sudo pvcreate $dispositivos

echo "Creamos grupo"
sudo vgcreate $nombre_grupo $dispositivos
 
if [ -z $aux ] > /dev/null 2>&1 ; then #Salida nula para mas argumentos de la cuenta. El mandato se encargara de fallar
	echo "Es necesario al menos un volumen logico para crear"
fi
nL=2
while IFS='\n' read -r line || [[ -n "$line" ]]; do
	nL=$((nL+1))
	IFS=' ' read name size <<< $line
	if [ -z $name ] || [ -z $size ] ; then #Es necesario un nombre y un tamaño
		echo "Linea $nL: Se espera un nombre y un tamaño"
		exit 1
	fi
	lvcreate --name $name --size $size $nombre_grupo #${size:-1} en caso de que gb != g 
done <<< "$aux"