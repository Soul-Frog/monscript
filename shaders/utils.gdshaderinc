// checks if two values are 'equal' (within EPSILON of each other)
// necessary when doing float calculations since it's not perfectly precise
const float EPSILON = 0.01;

bool floateq(float val1, float val2) {
	return val1 >= val2 - EPSILON && val1 <= val2 + EPSILON;
}

bool vec3eq(vec3 val1, vec3 val2) {
	return floateq(val1.r, val2.r) && floateq(val1.g, val2.g) && floateq(val1.b, val2.b);
}