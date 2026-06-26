# Game Design

## Concept

A cozy tabletop fantasy deck-building game for one local player. The prototype
focuses on a short, readable play loop rather than campaign, multiplayer, or
opponent systems.

## Turn Loop

The player begins with seven Pebble Coin cards and three Homestead cards, shuffles, and draws five cards. Resource cards generate coins. Action cards can draw cards or grant actions, buys, and coins. One action and one buy are available at the start of each turn.

Cards purchased from the shared market enter the discard pile and remove one card
from that finite supply pile. Ending a turn discards the hand and play area,
resets turn resources, and draws a new five-card hand. Empty draw piles are
replenished by shuffling the discard pile.

The market contains 14 cards: 2 resources, 10 actions, and 2 victory cards. The
catalog contains 64 cards: 2 starters, 56 random-market candidates, and 6
archived cards retained for testing, future sets, and art-linked reuse. The
26-card mechanics expansion is tagged as the `Hinterlands` group.
The home menu includes a tabbed Kingdoms browser. Whole optional kingdoms or
individual non-required cards can be disabled before a new game, removing those
cards from the random market pool. The required `Base Kingdom` keeps starter,
economy, and core victory cards available.

The market is arranged as one nearly edge-to-edge field: two resource piles on
the left, ten action piles in a two-by-five center grid, and two victory piles
on the right. Card type colors identify these groups without large enclosing
carpets or headers. Resource and victory piles descend in cost from top to
bottom. Action piles descend from the top-right across to the top-left, then
continue from the bottom-right to the cheapest pile at the bottom-left.

The hand occupies the lower center of the table. Compact docks at its sides hold
turn/deck/discard controls on the left and coins/actions/buys controls on the
right, leaving the top of the screen to the market artwork. Card faces display
their data-driven rules with bold `+1 buy`, `+2 coins`, and similar shorthand
for numeric gains and draws; hovering provides a larger art and reading view.

## Solo Effect Resolution

The game pauses on a generic card-choice overlay whenever an effect requires the
player to select cards. Choices can draw candidates from the hand, discard pile,
revealed cards, or available supply piles. Multi-step effects resume from an
ordered rules queue after each choice.

The solo rules support discarding, trashing, gaining, upgrading, replaying,
setting actions aside, inspecting cards, choosing revealed-card destinations,
selecting top-deck order, reacting to gain/discard/trash events, reducing costs,
and pausing cleanup for optional card recovery. Rival-only attack and reaction
clauses still have no effect because the game has no opponent.

## End and Scoring

The game ends after turn 15. Final score is the total victory points on cards in the draw pile, hand, play area, and discard pile.

## Prototype Scope

- Desktop, 1280x720, 2D interface
- One local player
- Random fourteen-card kingdom market with finite supply piles
- Home menu with New Game, Continue, local Settings controls, and a Kingdoms card browser
- Original medieval interface, painterly card art, and UI audio
- No AI opponent, multiplayer, campaign, or save system
