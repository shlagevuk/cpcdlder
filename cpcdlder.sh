#!/bin/bash
nl=$'\n'

echo '                     .:///:-`                                 '
echo '                 .odNdysoosyhdhs-                             '
echo '                oMd/...........:oho`                          '
echo '      `:sdddhyyyMd-...............:yo`                        '
echo '   .odNho/:---:/+oyhy+-............./d-                       '
echo ' .yNy/..............-/sy:............:m-                      '
echo '`mm:...................-oy/.........../m`                     '
echo 'sM-......................-ss-..........N/                     '
echo 'dd.........................oh..........m+                     '
echo 'dh..........................ys.........N+                     '
echo ':m-.........................-N:.......+M/                     '
echo ' .yy+:::://++++++/-..........yd-.....-mm`                     '
echo '   `/sssssoo/+o+/oyho-......./Ms.....-Nmdddh/ymdhy+`          '
echo '                 `:sNN+.......-....-://:-..:oddhysoyy+s+.     '
echo '               :yNho/--......+y--+mNhooosyyNy:.`.-oyosdoyh/`  '
echo '             :dmo-.-://::-.+my:oNy:       `os:-md   :yoh--+h: '
echo '           `yNo../dMMMMMMMmN+.hm-        +yd./o``    `hm+..-m-'
echo '           sN:..hMMMMMMMMMM+.oN.         .hN- :y      /Ms...mo'
echo '          -Mo..sMMMMMMMMMMM-.yy                y:     .Ms../M+'
echo '          /M-..mMMMMMMMMMMN-.+h                h:     +Ms:sNo '
echo '          .M:..NMMMMMMMMMMMd:.d-              .N`   `oNssy+.  '
echo '           ys..yMMMMNMMMMMMMNs:h:            :mNooshNN-       '
echo '           `d/.-NMMMMMMMMMMMMMNhNd+-`    `:odM+`.-.`dy        '
echo '            `d+.-hMMMMMMMMMMMMMMM:-+syyhhys/hh     -Mdhhhys-  '
echo '             `yy-.+dMMMMMMMMMMMMd           N/     sMMMMMMMMm`'
echo '               -ys:./smMMMMMMMMMy          -N`     dMMMMMdsyM.'
echo '                 -shs:.-:+ymMNMMy.`        /m-::+sdmhys++sdm/ '
echo '                    :shdyso/:/+osyyhhhyhdhhdhsoo+/-:oymmh+.   '
echo '                        -:/oymddhyso++//////++oyhdmds/.       '
echo '                               `-:/+osssssssso+/-`            '
echo '##################### ZE CPC SCRAPPER ########################'
echo '  Utilisez la surpuissance du caca pour récupérer sur vos'
echo 'disques la merveillosité canardesque'
echo '##############################################################'
echo ''

# Init des variables par defaut:
user=""
password=""
ouput_type="img"
verbose=0
debug=0
debug_path="./debug/"
output_path="./"
slowdown=0
font_size="28"
img_width="800"
pdf_margin_bottom="0"
pdf_margin_top="0"
pdf_margin_left="0"
pdf_margin_right="0"
pdf_page_width="10cm"

# Load du fichier de variables surchargé
if [ -f ./cpcdlder.opt ]; then
  source ./cpcdlder.opt
fi

while getopts "u:p:t:D:O:vdsh" opt; do
  case "$opt" in
  h)
    show_help
    exit 0
    ;;
  v)
    verbose=1
    ;;
  t)
    ouput_type=$OPTARG
    ;;
  u)
    user=$OPTARG
    ;;
  p)
    password=$OPTARG
    ;;
  d)
    debug=1
    verbose=1
    ;;
  D)
    debug_path=$OPTARG
    ;;
  O)
    output_path=$OPTARG
    ;;
  s)
    slowdown=$((slowdown + 1))
    ;;
  esac
done

function show_help()
{
  echo "
Utilisation:
cpcdlder -u user -p password [-O output_path] [-D debug_path] [-t output_type] [-v] [-d] [-s]+

user: compte utilisateur du site cpc
password: mot de passe du compte
output_type: img ou pdf
O: output_path, chemin ou seront depose les fichiers img ou pdf
D: chemin ou seront pose les fichiers de debug (fichiers intermediaires)
v: verbose
d: pdebug (on garde les fichiers temporaires + verbose)
s: pause d'1s entre chaques articles telecharge (repetable)
"
}
function perror()
{
  LOG_DATE=$(date "+%m/%d/%Y %H:%M:%S")
  MSG=$1
  echo "$LOG_DATE: \e[1mBoldERROR $MSG\e[21m"
}
function pinfo()
{
  LOG_DATE=$(date "+%m/%d/%Y %H:%M:%S")
  MSG=$1
  echo "$LOG_DATE: INFO $MSG"
}

