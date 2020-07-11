package localcommand

import (
	"fmt"
	"os"
	"syscall"
	"time"
)

type Option func(*LocalCommand)

func WithCloseSignal(signal syscall.Signal) Option {
	return func(lcmd *LocalCommand) {
		lcmd.closeSignal = signal
	}
}

func WithCloseTimeout(timeout time.Duration) Option {
	return func(lcmd *LocalCommand) {
		lcmd.closeTimeout = timeout
	}
}

func WithEnv(env map[string]string) Option {
	return func(lcmd *LocalCommand) {
		lcmd.cmd.Env = os.Environ()
		for k, v := range env {
			lcmd.cmd.Env = append(lcmd.cmd.Env, fmt.Sprintf(`%s=%s`, k, v))
		}
	}
}
