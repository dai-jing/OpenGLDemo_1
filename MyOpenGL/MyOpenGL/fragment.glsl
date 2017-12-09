varying lowp vec4 fragColor;
uniform highp float count;

void main(void) {
    highp float intensity = (count/100.0 + 1.0) / 2.0;
    gl_FragColor = fragColor * intensity;
}
