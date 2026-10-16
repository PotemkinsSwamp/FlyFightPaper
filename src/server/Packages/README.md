# ProfileStore

Upstream: https://github.com/MadStudioRoblox/ProfileStore
Source revision: 45c9847cbcf1fc260369c50eb335aba7c35aecdd (retrieved 2026-10-07).
`ProfileStore.luau` is the unmodified official source. The adjacent LICENSE is its Apache 2.0 license.
API documentation: https://madstudioroblox.github.io/ProfileStore/api/

Game-specific settings live in config/server.json and ProfileRuntime. Do not patch the library
for game rules. Studio explicitly selects .Mock; live sessions require real DataStore access.
