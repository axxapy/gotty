import { Terminal } from "xterm";
import { FitAddon } from "xterm-addon-fit";
import { lib } from "libapps"

export class Xterm {
    elem: HTMLElement;
    term: Terminal;
    resizeListener: () => void;
    decoder: lib.UTF8Decoder;

    message: HTMLElement;
    messageTimeout: number;
    messageTimer: number;

    constructor(elem: HTMLElement) {
        this.elem = elem;
        this.term = new Terminal();
        const fit = new FitAddon()
        this.term.loadAddon(fit);

        this.message = elem.ownerDocument.createElement("div");
        this.message.className = "xterm-overlay";
        this.messageTimeout = 2000;

        this.resizeListener = () => {
            fit.fit();
            this.term.scrollToBottom();
            this.showMessage(String(this.term.cols) + "x" + String(this.term.rows), this.messageTimeout);
        };

        window.addEventListener("resize", this.resizeListener);
        this.term.onResize(this.resizeListener)

        this.term.open(elem);
        fit.fit();

        this.decoder = new lib.UTF8Decoder()
    };

    info(): { columns: number, rows: number } {
        return { columns: this.term.cols, rows: this.term.rows };
    };

    output(data: string) {
        this.term.write(this.decoder.decode(data));
    };

    showMessage(message: string, timeout: number) {
        this.message.textContent = message;
        this.elem.appendChild(this.message);

        if (this.messageTimer) {
            clearTimeout(this.messageTimer);
        }
        if (timeout > 0) {
            this.messageTimer = window.setTimeout(() => {
                this.elem.removeChild(this.message);
            }, timeout);
        }
    };

    removeMessage(): void {
        if (this.message.parentNode == this.elem) {
            this.elem.removeChild(this.message);
        }
    }

    setWindowTitle(title: string) {
        document.title = title;
    };

    setPreferences(value: object) {
    };

    onInput(callback: (input: string) => void) {
        this.term.onData((data) => {
            callback(data);
        });
    };

    onResize(callback: (colmuns: number, rows: number) => void) {
        this.term.onResize((data) => {
            callback(data.cols, data.rows);
        });
    };

    deactivate(): void {
        //this.term.off("data");
        //this.term.off("resize");
        this.term.blur();
    }

    reset(): void {
        this.removeMessage();
        this.term.clear();
    }

    close(): void {
        window.removeEventListener("resize", this.resizeListener);
        this.term.dispose();
    }
}
