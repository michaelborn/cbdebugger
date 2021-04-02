/**
 * Copyright Since 2005 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * Profiles interception calls so we can profile them
 */
component implements="coldbox.system.aop.MethodInterceptor" accessors="true" {

	// DI
	property name="timerService"    inject="Timer@cbdebugger";
	property name="debuggerService" inject="debuggerService@cbdebugger";

	/**
	 * Constructor
	 */
	function init(
		required excludedInterceptions,
		required includedInterceptions
	){
		variables.excludedInterceptions = arguments.excludedInterceptions;
		variables.includedInterceptions = arguments.includedInterceptions;
		return this;
	}

	/**
	 * The AOP method invocation
	 */
	any function invokeMethod( required invocation ){
		var targetArgs = arguments.invocation.getArgs();

		// state
		if ( structKeyExists( targetArgs, "state" ) ) {
			var state = targetArgs.state;
		} else if ( structKeyExists( targetArgs, 1 ) ) {
			var state = targetArgs[ 1 ];
		}
		// data
		if ( structKeyExists( targetArgs, "data" ) ) {
			var data = targetArgs.data;
		} else if ( structKeyExists( targetArgs, 2 ) ) {
			var data = targetArgs[ 2 ];
		}

		// Do we need to profile it or not?
		if (
			arrayContainsNoCase(
				variables.excludedInterceptions,
				state
			) && !arrayContainsNoCase(
				variables.includedInterceptions,
				state
			)
		) {
			return arguments.invocation.proceed();
		}

		var txName    = "[Interception] #state#";

		// Is this an entity interception? If so, log it to assist
		if( data.keyExists( "entity" ) ){
			txName &= "( #getEntityName( data )# )";
		}

		// create FR tx with method name
		var labelHash = variables.timerService.start( txName );
		// proceed invocation
		var results   = arguments.invocation.proceed();
		// close tx
		variables.timerService.stop( labelhash );
		// return results
		if ( !isNull( results ) ) {
			return results;
		}
	}

	/**
	 * Try to discover an entity name from the passed intercept data
	 */
	private string function getEntityName( required data ){
		// If passed, just relay it back
		if( arguments.data.keyExists( "entityName" ) ){
			return arguments.data.entityName;
		}

		// Check if we have a quick entity
		if( structKeyExists( arguments.data.entity, "mappingName" ) ){
			return arguments.data.entity.mappingName();
		}

		// Short-cut discovery via ActiveEntity
		if ( structKeyExists( arguments.data.entity, "getEntityName" ) ) {
			return arguments.data.entity.getEntityName();
		} else {
			// it must be in session.
			return ormGetSession().getEntityName( arguments.data.entity );
		}
	}

}
