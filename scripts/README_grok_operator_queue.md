# Grok Operator Queue

Local-first semi-automated Grok Imagine operator workflow for Dragon Egg X.

## Files

- Queue inputs:
  - `catalog/exports/title_card_queue.csv`
  - `catalog/exports/move_animation_queue.csv`
  - `catalog/exports/animation_asset_status.csv`
- Operator outputs:
  - `catalog/exports/grok_operator_state.csv`
  - `catalog/exports/grok_operator_log.csv`

## Main scripts

- Python operator:
  - `scripts/grok_operator_queue.py`
- Shell helper:
  - `scripts/grok_next.sh`

## Safe behavior

- Copies the prompt to the macOS clipboard with `pbcopy`
- Opens the expected output folder in Finder
- Waits for explicit operator confirmation before promoting a downloaded file
- Preserves the original file in `~/Downloads`
- Copies into the canonical asset path instead of deleting the download
- Logs every completion, skip, or failure with timestamp and source path
- Refreshes local tracker exports after confirmed completions

## Typical workflow

Title cards first:

```bash
python3 scripts/grok_operator_queue.py --next --queue title
```

Moves after title cards:

```bash
python3 scripts/grok_operator_queue.py --next --queue move
```

Process multiple queued items in order:

```bash
python3 scripts/grok_operator_queue.py --next --queue title --limit 5
```

Dry-run preview:

```bash
python3 scripts/grok_operator_queue.py --next --dry-run --limit 3
```

Shell helper:

```bash
scripts/grok_next.sh --queue title
```

## Commands

Preview or process next items:

```bash
python3 scripts/grok_operator_queue.py --next [--queue title|move|all] [--limit N] [--dry-run]
```

Show status:

```bash
python3 scripts/grok_operator_queue.py --status [--queue title|move|all]
```

Manually mark a title card complete:

```bash
python3 scripts/grok_operator_queue.py --mark-complete --queue title --id 1 --source ~/Downloads/file.mp4
```

Manually mark a move complete:

```bash
python3 scripts/grok_operator_queue.py --mark-complete --queue move --id 1 --move-index 1 --source ~/Downloads/file.mp4
```

Skip an item:

```bash
python3 scripts/grok_operator_queue.py --skip --queue title --id 1 --notes "bad render"
```

## What happens during `--next`

1. Reads the next incomplete queue item
2. Prints queue type, character name, asset type, prompt, and canonical output path
3. Copies the prompt to the clipboard
4. Opens the target folder in Finder
5. Waits for Enter after Grok generation/download
6. Scans `~/Downloads` for the newest media file
7. Opens that candidate file
8. Requests confirmation
9. Copies the confirmed file into the canonical output path
10. Appends operator state/log rows
11. Refreshes local CSV exports

## Notes

- Queue ordering always prefers title cards before move animations when `--queue all` is used.
- The script treats existing canonical outputs as complete regardless of operator state rows.
- Google Sheets are not required for this workflow.
