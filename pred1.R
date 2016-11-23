# xgboost m?? installeres fra GitHub, da det er en bug i versjonen i CRAN som gj??r
# at skriptet ikke fungerer.

Sys.setlocale("LC_ALL", locale="no_NO")

library(lubridate)
library(caret)
library(xgboost)
library(data.table)
library(Matrix)

# Vi tar en kopi av dataen. avail_orig er listen over
# tilgjengelighetsdata for hvert stativ hentet ut hvert femte minutt.
# Den er noe redigert fra den opprinnelige CSV-en.
load('bindata/availability_edited')
a <- avail_orig
a <- a[order(a$date),]

rowCount <- nrow(a)

# Vi konverterer tiden fra formatet HH:MM til antall sekunder etter midnatt
a$time <- lubridate::period_to_seconds(lubridate::hm(a$time))
# Vi grupperer hver variabel p?? et visst antall niv??er for at xgboost
# skal ha det hyggeligere
a$time <- cut(a$time, 100, include.lowest=TRUE, labels=FALSE)
a$weekday <- as.numeric(a$weekday)
a$lat = cut(a$lat, 25, include.lowest=TRUE, labels=FALSE)
a$lon = cut(a$lon, 25, include.lowest=TRUE, labels=FALSE)
a$masl = cut(a$masl, 25, include.lowest=TRUE, labels=FALSE)

# Den avhengige variabelen: er stativet fullt eller ikke?
a$full = a$availableBikes == 0

# Vi lager en ny data.table med kun variablene vi skal bruke
reducedA <- data.table(a$full, a$time, a$weekday, a$lat, a$lon, a$masl, a$totalLocks)
colnames(reducedA) <- c("full", "time", "weekday", "lat", "lon", "masl", "totalLocks")

# Vi skal n?? dele opp i et treningssett og et testsett. Vi ??nsker ?? ha 80% av datapunktene i
# treningssettet, og 20% i testsettet. Her kan vi velge ?? trekke ut tilfeldige punkter,
###  trainIndex <- createDataPartition(a$full, p=0.8, list=FALSE, times=1)
# men vi ??nsker ?? bruke data fra en tidligere periode til ?? predikere en senere periode.
# Derfor bruker vi de f??rste 80% av m??neden i treningssettet, og de siste 20% i testsettet.
trainIndex <- 1:(rowCount*0.8)
testIndex <- (rowCount*0.8+1):(rowCount)
aTrain <- subset(reducedA[trainIndex], select=-full)
aTest <- subset(reducedA[testIndex], select=-full)
labelTrain <- reducedA[trainIndex,]$full
labelTest <- reducedA[testIndex,]$full

# Vi gj??r tabellen om til en matrise for ?? kunne bli puttet inn i DMatrix, det native
# representasjonsformatet til xgboost
aTrainMatrix <- data.matrix(aTrain)
aTestMatrix <- data.matrix(aTest)
colnames(aTrainMatrix) <- colnames(aTrain)
colnames(aTestMatrix) <- colnames(aTest)

# Vi putter dataen inn i en DMatrix
dTrain <- xgb.DMatrix(data=aTrainMatrix, label=labelTrain)
dTest <- xgb.DMatrix(data=aTestMatrix, label=labelTest)

# Vi trener en modell basert p?? dataen v??r
res <- xgboost(data=dTrain,
               max_depth=20,
               eta=0.1,
               nthread=15,
               nrounds=50,
               early_stopping_rounds=5,
               maximize=FALSE,
               objective = "binary:logistic")

# Vi sjekker hvilke variabler som er viktigst. Se s??rlig p?? Gain
importance <- xgb.importance(model=res)
xgb.plot.importance(importance_matrix=importance)

# Vi utf??rer prediksjon p?? testsettet v??rt og regner ut en feil
pred <- predict(res, dTest)
pred_rounded <- as.numeric(pred > 0.5)
err <- mean(pred_rounded != getinfo(dTest, 'label'))