# Gift a friend plan

**Status:** approved 2026-11-13 with Alan's changes ([decision](../decisions/2026-11-13-gift-a-friend.md)); being built.

Buy something in the shop for a Roblox friend. You pay; it lands in their save.

## What the player sees
1. **Gift a friend** (top of the shop) or the small gift button on a Paper pack or boost card opens a "Pick a friend"
   note: your Roblox friends, the ones in this server first, each with their picture and name.
2. Pick one, then the item (if you came from a card's gift button, it's already picked). Before anything is paid, the
   note says if that friend can't get it: hasn't played yet ("Invite them first!"), already has 10 gifts waiting, or
   already has that 2x forever. Otherwise: "A gift for Sam: +5,000 Paper, 299 R$" with Roblox's own purchase pop-up, the
   same price as buying it for yourself.
3. After paying: "Sent! Sam gets it next time they play." If Sam is playing right now, it arrives within seconds.
4. **Sam's side:** a gift moment in the hangar or menu: a wrapped parcel drops in, unties, and shows "A gift from Alex!"
   with the item. Paper goes into their Paper; a boost starts its timer.

## What can be gifted
- **Paper packs** and **timed 2x boosts**: yes.
- **2x forever passes:** not for now (Roblox ties a pass to its buyer); maybe later if gifts sell.
- **Starter pack, Paper jar, Double this match:** no.

## Limits
- Friends only, never strangers, and never yourself. The friend must have played at least once.
- No "First buy 2x!" on gifts, and a gift never uses up the giver's own first-buy 2x.
- Gifted Paper doesn't fill the jar (only Paper earned in matches does).
- Gifts count toward your 3 buys a day (after 3, the pop-up offers stop).
- At most 10 gifts waiting for one friend.
- No "ask a friend to buy me this" button.

## How it's built (cheap)
- Each giftable item has its own Roblox developer product ("Gift: 5,000 Paper"), so a gift payment can never be mistaken
  for a buy for yourself. The server remembers who it's for between the pick and the payment; if it ever forgets (a
  server restart in between), the giver gets the item instead, so no payment is lost.
- Delivery uses the save library we already use (ProfileStore's "message" to another player's save): it waits in the
  friend's save until their game picks it up, so a crash or a full server never loses a gift. A gift is only marked as
  paid for once it's in the friend's mailbox, and the same gift can never arrive twice.
- The friend list comes from Roblox; "has played" and "gifts waiting" are one save read when you pick a friend.
- Roblox's rules: the docs we checked don't say anything about gifting. Its paid-trading rule is about trading, not
  gifting, and our gifts are never random. Parents' spending limits apply as usual, because the giver pays through
  Roblox's own pop-up.

## Cost
Saving rules and tests: Codex (Track C, on Alan's ChatGPT plan). Pick-a-friend note, gift moment and Studio checks:
Opus, about one session. Pictures: reuse the shop's gift and paper art; one parcel picture from Codex if needed. Nothing
paid. At go-live Alan creates the 15 gift products on Roblox with the other products.

## Not in this plan
Gifting passes, parts or skins, a gift history page, thank-you messages.

Back to [HOME](../HOME.md)
