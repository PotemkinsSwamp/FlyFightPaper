# Design and colour research 2026-11-12

Alan asked for a design and colour theory skill backed by real research on games, kids and toys. This page holds the
findings; the rules built on them are in the `design-theory` skill (`.claude/skills/design-theory/SKILL.md`), which
cites the numbered findings here (C = colour, L = layout and reading, G = games).

## How strong this is
- **Strong:** many studies or a field consensus. **Medium:** one or a few decent studies. **Standard:** a published
  standard or platform guideline (numbers from expert committees, mostly not from experiments). **Practice:** what a
  studio does and explains, not tested. **Folklore:** no research found.
- Most colour studies test adults (often US students); child studies mostly test under-8s. Almost nothing tests
  8 to 16 year olds or game menus directly, so rules for our players lean on adult findings plus the child studies.
- Every link was opened by the researching helper unless marked. Five load-bearing claims were re-checked word for
  word on 2026-11-12: C2, L4, G1, G4 and the WCAG basis in L9.

## Colour (C)
- **C1. Saturated colours are liked most; muddy browns and olives least.** Palmer & Schloss 2010, PNAS, 48 adults,
  32 colours ([PDF](https://palmerlab.berkeley.edu/pdf/Palmer%26Schloss%282010%29.pdf)). Strong (adults).
- **C2. Colour pairs: similar hues plus a clear light/dark difference are liked; opposite (complementary) hues are
  not liked more.** Preference was "governed primarily by component color preferences, coolness, hue similarity, and
  lightness contrast"; "no increases in preference for complementary colors". Schloss & Palmer 2011, Attention,
  Perception & Psychophysics, 48 adults, 992 figure-on-ground pairs
  ([paper](https://pmc.ncbi.nlm.nih.gov/articles/PMC3037488), doi 10.3758/s13414-010-0027-0). Strong (adults).
  Re-checked.
- **C3. Brightness drives pleasure, saturation drives excitement.** Pleasure = 0.69 brightness + 0.22 saturation;
  arousal = 0.60 saturation - 0.31 brightness. Valdez & Mehrabian 1994, J. Exp. Psych: General
  ([doi](https://doi.org/10.1037/0096-3445.123.4.394), abstract only). Medium-strong (adults).
- **C4. Young children feel good about bright colours and bad about brown, black and grey.** Boyatzis & Varghese
  1994, 60 children aged 5 to 6 ([doi](https://doi.org/10.1080/00221325.1994.9914760), abstract only). Medium.
- **C5. Older children choose lower saturation than younger ones; "crayon-bright, not neon".** Hao & Guan 2025
  (ages 3 to 15, room colour schemes; [doi](https://doi.org/10.1177/19375867251327969), abstract only), weak-medium;
  Chen et al. 2023 (18 children aged 4 to 7: attention rose as block colours softened, then fell when washed out;
  [paper](https://www.frontiersin.org/articles/10.3389/fpsyg.2023.1205213)), weak.
- **C6. Toy colour is mostly marketing; from about 6 to 9, kids want real-looking things and call plastic-looking
  ones "babyish".** US CPSC 2020 Age Determination Guidelines, p. 16 and age sections
  ([PDF](https://www.cpsc.gov/s3fs-public/pdfs/blk_media_adg.pdf)). Standard (expert guideline from a literature
  review and observation).
- **C7. Light/dark carries edges, depth and motion; colours of equal brightness look flat.** Livingstone & Hubel 1987,
  J. Neuroscience ([doi](https://doi.org/10.1523/JNEUROSCI.07-11-03416.1987), abstract only); Livingstone, *Vision
  and Art*. Medium (well established, the strong form is disputed).
- **C8. Real-world colours help people recognise things; false colours don't.** Wichmann, Sharpe & Gegenfurtner 2002
  ([abstract](https://pubmed.ncbi.nlm.nih.gov/12018503/)). Strong.
- **C9. About 8% of boys of European ancestry and 0.4% of girls are red-green colour-blind.** Birch 2012, JOSA A
  ([doi](https://doi.org/10.1364/JOSAA.29.000313), abstract only). Strong.
- **C10. Never carry information by colour alone; add shape, icon, pattern or words.** Xbox Accessibility Guideline
  103 ([page](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/103)); Game
  Accessibility Guidelines ([page](https://gameaccessibilityguidelines.com/ensure-no-essential-information-is-conveyed-by-a-colour-alone/));
  Roblox ([accessibility](https://create.roblox.com/docs/production/publishing/accessibility)). Standard.
- **C11. The "60-30-10" colour split has no research behind it** (searched the web and an academic index of ~400M
  papers; only decorating articles). Folklore.

## Layout, reading and pointing (L)
- **L1. Things close together, or inside one border, are seen as one group; nearness is relative.** Wagemans et al.
  2012, Psychological Bulletin, review ([paper](https://pmc.ncbi.nlm.nih.gov/articles/PMC3482144)). Strong.
- **L2. Bigger and nearer targets are hit faster (Fitts's law).** MacKenzie 1992
  ([paper](https://www.yorku.ca/mack/hci1992.html)). Strong.
- **L3. Young children slip off targets near the end of the move.** Hourcade et al. 2004, ACM TOCHI, 39 people
  (4, 5 year olds and adults; [report](https://drum.lib.umd.edu/items/f3e5dc45-7acc-40c6-8dfd-a258b9c0bc9b/full)).
  Medium.
- **L4. Children 7 to 16 miss more taps (23.1% first-try misses vs adults 16.9%); a 10-pixel gap between a button and
  the screen edge nearly doubled misses; taps on where the last button was ("holdovers") came almost all from
  children.** Anthony et al. 2012, ITS, 16 children and 14 adults on a phone
  ([PDF](http://lisa-anthony.com/wp-content/uploads/2012/09/anthony-et-al-tabletop20121.pdf)). Medium; closest to
  our ages. Re-checked.
- **L5. Touch targets: errors stop falling at about 9.6 mm** (Parhi et al. 2006, 20 adults,
  [page](https://www.microsoft.com/en-us/research/?p=155150), medium). Apple 44 x 44 pt (minimum 28), Google 48 x 48
  dp "about 9 mm" with 8 dp gaps (standard, no research cited).
- **L6. Small text slows young readers and adds errors at every age; bigger lowercase letters help; a "child-friendly"
  font was not faster than a plain one.** Hughes & Wilkins 2000 (120 children, quoted in Kuster et al. 2018); Wilkins
  et al. 2009 ([abstract](https://repository.essex.ac.uk/1476/)). Medium.
- **L7. Handwriting-style words are slower to read, more so for rare words; friendly fonts like Comic Sans read as
  well as plain ones for 9 to 11 year olds.** Barnhart & Goldinger 2010 (adults,
  [paper](https://pmc.ncbi.nlm.nih.gov/articles/PMC4241396)), strong for adults; Bernard et al. 2002 (27 children,
  [page](https://portfolio.erau.edu/en/publications/examining-childrens-reading-performance-and-preference-for-differ/)),
  medium.
- **L8. Wider letter spacing halved errors for dyslexic children aged 8 to 14; special "dyslexia fonts" gave nothing
  once spacing matched.** Zorzi et al. 2012, PNAS ([paper](https://pmc.ncbi.nlm.nih.gov/articles/PMC3396504)); Kuster
  et al. 2018 ([paper](https://pmc.ncbi.nlm.nih.gov/articles/PMC5934461/)). Medium.
- **L9. Contrast: 3:1 is the minimum from ISO 9241-3 / ANSI-HFES-100; 4.5:1 = 3 x 1.5 to cover vision loss of about
  20/40; large text (18 pt, or 14 pt bold) may use 3:1.** W3C, Understanding WCAG 1.4.3
  ([page](https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html)). Standard. Re-checked.
- **L10. Busy backgrounds slow reading more than weak text contrast does** (background texture predicted speed,
  r = -.78; text contrast r = .43). Scharff, Ahumada & Hill 1999, 34 adults
  ([page](https://laurenscharff.com/research/spie99.html)). Medium.
- **L11. What grabs the eye: colour, motion, orientation, size; one strong peak stands out, many equal peaks cancel;
  goals, layout, experience and reward steer the eye more than raw contrast.** Itti, Koch & Niebur 1998
  ([page](https://ilab.usc.edu/publications/Itti_etal98pami.html)); Wolfe & Horowitz 2017, Nature Human Behaviour
  ([paper](https://pmc.ncbi.nlm.nih.gov/articles/PMC9879335)). Strong.
- **L12. The "F-pattern" is for skimming walls of web text only.** Nielsen Norman Group
  ([page](https://www.nngroup.com/articles/f-shaped-pattern-reading-web-content/)). Weak for games.
- **L13. "Too many choices" is not a reliable effect on its own** (meta-analysis of 50 experiments, average effect
  near zero); it shows up when people don't know what they want. Scheibehenne et al. 2010
  ([page](https://edoc.unibas.ch/20586)). Medium.

## Games (G)
- **G1. Valve's TF2: "muted colors dominating and small areas of saturation"; high-frequency detail left out of the
  world and sky so it doesn't "distract players".** Mitchell, Francke & Eng 2007
  ([PDF](https://www.advances.realtimerendering.com/s2007/Mitchell-IllustrativeRenderingInTF2(Siggraph07%20Course%20Notes).pdf)).
  Practice. Re-checked.
- **G2. Plan the read order: team (colour), then class (silhouette), then weapon, which gets the highest contrast.**
  Valve GDC 2008, *Stylization with a Purpose*
  ([slides](https://cdn.fastly.steamstatic.com/apps/valve/2008/GDC2008_StylizationWithAPurpose_TF2.pdf)). Practice.
- **G3. Silhouettes alone are an unreliable way to recognise objects (0% to 100% by object).** Wagemans et al. 2008,
  Perception ([doi](https://doi.org/10.1068/p5825), abstract only). Medium.
- **G4. Minimum text size (body height, top of tallest letter to bottom of lowest): PC 18 px at 1080p, console 26 px,
  phones 18 px at 100 DPI scaled with density; let players scale text to 200%; sentence case for sentences.** Xbox
  Accessibility Guideline 101 ([page](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/101)).
  Standard. Re-checked.
- **G5. Contrast 4.5:1 for text and key visuals, 3:1 for big text and disabled items; over texture, measure against
  the least-contrast patch; solid plate or border for text over the game.** Xbox Accessibility Guideline 102
  ([page](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/102)). Standard.
- **G6. Plain text on an unfussy background; the guides disagree on outlines** (Xbox shows outlines for text over a
  moving game; the Game Accessibility Guidelines say avoid outlined lettering for body text).
  ([page](https://gameaccessibilityguidelines.com/use-simple-clear-text-formatting/)). Standard.
- **G7. Roblox: respect the player's text size setting (`TextScaled` ignores it); pair colours with symbols; in shops
  grey out what can't be used, show unaffordable prices in red, make the best-value pick biggest; keep phone screens
  minimal.** Roblox Creator Docs ([UI/UX](https://create.roblox.com/docs/production/game-design/ui-ux-design),
  [adaptive](https://create.roblox.com/docs/production/publishing/adaptive-design)). Standard.
- **G8. About two thirds of Roblox daily users are 13 or older; about a third are under 13.** Roblox Q3 2025 earnings
  call ([transcript](https://s27.q4cdn.com/984876518/files/doc_financials/2025/q3/Q3-2025-Earnings-Conference-Call_Transcript.pdf)).
  Company data.
- **G9. During play, eyes stay near the centre of the screen; corner HUD is missed; motion pulls the eye most.**
  Sundstedt et al. 2013, review in *Game Analytics*
  ([PDF](https://www.cg.tuwien.ac.at/research/publications/2013/sundstedt-2013-vag/sundstedt-2013-vag-Paper.pdf)).
  Medium.
- **G10. Busy backgrounds make overlaid game items harder to find and use.** Caroux, Le Bigot & Vibert 2013,
  Ergonomics, three eye-tracking experiments ([doi](https://doi.org/10.1080/00140139.2013.847214), abstract only).
  Strong.
- **G11. A count shown as a number near the action beat rows of HUD icons (35% fewer wasted shots); health worked
  better on the HUD.** Peacocke et al. 2015 and 2018 ([2015](https://www.yorku.ca/mack/ieee_gem2015.html),
  [2018](https://www.yorku.ca/mack/ec2018.html)). Medium.
- **G12. Removing the HUD raised immersion only for expert players.** Iacovides et al. 2015, CHI PLAY
  ([doi](https://doi.org/10.1145/2793107.2793120), abstract only). Medium.
- **G13. Pushy buying design is common in kids' apps ("attractive lures" in 45%, time pressure 10 to 17%).** Radesky
  et al. 2022, JAMA Network Open, 160 children aged 3 to 5
  ([doi](https://doi.org/10.1001/jamanetworkopen.2022.17641), abstract only). Strong (younger children).

## What it says about this week's picks
- **Kraft brown circles (rejected):** brown is the least-liked colour family (C1), and its middle brightness
  contrasted with nothing (C7, L9).
- **Midnight indigo in the shop (rejected):** dark backings hide dark pieces (C7), and children link dark colours to
  bad feelings (C4).
- **Faded chalk green (Alan's pick for the shop):** middle brightness keeps white and black pieces visible (C7, L9);
  a cool, muted ground under warm, saturated parts matches what people like in figure-on-ground pairs (C2) and
  Valve's muted-ground, saturated-focus rule (G1).
- **The skill's old rules that had no backing:** 60-30-10 (C11), complementary pairs as harmony (C2 found no gain),
  F/Z reading patterns for game screens (L12). The rebuilt skill drops or relabels them.

## Gaps
No study of 8 to 16 year olds' colour taste in games; no research on how players read game shop screens; no text
contrast research with children; touch studies with children of our ages are small (16 in L4).

Back to [HOME](../HOME.md)