function pdebug()
{
  if [ $verbose == 0 ]; then
    return 0
  fi
  MSG=$1
  LOG_DATE=$(date "+%m/%d/%Y %H:%M:%S")
  echo "$LOG_DATE: DEBUG $MSG"
}

# check user/password correctement renseignés
if [[ -z "${user}" || -z "${password}" ]]; then
  perror "Pas d'utilisateur ou de password renseignés"
  show_help
  exit
fi

# Creation des dossiers de debug et output s'ils n'existent pas.
if [ $debug ] ||  [ ! -d $debug_path ]; then
  mkdir -p $debug_path
fi
if [ ! -d $output_path ]; then
  mkdir -p $output_path
fi

# On récupère un token d'authentification auprès du serveur
# Le token est stocké dans le fichier cookies qui est réutilisé par la suite.
pdebug "1) Recuperation du token"
curl -qs -o /dev/null -XPOST -b cookies -c cookies -d "form_id=user_login_form&name=${user}&pass=${password}&op=Se+connecter" "https://www.canardpc.com/user/login?destination=/"
[[ $? != 0 ]] && perror "curl recuperation token KO"

pdebug "2) Recuperation de la liste des numeros"
# Recuperation de la liste des numero:
curl -qs -o raw_numeros.html -XPOST -b cookies -c cookies "https://www.canardpc.com/numeros"
[[ $? != 0 ]] && perror "curl recuperation numeros KO"

# On parse la pages listant les numero:
#on grep uniquement les lignes avec des liens vers les numeros
#on garde uniquement le chemin relatif du numero (contenu du href)
numeros=$(grep -E '<a href="/numero/[[:alnum:]]+"><span class="archive-nom">'  raw_numeros.html  | sed -r 's/.*href="(.+)"><span.*/\1/' | cut -d'/' -f 3)

#pdebug "liste des numero a parser: $nl$numeros$nl"
for numero in $numeros; do
  pdebug "3) telechargement de la liste des articles du numero $numero"
  # recuperation du sommaire du numero pour avoir la liste des articles
  curl -qs -o raw_$numero.html -b cookies -c cookies "https://www.canardpc.com/numero/$numero"
  [[ $? != 0 ]] && perror "curl recuperation sommaire de $numero KO"


  # On recupere les liens vers les articles
  #même chose que pour les numeros, on grep sur les lignes ayant le numero
  #puis on garde uniquement le chemin relatif
  articles=$(grep -E "href=\"/${numero}/.+\" rel" raw_$numero.html | sed -r 's/.*href="(.+)" rel.*/\1/'|uniq)
  #On ajoute manuellement les "news" (format different)
  # TODO faire ca plus proprement
  articles=$"$articles$nl/news/$numero"

  #pdebug "liste des articles a telecharger: $nl$articles$nl"
  for article in $articles; do
    pdebug "4.1) telechargement de l'article $article"

    # raw_<numero>_<nom_article>.html
    # on remplace les '/' par des '_'
    raw_article_output="raw${article//\//_}.html"
    # numero_nom-article
    # on enleve le premier _
    article_output_name="${article//\//_}"

    pinfo "Telechargement de l'article ${article_output_name} dans ${raw_article_output}"
    curl -L -qs -o ${raw_article_output} -XPOST -b cookies -c cookies "https://www.canardpc.com/${article}"
    [[ $? != 0 ]] && perror "curl recuperation article KO"

    #on reconstruit une page HTML simplifiée dans export.html
    #header
    echo '<!DOCTYPE html>
