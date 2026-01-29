package services

import (
	"os"
	"strconv"
	"strings"
)

// TM1Service is the main entry point for the TM1 API
type TM1Service struct {
	Rest            *RestService
	Cubes           *CubeService
	Dimensions      *DimensionService
	Hierarchies     *HierarchyService
	Subsets         *SubsetService
	Views           *ViewService
	Processes       *ProcessService
	Chores          *ChoreService
	Elements        *ElementService
	Cells           *CellService
	Users           *UserService
	Security        *SecurityService
	Sessions        *SessionService
	Server          *ServerService
	Configuration   *ConfigurationService
	MessageLogs     *MessageLogService
	TransactionLogs *TransactionLogService
	AuditLogs       *AuditLogService
	Monitoring      *MonitoringService
	Threads         *ThreadService
	Jobs            *JobService
	Git             *GitService
	Files           *FileService
	Applications    *ApplicationService
	Sandboxes       *SandboxService
	PowerBi         *PowerBiService
	Annotations     *AnnotationService
	Loggers         *LoggerService
}

func NewTM1Service(address string, port int, ssl bool, user, password, namespace, databaseName string) (*TM1Service, error) {
	rs, err := NewRestService(address, port, ssl, user, password, namespace, databaseName)
	if err != nil {
		return nil, err
	}

	tm1 := &TM1Service{
		Rest: rs,
	}
	tm1.Cubes = NewCubeService(rs)
	tm1.Dimensions = NewDimensionService(rs)
	tm1.Hierarchies = NewHierarchyService(rs)
	tm1.Subsets = NewSubsetService(rs)
	tm1.Views = NewViewService(rs)
	tm1.Processes = NewProcessService(rs)
	tm1.Chores = NewChoreService(rs)
	tm1.Elements = NewElementService(rs)
	tm1.Cells = &CellService{rest: rs}
	tm1.Users = NewUserService(rs)
	tm1.Security = NewSecurityService(rs)
	tm1.Sessions = NewSessionService(rs)
	tm1.Server = NewServerService(rs)
	tm1.Configuration = NewConfigurationService(rs)
	tm1.MessageLogs = NewMessageLogService(rs)
	tm1.TransactionLogs = NewTransactionLogService(rs)
	tm1.AuditLogs = NewAuditLogService(rs)
	tm1.Monitoring = NewMonitoringService(rs)
	tm1.Threads = NewThreadService(rs)
	tm1.Jobs = NewJobService(rs)
	tm1.Git = NewGitService(rs)
	tm1.Files = NewFileService(rs)
	tm1.Applications = NewApplicationService(rs)
	tm1.Sandboxes = NewSandboxService(rs)
	tm1.PowerBi = NewPowerBiService(rs)
	tm1.Annotations = NewAnnotationService(rs)
	tm1.Loggers = NewLoggerService(rs)

	return tm1, nil
}

func NewTM1ServiceFromEnv() (*TM1Service, error) {
	address := os.Getenv("TM1_ADDRESS")
	portStr := os.Getenv("TM1_PORT")
	sslStr := os.Getenv("TM1_SSL")
	user := os.Getenv("TM1_USER")
	password := os.Getenv("TM1_PASSWORD")
	namespace := os.Getenv("TM1_NAMESPACE")
	databaseName := os.Getenv("TM1_DATABASE")

	port, _ := strconv.Atoi(portStr)
	ssl := strings.ToLower(sslStr) == "true" || sslStr == "1"

	return NewTM1Service(address, port, ssl, user, password, namespace, databaseName)
}

func (s *TM1Service) Logout() error {
	return s.Rest.Logout()
}
