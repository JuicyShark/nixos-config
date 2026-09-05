# Steam Games

Type `/steam` in Noctalia's launcher to search the games installed across all
Steam library folders. Selecting a result launches it with
`steam -applaunch <appid>`.

The provider reads Steam's local `libraryfolders.vdf` and `appmanifest_*.acf`
files. It does not use the network or modify Steam data. Proton, Steam Linux
Runtime, and Steamworks redistributable manifests are excluded from results.
