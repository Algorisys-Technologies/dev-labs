package models

type TM1ProjectTask struct {
	TaskName     string                   `json:"-"`
	Chore        string                   `json:"Chore,omitempty"`
	Process      string                   `json:"Process,omitempty"`
	Parameters   []map[string]interface{} `json:"Parameters,omitempty"`
	Dependencies []string                 `json:"Dependencies,omitempty"`
	Precondition string                   `json:"Precondition,omitempty"`
}

func (t *TM1ProjectTask) MapToTM1Body() map[string]interface{} {
	body := make(map[string]interface{})
	if t.Chore != "" {
		body["Chore"] = t.Chore
	} else if t.Process != "" {
		body["Process"] = t.Process
		if t.Parameters != nil {
			body["Parameters"] = t.Parameters
		}
	}
	if t.Dependencies != nil {
		body["Dependencies"] = t.Dependencies
	}
	if t.Precondition != "" {
		body["Precondition"] = t.Precondition
	}
	return body
}

type TM1Project struct {
	Version    float64                   `json:"Version"`
	Name       string                    `json:"Name,omitempty"`
	Settings   map[string]interface{}    `json:"Settings,omitempty"`
	Tasks      map[string]TM1ProjectTask `json:"Tasks,omitempty"`
	Objects    map[string]interface{}    `json:"Objects,omitempty"`
	Ignore     []string                  `json:"Ignore,omitempty"`
	Files      []string                  `json:"Files,omitempty"`
	Deployment map[string]interface{}    `json:"Deployment,omitempty"`
	PrePush    []string                  `json:"PrePush,omitempty"`
	PostPush   []string                  `json:"PostPush,omitempty"`
	PrePull    []string                  `json:"PrePull,omitempty"`
	PostPull   []string                  `json:"PostPull,omitempty"`
}

func (p *TM1Project) MapToTM1Body() map[string]interface{} {
	body := make(map[string]interface{})
	body["Version"] = p.Version
	if p.Name != "" {
		body["Name"] = p.Name
	}
	if p.Settings != nil {
		body["Settings"] = p.Settings
	}
	if p.Tasks != nil {
		tasksBody := make(map[string]interface{})
		for name, task := range p.Tasks {
			tasksBody[name] = task.MapToTM1Body()
		}
		body["Tasks"] = tasksBody
	}
	if p.Objects != nil {
		body["Objects"] = p.Objects
	}
	if p.Ignore != nil {
		body["Ignore"] = p.Ignore
	}
	if p.Files != nil {
		body["Files"] = p.Files
	}
	if p.Deployment != nil {
		body["Deployment"] = p.Deployment
	}
	if p.PrePush != nil {
		body["PrePush"] = p.PrePush
	}
	if p.PostPush != nil {
		body["PostPush"] = p.PostPush
	}
	if p.PrePull != nil {
		body["PrePull"] = p.PrePull
	}
	if p.PostPull != nil {
		body["PostPull"] = p.PostPull
	}
	return body
}
