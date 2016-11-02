# xgboost må installeres fra GitHub, da det er en bug i versjonen i CRAN som gjør
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
load('availability_edited')
a <- avail_orig
a <- a[order(a$date),]

rowCount <- nrow(a)

# Vi konverterer tiden fra formatet HH:MM til antall sekunder etter midnatt
a$time <- lubridate::period_to_seconds(lubridate::hm(a$time))
# Vi grupperer hver variabel på et visst antall nivåer for at xgboost
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

# Vi skal nå dele opp i et treningssett og et testsett. Vi ønsker å ha 80% av datapunktene i
# treningssettet, og 20% i testsettet. Her kan vi velge å trekke ut tilfeldige punkter,
###  trainIndex <- createDataPartition(a$full, p=0.8, list=FALSE, times=1)
# men vi ønsker å bruke data fra en tidligere periode til å predikere en senere periode.
# Derfor bruker vi de første 80% av måneden i treningssettet, og de siste 20% i testsettet.
trainIndex <- 1:(rowCount*0.8)
testIndex <- (rowCount*0.8+1):(rowCount)
aTrain <- subset(reducedA[trainIndex], select=-full)
aTest <- subset(reducedA[testIndex], select=-full)
labelTrain <- reducedA[trainIndex,]$full
labelTest <- reducedA[testIndex,]$full

# Vi gjør tabellen om til en matrise for å kunne bli puttet inn i DMatrix, det native
# representasjonsformatet til xgboost
aTrainMatrix <- data.matrix(aTrain)
aTestMatrix <- data.matrix(aTest)
colnames(aTrainMatrix) <- colnames(aTrain)
colnames(aTestMatrix) <- colnames(aTest)

# Vi putter dataen inn i en DMatrix
dTrain <- xgb.DMatrix(data=aTrainMatrix, label=labelTrain)
dTest <- xgb.DMatrix(data=aTestMatrix, label=labelTest)

# Vi trener en modell basert på dataen vår
res <- xgboost(data=dTrain,
               max_depth=20,
               eta=0.1,
               nthread=15,
               nrounds=50,
               early_stopping_rounds=5,
               maximize=FALSE,
               objective = "binary:logistic")

# Vi sjekker hvilke variabler som er viktigst. Se særlig på Gain
importance <- xgb.importance(model=res)
xgb.plot.importance(importance_matrix=importance)

# Vi utfører prediksjon på testsettet vårt og regner ut en feil
pred <- predict(res, dTest)
pred_rounded <- as.numeric(pred > 0.5)
err <- mean(pred_rounded != getinfo(dTest, 'label'))