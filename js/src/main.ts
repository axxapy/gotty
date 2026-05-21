import { Hterm } from "./hterm";
import { Xterm } from "./xterm";
import { Terminal, WebTTY, protocols } from "./webtty";
import { ConnectionFactory } from "./websocket";

// Globals injected by the server-rendered auth_token.js / config.js.
declare global {
    interface Window {
        gotty_auth_token: string;
        gotty_term: string;
    }
}

const elem = document.getElementById("terminal");

if (elem !== null) {
    const term: Terminal = window.gotty_term == "hterm" ? new Hterm(elem) : new Xterm(elem);
    const httpsEnabled = window.location.protocol == "https:";
    const url = (httpsEnabled ? "wss://" : "ws://") + window.location.host + window.location.pathname + "ws";
    const args = window.location.search;
    const factory = new ConnectionFactory(url, protocols);
    const wt = new WebTTY(term, factory, args, window.gotty_auth_token);
    const closer = wt.open();

    window.addEventListener("unload", () => {
        closer();
        term.close();
    });
}
