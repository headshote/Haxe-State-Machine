package stateMachine;

class State
{
	public var name:String;
	public var from:Dynamic;
	public var enter:StateMachineEvent->Void;
	public var exit:StateMachineEvent->Void;
	
	@:isVar public var parent(get, set):State;		
	public var children:Array<State>;
	
	public function new(name:String, from:Dynamic = null, enter:StateMachineEvent->Void = null, exit:StateMachineEvent->Void = null, parent:State = null)
	{
		this.name = name;
		if (!from) from = "*";
		this.from = from;
		this.enter = enter;
		this.exit = exit;
		this.children = [];
		if (parent != null)
		{
			this.parent = parent;
		}
	}
	
	inline function set_parent(parent:State):State
	{
		this.parent = parent;
		this.parent.children.push(this);
		return this.parent;
	}
	
	inline function get_parent():State
	{
		return parent;
	}
	
	public var root(get, never):State;
	inline function get_root():State
	{
		var parentState:State = parent;
		if(parentState != null)
		{
			while (parentState.parent != null)
			{
				parentState = parentState.parent;
			}
		}
		return parentState;
	}
	
	public var parents(get, never):Array<State>;
	inline function get_parents():Array<State>
	{
		var parentList:Array<State> = [];
		var parentState:State = parent;
		if(parentState != null)
		{
			parentList.push(parentState);
			while (parentState.parent != null)
			{
				parentState = parentState.parent;
				parentList.push(parentState);
			}
		}
		return parentList;
	}
	
	public function toString():String
	{
		return this.name;
	}
}
