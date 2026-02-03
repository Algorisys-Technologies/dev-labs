package services

import (
	"tm1go/pkg/models"
)

type MonitoringService struct {
	rest    *RestService
	users   *UserService
	threads *ThreadService
	session *SessionService
}

func NewMonitoringService(rest *RestService) *MonitoringService {
	return &MonitoringService{
		rest:    rest,
		users:   NewUserService(rest),
		threads: NewThreadService(rest),
		session: NewSessionService(rest),
	}
}

func (s *MonitoringService) GetThreads() ([]map[string]interface{}, error) {
	return s.threads.GetAll()
}

func (s *MonitoringService) GetActiveThreads() ([]map[string]interface{}, error) {
	return s.threads.GetActive()
}

func (s *MonitoringService) CancelThread(threadID int) error {
	return s.threads.Cancel(threadID)
}

func (s *MonitoringService) GetActiveUsers() ([]*models.User, error) {
	return s.users.GetActive()
}

func (s *MonitoringService) UserIsActive(userName string) (bool, error) {
	return s.users.IsActive(userName)
}

func (s *MonitoringService) DisconnectUser(userName string) error {
	return s.users.Disconnect(userName)
}

func (s *MonitoringService) GetSessions(includeUser, includeThreads bool) ([]map[string]interface{}, error) {
	return s.session.GetAll(includeUser, includeThreads)
}

func (s *MonitoringService) GetActiveSessionThreads(excludeIdle bool) ([]map[string]interface{}, error) {
	return s.session.GetThreadsForCurrent(excludeIdle)
}

func (s *MonitoringService) CloseSession(sessionID string) error {
	return s.session.Close(sessionID)
}

func (s *MonitoringService) GetCurrentUser() (*models.User, error) {
	return s.users.GetCurrent()
}
