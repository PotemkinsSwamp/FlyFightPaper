# Winners' circle and emotes plan

**Status, 2026-11-19.** Alan OK'd the staging (timeline, near-dark, lights 3rd-2nd-1st a second apart) and it is built, not yet seen in Play: [where it stands](../systems/modes-and-scoring.md). Camera Flick is built in as 1st's emote for Studio (Dev panel "end: flick"), not yet run in Play; the falling confetti is out (Alan). The book stacks must be new models, not the town's (Alan). His direction is in the
[decision](../decisions/2026-11-19-winners-circle-redo.md). Today's scene is on the
[modes and scoring](../systems/modes-and-scoring.md) page.

## The scene (proposed; Alan likes the dim and the spotlights, not yet OK'd as a whole)
About 15 seconds, the same every match:
1. "Pencils down!" The room dims over about a second.
2. The winners are already up, each on a stack of books on their desk: 1st's tallest, 3rd's lowest.
   **The books are always there** (Alan 2026-11-19), so emotes can sit on them or kick them over.
3. Spotlights snap on in order (3rd, 2nd, 1st), each with its paper name plate. The song starts on 1st's light.
4. Everyone plays their own emote. The camera moves in on 1st for theirs, then pulls back to all three; 2nd and 3rd's
   emotes loop the whole time.
5. The class reacts when 1st's light comes on: paper balls arc in from desks where players sit, starting off screen,
   landing around the winners, never on a face or the camera. (Alan: careful where each thing comes from.)
6. Report card, then the vote.

## Emotes: two slots
- **Winner emote** plays when you come 1st. **Runner-up emote** plays when you come 2nd or 3rd and never touches the
  camera. Dances (later) work in either slot. Everyone starts with one free emote in each slot; the rest are sold.
- **Touching the camera is an extra, not a rule** (Alan 2026-11-19): covering it, knocking it over or playing with
  the stage is what makes some emotes special, each in its own way; if every paid one did it, it would turn into a
  gimmick. The free one doesn't, and new emotes don't have to. When one does cover the camera, the cover coming off
  can be the cut back to your desk (Book Kicker).
- **Never depend on the body's shape** (Alan 2026-11-19): avatars have short arms, long arms or none, so nothing
  lands on an arm, and no prop has to line up with a body part. A prop may ride on one hand or the head (it follows
  any body); things that fly keep their own path around the kid.
- Liveliness comes from a toy or prop that moves by itself while the kid watches and reacts, not from camera work.
- Each emote is a recipe (body move, prop path, camera shots, the cover, song) run by one player script, so the shop
  preview and the scene play the same thing.

## Ideas (Alan 2026-11-19: "all those emotes are good", note them all)
Names are placeholders.

