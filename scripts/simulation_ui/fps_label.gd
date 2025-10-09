extends Label

## Real‑time FPS display label.
## Why: Provides immediate visual feedback about engine performance without using
## external debugging overlays. Lightweight and independent of Camera or Viewport.

## Updates the label text every frame with the current frames‑per‑second rate.
## Why: Accesses the engine’s internal FPS counter via `Engine.get_frames_per_second()`
## for accurate live monitoring in both debug and release builds.
func _process(_delta: float) -> void:
	text = "FPS: %d" % Engine.get_frames_per_second()
