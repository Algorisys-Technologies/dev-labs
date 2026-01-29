package models

import (
	"encoding/json"
	"fmt"
)

type User struct {
	Name         string   `json:"Name"`
	FriendlyName string   `json:"FriendlyName"`
	Enabled      bool     `json:"Enabled"`
	Password     string   `json:"Password,omitempty"`
	Type         string   `json:"Type"`
	Groups       []string `json:"-"`
}

func (u *User) MapToTM1Body() (string, error) {
	type userBody struct {
		Name         string   `json:"Name"`
		FriendlyName string   `json:"FriendlyName"`
		Enabled      bool     `json:"Enabled"`
		Type         string   `json:"Type"`
		Password     string   `json:"Password,omitempty"`
		GroupsBind   []string `json:"Groups@odata.bind,omitempty"`
	}

	body := userBody{
		Name:         u.Name,
		FriendlyName: u.FriendlyName,
		Enabled:      u.Enabled,
		Type:         u.Type,
		Password:     u.Password,
	}

	if len(u.Groups) > 0 {
		body.GroupsBind = make([]string, len(u.Groups))
		for i, group := range u.Groups {
			body.GroupsBind[i] = fmt.Sprintf("Groups('%s')", group)
		}
	}

	jsonBytes, err := json.Marshal(body)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func (u *User) UnmarshalJSON(data []byte) error {
	type Alias User
	aux := &struct {
		Groups []struct {
			Name string `json:"Name"`
		} `json:"Groups"`
		*Alias
	}{
		Alias: (*Alias)(u),
	}
	if err := json.Unmarshal(data, &aux); err != nil {
		return err
	}
	u.Groups = make([]string, len(aux.Groups))
	for i, g := range aux.Groups {
		u.Groups[i] = g.Name
	}
	return nil
}
