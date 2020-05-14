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
	
	func _init():
		status = PConditionStatus.new()
		return
	
	func reset():
		status.reset()
		var c = children.front()
		if c != null and c.ticked:
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
		var c = children.front()
		if c != null and c.ticked:
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
		var c = children.front()
		if c != null and c.ticked:
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
		var c = children.front()
		if c != null and c.ticked:
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
	
	func reset():
		tick_count = count
		status.reset()
		var c = children.front()
		if c != null and c.ticked:
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
	
	func reset():
		status.reset()
		var c = children.front()
		if c != null and c.ticked:
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

static func create_runtime(data:Dictionary, target) -> TNode:
	if  data.empty():
		return null
	var current = null
	if  data.type == 0:
		current = Root.new()
	elif  data.type == 1:
		current = Task.new()
		current.target = funcref(target, data.data.fn)
		if  data.data.has("values"):
			current.status.params = data.data.values
		else:
			current.status.params = []
	elif  data.type == 2:
		current = Sequence.new()
	elif  data.type == 3:
		current = Selector.new()
	elif  data.type == 4:
		current = PSelector.new()
	elif  data.type == 5:
		current = PCondition.new()
		current.target = funcref(target, data.data.fn)
		if  data.data.has("values"):
			current.status.params = data.data.values
		else:
			current.status.params = []
	elif data.type == 6:
		current = Paralel.new()
	elif data.type == 7:
		current = Mute.new()
	elif data.type == 8:
		current = Repeat.new()
		current.count = data.data.count
		current.tick_count = current.count
	elif data.type == 9:
		current = WhileNode.new()
		current.target = funcref(target, data.data.fn)
		if  data.data.has("values"):
			current.status.params = data.data.values
		else:
			current.status.params = []
	elif data.type == 10:
		current = WaitNode.new()
		current.count = data.data.count
		current.tick_count = current.count
	elif data.type == 11:
		current = Race.new()
	elif data.type == 12:
		current = RandomSelector.new()
	elif data.type == 13:
		current = RandomSequence.new()
	elif data.type == 14:
		current = Inverter.new()
	elif data.type == 99:
		current = create_runtime(data.data.data.root, target)
	if  current:
		for child in data.child:
			var tnode = create_runtime(child, target)
			if  tnode:
				current.children.append(tnode)
	return current
