package Manager

import "fmt"

// BuildManager function
func BuildManager(teamserver string, worker string, name string, port string, customHeader string, customSecret string) {
	fmt.Print(teamserver, worker, name, port, customHeader, customSecret)
}
