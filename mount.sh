#!/bin/bash

if [ $# -ne 1 ]
then
  echo "$0: Error de uso. Se necesita fichero_configuracion unicamente"
  exit 1
fi

printf "\nComenzando el mount \n"
#sed 'NUMq;d' file
nombre_dispos=`sed "1q;d" $1`
pto_montaje=`sed "2q;d" $1`

if [ -z $nombre_dispos ] || [ -z $pto_montaje ]; then 
  echo "Error en el archivo $1"
  exit 1
fi

if [ ! -d $pto_montaje ]; then
  echo "La carpeta no existe. Se procedera a crear"
  mkdir -p $pto_montaje
fi  

echo "$nombre_dispos en $pto_montaje"
#TODO: Comprobar si está montado
#TODO: Añadir en el fstab si no está  
if ! grep $nombre_dispos /etc/fstab > /dev/null; then 
  linea="$nombre_dispos  $pto_montaje  auto  auto  0  0"
  echo "Añadiendo $nombre_dispos a /etc/fstab"
  sudo echo "$linea" >> /etc/fstab
fi
#TODO: Hacer el mount en si
echo "Realizando el mount"
sudo mount -a || { echo "Error al ejecutar mount."; exit 1; }
printf "\n Fin del script $1\n"
exit 0