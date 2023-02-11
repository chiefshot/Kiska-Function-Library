scriptName "KISKA_fnc_convoyAdvanced_create";

#define CLEARANCE_TO_QUEUED_POINT 0.5
#define SPEED_LIMIT_MODIFIER 10
#define POINT_COMPLETE_RADIUS 10
#define MIN_VEHICLE_SPEED_LIMIT_MODIFIER 5
#define MIN_VEHICLE_SPEED_LIMIT 5
#define VEHICLE_SPEED_LIMIT_MULTIPLIER 2.5
#define SMALL_SPEED_LIMIT_DISTANCE_MODIFIER 1.25
#define FOLLOW_VEHICLE_MAX_SPEED_TO_HALT 5
#define LEAD_VEHICLE_MAX_SPEED_TO_HALT_FOLLOW 2
#define VEHICLE_SHOULD_CATCH_UP_DISTANCE 100
#define SPEED_DIFFERENTIAL_LIMIT 20

params [
	["_vics",[],[[]]],
    ["_convoySeperation",20,[123]]
];

if (_convoySeperation < 10) then {
    _convoySeperation = 10;
};

private _stateMachine = [
    _vics,
    true
] call CBA_stateMachine_fnc_create;


private _convoyHashMap = createHashMap;
_convoyHashMap set ["_stateMachine",_stateMachine];
_convoyHashMap set ["_minBufferBetweenPoints",1];
_convoyHashMap set ["_convoySeperation",_convoySeperation];

_vics apply {
    [
        _convoyHashMap,
        _x
    ] call KISKA_fnc_convoyAdvanced_addVehicle;
};


