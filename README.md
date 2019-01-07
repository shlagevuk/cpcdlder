# Canardpc downloader

cpcdownloader est un petit script permettant de scrapper les numeros de canardpc disponible sur leur site internet pour en extraire des images ou pdf compilant le contenu des articles.

## Comment utiliser

cpcdlder -u user -p password [-t output_type] [-v] [-d] [-s+]

user: compte utilisateur du site cpc
password: mot de passe du compte
output_type: img ou pdf
v: verbose
d: pdebug (on garde les fichiers temporaires + verbose)
s: pause d'1s entre chaques articles telecharge (repetable)

## Options supplémentaires

Voir ./cpcdlder.opt
