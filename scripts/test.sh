#!/usr/bin/env sh

set -eu

PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
GODOT_BIN=${GODOT_BIN:-godot}
GODOT_LOG=${GODOT_LOG:-${TMPDIR:-/tmp}/godot-game-design-starter-tests.log}

"$GODOT_BIN" --headless --path "$PROJECT_DIR" --log-file "$GODOT_LOG" --editor --quit

rg --files "$PROJECT_DIR/tests" -g 'test_*.gd' | while IFS= read -r test_file; do
	test_resource_path="res://${test_file#"$PROJECT_DIR/"}"
	"$GODOT_BIN" --headless --path "$PROJECT_DIR" --log-file "$GODOT_LOG" --check-only --script "$test_resource_path"
done

"$GODOT_BIN" --headless --path "$PROJECT_DIR" --log-file "$GODOT_LOG" --script res://addons/gut/gut_cmdln.gd -- \
	-gdir=res://tests \
	-ginclude_subdirs \
	-gexit