private _onEachFrame = {
    private _currentVehicle = _this;

    private _convoyHashMap = _currentVehicle getVariable "KISKA_convoyAdvanced_hashMap";
    private _convoyLead = _convoyHashMap get "_convoyLead";
    // private _stateMachine = _convoyHashMap get "_stateMachine";

    if (_currentVehicle isEqualTo _convoyLead) exitWith {};


	/* ----------------------------------------------------------------------------
        Setup
    ---------------------------------------------------------------------------- */
    private _debug = _currentVehicle getVariable ["KISKA_convoyAdvanced_debug",true];
    private "_currentVehicle_debugDrivePathObjects";
    if (_debug) then {
        _currentVehicle_debugDrivePathObjects = _currentVehicle getVariable "KISKA_convoyAdvanced_debugPathObjects";
    };

    private _currentVehicle_drivePath = _currentVehicle getVariable "KISKA_convoyAdvanced_drivePath";
    if (isNil "_currentVehicle_drivePath") then {
        _currentVehicle_drivePath = [];
        _currentVehicle setVariable ["KISKA_convoyAdvanced_drivePath",_currentVehicle_drivePath];

        if (_debug) then {
            _currentVehicle_debugDrivePathObjects = [];
            _currentVehicle setVariable ["KISKA_convoyAdvanced_debugPathObjects",_currentVehicle_debugDrivePathObjects];
        };
    };


    private _continue = false;
    /* ----------------------------------------------------------------------------
        Handle speed
    ---------------------------------------------------------------------------- */
    private _currentVehicle_index = _currentVehicle getVariable "KISKA_convoyAdvanced_index";
    private _vehicleAhead = _convoyHashMap get (_currentVehicle_index - 1);

    private _currentVehicle_frontBumperPosition = [_currentVehicle,false] call KISKA_fnc_convoyAdvanced_getBumperPosition;
    private _vehicleAhead_rearBumperPosition = [_vehicleAhead,true] call KISKA_fnc_convoyAdvanced_getBumperPosition;
    private _distanceBetweenVehicles = _currentVehicle_frontBumperPosition vectorDistance _vehicleAhead_rearBumperPosition;

    private _vehicleAhead_speed = speed _vehicleAhead;
    private _convoySeperation = _convoyHashMap get "_convoySeperation";
    private _vehiclesAreWithinBoundary = _distanceBetweenVehicles < _convoySeperation;

    private _currentVehicle_isStopped = _currentVehicle getVariable ["KISKA_convoyAdvanced_isStopped",false];
    private _vehicleAhead_isStopped = _vehicleAhead_speed <= LEAD_VEHICLE_MAX_SPEED_TO_HALT_FOLLOW;
    private _currentVehicle_shouldBeStopped = _vehicleAhead_isStopped AND _vehiclesAreWithinBoundary;

    if (_currentVehicle_isStopped) then {
        if (_currentVehicle_shouldBeStopped) exitWith { _continue = true; };
        
        _currentVehicle setVariable ["KISKA_convoyAdvanced_isStopped",false];
        private _currentVehicle_driver = driver _currentVehicle;
        if !(_currentVehicle_driver checkAIFeature "path") then {
            _currentVehicle_driver enableAI "path";
        };
        
    } else {
        if !(_currentVehicle_shouldBeStopped) exitWith {};
            
        if (_debug) then {
            private _currentVehicle_speed = speed _currentVehicle;
            hint str ["In Halt",_currentVehicle_speed,_distanceBetweenVehicles];
        };

        _currentVehicle setVariable ["KISKA_convoyAdvanced_isStopped",true];
        [_currentVehicle] call KISKA_fnc_convoyAdvanced_stopVehicle;

        _continue = true;
    };

    if (_continue) exitWith {};


    /* ---------------------------------
        Force speed based on distance
    --------------------------------- */
    private _currentVehicle_speed = speed _currentVehicle;
    if (_vehiclesAreWithinBoundary) then {
        private _modifier = ((_convoySeperation - _distanceBetweenVehicles) * VEHICLE_SPEED_LIMIT_MULTIPLIER) max MIN_VEHICLE_SPEED_LIMIT_MODIFIER;
        private _speedLimit = (_vehicleAhead_speed - _modifier) max MIN_VEHICLE_SPEED_LIMIT;
        // forceSpeed seems to do nothing, using limit instead
        _currentVehicle limitSpeed _speedLimit;
        
        if (_debug) then {
            hint ([
                "limit speed",endl,
                "Current Vehicle Speed: ", _currentVehicle_speed, endl,
                "Current Speed Limit: ", _speedLimit, endl,
                "Distance between: ", _distanceBetweenVehicles
            ] joinString "");
        };

    } else {
        private _distanceToLimitToVehicleAheadSpeed = _convoySeperation * SMALL_SPEED_LIMIT_DISTANCE_MODIFIER;
        if (_distanceBetweenVehicles < _distanceToLimitToVehicleAheadSpeed) exitWith {
            if (_debug) then {
                hint "un limit small";
            };

            private _speedToLimitTo = [_vehicleAhead_speed,5] select _vehicleAhead_isStopped;
            _currentVehicle limitSpeed _speedToLimitTo;
        };

        if (_distanceBetweenVehicles > VEHICLE_SHOULD_CATCH_UP_DISTANCE) exitWith { 
            if (_debug) then {
                hint "un limit";
            };
            _currentVehicle limitSpeed -1 
        };
        
        private _speedDifferential = abs (_currentVehicle_speed - _vehicleAhead_speed);
        if (_speedDifferential > SPEED_DIFFERENTIAL_LIMIT) exitWith {
            if (_debug) then {
                hint str ["Limit by differential",_currentVehicle_speed,_distanceBetweenVehicles];
            };

            _currentVehicle limitSpeed _distanceBetweenVehicles;
        };
        
        if (_debug) then {
            hint str ["un limit generic",_distanceBetweenVehicles];
        };
        _currentVehicle limitSpeed -1;
    };


    /* ----------------------------------------------------------------------------
        Delete old points
    ---------------------------------------------------------------------------- */
    private _currentVehicle_position = getPosATLVisual _currentVehicle;
    private _deleteStartIndex = -1;
    private _numberToDelete = 0;
    {
        private _pointReached = (_currentVehicle_position vectorDistance _x) <= POINT_COMPLETE_RADIUS;

        if !(_pointReached) then { break };
        _numberToDelete = _numberToDelete + 1;

        private _deleteStartIndexDefined = _deleteStartIndex isNotEqualTo -1;
        if (_deleteStartIndexDefined) then { continue };
        _deleteStartIndex = _forEachIndex;

    } forEach _currentVehicle_drivePath;
    
    private _pointsCanBeDeleted = (_deleteStartIndex >= 0) AND (_numberToDelete > 0);
    if (_pointsCanBeDeleted) then {
        _currentVehicle_drivePath deleteRange [_deleteStartIndex,_numberToDelete];

        if (_debug) then {
            private _lastIndexToDelete = _deleteStartIndex + (_numberToDelete - 1);
            private _debugObjectType = _currentVehicle getVariable ["KISKA_convoyAdvanced_debugMarkerType_deletedPoint","Sign_Arrow_Large_blue_F"];
            createVehicle [_debugObjectType, _currentVehicle_position, [], 0, "CAN_COLLIDE"];
            for "_i" from _deleteStartIndex to _lastIndexToDelete do { 
                deleteVehicle (_currentVehicle_debugDrivePathObjects select _i);
            };
            _currentVehicle_debugDrivePathObjects deleteRange [_deleteStartIndex,_numberToDelete];
        };
    };


    /* ----------------------------------------------------------------------------
        create new from queued point
    ---------------------------------------------------------------------------- */
    private _queuedPoint = _currentVehicle getVariable "KISKA_convoyAdvanced_queuedPoint";
    if !(isNil "_queuedPoint") exitWith {
        _currentVehicle setVariable ["KISKA_convoyAdvanced_queuedPoint",nil];
        
        if (_debug) then {
            private _debugObjectType = _currentVehicle getVariable ["KISKA_convoyAdvanced_debugMarkerType_queuedPoint","Sign_Arrow_Large_Cyan_F"];
            private _debugObject = createVehicle ["Sign_Arrow_Large_Cyan_F", _queuedPoint, [], 0, "CAN_COLLIDE"];
            _currentVehicle_debugDrivePathObjects pushBack _debugObject;
        };

        private _indexInserted = _currentVehicle_drivePath pushBack _queuedPoint;
        // vehicle need at least two points for setDriveOnPath to work
        if (_indexInserted >= 1) then {
            _currentVehicle setDriveOnPath _currentVehicle_drivePath;
        };
    };


    /* ----------------------------------------------------------------------------
        Add Queued point if needed
    ---------------------------------------------------------------------------- */
    // private _currentVehicle_lastQueuedTime = _currentVehicle getVariable ["KISKA_convoy_queuedTime",-1];
    // private _pointHasBeenQueued = _currentVehicle_lastQueuedTime isNotEqualTo -1;
    // private _updateFrequency = 0;
    // private _time = time;
    // if (
    //     _pointHasBeenQueued AND 
    //     !((_time - _currentVehicle_lastQueuedTime) >= _updateFrequency)
    // ) exitWith {};

    // _currentVehicle setVariable ["KISKA_convoy_queuedTime",_time];



    /* ----------------------------------------------------------------------------
        Only Queue points that aren't too close together
    ---------------------------------------------------------------------------- */
    private _convoyLeadPosition = getPosATLVisual _convoyLead;
    private _lastestPointToDriveTo = [_currentVehicle_drivePath] call KISKA_fnc_selectLastIndex;
    if (isNil "_lastestPointToDriveTo") exitWith {
        _currentVehicle setVariable ["KISKA_convoyAdvanced_queuedPoint",_convoyLeadPosition];
    };

    private _vehicleAhead_distanceToLastDrivePoint = _convoyLeadPosition vectorDistance _lastestPointToDriveTo;
    private _minBufferBetweenPoints = 1;
    if (_vehicleAhead_distanceToLastDrivePoint <= _minBufferBetweenPoints) exitWith {};
    
    _currentVehicle setVariable ["KISKA_convoyAdvanced_queuedPoint",_convoyLeadPosition];
};


private _mainState = [
    _stateMachine,
    _onEachFrame
] call CBA_stateMachine_fnc_addState;


_convoyHashMap
