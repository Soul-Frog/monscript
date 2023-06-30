class_name TestingUtils

class SignalCounter extends Node2D:
	var ct := 0
	
	func count():
		return ct
	
	func callback0():
		ct += 1
	func callback1(a):
		ct += 1
	func callback2(a, b):
		ct += 1
	func callback3(a, b, c):
		ct += 1
	func callback4(a, b, c, d):
		ct += 1
	func callback5(a, b, c, d, e):
		ct += 1
