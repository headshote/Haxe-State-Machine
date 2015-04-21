package stateMachine;

import flash.utils.Dictionary; 
import openfl.events.EventDispatcher;

class StateMachine extends EventDispatcher
{
	public var id:String;
	/* @private */
	private var _state:String;
	/* @private */
	public var states(get, null):Map<String, State>;
	/* @private */
	private var _outEvent:StateMachineEvent;
	/* @private */
	private var parentState:State;
	/* @private */
	private var parentStates:Array<State>;
	/* @private */
	private var path:Array<Int>;
	
	/**
	 * Creates a generic StateMachine. Available states can be set with addState and initial state can
	 * be set using initialState setter.
	 * @example This sample creates a state machine for a player model with 3 states (Playing, paused and stopped)
	 * <pre>
	 *	playerSM = new StateMachine();
	 *
	 *	playerSM.addState("playing",{ enter: onPlayingEnter, exit: onPlayingExit, from:["paused","stopped"] });
	 *	playerSM.addState("paused",{ enter: onPausedEnter, from:"playing"});
	 *	playerSM.addState("stopped",{ enter: onStoppedEnter, from:"*"});
	 *	
	 *	playerSM.addEventListener(StateMachineEvent.TRANSITION_DENIED,transitionDeniedFunction);
	 *	playerSM.addEventListener(StateMachineEvent.TRANSITION_COMPLETE,transitionCompleteFunction);
	 *	
	 *	playerSM.initialState = "stopped";
	 * </pre> 
	 *
	 * It's also possible to create hierarchical state machines using the argument "parent" in the addState method
	 * @example This example shows the creation of a hierarchical state machine for the monster of a game
	 * (Its a simplified version of the state machine used to control the AI in the original Quake game)
	 *	<pre>
	 *	monsterSM = new StateMachine()
	 *	
	 *	monsterSM.addState("idle",{enter:onIdle, from:"attack"})
	 *	monsterSM.addState("attack",{enter:onAttack, from:"idle"})
	 *	monsterSM.addState("melee attack",{parent:"atack", enter:onMeleeAttack, from:"attack"})
	 *	monsterSM.addState("smash",{parent:"melle attack", enter:onSmash})
	 *	monsterSM.addState("punch",{parent:"melle attack", enter:onPunch})
	 *	monsterSM.addState("missle attack",{parent:"attack", enter:onMissle})
	 *	monsterSM.addState("die",{enter:onDead, from:"attack", enter:onDie})
	 *	
	 *	monsterSM.initialState = "idle"
	 *	</pre>
	*/
	public function new()
	{
		super();
		states = new Map();
	}

	/**
	 * Adds a new state
	 * @param stateName	The name of the new State
	 * @param stateData	A hash containing state enter and exit callbacks and allowed states to transition from
	 * The "from" property can be a string or and array with the state names or * to allow any transition
	**/
	public function addState(stateName:String, stateData:Dynamic=null):Void
	{
#if (debug)	
		if ( states.exists(stateName) ) trace("[StateMachine]", id, "Overriding existing state " + stateName);
#end
		if(stateData == null) stateData = {};
		states[stateName] = new State(stateName, stateData.from, stateData.enter, stateData.exit, states[stateData.parent]);
	}

	/**
	 * Sets the first state, calls enter callback and dispatches TRANSITION_COMPLETE
	 * These will only occour if no state is defined
	 * @param stateName	The name of the State
	**/
	public var initialState(never, set):String;
	public function set_initialState(stateName:String):String
	{
		if (_state == null &&  states.exists(stateName )){
			_state = stateName;
			
			var _callbackEvent:StateMachineEvent = new StateMachineEvent(StateMachineEvent.ENTER_CALLBACK);
			_callbackEvent.toState = stateName;
			
			if(states[_state].root != null){
				parentStates = states[_state].parents;
				var j:Int = states[_state].parents.length-1;
				while( j>=0 ){
					if(parentStates[j].enter != null){
						_callbackEvent.currentState = parentStates[j].name;
						parentStates[j].enter(_callbackEvent);
					}
					j--;
				}
			}
			
			if(states[_state].enter != null){
				_callbackEvent.currentState = _state;
				states[_state].enter(_callbackEvent);
			}
			_outEvent = new StateMachineEvent(StateMachineEvent.TRANSITION_COMPLETE);
			_outEvent.toState = stateName;
			dispatchEvent(_outEvent);
		}
		return _state;
	}

	/**
	 *	Getters for the current state and for the Dictionary of states
	 */
	public var state(get, never):State;
	inline function get_state():State
	{
		return states[_state];
	}
	
