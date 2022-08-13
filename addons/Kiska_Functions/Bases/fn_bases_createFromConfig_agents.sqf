/* ----------------------------------------------------------------------------
Function: KISKA_fnc_bases_createFromConfig_agents

Description:
	Spawns a configed KISKA bases' agents.

Parameters:
    0: _baseConfig <CONFIG> - The config path of the base config

Returns:
    <HASHMAP> - see KISKA_fnc_bases_getHashmap

Examples:
    (begin example)
		[
            "SomeBaseConfig"
        ] call KISKA_fnc_bases_createFromConfig_agents;
    (end)

Author:
	Ansible2
---------------------------------------------------------------------------- */
scriptName "KISKA_fnc_bases_createFromConfig_agents";

params [
    ["_baseConfig",configNull,["",configNull]]
];


if (_baseConfig isEqualType "") then {
    _baseConfig = missionConfigFile >> "KISKA_Bases" >> _baseConfig;
};
if (isNull _baseConfig) exitWith {
    [[_baseConfig, " is a null config path"],true] call KISKA_fnc_log;
    []
};


private _baseMap = [_baseConfig] call KISKA_fnc_bases_getHashmap;
private _base_agentsList = _baseMap get "agent list";

private _agentsConfig = _baseConfig >> "agents";
private _agentClasses = configProperties [_agentsConfig,"isClass _x"];


/* ----------------------------------------------------------------------------

    Create Agents

---------------------------------------------------------------------------- */
_agentClasses apply {
    private _classConfig = _x;
    private _spawnPositions = (_classConfig >> "positions" ) call BIS_fnc_getCfgData;
    if (_spawnPositions isEqualType "") then {
        _spawnPositions = [_spawnPositions] call KISKA_fnc_getMissionLayerObjects;
    };

    if (_spawnPositions isEqualTo []) then {
        [["Could not find spawn positions for KISKA bases class: ",_x],true] call KISKA_fnc_log;
        continue;
    };

    private _unitClasses = [[_x,_baseConfig,_agentsConfig]] call KISKA_fnc_bases_getInfantryClasses;

    private _numberOfAgents = getNumber(_classConfig >> "numberOfAgents");
    private _numberOfSpawns = count _spawnPositions;
    if (_numberOfSpawns < _numberOfAgents OR (_numberOfAgents isEqualTo -1)) then {
        _numberOfAgents = _numberOfSpawns;
    };

    _spawnPositions = [_spawnPositions] call CBA_fnc_shuffle;
    private _agents = [];

    private _placement = "CAN_COLLIDE";
    private _placementConfigValue = getText(_x >> "placement");
    if (_placementConfigValue isNotEqualTo "") then {
        _placement = _placementConfigValue;
    };

    private _enableDynamicSim = [_classConfig >> "dynamicSim"] call BIS_fnc_getCfgDataBool;

    for "_i" from 0 to (_numberOfAgents - 1) do {
        private _spawnPosition = _spawnPositions select _i;
        private _direction = 0;
        if (_spawnPosition isEqualType objNull) then {
            _direction = getDir _spawnPosition;
        };
        if (_spawnPosition isEqualType [] AND {count _spawnPosition > 3}) then {
            _direction = _spawnPosition deleteAt 3;
        };

        private _agent = createAgent [
            selectRandom _unitClasses,
            _spawnPosition,
            [],
            0,
            _placement
        ];

        _agent enableDynamicSimulation _enableDynamicSim;
        _agent setDir _direction;
        _agents pushBack _agent;
    };

    /* -------------------------------------------
        Animate Class
    ------------------------------------------- */
    private _animateClass = _classConfig >> "ambientAnim";
    if !(isNull _animateClass) then {
        private _animationSet = (_animateClass >> "animationSet") call BIS_fnc_getCfgData;
        private _equipmentLevel = (_animateClass >> "equipmentLevel") call BIS_fnc_getCfgData;
        if (isNil "_equipmentLevel") then {
            _equipmentLevel = "";
        };

        private _snapToRange = getNumber(_animateClass >> "snapToRange");
        if (_snapToRange isEqualTo 0) then {
            _snapToRange = 5;
        };
        private _combat = [_animateClass >> "exitOnCombat"] call BIS_fnc_getCfgDataBool;
        private _fallbackFunction = getText(_animateClass >> "fallbackFunction");

        private _args = [
            _agents,
            _animationSet,
            _combat,
            _equipmentLevel,
            _snapToRange,
            _fallbackFunction
        ];

        private _getAnimationMapFunction = getText(_animateClass >> "getAnimationMapFunction");
        if (_getAnimationMapFunction isNotEqualTo "") then {
            private _animationMap = [[],_getAnimationMapFunction] call KISKA_fnc_callBack;
            _args pushBack _animationMap;
        };

        _args call KISKA_fnc_ambientAnim;
    };


    private _onAgentsCreated = getText(_classConfig >> "onAgentsCreated");
    if (_onAgentsCreated isNotEqualTo "") then {
        _onAgentsCreated = compile _onAgentsCreated;
        [
            _onAgentsCreated,
            [_agents]
        ] call CBA_fnc_directCall;
    };

    _base_agentsList append _agents;
};


_baseMap
