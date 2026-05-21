import { Xterm } from "./xterm";
import { WebTTY, protocols } from "./webtty";
import { ConnectionFactory } from "./websocket";

// gotty_auth_token is injected by the server-rendered auth_token.js.
declare global {
    interface Window {
        gotty_auth_token: string;
    }
}

const elem = document.getElementById("terminal");

if (elem !== null) {
    const term = new Xterm(elem);
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
