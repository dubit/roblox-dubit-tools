type PromiseStatus = {
	Started: string,
	Resolved: string,
	Rejected: string,
	Cancelled: string,
}

export type Promise = {
	andThen: (Promise, successHandler: ((...any) -> ...any)?, failureHandler: ((...any) -> ...any)?) -> Promise,
	catch: (Promise, failureHandler: (...any) -> ...any) -> Promise,
	await: (Promise) -> (boolean, ...any),
	expect: (Promise) -> ...any,
	cancel: (Promise) -> (),
	now: (Promise, rejectionValue: any) -> Promise,
	andThenCall: (Promise, callback: (...any) -> any) -> Promise,
	andThenReturn: (Promise, ...any) -> Promise,
	awaitStatus: (Promise) -> (PromiseStatus, ...any),
	finally: (Promise, finallyHandler: (status: PromiseStatus) -> ...any) -> Promise,
	finallyCall: (Promise, callback: (...any) -> any, ...any?) -> Promise,
	finallyReturn: (Promise, ...any) -> Promise,
	getStatus: (Promise) -> PromiseStatus,
	tap: (Promise, tapHandler: (...any) -> ...any) -> Promise,
	timeout: (Promise, seconds: number, rejectionValue: any?) -> Promise,
}

return {}
