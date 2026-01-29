package cubecalc

import (
	"errors"
	"math"
	"sort"
	"time"
)

// PV calculates the Present Value
func PV(rate, nper, pmt, fv float64, when int) float64 {
	if rate == 0 {
		return -1 * (fv + pmt*nper)
	}
	temp := math.Pow(1+rate, nper)
	return -1 * (fv + pmt*(1+rate*float64(when))*(temp-1)/rate) / temp
}

// FV calculates the Future Value
func FV(rate, nper, pmt, pv float64, when int) float64 {
	if rate == 0 {
		return -1 * (pv + pmt*nper)
	}
	temp := math.Pow(1+rate, nper)
	return -1 * (pv*temp + pmt*(1+rate*float64(when))*(temp-1)/rate)
}

// NPV calculates the Net Present Value
func NPV(rate float64, values []float64) float64 {
	npv := 0.0
	for i, v := range values {
		npv += v / math.Pow(1+rate, float64(i))
	}
	return npv
}

// XNPV calculates Net Present Value for non-periodic cash flows
func XNPV(rate float64, values []float64, dates []time.Time) (float64, error) {
	if len(values) != len(dates) {
		return 0, errors.New("values and dates must be same length")
	}
	xnpv := 0.0
	firstDate := dates[0]
	for i := 0; i < len(values); i++ {
		days := dates[i].Sub(firstDate).Hours() / 24.0
		xnpv += values[i] / math.Pow(1+rate, days/365.0)
	}
	return xnpv, nil
}

// XIRR calculates Internal Rate of Return for non-periodic cash flows
func XIRR(values []float64, dates []time.Time) (float64, error) {
	guess := 0.1
	for i := 0; i < 100; i++ {
		f, _ := XNPV(guess, values, dates)
		// df/dr of XNPV
		df := 0.0
		firstDate := dates[0]
		for j := 0; j < len(values); j++ {
			days := dates[j].Sub(firstDate).Hours() / 24.0
			df += values[j] * (-days / 365.0) * math.Pow(1+guess, -(days/365.0)-1)
		}
		if math.Abs(df) < 1e-12 {
			break
		}
		newGuess := guess - f/df
		if math.Abs(newGuess-guess) < 1e-9 {
			return newGuess, nil
		}
		guess = newGuess
	}
	return guess, nil
}

// MIRR calculates Modified Internal Rate of Return
func MIRR(values []float64, financeRate, reinvestRate float64) float64 {
	n := float64(len(values)) - 1
	pos := make([]float64, len(values))
	neg := make([]float64, len(values))
	for i, v := range values {
		if v >= 0 {
			pos[i] = v
		} else {
			neg[i] = v
		}
	}

	pvNeg := NPV(financeRate, neg)
	fvPos := NPV(reinvestRate, pos) * math.Pow(1+reinvestRate, n)

	return math.Pow(fvPos/-pvNeg, 1/n) - 1
}

// NPer calculates number of periods
func NPer(rate, pmt, pv, fv float64, when int) float64 {
	if rate == 0 {
		return -(fv + pv) / pmt
	}
	z := pmt * (1 + rate*float64(when)) / rate
	return math.Log((-fv+z)/(pv+z)) / math.Log(1+rate)
}

// PMT calculates the periodical payment
func PMT(rate, nper, pv, fv float64, when int) float64 {
	if rate == 0 {
		return -1 * (fv + pv) / nper
	}
	temp := math.Pow(1+rate, nper)
	return -1 * (fv + pv*temp) * rate / (temp - 1) / (1 + rate*float64(when))
}

// IRR calculates Internal Rate of Return using Newton's method
func IRR(values []float64) (float64, error) {
	// A simple Newton's method implementation
	guess := 0.1
	for i := 0; i < 100; i++ {
		f := NPV(guess, values)
		// derivative of NPV: sum -i * V_i / (1+r)^(i+1)
		df := 0.0
		for j, v := range values {
			df += float64(-j) * v / math.Pow(1+guess, float64(j+1))
		}
		if math.Abs(df) < 1e-12 {
			break
		}
		newGuess := guess - f/df
		if math.Abs(newGuess-guess) < 1e-9 {
			return newGuess, nil
		}
		guess = newGuess
	}
	return guess, nil // Return best guess if not converged
}

// Mean calculates the average of values
func Mean(values []float64) float64 {
	if len(values) == 0 {
		return 0
	}
	sum := 0.0
	for _, v := range values {
		sum += v
	}
	return sum / float64(len(values))
}

// Median calculates the middle value
func Median(values []float64) float64 {
	if len(values) == 0 {
		return 0
	}
	temp := make([]float64, len(values))
	copy(temp, values)
	sort.Float64s(temp)
	n := len(temp)
	if n%2 == 1 {
		return temp[n/2]
	}
	return (temp[n/2-1] + temp[n/2]) / 2.0
}

// StDev calculates the standard deviation
func StDev(values []float64, population bool) float64 {
	if len(values) < 2 {
		return 0
	}
	mean := Mean(values)
	sumSqDiff := 0.0
	for _, v := range values {
		sumSqDiff += math.Pow(v-mean, 2)
	}
	denom := float64(len(values))
	if !population {
		denom -= 1
	}
	return math.Sqrt(sumSqDiff / denom)
}
