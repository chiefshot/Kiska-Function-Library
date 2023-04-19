/* ----------------------------------------------------------------------------
Function: KISKA_fnc_convoyAdvanced_addVehicle

Description:
    Adds a given vehicle to a convoy.

Parameters:
    0: _vehicle <OBJECT> - The vehicle to add

Returns:
    NOTHING

Examples:
    (begin example)
        [vic] call KISKA_fnc_convoyAdvanced_removeVehicle;
    (end)

Author(s):
    Ansible2
---------------------------------------------------------------------------- */
scriptName "KISKA_fnc_convoyAdvanced_removeVehicle";

#define MAX_ARRAY_LENGTH 1E7

params [
    ["_vehicle",objNull,[objNull]]
];


if (isNull _vehicle) exitWith {
    ["_vehicle is null",false] call KISKA_fnc_log;
    nil
};

private _convoyHashMap = _vehicle getVariable "KISKA_convoyAdvanced_hashMap";
if (isNil "_convoyHashMap") exitWith {
    [[_vehicle," does not have a KISKA_convoyAdvanced_hashMap in its namespace"],true] call KISKA_fnc_log;
    nil
};



private _debugPathObjects = _vehicle getVariable ["KISKA_convoyAdvanced_debugPathObjects",[]];
_debugPathObjects apply {
    deleteVehicle _x;
};
private _debugDeletePathObjects = _vehicle getVariable ["KISKA_convoyAdvanced_debugDeletedPathObjects",[]];
_debugDeletePathObjects apply {
    deleteVehicle _x;
};


private _convoyVehicles = _convoyHashMap get "_convoyVehicles";
private _vehicleIndex = _vehicle getVariable "KISKA_convoyAdvanced_index";
_convoyVehicles deleteAt _vehicleIndex;

private _vehiclesToChangeIndex = _convoyVehicles select [_vehicleIndex,MAX_ARRAY_LENGTH];
_vehiclesToChangeIndex apply {
    private _currentIndex = _x getVariable ["KISKA_convoyAdvanced_index",-1];
    if (_currentIndex isEqualTo -1) then {
        [["Could not find 'KISKA_convoyAdvanced_index' in namespace of ", _x," to change"],true] call KISKA_fnc_log;
        continue
    };

    private _newIndex = _currentIndex - 1;
    _convoyHashMap set [_newIndex,_x];
    _x setVariable ["KISKA_convoyAdvanced_index",_newIndex];
};


(driver _vehicle) enableAI "path";
_vehicle limitSpeed -1;

if ((speed _vehicle) > 0) then {
    _vehicle move (getPosATLVisual _vehicle);
};


[
    "KISKA_convoyAdvanced_isStopped",
    "KISKA_convoyAdvanced_drivePath",
    "KISKA_convoyAdvanced_debugPathObjects",
    "KISKA_convoyAdvanced_debug",
    "KISKA_convoyAdvanced_hashMap",
    "KISKA_convoyAdvanced_index",
    "KISKA_convoyAdvanced_debugMarkerType_deletedPoint",
    "KISKA_convoyAdvanced_debugMarkerType_queuedPoint",
    "KISKA_convoyAdvanced_queuedPoint",
    "KISKA_convoyAdvanced_debugDeletedPathObjects",
    "KISKA_convoyAdvanced_seperation"
] apply {
    _vehicle setVariable [_x,nil];
};