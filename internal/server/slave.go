package server

import (
	"github.com/axxapy/gotty/internal/webtty"
)

// Slave is webtty.Slave with some additional methods.
type Slave interface {
	webtty.Slave

	Close() error
}

type Factory interface {
	Name() string
	New(params map[string][]string, env map[string]string) (Slave, error)
}
