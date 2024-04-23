# ASC - Tema 2

### Daraban Albert-Timotei

## Implementare

* Prima data am incercat sa iau direct codul for loop-ul dat ca exemplu de pe CPU. Si am creat MAX_NONCE GPU threads. Dupa cateva este sa vazut un speed up, dar nu suficient (1.6 s).
* Implementarea actuala este una la fel de simpla cu start si end de la APD. Practic creez NR_SMs * 256 threads si fiecare incearca o portiune din numere. Cand se gaseste se pune un flag si primul thread care il schimba isi scrie rezultatul.

## Rezultate

| Test | Timp XL(s) | Timp Local RTX 3060 Laptop(s) |
|------|------------|-------------------------------|
|   1  |    0.11    |              0.18             |
|   2  |    0.15    |              0.15             |
|   3  |    0.20    |              0.18             |
|   4  |    0.21    |              0.17             |
|   5  |    0.10    |              0.18             |
|   6  |    0.05    |              0.18             |
|   7  |    0.22    |              0.18             |
|   8  |    0.35    |              0.19             |
|   9  |    0.30    |              0.18             |
|  10  |    0.06    |              0.18             |
|  11  |    0.19    |              0.18             |
|  12  |    0.36    |              0.18             |
|  13  |    0.03    |              0.18             |
|  14  |    0.08    |              0.17             |
|  15  |    0.38    |              0.15             |
|  16  |    0.03    |              0.18             |
|  17  |    0.19    |              0.17             |
|  18  |    0.07    |              0.17             |
|  19  |    0.10    |              0.17             |
|  20  |    0.03    |              0.18             |
|  AVG |    0.16    |              0.175            |

Dupa cum se vede coada XL este in medie mai rapida decat masina mea locala. Dar are si o discrepanta mai mare intre valori care probabil vine de la faptul ca sunt si alti utilizatori ca ruleaza si uneori GPU este mai incarcat.
