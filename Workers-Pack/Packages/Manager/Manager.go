package Manager

import (
	"WorkerMan/Packages/Protection"
	"WorkerMan/Packages/Random"
	"WorkerMan/Packages/Templates"
	"WorkerMan/Packages/Utils"
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
		// Call function named CompareNameWithWorker
		name = Protection.CompareNameWithWorker(name, worker)
	}

	return teamserver, worker, name
}

// TemplateManager function
func TemplateManager(teamserver string, worker string, name string, customHeader string, customSecret string) (string, string) {
	// Call function named GenerateRandomVariableName
	randomVariableName, randomVariableName2, randomVariableName3 := Random.GenerateRandomVariableName()

	// Call function named GetDate
	date := Utils.GetDate()

	// Call function named BuildWranglerJSON
	wranglerJson := Templates.BuildWranglerJSON(teamserver, worker, name, customSecret, randomVariableName, randomVariableName2, randomVariableName3, date)

	// Call function named BuildIndexJS
	indexJs := Templates.BuildIndexJS(randomVariableName, randomVariableName2, randomVariableName3, customHeader)

	return wranglerJson, indexJs
}
