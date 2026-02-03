package utils

import (
	"fmt"
	"net/url"
	"strings"
)

func LowerAndDropSpaces(s string) string {
	return strings.ReplaceAll(strings.ToLower(s), " ", "")
}

func CaseAndSpaceInsensitiveEquals(s1, s2 string) bool {
	return LowerAndDropSpaces(s1) == LowerAndDropSpaces(s2)
}

func BuildUrlFriendlyObjectName(name string) string {
	res := strings.ReplaceAll(name, "'", "''")
	res = strings.ReplaceAll(res, "%", "%25")
	res = strings.ReplaceAll(res, "#", "%23")
	res = strings.ReplaceAll(res, "?", "%3F")
	res = strings.ReplaceAll(res, "&", "%26")
	return res
}

func FormatUrl(path string, args ...interface{}) string {
	formattedArgs := make([]interface{}, len(args))
	for i, arg := range args {
		if s, ok := arg.(string); ok {
			formattedArgs[i] = BuildUrlFriendlyObjectName(s)
		} else {
			formattedArgs[i] = arg
		}
	}
	return fmt.Sprintf(path, formattedArgs...)
}

func IntegerizeVersion(version string, precision int) int {
	clean := strings.ReplaceAll(version, ".", "")
	if len(clean) > precision {
		clean = clean[:precision]
	} else {
		for len(clean) < precision {
			clean += "0"
		}
	}
	var res int
	fmt.Sscanf(clean, "%d", &res)
	return res
}

func VerifyVersion(requiredVersion, currentVersion string) bool {
	precision := len(strings.ReplaceAll(requiredVersion, ".", ""))
	expected := IntegerizeVersion(requiredVersion, precision)
	actual := IntegerizeVersion(currentVersion, precision)
	return actual >= expected
}

func AddUrlParameters(baseUrl string, params map[string]string) string {
	u, err := url.Parse(baseUrl)
	if err != nil {
		return baseUrl
	}
	q := u.Query()
	for k, v := range params {
		if v != "" {
			q.Set(k, v)
		}
	}
	u.RawQuery = q.Encode()
	return u.String()
}

// CaseAndSpaceInsensitiveMap is a helper for TM1 object/element lookups
type CaseAndSpaceInsensitiveMap struct {
	internal map[string]interface{}
}

func NewCaseAndSpaceInsensitiveMap() *CaseAndSpaceInsensitiveMap {
	return &CaseAndSpaceInsensitiveMap{internal: make(map[string]interface{})}
}

func (m *CaseAndSpaceInsensitiveMap) Set(key string, value interface{}) {
	m.internal[LowerAndDropSpaces(key)] = value
}

func (m *CaseAndSpaceInsensitiveMap) Get(key string) (interface{}, bool) {
	val, ok := m.internal[LowerAndDropSpaces(key)]
	return val, ok
}

func ExtractUniqueNamesFromMembers(members []map[string]interface{}) []string {
	res := make([]string, len(members))
	for i, m := range members {
		if elem, ok := m["Element"].(map[string]interface{}); ok && elem != nil {
			res[i] = elem["UniqueName"].(string)
		} else {
			res[i] = m["UniqueName"].(string)
		}
	}
	return res
}

func ExtractElementNamesFromMembers(members []map[string]interface{}) []string {
	res := make([]string, len(members))
	for i, m := range members {
		if elem, ok := m["Element"].(map[string]interface{}); ok && elem != nil {
			res[i] = elem["Name"].(string)
		} else {
			res[i] = m["Name"].(string)
		}
	}
	return res
}

func SortCoordinates(cubeDimensions []string, unsortedCoordinates []string, elementsUniqueNames bool) []string {
	sorted := make([]string, 0, len(cubeDimensions))
	for _, dim := range cubeDimensions {
		for _, coord := range unsortedCoordinates {
			if strings.HasPrefix(coord, "["+dim+"].") {
				if elementsUniqueNames {
					sorted = append(sorted, coord)
				} else {
					sorted = append(sorted, ElementNameFromUniqueName(coord))
				}
				break
			}
		}
	}
	return sorted
}

