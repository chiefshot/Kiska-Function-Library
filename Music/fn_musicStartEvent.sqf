/* ----------------------------------------------------------------------------
Function: KISKA_fnc_musicStartEvent

Description:
	The function that should be activated when music starts playing.

Parameters:
	0: _trackClassname <STRING> - The classname of the track that started playing

Returns:
	NOTHING

Examples:
    (begin example)
		["trackThatStarted"] call KISKA_fnc_musicStartEvent;
    (end)

Author:
	Ansible2
---------------------------------------------------------------------------- */
scriptName "KISKA_fnc_musicStartEvent";

if (!hasInterface) exitWith {};

params [
	["_trackClassname","",[""]]
];

[["Started playing track: ", _trackClassname],false] call KISKA_fnc_log;

missionNamespace setVariable ["KISKA_musicPlaying",true];
missionNamespace setVariable ["KISKA_currentTrack",_trackClassName];
