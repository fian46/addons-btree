extends Reference

class Status:
	var params = []
	var status = RUNNING
	
	const RUNNING = 0
	const SUCCEED = 1
	const FAILED = -1
	
	func reset():
		status = RUNNING
		return
	
	func succeed():
		status = SUCCEED
		return
	
	func failed():
		status = FAILED
		return
	
	func get_status():
		return status
	
	func get_param(idx):
		return params[idx]
	
	func get_param_count():
		return params.size()

class TNode:
	var status = Status.new()
	var children = Array()
	var ticked = false
	
	func setup(data: Dictionary, target):
		pass
	
	func reset():
		return
	
	func tick() -> int:
		return 0

class Race extends TNode:
	func reset():
		status.reset()
		for c in children:
			if  c.ticked:
				c.reset()
		ticked = false
		return
	
	func tick() -> int:
		ticked = true
		if  status.status != Status.RUNNING:
			return status.status
		if  children.empty():
			status.succeed()
			return status.status
		var fcount = 0
		for c in children:
			var pr = c.status.status
			var r = pr
			
			if  pr == Status.RUNNING:
				r = c.tick()
			
			if  r == Status.SUCCEED:
				status.succeed()
				return status.status
			elif r == Status.FAILED:
				fcount += 1
		if  fcount == children.size():
			status.failed()
			return status.status
		return status.status

class Paralel extends TNode:
	func reset():
		status.reset()
		for c in children:
			if  c.ticked:
				c.reset()
		ticked = false
		return
	
	func tick() -> int:
		ticked = true
		if  status.status != Status.RUNNING:
			return status.status
		
		if  children.empty():
			status.succeed()
			return status.status
		
		var scount = 0
		for c in children:
			var pr = c.status.status
			var r = pr
			if  pr == Status.RUNNING:
				r = c.tick()
			if  r == Status.SUCCEED:
				scount += 1
			if  r == Status.FAILED:
				status.failed()
				return status.status
		if  scount == children.size():
			status.succeed()
		return status.status

class PSelector extends TNode:
	func reset():
		status.reset()
		for c in children:
			if  c.ticked:
				c.reset()
		ticked = false
		return
	
	func tick()->int:
		ticked = true
		if  status.status != Status.RUNNING:
			return status.status
		if  children.empty():
			status.failed()
			return status.status
		for c in children:
			var r = c.tick()
			if  r == Status.FAILED:
				continue
			if  r == Status.SUCCEED:
				var cr = c.children.front().tick()
				if  cr == Status.FAILED:
					continue
				if  cr == Status.RUNNING:
					return status.status
				if  cr == Status.SUCCEED:
					status.succeed()
					return status.status
		status.failed()
		return status.status

class PConditionStatus extends Status:
	func _init():
		reset()
		return
	
	func reset():
		status = Status.FAILED
		return

class PCondition extends TNode:
	var target = null

	func setup(data: Dictionary, target):
		.setup(data, target)
		status = PConditionStatus.new()
		self.target = funcref(target, data.fn)
		status.params = data.get('values', [])
		return
	
	func reset():
		status.reset()
		if  not children.empty():
			var c = children.front()
			if  c != null and c.ticked:
				c.reset()
		ticked = false
		return
	
	func tick()->int:
		ticked = true
		if  children.empty():
			status.failed()
			return status.status
		target.call_func(status)
		return status.status

class Root extends TNode:
	func reset():
		status.reset()
		if  not children.empty():
			var c = children.front()
			if  c != null and c.ticked:
				c.reset()
		ticked = false
		return
	
	func tick()->int:
		ticked = true
		if  status.status != Status.RUNNING:
			return status.status
		
		if  children.empty():
			status.failed()
			return status.status
		
		return children.front().tick()

class Task extends TNode:
	var target = null
	
	func setup(data: Dictionary, target):
		.setup(data, target)
		self.target = funcref(target, data.fn)
		status.params = data.get('values', [])
		return
	
	func reset():
		status.reset()
		ticked = false
		return
	
	func tick()->int:
		ticked = true
		if  status.status != Status.RUNNING:
			return status.status
		target.call_func(status)
		return status.status

class Sequence extends TNode:
	var current_child = 0
	
	func reset():
		status.reset()
		current_child = 0
		for c in children:
			if  c.ticked:
				c.reset()
		ticked = false
		return
	
	func tick()->int:
		ticked = true
		if  status.status != Status.RUNNING:
			return status.status
		if  children.empty():
			status.succeed()
			return status.status
		for i in range(current_child, children.size()):
			current_child = i
			var c = children[i]
			var r = c.tick()
			if  r == Status.RUNNING:
				return status.status
			elif r == Status.FAILED:
				status.failed()
				return status.status
		status.succeed()
		return status.status

