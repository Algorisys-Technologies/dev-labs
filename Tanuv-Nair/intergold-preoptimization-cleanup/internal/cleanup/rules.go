package cleanup

import (
	"fmt"
	"strconv"
	"strings"
	"time"

	"intergold-preoptimization-cleanup/internal/process_map"
)

const (
	processDateLayout = "02-01-2006" // dd-mm-yyyy
	sentinelDateStr   = "01-01-1900"
)

func excelColumnLabelToIndex(label string) (int, error) {
	// Excel letters: A=0, B=1, ..., Z=25, AA=26, etc.
	// We intentionally accept only uppercase letters to match expectations in tests.
	if label == "" {
		return 0, fmt.Errorf("empty label")
	}
	for i := 0; i < len(label); i++ {
		ch := label[i]
		if ch < 'A' || ch > 'Z' {
			return 0, fmt.Errorf("invalid label %q: must be A-Z", label)
		}
	}

	n := 0
	for i := 0; i < len(label); i++ {
		n = n*26 + int(label[i]-'A'+1)
	}
	return n - 1, nil
}

func colIndexFromEnvValue(v string) (int, error) {
	// Configuration values should not contain accidental whitespace (e.g. "AA ").
	if v == "" {
		return 0, fmt.Errorf("empty value")
	}
	if strings.TrimSpace(v) != v {
		return 0, fmt.Errorf("invalid value %q: must not contain leading/trailing whitespace", v)
	}

	if n, err := strconv.Atoi(v); err == nil {
		if n < 0 {
			return 0, fmt.Errorf("invalid numeric index %q: must be >= 0", v)
		}
		return n, nil
	}

	// If not numeric, treat it as Excel column letters (A, B, ..., AA, ...).
	return excelColumnLabelToIndex(v)
}

func parseProcessDateDDMMYYYYOrNull(s string, currentYear, windowX int) (time.Time, bool, error) {
	s = strings.TrimSpace(s)
	if s == "" {
		return time.Time{}, false, nil
	}
	if s == sentinelDateStr {
		return time.Time{}, false, nil
	}

	t, err := time.Parse(processDateLayout, s)
	if err != nil {
		return time.Time{}, false, fmt.Errorf("parse date %q: %w", s, err)
	}

	// The input uses 01-01-1900 as a sentinel for "null/invalid date".
	if t.Year() == 1900 && t.Month() == time.January && t.Day() == 1 {
		return time.Time{}, false, nil
	}

	y := t.Year()
	if y < currentYear-windowX || y > currentYear+windowX {
		return time.Time{}, false, nil
	}
	return t, true, nil
}

// adjustBusinessDays moves a date along the business-day calendar (Mon-Sat excluding
// holidays; Sunday is non-business).
//
//   - delta == 0: snap start to a business day — keep the same calendar day if it is
//     already Mon-Sat and not a holiday; otherwise advance to the next business day.
//   - delta > 0: move forward that many business-day steps (each step: next calendar
//     day, then skip non-business days).
//   - delta < 0: returns start unchanged (backward stepping is not supported).
func adjustBusinessDays(start time.Time, delta int, isHoliday func(time.Time) bool) time.Time {
	if isHoliday == nil {
		isHoliday = func(time.Time) bool { return false }
	}
	if delta < 0 {
		return start
	}
	if delta == 0 {
		candidate := dateOnlyUTC(start)
		for {
			if candidate.Weekday() != time.Sunday && !isHoliday(dateOnlyUTC(candidate)) {
				return candidate
			}
			candidate = candidate.AddDate(0, 0, 1)
		}
	}

	// Make date math deterministic.
	t := start.In(time.UTC)

	// For each "step", move to the next calendar day, then advance until you
	// land on a business day.
	for step := 0; step < delta; step++ {
		candidate := t.AddDate(0, 0, 1)
		for {
			weekday := candidate.Weekday()
			isWeekend := weekday == time.Sunday
			isHol := isHoliday(dateOnlyUTC(candidate))
			if !isWeekend && !isHol {
				break
			}
			candidate = candidate.AddDate(0, 0, 1)
		}
		t = candidate
	}
	return t
}

func dateOnlyUTC(t time.Time) time.Time {
	u := t.In(time.UTC)
	return time.Date(u.Year(), u.Month(), u.Day(), 0, 0, 0, 0, time.UTC)
}

type RulesConfig struct {
	ProdEndDtColIndex int
	BLOCColIndex      int

	FirstBlocProcessColIndex int
	LastBlocProcessColIndex  int

	// NULL_DATE_YEAR_WINDOW_X controls which years are treated as valid. Dates
	// outside [currentYear-X, currentYear+X] are treated as null/invalid.
	NullDateYearWindowX int

	RemarksExtensionNeeded string
}

