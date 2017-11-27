while IFS='' read -r line || [[ -n "$line" ]]; do
    if [ -z ${line:0:1} ] 
    then
	echo "-Línea en blanco"
    elif [ ${line:0:1} = "#" ]
    then
	echo "-Comentario"
    else
	echo "Línea: $line"
    fi
done < "$1"