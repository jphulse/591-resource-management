class_name ClickerUpgrades extends Panel

@onready var line_layer : Control = %LineLayer
@onready var upgrade_holder : HBoxContainer = %UpgradeHolder
@onready var balance_label : Label = %Balance


@export var clicker : InfectionClicker = null
@export var minimum_vertical_sep : int = 24
@export var minimum_horizontal_sep : int = 24

func _ready() -> void:
	upgrade_holder.add_theme_constant_override("separation", minimum_horizontal_sep)
	
	for child in upgrade_holder.get_children():
		if child is VBoxContainer:
			child.sort_children.connect(update_lines)

#func _notification(what: int) -> void:
	#if what == NOTIFICATION_RESIZED and is_node_ready():
		#print("Resized")
		#update_lines()
	#


func update_lines() -> void:
	for child in line_layer.get_children():
		child.queue_free()

	for column in upgrade_holder.get_children():
		if column is VBoxContainer:
			connect_buttons_vertically(column)


func connect_buttons_vertically(column: VBoxContainer) -> void:
	var buttons: Array[Control] = []

	for child in column.get_children():
		if child is TextureButton:
			buttons.append(child)

	for i in range(buttons.size() - 1):
		draw_connection(buttons[i], buttons[i + 1])


func draw_connection(a: Control, b: Control) -> void:
	var line := Line2D.new()
	line.width = 4.0
	line.default_color = Color.WHITE
	line_layer.add_child(line)

	var a_center_global := a.global_position + a.size * 0.5
	var b_center_global := b.global_position + b.size * 0.5

	line.add_point(line.to_local(a_center_global))
	line.add_point(line.to_local(b_center_global))
	

func _on_passive_bought(passive : PlaguePassive) -> void:
	var vbox : VBoxContainer = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.sort_children.connect(update_lines)
	upgrade_holder.add_child(vbox)
	vbox.add_theme_constant_override("separation", minimum_vertical_sep)
	var label : Label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text = str(passive.upgrade_cost)
	vbox.add_child(label)
	var button : ClickerTreeButton = ClickerTreeButton.new()
	button.pressed.connect(_on_upgrade_pressed.bind(vbox, button, passive, label))
	button.texture_normal = passive.sprite_texture
	
	vbox.add_child(button)
	update_lines()

func _on_upgrade_pressed(vbox : VBoxContainer, button : ClickerTreeButton, passive : PlaguePassive, label : Label) -> void:
	if clicker:
		if clicker.tree_upgrade_pressed(passive):
			button.disabled = true
			var next_button : ClickerTreeButton = ClickerTreeButton.new()
			next_button.pressed.connect(_on_upgrade_pressed.bind(vbox, next_button, passive, label))
			next_button.texture_normal = passive.sprite_texture
			vbox.add_child(next_button)
			label.text = str(passive.upgrade_cost)
			draw_connection.call_deferred(button, next_button)
