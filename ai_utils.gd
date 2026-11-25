extends Node

'''
AIに丸投げした、読んでなかったりあんまり理解してなかったりするコードを隔離する場所
'''

class_name AiUtils

# ポリゴンをカメラから2D座標に変換する。
#
# カメラ座標系では、カメラの前方が -Z。
# そのため near 平面は z = -near。
#
# near より手前（カメラの後ろ側）にある頂点は、
# near 平面との交点まで辺上を移動させる。
#
# これは Sutherland-Hodgman 法による near 平面でのクリッピング。
#
# 3つ以上の頂点が near 平面の後ろにある場合、
# クリッピングによって出力頂点数が元より少なくなる。
#
# すべての頂点が near 平面の後ろにある場合は、
# (-1, -1), (0, -1), (-1, 0) の三角形を返す。
static func safe_unprojection_polygon(
		camera: Camera3D,
		polygon: Array[Vector3],
		near: float = 0.01
	) -> PackedVector2Array:

	if polygon.size() < 3:
		return PackedVector2Array()

	# ワールド座標 -> カメラ座標
	var camera_transform: Transform3D = camera.global_transform.affine_inverse()

	var camera_polygon: Array[Vector3] = []
	for vertex in polygon:
		camera_polygon.append(camera_transform * vertex)

	# すべて near 平面の後ろにあるか確認
	var any_in_front := false
	for vertex in camera_polygon:
		if vertex.z <= -near:
			any_in_front = true
			break

	if not any_in_front:
		return PackedVector2Array([
			Vector2(0, 0),
			Vector2(0, -1),
			Vector2(-1, 0)
		])

	# near 平面 z = -near でクリッピング
	var clipped: Array[Vector3] = []

	for i in camera_polygon.size():
		var current: Vector3 = camera_polygon[i]
		var next: Vector3 = camera_polygon[(i + 1) % camera_polygon.size()]

		var current_inside := current.z <= -near
		var next_inside := next.z <= -near

		if current_inside and next_inside:
			# 両方とも平面の前
			clipped.append(next)

		elif current_inside and not next_inside:
			# 前 -> 後ろ
			# 辺と near 平面との交点を追加
			clipped.append(_near_intersection(current, next, near))

		elif not current_inside and next_inside:
			# 後ろ -> 前
			# 交点 + 次の頂点を追加
			clipped.append(_near_intersection(current, next, near))
			clipped.append(next)

		# 両方とも後ろなら何もしない

	if clipped.size() < 3:
		return PackedVector2Array([
			Vector2(-1, -1),
			Vector2(0, -1),
			Vector2(-1, 0)
		])

	# クリッピング後のカメラ座標をワールド座標へ戻してから投影
	var result := PackedVector2Array()

	for vertex in clipped:
		var world_vertex: Vector3 = camera.global_transform * vertex
		result.append(camera.unproject_position(world_vertex))

	return result


# 線分をカメラから2D座標に変換する。
#
# near 平面より手前（カメラの後ろ側）にある端点は、
# near 平面との交点まで移動させてから投影する。
#
# 両方の端点が near 平面より手前にある場合は、空の PackedVector2Array() を返す。
static func safe_unprojection_line(
		camera: Camera3D,
		from_pos: Vector3,
		to_pos: Vector3,
		near: float = 0.01
	) -> PackedVector2Array:

	# ワールド座標 -> カメラ座標
	var camera_transform: Transform3D = camera.global_transform.affine_inverse()
	var a: Vector3 = camera_transform * from_pos
	var b: Vector3 = camera_transform * to_pos

	var a_inside := a.z <= -near
	var b_inside := b.z <= -near

	# 両端点とも near 平面の後ろ（画面外・描画不可）にある場合
	if not a_inside and not b_inside:
		return PackedVector2Array()

	# 片方の端点が near 平面を越えている場合、交点に置き換える
	if a_inside and not b_inside:
		b = _near_intersection(a, b, near)
	elif not a_inside and b_inside:
		a = _near_intersection(a, b, near)

	# 調整後のカメラ座標をワールド座標へ戻して 2D 投影
	var world_a: Vector3 = camera.global_transform * a
	var world_b: Vector3 = camera.global_transform * b

	return PackedVector2Array([
		camera.unproject_position(world_a),
		camera.unproject_position(world_b)
	])

class UnprojectedLine:
	var from_pos: Vector2
	var to_pos: Vector2
	var width_curve: Curve

	func _init(
		from_pos_: Vector2,
		to_pos_: Vector2,
		width_curve_: Curve
	):
		from_pos = from_pos_
		to_pos = to_pos_
		width_curve = width_curve_

# 3D線分を2D線分へ投影する。
#
# width_constant は
#     カメラからの距離 * 2D上での線の太さ
# の値。
#
# 例えば距離10で太さ2pxにしたい場合、
# width_constant = 20。
#
# 戻り値:
#   from_pos   : 2D上の始点
#   to_pos     : 2D上の終点
#   width_curve: 各位置での線幅を表すCurve
#
# width_curve の値そのものをピクセル幅として扱うため、
# Line2D.width = 1.0 として使用する。
static func safe_unprojection_line_with_width(
	camera: Camera3D,
	from_pos: Vector3,
	to_pos: Vector3,
	width_constant: float,
	near: float = 0.01
) -> UnprojectedLine:

	# カメラ座標へ変換
	var camera_transform: Transform3D = camera.global_transform.affine_inverse()

	var a: Vector3 = camera_transform * from_pos
	var b: Vector3 = camera_transform * to_pos

	var a_inside := a.z <= -near
	var b_inside := b.z <= -near

	# 両端とも near より後ろ
	if not a_inside and not b_inside:
		return null

	# 元の線分上で、near平面によって残る範囲を
	# t = 0～1 で表す。
	var t_start := 0.0
	var t_end := 1.0

	if a_inside and not b_inside:
		t_end = _near_intersection_t(a, b, near)
	elif not a_inside and b_inside:
		t_start = _near_intersection_t(a, b, near)

	# クリッピング後の3D座標
	var clipped_a := a.lerp(b, t_start)
	var clipped_b := a.lerp(b, t_end)

	# 2Dへ投影
	var world_a: Vector3 = camera.global_transform * clipped_a
	var world_b: Vector3 = camera.global_transform * clipped_b

	var screen_a := camera.unproject_position(world_a)
	var screen_b := camera.unproject_position(world_b)

	# 幅のCurve
	var curve := Curve.new()

	var width_a: float = width_constant / max(-clipped_a.z, 0.000001)
	var width_b: float = width_constant / max(-clipped_b.z, 0.000001)

	curve.add_point(Vector2(0.0, width_a))
	curve.add_point(Vector2(1.0, width_b))
	
	curve.set_point_left_mode(0, Curve.TANGENT_LINEAR)
	curve.set_point_right_mode(0, Curve.TANGENT_LINEAR)
	curve.set_point_left_mode(1, Curve.TANGENT_LINEAR)
	curve.set_point_right_mode(1, Curve.TANGENT_LINEAR)

	return UnprojectedLine.new(
		screen_a,
		screen_b,
		curve
	)

# 線分 a -> b と near 平面 z = -near の交点
static func _near_intersection(a: Vector3, b: Vector3, near: float) -> Vector3:
	var plane_z := -near

	# a + t * (b - a)
	# z = plane_z となる t を求める
	var t := (plane_z - a.z) / (b.z - a.z)

	return a.lerp(b, t)

static func _near_intersection_t(
	a: Vector3,
	b: Vector3,
	near: float
) -> float:
	var plane_z := -near
	return (plane_z - a.z) / (b.z - a.z)
