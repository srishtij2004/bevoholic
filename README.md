
Contributions:

Likhita (25%) - 
Beta: Implemented custom avatars from settings/profile page, users can choose a Bevo with a unique hat and save their preferences and this will be their avatar across the whole game. Implemented basic UI for the Cards Against Longhorns game and basic game state logic added to WaitingVC, only the admin can control when everyone starts voting in this specific game.
Alpha: UI for dare screen on drink or dare game and nav header bar. Upload photo functionality and backend logic to only allow complete dare once a photo has been uploaded. Updated labels on dare screen according to game/dare mode and fixed settings page to have a consistent avatar cell which is used for the lobby screen table (will add to leaderboard next).

Srishti (25%) -
Beta Release: Implemented basic UI for the Imposter game, which is a 3+ player game where each player is shown a word and one player is assigned the imposter. When ready to guess players can move on to the voting screen where they unanimously vote for who they think the imposter is. If the imposter is caught then they are told to take a shot or else everyone else drinks. (Added logic for this game flow to ImposterGameViewController and ImposterGameManager). Also updated imposter word bank with UT themed categories and words. 
Alpha Release: Created the UI for the waiting and leaderboard screens for the Drink or Dare game Backend logic for drink or dare game including points system, game modes, game locations, waiting and leaderboard logic, dare banks, game routing.

Rohith (25%) -
Working on backend for imposter game. Was previously working but needed to change after changes to UI. 
Created UI for Launch Screen, Login screen and settings screen
Made login functionality and the ability for users to set usernames so that they can change the name that displays in game from their email to whatever they want
Fixed gamestate syncing between different people playing

Srilekha (25%)
	Beta: 
Fixed the round logic so players can play multiple rounds without the game getting stuck.
Built the system that calculates who won the round and handles tiebreakers if players have the same number of votes.
Created the winner screen to automatically pull the correct names and profile pictures from the database.
Connected the game screens together so everyone moves from the winner screen back to a new prompt at the same time (simultaneous prompts)
Added a game instructions screen to explain each game
	Alpha: 
Created UI for Home Screen and Lobby Screen
Added logic functionality to joining and creating game via access code 
Added functionality for a dynamic waiting lobby allowing for multiple players to view their usernames and avatar icons

Deviations:
We did not have time to figure out the map's implementation for drink or dare but did add the placeholder button for this feature. Creating both games and fixing these bugs took longer than expected. This will be implemented in the final release.
The UI will be more polished for our final release, however we have tried our best to keep everything consistent. Some screens still need constraints and minor UI changes.
Most functionality is complete and we are on track to finish for the final deadline


Sample Login:

Username: player1@gmail.com
Username: player2@gmail.com
Password for both: player123

Create a game on one device and save game code 
Use this game code to join on other device 

