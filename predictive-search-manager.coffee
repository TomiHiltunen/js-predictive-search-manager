###

PREDECTIVE SEARCH MANAGER - v1.0.0
by Tomi Hiltunen, released 2013
https://github.com/TomiHiltunen

This class is used to manage predictive search functions on a web interface.

Features:
	* Prevents multiple API queries on the same search term.
	* Keeps the entered searches logged to keep results appearing in right order.
	* Caches queried search terms for lighting fast results.

Released under the MIT license.

###


###
Extends Array class with lastIndexOf -function.
This is necessary for the use of predictive search manager.
If you have this script already included somewhere else in your code, you can remove this bit.

Original script from: http://www.tutorialspoint.com/javascript/array_lastindexof.htm
Converted to CoffeeScript with http://js2coffee.org
###
unless Array::lastIndexOf
	Array::lastIndexOf = (elt) -> #, from
		len = @length
		from = Number(arguments_[1])
		if isNaN(from)
			from = len - 1
		else
			from = (if (from < 0) then Math.ceil(from) else Math.floor(from))
			if from < 0
				from += len
			else from = len - 1  if from >= len
		while from > -1
			return from  if from of this and this[from] is elt
			from--
		-1


###
CONSTRUCTOR
@param options An object containing options for PSM
###
window.PredictiveSearchManager = (options) ->
	# Cache contains results for successful searches
	@cache = {}
	# Stack contains search clauses in order of input
	# Stack controls the order in which results are shown or if the result should be skipped
	@stack = []
	# Reserved keeps track of the active and past queries so that they will not be queried from the API multiple times
	@reserved = []
	# Default options
	@options =
		log: false
		url: ""
		method: "GET"
		data: {}
		callback: (data) ->
			console.log "PSM - Callback triggered with data:", data
		callbackEmpty: () ->
			console.log "PSM - Empty search callback triggered"
	# Check the user input options
	for i of options
		@options[i] = options[i] if @options.hasOwnProperty i
	# Return reference to this
	@

PredictiveSearchManager:: =
	###
	SEARCH RELATED
	###

	# Used to input new search to the manager
	# @param clause The search lause
	newSearch: (clause) ->
		console.log "<search-mgr>", "New search", "\""+clause+"\"" if @options.log
		# No empty searches allowed
		if !clause || clause == ""
			@emptySearch()
			return
		# Add search clause to stack
		@addToStack clause
		# Check cached entries
		cachedData = @getFromCache clause
		if cachedData != false
			console.log "<search-mgr>", "Found results from cache", "\""+clause+"\"", cachedData if @options.log
			@outputResults clause, cachedData
			return
		console.log "<search-mgr>", "No cached results", "\""+clause+"\"" if @options.log
		# Check if the clause is already being processed
		return if @isReserved clause
		# If not found from cache, query the API
		self = @
		console.log "<search-mgr>", "Making an API request", "\""+clause+"\"" if @options.log
		$.get @options.url.replace("{SEARCH}", encodeURIComponent(clause)), (data, resp) ->
			console.log "<search-mgr>", "API responded", "\""+clause+"\"", data, resp if self.options.log
			self.addToCache clause, data
			self.outputResults clause, data
		, "json"

	# Triggered when PSM is requested to perform a search on an empty/invalid search clause
	emptySearch: ->
		console.log "<search-mgr>", "Search clause was empty" if @options.log
		@truncateStack()
		@options.callbackEmpty.call() if typeof @options.callbackEmpty == "function"

	# Output results through callback
	# @param clause The search lause
	# @param data The search result data set
	outputResults: (clause, data) ->
		if @cutStack clause
			console.log "<search-mgr>", "Calling callback function", "\""+clause+"\"", data if @options.log
			@options.callback.call(@, data) if typeof @options.callback == "function"

	###
	CACHE RELATED
	###

	# Checks whether a data set is cached
	# @param clause The search lause
	getFromCache: (clause) ->
		return @cache[clause] if @cache[clause]
		return false

	# Cache result set
	# @param clause The search lause
	# @param data The search result data set
	addToCache: (clause, data) ->
		@cache[clause] = data

	# Clears completely the existing search cache
	truncateCache: ->
		@cache = {}

	###
	STACK RELATED
	###

	# Checks if clause is already processed/being processed
	# If not, the clause is added to the list
	# @return bool
	isReserved: (clause) ->
		if @reserved.lastIndexOf(clause) > -1
			console.log "<search-mgr>", "Search clause was reserved" if @options.log
			return true
		console.log "<search-mgr>", "Search clause was not yet reserved" if @options.log
		@reserved.push clause
		return false

	# Clears completely the existing search stack
	truncateStack: ->
		@stack = []

	# Adds a new search term to the end of stack
	# @param clause The search lause
	addToStack: (clause) ->
		@stack.push clause

	# Cut the stack from the last occurence of search clause
	# @param clause The search lause
	# @return bool
	cutStack: (clause) ->
		# Get the last index of the clause in stack
		lastIndex = @stack.lastIndexOf clause
		# If the last index is not in the stack, return false
		return false if lastIndex < 0
		# Loop through the rest of the array to create new one
		idx = lastIndex+1
		newStack = []
		while idx < @stack.length
			newStack.push @stack[idx]
			idx++
		@stack = newStack
		# Tell the outputter that it is OK to go ahead
		return true
