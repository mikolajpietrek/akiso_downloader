clear 
echo -n "podaj numer indeksu: "
read user
echo -n "podaj hasło svn: "
read password
echo

if [ "2" -gt `curl -s -S -u "$user:$password" "http://cs.pwr.edu.pl/zawada/akiso/download/" | wc -l` ]; then
 echo "błąd logowania"
 echo
 exit 1
fi

listawykladow=(`curl -s -S http://cs.pwr.edu.pl/zawada/akiso/ | grep 'download' | grep 'Wykład' | sed -E 's/.*"download\/([0-9]{8})">.*/\1/'`) 
rm -r "wyklady/" 2>/dev/null
mkdir "wyklady"

for wyklad in "${listawykladow[@]}"
do
    listaplikow=(`echo $wyklad | sed -E 's/(.*)/http:\/\/cs.pwr.edu.pl\/zawada\/akiso\/download\/\1\//' | xargs -n 1 curl -s -S -u "$user:$password" | grep "<img" | sed -e 's/" .*//' -e 's/.*"//'`)
    
    ponow=1

    while [ "$ponow" = 1 ]; do

      echo -n "trwa pobieranie wykladu $wyklad  "
      rm -r $wyklad"/" 2>/dev/null 
      mkdir $wyklad
      konwerter=""
      licznik=0;
     
      for plik in "${listaplikow[@]}"
      do
        ((licznik++)) 
        nazwa=$wyklad"/"$licznik".png"
        `echo $plik | sed -E "s/(.*)/http:\/\/cs.pwr.edu.pl\/zawada\/akiso\/download\/$wyklad\/\1/" | xargs -n 1 curl -s -S -u "$user:$password" -o $nazwa`
        konwerter=$konwerter" -adjoin "$nazwa" "
        echo -n "|"
      done

      echo
      if [ "$licznik" = `ls "$wyklad""/" -1 | wc -l` ]; then
        echo "liczba slajdów prawidłowa"
        ponow=0
      else
        echo "Błędna liczba slajdów, ponawiam. Naciśnij CTRL+C, jeśli chcesz przerwać skrypt."
        ponow=1
      fi
      echo 
    
    done
    
    tempwyklad=`echo $wyklad | sed -E 's/^(.{4})(.{2})/\1_\2_/' `
    nazwapdf="$tempwyklad"`cat opisy.txt 2>/dev/null | grep "$tempwyklad" 2>/dev/null | sed -E "s/ (.*)/ \1/" | sed -E "s/[^ ]* (.*)/ \1/" | sed -e "s/\r//"`".pdf"
    convert $konwerter "wyklady/$nazwapdf"
    rm -r $wyklad"/" 2>/dev/null
done

echo
echo "GOTOWE :--)"
echo