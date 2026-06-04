extends Node2D

signal gap_entry
signal gap_exit

func _on_entry_body_entered(body):gap_entry.emit()
func _on_exit_body_exited(body):gap_exit.emit()