**Winner emotes (1st place)**
| Emote | What happens |
|---|---|
| Toy Pilot (free) | Flies their plane around like a toy, then holds it up |
| Camera Flick (Alan) | Flicks the plane at the camera; it fills the screen and the camera tips over |
| Book Kicker (Alan) | Kicks a book; it flies at the camera, opens, slaps flat on the lens and slides down to your desk |
| Skeet Shoot (Alan) | The runner-ups throw their paper planes and 1st shoots them out of the air, like skeet shooting, with rubber bands off a finger or a slingshot: something a child would do |
| Bubblegum | Blows a bubble that grows until it fills the screen, pops and leaves pink gum on the lens |
| Spitball | Loads a straw, grins and fires; a wet splat hits the lens and slides down |
| Autograph | The camera comes in close on them (Alan: an arm can't reach the screen, the screen comes to them); they sign it in marker, add a moustache, wipe it off with a sleeve |
| Fold It Up | Grabs the picture itself, folds the whole screen into a paper plane and throws it away |
| A+ | Holds up their report card and slaps it on the lens, where it becomes the real report card |
| Chalk Bomb | Claps two board erasers; a chalk cloud swallows the screen and drifts off |
| Stomp | Jumps off the books at the camera; the shoe sole fills the screen |
| Magician (Alan) | Whistles; paper planes fly in and circle them; the kid floats up into the air in the middle with hands out to the sides, like a stage magician |
| Domino Books | Nudges one book and a line of them topples around the desk like dominoes, ending arms up |
| Paper Storm | Throws a whole stack of homework in the air and spins under it as it rains down |
| Ruler Drumroll | Drums with two rulers, spins one and catches it behind their back |

Dropped: Confetti Blast (a dance, then confetti over the lens). Alan: not interesting enough; it needs something fun
and edgy like Camera Flick and Book Kicker.

**Runner-up emotes (2nd and 3rd)**
| Emote | What happens |
|---|---|
| Good Game (free) | A small clap and a wave |
| Next One (Alan) | Sits on the books folding a new paper plane |
| So Close (Alan) | Sits on the books shaking their head, sad not to be 1st |
| Slow Clap | A slow, sarcastic clap |
| Sore Loser | Arms crossed, back turned to 1st, sneaking looks over the shoulder |
| Doodler | Scribbles in a notebook, then holds up a drawing of themselves in 1st. **Stick figures** (Alan): a child drew it |
| Nap | Asleep on the books with little Z's |
| Test Flight | Tosses a tiny plane that loops and comes back to their hand |
| Sneaky Toss | Lobs a paper ball toward 1st, then looks away whistling |

## The first five (Alan's pick, 2026-11-19)
Toy Pilot, Camera Flick, Good Game, Next One, Nap. **Camera Flick proves the process first**: Alan looks at a couple
of versions, and if it's good the other four get made the same way. The process gets written down while it happens
([emote making](../workshop/emote-making.md)); if it works it becomes a skill so the results can be repeated.
Rest of the beta set (after these): Book Kicker, Bubblegum, Magician, So Close. Later: Skeet Shoot, A+, Fold It Up
and the others.

## How an emote gets made (proposed; waits for Alan's OK)
Where the body motion comes from, cheapest first (research 2026-11-19):
1. **Roblox's Prompt to Animation** (Studio beta, announced November 2026): a written description becomes an R15
   animation, through our Studio link. Free in the beta, four tries a minute. Roblox says it is best at everyday
   human movement; name the end pose, join actions with "then" and "while", keep each action 1-10 s.
2. **Roblox's Animation Capture**: a video of one person (under 15 s, steady camera, good light) becomes an R15
   animation. Free. For moves the generator can't do; Alan or anyone films it.
3. **Free motion from outside** (Rokoko's video capture and text-to-motion, Mixamo's library): arrives as FBX and
   goes through our own fitting tool (`tools/meshy_to_r15.py`, one bone-name list per source). Export limits and
   licences get checked on the day.
4. **Roblox's own emotes**: free to play, can't be changed. Stand-ins, and maybe all Good Game needs.
Never typed-in keyframes for a body move (October's arm-only test looked lifeless).

The steps, each with a check before the next:
1. **Shot card** in words: the beats and their times, the prop's path, what the camera does.
2. **Body motion**: three versions from source 1, each a different wording.
3. **Numbers check** on every version, before anyone looks: length; feet stay on the spot; the key moment is sharp
   (a flick is a spike in hand speed); the end pose holds; no drift on a big avatar.
4. **Clean-up**: trim, lock the hips over the desk, ease in from standing, hold the end pose, mark the key moment
   inside the animation (a named marker, so the prop and camera fire on it whatever the loading does).
5. **Prop and camera** by script, fired by the marker.
6. **Body sweep**: the same emote on a set of extreme avatars (tiny, tall, short arms, no visible arms, non-human).
7. **Alan's look**: a Studio-only Dev button in Play steps through the versions in the real scene.
8. **Upload** the one he picks (free, his go), put its id in the config, log the recipe.

## Open
- Skeet Shoot uses all three winners: the runner-ups' own emotes pause while they throw, then carry on (Alan
  2026-11-19). It doesn't touch the camera; how it ends is open (idea: 1st blows across the finger, the planes
  spiral down).
- Sitting or one-clear-action emotes are the safest; Autograph and Stomp need the most real motion.
- Whether Camera Flick is proven in today's scene first (smaller) or after the scene redo.
- Props that ride on a hand are fine on any body (Alan 2026-11-19). Ideas where two things must meet need a safe
  version: Ruler Drumroll (hands reaching the desk), Next One (two hands on the plane), the claps (hands meeting).
- **How any avatar plays any emote:** every Roblox avatar already has the same standard skeleton (R15), and an
  animation is stored as joint turns by name, so it plays at once on any of them; today's scene already copies each
  winner's avatar and plays animations on the copy (`WinnersCutscene` `copyWinner`). Only proportions differ, so sizes
  and camera distances come from the avatar's own height, and each emote gets checked on a set of extreme bodies
  (tiny, tall, short arms, no visible arms) before it ships. Old-style R6 avatars (6 parts) can't play these: they
  get a simple fallback.
- Music: licensed only. Prices, and which emotes ship in the beta.
- Proposed build order: the scene first with today's dances standing in; then Camera Flick and Next One to prove the
  method; then the rest and the shop shelf.