<html lang="fr" dir="ltr" prefix="content: http://purl.org/rss/1.0/modules/content/  dc: http://purl.org/dc/terms/  foaf: http://xmlns.com/foaf/0.1/  og: http://ogp.me/ns#  rdfs: http://www.w3.org/2000/01/rdf-schema#  schema: http://schema.org/  sioc: http://rdfs.org/sioc/ns#  sioct: http://rdfs.org/sioc/types#  skos: http://www.w3.org/2004/02/skos/core#  xsd: http://www.w3.org/2001/XMLSchema# ">
<head>
  <meta charset="utf-8" />
  ' > export.html


    # on parse la page raw de l'article pour recuperer le chemin des css cpc
    urls=$(grep -o -E 'link .+="(.*css[^ ]*)" ' ${raw_article_output} |grep -Eo 'href="[^\"]+"' | grep -Eo '".*"' | grep -oP '"\K[^"\047]+(?=["\047])' | sed 's@^/@http://www.canardpc.com/@'| cut -d '?' -f 1)

    #pdebug "liste des url CSS a telecharger: $rl$urls$rl"
    for url in $urls;do
      pdebug "4.2) telechargement du fichier css: $url"
      wget --no-clobber -q -x "$url"

      # On ajoute le lien du fichier css dans le fichier export
      echo -n '<link rel="stylesheet" href="' >> export.html ; echo -n "$url" | sed -e 's@http:/@.@;s@https:/@.@' >> export.html; echo '" media="all" />' >> export.html

    done


    # on passe au body html (le corp de la page)
    echo '</head><body>' >> export.html

    # on extrait le contenu de l'article uniquement et on l'ajoute dans export
    xmllint --html --xpath '//*[@id="zenContent"]' --htmlout ${raw_article_output} >> export.html 2>/dev/null

    # add footer
    echo '</body></html>' >> export.html


    # Constitution de la liste des images a telecharger
    imgs=$(grep -o -E 'href="/sites/default/.*\.(png|jpeg|jpg)"' ${raw_article_output} |grep -oP '"\K[^"\047]+(?=["\047])')

    # Telechargement des images
    for img in $imgs;do
      pdebug "4.3) telechargement de l'image: $img"
      wget --no-clobber -q -x "http://www.canardpc.com$img"
    done

    # On passe les tag "liens" avec une image en fond en image directement
    # Les images sont configuré pour que leur largeur corresponde a celle de la page
    # Etant dans une div le padding du css est ajoute
    sed -i -r "/slideshow/ s/<a/<div style=\"width: ${img_width}\"> <img/; s/href/src/; s/title=\".*\".+style=\"background-image: url(.*);\">/style=\"max-width: 100%;vertical-align: middle;\" >/; s/<\/a>/<\/div>/" export.html

    # On remplace les liens relatifs vers CPC pour le chemin des images en local
    # ex: /mon/images.jpg -> ./www.canardpc.com/mon/images.jpg
    sed -i -r '/slideshow/ s/([^m])\/sites\//\1.\/www.canardpc.com\/sites\//g' export.html

    # Dans certains cas on a des url très longues, on ajoute le style pour les obliger a faire un retour a la ligne
    sed -i -r 's/<a src=/<a style="word-wrap: break-word;" src=/' export.html

    # Generation des exports img ou pdf
    if [[ "$ouput_type" == "img" ]]; then
      pinfo "export en format image de l'article"
      wkhtmltoimage --width ${img_width} \
                    --minimum-font-size ${font_size} \
                    export.html ${output_path}${article//\//_}.jpg
    fi
    if [[ "$ouput_type" == "pdf" ]]; then
      pinfo "export en format pdf de l'article"
      wkhtmltopdf --minimum-font-size ${font_size} \
                  --margin-bottom ${pdf_margin_bottom} \
                  --margin-top ${pdf_margin_top} \
                  --margin-left ${pdf_margin_left}  \
                  --margin-right ${pdf_margin_right} \
                  --page-width ${pdf_page_width} \
                  export.html ${output_path}${article//\//_}.pdf
    fi
    if [ $debug ]; then
      pdebug "4.4) export html sauvegarde dans debug_${article//\//_}.html"
      mv export.html ${debug_path}debug${article//\//_}.html
    else
      rm export.html
      rm ${raw_article_output}
    fi
    if [ "$slowdown" != "0" ]; then
      pdebug "5) pause de ${slowdown}s avant le telechargement suivant"
      sleep "${slowdown}"
    fi
  done

  if [ ! $debug ]; then
    rm raw_$numero.html
  else
    mv raw_$numero.html ${debug_path}raw_$numero.html
  fi
done

if [ ! $debug ]; then
  rm raw_numeros.html
else
  mv raw_numeros.html ${debug_path}raw_numeros.html
fi
exit 0
