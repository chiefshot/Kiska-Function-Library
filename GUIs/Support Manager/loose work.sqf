#include "Support Manager Common Defines.hpp"
#define TO_STRING(NAME_OF) #NAME_OF
#define POOL_GVAR KISKA_SM_pool


KISKA_fnc_supportManager_onLoad = {
	params ["_display"];
	uiNamespace setVariable ["KISKA_sm_display",_display];
	
	uiNamespace setVariable ["KISKA_SM_poolListBox_ctrl",_display displayCtrl SM_POOL_LISTBOX_IDC];
	[_display] spawn KISKA_fnc_supportManager_onLoad_supportPool;

	uiNamespace setVariable ["KISKA_SM_currentListBox_ctrl",_display displayCtrl SM_CURRENT_LISTBOX_IDC];
	[_display] call KISKA_fnc_supportManager_updateCurrentList;

	[_display] call KISKA_fnc_supportManager_onLoad_buttons;

	_display displayAddEventHandler ["unload",{
		uiNamespace setVariable ["KISKA_sm_display",nil];
		uiNamespace setVariable ["KISKA_SM_poolListBox_ctrl",nil];
		uiNamespace setVariable ["KISKA_SM_currentListBox_ctrl",nil];
	}];
};

KISKA_fnc_supportManager_onLoad_supportPool = {
	params ["_display"];
	
	private _poolControl = uiNamespace getVariable "KISKA_SM_poolListBox_ctrl";
	_poolControl ctrlAddEventHandler ["LBSelChanged",{
		params ["_control", "_selectedIndex"];
		hint str (_control lbValue _selectedIndex);
	}];

	// init to empty array if undefined to allow comparisons
	if (isNil TO_STRING(POOL_GVAR)) then {
		missionNamespace setVariable [TO_STRING(POOL_GVAR),[]];
	};

	private _fn_updateSupportPoolList = {
		
		if (POOL_GVAR isEqualTo []) exitWith {
			lbClear _poolControl;
		};

		// subtracting 1 from these to used the number of array indexes
		private _countOfDisplayed = (count _supportPool_displayed) - 1;
		private _countOfCurrent = (count POOL_GVAR) - 1;
		
		private _configHash = createHashMap;

		private ["_displayText","_comparedIndex","_config","_comMenuClass","_path","_toolTip"];
		private _fn_setText = {
			if (_comMenuClass in _configHash) then {
				_config = _configHash get _comMenuClass;
			} else {
				_config = [["CfgCommunicationMenu",_comMenuClass]] call KISKA_fnc_findConfigAny;
				_configHash set [_comMenuClass,_config];
			};	

			_displayText = getText(_config >> "text");
			_toolTip = getText(_config >> "tooltip"); 
		};
		private _fn_adjustCurrentEntry = {
			// entries that are arrays will be ["classname",NumberOfUsesLeft]
			// some supports have multiple uses in them, this keeps track of that if someone stores a
			// multi-use one after having already used it.
			if (_comMenuClass isEqualType []) then {
				_poolControl lbSetValue [_path,(_comMenuClass select 1)];
				_comMenuClass = (_comMenuClass select 0);
			} else {
				// set to default value of zero if entry was not already there
				if ((_poolControl lbValue _path) isNotEqualTo 0) then {
					_poolControl lbSetValue [_path,0];
				};
			};
			_poolControl lbSetData [_path,_comMenuClass];
			call _fn_setText;
			_poolControl lbSetTooltip [_path,_toolTip];
			_poolControl lbSetText [_path,_displayText];
		};

		{	
			_comMenuClass = _x;
			// instead of clearing the list, we will change entries up until there are more entries in the array then currently in the list
			if (_countOfDisplayed >= _forEachIndex) then {			
				// check if entry at index is different and therefore needs to be changed
				_comparedIndex = _supportPool_displayed select _forEachIndex;
				if (_comMenuClass isNotEqualTo _comparedIndex) then {
					_path = _forEachIndex;
					call _fn_adjustCurrentEntry;
				};
			} else {
				_path = _poolControl lbAdd "";
				call _fn_adjustCurrentEntry;
			};
		} forEach POOL_GVAR;	
	};
	
	private _supportPool_displayed = [];	
	while {sleep 0.5; !(isNull _display)} do {

		// support pool check
		if (_supportPool_displayed isNotEqualTo POOL_GVAR) then {		
			call _fn_updateSupportPoolList;
			_supportPool_displayed = +POOL_GVAR;
		};

	};
};

KISKA_fnc_supportManager_onLoad_buttons = {
	params ["_display"];
//[["DATALINK",1.1,[0.75,0,0,1]],_message,false] call CBA_fnc_notify;
	(_display displayCtrl SM_TAKE_BUTTON_IDC) ctrlAddEventHandler ["ButtonClick",{
		params ["_control"];
		// make sure to also get the number of uses a support has (assuming it was used) and pass that param
		// use a hash with ids
	}];

	(_display displayCtrl SM_STORE_BUTTON_IDC) ctrlAddEventHandler ["ButtonClick",{
		params ["_control"];
		// need to figure out a way to get the number of uses a support has left
	}];

	(_display displayCtrl SM_CLOSE_BUTTON_IDC) ctrlAddEventHandler ["ButtonClick",{
		params ["_control"];
		//hint ""; // get rid of hints
		(uiNamespace getVariable "KISKA_sm_display") closeDisplay 2;
	}];
};

KISKA_fnc_supportManager_take_buttonClickEvent = {

};

KISKA_fnc_supportManager_updateCurrentList = {

};




[[1,"Test Heli CAS","","[bis_o1,1] call bis_fnc_removeCommMenuItem;_this = [bis_o1,_pos,_target,_is3D,1];[""KISKA_testHeliCAS"",_this,-1] call KISKA_fnc_callingForSupportMaster","cursorOnGround","","\a3\Ui_f\data\GUI\Cfg\CommunicationMenu\call_ca.paa",""]]