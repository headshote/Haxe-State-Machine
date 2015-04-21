package stateMachine;

import flash.events.Event;

class StateMachineEvent extends Event
{
	public static inline var EXIT_CALLBACK:String = "exit";
	public static inline var ENTER_CALLBACK:String = "enter";
	public static inline var TRANSITION_COMPLETE:String = "transition complete";
	public static inline var TRANSITION_DENIED:String = "transition denied";
	
	public var fromState : String;
	public var toState : String;
	public var currentState : String;
	public var allowedStates : Dynamic;

	public function new(type:String, bubbles:Bool=false, cancelable:Bool=false)
	{
		super(type, bubbles, cancelable);
	}
}