	inline function get_states():Map<String, State>
	{
		return states;
	}
	
	public function getStateByName( name:String ):State
	{
		for(  s in states ){
			if( s.name == name )
				return s;
		}
		
		return null;
	}
	/**
	 * Verifies if a transition can be made from the current state to the state passed as param
	 * @param stateName	The name of the State
	**/
	public function canChangeStateTo(stateName:String):Bool
	{
		return (stateName != _state && 
		(states[stateName].from.indexOf(_state)!=-1 || states[stateName].from == "*" || states[stateName].parent == state));
	}

	/**
	 * Discovers the how many "exits" and how many "enters" are there between two
	 * given states and returns an array with these two integers
	 * @param stateFrom The state to exit
	 * @param stateTo The state to enter
	**/
	public function findPath(stateFrom:String, stateTo:String):Array<Int>
	{
		// Verifies if the states are in the same "branch" or have a common parent
		var fromState:State = states[stateFrom];
		var c:Int = 0;
		var d:Int = 0;
		while (fromState != null)
		{
			d=0;
			var toState:State = states[stateTo];
			while (toState != null)
			{
				if(fromState == toState)
				{
					// They are in the same brach or have a common parent Common parent
					return [c,d];
				}
				d++;
				toState = toState.parent;
			}
			c++;
			fromState = fromState.parent;
		}
		// No direct path, no commom parent: exit until root then enter until element
		return [c,d];
	}

	/**
	 * Changes the current state
	 * This will only be done if the intended state allows the transition from the current state
	 * Changing states will call the exit callback for the exiting state and enter callback for the entering state
	 * @param stateTo	The name of the state to transition to
	**/
	public function changeState(stateTo:String):Void
	{
		// If there is no state that maches stateTo
		if ( !states.exists(stateTo) ) {
#if (debug)	
			trace("[StateMachine]", id, "Cannot make transition: State " + stateTo +" is not defined");
#end
			return;
		}
		
		// If current state is not allowed to make this transition
		if(!canChangeStateTo(stateTo))
		{
#if (debug)	
			trace("[StateMachine]", id, "Transition to " + stateTo +" denied");
#end
			_outEvent = new StateMachineEvent(StateMachineEvent.TRANSITION_DENIED);
			_outEvent.fromState = _state;
			_outEvent.toState = stateTo;
			_outEvent.allowedStates = states[stateTo].from;
			dispatchEvent(_outEvent);
			return;
		}
		
		// call exit and enter callbacks (if they exits)
		path = findPath(_state,stateTo);
		if(path[0]>0)
		{
			var _exitCallbackEvent:StateMachineEvent = new StateMachineEvent(StateMachineEvent.EXIT_CALLBACK);
			_exitCallbackEvent.toState = stateTo;
			_exitCallbackEvent.fromState = _state;
			
			if(states[_state].exit != null){
				_exitCallbackEvent.currentState = _state;
				states[_state].exit(_exitCallbackEvent);
			}
			parentState = states[_state];
			var i:Int=0;
			while( i<path[0]-1 )
			{
				parentState = parentState.parent;
				if(parentState.exit != null){
					_exitCallbackEvent.currentState = parentState.name;
					parentState.exit(_exitCallbackEvent);
				}
				i++;
			}
		}
		
		var oldState:String = _state;
		_state = stateTo;
		
		if(path[1]>0)
		{
			var _enterCallbackEvent:StateMachineEvent = new StateMachineEvent(StateMachineEvent.ENTER_CALLBACK);
			_enterCallbackEvent.toState = stateTo;
			_enterCallbackEvent.fromState = oldState;
			
			if(states[stateTo].root != null)
			{
				parentStates = states[stateTo].parents;
				var k:Int = path[1]-2;
				while( k>=0 )
				{
					if(parentStates[k] != null && parentStates[k].enter != null){
						_enterCallbackEvent.currentState = parentStates[k].name;
						parentStates[k].enter(_enterCallbackEvent);
					}
					k--;
				}
			}
			
			if(states[_state].enter != null){
				_enterCallbackEvent.currentState = _state;
				states[_state].enter(_enterCallbackEvent);
			}
		}
#if (debug)	
		trace("[StateMachine]", id, "State Changed to " + _state);
#end
		
		// Transition is complete. dispatch TRANSITION_COMPLETE
		_outEvent = new StateMachineEvent(StateMachineEvent.TRANSITION_COMPLETE);
		_outEvent.fromState = oldState;
		_outEvent.toState = stateTo;
		dispatchEvent(_outEvent);
	}
}
