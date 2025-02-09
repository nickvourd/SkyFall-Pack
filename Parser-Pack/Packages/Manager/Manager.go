package Manager

import (
	"WorkerMan/Packages/Protection"
)

// BuildManager function
func BuildManager(teamserver string, worker string, name string) (string, string, string) {
	// Call function named MandatoryFlag
	Protection.MandatoryFlag(teamserver, "t", "teamserver")

	// Call function named MandatoryFlag
	Protection.MandatoryFlag(worker, "w", "worker")

	// Call function named ExtractFQDN
	teamserver = Protection.ExtractFQDN(teamserver)

	// Call function named ExtractFQDN
	worker = Protection.ExtractFQDN(worker)

	// if name is empty
	if name == "" {
		// Call function named ExtractWorkerName
		name = Protection.ExtractWorkerName(worker)
	} else { // if name is not empty
		// Call function named ExtractFQDN
		name = Protection.ExtractFQDN(name)

		// Call function named ExtractWorkerName
		name = Protection.ExtractWorkerName(name)
	}

	return teamserver, worker, name
}

// TemplateManager function
func TemplateManager(teamserver string, worker string, name string, port string, customHeader string, customSecret string) {
	// Placeholder for future code
}
