package models

type GitCommit struct {
	ID      string `json:"ID,omitempty"`
	Summary string `json:"Summary,omitempty"`
	Author  string `json:"Author,omitempty"`
}

type GitRemote struct {
	Connected bool     `json:"Connected"`
	Branches  []string `json:"Branches"`
	Tags      []string `json:"Tags"`
}

type Git struct {
	URL            string                 `json:"URL"`
	Deployment     string                 `json:"Deployment"`
	Force          bool                   `json:"Force"`
	DeployedCommit GitCommit              `json:"DeployedCommit"`
	Remote         GitRemote              `json:"Remote"`
	Config         map[string]interface{} `json:"Config,omitempty"`
}

type GitPlan struct {
	ID     string `json:"ID"`
	Branch string `json:"Branch"`
	Force  bool   `json:"Force"`
}

type GitPushPlan struct {
	GitPlan
	NewBranch    string    `json:"NewBranch"`
	NewCommit    GitCommit `json:"NewCommit"`
	ParentCommit GitCommit `json:"ParentCommit"`
	SourceFiles  []string  `json:"SourceFiles"`
}

type GitPullPlan struct {
	GitPlan
	Commit     GitCommit `json:"Commit"`
	Operations []string  `json:"Operations"`
}
