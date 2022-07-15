// Works with agents
// Is able to take an animation map as a parameter
// Is able to convert a config into an animation map
// User can provide an array of desired animation sets to randomly (weighted too) select from
// User can define whther or not unit should exit animationwhile in combat
// user can define a function to activate when unit enters combat
// user can define a callback function that fires when the unit enters the animation
// user can manually terminate the animation
// attempts to not play the same animation twice within the same general area
// user can define levels of gear to remove from the unit

// handle remote units being passed


// TODO properties in map that can be object that units can get attached to and the relative coordinates needed
//  to do so with setPosWorld

// TODO: play animation function
// TODO: terminate animations function
// TODO: can interpolate property in animation set

params [
    ["_units",objNull,[[],objNull]],
    ["_animationMap",configNull,[createHashMap,configNull]],
    ["_animSet","",["",[]]],
    ["_equipmentLevel","",["",[]]],
    ["_onAnimate",{},[{},[],""]]
];

/* ----------------------------------------------------------------------------

    Verify params

---------------------------------------------------------------------------- */
if (_units isEqualTo []) exitWith {
    ["Empty _units array passed!", true] call KISKA_fnc_log;
    nil
};

private _isObject = _units isEqualType objNull;
if (_isObject AND {isNull _units}) exitWith {
    ["Null unit passed", true] call KISKA_fnc_log;
    nil
};

if (_isObject) then {
    _units = [_units];
};

private _animationMapIsConfig = _animationMap isEqualType configNull;
if (_animationMapIsConfig AND {isNull _animationMap}) exitWith {
    ["_animationMap is null config!", true] call KISKA_fnc_log;
    nil
};

if (_animationMapIsConfig) then {
    _animationMap = [_animationMap] call KISKA_fnc_ambientAnim_createMapFromConfig;
};

/*
JSON rep of map
{
    someAnimSet: {
        animations: [
            "anim1",
            "anim2"
        ],
        allowedGear: [
            "full",
            "light",
            "medium"
        ],
        unarmed: true,
        forceHolster: true,
        interpolate: true // means animations will be played in a sequence
    }
}
*/

private _randomAnimSet = _animset isEqualType [];
private _randomEquipmentLevel = _equipmentLevel isEqualType [];

/* ----------------------------------------------------------------------------

    Apply Animations

---------------------------------------------------------------------------- */
_units apply {
    private _unit = _x;
    if !(alive _unit) then {
        continue;
    };

    private _unitInfoMap = createHashmap;

    /* --------------------------------------
        Get Animation Set Info
    -------------------------------------- */
    private _animSetSelection = _animset;
    if (_randomAnimSet) then {
        _animSetSelection = [_animSet,""] call KISKA_fnc_selectRandom;
    };
    private _animationSetInfo = _animationMap getOrDefault [_animSetSelection,[]];
    if (_animationSetInfo isEqualTo []) then {
        [["Empty animation set provided: ", _animSetSelection], true] call KISKA_fnc_log;
        continue;
    };
    _unitInfoMap set ["_animationSetInfo",_animationSetInfo];


    /* --------------------------------------
        Handle Equipment
    -------------------------------------- */
    private _unitLoadout = getUnitLoadout _unit;
    _unitInfoMap set ["_unitLoadout",_unitLoadout];

    private _removeWeapons = _animationSetInfo getOrDefault ["removeWeapons",false];
    if (_removeWeapons) then {
        removeAllWeapons _unit;
    };

    private _removeNightVision = _animationSetInfo getOrDefault ["removeNightVison",false];
    if (_removeNightVision) then {
        removeAllAssignedItems _unit;
    };

    private _equipmentLevelSelection = _equipmentLevel;
    if (_randomEquipmentLevel) then {
        _equipmentLevelSelection = [_equipmentLevel,""] call KISKA_fnc_selectRandom;
    };
    switch (_equipmentLevelSelection) do
    {
        case "NONE":
        {
            removeGoggles _unit;
            removeHeadgear _unit;
            removeVest _unit;
            removeAllWeapons _unit;
            removeBackpack _unit;
        };
        case "LIGHT":
        {
            removeGoggles _unit;
            removeHeadgear _unit;
            removeVest _unit;
            removeBackpack _unit;
        };
        case "MEDIUM":
        {
            removeGoggles _unit;
            removeHeadgear _unit;
        };
        case "FULL":
        {
            removeGoggles _unit;
        };
        default
        {
        };
    };


    private _isAgent = isAgent (teamMember _unit);
    if !(_isAgent) then {
        ["ANIM","AUTOTARGET","FSM","MOVE","TARGET"] apply {
            _unit disableAI _x;
        };
    };

    detach _unit;

    private _nearUnits = _unit nearEntities ["man", 5];
    _unitInfoMap set ["_nearUnits",_nearUnits];


    /* --------------------------------------
        Add Eventhandlers
    -------------------------------------- */
    private _animDoneEventHandlerId = _unit addEventHandler ["AnimDone",
        {
            params ["_unit","_anim"];

            if (alive _unit) then {
                _this call KISKA_fnc_ambientAnim_play;

            } else {
                [_unit] call KISKA_fnc_ambientAnim_terminate;

            };
        }
    ];
    _unitInfoMap set ["_animDoneEventHandlerId",_animDoneEventHandlerId];


    private _unitKilledEventHandlerId = _unit addEventHandler ["KILLED",
        {
            params ["_unit"];
            [_unit] call KISKA_fnc_ambientAnim_terminate;
        }
    ];
    _unitInfoMap set ["_unitKilledEventHandlerId",_unitKilledEventHandlerId];



    _unit setVariable ["KISKA_ambientAnimMap",_unitInfoMap];
};


nil
