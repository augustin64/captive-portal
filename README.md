# Simple Access Point

Ce projet a pour objectif de fournir un point d'accès wifi simple menant à un site Internet hébergé en local,  
l'objectif n'étant pas d'utiliser ce portail pour se connecter à Internet mais simplement pour consulter le site en question.

# Dépendances

- NetworkManager
- nmcli
- dnsmasq
- iptables
- nginx (optionnel)

# Utilisation

Pour démarrer le serveur web et configurer toutes les règles automatiquement:  
```bash
./captive-hotspot.sh
```