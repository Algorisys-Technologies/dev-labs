package models

type Server struct {
	Name                         string `json:"Name"`
	IPAddress                    string `json:"IPAddress"`
	IPv6Address                  string `json:"IPv6Address"`
	PortNumber                   int    `json:"PortNumber"`
	ClientMessagePortNumber      int    `json:"ClientMessagePortNumber"`
	HTTPPortNumber               int    `json:"HTTPPortNumber"`
	UsingSSL                     bool   `json:"UsingSSL"`
	AcceptingClients             bool   `json:"AcceptingClients"`
	SelfRegistered               bool   `json:"SelfRegistered"`
	Host                         string `json:"Host"`
	IsLocal                      bool   `json:"IsLocal"`
	SSLCertificateID             string `json:"SSLCertificateID"`
	SSLCertificateAuthority      string `json:"SSLCertificateAuthority"`
	SSLCertificateRevocationList string `json:"SSLCertificateRevocationList"`
	ClientExportSSLSvrKeyID      string `json:"ClientExportSSLSvrKeyID"`
	ClientExportSSLSvrCert       string `json:"ClientExportSSLSvrCert"`
	LastUpdated                  string `json:"LastUpdated"`
}