func ElementNameFromUniqueName(uniqueName string) string {
	lastDot := strings.LastIndex(uniqueName, "].[")
	if lastDot == -1 {
		return strings.Trim(uniqueName, "[]")
	}
	res := uniqueName[lastDot+3 : len(uniqueName)-1]
	return strings.ReplaceAll(res, "]]", "]")
}

func DimensionNameFromUniqueName(uniqueName string) string {
	firstDot := strings.Index(uniqueName, "].[")
	if firstDot == -1 {
		return strings.Trim(uniqueName, "[]")
	}
	return uniqueName[1:firstDot]
}

func ExtractAxesFromCellset(rawCellset map[string]interface{}) []map[string]interface{} {
	axes, ok := rawCellset["Axes"].([]interface{})
	if !ok {
		return nil
	}
	res := make([]map[string]interface{}, 0)
	for _, axis := range axes {
		if a, ok := axis.(map[string]interface{}); ok {
			tuples, ok := a["Tuples"].([]interface{})
			if ok && len(tuples) > 0 {
				res = append(res, a)
			}
		}
	}
	return res
}

func BuildContentFromCellset(rawCellset map[string]interface{}, top int, elementsUniqueNames bool, skipCellProperties bool) map[string]interface{} {
	cube, _ := rawCellset["Cube"].(map[string]interface{})
	dims, _ := cube["Dimensions"].([]interface{})
	cubeDimensions := make([]string, len(dims))
	for i, d := range dims {
		dm, _ := d.(map[string]interface{})
		cubeDimensions[i] = dm["Name"].(string)
	}

	cells, _ := rawCellset["Cells"].([]interface{})
	axes := ExtractAxesFromCellset(rawCellset)

	content := make(map[string]interface{})

	limit := len(cells)
	if top > 0 && top < limit {
		limit = top
	}

	for ordinal := 0; ordinal < limit; ordinal++ {
		cell, _ := cells[ordinal].(map[string]interface{})
		cellOrdinal := ordinal
		if ord, ok := cell["Ordinal"].(float64); ok {
			cellOrdinal = int(ord)
		}

		coordinates := make([]string, 0)
		for axisOrdinal, axis := range axes {
			cardinality := int(axis["Cardinality"].(float64))
			tuples, _ := axis["Tuples"].([]interface{})

			if axisOrdinal == 0 {
				indexColumns := cellOrdinal % cardinality
				tuple, _ := tuples[indexColumns].(map[string]interface{})
				members, _ := tuple["Members"].([]interface{})

				memberMaps := make([]map[string]interface{}, len(members))
				for i, m := range members {
					memberMaps[i] = m.(map[string]interface{})
				}
				coordinates = append(coordinates, ExtractUniqueNamesFromMembers(memberMaps)...)
			} else {
				tupleOrdinal := cellOrdinal
				for i := 0; i < axisOrdinal; i++ {
					prevCardinality := int(axes[i]["Cardinality"].(float64))
					tupleOrdinal = tupleOrdinal / prevCardinality
				}
				tupleOrdinal = tupleOrdinal % cardinality
				tuple, _ := tuples[tupleOrdinal].(map[string]interface{})
				members, _ := tuple["Members"].([]interface{})

				memberMaps := make([]map[string]interface{}, len(members))
				for i, m := range members {
					memberMaps[i] = m.(map[string]interface{})
				}
				coordinates = append(coordinates, ExtractUniqueNamesFromMembers(memberMaps)...)
			}
		}

		sortedCoordinates := SortCoordinates(cubeDimensions, coordinates, elementsUniqueNames)
		key := strings.Join(sortedCoordinates, "|")

		if skipCellProperties {
			content[key] = cell["Value"]
		} else {
			content[key] = cell
		}
	}

	return content
}