class RandomSequence extends Sequence:
	func reset():
		.reset()
		children.shuffle()
		return

class Selector extends TNode:
	var current_child = 0

	func reset():
		status.reset()
		current_child = 0
		for c in children:
			if  c.ticked:
				c.reset()
		ticked = false
		return

	func tick()->int:
		ticked = true
		if  status.status != Status.RUNNING:
			return status.status
		if  children.empty():
			status.succeed()
			return status.status
		for i in range(current_child, children.size()):
			current_child = i
			var c = children[i]
			var r = c.tick()
			if  r == Status.RUNNING:
				return status.status
			elif r == Status.SUCCEED:
				status.succeed()
				return status.status
		status.failed()
		return status.status

class RandomSelector extends Selector:
	func reset():
		.reset()
		children.shuffle()
		return

class Mute extends TNode:
	func reset():
		status.reset()
		if  not children.empty():
			var c = children.front()
			if  c != null and c.ticked:
				c.reset()
		ticked = false
		return
	
	func tick()->int:
		ticked = true
		if  status.status != Status.RUNNING:
			return status.status
		if  children.empty():
			status.succeed()
			return status.status
		var r = children.front().tick()
		if  r != Status.RUNNING:
			status.succeed()
		return status.status

class Inverter extends TNode:
	func reset():
		status.reset()
		if  not children.empty():
			var c = children.front()
			if  c != null and c.ticked:
				c.reset()
		ticked = false
		return
	
	func tick()->int:
		ticked = true
		if  status.status != Status.RUNNING:
			return status.status
		if  children.empty():
			status.succeed()
			return status.status
		var r = children.front().tick()
		if  r != Status.RUNNING:
			if  r == Status.SUCCEED:
				status.failed()
			else:
				status.succeed()
		return status.status


class Repeat extends TNode:
	var tick_count = 0
	var count = 0
	
	func setup(data: Dictionary, target):
		.setup(data, target)
		count = data.count
		tick_count = count
		return
	
	func reset():
		tick_count = count
		status.reset()
		if  not children.empty():
			var c = children.front()
			if  c != null and c.ticked:
				c.reset()
		ticked = false
		return
	
	func tick()->int:
		ticked = true
		if  count > 0 and tick_count == 0:
			status.succeed()
			return status.status
		if  status.status != Status.RUNNING:
			return status.status
		if  children.empty():
			status.succeed()
			return status.status
		var result = children.front().tick()
		if  result == Status.SUCCEED:
			children.front().reset()
			if  count > 0:
				tick_count -= 1
				if  tick_count == 0:
					status.succeed()
			return status.status
		
		if  result == Status.FAILED:
			status.failed()
			return status.status
		return status.status

class WhileNode extends TNode:
	var target = null
	
	func setup(data: Dictionary, target):
		.setup(data, target)
		self.target = funcref(target, data.fn)
		status.params = data.get('values', [])
		return
	
	func reset():
		status.reset()
		if  not children.empty():
			var c = children.front()
			if  c != null and c.ticked:
				c.reset()
		ticked = false
		return
	
	func tick() -> int:
		ticked = true
		if  status.status != Status.RUNNING:
			return status.status
		if  children.empty():
			status.failed()
			return status.status
		status.failed()
		target.call_func(status)
		if  status.status == Status.SUCCEED:
			status.status = children.front().tick()
		return status.status

class WaitNode extends TNode:
	var tick_count = 0
	var count = 0
	
	func setup(data: Dictionary, target):
		.setup(data, target)
		count = data.count
		tick_count = count
		return
	
	func reset():
		tick_count = count
		status.reset()
		ticked = false
		return
	
	func tick()->int:
		ticked = true
		if  tick_count <= 0:
			status.succeed()
			return status.status
		if  status.status != Status.RUNNING:
			return status.status
		tick_count -= 1
		if  tick_count <= 0:
			status.succeed()
		return status.status
		
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
	if not constructors.empty():
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

static func create_runtime(data:Dictionary, target) -> TNode:
	if  data.empty():
		return null
	var current = null
	var t_node_type = get_constructors().get(data.type)
	if t_node_type != null:
		current = t_node_type.new()
		current.setup(data.data, target)
	if data.type == TNodeTypes.MINIM:
		current = create_runtime(data.data.data.root, target)
	if  current:
		for child in data.child:
			var tnode = create_runtime(child, target)
			if  tnode:
				current.children.append(tnode)
	return current
