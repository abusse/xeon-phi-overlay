/* Intel MPSS 5.1.1 ICEs at -O0 (knc.md knc_store<mode>: misaligned
   vpackstore of a by-value struct { float, float }).  */
struct sf2 { float x, y; };
struct sf2 sf2_scale(struct sf2 v, float s) { v.x *= s; v.y *= s; return v; }
