#!/bin/sh
# Lanceur de M-Alert avec l'Electron du système. Licence : 0BSD.
# MALERT_EXEC sert au lancement au démarrage (~/.config/autostart), qui doit
# appeler ce lanceur plutôt qu'un chemin d'Electron qui change avec les versions.
export MALERT_EXEC=/usr/bin/m-alert
exec /usr/bin/electron44 /usr/lib/m-alert "$@"
