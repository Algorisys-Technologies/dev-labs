package services

type ServerService struct {
	rest            *RestService
	TransactionLogs *TransactionLogService
	MessageLogs     *MessageLogService
	Configuration   *ConfigurationService
	AuditLogs       *AuditLogService
	Loggers         *LoggerService
}

func NewServerService(rest *RestService) *ServerService {
	return &ServerService{
		rest:            rest,
		TransactionLogs: NewTransactionLogService(rest),
		MessageLogs:     NewMessageLogService(rest),
		Configuration:   NewConfigurationService(rest),
		AuditLogs:       NewAuditLogService(rest),
		Loggers:         NewLoggerService(rest),
	}
}

func (s *ServerService) GetServerName() (string, error) {
	return s.Configuration.GetServerName()
}

func (s *ServerService) GetProductVersion() (string, error) {
	return s.Configuration.GetProductVersion()
}

func (s *ServerService) GetConfiguration() (map[string]interface{}, error) {
	return s.Configuration.GetAll()
}

func (s *ServerService) GetStaticConfiguration() (map[string]interface{}, error) {
	return s.Configuration.GetStatic()
}

func (s *ServerService) UpdateStaticConfiguration(config map[string]interface{}) ([]byte, error) {
	return s.Configuration.UpdateStatic(config)
}

func (s *ServerService) SaveData() ([]byte, error) {
	// Execute TI Code SaveDataAll;
	processService := NewProcessService(s.rest)
	return processService.Execute("SaveDataAll", nil) // Simplified, actual TM1py uses unbound TI
}