func formatDDMMYYYY(d time.Time) string {
	return d.In(time.UTC).Format(processDateLayout)
}

func headerNameToIndex(header []string) map[string]int {
	out := make(map[string]int, len(header))
	for i := range header {
		if header[i] == "" {
			continue
		}
		// Keep first match (stable behavior).
		if _, exists := out[header[i]]; !exists {
			out[header[i]] = i
		}
	}
	return out
}

// ApplyRulesToRow applies the bloc-process scheduling/extension rules for a
// single CSV data row.
//
// row is expected to be a data-row only (no header, and no trailing Remarks).
func ApplyRulesToRow(
	header []string,
	row []string,
	cfg RulesConfig,
	processMap process_map.ProcessMap,
	now time.Time,
	holidays func(time.Time) bool,
) ([]string, string, error) {
	now = dateOnlyUTC(now)

	if cfg.ProdEndDtColIndex < 0 || cfg.ProdEndDtColIndex >= len(row) {
		return nil, "", fmt.Errorf("ProdEndDtColIndex out of range: %d", cfg.ProdEndDtColIndex)
	}
	if cfg.BLOCColIndex < 0 || cfg.BLOCColIndex >= len(row) {
		return nil, "", fmt.Errorf("BLOCColIndex out of range: %d", cfg.BLOCColIndex)
	}
	if cfg.FirstBlocProcessColIndex < 0 || cfg.LastBlocProcessColIndex < cfg.FirstBlocProcessColIndex {
		return nil, "", fmt.Errorf("invalid process column bounds")
	}
	if cfg.LastBlocProcessColIndex >= len(row) {
		return nil, "", fmt.Errorf("LastBlocProcessColIndex out of range: %d", cfg.LastBlocProcessColIndex)
	}

	updatedRow := append([]string{}, row...)

	holFn := holidays
	if holFn == nil {
		holFn = func(time.Time) bool { return false }
	}

	prodEndDt, prodEndOk, err := parseProcessDateDDMMYYYYOrNull(updatedRow[cfg.ProdEndDtColIndex], now.Year(), cfg.NullDateYearWindowX)
	if err != nil {
		return nil, "", err
	}

	blocCode := strings.TrimSpace(updatedRow[cfg.BLOCColIndex])
	if blocCode == "" {
		return nil, "", fmt.Errorf("empty bloc code")
	}

	mappedValues := processMap[blocCode]
	if len(mappedValues) == 0 {
		return nil, "", fmt.Errorf("no process mapping for bloc %q", blocCode)
	}

	nameToIndex := headerNameToIndex(header)
	startColName := mappedValues[0]
	startColIndex, exists := nameToIndex[startColName]
	if !exists {
		return nil, "", fmt.Errorf("mapped start column %q not found in header", startColName)
	}

	// The process columns we scan are the configured last range.
	scanStart := startColIndex
	if scanStart < cfg.FirstBlocProcessColIndex {
		// Be defensive: cap to configured window.
		scanStart = cfg.FirstBlocProcessColIndex
	}
	if scanStart > cfg.LastBlocProcessColIndex {
		return nil, "", fmt.Errorf("scanStart > LastBlocProcessColIndex")
	}

	// Sentinel/null ProdEndDt: we cannot safely check the undo condition, so
	// treat as an extension-needed scenario with no date changes.
	if !prodEndOk {
		return updatedRow, fmt.Sprintf("No changes made; %s", cfg.RemarksExtensionNeeded), nil
	}

	prodEndDt = dateOnlyUTC(prodEndDt)
	nowDate := now

	// Case 1: ProdEndDt < CurrentDate
	if prodEndDt.Before(nowDate) {
		if blocCode != "RPOL" {
			return updatedRow, fmt.Sprintf("No changes made; %s", cfg.RemarksExtensionNeeded), nil
		}

		// RPOL: update mapped column.
		newDate := adjustBusinessDays(nowDate, 0, holFn)
		updatedRow[startColIndex] = formatDDMMYYYY(newDate)

		return updatedRow, fmt.Sprintf("Updated: %s; changes made", header[startColIndex]), nil
	}

	// Case 2: ProdEndDt >= CurrentDate
	updatedSet := make(map[int]bool)
	originalValues := make(map[int]string)
	updatedIndices := make([]int, 0, cfg.LastBlocProcessColIndex-scanStart+1)

	setUpdated := func(col int, newVal string) {
		if !updatedSet[col] {
			updatedSet[col] = true
			originalValues[col] = updatedRow[col]
			updatedIndices = append(updatedIndices, col)
		}
		updatedRow[col] = newVal
	}

	// First iteration always sets the first eligible process column to CurrentDate
	// (as a business day; Sunday/holidays roll forward).
	baselineDate := adjustBusinessDays(nowDate, 0, holFn)
	prevUpdatedDate := baselineDate
	prevUpdatedCol := -1
	var prevExistingDate time.Time
	started := false

	// Evaluate scanStart first (the mapped start process column).
	scanExistingDate, scanExistingOk, parseErr := parseProcessDateDDMMYYYYOrNull(row[scanStart], now.Year(), cfg.NullDateYearWindowX)
	if parseErr != nil {
		return nil, "", parseErr
	}
	if scanExistingOk {
		if scanExistingDate.Before(nowDate) {
			setUpdated(scanStart, formatDDMMYYYY(prevUpdatedDate))
			started = true
			prevUpdatedCol = scanStart
			prevExistingDate = scanExistingDate
		} else {
			// Stop immediately: scanStart is already >= now.
			remarks := buildRemarks(header, scanStart, cfg.LastBlocProcessColIndex, updatedSet, "No changes made")
			return updatedRow, remarks, nil
		}
	}

	// Sequential updates from scanStart+1..Last.
	for col := scanStart + 1; col <= cfg.LastBlocProcessColIndex; col++ {
		currentExistingDate, currentOk, parseErr := parseProcessDateDDMMYYYYOrNull(row[col], now.Year(), cfg.NullDateYearWindowX)
		if parseErr != nil {
			return nil, "", parseErr
		}

		if !currentOk {
			// Skip invalid/null process dates entirely (do not update, do not
			// affect stop condition).
			continue
		}

		// Process date at/after the run date: either stop, or if it is still
		// before the last adjusted date in the chain, bump to
		// calendar(prevUpdatedDate+1) snapped to a business day and continue.
		if !currentExistingDate.Before(nowDate) {
			if !started || !currentExistingDate.Before(prevUpdatedDate) {
				tail := "changes made"
				if len(updatedSet) == 0 {
					tail = "No changes made"
				}
				remarks := buildRemarks(header, scanStart, cfg.LastBlocProcessColIndex, updatedSet, tail)
				return updatedRow, remarks, nil
			}
			bumped := dateOnlyUTC(prevUpdatedDate).AddDate(0, 0, 1)
			bumped = adjustBusinessDays(bumped, 0, holFn)
			setUpdated(col, formatDDMMYYYY(bumped))
			prevUpdatedDate = bumped
			prevUpdatedCol = col
			prevExistingDate = currentExistingDate
			continue
		}

		// currentExistingDate < nowDate => eligible for update.
		if !started {
			setUpdated(col, formatDDMMYYYY(prevUpdatedDate))
			started = true
			prevUpdatedCol = col
			prevExistingDate = currentExistingDate
			continue
		}

		// Keep updated values the same when the two original (pre-change)
		// process dates were equal.
		if currentExistingDate.Equal(prevExistingDate) {
			setUpdated(col, formatDDMMYYYY(prevUpdatedDate))
			prevUpdatedCol = col
			prevExistingDate = currentExistingDate
			continue
		}

		// Enforce a business-day gap between the previously updated process date
		// and the new updated date.
		minAllowed := adjustBusinessDays(prevUpdatedDate, 1, holFn)
		// PrePolish can be on the same day as Filing; don't force the +1 gap
		// specifically for this transition.
		if prevUpdatedCol >= 0 && header[prevUpdatedCol] == "Filing" && header[col] == "PrePolish" {
			minAllowed = prevUpdatedDate
		}
		nextDate := currentExistingDate
		if currentExistingDate.Before(minAllowed) {
			nextDate = minAllowed
		}

		setUpdated(col, formatDDMMYYYY(nextDate))
		prevUpdatedDate = nextDate
		prevUpdatedCol = col
		prevExistingDate = currentExistingDate
	}

	// Final iteration: last updated date may exceed ProdEndDt => undo.
	if len(updatedSet) > 0 && prevUpdatedDate.After(prodEndDt) {
		for col := range updatedSet {
			updatedRow[col] = originalValues[col]
		}
		// Undo restored all modified process columns back to their original values.
		// In this case, we must not report per-column updates.
		return updatedRow, fmt.Sprintf("No changes made; %s", cfg.RemarksExtensionNeeded), nil
	}

	tail := "changes made"
	if len(updatedSet) == 0 {
		tail = "No changes made"
	}
	remarks := buildRemarks(header, scanStart, cfg.LastBlocProcessColIndex, updatedSet, tail)
	return updatedRow, remarks, nil
}

func buildRemarks(header []string, scanStart, scanEnd int, updatedSet map[int]bool, tail string) string {
	updatedNames := make([]string, 0, len(updatedSet))
	for col := scanStart; col <= scanEnd; col++ {
		if updatedSet[col] {
			updatedNames = append(updatedNames, header[col])
		}
	}
	if len(updatedNames) == 0 {
		return tail
	}
	return fmt.Sprintf("Updated: %s; %s", strings.Join(updatedNames, ","), tail)
}
