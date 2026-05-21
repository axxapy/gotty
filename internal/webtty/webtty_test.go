package webtty

import (
	"bytes"
	"context"
	"encoding/base64"
	"errors"
	"io"
	"sync"
	"testing"
)

// pipePair satisfies io.ReadWriter by pairing a reader with a writer from two pipes.
type pipePair struct {
	io.Reader
	io.Writer
}

// stubSlave is a minimal Slave implementation backed by external pipes.
type stubSlave struct {
	io.Reader
	io.Writer
}

func (s *stubSlave) WindowTitleVariables() map[string]interface{} { return nil }
func (s *stubSlave) ResizeTerminal(columns, rows int) error       { return nil }

// drainInitializeMessage consumes the SetWindowTitle frame that Run sends on start.
func drainInitializeMessage(t *testing.T, r io.Reader) {
	t.Helper()
	buf := make([]byte, 1024)
	n, err := r.Read(buf)
	if err != nil {
		t.Fatalf("read initialize message: %s", err)
	}
	if n < 1 || buf[0] != SetWindowTitle {
		t.Fatalf("unexpected initialize message type %d", buf[0])
	}
}

func runWebTTY(t *testing.T, dt *WebTTY) (context.CancelFunc, *sync.WaitGroup) {
	t.Helper()
	ctx, cancel := context.WithCancel(context.Background())
	var wg sync.WaitGroup
	wg.Add(1)
	go func() {
		defer wg.Done()
		if err := dt.Run(ctx); err != nil && !errors.Is(err, context.Canceled) {
			t.Errorf("unexpected error from Run(): %s", err)
		}
	}()
	return cancel, &wg
}

func TestWriteFromPTY(t *testing.T) {
	// Master pipes: wt writes server→client via clientInW; test reads via clientInR.
	clientInR, clientInW := io.Pipe()
	// clientOutR provides client→server input; this test sends none.
	clientOutR, _ := io.Pipe()
	master := pipePair{clientOutR, clientInW}

	// Slave pipes: wt reads slave output via slaveOutR; test feeds it via slaveOutW.
	slaveOutR, slaveOutW := io.Pipe()
	slave := &stubSlave{Reader: slaveOutR, Writer: io.Discard}

	dt, err := New(master, slave)
	if err != nil {
		t.Fatalf("unexpected error from New(): %s", err)
	}

	cancel, wg := runWebTTY(t, dt)
	defer wg.Wait()
	defer cancel()

	drainInitializeMessage(t, clientInR)

	message := []byte("foobar")
	if _, err := slaveOutW.Write(message); err != nil {
		t.Fatalf("write to slave: %s", err)
	}

	buf := make([]byte, 1024)
	n, err := clientInR.Read(buf)
	if err != nil {
		t.Fatalf("read from master: %s", err)
	}
	if buf[0] != Output {
		t.Fatalf("unexpected message type `%c`", buf[0])
	}
	decoded := make([]byte, 1024)
	dn, err := base64.StdEncoding.Decode(decoded, buf[1:n])
	if err != nil {
		t.Fatalf("base64 decode: %s", err)
	}
	if !bytes.Equal(decoded[:dn], message) {
		t.Fatalf("unexpected message received: %q", decoded[:dn])
	}
}

func TestWriteFromConn(t *testing.T) {
	clientInR, clientInW := io.Pipe()
	clientOutR, clientOutW := io.Pipe()
	master := pipePair{clientOutR, clientInW}

	// Slave: wt reads from slaveOutR (no data for this test); wt writes input to slaveInW.
	slaveOutR, _ := io.Pipe()
	slaveInR, slaveInW := io.Pipe()
	slave := &stubSlave{Reader: slaveOutR, Writer: slaveInW}

	dt, err := New(master, slave, WithPermitWrite())
	if err != nil {
		t.Fatalf("unexpected error from New(): %s", err)
	}

	cancel, wg := runWebTTY(t, dt)
	defer wg.Wait()
	defer cancel()

	drainInitializeMessage(t, clientInR)

	// Client→server input frame: [Input, 'h', 'e', 'l', 'l', 'o', '\n'].
	payload := []byte("hello\n")
	frame := append([]byte{Input}, payload...)
	if _, err := clientOutW.Write(frame); err != nil {
		t.Fatalf("write input frame: %s", err)
	}

	readBuf := make([]byte, 1024)
	n, err := slaveInR.Read(readBuf)
	if err != nil {
		t.Fatalf("read from slave: %s", err)
	}
	if !bytes.Equal(readBuf[:n], payload) {
		t.Fatalf("unexpected payload at slave: %q", readBuf[:n])
	}

	// Ping → expect Pong on the master writer.
	if _, err := clientOutW.Write([]byte{Ping}); err != nil {
		t.Fatalf("write ping: %s", err)
	}
	n, err = clientInR.Read(readBuf)
	if err != nil {
		t.Fatalf("read pong: %s", err)
	}
	if !bytes.Equal(readBuf[:n], []byte{Pong}) {
		t.Fatalf("unexpected pong response: %q", readBuf[:n])
	}
}
