package services

type PowerBiService struct {
	rest     *RestService
	cells    *CellService
	elements *ElementService
}

func NewPowerBiService(rest *RestService) *PowerBiService {
	return &PowerBiService{
		rest:     rest,
		cells:    &CellService{rest: rest},
		elements: NewElementService(rest),
	}
}

func (s *PowerBiService) ExecuteMDX(mdx string) (interface{}, error) {
	// In Go we'll probably return a custom struct or map for PowerBI
	return s.cells.ExecuteMDX(mdx)
}
