extends Reference

enum Status {
	RUNNING = 0,
	SUCCEED = 1,
	FAILED = -1,
}

class TNode:
	var status: int = Status.RUNNING
	var ticked := false
	
	func reset() -> int:
		status = Status.RUNNING
		ticked = false
		return status
	
	func succeed() -> int:
		status = Status.SUCCEED
		return status
	
	func failed() -> int:
		status = Status.FAILED
		return status
	
	func get_status():
		return status
	
	func setup(data: Dictionary, target):
		pass
	
	func tick() -> int:
		return Status.RUNNING

class CompositeTNode extends TNode:
	var children := []
	
	func reset():
		.reset()
		for c in children:
			if  c.ticked:
				c.reset()
		return

class DecoratorTNode extends TNode:
	var child: TNode
	
	func reset():
		.reset()
		if  child and child.ticked:
			child.reset()
		return

class Race extends CompositeTNode:
	func tick() -> int:
		ticked = true
		if  status != Status.RUNNING:
			return status
		if  children.empty():
			return succeed()
		var fcount = 0
		for c in children:
			var pr = c.status
			var r = pr
			
			if  pr == Status.RUNNING:
				r = c.tick()
			
			if  r == Status.SUCCEED:
				return succeed()
			elif r == Status.FAILED:
				fcount += 1
		if  fcount == children.size():
			return failed()
		return status

class Paralel extends CompositeTNode:
	func tick() -> int:
		ticked = true
		if  status != Status.RUNNING:
			return status
		
		if  children.empty():
			return succeed()
		
		var scount = 0
		for c in children:
			var pr = c.status
			var r = pr
			if  pr == Status.RUNNING:
				r = c.tick()
			if  r == Status.SUCCEED:
				scount += 1
			if  r == Status.FAILED:
				return failed()
		if  scount == children.size():
			succeed()
		return status

class PSelector extends CompositeTNode:
	func tick() -> int:
		ticked = true
		if  status != Status.RUNNING:
			return status
		if  children.empty():
			return failed()
		for c in children:
			var r = c.tick()
			if  r == Status.FAILED:
				continue
			if  r == Status.SUCCEED:
				var cr = c.child.tick()
				if  cr == Status.FAILED:
					continue
				if  cr == Status.RUNNING:
					return status
				if  cr == Status.SUCCEED:
					return succeed()
		return failed()

class PCondition extends DecoratorTNode:
	var target: FuncRef
	var params := []
	
	func _init():
		status = Status.FAILED
		return
	
	func reset():
		.reset()
		status = Status.FAILED
		return
	
	func setup(data: Dictionary, target):
		.setup(data, target)
		self.target = funcref(target, data.fn)
		params = data.get('values', [])
		return
	
	func tick() -> int:
		ticked = true
		if  not child:
			return failed()
		target.call_func(self)
		return status
	
	func get_param(idx):
		return params[idx]
		
	func get_param_count():
		return params.size()

class Root extends DecoratorTNode:
	func tick() -> int:
		ticked = true
		if  status != Status.RUNNING:
			return status
		if  not child:
			return failed()
		return child.tick()

class Task extends TNode:
	var target: FuncRef
	var params := []
	
	func setup(data: Dictionary, target):
		.setup(data, target)
		self.target = funcref(target, data.fn)
		params = data.get('values', [])
		return
	
	func tick() -> int:
		ticked = true
		if  status != Status.RUNNING:
			return status
		target.call_func(self)
		return status
	
	func get_param(idx):
		return params[idx]
		
	func get_param_count():
		return params.size()

class Sequence extends CompositeTNode:
	var current_child = 0
	
	func reset():
		.reset()
		current_child = 0
		return
	
	func tick() -> int:
		ticked = true
		if  status != Status.RUNNING:
			return status
		if  children.empty():
			return succeed()
		for i in range(current_child, children.size()):
			current_child = i
			var c = children[i]
			var r = c.tick()
			if  r == Status.RUNNING:
				return status
			elif r == Status.FAILED:
				return failed()
		return succeed()

class RandomSequence extends Sequence:
	func reset():
		.reset()
		children.shuffle()
		return

class Selector extends CompositeTNode:
	var current_child = 0
	
	func reset():
		.reset()
		current_child = 0
		return
	
	func tick() -> int:
		ticked = true
		if  status != Status.RUNNING:
			return status
		if  children.empty():
			return succeed()
		for i in range(current_child, children.size()):
			current_child = i
			var c = children[i]
			var r = c.tick()
			if  r == Status.RUNNING:
				return status
			elif r == Status.SUCCEED:
				return succeed()
		return failed()

