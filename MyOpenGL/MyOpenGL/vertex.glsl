attribute vec4 position;    // 变量类型 变量数据类型 变量名;
attribute vec4 color;

uniform float count;	// >0 -> right, <0 -> left

varying vec4 fragColor;

void main(void) {
    fragColor = color;
    gl_Position = vec4(position.x + 0.5*count/100.0, position.y, position.z, 1.0);
}
