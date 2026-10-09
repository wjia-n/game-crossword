# Crossword — Rules of Play

_Authoritative source of truth for this game's rules. If the implementation
ever diverges, the implementation must be fixed, never this document._

## 1. Objective
Fill every white square of the crossword grid with the correct letter so all
across and down entries match their clues. Win by completing the whole grid;
in timed mode, beat the clock.

## 2. Setup
- The player picks a puzzle (Mini / Classic / Expert) and a mode: relaxed
  (no timer) or timed (countdown per difficulty).
- The grid loads with all white squares empty; black squares are blocked.
- Words are numbered like a real newspaper crossword: entries across get `→`
  numbers, entries down get `↓` numbers.

## 3. Turn order
Single-player. The player selects a word (tap a square), types letters one at
a time, and can switch words freely at any point.

## 4. Legal moves
- Tap any white square: selects its word. Tapping the same square again
  flips across ↔ down when both exist at that square.
- Type a letter: places it in the cursor cell, then the cursor advances to
  the next non-locked cell of the word.
- Backspace: clears the nearest editable cell holding a letter, stepping back.
- Check: flashes wrong letters red for 1.4s (counts as a check).
- Reveal: reveals the selected word letter-by-letter with a staged animation
  (counts as a hint). Revealed cells lock and cannot be edited.
- Clear: empties the selected word's editable cells (revealed cells stay).
- Next/previous word buttons and a tappable clue list jump between entries.

## 5. Illegal moves
- Typing on a black square, during check/reveal animations, while paused, or
  after the puzzle is done — all ignored (invalid buzz).
- Typing when the selected word has no editable cells left — ignored.
- Editing a revealed (locked) cell — impossible; the cursor skips it.
- Selecting Expert puzzles or PRO themes/styles while not PRO — gated to
  the Pro screen.

## 6. Captures
Not applicable (no capturing in crosswords).

## 7. Special rules
- **Timed mode**: countdown per difficulty — Mini 5:00, Classic 8:00,
  Expert 12:00. Timer runs only while input is open; pausing freezes it.
- **Timeout**: when the countdown hits zero the puzzle ends as a loss; the
  partially-filled grid stays visible with the correct answers NOT shown.
- **Scoring**: base = 20 points per entry. Timed: +2 per second remaining.
  Relaxed: time bonus shrinks the longer you take (up to 300s counted).
  Penalties: −10 per reveal (hint), −2 per check. Clamped to 10–9999.
- **Stars**: 3 stars with no reveals, 2 with ≤2, otherwise 1 (win only).

## 8. Scoring
See §7. Score is shown live during play and counts up on the results card.

## 9. Winning conditions
All white squares hold the correct letters. Win triggers immediately —
via typing, reveal, or a perfect check — with a fanfare, star rating, and
animated score count-up.

## 10. Draw conditions
Not applicable. Every puzzle is either won or timed out.

## 11. AI strategy
No AI opponent. Difficulty comes from puzzle size and clue difficulty:
Mini (7×7, easy clues), Classic (9×9, medium), Expert (9×9, hard).

## 12. Edge cases
- A word where every cell is revealed: reveal reports "invalid" — nothing to do.
- Backspace with no editable letter in the word: invalid buzz, nothing cleared.
- Check with zero mistakes and a complete grid: instant win, no flash.
- App backgrounded mid check/reveal: timers are cancelled and the watchdog
  re-settles the phase on resume — no stuck state is possible.
- Timed mode paused: countdown and watchdog both frozen; resume re-arms them.
- Player quits mid-puzzle: progress is not saved; a fresh grid loads next time.

## 13. Test cases
1. Type a full correct word → word-done chime, word marked complete.
2. Type a wrong letter, press Check → letter flashes red 1.4s, no win.
3. Reveal a word → letters appear one at a time (~130ms apart), cells lock,
   cursor skips them.
4. Fill the last wrong cell correctly → immediate win, stars + count-up.
5. Timed mode hits 0:00 → loss screen, score = base − penalties.
6. Background the app during a reveal → resume recovers, reveal completes.
7. Rename player → name persists across app restart, never scrambled.
8. Free player taps Expert puzzle → Pro screen, not the game.
9. Toggle music/SFX/volume in settings → persists, applies immediately.
10. Complete 3 puzzles → in-app review prompt appears once.