class RandomSelector extends Selector:
	func reset():
		.reset()
		children.shuffle()
		return

class Mute extends DecoratorTNode:
	func tick() -> int:
		ticked = true
		if  status != Status.RUNNING:
			return status
		if  not child or child.tick() != Status.RUNNING:
			return succeed()
		return status

class Inverter extends DecoratorTNode:
	func tick() -> int:
		ticked = true
		if  status != Status.RUNNING:
			return status
		if  not child:
			return succeed()
		var r = child.tick()
		if  r != Status.RUNNING:
			if  r == Status.SUCCEED:
				failed()
			else:
				succeed()
		return status

class Repeat extends DecoratorTNode:
	var tick_count = 0
	var count = 0
	
	func setup(data: Dictionary, target):
		.setup(data, target)
		count = data.count
		tick_count = count
		return
	
	func reset():
		.reset()
		tick_count = count
		return
	
	func tick() -> int:
		ticked = true
		if  count > 0 and tick_count == 0:
			return succeed()
		if  status != Status.RUNNING:
			return status
		if  not child:
			return succeed()
		var result = child.tick()
		if  result == Status.SUCCEED:
			child.reset()
			if  count > 0:
				tick_count -= 1
				if  tick_count == 0:
					succeed()
			return status
		
		if  result == Status.FAILED:
			return failed()
		return status

class WhileNode extends DecoratorTNode:
	var target: FuncRef
	var params := []
	
	func setup(data: Dictionary, target):
		.setup(data, target)
		self.target = funcref(target, data.fn)
		params = data.get('values', [])
		return
	
	func tick() -> int:
		ticked = true
		if  status != Status.RUNNING:
			return status
		if  not child:
			return failed()
		failed()
		target.call_func(self)
		if  status == Status.SUCCEED:
			status = child.tick()
		return status
	
	func get_param(idx):
		return params[idx]
		
	func get_param_count():
		return params.size()

class WaitNode extends TNode:
	var tick_count = 0
	var count = 0
	
	func setup(data: Dictionary, target):
		.setup(data, target)
		count = data.count
		tick_count = count
		return
	
	func reset():
		.reset()
		tick_count = count
		return
	
	func tick() -> int:
		ticked = true
		if  tick_count <= 0:
			return succeed()
		if  status != Status.RUNNING:
			return status
		tick_count -= 1
		if  tick_count <= 0:
			succeed()
		return status

enum TNodeTypes {
	ROOT,
	TASK,
	SEQUENCE,
	SELECTOR,
	PRIORITY_SELECTOR,
	PRIORITY_CONDITION,
	PARALEL,
	MUTE,
	REPEAT,
	WHILE,
	WAIT,
	RACE,
	RANDOM_SELECTOR,
	RANDOM_SEQUENCE,
	INVERTER,
	MINIM = 99
}

const constructors = {}
static func get_constructors() -> Dictionary:
	if  not constructors.empty():
		return constructors
	constructors[TNodeTypes.ROOT] = Root
	constructors[TNodeTypes.TASK] = Task
	constructors[TNodeTypes.SEQUENCE] = Sequence
	constructors[TNodeTypes.SELECTOR] = Selector
	constructors[TNodeTypes.PRIORITY_SELECTOR] = PSelector
	constructors[TNodeTypes.PRIORITY_CONDITION] = PCondition
	constructors[TNodeTypes.PARALEL] = Paralel
	constructors[TNodeTypes.MUTE] = Mute
	constructors[TNodeTypes.REPEAT] = Repeat
	constructors[TNodeTypes.WHILE] = WhileNode
	constructors[TNodeTypes.WAIT] = WaitNode
	constructors[TNodeTypes.RACE] = Race
	constructors[TNodeTypes.RANDOM_SELECTOR] = RandomSelector
	constructors[TNodeTypes.RANDOM_SEQUENCE] = RandomSequence
	constructors[TNodeTypes.INVERTER] = Inverter
	return constructors

static func create_runtime(data: Dictionary, target) -> TNode:
	if  data.empty():
		return null

	if  data.type == TNodeTypes.MINIM:
		return create_runtime(data.data.data.root, target)

	var tnode_type = get_constructors().get(data.type)
	var current: TNode = tnode_type.new()
	current.setup(data.data, target)

	for child in data.child:
		var tnode_child = create_runtime(child, target)
		if  current is CompositeTNode:
			current.children.append(tnode_child)
		elif current is DecoratorTNode:
			current.child = tnode_child
	return current
