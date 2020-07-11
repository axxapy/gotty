package server

import (
	"fmt"
	"net/http"
	"strings"
)

func exportHeaders(options *Options, prefix string, r *http.Request) map[string]string {
	exportCookies := options.EnableCookiesExport
	exportHeaders := options.EnableHeadersExport

	if !exportCookies && !exportHeaders {
		return nil
	}

	var env = make(map[string]string)
	var envPrefixUpper = strings.ToUpper(prefix)
	var value string

	if exportHeaders {
		for name, values := range r.Header {
			if len(values) == 0 {
				value = ""
			} else {
				value = fmt.Sprint(values[0])
			}

			env[fmt.Sprintf("%sHEADER_%s", envPrefixUpper, normalizeEnvName(name))] = value
		}
	}

	if exportCookies {
		for _, cookie := range r.Cookies() {
			env[fmt.Sprintf("%sCOOKIE_%s", envPrefixUpper, normalizeEnvName(cookie.Name))] = cookie.Value
		}
	}

	return env
}

func normalizeEnvName(name string) string {
	name = strings.ToUpper(name)
	name = strings.Replace(name, "-", "_", -1)
	return name
}
