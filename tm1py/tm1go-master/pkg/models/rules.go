package models

import (
	"strings"
)

type Rules struct {
	Text           string   `json:"Rules"`
	RulesAnalytics []string `json:"-"`
}

func NewRules(text string) *Rules {
	r := &Rules{Text: text}
	r.InitAnalytics()
	return r
}

func (r *Rules) InitAnalytics() {
	lines := strings.Split(r.Text, "\n")
	var textWithoutComments []string
	for _, line := range lines {
		trimmed := strings.TrimSpace(line)
		if trimmed != "" && !strings.HasPrefix(trimmed, "#") {
			textWithoutComments = append(textWithoutComments, trimmed)
		}
	}

	joined := strings.Join(textWithoutComments, " ")
	statements := strings.Split(joined, ";")
	for _, s := range statements {
		trimmed := strings.TrimSpace(s)
		if trimmed != "" {
			r.RulesAnalytics = append(r.RulesAnalytics, strings.ToUpper(strings.ReplaceAll(trimmed, "\n", "")))
		}
	}
}

func (r *Rules) HasFeeders() bool {
	for _, s := range r.RulesAnalytics {
		if s == "FEEDERS" {
			return true
		}
	}
	return false
}

func (r *Rules) Skipcheck() bool {
	limit := 5
	if len(r.RulesAnalytics) < 5 {
		limit = len(r.RulesAnalytics)
	}
	for i := 0; i < limit; i++ {
		if r.RulesAnalytics[i] == "SKIPCHECK" {
			return true
		}
	}
	return false
}

func (r *Rules) Feedstrings() bool {
	limit := 5
	if len(r.RulesAnalytics) < 5 {
		limit = len(r.RulesAnalytics)
	}
	for i := 0; i < limit; i++ {
		if r.RulesAnalytics[i] == "FEEDSTRINGS" {
			return true
		}
	}
	return false
}

func (r *Rules) Undefvals() bool {
	limit := 5
	if len(r.RulesAnalytics) < 5 {
		limit = len(r.RulesAnalytics)
	}
	for i := 0; i < limit; i++ {
		if r.RulesAnalytics[i] == "UNDEFVALS" {
			return true
		}
	}
	return false
}
