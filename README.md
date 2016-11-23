# bysykkel-ml

Eksperimenter med maskinlæring på et datagrunnlag fra Oslo bysykkel.

* **map.R** lager et kart over de mest brukte sykkelstativene i Oslo. Fjern kommentartegnet foran nest siste linje for å også plotte de mest populære rutene.
* **pred1.R** bruker [xgboost](https://github.com/dmlc/xgboost) for å forsøke å predikere om et gitt stativ er fullt basert på tid, ukedag, stativets plassering og totalt antall sykkellåser i stativet.
* **analyze.py** regner ut noe statistikk basert på reisedataen.

Anbefaler å bruke RStudio for å kjøre skriptene. Husk å installere de nødvendige pakkene med `install.packages` før bruk.