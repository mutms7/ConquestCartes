# Game Design

## Concept

A cozy tabletop fantasy deck-building game for one local player. The prototype
focuses on a short, readable play loop rather than campaign, multiplayer, or
opponent systems.

## Turn Loop

The player begins with seven Pebble Coin cards and three Homestead cards, shuffles, and draws five cards. Resource cards generate coins. Action cards can draw cards or grant actions, buys, and coins. One action and one buy are available at the start of each turn.

Cards purchased from the shared market enter the discard pile. Ending a turn
discards the hand and play area, resets turn resources, and draws a new five-card
hand. Empty draw piles are replenished by shuffling the discard pile.

The market contains 12 cards: 2 resources, 7 actions, and 3 victory cards. It is
rebuilt each game from a 38-card catalog.

## Solo Effect Resolution

The game has no opponent and does not pause for card-selection dialogs. Effects
that would normally ask for a choice use consistent automatic rules:

- Gaining selects the highest-utility eligible card.
- Trashing and top-decking from hand select the lowest-utility eligible card.
- Recovering from discard selects the highest-utility card.
- Inspection effects discard pure victory cards and retain other cards.
- Rival-only attack and reaction clauses have no solo effect.

These rules keep turns quick while retaining deck searching, trashing, upgrading,
replaying, variable scoring, and other distinct card roles.

## End and Scoring

The game ends after turn 15. Final score is the total victory points on cards in the draw pile, hand, play area, and discard pile.

## Prototype Scope

- Desktop, 1280x720, 2D interface
- One local player
- Random twelve-card shared market with unlimited prototype supply
- Original medieval interface, painterly card art, and UI audio
- No AI opponent, multiplayer, campaign, or save system
