--!strict

local M = {}
M.__index = M

export type Thread = {
	Start: (self: Thread, ...any) -> (),
	Stop: (self: Thread) -> (),
	IsRunning: (self: Thread) -> boolean,
	Destroy: (self: Thread) -> (),
	OnFinishCallback: (self: Thread, () -> ()) -> ()
}

type ThreadImpl = {
	_func: (...any) -> (),
	_args: {any},
	_thread: thread?,
	_running: boolean,
	_shouldStop: boolean,
	_onFinishedCallback: () -> ()
}

function M.new(func: (...any) -> (), ...: any): Thread
	local self: ThreadImpl = setmetatable({}, M) :: any
	
	self._func = func
	self._args = {...}
	self._thread = nil
	self._running = false
	self._shouldStop = false
	
	return self :: any
end

function M:Start(...: any)
	if self._running then
		warn("Thread is already running")
		return
	end
	
	self._running = true
	self._shouldStop = false
	
	-- Use arguments from Start() if provided, otherwise use stored arguments
	local args = if select("#", ...) > 0 then {...} else self._args
	
	self._thread = task.spawn(function()
		-- Call the function with the arguments
		self._func(table.unpack(args))
		self._running = false
		self._onFinishedCallback()
	end)
end

function M:Stop()
	if not self._running then
		warn("Thread is not running")
		return
	end
	
	self._shouldStop = true
	
	if self._thread then
		task.cancel(self._thread)
		self._thread = nil
	end
	
	self._running = false
end

function M:IsRunning(): boolean
	return self._running
end

function M:Destroy()
	self:Stop()
	self._func = nil :: any
	self._args = {}
end

function M:OnFinishCallback(func: () -> ())
	self._onFinishedCallback = func
end

return M
