export type Stack<T> = {
	first: number,
	last: number,
	size: number,

	push: (stack: Stack<T>, value: T) -> (),
	pushFirst: (stack: Stack<T>, value: T) -> (),
	pushLast: (stack: Stack<T>, value: T) -> (),

	pop: (stack: Stack<T>) -> T?,
	popFirst: (stack: Stack<T>) -> T?,
	popLast: (stack: Stack<T>) -> T?,

	peek: (stack: Stack<T>) -> T,
	peekFirst: (stack: Stack<T>) -> T,
	peekLast: (stack: Stack<T>) -> T,
}

local Stack = {}

function Stack.new<T>(): Stack<T>
	return setmetatable(
		{
			first = 1,
			last = 0,
			size = 0,
		} :: any,
		{
			__index = Stack,
		}
	)
end

function Stack.pushFirst<T>(stack: Stack<T>, value: T)
	stack.size += 1
	stack.first -= 1
	stack[stack.first] = value
end

function Stack.pushLast<T>(stack: Stack<T>, value: T)
	stack.size += 1
	stack.last += 1
	stack[stack.last] = value
end

function Stack.popFirst<T>(stack: Stack<T>): T?
	local first = stack.first
	if first > stack.last then
		return
	end

	stack.size -= 1

	local value = stack[first]
	stack[first] = nil
	stack.first += 1
	return value
end

function Stack.popLast<T>(stack: Stack<T>): T?
	local last = stack.last
	if stack.first > last then
		return
	end

	stack.size -= 1

	local value = stack[last]
	stack[last] = nil
	stack.last -= 1
	return value
end

function Stack.peekFirst<T>(stack: Stack<T>): T?
	return stack[stack.first]
end

function Stack.peekLast<T>(stack: Stack<T>): T?
	return stack[stack.last]
end

Stack.peek = Stack.peekFirst
Stack.push = Stack.pushFirst
Stack.pop = Stack.popFirst

return Stack
