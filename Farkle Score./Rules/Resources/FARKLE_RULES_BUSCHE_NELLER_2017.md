# Farkle — Busche & Neller (2017) “minimal” rules

Reference summary of the rule set used in *Optimal Play of the Farkle Dice Game* (ACG 2017). The authors deliberately chose a **small scoring table**—only **single 1s/5s** and **three of a kind**—with **no** straights, three pair, four/five/six of a kind, or other combination bonuses. That makes it a useful **reference implementation** when you want the simplest common Farkle core without extra melds.

**Source:** Matthew Busche and Todd W. Neller, “Optimal Play of the Farkle Dice Game,” in *Advances in Computer Games* (ACG 2017), LNCS 10664, Springer, 2017.  
**Open access PDF (author hosting):** [cs.gettysburg.edu — acg2017.pdf](http://cs.gettysburg.edu/~tneller/papers/acg2017.pdf)  
**DOI:** [10.1007/978-3-319-71649-7_6](https://doi.org/10.1007/978-3-319-71649-7_6)

## Objective

Be the **first player to reach a banked score of 10,000 or more** (paper’s wording; analysis is for **two** players, but the game generalizes).

## Equipment

Six standard six-sided dice; pencil and paper (or equivalent) for scores.

## Turn structure

1. **Start of turn:** Roll all six dice.
2. **Scoring:** Identify **combinations** from **this roll only** (see table). Each die may be used in **at most one** combination. You may take **multiple** non-overlapping combinations from the same roll.
3. **Set aside:** If any combinations exist, you **must** set aside **at least one** combination and may set aside more. Add those points to your **turn total**.
4. **Choose:** Re-roll dice not in combinations, or **bank** (add turn total to banked score and end turn).
5. **Farkle:** If the roll has **no** legal combination, you **score 0 for the turn**; banked score is unchanged; pass the dice.
6. **Hot dice:** If combinations use **all six** dice, roll **all six again** and continue the same turn (same turn total at risk until you bank or farkle).

## Scoring combinations (complete list in paper)

These are the **only** scoring patterns in this variant:

| Combination | Points |
|-------------|--------|
| One **1** | 100 |
| One **5** | 50 |
| Three **1**s | 1,000 |
| Three **2**s | 200 |
| Three **3**s | 300 |
| Three **4**s | 400 |
| Three **5**s | 500 |
| Three **6**s | 600 |

There are **no** points for a 1–6 run, three pairs, two triplets, or four+ of a kind in this ruleset.

## Optional fairness note (from the paper)

For **two-player** “fairest” opening positions, the authors **recommend 200 compensation points** for the **second** player at game start (see paper abstract and body). This is a research/tournament tweak, not part of most casual rule sheets.

## Relation to other files in this repo

This variant is **strictly narrower** than `FARKLE_RULES.md` (Cardgames.io), `FARKLE_RULES_WIKIPEDIA_ARNOLD.md`, and `FARKLE_RULES_PLAYMONSTER.md`, which add straights, extra multiples, pairs, etc. Use Busche & Neller when you want **minimal** scoring and **maximum** freedom in **which** scoring dice to keep (the paper stresses that design goal).
