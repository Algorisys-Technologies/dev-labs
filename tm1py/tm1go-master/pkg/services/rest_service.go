package services

import (
	"bytes"
	"crypto/tls"
	"encoding/base64"
	"fmt"
	"io"
	"net/http"
	"net/http/cookiejar"
)

type RestService struct {
	client       *http.Client
	baseURL      string
	databaseName string
	headers      map[string]string
}

func NewRestService(address string, port int, ssl bool, user, password, namespace, databaseName string) (*RestService, error) {
	jar, _ := cookiejar.New(nil)
	tr := &http.Transport{
		TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
	}
	client := &http.Client{
		Transport: tr,
		Jar:       jar,
	}

	protocol := "http"
	if ssl {
		protocol = "https"
	}
	baseURL := fmt.Sprintf("%s://%s:%d/tm1/api/%s/api/v1", protocol, address, port, databaseName)
	if databaseName == "" {
		baseURL = fmt.Sprintf("%s://%s:%d/api/v1", protocol, address, port)
	}

	rs := &RestService{
		client:       client,
		baseURL:      baseURL,
		databaseName: databaseName,
		headers: map[string]string{
			"Connection":         "keep-alive",
			"User-Agent":         "tm1go",
			"Content-Type":       "application/json; odata.streaming=true; charset=utf-8",
			"Accept":             "application/json;odata.metadata=none,text/plain",
			"TM1-SessionContext": "tm1go",
		},
	}

	// Handle Authorization
	if user != "" && password != "" {
		if namespace != "" {
			// CAM Authentication
			token := fmt.Sprintf("%s:%s:%s", user, password, namespace)
			encodedToken := base64.StdEncoding.EncodeToString([]byte(token))
			rs.headers["Authorization"] = "CAMNamespace " + encodedToken
		} else {
			// Basic Authentication
			token := fmt.Sprintf("%s:%s", user, password)
			encodedToken := base64.StdEncoding.EncodeToString([]byte(token))
			rs.headers["Authorization"] = "Basic " + encodedToken
		}
	}

	return rs, nil
}

func (rs *RestService) Request(method, url string, data []byte) (*http.Response, error) {
	fullURL := rs.baseURL + url
	req, err := http.NewRequest(method, fullURL, bytes.NewBuffer(data))
	if err != nil {
		return nil, err
	}

	for k, v := range rs.headers {
		req.Header.Set(k, v)
	}

	return rs.client.Do(req)
}

func (rs *RestService) GET(url string) ([]byte, error) {
	resp, err := rs.Request("GET", url, nil)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 400 {
		return nil, fmt.Errorf("HTTP error: %d", resp.StatusCode)
	}

	return io.ReadAll(resp.Body)
}

func (rs *RestService) POST(url string, data []byte) ([]byte, error) {
	resp, err := rs.Request("POST", url, data)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 400 {
		return nil, fmt.Errorf("HTTP error: %d", resp.StatusCode)
	}

	return io.ReadAll(resp.Body)
}
