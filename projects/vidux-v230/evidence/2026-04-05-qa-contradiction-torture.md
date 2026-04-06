# QA Contradiction Detection Torture Test

**Date:** 2026-04-05
**Task:** 3.2b
**Script:** `vidux-loop.sh` (contradiction detection subsystem)
**Test root:** `/tmp/vidux-qa-contradiction/`

## Results: 6/6 PASSED

| # | Name | Expected | Actual | Result |
|---|------|----------|--------|--------|
| 1 | DELETION overlap | `contradiction_warning: true`, matches contain "verbose" + "flag" | `true`, `[DELETION] overlap(3): --verbose,flag,re-add` | PASS |
| 2 | Below threshold (1 keyword) | `contradiction_warning: false` | `false` | PASS |
| 3 | Explicit `[Contradicts:]` tag | `contradiction_warning: true`, `contradicts_tag` non-empty | `true`, `contradicts_tag: [Contradicts: DL-1]` | PASS |
| 4 | RATE-LIMIT skip | `contradiction_warning: false` | `false` | PASS |
| 5 | No Decision Log section | all three fields false/empty | `false`, `""`, `""` | PASS |
| 6 | DIRECTION overlap | `contradiction_warning: true` | `true`, `[DIRECTION] overlap(2): postgres,storage` | PASS |

## Test Plan Details

### Test 1: DELETION overlap
- **Decision Log:** `[DELETION] Removed legacy --verbose flag. Do not re-add.`
- **Task:** `Re-add --verbose flag to the CLI`
- **Why it fires:** 3 keyword overlap (--verbose, flag, re-add) against DELETION entry, threshold is >= 2.

### Test 2: No overlap below threshold
- **Decision Log:** `[DELETION] Removed payment retry logic.`
- **Task:** `Add payment webhook handler`
- **Why it does NOT fire:** Only 1 keyword overlap ("payment"). "retry" vs "webhook" do not match. "logic" vs "handler" do not match. Below the >= 2 threshold.

### Test 3: Explicit tag
- **Decision Log:** `[DELETION] Removed the old caching layer for performance reasons.`
- **Task:** `Restore the old caching layer [Contradicts: DL-1]`
- **Why it fires:** Explicit `[Contradicts: DL-1]` tag in task description triggers unconditionally (line 126-130). Also caught by keyword overlap (3 words: caching, layer, old).

### Test 4: RATE-LIMIT skip
- **Decision Log:** `[RATE-LIMIT] Deploy limited to 3 per day.`
- **Task:** `Deploy the new feature`
- **Why it does NOT fire:** The keyword overlap check only runs against `[DELETION]` and `[DIRECTION]` entries (line 139). `[RATE-LIMIT]` entries are intentionally skipped because they are quantity-based, not subject-based contradictions.

### Test 5: No Decision Log
- **Plan has no `## Decision Log` section at all.**
- **Why all fields are false/empty:** No DL block to parse, so `DL_WARNING=false`, and keyword overlap loop never executes.

### Test 6: DIRECTION overlap
- **Decision Log:** `[DIRECTION] Chose SQLite over Postgres for storage.`
- **Task:** `Migrate storage to Postgres`
- **Why it fires:** 2 keyword overlap (postgres, storage) against DIRECTION entry, meets the >= 2 threshold. Note: "sqlite" is only in the DL entry, not the task, so it does not appear in the overlap set.

## Raw JSON Outputs

### Test 1
```json
{
  "contradiction_warning": true,
  "contradiction_matches": "[DELETION] overlap(3): --verbose,flag,re-add",
  "contradicts_tag": ""
}
```

### Test 2
```json
{
  "contradiction_warning": false,
  "contradiction_matches": "",
  "contradicts_tag": ""
}
```

### Test 3
```json
{
  "contradiction_warning": true,
  "contradiction_matches": "explicit: [Contradicts: DL-1]; [DELETION] overlap(3): caching,layer,old",
  "contradicts_tag": "[Contradicts: DL-1]"
}
```

### Test 4
```json
{
  "contradiction_warning": false,
  "contradiction_matches": "",
  "contradicts_tag": ""
}
```

### Test 5
```json
{
  "contradiction_warning": false,
  "contradiction_matches": "",
  "contradicts_tag": ""
}
```

### Test 6
```json
{
  "contradiction_warning": true,
  "contradiction_matches": "[DIRECTION] overlap(2): postgres,storage",
  "contradicts_tag": ""
}
```
