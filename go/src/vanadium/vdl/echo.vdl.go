// This file was auto-generated by the vanadium vdl tool.
// Source: echo.vdl

package vanadium

import (
	// VDL system imports
	"v.io/v23"
	"v.io/v23/context"
	"v.io/v23/rpc"
)

// EchoClientMethods is the client interface
// containing Echo methods.
type EchoClientMethods interface {
	Echo(ctx *context.T, msg string, opts ...rpc.CallOpt) (string, error)
}

// EchoClientStub adds universal methods to EchoClientMethods.
type EchoClientStub interface {
	EchoClientMethods
	rpc.UniversalServiceMethods
}

// EchoClient returns a client stub for Echo.
func EchoClient(name string) EchoClientStub {
	return implEchoClientStub{name}
}

type implEchoClientStub struct {
	name string
}

func (c implEchoClientStub) Echo(ctx *context.T, i0 string, opts ...rpc.CallOpt) (o0 string, err error) {
	err = v23.GetClient(ctx).Call(ctx, c.name, "Echo", []interface{}{i0}, []interface{}{&o0}, opts...)
	return
}

// EchoServerMethods is the interface a server writer
// implements for Echo.
type EchoServerMethods interface {
	Echo(ctx *context.T, call rpc.ServerCall, msg string) (string, error)
}

// EchoServerStubMethods is the server interface containing
// Echo methods, as expected by rpc.Server.
// There is no difference between this interface and EchoServerMethods
// since there are no streaming methods.
type EchoServerStubMethods EchoServerMethods

// EchoServerStub adds universal methods to EchoServerStubMethods.
type EchoServerStub interface {
	EchoServerStubMethods
	// Describe the Echo interfaces.
	Describe__() []rpc.InterfaceDesc
}

// EchoServer returns a server stub for Echo.
// It converts an implementation of EchoServerMethods into
// an object that may be used by rpc.Server.
func EchoServer(impl EchoServerMethods) EchoServerStub {
	stub := implEchoServerStub{
		impl: impl,
	}
	// Initialize GlobState; always check the stub itself first, to handle the
	// case where the user has the Glob method defined in their VDL source.
	if gs := rpc.NewGlobState(stub); gs != nil {
		stub.gs = gs
	} else if gs := rpc.NewGlobState(impl); gs != nil {
		stub.gs = gs
	}
	return stub
}

type implEchoServerStub struct {
	impl EchoServerMethods
	gs   *rpc.GlobState
}

func (s implEchoServerStub) Echo(ctx *context.T, call rpc.ServerCall, i0 string) (string, error) {
	return s.impl.Echo(ctx, call, i0)
}

func (s implEchoServerStub) Globber() *rpc.GlobState {
	return s.gs
}

func (s implEchoServerStub) Describe__() []rpc.InterfaceDesc {
	return []rpc.InterfaceDesc{EchoDesc}
}

// EchoDesc describes the Echo interface.
var EchoDesc rpc.InterfaceDesc = descEcho

// descEcho hides the desc to keep godoc clean.
var descEcho = rpc.InterfaceDesc{
	Name:    "Echo",
	PkgPath: "examples/vanadium",
	Methods: []rpc.MethodDesc{
		{
			Name: "Echo",
			InArgs: []rpc.ArgDesc{
				{"msg", ``}, // string
			},
			OutArgs: []rpc.ArgDesc{
				{"", ``}, // string
			},
		},
	},
}