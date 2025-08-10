class_name ResourceOperations
extends Node

var _http: HTTPRequest
var errors: Array[String] = []
var warnings: Array[String] = []


# Create an HTTP request node and connect its completion signal.
func get_http() -> HTTPRequest:
	if not _http:
		_http = HTTPRequest.new()
		_http.timeout = 60.0
		add_child(_http)
	return _http


# Returns a string of all error messages, separated by newlines.
func get_error_messages() -> String:
	var error_messages: String = ""
	for err in errors:
		error_messages += err + "\n"
	return error_messages.strip_edges()


# Returns true if there are any errors recorded.
func has_errors() -> bool:
	return errors.size() > 0
	
	
# Clear all recorded errors
func clear_errors() -> void:
	errors.clear()


# Add error message to the list and log it.
func error(message: String) -> void:
	errors.append(message)
	push_error("[ManifestLoader] %s" % message)
