# Farkle — Busche & Neller (2017) règles « minimales »

Résumé de référence de l'ensemble de règles utilisé dans *Optimal Play of the Farkle Dice Game* (ACG 2017). Les auteurs ont délibérément choisi une **petite table de notation** – uniquement des **simples 1/5** et des **brelans**—avec **pas** de suite, trois paires, quatre/cinq/six ou d'autres bonus de combinaison. Cela en fait une **implémentation de référence** utile lorsque vous souhaitez le noyau Farkle commun le plus simple sans fusions supplémentaires.

**Source :** Matthew Busche et Todd W. Neller, « Optimal Play of the Farkle Dice Game », dans *Advances in Computer Games* (ACG 2017), LNCS 10664, Springer, 2017.
**PDF en libre accès (hébergement par l'auteur) :** [cs.gettysburg.edu — acg2017.pdf](http://cs.gettysburg.edu/~tneller/papers/acg2017.pdf)
**DOI :** [10.1007/978-3-319-71649-7_6](https://doi.org/10.1007/978-3-319-71649-7_6)

## Objectif

Soyez le **premier joueur à atteindre un score en banque de 10 000 ou plus** (texte du document ; l'analyse concerne **deux** joueurs, mais le jeu se généralise).

## Équipement

Six dés standards à six faces ; crayon et papier (ou équivalent) pour les partitions.

## Tourner la structure

1. **Début du tour :** Lancez les six dés.
2. **Notation :** Identifiez les **combinaisons** à partir de **ce lancer uniquement** (voir tableau). Chaque dé peut être utilisé dans **au plus une** combinaison. Vous pouvez prendre **plusieurs** combinaisons sans chevauchement à partir du même lancer.
3. **Mettez de côté :** S'il existe des combinaisons, vous **devez** mettre de côté **au moins une** combinaison et pouvez en mettre de côté davantage. Ajoutez ces points à votre **total de tour**.
4. **Choisissez :** Relancez les dés sans combinaison, ou **banque** (ajoutez le total du tour au score en banque et terminez le tour).
5. **Farkle :** Si le jet n'a **aucune** combinaison légale, vous **marquez 0 pour le tour** ; le score en banque est inchangé ; passez les dés.
6. **Dés chauds :** Si les combinaisons utilisent **tous les six** dés, lancez **tous les six** à nouveau** et continuez le même tour (même tour total à risque jusqu'à ce que vous fassiez une banque ou un farkle).

## Combinaisons de notation (liste complète sur papier)

Voici les **seuls** modèles de notation dans cette variante :

| Combinaison | Points |
|-------------|--------|
| Un **1** | 100 |
| Un **5** | 50 |
| Trois **1** | 1 000 |
| Trois **2** | 200 |
| Trois **3** | 300 |
| Trois **4** | 400 |
| Trois **5** | 500 |
| Trois **6** | 600 |

Il n'y a **aucun** point pour une série de 1 à 6, trois paires, deux triplets ou quatre+ d'une sorte dans cet ensemble de règles.

## Note d'équité facultative (extraite du document)

Pour les positions d'ouverture « les plus justes » à deux joueurs**, les auteurs **recommandent 200 points de compensation** pour le **deuxième** joueur au début du jeu (voir le résumé et le corps de l'article). Il s'agit d'un ajustement de recherche/tournoi, qui ne fait pas partie des feuilles de règles les plus occasionnelles.

## Relation avec d'autres fichiers de ce dépôt

Cette variante est **strictement plus étroite** que `FARKLE_RULES.md` (Cardgames.io), `FARKLE_RULES_WIKIPEDIA_ARNOLD.md` et `FARKLE_RULES_PLAYMONSTER.md`, qui ajoutent des suites, des multiples supplémentaires, des paires, etc. Utilisez Busche & Neller lorsque vous voulez un score **minimal** et une liberté **maximale** dans **quels** dés à conserver (le papier souligne cet objectif de conception).
