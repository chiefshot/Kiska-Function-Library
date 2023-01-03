/* ----------------------------------------------------------------------------
Function: KISKA_fnc_GCH_dontExcludePlayerGroupDefault

Description:
	In order to maintain a player-group-is-not-excluded by default in the 
	 Group Changer, when a player joins the game, they will set their group
	 to be not excluded on all other machines and JIP

Parameters:
	NONE

Returns:
	NOTHING

Examples:
    (begin example)
		POST-INIT Function
    (end)

Author:
	Ansible2
---------------------------------------------------------------------------- */
scriptName "KISKA_fnc_GCH_dontExcludePlayerGroupDefault";

if !(hasInterface) exitWith {};

private _playerGroup = group player;
if (isNull _playerGroup) exitWith {};

if !([_playerGroup] call KISKA_fnc_GCH_isGroupExcluded) exitWith {};

// TODO: in a dedicated server load, this is probably too much of an assumption causing #142
// Suspect that when multiple players are in the same group during postinit, this will not run
// because everyone thinks the other player will have already taken care of init

// current setting of exclusion in the group 
// should be valid if a player is already in it
private _groupAlreadyHasPlayer = [_playerGroup] call KISKA_fnc_GCH_doesGroupHaveAnotherPlayer;
if (_groupAlreadyHasPlayer) exitWith {};


[_playerGroup,false,true] call KISKA_fnc_GCH_setGroupExcluded;


nil
