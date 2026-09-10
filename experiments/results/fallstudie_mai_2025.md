# Fallstudienanalyse Mai 2025

Positive Flüsse bedeuten Import nach Deutschland, negative Export. Der
`summierte Fluss` ist die Summe der elf bilateralen CBPF-Werte je Stunde und
damit eine abgeleitete explorative Größe.

## Korrelationen (Pearson)

| Variablen | r |
|---|---:|
| Strompreis und erneuerbare Leistung | -0,758 |
| Strompreis und Anteil Erneuerbarer | -0,817 |
| Strompreis und summierter Fluss | 0,084 |
| Erneuerbare Leistung und summierter Fluss | 0,042 |

Die Werte beschreiben lineare Gleichläufigkeit im ausgewählten Monat und
belegen keine Kausalität.

## Vergleich nach Richtung des summierten Flusses

| Zustand | Stunden | mittlerer Preis (EUR/MWh) | mittlere Erneuerbare (GW) | mittlerer Anteil Erneuerbarer |
|---|---:|---:|---:|---:|
| positiver Summenfluss | 123 | 75,90 | 35,84 | 63,0 % |
| negativer Summenfluss | 621 | 65,63 | 35,24 | 64,3 % |

## Auffällige Stunden

| Zeitpunkt (UTC) | Preis (EUR/MWh) | Erneuerbare (GW) | Anteil Erneuerbare | summierter Fluss (GW) |
|---|---:|---:|---:|---:|
| 11.05. 11 h | -250,32 | 58,961 | 88,7 % | -7,32 |
| 19.05. 18 h | 229,11 | 11,582 | 24,6 % | -13,36 |
| 12.05. 10 h | -25,00 | 71,465 | 88,7 % | 0,74 |
| 23.05. 22 h | 98,99 | 23,037 | 53,3 % | 5,49 |
| 03.05. 13 h | -0,03 | 44,734 | 84,2 % | -14,23 |

## Partnerprofile

| Partner | Mittelwert (GW) | Minimum (GW) | Maximum (GW) | Importstunden | Exportstunden |
|---|---:|---:|---:|---:|---:|
| Austria | -1,272 | -3,320 | 2,106 | 91 | 653 |
| Belgium | -0,096 | -1,002 | 1,002 | 308 | 436 |
| Czech Republic | 0,255 | -1,959 | 2,497 | 452 | 292 |
| Denmark | -0,680 | -3,212 | 2,995 | 214 | 530 |
| France | 0,995 | -2,513 | 4,553 | 533 | 211 |
| Luxembourg | -0,428 | -0,777 | -0,124 | 0 | 744 |
| Netherlands | -0,176 | -3,217 | 4,370 | 297 | 447 |
| Norway | 0,015 | -1,444 | 1,403 | 438 | 306 |
| Poland | -1,205 | -2,346 | -0,145 | 0 | 744 |
| Sweden | -0,075 | -0,596 | 0,607 | 116 | 628 |
| Switzerland | -1,725 | -4,054 | 2,596 | 53 | 691 |
