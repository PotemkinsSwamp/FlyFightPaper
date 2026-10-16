# South monorail station review

Built and inspected against approved concept E on 2026-10-16.

Three build/review rounds: the first established the tunnel and six open windows; the second removed shadow patches from the front enamel; the third aligned front/back texture coordinates after the rear inspection showed a stripe.

Inspected compare.png, front/three-quarter, both end-on opening views, the rear long-face view, and all final colour, normal and roughness contact sheets. The main view shows the left end aperture and the three front windows. The rear view shows all three back windows and the hinges above them.

Pieces: 30; triangles: 33692. Maximum per piece: 4016 of the 12000 limit. Lowest front density: 7.3 pixels/stud; lowest across all outer sides: 7.28 (minimum 6).

Comparison: [compare.png](compare.png). Measurements and width sums: [sizes.md](sizes.md). Build output: [build.log](build.log).

| Piece | Triangles | front_pixels_per_stud |
|---|---:|---:|
| 1-left-toy-leg-course-1 | 1868 | 7.978 |
| 2-left-toy-leg-course-2 | 324 | 7.984 |
| 3-left-toy-leg-course-3 | 324 | 7.984 |
| 4-left-toy-leg-course-4 | 864 | 7.983 |
| 5-left-toy-leg-course-5 | 3732 | 7.898 |
| 6-right-toy-leg-course-1 | 864 | 7.983 |
| 7-right-toy-leg-course-2 | 324 | 7.984 |
| 8-right-toy-leg-course-3 | 324 | 7.984 |
| 9-right-toy-leg-course-4 | 864 | 7.983 |
| 10-right-toy-leg-course-5 | 3732 | 7.898 |
| 11-rounded-red-lunch-tin-half-1 | 652 | 7.792 |
| 12-rounded-red-lunch-tin-half-2 | 652 | 7.792 |
| 13-rounded-bottom-tin-rim-1 | 76 | 7.765 |
| 14-rounded-bottom-tin-rim-2 | 76 | 7.765 |
| 15-deep-lunch-tin-lid-1 | 556 | 7.573 |
| 16-deep-lunch-tin-lid-2 | 556 | 7.573 |
| 17-rolled-tin-rim-82-1 | 860 | 7.3 |
| 18-rolled-tin-rim-82-2 | 860 | 7.3 |
| 19-rolled-tin-rim-143.3-1 | 860 | 7.3 |
| 20-rolled-tin-rim-143.3-2 | 860 | 7.3 |
| 21-rolled-tin-rim-149.2-1 | 860 | 7.3 |
| 22-rolled-tin-rim-149.2-2 | 860 | 7.3 |
| 23-metal-lined-open-track-tunnel | 4016 | 7.968 |
| 24-front-open-long-window--52 | 864 | 7.94 |
| 25-front-open-long-window-0 | 864 | 7.94 |
| 26-front-open-long-window-52 | 864 | 7.94 |
| 27-back-open-long-window--52 | 864 | None |
| 28-back-open-long-window-0 | 864 | None |
| 29-back-open-long-window-52 | 864 | None |
| 30-real-hinges-and-closing-clasps | 3544 | 7.857 |

All builder checks passed with Blender exit 0: closed manifold shells, positive volume, no loose vertices or duplicate triangles, triangle limits, at least 6 pixels/stud on every outer side, 1024 RGB PBR maps, per-piece FBX re-import and dimensions/UVs, exact 150 height, unchanged concept bytes, and exact comparison image halves.

The road through Y, tunnel through X, and three aligned front/back window pairs each passed all 1250 rays. No tunnel grid samples were skipped by the axis-x shape form. A separate saved-scene check confirmed the red piers/end margins still exist and rays .01 inside the tunnel boundaries are clear.

Ran fill_gaps.py in real-UV mode on all 90 external maps, then checked every protected texel against the originals. Windows blocked direct overwrites, so the same tool filled temporary copies which were verified and atomically replaced. The packed scene retains the builder's maps; protected island pixels and their three-pixel bleed are identical. Refreshed all texture contact sheets and inspected them.

Remaining differences: The station-only export has no train, track beam, road, curb or grey leg plinths. Those picture elements are outside this rebuild. Metal is cleaner and cooler than the concept, the cream trim has squarer corners, and the retained leg windows are opaque blue with smaller frames. Brick colours are less saturated in the studio lighting.

Only the south station function and its camera/opening entries changed in blocks.py. No uploads, Studio actions or commits.
