# Gift a friend plan

**Status:** draft for Alan's OK (2026-11-12). No code until he says build it.

Buy something in the shop for a Roblox friend. You pay; it lands in their save.

## What the player sees
1. **Gift a friend** (top of the shop) or the small gift button on a card opens a "Pick a friend" note: your Roblox
   friends who have played Paper Flight, the ones in this server first, each with their picture and name.
2. Pick one, then the card to gift (if you came from a card's gift button, it's already picked). The note says
   "A gift for Sam: +5,000 Paper, 299 R$" with Roblox's own purchase pop-up, the same price as buying it for yourself.
3. After paying: "Sent! Sam gets it next time they're in a game." If Sam is playing right now, it arrives within
   seconds.
4. **Sam's side:** a gift moment the first time they're in the hangar or menu: a wrapped parcel drops in, unties, and
   shows "A gift from Alex!" with the item. Paper goes into their Paper; a boost starts its timer; a pass is theirs
   forever.

## What can be gifted
- **Paper packs** and **2x boosts** (the timed ones): yes.
- **2x forever passes:** yes, but only to a friend who doesn't own that pass yet (they're greyed out in the friend list).
- **Starter pack:** yes, only to a friend who hasn't had one (it's a one-time deal per player).
- **Paper jar:** no; it's your own savings. **Double this match:** no; it's your match.

## Limits
- Friends only, never strangers, and never yourself.
- The friend must have played Paper Flight at least once (else: "Invite them first!"; nothing is charged).
- No "First buy 2x!" on gifts: the friend keeps their own first-buy deal.
- Gifted Paper counts as bought Paper (it doesn't fill the friend's jar).
- Gifts count toward your 3 buys a day (the calm rule P: after 3, the pop-up offers stop).
- At most 10 gifts waiting for one friend; after that: "Sam has 10 gifts waiting! Try again after they play."

## How it's built (cheap)
- Roblox's purchase is a normal developer product; the server knows who it's for because you picked the friend
  before the pop-up (it remembers "Alex is buying 5,000 Paper for Sam" for a few minutes).
- Delivery uses the save library we already use (ProfileStore's "message" to another player's save): it waits in the
  friend's save until their game picks it up, so a crash or a full server never loses a gift. A gift is only marked as
  paid for once it's in the friend's mailbox.
- The friend list comes from Roblox (`GetFriendsAsync`); "has played" is one save read when you pick a friend.
- Roblox's rules: the docs we checked don't say anything about gifting. Its paid-trading rule is about trading, not
  gifting, and our gifts are never random. Parents' spending limits apply as usual, because the giver pays through
  Roblox's own pop-up.

## Cost
Saving rules and tests: Codex (Track C, on Alan's ChatGPT plan). Pick-a-friend note, gift moment and Studio checks:
Opus, about one session. Pictures: reuse the shop's gift and paper art; one parcel picture from Codex if needed. Nothing
paid.

## Not in this plan
Gifting parts or skins, a gift history page, thank-you messages.

Back to [HOME](../HOME.md)
